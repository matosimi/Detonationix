;DETONATIONIX 25-26.8.2020 - Abbuc 2020

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

mypmbase	equ $4c00
vram	equ $1000
vram2	equ $1400
code	equ $2000
msx	equ $9000
player	equ $a400

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
ctype	equ $ad ;current tile type
crotation	equ $ae ;current tile rotation
stick	equ $af ;porta cut to 1 player
ztmp	equ $b0 ;zero page temp
speed	equ $b1 ;controls speed 
speed_anc	equ $b2 ;speed anchor
gravtick	equ $b3 ;gravity speed (level)
cbomb	equ $b4 ;current bomb
bstor	equ $b5 ;bomb index storage

C_FULLBOMB	equ $ff
C_NOBOMB		equ $f0
C_BRICK		equ 't'*
C_EMPTY		equ ' '*
C_BOMB		equ 'u'
C_DETONATION	equ 'v'

debug_no_music	equ 0

	org code
.local	init
	mwa #idl $230
	mva #$26 $2c4
	mva #$b8 $2c5
	mva #$52 $2c6
	mva #$00 $2c8
	
	pause 1
	
	mva #$ff portb ;turn on osrom a load next block
	
	;detect video system
	mva #0 ntsc
	sta ntsctimer
	ldx 20
	inx
	inx
x1	lda vcount
	a_lt ntsc x2
	sta ntsc
x2	cpx 20
	bne x1
	lda ntsc
	a_lt #140 sys_ntsc
	mva #1 ntsc
	rts
sys_ntsc	mva #0 ntsc
	
	rts
idl	dta $70,$70,$70,$48,a(gr3)
:23	dta 8
	dta $70
	dta $42,a(text)
tptr	equ *-2
	dta $41,a(idl)
.endl
;240 B
gr3	ins "dtnx.gr3",0,240
text	dta "       ABBUC Software Contest 2020      "
game
	ini code ;init

;quickhack
	org mypmbase
:38	dta $ff
:218-33	dta $f0
:9	dta $ff
:33-9	dta $00

;:256	dta $00
:38	dta $ff
:218-33	dta $00
:9	dta $ff
:33-9	dta $00

:38+10	dta $ff
:9*8-1	dta $f0
:1	dta $ff
:11*8-1	dta $f0
:24	dta $ff
:24+1	dta $00

:38+10	dta $ff
:9*8-1	dta $0f
:1	dta $ff
:11*8-1	dta $0f
:24	dta $ff
:24+1	dta $00

	org game
	info
	
	game_init
	rmt.init
	draw_background
	draw_playfield
	draw_stats
	next_tile
	next_tile
	
:4	mva #64+32*:1 hposp0+:1
:4	mva #$18 colpm0+:1
:4	mva #3 sizep0+:1
	/*mva #4 draw_tile.type
	mva #2 draw_tile.rotation
	mva #10 xpos
	sta ypos
	draw_tile
	jmp **/
	
	;game loop

	mva #10 speed
	mva 20 gravity.grav_anc	;starting counter for gravity
	mva #40 gravtick
	;init new tile
	
	mva #4+4 xpos
	mva #2 ypos
	;mva ctype draw_tile.type
loop	
	;mva crotation draw_tile.rotation
	;draw_tile
	
	lda 20
	add speed
	sta speed_anc
	mva #1 controls.handled
cloop	controls
	gravity
	
	lda speed_anc
	cmp 20
	beq loop
	add #10
	cmp 20
	bne cloop
	
	jmp loop

.proc	info
	mwa #text2 init.tptr
	ldx #5
x1	pause 200
	add16 #40 init.tptr
	dex
	bpl x1
	
	rts
text2	dta " Created by Martin Simecek 25-26.8.2020 "
text3	dta "    This is just preview version!       "
text4	dta " Sorry, this time I was not able to     "
text5	dta "       finish the game in time.         "
text6	dta "           Enjoy anyway...              "
text7	dta "      http://matosimi.atari.org         "	
.endp

.proc	place_tile
	draw_tile
	check_lines
	lda check_lines.count
	beq x1
	detonate_bombs
	
x1	next_tile
	mva #4+4 xpos
	mva #2 ypos
	mva ctype draw_tile.type
	mva crotation draw_tile.rotation
	mva cbomb draw_tile.bomb
	mva #0 controls.handled
	rts
.endp
	
.proc	check_lines
	mva #0 count
	sta bomb_buffer_index
	
	ldx #23*2
x2	mwa lines,x w1
	ldy #5
x1	lda (w1),y
	cmp #C_EMPTY
	beq nextline
x3	iny
	cpy #16
	bne x1
	inc count
	addbombs	
nextline	dex
	dex
	cpx #4
	bne x2
	rts
count	dta 0	
.endp	

.proc	addbombs
	stx ztmp
	
x2	lda (w1),y
	cmp #C_BOMB
	beq x1
x3	dey
	cpy #4
	bne x2
	
	ldx ztmp
	rts

