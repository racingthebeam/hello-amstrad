macro ASIC_PAGE_IN
    ld bc, $7fb8
    out (c), c
mend

macro ASIC_PAGE_OUT
    ld bc, $7fa0
    out (c), c
mend

macro WRITE_BYTE addr, val
    ld a, {val}
    ld ({addr}), a
mend