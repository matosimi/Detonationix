;DETONATIONIX 25.8.2020 - Abbuc 2020

hposp0	equ $d000
hposm0	equ $d004
sizep0	equ $d008
sizem	equ $d00c
trig0	equ $d010
colpm0	equ $d012
colpf0	equ $d016
colbk	equ $d01a
prior	equ $d01b
vdelay	equ $d01c ;shift PM by 1 scanline, first missiles,then players(bits)
gractl	equ $d01d ;BIT1-ACTIV.PMG
consol	equ $d01f
random	equ $d20a
skctl	equ $d20f
porta	equ $d300 ;stick 0,1
portb	equ $d301
dmactl	equ $d400
dlistl	equ $d402
hscrol	equ $d404
pmbase	equ $d407
chbase	equ $d409
wsync	equ $d40a
vcount	equ $d40b
nmien	equ $d40e
nmist	equ $d40f

mypmbase	equ $0c00
vram	equ $1000
vram2	equ $1400
code	equ $2000
msx	equ $9000
player	equ $a100

;variables
vbi_ptr	equ $a0
dli_ptr	equ $a2
w1	equ $a4 ;2bytes
w2	equ $a6 ;2bytes
ntsc	equ $a8 ;0=pal,1=ntsc
ntsctimer	equ $a9 ;6th frame counter
level	equ $aa
dbgcount	equ $ab ;debug clicker counter


	org code
.local	init
	mwa #idl $230
	mva #$0e $2c4
	mva #$38 $2c5
	mva #$34 $2c6
	mva #$06 $2c8
	
	pause 5
	
	mva #$ff portb ;turn on osrom a load next block
	rts
idl	dta $70,$70,$70,$48,a(gr3)
:23	dta 8
	dta $70
	dta 2
	dta $41,a(idl)
.endl
;240 B
gr3	;ins "dtnx.gr3"
	dta "       ABBUC Software Contest 2020         "
game
	ini code ;init

	org game
	game_init
	draw_background
	draw_playfield
	jmp *
	
.proc	draw_background
	ldx #0
x1	
:4	mva data+$100*:1+32*4,x vram+$100*:1,x

	inx
	bne x1
	rts
data	ins 'bg2_narr/bg2_narrow.scr'
.endp
	
.proc	draw_playfield
	
	mwa #playfield+24 w1
	mwa #vram+32*2+3 w2
	ldx #22
x2	ldy #11
x1	mva (w1),y (w2),y
	dey
	bpl x1
	
	add16 #12 w1
	add16 #32 w2
	
	dex
	bpl x2
	rts
.endp

gamedli	rti

gamevbi	php
	mva >gamefont chbase
	plp
	rti	
	
playfield
:24	dta 'p          p'
	dta 'rqqqqqqqqqqs'		
	
.proc 	game_init	
	mva #0 nmien
	mva #$fe portb	;osrom off, basicrom off
	mwa #NMI $fffa		
	mwa #gamedl dlistl
	mwa #gamedli dli_ptr
	mwa #gamevbi vbi_ptr
	mva #$c0 nmien ;c0
	mva #32+1+12+16 dmactl
	mva #$03 gractl
	mva >mypmbase pmbase
	;mva #1 sizep0+1
	mva #8 consol
	rts
.endp
	
NMI	bit nmist
	bpl nmi_vbi	;vbi
	jmp (dli_ptr)	;dli
nmi_vbi	jmp (vbi_ptr)
	
	icl "matosimi_macros.asx"
	
	.align $400
gamefont	ins 'deto.fnt'
gamedl	dta $70,$70
	dta $44,a(vram)
:25	dta 4
	dta $41,a(gamedl)
	
/*
	org msx
	opt h-
	ins "msx.rmt"
	opt h+
	
.local	rmt
	STEREOMODE = 0 ;custom stereo mode
	org player
	icl 'rmtplayr.a65'
	
.proc	play
	lda ntsc
	beq x1
	lda ntsctimer
	cmp #255 ;skip 1 frame because of ntsc
	bne x1
	rts
	lda stop
	beq x1
	jsr rmt.RASTERMUSICTRACKER+9
	rts
x1	jsr rmt.RASTERMUSICTRACKER+3
	rts
.endp

.proc	init
	play_music
	mva #0 stop
	rts
.endp

.proc	play_music
	lda #0 ;songline				;starting song line 0-255 to A reg	
	ldx #<msx					;low byte of RMT module to X reg
	ldy #>msx					;hi byte of RMT module to Y reg
	jsr rmt.RASTERMUSICTRACKER
	rts
.endp

stop	dta 0	
.endl	
	
	
*/
	run game
