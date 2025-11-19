package game

import "base:runtime"
import sapp "sokol:app/"

init_cb :: proc "c"() {
    context = runtime.default_context()
    gfx_init(int(sapp.width()), int(sapp.height()))
    game_start()
}

cleanup_cb :: proc "c"() {
    context = runtime.default_context()
    game_exit()
    gfx_shutdown()
}

frame_cb :: proc "c"() {
    context = runtime.default_context()
    game_loop()
}

event_cb :: proc "c"(ev : ^sapp.Event) {
    context = runtime.default_context()
    input_accumulate_event(ev^)
}

main :: proc() {
    sapp.run(sapp.Desc{
        init_cb = init_cb,
        cleanup_cb = cleanup_cb,
        frame_cb = frame_cb,
        event_cb = event_cb
    })
}