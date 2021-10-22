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

vramtop		equ $0f00	;contains 2 top lines of vram
vram		equ $1000
vram2		equ $1400

;flood fill buffers
w1lbuf		equ $1800
w1hbuf		equ $1900
xbuf		equ $1a00
ybuf		equ $1b00
bomb_buffer	equ $1c00	;L0200
blast_size_buffer	equ $1e00	;L0200
code		equ $2000
mypmbase		equ $7c00
msx		equ $9000
player		equ $a400

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
;ctype	equ $ad ;current tile type
crotation	equ $ae ;current tile rotation
stick	equ $af ;porta cut to 1 player
ztmp	equ $b0 ;zero page temp
speed	equ $b1 ;controls speed 
speed_anc	equ $b2 ;speed anchor
gravtick	equ $b3 ;gravity speed (level)
;cbomb	equ $b4 ;current bomb
;bstor	equ $b5 ;bomb index storage
tag	equ $b6 ;used for floodfill
tagcount	equ $b7 ;number of tagged
tagcount2	equ $b8 ;number of tagged in single direction
fftmp	equ $b9 ;floodfill temp
gover	equ $ba ;1=game is over
gcounter	equ $bb ;gravity counter (vbi)
ccounter	equ $bc ;controls counter (vbi)
leveldone	equ $bd ;0 if level is done
gwin	equ $be ;1=player is the winner
fftmp_seg	equ $bf ;floodfill temp for segments

C_CHARBRICK	equ 't'*
C_CHAREMPTY	equ " "
C_CHARBOMB	equ 'u'
C_CHARDETONATION	equ $4b
C_CHARGROUNDED	equ $ff
C_CHARFULLLINE	equ $f6
C_CHARFULLLINEBMB	equ $77
C_CHARBOMBMARK	equ $78	;bomb marked to detonate
C_LINES		equ 23		;zero based (24 together)
C_TOP_LINE	equ 5		;top-left corner of playfield
C_BOTTOM_LINE	equ C_LINES*32+5	;bottom-left corner of playfield

debug_no_music	equ 1
debug_skip_title	equ 1
debug_vram_flicker	equ 0
debug_gravity	equ 0
debug_tiledemo	equ 0

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
	
	convert_tiles
	
	draw_playfield
	draw_stats
	
	reset_stage
	reset_score
	reset_gscore
	
	next_tile
;	next_tile
	
	reset_score
	
	mva #0 gover
	sta gwin
	sta gcounter
	sta ccounter
	
	mva #16 next_tile.fullbomb_counter

	mva #5 speed	;controls responsiveness
	sta leveldone
	mva #40 gravtick	;gravity speed
	;init new tile
	
	mva #4+4 xpos
	mva #0 ypos 
	;mva ctype tile.type
	;mva cbomb next_tile.bomb
	ift debug_tiledemo==1
	tiledemo
	eif
	
	
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
	draw_current_tile
linesloop
	count_full_lines
	lda bomb_buffer_index2
	beq x1
	animate_full_lines
	copy_bomb_buffer
	detonate_bombs
	segmentation
gravloop
	ift debug_gravity == 1
	wait_for_start
	eif
	pause 1
	sticky_gravity
	cmp #0 ;nothing felt
	bne gravloop
	check_level_done
	jmp linesloop
	

	
x1	next_tile
@	mva #4+4 xpos
	mva #0 ypos
	;mva ctype tile.type
	;mva cbomb next_tile.bomb
	mva #0 controls.handled
	validate_tile
	jeq ok
	mva #1 gover ;game over
ok	draw_current_tile
	rts
.endp
	
.proc	count_full_lines
	mva #0 count
	sta bomb_buffer_index2
	
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
	ldy count
	dey
	txa
	sta flbuffer,y	;store which line is full to buffer	
nextline	dex
	dex
	cpx #4
	bne x2
	rts
count	dta 0
flbuffer		;buffer of lines indexes
:C_LINES	dta 0
.endp

