; Init an empty set at the address passed on the stack. 
;
ql_set_init:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld e, (hl)                  ; load the dest address L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the dest address U
    ex de, hl                   ; set hl to destination address
    ld (hl), 0x00               ; load the type L
    inc hl                      ; move to U
    ld (hl), 0x80               ; set the bit to represent a set
    ret

; Init a chunk of a given size at the location passed
;
;     ql_chunk_init(uint16_t chunk, uint16_t size);
;
ql_chunk_init:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load the desired space value into bc and make sure its not too large
    ld c, (hl)                  ; load the size address L
    inc hl                      ; skip over L
    ld b, (hl)                  ; load the size address U
    bit 7, b                    ; test if the size is too big
    jp nz, qlci_error           ; the size is too big
    ; load the chunk address from stack argument
    inc hl                      ; skip over U
    ld e, (hl)                  ; load the dest address L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the dest address U
    ; write the set header
    ex de, hl                   ; set hl to destination address
    ld (hl), c                  ; load the type L
    inc hl                      ; move to U
    ld (hl), b                  ; set the bit to represent a chunk
    inc hl                      ; move to start of chunk data
    ret
qlci_error:
    ld hl, 0x0000               ; set error code
    ret

; ql_set_append(uint16_t set, uint16_t size);
;
;     ld bc, <set address>           ; push the address of the set
;     ld de, <size of thing to add>  ; push the size of the chunk (header + data)
;     call ql_set_append             ; returns the address of where the chunk data starts in hl
;
ql_set_append:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load the desired space value into bc and make sure its not too large
    ld c, (hl)                  ; load the size address L
    inc hl                      ; skip over L
    ld b, (hl)                  ; load the size address U
    bit 7, b                    ; test if the size is too big
    jp nz, qlsa_error           ; the size is too big
    inc hl                      ; skip over U
    ; load the set address from stack argument and load the current set size
    ld e, (hl)                  ; load the set address L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the set address U
    ex de, hl                   ; set hl to set address, de is stack location
    ld e, (hl)                  ; load the lower of the size
    inc hl                      ; skip over L
    ld a, (hl)                  ; load the U into a
    ld d, 0x7f                  ; prepare to mask away the set type bit
    and d                       ; mask away the set type bit
    ld d, a                     ; de now contains the current size
    push de                     ; save original size
    ; add the desired size to current size in set and check if too big
    ex de, hl                   ; de is address of upper byte of set size, hl is current size
    add hl, bc                  ; hl is the new size
    jp c, qlsa_pop_error        ; new size too big
    ; write the new size to the set header making sure the set bit is on
    ex de, hl                   ; de is the new size, hl is is pointing to high byte
    dec hl                      ; decrement hl to low byte of set size
    ld a, d                     ; set a to U of new size
    ld b, 0x80                  ; prepare to set the set bit
    or b                        ; set the set bit
    ld d, a                     ; put the modified U back in de
    ld (hl), e                  ; save the new size L
    inc hl                      ; skip over L
    ld (hl), d                  ; save the new size U
    ; add the old set size to the set data address to get end of the set
    inc hl                      ; hl is now the start of the chunk data
    pop de                      ; load the old size into de
    add hl, de                  ; hl is now where the append can happen
    ret
qlsa_pop_error:
    pop de                      ; discard the original size
qlsa_error:
    ld hl, 0x0000               ; returns NULL
    ret

; Get the address for a given idx in a set
;
;     ql_get_addr(uint16_t set, uint16_t idx);
;
ql_get_addr:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load the desired idx into bc
    ld c, (hl)                  ; load the idx L
    inc hl                      ; skip over L
    ld b, (hl)                  ; load the idx U
    inc hl                      ; skip over U
    ; load the set address from stack argument
    ld e, (hl)                  ; load the set address L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the set address U
    ex de, hl                   ; set hl to set address, de is stack location
    inc hl                      ; skip over set header L
    inc hl                      ; skip over set header U
    ; test bc for zero
    ld a, b                     ; prepare to test zero
    or a                        ; test for zero
    jp nz, qlga_nextc           ; not zero
    ld a, c                     ; prepare to test zero
    or a                        ; test for zero
    jp nz, qlga_nextc           ; not zero
    jp qlga_zero                ; bc is zero, we have arrived