x1	add_bomb_to_buffer
	jmp x3	
	
.endp

.proc	add_bomb_to_buffer
	ldx bomb_buffer_index
	tya
	add w1
	sta bomb_buffer,x
	lda #0
	adc w1+1
	sta bomb_buffer+1,x
	inc bomb_buffer_index
	inc bomb_buffer_index
	rts
.endp

bomb_buffer
:128	dta 0
bomb_buffer_index
	dta 0
	
.proc	detonate_bombs
	ldy bomb_buffer_index
	jeq x0	;nothing to detonate
	
	sty bstor
	
	ldx check_lines.count ;size of detonation
	dex
	mva xbt,x xblast
	mva ybt,x yblast
	mva wbt,x wblast
	mva ylines,x ylinesup
	mva hbt,x hblast
	
	mva #C_DETONATION draw_detonation.ptr1
	
x1	ldy bomb_buffer_index
	jeq x00
	dey
	dey
	sty bomb_buffer_index
	mwa bomb_buffer,y w1
	sub16 xblast w1	;left edge
	sub16 ylinesup w1	;top-left edge
	
	draw_detonation
	
	jmp x1
x0	rts
x00	pause 50
	ldy bstor
	beq x0
	mva #0 bstor
	sty bomb_buffer_index
	mva #C_EMPTY draw_detonation.ptr1
	jmp x1

ybt	dta 0,1,2,3
xbt	dta 3,4,5,6
ylines	dta 0,32,64,96
wbt	dta 6,6,6,6 ;8,10,11	;width of the blast
hbt	dta 1,3,5,7	;height of the blast
xblast	dta 0
yblast	dta 0
wblast	dta 0
hblast	dta 0
ylinesup	dta 0
.endp

.proc	draw_detonation
	ldx detonate_bombs.hblast
x2	ldy detonate_bombs.wblast
x1	lda (w1),y
	cmp #C_EMPTY
	beq x3
	cmp #C_BRICK
	beq x3
	cmp #C_BOMB
	beq x3
	cmp #C_DETONATION
	beq x3
	jmp x4 ;do not draw blast outside playfield
x3	lda #C_DETONATION
ptr1	equ *-1
	sta (w1),y
x4	dey
	bpl x1
	add16 #32 w1
	dex
	bne x2
	rts
.endp
	
.proc	gravity
	lda 20
	cmp grav_anc
	bne x0
	
	add gravtick
	sta grav_anc	;set next gravity occurence
	
	delete_tile
	inc ypos
	validate_tile
	jeq ok
	dec ypos
	place_tile
	rts
ok	draw_tile
x0	rts
grav_anc	dta 0
.endp	
	
.proc	controls
	lda handled
	beq x0
	
	lda porta
	lsr @
	jcc up
	lsr @
	jcc down
	lsr @
	jcc left
	lsr @
	jcc right
x0	rts
	
up	delete_tile
	inc crotation
	mva crotation draw_tile.rotation
	validate_tile
	jeq ok
	lda crotation
	add #3
	and #$03
	sta crotation
	sta draw_tile.rotation
	rts
	
down	delete_tile
	inc ypos
	validate_tile
	jeq ok
	dec ypos	;revert
	rts
	
left	delete_tile
	dec xpos
	validate_tile
	jeq ok
	inc xpos	;revert
	rts
	
right	delete_tile
	inc xpos
	validate_tile
	jeq ok
	dec xpos
	rts

ok	draw_tile
	mva #0 handled
	rts
	
handled	dta 0

.endp	
	
.proc	next_tile
	draw_stats
	
	mva type ctype
	mva rotation crotation
	mva bomb cbomb
x1	lda random
	and #%00000111
	a_ge #6 x1
	sta type
	sta draw_tile.type
	lda random
	and #$03
	sta rotation
	sta draw_tile.rotation
	
	add_bomb
		
	mva #22 xpos
	mva #6 ypos
	draw_tile
	rts
type	dta 0
rotation	dta 0
bomb	dta 0
.endp
	
.proc	add_bomb
	lda random
	and #$07
	beq fullbomb
	and #$01
	beq nobomb
	;add single bomb
	ldx next_tile.type
	lda draw_tile.dsizes,x
	sta size
	txa
	asl @
	tax
	mwa draw_tile.tiles,x w1 
	
x1	lda random
	and #%00001111	;biggest size
	a_ge size x1
	tay
	lda (w1),y
	cmp #C_BRICK
	bne x1	;if empty find another brick	
	sty next_tile.bomb
	sty draw_tile.bomb
	rts
	
size	dta 0
	
nobomb	mva #C_NOBOMB draw_tile.bomb
	sta next_tile.bomb
	rts
fullbomb	mva #C_FULLBOMB draw_tile.bomb
	sta next_tile.bomb
	rts
.endp
	
.proc	draw_background
	ldx #0
x1	
:4	mva data+$100*:1+32*4,x vram+$100*:1,x

	inx
	bne x1
	rts
