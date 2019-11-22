sio_channel_a_init:
    ld a, 0x00                  ; null command
    out (sioa_c), a
    ld a, 0x18                  ; CMD 3: Channel reset
    out (sioa_c), a
    ld a, 0x04                  ; write to register 4
    out (sioa_c), a
    ld a, 0xc4                  ; 11-00-01-00 x64 clock, 8 bit sync, 1 stop bit, no parity
    out (sioa_c), a
    ld a, 0x01                  ; write to register 1
    out (sioa_c), a
    ld a, 0x18                  ; 000-11-000 Interrupt on all characters
    out (sioa_c), a
    ld a, 0x03                  ; write to register 3
    out (sioa_c), a
    ld a, 0xe1                  ; 11-100001 8 bits per char, auto enables, Rx enable
    out (sioa_c), a
    ld a, 0x05                  ; write to register 5
    out (sioa_c), a
    ld a, 0xea                  ; 1-11-01010 DTR, Tx 8 bits per char, Tx enable, RTS
    out (sioa_c), a
    ret

sio_channel_b_init:
    ld a, 0x00
    out (siob_c), a
    ld a, 0x18                  ; CMD 3: Channel reset
    out (siob_c), a
    ld a, 0x04                  ; write to register 4
    out (siob_c), a
    ld a, 0xc4                  ; 11-00-01-00 x64 clock, 8 bit sync, 1 stop bit, no parity
    out (siob_c), a
    ld a, 0x01                  ; write to register 1
    out (siob_c), a
    ld a, 0x18                  ; 000-11-000 Interrupt on all characters
    out (siob_c), a
    ld a, 0x02                  ; write to register 2
    out (siob_c), a
    ld a, 0x60                  ; INTERRUPT VECTOR
    out (siob_c), a
    ld a, 0x03                  ; write to register 3
    out (siob_c), a
    ld a, 0xe1                  ; 11-100001 8 bits per char, auto enables, Rx enable
    out (siob_c), a
    ld a, 0x05                  ; write to gegister 5
    out (siob_c), a
    ld a, 0xea                  ; 1-11-01010 DTR, Tx 8 bits per char, Tx enable, RTS
    out (siob_c), a
    ret
