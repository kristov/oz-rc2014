; The main OS loop.
;
kq_main:
    ld a, (kq_curr_id)          ; load the current queue idx into a
    call kqs_next_q_id          ; find the next runnable queue
    sub l                       ; test equality with returned id
    jp z, kq_main               ; loop indefinitely unless a new queue found
    push hl                     ; push the new queue id onto args
    call kq_run_queue           ; run the newly detected queue
    pop hl                      ; clean up arguments
    jp kq_main                  ; do it all over again

; Takes a queue id from argument and run the producer and consumer functions.
;
kq_run_queue:
    ld hl, 0x0003               ; extract argument 2 from stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; load the id
    ; calculate offset in queue table
    ; copy queue address into kq_addr
    ; copy producer function into kfn_addr
    ret

; Run the loaded function.
;
kq_run_func:
    ld hl, (kfn_addr)           ; load the function address into hl
    ld bc, kq_run_func_ret      ; put return address in bc
    push bc                     ; push return address on function stack
    jp (hl)                     ; jump to the function
kq_run_func_ret:
    ret

; Returns the index of the next available queue record.
;
kqs_next_q_id:
    ld a, (kq_curr_id)          ; load the current queue idx into a
    ld c, kqs_mask              ; set the queue status mask
kqsnq_next:
    inc a                       ; increment it
    and c                       ; mask it to wrap
    ld d, 0x00                  ; zero high byte of de
    ld e, a                     ; load lower byte of de with new idx
    ld hl, kqs_tbase            ; set the address of the status table
    add hl, de                  ; add idx to base address
    ld a, (hl)                  ; load the status
    or a                        ; test for zero
    jp nz, kqsnq_yes            ; if not zero go to found
    ld a, e                     ; copy index back
    jp kqsnq_next               ; loop
kqsnq_yes:
    ex de, hl                   ; de has the index
    ret