.proc	animate_full_lines
	mva #$ff first_full_line
	mva #0 counter
	lda count_full_lines.count
	beq x0
	tay
	dey
	copy_vram
x1	lda count_full_lines.flbuffer,y
	tax
	mwa lines,x w1
	sty tmpy
	
	;fill full line with the fullline chars
	ldy #16
x2	lda (w1),y
	cmp #C_CHARBRICK
	bne @+
	mva #C_CHARFULLLINE (w1),y
@	cmp #C_CHARBOMBMARK
	bne @+
	mva #C_CHARFULLLINEBMB (w1),y
@	dey
	cpy #5
	bpl x2
	inc counter
	lda first_full_line
	bmi @+
	ldy #9
	mva #C_CHARFULLLINE (w2),y	;remove old number
	
@	mwa lines,x w2
	inc first_full_line
	lda counter
	ora #$90	;make it number
	ldy #9
	sta (w2),y	;write number of full lines on top line to the left

	pause 5

	ldy tmpy
	dey
	bpl x1
	
	pause 30
	copy_vram2
x0	rts

tmpy		dta 0
first_full_line	dta 0
counter		dta 0

.endp

;adds bombs in the current line to bomb buffer
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

x1	mva #C_CHARBOMBMARK (w1),y	;mark bomb that is detonating
	add_bomb_to_buffer
	jmp x3	
	
.endp

.proc	add_bomb_to_buffer
	ldx bomb_buffer_index2
	tya
	add w1
	sta bomb_buffer+$100,x
	lda #0	;TODO: use $80 for mega bomb
	adc w1+1
	sta bomb_buffer+$100+1,x
	mva #1 blast_size_buffer+$100,x	;set initial blast width to 1
	sta blast_size_buffer+$100+1,x	;set initial blast height to 1
	inc bomb_buffer_index2
	inc bomb_buffer_index2
	rts
.endp

;copies buffer1 -> buffer2 and resets buffer1
.proc	copy_bomb_buffer
	ldx #0
@	mva bomb_buffer+$100,x bomb_buffer,x
	mva blast_size_buffer+$100,x blast_size_buffer,x
	inx
	bne @-
	mva bomb_buffer_index2 bomb_buffer_index
	mva #0 bomb_buffer_index2
	rts
.endp

bomb_buffer_index	dta 0
bomb_buffer_index2	dta 0
	
.proc	detonate_bombs
;Todo: bomb explosion propagation
;clear should be executed after each bombbuffer is blown
;important: do not extend bombbuffer with new bombs, rather store it elsewhere
;and detonate after clear
	ldy bomb_buffer_index
	jeq x0	;nothing to detonate
	ldx count_full_lines.count ;size of detonation
	dex
	mva blast_width,x wblast 
	mva blast_height,x hblast
loop3	copy_vram
	/*
	mva xbt,x xblast
	mva ybt,x yblast
	mva wbt,x wblast
	mva ylines,x ylinesup
	mva hbt,x hblast
	
	mva #C_CHARDETONATION draw_detonation.ptr1
	*/
	
loop2	mva #0 change	;reset change
	mva bomb_buffer_index bomb_buffer_iterator
	pause 0
loop	ldy bomb_buffer_iterator
	jeq x00
	dey
	dey
	sty bomb_buffer_iterator
	mwa bomb_buffer,y w1
	
	lda blast_size_buffer,y
	a_ge wblast loop	;width is dominant so if blast width == wblast
			;then it is final for this one
	;grow blast width
	add #2
	sta blast_size_buffer,y
	inc change
			
@	lda blast_size_buffer+1,y
	a_ge hblast @+
	;grow blast height
	add #2
	sta blast_size_buffer+1,y
	inc change

@	lda blast_size_buffer,y
	tax
	lda blast_size_buffer+1,y
	tay

	/*
	ldy #0
	mva #C_CHAREMPTY (w1),y ;unmark detonating bomb (to not add it again during blast propagation)
	;trigger_push_release ;debug
	sub16 xblast w1	;left edge
	sub16 ylinesup w1	;top-left edge
	
	draw_detonation
	*/
	;ldx wblast
	;ldy hblast
	draw_blast
	jmp loop
