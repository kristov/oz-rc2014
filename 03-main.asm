kq_curr_id: equ 0x00
kq_tbase: equ 0x00
kq_tab_max: 0x00
kqf_tbase: equ 0x00

kq_init:
    ld a, 0x00                  ; zero a
    ld (kq_curr_id), a          ; save it as the current queue id
kq_main_loop:
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy current queue id to l
    ld de, (kq_tbase)           ; load the base address of table from variable
    add hl, de                  ; add base address to index
    ld e, a                     ; copy current queue id to temp variable
    ld a, (kq_tab_max)          ; load the table length from variable
    ld b, a                     ; set counter to table length
    sub e                       ; a now contains the max id - id
    ld d, a                     ; load passes until a loop around
kq_next_id:
    inc hl                      ; shift hl to next item
    inc e                       ; increment the new id stored
    dec d                       ; decrement loop var
    jp nz, kq_no_reset          ; if loop var is not zero skip resetting de
    ld de, (kq_tbase)           ; cycle de back to beginning of table
    ld e, 0x00                  ; cycle new id back around
kq_no_reset:
    ld a, (hl)                  ; load byte to prepare to test it
    sub c                       ; test if its equal
    jp z, kq_found              ; if zero we found an entry
    djnz kq_next_id             ; keep looking b number of times
    jp kq_main_loop             ; keep going forever
kq_found:
    ld a, e                     ; get new found id
    ld (kq_curr_id), a          ; save it
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy current tid to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    add hl, hl                  ; x8
    add hl, hl                  ; x16
    ld de, (kqf_tbase)          ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ;
    ; get the queue location and store it in a variable
    ; get the producer function id and store in a variable
    ; get the consumer function id and store in a variable
    ;
    ; load the producer function record by id
    ; get the sp and store in a variable
    ; get the heap base and store in a variable
    ; switch the sp in, push return address on stack
    ; JP to function
    ; restore the kernel sp
    ;
    ; load the consumer function record by id
    ; get the sp and store in a variable
    ; get the heap base and store in a variable
    ; switch the sp in, push return address on stack
    ; JP to function
    ; restore the kernel sp
    ;
    ; goto kq_main_loop
