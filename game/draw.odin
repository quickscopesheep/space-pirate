package game

draw_world_sprite :: proc (xform : Mat4, sprite : Sprite, tint := Vec4{1, 1, 1, 1}, ppu : int = 16) {
    xform := xform

    scale := f32(sprite.h) / f32(ppu) 
    local_xform := xform_make(pos = {-sprite.anchor.x * scale, -sprite.anchor.y * scale, 0})
    local_xform *= xform_make(scale = {scale * f32(sprite.w) / f32(sprite.h), scale, 1})

    xform = xform * local_xform

    uv0, uv1 := sprite_to_uv(sprite, .WORLD)

    gfx_push_cmd(.WORLD, {
        xform = xform,
        tint = tint,
        uv0 = uv0,
        uv1 = uv1,
    })
}