package game

import "core:math"
import "core:math/linalg"
import "vendor:raylib"

GRAVITY :: 32.0
MAX_RUN_SPEED :: 7.5
MAX_CROUCH_SPEED :: 2.5
JUMP_FORCE :: 12.0
MAX_ACCELERATION :: 150.0
FRICTION_GROUNDED :: 0.86
FRICTION_AIRBORNE :: 0.98
DIRECTION_CONTROL_RESPONSIVENESS :: 15.0
MINIMUM_SPEED_THRESHOLD :: 0.01

HEIGHT_CROUCHING :: 0.5
HEIGHT_STANDING :: 1.0
HEIGHT_BOTTOM_OFFSET :: 0.5
FOV_DEFAULT :: 60.0
FOV_MOVING :: 55.0

SPEED_CROUCH_TRANSITION :: 20.0
SPEED_HEAD_BOB_TIMER :: 3.0
SPEED_WALK_BOB_TRANSITION :: 10.0
SPEED_FOV_TRANSITION_MOVING :: 5.0
SPEED_FOV_TRANSITION_STOPPING :: 10.0
SPEED_LEAN_TRANSITION :: 10.0

MOUSE_SENSITIVITY_X :: 0.001
MOUSE_SENSITIVITY_Y :: 0.001
LEAN_MAX_HORIZONTAL :: 0.02
LEAN_MAX_FORWARD :: 0.015
HEAD_BOB_STEP_ROTATION :: 0.01
HEAD_BOB_AMPLITUDE_SIDE :: 0.1
HEAD_BOB_AMPLITUDE_UP :: 0.15
PITCH_CLAMP_PADDING :: 0.0001
PITCH_MAX_LIMIT :: math.PI / 2.0 - PITCH_CLAMP_PADDING
PITCH_MIN_LIMIT :: -math.PI / 2.0 + PITCH_CLAMP_PADDING

VECTOR_UP :: linalg.Vector3f32{0.0, 1.0, 0.0}
VECTOR_DOWN :: linalg.Vector3f32{0.0, -1.0, 0.0}
VECTOR_FORWARD :: linalg.Vector3f32{0.0, 0.0, -1.0}
VECTOR_ZERO :: linalg.Vector3f32{0.0, 0.0, 0.0}

Player :: struct {
	camera:           raylib.Camera3D,
	position:         linalg.Vector3f32,
	velocity:         linalg.Vector3f32,
	direction:        linalg.Vector3f32,
	look_rotation:    linalg.Vector2f32,
	head_bob_timer:   f32,
	walk_bob_lerp:    f32,
	head_height_lerp: f32,
	camera_lean:      linalg.Vector2f32,
	is_grounded:      bool,
}

player_update :: proc(player: ^Player) {
	delta_time := raylib.GetFrameTime()

	apply_mouse_look(player)

	move_right, move_forward, is_crouching := get_movement_inputs()

	update_player_physics(player, move_right, move_forward, is_crouching, delta_time)

	update_camera_stance_and_effects(player, move_right, move_forward, is_crouching, delta_time)

	apply_camera_transformations(player)
}

apply_mouse_look :: proc(player: ^Player) {
	mouse_delta := raylib.GetMouseDelta()
	player.look_rotation.x -= mouse_delta.x * MOUSE_SENSITIVITY_X
	player.look_rotation.y += mouse_delta.y * MOUSE_SENSITIVITY_Y
}

get_movement_inputs :: proc() -> (move_right: f32, move_forward: f32, is_crouching: bool) {
	if raylib.IsKeyDown(MOVE_RIGHT) {
		move_right = 1.0
	} else if raylib.IsKeyDown(MOVE_LEFT) {
		move_right = -1.0
	}

	if raylib.IsKeyDown(MOVE_FORWARD) {
		move_forward = 1.0
	} else if raylib.IsKeyDown(MOVE_BACKWARD) {
		move_forward = -1.0
	}

	is_crouching = raylib.IsKeyDown(CROUCH)
	return move_right, move_forward, is_crouching
}

