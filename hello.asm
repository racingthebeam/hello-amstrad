include 'dma.asm'
include 'crtc.asm'
include 'constants.asm'
include 'macros.asm'
	
macro CRTC_SET_BANNER
	CRTC_WRITE_REG $0C, %00010000 ; $4000, 16K
mend

macro CRTC_SET_GAMEPLAY
	CRTC_WRITE_REG $0c, %00110000 ; $C000, 16K
mend

org $1200

BANNER_SCREEN		equ $4000
GAMEPLAY_SCREEN		equ $c000	
SPLIT_LINE			equ 32
RESTORE_LINE		equ 192



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

Scroll:		db 0
	

go:
	; Set CRTC to 256x192
	CRTC_WRITE_REG $00, 63
	CRTC_WRITE_REG $01, 32
	CRTC_WRITE_REG $02, 42
	CRTC_WRITE_REG $03, 134
	CRTC_WRITE_REG $06, 24
	CRTC_WRITE_REG $07, 31
	CRTC_WRITE_REG $0c, %00010000 ; screen addr = $4000, 16K

	; Fill screen
	ld a, $f6
	ld bc, 16384
	ld hl, GAMEPLAY_SCREEN
	call Fill
	
	; Fill banner
	ld a, $9c
	ld bc, 16384
	ld hl, $4000
	call Fill

	di
	im 1			; setup the IM1 ISR
	ld a,$C3
	ld hl,isr_screenmode
	ld ($38),a
	ld ($39),hl

	call PlusInit
	call ASICPageIn

	; ld hl,colours		;copy colours into ASIC palette registers
	; ld de,$6400
	; ld bc,17*2
	; ldir

	ld a, SPLIT_LINE
	ld ($6800), a	; set the raster interrupt scanline (PRI)
	ld ($6801), a	; set the splitscreen scanline (SPLT)
	ld hl, $0030	; set the splitscreen address (SSA) for the bottom 3 rows
	ld ($6802), hl	; (caution => SSA is a 16bit big endian register!!!)
	
	call ASICPageOut	;page-out asic registers
	ei
	
scroll_loop:
	jr scroll_loop


isr_screenmode:
	push af, bc
	ASIC_PAGE_IN (void)
	
	ld a, SPLIT_LINE-1

; Generate an address that points to the previous instruction's operand
var_pri	equ $-1
	
	; This will cause A to swap between SPLIT_LINE-1 and RESTORE_LINE
	xor SPLIT_LINE-1 XOR RESTORE_LINE
	
	ld (ASIC_PRI), a		; set the next raster interrupt scanline
	ld (var_pri), a		; and save the value so we can flip it back

	sub RESTORE_LINE			; switch screenmode

	jr c, isr_screenmode_banner

isr_screenmode_gameplay:
	ld a, (Scroll)
	add 4
	and $0f
	or $80
	ld (Scroll), a
	ld (ASIC_SSCR), a
	ld a, $8c
	out (c), a
	jr isr_screenmode_done

isr_screenmode_banner:
	ld a, 0
	ld (ASIC_SSCR), a
	ld a, $8d
	out (c), a

isr_screenmode_done:
	call ASICPageRestore	
	pop bc, af
	ei
	ret



Start:
	call PlusInit

	; Set mode 0
	ld a, 0
	call #bc0e

	; Set up 256x192 region
	CRTC_WRITE_REG $00, 63
	CRTC_WRITE_REG $01, 32
	CRTC_WRITE_REG $02, 42
	CRTC_WRITE_REG $03, 134
	CRTC_WRITE_REG $06, 24
	CRTC_WRITE_REG $07, 31
	CRTC_SET_BANNER

	; Fill screen
	ld a, $c9
	ld bc, 16384
	ld hl, $C000
	call Fill
	
	; Fill banner
	ld a, $33
	ld bc, 16384
	ld hl, $4000
	call Fill
	
	di
	
	ASIC_PAGE_IN (void)
	WRITE_BYTE ASIC_SSA, $C0
	WRITE_BYTE ASIC_SSA+1, $00
	WRITE_BYTE ASIC_SPLIT, SPLIT_LINE
	ASIC_PAGE_OUT (void)
	
	ei

	;ld bc, $75b8 ; page in ASIC
	;out (c), c
	;ld a, 1
	;ld ($6805), a
	

	

	;ld bc, #7fb8	; Page in Plus registers
	;out (c), c		; ASIC rambank is at #4000 - #7FFFF
	;
	;ld hl, DmaList
	;ld (DMA0_ADDR), hl	; Set DMA channel 0 address
	;ld a, 0
	;ld (DMA0_SCALE), a	; Set prescaler
	;ld a, #01
	;ld (DMA_CTL), a		; Enable DMA channel 0
	;
	;ld bc, #7fa0
	;out (c), c		; Page out Plus registers

	; ld bc, 0
	; ld de, 60
	; ld hl, 150
	; call DrawBGTile