qlga_nextc:
    ld e, (hl)                  ; load the chunk size L
    inc hl                      ; skip over L
    ld a, (hl)                  ; load the U into a
    inc hl                      ; skip over U
    ld d, 0x7f                  ; prepare to mask away the set type bit
    and d                       ; mask away the set type bit
    ld d, a                     ; de now contains the current size
    ; test decremented bc for zero
    ld a, b                     ; prepare to test zero
    or a                        ; test for zero
    jp nz, qlga_nzero           ; not zero
    ld a, c                     ; prepare to test zero
    or a                        ; test for zero
    jp nz, qlga_nzero           ; not zero
    jp qlga_zero_rwd            ; bc is zero, we have arrived
qlga_nzero:
    add hl, de                  ; add the chunk size to pointer
    dec bc                      ; decrement the idx
    jp qlga_nextc               ; next chunk
qlga_zero_rwd:
    dec hl                      ; rewind hl
    dec hl                      ; rewind hl
qlga_zero:
    ret

; Get the address of the end of a set
;
;     ql_get_end_addr(uint16_t set);
;
ql_get_end_addr:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load the set address from stack argument and load the current set size
    ld e, (hl)                  ; load the set address L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the set address U
    inc hl                      ; skip over U
    ex de, hl                   ; set hl to set address, de is stack location
    ld e, (hl)                  ; load the lower of the size
    inc hl                      ; skip over L
    ld a, (hl)                  ; load the U into a
    inc hl                      ; skip over U
    ld d, 0x7f                  ; prepare to mask away the set type bit
    and d                       ; mask away the set type bit
    ld d, a                     ; de now contains the current size
    ; add the set size to the set data address
    add hl, de                  ; hl is now the end of the set
    ret

; Delete a chunk from a set
;
;     ql_set_delete(uint16_t set, uint16_t idx);
;
ql_set_delete:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load the desired idx into bc
    ld c, (hl)                  ; load the idx L
    inc hl                      ; skip over L
    ld b, (hl)                  ; load the idx U
    inc hl                      ; skip over U
    ; load the set address from stack argument
    ld e, (hl)                  ; load the set address L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the set address U
    inc hl                      ; skip over U
    push de                     ; save the set address
    ; get the address of the idx'th chunk
    push de                     ; push set address arg
    push bc                     ; push idx arg
    call ql_get_addr            ; get the address of the chunk
    pop bc                      ; discard arg
    pop de                      ; discard arg
    ; check hl for NULL
    push hl                     ; save the address of the chunk
    ; get the end address of the set
    push de                     ; push set address arg
    call ql_get_end_addr        ; get the end address of the set
    pop de                      ; discard arg
    ; check hl for NULL
    ex de, hl                   ; de is set end address, hl set address
    ; calculate length of data to copy
    pop hl                      ; pop address of the chunk
    push hl                     ; save the address of the chunk
    ld c, (hl)                  ; load the chunk size L
    inc hl                      ; skip over L
    ld b, (hl)                  ; load the chunk size U
    inc hl                      ; skip over U
    add hl, bc                  ; hl is end of chunk
    ex de, hl                   ; de is end of chunk, hl is set end address
    sbc hl, de                  ; hl is length of copy
    ; prepare and execute the block copy
    ld c, l                     ; copy hl L
    ld b, h                     ; copy hl U
    ex de, hl                   ; hl is end of chunk, de is the copy length
    pop de                      ; restore the address of the chunk
    push bc                     ; save the length
    ldir                        ; copy bc bytes from hl to de
    ; write the new length to the set header
    pop bc                      ; restore the length
    pop hl                      ; restore the set address
    ; write (curr length - bc)
    ret
qlsd_error:
    ld hl, 0xffff
    ret
