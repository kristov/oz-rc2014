ram_base: equ 0x0200            ; base of ram for kernel vars
kqs_mask: equ 0x0f              ; 16 byte status table

kq_curr_id: equ ram_base        ; location of current queue idx
kq_addr: equ kq_curr_id + 1     ; location of current queue data
kfn_paddr: equ kq_addr + 2      ; producer function address
kfn_caddr: equ kfn_paddr + 2    ; consumer function address
kqs_tbase: equ kfn_caddr + 2    ; location of queue status table

init:
    ld sp, 0x0fff
    ld hl, 0x0300
    ld (kq_addr), hl
    ld a, 0x0f
    ld (hl), a
    ld a, 0x00
    inc hl
    ld (hl), a
    inc hl
    ld (hl), a

