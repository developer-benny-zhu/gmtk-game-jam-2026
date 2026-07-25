package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "vendor:raylib"

GRAVITY :: 32.0
MAX_WALK_SPEED :: 4.5
MAX_RUN_SPEED :: 8.5
MAX_CROUCH_SPEED :: 2.5
MAX_SLIDE_SPEED :: 16.0
JUMP_FORCE :: 12.0
MAX_ACCELERATION :: 150.0
FRICTION_GROUNDED :: 0.86
FRICTION_AIRBORNE :: 0.98
FRICTION_SLIDING :: 0.995
DIRECTION_CONTROL_RESPONSIVENESS :: 15.0
MINIMUM_SPEED_THRESHOLD :: 0.01

HEIGHT_SLIDING :: 0.25
HEIGHT_CROUCHING :: 0.5
HEIGHT_STANDING :: 1.0
HEIGHT_BOTTOM_OFFSET :: 0.5
FOV_DEFAULT :: 60.0
FOV_MOVING :: 55.0
FOV_SLIDING :: 75.0

SPEED_CROUCH_TRANSITION :: 20.0
SPEED_HEAD_BOB_TIMER :: 3.0
SPEED_WALK_BOB_TRANSITION :: 10.0
SPEED_FOV_TRANSITION_MOVING :: 5.0
SPEED_FOV_TRANSITION_STOPPING :: 10.0
SPEED_LEAN_TRANSITION :: 10.0
SPEED_LANDING_KICK :: 10.0

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

WALK_BOB_SPEED :: 1.0
CROUCH_BOB_SPEED :: 0.5
BREATHING_SPEED :: 1.5
BREATHING_AMPLITUDE :: 0.02
LANDING_KICK_AMPLITUDE :: 0.35

SLIDE_BOOST :: 12.0
SLIDE_DURATION_MAX :: 0.75
SPEED_LINE_THRESHOLD :: 9.0

VECTOR_UP :: linalg.Vector3f32{0.0, 1.0, 0.0}
VECTOR_DOWN :: linalg.Vector3f32{0.0, -1.0, 0.0}
VECTOR_FORWARD :: linalg.Vector3f32{0.0, 0.0, -1.0}
VECTOR_ZERO :: linalg.Vector3f32{0.0, 0.0, 0.0}

Player :: struct {
	camera:            raylib.Camera3D,
	view_model_camera: raylib.Camera3D,
	position:          linalg.Vector3f32,
	velocity:          linalg.Vector3f32,
	direction:         linalg.Vector3f32,
	look_rotation:     linalg.Vector2f32,
	head_bob_timer:    f32,
	walk_bob_lerp:     f32,
	head_height_lerp:  f32,
	camera_lean:       linalg.Vector2f32,
	is_grounded:       bool,
	was_grounded:      bool,
	is_sliding:        bool,
	slide_timer:       f32,
	landing_kick_lerp: f32,
	breath_timer:      f32,
	view_model:        View_Model,
	health:            f32,
	hurt_timer:        f32,
}

player_shoot_ray :: proc(player: Player) -> raylib.Ray {
	screen_center := linalg.Vector2f32 {
		f32(raylib.GetScreenWidth()) / 2.0,
		f32(raylib.GetScreenHeight()) / 2.0,
	}
	return raylib.GetScreenToWorldRay(screen_center, player.camera)
}

player_init :: proc(player: ^Player) {
	player.health = 100.0
	player.view_model_camera.fovy = 60.0
	player.view_model_camera.projection = .PERSPECTIVE
	player.view_model_camera.up = {0.0, 1.0, 0.0}
	player.view_model_camera.target = {0.0, 0.0, -1.0}
}

player_draw_hud :: proc(player: ^Player) {
	draw_speed_lines(player)
}

player_update :: proc(player: ^Player, assets: Assets) {
	delta_time := raylib.GetFrameTime()
	player.was_grounded = player.is_grounded

	apply_mouse_look(player)

	move_right, move_forward, is_crouching, is_sprinting := get_movement_inputs()

	update_player_physics(player, move_right, move_forward, is_crouching, is_sprinting, delta_time)

	if player.is_grounded && !player.was_grounded {
		player.landing_kick_lerp = 1.0
	}
	player.landing_kick_lerp = math.lerp(
		player.landing_kick_lerp,
		0.0,
		SPEED_LANDING_KICK * delta_time,
	)

	update_camera_stance_and_effects(player, move_right, move_forward, is_crouching, delta_time)

	apply_camera_transformations(player)
	apply_footstep_sound(player, assets)
}

