SECTION "SoundLogic",ROM0


; General Sound Functions -----------------------------------------------------
; -----------------------------------------------------------------------------
sound_enable:

    ; enable both speakers and set to maximum volume
    ld      a,%11111111
    ld      [$ff24],a 

    ; output all channels to both speakers
    ld      [$ff25],a 

    ; reset wave pattern index
    ld      [Channel3LastSampleIndex],a

    ; enable sound engine
    ld      [soundEnabled],a

    ; enable sound circuits
    ld      a,%10000000
    ld      [$ff26],a 

    ret


sound_disable:

    ; disable output of all channels
    xor     a
    ld      [$ff25],a 

    ; disable sound circuits
    ld      [$ff26],a 

    ; disable sound engine
    ld      [soundEnabled],a

    ret

sound_play_effect_two_wait:; a = song id
    ld      c,a
    ld      b,5
    call    _track_get_pointer_hl
    bit     7,[hl]
    ret     nz
    ld      a,c
    jr      sound_play_effect_two

sound_play_effect_one:; a = song id
    push    bc
    ld      b,4
    jr      _sound_play_effect

sound_play_effect_two:; a = song id
    push    bc
    ld      b,5

_sound_play_effect:
    push    de
    ld      de,SoundEffectTable
    add     a; x 2
    add     a,e
    ld      e,a
    adc     a,d
    sub     e
    ld      d,a
    ld      c,%00100000

_sound_load_track:; de = track data, b = track id, c = effect

    push    hl

    ; get pointer to track data
    call    _track_get_pointer_hl

    ; load tempo and looping flag
    ld      a,[de]; 0 - 31
    ld      b,a; copy into b
    inc     de

    ; set effect flag
    or      c

    ; set active flag
    or      %10000000   
    ld      [hli],a; store flag and tempo
    
    ; reset initial tick count to tempo (lower 5 bits)
    ld      a,b
    and     %00011111; mask of flags
    or      %11100000; disable active channel (upper 3 bits all 1)
    ld      [hli],a
    
    ; load pattern index value
    ld      a,[de]

    ; resolve pattern pointer from table via the index
    push    hl
    ld      hl,SoundPatternTable ; table + index * 2

    ; setup addition and copy pointer to table entry into de
    ld      b,0; TODO optimize?
    ld      c,a
    add     hl,bc
    add     hl,bc
    ld      b,h
    ld      c,l

    pop     hl

    ; setup pattern pointer
    ld      a,[bc]
    ld      [hli],a
    inc     bc

    ld      a,[bc]
    ld      [hli],a

    ; setup index pointer and data pointer
    ; these are interleaves for more effective reset later on
    ld      a,d
    ld      [hli],a; high index
    ld      [hli],a; high data
    ld      a,e
    ld      [hli],a; low index
    ld      [hl],a; low data

    pop     hl

    pop     de
    pop     bc

    ret


; Update Active Tracks --------------------------------------------------------
; -----------------------------------------------------------------------------
sound_update:

    ; check if sound is enabled
    ld      a,[soundEnabled]
    cp      0
    ret     z

    ; for all tracks
    ld      b,0
.next_track:
    
    ; get pointer to track data
    call    _track_get_pointer_hl

    ; check if track is active
    ld      a,[hli]
    ld      e,a ; store flags
    bit     7,a
    jr      z,.skip

    ; mask of flags to get tempo
    and     %00011111
    ld      c,a; store tempo

    ; load tick count
.tick:
    ld      a,[hl]
    and     %00011111; mask of channel active flag
    cp      c; check if tickcount === tempo
    jr      nz,.wait
    
    ; reload saved flags 
    ld      c,e

    ; reset tick count to 0
    xor     a
    ld      [hli],a
                
    ; update the track
    push    bc
    call    _update_track
    pop     bc

    ; next track
    jr      .skip

.wait:
    ; increase tick count and store back
    inc     [hl]

.skip:
    inc     b
    ld      a,b
    cp      6
    jr      nz,.next_track

    ; check if channel 1 is active
.sound_update_channel_1:
    ld      a,[Channel1FlagsFreqHi]
    bit     7,a
    jr      z,.sound_update_channel_2

    ; reset active flag
    and     %01111111
    ld      [Channel1FlagsFreqHi],a

    ; set sweep
    ld      a,[Channel1Sweep]
    ld      [$FF10],a
    
    ; set length and duty
    ld      a,[Channel1LengthDuty]
    ld      [$FF11],a
    
    ; Envelope
    ld      a,[Channel1Envelope]
    ld      [$FF12],a

    ; Low Frequency
    ld      a,[Channel1FreqLo]
    ld      [$FF13],a
    
    ; High Frequency / Play again
    ld      a,[Channel1FlagsFreqHi]
    or      %10000000; set active flag
    and     %11000111
    ld      [$FF14],a

