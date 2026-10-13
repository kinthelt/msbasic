; SAVE and LOAD over the console with XMODEM/CRC, through the 816os
; kernel's K_SAVE and K_LOAD services. BASIC must be the foreground
; process; the kernel prints whether the transfer worked.
;
; A file is a raw image of the program text, from TXTTAB up to VARTAB,
; as in eater_loadsave.s: the tokenized lines followed by the two zero
; bytes that end the program. XMODEM pads it with zeros to a whole number
; of 128-byte blocks, and LOAD finds the real end by walking the lines.
;
; K_LOAD doesn't say how much it received, so LOAD checks the lines
; against the end of BASIC's memory (MEMSIZ) instead. Nothing stops a
; file bigger than that from being written past it, into the rest of the
; bank and on into the next one.

.segment "CODE"

; Point the XMODEM address table at TXTTAB, in this bank.
XM_TXTTAB:
        lda     TXTTAB
        sta     XM_ADDR
        lda     TXTTAB+1
        sta     XM_ADDR+1
        phb
        pla
        sta     XM_ADDR+2
        rts

; ----------------------------------------------------------------------------
; "SAVE" STATEMENT
;
; Sends the program as an XMODEM file. Either way, BASIC carries on with
; the next statement.
; ----------------------------------------------------------------------------
SAVE:
        bne     SAVE_RTS	; anything after SAVE is a syntax error
        jsr     XM_TXTTAB
        sec
        lda     VARTAB
        sbc     TXTTAB
        sta     XM_LEN
        lda     VARTAB+1
        sbc     TXTTAB+1
        sta     XM_LEN+1
        lda     #$00
        sta     XM_LEN+2
        rep     #$30		; the tables' addresses go in 16-bit A and X
        .a16
        .i16
        lda     #XM_ADDR
        ldx     #XM_LEN
        jsl     K_SAVE
        sep     #$30
        .a8
        .i8
SAVE_RTS:
        rts

; ----------------------------------------------------------------------------
; "LOAD" STATEMENT
;
; Receives an XMODEM file into the program area, replacing the program
; and clearing the variables, then waits for the next command.
;
; If the transfer failed but the old program is still whole (nothing
; arrived, say), it is kept. Otherwise, if the transfer failed or what
; arrived is not a BASIC program, the program area is no longer usable,
; so it is cleared as by NEW.
; ----------------------------------------------------------------------------
LOAD:
        bne     SAVE_RTS	; anything after LOAD is a syntax error
        jsr     XM_TXTTAB
        rep     #$20
        .a16
        lda     #XM_ADDR
        jsl     K_LOAD
        sep     #$20
        .a8
        lda     #$00
        rol     a
        sta     XM_LEN		; 1 if the transfer worked

; Find the end of the program by walking its lines, as FIX_LINKS does,
; and make sure every line starts below MEMSIZ.
        lda     TXTTAB
        ldy     TXTTAB+1
        sta     INDEX
        sty     INDEX+1
LOAD_LINE:
        lda     INDEX		; INDEX+2 = end of this line's link,
        clc			; which must be in BASIC's memory
        adc     #$02
        tax
        lda     INDEX+1
        adc     #$00
        tay
        cpx     MEMSIZ		; carry set if INDEX+2 >= MEMSIZ
        sbc     MEMSIZ+1	; (A still holds the high byte)
        bcc     LOAD_IN_RANGE	; INDEX+2 < MEMSIZ
        cpx     MEMSIZ		; INDEX+2 = MEMSIZ is also fine
        bne     LOAD_BAD
        cpy     MEMSIZ+1
        bne     LOAD_BAD
LOAD_IN_RANGE:
        sty     XM_ADDR+1	; keep INDEX+2: VARTAB if this is the end
        stx     XM_ADDR
        ldy     #$01
        lda     (INDEX),y	; high byte of the link is zero
        beq     LOAD_END	; at the end of the program
        ldy     #$04		; skip the link and line number
LOAD_SCAN:
        iny
        beq     LOAD_BAD	; too long to be a line
        lda     (INDEX),y
        bne     LOAD_SCAN	; up to the zero that ends the line
        iny
        tya
        clc
        adc     INDEX
        sta     INDEX
        bcc     LOAD_LINE
        inc     INDEX+1
        bne     LOAD_LINE	; always

LOAD_END:
        lda     XM_LEN
        beq     LOAD_KEEP	; the transfer failed
        lda     XM_ADDR
        ldy     XM_ADDR+1
        sta     VARTAB
        sty     VARTAB+1
        lda     #<QT_OK		; FIX_LINKS goes back to reading lines
        ldy     #>QT_OK		; without a prompt, so print it here
        jsr     STROUT
        jmp     FIX_LINKS	; clear variables, relink, read next line

; The transfer failed, but there is a program. If it ends where the old
; one did, it is the old one: keep it.
LOAD_KEEP:
        lda     XM_ADDR
        cmp     VARTAB
        bne     LOAD_FAILED
        lda     XM_ADDR+1
        cmp     VARTAB+1
        bne     LOAD_FAILED
        rts

LOAD_BAD:
        lda     XM_LEN
        beq     LOAD_FAILED	; the transfer failed: just say so
        lda     #<QT_NOT_PROGRAM
        ldy     #>QT_NOT_PROGRAM
        jsr     STROUT
LOAD_FAILED:
        lda     #<QT_ERASED
        ldy     #>QT_ERASED
        jsr     STROUT
        jsr     SCRTCH
        jmp     RESTART

QT_NOT_PROGRAM:
        .byte   "NOT A BASIC PROGRAM",CR,LF,0
QT_ERASED:
        .byte   "PROGRAM ERASED",CR,LF,0
