;DETONATIONIX 25-26.8.2020 - Abbuc 2020
;additional fixes to 29.8.2020
;bomb buffer fix (128->256 size) 31.8.2020

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

mypmbase	equ $7c00
vram	equ $1000
vram2	equ $1400

;flood fill buffers
w1lbuf	equ $1800
w1hbuf	equ $1900
xbuf	equ $1a00
ybuf	equ $1b00

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
stageno	equ $aa ;current stage
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
tag	equ $b6 ;used for floodfill
tagcount	equ $b7 ;number of tagged
tagcount2	equ $b8 ;number of tagged in single direction
fftmp	equ $b9 ;floodfill temp
gover	equ $ba ;1=game is over
gcounter	equ $bb ;gravity counter (vbi)
ccounter	equ $bc ;controls counter (vbi)
leveldone	equ $bd ;0 if level is done
gwin	equ $be ;1=player is the winner
fftmp_seg	equ $ef ;floodfill temp for segments

C_FULLBOMB	equ $ff
C_NOBOMB		equ $f0

C_CHARBRICK	equ 't'*
C_CHAREMPTY	equ ' '*
C_CHARBOMB	equ 'u'
C_CHARDETONATION	equ 'v'
C_CHARGROUNDED	equ $ff

debug_no_music	equ 1
debug_skip_title	equ 1
debug_vram_flicker	equ 1

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
.local	game_cycle

title	info
	
	game_init
	rmt.init
	draw_background
	mva #0 stageno
	
	draw_playfield
	draw_stats
	
	reset_stage
	reset_score
	reset_gscore
	
	next_tile
	next_tile
	
	reset_score
	
	mva #0 gover
	sta gwin
	sta gcounter
	sta ccounter

	mva #5 speed	;controls responsiveness
	sta leveldone
	mva #40 gravtick	;gravity speed
	;init new tile
	
	mva #4+4 xpos
	mva #2 ypos 
	mva ctype draw_tile.type
	mva crotation draw_tile.rotation
	mva cbomb draw_tile.bomb
	
	;mva ctype draw_tile.type
loop	lda gover
	beq x1
	;game over sequence
	game_over
	trigger_push_release
	jmp title
x1	lda leveldone
	bne x2
	;next stage sequence
XXXX	next_stage
	inc leveldone
	lda gwin ;win
	bne title
	
x2	mva #1 controls.handled
cloop	controls
	gravity
	;debug:
	;lda consol
	;cmp #6
	;beq XXXX
	lda ccounter
	a_lt speed cloop
	
	mva #0 ccounter
	jmp loop
.endl

.proc	place_tile
	draw_tile
linesloop
	check_lines
	lda bomb_buffer_index
	beq x1
	detonate_bombs
	segmentation
gravloop
	wait_for_start
	pause 3
	sticky_gravity
	cmp #0 ;nothing felt
	bne gravloop
	check_level_done
	jmp linesloop
	

	
x1	next_tile
	mva #4+4 xpos
	mva #2 ypos
	mva ctype draw_tile.type
	mva crotation draw_tile.rotation
	mva cbomb draw_tile.bomb
	mva #0 controls.handled
	mva #100 gcounter	;instant gravity (draw)
	validate_tile
	jeq ok
	mva #1 gover ;game over
ok	rts
.endp
	
.proc	check_lines
	mva #0 count
	sta bomb_buffer_index
	
	ldx #23*2
x2	mwa lines,x w1
	ldy #5
x1	lda (w1),y
	cmp #C_CHAREMPTY
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
	cmp #C_CHARBOMB
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
:256	dta 0
bomb_buffer_index
	dta 0
	
.proc	detonate_bombs
;Todo: bomb explosion propagation
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
	
	mva #C_CHARDETONATION draw_detonation.ptr1
	