x0	rts

x00	pause 1
	lda change
	jne loop2
	pause 10
	/*ldy bstor	;bomb_buffer_top_index
	beq x0
	mva #0 bstor
	sty bomb_buffer_index
	mva #C_CHAREMPTY draw_detonation.ptr1
	jmp x1 */
	
	;clean up detonations
	ldx #21	;vram lines
	mwa #vram w1
	mwa #vram2 w2
	pause 0
;copy whole 2 top lines
	ldy #31+32+5
@	mva (w2),y (w1),y
	dey
	bpl @-
	
	add16 #64+5 w1
	add16 #64+5 w2
	
clear_loop
	ldy #31
@	mva (w2),y (w1),y
	dey
	cpy #9
	bne @-
	
@	lda (w1),y
	cmp #C_CHARBOMB
	beq @+
	cmp #C_CHARBRICK
	beq @+
	mva #C_CHAREMPTY (w1),y
@	dey
	bpl @-1
	add16 #32 w1
	add16 #32 w2
	dex
	bpl clear_loop
	
	;copy whole 2 bottom lines
	ldy #31+32-5
@	mva (w2),y (w1),y
	dey
	bpl @-

	pause 10
	
	copy_bomb_buffer
	lda bomb_buffer_index
	jne loop3
	
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

change	dta 0	;>1 some change to blast has been made
bomb_buffer_iterator	dta 0

blast_width
	dta 7,7,7,7,8,11,11,13,13
:10	dta 15

blast_height
	dta 1,3,5,7,9,11,11,13,13
:10	dta 15
;TODO: megabomb
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

;draws rectangular blast and adds blast-reached bombs to bomb buffer
;w1=contains center, x,y=width,height
.proc	draw_blast
	stx width
	txa
	lsr @
	sta subx 
	sub16 subx w1 ;subtract half of the width -> set left edge
	cpy #1
	jeq flat_blast
;rectangular blast
	dey
	tya
	lsr @
	sta suby
	;draw middle line
	ldx #$4a
	jsr set_blast_line_type
	jsr draw_blast_line	
	mwa w1 w1tmp
	mva #1 repeat

@	sub16 #32 w1	;line up
	lda w1+1
	a_lt >vram x00	;clip to beginning of vram
	lda repeat
	cmp suby
	beq x1
	jsr draw_blast_line ;inside line
	inc repeat
	jmp @-

	;draw top line
x1	ldx #$47	
	jsr set_blast_line_type
	jsr draw_blast_line
	
	;top part of blast is drawn, now to the bottom
	
x00	ldx #$4a	;set middle line type again
	jsr set_blast_line_type
	mwa w1tmp w1
	mva #1 repeat
	
@	add16 #32 w1	;line down
	lda w1+1
	a_ge >vram2 x0	;clip to end of vram
	lda repeat
	cmp suby
	beq x2
	jsr draw_blast_line ;inside line
	inc repeat
	jmp @-
	
	;draw bottom line
x2	ldx #$4d	
	jsr set_blast_line_type
	jsr draw_blast_line
x0	rts

flat_blast
	ldx #$40
	jsr set_blast_line_type
	
draw_blast_line	
	ldy width
	dey
	lda (w1),y
	cmp #C_CHARBOMB
	bne @+
	add_bomb_to_buffer
@	lda #$42 ;right piece
ptr3	equ *-1
	sta (w1),y 
	
	dey
@	lda (w1),y
	cmp #C_CHARBOMB
	bne @+
	add_bomb_to_buffer
@	lda #$41 ;middle piece
ptr2	equ *-1
	sta (w1),y

	dey
	bne @-1
	
	lda (w1),y
	cmp #C_CHARBOMB
	bne @+
	add_bomb_to_buffer
@	lda #$40 ;left piece
ptr1	equ *-1
	sta (w1),y 
	rts
	
