REG_CRTC_SEL    equ $bc00
REG_CRTC_WRITE  equ $bd00
REG_CRTC_READ   equ $be00

macro CRTC_SEL register
    ld bc, REG_CRTC_SEL + {register}
    out (c), c
mend

macro CRTC_WRITE value
    ld bc, REG_CRTC_WRITE + {value}
    out (c), c
mend

macro CRTC_WRITE_REG register, value
    CRTC_SEL {register}
    ld bc, REG_CRTC_WRITE + {value}
    out (c), c
mend

macro CRTC_READ_REG register
    CRTC_SEL {register}
    in a, (c)
mend
