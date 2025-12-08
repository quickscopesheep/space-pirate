package util

import "core:math/linalg"
import "core:math/linalg/glsl"
import "core:math"

Vec2 :: glsl.vec2
Vec3 :: glsl.vec3
Vec4 :: glsl.vec4

Ivec2 :: glsl.ivec2
Ivec3 :: glsl.ivec3
Ivec4 :: glsl.ivec4

Quat :: quaternion128
Mat4 :: glsl.mat4

xform_make :: proc(pos := Vec3{0, 0, 0}, roll := f32(0), scale := Vec3{1, 1, 1}) -> (xform : Mat4) {
    x := Vec3{math.cos(roll)*scale.x, -math.sin(roll)*scale.x, 0}
    y := Vec3{math.sin(roll)*scale.y, math.cos(roll)*scale.y, 0}
    z := Vec3{0, 0, 1*scale.z}

    xform[0] = {x.x, x.y, x.z, 0}
    xform[1] = {y.x, y.y, y.z, 0}
    xform[2] = {z.x, z.y, z.z, 0}
    xform[3] = {pos.x, pos.y, pos.z, 1}

    return
}

view_make :: proc(view_pos := Vec3{0, 0, 0}, view_roll : f32) -> (V : Mat4) {
    return xform_make(pos = Vec3{0, 0, 1} - view_pos, roll = -view_roll)
}

projection_make :: proc(size, aspect : f32) -> (P : Mat4) {
    size := size
    size /= 2

    far := f32(1000)
    near := f32(0.01)

    right := size * aspect
    left := -size * aspect
    top := size
    bottom := -size

    return linalg.matrix_ortho3d(left, right, top, bottom, far, near, false)
}

roll_make :: proc(theta_degrees : f32) -> f32 {
    return theta_degrees * math.PI / 180.0
}

lerp_f32 :: proc(a, b, t : f32) -> f32 {
    return a + t * (b-a)
}

lerp_f64 :: proc(a, b, t : f64) -> f64 {
    return a + t * (b-a)
}

lerp_vec2 :: proc(a, b : Vec2, t : f32) -> Vec2 {
    return a + t * (b-a)
}

lerp_vec3 :: proc(a, b : Vec3, t : f32) -> Vec3 {
    return a + t * (b-a)
}

lerp_vec4 :: proc(a, b : Vec4, t : f32) -> Vec4 {
    return a + t * (b-a)
}

lerp :: proc {
    lerp_f32,
    lerp_f64,
    lerp_vec2,
    lerp_vec3,
    lerp_vec4
}