subx	dta 0
suby	dta 0
width	dta 0
w1tmp	dta 0,0
repeat	dta 0

set_blast_line_type
	stx ptr1
	inx
	stx ptr2
	inx
	stx ptr3
	rts
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
	count_if_more_than_10_blocks
	beq x0
	make_fullbomb
	rts
ok	draw_current_tile
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
	store_current
	delete_tile
:3	rotate_tile
	validate_tile
	jeq ok
	restore_current
	jmp err
	
up	store_current
	delete_tile
	rotate_tile
	validate_tile
	jeq ok
	restore_current
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
	draw_current_tile
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

ok	draw_current_tile
	mva #0 handled
	sta ccounter
	rts

err	draw_current_tile
	rts
	
handled	dta 0

.endp	
	
.proc	next_tile
	clear_next_window
	dec_score
	
	dec fullbomb_counter
	bpl x2
	
	ldx #8	;fullbomb every 8 tiles (stage 4->x)
	lda stage
	a_ge #4 @+
	ldx #16
@	stx fullbomb_counter
		
x2	;mva tile.type ctype
	;mva hflip chflip
	;mva bomb cbomb
x1	lda random
	and #$07
	;a_ge #8 x1
	sta tile.type
	lda random
	and #$08
	sta hflip
	sta prepare_tile.hflip
	
	prepare_tile
		
	mva #22 xpos
	mva #6 ypos
	draw_current_tile
	mva #0 gcounter
	rts

hflip	dta 0
bomb	dta 0
fullbomb_counter	dta 0
.endp

.proc	make_fullbomb
	ldx tile.type
	lda tile.dsizes,x
	tay
@	lda current,y
	cmp #C_CHARBRICK
	bne @+
	mva #C_CHARBOMB current,y	
@	dey
	bpl @-1
	rts
.endp

.proc	add_bomb_to_tile
	;add single bomb
	ldx tile.type
	lda tile.dsizes,x
	sta dsize
	
@	lda random
	and #%00001111	;biggest size
	a_ge dsize @-
	tay
	lda current,y
	cmp #C_CHARBRICK
	bne @-	;if empty find another brick	
	mva #C_CHARBOMB current,y
	rts
	
dsize	dta 0
.endp
	
.proc	draw_background
	ldx #0
x1	
:4	mva data+$100*:1+32*4,x vram+$100*:1,x

	inx
	bne x1
	
	;fill vramtop (covers top 2 lines of playfield)
	ldx #63
@	mva data+32*4,x vramtop,x
	dex
	bpl @-
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
	
	mwa #playfield w1
	mwa #vram+4 w2
	ldx #23
x2	ldy #11
x1	mva (w1),y (w2),y
	dey
	bpl x1
	add16 #32 w2
	
	dex
	bpl x2

	;bottom part
	add16 #12 w1
	ldy #11
@	mva (w1),y (w2),y
	dey
	bpl @-
	
	mva #1 load_stage.noanim
	load_stage
	mva #0 load_stage.noanim

	rts
.endp

.proc	delete_tile
	inc save.delete
	draw_current_tile
	dec save.delete
	rts
.endp

;try drawing, if possible it is valid
.proc	validate_tile
	inc save.validate
	mva #0 save.valid	;reset validation result
	draw_current_tile
	dec save.validate
	lda save.valid
	rts
.endp

.proc	store_current
	ldx #15
@	mva current,x store,x
	dex
	bpl @-
	rts
store	
:16	dta 0
.endp

.proc	restore_current
	ldx #15
@	mva store_current.store,x current,x
	dex
	bpl @-
	rts
.endp

;prepares tile into "current"
;containing hflip and bomb(s)
.proc	prepare_tile
	lda tile.type
	asl @
	tax
	lda tile.addresses,x
	sta w1
	lda tile.addresses+1,x
	sta w1+1
	
	ldx tile.type
	lda tile.dsizes,x
	tay
	dey
	sty dsize

	;copy tile teplate to current