.sound_update_channel_2:
    
    ; check if channel 2 is active
    ld      a,[Channel2FlagsFreqHi]
    bit     7,a
    jr      z,.sound_update_channel_3

    ; reset active flag
    and     %01111111
    ld      [Channel2FlagsFreqHi],a

    ; set length and duty
    ld      a,[Channel2LengthDuty]
    ld      [$FF16],a
    
    ; Envelope
    ld      a,[Channel2Envelope]
    ld      [$FF17],a

    ; Low Frequency
    ld      a,[Channel2FreqLo]
    ld      [$FF18],a
    
    ; High Frequency / Play again
    ld      a,[Channel2FlagsFreqHi]
    or      %10000000; set active flag
    and     %11000111
    ld      [$FF19],a

.sound_update_channel_3:

    ; check if channel 3 is active
    ld      a,[Channel3FlagsFreqHi]
    and     %10000000
    jr      z,.sound_update_channel_4

    ; check if wave pattern changed
    ld      a,[Channel3LastSampleIndex]
    ld      b,a
    ld      a,[Channel3SampleIndex]
    cp      b
    jr      z,.play_channel_3

    ; update pattern index and data
    ld      [Channel3LastSampleIndex],a
    
    ; setup pcm sample
    swap    a; x 16

    ld      de,SoundSampleTable
    add     a,e; a = pattern index x 16
    ld      e,a
    adc     a,d
    sub     e
    ld      d,a

    ; load base pointer for wave pattern ram
    ld      hl,$FF30

    ; disable playpack before update
    xor     a
    ld      [$FF1A],a

.load_next_wave_sample:
    ld      a,[de]
    ld      [hli],a
    inc     de
    ld      a,l
    cp      $3f
    jr      nz,.load_next_wave_sample

.play_channel_3:

    ; reset active flag
    ld      a,[Channel3FlagsFreqHi]
    ld      [$FF1A],a; set channel master enable
    and     %01111111
    ld      [Channel3FlagsFreqHi],a

    ; Length 
    ld      a,[Channel3Length]
    ld      [$FF1B],a

    ; OutputLevel
    ld      a,[Channel3OutputLevel]
    ld      [$FF1C],a

    ; set frequency FF1D to frequency lower 8 bits
    ld      a,[Channel3FreqLo]
    ld      [$FF1D],a

    ; High Frequency / Play again
    ld      a,[Channel3FlagsFreqHi]
    or      %10000000; set active flag
    and     %11000111
    ld      [$FF1E],a

.sound_update_channel_4:

    ; check if channel 4 is active
    ld      a,[Channel4Flags]
    bit     7,a
    ret     z

    ; reset active flag
    and     %01111111
    ld      [Channel4Flags],a

    ; set length 
    ld      a,[Channel4Length]
    ld      [$FF20],a
    
    ; Envelope
    ld      a,[Channel4Envelope]
    ld      [$FF21],a

    ; Polynomial
    ld      a,[Channel4Polynomial]
    ld      [$FF22],a

    ; Play again
    ld      a,[Channel4Flags]
    or      %10000000; set active flag
    and     %11000000
    ld      [$FF23],a

    ret


; Internal Track Update Logic -------------------------------------------------
; -----------------------------------------------------------------------------
_update_track:; c = flags

    ; load PatternPointer into DE
    ld      a,[hli]
    ld      e,a
    ld      a,[hl]
    ld      d,a

    ; load high byte of data located at PatternPointer
    ld      a,[de]

    ; check if end of pattern
    cp      $FF
    jr      nz,.play_pattern

    ; restore pattern offset and skip to high byte
    push    hl
    inc     hl

    ; load IndexPointer into DE
    ld      a,[hli]
    ld      d,a
    inc     hl; skip high byte of interleaved data pointer
    ld      a,[hl]
    ld      e,a

    ; increase index pointer and store back
    inc     de
    ld      a,e
    ld      [hld],a;
    dec     hl; skip high byte of interleaved data pointer
    ld      a,d
    ld      [hli],a;

    ; load value from IndexPointer (next pattern value)
    ld      a,[de]

    ; check if effect flag is set (which means the track has only one pattern)
    ld      a,c
    and     %00100000
    jr      nz,.reset_track

    ; check if end of track
    cp      $FF
    jr      nz,.load_pattern

    ; reset IndexPointer to DataPointer
