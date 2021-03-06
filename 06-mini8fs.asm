m8_base: equ 0x0400
m8_block_base: equ m8_base + 0x0200
m8_files_per_block: equ 0x08
m8_file_entry_len: equ 0x08
m8_file_name_len: equ 0x06
m8_dir_separator: equ 0x2f

; Get memory address for block id
;
;     uint8_t* m8_blk_addr(uint8_t blockid);
;
m8_blk_addr:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ld l, (hl)                  ; load the block id L
    ld h, 0x00                  ; zero U
    xor a                       ; prepare for test
    cp l                        ; test for zero
    jp z, m8_ba_skip            ; skip multiplying zero
    add hl, hl                  ; x2
    add hl, hl                  ; x4
    add hl, hl                  ; x8
    add hl, hl                  ; x16
    add hl, hl                  ; x32
    add hl, hl                  ; x64
m8_ba_skip:
    ld de, m8_block_base        ; load base address
    add hl, de                  ; add multiplied offset
    ret

; Find a file entry from a chained block id
;
;     uint8_t* m8_blkc_find(uint8_t blockid, uint8_t* name, uint8_t strlen);
;
m8_blkc_find:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load the strlen
    ld b, (hl)                  ; load strlen
    inc hl                      ; skip over L
    inc hl                      ; skip over H
    ; load the desired file name from args
    ld e, (hl)                  ; load the name L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load the name U
    inc hl                      ; skip over H
    ; load the blockid from args and save it
    ld c, (hl)                  ; load blockid L
m8_bcf_nextb:
    push de                     ; save name
    push bc                     ; push blockid (c) and strlen arg (b)
    call m8_blk_addr            ; convert blockid into block addr
    pop bc                      ; restore blockid and strlen from stack
    pop de                      ; restore name
    ; swap the strlen and blockid
    ld a, b                     ; store strlen in a
    ld b, c                     ; store blockid in b
    ld c, a                     ; store strlen in c
    push bc                     ; save blockid (b) for later
m8_bcf_nextf:
    ; search for the file name in the current block
    ld b, m8_files_per_block    ; load the number of files per block
    push de                     ; save the desired name pointer
    push hl                     ; save file entry name from dir
    push bc                     ; save strlen in c (count in b)
    ; test the file name
    ld b, c                     ; set counter to strlen
m8_bcf_nc_loop:
    ld a, (de)                  ; load char from str2
    cp (hl)                     ; compare a with char at str1
    jp nz, m8_bcf_nc_nequ       ; not equal
    inc hl                      ; advance str1
    inc de                      ; advance str2
    djnz m8_bcf_nc_loop         ; keep looking
    jp m8_bcf_found             ; name matched!
m8_bcf_nc_nequ:
    pop bc                      ; pop strlen and count
    pop hl                      ; restore file entry name from dir
    ld d, 0x00                  ; zero high byte
    ld e, m8_file_entry_len     ; file entry length
    add hl, de                  ; advance to next file entry
    pop de                      ; restore the name pointer
    djnz m8_bcf_nextf           ; look for next file
    ; move to the next block in the chain
    pop bc                      ; restore the blockid
    push de                     ; save the desired name pointer
    push hl                     ; save file entry name from dir
    ; find the next chained id
    ld h, 0x00                  ; zero d
    ld l, b                     ; set the blockid
    add hl, hl                  ; block table entries two bytes
    ex de, hl                   ; free hl
    ld hl, m8_base              ; load the block table addr
    add hl, de                  ; hl is now the block table byte
    inc hl                      ; skip to next block val
    ld l, (hl)                  ; load the value
    xor a                       ; zero a
    cp l                        ; check for zero block id
    jp z, m8_bcf_retnull        ; no next block found
    ; swap the strlen and blockid
    ld a, c                     ; store strlen in a
    ld c, l                     ; save the next blockid in c
    ld b, a                     ; store the strlen in b
    pop hl                      ; restore file entry name from dir
    pop de                      ; restore the desired name pointer
    jp m8_bcf_nextb             ; check the next block
m8_bcf_found:
    pop bc                      ; restore the blockid
    pop hl                      ; restore file entry address
    pop de                      ; discard name pointer
    pop bc                      ; discard saved blockid
    ret
m8_bcf_retnull:
    pop hl                      ; discard
    pop hl                      ; discard
    ld hl, 0x0000               ; return null
    ret

; Find a chunk of X consecutive free blocks
;
;     uint8_t m8_find_cons_blks(uint8_t nrblocks);
;
m8_find_cons_blks:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load nrblocks
    ld b, (hl)                  ; load nrblocks
    ld c, 0x00                  ; start of block chain
    ld d, b
    ld e, c
    ld hl, m8_base              ; set block table base
