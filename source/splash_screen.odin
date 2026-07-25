package game

import "core:c"
import "core:math"
import "vendor:raylib"

ODIN_SEGMENT_START_TIME :: 0
ODIN_SEGMENT_END_TIME :: 2
ODIN_SEGMENT_TEXT :: "Made With Odin Programming Language"

RAYLIB_SEGMENT_START_TIME :: 2
RAYLIB_SEGMENT_END_TIME :: 4
RAYLIB_SEGMENT_TEXT :: "Made With Raylib"

CREATOR_SEGMENT_START_TIME :: 4
CREATOR_SEGMENT_END_TIME :: 6
CREATOR_SEGMENT_TEXT :: "Made By COOKIE POLICE"

GAME_NAME_SEGMENT_START_TIME :: 6
GAME_NAME_SEGMENT_END_TIME :: 8
GAME_NAME_SEGMENT_TEXT :: "GMTK Game Jam 2026"

SEGMENT_TRANSITION_DURATION :: 0.3

Splash_Screen :: struct {
	current_time: f32,
}

splash_screen_update :: proc(splash_screen: ^Splash_Screen, game_state: ^Game_State) {
	gui_camera_update(&game_state.gui_camera)
	splash_screen.current_time += raylib.GetFrameTime()

	text: cstring
	segment_start: f32
	segment_end: f32

	switch splash_screen.current_time {
	case ODIN_SEGMENT_START_TIME ..< ODIN_SEGMENT_END_TIME:
		text = ODIN_SEGMENT_TEXT
		segment_start = ODIN_SEGMENT_START_TIME
		segment_end = ODIN_SEGMENT_END_TIME

	case RAYLIB_SEGMENT_START_TIME ..< RAYLIB_SEGMENT_END_TIME:
		text = RAYLIB_SEGMENT_TEXT
		segment_start = RAYLIB_SEGMENT_START_TIME
		segment_end = RAYLIB_SEGMENT_END_TIME

	case CREATOR_SEGMENT_START_TIME ..< CREATOR_SEGMENT_END_TIME:
		text = CREATOR_SEGMENT_TEXT
		segment_start = CREATOR_SEGMENT_START_TIME
		segment_end = CREATOR_SEGMENT_END_TIME

	case GAME_NAME_SEGMENT_START_TIME ..= GAME_NAME_SEGMENT_END_TIME:
		text = GAME_NAME_SEGMENT_TEXT
		segment_start = GAME_NAME_SEGMENT_START_TIME
		segment_end = GAME_NAME_SEGMENT_END_TIME
	case:
		game_state_switch_scene(game_state, .Main_Menu)
	}

	tint := raylib.WHITE
	update_segment_fade(
		&tint,
		splash_screen.current_time,
		segment_start,
		segment_end,
		SEGMENT_TRANSITION_DURATION,
	)

	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)
	raylib.BeginMode2D(game_state.gui_camera)

	draw_text(
		text,
		{VIRTUAL_WINDOW_CENTER_X, VIRTUAL_WINDOW_CENTER_Y},
		raylib.GetFontDefault(),
		32,
		.Center,
		tint = tint,
	)

	raylib.EndMode2D()
	raylib.EndDrawing()
}

update_fade_in :: proc(color: ^raylib.Color, current_time: f32, start_time: f32, end_time: f32) {
	assert(start_time != end_time)
	duration := end_time - start_time
	elapsed := current_time - start_time
	t := math.clamp(elapsed / duration, 0, 1)
	color.a = u8(math.lerp(f32(0), f32(255), t))
}

update_fade_out :: proc(color: ^raylib.Color, current_time: f32, start_time: f32, end_time: f32) {
	assert(start_time != end_time)
	duration := end_time - start_time
	elapsed := current_time - start_time
	t := math.clamp(elapsed / duration, 0, 1)
	color.a = u8(math.lerp(f32(255), f32(0), t))
}
update_segment_fade :: proc(
	color: ^raylib.Color,
	current_time: f32,
	segment_start_time: f32,
	segment_end_time: f32,
	segment_transition_duration: f32,
) {
	fade_in_end := segment_start_time + segment_transition_duration
	fade_out_start := segment_end_time - segment_transition_duration

	if current_time < fade_in_end {
		update_fade_in(color, current_time, segment_start_time, fade_in_end)
	} else if current_time > fade_out_start {
		update_fade_out(color, current_time, fade_out_start, segment_end_time)
	} else {
		color.a = 255
	}
}
