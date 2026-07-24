package game

import "vendor:raylib"


draw_crosshair :: proc(spacing: f32 = 5, length: f32 = 10, thickness: f32 = 2, color := raylib.WHITE) {

	// Top line
	raylib.DrawLineEx(
		{VIRTUAL_WINDOW_CENTER_X, VIRTUAL_WINDOW_CENTER_Y - spacing},
		{VIRTUAL_WINDOW_CENTER_X, VIRTUAL_WINDOW_CENTER_Y - spacing - length},
		thickness,
		color,
	)
	// Left line
	raylib.DrawLineEx(
		{VIRTUAL_WINDOW_CENTER_X - spacing, VIRTUAL_WINDOW_CENTER_Y},
		{VIRTUAL_WINDOW_CENTER_X - spacing - length, VIRTUAL_WINDOW_CENTER_Y},
		thickness,
		color,
	)
	// Right line
	raylib.DrawLineEx(
		{VIRTUAL_WINDOW_CENTER_X + spacing, VIRTUAL_WINDOW_CENTER_Y},
		{VIRTUAL_WINDOW_CENTER_X + spacing + length, VIRTUAL_WINDOW_CENTER_Y},
		thickness,
		color,
	)
	// Bottom line
	raylib.DrawLineEx(
		{VIRTUAL_WINDOW_CENTER_X, VIRTUAL_WINDOW_CENTER_Y + spacing},
		{VIRTUAL_WINDOW_CENTER_X, VIRTUAL_WINDOW_CENTER_Y + spacing + length},
		thickness,
		color,
	)


}
