package game

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

//todo: replace linalg calls with my own matrix math

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
    return xform_make(pos = -view_pos, roll = -view_roll)
}

projection_make :: proc(size, aspect : f32) -> (P : Mat4) {
    //dont change z axis

    far := f32(10)
    near := f32(0.01)

    right := size * aspect
    left := -size * aspect
    top := size
    bottom := -size

    //P[0] = Vec4{2.0/(right-left), 0, 0, -(right+left)/(right-left)}
    //P[1] = Vec4{0, 2.0/(top-bottom), 0, -(top+bottom)/(top-bottom)}
    //P[2] = Vec4{0, 0, -2.0/(far-near), -(far+near)/(far-near)}
    //P[3] = Vec4{0, 0, 0, 1}

    P[0] = Vec4{2.0 / (right-left), 0, 0, -(right+left)/(right-left)}
    P[1] = Vec4{0, 2.0 / (top-bottom), 0, -(top+bottom)/(top-bottom)}
    P[2] = Vec4{0, 0, -far / (far-near), -(far+near)/(far-near)}
    P[3] = Vec4{0, 0, 0, 1.0}
    return
}

roll_make :: proc(theta_degrees : f32) -> f32 {
    return theta_degrees * math.PI / 180.0
}