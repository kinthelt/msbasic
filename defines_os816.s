; 816os: BASIC as a native-mode 65C816 process.
;
; The image is linked at $0000 (os816.cfg). Load it into any free bank
; (1-7) and start it with the shell's "run <bank>". It runs in native mode
; with 8-bit registers, its own bank as the program and data bank, and
; uses its bank up to RAMTOP for the program and variables.
;
; Its direct page and stack can't be where a 6502 expects them, and both
; are in bank 0 while the program is in BASIC's bank. Where that matters,
; the code has ".ifdef OS816" sections or the macros at the end of
; macros.s. In short:
;
; - The zero page variables are in the direct page the kernel gives the
;   process.
; - The kernel also gives each process a 2 KB stack area in bank 0. BASIC
;   uses its top page as the stack page; TSX gives the offset in that page,
;   as on a 6502. STACK is $00:0000 as a far address, so the 6502 code's
;   "LDA STACK+n,X" after a TSX assembles as long,X, and stack_x16 makes X
;   the whole stack pointer value for it. TXS with 8-bit index registers
;   would clear the stack pointer's high byte, so it is txs_safe.
; - Anything BASIC reaches through a 16-bit pointer must be in its own
;   bank: the temporary string descriptors, the floating point
;   temporaries, the RND seed, and the input and number output buffers
;   (BANKVARS in zeropage.s, INPUTBUFFER, STACK2).
; - CHRGET can't run from the direct page, so it is ordinary code that
;   reads the program text with LDA (TXTPTR).
; - JMP (addr) reads its address from bank 0, and JSR to a zero page
;   address goes to $00xx of BASIC's bank. So the jump vectors (GORESTART,
;   USR...) are JMP instructions in BASIC's bank, and jumps through a
;   pointer in the direct page go through JMPTRAMP.

; configuration
CONFIG_2A := 1
;
;CONFIG_CBM_ALL := 1
;
;CONFIG_DATAFLG := 1
;CONFIG_EASTER_EGG := 1; writes to the PET screen at $8000, BASIC's RAM here
;CONFIG_FILE := 1; support PRINT#, INPUT#, GET#, CMD
;CONFIG_NO_CR := 1; terminal doesn't need explicit CRs on line ends
;CONFIG_NO_LINE_EDITING := 1; support for "@", "_", BEL etc.
;CONFIG_NO_READ_Y_IS_ZERO_HACK := 1
CONFIG_PEEK_SAVE_LINNUM := 1
CONFIG_SCRTCH_ORDER := 2
;
; zero page (the direct page; GORESTART and the other vectors are in
; BANKVARS, so there is no ZP_START1)
ZP_START2 = $0C
ZP_START3 = $62
ZP_START4 = $6D
;
; inputbuffer, in BASIC's bank; INPUTBUFFER-3 to INPUTBUFFER-1 are used too
INPUTBUFFER     := $0200
;
; constants
SPACE_FOR_GOSUB := $3E
STACK_TOP		:= $FA
WIDTH			:= 40
WIDTH2			:= 30

; $00:0000, as a far label, so "LDA STACK+n,X" is a long,X access to the
; stack in bank 0 (see above)
.pushseg
.segment "BANK0": far
STACK:
.popseg
; FOUT's number buffer, from STACK2-1, in BASIC's bank. As on the 6502,
; STACK2-1 is in page 0, so STR$ copies its result out of the buffer.
STACK2			:= $0100

; RAMSTART2 is the end of the image (os816_extra.s). BASIC's memory ends at
; RAMTOP, where 816os's cfg/app.cfg ends a program; the 816os design keeps
; the rest of a bank in mind for messages between processes.
RAMTOP			:= $E000

; 816os kernel services (816os include/os816.inc), called with JSL
K_PUTC			:= $00FFB0
K_GETC			:= $00FFB3
K_YIELD			:= $00FFB9
K_LOAD			:= $00FFCB
K_SAVE			:= $00FFCE
