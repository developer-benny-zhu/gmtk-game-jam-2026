package game

import "core:math"
import "core:math/rand"
import "vendor:raylib"

STAR_COUNT :: 300
SHOOTING_STAR_INTERVAL :: 4.0

Star :: struct {
	position: raylib.Vector2,
	speed:    f32,
	radius:   f32,
	alpha:    f32,
	layer:    u8,
	twinkle:  f32,
	color:    raylib.Color,
}

Shooting_Star :: struct {
	active:   bool,
	position: raylib.Vector2,
	velocity: raylib.Vector2,
	life:     f32,
}

Main_Menu :: struct {
	selected_index:      int,
	cursor_y:            f32,
	stars:               [STAR_COUNT]Star,
	shooting_star:       Shooting_Star,
	shooting_star_timer: f32,
	nebula_offset_a:     f32,
	nebula_offset_b:     f32,
}

main_menu_init :: proc(menu: ^Main_Menu, game_state: Game_State) {
	raylib.PlayMusicStream(game_state.assets.main_menu_music)
	menu.selected_index = 0
	menu.cursor_y = 250

	for i in 0 ..< STAR_COUNT {
		layer := u8(rand.int_range(0, 3))

		speed: f32

		switch layer {
		case 0:
			speed = 2
		case 1:
			speed = 5
		case:
			speed = 10
		}

		star_color := raylib.WHITE
		color_roll := rand.int_range(0, 12)
		if color_roll == 0 {
			star_color = raylib.Color{180, 210, 255, 255}
		} else if color_roll == 1 {
			star_color = raylib.Color{255, 220, 180, 255}
		} else if color_roll == 2 {
			star_color = raylib.Color{255, 170, 170, 255}
		}

		menu.stars[i] = Star {
			position = {
				f32(rand.int_range(0, VIRTUAL_WINDOW_WIDTH)),
				f32(rand.int_range(0, VIRTUAL_WINDOW_HEIGHT)),
			},
			speed    = speed,
			radius   = f32(rand.int_range(1, 3)) * 0.8,
			alpha    = f32(rand.int_range(60, 220)) / 255.0,
			layer    = layer,
			twinkle  = f32(rand.int_range(0, 628)) / 100.0,
			color    = star_color,
		}
	}

	menu.shooting_star_timer = SHOOTING_STAR_INTERVAL
}

draw_space_background :: proc(menu: ^Main_Menu) {
	raylib.ClearBackground(raylib.Color{4, 5, 18, 255})

	menu.nebula_offset_a += raylib.GetFrameTime() * 4
	menu.nebula_offset_b += raylib.GetFrameTime() * 2

	raylib.DrawCircle(
		180 + i32(math.sin(menu.nebula_offset_a * 0.2) * 25),
		170,
		220,
		raylib.Fade(raylib.Color{70, 40, 170, 255}, 0.08),
	)

	raylib.DrawCircle(
		820 + i32(math.cos(menu.nebula_offset_b * 0.2) * 20),
		470,
		260,
		raylib.Fade(raylib.Color{30, 120, 255, 255}, 0.06),
	)

	raylib.DrawCircle(560, 260, 180, raylib.Fade(raylib.Color{180, 70, 255, 255}, 0.03))

	time := f32(raylib.GetTime())

	for i in 0 ..< STAR_COUNT {
		star := &menu.stars[i]
		brightness := star.alpha * (0.6 + 0.4 * math.sin(time * 3.0 + star.twinkle))
		raylib.DrawCircleV(star.position, star.radius, raylib.Fade(star.color, brightness))
	}

	if menu.shooting_star.active {
		end := raylib.Vector2 {
			menu.shooting_star.position.x - 70,
			menu.shooting_star.position.y + 25,
		}
		raylib.DrawLineEx(menu.shooting_star.position, end, 2, raylib.WHITE)
	}
}

