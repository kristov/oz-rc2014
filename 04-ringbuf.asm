;   in a, (sioa_d)
;   ld b, a
;   push bc
;   call rb_writeb
;   ; check hl

; Get the number of bytes that can be written to a buffer.
;
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

; Get the number of bytes stored in the queue.
;
rb_count:
    ld hl, kq_addr              ; set the ring buffer base address
    ld c, (hl)                  ; load the queue mask
    inc hl                      ; move to read pointer
    ld a, (hl)                  ; load the read pointer
    inc hl                      ; move to write pointer
    ld b, (hl)                  ; load the write pointer
    ld hl, 0x0000               ; byte counter
rbc_loop:
    and c                       ; mask the pointer to wrap it
    cp b                        ; compare read pointer to test equality
    jr z, rbc_end               ; if read and write are equal break
    inc a                       ; advance the read pointer
    inc hl                      ; increment the counter
    jp rbc_loop                 ; loop
rbc_end:
    ret

; Write a single byte to the queue.
;
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
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
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

; Write a chunk of bytes to the queue.
;
;     uint16_t rb_writem(uint16_t src, uint16_t count);
;
rb_writem:
    ; check if the count is greater than available space
    call rb_space               ; get the number of free bytes on the queue
    ld a, l                     ; load the counter from rb_space return
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld b, (hl)                  ; load the count argument
    sub b                       ; subtract the desired count from available
    jp c, rbwm_error            ; desired count is greater than available space
    ; load count and source address arguments
    inc hl                      ; skip over B
    inc hl                      ; skip over C
    ld e, (hl)                  ; load the src address L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the src address U
    push de                     ; save source address
    ; set up the destination address
    ld hl, kq_addr              ; load the base of the table
    ld c, (hl)                  ; load the mask into c
    inc hl                      ; skip over mask
    inc hl                      ; skip over read pointer
    ld a, (hl)                  ; load the write pointer
    inc hl                      ; skip over write pointer
    ld e, a                     ; copy the write pointer to de
    ld d, 0x00                  ; zero upper byte of de
    add hl, de                  ; add the write pointer to the queue
    pop de                      ; restore the source address
    ex de, hl                   ; hl is the source
rbwm_loop:
    push af                     ; save the write pointer
    ld a, (hl)                  ; read the source byte
    ex de, hl                   ; hl is destination
    ld (hl), a                  ; write the destination byte
    dec b                       ; decrement the counter
    jp z, rbwm_end              ; finished writing
    inc hl                      ; increment the destination
    ex de, hl                   ; hl is source
    inc hl                      ; increment the source
    pop af                      ; restore the write pointer
    inc a                       ; increment the write pointer
    and c                       ; mask it to wrap
    jp nz, rbwm_loop            ; if it was not reset to zero then loop
    ; zero the pointers to the beginning of the queue
    ex de, hl                   ; hl is destination
    ld hl, kq_addr              ; reset destination
    inc hl                      ; skip over mask
    inc hl                      ; skip over read pointer
    inc hl                      ; skip over write pointer
    ex de, hl                   ; hl is source
    jp rbwm_loop                ; continue writing
rbwm_end:
    ; save the new write pointer
    pop af                      ; restore the write pointer
    inc a                       ; increment the write pointer
    and c                       ; mask it to wrap
    ld hl, kq_addr              ; set destination
    inc hl                      ; skip over mask
    inc hl                      ; skip over read pointer
    ld (hl), a                  ; save the incremented write pointer
    ld hl, 0x0000               ; set success return code
    ret
rbwm_error:
    ld hl, 0xffff               ; set error value
    ret

; Read a single byte from the queue.
;
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

; Read all available bytes from a queue into a memory address.
;
rb_readm:
    call rb_count               ; get the number of bytes in the queue
    ld a, l                     ; copy it to a
    or a                        ; test for zero flags
    jp z, rbrm_zero             ; jump to return zero
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld e, (hl)                  ; load the dest address L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the dest address U
    ld b, 0x00                  ; zero high byte of b
    ld c, a                     ; set counter to number bytes in queue
    push bc                     ; push the byte count for return
    push de                     ; save destination for later
    ld hl, kq_addr              ; set the queue base address
    ld b, (hl)                  ; load the queue mask
    inc hl                      ; move to read pointer
    ld a, (hl)                  ; load the read pointer
    inc hl                      ; move over read pointer
    inc hl                      ; move over write pointer
    ld d, 0x00                  ; zero high byte of de
    ld e, a                     ; copy read point to lower byte of de
    add hl, de                  ; add read pointer value to base
    pop de                      ; restore destination
rbrm_loop:
    push af                     ; save the read pointer
    ld a, (hl)                  ; read the source byte
    ex de, hl                   ; hl is destination
    ld (hl), a                  ; write the destination byte
    dec c                       ; decrement the counter
    jp z, rbrm_end              ; finished writing
    inc hl                      ; increment the destination
    ex de, hl                   ; hl is source
    inc hl                      ; increment the source
    pop af                      ; restore the read pointer
    inc a                       ; advance the read pointer
    and b                       ; mask the pointer to wrap it
    jp nz, rbrm_loop            ; if it was not reset to zero then loop
    ; zero the pointers to the beginning of the queue
    ld hl, kq_addr              ; reset source
    inc hl                      ; skip over mask
    inc hl                      ; skip over read pointer
    inc hl                      ; skip over write pointer
    jp rbrm_loop                ; continue writing
rbrm_end:
    ; save the new write pointer
    pop af                      ; restore the read pointer
    inc a                       ; increment the read pointer
    and c                       ; mask it to wrap
    ld hl, kq_addr              ; set destination
    inc hl                      ; skip over mask
    ld (hl), a                  ; save the incremented read pointer
    inc hl                      ; skip over write pointer
    pop hl                      ; return the original count of bytes
    ret
rbrm_zero:
    ld hl, 0x0000               ; zero bytes read
    ret

