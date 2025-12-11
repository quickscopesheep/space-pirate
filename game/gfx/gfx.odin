package gfx

import sg "sokol:gfx/"
import sglue "sokol:glue/"
import slog "sokol:log/"

import "../shaders"

MAX_GFX_LAYERS :: 16

Common_Samplers :: enum {
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
    },

    blit_pipeline : #sparse [sg.Pixel_Format] Maybe(sg.Pipeline)
}

viewport_width, viewport_height : int

@private
init_common_resources :: proc() {
    vertices := []f32 {
        -0.5, 0.5,   0, 1,
        0.5, 0.5,    1, 1,
        0.5, -0.5,   1, 0,
        -0.5, -0.5,  0, 0
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
        },

        usage = {
            index_buffer = true
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

    common_resources.blit_pipeline[.RGBA8] = sg.make_pipeline(
        default_rect_pipeline_desc(
            shaders.blit_shader_desc(sg.query_backend()),
            .RGBA8
        )
    )
    common_resources.blit_pipeline[.RGBA16] = sg.make_pipeline(
        default_rect_pipeline_desc(
            shaders.blit_shader_desc(sg.query_backend()),
            .RGBA16
        )
    )
}

blit_swapchain :: proc(image : sg.View) {
    format := sglue.swapchain().color_format
    pipeline := common_resources.blit_pipeline[format].(sg.Pipeline)

    sg.begin_pass({
        swapchain = sglue.swapchain(),
    })

    sg.apply_pipeline(pipeline)
    sg.apply_bindings({
        vertex_buffers = {
            0 = common_resources.rect_vtx_buffer
        },
        index_buffer = common_resources.rect_idx_buffer,

        views = {
            shaders.VIEW_blit_tex = image
        },
        samplers = {
            0 = common_resources.samplers[.POINT_CLAMP]
        }
    })

    sg.draw(0, 6, 1)

    sg.end_pass()
}

blit_framebuffer :: proc(image : sg.View, fb : sg.View) {
    format := sg.query_image_pixelformat(
        sg.query_view_image(fb)
    )
    pipeline := common_resources.blit_pipeline[format].(sg.Pipeline)

    sg.begin_pass({
        attachments = {
            colors = {
                0 = fb
            }
        }
    })

    sg.apply_pipeline(pipeline)
    sg.apply_bindings({
        vertex_buffers = {
            0 = common_resources.rect_vtx_buffer
        },
        index_buffer = common_resources.rect_idx_buffer,

        views = {
            shaders.VIEW_blit_tex = image
        },
        samplers = {
            0 = common_resources.samplers[.POINT_CLAMP]
        }
    })

    sg.draw(0, 6, 1)

    sg.end_pass()
}

blit :: proc {
    blit_swapchain,
    blit_framebuffer
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