; "SSVIDEO.ASM" PC-9801UV11 make by R.H 1991/06/15
;
;	E X E L O A D     V I D E O    T E S T    c o m m a n d .
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

PUBLIC	CMDVTEST	; VIDEO test.

; *********************************************************
;	VIDEO test.
; *********************************************************

CMDVTEST	PROC	NEAR
CMDVTEST_START:
	PRF	"1.disply mode/int10h/ah=00h"
	PRF	"2.box paint"
	PRF	"3.video DAC color reg dump"
	PRF	"4.VGA text test"
	PRF	"5.video DAC chenge test."
	PRF	"6.video DAC chenge test CGA color."

CMDVTEST_INP:
	INP	"[Q:EXIT]="
	CALL	STRDEC
	CMP	DX,0
	JE	CMDVTEST_START

	CALL_NM	1,CMDVMOD		; VIDEO mode set.
	CALL_NM	2,BOXPAINT		; box paint.
	CALL_NM	3,VIDEO_DAC_DUMP	; video DAC dump.
	CALL_NM	4,VGA_TEXT_TEST		; VGA text test.
	CALL_NM 5,VIDEO_DAC_CHENG_TEST	; video DAC chenge test.
	CALL_NM	6,VIDEO_DAC_CHENG_2TST	; video DAC chenge test CGA color.

	JMP	CMDVTEST_INP

	RET
CMDVTEST	ENDP


;	VIDEO mode set.

CMDVMOD	PROC	NEAR
	PRF	" v e r y    d a n g e r !!"
	INP	"mode: "
	CMP	BYTE PTR DS:[SI],0
	JE	CMDVMOD_EXIT

	CALL	STRDEC		; string->dec.

	MOV	AL,DL		; disply mode.
	MOV	AH,00H		; mode set.
	INT	10H		; graph bios.

CMDVMOD_EXIT:
	RET
CMDVMOD	ENDP


;	box paint.

BOXPAINT	PROC	NEAR

	CALL	V_MODE_SELECT		; video mode select.
	CMP	VMODE,10H		; video mode.
	JE	BOXPAINT_EGA		;
	CMP	VMODE,12H		; video mode.
	JE	BOXPAINT_VGA		;
	RET

BOXPAINT_EGA:
	JMP	BOXPAINT_RETRY		;

BOXPAINT_VGA:
	JMP	BOXPAINT_RETRY		;

BOXPAINT_RETRY:
	CALL	COLOR_BAR_DISP		; color bar disply.

	CALL	INPUT
	CMP	WORD PTR [SI],'R'
	JMPEQ	BOXPAINT_RETRY


	CALL	V_MODE_RET		; video mode return.

	RET
BOXPAINT	ENDP


;	color bar disply.

COLOR_BAR_DISP	PROC	NEAR
	MOV	AX,0305H	; write mode 3.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0FF00H	; set/reset.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0001H	; enable set/reset.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0003H	; data rotate/funtion select.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0007H	; color don't care.
	MOV	DX,3CEH		; address prot.

	OUT	DX,AX		;

	JMP	$+2

	MOV	AX,0FF08H	; bit mask.
	MOV	DX,3CEH		; address prot.
	OUT	DX,AX		;

	JMP	$+2

	MOV	PAI_COLOR,0		; paint color.
	MOV	YY,0			; y.
	MOV	HIGHT,20		; hight.
	MOV	CX,16			;
COLOR_BAR_DISP_LOOP:			;
	CALL	BANDO_PAINT		; bando paint.
	INC	PAI_COLOR		; paint color.
	ADD	YY,20			;
	LOOP	COLOR_BAR_DISP_LOOP	;

	RET
COLOR_BAR_DISP	ENDP



;	VGA text test.

VGA_TEXT_TEST	PROC	NEAR
	CALL	V_MODE_SELECT		; video mode select.
	CALL	PAL_TO_REG_SET		; palet nunber to color registar set.

	CALL	VIDEO_PARA_SAVE		; EGA & VGA video bios parameter save.
	CALL	VGA_PARA_SAVE		; VGA secondary parameter save.

	CALL	CLS

	MOV	COLNUM,0		; color.
	MOV	CX,16
