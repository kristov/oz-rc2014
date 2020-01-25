;   in a, (sioa_d)
;   ld b, a
;   push bc
;   call rb_writeb
;   ; check hl

; get the number of bytes that can be written to a buffer
rb_space:
    ld hl, kq_addr              ; set the ring buffer base address
    ld c, (hl)                  ; load the queue mask
    inc hl                      ; move to read pointer
    ld b, (hl)                  ; load the read pointer
    inc hl                      ; move to write pointer
    ld a, (hl)                  ; load the write pointer
    ld hl, 0x0000               ; space counter
rbs_loop:
    inc a                       ; advance the write pointer
    and c                       ; mask the pointer to wrap it
    cp b                        ; compare read pointer to test equality
    jr z, rbs_end               ; if read and write are equal break
    inc hl                      ; increment the counter
    jp rbs_loop                 ; loop
rbs_end:
    ret

rb_writeb:
    ld hl, kq_addr              ; set the queue base address
    ld c, (hl)                  ; load the queue mask
    inc hl                      ; move to read pointer
    ld b, (hl)                  ; load the read pointer
    inc hl                      ; move to write pointer
    ld a, (hl)                  ; load the write pointer
    ld e, a                     ; save the write pointer for later
    inc a                       ; advance the write pointer
    and c                       ; mask the pointer to wrap it
    cp b                        ; compare read pointer to test equality
    jr z, rbwb_error            ; if read and write are equal abort
    ld (hl), a                  ; store advanced write pointer
    ld hl, 0x0003               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld c, (hl)                  ; copy the single byte argument to c
    ld d, 0x00                  ; zero high byte of de
    ld hl, kq_addr              ; set the queue base address
    inc hl                      ; move over mask
    inc hl                      ; move over read pointer
    inc hl                      ; move over write pointer
    add hl, de                  ; add write pointer value to base
    ld (hl), c                  ; save c into the buffer
    ld hl, 0x0000               ; success
    ret
rbwb_error:
    ld hl, 0xffff               ; error status
    ret

rb_readb:
    ld hl, kq_addr              ; set the queue base address
    ld c, (hl)                  ; load the queue mask
    inc hl                      ; move to read pointer
    ld a, (hl)                  ; load the read pointer
    inc hl                      ; move to write pointer
    ld b, (hl)                  ; load the write pointer
    cp b                        ; compare write pointer to test equality
    jr z, rbrb_error            ; if read and write are equal abort
    ld e, a                     ; save the read pointer for later
    inc a                       ; advance the read pointer
    and c                       ; mask the pointer to wrap it
    dec hl                      ; decrement hl to read pointer address
    ld (hl), a                  ; store advanced read pointer
    inc hl                      ; move over read pointer
    inc hl                      ; move over write pointer
    ld d, 0x00                  ; zero high byte of de
    add hl, de                  ; add read pointer value to base
    ld c, (hl)                  ; read the byte into c
    ld hl, 0x0000               ; success
    ret
rbrb_error:
    ld hl, 0xffff               ; error status
    ret

