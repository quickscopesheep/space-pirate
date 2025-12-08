package input

import "../util"

Key :: enum i32 {
    INVALID = 0,
    SPACE = 32,
    APOSTROPHE = 39,
    COMMA = 44,
    MINUS = 45,
    PERIOD = 46,
    SLASH = 47,
    _0 = 48,
    _1 = 49,
    _2 = 50,
    _3 = 51,
    _4 = 52,
    _5 = 53,
    _6 = 54,
    _7 = 55,
    _8 = 56,
    _9 = 57,
    SEMICOLON = 59,
    EQUAL = 61,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    LEFT_BRACKET = 91,
    BACKSLASH = 92,
    RIGHT_BRACKET = 93,
    GRAVE_ACCENT = 96,
    WORLD_1 = 161,
    WORLD_2 = 162,
    ESCAPE = 256,
    ENTER = 257,
    TAB = 258,
    BACKSPACE = 259,
    INSERT = 260,
    DELETE = 261,
    RIGHT = 262,
    LEFT = 263,
    DOWN = 264,
    UP = 265,
    PAGE_UP = 266,
    PAGE_DOWN = 267,
    HOME = 268,
    END = 269,
    CAPS_LOCK = 280,
    SCROLL_LOCK = 281,
    NUM_LOCK = 282,
    PRINT_SCREEN = 283,
    PAUSE = 284,
    F1 = 290,
    F2 = 291,
    F3 = 292,
    F4 = 293,
    F5 = 294,
    F6 = 295,
    F7 = 296,
    F8 = 297,
    F9 = 298,
    F10 = 299,
    F11 = 300,
    F12 = 301,
    F13 = 302,
    F14 = 303,
    F15 = 304,
    F16 = 305,
    F17 = 306,
    F18 = 307,
    F19 = 308,
    F20 = 309,
    F21 = 310,
    F22 = 311,
    F23 = 312,
    F24 = 313,
    F25 = 314,
    KP_0 = 320,
    KP_1 = 321,
    KP_2 = 322,
    KP_3 = 323,
    KP_4 = 324,
    KP_5 = 325,
    KP_6 = 326,
    KP_7 = 327,
    KP_8 = 328,
    KP_9 = 329,
    KP_DECIMAL = 330,
    KP_DIVIDE = 331,
    KP_MULTIPLY = 332,
    KP_SUBTRACT = 333,
    KP_ADD = 334,
    KP_ENTER = 335,
    KP_EQUAL = 336,
    LEFT_SHIFT = 340,
    LEFT_CONTROL = 341,
    LEFT_ALT = 342,
    LEFT_SUPER = 343,
    RIGHT_SHIFT = 344,
    RIGHT_CONTROL = 345,
    RIGHT_ALT = 346,
    RIGHT_SUPER = 347,
    MENU = 348,
}

Mouse_Button :: enum i32 {
    LEFT = 0,
    RIGHT = 1,
    MIDDLE = 2,
    INVALID = 256,
}

Input_State :: enum {
    PRESSED,
    RELEASED,
    HELD
}

Event_Kind :: enum {
    KEY,
    MOUSE,
    CURSOR,
    SCROLL
}

Event_Action :: enum {
    PRESS,
    RELEASE
}

Event :: struct {
    kind : Event_Kind,
    action : Event_Action,
    key : Key,
    mb : Mouse_Button,
    cursor : util.Vec2,
    scroll : f32
}

@private
Input_Bits :: bit_set[Input_State]

@private
keys : #sparse [Key] Input_Bits
@private
mbs : #sparse [Mouse_Button] Input_Bits

@private
mouse_pos : util.Vec2
@private
delta_mouse_pos : util.Vec2
@private
mouse_scroll : f32
@private
delta_mouse_scroll : f32

@private
events : [64] Event
@private
ev_top : u8

accumulate_event :: proc(ev : Event) {
    events[ev_top] = ev
    ev_top += 1
}

poll_events :: proc() {
    for ev in events[:ev_top] {
        #partial switch ev.kind {
            case .KEY:
                if ev.action == .PRESS do keys[Key(ev.key)] = {.PRESSED, .HELD}
                else do keys[Key(ev.key)] = {.RELEASED}
            case .MOUSE:
                if ev.action == .PRESS do mbs[Mouse_Button(ev.mb)] = {.PRESSED, .HELD}
                else do mbs[Mouse_Button(ev.mb)] = {.RELEASED}
            case .CURSOR:
                last := mouse_pos
                mouse_pos = {ev.cursor.x, ev.cursor.y}
                delta_mouse_pos = mouse_pos - last
            case .SCROLL:
                last := mouse_scroll
                mouse_scroll = ev.scroll
                delta_mouse_scroll = mouse_scroll - last
        }
    }

    ev_top = 0
}

normalise :: proc(num_ticks : int) {
    delta_mouse_pos /= f32(num_ticks)
    delta_mouse_scroll /= f32(num_ticks)
}

reset_temp :: proc() {
    for &key in keys do key &= {.HELD}
    for &mb in mbs do mb &= {.HELD}
}

get_key :: proc(key : Key) -> bool {
    return .HELD in keys[key]
}

get_key_down :: proc(key : Key) -> bool {
    return .PRESSED in keys[key]
}

get_key_up :: proc(key : Key) -> bool {
    return .RELEASED in keys[key]
}

get_mb :: proc(mb : Mouse_Button) -> bool {
    return .HELD in mbs[mb]
}

get_mb_down :: proc(mb : Mouse_Button) -> bool {
    return .PRESSED in mbs[mb]
}

get_mb_up :: proc(mb : Mouse_Button) -> bool {
    return .RELEASED in mbs[mb]
}

get_mouse_pos :: proc() -> util.Vec2 {
    return mouse_pos
}

get_mouse_scroll :: proc() -> f32 {
    return mouse_scroll
}

get_delta_mouse_pos :: proc() -> util.Vec2 {
    return delta_mouse_pos
}

get_delta_mouse_scroll :: proc() -> f32 {
    return delta_mouse_scroll
}