.reset_track:
    inc     hl
    inc     hl
    ld      a,[hld]; load data low
    ld      [hld],a; write index low
    ld      a,[hld]; load data high
    ld      [hl],a; write index high

    ; reload flags
    ld      a,c

    ; substract 4 (this takes only 24 cycles)
    ld      bc,$fffc
    add     hl,bc

    ; check if looping
    bit     6,a
    jr      nz,.load_pattern; if we do, load next pattern

    ; otherwise unset active flag
    and     %01111111
    ld      [hl],a

    ; restore stack, as we don't need the pattern pointer anymore
    pop     hl
    ret

.load_pattern:; de = index pointer

    ; load pattern value from index pointer
    ld      a,[de]

    ; resolve pattern pointer from table via the index
    ld      hl,SoundPatternTable ; table + index * 2
    ld      b,0
    ld      c,a
    add     hl,bc
    add     hl,bc

    ; hl is now the pointer to the pattern table entry
    ld      a,[hli]
    ld      e,a

    ld      a,[hl]
    ld      d,a ; de is now the pointer to the pattern

    ; restore pattern offset and go back to low byte
    pop     hl
    dec     hl

    ; write new pattern pointer to memory
    ld      a,e
    ld      [hli],a
    ld      a,d
    ld      [hl],a; hl is now back at the high byte

.play_pattern: ; hl = high byte of pattern pointer

    ; store NoteIndex into B
    ld      a,[de]
    cp      $ff
    ret     z; check for rest note

    ld      b,a
    inc     de

    ; store InstrumentTableIndex into C
    ld      a,[de]
    ld      c,a
    inc     de

    ; write back increased PatternPointer
    ld      a,d
    ld      [hld],a;
    ld      a,e
    ld      [hl],a;
    ; = 48 cycles

    ; B = note value, C = instrument table index
    ld      hl,SoundNoteFrequencies
    ld      a,b
    add     a; x2
    add     a,l
    ld      l,a
    adc     a,h
    sub     l
    ld      h,a

    ; load frequency into DE
    ld      a,[hli]
    ld      e,a
    ld      a,[hl]
    ld      d,a

    ; load instrument pointer into HL
    ld      hl,SoundInstrumentTable
    ld      b,0
    add     hl,bc
    add     hl,bc
    add     hl,bc
    add     hl,bc

    ; load channel id from instrument and multiply by 5
    ld      a,[hl]
    and     %00000011
    ld      b,a; 
    add     a; x 2
    add     a; x 4
    add     b; x 5

    ; load channel data pointer
    ld      bc,soundChannelsData
    add     a,c; add channel offset
    ld      c,a
    adc     a,b
    sub     c
    ld      b,a

    ; bc = channel data pointer, de = frequency value, hl = instrument data pointer

    ; load continous flag and mask off channel offset
    ld      a,[hl]
    inc     hl
    and     %11000000

    ; add active flag
    or      %10000000

    ; add high frequency
    or      d
    
    ; store channel flags and high frequency
    ld      [bc],a
    inc     bc

    ; store low frequency
    ld      a,e
    ld      [bc],a
    inc     bc
    
    ; copy instrument data to channel
    ld      a,[hli]
    ld      [bc],a
    inc     bc

    ld      a,[hli]
    ld      [bc],a
    inc     bc

    ld      a,[hli]
    ld      [bc],a

    ret


_track_get_pointer_hl:; b = stream index
    ld      h,soundTracksData >> 8; load high byte from aligned track data ram
    ld      a,b
    add     a; x 2 
    add     a; x 4 
    add     a; x 8 
    ld      l,a
    ret


SoundNoteFrequencies:

    ; C3
    DW  $002c, $009c, $0106, $016b, $01c9, $0223, $0277, $02c6, $0312, $0356, $039b, $03da

    ; C4
    DW  $0416, $044e, $0483, $04b5, $04e5, $0511, $053b, $0563, $0589, $05ac, $05ce, $05ed

    ; C5
    DW  $060a, $0627, $0642, $065b, $0672, $0689, $069e, $06b2, $06c4, $06d6, $06e7, $06f7

    ; C6
    DW  $0706, $0714, $0721, $072d, $0739, $0744, $074f, $0759, $0762, $076b, $0773, $077b

    ; C7
    DW  $0783, $078a, $0790, $0797, $079d, $07a2, $07a7, $07ac, $07b1, $07b6, $07ba, $07be

    ; C8
    DW  $07c1, $07c4, $07c8, $07cb, $07ce, $07d1, $07d4, $07d6, $07d9, $07db, $07dd, $07df


