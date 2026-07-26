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
WARNING_TIME :: 2.0
DAMAGE_PER_SECOND :: 10.0
MAX_ENEMIES :: 100

Tile_Phase :: enum {
	Safe,
	Warning,
	Lerping_Red,
	Danger,
	Lerping_Green,
}

Enemy :: struct {
	position:        linalg.Vector3f32,
	target_position: linalg.Vector3f32,
	move_timer:      f32,
	base_y:          f32,
	health:          f32,
	hurt_timer:      f32,
	shoot_timer:     f32,
	active:          bool,
	scale:           linalg.Vector3f32,
	on_fire_timer:   f32,
}

Projectile :: struct {
	position: linalg.Vector3f32,
	velocity: linalg.Vector3f32,
	rotation: linalg.Quaternionf32,
	active:   bool,
}

Player_Projectile :: struct {
	position: linalg.Vector3f32,
	velocity: linalg.Vector3f32,
	active:   bool,
	life:     f32,
}

Stasis_Field :: struct {
	position: linalg.Vector3f32,
	radius:   f32,
	damage:   f32,
	active:   bool,
	life:     f32,
}

World :: struct {
	player:                     Player,
	floor_instance_buffer:      r3d.InstanceBuffer,
	enemy_instance_buffer:      r3d.InstanceBuffer,
	projectile_instance_buffer: r3d.InstanceBuffer,
	tile_phase:                 Tile_Phase,
	tile_timer:                 f32,
	danger_tiles:               [WORLD_SIZE_X * WORLD_SIZE_Y]bool,
	enemies:                    [MAX_ENEMIES]Enemy,
	projectiles:                [1000]Projectile,
	player_projectiles:         [200]Player_Projectile,
	stasis_fields:              [50]Stasis_Field,
	cards_sys:                  Cards_System,
	hitmarker_timer:            f32,
	wave:                       int,
	is_paused:                  bool,
	pause_selected_index:       int,
}

spawn_wave :: proc(world: ^World) {
	enemy_count := 2 + (world.wave - 1) * 3
	if enemy_count > MAX_ENEMIES do enemy_count = MAX_ENEMIES

	for i in 0 ..< MAX_ENEMIES {
		if i < enemy_count {
			base_y := rand.float32_range(8.0, 25.0)
			pos := linalg.Vector3f32 {
				rand.float32_range(10.0, f32(WORLD_SIZE_X) - 10.0),
				base_y,
				rand.float32_range(10.0, f32(WORLD_SIZE_Y) - 10.0),
			}
			world.enemies[i] = Enemy {
				position        = pos,
				target_position = pos,
				move_timer      = 0.0,
				base_y          = base_y,
				health          = 100.0,
				active          = true,
				shoot_timer     = rand.float32_range(1.0, 5.0),
				scale           = {1.0, 1.0, 1.0},
				on_fire_timer   = 0.0,
			}
		} else {
			world.enemies[i].active = false
		}
	}
}

lerp_color :: proc(c1, c2: raylib.Color, t: f32) -> raylib.Color {
	return {
		u8(math.lerp(f32(c1.r), f32(c2.r), t)),
		u8(math.lerp(f32(c1.g), f32(c2.g), t)),
		u8(math.lerp(f32(c1.b), f32(c2.b), t)),
		255,
	}
}

