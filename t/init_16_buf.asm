kq_addr: equ 0x100          ; location of queue

init:
    ; set up a 16 byte queue
    ld sp, 0x0140
    ld hl, kq_addr
    ld a, 0x0f
    ld (hl), a
    ld a, 0x00
    inc hl
    ld (hl), a
    inc hl
    ld (hl), a
