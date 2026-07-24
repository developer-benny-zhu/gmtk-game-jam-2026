package game

import "vendor/r3d"
import "vendor:raylib"

AMOUNT_OF_CONCRETE_FOOTSTEPS :: 4

Assets :: struct {
	concrete_footsteps: [AMOUNT_OF_CONCRETE_FOOTSTEPS]raylib.Sound,
	wall:           r3d.Model,
	banner_wall:    r3d.Model,
	detailed_floor: r3d.Model,
	pistol:         r3d.Model,
	submachine_gun: r3d.Model,
}

assets_init :: proc(assets: ^Assets) {
	assets.concrete_footsteps[0] = raylib.LoadSound("assets/kenney_impact_sounds/concrete_footstep_0.ogg")
	assets.concrete_footsteps[1] = raylib.LoadSound("assets/kenney_impact_sounds/concrete_footstep_1.ogg")
	assets.concrete_footsteps[2] = raylib.LoadSound("assets/kenney_impact_sounds/concrete_footstep_2.ogg")
	assets.concrete_footsteps[3] = raylib.LoadSound("assets/kenney_impact_sounds/concrete_footstep_3.ogg")
	assets.wall = r3d.LoadModel("assets/kenney_space_station_kit/wall.glb")
	assets.banner_wall = r3d.LoadModel("assets/kenney_space_station_kit/banner_wall.glb")
	assets.detailed_floor = r3d.LoadModel("assets/kenney_space_station_kit/detailed_floor.glb")
	assets.pistol = r3d.LoadModel("assets/kenney_blaster_kit/pistol.glb")
	assets.submachine_gun = r3d.LoadModel("assets/kenney_blaster_kit/submachine_gun.glb")
}

assets_destroy :: proc(assets: ^Assets) {
	for footstep in assets.concrete_footsteps {
		raylib.UnloadSound(footstep)
	}
	r3d.UnloadModel(assets.wall, true)
	r3d.UnloadModel(assets.banner_wall, true)
	r3d.UnloadModel(assets.detailed_floor, true)
	r3d.UnloadModel(assets.pistol, true)
	r3d.UnloadModel(assets.submachine_gun, true)
}