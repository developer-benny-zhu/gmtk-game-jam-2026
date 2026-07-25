package game

import "core:math"
import "core:math/rand"
import "vendor:raylib"

CREDITS_SCROLL_SPEED :: 80.0
CREDITS_START_OFFSET :: 100.0
CREDITS_TITLE_SIZE :: 48
CREDITS_TEXT_SIZE :: 24
CREDITS_FOOTER_SIZE :: 20
CREDITS_LINE_SPACING :: 40.0
CREDITS_TITLE_SPACING :: 80.0
CREDITS_FOOTER_SPACING :: 60.0

Credits :: struct {
	scroll_y:            f32,
	stars:               [STAR_COUNT]Star,
	shooting_star:       Shooting_Star,
	shooting_star_timer: f32,
	nebula_offset_a:     f32,
	nebula_offset_b:     f32,
}

credits_init :: proc(credits: ^Credits) {
	credits.scroll_y = 0

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

		credits.stars[i] = Star {
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

	credits.shooting_star_timer = SHOOTING_STAR_INTERVAL
}

draw_space_background_credits :: proc(credits: ^Credits) {
	raylib.ClearBackground(raylib.Color{4, 5, 18, 255})

	credits.nebula_offset_a += raylib.GetFrameTime() * 4
	credits.nebula_offset_b += raylib.GetFrameTime() * 2

	raylib.DrawCircle(
		180 + i32(math.sin(credits.nebula_offset_a * 0.2) * 25),
		170,
		220,
		raylib.Fade(raylib.Color{70, 40, 170, 255}, 0.08),
	)

	raylib.DrawCircle(
		820 + i32(math.cos(credits.nebula_offset_b * 0.2) * 20),
		470,
		260,
		raylib.Fade(raylib.Color{30, 120, 255, 255}, 0.06),
	)

	raylib.DrawCircle(560, 260, 180, raylib.Fade(raylib.Color{180, 70, 255, 255}, 0.03))

	time := f32(raylib.GetTime())

	for i in 0 ..< STAR_COUNT {
		star := &credits.stars[i]
		brightness := star.alpha * (0.6 + 0.4 * math.sin(time * 3.0 + star.twinkle))
		raylib.DrawCircleV(star.position, star.radius, raylib.Fade(star.color, brightness))
	}

	if credits.shooting_star.active {
		end := raylib.Vector2 {
			credits.shooting_star.position.x - 70,
			credits.shooting_star.position.y + 25,
		}
		raylib.DrawLineEx(credits.shooting_star.position, end, 2, raylib.WHITE)
	}
}

credits_draw :: proc(credits: ^Credits, game_state: Game_State) {
	raylib.BeginDrawing()
	raylib.BeginMode2D(game_state.gui_camera)

	draw_space_background_credits(credits)

	initial_y := f32(VIRTUAL_WINDOW_HEIGHT) + CREDITS_START_OFFSET
	title_y := initial_y - credits.scroll_y

	draw_text(
		"CREDITS",
		{VIRTUAL_WINDOW_CENTER_X, title_y},
		raylib.GetFontDefault(),
		CREDITS_TITLE_SIZE,
		.Center,
	)

	credits_lines := []string {
		"Lead Programmer",
		"COOKIE POLICE",
		"",
		"Programming Language",
		"Odin",
		"",
		"Special Thanks",
		"Ginger Bill",
		"For creating the Odin Programming Language",
		"",
		"Raysan",
		"For creating the Raylib library",
		"",
		"Kenney",
		"For providing Kenney Assets",
		"",
		"Thank You For Playing!",
	}

	start_y := title_y + CREDITS_TITLE_SPACING

	for line, i in credits_lines {
		draw_text(
			cstring(raw_data(line)),
			{VIRTUAL_WINDOW_CENTER_X, start_y + f32(i) * CREDITS_LINE_SPACING},
			raylib.GetFontDefault(),
			CREDITS_TEXT_SIZE,
			.Center,
		)
	}

	draw_text(
		"Press ESC to Return",
		{
			VIRTUAL_WINDOW_CENTER_X,
			start_y + f32(len(credits_lines)) * CREDITS_LINE_SPACING + CREDITS_FOOTER_SPACING,
		},
		raylib.GetFontDefault(),
		CREDITS_FOOTER_SIZE,
		.Center,
	)

	raylib.EndMode2D()
	raylib.EndDrawing()
}

credits_update :: proc(credits: ^Credits, game_state: ^Game_State) {
	gui_camera_update(&game_state.gui_camera)

	dt := raylib.GetFrameTime()
	credits.scroll_y += CREDITS_SCROLL_SPEED * dt

	for i in 0 ..< STAR_COUNT {
		star := &credits.stars[i]

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

	credits.shooting_star_timer -= dt

	if !credits.shooting_star.active && credits.shooting_star_timer <= 0 {
		credits.shooting_star.active = true
		credits.shooting_star.position = {
			f32(rand.int_range(VIRTUAL_WINDOW_WIDTH / 2, VIRTUAL_WINDOW_WIDTH)),
			f32(rand.int_range(0, VIRTUAL_WINDOW_HEIGHT / 3)),
		}
		credits.shooting_star.velocity = {-550, 190}
		credits.shooting_star.life = 1.2
		credits.shooting_star_timer = SHOOTING_STAR_INTERVAL + f32(rand.int_range(0, 4))
	}

	if credits.shooting_star.active {
		credits.shooting_star.position += credits.shooting_star.velocity * dt
		credits.shooting_star.life -= dt

		if credits.shooting_star.life <= 0 {
			credits.shooting_star.active = false
		}
	}

	if raylib.IsKeyPressed(.ESCAPE) {
		game_state_switch_scene(game_state, .Main_Menu)
	}
}

credits_loop :: proc(credits: ^Credits, game_state: ^Game_State) {
	credits_update(credits, game_state)
	credits_draw(credits, game_state^)
}
