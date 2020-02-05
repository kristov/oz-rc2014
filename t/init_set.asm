main:
    ; this inits a set with 4 child chunks for testing
    ld hl, 0x0400
    push hl
    call ql_set_init
    pop de

    ; chunk 0: append 5 bytes of space
    ld hl, 0x0400
    push hl
    ld hl, 0x0005
    push hl
    call ql_set_append
    pop de
    pop de
    ; init a 3 byte chunk into that space
    push hl
    ld hl, 0x0003
    push hl
    call ql_chunk_init
    pop de
    pop de
    ld (hl), 0xaa
    inc hl
    ld (hl), 0xaa
    inc hl
    ld (hl), 0xaa

    ; chunk 1: append 3 bytes of space
    ld hl, 0x0400
    push hl
    ld hl, 0x0003
    push hl
    call ql_set_append
    pop de
    pop de
    ; init a 1 byte chunk into that space
    push hl
    ld hl, 0x0001
    push hl
    call ql_chunk_init
    pop de
    pop de
    ld (hl), 0xbb

    ; chunk 2: append 6 bytes of space
    ld hl, 0x0400
    push hl
    ld hl, 0x0006
    push hl
    call ql_set_append
    pop de
    pop de
    ; init a 4 byte chunk into that space
    push hl
    ld hl, 0x0004
    push hl
    call ql_chunk_init
    pop de
    pop de
    ld (hl), 0xcc
    inc hl
    ld (hl), 0xcc
    inc hl
    ld (hl), 0xcc
    inc hl
    ld (hl), 0xcc

    ; chunk 3: append 5 bytes of space
    ld hl, 0x0400
    push hl
    ld hl, 0x0005
    push hl
    call ql_set_append
    pop de
    pop de
    ; init a 3 byte chunk into that space
    push hl
    ld hl, 0x0003
    push hl
    call ql_chunk_init
    pop de
    pop de
    ld (hl), 0xdd
    inc hl
    ld (hl), 0xdd
    inc hl
    ld (hl), 0xdd
