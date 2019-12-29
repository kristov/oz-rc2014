kq_init:
    ld a, 0x00                  ; zero a
    ld (kq_curr_id), a          ; save it as the current queue id
kq_main_loop:
    ld a, (kq_curr_id)          ; load the current queue id into a
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy current queue id to l
    ld de, kqs_tbase            ; load the base address of table from variable
    add hl, de                  ; add base address to index
    ld e, a                     ; copy current queue id to temp variable
    ld a, kqs_tmax              ; load the table length from variable
    ld b, a                     ; set counter to table length
    sub e                       ; a now contains the max id - id
    ld d, a                     ; load passes until a loop around
kq_next_id:
    inc hl                      ; shift hl to next item
    inc e                       ; increment the new id stored
    dec d                       ; decrement loop var
    jp nz, kq_no_reset          ; if loop var is not zero skip resetting de
    ld de, kqs_tbase            ; cycle de back to beginning of table
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
    ld l, a                     ; copy queue id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    add hl, hl                  ; x8
    ld de, kq_tbase             ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ld de, kq_addr              ; set block copy destination address
    ldi                         ; low byte of queue address
    ldi                         ; high byte of queue address
    ldi                         ; producer id
    ldi                         ; consumer id
    ldi                         ; write pointer idx
    ldi                         ; read pointer idx
kq_run_prod:
    ld a, (kq_prod_id)          ; load the producer id
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy function id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    ld de, kfn_tbase            ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ld de, kfn_addr             ; set block copy destination address
    ldi                         ; low byte of function address
    ldi                         ; high byte of function address
    ldi                         ; low byte of stack pointer
    ldi                         ; high byte of stack pointer
    ld bc, kq_run_cons          ; put return address in bc
    ld hl, (kfn_addr)           ; load the function address into hl
    ld sp, (kfn_sp)             ; set stack pointer
    push bc                     ; push return address on function stack
    jp (hl)                     ; jump to the function
    ld sp, (k_sp_kernel)        ; restore the kernel stack pointer
kq_run_cons:
    ld a, (kq_cons_id)          ; load the consumer id
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy function id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    ld de, kfn_tbase            ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ld de, kfn_addr             ; set block copy destination address
    ldi                         ; low byte of function address
    ldi                         ; high byte of function address
    ldi                         ; low byte of stack pointer
    ldi                         ; high byte of stack pointer
    ld bc, kq_end_loop          ; put return address in bc
    ld hl, (kfn_addr)           ; load the function address into hl
    ld sp, (kfn_sp)             ; set stack pointer
    push bc                     ; push return address on function stack
    jp (hl)                     ; jump to the function
    ld sp, (k_sp_kernel)        ; restore the kernel stack pointer
kq_end_loop:
    jp kq_main_loop
