.segment "EXTRA"
.export MONRDKEY

MONRDKEY:
  jsr CHRIN
  bcc @monrdkey_no_keypressed
  jsr CHROUT
@monrdkey_no_keypressed:
  rts

.include "eater_bios.s"
