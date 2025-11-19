package game

import "core:math/linalg"
import "core:math/linalg/glsl"

Vec2 :: glsl.vec2
Vec3 :: glsl.vec3
Vec4 :: glsl.vec4

Ivec2 :: glsl.ivec2
Ivec3 :: glsl.ivec3
Ivec4 :: glsl.ivec4

Quat :: quaternion128
Mat4 :: glsl.mat4

//todo: replace linalg calls with my own matrix math

xform_make :: proc(pos := Vec3{0, 0, 0}, roll := f32(0), scale := Vec3{1, 1, 1}) -> (xform : Mat4) {
    xform = linalg.identity(Mat4)

    xform *= linalg.matrix4_translate(pos)
    xform *= linalg.matrix4_rotate(roll, Vec3{0, 0, 1.0})
    xform *= linalg.matrix4_scale(scale)

    return
}

view_make :: proc(view_pos := Vec3{0, 0, 0}, view_roll : f32) -> (V : Mat4) {
    V = linalg.identity(Mat4)
    V *= linalg.matrix4_translate(-view_pos)
    V *= linalg.matrix4_rotate(view_roll , Vec3{0, 0, -1.0})

    return
}

projection_make :: proc(size, aspect : f32) -> (P : Mat4) {
    P = linalg.identity(Mat4)
    P *= linalg.matrix_ortho3d_f32(-aspect * size, aspect * size, -size, size, -1.0, 1.0)

    return
}