m8_fcb_loop:
    ld a, (hl)                  ; load block usage
    or a                        ; test for zero
    jp nz, m8_fcb_adv           ; block in use
    dec b                       ; decrement nrblocks
    jp z, m8_fcb_found          ; found b consecutive blocks
    inc e                       ; increment block start
    jp z, m8_fcb_empty          ; no more blocks left
    inc hl                      ; increment over block usage
    inc hl                      ; increment over block link
    jp m8_fcb_loop              ; loop to keep looking
m8_fcb_adv:
    inc e                       ; increment block start
    jp z, m8_fcb_empty          ; no more blocks left
    inc hl                      ; increment over block usage
    inc hl                      ; increment over block link
    ld b, d                     ; restore original counter
    ld c, e                     ; advance block start
    jp m8_fcb_loop              ; loop to keep looking
m8_fcb_found:
    ld h, 0x00                  ; zero U
    ld l, c                     ; return start block location
    ret
m8_fcb_empty:
    ld hl, 0x0000               ; block zero reserved - invalid
    ret

; Find and link a chunk of X consecutive blocks together
;
;     uint8_t* m8_link_cons_blks(uint8_t nrblocks);
;
m8_link_cons_blks:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load nrblocks
    ld b, (hl)                  ; load nrblocks
    push bc                     ; push arg
    call m8_find_cons_blks      ; find free blocks
    pop bc                      ; restore nrblocks
    xor a                       ; prepare to test l
    cp l                        ; see if we found blocks
    jp z, m8_lcb_empty          ; no free blocks
    ld c, l                     ; save blockid
    push bc                     ; save blockid and nrblocks
    push hl                     ; push arg
    call m8_blk_addr            ; get block start address
    pop de                      ; discard arg
    pop bc                      ; restore blockid and nrblocks
    push hl                     ; save starting block address
    ld h, 0x00                  ; zero H
    ld l, c                     ; prepare to multiply blockid by 2
    add hl, hl                  ; multiply
    ld de, m8_base              ; load block table base
    add hl, de                  ; add to multiplied blockid
m8_lcb_next:
    ld (hl), 0x01               ; set to in-use
    dec b                       ; decrement nrblocks
    jp z, m8_lcb_done           ; finished writing blocks
    inc c                       ; next block id
    inc hl                      ; move to block link
    ld (hl), c                  ; save next block link
    inc hl                      ; move to block status
    jp m8_lcb_next              ; keep writing blocks
m8_lcb_done:
    pop hl                      ; restore starting block address
    ret
m8_lcb_empty:
    ld hl, 0x0000               ; invalid block address
    ret

; Unlink (delete) a chunk of X consecutive blocks
;
;     m8_unlink_cons_blks(uint8_t blockid);
;
m8_unlink_cons_blks:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load nrblocks
    ld c, (hl)                  ; load blockid
    ld b, 0x00                  ; count of unlinked blocks
    xor a                       ; set value for tests
    ld de, m8_base              ; load block table base
m8_ucb_nextblk:
    ld h, 0x00                  ; zero H
    ld l, c                     ; prepare to multiply blockid by 2
    add hl, hl                  ; multiply
    add hl, de                  ; add to multiplied blockid
    ld (hl), 0x00               ; zero block in-use value
    inc b                       ; count of unlinked blocks
    inc hl                      ; move to next block id
    ld c, (hl)                  ; load next block id
    cp c                        ; test block id for zero-ness
    jp z, m8_ucb_done           ; move to the next block
    ld (hl), 0x00               ; zero block id
    jp m8_ucb_nextblk           ; keep going
m8_ucb_done:
    ld h, 0x00                  ; zero U
    ld l, b                     ; count of unlinked blocks
    ret

; Find a file/dir entry for a path (null terminated), from a starting block id
;
;     uint8_t* m8_path_find(uint8_t blockid, uint8_t* path);
;
m8_path_find:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load the path from args
    ld e, (hl)                  ; load path L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load path U
    inc hl                      ; skip over H
    ; load the block id from args and save it
    ld b, (hl)                  ; save block id L
    ld c, 0x00                  ; zero counter
    ld h, d                     ; set pointers equal
    ld l, e                     ; set pointers equal
m8_pf_nextc:
    ld a, (hl)                  ; load the character
    inc hl                      ; advance char pointer
    cp m8_dir_separator         ; look for dir separator
    jp z, m8_pf_sepfound        ; process the part
    cp 0x00                     ; look for null terminator
    jp z, m8_pf_lstfound        ; process the last part
    inc c
    jp m8_pf_nextc              ; go to next char
