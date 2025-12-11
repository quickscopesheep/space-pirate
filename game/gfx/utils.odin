package gfx

import sg "sokol:gfx/"

default_rect_pipeline_desc :: proc(shd : sg.Shader_Desc, pixel_format := sg.Pixel_Format.RGBA8) -> (desc : sg.Pipeline_Desc) {
    desc.shader = sg.make_shader(shd)
    desc.colors[0].pixel_format = pixel_format
    desc.index_type = .UINT16
    desc.layout = {
        attrs = {
            0 = {format = .FLOAT2},
            1 = {format = .FLOAT2}
        }
    }

    return
}