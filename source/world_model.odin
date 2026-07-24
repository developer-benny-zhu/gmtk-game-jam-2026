package game

import "vendor:raylib"
import "core:math/linalg"

World_Model :: struct {
    position: linalg.Vector3f32,
	kind: Item_Kind,
}

world_model_draw :: proc(world_model: World_Model, assets: Assets) {
    raylib.DrawModel(assets.items[world_model.kind], {0, 0, -1}, 1, raylib.WHITE)
}