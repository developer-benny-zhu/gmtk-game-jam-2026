package game

import "vendor:raylib"

draw_crosshair :: proc(
	spacing: f32 = 5,
	length: f32 = 10,
	thickness: f32 = 2,
	color := raylib.WHITE,
	show_hitmarker: bool = false,
) {
	raylib.DrawLineEx(
		{VIRTUAL_WINDOW_CENTER_X, VIRTUAL_WINDOW_CENTER_Y - spacing},
		{VIRTUAL_WINDOW_CENTER_X, VIRTUAL_WINDOW_CENTER_Y - spacing - length},
		thickness,
		color,
	)
	raylib.DrawLineEx(
		{VIRTUAL_WINDOW_CENTER_X - spacing, VIRTUAL_WINDOW_CENTER_Y},
		{VIRTUAL_WINDOW_CENTER_X - spacing - length, VIRTUAL_WINDOW_CENTER_Y},
		thickness,
		color,
	)
	raylib.DrawLineEx(
		{VIRTUAL_WINDOW_CENTER_X + spacing, VIRTUAL_WINDOW_CENTER_Y},
		{VIRTUAL_WINDOW_CENTER_X + spacing + length, VIRTUAL_WINDOW_CENTER_Y},
		thickness,
		color,
	)
	raylib.DrawLineEx(
		{VIRTUAL_WINDOW_CENTER_X, VIRTUAL_WINDOW_CENTER_Y + spacing},
		{VIRTUAL_WINDOW_CENTER_X, VIRTUAL_WINDOW_CENTER_Y + spacing + length},
		thickness,
		color,
	)

	if show_hitmarker {
		hm_spacing: f32 = 4
		hm_length: f32 = 8
		raylib.DrawLineEx(
			{VIRTUAL_WINDOW_CENTER_X - hm_spacing, VIRTUAL_WINDOW_CENTER_Y - hm_spacing},
			{
				VIRTUAL_WINDOW_CENTER_X - hm_spacing - hm_length,
				VIRTUAL_WINDOW_CENTER_Y - hm_spacing - hm_length,
			},
			thickness,
			raylib.WHITE,
		)
		raylib.DrawLineEx(
			{VIRTUAL_WINDOW_CENTER_X + hm_spacing, VIRTUAL_WINDOW_CENTER_Y - hm_spacing},
			{
				VIRTUAL_WINDOW_CENTER_X + hm_spacing + hm_length,
				VIRTUAL_WINDOW_CENTER_Y - hm_spacing - hm_length,
			},
			thickness,
			raylib.WHITE,
		)
		raylib.DrawLineEx(
			{VIRTUAL_WINDOW_CENTER_X - hm_spacing, VIRTUAL_WINDOW_CENTER_Y + hm_spacing},
			{
				VIRTUAL_WINDOW_CENTER_X - hm_spacing - hm_length,
				VIRTUAL_WINDOW_CENTER_Y + hm_spacing + hm_length,
			},
			thickness,
			raylib.WHITE,
		)
		raylib.DrawLineEx(
			{VIRTUAL_WINDOW_CENTER_X + hm_spacing, VIRTUAL_WINDOW_CENTER_Y + hm_spacing},
			{
				VIRTUAL_WINDOW_CENTER_X + hm_spacing + hm_length,
				VIRTUAL_WINDOW_CENTER_Y + hm_spacing + hm_length,
			},
			thickness,
			raylib.WHITE,
		)
	}
}
