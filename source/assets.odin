package game

import "core:fmt"
import "core:math/rand"
import "vendor/r3d"
import "vendor:raylib"

AMOUNT_OF_CONCRETE_FOOTSTEP_SOUNDS :: 4
AMOUNT_OF_LASER_SOUNDS :: 9
AMOUNT_OF_MALE_GRUNT_SOUNDS :: 5

Item_Kind :: enum u8 {
	Pistol,
	Submachine_Gun,
}

Assets :: struct {
	concrete_footstep_sounds: [AMOUNT_OF_CONCRETE_FOOTSTEP_SOUNDS]raylib.Sound,
	laser_sounds:             [AMOUNT_OF_LASER_SOUNDS]raylib.Sound,
	male_grunt_sounds:        [AMOUNT_OF_MALE_GRUNT_SOUNDS]raylib.Sound,
	items:                    [Item_Kind]raylib.Model,
	cube:                     r3d.Mesh,
	enemy_mesh:               r3d.Mesh,
	projectile_mesh:          r3d.Mesh,
}

play_random_male_grunt_sound :: proc(assets: Assets) {
	random_index := rand.int_range(0, AMOUNT_OF_MALE_GRUNT_SOUNDS)
	raylib.PlaySound(assets.male_grunt_sounds[random_index])
}

assets_init_male_grunt_sounds :: proc(assets: ^Assets) {
	for index in 0 ..< AMOUNT_OF_MALE_GRUNT_SOUNDS {
		path := fmt.ctprintf("assets/male_grunts/male_grunt_%v.ogg", index)
		assets.male_grunt_sounds[index] = raylib.LoadSound(path)
	}
}

assets_init_concrete_footstep_sounds :: proc(assets: ^Assets) {
	for index in 0 ..< AMOUNT_OF_CONCRETE_FOOTSTEP_SOUNDS {
		path := fmt.ctprintf("assets/kenney_impact_sounds/concrete_footstep_%v.ogg", index)
		assets.concrete_footstep_sounds[index] = raylib.LoadSound(path)
	}
}

assets_init_laser_sounds :: proc(assets: ^Assets) {
	for index in 0 ..< AMOUNT_OF_LASER_SOUNDS {
		path := fmt.ctprintf("assets/kenney_digital_audio/laser_%v.ogg", index)
		assets.laser_sounds[index] = raylib.LoadSound(path)
	}
}

assets_init_items :: proc(assets: ^Assets) {
	assets.items[.Pistol] = raylib.LoadModel("assets/kenney_blaster_kit/pistol.glb")
	assets.items[.Submachine_Gun] = raylib.LoadModel(
		"assets/kenney_blaster_kit/submachine_gun.glb",
	)
}

assets_init :: proc(assets: ^Assets) {
	assets_init_concrete_footstep_sounds(assets)
	assets_init_male_grunt_sounds(assets)
	assets_init_laser_sounds(assets)
	assets_init_items(assets)
	assets.cube = r3d.GenMeshCube(1, 1, 1)
	assets.enemy_mesh = r3d.GenMeshSphere(2.0, 16, 16)
	assets.projectile_mesh = r3d.GenMeshCube(0.4, 0.4, 2.0)
}

assets_destroy :: proc(assets: ^Assets) {
	assets_destroy_laser_sounds(assets)
	assets_destroy_items(assets)
	assets_destroy_concrete_footstep_sounds(assets)
	assets_destroy_male_grunt_sounds(assets)
	r3d.UnloadMesh(assets.cube)
	r3d.UnloadMesh(assets.enemy_mesh)
	r3d.UnloadMesh(assets.projectile_mesh)
}

assets_destroy_concrete_footstep_sounds :: proc(assets: ^Assets) {
	for sound in assets.concrete_footstep_sounds {
		raylib.UnloadSound(sound)
	}
}

assets_destroy_items :: proc(assets: ^Assets) {
	for item in assets.items {
		raylib.UnloadModel(item)
	}
}

assets_destroy_laser_sounds :: proc(assets: ^Assets) {
	for sound in assets.laser_sounds {
		raylib.UnloadSound(sound)
	}
}

assets_destroy_male_grunt_sounds :: proc(assets: ^Assets) {
	for sound in assets.male_grunt_sounds {
		raylib.UnloadSound(sound)
	}
}
