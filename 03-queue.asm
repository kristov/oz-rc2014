; Queue main loop function. It is expected that this function never ends.
;
kq_main_loop_COMPLEX:
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
    push af                     ; prepare to call kq_load_q
    call kq_load_q              ; load the queue record into working space
    pop af                      ; discard af from stack
    ld a, (kq_prod_id)          ; load the producer id
    push af                     ; prepare to call kq_load_func
    call kq_load_func           ; load the producer into working space
    pop af                      ; discard af from stack
    call kq_run_func            ; run the current function
    ld a, (kq_cons_id)          ; load the consumer id
    push af                     ; prepare to call kq_load_func
    call kq_load_func           ; load the consumer into working space
    pop af                      ; discard af from stack
    call kq_run_func            ; run the current function
    ld a, (kq_curr_id)          ; prepare to save the queue state
    push af                     ; push current queue id onto stack
    call kq_save_q              ; save the queue back to table
    pop af                      ; discard af from stack
    jp kq_main_loop

; Test loop assuming the current queue is never switched
;
kq_main_loop:
    ld a, (kq_prod_id)          ; load the producer id
    push af                     ; prepare to call kq_load_func
    call kq_load_func           ; load the producer into working space
    pop af                      ; discard af from stack
    call kq_run_func            ; run the current function
    ld a, (kq_cons_id)          ; load the consumer id
    push af                     ; prepare to call kq_load_func
    call kq_load_func           ; load the consumer into working space
    pop af                      ; discard af from stack
    call kq_run_func            ; run the current function
    jp kq_main_loop

; Load a queue from the queue table into working space
;
kq_load_q:
    ld hl, 0x0002               ; extract argument 2 from stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; copy the single byte argument to a
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
    ldi                         ; size mask
    ldi                         ; flags
    ret

; Load a function into the function record
;
kq_load_func:
    ld hl, 0x0002               ; extract argument 2 from stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; copy the single byte argument to a
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy function id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    ld de, kfn_tbase            ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ld de, kfn_sp               ; set block copy destination address
    ldi                         ; low byte of function address
    ldi                         ; high byte of function address
    ldi                         ; low byte of stack pointer
    ldi                         ; high byte of stack pointer
    ret

; Save a function into the function table
;
kq_save_func:
    ld hl, 0x0002               ; extract argument 2 from stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; copy the single byte argument to a
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy function id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    ld de, kfn_tbase            ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ex de, hl                   ; exchange
    ld hl, kfn_sp               ; set block copy source address
    ldi                         ; low byte of function address
    ldi                         ; high byte of function address
    ldi                         ; low byte of stack pointer
    ldi                         ; high byte of stack pointer
    ret

; Run the loaded function
;
kq_run_func:
    ld bc, kq_run_func_ret      ; put return address in bc
    ld hl, (kfn_addr)           ; load the function address into hl
    ld sp, (kfn_sp)             ; set stack pointer
    push bc                     ; push return address on function stack
    jp (hl)                     ; jump to the function
kq_run_func_ret:
    ret

; Check the interrupt disable flag and enable it
;
kq_cflag_ei:
    ld sp, (k_sp_kernel)        ; restore the kernel stack pointer
    ld a, (kq_flags)            ; load flags
    bit 0, a                    ; test interrupt disable flag
    jp z, kq_cflag_ei_ret       ; skip ei if not enabled
    ei                          ; enable interrupts
kq_cflag_ei_ret:
    ret

; Check the interrupt disable flag and disable it
;
kq_cflag_di:
    ld a, (kq_flags)            ; load flags
    bit 0, a                    ; test interrupt disable flag
    jp z, kq_cflag_di_ret       ; skip di if not enabled
    di                          ; disable interrupts
kq_cflag_di_ret:
    ret

; Save the loaded queue back into the queue table
;
kq_save_q:
    ld hl, 0x0002               ; extract argument 2 from stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; copy the single byte argument to a
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy queue id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    add hl, hl                  ; x8
    ld de, kq_tbase             ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ex de, hl                   ; swap the usual destination
    ld hl, kq_addr              ; set block copy destination address
    ldi                         ; low byte of queue address
    ldi                         ; high byte of queue address
    ldi                         ; producer id
    ldi                         ; consumer id
    ldi                         ; write pointer idx
    ldi                         ; read pointer idx
    ldi                         ; size mask
    ldi                         ; flags
    ret

; Returns the memory address of the kq_tbase queue entry for the provided
; index.
;
kq_addr_by_idx:
    ld hl, 0x0002               ; extract argument 2 from stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; copy the single byte argument to a
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy queue id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    add hl, hl                  ; x8
    ld de, kq_tbase             ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ret

; Returns the memory address of the kfn_tbase function entry for the provided
; index.
;
kfn_addr_by_idx:
    ld hl, 0x0002               ; extract argument 2 from stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; copy the single byte argument to a
    ld h, 0x00                  ; zero h
    ld l, a                     ; copy queue id to l
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    ld de, kfn_tbase            ; put base address in de
    add hl, de                  ; add base address to calculated offset
    ret
