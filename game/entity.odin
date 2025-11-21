package game

Entity_Id :: bit_field u32 {
    sparse_id : int | 16,
    gen_id : int | 16
}

Entity :: struct {
    pos : Vec3,
    roll : f32,
    scale : Vec3,

    id : Entity_Id

}

entity_init_array :: proc(game : ^Game) {
    for i in 0..<MAX_ENTITIES-1 {
        game.entities.sparse[i] = i16(i) + 1
    }
    game.entities.sparse[MAX_ENTITIES-1] = -1
}

entity_create :: proc(game : ^Game) -> (id : Entity_Id, ref : ^Entity) {
    if game.entities.dense_next == MAX_ENTITIES do return

    sparse_id := game.entities.sparse_next
    game.entities.sparse_next = game.entities.sparse[sparse_id]

    dense_id := game.entities.dense_next
    game.entities.dense_next += 1

    game.entities.dense[dense_id].id.sparse_id = int(sparse_id)
    game.entities.sparse[sparse_id] = dense_id


    return
}

entity_kill :: proc(game : ^Game, id : Entity_Id) {

}

entity_ref :: proc(game : ^Game, id : Entity_Id) -> (ref : ^Entity) {
    return
}

entity_update :: proc(game : ^Game) {

}

entity_draw :: proc(game : ^Game) {
    
}