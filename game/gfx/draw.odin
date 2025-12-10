package gfx

import "core:c"

import sg "sokol:gfx/"
import sglue "sokol:glue/"
import slog "sokol:log/"

import "../util"
import "../shaders"

SAMPLE_COUNT :: 8

DRAW_LAYER_WORLD :: 0
DRAW_LAYER_UI :: 1
DRAW_LAYER_DEBUG :: 2

@private
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

    framebuffer.color_attachment_view = sg.make_view({
        color_attachment = {image = framebuffer.color_tex}
    })
    framebuffer.depth_attachment_view = sg.make_view({
        depth_stencil_attachment = {image = framebuffer.depth_tex}
    })
    framebuffer.color_resolve_view = sg.make_view({
        resolve_attachment = {image = framebuffer.color_resolve_tex}
    })
    framebuffer.color_tex_view = sg.make_view({
        texture = {image = framebuffer.color_tex}
    })
}

@private
init_framebuffer :: proc(w, h : int) {
    if sg.query_image_state(framebuffer.color_tex) == .VALID do sg.uninit_image(framebuffer.color_tex)
    if sg.query_image_state(framebuffer.color_resolve_tex) == .VALID do sg.uninit_image(framebuffer.color_resolve_tex)
    if sg.query_image_state(framebuffer.depth_tex) == .VALID do sg.uninit_image(framebuffer.depth_tex)

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
}

init_pipelines :: proc() {
    pipelines.world_lit = sg.make_pipeline({
        shader = sg.make_shader(shaders.world_lit_shader_desc(sg.query_backend()))

        //pipeline shit
        
    })
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
        }
    })

    //WORLD PASS
    world_layer := queue.layers[DRAW_LAYER_WORLD]
    for batch in queue.batches[world_layer.batch_start:world_layer.batch_end] {
    }

    sg.end_pass()
}

//draw_world_sprite :: proc (xform : util.Mat4, sprite : Sprite, tint := util.Vec4{1, 1, 1, 1}, ppu : int = 16) {
    //xform := xform

    //scale := f32(sprite.h) / f32(ppu) 
    //local_xform := util.xform_make(pos = {-sprite.anchor.x * scale, -sprite.anchor.y * scale, 0})
    //local_xform *= util.xform_make(scale = {scale * f32(sprite.w) / f32(sprite.h), scale, 1})

    //xform = xform * local_xform

    //uv0, uv1 := sprite_to_uv(sprite)

    //push_cmd(.WORLD, {
    //    xform = xform,
    //    tint = tint,
    //    uv0 = uv0,
    //    uv1 = uv1,
    //})
//}