x1	ldy bomb_buffer_index
	jeq x00
	dey
	dey
	sty bomb_buffer_index
	mwa bomb_buffer,y w1
	
	ldy #0
	mva #C_CHAREMPTY (w1),y ;unmark detonating bomb (to not add it again during blast propagation)
	;trigger_push_release ;debug
	sub16 xblast w1	;left edge
	sub16 ylinesup w1	;top-left edge
	
	draw_detonation
	
	jmp x1
x0	rts
x00	pause 25
	/*ldy bstor	;bomb_buffer_top_index
	beq x0
	mva #0 bstor
	sty bomb_buffer_index
	mva #C_CHAREMPTY draw_detonation.ptr1
	jmp x1 */
	
	;clean up detonations
	mwa #vram+2*32+5 w1
	ldx #22
x22	ldy #9
x12	lda (w1),y
	cmp #C_CHARDETONATION
	bne x32
	mva #C_CHAREMPTY (w1),y
x32	dey
	bpl x12
	
	add16 #32 w1
	dex
	bne x22
	rts

ybt	dta 0,1,2,3
xbt	dta 3,4,5,6
ylines	dta 0,32,64,96
wbt	dta 6,8,10,12	;width of the blast
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
	cmp #C_CHAREMPTY
	beq x3
	cmp #C_CHARBRICK
	beq x3
	cmp #C_CHARBOMB
	beq x5 ;propagate blast
	cmp #C_CHARDETONATION
	beq x3
	jmp x4 ;do not draw blast outside playfield
x3	lda #C_CHARDETONATION
ptr1	equ *-1
	sta (w1),y
x4	dey
	bpl x1
	add16 #32 w1
	dex
	bne x2
	rts
	
x5	;add to bomb buffer
	mwa w1 w2
	stx xstor
	sty ystor
	;check_if_bomb_in_buffer_already
	;jne x6
	add_bomb_to_buffer
	;trigger_push_release ;debug
x6	mwa w2 w1
	ldx xstor
	ldy ystor
	jmp x3
xstor	dta 0
ystor	dta 0
.endp
	
.proc	gravity
	lda gcounter
	a_lt gravtick x0
	
	pause 0	;removes flicker
	delete_tile
	mva #0 gcounter	;reset gravity counter
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
	
	lda trig0
	beq rotate_back
	
	lda porta
	and #$0f
	cmp #$0f
	beq x0	
	ldx:cpx:req 20	;removes flicker
	lsr @
	jcc up
	lsr @
	jcc down
	lsr @
	jcc left
	lsr @
	jcc right
	
x0	rts

rotate_back
	delete_tile
	dec crotation
	lda crotation
	and #$03
	sta crotation
	mva crotation draw_tile.rotation
	validate_tile
	jeq ok
	inc crotation
	lda crotation
	and #$03
	sta crotation
	sta draw_tile.rotation
	jmp err
	
up	delete_tile
	inc crotation
	lda crotation
	and #$03
	sta crotation
	
	mva crotation draw_tile.rotation
	validate_tile
	jeq ok
	dec crotation
	lda crotation
	and #$03
	sta crotation
	sta draw_tile.rotation
	jmp err
	
down	delete_tile
	inc ypos
	validate_tile
	jeq dgrav
	dec ypos	;revert
	jmp err
dgrav	mva #0 gcounter	;reset gravity when forced move down
	ldx speed
	dex
	stx ccounter	;makes falling faster than other controls
	draw_tile
	mva #0 handled
	rts
	
left	delete_tile
	dec xpos
	validate_tile
	jeq ok
	inc xpos	;revert
	jmp err
	
right	delete_tile
	inc xpos
	validate_tile
	jeq ok
	dec xpos
	jmp err

ok	draw_tile
	mva #0 handled
	sta ccounter
	rts

err	draw_tile
	rts
	
handled	dta 0

.endp	
	
.proc	next_tile
	clear_next_window
	dec_score
	
	mva type ctype
	mva rotation crotation
	mva bomb cbomb
x1	lda random
	and #%00000111
	a_ge #7 x1
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
	cmp #C_CHARBRICK
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
;playfield background - vanishing tetris pieces
data	ins 'bg2_narr/bg2_narrow.scr'
.endp

