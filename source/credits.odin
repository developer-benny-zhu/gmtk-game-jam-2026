package game

import "core:math"
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
	scroll_y: f32,
}

credits_init :: proc(credits: ^Credits) {
	credits.scroll_y = 0
}

credits_draw :: proc(credits: Credits, game_state: Game_State) {
	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)
	raylib.BeginMode2D(game_state.gui_camera)

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

	credits.scroll_y += CREDITS_SCROLL_SPEED * raylib.GetFrameTime()

	if raylib.IsKeyPressed(.ESCAPE) {
	}
}

credits_loop :: proc(credits: ^Credits, game_state: ^Game_State) {
	credits_update(credits, game_state)
	credits_draw(credits^, game_state^)
}
