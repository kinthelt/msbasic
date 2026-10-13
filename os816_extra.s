.segment "EXTRA"

; Console I/O through the 816os kernel services. They keep the caller's
; register widths, X, Y and flags, and A unless they return a value in it.

; Read a key if one was typed, without waiting, and echo it.
; Carry set: A = the key. Carry clear: none, A = 0.
GETKEY:
        lda     KEYBUF          ; first, a key ISCNTC kept
        beq     @read
        stz     KEYBUF
        sec
        bra     @echo
@read:
        jsl     K_GETC
        bcc     @none
@echo:
        jsl     K_PUTC
@none:
        rts

; As GETKEY, but if no key was typed, give the rest of this time slice to
; the other processes: INLIN and GET call this in a loop while they wait.
MONRDKEY:
        jsr     GETKEY
        bcs     @done
        jsl     K_YIELD
@done:
        rts

MONCOUT:
        jsl     K_PUTC
        rts

; JMP (INDEX) for FRM_STACK3: JMP (addr) would read the address from
; bank 0, not the direct page. Keeps A and the flags.
JMP_INDEX:
        php
        pha
        lda     INDEX
        sta     JMPTRAMP+1
        lda     INDEX+1
        sta     JMPTRAMP+2
        pla
        plp
        jmp     JMPTRAMP

; End of the image: the program text starts here (init.s).
RAMSTART2:
