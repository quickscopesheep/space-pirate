package game

import "base:runtime"
import sapp "sokol:app/"

import "input"
import "gfx"

init_cb :: proc "c"() {
    context = runtime.default_context()
    gfx.setup(int(sapp.width()), int(sapp.height()))
    game_start()
}

cleanup_cb :: proc "c"() {
    context = runtime.default_context()
    game_exit()
    gfx.shutdown()
}

frame_cb :: proc "c"() {
    context = runtime.default_context()
    game_loop()
}

event_cb :: proc "c"(ev : ^sapp.Event) {
    context = runtime.default_context()
    #partial switch ev.type {
        case .KEY_DOWN:
            if ev.key_repeat do break
            input.accumulate_event({
                kind = .KEY,
                action = .PRESS,
                key = input.Key(ev.key_code)
            })
        case .KEY_UP:
            input.accumulate_event({
                kind = .KEY,
                action = .RELEASE,
                key = input.Key(ev.key_code)
            })
        case .MOUSE_DOWN:
            input.accumulate_event({
                kind = .MOUSE,
                action = .PRESS,
                mb = input.Mouse_Button(ev.mouse_button)
            })
        case .MOUSE_UP:
            input.accumulate_event({
                kind = .MOUSE,
                action = .RELEASE,
                mb = input.Mouse_Button(ev.mouse_button)
            })
        case .MOUSE_MOVE:
            input.accumulate_event({
                kind = .CURSOR,
                cursor = {ev.mouse_x, ev.mouse_y}
            })
        case .MOUSE_SCROLL:
            input.accumulate_event({
                kind = .SCROLL,
                scroll = ev.scroll_y
            })
    }
}

main_get_width :: proc() -> int {
    return int(sapp.width())
}

main_get_height :: proc() -> int {
    return int(sapp.height())
}

main :: proc() {
    sapp.run(sapp.Desc{
        init_cb = init_cb,
        cleanup_cb = cleanup_cb,
        frame_cb = frame_cb,
        event_cb = event_cb
    })
}