; 
	; ;ld bc, 1
	; ;ld de, 20
	; ;ld hl, 40
	; ;call DrawBGTile
	; ;
	; ;ld bc, 1
	; ;ld de, 20
	; ;ld hl, 80
	; ;call DrawBGTile
; 
	; ld bc, 0
	; ld de, 100
	; ld hl, 80
	; call DrawBGTile
	; 
	; ld bc, 0
	; ld de, 70
	; ld hl, 80
	; call DrawBGTile
	; ;ld bc, 1
	; ;ld de, 20
	; ;ld hl, 10
	; ;call DrawBGTile
	
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

	align 2
DmaList:
	DMA_REPEAT #fff
	;DMA_SET AY_REG_MIXER, (AY_MIX_PORT_A_CTL | AY_MIX_B_ENABLE | AY_MIX_B_NOISE_ENABLE) ^ #ffff
	DMA_SET AY_REG_MIXER, %00111101
	DMA_SET AY_REG_NOISE, %00000011
	DMA_SET AY_REG_VOLUME_B, #0f
	DMA_SET AY_REG_TONE_B_COARSE, #04
	DMA_PAUSE 300 * 10
	DMA_SET AY_REG_MIXER, AY_MIXER_ALL_OFF
	DMA_PAUSE 300 * 10
	DMA_LOOP
	DMA_STOP

;; TODO: make this use reg A for the tile index, will speed up the shifting
;; bc - tile index (0-127)
;; de - x-pos
;; hl - y-pos
;DrawBGTile:
;	sla c				; multiply tile index by 2 (we only support 128 background tiles so this won't carry)
;	sla c				; multiply by 2 again; might carry
;	ld b, 0
;	jr nc, DrawBGTile_NoCarry
;	inc b
;
;DrawBGTile_NoCarry:
;	ld ix, BGTiles		; base tile address
;	add ix, bc			; get base address of tile info
;	
;	ld bc, (ix+0)		; get the sprite data base address into iy via bc
;	ld iy, bc
;
;	; 
;	ld a, (ix+2)
;	ld (DrawBGTile_width), a
;	ld a, (ix+3)
;	ld (DrawBGTile_height), a
;
;	call $bc1d
;	ld ixh, h
;	ld ixl, l
;
;	ld a, (DrawBGTile_height)
;	ld b, a
;DrawBGTile_Line:
;	ld b, (DrawBGTile_width)
;DrawBGTile_Pixel:
;	ld d, (iy)
;	inc iy
;	ld e, (iy)
;	inc iy
;	ld (ix), de
;	djnz DrawBGTile_Pixel
;
;	dec a
;	jr z, DrawBGTile_Done
;
;	call $bc26
;	ld ix, hl
;
;	jr DrawBGTile_Line
;DrawBGTile_Done:
;	ld sp, (scratchSP)	; restore stack pointer
;	ret
;
;DrawBGTile_width:
;	db 0
;
;DrawBGTile_height:
;	db 0

; Array of background tile specifications
; Each entry has the format:
; dw $data_address
; db $width, $height
; NOTE: $width is specified in HALF BYTES; actual on-screen width is quadrupled
;       This means that every background tile must be a multiple of 4 pixels wide
BGTiles:
	dw BGTile0
	db 4, 8
	dw BGTile1
	db 2, 4

BGTile0:
	db #cc, #cc, #cc, #cc, #cc, #cc, #cc, #cc
	db #cc, #33, #33, #33, #33, #33, #33, #cc
	db #cc, #33, #33, #33, #33, #33, #33, #cc
	db #cc, #33, #33, #c3, #3c, #33, #33, #cc
	db #cc, #33, #33, #3c, #c3, #33, #33, #cc
	db #cc, #33, #33, #33, #33, #33, #33, #cc
	db #cc, #33, #33, #33, #33, #33, #33, #cc
	db #cc, #cc, #cc, #cc, #cc, #cc, #cc, #cc

BGTile1:
	db #33, #33, #33, #33
	db #33, #cc, #cc, #33
	db #33, #cc, #cc, #33
	db #33, #33, #33, #33


include 'lib.asm'
include 'scratch.asm'