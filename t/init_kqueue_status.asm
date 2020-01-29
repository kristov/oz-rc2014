ram_base: equ 0x0300            ; base of ram for kernel vars
kqs_mask: equ 0x0f              ; 16 byte status table

kq_curr_id: equ ram_base        ; location of current queue idx
kq_addr: equ kq_curr_id + 1     ; location of current queue data
kfn_paddr: equ kq_addr + 2      ; producer function address
kfn_caddr: equ kfn_paddr + 2    ; consumer function address
kqs_tbase: equ kfn_caddr + 2    ; location of queue status table