update_tile_colors :: proc(world: ^World, c1, c2: raylib.Color, t: f32) {
	colors := cast([^]raylib.Color)r3d.MapInstances(world.floor_instance_buffer, {.COLOR}, false)
	for i in 0 ..< WORLD_SIZE_X * WORLD_SIZE_Y {
		if world.danger_tiles[i] {
			colors[i] = lerp_color(c1, c2, t)
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

	world.tile_phase = .Safe
	world.tile_timer = 0.0
	world.wave = 1
	world.is_paused = false
	world.pause_selected_index = 0
	world.hitmarker_timer = 0.0


	for i in 0 ..< len(world.projectiles) {
		world.projectiles[i].active = false
	}


	for i in 0 ..< len(world.danger_tiles) {
		world.danger_tiles[i] = false
	}

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

	world.enemy_instance_buffer = r3d.LoadInstanceBuffer(MAX_ENEMIES, {.POSITION, .SCALE, .COLOR})
	world.projectile_instance_buffer = r3d.LoadInstanceBuffer(1000, {.POSITION, .ROTATION, .COLOR})

	spawn_wave(world)
}

spawn_stasis :: proc(world: ^World, pos: linalg.Vector3f32) {
	for s in 0 ..< len(world.stasis_fields) {
		if !world.stasis_fields[s].active {
			world.stasis_fields[s].active = true
			world.stasis_fields[s].position = pos
			world.stasis_fields[s].radius = 4.0 + f32(world.player.powerups[.Stasis]) * 2.0
			world.stasis_fields[s].damage = 10.0 + f32(world.player.powerups[.Stasis]) * 5.0
			world.stasis_fields[s].life = 5.0
			break
		}
	}
}

world_update :: proc(world: ^World, game_state: ^Game_State) {
	if world.cards_sys.active {
		cards_update(&world.cards_sys, world, game_state)
		return
	}

	if raylib.IsKeyPressed(.ESCAPE) {
		world.is_paused = !world.is_paused
		if world.is_paused {
			raylib.EnableCursor()
		} else {
			raylib.DisableCursor()
		}
	}

	if world.is_paused {
		if raylib.IsKeyPressed(.DOWN) || raylib.IsKeyPressed(.S) {
			world.pause_selected_index = (world.pause_selected_index + 1) % 2
		}
		if raylib.IsKeyPressed(.UP) || raylib.IsKeyPressed(.W) {
			world.pause_selected_index = (world.pause_selected_index - 1 + 2) % 2
		}
		if raylib.IsKeyPressed(.ENTER) {
			if world.pause_selected_index == 0 {
				world.is_paused = false
				raylib.DisableCursor()
			} else {
				game_state_switch_scene(game_state, .Main_Menu)
			}
		}
		return
	}

	delta := raylib.GetFrameTime()
	if world.player.hurt_timer > 0.0 {
		world.player.hurt_timer -= delta
	}
	world.tile_timer += delta

	if world.hitmarker_timer > 0.0 {
		world.hitmarker_timer -= delta
	}

	active_enemies := 0
	ray := player_shoot_ray(world.player)

	for i in 0 ..< MAX_ENEMIES {
		if world.enemies[i].active {
			active_enemies += 1
			if world.enemies[i].hurt_timer > 0.0 {
				world.enemies[i].hurt_timer -= delta
			}

			if world.enemies[i].on_fire_timer > 0.0 {
				world.enemies[i].on_fire_timer -= delta
				world.enemies[i].health -= 15.0 * f32(world.player.powerups[.Fire_Bullets]) * delta
				if world.enemies[i].health <= 0.0 {
					world.enemies[i].active = false
				}
			}

			if !world.enemies[i].active {
				continue
			}

			world.enemies[i].move_timer -= delta
			if world.enemies[i].move_timer <= 0.0 {
				world.enemies[i].move_timer = rand.float32_range(4.0, 8.0)
				world.enemies[i].base_y = rand.float32_range(6.0, 28.0)
				world.enemies[i].target_position = {
					rand.float32_range(10.0, f32(WORLD_SIZE_X) - 10.0),
					world.enemies[i].base_y,
					rand.float32_range(10.0, f32(WORLD_SIZE_Y) - 10.0),
				}
			}

			time := f32(raylib.GetTime())
			float_offset := math.sin(time * 2.5 + f32(i)) * 1.5
			target_pos_with_float := world.enemies[i].target_position
			target_pos_with_float.y += float_offset

			world.enemies[i].position = linalg.lerp(
				world.enemies[i].position,
				target_pos_with_float,
				delta * 1.1,
			)

			dir_to_enemy := raylib.Vector3Normalize(
				world.enemies[i].position - world.player.position,
			)
			dot := linalg.vector_dot(ray.direction, dir_to_enemy)
			if dot > 0.95 {
				world.enemies[i].target_position.x += rand.float32_range(-8.0, 8.0)
				world.enemies[i].target_position.z += rand.float32_range(-8.0, 8.0)
				world.enemies[i].target_position.x = raylib.Clamp(
					world.enemies[i].target_position.x,
					10.0,
					f32(WORLD_SIZE_X) - 10.0,
				)
				world.enemies[i].target_position.z = raylib.Clamp(
					world.enemies[i].target_position.z,
					10.0,
					f32(WORLD_SIZE_Y) - 10.0,
				)
			}

			world.enemies[i].scale = linalg.lerp(
				world.enemies[i].scale,
				linalg.Vector3f32{1.0, 1.0, 1.0},
				delta * 4.0,
			)

			world.enemies[i].shoot_timer -= delta
			if world.enemies[i].shoot_timer <= 0.0 {
				world.enemies[i].shoot_timer = rand.float32_range(2.5, 6.0)
				world.enemies[i].scale = {1.5, 0.4, 1.5}

				rand_idx := rand.int_range(0, AMOUNT_OF_LASER_SOUNDS)
				sound := game_state.assets.laser_sounds[rand_idx]
				set_sound_position(world.player.camera, sound, world.enemies[i].position, 40.0)
				raylib.PlaySound(sound)

				for j in 0 ..< len(world.projectiles) {
					if !world.projectiles[j].active {
						world.projectiles[j].active = true
						world.projectiles[j].position = world.enemies[i].position
						direction := raylib.Vector3Normalize(
							world.player.position - world.enemies[i].position,
						)
						world.projectiles[j].velocity = direction * 25.0

						forward := linalg.Vector3f32{0, 0, 1}
						axis := linalg.vector_cross(forward, direction)
						proj_dot := linalg.vector_dot(forward, direction)
						if math.abs(proj_dot + 1.0) < 0.00001 {
							world.projectiles[j].rotation = linalg.quaternion_angle_axis_f32(
								math.PI,
								{0, 1, 0},
							)
						} else if math.abs(proj_dot - 1.0) < 0.00001 {
							world.projectiles[j].rotation = linalg.quaternion_angle_axis_f32(
								0,
								{0, 1, 0},
							)
						} else {
							angle := math.acos(raylib.Clamp(proj_dot, -1.0, 1.0))
							world.projectiles[j].rotation = linalg.quaternion_angle_axis_f32(
								angle,
								linalg.vector_normalize(axis),
							)
						}
						break
					}
				}
			}
		}
	}

	for i in 0 ..< len(world.projectiles) {
		if world.projectiles[i].active {
			world.projectiles[i].position += world.projectiles[i].velocity * delta

			player_box := raylib.BoundingBox {
				min = world.player.position - {0.5, 0.0, 0.5},
				max = world.player.position + {0.5, 2.0, 0.5},
			}
			proj_box := raylib.BoundingBox {
				min = world.projectiles[i].position - {0.2, 0.2, 0.2},
				max = world.projectiles[i].position + {0.2, 0.2, 0.2},
			}

			if raylib.CheckCollisionBoxes(player_box, proj_box) {
				world.projectiles[i].active = false
				world.player.health -= 15.0
				world.player.hurt_timer = 0.25
				play_random_male_grunt_sound(game_state.assets)
			}

			if world.projectiles[i].position.y < 0.0 ||
			   world.projectiles[i].position.y > 100.0 ||
			   world.projectiles[i].position.x < -10.0 ||
			   world.projectiles[i].position.x > f32(WORLD_SIZE_X) + 10.0 ||
			   world.projectiles[i].position.z < -10.0 ||
			   world.projectiles[i].position.z > f32(WORLD_SIZE_Y) + 10.0 {
				world.projectiles[i].active = false
			}
		}
	}

	for p in 0 ..< len(world.player_projectiles) {
		if world.player_projectiles[p].active {
			world.player_projectiles[p].position += world.player_projectiles[p].velocity * delta
			world.player_projectiles[p].life -= delta

			hit := false

			if world.player_projectiles[p].position.y <= 0.0 {
				hit = true
				world.player_projectiles[p].position.y = 0.0
			}

			if !hit {
				for e in 0 ..< MAX_ENEMIES {
					if world.enemies[e].active {
						dist := linalg.vector_length(
							world.player_projectiles[p].position - world.enemies[e].position,
						)
						if dist < 4.2 {
							world.enemies[e].health -= 25.0
							world.enemies[e].hurt_timer = 0.15
							world.hitmarker_timer = 0.2

							if world.player.powerups[.Fire_Bullets] > 0 {
								world.enemies[e].on_fire_timer = 5.0
							}
							if world.player.powerups[.Life_Steal] > 0 {
								world.player.health +=
									f32(world.player.powerups[.Life_Steal]) * 2.5
								world.player.health = math.clamp(world.player.health, 0.0, 100.0)
							}

							if world.enemies[e].health <= 0.0 {
								world.enemies[e].active = false
							}
							hit = true
							break
						}
					}
				}
			}

			if hit {
				if world.player.powerups[.Stasis] > 0 {
					spawn_stasis(world, world.player_projectiles[p].position)
				}
				world.player_projectiles[p].active = false
			} else if world.player_projectiles[p].life <= 0.0 {
				world.player_projectiles[p].active = false
			}
		}
	}

	for s in 0 ..< len(world.stasis_fields) {
		if world.stasis_fields[s].active {
			world.stasis_fields[s].life -= delta
			if world.stasis_fields[s].life <= 0.0 {
				world.stasis_fields[s].active = false
			} else {
				for e in 0 ..< MAX_ENEMIES {
					if world.enemies[e].active {
						dist := linalg.vector_length(
							world.stasis_fields[s].position - world.enemies[e].position,
						)
						if dist < world.stasis_fields[s].radius {
							world.enemies[e].health -= world.stasis_fields[s].damage * delta
							if world.enemies[e].health <= 0.0 {
								world.enemies[e].active = false
							}
						}
					}
				}
			}
		}
	}

	switch world.tile_phase {
	case .Safe:
		if active_enemies > 0 {
			if world.tile_timer >= TILE_WAIT_TIME {
				world.tile_timer = 0.0
				world.tile_phase = .Warning
				danger_chance := raylib.Clamp(0.1 + (f32(world.wave) * 0.05), 0.1, 0.95)
				for i in 0 ..< WORLD_SIZE_X * WORLD_SIZE_Y {
					world.danger_tiles[i] = rand.float32() < danger_chance
				}
			}
		} else {
			if !world.cards_sys.active {
				cards_init_for_wave(&world.cards_sys)
			}
		}
	case .Warning:
		if world.tile_timer >= WARNING_TIME {
			world.tile_timer = 0.0
			world.tile_phase = .Lerping_Red
		} else {
			blink := math.sin(world.tile_timer * 20.0) > 0.0
			colors := cast([^]raylib.Color)r3d.MapInstances(
				world.floor_instance_buffer,
				{.COLOR},
				false,
			)
			for i in 0 ..< WORLD_SIZE_X * WORLD_SIZE_Y {
				if world.danger_tiles[i] {
					colors[i] = blink ? raylib.Color{255, 100, 100, 255} : raylib.GREEN
				} else {
					colors[i] = raylib.GREEN
				}
			}
			r3d.UnmapInstances(world.floor_instance_buffer, {.COLOR})
		}
	case .Lerping_Red:
		if world.tile_timer >= TILE_LERP_TIME {
			world.tile_timer = 0.0
			world.tile_phase = .Danger
			update_tile_colors(world, raylib.Color{255, 100, 100, 255}, raylib.RED, 1.0)
		} else {
			update_tile_colors(
				world,
				raylib.Color{255, 100, 100, 255},
				raylib.RED,
				world.tile_timer / TILE_LERP_TIME,
			)
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
			update_tile_colors(world, raylib.RED, raylib.GREEN, 1.0)
		} else {
			update_tile_colors(world, raylib.RED, raylib.GREEN, world.tile_timer / TILE_LERP_TIME)
		}
	}

	view_model_update(&world.player.view_model)
	gui_camera_update(&game_state.gui_camera)
	player_update(&world.player, game_state.assets)

	if world.player.health <= 0.0 {
		game_state_switch_scene(game_state, .Game_Over)
		return
	}

	if raylib.IsMouseButtonPressed(.LEFT) {
		view_model_add_recoil(&world.player.view_model)
		random_index := rand.int_range(0, AMOUNT_OF_LASER_SOUNDS)
		raylib.PlaySound(game_state.assets.laser_sounds[random_index])

		base_ray := player_shoot_ray(world.player)
		bullet_count := 1 + world.player.powerups[.More_Bullets] * 2

		for b in 0 ..< bullet_count {
			dir := base_ray.direction
			if bullet_count > 1 {
				spread := f32(world.player.powerups[.More_Bullets]) * 0.03
				dir.x += rand.float32_range(-spread, spread)
				dir.y += rand.float32_range(-spread, spread)
				dir.z += rand.float32_range(-spread, spread)
				dir = raylib.Vector3Normalize(dir)
			}

			for p in 0 ..< len(world.player_projectiles) {
				if !world.player_projectiles[p].active {
					world.player_projectiles[p].active = true
					world.player_projectiles[p].position = world.player.camera.position + dir * 1.0
					world.player_projectiles[p].velocity = dir * 100.0
					world.player_projectiles[p].life = 3.0
					break
				}
			}
		}
	}
}

world_draw :: proc(world: ^World, game_state: ^Game_State) {
	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)
	rlgl.SetClipPlanes(0.5, 1000.0)

	r3d.Begin(world.player.camera)
	raylib.DrawGrid(50, 1.0)
	world_draw_floor(world, game_state.assets)

	enemy_positions := cast([^]linalg.Vector3f32)r3d.MapInstances(
		world.enemy_instance_buffer,
		{.POSITION},
		false,
	)
	enemy_scales := cast([^]linalg.Vector3f32)r3d.MapInstances(
		world.enemy_instance_buffer,
		{.SCALE},
		false,
	)
	enemy_colors := cast([^]raylib.Color)r3d.MapInstances(
		world.enemy_instance_buffer,
		{.COLOR},
		false,
	)

	active_enemy_count: i32 = 0
	for i in 0 ..< MAX_ENEMIES {
		if world.enemies[i].active {
			enemy_positions[active_enemy_count] = world.enemies[i].position
			enemy_scales[active_enemy_count] = world.enemies[i].scale
			enemy_colors[active_enemy_count] =
				raylib.RED if world.enemies[i].hurt_timer > 0.0 else raylib.BLUE
			active_enemy_count += 1
		}
	}

	r3d.UnmapInstances(world.enemy_instance_buffer, {.POSITION, .SCALE, .COLOR})

	if active_enemy_count > 0 {
		r3d.DrawMeshInstanced(
			game_state.assets.enemy_mesh,
			r3d.GetDefaultMaterial(),
			world.enemy_instance_buffer,
			active_enemy_count,
		)
	}

	proj_positions := cast([^]linalg.Vector3f32)r3d.MapInstances(
		world.projectile_instance_buffer,
		{.POSITION},
		false,
	)
	proj_rotations := cast([^]linalg.Quaternionf32)r3d.MapInstances(
		world.projectile_instance_buffer,
		{.ROTATION},
		false,
	)
	proj_colors := cast([^]raylib.Color)r3d.MapInstances(
		world.projectile_instance_buffer,
		{.COLOR},
		false,
	)

	active_proj_count: i32 = 0
	for i in 0 ..< len(world.projectiles) {
		if world.projectiles[i].active {
			proj_positions[active_proj_count] = world.projectiles[i].position
			proj_rotations[active_proj_count] = world.projectiles[i].rotation
			proj_colors[active_proj_count] = raylib.RED
			active_proj_count += 1
		}
	}

	r3d.UnmapInstances(world.projectile_instance_buffer, {.POSITION, .ROTATION, .COLOR})

	if active_proj_count > 0 {
		r3d.DrawMeshInstanced(
			game_state.assets.projectile_mesh,
			r3d.GetDefaultMaterial(),
			world.projectile_instance_buffer,
			active_proj_count,
		)
	}

	r3d.End()

	raylib.BeginMode3D(world.player.camera)
	for p in 0 ..< len(world.player_projectiles) {
		if world.player_projectiles[p].active {
			raylib.DrawSphere(world.player_projectiles[p].position, 0.2, raylib.YELLOW)
		}
	}
	for s in 0 ..< len(world.stasis_fields) {
		if world.stasis_fields[s].active {
			raylib.DrawSphere(
				world.stasis_fields[s].position,
				world.stasis_fields[s].radius,
				raylib.Color{138, 43, 226, 120},
			)
		}
	}
	raylib.EndMode3D()

	raylib.BeginMode2D(game_state.gui_camera)
	draw_crosshair(show_hitmarker = world.hitmarker_timer > 0.0)
	draw_ui(world)
	player_draw_hud(&world.player)

	if world.cards_sys.active {
		cards_draw(&world.cards_sys)
	}

	if world.is_paused {
		raylib.DrawRectangle(
			0,
			0,
			VIRTUAL_WINDOW_WIDTH,
			VIRTUAL_WINDOW_HEIGHT,
			raylib.Color{0, 0, 0, 150},
		)

		raylib.DrawText(
			"PAUSED",
			VIRTUAL_WINDOW_WIDTH / 2 - raylib.MeasureText("PAUSED", 60) / 2,
			200,
			60,
			raylib.WHITE,
		)

		resume_color := world.pause_selected_index == 0 ? raylib.YELLOW : raylib.WHITE
		raylib.DrawText(
			"Resume",
			VIRTUAL_WINDOW_WIDTH / 2 - raylib.MeasureText("Resume", 40) / 2,
			350,
			40,
			resume_color,
		)

		quit_color := world.pause_selected_index == 1 ? raylib.YELLOW : raylib.WHITE
		raylib.DrawText(
			"Quit to Menu",
			VIRTUAL_WINDOW_WIDTH / 2 - raylib.MeasureText("Quit to Menu", 40) / 2,
			420,
			40,
			quit_color,
		)

		cursor_y: i32 = world.pause_selected_index == 0 ? 350 : 420
		raylib.DrawText(">", VIRTUAL_WINDOW_WIDTH / 2 - 150, cursor_y, 40, raylib.YELLOW)
	}

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
	if world.player.hurt_timer > 0.0 {
		alpha_factor := world.player.hurt_timer / 0.25
		flash_alpha := u8(raylib.Clamp(alpha_factor * 100.0, 0.0, 100.0))

		raylib.DrawRectangle(
			0,
			0,
			i32(VIRTUAL_WINDOW_WIDTH),
			i32(VIRTUAL_WINDOW_HEIGHT),
			raylib.Color{255, 0, 0, flash_alpha},
		)
	}

	if world.player.health < 30.0 && world.player.health > 0.0 {
		pulse := (math.sin(f32(raylib.GetTime()) * 10.0) + 1.0) * 0.5
		border_alpha := u8(50.0 + pulse * 100.0)
		border_thickness: f32 = 14.0

		raylib.DrawRectangleLinesEx(
			raylib.Rectangle{0, 0, VIRTUAL_WINDOW_WIDTH, VIRTUAL_WINDOW_HEIGHT},
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
	case .Warning:
		phase_name = "WARNING!"
		total_phase_time = WARNING_TIME
		text_color = raylib.ORANGE
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

	text_x := i32(VIRTUAL_WINDOW_WIDTH / 2.0) - (text_width / 2)
	text_y: i32 = 30

	raylib.DrawText(timer_text, text_x + 3, text_y + 3, font_size, raylib.BLACK)
	raylib.DrawText(timer_text, text_x, text_y, font_size, text_color)

	wave_text := fmt.ctprintf("WAVE %d", world.wave)
	wave_text_width := raylib.MeasureText(wave_text, font_size)
	wave_text_x := i32(VIRTUAL_WINDOW_WIDTH / 2.0) - (wave_text_width / 2)

	raylib.DrawText(wave_text, wave_text_x + 3, 83, font_size, raylib.BLACK)
	raylib.DrawText(wave_text, wave_text_x, 80, font_size, raylib.WHITE)

	bar_width: f32 = 300.0
	bar_height: f32 = 30.0
	bar_x: f32 = 30.0
	bar_y := VIRTUAL_WINDOW_HEIGHT - bar_height - 30.0

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
	r3d.UnloadInstanceBuffer(world.enemy_instance_buffer)
	r3d.UnloadInstanceBuffer(world.projectile_instance_buffer)
}
