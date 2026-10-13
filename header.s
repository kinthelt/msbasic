		.segment "HEADER"
.ifdef W65C816SXB
; Disable emulation mode (is left on from the monitor)
.setcpu "65816"
        SEC ;set carry for emulation mode
        XCE ;go into emulation mode
.setcpu "65C02"
        jsr INITUSBSERIAL

        ; Add a small delay to allow monitor to connect the terminal after
        ; starting execution
        ldy #0
        ldx #0
@loop:
        dex
        bne @loop
        dey
        bne @loop
        jmp COLD_START
.endif

.ifdef KBD
        jmp     LE68C
        .byte   $00,$13,$56
.endif
.ifdef AIM65
        jmp     COLD_START
        jmp     RESTART
        .word   AYINT,GIVAYF
.endif
.ifdef SYM1
        jmp     PR_WRITTEN_BY
.endif
.ifdef EATER
        jmp     COLD_START
.endif
.ifdef OS816
; The kernel starts a process here in native mode, with 16-bit registers,
; its own direct page, and S near the top of its stack area in bank 0.
; BASIC's stack is that area's top page (defines_os816.s).
        .a16
        .i16
        tsc
        and     #$FF00          ; the stack page
        ora     #STACK_TOP
        tcs
        sta     STKSAV          ; STKSAV+1 = the stack page
        sep     #$30
        .a8
        .i8
        stz     KEYBUF
        jmp     COLD_START
.endif
