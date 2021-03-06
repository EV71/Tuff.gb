SECTION "Bank1 Data",ROMX,BANK[1]

; Shared Game Data ------------------------------------------------------------
DataBlockDef: 
    INCBIN  "/data/bin/blocks.def.bin" ; 4 rows of 256 bytes each
                                         ; 0 1 which contain the sub tiles for
                                         ; 2 3 each 16x16 block

DataTileCol: ; placed specifically @ 0x4400 for collision checks
    INCBIN  "/data/bin/tiles.col.bin"; 256 byte

DataTileImg:
    INCBIN  "/data/bin/tiles.bg.bin" 

DataTileAnimationImg:
    INCBIN  "/data/bin/animation.bg.bin" 


; Logo ------------------------------------------------------------------------
DataLogoImg:
    INCBIN  "/data/bin/logoTree.bg.bin" 


; Title Screen ----------------------------------------------------------------
DataTitleImg:
    INCBIN  "/data/bin/title.bg.bin" 

DataTitleLayout:
    DB      $10,$11,$12,$13
    DB      $14,$15,$16,$17,$18,$19

DataTitleSprite:
    INCBIN  "/data/bin/title.ch.bin" 

DataTitleSpriteLayout:

    ; Upper Part of T
    DB      0, 0 + DATA_TITLE_SPRITE_X,$60,$10
    DB      0, 8 + DATA_TITLE_SPRITE_X,$62,$10
    DB      0,16 + DATA_TITLE_SPRITE_X,$64,$10
    DB      0,24 + DATA_TITLE_SPRITE_X,$66,$10
    DB      0,32 + DATA_TITLE_SPRITE_X,$68,$10
    DB      0,40 + DATA_TITLE_SPRITE_X,$6A,$10

    ; Middle Part of T
    DB      0,12 + DATA_TITLE_SPRITE_X,$6C,$10

    ; Lower Part of T
    DB      0,12 + DATA_TITLE_SPRITE_X,$76,$10

    ; Left Half of U
    DB      0,22 + DATA_TITLE_SPRITE_X,$6E,$10

    ; Right Half of U
    DB      0,36 + DATA_TITLE_SPRITE_X,$70,$10

    ; Lower Parts of U
    DB      0,22 + DATA_TITLE_SPRITE_X,$78,$10
    DB      0,30 + DATA_TITLE_SPRITE_X,$7A,$10
    DB      0,36 + DATA_TITLE_SPRITE_X,$7C,$10

    ; First F
    DB      0,46 + DATA_TITLE_SPRITE_X,$72,$10
    DB      0,54 + DATA_TITLE_SPRITE_X,$74,$10
    DB      0,46 + DATA_TITLE_SPRITE_X,$7E,$10

    ; Second F
    DB      0,64 + DATA_TITLE_SPRITE_X,$72,$10
    DB      0,72 + DATA_TITLE_SPRITE_X,$74,$10
    DB      0,64 + DATA_TITLE_SPRITE_X,$7E,$10

DataTitleSpriteLayoutAnimation:
    DB      0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 6
    DB      6, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 1, 1, 1, 0

DataTitleSpriteLayoutYOffsets:
    DB      8, 8, 8, 8, 8, 8,24,40,24,24,40,40,40,24,24,40,24,24,40


; Everything else -------------------------------------------------------------
DataPlayerImg:
    INCBIN  "/data/bin/player.ch.bin" 

DataEntityImg:
    INCBIN  "/data/bin/entities.ch.bin" 

DataSpriteAnimation:
    INCLUDE "animation/player.gb.s"
    INCLUDE "animation/entity.gb.s"

DataTileAnimation:
    INCLUDE "animation/tile.gb.s"

DataEntityDefinitions:
    INCLUDE "entities/entities.gb.s"

DataCutsceneDefinitions:
    INCLUDE "cutscenes/cutscenes.gb.s"

DataScriptDefinitions:
    INCLUDE "scripts/scripts.gb.s"

DataSoundDefinitions:
    INCLUDE "sound/data.gb.s"

