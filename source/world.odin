package game

import "core:math/linalg"
import "vendor/r3d"
import "vendor:raylib"
import "vendor:raylib/rlgl"
import "core:math/rand"

WORLD_SIZE_X :: 100
WORLD_SIZE_Y :: 100

World :: struct {
	player:                Player,
	floor_instance_buffer: r3d.InstanceBuffer,
}

world_init :: proc(world: ^World) {
	player_init(&world.player)
	raylib.DisableCursor()
	world.floor_instance_buffer = r3d.LoadInstanceBuffer(WORLD_SIZE_X * WORLD_SIZE_Y, {.POSITION})
	positions := cast([^]linalg.Vector3f32)r3d.MapInstances(
		world.floor_instance_buffer,
		{.POSITION},
		false,
	)
	for row in 0 ..< WORLD_SIZE_Y {
		for column in 0 ..< WORLD_SIZE_X {
			positions[row * WORLD_SIZE_X + column] = {f32(column), 0, f32(row)}
		}
	}
	r3d.UnmapInstances(world.floor_instance_buffer, {.POSITION})
	light := r3d.CreateLight(.DIR)
	r3d.SetLightDirection(light, {0, -1, 0})
	r3d.EnableLight(light)
}

world_update :: proc(world: ^World, game_state: ^Game_State) {
	view_model_update(&world.player.view_model)
	gui_camera_update(&game_state.gui_camera)
	player_update(&world.player, game_state.assets)
	if raylib.IsMouseButtonPressed(.LEFT) {
		view_model_add_recoil(&world.player.view_model)
		random_index := rand.int_range(0, AMOUNT_OF_LASER_SOUNDS)
		raylib.PlaySound(game_state.assets.laser_sounds[random_index])
	}
}

world_draw :: proc(world: ^World, game_state: ^Game_State) {
	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)
	rlgl.SetClipPlanes(0.5, 1000.0)
	r3d.Begin(world.player.camera)
	raylib.DrawGrid(50, 1.0)
	world_draw_floor(world, game_state.assets)
	r3d.End()
	raylib.BeginMode2D(game_state.gui_camera)
	draw_crosshair()

	raylib.BeginMode3D(world.player.view_model_camera)
	view_model_draw(
		world.player.view_model,
		game_state.assets,
		world.player.head_bob_timer,
		world.player.walk_bob_lerp,
	)
	raylib.EndMode3D()

	raylib.EndMode2D()
	raylib.DrawFPS(10, 10)
	raylib.EndDrawing()
}

world_draw_floor :: proc(world: ^World, assets: Assets) {
	material_index := assets.detailed_floor.meshMaterials[0]
	material := assets.detailed_floor.materials[material_index]
	r3d.DrawMeshInstanced(
		assets.detailed_floor.meshes[0],
		material,
		world.floor_instance_buffer,
		WORLD_SIZE_X * WORLD_SIZE_Y,
	)

}
world_destroy :: proc(world: ^World) {
	r3d.UnloadInstanceBuffer(world.floor_instance_buffer)
}
