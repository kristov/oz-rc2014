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

; ql_set_append(set, size);
;
;     ld bc, <set address>           ; push the address of the set
;     ld de, <size of thing to add>  ; push the size of the chunk
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
