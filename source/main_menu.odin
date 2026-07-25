package game

import "core:math"
import "vendor:raylib"

Main_Menu :: struct {
	selected_index: int,
	cursor_y:       f32,
}

main_menu_draw :: proc(main_menu: Main_Menu, game_state: Game_State) {
	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)
	raylib.BeginMode2D(game_state.gui_camera)

	draw_text(TITLE, {VIRTUAL_WINDOW_CENTER_X / 2, 100}, raylib.GetFontDefault(), 48, .Center)

	menu_options := []string{"Start", "Options", "Credits", "Quit game"}
	start_y: f32 = 250
	spacing: f32 = 50

	cursor_x := (VIRTUAL_WINDOW_CENTER_X / 2) - 100
	draw_text("x", {f32(cursor_x), main_menu.cursor_y}, raylib.GetFontDefault(), 24, .Center)

	for option, i in menu_options {
		pos_y := start_y + (f32(i) * spacing)
		draw_text(
			cstring(raw_data(option)),
			{VIRTUAL_WINDOW_CENTER_X / 2, pos_y},
			raylib.GetFontDefault(),
			32,
			.Center,
		)
	}

	raylib.EndMode2D()
	raylib.EndDrawing()
}

main_menu_update :: proc(main_menu: ^Main_Menu, game_state: ^Game_State) {
	gui_camera_update(&game_state.gui_camera)

	total_options :: 4
	start_y: f32 = 250
	spacing: f32 = 50

	if raylib.IsKeyPressed(.DOWN) || raylib.IsKeyPressed(.S) {
		main_menu.selected_index = (main_menu.selected_index + 1) % total_options
	}
	if raylib.IsKeyPressed(.UP) || raylib.IsKeyPressed(.W) {
		main_menu.selected_index = (main_menu.selected_index - 1 + total_options) % total_options
	}

	target_y := start_y + (f32(main_menu.selected_index) * spacing)
	main_menu.cursor_y +=
		(target_y - main_menu.cursor_y) * (1.0 - math.exp(-15.0 * raylib.GetFrameTime()))

	if raylib.IsKeyPressed(.ENTER) {
		switch main_menu.selected_index {
		case 0:
		case 1:
		case 2:
		case 3:
		}
	}
}

main_menu_loop :: proc(main_menu: ^Main_Menu, game_state: ^Game_State) {
	main_menu_update(main_menu, game_state)
	main_menu_draw(main_menu^, game_state^)
}