.proc	clear_next_window
	ldx #3
	lda #C_CHAREMPTY
x1
:4	sta vram+32*(6+:1)+22,x
	dex
	bpl x1
	rts
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
	
stats	dta d'yqqqqqqz'*
	dta d'p NEXT p'*
:6	dta d'p      p'*
	dta d'rqqqqqqs'*
	dta d'yqqqqqqz'*
	dta d'pSCORE p'*
	dta d'p      p'*
	dta d'p      p'*
	dta d'pSTAGE p'*
	dta d'p      p'*
	dta d'p      p'*
	dta d'pGRAND p'*
	dta d'pSCORE p'*
	dta d'p      p'*
	dta d'rqqqqqqs'*
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

	mva #1 load_stage.noanim
	load_stage
	mva #0 load_stage.noanim

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
	mva #C_CHARBOMB current,y
	jmp x2
x3	;full bomb
	ldy size
x31	lda current,y
	cmp #C_CHARBRICK
	beq x4
	dey
	bpl x31
	jmp x2	
x4	mva #C_CHARBOMB current,y
	dey
	bpl x31
	
	;end of bomb injection
x2	ldx type
	lda rotation
	jeq drawIt
	x_lt #5 rot3
	cpx #5
	jeq rot2
	rotate4
	jmp drawIt
rot2	rotate2
	jmp drawIt
rot3	rotate3	

drawIt	
	ldx type
	x_lt #5 drw3
	cpx #5 
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

	
tiles	dta a(tile0,tile1,tile2,tile3,tile4,tile5,tile6)
sizes	dta 3,3,3,3,3,2,4
dsizes	dta 9,9,9,9,9,4,16
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
	;inc 20 - moved to rmt.play
	mva >gamefont chbase
	mva #$ec colpf0
	mva #$e4 colpf0+1
	mva #$38 colpf0+2
	mva #$76 colpf0+3
	mva #$00 colpf0+4
:4	sta colpm0+:1

	ift debug_no_music == 0
	rmt.play
	inc 20
	inc gcounter
	inc ccounter
	els
	inc 20
	inc gcounter
	inc ccounter
	eif
	
	
	ift debug_vram_flicker == 1
	switch_vram
	eif

	ldx #7
x1	lda random
	ora #%01010101
	sta gamefont+C_CHARDETONATION*8,x
	dex
	bpl x1
	
	plr
	rti	
	
playfield

:24	dta 'p          p'*
	dta 'rqqqqqqqqqqs'		


/* test
:10	dta 'p   u      p'*
	dta 'p  tutu    p'*
	dta 'p  t   t u p'*
	dta 'p  t t t u p'*
	dta 'p  t   u   p'*
:2	dta 'p   uu     p'*
:8	dta 'ptt       tp'*
	
	dta 'rqqqqqqqqqqs'
*/

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

tile4	dta ' t '*
	dta ' t '*
	dta 'tt '*
	
;2x2	
tile5	dta 'tt'*
	dta 'tt'*

;4x4	
tile6	dta '  t '*
	dta '  t '*
	dta '  t '*
	dta '  t '*
	
.proc 	game_init
	mva #0 nmien		
	mwa #gamedl dlistl
	mwa #gamedli dli_ptr
	mwa #gamevbi vbi_ptr
	mva #$c0 nmien ;c0
	mva #32+1+12+16 dmactl
	mva #$03 gractl
	mva >mypmbase pmbase
	mva #4 prior
	mva #8 consol
	
:4	mva #64+32*:1 hposp0+:1
:4	mva #$18 colpm0+:1
:4	mva #3 sizep0+:1
	rts
.endp
	
NMI	bit nmist
	bpl nmi_vbi	;vbi
	jmp (dli_ptr)	;dli
nmi_vbi	jmp (vbi_ptr)
	
	icl "matosimi_macros.asx"
	
	.align $400
gamefont	ins 'deto.fnt'
titlefont	ins 'title\detx_title.fnt'
gamedl	dta $70,$70+$80
	dta $44+$80