data	ins 'bg2_narr/bg2_narrow.scr'
.endp
	
.proc	draw_stats
	mwa #stats w1
	mwa #vram+32*3+20 w2
	ldx #19
x2	ldy #7
x1	mva (w1),y (w2),y
	dey
	bpl x1
	
	add16 #8 w1
	add16 #32 w2
	
	dex
	bpl x2
	rts
	
stats	dta 'yqqqqqqz'
	dta d'p NEXT p'
:6	dta 'p      p'
	dta 'rqqqqqqs'
	dta 'yqqqqqqz'
	dta d'pSCORE p'
:2	dta 'p      p'
	dta d'pSTAGE p'
:2	dta 'p      p'
	dta d'pGRAND p'
	dta d'pSCORE p'
	dta 'p      p'
	dta 'rqqqqqqs'
.endp
	
.proc	draw_playfield
	
	mwa #playfield+24 w1
	mwa #vram+32*2+4 w2
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

.proc	delete_tile
	inc draw_tile.save.delete
	draw_tile
	dec draw_tile.save.delete
	rts
.endp

.proc	validate_tile
	inc draw_tile.save.validate
	mva #0 draw_tile.save.valid	;reset validation result
	draw_tile
	dec draw_tile.save.validate
	lda draw_tile.save.valid
	rts
.endp

.proc	draw_tile
	ldx type
	lda dsizes,x
	tay
	dey
	sty size
	
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
	
	lda bomb
	cmp #C_NOBOMB
	beq x2
	cmp #C_FULLBOMB
	beq x3
	;single bomb
	tay
	mva #C_BOMB current,y
	jmp x2
x3	;full bomb
	ldy size
x31	lda current,y
	cmp #C_BRICK
	beq x4
	dey
	bpl x31
	jmp x2	
x4	mva #C_BOMB current,y
	dey
	bpl x31
	
	;end of bomb injection
x2	ldx type
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
	cmp #' '*
	beq x0	;draw only those that are not empty
	sta ztmp
	lda delete
	beq x1
	;delete branch
	lda #' '*
	jmp x2
x1	lda validate
	beq x3
	;validate branch
	mwa ptr1 ptr2
	lda $ffff,x
ptr2	equ *-2
	cmp #' '*
	bne x4 ;invalid
	rts
	
x3	lda ztmp
x2	sta $ffff,x
ptr1	equ *-2
x0	rts
x4	inc valid
	rts
	
delete	dta 0	;1 = delete tile
validate	dta 0	;1 = validate tile
valid	dta 0	;>0 - invalid
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
bomb	dta C_NOBOMB
size	dta 0
current	
:16	dta ' '

.endp

lines
:25	dta a(vram+32*:1)

gamedli	phr
	ldx vcount
.rept 8	
	sta wsync
	lda pcolors,x 
:4	sta colpm0+:1
	inx
.endr
	plr
	rti

gamevbi	phr
	inc 20
	mva >gamefont chbase
	mva #$ec colpf0
	mva #$e4 colpf0+1
	mva #$38 colpf0+2
	mva #$76 colpf0+3
	mva #$00 colpf0+4
:4	sta colpm0+:1

	ift debug_no_music == 0
	rmt.play
	eif

	ldx #7
x1	lda random
	ora #%01010101
	sta gamefont+C_DETONATION*8,x
	dex
	bpl x1
	
	plr
	rti	
	
playfield
:24	dta 'p          p'*
	dta 'rqqqqqqqqqqs'		

;3x3
tile0	dta '   '*
	dta ' tt'*
	dta 'tt '*
	
tile1	dta '   '*
	dta 'tt '*
	dta ' tt'*
	
tile2	dta '   '*
	dta 'ttt'*
	dta ' t '*
	
tile3	dta ' t '*
	dta ' t '*
	dta ' tt'*

;2x2	
tile4	dta 'tt'*
	dta 'tt'*

;4x4	
tile5	dta '  t '*
	dta '  t '*
	dta '  t '*
	dta '  t '*
	
.proc 	game_init
	sei	
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
	mva #4 prior
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
gamedl	dta $70,$70+$80
	dta $44+$80,a(vram)
:25	dta 4+$80
	dta $41,a(gamedl)
	

	org msx
	opt h-
	ins 'dtnx_9000.rmt'
	opt h+
	
.local	rmt
	org player
	icl 'rmtplayr.a65'
	
;play same independently on the video system (PAL/NTSC)
.proc	play
	lda ntsc
	bne vbpal
	inc ntsctimer
	lda ntsctimer
	cmp #6
	bne vbpal
	mva #255 ntsctimer
	jmp vbntsc
	
vbpal	jsr rmt.rmt_play 
vbntsc	rts
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
pcolors	
;:32	dta 0
C_LUM	equ $8
.rept 14,#
	dta :1*$10+C_LUM
	dta [:1+1]*$10+C_LUM
	dta :1*$10+C_LUM
:6	dta [:1+1]*$10+C_LUM

.endr

	run game
