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
    start, end : uint
}

Draw_Queue :: struct{
    cmds : [MAX_CMDS_PER_QUEUE] Draw_Cmd,
    batches : [MAX_BATCHES_PER_QUEUE] Draw_Batch,
    cmd_top : int
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

    
}

queue_commit :: proc(this : Draw_Queue) {

}