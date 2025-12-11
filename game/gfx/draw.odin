package gfx

import "core:c"

import sg "sokol:gfx/"
import sglue "sokol:glue/"
import slog "sokol:log/"

import "core:fmt"

import "../math"
import "../shaders"

SAMPLE_COUNT :: 8

DRAW_LAYER_WORLD :: 0
DRAW_LAYER_UI :: 1
DRAW_LAYER_DEBUG :: 2

queue : Draw_Queue

pipelines : struct {
    world_lit : sg.Pipeline
}

@private
framebuffer : struct {
    color_tex,
    color_resolve_tex,
    depth_tex : sg.Image,

    color_attachment_view,
    depth_attachment_view,
    color_resolve_view,
    color_tex_view : sg.View
}

@private
alloc_framebuffer :: proc() {
    framebuffer.color_tex = sg.alloc_image()
    framebuffer.color_resolve_tex = sg.alloc_image()
    framebuffer.depth_tex = sg.alloc_image()

    framebuffer.color_attachment_view = sg.alloc_view()
    framebuffer.depth_attachment_view = sg.alloc_view()
    framebuffer.color_resolve_view = sg.alloc_view()
    framebuffer.color_tex_view = sg.alloc_view()
}

@private
init_framebuffer :: proc(w, h : int) {
    if sg.query_image_state(framebuffer.color_tex) == .VALID do sg.uninit_image(framebuffer.color_tex)
    if sg.query_image_state(framebuffer.color_resolve_tex) == .VALID do sg.uninit_image(framebuffer.color_resolve_tex)
    if sg.query_image_state(framebuffer.depth_tex) == .VALID do sg.uninit_image(framebuffer.depth_tex)

    if sg.query_view_state(framebuffer.color_attachment_view) == .VALID do sg.uninit_view(framebuffer.color_attachment_view)
    if sg.query_view_state(framebuffer.color_resolve_view) == .VALID do sg.uninit_view(framebuffer.color_resolve_view)
    if sg.query_view_state(framebuffer.color_tex_view) == .VALID do sg.uninit_view(framebuffer.color_tex_view)
    if sg.query_view_state(framebuffer.depth_attachment_view) == .VALID do sg.uninit_view(framebuffer.depth_attachment_view)

    sg.init_image(framebuffer.color_tex, {
        width = c.int(w),
        height = c.int(h),

        pixel_format = .RGBA16,
        sample_count = SAMPLE_COUNT,

        usage = {
            color_attachment = true
        }
    })
    sg.init_image(framebuffer.color_resolve_tex, {
        width = c.int(w),
        height = c.int(h),

        pixel_format = .RGBA16,

        usage = {
            resolve_attachment = true
        }
    })
    sg.init_image(framebuffer.depth_tex, {
        width = c.int(w),
        height = c.int(h),

        pixel_format = .DEPTH,
        sample_count = SAMPLE_COUNT,

        usage = {
            depth_stencil_attachment = true
        }
    })

    sg.init_view(framebuffer.color_attachment_view, {
        color_attachment = {image = framebuffer.color_tex}
    })
    sg.init_view(framebuffer.depth_attachment_view, {
        depth_stencil_attachment = {image = framebuffer.depth_tex}
    })
    sg.init_view(framebuffer.color_resolve_view, {
        resolve_attachment = {image = framebuffer.color_resolve_tex}
    })
    sg.init_view(framebuffer.color_tex_view, {
        texture = {image = framebuffer.color_resolve_tex}
    })
}

init_pipelines :: proc() {
    world_lit_desc := default_rect_pipeline_desc(shaders.world_lit_shader_desc(sg.query_backend()))
    world_lit_desc.sample_count = SAMPLE_COUNT
    world_lit_desc.colors[0] = {
        pixel_format = .RGBA16
    }
    world_lit_desc.depth = {
        pixel_format = .DEPTH,
        write_enabled = true
    }

    pipelines.world_lit = sg.make_pipeline(world_lit_desc)
}

@private
setup_frontend :: proc() {
    queue_init(&queue)

    alloc_framebuffer()
    init_framebuffer(viewport_width, viewport_height)
    init_pipelines()
}

begin :: proc() {
    queue_begin(&queue)
}

end :: proc() {
    queue_end(&queue)

    sg.begin_pass({
        attachments = {
            colors = {
                0 = framebuffer.color_attachment_view
            },
            resolves = {
                0 = framebuffer.color_resolve_view
            },

            depth_stencil = framebuffer.depth_attachment_view
        },

        action = {
            colors = {
                0 = {load_action = .CLEAR, clear_value = {0.1, 0.1, 0.1, 1}}
            }
        }
    })

    pip : sg.Pipeline
    tex : sg.View

    bindings : sg.Bindings
    bindings.vertex_buffers[0] = common_resources.rect_vtx_buffer
    bindings.index_buffer = common_resources.rect_idx_buffer
    bindings.samplers[shaders.SMP_lit_smp] = common_resources.samplers[.POINT_REPEAT]
    bindings.views[shaders.VIEW_lit_per_instance] = queue.cmd_view

    //WORLD_PASS
    world_pass_start := queue.layer_starts[DRAW_LAYER_WORLD]
    for batch in queue.batches[world_pass_start:queue.batch_top] {
        if batch.layer != DRAW_LAYER_WORLD do break
        if batch.pip != pip {
            pip = batch.pip
            sg.apply_pipeline(pip)
        }
        if batch.tex != tex {
            tex = batch.tex
            bindings.views[shaders.VIEW_lit_tex] = tex
            sg.apply_bindings(bindings)
        }

        uniforms := shaders.Lit_Per_Batch_Data{
            batch_start = i32(batch.start)
        }
        
        sg.apply_uniforms(shaders.UB_lit_per_batch_data, {
            ptr = &uniforms,
            size = size_of(shaders.Lit_Per_Batch_Data)
        })

        sg.draw(0, 6, batch.size) 
    }

    sg.end_pass()

    blit(framebuffer.color_tex_view)

    sg.commit()
}

//draw_world_sprite :: proc (xform : math.Mat4, sprite : Sprite, tint := util.Vec4{1, 1, 1, 1}, ppu : int = 16) {
//  //xform := xform
//  //scale := f32(sprite.h) / f32(ppu) 
//  //local_xform := util.xform_make(pos = {-sprite.anchor.x * scale, -sprite.anchor.y * scale, 0})
//  //local_xform *= util.xform_make(scale = {scale * f32(sprite.w) / f32(sprite.h), scale, 1})
//  //xform = xform * local_xform
//  //uv0, uv1 := sprite_to_uv(sprite)
//  //push_cmd(.WORLD, {
//  //    xform = xform,
//  //    tint = tint,
//  //    uv0 = uv0,
//  //    uv1 = uv1,
//  //})
//}