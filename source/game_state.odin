package game

import "vendor:raylib"

Scene :: enum u8 {
	Credits,
	Main_Menu,
	Splash_Screen,
	World,
}

Game_State :: struct {
	assets:        Assets,
	world:         World,
	splash_screen: Splash_Screen,
	main_menu:     Main_Menu,
	credits:       Credits,
	gui_camera:    raylib.Camera2D,
	scene:         Scene,
}

game_state_init :: proc(game_state: ^Game_State) {
	assets_init(&game_state.assets)
	world_init(&game_state.world)
}

game_state_update :: proc(game_state: ^Game_State) {
	switch game_state.scene {
	case .Splash_Screen:
		splash_screen_update(&game_state.splash_screen, game_state)
	case .World:
		world_update(&game_state.world, game_state)
		world_draw(&game_state.world, game_state)
	case .Main_Menu:
		main_menu_loop(&game_state.main_menu, game_state)
	case .Credits:
		credits_loop(&game_state.credits, game_state)
	}
}

game_state_destroy :: proc(game_state: ^Game_State) {
	assets_destroy(&game_state.assets)
}
