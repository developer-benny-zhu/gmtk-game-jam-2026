package game

import "core:math"
import "core:math/rand"
import "vendor:raylib"

Card_State :: enum {
	Descending,
	Paused,
	Flipping,
	Idle,
}

Card :: struct {
	kind:       Powerup_Kind,
	rect:       raylib.Rectangle,
	y_offset:   f32,
	flip_angle: f32,
}

Cards_System :: struct {
	active:  bool,
	timer:   f32,
	state:   Card_State,
	choices: [3]Card,
}

cards_init_for_wave :: proc(sys: ^Cards_System) {
	sys.active = true
	sys.timer = 0.0
	sys.state = .Descending

	for i in 0 ..< 3 {
		sys.choices[i] = Card {
			kind       = Powerup_Kind(rand.int_range(0, len(Powerup_Kind))),
			y_offset   = -400.0,
			flip_angle = 180.0,
		}
	}
	raylib.EnableCursor()
}
cards_update :: proc(sys: ^Cards_System, world: ^World, game_state: ^Game_State) {
	delta := raylib.GetFrameTime()
	sys.timer += delta

	spacing: f32 = 250.0
	start_x := f32(VIRTUAL_WINDOW_WIDTH) / 2.0 - spacing

	for i in 0 ..< 3 {
		sys.choices[i].rect = raylib.Rectangle {
			start_x + f32(i) * spacing - 100,
			sys.choices[i].y_offset,
			200,
			300,
		}
	}

	switch sys.state {
	case .Descending:
		for i in 0 ..< 3 {
			sys.choices[i].y_offset = math.lerp(
				sys.choices[i].y_offset,
				f32(VIRTUAL_WINDOW_HEIGHT) / 2.0 - 150.0,
				delta * 5.0,
			)
		}
		if sys.timer > 1.5 {
			sys.state = .Paused
			sys.timer = 0.0
		}
	case .Paused:
		if sys.timer > 0.5 {
			sys.state = .Flipping
			sys.timer = 0.0
		}
	case .Flipping:
		for i in 0 ..< 3 {
			sys.choices[i].flip_angle = math.lerp(sys.choices[i].flip_angle, 0.0, delta * 8.0)
		}
		if sys.timer > 1.0 {
			sys.state = .Idle
		}
	case .Idle:
		scale_x := f32(raylib.GetScreenWidth()) / f32(VIRTUAL_WINDOW_WIDTH)
		scale_y := f32(raylib.GetScreenHeight()) / f32(VIRTUAL_WINDOW_HEIGHT)
		screen_mouse := raylib.GetMousePosition()
		mouse_pos := raylib.Vector2{screen_mouse.x / scale_x, screen_mouse.y / scale_y}

		if raylib.IsMouseButtonPressed(.LEFT) {
			for i in 0 ..< 3 {
				if raylib.CheckCollisionPointRec(mouse_pos, sys.choices[i].rect) {
					world.player.powerups[sys.choices[i].kind] += 1
					sys.active = false
					world.wave += 1
					spawn_wave(world)
					world.tile_timer = 0.0
					raylib.DisableCursor()
					break
				}
			}
		}
	}
}

cards_draw :: proc(sys: ^Cards_System) {
	raylib.DrawRectangle(
		0,
		0,
		VIRTUAL_WINDOW_WIDTH,
		VIRTUAL_WINDOW_HEIGHT,
		raylib.Color{0, 0, 0, 180},
	)

	scale_x := f32(raylib.GetScreenWidth()) / f32(VIRTUAL_WINDOW_WIDTH)
	scale_y := f32(raylib.GetScreenHeight()) / f32(VIRTUAL_WINDOW_HEIGHT)
	screen_mouse := raylib.GetMousePosition()
	mouse_pos := raylib.Vector2{screen_mouse.x / scale_x, screen_mouse.y / scale_y}

	for i in 0 ..< 3 {
		rect := sys.choices[i].rect
		is_back := sys.choices[i].flip_angle > 90.0

		width_scale := math.abs(math.cos(sys.choices[i].flip_angle * math.PI / 180.0))
		draw_rect := raylib.Rectangle {
			rect.x + rect.width / 2.0 * (1.0 - width_scale),
			rect.y,
			rect.width * width_scale,
			rect.height,
		}

		if is_back {
			raylib.DrawRectangleRec(draw_rect, raylib.DARKBLUE)
			raylib.DrawRectangleLinesEx(draw_rect, 4.0, raylib.GOLD)
		} else {
			raylib.DrawRectangleRec(draw_rect, raylib.RAYWHITE)
			raylib.DrawRectangleLinesEx(draw_rect, 4.0, raylib.BLACK)

			if width_scale > 0.1 {
				text: cstring = ""
				#partial switch sys.choices[i].kind {
				case .Stasis:
					text = "Stasis"
				case .Fire_Bullets:
					text = "Fire Bullets"
				case .More_Bullets:
					text = "More Bullets"
				case .Life_Steal:
					text = "Life Steal"
				case .Health_Regen:
					text = "Health Regen"
				case .Speed_Boost:
					text = "Speed Boost"
				}

				font_size: i32 = 24
				text_width := raylib.MeasureText(text, font_size)
				raylib.DrawText(
					text,
					cast(i32)(draw_rect.x + draw_rect.width / 2.0 - f32(text_width) / 2.0),
					cast(i32)(draw_rect.y + 130),
					font_size,
					raylib.BLACK,
				)
			}
		}

		if sys.state == .Idle {
			if raylib.CheckCollisionPointRec(mouse_pos, rect) {
				raylib.DrawRectangleLinesEx(rect, 6.0, raylib.YELLOW)
			}
		}
	}

	title: cstring = "CHOOSE A POWERUP"
	title_width := raylib.MeasureText(title, 40)
	raylib.DrawText(title, VIRTUAL_WINDOW_WIDTH / 2 - title_width / 2, 100, 40, raylib.WHITE)
}