VGA_TEXT_TEST_LOOP:
	PUSH	CX
	MOV	AX,COLNUM		; color.
	CALL	PRNCOL			; print color.
	PRF	"ABCDEFGHIJKLMN"

	CALL	UUWAIT			; wait.

	INC	COLNUM			; color.
	POP	CX
	LOOP	VGA_TEXT_TEST_LOOP

	MOV	AX,111B			; color.
	CALL	PRNCOL			; print color.

	MOV	COLNUM,0		; color.
	MOV	CX,16
VGA_TEXT_TEST_LOOP2:
	PUSH	CX
	CALL	BACK_COLOR_SET		; back color set.

	CALL	UUWAIT			; wait.

	INC	COLNUM			; color.
	POP	CX
	LOOP	VGA_TEXT_TEST_LOOP2

	MOV	COLNUM,1		; color.
	CALL	BACK_COLOR_SET		; back color set.

	CALL	USR_WAIT		; user wait.

	CALL	VIDEO_PARA_LOAD		; EGA & VGA video bios parameter load.

	CALL	V_MODE_RET		; video mode return.
	RET
VGA_TEXT_TEST	ENDP


;	back color set.
;	-I- COLNUM : color.

BACK_COLOR_SET	PROC	NEAR
	MOV	BH,0			;
	MOV	BL,BYTE PTR COLNUM	; color.
	MOV	AH,0BH			; color palet set.
	INT	10H			; video bios.
	RET
BACK_COLOR_SET	ENDP


;	wait.

UUWAIT	PROC	NEAR
	MOV	CX,10000
UUWAIT_LOOP:
	JMP	UUWAIT_JP1
UUWAIT_JP1:
	LOOP	UUWAIT_LOOP
	RET
UUWAIT	ENDP



;	video mode select.
;	-O- VMODE : video mode.

V_MODE_SELECT	PROC	NEAR
	INP	"1:EGA,2:VGA :"
	CALL	STRDEC
	CMP	DX,1
	JE	V_MODE_SELECT_EGA
	CMP	DX,2
	JE	V_MODE_SELECT_VGA

	CALL	V_MODE_RET		; video mode return.
	RET

V_MODE_SELECT_EGA:
	CALL	V_MODE_SLCT_EGA		; video mode select EGA.
	RET

V_MODE_SELECT_VGA:
	CALL	V_MODE_SLCT_VGA		; video mode select VGA.
	RET
V_MODE_SELECT	ENDP


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
;	-O- VMODE : video mode.

V_MODE_RET	PROC	NEAR
	MOV	AL,02H			; disply mode.
	MOV	AH,00H			; mode set.
	INT	10H			; graph bios.

	MOV	VMODE,02H		; video mode.
	RET
V_MODE_RET	ENDP


;	bando paint.
;	-I- PAI_COLOR : paint color.
;	    YY        : y.
;	    HIGHT     : hight.

BANDO_PAINT	PROC	NEAR
	PUSH	CX

	JMP	$+2			;
	MOV	AH,BYTE PTR PAI_COLOR	; paint color.
	MOV	AL,00H			; set/reset.
	MOV	DX,3CEH			; address prot.
	OUT	DX,AX			;
	JMP	$+2			;
	MOV	CX,0A000H
	MOV	ES,CX

	MOV	AX,YY			; y.
	MOV	BX,80			;
	MOV	DX,0			; DI = y * 80
	MUL	BX			;
	MOV	DI,AX			;

	MOV	AX,HIGHT		; hight.
	MOV	BX,80			;
	MOV	DX,0			; CX = hight * 80
	MUL	BX			;
	MOV	CX,AX			;

	MOV	AL,0FFH
	REP	STOSB

	POP	CX
	RET
BANDO_PAINT	ENDP


;	video DAC dump.

VIDEO_DAC_DUMP	PROC	NEAR

	CALL	V_MODE_SELECT		; video mode select.

	MOV	NUM,0
	MOV	CX,16
