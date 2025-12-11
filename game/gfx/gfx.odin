package gfx

import sg "sokol:gfx/"
import sglue "sokol:glue/"
import slog "sokol:log/"

MAX_GFX_LAYERS :: 16

Common_Samplers :: enum{
    LINEAR_REPEAT,
    POINT_REPEAT,
    POINT_CLAMP
}

common_resources : struct {
    rect_vtx_buffer : sg.Buffer,
    rect_idx_buffer : sg.Buffer,

    samplers : [Common_Samplers]sg.Sampler,
    default_tex : struct{
        img : sg.Image,
        view : sg.View
    }
}

viewport_width, viewport_height : int

@private
init_common_resources :: proc() {
    vertices := []f32 {
        -0.5, 0.5, 0,   0, 1,
        0.5, 0.5, 0,    1, 1,
        0.5, -0.5, 0,   1, 0,
        -0.5, -0.5, 0,  0, 0
    }

    indices := []u16 {
        0, 1, 2,
        2, 3, 0
    }

    common_resources.rect_vtx_buffer = sg.make_buffer({
        data = {
            ptr = &vertices[0],
            size = len(vertices) * size_of(f32)
        }
    })

    common_resources.rect_idx_buffer = sg.make_buffer({
        data = {
            ptr = &indices[0],
            size = len(indices)* size_of(u16)
        }
    })

    filters := []sg.Filter{
        .LINEAR,
        .NEAREST,
        .NEAREST
    }
    wrap := []sg.Wrap{
        .REPEAT,
        .CLAMP_TO_EDGE,
        .CLAMP_TO_BORDER
    }

    for i in 0..<len(common_resources.samplers){
        common_resources.samplers[Common_Samplers(i)] = sg.make_sampler({
            min_filter = filters[i],
            mag_filter = filters[i],
            wrap_u = wrap[i],
            wrap_v = wrap[i]
        })
    }

    white := 0xffffffff

    tex_data : sg.Image_Data
    tex_data.mip_levels[0] = {
        ptr = &white,
        size = size_of(u32)
    }

    common_resources.default_tex.img = sg.make_image({
        width = 1,
        height = 1,
        pixel_format = .RGBA8,
        data = tex_data
    })

    common_resources.default_tex.view = sg.make_view({
        texture = {image = common_resources.default_tex.img}
    })
}

setup :: proc(w, h : int) {
    viewport_width, viewport_height = w, h

    sg.setup({
        environment = sglue.environment(),
        logger = {
            func = slog.func
        }
    })

    init_common_resources()
    setup_frontend()
}

on_window_resize :: proc(new_w, new_h : int) {
    viewport_width, viewport_height = new_w, new_h
    init_framebuffer(viewport_width, viewport_height)
}

shutdown :: proc() {
    sg.shutdown()
}