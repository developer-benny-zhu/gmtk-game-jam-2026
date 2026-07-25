package game

import "core:c"
import "core:math"
import "vendor/r3d"
import "vendor:raylib"

VIRTUAL_WINDOW_WIDTH :: 1152
VIRTUAL_WINDOW_HEIGHT :: 648
VIRTUAL_WINDOW_CENTER_X :: VIRTUAL_WINDOW_WIDTH / 2
VIRTUAL_WINDOW_CENTER_Y :: VIRTUAL_WINDOW_HEIGHT / 2
LETTER_BOX_COLOR :: raylib.BLACK
TITLE :: "Stellar"


game_state: Game_State
run: bool

init :: proc() {
	run = true
	raylib.SetConfigFlags({.WINDOW_RESIZABLE, .WINDOW_HIGHDPI, .VSYNC_HINT})
	raylib.InitWindow(VIRTUAL_WINDOW_WIDTH, VIRTUAL_WINDOW_HEIGHT, TITLE)
	raylib.InitAudioDevice()
	r3d.Init(VIRTUAL_WINDOW_WIDTH, VIRTUAL_WINDOW_HEIGHT)
	game_state_init(&game_state)
	raylib.SetExitKey(nil)
}

update :: proc() {
	game_state_update(&game_state)
	free_all(context.temp_allocator)
}

parent_window_size_changed :: proc(w, h: int) {
	raylib.SetWindowSize(raylib.GetRenderWidth(), raylib.GetRenderHeight())
	r3d.SetResolution(raylib.GetRenderWidth(), raylib.GetRenderHeight())
}

shutdown :: proc() {
	game_state_destroy(&game_state)
	r3d.Close()
	raylib.CloseWindow()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		if raylib.WindowShouldClose() {
			run = false
		}
	}
	return run
}
