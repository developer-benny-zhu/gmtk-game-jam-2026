package game

import "vendor:raylib"

Game_Over :: struct {
	selected_index: int,
}

game_over_init :: proc(game_over: ^Game_Over) {
	game_over.selected_index = 0
	raylib.EnableCursor()
}

game_over_loop :: proc(game_over: ^Game_Over, game_state: ^Game_State) {
	gui_camera_update(&game_state.gui_camera)

	if raylib.IsKeyPressed(.DOWN) || raylib.IsKeyPressed(.S) {
		game_over.selected_index = (game_over.selected_index + 1) % 2
	}
	if raylib.IsKeyPressed(.UP) || raylib.IsKeyPressed(.W) {
		game_over.selected_index = (game_over.selected_index - 1 + 2) % 2
	}

	if raylib.IsKeyPressed(.ENTER) {
		if game_over.selected_index == 0 {
			game_state_switch_scene(game_state, .World)
		} else {
			game_state_switch_scene(game_state, .Main_Menu)
		}
	}

	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)
	raylib.BeginMode2D(game_state.gui_camera)

	title: cstring = "GAME OVER"
	title_width := raylib.MeasureText(title, 60)
	raylib.DrawText(title, VIRTUAL_WINDOW_WIDTH / 2 - title_width / 2, 180, 60, raylib.RED)

	restart_color := game_over.selected_index == 0 ? raylib.YELLOW : raylib.WHITE
	restart_text: cstring = "Restart"
	restart_width := raylib.MeasureText(restart_text, 40)
	raylib.DrawText(
		restart_text,
		VIRTUAL_WINDOW_WIDTH / 2 - restart_width / 2,
		330,
		40,
		restart_color,
	)

	quit_color := game_over.selected_index == 1 ? raylib.YELLOW : raylib.WHITE
	quit_text: cstring = "Quit to Menu"
	quit_width := raylib.MeasureText(quit_text, 40)
	raylib.DrawText(quit_text, VIRTUAL_WINDOW_WIDTH / 2 - quit_width / 2, 400, 40, quit_color)

	cursor_y: i32 = game_over.selected_index == 0 ? 330 : 400
	raylib.DrawText(">", VIRTUAL_WINDOW_WIDTH / 2 - 150, cursor_y, 40, raylib.YELLOW)

	raylib.EndMode2D()
	raylib.EndDrawing()
}
