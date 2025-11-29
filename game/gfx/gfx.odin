package gfx

Cmd :: struct {
    //xform
    //uvs
    //tint
}

Queue :: struct {
    //gfx cmds buffer
    //gfx cmds array
    //when queue pushed commands sorted by pipeline and sprite
    //then pushed to buffer and drawn instanced
}

//takes cmd and pushes to queue
queue_push :: proc() {

}

//processes and draws all cmds to framebuffer
queue_execute :: proc() {

}

//starts and ends pass
begin :: proc() {

}

end :: proc() {

}

//draws one tex to another with shader
blit :: proc() {

}