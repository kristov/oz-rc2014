k_rst00:
    di
    jp k_boot
    nop
    nop
    nop
    nop

k_rst08:
    di
    jp k_syscall
    nop
    nop
    nop
    nop

k_rst10:
    di
    jp k_int_reti
    nop
    nop
    nop
    nop

k_rst18:
    di
    jp k_int_reti
    nop
    nop
    nop
    nop

k_rst20:
    di
    jp k_int_reti
    nop
    nop
    nop
    nop

k_rst28:
    di
    jp k_int_reti
    nop
    nop
    nop
    nop

k_rst30:
    di
    jp k_int_reti
    nop
    nop
    nop
    nop

k_rst38:
    di
    jp k_serial_read
    nop
    nop
    nop
    nop

; Table of kernel syscall functions
;
k_syscall_tbase:
    dw k_syscall_noop           ; a no operation syscall id 0
    dw rb_writeb
    dw rb_readb

k_int_reti:
    ei                          ; enable interrupts
    reti                        ; return from interrupt

k_boot_msg:
    defb "oz 0.0\n", 0

; Called at boot time to initialize the system
;
k_boot:
    im 1                        ; INTERRUPT MODE 1 (rst38)
    ld sp, 0x7fff               ; set the kernel stack top
    ld (k_sp_kernel), sp        ; store the kernel stack top variable
    call sio_channel_a_init     ; init the A channel of the SIO
    ld a, 0x00                  ; prepare to set k_serbuf_read
    ld (k_serbuf_read), a       ; set k_serbuf_read to zero
    ld a, 0x00                  ; prepare to set k_serbuf_write
    ld (k_serbuf_write), a      ; set k_serbuf_write to zero
    call k_boot_sysinfo         ; print system info
    ei
k_boot_main:
    nop                         ; this is what the kernel will do until interrupt
    jp k_boot_main              ; enter an infinite loop

; Print system information to the serial console
;
k_boot_sysinfo:
    ld hl, k_boot_msg           ; prepare to print first line
    call k_print_string         ; call print routine
    ret

; Print a null terminated string from a memory location in hl to the serial
; console
;
k_print_string:
    ld a, (hl)                  ; load the first char into a
    cp 0x00                     ; check if zero
    jr z, k_print_end           ; return if null terminator
    out (sioa_d), a             ; print the char
    inc hl                      ; move to next char
    jr k_print_string           ; print next char
k_print_end:
    ret

; Init stdin, stdout, and releated producer and consumer functions
;
k_init_stdq:
    ld a, 0x00                  ; prepare to get address for slot 0 in function table
    push af                     ; prepare args
    call kfn_addr_by_idx        ; calculate address
    ...

; Called from the interrupt generated by the SIO on a key press
;
k_serial_read:
    ex af, af'                  ; exchange part 1
    exx                         ; exchange part 2
    in a, (sioa_c)              ; read the status register
    bit 0, a                    ; test the char ready bit
    jr z, k_serial_read_end     ; if no char abort
    in a, (sioa_d)              ; read the character
    push af                     ; store character on stack
    call rb_writeb_stdin        ; call special stdin function
    jp k_serial_read            ; continue to read until empty
k_serial_read_end:
    exx                         ; exchange part 2
    ex af, af'                  ; exchange part 1
    jp k_int_reti               ; jump to return

k_syscall:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; copy the single byte argument to a
    add a, a                    ; multiply syscall id by 2
    ld h, 0x00                  ; clear high byte of hl
    ld l, a                     ; set lower byte to idx * 2
    ld de, k_syscall_tbase      ; load base of the jump table
    add hl, de                  ; hl is now the location of the sub address in the table
    ld a, (hl)                  ; load first byte of address into a
    inc hl                      ; move to second byte of word
    ld h, (hl)                  ; load second byte into upper byte of hl
    ld l, a                     ; load first byte into lower byte of hl
    ld bc, k_int_reti           ; load return address from call
    jp (hl)                     ; jump to that address

k_syscall_noop:
    jp k_int_reti               ; return immediately

; Returns the memory address of the kq_tbase queue entry for the provided index
;
kq_addr_by_idx:
    ld hl, 0x0002               ; extract argument 2 from stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; copy the single byte argument to c
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy queue id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    add hl, hl                  ; x8
    ld de, kq_tbase             ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ret

; Returns the memory address of the kfn_tbase function entry for the provided
; index
;
kfn_addr_by_idx:
    ld hl, 0x0002               ; extract argument 2 from stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; copy the single byte argument to c
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy queue id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    ld de, kfn_tbase            ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ret