@	lda (w1),y 
	sta current,y
	dey
	bpl @-
	
	lda next_tile.fullbomb_counter
	beq @+
	add_bomb_to_tile
@
	ldy dsize
x1	lda current,y 
	cmp #"X"	;replace with charbrick
	bne @+
	mva #C_CHARBRICK current,y
@	dey
	bpl x1
	
	lda next_tile.fullbomb_counter
	bne x2
	
	;full bomb
	ldy dsize
@	lda current,y
	cmp #C_CHARBRICK
	bne @+
	mva #C_CHARBOMB current,y	
@	dey
	bpl @-1

x2	lda hflip
	bne x0
	
	;horizontal flip
	lda dsize
	cmp #8 
	beq x4
	cmp #3
	beq x5
	ldy #15

;4x4 flip
	ldy #7
@	lda flipdata4,y
	tax
	mva current,x tmp
	stx tmpx
	lda flipdata4+8,y
	tax
	lda current,x
	sta tmp+1
	mva tmp current,x
	ldx tmpx
	mva tmp+1 current,x
	dey
	bpl @-		
x0	rts

;3x3 flip
x4	ldy #2
@	lda flipdata3,y
	tax
	mva current,x tmp
	stx tmpx
	lda flipdata3+3,y
	tax
	lda current,x
	sta tmp+1
	mva tmp current,x
	ldx tmpx
	mva tmp+1 current,x
	dey
	bpl @-
	rts
	
;2x2 flip
x5	mva current tmp
	mva current+1 current
	mva tmp current+1
		
	mva current+2 tmp
	mva current+3 current+2
	mva tmp current+3
	rts
	
tmp	dta 0,0
tmpx	dta 0
dsize	dta 0
hflip	dta 0
;0,1,2,3
;4,5,6,7
;8,9,a,b
;c,d,e,f
flipdata4 dta 0,4,8,$c,1,5,9,$d
	dta 3,7,$b,$f,2,6,$a,$e
	
;0,1,2
;3,4,5
;6,7,8
flipdata3	dta 0,3,6
	dta 2,5,8
.endp

.proc	rotate_tile
	ldx tile.type
	lda tile.sizes,x
	cmp #3
	beq rotate3
	cmp #2
	beq rotate2

rotate4
; 0123
; 4567
; 89ab
; cdef

	ldx #15
@	lda matches,x
	tay
	mva current,y robuff,x
	dex
	bpl @-
	
	ldx #15
@	mva robuff,x current,x
	dex
	bpl @-
	
	rts

matches	dta 3,7,$b,$f
	dta 2,6,$a,$e
	dta 1,5,9,$d
	dta 0,4,8,$c
robuff	
:16	dta 0
tmp	dta 0

; 01
; 23	
rotate2
	mva current tmp
	mva current+1 current
	mva current+3 current+1
	mva current+2 current+3
	mva tmp current+2
	rts

rotate3
; 012
; 345
; 678	
	;diagonals
	mva current tmp
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
	rts
.endp

;tile has to be prepared first!
.proc	draw_current_tile
	lda ypos
	asl @
	tax
	
	lda lines,x
	add xpos
	sta save.ptr1
	mva lines+1,x save.ptr1+1

	ldx tile.type
	lda tile.sizes,x
	cmp #3
	beq draw3
	cmp #2
	beq draw2
	
draw4
	ldy #15
@	lda dr4table,y
	tax
	lda current,y
	save
	dey
	bpl @-
	rts

dr4table	
:4	dta 0+:1*32, 1+:1*32, 2+:1*32, 3+:1*32

draw3
	
	ldy #8
@	lda dr3table,y
	tax
	lda current,y
	save
	dey
	bpl @-
	rts	

dr3table
:3	dta 0+:1*32, 1+:1*32, 2+:1*32
	
draw2
	lda current
	ldx #32
	save
	lda current+1
	inx
	save
	lda current+2
	ldx #64
	save
	lda current+3
	inx
	save
	rts
