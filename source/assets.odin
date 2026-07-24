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
	wall:                     r3d.Model,
	banner_wall:              r3d.Model,
	detailed_floor:           r3d.Model,
	items:                    [Item_Kind]raylib.Model,
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

	assets.wall = r3d.LoadModel("assets/kenney_space_station_kit/wall.glb")
	assets.banner_wall = r3d.LoadModel("assets/kenney_space_station_kit/banner_wall.glb")
	assets.detailed_floor = r3d.LoadModel("assets/kenney_space_station_kit/detailed_floor.glb")
	assets.items[.Pistol] = raylib.LoadModel("assets/kenney_blaster_kit/pistol.glb")
	assets.items[.Submachine_Gun] = raylib.LoadModel(
		"assets/kenney_blaster_kit/submachine_gun.glb",
	)
}

assets_destroy :: proc(assets: ^Assets) {
	for sound in assets.concrete_footstep_sounds {
		raylib.UnloadSound(sound)
	}
	for sound in assets.laser_sounds {
		raylib.UnloadSound(sound)
	}
	r3d.UnloadModel(assets.wall, true)
	r3d.UnloadModel(assets.banner_wall, true)
	r3d.UnloadModel(assets.detailed_floor, true)
	for item in assets.items {
		raylib.UnloadModel(item)
	}
}
