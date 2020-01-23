kq_mask: equ 0x0100         ; queue length mask variable
kq_pread: equ 0x101         ; read index
kq_pwrite: equ 0x102        ; write index
kq_addr: equ 0x103          ; base address of buffer

init:
    ld sp, 0x0140           ; set stack top
    ld a, 0x0f
    ld (kq_mask), a         ; set mask to 16
    ld a, 0x00
    ld (kq_pread), a        ; read at zero
    ld a, 0x00
    ld (kq_pwrite), a       ; write at zero
