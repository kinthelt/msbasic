; SAVE and LOAD over the serial port with XMODEM/CRC, using the XSAVE
; and XLOAD routines in the BIOS (eater_bios.s, eater_xmodem.s).
;
; A file is a raw image of the program text, from TXTTAB up to VARTAB:
; the tokenized lines followed by the two zero bytes that end the
; program. It holds no length or load address. XMODEM pads it with
; zeros to a whole number of 128-byte blocks, and LOAD finds the real
; end by walking the lines, so the padding does no harm.
;
; The XMODEM code keeps its variables in zero page from blkno to
; retry2, which is in the middle of BASIC's input buffer. The buffer
; still holds the rest of a line typed in direct mode, such as
; "SAVE:PRINT ...", so those bytes are saved on the stack around each
; transfer and put back afterwards.

XM_ZP		:= blkno		; first XMODEM zero page variable
XM_ZP_SIZE	= retry2 - blkno + 1	; number of bytes it uses

; Address and byte count tables (low, high, bank) for XSAVE and XLOAD.
; FAC and ARG are free between statements.
XM_ADDR		:= FAC
XM_LEN		:= ARG
XM_END		:= DEST			; end of the data LOAD received

.segment "CODE"

; Save the XMODEM zero page variables on the stack.
.macro xm_push_zp
	.local	@push
        ldx     #$00
@push:
        lda     z:XM_ZP,x
        pha
        inx
        cpx     #XM_ZP_SIZE
        bne     @push
.endmacro

; Put them back. Leaves the carry flag alone.
.macro xm_pull_zp
	.local	@pull
        ldx     #XM_ZP_SIZE-1
@pull:
        pla
        sta     z:XM_ZP,x
        dex
        bpl     @pull
.endmacro

; ----------------------------------------------------------------------------
; "SAVE" STATEMENT
;
; Sends the program as an XMODEM file. The XMODEM code prints whether
; the transfer worked; either way, BASIC carries on with the next
; statement.
; ----------------------------------------------------------------------------
SAVE:
        bne     SAVE_RTS	; anything after SAVE is a syntax error
        lda     TXTTAB
        sta     XM_ADDR
        lda     TXTTAB+1
        sta     XM_ADDR+1
        lda     #$00
        sta     XM_ADDR+2
        sta     XM_LEN+2
        sec
        lda     VARTAB
        sbc     TXTTAB
        sta     XM_LEN
        lda     VARTAB+1
        sbc     TXTTAB+1
        sta     XM_LEN+1
        xm_push_zp
        lda     #XM_ADDR
        ldx     #XM_LEN
        jsr     XSAVE
        xm_pull_zp
SAVE_RTS:
        rts

; ----------------------------------------------------------------------------
; "LOAD" STATEMENT
;
; Receives an XMODEM file into the program area, replacing the program
; and clearing the variables, then waits for the next command.
;
; If nothing was received, the old program is left as it was. If the
; transfer failed part way, or what arrived is not a BASIC program,
; the program area is no longer usable, so it is cleared as by NEW.
;
; Nothing stops a file bigger than free memory from being written past
; the end of RAM.
; ----------------------------------------------------------------------------
LOAD:
        bne     SAVE_RTS	; anything after LOAD is a syntax error
        lda     TXTTAB
        sta     XM_ADDR
        lda     TXTTAB+1
        sta     XM_ADDR+1
        lda     #$00
        sta     XM_ADDR+2
        xm_push_zp
        lda     #XM_ADDR
        jsr     XLOAD
        lda     z:ptr		; where the next byte would have gone
        sta     XM_END
        lda     z:ptrh
        sta     XM_END+1
        xm_pull_zp		; keeps the carry from XLOAD
        lda     XM_END		; was anything written?
        eor     TXTTAB		; (EOR, not CMP, to keep the carry)
        bne     LOAD_WROTE
        lda     XM_END+1
        eor     TXTTAB+1
        beq     SAVE_RTS	; no, keep the old program
LOAD_WROTE:
        bcc     LOAD_FAILED	; carry from XLOAD: clear if it failed

; Find the end of the program by walking its lines, as FIX_LINKS does,
; and make sure every line lies within the data received.
        lda     TXTTAB
        ldy     TXTTAB+1
        sta     INDEX
        sty     INDEX+1
LOAD_LINE:
        lda     INDEX		; INDEX+2 = end of this line's link,
        clc			; which must have been received
        adc     #$02
        tax
        lda     INDEX+1
        adc     #$00
        tay
        cpx     XM_END		; carry set if INDEX+2 >= XM_END
        sbc     XM_END+1	; (A still holds the high byte)
        bcc     LOAD_IN_RANGE	; INDEX+2 < XM_END
        cpx     XM_END		; INDEX+2 = XM_END is also fine
        bne     LOAD_BAD
        cpy     XM_END+1
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
        lda     XM_ADDR
        ldy     XM_ADDR+1
        sta     VARTAB
        sty     VARTAB+1
        lda     #<QT_OK		; FIX_LINKS goes back to reading lines
        ldy     #>QT_OK		; without a prompt, so print it here
        jsr     STROUT
        jmp     FIX_LINKS	; clear variables, relink, read next line

LOAD_BAD:
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
