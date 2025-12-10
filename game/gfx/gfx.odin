package gfx

import sg "sokol:gfx/"
import sglue "sokol:glue/"
import slog "sokol:log/"

Common_Samplers :: enum{
    LINEAR_REPEAT,
    POINT_REPEAT,
    POINT_CLAMP
}

common_resources : struct {
    rect_vtx_buffer : sg.Buffer,
    rect_idx_buffer : sg.Buffer,

    samplers : [Common_Samplers]sg.Sampler
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

shutdown :: proc() {
    sg.shutdown()
}