VIDEO_DAC_DUMP_LOOP:
	PUSH	CX
	PRBYTE	".",<BYTE PTR NUM>

	MOV	AL,15H			; DAC color registar read.
	MOV	BX,NUM			; color registar number.
	MOV	AH,10H			; palet reg set.
	INT	10H			; video bios.

	PRBYTE	" G",CH
	PRBYTE	" B",CL
	PRBYTE	" R",DH
	LF

	INC	NUM

	POP	CX
	LOOPX	VIDEO_DAC_DUMP_LOOP


	CALL	USR_WAIT		; user wait.

	CALL	V_MODE_RET		; video mode return.

	RET
VIDEO_DAC_DUMP	ENDP


;	video DAC chenge test.

VIDEO_DAC_CHENG_TEST	PROC	NEAR
	CALL	V_MODE_SLCT_VGA		; video mode select VGA.

	CALL	COLOR_BAR_DISP		; color bar disply.

	CALL	PAL_TO_REG_SET		; palet nunber to color registar set.

	MOV	PLTNUM,0		; palet.
	MOV	CX,16			;
VIDEO_DAC_CHENG_TEST_LOOP:		;
	PUSH	CX			;

	MOVX	COLREG,PLTNUM		; color registar number.
	CALL	COLREG_BRINK		; color registar brink.

	CALL	KESCAP			; ESC key & break check & pause.
	CMP	AX,2			; 0=normal, 1=ESC on, 2=ctrl-C
	JMPEQ	VIDEO_DAC_CHENG_TEST_BREAK

	INC	PLTNUM			; palet.
	POP	CX
	LOOP	VIDEO_DAC_CHENG_TEST_LOOP

	CALL	USR_WAIT		; user wait.

	CALL	V_MODE_RET		; video mode return.
	RET
VIDEO_DAC_CHENG_TEST_BREAK:
	POP	CX
	CALL	V_MODE_RET		; video mode return.
	RET
VIDEO_DAC_CHENG_TEST	ENDP


;	video DAC chenge test CGA color.

VIDEO_DAC_CHENG_2TST	PROC	NEAR
	CALL	V_MODE_SLCT_VGA		; video mode select VGA.

	CALL	COLOR_BAR_DISP		; color bar disply.

	MOV	PLTNUM,0		; palet.
	MOV	CX,16			;
VIDEO_DAC_CHENG_2TST_LOOP:		;
	PUSH	CX			;

	MOV	SI,PLTNUM		; palet.
	MOV	AL,DS:PAL_TO_REG[SI]	; palet nunber to color registar
	MOV	AH,0			;
	MOV	COLREG,AX		; color registar number.
	CALL	COLREG_BRINK		; color registar brink.

	CALL	KESCAP			; ESC key & break check & pause.
	CMP	AX,2			; 0=normal, 1=ESC on, 2=ctrl-C
	JMPEQ	VIDEO_DAC_CHENG_2TST_BREAK

	INC	PLTNUM			; palet.
	POP	CX
	LOOP	VIDEO_DAC_CHENG_2TST_LOOP

	CALL	USR_WAIT		; user wait.

	CALL	V_MODE_RET		; video mode return.
	RET
VIDEO_DAC_CHENG_2TST_BREAK:
	POP	CX
	CALL	V_MODE_RET		; video mode return.
	RET
VIDEO_DAC_CHENG_2TST	ENDP





;	color registar brink.
;	-I- COLREG : color registar number.

COLREG_BRINK	PROC	NEAR
	MOV	VAL_GREEN,0		; green.
	MOV	VAL_BLUE,0		; blue.
	MOV	VAL_RED,0		; red.

	MOV	CX,64/2
COLREG_BRINK_LOOP:
	PUSH	CX

	CALL	KESCAP			; ESC key & break check & pause.
	CMP	AX,2			; 0=normal, 1=ESC on, 2=ctrl-C
	JMPEQ	COLREG_BRINK_EXIT	;

	ADD	VAL_GREEN,2		; green.
	ADD	VAL_BLUE,2		; blue.
	ADD	VAL_RED,2		; red.

	MOV	BX,COLREG		; color registar number.
	MOV	CH,BYTE PTR VAL_GREEN	; green.
	MOV	CL,BYTE PTR VAL_BLUE	; blue.
	MOV	DH,BYTE PTR VAL_RED	; red.
	MOV	AL,10H			; DAC color registar rewrite.
	MOV	AH,10H			; palet set.
	INT	10H			; video bios.

	POP	CX
	LOOP	COLREG_BRINK_LOOP
	RET