apply_footstep_sound :: proc(player: ^Player, assets: Assets) {
	horizontal_velocity := linalg.Vector3f32{player.velocity.x, 0.0, player.velocity.z}
	is_moving := linalg.length(horizontal_velocity) > 0.01

	if !player.is_grounded || !is_moving {
		return
	}

	previous_bob := math.sin(
		(player.head_bob_timer - raylib.GetFrameTime() * SPEED_HEAD_BOB_TIMER) * math.PI,
	)
	current_bob := math.sin(player.head_bob_timer * math.PI)

	if (previous_bob < 0.0 && current_bob >= 0.0) || (previous_bob > 0.0 && current_bob <= 0.0) {
		random_index := rand.int_range(0, AMOUNT_OF_CONCRETE_FOOTSTEP_SOUNDS)
		raylib.PlaySound(assets.concrete_footstep_sounds[random_index])
	}
}

apply_mouse_look :: proc(player: ^Player) {
	mouse_delta := raylib.GetMouseDelta()
	player.look_rotation.x -= mouse_delta.x * MOUSE_SENSITIVITY_X
	player.look_rotation.y += mouse_delta.y * MOUSE_SENSITIVITY_Y
}

get_movement_inputs :: proc(
) -> (
	move_right: f32,
	move_forward: f32,
	is_crouching: bool,
	is_sprinting: bool,
) {
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
	is_sprinting = raylib.IsKeyDown(.LEFT_SHIFT)
	return move_right, move_forward, is_crouching, is_sprinting
}

update_player_physics :: proc(
	player: ^Player,
	move_right: f32,
	move_forward: f32,
	is_crouching: bool,
	is_sprinting: bool,
	delta_time: f32,
) {
	input_direction := linalg.Vector2f32{move_right, -move_forward}
	if move_right != 0.0 && move_forward != 0.0 {
		input_direction = raylib.Vector2Normalize(input_direction)
	}

	apply_gravity_and_jump(player, delta_time)

	sin_yaw := math.sin(player.look_rotation.x)
	cos_yaw := math.cos(player.look_rotation.x)

	basis_matrix := matrix[3, 3]f32{
		cos_yaw, 0.0, sin_yaw,
		0.0, 1.0, 0.0,
		-sin_yaw, 0.0, cos_yaw,
	}

	local_movement := linalg.Vector3f32{input_direction.x, 0.0, input_direction.y}
	desired_movement_direction := basis_matrix * local_movement

	forward_basis := basis_matrix * linalg.Vector3f32{0.0, 0.0, -1.0}
	if player.is_sliding {
		desired_movement_direction = forward_basis
	}

	player.direction = linalg.lerp(
		player.direction,
		desired_movement_direction,
		DIRECTION_CONTROL_RESPONSIVENESS * delta_time,
	)

	speed := linalg.length(linalg.Vector3f32{player.velocity.x, 0.0, player.velocity.z})

	if is_crouching &&
	   raylib.IsKeyPressed(CROUCH) &&
	   player.is_grounded &&
	   speed > MAX_WALK_SPEED &&
	   !player.is_sliding &&
	   player.slide_timer <= 0.0 {
		player.is_sliding = true
		player.slide_timer = SLIDE_DURATION_MAX
		player.velocity.x = forward_basis.x * (speed + SLIDE_BOOST)
		player.velocity.z = forward_basis.z * (speed + SLIDE_BOOST)
	}

	if player.is_sliding {
		player.slide_timer -= delta_time
		if player.slide_timer <= 0.0 || speed < (MAX_CROUCH_SPEED * 1.2) {
			player.is_sliding = false
			player.slide_timer = 0.5
		}
	}

	if !player.is_sliding && player.slide_timer > 0.0 {
		player.slide_timer -= delta_time
	}

	apply_friction_and_acceleration(player, is_crouching, is_sprinting, delta_time)
	apply_velocity_to_position(player, delta_time)
}

apply_gravity_and_jump :: proc(player: ^Player, delta_time: f32) {
	if !player.is_grounded {
		player.velocity.y -= GRAVITY * delta_time
	}

	if player.is_grounded && raylib.IsKeyPressed(JUMP) && !player.is_sliding {
		player.velocity.y = JUMP_FORCE
		player.is_grounded = false
	}
}