gdvrptr	dta a(vram)
:25	dta 4+$80
	dta $41,a(gamedl)
	
titledl	
:7	dta $70
	dta $42,a(titvram)
:7	dta 2
	dta $F0,$44,a(texts)
	dta $70,$70,4,$70,$70,4
	dta $41,a(titledl)

;wait for push and release of trigger
.proc	trigger_push_release
x1	lda trig0
	bne x1
x2	lda trig0
	beq x2
	rts
.endp

;title screen	
.proc	info
	pause 1
	sei	
	mva #0 nmien
	mva #$fe portb	;osrom off, basicrom off
	mwa #NMI $fffa
	mwa #titledli dli_ptr
	mwa #titlevbi vbi_ptr
	mwa #titledl dlistl
	mva #$c0 nmien
	mva #32+12+16+1 dmactl
	
	ift debug_skip_title == 0
	trigger_push_release
	eif
	
	rts

titlevbi	pha
	inc 20
	mva >titlefont chbase
	mva #$f2 colpf0+2
	mva #$0c colpf0+1
	jsr rmt.rmt_silence
	pla
	rti

titledli	pha
	sta wsync
	mva >gamefont chbase
	mva #$22 colpf0+1
	mva #$1c colpf0
	sta colpf0+2
	pla
	rti
.endp


titvram	ins 'title\detx_title.scr'

texts	dta "   CREATED BY MARTIN SIMECEK    "
	
	dta "   HTTP://MATOSIMI.ATARI.ORG    "	
	
	dta "  ABBUC SOFTWARE CONTEST 2020   "

score	equ vram+32*14+21 ;leftmost char
gscore 	equ vram+32*21+21 ;leftmost char
stage	equ vram+32*17+26 ;last char

.proc	reset_score
	mva #"9"* score+4
	sta score+5
	rts
.endp

.proc	reset_stage
	lda #"1"* 
	sta stage
	mva #0 stageno ;zero based stage number
	rts
.endp

.proc	reset_gscore
	lda #"0"* 
	sta gscore+5
	rts
.endp

.proc	inc_stage
	inc stageno	;number form
	inc stage		;char form
	lda stage
	a_ge #"9"*+1 x1
	rts
x1	mva #"0"* stage
	inc stage-1
	lda stage-1
	ora #$10
	sta stage-1 
	rts
.endp

.proc	dec_score
	ldx #5
x2	dec score,x
	lda score,x
	a_lt #"0"* x1
	rts
	
x1	dex
	lda score,x
	cmp #"0"*
	beq gameover
	mva #"9"* score+1,x
	dec gravtick ;speed up gravity
	dec gravtick
	dec gravtick
	jmp x2
	
gameover	mva #"0"* score+1,x
	mva #1 gover
	rts	
.endp

.proc	add_gscore
	ldx #5
x4	lda score,x
	cmp #" "*
	bne x5
	lda #0
x5	and #$0f
	add gscore,x
	and #$3f
	a_ge #$1a x1
	ora #$90
	sta gscore,x
	dex
x2	cpx #$ff
	bne x4
	
	;mask leading zeros
x6	inx
	lda gscore,x
	cmp #"0"*
	bne x0
	mva #" "* gscore,x
	jmp x6
	
x0	rts
	
x1	sub #10
	ora #$90
	sta gscore,x
	dex
	lda gscore,x
	cmp #" "*
	bne x3
	mva #"0"* gscore,x
x3	inc gscore,x
	jmp x2

.endp

.proc	switch_vram
	lda gdvrptr+1	;gamedl vram pointer - hi
	eor #$04
	sta gdvrptr+1
	rts
.endp

;flood fill
.proc	segmentation
	;copy vram
	ldx #0
x20	
:4	mva vram+:1*$100,x vram2+:1*$100,x
	inx
	bne x20

	;starting point - running on vram copy (vram2)
	ldx #0
	mwa #vram2+2*32+5 w1
	mva #"1" tag
	ldy #0
	;search for first filled byte