main_menu_update :: proc(main_menu: ^Main_Menu, game_state: ^Game_State) {
	raylib.UpdateMusicStream(game_state.assets.main_menu_music)
	gui_camera_update(&game_state.gui_camera)

	dt := raylib.GetFrameTime()

	for i in 0 ..< STAR_COUNT {
		star := &main_menu.stars[i]

		star.position.y += star.speed * dt

		switch star.layer {
		case 0:
			star.position.x += math.sin(f32(raylib.GetTime()) * 0.15 + star.twinkle) * 0.03
		case 1:
			star.position.x += math.cos(f32(raylib.GetTime()) * 0.25 + star.twinkle) * 0.06
		case:
			star.position.x += math.sin(f32(raylib.GetTime()) * 0.35 + star.twinkle) * 0.10
		}

		if star.position.y > f32(VIRTUAL_WINDOW_HEIGHT) {
			star.position.y = 0
			star.position.x = f32(rand.int_range(0, VIRTUAL_WINDOW_WIDTH))
		}

		if star.position.x < 0 {
			star.position.x += f32(VIRTUAL_WINDOW_WIDTH)
		}

		if star.position.x > f32(VIRTUAL_WINDOW_WIDTH) {
			star.position.x -= f32(VIRTUAL_WINDOW_WIDTH)
		}
	}

	main_menu.shooting_star_timer -= dt

	if !main_menu.shooting_star.active && main_menu.shooting_star_timer <= 0 {
		main_menu.shooting_star.active = true
		main_menu.shooting_star.position = {
			f32(rand.int_range(VIRTUAL_WINDOW_WIDTH / 2, VIRTUAL_WINDOW_WIDTH)),
			f32(rand.int_range(0, VIRTUAL_WINDOW_HEIGHT / 3)),
		}
		main_menu.shooting_star.velocity = {-550, 190}
		main_menu.shooting_star.life = 1.2
		main_menu.shooting_star_timer = SHOOTING_STAR_INTERVAL + f32(rand.int_range(0, 4))
	}

	if main_menu.shooting_star.active {
		main_menu.shooting_star.position += main_menu.shooting_star.velocity * dt
		main_menu.shooting_star.life -= dt

		if main_menu.shooting_star.life <= 0 {
			main_menu.shooting_star.active = false
		}
	}

	total_options :: 3
	start_y: f32 = 250
	spacing: f32 = 50

	if raylib.IsKeyPressed(.DOWN) || raylib.IsKeyPressed(.S) {
		main_menu.selected_index = (main_menu.selected_index + 1) % total_options
	}

	if raylib.IsKeyPressed(.UP) || raylib.IsKeyPressed(.W) {
		main_menu.selected_index = (main_menu.selected_index - 1 + total_options) % total_options
	}

	target_y := start_y + f32(main_menu.selected_index) * spacing

	main_menu.cursor_y += (target_y - main_menu.cursor_y) * (1.0 - math.exp(-15.0 * dt))

	if raylib.IsKeyPressed(.ENTER) {
		switch main_menu.selected_index {
		case 0:
			game_state_switch_scene(game_state, .World)
		case 1:
			game_state_switch_scene(game_state, .Credits)
		case 2:
			run = false
		}
	}
}

main_menu_draw :: proc(main_menu: ^Main_Menu, game_state: Game_State) {
	raylib.BeginDrawing()
	raylib.BeginMode2D(game_state.gui_camera)

	draw_space_background(main_menu)

	title_pos := raylib.Vector2{f32(VIRTUAL_WINDOW_CENTER_X / 2), 100}

	glow := 0.6 + 0.4 * (0.5 + 0.5 * math.sin(raylib.GetTime() * 2.0))
	glow_color := raylib.Fade(raylib.Color{120, 180, 255, 255}, f32(glow) * 0.35)

	draw_text(
		TITLE,
		{title_pos.x - 2, title_pos.y},
		raylib.GetFontDefault(),
		48,
		.Center,
		0,
		glow_color,
	)

	draw_text(
		TITLE,
		{title_pos.x + 2, title_pos.y},
		raylib.GetFontDefault(),
		48,
		.Center,
		0,
		glow_color,
	)

	draw_text(
		TITLE,
		{title_pos.x, title_pos.y - 2},
		raylib.GetFontDefault(),
		48,
		.Center,
		0,
		glow_color,
	)

	draw_text(
		TITLE,
		{title_pos.x, title_pos.y + 2},
		raylib.GetFontDefault(),
		48,
		.Center,
		0,
		glow_color,
	)

	draw_text(TITLE, {title_pos.x, title_pos.y}, raylib.GetFontDefault(), 48, .Center)

	menu_options := []string{"Start", "Credits", "Quit Game"}

	start_y: f32 = 250
	spacing: f32 = 50

	cursor_x := (VIRTUAL_WINDOW_CENTER_X / 2) - 110

	cursor_alpha := 0.7 + 0.3 * (0.5 + 0.5 * math.sin(raylib.GetTime() * 8.0))

	draw_text(
		">",
		{f32(cursor_x), main_menu.cursor_y},
		raylib.GetFontDefault(),
		30,
		.Center,
		0,
		raylib.Fade(raylib.WHITE, f32(cursor_alpha)),
	)

	for option, i in menu_options {
		pos_y := start_y + f32(i) * spacing

		selected := i == main_menu.selected_index

		color := raylib.WHITE
		size: f32 = 32

		if selected {
			color = raylib.Color{180, 220, 255, 255}
			size = 36

			glow := raylib.Fade(raylib.Color{80, 140, 255, 255}, 0.25)

			draw_text(
				cstring(raw_data(option)),
				{VIRTUAL_WINDOW_CENTER_X / 2 - 2, pos_y},
				raylib.GetFontDefault(),
				size,
				.Center,
				0,
				glow,
			)

			draw_text(
				cstring(raw_data(option)),
				{VIRTUAL_WINDOW_CENTER_X / 2 + 2, pos_y},
				raylib.GetFontDefault(),
				size,
				.Center,
				0,
				glow,
			)
		}

		draw_text(
			cstring(raw_data(option)),
			{VIRTUAL_WINDOW_CENTER_X / 2, pos_y},
			raylib.GetFontDefault(),
			size,
			.Center,
			0,
			color,
		)
	}

	raylib.EndMode2D()
	raylib.EndDrawing()
}

main_menu_loop :: proc(main_menu: ^Main_Menu, game_state: ^Game_State) {
	main_menu_update(main_menu, game_state)
	main_menu_draw(main_menu, game_state^)
}

main_menu_destroy :: proc(game_state: Game_State) {
	raylib.StopMusicStream(game_state.assets.main_menu_music)
}
