package game

import "base:runtime"
import "core:mem"
import "core:math"
import "core:time"

import "core:fmt"

Game :: struct {
    entities : Entity_Array,
    player : Entity_Id
}

DT :: 1 / 60.0

prev_time := time.tick_now()
acc : f64

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

game_draw :: proc(alpha : f64) {
    gfx_set_coord_mode(.VIEW_PROJECTED)
    entity_draw(alpha)
}

game_loop :: proc() {
    input_poll_events()

    frame_duration := time.duration_seconds(time.tick_since(prev_time))
    prev_time = time.tick_now()

    acc += frame_duration
    num_ticks := int(math.floor(acc / DT))
    acc -= f64(num_ticks) * DT

    if num_ticks > 0 {
        input_normalise(num_ticks)
        for i in 0..<num_ticks {
            game_tick()

            input_reset_temp()
        }
    }
    
    alpha := acc / DT

    game_draw(alpha)
    gfx_execute()

    free_all(context.temp_allocator)
}