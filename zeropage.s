
.feature org_per_seg
.zeropage

.ifndef OS816 ; 816os: in BASIC's own bank, see below
.org ZP_START1

GORESTART:
	.res 3
GOSTROUT:
	.res 3
GOAYINT:
	.res 2
GOGIVEAYF:
	.res 2
.endif

.org ZP_START2
Z15:
	.res 1
.ifndef POSX; allow override
POSX:
.endif
	.res 1
.ifndef Z17; allow override
Z17:
.endif
	.res 1
.ifndef Z18; allow override
Z18:
.endif
	.res 1
LINNUM:
.ifndef TXPSV; allow override
TXPSV:
.endif
	.res 2
.ifdef OS816
PEEKBANK:			; the bank PEEK, POKE and WAIT use: with LINNUM,
	.res 1			; a long pointer (see BANK in os816_extra.s)
.assert PEEKBANK = LINNUM+2, error, "[LINNUM],Y needs the bank after LINNUM"
.endif
.ifndef INPUTBUFFER; allow override
INPUTBUFFER:
.endif

.org ZP_START3

CHARAC:
	.res 1
ENDCHR:
	.res 1
EOLPNTR:
	.res 1
DIMFLG:
	.res 1
VALTYP:
.ifdef CONFIG_SMALL
	.res 1
.else
	.res 2
.endif
DATAFLG:
	.res 1
SUBFLG:
	.res 1
INPUTFLG:
	.res 1
CPRMASK:
	.res 1
Z14:
	.res 1

.org ZP_START4

TEMPPT:
	.res 1
LASTPT:
	.res 2
.ifndef OS816
TEMPST:
	.res 9
.endif
INDEX:
	.res 2
DEST:
	.res 2
RESULT:
	.res BYTES_FP
RESULT_LAST = RESULT + BYTES_FP-1
TXTTAB:
	.res 2
VARTAB:
	.res 2
ARYTAB:
	.res 2
STREND:
	.res 2
FRETOP:
	.res 2
FRESPC:
	.res 2
MEMSIZ:
	.res 2
CURLIN:
	.res 2
OLDLIN:
	.res 2
OLDTEXT:
	.res 2
Z8C:
	.res 2
DATPTR:
	.res 2
INPTR:
	.res 2
VARNAM:
	.res 2
VARPNT:
	.res 2
FORPNT:
	.res 2
LASTOP:
	.res 2
CPRTYP:
	.res 1
FNCNAM:
.ifndef OS816
TEMP3:
.endif
	.res 2
DSCPTR:
.ifdef CONFIG_SMALL
		.res 2
.else
		.res 3
.endif
DSCLEN:
	.res 2
.ifndef JMPADRS ; allow override
JMPADRS			:= DSCLEN + 1
.endif
Z52:
	.res 1
ARGEXTENSION:
.ifndef CONFIG_SMALL
	.res 1
.endif
.ifndef OS816
TEMP1:
.endif
	.res 1
HIGHDS:
	.res 2
HIGHTR:
	.res 2
.ifndef CONFIG_SMALL
  .ifndef OS816
TEMP2:
  .endif
	.res 1
.endif
INDX:
TMPEXP:
.ifdef CONFIG_SMALL
TEMP2:
.endif
	.res 1
EXPON:
	.res 1
LOWTR:
.ifndef LOWTRX ; allow override
LOWTRX:
.endif
	.res 1
EXPSGN:
	.res 1
FAC:
	.res BYTES_FP
FAC_LAST = FAC + BYTES_FP-1
FACSIGN:
	.res 1
SERLEN:
	.res 1
SHIFTSIGNEXT:
	.res 1
ARG:
	.res BYTES_FP
ARG_LAST = ARG + BYTES_FP-1
ARGSIGN:
	.res 1
STRNG1:
	.res 2
SGNCPR = STRNG1
FACEXTENSION = STRNG1+1
STRNG2:
	.res 2
.ifdef AIM65
ATN:
	.res 3
ZBE:
	.res 1
.endif
.ifdef SYM1
USR1:
	.res 3
USR2:
	.res 3
USR3:
	.res 3
.endif
.ifdef OS816
TXTPTR:
	.res 2
STKSAV:				; for txs_safe and stack_x16: X, then the
	.res 2			; stack page (macros.s)
KEYBUF:				; a key ISCNTC read that wasn't Ctrl-C, or 0
	.res 1
.assert * <= $0100, error, "direct page variables don't fit in a page"
.else
CHRGET:
TXTPTR = <(GENERIC_TXTPTR-GENERIC_CHRGET + CHRGET)
CHRGOT = <(GENERIC_CHRGOT-GENERIC_CHRGET + CHRGET)
CHRGOT2 = <(GENERIC_CHRGOT2-GENERIC_CHRGET + CHRGET)
RNDSEED = <(GENERIC_RNDSEED-GENERIC_CHRGET + CHRGET)
.endif

.ifdef OS816
; ----------------------------------------------------------------------------
; 816os: variables in BASIC's own bank
;
; The direct page is in bank 0, but (zp),Y pointers reach BASIC's own bank
; through the data bank register. So anything BASIC points at with a 16-bit
; pointer has to be in this bank, not in the direct page. This segment is
; linked into page 0 of the image, so pointers to it still have a zero high
; byte, as the code expects (for example "LDX #TEMPST" plus "LDY #$00").
; Labels here are absolute, so the assembler uses absolute addressing
; (data bank) for them, not direct page addressing.
; ----------------------------------------------------------------------------
.segment "BANKVARS": absolute
BANKVARS_START:
TEMPST:				; temporary string descriptors
	.res 9
TEMP1:				; floating point temporaries
	.res 5
TEMP2:
	.res 5
TEMP3:
	.res 5
RNDSEED:
	.res BYTES_FP
FORBUF:				; NEXT: STEP, its sign and the limit, from the stack
	.res 2*BYTES_FP+1
ARGBUF:				; relational operators: ARG, for FCOMP
	.res BYTES_FP
FACBUF:				; LET: a string descriptor from FAC
	.res 3
BANKVARS_PAGE0_END:		; everything above must stay in page 0
GORESTART:			; JMP instructions
	.res 3
GOSTROUT:
	.res 3
USR:
	.res 3
JMPTRAMP:			; for jumps through a vector in the direct page
	.res 3
GOAYINT:			; addresses for USR routines
	.res 2
GOGIVEAYF:
	.res 2
XM_ADDR:			; LOAD and SAVE: address and count tables
	.res 3
XM_LEN:
	.res 3
.assert BANKVARS_PAGE0_END <= STACK2-1, lderror, "BANKVARS must be in page 0, below STACK2-1"
.endif