apply_friction_and_acceleration :: proc(
	player: ^Player,
	is_crouching: bool,
	is_sprinting: bool,
	delta_time: f32,
) {
	deceleration_factor: f32 = FRICTION_GROUNDED if player.is_grounded else FRICTION_AIRBORNE
	if player.is_sliding {
		deceleration_factor = FRICTION_SLIDING
	}

	horizontal_velocity := linalg.Vector3f32 {
		player.velocity.x * deceleration_factor,
		0.0,
		player.velocity.z * deceleration_factor,
	}

	velocity_magnitude := linalg.length(horizontal_velocity)
	if velocity_magnitude < (MAX_WALK_SPEED * MINIMUM_SPEED_THRESHOLD) {
		horizontal_velocity = VECTOR_ZERO
	}

	current_speed := linalg.dot(horizontal_velocity, player.direction)

	maximum_allowed_speed: f32 = MAX_WALK_SPEED
	if player.is_sliding {
		maximum_allowed_speed = MAX_SLIDE_SPEED
	} else if is_crouching {
		maximum_allowed_speed = MAX_CROUCH_SPEED
	} else if is_sprinting {
		maximum_allowed_speed = MAX_RUN_SPEED
	}

	acceleration_amount := raylib.Clamp(
		maximum_allowed_speed - current_speed,
		0.0,
		MAX_ACCELERATION * delta_time,
	)

	if !player.is_sliding {
		horizontal_velocity.x += player.direction.x * acceleration_amount
		horizontal_velocity.z += player.direction.z * acceleration_amount
	}

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

	player.position.x = raylib.Clamp(player.position.x, 0.0, f32(WORLD_SIZE_X - 1.0))
	player.position.z = raylib.Clamp(player.position.z, 0.0, f32(WORLD_SIZE_Y - 1.0))
}

update_camera_stance_and_effects :: proc(
	player: ^Player,
	move_right: f32,
	move_forward: f32,
	is_crouching: bool,
	delta_time: f32,
) {
	target_height: f32 = HEIGHT_STANDING
	if player.is_sliding {
		target_height = HEIGHT_SLIDING
	} else if is_crouching {
		target_height = HEIGHT_CROUCHING
	}

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
	speed := linalg.length(linalg.Vector3f32{player.velocity.x, 0.0, player.velocity.z})

	if player.is_grounded && is_moving {
		bob_speed_multiplier: f32 = WALK_BOB_SPEED
		if is_crouching && !player.is_sliding {
			bob_speed_multiplier = CROUCH_BOB_SPEED
		}

		player.head_bob_timer += delta_time * SPEED_HEAD_BOB_TIMER * bob_speed_multiplier
		player.walk_bob_lerp = math.lerp(
			player.walk_bob_lerp,
			1.0,
			SPEED_WALK_BOB_TRANSITION * delta_time,
		)
	} else {
		player.walk_bob_lerp = math.lerp(
			player.walk_bob_lerp,
			0.0,
			SPEED_WALK_BOB_TRANSITION * delta_time,
		)
	}

	if !is_moving && player.is_grounded && !player.is_sliding {
		player.breath_timer += delta_time * BREATHING_SPEED
	} else {
		player.breath_timer = 0.0
	}

	target_fov: f32 = FOV_DEFAULT
	if player.is_sliding {
		target_fov = FOV_SLIDING
	} else if is_moving {
		target_fov = FOV_MOVING + (speed * 0.75)
	}

	transition_speed: f32 =
		SPEED_FOV_TRANSITION_MOVING if is_moving || player.is_sliding else SPEED_FOV_TRANSITION_STOPPING
	player.camera.fovy = math.lerp(player.camera.fovy, target_fov, transition_speed * delta_time)

	target_lean_x := move_right * LEAN_MAX_HORIZONTAL
	target_lean_y := move_forward * LEAN_MAX_FORWARD
	if player.is_sliding {
		target_lean_x *= 1.5
		target_lean_y *= 1.5
	}

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

	breath_offset := math.sin(player.breath_timer * math.PI) * BREATHING_AMPLITUDE

	final_camera_position := base_camera_position + (head_bob_offset * player.walk_bob_lerp)
	final_camera_position.y += breath_offset
	final_camera_position.y -= player.landing_kick_lerp * LANDING_KICK_AMPLITUDE

	player.camera.position = final_camera_position
	player.camera.target = final_camera_position + rotated_pitch_vector
}

draw_speed_lines :: proc(player: ^Player) {
	speed := linalg.length(linalg.Vector3f32{player.velocity.x, 0.0, player.velocity.z})
	if speed < SPEED_LINE_THRESHOLD {return}

	center_x := raylib.GetScreenWidth() / 2
	center_y := raylib.GetScreenHeight() / 2
	intensity := raylib.Clamp((speed - SPEED_LINE_THRESHOLD) / 4.0, 0.0, 1.0)
	lines_count := i32(intensity * 40.0)

	for i in 0 ..< lines_count {
		angle := rand.float32_range(0.0, math.PI * 2.0)
		dist_start := rand.float32_range(0.3, 0.7) * f32(center_x)
		dist_end := dist_start + rand.float32_range(0.1, 0.4) * f32(center_x)

		start_x := center_x + i32(math.cos(angle) * dist_start)
		start_y := center_y + i32(math.sin(angle) * dist_start)
		end_x := center_x + i32(math.cos(angle) * dist_end)
		end_y := center_y + i32(math.sin(angle) * dist_end)

		alpha := u8(f32(rand.int_range(20, 120)) * intensity)
		color := raylib.Color{255, 255, 255, alpha}
		raylib.DrawLine(start_x, start_y, end_x, end_y, color)
	}
}
