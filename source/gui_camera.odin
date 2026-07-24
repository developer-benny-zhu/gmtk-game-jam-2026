package game

import "vendor:raylib"
import "core:math"

gui_camera_update :: proc(camera: ^raylib.Camera2D) {
	render_width := f32(raylib.GetRenderWidth())
	render_height := f32(raylib.GetRenderHeight())
	scale := math.min(render_width / VIRTUAL_WINDOW_WIDTH, render_height / VIRTUAL_WINDOW_HEIGHT)
	camera.offset = {render_width * 0.5, render_height * 0.5}
	camera.target = {VIRTUAL_WINDOW_WIDTH * 0.5, VIRTUAL_WINDOW_HEIGHT * 0.5}
	camera.zoom = scale
}