update_player_physics :: proc(
	player: ^Player,
	move_right: f32,
	move_forward: f32,
	is_crouching: bool,
	delta_time: f32,
) {
	input_direction := linalg.Vector2f32{move_right, -move_forward}
	if move_right != 0.0 && move_forward != 0.0 {
		input_direction = raylib.Vector2Normalize(input_direction)
	}

	apply_gravity_and_jump(player, delta_time)

	yaw_rotation := player.look_rotation.x
	forward_vector := linalg.Vector3f32{math.sin(yaw_rotation), 0.0, math.cos(yaw_rotation)}
	right_vector := linalg.Vector3f32{math.cos(-yaw_rotation), 0.0, math.sin(-yaw_rotation)}

	desired_movement_direction := linalg.Vector3f32 {
		input_direction.x * right_vector.x + input_direction.y * forward_vector.x,
		0.0,
		input_direction.x * right_vector.z + input_direction.y * forward_vector.z,
	}

	player.direction = linalg.lerp(
		player.direction,
		desired_movement_direction,
		DIRECTION_CONTROL_RESPONSIVENESS * delta_time,
	)

	apply_friction_and_acceleration(player, is_crouching, delta_time)

	apply_velocity_to_position(player, delta_time)
}

apply_gravity_and_jump :: proc(player: ^Player, delta_time: f32) {
	if !player.is_grounded {
		player.velocity.y -= GRAVITY * delta_time
	}

	if player.is_grounded && raylib.IsKeyPressed(JUMP) {
		player.velocity.y = JUMP_FORCE
		player.is_grounded = false
	}
}

apply_friction_and_acceleration :: proc(player: ^Player, is_crouching: bool, delta_time: f32) {
	deceleration_factor: f32 = FRICTION_GROUNDED if player.is_grounded else FRICTION_AIRBORNE
	horizontal_velocity := linalg.Vector3f32 {
		player.velocity.x * deceleration_factor,
		0.0,
		player.velocity.z * deceleration_factor,
	}

	velocity_magnitude := linalg.length(horizontal_velocity)
	if velocity_magnitude < (MAX_RUN_SPEED * MINIMUM_SPEED_THRESHOLD) {
		horizontal_velocity = VECTOR_ZERO
	}

	current_speed := linalg.dot(horizontal_velocity, player.direction)

	maximum_allowed_speed: f32 = MAX_CROUCH_SPEED if is_crouching else MAX_RUN_SPEED
	acceleration_amount := raylib.Clamp(
		maximum_allowed_speed - current_speed,
		0.0,
		MAX_ACCELERATION * delta_time,
	)

	horizontal_velocity.x += player.direction.x * acceleration_amount
	horizontal_velocity.z += player.direction.z * acceleration_amount

	player.velocity.x = horizontal_velocity.x
	player.velocity.z = horizontal_velocity.z
}

apply_velocity_to_position :: proc(player: ^Player, delta_time: f32) {
	player.position.x += player.velocity.x * delta_time
	player.position.y += player.velocity.y * delta_time
	player.position.z += player.velocity.z * delta_time

	if player.position.y <= 0.0 {
		player.position.y = 0.0
		player.velocity.y = 0.0
		player.is_grounded = true
	}
}

