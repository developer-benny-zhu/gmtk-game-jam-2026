package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "vendor/r3d"
import "vendor:raylib"
import "vendor:raylib/rlgl"

WORLD_SIZE_X :: 100
WORLD_SIZE_Y :: 100
TILE_WAIT_TIME :: 10.0
TILE_LERP_TIME :: 1.0
DAMAGE_PER_SECOND :: 10.0

Tile_Phase :: enum {
	Safe,
	Lerping_Red,
	Danger,
	Lerping_Green,
}

World :: struct {
	player:                Player,
	floor_instance_buffer: r3d.InstanceBuffer,
	tile_phase:            Tile_Phase,
	tile_timer:            f32,
	danger_tiles:          [WORLD_SIZE_X * WORLD_SIZE_Y]bool,
}

lerp_color :: proc(c1, c2: raylib.Color, t: f32) -> raylib.Color {
	return {
		u8(math.lerp(f32(c1.r), f32(c2.r), t)),
		u8(math.lerp(f32(c1.g), f32(c2.g), t)),
		u8(math.lerp(f32(c1.b), f32(c2.b), t)),
		255,
	}
}

update_tile_colors :: proc(world: ^World, t: f32) {
	colors := cast([^]raylib.Color)r3d.MapInstances(world.floor_instance_buffer, {.COLOR}, false)
	for i in 0 ..< WORLD_SIZE_X * WORLD_SIZE_Y {
		if world.danger_tiles[i] {
			colors[i] = lerp_color(raylib.GREEN, raylib.RED, t)
		} else {
			colors[i] = raylib.GREEN
		}
	}
	r3d.UnmapInstances(world.floor_instance_buffer, {.COLOR})
}

check_player_damage :: proc(world: ^World, game_state: Game_State) {
	delta_time := raylib.GetFrameTime()
	if world.player.is_grounded {
		grid_x := int(math.round(world.player.position.x))
		grid_y := int(math.round(world.player.position.z))

		if grid_x >= 0 && grid_x < WORLD_SIZE_X && grid_y >= 0 && grid_y < WORLD_SIZE_Y {
			idx := grid_y * WORLD_SIZE_X + grid_x
			if world.danger_tiles[idx] {
				prev_health := int(world.player.health)
				world.player.health -= DAMAGE_PER_SECOND * delta_time
				play_random_male_grunt_sound(game_state.assets)
				world.player.hurt_timer = 0.25

				curr_health := int(world.player.health)
				if curr_health < prev_health {
					fmt.println(curr_health)
				}
			}
		}
	}
}

world_init :: proc(world: ^World) {
	player_init(&world.player)
	raylib.DisableCursor()
	world.floor_instance_buffer = r3d.LoadInstanceBuffer(
		WORLD_SIZE_X * WORLD_SIZE_Y,
		{.POSITION, .COLOR},
	)
	positions := cast([^]linalg.Vector3f32)r3d.MapInstances(
		world.floor_instance_buffer,
		{.POSITION},
		false,
	)
	colors := cast([^]raylib.Color)r3d.MapInstances(world.floor_instance_buffer, {.COLOR}, false)
	for row in 0 ..< WORLD_SIZE_Y {
		for column in 0 ..< WORLD_SIZE_X {
			positions[row * WORLD_SIZE_X + column] = {f32(column), 0, f32(row)}
			colors[row * WORLD_SIZE_X + column] = raylib.GREEN
		}
	}
	r3d.UnmapInstances(world.floor_instance_buffer, {.POSITION, .COLOR})
	light := r3d.CreateLight(.DIR)
	r3d.SetLightDirection(light, {0, -1, 0})
	r3d.EnableLight(light)

	world.tile_phase = .Safe
	world.tile_timer = 0.0
}

world_update :: proc(world: ^World, game_state: ^Game_State) {
	delta := raylib.GetFrameTime()
	if world.player.hurt_timer > 0.0 {
		world.player.hurt_timer -= delta
	}
	world.tile_timer += delta

	switch world.tile_phase {
	case .Safe:
		if world.tile_timer >= TILE_WAIT_TIME {
			world.tile_timer = 0.0
			world.tile_phase = .Lerping_Red
			for i in 0 ..< WORLD_SIZE_X * WORLD_SIZE_Y {
				world.danger_tiles[i] = rand.float32() < 0.5
			}
		}
	case .Lerping_Red:
		if world.tile_timer >= TILE_LERP_TIME {
			world.tile_timer = 0.0
			world.tile_phase = .Danger
			update_tile_colors(world, 1.0)
		} else {
			update_tile_colors(world, world.tile_timer / TILE_LERP_TIME)
		}
	case .Danger:
		if world.tile_timer >= TILE_WAIT_TIME {
			world.tile_timer = 0.0
			world.tile_phase = .Lerping_Green
		} else {
			check_player_damage(world, game_state^)
		}
	case .Lerping_Green:
		if world.tile_timer >= TILE_LERP_TIME {
			world.tile_timer = 0.0
			world.tile_phase = .Safe
			update_tile_colors(world, 0.0)
		} else {
			update_tile_colors(world, 1.0 - (world.tile_timer / TILE_LERP_TIME))
		}
	}

	view_model_update(&world.player.view_model)
	gui_camera_update(&game_state.gui_camera)
	player_update(&world.player, game_state.assets)
	if raylib.IsMouseButtonPressed(.LEFT) {
		view_model_add_recoil(&world.player.view_model)
		random_index := rand.int_range(0, AMOUNT_OF_LASER_SOUNDS)
		raylib.PlaySound(game_state.assets.laser_sounds[random_index])
	}
}

