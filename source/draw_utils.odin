package game

import "core:math/linalg"
import "vendor:raylib"

Origin :: enum {
	Center,
	Top_Left,
	Top_Right,
	Bottom_Left,
	Bottom_Right,
}

draw_texture_from_tile_sheet :: proc(
	texture: raylib.Texture2D,
	tile_size: linalg.Vector2f32,
	tile_coordinate: linalg.Vector2f32,
	position: linalg.Vector2f32,
	$origin: Origin,
	rotation: f32 = 0,
	scale := linalg.Vector2f32{1, 1},
	tint := raylib.WHITE,
) {

	source := raylib.Rectangle {
		tile_coordinate.x * tile_size.x,
		tile_coordinate.y * tile_size.y,
		tile_size.x,
		tile_size.y,
	}
	draw_texture(texture, source, position, origin, rotation, scale, tint)
}


draw_texture :: proc(
	texture: raylib.Texture2D,
	source: raylib.Rectangle,
	position: linalg.Vector2f32,
	$origin: Origin,
	rotation: f32 = 0,
	scale := linalg.Vector2f32{1, 1},
	tint := raylib.WHITE,
) {
	destination := raylib.Rectangle {
		position.x,
		position.y,
		source.width * scale.x,
		source.height * scale.y,
	}
	origin_value: linalg.Vector2f32
	when origin == Origin.Center {
		origin_value = {destination.width / 2, destination.height / 2}
	}
	when origin == Origin.Top_Left {
		origin_value = {0, 0}
	}
	when origin == Origin.Top_Right {
		origin_value = {destination.width, 0}
	}
	when origin == Origin.Bottom_Left {
		origin_value = {0, destination.height}
	}
	when origin == Origin.Bottom_Right {
		origin_value = {destination.width, destination.height}
	}
	raylib.DrawTexturePro(texture, source, destination, origin_value, rotation, tint)
}

draw_text :: proc(
	text: cstring,
	position: linalg.Vector2f32,
	font: raylib.Font,
	font_size: f32,
	$origin: Origin,
	rotation: f32 = 0,
	tint := raylib.WHITE,
	spacing: f32 = 2,
) {
	text_size := raylib.MeasureTextEx(font, text, font_size, spacing)
	when origin == .Center {
		raylib.DrawTextPro(font, text, position, text_size / 2, rotation, font_size, spacing, tint)
	}
	when origin == .Top_Left {
		raylib.DrawTextPro(font, text, position, {0, 0}, rotation, font_size, spacing, tint)
	}
	when origin == .Top_Right {
		raylib.DrawTextPro(
			font,
			text,
			position,
			{text_size.x, 0},
			rotation,
			font_size,
			spacing,
			tint,
		)
	}
	when origin == .Bottom_Left {
		raylib.DrawTextPro(
			font,
			text,
			position,
			{0, text_size.y},
			rotation,
			font_size,
			spacing,
			tint,
		)
	}
	when origin == .Bottom_Right {
		raylib.DrawTextPro(font, text, position, text_size, rotation, font_size, spacing, tint)
	}
}