COLREG_BRINK_EXIT:
	POP	CX
	RET
COLREG_BRINK	ENDP



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

	POP	CX
	LOOP	PAL_TO_REG_SET_LOOP

	RET
PAL_TO_REG_SET	ENDP





SAVE_PTR_OFS	EQU	0A8H		; save pointer table offset.
SAVE_PTR_SEG	EQU	040H		; save pointer table segment.


;	EGA & VGA video bios parameter save.

VIDEO_PARA_SAVE	PROC	NEAR

	CLI

	; (1) old pointer save.

	MOVX	ES,SAVE_PTR_SEG			; save pointer table segment.
	MOVX	OLD_SAVE_POINTER_OFS,ES:[SAVE_PTR_OFS]   ; save pointer
	MOVX	OLD_SAVE_POINTER_SEG,ES:[SAVE_PTR_OFS][2]; save pointer

	; (2) save pointer table copy.

	PUSH	DS				;
	MOV	DI,OFFSET MY_SAVE_POI_TBL	; save pointer
	MOVX	ES,DS				;
	MOV	SI,OLD_SAVE_POINTER_OFS		; old save pointer offset.
	MOV	DS,OLD_SAVE_POINTER_SEG		; old save pointer segment.
	MOV	CX,7*4				; 7 duble word.
	REP	MOVSB				;
	POP	DS				;

	; (3) new pointer load.

	MOVX	ES,SAVE_PTR_SEG			 ; save pointer table segment.
	MOV	WORD PTR ES:[SAVE_PTR_OFS],OFFSET MY_SAVE_POI_TBL
	MOV	WORD PTR ES:[SAVE_PTR_OFS][2],DS

	; (4) "save pointer" table address set.

	MOV	MY_SAVE_POI_TBL[4],OFFSET VIDEO_BIOS_TBL ; video table offset.
	MOV	MY_SAVE_POI_TBL[6],DS			 ; video table segment.

	STI

	RET
VIDEO_PARA_SAVE	ENDP


;	VGA secondary parameter save.
;	calling after "VIDEO_PARA_SAVE"

VGA_PARA_SAVE	PROC	NEAR

	CLI

	; (1) secondary save pointer table copy.

	PUSH	DS				;
	MOV	SI,MY_SAVE_POI_TBL[16]		; +16 secondary save ptr adrs.
	MOV	DI,OFFSET MY_SCND_SAVE_POI_TBL	;secondary save pointer table.
	MOVX	ES,DS				;
	MOVX	DS,MY_SAVE_POI_TBL[18]		; +18 secondary save ptr seg.
	MOV	CX,26				; 2nd save ptr table len.
	REP	MOVSB				;
	POP	DS				;

	; (2) new secondary save pointer table address set.

	MOV	MY_SAVE_POI_TBL[16],OFFSET MY_SCND_SAVE_POI_TBL
	MOV	MY_SAVE_POI_TBL[18],DS

	; (2) user palet profile table set.

	MOV	MY_SCND_SAVE_POI_TBL[10],OFFSET USER_PALET_PROFILE_TBL
	MOV	MY_SCND_SAVE_POI_TBL[12],DS

	STI

	RET
VGA_PARA_SAVE	ENDP



;	EGA & VGA video bios parameter load.

VIDEO_PARA_LOAD	PROC	NEAR

	; (1) old pointer load.

	MOVX	ES,40H				;
	MOVX	ES:[SAVE_PTR_OFS],OLD_SAVE_POINTER_OFS    ; save pointer
	MOVX	ES:[SAVE_PTR_OFS][2],OLD_SAVE_POINTER_SEG ; save pointer

	RET
VIDEO_PARA_LOAD	ENDP


;	user wait.

USR_WAIT	PROC	NEAR
	INP	"WAIT"
	RET
USR_WAIT	ENDP

