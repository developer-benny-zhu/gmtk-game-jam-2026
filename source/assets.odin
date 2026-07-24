package game

import "core:fmt"
import "vendor/r3d"
import "vendor:raylib"

AMOUNT_OF_CONCRETE_FOOTSTEP_SOUNDS :: 4
AMOUNT_OF_LASER_SOUNDS :: 9

Item_Kind :: enum u8 {
	Pistol,
	Submachine_Gun,
}

Assets :: struct {
	concrete_footstep_sounds: [AMOUNT_OF_CONCRETE_FOOTSTEP_SOUNDS]raylib.Sound,
	laser_sounds:             [AMOUNT_OF_LASER_SOUNDS]raylib.Sound,
	items:                    [Item_Kind]raylib.Model,
	cube: r3d.Mesh
}

assets_init :: proc(assets: ^Assets) {
	for index in 0 ..< AMOUNT_OF_CONCRETE_FOOTSTEP_SOUNDS {
		path := fmt.ctprintf("assets/kenney_impact_sounds/concrete_footstep_%v.ogg")
		assets.concrete_footstep_sounds[index] = raylib.LoadSound(path)
	}
	assets.concrete_footstep_sounds[0] = raylib.LoadSound(
		"assets/kenney_impact_sounds/concrete_footstep_0.ogg",
	)
	assets.concrete_footstep_sounds[1] = raylib.LoadSound(
		"assets/kenney_impact_sounds/concrete_footstep_1.ogg",
	)
	assets.concrete_footstep_sounds[2] = raylib.LoadSound(
		"assets/kenney_impact_sounds/concrete_footstep_2.ogg",
	)
	assets.concrete_footstep_sounds[3] = raylib.LoadSound(
		"assets/kenney_impact_sounds/concrete_footstep_3.ogg",
	)
	for index in 0 ..< AMOUNT_OF_LASER_SOUNDS {
		path := fmt.ctprintf("assets/kenney_digital_audio/laser_%v.ogg", index)
		assets.laser_sounds[index] = raylib.LoadSound(path)
	}
	assets.items[.Pistol] = raylib.LoadModel("assets/kenney_blaster_kit/pistol.glb")
	assets.items[.Submachine_Gun] = raylib.LoadModel(
		"assets/kenney_blaster_kit/submachine_gun.glb",
	)
	assets.cube = r3d.GenMeshCube(1, 1, 1)
}

assets_destroy :: proc(assets: ^Assets) {
	for sound in assets.concrete_footstep_sounds {
		raylib.UnloadSound(sound)
	}
	for sound in assets.laser_sounds {
		raylib.UnloadSound(sound)
	}
	for item in assets.items {
		raylib.UnloadModel(item)
	}
}
