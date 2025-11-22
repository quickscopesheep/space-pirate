package game

import "core:image"
import "core:c"

import stbi "vendor:stb/image"

import sg "sokol:gfx/"

import sglue "sokol:glue/"
import slog "sokol:log/"

import "shaders"

MAX_DRAWS :: 256

BINDING_CMD_BUFF :: 0
BINDING_TEX :: 1

Textures :: enum u8 {
    WORLD,
    UI
}

texture_paths := [Textures] cstring {
    .WORLD = "data/world.png",
    .UI = "data/ui.png"
}

Coord_Mode :: enum {
    CLIP,
    PROJECTED,
    VIEW_PROJECTED
}

Draw_Channels :: enum {
    WORLD,
    UI
}

Sprite :: struct {
    x, y : int,
    w, h : int
}

Texture :: struct {
    w, h : int,
    image : sg.Image,
    view : sg.View
}

Draw_Cmd :: struct {
    xform : Mat4,
    tint : Vec4,
    uv0 : Vec2,
    uv1 : Vec2,
}

Draw_Channel :: struct {
    shader : sg.Shader,
    pip : sg.Pipeline,
    tex : Texture,

    cmd_buffer : sg.Buffer,
    cmd_view : sg.View,

    cmds : [MAX_DRAWS]Draw_Cmd,
    cmds_top : int
}

fb_w, fb_h : int

rect_vertex_buffer : sg.Buffer
rect_index_buffer : sg.Buffer

point_sampler : sg.Sampler

coord_mode : Coord_Mode
V, P : Mat4

cam_scroll : Vec3
cam_roll : f32
cam_size : f32

textures : [Textures] Maybe(Texture)
draw_channels : [Draw_Channels] Draw_Channel

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
get_or_create_texture :: proc(texture : Textures) -> Texture{
    if _, ok := textures[texture].?; ok {
        return textures[texture].?
    }

    w, h, nc : c.int
    data := stbi.load(texture_paths[texture], &w, &h, &nc, 4)
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


    textures[texture] = Texture{
        w = int(w),
        h = int(h),
        image = img,
        view = view
    }

    return textures[texture].?
}

//DRAW CHANNEL API

@(private="file")
draw_channel_create :: proc(shader_desc : sg.Shader_Desc, transparent : bool, tex : Textures) -> (channel : Draw_Channel){
    channel.tex = get_or_create_texture(tex)

    channel.cmd_buffer = sg.make_buffer({
        size = len(channel.cmds) * size_of(Draw_Cmd),

        usage = {
            storage_buffer = true,
            stream_update = true
        }
    })

    channel.cmd_view = sg.make_view({
        storage_buffer = {
            buffer = channel.cmd_buffer
        }
    })

    channel.shader = sg.make_shader(shader_desc)

    pip_desc := sg.Pipeline_Desc{
        shader = channel.shader,

        index_type = .UINT16,

        layout = {
            attrs = {
                0 = {format = .FLOAT2},
                1 = {format = .FLOAT2},
            }
        },
    }

    channel.pip = sg.make_pipeline(pip_desc)

    return
}

@(private="file")
draw_channel_push :: proc(channel : ^Draw_Channel, cmd : Draw_Cmd) {
    channel.cmds[channel.cmds_top] = cmd
    channel.cmds_top += 1
}

@(private="file")
draw_channel_execute :: proc(channel : ^Draw_Channel) {
    sg.update_buffer(channel.cmd_buffer, {
        ptr = &channel.cmds[0],
        size = len(channel.cmds) * size_of(Draw_Cmd)
    })

    sg.begin_pass({
        action = {
            colors = {
                0 = {load_action = .LOAD}
            }
        },

        swapchain = sglue.swapchain()
    })

    sg.apply_pipeline(channel.pip)

    sg.apply_bindings({
        vertex_buffers = {0 = rect_vertex_buffer},
        index_buffer = rect_index_buffer,
        views = {
            BINDING_CMD_BUFF = channel.cmd_view,
            BINDING_TEX = channel.tex.view
        },
        samplers = {0 = point_sampler}
    })

    sg.draw(0, 6, channel.cmds_top)

    sg.end_pass()

    channel.cmds_top = 0
}

//GFX API

gfx_init :: proc(w, h : int) {
    fb_w, fb_h = w, h

    coord_mode = .VIEW_PROJECTED
    gfx_set_cam_scroll({0, 0, 0})
    gfx_set_cam_size(10)

    sg.setup({
        environment = sglue.environment(),
        logger = {
            func = slog.func
        }
    })
    
    init_base_resources()

    draw_channels[.WORLD] = draw_channel_create(
        shaders.lit_shader_desc(sg.query_backend()),
        false,
        .WORLD
    )
    draw_channels[.UI] = draw_channel_create(
        shaders.lit_shader_desc(sg.query_backend()),
         true,
        .UI
    )
}

gfx_set_coord_mode :: proc(mode : Coord_Mode) {
    coord_mode = mode
}

gfx_set_cam_scroll :: proc(pos : Vec3) {
    cam_scroll = pos
    V = view_make(pos, cam_roll)
}

gfx_set_cam_size :: proc(size : f32) {
    cam_size = size
    P = projection_make(cam_size, f32(fb_w) / f32(fb_h))
}

gfx_set_cam_roll :: proc(roll : f32) {
    cam_roll = roll
    V = view_make(cam_scroll, roll)
}

gfx_push_cmd :: proc (channel : Draw_Channels, cmd : Draw_Cmd) {
    cmd := cmd

    if coord_mode == .VIEW_PROJECTED do cmd.xform = P * V * cmd.xform
    else if coord_mode == .PROJECTED do cmd.xform = P * cmd.xform

    draw_channel_push(&draw_channels[channel], cmd)
}

gfx_execute :: proc() {
    //dummy pass to clear screen
    sg.begin_pass({
        action = {
            colors = {
                0 = {load_action = .CLEAR, clear_value = {0, 0, 0, 0}}
            }
        },

        swapchain = sglue.swapchain()
    })
    sg.end_pass()

    //do drawing
    for &c in draw_channels {
        draw_channel_execute(&c)
    }

    sg.commit()
}

gfx_shutdown :: proc() {
    sg.shutdown()
}

sprite_to_uv :: proc(sprite : Sprite, texture : Textures) -> (uv0, uv1 : Vec2) {
    tex := get_or_create_texture(texture)

    uv0 = Vec2{f32(sprite.x) / f32(tex.w), f32(sprite.y) / f32(tex.w)}
    uv1 = Vec2{f32(sprite.x + sprite.w) / f32(tex.w), f32(sprite.y + sprite.h) / f32(tex.h)}

    return
}