package game

import "base:runtime"
import "core:mem"
import "core:time"

import stdmath "core:math"

import "core:fmt"

import "math"
import "input"
import "gfx"

Game :: struct {
    entities : Entity_Array,
    player : Entity_Id
}

GAME_DELTA_TIME :: 1 / 60.0

@(private="file")
prev_time := time.tick_now()
@(private="file")
acc : f64

@(private="file")
elapsed_time : f64

game : Game

game_start :: proc() {
    entity_init_array(&game.entities)

    game.player, _ = entity_create(&game.entities, .PLAYER)
}

game_exit :: proc() {

}

game_tick :: proc() {
    entity_update()
}

game_draw :: proc(alpha : f32) {
    gfx.begin()
    entity_draw(alpha)
    gfx.end()
}

game_loop :: proc() {
    input.poll_events()

    frame_duration := time.duration_seconds(time.tick_since(prev_time))
    prev_time = time.tick_now()

    acc += frame_duration
    num_ticks := int(stdmath.floor(acc / GAME_DELTA_TIME))
    acc -= f64(num_ticks) * GAME_DELTA_TIME

    if num_ticks > 0 {
        input.normalise(num_ticks)
        for i in 0..<num_ticks {
            elapsed_time += GAME_DELTA_TIME
            game_tick()

            input.reset_temp()
        }
    }

    elapsed_time += acc
    alpha := f32(acc / GAME_DELTA_TIME)

    game_draw(alpha)

    free_all(context.temp_allocator)
}