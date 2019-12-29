;   ld b, 0x01
;   in a, (sioa_d)
;   ld c, a
;   push bc
;   rst 08h
;   pop

rb_writeb:
    ld a, (kq_mask)             ; load the queue mask
    ld c, a                     ; copy it to c
    ld a, (kq_pread)            ; load the serial read pointer
    ld b, a                     ; move it to b
    ld a, (kq_pwrite)           ; load the serial write pointer
    inc a                       ; advance the copy of write pointer
    and c                       ; mask the pointer to wrap it
    cp b                        ; subtract read pointer to test equality
    jr z, rbw_end               ; if read and write are equal abort
    ld (kq_pwrite), a           ; store advanced write pointer
    ld hl, 0x0003               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address and syscall id on stack
    ld c, (hl)                  ; copy the single byte argument to c
    ld d, 0x00                  ; zero high byte of de
    ld e, a                     ; load e with new write pointer
    ld hl, (kq_location)        ; load the ring buffer base address
    add hl, de                  ; add write pointer value to base
    ld (hl), c                  ; save c into the buffer
rbw_end:
    ret

rb_readb:
    ld a, (kq_mask)             ; load the queue mask
    ld c, a                     ; copy it to c
    ld a, (kq_pwrite)           ; load the serial write pointer
    ld b, a                     ; move it to b
    ld a, (kq_pread)            ; load the serial read pointer
    cp b                        ; subtract write pointer to test equality
    jr z, rbr_end               ; if read and write are equal abort
    inc a                       ; advance the copy of read pointer
    and c                       ; mask the pointer to wrap it
    ld d, 0x00                  ; zero high byte of de
    ld e, a                     ; load e with new read pointer
    ld hl, (kq_location)        ; load the ring buffer base address
    add hl, de                  ; add write pointer value to base
    ld c, (hl)                  ; read the byte into c
rbr_end:
    ; TODO: return value plus flag to indicate an error or not
    ret

