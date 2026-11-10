/***************************************/
/*  Use MADS http://mads.atari8.info/  */
/*  Mode: DLI (char mode)              */
/***************************************/
	.ifndef integrated
	integrated = 0
	eif
	
	icl "dtnx_pg.h"
	ift integrated == 1
begin
	eif
	org $f0

fcnt	.ds 2
fadr	.ds 2
fhlp	.ds 2
cloc	.ds 1
regA	.ds 1
regX	.ds 1
regY	.ds 1

WIDTH	= 40
HEIGHT	= 30
	ift integrated == 0
; ---	BASIC switch OFF
	org $2000\ mva #$ff portb\ rts\ ini $2000
	icl "..\..\matosimi_macros.asx"
; ---	MAIN PROGRAM
	org $2000
	els
	org begin ;$2000
	eif
.print	"free before DL: ",ant-*
	.align $100
ant	dta $70
	dta $70,$F0,$44,a(scr),$04,$84,$04,$04,$84,$84,$84
	dta $30+$80,$70,$20
	dta $42+$80,a(texts2026) ;mode
	dta $30
	dta 2	;mode selection options
	dta $70+$80
	dta 2+$80	;stage set text
	dta $30
	dta 2	;stage selection options
	dta $70
	dta 2+$80	;last/high score
	dta $30
	dta 2,2,$82	;bigscore+stage
	dta $80+$30
	dta $41,a(ant)

scr	ins "dtnx_pg.scr"
texts2026	ins "..\texts2026.dat"
	.ALIGN $0400
fnt	ins "dtnx_pg.fnt"
textfnt	ins "..\texts2026.fnt"
.print	"free before pmg: ",pmg-*
	ift USESPRITES
	.ALIGN $0800
pmg	.ds $0300
	ift FADECHR = 0
	SPRITES
	els
	.ds $500
	eif
	eif
	
main
; ---	init PMG

	ift USESPRITES
	mva >pmg pmbase		;missiles and players data address
	mva #$03 pmcntl		;enable players and missiles
	eif

	lda:cmp:req $14		;wait 1 frame

	sei			;stop IRQ interrupts
	mva #$00 nmien		;stop NMI interrupts
	sta dmactl
	mva #$fe portb		;switch off ROM to get 16k more ram

	;todo: draw_bigscore

	mwa #NMI $fffa		;new NMI handler

	mva #$c0 nmien		;switch on NMI+DLI again

	ift CHANGES		;if label CHANGES defined

_lp	lda trig0		; FIRE #0
	beq stop

	lda trig1		; FIRE #1
	beq stop

	lda consol		; START
	and #1
	beq stop

	joy_control
	
	lda skctl
	and #$04
	bne _lp			;wait to press any key; here you can put any own routine

	els

null	jmp DLI.dli1		;CPU is busy here, so no more routines allowed

	eif

	jmp *
stop
	mva #$00 pmcntl		;PMG disabled
	tax
	sta:rne hposp0,x+

	;mva #$ff portb		;ROM switch on
	;mva #$40 nmien		;only NMI interrupts, DLI disabled
	;cli			;IRQ enabled

	rts			;return to ... DOS


; ---	DLI PROGRAM

.local	DLI

	?old_dli = *

	ift !CHANGES

dli1	lda trig0		; FIRE #0
	beq stop
	
	lda trig1		; FIRE #1
	beq stop

	lda consol		; START
	and #1
	beq stop

	lda skctl
	and #$04
	beq stop

	lda vcount
	cmp #$02
	bne dli1

	:3 sta wsync

	DLINEW dli6

	eif

dli_start

dli6
	sta regA
	stx regX

	lda #$11
	sta wsync		;line=24
	sta gtictl
	sta wsync		;line=25
	sta wsync		;line=26
	sta wsync		;line=27
c8	lda #$A8
	sta wsync		;line=28
	sta color0
c9	lda #$96
	sta wsync		;line=29
	sta color0
c10	lda #$A8
c11	ldx #$A4
	sta wsync		;line=30
	sta color0
	stx color3
	sta wsync		;line=31
c12	lda #$BA
	sta wsync		;line=32
	sta color0
c13	lda #$A8
	sta wsync		;line=33
	sta color0
c14	lda #$BA
c15	ldx #$B6
	sta wsync		;line=34
	sta color0
	stx color3
	DLINEW dli7 1 1 0

dli7
	sta regA
	stx regX

c16	lda #$C8
c17	ldx #$C4
	sta wsync		;line=48
	sta color0
	stx color3
c18	lda #$BA
	sta wsync		;line=49
	sta color0
c19	lda #$C8
	sta wsync		;line=50
	sta color0
	sta wsync		;line=51
c20	lda #$D6
c21	ldx #$D2
	sta wsync		;line=52
	sta color0
	stx color3
