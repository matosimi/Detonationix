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
xpos	equ $ab ;x position of tile
ypos	equ $ac ;y position of tile


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
	
	mva #4 draw_tile.type
	mva #2 draw_tile.rotation
	mva #10 xpos
	sta ypos
	draw_tile
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

.proc	draw_tile
	ldx type
	lda dsizes,x
	tay
	dey
	
	txa
	asl @
	tax
	lda tiles,x
	sta w1
	lda tiles+1,x
	sta w1+1
	
x1	mva (w1),y current,y
	dey
	bpl x1
	
	;lda bomb
	;todo
	
	ldx type
	lda rotation
	jeq drawIt
	x_lt #4 rot3
	cpx #4
	jeq rot2
	rotate4
	jmp drawIt
rot2	rotate2
	jmp drawIt
rot3	rotate3	

drawIt	
	ldx type
	x_lt #4 drw3
	cpx #4 
	jeq drw2
	draw4
	jmp x0
drw2	draw2
	jmp x0
drw3	draw3
	;jmp x0
		
x0	rts

.proc	draw4
	lda ypos
	asl @
	tax
	mwa lines,x save.ptr1
	add16 xpos save.ptr1
	mva #4 ptr2
	
	ldy #0
	ldx #0
x1	lda current,y
	save
	iny
	inx
	cpx #4
ptr2	equ *-1
	bne x1
	add16 #32-4 save.ptr1
	cpy #4*4
	beq x0	;done
	
	lda ptr2
	add #4	;next line
	sta ptr2
	jmp x1
	
x0	rts

.endp

.proc	draw3
	lda ypos
	asl @
	tax
	mwa lines,x save.ptr1
	add16 xpos save.ptr1
	mva #3 ptr2
	
	ldy #0
	ldx #0
x1	lda current,y
	save
	iny
	inx
	cpx #3
ptr2	equ *-1
	bne x1
	add16 #32-3 save.ptr1
	cpy #3*3
	beq x0	;done
	
	lda ptr2
	add #3	;next line
	sta ptr2
	jmp x1
	
x0	rts

.endp
	
.proc	draw2
	lda ypos
	asl @
	tax
	mwa lines,x save.ptr1
	add16 xpos save.ptr1
	
	lda current
	ldx #0
	save
	lda current+1
	inx
	save
	lda current+2
	ldx #32
	save
	lda current+3
	inx
	save
	rts
.endp
	
.proc	save
	sta $ffff,x
ptr1	equ *-2
	rts
.endp

	
.proc	rotate2
	ldx rotation
x1	mva current tmp
	mva current+1 current
	mva current+2 current+1
	mva current+3 current+2
	mva tmp current+3
	dex
	bne x1
	rts
tmp 	dta 0
.endp

.proc	rotate3
	ldx rotation
; 012
; 345
; 678	
	;diagonals
x1	mva current tmp
	mva current+2 current
	mva current+8 current+2
	mva current+6 current+8
	mva tmp current+6
	
	;orthogonals
	mva current+1 tmp
	mva current+5 current+1
	mva current+7 current+5
	mva current+3 current+7
	mva tmp current+3 
	
	;4 is not moving at all
	dex
	bne x1
	
	rts
tmp	dta 0
.endp

.proc	rotate4
; 0123
; 4567
; 89ab
; cdef
	mva rotation rot_local

x3	ldx #15
x1	mva current,x tmp,x
	dex
	bpl x1
	
	ldx #15
x2	lda matches,x
	tay
	mva tmp,y current,x
	dex
	bpl x2
	
	dec rot_local
	bne x3
	
	rts
matches	dta 3,7,$b,$f
	dta 2,6,$a,$e
	dta 1,5,9,$d
	dta 0,4,8,$c
tmp
:16	dta 0
rot_local	dta 0
.endp

	
tiles	dta a(tile0,tile1,tile2,tile3,tile4,tile5)
sizes	dta 3,3,3,3,2,4
dsizes	dta 9,9,9,9,4,16
type	dta 1
rotation	dta 0
current	
:16	dta ' '

.endp

lines
:25	dta a(vram+32*:1)

gamedli	rti

gamevbi	php
	mva >gamefont chbase
	plp
	rti	
	
playfield
:24	dta 'p          p'
	dta 'rqqqqqqqqqqs'		

;3x3
tile0	dta '   '
	dta ' tt'
	dta 'tt '
	
tile1	dta '   '
	dta 'tt '
	dta ' tt'
	
tile2	dta '   '
	dta 'ttt'
	dta ' t '
	
tile3	dta ' t '
	dta ' t '
	dta ' tt'

;2x2	
tile4	dta 'tt'
	dta 'tt'

;4x4	
tile5	dta '  t '
	dta '  t '
	dta '  t '
	dta '  t '
	
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