m8_pf_sepfound:
    push hl                     ; save the end str address
    ld l, b                     ; copy block id to l
    push hl                     ; push block id arg
    push de                     ; push string start
    push bc                     ; push string length in c
    call m8_blkc_find           ; find the path part
    pop bc                      ; restore c
    pop de                      ; restore string location
    xor a                       ; prepare for test
    cp l                        ; test l for non-zeroness
    jp nz, m8_pf_pfound         ; if non-zero something found
    cp h                        ; test h for non-zeroness
    jp nz, m8_pf_pfound         ; if non-zero something found
    jp m8_pf_notfound           ; not found
m8_pf_pfound:
    ld b, 0x00                  ; prepare to add 6
    ld c, 0x06                  ; prepare to add 6
    add hl, bc                  ; skip over filename
    ld a, (hl)                  ; grab the type byte
    bit 7, a                    ; test the dir bit
    jp z, m8_pf_notfound        ; these parts cant be files
    inc hl                      ; advance to block id
    ld b, (hl)                  ; save the block id of dir
    pop hl                      ; discard block id
    pop de                      ; restore final str address
    ld h, d                     ; set pointers equal
    ld l, e                     ; set pointers equal
    ld c, 0x00                  ; zero char count
    jp m8_pf_nextc              ; look for next part
m8_pf_lstfound:
    push hl                     ; save the end str address
    ld l, b                     ; copy block id to l
    push hl                     ; push block id arg
    push de                     ; push string start
    push bc                     ; push string length in c
    call m8_blkc_find           ; find the path part
    pop bc                      ; restore c
    pop de                      ; restore string location
    xor a                       ; prepare for test
    cp l                        ; test l for non-zeroness
    jp nz, m8_pf_ffound         ; if non-zero something found
    cp h                        ; test h for non-zeroness
    jp nz, m8_pf_ffound         ; if non-zero something found
    jp m8_pf_notfound           ; not found
m8_pf_ffound:
    pop de                      ; discard arg
    pop de                      ; discard arg
    ret
m8_pf_notfound:
    pop hl                      ; discard arg
    pop hl                      ; discard arg
    ld hl, 0x0000               ; not found
    ret

; Delete a file entry for a path (null terminated), from a starting block id
;
;     uint8_t m8_path_rm(uint8_t blockid, uint8_t* path);
;
m8_path_rm:
    ld hl, 0x0002               ; prepare hl to extract argument on the stack
    add hl, sp                  ; skip over return address on stack
    ; load the path from args
    ld e, (hl)                  ; load path L
    inc hl                      ; skip over L
    ld d, (hl)                  ; load path U
    inc hl                      ; skip over H
    ; load the blockid from args and save it
    ld c, (hl)                  ; save block id L
    push bc                     ; push blockid
    push de                     ; push string
    call m8_path_find           ; find the address of the file entry
    pop de                      ; discard arg
    pop bc                      ; discard arg
    xor a                       ; zero a
    cp l                        ; test l for non-zeroness
    jp nz, m8_pr_found          ; if non-zero something found
    cp h                        ; test h for non-zeroness
    jp nz, m8_pr_found          ; if non-zero something found
    ld hl, 0xffff               ; file not found
    ret
m8_pr_found:
    ld b, 0x07
m8_pr_fnloop:
    ld (hl), 0x00               ; zero file entry
    inc hl                      ; go to next byte
    djnz m8_pr_fnloop           ; erase file name
    push hl                     ; save blockid location
    ld d, 0x00                  ; zero U
    ld e, (hl)                  ; save blockid
    push de                     ; push blockid of file
    call m8_unlink_cons_blks    ; delete the chain of blocks
    pop de                      ; discard arg
    ex de, hl                   ; save nr blocks unlinked in de
    pop hl                      ; restore blockid location
    ld (hl), 0x00               ; zero blockid
    ld hl, 0x0000               ; success
    ex de, hl                   ; return nr blocks unlinked
    ret

; Create a new file for a path (null terminated), from a starting block id
;
;     uint8_t m8_file_new(uint8_t blockid, uint8_t* path);
;
m8_file_new:
    ; get file size
    ; look up 

; Public API
;
; * Find a file by path and return record (m8_path_find)
; * Delete a file and free associated blocks (m8_path_rm)
; * Delete a directory if empty
; * List the contents of a directory by path
; * Create a new directory
; * Create a new file
