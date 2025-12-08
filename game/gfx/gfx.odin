package gfx

import "core:math/linalg"
import "core:image"
import "core:c"

import stbi "vendor:stb/image"

import sg "sokol:gfx/"
import sglue "sokol:glue/"
import slog "sokol:log/"

import "../util"
import "../shaders"

MAX_DRAWS :: 1024

BINDING_CMD_BUFF :: 0
BINDING_TEX :: 1

Coord_Mode :: enum {
    CLIP,
    PROJECTED,
    VIEW_PROJECTED
}

Sprite :: struct {
    x, y : int,
    w, h : int,

    //anchor
    anchor : util.Vec2
}

Atlas :: struct {
    w, h : int,
    image : sg.Image,
    view : sg.View
}

@private
fb_w, fb_h : int

@private
rect_vertex_buffer : sg.Buffer
@private
rect_index_buffer : sg.Buffer

@private
point_sampler : sg.Sampler

@private
coord_mode : Coord_Mode
@private
V, P : util.Mat4

@private
cam_scroll : util.Vec3
@private
cam_roll : f32
@private
cam_size : f32

//RESOURCE CREATION API

@(private="file")
init_base_resources :: proc() {
    rect_vertex_data := []f32 {
        //POS       //UV
        -0.5, 0.5,  0, 1,
        0.5, 0.5,   1, 1,
        0.5, -0.5,  1, 0,
        -0.5, -0.5, 0, 0
    }

    rect_vertex_buffer = sg.make_buffer({
        data = {
            ptr = raw_data(rect_vertex_data),
            size = len(rect_vertex_data) * size_of(f32)
        }
    })

    rect_index_data := []u16 {
        0, 1, 2,
        2, 3, 0
    }

    rect_index_buffer = sg.make_buffer({
        data = {
            ptr = raw_data(rect_index_data),
            size = len(rect_index_data) * size_of(u16)
        },

        usage = {
            index_buffer = true
        }
    })

    point_sampler = sg.make_sampler({
        min_filter = .NEAREST,
        mag_filter = .NEAREST
    })
}

@(private="file")
load_atlas :: proc(path : cstring) -> Atlas{
    w, h, nc : c.int
    data := stbi.load(path, &w, &h, &nc, 4)
    assert(data != nil)

    defer stbi.image_free(data)

    img := sg.make_image({
        width = w,
        height = h,
        pixel_format = .RGBA8,

        data = {
            mip_levels = {
                0 = {ptr = data, size = c.size_t(w*h*4)}
            }
        }
    })

    view := sg.make_view({
        texture = {
            image = img
        }
    })

    return Atlas {
        w = int(w),
        h = int(h),
        image = img,
        view = view
    }
}

//GFX API

init :: proc(w, h : int) {
    fb_w, fb_h = w, h

    coord_mode = .VIEW_PROJECTED
    set_cam_scroll({0, 0, 0})
    set_cam_size(10)

    sg.setup({
        environment = sglue.environment(),
        logger = {
            func = slog.func
        }
    })
    
    init_base_resources()
    setup_drawing()
}

set_coord_mode :: proc(mode : Coord_Mode) {
    coord_mode = mode
}

set_cam_scroll :: proc(pos : util.Vec3) {
    cam_scroll = pos
    V = util.view_make(pos, cam_roll)
}

set_cam_size :: proc(size : f32) {
    cam_size = size
    P = util.projection_make(cam_size, f32(fb_w) / f32(fb_h))
}

set_cam_roll :: proc(roll : f32) {
    cam_roll = roll
    V = util.view_make(cam_scroll, roll)
}

shutdown :: proc() {
    sg.shutdown()
}

sprite_to_uv :: proc(sprite : Sprite, atlas : Atlas) -> (uv0, uv1 : util.Vec2) {
    uv0 = util.Vec2{f32(sprite.x) / f32(atlas.w), f32(sprite.y) / f32(atlas.w)}
    uv1 = util.Vec2{f32(sprite.x + sprite.w) / f32(atlas.w), f32(sprite.y + sprite.h) / f32(atlas.h)}

    return
}