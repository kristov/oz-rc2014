; Find the address just after the the last queue
;
ql_end_addr:
    ld hl, (ql_base)            ; load the start of the queue list
qlea_next:
    ld d, 0x00                  ; zero high byte of d
    ld a, (hl)                  ; load the queue mask (length)
    or a                        ; test for zero
    jp z, qlea_found            ; end of list
    ld e, a                     ; copy length over to e
    inc hl                      ; skip over mask
    inc hl                      ; skip over read pointer
    inc hl                      ; skip over write pointer
    add hl, de                  ; add queue length
    inc hl                      ; add one
    jp qlea_next                ; look for the next queue
qlea_found:
    ret
