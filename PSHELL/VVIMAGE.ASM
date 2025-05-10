; "SSIMAGE.ASM" PC-9801UV11 make by R.H 1991/06/19
;
;	E X E L O A D     I M A G E    T E S T    c o m m a n d .
;
;
; command.

INCLUDE	TSTSET.INC

CALL_NM	MACRO	NUM,LBL
	LOCAL	L1
	CMP	DX,NUM
	JNE	L1
	PUSH	DX
	CALL	LBL
	POP	DX
L1:
	ENDM


CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,ES:DATA

PUBLIC	CMDIMAGE		; image test.

PUBLIC	VV_SETUP_EGA		; setup EGA mode.
PUBLIC	VV_SETUP_VGA		; setup VGA mode.
PUBLIC	VV_SETUP_RET		; video mode return.
PUBLIC	VV_PUT_MODE_SET		; put mode standerd.
PUBLIC	VV_PLEAN_SLCT		; plean select.

EXTRN	LODBET:NEAR		; ベタファイルロード
EXTRN	LODPLT:NEAR		; パレットファイルロード

EXTRN	PLSET:NEAR		; パレットセット
EXTRN	PLPSET:NEAR		; パレット編集セット

; *********************************************************
;	image test.
; *********************************************************

CMDIMAGE	PROC	NEAR
	PRF	"used VGA graphic adaptar."
CMDIMAGE_START:
	PRF	"1.beta file load (*.B1 *.R1 *.G1 *.E1 *.ALG) : "

CMDIMAGE_INP:
	INP	"[Q:EXIT]="
	CALL	STRDEC
	CMP	DX,0
	JE	CMDIMAGE_START

	CALL_NM	1,CMDBETA_LOAD		; beta file load.

	JMP	CMDIMAGE_INP

	RET
CMDIMAGE	ENDP


;	beta file load.

CMDBETA_LOAD	PROC	NEAR

	INP	"file:"
	SETS	FILENM,20		; file name.

	INP	"1:EGA,2:VGA :"
	CALL	STRDEC
	CMP	DX,1
	JE	CMDBETA_LOAD_EGA
	JMP	CMDBETA_LOAD_VGA
CMDBETA_LOAD_EGA:
	CALL	VV_SETUP_EGA		; setup EGA mode.
	JMP	CMDBETA_LOAD_BETA	;
CMDBETA_LOAD_VGA:
	CALL	VV_SETUP_VGA		; setup VGA mode.
	CALL	VV_PUT_MODE_SET		; put mode standerd.
	CALL	PAL_TO_REG_SET	; palet nunber to color registar set.
	MOV	SI,OFFSET FILENM	; file name.
	MOV	BX,0			; palet table number.
	CALL	LODPLT			; パレットファイルロード

	MOV	BX,0			; パレットテーブル番号
	CALL	PLSET			; パレットセット

CMDBETA_LOAD_BETA:
	MOV	SI,OFFSET FILENM	; file name.
	CALL	LODBET			; ベタファイルロード

	LC	0,25
	INP	" "

	CALL	VV_SETUP_RET		; video mode return.

	RET
CMDBETA_LOAD	ENDP


;	setup EGA mode.

VV_SETUP_EGA	PROC	NEAR
	CALL	V_MODE_SLCT_EGA		; video mode select EGA.
	RET
VV_SETUP_EGA	ENDP


;	setup VGA mode.

VV_SETUP_VGA	PROC	NEAR
	CALL	V_MODE_SLCT_VGA		; video mode select VGA.
	RET
VV_SETUP_VGA	ENDP


;	video mode return.

VV_SETUP_RET	PROC	NEAR
	CALL	V_MODE_RET		; video mode return.
	RET
VV_SETUP_RET	ENDP


;	video mode select EGA.

V_MODE_SLCT_EGA	PROC	NEAR
	MOV	AL,10H			; disply mode.
	MOV	AH,00H			; mode set.
	INT	10H			; graph bios.
	MOV	VMODE,10H		; video mode.
	RET
V_MODE_SLCT_EGA	ENDP


;	video mode select VGA.

V_MODE_SLCT_VGA	PROC	NEAR
	MOV	AL,12H			; disply mode.
	MOV	AH,00H			; mode set.
	INT	10H			; graph bios.
	MOV	VMODE,12H		; video mode.
	RET
V_MODE_SLCT_VGA	ENDP


;	video mode return.

V_MODE_RET	PROC	NEAR
	MOV	AL,02H			; disply mode.
	MOV	AH,00H			; mode set.
	INT	10H			; graph bios.
	MOV	VMODE,02H		; video mode.
	RET
V_MODE_RET	ENDP


;	put mode standerd.

VV_PUT_MODE_SET	PROC	NEAR

	MOV	AL,0			;
	MOV	BX,111B			; text attrbute.
	MOV	CX,1			; character length.
	MOV	AH,09H			; character & attrbute write.
	INT	10H			; IBM bios.

	JMP	$+2

	MOV	AX,0305H	; write mode 3.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0F00H	; set/reset.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0F01H	; enable set/reset.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0003H	; data rotate/funtion select.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0F07H	; color don't care.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0FF08H	; bit mask.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	RET
VV_PUT_MODE_SET	ENDP


;	palet nunber to color registar set.

PAL_TO_REG_SET	PROC	NEAR
	MOV	PLTNUM,0		; palet.
	MOV	CX,16			;
PAL_TO_REG_SET_LOOP:
	PUSH	CX

	MOV	BH,BYTE PTR PLTNUM	; palet code.
	MOV	BL,BYTE PTR PLTNUM	; palet registar number.
	MOV	AL,00H			; palet registar set.
	MOV	AH,10H			; palet set.
	INT	10H			; video bios.

	INC	PLTNUM			; palet.

	MOV	CX,20000
PAL_TO_REG_SET_LP2:
	JMP	$+2
	JMP	$+2
	JMP	$+2
	LOOP	PAL_TO_REG_SET_LP2

	POP	CX
	LOOP	PAL_TO_REG_SET_LOOP

	RET
PAL_TO_REG_SET	ENDP


;	plean select.
;	-I- DX : vram plean select.

VV_PLEAN_SLCT	PROC	NEAR
	MOV	PLEAN_SLCT,DX		; vram plean select.

	JMP	$+2			;

	MOV	AH,BYTE PTR PLEAN_SLCT	; vram plean select.
	MOV	AL,2			; map mask.
	MOV	DX,3C4H			; sequence registar.
	OUT	DX,AX			;

	JMP	$+2

	RET
VV_PLEAN_SLCT	ENDP

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

PLEAN_SLCT	DW	0		; vram plean select.
VMODE		DW	0		; video mode.

FILENM		DB	20 DUP (0),0,0	; file name.

COLNUM		DW	0		; color.
PLTNUM		DW	0		; palet.

DATA	ENDS

	END
;
;	end of "SSIMAGE.ASM"
;