.endp

;saves (draws) single character to ptr1,x position
;does not change X,Y	
.proc	save
	cmp #C_CHAREMPTY
	beq x0	;draw only those that are not empty
	sta ztmp
	lda delete
	beq x1
	;delete branch
	lda #C_CHAREMPTY
	jmp x2
x1	lda validate
	beq x3
	;validate branch
	mwa ptr1 ptr2
	lda $ffff,x
ptr2	equ *-2
	cmp #C_CHAREMPTY
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

	

.local	tile
addresses
:8	dta a(tile:1)

sizes	dta 3,3,3,3,2,2,2,4
dsizes	dta 9,9,9,9,4,4,4,16
type	dta 1
.endl

current	
:16	dta " "

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

	;crappy blast char animation
/*	ldx #7
x1	lda random
	ora #%01010101
	sta gamefont+C_CHARDETONATION*8,x
	dex
	bpl x1
*/	
	plr
	rti	
	
playfield
	dta d'p',d'          ',d'p'*
	dta d'rqqqqqqqqqqs'		


;# = regular brick which can be bomb
;X = regular brick which cannot be bomb
;3x3
tile0	dta "   "
	dta " ##"
	dta "## "
	
tile1	dta "   "
	dta "#X#"
	dta " # "
	
tile2	dta "   "
	dta "#X#"
	dta "  #"

tile3	dta "   "
	dta "#X#"
	dta "   "
	
;2x2	
tile4	dta "##"
	dta "##"
	
tile5	dta "##"
	dta "# "
	
tile6	dta "  "
	dta "##"

;4x4	
tile7	dta "    "
	dta "#XX#"
	dta "    "
	dta "    "
		
	dta $ff
	
;switches # -> charbrick
.proc	convert_tiles
	ldx #0
x1	lda tile0,x
	cmp #$ff
	beq x0
	cmp #"#"
	bne @+
	lda #C_CHARBRICK
	sta tile0,x
@	inx
	bne x1
x0	rts
.endp
	
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
	dta a(vram),$84
	dta $44+$80
gdvrptr	dta a(vram+64)
:23	dta 4+$80
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

.proc	copy_vram
	ldx #0
@
:4	mva vram+:1*$100,x vram2+:1*$100,x
	inx
	bne @-
	rts
.endp

.proc	copy_vram2
	ldx #0
@
:4	mva vram2+:1*$100,x vram+:1*$100,x
	inx
	bne @-
	rts
.endp

;flood fill
.proc	segmentation
	copy_vram

	;starting point - running on vram copy (vram2)
	ldx #0
	mwa #vram2+C_TOP_LINE w1
	mva #"1" tag
	ldy #0
	;search for first filled byte
x2	ldy #9
x1	lda (w1),y
	;a_ge #C_CHARBRICK found
	cmp #C_CHARBRICK
	beq found
	cmp #C_CHARBOMB
	beq found
	dey
	bpl x1
	add16 #32 w1
	inx
	cpx #C_LINES+1
	bne x2
	
	;wait_for_start ;debug
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
	cpx #C_LINES+1
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

;return in Z-flag
.proc	count_if_more_than_10_blocks
	mwa #vram+C_BOTTOM_LINE w1
	ldx #0	;number of blocks in playfield
x6	ldy #9
	mva #0 empties
@	lda (w1),y
	cmp #C_CHAREMPTY
	beq x3
	inx
	x_ge #10 x1	;>= 10
	jmp x2
x3	inc empties
x2	dey
	bpl @-
	sub16 #32 w1
	lda empties
	cmp #10
	beq x4		;there is no more blocks above so finish
	jmp x6
	
x1	lda #0
	rts
x4	lda #$ff
	rts
	
empties	dta 0	;how many empty blocks are in the current line
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
	ground_touching_ground	
	
	;all segments touching bottom line are grounded = $ff
	;only falling segments remained, so move them down	
	mwa #vram2+C_BOTTOM_LINE-32 w2	;bottom line-1
	mwa #vram+C_BOTTOM_LINE-32 w1
	ldx #C_LINES-1	;lines
