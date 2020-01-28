ram_base: equ 0x0300            ; base of ram for kernel vars
kqs_mask: equ 0x0f              ; 16 byte status table

kq_curr_id: equ ram_base        ; location of current queue idx
kqs_tbase: equ kq_curr_id + 1   ; location of queue status table