world_draw :: proc(world: ^World, game_state: ^Game_State) {
	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)
	rlgl.SetClipPlanes(0.5, 1000.0)

	r3d.Begin(world.player.camera)
	raylib.DrawGrid(50, 1.0)
	world_draw_floor(world, game_state.assets)
	r3d.End()


	raylib.BeginMode2D(game_state.gui_camera)
	draw_crosshair()
	draw_ui(world)
	raylib.EndMode2D()

	raylib.BeginMode3D(world.player.view_model_camera)
	view_model_draw(
		world.player.view_model,
		game_state.assets,
		world.player.head_bob_timer,
		world.player.walk_bob_lerp,
	)
	raylib.EndMode3D()

	raylib.DrawFPS(10, 10)
	raylib.EndDrawing()
}

draw_ui :: proc(world: ^World) {
	screen_width := f32(raylib.GetScreenWidth())
	screen_height := f32(raylib.GetScreenHeight())

	if world.player.hurt_timer > 0.0 {
		alpha_factor := world.player.hurt_timer / 0.25
		flash_alpha := u8(raylib.Clamp(alpha_factor * 100.0, 0.0, 100.0))

		raylib.DrawRectangle(
			0,
			0,
			i32(screen_width),
			i32(screen_height),
			raylib.Color{255, 0, 0, flash_alpha},
		)
	}

	if world.player.health < 30.0 && world.player.health > 0.0 {
		pulse := (math.sin(f32(raylib.GetTime()) * 10.0) + 1.0) * 0.5
		border_alpha := u8(50.0 + pulse * 100.0)
		border_thickness: f32 = 14.0

		raylib.DrawRectangleLinesEx(
			raylib.Rectangle{0, 0, screen_width, screen_height},
			border_thickness,
			raylib.Color{255, 0, 0, border_alpha},
		)
	}

	phase_name := ""
	total_phase_time: f32 = 0.0
	text_color := raylib.WHITE

	switch world.tile_phase {
	case .Safe:
		phase_name = "SAFE"
		total_phase_time = TILE_WAIT_TIME
		text_color = raylib.GREEN
	case .Lerping_Red:
		phase_name = "SHIFTING!"
		total_phase_time = TILE_LERP_TIME
		text_color = raylib.YELLOW
	case .Danger:
		phase_name = "DANGER!"
		total_phase_time = TILE_WAIT_TIME
		text_color = raylib.RED
	case .Lerping_Green:
		phase_name = "CLEARING"
		total_phase_time = TILE_LERP_TIME
		text_color = raylib.SKYBLUE
	}

	remaining_time := math.max(0.0, total_phase_time - world.tile_timer)

	timer_text := fmt.ctprintf("%s: %.1fs", phase_name, remaining_time)
	font_size: i32 = 40
	text_width := raylib.MeasureText(timer_text, font_size)

	text_x := i32(screen_width / 2.0) - (text_width / 2)
	text_y: i32 = 30

	raylib.DrawText(timer_text, text_x + 3, text_y + 3, font_size, raylib.BLACK)
	raylib.DrawText(timer_text, text_x, text_y, font_size, text_color)

	bar_width: f32 = 300.0
	bar_height: f32 = 30.0
	bar_x: f32 = 30.0
	bar_y := screen_height - bar_height - 30.0

	health_pct := world.player.health / 100.0
	current_bar_width := math.max(0.0, bar_width * health_pct)

	health_color := raylib.GREEN
	if health_pct <= 0.5 do health_color = raylib.YELLOW
	if health_pct <= 0.25 do health_color = raylib.RED

	raylib.DrawRectangle(
		i32(bar_x),
		i32(bar_y),
		i32(bar_width),
		i32(bar_height),
		raylib.Color{40, 40, 40, 255},
	)
	raylib.DrawRectangle(
		i32(bar_x),
		i32(bar_y),
		i32(current_bar_width),
		i32(bar_height),
		health_color,
	)
	raylib.DrawRectangleLinesEx(
		raylib.Rectangle{bar_x, bar_y, bar_width, bar_height},
		3.0,
		raylib.WHITE,
	)

	health_text := fmt.ctprintf("HP: %d / 100", int(math.max(0.0, world.player.health)))
	raylib.DrawText(health_text, i32(bar_x + 10), i32(bar_y + 5), 20, raylib.WHITE)
}

world_draw_floor :: proc(world: ^World, assets: Assets) {
	r3d.DrawMeshInstanced(
		assets.cube,
		r3d.GetDefaultMaterial(),
		world.floor_instance_buffer,
		WORLD_SIZE_X * WORLD_SIZE_Y,
	)
}

world_destroy :: proc(world: ^World) {
	r3d.UnloadInstanceBuffer(world.floor_instance_buffer)
}
