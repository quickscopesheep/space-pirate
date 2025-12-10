package gfx

import "core:sort"

import sg "sokol:gfx/"

import "../util"

MAX_CMDS_PER_QUEUE :: 1024
MAX_BATCHES_PER_QUEUE :: 128

Draw_Data :: struct{
    xform : util.Mat4,
    tint : util.Vec4,
    uv0 : util.Vec2,
    uv1 : util.Vec2,
}

Draw_Cmd :: struct {
    payload : Draw_Data,

    layer : u32,
    pipeline : sg.Pipeline,
    tex : sg.View
}

Draw_Batch :: struct {
    //start inclusive, end exclusive
    start, end : uint
}

//functionally the same as a batch but instead points to batches array
Draw_Layer :: struct {
    batch_start : uint,
    batch_end : uint
}

Draw_Queue :: struct{
    cmds : [MAX_CMDS_PER_QUEUE] Draw_Cmd,
    cmd_top : int,
    batches : [MAX_BATCHES_PER_QUEUE] Draw_Batch,
    batch_top : int,

    packed_data : [MAX_CMDS_PER_QUEUE]Draw_Data,
    cmd_buffer : sg.Buffer,
    cmd_view : sg.View,

    layers : [MAX_GFX_LAYERS]Draw_Layer
}

queue_init :: proc(this : ^Draw_Queue) {
    this.cmd_buffer = sg.make_buffer({
        size = MAX_CMDS_PER_QUEUE * size_of(Draw_Data),
        usage = {
            storage_buffer = true,
            stream_update = true
        }
    })
    this.cmd_view = sg.make_view({
        storage_buffer = {buffer = this.cmd_buffer}
    })
}

queue_begin :: proc(this : ^Draw_Queue)  {
    this.cmd_top = 0
}

queue_push_cmd :: proc(this : ^Draw_Queue, cmd : Draw_Cmd) {
    this.cmds[this.cmd_top] = cmd
    this.cmd_top += 1
}

queue_end :: proc(this : ^Draw_Queue) {
    it : sort.Interface
    it.collection = rawptr(&this.cmds)

    //sloppy but in theory should work
    hash_cmd :: proc "contextless" (cmd : Draw_Cmd) -> (hash : u128) {
        hash += u128(transmute(u32)cmd.tex)
        hash += u128(transmute(u32)cmd.pipeline << 32)
        hash += u128(cmd.layer << 64)

        return
    }

    it.len = proc(it : sort.Interface) -> int {
        sl := (^[]Draw_Cmd)(it.collection)
        return len(sl^)
    }
    it.less = proc(it : sort.Interface, i, j : int) -> bool {
        sl := (^[]Draw_Cmd)(it.collection)
        a, b := hash_cmd(sl[i]), hash_cmd(sl[j])

        return a < b
    }
    it.swap = proc(it : sort.Interface, i, j : int) {
        sl := (^[]Draw_Cmd)(it.collection)
        sl[i], sl[j] = sl[j], sl[i]
    }

    sort.sort(it)

    last_pip : sg.Pipeline
    last_tex : sg.View
    last_layer : u32

    for i in 0..<this.cmd_top {
        cmd := this.cmds[i]
        batch := &this.batches[this.batch_top]

        batch.end += 1

        if cmd.pipeline != last_pip || cmd.tex != last_tex || cmd.layer != last_layer {
            this.batch_top += 1
            this.batches[this.batch_top].start = uint(i)
        }

        last_pip = cmd.pipeline
        last_tex = cmd.tex
        last_layer = cmd.layer
    }
}