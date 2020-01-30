ram_base: equ 0x01f0            ; base of ram for kernel vars
kqs_mask: equ 0x0f              ; 16 byte status table

kq_curr_id: equ ram_base        ; location of current queue idx
kq_addr: equ kq_curr_id + 1     ; location of current queue data
kfn_paddr: equ kq_addr + 2      ; producer function address
kfn_caddr: equ kfn_paddr + 2    ; consumer function address
ql_base: equ kfn_caddr + 2      ; location of queue list
kqs_tbase: equ ql_base + 2      ; location of queue status table

init:
    ; init the stack top
    ld sp, 0x0fff

    ; load the location of the queue list table
    ld hl, 0x0300
    ld (ql_base), hl

    ; set up the first queue
    ld hl, 0x0300
    ld (kq_addr), hl
    ld a, 0x0f
    ld (hl), a
    ld a, 0x00
    inc hl
    ld (hl), a
    inc hl
    ld (hl), a

