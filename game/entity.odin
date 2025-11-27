package game

import "core:fmt"
import "core:mem"

import "core:math"
import "core:math/linalg"

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

    pos, last_pos : Vec3,

    roll, last_roll : f32,
    scale : Vec3,

    //player
    dir : Vec2,
    moving : bool,
    walk_anim_time : f32
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

PLAYER_SPEED :: 8.0

player_update :: proc(ref : ^Entity) {
    input_vect := Vec3{}

    if input_key(.W) do input_vect += Vec3{0, -1, 0}
    if input_key(.S) do input_vect += Vec3{0, 1, 0}
    if input_key(.A) do input_vect += Vec3{-1, 0, 0}
    if input_key(.D) do input_vect += Vec3{1, 0, 0}

    if linalg.length(input_vect) > 0.0 do input_vect = linalg.normalize(input_vect)

    if linalg.length(input_vect) > 0.0 do ref.dir = input_vect.xy
    if input_vect.x != 0 && input_vect.y == 0 do ref.dir.y = 1

    ref.moving = linalg.length(input_vect) > 0.0
    if ref.moving{
        ref.walk_anim_time += DT
    }else {
        ref.walk_anim_time = 0
    }

    ref.pos += input_vect * PLAYER_SPEED * DT
}

HEAD_OFFSET_Y :: -1.42
FACE_OFFSET_Y :: -0.5
FACE_OFFSET_X :: 0.2

ARM_OFFSET_X :: 0.62
ARM_OFFSET_Y :: -1.42

LEG_OFFSET_X :: 0.3

MAX_LEG_ANGLE :: 15
WALK_ANGLE_SPEED :: 2 * math.PI * (1 / 0.6)

LEG_LENGTH :: 20.0 / 16.0

player_draw :: proc(ref : ^Entity, alpha : f32) {
    player_xfrom := xform_make(pos = lerp(ref.last_pos, ref.pos, alpha), roll = lerp(ref.last_roll, ref.roll, alpha))

    draw_world_sprite(player_xfrom * xform_make(), SPRITE_PLAYER_BODY)
    draw_world_sprite(player_xfrom * xform_make(pos = {0, HEAD_OFFSET_Y, 0}), SPRITE_PLAYER_HEAD)

    if ref.dir.y > 0 {
        face_offset_x := FACE_OFFSET_X * ref.dir.x
        draw_world_sprite(player_xfrom * xform_make(pos = {face_offset_x, HEAD_OFFSET_Y + FACE_OFFSET_Y, 0}),
            SPRITE_PLAYER_FACE)
    }

    limb_rot := ref.moving ? math.sin(ref.walk_anim_time * WALK_ANGLE_SPEED) * MAX_LEG_ANGLE : 0

    //left arm
    draw_world_sprite(player_xfrom * xform_make(
        pos = {-ARM_OFFSET_X, ARM_OFFSET_Y, 0},
        roll = roll_make(-limb_rot),
        scale = {1, 1, 1}),
        SPRITE_PLAYER_ARM
    )

    //right arm
    draw_world_sprite(player_xfrom * xform_make(
        pos = {ARM_OFFSET_X, ARM_OFFSET_Y, 0},
        roll = roll_make(limb_rot),
        scale = {1, 1, 1}),
        SPRITE_PLAYER_ARM
    )

    //left leg
    draw_world_sprite(player_xfrom * xform_make(
        pos = {-LEG_OFFSET_X, 0, 0},
        roll= roll_make(limb_rot),
        scale = {1, 1, 1}),
        SPRITE_PLAYER_LEG)

    //right leg
    draw_world_sprite(player_xfrom * xform_make(
        pos = {LEG_OFFSET_X, 0, 0},
        roll=roll_make(-limb_rot),
        scale = {1, 1, 1}),
        SPRITE_PLAYER_LEG
    )
}