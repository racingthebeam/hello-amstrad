DMA0_ADDR	equ #6c00
DMA0_SCALE	equ #6c02
DMA1_ADDR	equ #6c04
DMA1_SCALE	equ #6c06
DMA2_ADDR	equ #6c08
DMA2_SCALE	equ #6c0a
DMA_CTL		equ #6c0f

macro DMA_SET reg, val
	dw ({reg} << 8) | {val}
mend

macro DMA_PAUSE ticks
	dw #1000 | {ticks}
mend

macro DMA_REPEAT times
	dw #2000 | {times}
mend

macro DMA_NOP
	dw #4000
mend

macro DMA_LOOP
	dw #4001
mend

macro DMA_INT
	dw #4010
mend

macro DMA_STOP
	dw #4020
mend

