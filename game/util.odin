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

xform_make :: proc(pos := Vec3{0, 0, 0}, roll := f32(0), scale := Vec3{1, 1, 1}) -> (xform : Mat4) {
    xform = linalg.identity(Mat4)

    xform *= linalg.matrix4_translate(pos)
    xform *= linalg.matrix4_rotate(roll, Vec3{0, 0, 1.0})
    xform *= linalg.matrix4_scale(scale)

    return
}