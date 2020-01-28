; Returns the index of the next available queue record.
;
kqs_next_q_id:
    ld hl, kq_curr_id           ; set the current queue idx addr
    ld a, (hl)                  ; load the current queue idx into a
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


