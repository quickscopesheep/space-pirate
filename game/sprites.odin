package game

SPRITE_RUPERT :: Sprite {
    x = 16, y = 0, w = 16, h = 16
}

SPRITE_PLAYER_BODY :: Sprite {
    x = 64, y = 23,
    w = 24, h = 23,
    anchor = {0, 0.5}
}

SPRITE_PLAYER_HEAD :: Sprite {
    x = 64, y = 0,
    w = 14, h = 16,
    anchor = {0, 0.5}
}

SPRITE_PLAYER_FACE :: Sprite {
    x = 80, y = 0,
    w = 12, h = 11
}

SPRITE_PLAYER_LEG :: Sprite {
    x = 89, y = 44,
    w = 6, h = 20,
    anchor = {0, -0.5}
}

SPRITE_PLAYER_ARM :: Sprite {
    x = 89, y = 23,
    w = 4, h = 20,
    anchor = {0, -0.5}
}

SPRITE_FLOOR_GRATE :: Sprite {
    x = 144, y = 48,
    w = 32, h = 32,
}