;*;	MOV	AL,13H			; color page select.
;*;	MOV	BL,00H			; paging mode select.
;*;	MOV	BH,01H			; 00H=4 block, 01H=16 block
;*;	MOV	AH,10H			; palet reg set.
;*;	INT	10H			; video bios.
;*;
;*;	MOV	AL,13H			; color page select.
;*;	MOV	BL,01H			; page select.
;*;	MOV	BH,0			; page.
;*;	MOV	AH,10H			; palet reg set.
;*;	INT	10H			; video bios.
;*;
;*;	MOV	BL,31H	; default palet load enable/disable.
;*;	MOV	AL,1	; 0=disable,1=enable.
;*;	MOV	AH,12H	; video sub system set.
;*;	INT	10H	; video bios.

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

GRAPH_BIT_PLEAN		DB	0		;
PAI_COLOR		DW	0		; paint color.
XX			DW	0		; x.
YY			DW	0		; y.
HIGHT			DW	0		; hight.
NUM			DW	0		; number.
VMODE			DW	0		; video mode.
COLNUM			DW	0		; color.
PLTNUM			DW	0		; palet.
COLREG			DW	0		; color registar number.

VAL_GREEN		DW	0		; green.
VAL_BLUE		DW	0		; blue.
VAL_RED			DW	0		; red.

OLD_SAVE_POINTER_OFS	DW	0		; old save pointer offset.
OLD_SAVE_POINTER_SEG	DW	0		; old save pointer segment.

MY_SAVE_POI_TBL		LABEL	WORD		; save pointer table.
			DD	0		; +0  video parameter table ad.
			DD	0		; +4  parameter work area adrs.
			DD	0		; +8  text char set adrs.
			DD	0		; +12 graphic char set adrs.
			DD	0		; +16 secondary save ptr adrs.
			DD	0		; +20 reserved.
			DD	0		; +24 reserved.

MY_SCND_SAVE_POI_TBL	LABEL	WORD		;secondary save pointer table.
			DW	0		; +0  2nd save ptr table len.
			DD	0		; +2  disply conbi'tbl adrs.
			DD	0		; +6  2nd text char set adrs.
			DD	0		; +10 user palet profile adrs.
			DD	0		; +14 reserved.
			DD	0		; +18 reserved.
			DD	0		; +22 reserved.

VIDEO_BIOS_TBL		DB	256 DUP (0)	; video bios table.

USER_PALET_PROFILE_TBL	LABEL	BYTE		; user palet profile table.
			DB	0		; +0  byte:under line.
			DB	0		; +1  byte:reserved.
			DW	0		; +2  word:reserved.
			DW	17		; +4  attr contlor reg count.
			DW	0		; +6  attr contlor reg number.
			DW	PALTABLE	; +8  attr contlor tbl offset.
			DW	SEG DATA	; +10 attr contlor tbl segment.
			DW	0		; +12 DAC color reg count.
			DW	0		; +14 DAC color reg number.
			DW	0		; +16 DAC color tbl offset.
			DW	0		; +18 DAC color tbl segment.
			DB	03		; +20 used video mode.
			DB	0FFH		; end data.

PALTABLE		LABEL	BYTE		; palet table.
			;	0   1   2   3   4   5   6   7
			DB	30H,31H,32H,33H,34H,35H,36H,37H
			DB	00H,01H,02H,03H,04H,05H,14H,07H
			DB	01H		; over scan registar.

PAL_TO_REG		LABEL	BYTE		;palet nunber to color registar
			DB	00H		;00H	black
			DB	01H		;01H	dark blue
			DB	02H		;02H	dark green
			DB	03H		;03H	dark cyan
			DB	04H		;04H	dark red
			DB	05H		;05H	dark violet
			DB	14H		;06H	brown
			DB	07H		;07H	gray
			DB	38H		;08H	dark gray
			DB	39H		;09H	blue
			DB	3AH		;0AH	green
			DB	3BH		;0BH	cyan
			DB	3CH		;0CH	red
			DB	3DH		;0DH	violet
			DB	3EH		;0EH	yellow
			DB	3FH		;0FH	white

DATA	ENDS

	END
;
;	end of "SSVIDEO.ASM"
;
