entity_handler_load_gem:; b = entity index, c = sprite index
    ld      a,c
    ld      b,ENTITY_ANIMATION_OFFSET + ENTITY_ANIMATION_GEM
    call    new_sprite_set_animation
    inc     e; skip type
    ld      a,[de]; check collection flag
    ret
    
entity_handler_update_gem: ; b = entity index, c = sprite index, de = screen data

    inc     e; skip type
    ld      a,[de]; check flags
    cp      1
    ret     z

    inc     e; skip flags
    inc     e; skip direction

    ; check for collection
    call    entity_col_player
    cp      0
    ret     z

    ; disable entity
    dec     e
    dec     e; back to direction
    dec     e; back to flags
    ld      a,1
    ld      [de],a
    dec     e; back to type

    ; disable entity
    ld      a,$ff
    ld      [de],a

    ; flash screen
    ld      a,SCREEN_PALETTE_FLASH_FAST | SCREEN_PALETTE_LIGHT
    call    screen_animate

    ret

