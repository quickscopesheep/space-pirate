#+private file
package game

import sg "sokol:gfx/"

import sglue "sokol:glue/"
import slog "sokol:log/"

import "shaders"

MAX_DRAWS :: 1024

//keep all game shit in one image
//keep all UI shit in different image

Draw_Cmd :: struct {
    xform : Mat4,
    tint : Vec4,
    uv0 : Vec2,
    uv1 : Vec2,
}

Coord_Mode :: enum {
    CLIP,
    PROJECTED,
    VIEW_PROJECTED
}

fb_w, fb_h : int

draw_cmds : [MAX_DRAWS] Draw_Cmd
draw_cmds_top : int

rect_vertex_buffer : sg.Buffer
rect_index_buffer : sg.Buffer

per_instance_buffer : sg.Buffer
per_instance_buffer_view : sg.View

lit_shader : sg.Shader
lit_pip : sg.Pipeline

coord_mode : Coord_Mode
V, P : Mat4

cam_scroll : Vec3
cam_roll : f32
cam_size : f32

gfx_init_resources :: proc() {
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

    per_instance_buffer = sg.make_buffer({
        size = len(draw_cmds) * size_of(Draw_Cmd),

        usage = {
            storage_buffer = true,
            stream_update = true
        }
    })

    per_instance_buffer_view = sg.make_view({
        storage_buffer = {
            buffer = per_instance_buffer
        }
    })

    lit_shader = sg.make_shader(shaders.lit_shader_desc(sg.query_backend()))
    lit_pip = sg.make_pipeline({
        shader = lit_shader,

        index_type = .UINT16,

        layout = {
            attrs = {
                shaders.ATTR_lit_a_pos = {format = .FLOAT2},
                shaders.ATTR_lit_a_uv = {format = .FLOAT2},
            }
        },
    })
}

@private
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
    
    gfx_init_resources()
}

@private
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

@private
gfx_push_cmd :: proc (cmd : Draw_Cmd) {
    cmd := cmd

    if coord_mode == .VIEW_PROJECTED do cmd.xform = P * V * cmd.xform
    else if coord_mode == .PROJECTED do cmd.xform = P * cmd.xform

    draw_cmds[draw_cmds_top] = cmd
    draw_cmds_top += 1
}

@private
gfx_execute :: proc() {
    //do drawing
    sg.update_buffer(per_instance_buffer, {
        ptr = &draw_cmds[0],
        size = len(draw_cmds) * size_of(Draw_Cmd)
    })

    sg.begin_pass({
        action = {
            colors = {
                0 = {load_action = .CLEAR, clear_value = {0.1, 0.1, 0.1, 1.0}}
            }
        },

        swapchain = sglue.swapchain()
    })

    sg.apply_pipeline(lit_pip)

    sg.apply_bindings({
        vertex_buffers = {0 = rect_vertex_buffer},
        index_buffer = rect_index_buffer,
        views = {0 = per_instance_buffer_view}
    })

    sg.draw(0, 6, draw_cmds_top)

    sg.end_pass()
    sg.commit()

    draw_cmds_top = 0
}

@private
gfx_shutdown :: proc() {
    sg.shutdown()
}