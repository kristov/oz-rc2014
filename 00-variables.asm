; Layout of kernel variables in memory, starting from the first writable
; address (ROM occupies first 1K of address space).
;
;   +-------------+--------------------------------------+
;   | 0x0000      | Start of ROM                         |
;   |             |                                      |
;   | 0x03ff      | End of ROM                           |
;   |-------------+--------------------------------------|
;   | k_sp_kernel | kernel stack pointer                 |
;   |             |                                      |
;   |-------------+--------------------------------------|
;   | kq_curr_id  | current working queue id             |
;   |-------------+--------------------------------------|
;   | kq_addr     | start of the working queue record    |
;   |             | and working queue address            |
;   | kq_prod_id  | working queue producer id            |
;   | kq_cons_id  | working queue consumer id            |
;   | kq_pwrite   | working queue write index            |
;   | kq_pread    | working queue read index             |
;   | kq_mask     | working queue size mask              |
;   | kq_flags    | working queue flags                  |
;   |-------------+--------------------------------------|
;   | kfn_sp      | start of the working function record |
;   |             | and function stack top               |
;   | kfn_addr    | working function address             |
;   |             |                                      |
;   |-------------+--------------------------------------|
;   | kqs_tbase   | start of the queue status table      |
;   |             |                                      |
;   |-------------+--------------------------------------|
;   | kq_tbase    | start of the queue table             |
;   |             |                                      |
;   |-------------+--------------------------------------|
;   | kfn_tbase   | start of the function table          |
;   |             |                                      |
;   |-------------+--------------------------------------|

; master configuration
k_rs:           equ 0x03ff                  ; where writable ram starts
sioa_c:         equ 0x0080                  ; channel A control
sioa_d:         equ 0x0081                  ; channel A data
siob_c:         equ 0x0082                  ; channel B control
siob_d:         equ 0x0083                  ; channel B data
kqs_tmax:       equ 0x00ff                  ; maximum number of queues

; kernel variables
k_sp_kernel:    equ k_rs + 0x00             ; stores stack pointer of the kernel
kq_curr_id:     equ k_sp_kernel + 0x02      ; current working queue id
kq_addr:        equ kq_curr_id + 0x01       ; working queue record
kq_prod_id:     equ kq_addr + 0x02          ; working queue producer id
kq_cons_id:     equ kq_prod_id + 0x01       ; working queue consumer id
kq_pwrite:      equ kq_cons_id + 0x01       ; working queue write index
kq_pread:       equ kq_pwrite + 0x01        ; working queue read index
kq_mask:        equ kq_pread + 0x01         ; working queue size mask
kq_flags:       equ kq_mask + 0x01          ; working queue flags
kfn_sp:         equ kq_flags + 0x01         ; working function record
kfn_addr:       equ kfn_sp + 0x02           ; working function address

; constants
kqs_tbase:      equ kfn_addr + 0x02         ; location of the queue status table
kq_tbase:       equ kqs_tbase + kqs_tmax    ; location of the queue record table
kfn_tbase:      equ kq_tbase + (kqs_tmax * 0x08)    ; location of the working function table

; Serial buffer variables
k_serbuf_write: equ 0x0000      ; location of serial buffer write pointer
k_serbuf_read: equ 0x0000       ; location of serial buffer read pointer
k_serbuf_base: equ 0x0000       ; base of the serial buffer
