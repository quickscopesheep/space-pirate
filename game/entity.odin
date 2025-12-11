package game

import "core:fmt"
import "core:mem"

import "gfx"
import "math"
import "input"

MAX_ENTITIES :: 256

Entity_Kind :: enum{
    PLAYER
}

Entity_Dir :: enum {
    NORTH,
    SOUTH,
    EAST,
    WEST
}

Entity_Id :: bit_field u32 {
    sparse_id : int | 16,
    uid : int | 16
}

Entity :: struct {
    id : Entity_Id,
    kind : Entity_Kind,

    pos, last_pos : math.Vec3,

    roll, last_roll : f32,
    scale : math.Vec3,

    dir : f32
}

Entity_Array :: struct{
    dense : [MAX_ENTITIES] Entity,
    dense_next : i16,

    sparse : [MAX_ENTITIES] i16,
    sparse_next : i16,

    uid_next : i16
}

entity_init_array :: proc(arr : ^Entity_Array) {
    for i in 0..<MAX_ENTITIES-1 {
        arr.sparse[i] = i16(i) + 1
    }
    arr.sparse[MAX_ENTITIES-1] = -1
}

entity_ref :: proc(arr : ^Entity_Array, id : Entity_Id) -> (ref : ^Entity) {
    if !entity_valid(arr, id) do return nil
    return &arr.dense[arr.sparse[id.sparse_id]]
}

entity_valid :: proc(arr : ^Entity_Array, id : Entity_Id) -> bool {
    if id.sparse_id < 0 || id.sparse_id >= MAX_ENTITIES do return false
    if id.uid != arr.dense[id.sparse_id].id.uid do return false
    return true
}

entity_create :: proc(arr : ^Entity_Array, kind : Entity_Kind) -> (id : Entity_Id, ref : ^Entity) {
    if arr.dense_next == MAX_ENTITIES do return

    sparse_id := arr.sparse_next
    arr.sparse_next = arr.sparse[sparse_id]

    dense_id := arr.dense_next
    arr.dense_next += 1

    ref = &arr.dense[dense_id]

    mem.zero(ref, size_of(Entity))

    ref.id = Entity_Id{
        sparse_id = int(sparse_id),
        uid = int(arr.uid_next)
    }

    ref.kind = kind

    arr.uid_next += 1

    arr.sparse[sparse_id] = dense_id

    switch ref.kind{
        case .PLAYER:

        case:
            break
    }

    return
}

entity_kill :: proc(arr : ^Entity_Array, id : Entity_Id) {
    if !entity_valid(arr, id) do return
    ref := entity_ref(arr, id)

    #partial switch ref.kind{
        case:
            break
    }

    last_id := arr.dense[arr.dense_next-1].id

    arr.dense[arr.sparse[last_id.sparse_id]].id.sparse_id = id.sparse_id
    arr.sparse[last_id.sparse_id] = arr.sparse[id.sparse_id]
    arr.sparse[id.sparse_id] = arr.sparse_next
    arr.sparse_next = i16(id.sparse_id)
    arr.dense_next -= 1

    mem.copy(&arr.dense[arr.sparse[id.sparse_id]], &arr.dense[arr.dense_next-1], size_of(Entity))
}

entity_update :: proc() {
    for i in 0..<game.entities.dense_next {
        ref := &game.entities.dense[i]
        switch ref.kind {
            case .PLAYER:
                player_update(ref)
            case:
                break
        }

        ref.last_pos = ref.pos
        ref.last_roll = ref.roll
    }
}

entity_draw :: proc(alpha : f32) {
    for i in 0..<game.entities.dense_next {
        ref := &game.entities.dense[i]
        switch ref.kind {
            case .PLAYER:
                player_draw(ref, alpha)
            case:
                break
        }
    }
}

player_update :: proc(ref : ^Entity) {

}

player_draw :: proc(ref : ^Entity, alpha : f32) {
    
}