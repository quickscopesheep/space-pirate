package gfx

import "core:sort"

import sg "sokol:gfx/"

import "../math"

MAX_CMDS_PER_QUEUE :: 1024
MAX_BATCHES_PER_QUEUE :: 128

Draw_Data :: struct  #align(16) {
    using _: struct #packed {
        xform : math.Mat4,
        tint : math.Vec4,
        uv0 : math.Vec2,
        uv1 : math.Vec2,
    }
}

Draw_Cmd :: struct {
    payload : Draw_Data,

    layer : u32,
    pipeline : sg.Pipeline,
    tex : sg.View
}

Draw_Batch :: struct {
    start, size : int,
    pip : sg.Pipeline,
    tex : sg.View,
    layer : u32
}

Draw_Queue :: struct{
    cmds : [MAX_CMDS_PER_QUEUE] Draw_Cmd,
    cmd_top : int,

    packed_data : [MAX_CMDS_PER_QUEUE] Draw_Data,
    cmd_buffer : sg.Buffer,
    cmd_view : sg.View,

    batches : [MAX_BATCHES_PER_QUEUE] Draw_Batch,
    batch_top : int,

    layer_starts : [MAX_GFX_LAYERS] int
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
    this.batch_top = 0
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

    last_pip := this.cmds[0].pipeline
    last_tex := this.cmds[0].tex
    last_layer := this.cmds[0].layer

    for i in 0..<this.cmd_top {
        cmd := &this.cmds[i]
        queue.packed_data[i] = cmd.payload

        batch := &this.batches[this.batch_top]
        batch.size += 1

        if cmd.pipeline != last_pip || cmd.tex != last_tex || cmd.layer != last_layer || i == this.cmd_top-1 {
            batch.pip = last_pip
            batch.tex = last_tex
            batch.layer = last_layer

            if cmd.layer != last_layer do this.layer_starts[cmd.layer] = this.batch_top

            this.batch_top += 1
            this.batches[this.batch_top].start = i
        }

        last_pip = cmd.pipeline
        last_tex = cmd.tex
        last_layer = cmd.layer
    }

    sg.update_buffer(this.cmd_buffer, {
        ptr = &this.packed_data[0],
        size = uint(this.cmd_top * size_of(Draw_Data))
    })
}