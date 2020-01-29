; The main OS loop.
;
;kq_main:
;    ld a, (kq_curr_id)          ; load the current queue idx into a
;    call kqs_next_q_id          ; find the next runnable queue
;    sub l                       ; test equality with returned id
;    jp z, kq_main               ; loop indefinitely unless a new queue found
;    push hl                     ; push the new queue id onto args
;    call kq_run_queue           ; run the newly detected queue
;    pop hl                      ; clean up arguments
;    jp kq_main                  ; do it all over again

; Takes a queue id from argument and run the producer and consumer functions.
;
;kq_run_queue:
;    ld hl, 0x0003               ; extract argument 2 from stack
;    add hl, sp                  ; skip over return address on stack
;    ld d, 0x00                  ; zero d
;    ld e, (hl)                  ; load the id
;    ex de, hl                   ; swap them for multiplication
;    add hl, hl                  ; 2x
;    add hl, hl                  ; 4x
;    add hl, hl                  ; 8x
;    ld de, kq_tbase             ; set the queue table base
;    add hl, de                  ; add multiplied offset
;    ld de, kq_addr              ; load base of queue vars
;    ldi
;    ldi
;    ldi
;    ldi
;    ldi
;    ldi
;    ret

; Run the loaded producer function.
;
kq_run_func:
    ld hl, 0x0002               ; extract argument stack
    add hl, sp                  ; skip over return address on stack
    ld e, (hl)                  ; load lower byte
    inc hl                      ; move to higher byte
    ld d, (hl)                  ; load higher byte
    ex de, hl                   ; de is nowthe function address
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


