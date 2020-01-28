ram_base: equ 0x0300            ; base of ram for kernel vars
kqs_mask: equ 0x0f              ; 16 byte status table

kq_curr_id: equ ram_base        ; location of current queue idx
kfn_addr: equ kq_curr_id + 1    ; function address
kqs_tbase: equ kfn_addr + 2     ; location of queue status table
