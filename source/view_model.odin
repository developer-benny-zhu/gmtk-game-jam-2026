package game

import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "vendor:raylib"

item_kind_to_view_model_position: [Item_Kind]linalg.Vector3f32 = {
	.Pistol         = {0.35, -0.2, -0.9},
	.Submachine_Gun = {0, 0, -1},
}

item_kind_to_view_model_kick_back: [Item_Kind]f32 = {
	.Pistol         = 0.25,
	.Submachine_Gun = 0.12,
}

item_kind_to_view_model_kick_up: [Item_Kind]f32 = {
	.Pistol         = 0.18,
	.Submachine_Gun = 0.07,
}

item_kind_to_view_model_kick_side: [Item_Kind]f32 = {
	.Pistol         = 0.12,
	.Submachine_Gun = 0.06,
}

BOB_AMPLITUDE_X :: 0.015
BOB_AMPLITUDE_Y :: 0.02
ROTATION_BOB :: 1.8

IDLE_BOB_SPEED :: 1.2
IDLE_BOB_AMPLITUDE :: 0.005
DEG_TO_RAD :: math.PI / 180.0

View_Model :: struct {
	kind:            Item_Kind,
	recoil_position: linalg.Vector3f32,
	recoil_rotation: linalg.Vector3f32,
	target_position: linalg.Vector3f32,
	target_rotation: linalg.Vector3f32,
}

view_model_add_recoil :: proc(view_model: ^View_Model) {
	kick_back := item_kind_to_view_model_kick_back[view_model.kind]
	kick_up := item_kind_to_view_model_kick_up[view_model.kind]
	kick_side := item_kind_to_view_model_kick_side[view_model.kind]

	random_intensity := rand.float32_range(0.9, 1.5)
	random_yaw := rand.float32_range(-1.2, 1.2)
	random_roll := rand.float32_range(-1.5, 1.5)

	view_model.target_position.z += kick_back * random_intensity
	view_model.target_position.y += kick_up * 0.6 * random_intensity
	view_model.target_position.x += kick_side * 0.2 * random_yaw

	view_model.target_rotation.x += kick_up * 18.0 * random_intensity
	view_model.target_rotation.y += kick_side * 12.0 * random_yaw
	view_model.target_rotation.z += kick_side * 8.0 * random_roll
}

view_model_update :: proc(
	view_model: ^View_Model,
	snappiness: f32 = 45.0,
	return_speed: f32 = 8.0,
) {
	delta_time := raylib.GetFrameTime()

	view_model.target_position = linalg.lerp(
		view_model.target_position,
		linalg.Vector3f32{0, 0, 0},
		return_speed * 1.8 * delta_time,
	)
	view_model.target_rotation = linalg.lerp(
		view_model.target_rotation,
		linalg.Vector3f32{0, 0, 0},
		return_speed * 0.9 * delta_time,
	)

	view_model.recoil_position = linalg.lerp(
		view_model.recoil_position,
		view_model.target_position,
		snappiness * delta_time,
	)
	view_model.recoil_rotation = linalg.lerp(
		view_model.recoil_rotation,
		view_model.target_rotation,
		snappiness * delta_time,
	)
}

view_model_draw :: proc(
	view_model: View_Model,
	assets: Assets,
	head_bob_timer: f32,
	walk_bob_interpolation: f32,
) {
	base_position := item_kind_to_view_model_position[view_model.kind]
	time := cast(f32)raylib.GetTime()

	walk_bob_x := math.sin(head_bob_timer * math.PI) * BOB_AMPLITUDE_X * walk_bob_interpolation
	walk_bob_y :=
		math.abs(math.cos(head_bob_timer * math.PI)) * -BOB_AMPLITUDE_Y * walk_bob_interpolation

	idle_bob_x :=
		math.sin(time * IDLE_BOB_SPEED) * IDLE_BOB_AMPLITUDE * (1.0 - walk_bob_interpolation)
	idle_bob_y :=
		math.cos(time * IDLE_BOB_SPEED * 0.5) * IDLE_BOB_AMPLITUDE * (1.0 - walk_bob_interpolation)

	final_position := linalg.Vector3f32 {
		base_position.x + walk_bob_x + idle_bob_x + view_model.recoil_position.x,
		base_position.y + walk_bob_y + idle_bob_y + view_model.recoil_position.y,
		base_position.z + view_model.recoil_position.z,
	}

	walk_roll_angle := math.sin(head_bob_timer * math.PI) * ROTATION_BOB * walk_bob_interpolation

	pitch := view_model.recoil_rotation.x * DEG_TO_RAD
	yaw := view_model.recoil_rotation.y * DEG_TO_RAD
	roll := (walk_roll_angle + view_model.recoil_rotation.z) * DEG_TO_RAD

	model := assets.items[view_model.kind]
	model.transform = raylib.MatrixRotateXYZ({pitch, yaw, roll})

	raylib.DrawModel(model, final_position, 1.0, raylib.WHITE)
}