x2	ldy #9
x1	lda (w1),y
	a_ge #C_CHARBRICK found
	;cmp #C_CHAREMPTY
	;bne found
	dey
	bpl x1
	add16 #32 w1
	inx
	cpx #22
	bne x2
	
	;wait for start
	wait_for_start ;debug
	;done
	rts
	
found	stx last_y
	sty last_x
	mwa w1 w1_store
	mva #0 ffindex
	
	;begin tracing
	tag_it
	mva #0 tagcount
traceloop	
	;left
l2	dey
	bmi l1
	tag_it
	cmp tag
	beq l2
		
l1	iny
	;down
d2	add16 #32 w1
	inx
	cpx #22
	beq d1
	tag_it
	cmp tag
	beq d2
		
d1	sub16 #32 w1
	dex
	;right
r2	iny
	y_ge #10 r1
	tag_it
	cmp tag
	beq r2
r1	dey
	;up
u2	sub16 #32 w1
	dex
	bmi u1
	tag_it
	cmp tag
	beq u2	
u1	add16 #32 w1
	inx
	
	;go to previous direction change and continue
	dec ffindex
	lda ffindex
	cmp #$ff
	beq nextsegment
	
	ldx ffindex
	mva w1lbuf,x w1
	mva w1hbuf,x w1+1
	lda ybuf,x
	tay
	lda xbuf,x
	tax
	jmp traceloop
	
nextsegment
	inc tag
	mwa w1_store w1
	ldx last_y
	ldy last_x
	jmp x1

	
.proc	add_to_ffbuffer
	stx fftmp
	
	ldx ffindex
	mva w1 w1lbuf,x
	mva w1+1 w1hbuf,x
	mva fftmp xbuf,x
	tya
	sta ybuf,x
	inc ffindex
	
	ldx fftmp
	rts
.endp
	
;returns A=tag if tagged
.proc	tag_it
	lda (w1),y
	cmp #C_CHAREMPTY
	bne x1
	rts
	
x1	cmp tag
	bne x2
	lda #0
	rts
	
x2	mva tag (w1),y
	inc tagcount
	add_to_ffbuffer
	rts
.endp

last_x	dta 0
last_y	dta 0
w1_store	dta 0,0
/*
w1lbuf	
:256	dta 0
w1hbuf	
:256	dta 0
xbuf	
:256	dta 0
ybuf
:256	dta 0*/
ffindex	dta 0
.endp

.proc	wait_for_start
	lda #6
@	cmp consol
	bne @-
@	cmp consol
	beq @-
	rts
.endp

;moves down each segment that does not touch bottom line
;returns number of bricks that fell in A
.proc	sticky_gravity
	mva #0 ztmp ;counter of falling bricks
	/*
	mwa #vram2+(2+21)*32+5 w2	;bottom line
	ldy #9
x2	lda (w2),y
	cmp #C_CHAREMPTY
	beq x1
	delete_current_segment
x1	dey
	bpl x2*/
	ground_bottom_line
	todo: look for anything that touches grounded blocks and ground it
	
	
	
	;all segments touching bottom line are grounded = $ff
	;only falling segments remained, so move them down	
	mwa #vram2+(2+20)*32+5 w2	;bottom line-1
	mwa #vram+(2+20)*32+5 w1
	ldx #20	;lines
x5	ldy #9
x4	lda (w2),y
	cmp #C_CHAREMPTY
	beq x3
	mva (w1),y fftmp
	mva (w2),y fftmp_seg
	tya
	ora #32
	tay
	mva fftmp (w1),y
	mva fftmp_seg (w2),y
	tya
	and #$0f
	tay
	mva #C_CHAREMPTY (w1),y
	sta (w2),y
	inc ztmp
	
x3	dey
	bpl x4
	sub16 #32 w1
	sub16 #32 w2
	dex
	bpl x5
	lda ztmp	
	rts

.proc	delete_current_segment
	sta tag
	ldx #0
x2	
.rept 4,#
	lda vram2+:1*$100,x
	cmp tag
	bne x1:1
	mva #C_CHAREMPTY vram2+:1*$100,x	