update_camera_stance_and_effects :: proc(
	player: ^Player,
	move_right: f32,
	move_forward: f32,
	is_crouching: bool,
	delta_time: f32,
) {
	target_height: f32 = HEIGHT_CROUCHING if is_crouching else HEIGHT_STANDING
	player.head_height_lerp = math.lerp(
		player.head_height_lerp,
		target_height,
		SPEED_CROUCH_TRANSITION * delta_time,
	)

	player.camera.position = linalg.Vector3f32 {
		player.position.x,
		player.position.y + (HEIGHT_BOTTOM_OFFSET + player.head_height_lerp),
		player.position.z,
	}

	is_moving := move_forward != 0.0 || move_right != 0.0
	if player.is_grounded && is_moving {
		player.head_bob_timer += delta_time * SPEED_HEAD_BOB_TIMER
		player.walk_bob_lerp = math.lerp(
			player.walk_bob_lerp,
			1.0,
			SPEED_WALK_BOB_TRANSITION * delta_time,
		)
		player.camera.fovy = math.lerp(
			player.camera.fovy,
			FOV_MOVING,
			SPEED_FOV_TRANSITION_MOVING * delta_time,
		)
	} else {
		player.walk_bob_lerp = math.lerp(
			player.walk_bob_lerp,
			0.0,
			SPEED_WALK_BOB_TRANSITION * delta_time,
		)
		player.camera.fovy = math.lerp(
			player.camera.fovy,
			FOV_DEFAULT,
			SPEED_FOV_TRANSITION_STOPPING * delta_time,
		)
	}

	target_lean_x := move_right * LEAN_MAX_HORIZONTAL
	target_lean_y := move_forward * LEAN_MAX_FORWARD
	player.camera_lean.x = math.lerp(
		player.camera_lean.x,
		target_lean_x,
		SPEED_LEAN_TRANSITION * delta_time,
	)
	player.camera_lean.y = math.lerp(
		player.camera_lean.y,
		target_lean_y,
		SPEED_LEAN_TRANSITION * delta_time,
	)
}

apply_camera_transformations :: proc(player: ^Player) {
	player.camera.projection = .PERSPECTIVE

	base_camera_position := linalg.Vector3f32 {
		player.position.x,
		player.position.y + (HEIGHT_BOTTOM_OFFSET + player.head_height_lerp),
		player.position.z,
	}

	rotated_yaw_vector := raylib.Vector3RotateByAxisAngle(
		VECTOR_FORWARD,
		VECTOR_UP,
		player.look_rotation.x,
	)

	clamp_vertical_look_rotation(player, rotated_yaw_vector)

	camera_right_vector := raylib.Vector3Normalize(
		raylib.Vector3CrossProduct(rotated_yaw_vector, VECTOR_UP),
	)

	pitch_angle := -player.look_rotation.y - player.camera_lean.y
	pitch_angle = raylib.Clamp(pitch_angle, PITCH_MIN_LIMIT, PITCH_MAX_LIMIT)
	rotated_pitch_vector := raylib.Vector3RotateByAxisAngle(
		rotated_yaw_vector,
		camera_right_vector,
		pitch_angle,
	)

	apply_head_bob_and_finalize_camera(
		player,
		base_camera_position,
		rotated_pitch_vector,
		camera_right_vector,
	)
}

clamp_vertical_look_rotation :: proc(player: ^Player, rotated_yaw_vector: linalg.Vector3f32) {
	max_angle_up := raylib.Vector3Angle(VECTOR_UP, rotated_yaw_vector)
	max_angle_up -= PITCH_CLAMP_PADDING
	if -player.look_rotation.y > max_angle_up {
		player.look_rotation.y = -max_angle_up
	}

	max_angle_down := raylib.Vector3Angle(VECTOR_DOWN, rotated_yaw_vector)
	max_angle_down *= -1.0
	max_angle_down += PITCH_CLAMP_PADDING
	if -player.look_rotation.y < max_angle_down {
		player.look_rotation.y = -max_angle_down
	}
}

apply_head_bob_and_finalize_camera :: proc(
	player: ^Player,
	base_camera_position: linalg.Vector3f32,
	rotated_pitch_vector: linalg.Vector3f32,
	camera_right_vector: linalg.Vector3f32,
) {
	head_sin_wave := math.sin(player.head_bob_timer * math.PI)
	head_cos_wave := math.cos(player.head_bob_timer * math.PI)

	player.camera.up = raylib.Vector3RotateByAxisAngle(
		VECTOR_UP,
		rotated_pitch_vector,
		(head_sin_wave * HEAD_BOB_STEP_ROTATION) + player.camera_lean.x,
	)

	head_bob_offset := camera_right_vector * (head_sin_wave * HEAD_BOB_AMPLITUDE_SIDE)
	head_bob_offset.y = math.abs(head_cos_wave * HEAD_BOB_AMPLITUDE_UP)

	final_camera_position := base_camera_position + (head_bob_offset * player.walk_bob_lerp)

	player.camera.position = final_camera_position
	player.camera.target = final_camera_position + rotated_pitch_vector
}
