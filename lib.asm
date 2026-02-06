; Initialize Plus features
; Interrupts must be disabled prior
PlusInit:
	ld b, #bc
	ld hl, PlusInit_Sequence
	ld e, 17
PlusInit_Loop:
	ld a, (hl)
	out (c), a
	inc hl
	dec e
	jr nz, PlusInit_Loop
	ret
PlusInit_Sequence:
	db #ff, #00, #ff, #77, #b3, #51, #a8, #d4
	db #62, #39, #9c, #46, #2b, #15, #8a, #cd
	db #ee

; Pause for 16 bit duration stored in BC
; A => clobbered
; BC => 0
PauseBC:
	dec bc
	ld a, b
	or c
	jr nz, PauseBC
	ret

; Fill BC bytes starting at (HL) with A
; BC must be > 1
; BC => 0
; DE, HL => clobbered
Fill:
    ld de, hl
    inc de
    ld (hl), a
    dec bc
    ldir
    ret

; Page in ASIC registers to $4000-$7FFF
; Grim - https://www.cpcwiki.eu/forum/index.php?msg=4593
; ASICPageIn and ASICPageOut must be called with interrupts disabled
; ASICPageRestore is called from an ISR to restore ASIC page state to whatever
; userland was doing prior.
ASICPageIn:
    ld bc, $7fb8
    jr ASICPageIn_SetPage
ASICPageOut:
    ld bc, $7fa0
ASICPageIn_SetPage:
    ld (ASICPageRestore+1), bc
ASICPageRestore:
    ld bc, 0
    out (c), c
    ret
