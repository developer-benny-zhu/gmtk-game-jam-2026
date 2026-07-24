package game

import "vendor/r3d"

Gun_Kind :: enum u8 {
    Pistol,
    Submachine_Gun
}

Gun :: struct {
    kind: Gun_Kind
}

gun_draw :: proc(gun: Gun, assets: Assets) {
    switch gun.kind {
        case .Pistol:
            r3d.DrawModel(assets.pistol, {0, 0, 0}, 1)
        case .Submachine_Gun:
            r3d.DrawModel(assets.submachine_gun, {0, 0, 0}, 1)
    }
}