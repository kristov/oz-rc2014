m8_base: equ 0x0400
m8_files_per_block: equ 0x08
m8_file_entry_len: equ 0x08
m8_file_name_len: equ 0x06
m8_dir_separator: equ 0x2f

; Find a free block in the block table
;
m8_blk_find_free:
    ld hl, m8_base
    ld b, 0xff
m8_bff_next:
    ld a, (hl)
    or a
    jp z, m8_bff_found
    inc hl
    dec b
    jp z, m8_bff_full
    jp m8_bff_next
m8_bff_full:
    ld hl, 0xffff
    ret
m8_bff_found:
    ld a, 0xff
    sub b
    ld h, 0x00
    ld l, a
    ret

; Get memory address for block id
;
m8_blk_addr:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld a, (hl)                  ; load the block id L
    or a                        ; test for zero
    jp z, m8_ba_skip            ; skip multiplying zero
    add a, a                    ; x2
    add a, a                    ; x4
    add a, a                    ; x8
    add a, a                    ; x16
    add a, a                    ; x32
    add a, a                    ; x64
m8_ba_skip:
    ld c, a                     ; copy to bc
    ld b, 0x00                  ; zero high byte of bc
    ld hl, m8_base              ; load base address
    add hl, bc                  ; add multiplied offset
    ret

; Compare a file name with another
;
m8_namecmp:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld b, (hl)                  ; load the strlen
    inc hl                      ; skip over L
    inc hl                      ; skip over U
    ld e, (hl)                  ; load the str2 L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the str2 U
    inc hl                      ; skip over H
    push de                     ; save str2
    ld e, (hl)                  ; load the str1 L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the str1 U
    inc hl                      ; skip over H
    ex de, hl                   ; hl is str1
    pop de                      ; restore de
m8_nc_loop:
    ld a, (de)                  ; load char from str2
    cp (hl)                     ; compare a with 
    jp nz, m8_nc_nequ           ; not equal
    inc hl                      ; advance str1
    inc de                      ; advance str2
    djnz m8_nc_loop             ; keep looking
    ld hl, 0x0000               ; string match
    ret
m8_nc_nequ:
    ld hl, 0xffff               ; not equal
    ret

; Find a file or folder in a directory block
;
;     m8_blk_find(uint16_t blk_addr, uint16_t name, uint8_t strlen);
;
; Returns address of entry in hl, or 0x0000
;
m8_blk_find:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld c, (hl)                  ; load strlen
    inc hl                      ; skip over L
    inc hl                      ; skip over H
    ; load the desired file name from args
    ld e, (hl)                  ; load the name L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the name U
    push de                     ; save the name pointer
    inc hl                      ; skip over H
    ; load the block address from args
    ld e, (hl)                  ; load block address L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load block address U
    ex de, hl                   ; hl is the block address
    pop de                      ; restore the name pointer
    ld b, m8_files_per_block    ; load the number of files per block
m8_bf_next:
    push de                     ; push the name pointer
    push hl                     ; push beginning of file entry name
    push bc                     ; push strlen in c
    call m8_namecmp             ; compare names
    pop bc                      ; pop arg
    ; check return code and jump if found
    ld a, l                     ; load low byte of return code
    or a                        ; test for zero
    jp z, m8_bf_found           ; name matched
    ; move hl forward and go to next entry
    pop hl                      ; restore file entry address
    ld d, 0x00                  ; zero high byte
    ld e, m8_file_entry_len     ; file entry length
    add hl, de                  ; advance to next file entry
    pop de                      ; restore the name pointer
    djnz m8_bf_next             ; look for next file
    ld hl, 0x0000               ; not found
    ret
m8_bf_found:
    pop hl                      ; restore file entry address
    pop de                      ; restore the name pointer
    ret
