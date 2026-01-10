

	;test code

begin

	ld hl,music_data
	call play
	ret
	
	
	
;Squeeker Plus
;ZX Spectrum beeper engine by utz
;based on Squeeker by zilogat0r

BORDER equ #ff



;HL = add counter ch1
;DE = add counter ch2
;IX = add counter ch3
;IY = add counter ch4
;BC = basefreq ch1-4
;SP = buffer pointer

	
play

	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (mLoopVar),de
	ld (seqpntr),hl
	
	ei			;detect kempston
	halt
	in a,(#1f)
	inc a
	jr nz,_skip
	ld (maskKempston),a
_skip	
	di
	exx
	push hl			;preserve HL' for return to BASIC
	ld (oldSP),sp

;******************************************************************
rdseq
seqpntr equ $+1
	ld sp,0
	xor a
	pop de			;pattern pointer to DE
	or d
	ld (seqpntr),sp
	jr nz,rdptn0
	
	;jp exit		;uncomment to disable looping
	
mLoopVar=$+1
	ld sp,0		;get loop point
	jr rdseq+3

;******************************************************************
rdptn0
	;ld (ptnpntr),de
	ex de,hl
	ld sp,hl
	ld iy,0
rdptn
	in a,(#1f)		;read joystick
maskKempston equ $+1
	and #1f
	ld c,a
	in a,(#fe)		;read kbd
	cpl
	or c
	and #1f
	jp nz,exit


;ptnpntr equ $+1
;	ld sp,0	
	
	pop af
	jr z,rdseq
	
	ld i,a
	
	exx
	
	pop hl
	ld a,h
	ld (noise1),a
	ld a,l
	ld (noise2),a
	
	jr c,ld2
	pop hl
	ld (fch1),hl
	pop hl
	ld (envset1),hl
	ld a,(hl)
	ld (duty1),a
	exx
	ld hl,0
	exx
ld2	
	jp pe,ld3
	pop hl
	ld (fch2),hl
	pop hl
	ld (envset2),hl
	ld a,(hl)
	ld (duty2),a
	exx
	ld de,0
	exx
ld3
	jp m,ld4	
	pop hl
	ld (fch3),hl
	pop hl
	ld (envset3),hl
	ld a,(hl)
	ld (duty3),a
	ld ix,0
ld4	
	pop af
	jr z,ldx
	pop hl
	ld (fch4),hl		;freq 4
	ld iy,0
	ld de,0

	ld a,slideskip-jrcalc1
	jr nc,nokick
	ld a,d			;A=0
	ex de,hl
nokick
	ld (jrcalc),a
	pop hl
	ld (envset4),hl
	ld a,(hl)
	ld (duty4),a

ldx	
	jp pe,drum1
	jp m,drum2
	xor a
	ld c,a
drumret
	ex af,af'	
	

		
	;ld (ptnpntr),sp
	ld b,#80
	
	exx
	
;******************************************************************
playNote

fch1 equ $+1
	ld bc,0			;10
	add hl,bc		;11
noise1
	db #00,#04		;8	;replaced with cb 04 (rlc h) for noise
					; - 04 is inc b, which has no effect
duty1 equ $+1
	ld a,0			;7
	add a,h			;4
	exx			;4
	rl c			;8
	exx			;4
	
	ex de,hl		;4
fch2 equ $+1
	ld bc,0			;10
	add hl,bc		;11
noise2
	db #00,#04		;8
duty2 equ $+1
	ld a,0			;7
	add a,h			;4
	ex de,hl		;4
	exx			;4
	rl c			;8
	exx			;4

fch3 equ $+1
	ld bc,0			;10
	add ix,bc		;15
	
duty3 equ $+1
	ld a,0			;7
	add a,ixh		;8
	exx			;4
	rl c			;8
	exx			;4
				;176

fch4 equ $+1
	ld bc,0			;10
	add iy,bc		;15
duty4 equ $+1
	ld a,0			;7
	add a,iyh		;8
	
	exx			;4
	ld a,#f			;7
	adc a,c			;4
	ld c,0			;7
	exx			;4
	
	and BORDER		;7
	out (#fe),a		;11
	
	
	ex af,af'		;4
	dec a			;4
	jp z,updateTimer	;10
	ex af,af'		;4
	
	ex (sp),hl		;19
	ex (sp),hl		;19
	ex (sp),hl		;19
	ex (sp),hl		;19
	
	jp playNote		;10
				;368

;******************************************************************
updateTimer
	ex af,af'
	
	exx
	
envset1 equ $+1			;update duty envelope pointers
	ld hl,0
	inc hl
	ld a,(hl)
	cp b			;check for envelope end (b = #80)
	jr z,e2
	ld (duty1),a
	ld (envset1),hl
e2	
envset2 equ $+1
	ld hl,0
	inc hl
	ld a,(hl)
	cp b
	jr z,e3
	ld (duty2),a
	ld (envset2),hl
e3
envset3 equ $+1
	ld hl,0
	inc hl
	ld a,(hl)
	cp b
	jr z,e4
	ld (duty3),a
	ld (envset3),hl
e4	
envset4 equ $+1
	ld hl,0
	inc hl
	ld a,(hl)
	cp b
	jr z,eex
	ld (duty4),a
	ld (envset4),hl

eex
jrcalc equ $+1
	jr slideskip		;
jrcalc1
	ld hl,(fch4)		;update ch4 pitch
	srl d			;if pitch slide is enabled, de = freq.ch4
	rr e			;else, de = 0
	
	sbc hl,de		;thus, freq.ch4 = freq.ch4 - int(freq.ch4/2)
	ld (fch4),hl		;if pitch slide is enabled, else no change
 	
	ld iy,0			;reset add counter ch4 so it isn't accidentally

slideskip			;left in a 'high' state
	
	exx
	
	ld a,i
	dec a
	jp z,rdptn
	ld i,a
	jp playNote

;******************************************************************
exit
oldSP equ $+1
	ld sp,0
	pop hl
	exx
	ei
	ret
;******************************************************************
drum2
	ld hl,hat1
	ld b,hat1end-hat1
	jr drentry
drum1
	ld hl,kick1		;10
	ld b,kick1end-kick1	;7
drentry
	xor a			;4
_s2	
	xor BORDER		;7
	ld c,(hl)		;7
	inc hl			;6
_s1	
	out (#fe),a		;11
	dec c			;4
	jr nz,_s1		;12/7    
	
	djnz _s2		;13/8
	ld a,#6d		;7	;correct tempo
	jp drumret		;10
	
kick1					;27*16*4 + 27*32*4 + 27*64*4 + 27*128*4 + 27*256*4 = 53568, + 20*33 = 53568 -> -147,4 loops -> AF' = #6D
	ds 4,#10
	ds 4,#20
	ds 4,#40
	ds 4,#80
	ds 4,0
kick1end

hat1
	db 16,3,12,6,9,20,4,8,2,14,9,17,5,8,12,4,7,16,13,22,5,3,16,3,12,6,9,20,4,8,2,14,9,17,5,8,12,4,7,16,13,22,5,3
	db 12,8,1,24,6,7,4,9,18,12,8,3,11,7,5,8,3,17,9,15,22,6,5,8,11,13,4,8,12,9,2,4,7,8,12,6,7,4,19,22,1,9,6,27,4,3,11
	db 5,8,14,2,11,13,5,9,2,17,10,3,7,19,4,3,8,2,9,11,4,17,6,4,9,14,2,22,8,4,19,2,3,5,11,1,16,20,4,7
	db 8,9,4,12,2,8,14,3,7,7,13,9,15,1,8,4,17,3,22,4,8,11,4,21,9,6,12,4,3,8,7,17,5,9,2,11,17,4,9,3,2
	db 22,4,7,3,8,9,4,11,8,5,9,2,6,2,8,8,3,11,5,3,9,6,7,4,8
hat1end

env0
	db 0,#80

;compiled music data

music_data
	dw .loop
	dw .pattern1
.loop:
	dw .pattern2
	dw 0
.pattern1
	db #40
.pattern2
	dw #600,#0,#1be,env2,#e1,env4,#0,env1,#4,#0,env1
	dw #380,#0,#0,env2,#0,env4,#40
	dw #680,#0,#1be,env3,#e1,env5,#c0
	dw #380,#0,#0,env3,#0,env5,#40
	dw #685,#0,#44
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#80,#0,env10
	dw #385,#0,#c0
	dw #685,#0,#5,#1c2b,env10
	dw #385,#0,#0,#0,env10
	dw #685,#0,#c0
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#4,#0,env10
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#c0
	dw #685,#0,#44
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#4,#0,env10
	dw #385,#0,#40
	dw #685,#0,#81,#1c2b,env10
	dw #385,#0,#80,#0,env10
	dw #685,#0,#44
	dw #385,#0,#1,#217f,env10
	dw #685,#0,#80,#0,env10
	dw #385,#0,#40
	dw #685,#0,#5,#1c2b,env10
	dw #380,#0,#381,env7,#1c2,env1,#0,#0,env10
	dw #680,#0,#0,env7,#0,env1,#c0
	dw #380,#0,#381,env8,#1c2,env4,#c0
	dw #680,#0,#1be,env4,#e1,env4,#44
	dw #380,#0,#0,env4,#0,env4,#40
	dw #680,#0,#1be,env2,#e1,env1,#c0
	dw #380,#0,#0,env2,#0,env1,#40
	dw #685,#0,#44
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#80,#0,env10
	dw #385,#0,#c0
	dw #685,#0,#5,#1c2b,env10
	dw #385,#0,#0,#0,env10
	dw #685,#0,#c0
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#4,#0,env10
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#c0
	dw #685,#0,#44
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#4,#0,env10
	dw #385,#0,#40
	dw #685,#0,#81,#1c2b,env10
	dw #385,#0,#80,#0,env10
	dw #685,#0,#44
	dw #385,#0,#1,#217f,env10
	dw #685,#0,#80,#0,env10
	dw #385,#0,#40
	dw #685,#0,#5,#1c2b,env10
	dw #380,#0,#381,env3,#1c2,env1,#0,#0,env10
	dw #680,#0,#0,env3,#0,env1,#c0
	dw #380,#0,#381,env6,#1c2,env1,#c0
	dw #680,#0,#1be,env6,#e1,env4,#44
	dw #380,#0,#0,env6,#0,env4,#40
	dw #680,#0,#1be,env7,#e1,env5,#c0
	dw #380,#0,#0,env7,#0,env5,#40
	dw #685,#0,#44
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#80,#0,env10
	dw #385,#0,#c0
	dw #685,#0,#5,#1c2b,env10
	dw #385,#0,#0,#0,env10
	dw #685,#0,#c0
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#4,#0,env10
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#c0
	dw #685,#0,#44
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#4,#0,env10
	dw #385,#0,#40
	dw #685,#0,#81,#1c2b,env10
	dw #385,#0,#80,#0,env10
	dw #685,#0,#44
	dw #385,#0,#1,#217f,env10
	dw #685,#0,#80,#0,env10
	dw #385,#0,#40
	dw #685,#0,#5,#1c2b,env10
	dw #380,#0,#381,env8,#1c2,env1,#0,#0,env10
	dw #680,#0,#0,env8,#0,env1,#c0
	dw #380,#0,#381,env7,#1c2,env1,#c0
	dw #680,#0,#1be,env6,#e1,env4,#44
	dw #380,#0,#0,env6,#0,env4,#40
	dw #680,#0,#1be,env5,#e1,env3,#44
	dw #380,#0,#0,env5,#0,env3,#40
	dw #685,#0,#40
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#80,#0,env10
	dw #385,#0,#40
	dw #685,#0,#1,#1c2b,env10
	dw #385,#0,#0,#0,env10
	dw #685,#0,#c0
	dw #385,#0,#1,#1c2b,env10
	dw #601,#0,#706,env13,#70a,env13,#0,#0,env10
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #601,#0,#702,env12,#706,env12,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#1,#1c2b,env10
	dw #685,#0,#0,#0,env10
	dw #385,#0,#40
	dw #685,#0,#81,#1c2b,env10
	dw #385,#0,#0,#0,env10
	dw #685,#0,#40
	dw #385,#0,#1,#217f,env10
	dw #685,#0,#80,#0,env10
	dw #385,#0,#40
	dw #685,#0,#5,#1c2b,env10
	dw #380,#0,#381,env3,#1c2,env4,#4,#0,env10
	dw #680,#0,#0,env3,#0,env4,#44
	dw #380,#0,#381,env2,#1c2,env2,#44
	dw #600,#0,#1be,env2,#e1,env3,#0,env12,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#42f,env11,#c0
	dw #384,#0,#0,env4,#c0
	dw #600,#0,#1c2,env3,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env3,#385,env11,#42f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#385,env11,#42f,env11,#c0
	dw #301,#0,#0,env11,#0,env11,#81,#1c2b,env10
	dw #684,#0,#1c2,env2,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#42f,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#42f,env11,#c0
	dw #384,#0,#0,env4,#81,#1c2b,env10
	dw #600,#0,#1c2,env3,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env3,#385,env11,#42f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#385,env11,#42f,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#0,#1c2,env2,#dd,env3,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#42f,env11,#1,#3852,env10
	dw #384,#0,#381,env6,#80,#0,env10
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#46f,env11,#c0
	dw #384,#0,#0,env4,#c0
	dw #600,#0,#1c2,env3,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env3,#385,env11,#46f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#385,env11,#46f,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #604,#0,#1c2,env2,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#46f,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#46f,env11,#c0
	dw #384,#0,#0,env4,#81,#1c2b,env10
	dw #600,#0,#1c2,env3,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env3,#385,env11,#46f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#385,env11,#46f,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#0,#1c2,env2,#381,env5,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#379,env11,#46f,env11,#1,#3852,env10
	dw #380,#0,#381,env6,#dd,env11,#80,#0,env10
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#42f,env11,#c0
	dw #384,#0,#0,env4,#c0
	dw #600,#0,#1c2,env3,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env3,#385,env11,#42f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#385,env11,#42f,env11,#c0
	dw #301,#0,#0,env11,#0,env11,#81,#1c2b,env10
	dw #684,#0,#1c2,env2,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#42f,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#42f,env11,#c0
	dw #384,#0,#0,env4,#81,#1c2b,env10
	dw #600,#0,#1c2,env3,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env3,#385,env11,#42f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#385,env11,#42f,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#0,#1c2,env2,#dd,env3,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#42f,env11,#1,#3852,env10
	dw #384,#0,#381,env6,#80,#0,env10
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#46f,env11,#c0
	dw #384,#0,#0,env4,#c0
	dw #600,#0,#1c2,env3,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env3,#385,env11,#46f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#385,env11,#46f,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #604,#0,#1c2,env2,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#46f,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#46f,env11,#c0
	dw #384,#0,#0,env4,#81,#1c2b,env10
	dw #600,#0,#1c2,env3,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env3,#385,env11,#46f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#385,env11,#46f,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#0,#1c2,env2,#381,env5,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#379,env11,#46f,env11,#1,#3852,env10
	dw #380,#0,#381,env6,#dd,env11,#80,#0,env10
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#42f,env11,#c0
	dw #384,#0,#0,env4,#c0
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#385,env11,#42f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#385,env11,#42f,env11,#c0
	dw #301,#0,#0,env11,#0,env11,#81,#1c2b,env10
	dw #684,#cb00,#3856,env4,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#42f,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#42f,env11,#c0
	dw #384,#0,#0,env4,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#385,env11,#42f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#385,env11,#42f,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#dd,env3,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#42f,env11,#1,#3852,env10
	dw #384,#0,#381,env6,#80,#0,env10
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#46f,env11,#c0
	dw #384,#0,#0,env4,#c0
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#385,env11,#46f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#385,env11,#46f,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #604,#cb00,#3856,env4,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#46f,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#46f,env11,#c0
	dw #384,#0,#0,env4,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#385,env11,#46f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#385,env11,#46f,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#381,env5,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#379,env11,#46f,env11,#1,#3852,env10
	dw #380,#0,#381,env6,#dd,env11,#c0
	dw #600,#0,#e1,env2,#70a,env13,#706,env13,#5,#381,env10
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env13,#5,#381,env10
	dw #300,#0,#0,env4,#385,env11,#42f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#385,env11,#42f,env11,#c0
	dw #301,#0,#0,env11,#0,env11,#81,#1c2b,env10
	dw #684,#cb00,#3856,env4,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#385,env11,#42f,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #380,#0,#0,env2,#0,env3,#40
	dw #600,#0,#1c2,env4,#385,env11,#42f,env11,#c0
	dw #384,#0,#0,env4,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#385,env11,#42f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#385,env11,#42f,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#70a,env13,#706,env13,#5,#381,env10
	dw #384,#0,#0,env4,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #600,#0,#e1,env1,#1ba,env1,#381,env1,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env1,#385,env1,#70a,env1,#40
	dw #300,#0,#385,env1,#70a,env1,#e15,env1,#40
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env1,#5,#381,env10
	dw #300,#0,#0,env4,#385,env11,#46f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#385,env11,#46f,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e15,env12,#1c2,env1,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #684,#0,#1c2,env7,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env1,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env4,#385,env11,#46f,env11,#c0
	dw #380,#0,#385,env4,#e15,env11,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#385,env11,#46f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#cb00,#3856,env4,#e1,env3,#5,#381,env10
	dw #300,#0,#0,env4,#385,env11,#46f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #300,#0,#0,env3,#0,env11,#0,env11,#c0
	dw #680,#cb00,#3856,env4,#e1,env3,#5,#381,env10
	dw #380,#0,#0,env4,#0,env11,#c0
	dw #680,#cb00,#3856,env4,#e1,env3,#5,#381,env10
	dw #381,#cb00,#0,env11,#5,#381,env10
	dw #600,#0,#0,env4,#e1,env1,#1be,env1,#5,#381,env10
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #601,#0,#0,env1,#213,env1,#0,#10b,env1
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #305,#0,#233,env1,#0,#11b,env1
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #605,#0,#1be,env1,#0,#e1,env1
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #605,#0,#213,env1,#0,#10b,env1
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #305,#0,#233,env1,#0,#11b,env1
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #605,#0,#14d,env1,#0,#2a3,env1
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #605,#0,#117,env1,#0,#237,env1
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #600,#0,#e15,env12,#e11,env12,#1be,env1,#0,#e1,env1
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #680,#0,#e11,env11,#0,env12,#40
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#40
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#40
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#c0
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#40
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#40
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#40
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#c0
	dw #384,#0,#0,env11,#40
	dw #604,#0,#e11,env11,#213,env1,#0,#10b,env1
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #304,#0,#e11,env11,#233,env1,#0,#11b,env1
	dw #680,#0,#e15,env13,#e09,env13,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #684,#0,#e11,env11,#40
	dw #384,#0,#11ba,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#40
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#11ba,env11,#40
	dw #684,#0,#10bb,env11,#40
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#c0
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#40
	dw #384,#0,#11ba,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#40
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#11ba,env11,#40
	dw #684,#0,#10bb,env11,#40
	dw #384,#0,#e11,env11,#40
	dw #604,#0,#385,env4,#107,env1,#80,#217,env1
	dw #384,#0,#70a,env4,#40
	dw #684,#0,#e11,env11,#40
	dw #384,#0,#11ba,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#1c27,env11,#40
	dw #600,#0,#e15,env12,#706,env12,#1be,env1,#0,#e1,env1
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #684,#0,#e11,env11,#40
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#40
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#40
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#c0
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#40
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#40
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#40
	dw #384,#0,#e11,env11,#40
	dw #684,#0,#385,env2,#c0
	dw #384,#0,#70a,env2,#40
	dw #604,#0,#e11,env11,#213,env1,#0,#10b,env1
	dw #384,#0,#fca,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #304,#0,#e11,env11,#233,env1,#0,#11b,env1
	dw #680,#0,#e15,env13,#702,env13,#40
	dw #385,#0,#40
	dw #685,#0,#c0
	dw #385,#0,#40
	dw #684,#0,#e11,env11,#40
	dw #384,#0,#11ba,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#40
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#11ba,env11,#40
	dw #684,#0,#10bb,env11,#40
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#c0
	dw #384,#0,#0,env11,#40
	dw #604,#0,#e11,env11,#14d,env1,#0,#2a3,env1
	dw #384,#0,#11ba,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#40
	dw #384,#0,#0,env11,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#11ba,env11,#40
	dw #604,#0,#10bb,env11,#117,env1,#0,#237,env1
	dw #384,#0,#e11,env11,#40
	dw #685,#0,#c0
	dw #384,#0,#0,env11,#40
	dw #604,#0,#e11,env11,#107,env1,#0,#217,env1
	dw #384,#0,#11ba,env11,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#1c27,env11,#40
	dw #600,#cb,#e15,env12,#3856,env4,#1be,env1,#4,#e1,env1
	dw #381,#0,#0,env4,#40
	dw #681,#cb,#3856,env4,#44
	dw #381,#0,#0,env4,#40
	dw #680,#cb,#e11,env11,#3856,env4,#44
	dw #380,#0,#fca,env11,#0,env4,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #681,#cb,#3856,env4,#44
	dw #380,#0,#0,env11,#0,env4,#40
	dw #684,#0,#e11,env11,#c0
	dw #380,#cb,#fca,env11,#3856,env4,#44
	dw #680,#0,#10bb,env11,#0,env4,#40
	dw #380,#cb,#1c27,env11,#3856,env4,#40
	dw #680,#0,#385,env11,#0,env4,#44
	dw #384,#0,#70a,env11,#40
	dw #680,#cb,#e11,env11,#3856,env4,#44
	dw #380,#0,#fca,env11,#0,env4,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #681,#cb,#3856,env4,#44
	dw #380,#0,#0,env11,#0,env4,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#fca,env11,#40
	dw #680,#cb,#10bb,env11,#3856,env4,#44
	dw #380,#0,#1c27,env11,#0,env4,#40
	dw #684,#0,#70a,env11,#c0
	dw #380,#cb,#385,env11,#3856,env4,#44
	dw #600,#0,#e11,env11,#0,env4,#213,env1,#0,#10b,env1
	dw #380,#cb,#fca,env11,#3856,env4,#44
	dw #680,#0,#10bb,env11,#0,env4,#c0
	dw #300,#cb,#e11,env11,#3856,env4,#233,env1,#4,#11b,env1
	dw #684,#cb,#e15,env13,#44
	dw #381,#0,#0,env4,#40
	dw #681,#cb,#3856,env4,#44
	dw #381,#0,#0,env4,#40
	dw #680,#cb,#e11,env11,#3856,env4,#44
	dw #380,#0,#11ba,env11,#0,env4,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #681,#cb,#3856,env4,#44
	dw #380,#0,#0,env11,#0,env4,#40
	dw #684,#0,#e11,env11,#c0
	dw #380,#cb,#11ba,env11,#3856,env4,#44
	dw #680,#0,#10bb,env11,#0,env4,#40
	dw #380,#cb,#1c27,env11,#3856,env4,#40
	dw #680,#0,#385,env11,#0,env4,#44
	dw #384,#0,#70a,env11,#40
	dw #680,#cb,#e11,env11,#3856,env4,#44
	dw #380,#0,#11ba,env11,#0,env4,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #681,#cb,#3856,env4,#44
	dw #380,#0,#0,env11,#0,env4,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#11ba,env11,#40
	dw #600,#cb,#10bb,env11,#3856,env4,#107,env1,#4,#217,env1
	dw #380,#0,#e11,env11,#0,env4,#40
	dw #604,#0,#70a,env11,#213,env1,#80,#42f,env1
	dw #380,#cb,#385,env11,#3856,env4,#44
	dw #600,#0,#e11,env11,#0,env4,#ea,env1,#0,#1dd,env1
	dw #380,#cb,#11ba,env11,#3856,env4,#44
	dw #600,#0,#10bb,env11,#0,env4,#1d9,env1,#80,#3ba,env1
	dw #380,#cb,#e11,env11,#3856,env4,#44
	dw #604,#cb,#e15,env12,#1be,env1,#4,#e1,env1
	dw #381,#0,#0,env4,#40
	dw #681,#cb,#3856,env4,#44
	dw #381,#0,#0,env4,#40
	dw #680,#cb,#e11,env11,#3856,env4,#44
	dw #380,#0,#fca,env11,#0,env4,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #681,#cb,#3856,env4,#44
	dw #380,#0,#0,env11,#0,env4,#40
	dw #684,#0,#e11,env11,#c0
	dw #380,#cb,#fca,env11,#3856,env4,#44
	dw #680,#0,#10bb,env11,#0,env4,#40
	dw #380,#cb,#1c27,env11,#3856,env4,#40
	dw #680,#0,#385,env11,#0,env4,#44
	dw #384,#0,#70a,env11,#40
	dw #680,#cb,#e11,env11,#3856,env4,#44
	dw #380,#0,#fca,env11,#0,env4,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #681,#cb,#3856,env4,#44
	dw #380,#0,#0,env11,#0,env4,#40
	dw #684,#0,#e11,env11,#c0
	dw #384,#0,#fca,env11,#40
	dw #600,#cb,#10bb,env11,#3856,env4,#381,env1,#4,#1c2,env1
	dw #380,#0,#e11,env11,#0,env4,#40
	dw #604,#0,#70a,env11,#1be,env1,#80,#e1,env1
	dw #380,#cb,#385,env11,#3856,env4,#44
	dw #600,#0,#e11,env11,#0,env4,#213,env1,#0,#10b,env1
	dw #380,#cb,#fca,env11,#3856,env4,#44
	dw #600,#0,#10bb,env11,#0,env4,#42f,env1,#80,#217,env1
	dw #300,#cb,#e11,env11,#3856,env4,#233,env1,#4,#11b,env1
	dw #684,#cb,#e15,env13,#44
	dw #381,#0,#0,env4,#40
	dw #681,#cb,#3856,env4,#44
	dw #381,#0,#0,env4,#40
	dw #680,#cb,#e11,env11,#3856,env4,#44
	dw #380,#0,#11ba,env11,#0,env4,#40
	dw #684,#0,#10bb,env11,#c0
	dw #384,#0,#e11,env11,#40
	dw #681,#cb,#3856,env4,#44
	dw #380,#0,#0,env11,#0,env4,#40
	dw #684,#0,#e11,env11,#c0
	dw #380,#cb,#11ba,env11,#3856,env4,#44
	dw #680,#0,#10bb,env11,#0,env4,#40
	dw #380,#cb,#1c27,env11,#3856,env4,#40
	dw #680,#0,#e15,env11,#0,env4,#44
	dw #384,#0,#70a,env11,#40
	dw #680,#cb,#e11,env11,#3856,env4,#44
	dw #380,#0,#11ba,env11,#0,env4,#40
	dw #680,#cb,#10bb,env11,#3856,env4,#44
	dw #380,#0,#e11,env11,#0,env4,#40
	dw #680,#cb,#70a,env13,#3856,env4,#44
	dw #381,#0,#0,env4,#40
	dw #681,#cb,#3856,env4,#44
	dw #381,#0,#0,env4,#40
	dw #680,#cb,#3856,env13,#3856,env4,#44
	dw #384,#cb,#3baf,env13,#44
	dw #684,#cb,#3f3b,env13,#44
	dw #384,#cb,#42fe,env13,#44
	dw #684,#cb,#46fa,env13,#44
	dw #384,#cb,#4b33,env13,#44
	dw #684,#cb,#4fac,env13,#44
	dw #384,#cb,#5469,env13,#44
	dw #104,#0,#0,env13,#0,env1,#80,#0,env1
	dw #181,#0,#0,env4,#40
	dw #181,#0,#42fe,env4,#40
	dw #181,#0,#0,env4,#40
	dw #181,#0,#4b33,env4,#40
	dw #181,#0,#0,env4,#40
	dw #181,#0,#4b33,env4,#40
	dw #181,#0,#0,env4,#40
	dw #185,#0,#40
	dw #181,#0,#42fe,env4,#40
	dw #185,#0,#40
	dw #181,#0,#5469,env4,#40
	dw #181,#cb,#3856,env4,#40
	dw #181,#0,#5ebf,env4,#40
	dw #181,#cb,#4fac,env4,#40
	dw #181,#0,#596d,env4,#40
	dw #181,#cb,#4fac,env4,#40
	dw #181,#0,#0,env4,#40
	dw #181,#0,#3856,env4,#c0
	dw #181,#0,#0,env4,#40
	dw #185,#0,#40
	dw #181,#0,#3856,env4,#40
	dw #181,#0,#0,env4,#40
	dw #185,#0,#40
	dw #181,#0,#3856,env4,#40
	dw #181,#0,#0,env4,#40
	dw #185,#0,#40
	dw #181,#0,#3856,env4,#40
	dw #181,#0,#0,env4,#40
	dw #185,#0,#40
	dw #181,#0,#3856,env4,#40
	dw #181,#0,#0,env4,#40
	dw #185,#0,#40
	dw #181,#0,#3856,env4,#40
	dw #181,#0,#0,env4,#40
	dw #185,#0,#40
	dw #181,#0,#3856,env4,#c0
	dw #185,#0,#40
	dw #181,#0,#0,env4,#40
	dw #181,#cb,#42fe,env4,#40
	dw #185,#cb,#40
	dw #181,#0,#0,env4,#40
	dw #181,#0,#4b33,env4,#40
	dw #185,#0,#40
	dw #181,#0,#0,env4,#40
	dw #181,#cb,#596d,env4,#40
	dw #185,#cb,#40
	dw #181,#0,#0,env4,#40
	dw #181,#0,#5ebf,env4,#40
	dw #185,#0,#40
	dw #181,#0,#0,env4,#40
	dw #181,#0,#6a58,env4,#40
	dw #185,#0,#40
	dw #181,#0,#0,env4,#40
	dw #100,#cb,#966,env1,#4b33,env4,#4af,env1,#4,#255,env1
	dw #100,#0,#8df,env1,#46fa,env4,#46b,env1,#0,#233,env1
	dw #100,#cb,#85f,env1,#42fe,env4,#42b,env1,#0,#213,env1
	dw #100,#0,#7e7,env1,#3f3b,env4,#3ef,env1,#0,#1f5,env1
	dw #100,#cb,#775,env1,#3baf,env4,#3b6,env1,#0,#1d9,env1
	dw #100,#0,#70a,env1,#3856,env4,#381,env1,#0,#1be,env1
	dw #100,#cb,#6a5,env1,#352c,env4,#34e,env1,#0,#1a5,env1
	dw #100,#0,#646,env1,#3230,env4,#31f,env1,#0,#18d,env1
	dw #100,#cb,#5eb,env1,#2f5f,env4,#2f1,env1,#0,#176,env1
	dw #100,#0,#596,env1,#2cb6,env4,#2c7,env1,#4,#161,env1
	dw #100,#cb,#546,env1,#2a34,env4,#29f,env1,#0,#14d,env1
	dw #100,#0,#4fa,env1,#27d6,env4,#279,env1,#0,#13a,env1
	dw #100,#cb,#4b3,env1,#2599,env4,#255,env1,#0,#128,env1
	dw #100,#0,#46f,env1,#237d,env4,#233,env1,#0,#117,env1
	dw #100,#cb,#42f,env1,#217f,env4,#213,env1,#0,#107,env1
	dw #100,#0,#3f3,env1,#1f9d,env4,#1f5,env1,#4,#f8,env1
	dw #100,#cb,#3ba,env1,#1dd7,env4,#1d9,env1,#0,#ea,env1
	dw #100,#0,#385,env1,#1c2b,env4,#1be,env1,#0,#dd,env1
	dw #600,#0,#1be,env2,#e1,env3,#0,env1,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env4,#70a,env11,#85f,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#85f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#85f,env11,#c0
	dw #301,#0,#0,env11,#0,env11,#81,#1c2b,env10
	dw #684,#cb00,#3856,env4,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#85f,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#85f,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#85f,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#85f,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#dd,env3,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#85f,env11,#1,#3852,env10
	dw #384,#0,#381,env6,#80,#0,env10
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env4,#70a,env11,#8df,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#8df,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#8df,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #604,#cb00,#3856,env4,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#8df,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#8df,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#8df,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#8df,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#381,env5,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#6fe,env11,#8df,env11,#1,#3852,env10
	dw #380,#0,#381,env6,#dd,env11,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env4,#70a,env11,#966,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#966,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#966,env11,#c0
	dw #301,#0,#0,env11,#0,env11,#81,#1c2b,env10
	dw #684,#cb00,#3856,env4,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#966,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#966,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#966,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#966,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#dd,env3,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#966,env11,#1,#3852,env10
	dw #384,#0,#381,env6,#80,#0,env10
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env4,#70a,env11,#a8d,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#a8d,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #604,#cb00,#3856,env4,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#a8d,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#a8d,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#a8d,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#381,env5,#0,env11,#5,#381,env10
	dw #384,#0,#0,env4,#40
	dw #600,#0,#1c2,env2,#d5,env11,#a8d,env11,#80,#542,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env13,#1c27,env13,#5,#381,env10
	dw #385,#0,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env13,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#85f,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#85f,env11,#c0
	dw #301,#0,#0,env11,#0,env11,#81,#1c2b,env10
	dw #684,#cb00,#3856,env4,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#85f,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#85f,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e15,env12,#1c2,env1,#5,#381,env10
	dw #384,#0,#e1,env2,#c0
	dw #685,#0,#40
	dw #384,#0,#385,env2,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#85f,env11,#80,#0,env10
	dw #381,#0,#10bf,env11,#c0
	dw #600,#cb00,#3856,env4,#1be,env3,#e1,env2,#5,#381,env10
	dw #384,#0,#0,env4,#c0
	dw #601,#0,#70a,env3,#1c2,env2,#1,#3852,env10
	dw #385,#0,#80,#0,env10
	dw #600,#0,#1be,env2,#e1,env3,#0,env2,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#385,env4,#70a,env11,#8df,env11,#0,#a8d,env10
	dw #385,#0,#40
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#8df,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#8df,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#1ba,env1,#381,env1,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env4,#385,env1,#70a,env1,#40
	dw #300,#0,#385,env4,#70a,env1,#e15,env1,#40
	dw #600,#0,#1be,env2,#e1,env3,#0,env1,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#8df,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#8df,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#8df,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#381,env5,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#6fe,env11,#8df,env11,#1,#3852,env10
	dw #380,#0,#381,env6,#dd,env11,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#385,env13,#70a,env13,#966,env13,#80,#b29,env13
	dw #385,#0,#40
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env13,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#966,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env12,#966,env12,#80,#b2d,env12
	dw #385,#0,#44
	dw #100,#cb00,#3852,env4,#966,env1,#4af,env1,#5,#255,env1
	dw #101,#cb00,#8df,env1,#46b,env1,#0,#233,env1
	dw #101,#cb00,#85f,env1,#42b,env1,#0,#213,env1
	dw #101,#cb00,#7e7,env1,#3ef,env1,#0,#1f5,env1
	dw #101,#cb00,#775,env1,#3b6,env1,#0,#1d9,env1
	dw #101,#cb00,#70a,env1,#381,env1,#0,#1be,env1
	dw #100,#0,#0,env4,#6a5,env1,#34e,env1,#0,#1a5,env1
	dw #101,#0,#646,env1,#31f,env1,#0,#18d,env1
	dw #101,#0,#5eb,env1,#2f1,env1,#0,#176,env1
	dw #100,#cb00,#3856,env4,#596,env1,#2c7,env1,#4,#161,env1
	dw #101,#cb00,#546,env1,#29f,env1,#0,#14d,env1
	dw #101,#cb00,#4fa,env1,#279,env1,#0,#13a,env1
	dw #101,#cb00,#4b3,env1,#255,env1,#0,#128,env1
	dw #101,#cb00,#46f,env1,#233,env1,#0,#117,env1
	dw #101,#cb00,#42f,env1,#213,env1,#0,#107,env1
	dw #101,#cb00,#3f3,env1,#1f5,env1,#4,#f8,env1
	dw #101,#cb00,#3ba,env1,#1d9,env1,#0,#ea,env1
	dw #101,#cb00,#385,env1,#1be,env1,#0,#dd,env1
	dw #600,#0,#1be,env2,#e1,env3,#0,env1,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#966,env11,#80,#c8c,env10
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#966,env11,#0,#c8c,env10
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#966,env11,#80,#c8c,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#dd,env3,#1c2,env11,#5,#381,env10
	dw #385,#0,#0,#0,env10
	dw #600,#0,#c8c,env1,#966,env1,#e15,env1,#5,#dd,env10
	dw #385,#0,#40
	dw #600,#0,#e1,env1,#1ba,env1,#381,env1,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env1,#385,env1,#70a,env1,#0,#a8d,env10
	dw #300,#0,#385,env1,#70a,env1,#e15,env1,#0,#151a,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env1,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#a8d,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#a8d,env13,#70a,env13,#5,#381,env10
	dw #384,#0,#0,env4,#40
	dw #684,#0,#e1,env1,#0,#1be,env3
	dw #385,#0,#40
	dw #600,#0,#1be,env2,#e1,env3,#0,env13,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#a8d,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#a8d,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #100,#cb00,#3852,env4,#966,env1,#4af,env1,#5,#255,env1
	dw #101,#cb00,#8df,env1,#46b,env1,#0,#233,env1
	dw #101,#cb00,#85f,env1,#42b,env1,#0,#213,env1
	dw #101,#cb00,#7e7,env1,#3ef,env1,#0,#1f5,env1
	dw #101,#cb00,#775,env1,#3b6,env1,#0,#1d9,env1
	dw #101,#cb00,#70a,env1,#381,env1,#0,#1be,env1
	dw #100,#0,#0,env4,#6a5,env1,#34e,env1,#0,#1a5,env1
	dw #101,#0,#646,env1,#31f,env1,#0,#18d,env1
	dw #101,#0,#5eb,env1,#2f1,env1,#0,#176,env1
	dw #100,#cb00,#3856,env4,#596,env1,#2c7,env1,#4,#161,env1
	dw #101,#cb00,#546,env1,#29f,env1,#0,#14d,env1
	dw #101,#cb00,#4fa,env1,#279,env1,#0,#13a,env1
	dw #101,#cb00,#4b3,env1,#255,env1,#0,#128,env1
	dw #101,#cb00,#46f,env1,#233,env1,#0,#117,env1
	dw #101,#cb00,#42f,env1,#213,env1,#0,#107,env1
	dw #101,#cb00,#3f3,env1,#1f5,env1,#4,#f8,env1
	dw #101,#cb00,#3ba,env1,#1d9,env1,#0,#ea,env1
	dw #101,#cb00,#385,env1,#1be,env1,#0,#dd,env1
	dw #600,#0,#1be,env2,#e1,env3,#0,env1,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env4,#70a,env11,#a8d,env11,#c0
	dw #300,#0,#385,env4,#e15,env11,#151a,env11,#c0
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#a8d,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #604,#cb00,#3856,env4,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#a8d,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#a8d,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#1ba,env1,#381,env1,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env4,#385,env1,#70a,env1,#0,#a8d,env10
	dw #300,#0,#385,env4,#70a,env1,#e15,env1,#0,#151a,env10
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#a8d,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#381,env5,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#6fe,env11,#a8d,env11,#1,#3852,env10
	dw #380,#0,#381,env6,#dd,env11,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #385,#0,#40
	dw #600,#0,#1c2,env4,#70a,env11,#a8d,env11,#c0
	dw #300,#0,#385,env4,#e15,env11,#151a,env11,#c0
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#a8d,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #604,#cb00,#3856,env4,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#a8d,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#a8d,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #600,#0,#1be,env12,#e15,env13,#70a,env13,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#a8d,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#381,env5,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#6fe,env11,#a8d,env11,#1,#3852,env10
	dw #380,#0,#381,env6,#dd,env11,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #305,#0,#3856,env1,#40
	dw #605,#0,#5469,env1,#40
	dw #305,#0,#42fe,env1,#40
	dw #604,#cb00,#3856,env4,#0,env1,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#0,env11,#c0
	dw #680,#0,#1be,env12,#e1,env5,#5,#381,env10
	dw #385,#0,#40
	dw #601,#0,#70a,env11,#a8d,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #604,#cb00,#3856,env4,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#3baf,env3,#40
	dw #304,#0,#381,env6,#4b33,env3,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env3,#5,#381,env10
	dw #381,#0,#0,env3,#40
	dw #600,#0,#1c2,env4,#70a,env11,#a8d,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#5469,env11,#40
	dw #604,#0,#1c2,env3,#0,env11,#81,#1c2b,env10
	dw #301,#0,#0,env11,#5ebf,env1,#80,#0,env10
	dw #600,#0,#1be,env12,#e1,env5,#2a34,env1,#5,#381,env10
	dw #385,#0,#1,#217f,env10
	dw #601,#0,#70a,env11,#a8d,env11,#80,#0,env10
	dw #381,#0,#0,env11,#c0
	dw #600,#cb00,#3856,env4,#381,env13,#379,env13,#5,#381,env10
	dw #384,#0,#0,env8,#40
	dw #685,#0,#40
	dw #385,#0,#40
	dw #600,#0,#381,env2,#1c2,env3,#1be,env11,#5,#381,env10
	dw #385,#0,#40
	dw #684,#0,#d5,env2,#c0
	dw #300,#0,#702,env2,#70a,env3,#151a,env11,#c0
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#1,#1c2b,env10
	dw #684,#0,#1c2,env3,#80,#0,env10
	dw #301,#0,#0,env11,#2a34,env11,#c0
	dw #600,#0,#1be,env12,#e1,env5,#0,env11,#5,#381,env10
	dw #305,#0,#2a34,env11,#40
	dw #601,#0,#70a,env11,#a8d,env11,#c0
	dw #381,#0,#0,env11,#81,#1c2b,env10
	dw #604,#cb00,#3856,env4,#0,env11,#5,#381,env10
	dw #384,#0,#381,env8,#c0
	dw #600,#0,#1c2,env7,#70a,env11,#a8d,env11,#40
	dw #384,#0,#381,env6,#c0
	dw #600,#0,#1be,env2,#e1,env3,#0,env11,#5,#381,env10
	dw #381,#0,#0,env3,#1,#1c2b,env10
	dw #600,#0,#1c2,env4,#70a,env11,#a8d,env11,#c0
	dw #385,#0,#81,#1c2b,env10
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #680,#cb00,#3856,env4,#e1,env3,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#40
	dw #684,#0,#1c2,env3,#81,#1c2b,env10
	dw #301,#0,#0,env11,#0,env11,#80,#0,env10
	dw #680,#cb00,#3856,env4,#e1,env3,#5,#381,env10
	dw #300,#0,#0,env4,#70a,env11,#a8d,env11,#40
	dw #600,#cb00,#3856,env4,#e1,env3,#0,env11,#5,#381,env10
	dw #385,#cb00,#5,#381,env10
	dw #100,#0,#12c8,env1,#966,env1,#4af,env1,#4,#255,env1
	dw #100,#0,#11ba,env1,#8df,env1,#46b,env1,#0,#233,env1
	dw #100,#0,#10bb,env1,#85f,env1,#42b,env1,#0,#213,env1
	dw #100,#0,#fca,env1,#7e7,env1,#3ef,env1,#0,#1f5,env1
	dw #100,#0,#ee7,env1,#775,env1,#3b6,env1,#0,#1d9,env1
	dw #100,#0,#e11,env1,#70a,env1,#381,env1,#0,#1be,env1
	dw #100,#0,#d47,env1,#6a5,env1,#34e,env1,#0,#1a5,env1
	dw #100,#0,#c88,env1,#646,env1,#31f,env1,#0,#18d,env1
	dw #100,#0,#bd3,env1,#5eb,env1,#2f1,env1,#0,#176,env1
	dw #100,#0,#b29,env1,#596,env1,#2c7,env1,#0,#161,env1
	dw #100,#0,#a89,env1,#546,env1,#29f,env1,#0,#14d,env1
	dw #100,#0,#9f1,env1,#4fa,env1,#279,env1,#0,#13a,env1
	dw #100,#0,#962,env1,#4b3,env1,#255,env1,#0,#128,env1
	dw #100,#0,#8db,env1,#46f,env1,#233,env1,#0,#117,env1
	dw #100,#0,#85b,env1,#42f,env1,#213,env1,#0,#107,env1
	dw #100,#0,#7e3,env1,#3f3,env1,#1f5,env1,#0,#f8,env1
	dw #100,#0,#771,env1,#3ba,env1,#1d9,env1,#0,#ea,env1
	dw #100,#0,#706,env1,#385,env1,#1be,env1,#0,#dd,env1
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a00,#0,#0,env1,#0,env1,#0,env1,#0,#0,env1
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	dw #a85,#0,#40
	db #40
env1
	db #20,#80
env2
	db #1c,#80
env3
	db #18,#80
env4
	db #14,#80
env5
	db #10,#80
env6
	db #c,#80
env7
	db #8,#80
env8
	db #4,#80
env10
	db #3c,#3c,#3c,#2c,#2c,#2c,#24,#24,#24,#20,#20,#20,#1c,#1c,#1c,#18,#18,#18,#18,#18,#18,#14,#14,#14,#14,#14,#14,#10,#10,#10,#10,#10,#10,#10,#10,#10,#c,#c,#c,#c,#c,#c,#c,#c,#c,#c,#c,#c,#8,#8,#8,#8,#8,#8,#8,#8,#8,#8,#8,#8,#4,#4,#4,#4,#4,#4,#0,#0,#0,#3c,#3c,#3c,#80
env11
	db #28,#1c,#14,#8,#4,#4,#0,#80
env12
	db #3c,#34,#2c,#24,#1c,#14,#c,#4,#0,#3c,#34,#2c,#24,#1c,#14,#c,#4,#0,#80
env13
	db #3c,#30,#24,#18,#c,#0,#3c,#30,#24,#18,#c,#0,#3c,#30,#24,#18,#c,#0,#80