c22	lda #$C8
	sta wsync		;line=53
	sta color0
c23	lda #$D6
	sta wsync		;line=54
	sta color0
	sta wsync		;line=55
c24	lda #$08
c25	ldx #$04
	sta wsync		;line=56
	sta color0
	stx color3
	DLINEW DLI.dli2 1 1 0

dli2
	sta regA
	stx regX
	sty regY
	lda >fnt+$400*$01
	sta wsync		;line=72
	sta chbase
	sta wsync		;line=73
	sta wsync		;line=74
	sta wsync		;line=75
x5	lda #$84
x6	ldx #$8C
c26	ldy #$E8
	sta wsync		;line=76
	sta hposp1
	stx hposp2
	sty colpm1
	sty colpm2
	DLINEW dli8 1 1 1

dli8
	sta regA
	stx regX
	sty regY

	sta wsync		;line=80
	sta wsync		;line=81
	sta wsync		;line=82
	sta wsync		;line=83
	sta wsync		;line=84
x7	lda #$6C
x8	ldx #$74
c27	ldy #$0C
	sta wsync		;line=85
	sta hposp1
	stx hposp2
	sty colpm1
	sty colpm2
	DLINEW dli3 1 1 1

dli3
	sta regA
	lda >fnt+$400*$00
	sta wsync		;line=88
	sta chbase
	mva joy_control.selector+1 hposp0
	;add #20
	;sta hposp1
	sta wsync
	mva #3 sizep0
	sta hposm0
	sta sizep1
	sta sizep2
	mva #$00 colpm2
	sta colpm1
	mva #$d4 hposp2
	mva #$0c hposp1
	DLINEW dli9 1 0 0

dli9 ;text part
	sta regA
	sta wsync		
	lda >textfnt	
	sta chbase
	mva #$6c colpm3
	mva #$2c hposp3
	mva #$d2 hposm3
	mva #$01 $d01b ;prior
	
.rept 6,#
	sta wsync
	mva #$60+:1*2 colbak
.endr	
	sta wsync
	mva #$00 colbak

	mva #$0e color1
	mva #$e2 color2
	
	DLINEW dli10 1 0 0

;easy normal hard	
dli10	sta regA
	sta wsync	
	;mva #$0e color1
	mva #$00 color2
	sta wsync
	mva #$34 colpm0
	;sta colpm1
:4	sta wsync
	mva cl0:#$36 colpm0
	;sta colpm1
:7	sta wsync
	mva #$34 colpm0
	;sta colpm1
	DLINEW dli11 1 0 0 

dli11	sta regA
	sta wsync	
	;mva #$0f color1
	mva #$e2 color2
	mva joy_control.selector+2 hposp0
	DLINEW dli_stage_set 1 0 0 

dli_stage_set
	sta regA
	sta wsync	
	;mva #$0c color1
	mva #$00 color2
	sta wsync
	mva #$34 colpm0
	;sta colpm1
:4	sta wsync
	mva cl1:#$36 colpm0
	;sta colpm1
:7	sta wsync
	mva #$34 colpm0
	;sta colpm1
	;mva #$0e color1
	mva #$e2 color2
	DLINEW dli12 1 0 0 

dli12	sta regA
	sta wsync	
	mva #$08 color1
	mva #$00 color2
	DLINEW dli13 1 0 0 

	
dli13	sta regA
	sta wsync
	;mva #$08 color1
	;mva #$00 color2
	DLINEW dli14 1 0 0 

dli14	
	sta regA
.rept 6,#
	sta wsync
	mva #$60+10-:1*2 colbak
.endr
	sta wsync
	mva #0 colbak
	lda regA
	rti

.endl

; ---

CHANGES = 1
FADECHR	= 0

SCHR	= 127

; ---

.proc	NMI

	bit nmist
	bpl VBL

	jmp DLI.dli_start
dliv	equ *-2

VBL
	sta regA
	stx regX
	sty regY

	sta nmist		;reset NMI flag

	mwa #ant dlptr		;ANTIC address program

	;mva #@dmactl(standard|dma|lineX1|players|missiles) dmactl	;set new screen width
	mva #scr40 dmactl 
	inc cloc		;little timer
	inc 20

; Initial values

	lda >fnt+$400*$00
	sta chbase
c0	lda #$00
	sta colbak
	lda #$02
	sta chrctl
	lda #$04
	sta gtictl
c1	lda #$96
	sta color0
c2	lda #$E4
	sta color1
c3	lda #$E6
	sta color2
c4	lda #$92
	sta color3
s0	lda #$00
	sta sizep0
x0	lda #$7C
	sta hposp0
	sta hposm0
c5	lda #$E2
	sta colpm0
s1	lda #$00
	sta sizep1
	sta sizep2
	sta sizep3
