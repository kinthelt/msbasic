.segment "CHRGET"
RAMSTART1:
.ifdef OS816
; 816os: the direct page is in bank 0 and the program text is in BASIC's
; bank, so CHRGET can't be copied to the direct page and modify its own
; operand. It reads the text through TXTPTR instead, with the same
; results: A, flags, and X and Y untouched.
CHRGET:
        inc     TXTPTR
        bne     CHRGOT
        inc     TXTPTR+1
CHRGOT:
        lda     (TXTPTR)
        cmp     #$3A
        bcs     L4058
CHRGOT2:
        cmp     #$20
        beq     CHRGET
        sec
        sbc     #$30
        sec
        sbc     #$D0
L4058:
        rts
.else
GENERIC_CHRGET:
        inc     TXTPTR
        bne     GENERIC_CHRGOT
        inc     TXTPTR+1
GENERIC_CHRGOT:
GENERIC_TXTPTR = GENERIC_CHRGOT + 1
        lda     $EA60
.ifdef KBD
        jsr     LF430
.endif
        cmp     #$3A
        bcs     L4058
GENERIC_CHRGOT2:
        cmp     #$20
        beq     GENERIC_CHRGET
        sec
        sbc     #$30
        sec
        sbc     #$D0
L4058:
        rts
.endif
