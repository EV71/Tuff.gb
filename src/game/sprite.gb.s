SECTION "SpriteLogic",ROM0


; Sprite Animation Update -----------------------------------------------------
sprite_animate_all:
    ld      b,0 ; loop counter
    
.update_loop:

    ; check if active and animating
    ld      a,b
    call    _sprite_meta_offset

    ; load flags
    ld      a,[hli]

    ; check if active
    bit     0,a
    jr      z,.next_sprite

    ; check if animating
    bit     2,a
    jr      z,.next_sprite

    ; load animation frame number
    ld      c,[hl] 
    inc     hl

    ; load animation id
    ld      l,[hl] 
    ld      h,0

    ; multiply by 32 to get into the animation table offset
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl

    ; add the animation table base address
    ld      de,DataSpriteAnimation
    add     hl,de

    ; add the current frame index
    ld      d,0
    ld      e,c
    add     hl,de ; hl is the data offset

    ; now update the sprite to the tile index
    ld      d,a; store sprite flags
    ld      a,b ; sprite index (counter)
    ld      b,[hl] ; ; get tile for animation index (16x16 sprite tile )
    call    sprite_set_tile_index
    ld      b,a ; restore sprite counter
    ld      a,d; restore sprite flags

    ; Restore flags
    call    _sprite_update_animation

.next_sprite:
    inc    b
    ld     a,b
    cp     20 ; 20 sprites overall
    jr     nz,.update_loop
    ret


_sprite_update_animation: ; a = sprite flags, hl = animation data base offset

    ; load frame timing data
    ld      d,0
    ld      e,16
    add     hl,de
    ld      e,[hl]


    ; update number of frames left for this animation index
    ld      d,a
    ld      a,b ; sprite index (counter)
    call    sprite_animation_timer
    cp      0 
    ret     nz ; if there are still frames to play, dont advance index


    ; advance frame index based on direction
    bit     4,d
    jr      nz,.backwards

.forwards:
    inc     c ; next animation frame
    inc     hl ; next frame value

.update_mode:

    ; load new frame timing data
    ld      a,[hl]

    ; if it is a stop frame do nothing
    cp      $ff
    ret     z

    ; if it is a loop frame jump back to the first frame
    cp      $fe
    jr      z,.loop

    ; if it is a bounce frame toggle the bounce direction 
    cp      $fd
    jr      z,.bounce
    jr      .update

.backwards:
    dec     c ; previous animation frame
    dec     hl ; previous frame value
    jr      .update_mode

    ; reset frame number for looping
.loop:
    ld      c,1

    ; store the new animation index
.update:
    ld      a,b ; sprite index (counter)
    call    _sprite_meta_offset
    inc     hl
    ld      [hl],c ; store new frame number
    inc     hl ; skip animation id
    inc     hl
    ld      [hl],0 ; reset timing data
    ret

    ; toggle bounce direction
.bounce:
    bit     4,d; backwards flag
    jr      z,.switch_to_backwards

.switch_to_forwards:
    ld      a,b
    call    sprite_animation_forward
    inc     c
    jr      .update

.switch_to_backwards:
    ld      a,b
    call    sprite_animation_backward
    dec     c
    jr      .update


sprite_animation_timer: ; a = sprite index, e = frame count, a -> frames left

    push    hl

    call    _sprite_meta_offset
    inc     hl ; skip flags
    inc     hl ; skip skip id
    inc     hl ; go to frames left
    ld      a,[hl] ; a now has the number of frames left

    ; if zero frames are left, initialize them 
    cp      0
    jr      nz,.decrease
    ld      a,e
    dec     a; This is done since otherwise we'll get one extra frame playing
    ld      [hl],a
    jr      .done

    ; otherwise decrease it and put the value into a
.decrease:
    dec     a
    ld      [hl],a

.done:
    pop     hl
    ret



; Animation Controls ----------------------------------------------------------
sprite_animation_set: ; a = sprite index, b = animation id

    push    hl
    push    de
    push    bc

    call    _sprite_meta_offset
    inc     hl; skip flags
    ld      [hl],1 ; reset frame (0 and 15 are option frames)
    inc     hl
    ld      [hl],b ; set id
    inc     hl

    ; add the animation table base address
    ld      l,b
    ld      h,0

    ; multiply by 32 to get into the animation table offset
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl

    ; add base offset
    ld      de,DataSpriteAnimation
    add     hl,de
    inc     hl

    ; now update the sprite to the tile index
    ld      b,[hl] ; 16x16 sprite tile 
    call    sprite_set_tile_index

    pop     bc
    pop     de
    pop     hl
    ret


sprite_animation_start: ; a = sprite index

    push    af
    push    hl
    push    bc

    call    _sprite_meta_offset
    ld      a,[hl]
    or      %00000100 ; set animating
    ld      [hli],a
    ld      a,1
    ld      [hli],a ; set current animation frame
    ld      a,[hli]; load animation id
    ld      b,a

    ; set frames left
    push    de
    push    hl

    ; calculate the animation offset from the id
    ld      l,b
    ld      h,0

    ; multiply by 32 to get into the animation table offset
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl
    add     hl,hl

    ; add base offset
    ld      de,DataSpriteAnimation + 17; get timing data of first frame
    add     hl,de
    ld      a,[hl]
    pop     hl; restore sprite data offset
    ld      [hl],a ; set frames left

    pop     de
    pop     bc

    pop     hl
    pop     af
    ret


sprite_animation_pause: ; a = sprite index
    push    hl
    call    _sprite_meta_offset
    res     2,[hl] ; unset animating flag
    pop     hl
    ret


sprite_animation_resume: ; a = sprite index
    push    hl
    call    _sprite_meta_offset
    set     2,[hl] ; set animating flag
    pop     hl
    ret