x1	lda #$6C
	sta hposp1
x2	lda #$74
	sta hposp2
x3	lda #$6C
	sta hposp3
c6	lda #$0C
	sta colpm1
	sta colpm2
c7	lda #$EE
	sta colpm3
x4	lda #$00
	sta hposm1
	sta hposm2
	sta hposm3
	sta sizem

	mwa #DLI.dli_start dliv	;set the first address of DLI interrupt
;this area is for yours routines
	lda 20
	and #$06
	eor #$36
	add #2
	ldx joy_control.line
	cpx #2
	beq @+
	;line1 
	sta DLI.cl0
	jmp quit
	
@	;line2
	sta DLI.cl1
	jmp quit

quit
	lda regA
	ldx regX
	ldy regY
	rti

.endp

; ---	
.proc	joy_control
	lda porta
	and #$0f
	cmp #$0f
	beq x0
	lsr @
	bcs @+
	mva #1 line
	jmp set_active
@	lsr @
	bcs @+
	mva #2 line
	jmp set_active

@	lsr @
	bcc left
	lsr @
	bcc right
	
x0	rts
	
set_active 
	lda line
	cmp #1
	beq @+
	mva #$36 DLI.cl0
	sta DLI.cl1
	;mva #$56 DLI.cl1
	mva item+2 item
	mva selector+2 selector
	rts
@	;mva #$56 DLI.cl0
	mva #$36 DLI.cl1
	sta DLI.cl0
	mva item+1 item
	mva selector+1 selector
	rts
	
	
left	lda item
	cmp #2 ;last item
	beq pmleft
	cmp #1
	beq pmleft
	rts

pmleft	ldy #5
@	lda selector
	sub moves,y
	sta selector
	ldx line
	sta selector,x
	pause 0
	dey
	bpl @-
	dec item
	mva item item,x
	jsr delay
	rts
	
right	lda item
	beq pmright ;first item
	cmp #1
	beq pmright
	rts
	
pmright	ldy #5
@	lda moves,y
	add:sta selector
	ldx line
	mva selector selector,x
	pause 0
	dey
	bpl @-
	inc item
	mva item item,x
	jsr delay
	rts
	
delay	pause 5 ;todo: add debounce
;TODO: add keyboard, consol controls
	rts
	
selector	dta $3a,$3a,$3a
item	dta 0,0,0
line	dta 1
step	dta 0
moves	dta 1,4,8,16,20,3
mlef	dta 0
mrig	dta 0,14,13,13,0
rpt	dta 0
.endp

;X param: 0=left title(last), 1=right title(high)
.proc	write_stage
	cpx #0
	beq @+
	ldx #33-7	;shift to the right number
@	
	ldy #2
@	lda stageno,y
	add #$40
	sta texts2026+40*8+7,x
	dey
	bpl @-
	rts
stageno 	dta 2,2,2
.endp

; ---

	ift integrated == 0
	run main
	eif

	opt l-

.MACRO	SPRITES
missiles

	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02
	.he 00 02 02 00 02 00 02 00 00 00 00 00 00 00 00 00

.rept 11
	dta %00110000
.endr
.rept 100
	dta $ff
.endr
.rept 256-6*16-11-100-10
	dta %00110000
.endr

.rept 10
	dta 0
.endr

player0
;.rept 256
;	dta $ff
;.endr

	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 40 00 01 0A 20
	.he 80 18 20 08 30 00 18 28 10 38 00 18 20 18 08 30
	.he 08 10 30 08 30 08 00 00 00 40 10 04 01 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff ff
	.he ff ff ff ff ff ff ff 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 ff ff ff ff ff ff
	.he ff ff ff 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 
player1
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 02 00 04 00 08 08 08 00 10 10 20 58 00 00
	.he 00 80 20 00 00 01 0E F0 00 00 00 00 00 00 00 00
	.he 00 00
.rept 256-16*6-2
	dta 255
.endr

player2
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 80 40 00 00 00 20 00 00 00 00 00 20 70 20 50
	.he 20 00 00 00 30 C0 00 00 00 00 00 00 00 00 00 00
	.he 00 00
.rept 256-16*6-2
	dta 255
.endr
player3
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 20 70 70
	.he 70 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	
.rept 11
	dta 0
.endr
.rept 100
	dta $c0
.endr
.rept 256-6*16-11-100
	dta 0
.endr

.ENDM

USESPRITES = 1

.MACRO	DLINEW
	mva <:1 NMI.dliv
	ift [>?old_dli]<>[>:1]
	mva >:1 NMI.dliv+1
	eif

	ift :2
	lda regA
	eif

	ift :3
	ldx regX
	eif

	ift :4
	ldy regY
	eif

	rti

	.def ?old_dli = *
.ENDM