x5	ldy #9
x4	lda (w2),y
	cmp #C_CHAREMPTY
	beq x3
	cmp #C_CHARGROUNDED
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

;uses A,Y
.proc	ground_touching_ground
	mwa #vram2+C_BOTTOM_LINE-32 ptr1 ;1 above bottom line
	mva #20 lines
x2	ldy #9
x1	jsr load_vram2_y
	cmp #C_CHAREMPTY
	beq @+
	cmp #C_CHARGROUNDED
	beq @+
	sta current_segment
	sty ystore
	tya
	ora #32
	tay
	jsr load_vram2_y
	ldy ystore
	cmp #C_CHARGROUNDED
	bne @+
	
	lda current_segment	;ground current segment if it touches ground
	ground_current_segment
	;ldy ystore ;previous routine does not change Y
	
@	dey
	bpl x1
	sub16 #32 ptr1
	dec lines
	bpl x2
	rts

load_vram2_y
	lda vram2+C_BOTTOM_LINE-32,y
ptr1	equ *-2
	rts

lines	dta 0
ystore	dta 0
current_segment	dta 0
.endp

;uses A,Y
.proc	ground_bottom_line
	ldy #9
x1	lda vram2+C_BOTTOM_LINE,y
	cmp #C_CHAREMPTY
	beq @+
	cmp #C_CHARGROUNDED
	beq @+
	ground_current_segment
@	dey
	bpl x1
	rts
.endp

;uses A,X
.proc	ground_current_segment
	sta tag
	mva #20 lines
	mwa #vram2+C_BOTTOM_LINE ptr1
x2	ldx #9
x1	lda vram2+C_BOTTOM_LINE,x
ptr1	equ *-2
	cmp tag
	bne @+
	mwa ptr1 ptr2
	lda #C_CHARGROUNDED
	sta vram2+C_BOTTOM_LINE,x
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
	mwa #vram+C_TOP_LINE w1
	ldx #C_LINES
x2	ldy #9
	lda #C_CHARBRICK
character	equ *-1	
x1	sta (w1),y
	dey
	bpl x1
	
	pause 2
	
	add16 #32 w1
	dex
	bpl x2
	rts
.endp	

.proc	next_stage
	lda stageno
	cmp #14
	beq w	inner
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
	next_tile		;do not continue with tile from previous stage
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
	mwa #vram+C_TOP_LINE w1
	mwa stages,x w2
	
	ldx #2	;empty first two lines (above stage data)
@	ldy #9
	lda #C_CHAREMPTY
@	sta (w1),y
	dey
	bpl @-
	add16 #32 w1
	dex
	bne @-1
		
	ldx #22	;lines of stage data
x2	ldy #9
	
x1	lda (w2),y
	;beq x4	;mask #0 as #C_CHAREMPTY
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
	
;x4	lda #C_CHAREMPTY
;	jmp x5
	
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

;sets leveldone=0 if level is done (bottom line empty)
.proc	check_level_done
	ldx #9
x1	lda vram+C_BOTTOM_LINE,x
	cmp #C_CHAREMPTY
	bne x0
	dex
	bpl x1
	lda #0
x0	sta leveldone
	rts
.endp

stagedata
	ins 'stages\stagex.dat' ;debug
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


	ift debug_tiledemo==1
.proc	tiledemo
	mva #0 prepare_tile.hflip
x2	mva #7 tp
	
	lda #0
	ldx #0
@
:4	sta vram+:1*$100,x
	dex
	bne @-
	
x1	mva tp tile.type
	asl @
	asl @
	sta xpos
	mva #0 ypos
	
	prepare_tile
	;rotate_tile
	draw_current_tile
	dec tp
	bpl x1
	
	pause 25
	
	lda prepare_tile.hflip
	eor #$01
	sta prepare_tile.hflip
	jmp x2
	rts
tp	dta 0
.endp	
	eif


	run game