sprite_animation_stop: ; a = sprite index

    push    hl

    call    _sprite_meta_offset
    res     2,[hl] ; unset animating flag

    ; reset animation frame
    inc     hl
    ld      [hl],1 ; 0 and 15 are border frames

    pop     hl
    ret


sprite_animation_forward: ; a = sprite index
    push    hl
    call    _sprite_meta_offset
    res     4,[hl]; unset backwards flag
    pop     hl
    ret

sprite_animation_backward: ; a = sprite index
    push    hl
    call    _sprite_meta_offset
    set     4,[hl]; set backwards flag
    pop     hl
    ret


sprite_set_palette: ; a = sprite index, b = palette (0 or 16)
    push    af
    push    hl
    push    de

    ld      e,a ; store index
    call    _sprite_meta_offset

    ld      d,3
    call    _sprite_get_left
    ld      a,[hl]
    and     %11100000 ; clear palette bit
    or      b
    ld      [hl],a

    ld      d,3
    call    _sprite_get_right
    ld      a,[hl]
    and     %11100000 ; clear palette bit
    or      b
    ld      [hl],a

    pop     de
    pop     hl
    pop     af
    ret


; Sprite Control --------------------------------------------------------------
sprite_enable: ; a = sprite index
    push    hl
    call    _sprite_meta_offset
    ld      [hl],1
    pop     hl
    ret


sprite_disable: ; a = sprite index
    push    hl
    push    bc

    ; reset all flags
    call    _sprite_meta_offset
    ld      [hl],0 

    ; reset tile index
    ld      b,0
    call    sprite_set_tile_index

    ; reset position
    ld      b,0
    ld      c,0
    call    sprite_set_position

    ; reset palette
    ld      b,0
    call    sprite_set_palette

    pop     bc
    pop     hl
    ret


sprite_set_tile_offset: ; a = sprite, b = tile offset

    push    af
    push    hl

    ; multiple tile offset by 4
    sla     b
    sla     b
    call    _sprite_meta_offset
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    ld      [hl],b ; store offset

    pop     hl
    pop     af

    ret


sprite_set_tile_index: ; a = sprite index, b = tile index

    push    af
    push    hl
    push    de

    ; multiple tile index by 4
    sla     b
    sla     b

    ld      e,a ; store index for get_left / get_right
    call    _sprite_meta_offset
    ld      d,[hl]; store flags

    ; add tile offset
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    ld      a,[hl]
    add     b
    ld      b,a

    ; check flags
    ld      a,d
    and     %00000010
    jr      z,.not_mirrored

.mirrored:

    ld      d,2
    call    _sprite_get_left
    ld      [hl],b
    inc     hl
    set     5,[hl]

    call    _sprite_get_right
    ld      a,b
    add     2
    ld      [hli],a
    set     5,[hl]

    jr     .index_done

.not_mirrored:
    ld      d,2
    call    _sprite_get_left
    ld      [hl],b
    inc     hl
    res     5,[hl]

    call    _sprite_get_right
    ld      a,b
    add     2
    ld      [hli],a
    res     5,[hl]

.index_done:
    pop     de
    pop     hl
    pop     af
    ret


sprite_set_position: ; a = sprite index, b = xpos, c = ypos

    push    hl
    push    de

    ld      e,a ; store index

    ; add scroll offset
    ld      a,[coreScrollX]
    cp      0
    jr      z,.no_x_offset
    ld      d,a
    ld      a,b
    sub     d
    ld      b,a

.no_x_offset:
    ld      a,[coreScrollY]
    cp      0
    jr      z,.no_y_offset
    ld      d,a
    ld      a,c
    sub     d
    ld      c,a

.no_y_offset:
    ld      a,e
    call    _sprite_meta_offset
    ld      a,[hl]
    and     %00000010
    jr      z,.not_mirrored
.mirrored:

    ld      d,0
    call    _sprite_get_right
    ld      [hl],c
    inc     hl
    ld      [hl],b

    call    _sprite_get_left
    ld      [hl],c
    inc     hl
    ld      a,b
    add     a,8
    ld      [hl],a

    jr     .pos_done

.not_mirrored:
    ld      d,0
    call    _sprite_get_left
    ld      [hl],c
    inc     hl
    ld      [hl],b
    
    call    _sprite_get_right
    ld      [hl],c
    ld      a,b
    add     a,8
    inc     hl
    ld      [hl],a
    

.pos_done:
    pop     de
    pop     hl
    ret


sprite_set_mirror: ; a = sprite index
    push    hl
    call    _sprite_meta_offset
    set     1,[hl]; set mirror flag
    pop     hl
    ret


sprite_unset_mirror: ; a = sprite index
    push    hl
    call    _sprite_meta_offset
    res     1,[hl]; unset mirror flag
    pop     hl
    ret


; Helper ----------------------------------------------------------------------
_sprite_get_left: ; e = raw index, d = value byte offset
    ld      h,spriteData >> 8; high byte, needs to be aligned at 256 bytes
    ld      a,e
    add     a
    add     a
    add     a
    add     a,d
    ld      l,a
    ret


_sprite_get_right: ; e = raw index, d = value byte offset
    ld      h,spriteData >> 8; high byte, needs to be aligned at 256 bytes
    ld      a,e
    add     a
    add     a
    add     a
    add     a,d
    add     a,4; skip one hardware sprite
    ld      l,a
    ret


_sprite_meta_offset: ; a = sprite index -> hl = offset
    ld      h,spriteMeta >> 8; high byte, needs to be aligned at 256 bytes
    ld      l,a
    sla     l
    sla     l
    sla     l
    ret

