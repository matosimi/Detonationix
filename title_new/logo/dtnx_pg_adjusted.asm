/***************************************/
/*  Use MADS http://mads.atari8.info/  */
/*  Mode: DLI (char mode)              */
/***************************************/

	icl "dtnx_pg.h"
begin
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

; ---	BASIC switch OFF
	;org $2000\ mva #$ff portb\ rts\ ini $2000

; ---	MAIN PROGRAM
	org begin ;$2000
.print	"free before DL: ",ant-*
	.align $100
ant	dta $70
	dta $70,$F0,$44,a(scr),$04,$84,$04,$04,$84,$84,$84
	dta $30+$80,$70,$50
	dta $42+$80,a(titletxt+4*40) ;mode
	dta $20
:16	dta $4f,a(modesgfx+80*:1)
	dta $70+$80
	dta $42+$80,a(titletxt+2*40)
	dta $20
	dta $42,a(bigscore),2+$80
	dta $42,a(titletxt+3*40),$70+$80
	dta $41,a(ant)

scr	ins "dtnx_pg.scr"

bigscore	
:40*2	dta d"@"
;:40*15	dta 0	;we have 15 lines here 
.print	"free before font: ",fnt-*
	.ALIGN $0400
fnt	ins "dtnx_pg.fnt"
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

	draw_bigscore

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

	lda skctl
	and #$04
	bne _lp			;wait to press any key; here you can put any own routine

	els

null	jmp DLI.dli1		;CPU is busy here, so no more routines allowed

	eif


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
	DLINEW dli9 1 0 0

dli9 ;text part
	sta regA
	sta wsync		
	lda >titlefnt		
	sta chbase
			
.rept 6,#
	sta wsync
	mva #$60+:1*2 colbak
.endr	
	sta wsync
	mva #$00 colbak

	mva #$0f color1
	mva #$00 color2
	
	DLINEW dli10 1 0 0
	
dli10	sta regA
	sta wsync	
	mva #$0c color1
	DLINEW dli11 1 0 0 

dli11	sta regA
	sta wsync	
	mva #$0f color1
	DLINEW dli12 1 0 0 

dli12	sta regA
	sta wsync	
	mva #$0a color1
	DLINEW dli13 1 0 0 

	
dli13	sta regA
	sta wsync
	mva #$08 color1
	DLINEW dli14 1 0 0 

dli14	
	sta regA
.rept 6,#
	sta wsync
	mva #$60+12-:1*2 colbak
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

quit
	lda regA
	ldx regX
	ldy regY
	rti

.endp

; ---
	;run main
; ---

	opt l-

.MACRO	SPRITES
missiles
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02
	.he 00 02 02 00 02 00 02 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player0
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 40 00 01 0A 20
	.he 80 18 20 08 30 00 18 28 10 38 00 18 20 18 08 30
	.he 08 10 30 08 30 08 00 00 00 40 10 04 01 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player1
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 02 00 04 00 08 08 08 00 10 10 20 58 00 00
	.he 00 80 20 00 00 01 0E F0 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player2
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 80 40 00 00 00 20 00 00 00 00 00 20 70 20 50
	.he 20 00 00 00 30 C0 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player3
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 20 70 70
	.he 70 20 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
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

