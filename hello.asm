include 'dma.asm'

org #1200

; Firmware functions
; https://www.cpcwiki.eu/index.php/BIOS_Function_Summary
TXT_OUTPUT 		equ #bb5a	; prints contents of A
KM_GET_JOYSTICK	equ #bb24	; returns ---FRLDU into A/H (js0), L (js1)

; Positions of button bit positions
BTN_UP			equ 0
BTN_DOWN		equ 1
BTN_LEFT		equ 2
BTN_RIGHT		equ 3
BTN_FIRE		equ 4

PlayerPosX:			dw #0000
PlayerPosY:			dw #0040
PlayerPrevPosX:		dw #0000
PlayerPrevPosY:		dw #0040

macro CheckButton val, or_label
	bit {val}, a
	jr z, {or_label}
mend

Start:
	call PlusInit
	
	ld bc, #7fb8	; Page in Plus registers
	out (c), c		; ASIC rambank is at #4000 - #7FFFF

	ld hl, DmaList
	ld (DMA0_ADDR), hl	; Set DMA channel 0 address
	ld a, 0
	ld (DMA0_SCALE), a	; Set prescaler
	ld a, #01
	ld (DMA_CTL), a		; Enable DMA channel 0

	ld bc, #7fa0
	out (c), c		; Pake out Plus registers
	
MainLoop:
	call ReadInput
	or a
	jr z, MainLoop

	push af
		; Record player previous X/Y
		ld de, (PlayerPosX)
		ld (PlayerPrevPosX), de
		ld hl, (PlayerPosY)
		ld (PlayerPrevPosY), hl

		push hl, de
		ld bc, EmptySprite
		call DrawSprite8x8
		pop de, hl
	pop af

	; Handle input
	CheckButton BTN_UP, JoyNotUp
	inc hl
JoyNotUp:
	CheckButton BTN_DOWN, JoyNotDown
	dec hl
JoyNotDown:
	CheckButton BTN_LEFT, JoyNotLeft
	dec de
JoyNotLeft:
	CheckButton BTN_RIGHT, JoyNotRight
	inc de
JoyNotRight:
	ld (PlayerPosX), de
	ld (PlayerPosY), hl

	ld bc, TestSprite
	call DrawSprite8x8

	ld bc, 500
	call PauseBC

	jp MainLoop

; Read the input and store in a, updates f
ReadInput:
	call KM_GET_JOYSTICK
	ret

; de - x-pos
; hl - y-pos
; bc - sprite address
DrawSprite8x8:
	push bc
	call #bc1d	; return pixel address in HL
	pop de 		; sprite to draw
	ld b, 8
DrawSprite8x8Line:
	push hl
	ld a,(de)
	ld (hl),a
	inc de
	inc hl
	ld a,(de)
	ld (hl),a
	inc de
	inc hl
	pop hl
	call #bc26
	djnz DrawSprite8x8Line
	ret

TestSprite:
db %00110000,%11000000
db %01110000,%11100000
db %11110010,%11110100
db %11110000,%11110000
db %11110000,%11110000
db %11010010,%10110100
db %01100001,%01101000
db %00110000,%11000000

EmptySprite:
db %00000000,%00000000
db %00000000,%00000000
db %00000000,%00000000
db %00000000,%00000000
db %00000000,%00000000
db %00000000,%00000000
db %00000000,%00000000
db %00000000,%00000000

PauseBC:
	dec bc
	ld a, b
	or c
	jr nz, PauseBC
	ret

PlusInit:
	di
	ld b, #bc
	ld hl, PlusInitSequence
	ld e, 17
PlusInitLoop:
	ld a, (hl)
	out (c), a
	inc hl
	dec e
	jr nz, PlusInitLoop
	ei
	ret
PlusInitSequence:
	db #ff, #00, #ff, #77, #b3, #51, #a8, #d4, #62, #39, #9c, #46, #2b, #15, #8a, #cd, #ee

	align 2
DmaList:
	DMA_REPEAT #100
	DMA_SET AY_REG_MIXER, (AY_MIX_B_ENABLE | AY_MIX_B_NOISE_ENABLE) ^ #ffff
	DMA_SET AY_REG_MIXER, %00111101
	DMA_SET AY_REG_NOISE, %00001011
	DMA_SET AY_REG_VOLUME_B, #0f
	DMA_SET AY_REG_TONE_B_COARSE, #01
	DMA_PAUSE 300 * 10
	DMA_SET AY_REG_MIXER, #ffff
	DMA_PAUSE 300 * 10
	DMA_LOOP
	DMA_INT
	DMA_STOP

