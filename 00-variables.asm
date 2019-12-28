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

; constants
kqs_tmax: equ 0x0000            ; length of the queue status table
kqs_tbase: equ 0x0000           ; location of the queue status table
kq_tbase: equ 0x0000            ; location of the queue record table
kfn_tbase: equ 0x0000           ; location of the working function table
sioa_c: equ 0x0080              ; channel A control
sioa_d: equ 0x0081              ; channel A data
siob_c: equ 0x0082              ; channel B control
siob_d: equ 0x0083              ; channel B data

; kernel variables
k_sp_kernel: equ 0x0000         ; stores stack pointer of the kernel
kq_curr_id: equ 0x0000          ; current working queue id
kq_addr: equ 0x0000             ; location of the working queue record
kq_prod_id: equ 0x0000          ; location of the working queue producer id
kq_cons_id: equ 0x0000          ; location of the working queue consumer id
kfn_sp: equ 0x0000              ; location of the working function record
kfn_addr: equ 0x0000            ; location of the working function address

; Serial buffer variables
k_serbuf_write: equ 0x0000      ; location of serial buffer write pointer
k_serbuf_read: equ 0x0000       ; location of serial buffer read pointer
k_serbuf_base: equ 0x0000       ; base of the serial buffer
