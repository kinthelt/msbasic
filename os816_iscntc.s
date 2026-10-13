; Doesn't yield, since it runs before every statement. A key that isn't
; Ctrl-C is kept in KEYBUF for GETKEY, so GET still sees it (only the
; latest one, if several are typed between two statements).
ISCNTC:
        jsl     K_GETC
        bcc     not_cntc
        cmp     #3
        beq     is_cntc
        sta     KEYBUF

not_cntc:
        rts

is_cntc:
        ; Fall through
