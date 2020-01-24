;   in a, (sioa_d)
;   ld b, a
;   push bc
;   call rb_writeb
;   ; check hl

rb_writeb:
    ld hl, 0xffff               ; error status
    ld a, (kq_mask)             ; load the queue mask
    ld c, a                     ; copy it to c
    ld a, (kq_pread)            ; load the serial read pointer
    ld b, a                     ; copy it to b
    ld a, (kq_pwrite)           ; load the serial write pointer
    ld e, a                     ; save the write pointer for later
    inc a                       ; advance the write pointer
    and c                       ; mask the pointer to wrap it
    cp b                        ; compare read pointer to test equality
    jr z, rbw_end               ; if read and write are equal abort
    ld (kq_pwrite), a           ; store advanced write pointer
    ld hl, 0x0003               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld c, (hl)                  ; copy the single byte argument to c
    ld d, 0x00                  ; zero high byte of de
    ld hl, kq_addr              ; load the ring buffer base address
    add hl, de                  ; add write pointer value to base
    ld (hl), c                  ; save c into the buffer
    ld hl, 0x0000               ; success
rbw_end:
    ret

rb_readb:
    ld hl, 0xffff               ; error status
    ld a, (kq_mask)             ; load the queue mask
    ld c, a                     ; copy it to c
    ld a, (kq_pwrite)           ; load the serial write pointer
    ld b, a                     ; copy it to b
    ld a, (kq_pread)            ; load the serial read pointer
    cp b                        ; compare write pointer to test equality
    jr z, rbr_end               ; if read and write are equal abort
    inc a                       ; advance the read pointer
    and c                       ; mask the pointer to wrap it
    ld d, 0x00                  ; zero high byte of de
    ld e, a                     ; load e with new read pointer
    ld hl, (kq_addr)            ; load the ring buffer base address
    add hl, de                  ; add write pointer value to base
    ld c, (hl)                  ; read the byte into c
    ld hl, 0x0000               ; success
rbr_end:
    ret

