package game

import "core:math"
import "vendor:raylib"

Scene :: enum u8 {
	Splash_Screen,
	Main_Menu,
	World,
	Credits,
}

Fade_State :: enum u8 {
	None,
	Fading_Out,
	Fading_In,
}

Game_State :: struct {
	assets:           Assets,
	world:            World,
	splash_screen:    Splash_Screen,
	main_menu:        Main_Menu,
	credits:          Credits,
	gui_camera:       raylib.Camera2D,
	scene:            Scene,
	next_scene:       Scene,
	fade_state:       Fade_State,
	fade_alpha:       f32,
	is_transitioning: bool,
}

game_state_switch_scene :: proc(game_state: ^Game_State, $scene: Scene) {
	game_state.next_scene = scene
	game_state.fade_state = .Fading_Out
	game_state.is_transitioning = true
}

_execute_scene_switch :: proc(game_state: ^Game_State, scene: Scene) {
	#partial switch scene {
	case .World:
		raylib.DisableCursor()
		world_init(&game_state.world)
		game_state.scene = .World
	case .Main_Menu:
		raylib.EnableCursor()
		main_menu_init(&game_state.main_menu, game_state^)
		game_state.scene = .Main_Menu
	case .Credits:
		raylib.EnableCursor()
		credits_init(&game_state.credits)
		game_state.scene = .Credits
	case .Splash_Screen:
		raylib.DisableCursor()
		game_state.scene = .Splash_Screen
	}
	if game_state.scene != .Main_Menu && scene != .Main_Menu {
	}
}

game_state_init :: proc(game_state: ^Game_State) {
	assets_init(&game_state.assets)
	game_state.scene = .Splash_Screen
	game_state.fade_alpha = 0.0
	game_state.fade_state = .None
	game_state.is_transitioning = false
	game_state_switch_scene(game_state, .Splash_Screen)
}

game_state_update :: proc(game_state: ^Game_State) {
	delta := raylib.GetFrameTime()

	// Handle Fade Transitions between scenes
	if game_state.fade_state != .None {
		if game_state.fade_state == .Fading_Out {
			game_state.fade_alpha += delta * 2.0
			if game_state.fade_alpha >= 1.0 {
				game_state.fade_alpha = 1.0
				_execute_scene_switch(game_state, game_state.next_scene)
				game_state.fade_state = .Fading_In
			}
		} else if game_state.fade_state == .Fading_In {
			game_state.fade_alpha -= delta * 2.0
			if game_state.fade_alpha <= 0.0 {
				game_state.fade_alpha = 0.0
				game_state.fade_state = .None
				game_state.is_transitioning = false
			}
		}
	}

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

	// Render global fade overlay if transition is active
	if game_state.fade_state != .None {
		raylib.BeginMode2D(game_state.gui_camera)
		alpha_val := u8(raylib.Clamp(game_state.fade_alpha * 255.0, 0.0, 255.0))
		raylib.DrawRectangle(
			0,
			0,
			VIRTUAL_WINDOW_WIDTH,
			VIRTUAL_WINDOW_HEIGHT,
			raylib.Color{0, 0, 0, alpha_val},
		)
		raylib.EndMode2D()
	}
}

game_state_destroy :: proc(game_state: ^Game_State) {
	assets_destroy(&game_state.assets)
}
