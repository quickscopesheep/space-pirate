#+private file
package game

import "core:mem"
import "core:math"
import "core:time"

import "core:fmt"

Game :: struct {

}

@private
DT :: 1 / 50.0

prev_time := time.now()
acc : f64

@private
game : Game
@private
prev_game : Game

@private
game_start :: proc() {
    
}

@private
game_exit :: proc() {

}

game_tick :: proc() {

}

game_draw :: proc(alpha : f64) {
    gfx_push_cmd({
        xform = xform_make(scale = {0.25, 0.25, 1}),
        tint = Vec4{1, 0, 1, 1}
    })
}

@private
game_loop :: proc() {
    input_poll_events()

    frame_duration := time.duration_seconds(time.since(prev_time))
    prev_time := time.now()

    acc += frame_duration
    num_ticks := int(math.floor(acc / DT))
    acc -= f64(num_ticks) * DT

    if num_ticks > 0 {
        input_normalise(num_ticks)
        for i in 0..<num_ticks {
            mem.copy_non_overlapping(&prev_game, &game, size_of(Game))
            game_tick()

            input_reset_temp()
        }
    }
    
    alpha := acc / DT

    game_draw(alpha)
    gfx_execute()
}