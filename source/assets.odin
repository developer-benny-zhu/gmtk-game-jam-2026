package game

import "vendor:raylib"
import "vendor/r3d"

Assets :: struct {
    wall: r3d.Model,
    banner_wall: r3d.Model,
    detailed_floor: r3d.Model
}

assets_init :: proc(assets: ^Assets) {
    assets.wall = r3d.LoadModel("assets/kenney_space_station_kit/wall.glb")
    assets.banner_wall = r3d.LoadModel("assets/kenney_space_station_kit/banner_wall.glb")
    assets.detailed_floor = r3d.LoadModel("assets/kenney_space_station_kit/detailed_floor.glb")
}

assets_destroy :: proc(assets: ^Assets) {
    r3d.UnloadModel(assets.wall, true)
    r3d.UnloadModel(assets.banner_wall, true)
    r3d.UnloadModel(assets.detailed_floor, true)
}