x1:1	
.endr
	dex
	bne x2
	rts
.endp

.proc	ground_bottom_line
	ldy #9
x1	lda vram2+(2+21)*32+5,y
	cmp #C_CHAREMPTY
	beq @+
	cmp #C_CHARGROUNDED
	beq @+
	ground_current_segment
@	dey
	bpl x1
	rts
.endp

.proc	ground_current_segment
	sta tag
	mva #20 lines
	mwa #vram2+(2+21)*32+5 ptr1
x2	ldx #9
x1	lda vram2+(2+21)*32+5,x
ptr1	equ *-2
	cmp tag
	bne @+
	mwa #ptr1 ptr2
	lda #C_CHARGROUNDED
	sta vram2+(2+21)*32+5,x
ptr2	equ *-2
@	dex
	bpl x1
	sub16 #32 ptr1
	dec lines
	bpl x2
	rts
lines	dta 0
.endp
.endp

.proc	fill_playfield
	mwa #vram+2*32+5 w1
	ldx #22
x2	ldy #9
	lda #C_CHARBRICK
character	equ *-1	
x1	sta (w1),y
	dey
	bpl x1
	
	pause 2
	
	add16 #32 w1
	dex
	bne x2
	rts
.endp	

.proc	next_stage
	lda stageno
	cmp #14
	beq winner
	mva #":" fill_playfield.character
	fill_playfield
	inc_stage
	add_gscore
	reset_score
	;mva #C_CHAREMPTY fill_playfield.character
	;fill_playfield
	load_stage
	lda #40		;lowest game speed
	sub stageno	;sub stage number
	sta gravtick 	;speed up game every stage
	rts
winner
	mva #C_CHARDETONATION fill_playfield.character
	fill_playfield
	add_gscore
	reset_score
	
	mva #3 lines
	
	mwa #vram+11*32+6 w1
	ldx #7
x4	ldy #7
x3	mva text,x (w1),y
	dex
	dey
	bpl x3
	add16 #32 w1
	txa
	add #8+8
	tax
	dec lines
	bne x4
	
	mva #1 gwin
	trigger_push_release	
	rts
lines	dta 3	
text	dta d"        "
	dta d" WINNER "
	dta d"        "
.endp	

;load stage based on stageno
.proc	load_stage
	lda stageno
	asl @
	tax
	mwa #vram+2*32+5 w1
	mwa stages,x w2
	
	ldx #22
x2	ldy #9
	
x1	lda (w2),y
	beq x4	;mask #0 as #C_CHAREMPTY
x5	sta (w1),y
	dey
	bpl x1
	
	add16 #32 w1
	add16 #10 w2
	
	lda noanim	;do not animate if noanim set
	bne x3
	
	pause 2
	
x3	dex
	bne x2
	rts
	
x4	lda #C_CHAREMPTY
	jmp x5
	
noanim	dta 0
stages	
:15	dta a(stagedata+:1*220)
.endp
	
.proc	game_over
	mva #C_CHARBRICK fill_playfield.character
	fill_playfield
	
	mva #4 lines
	
	mwa #vram+11*32+7 w1
	ldx #5
x4	ldy #5
x3	mva text,x (w1),y
	dex
	dey
	bpl x3
	add16 #32 w1
	txa
	add #6+6
	tax
	dec lines
	bne x4
	
	rts
lines	dta 4	
text	dta d"      "
	dta d" GAME "
	dta d" OVER "
	dta d"      "
.endp

;sets leveldone=0 if level is done
.proc	check_level_done
	ldx #9
x1	lda vram+(2+21)*32+5,x
	cmp #C_CHAREMPTY
	bne x0
	dex
	bpl x1
	lda #0
x0	sta leveldone
	rts
.endp

stagedata
	ins 'stages\stagex.dat'
.rept 9,#+1
	ins 'stages\stage0:1.dat'
.endr
:6	ins 'stages\stage1:1.dat'

	guard $9000

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
