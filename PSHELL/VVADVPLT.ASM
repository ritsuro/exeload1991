; "ADVPLT.ASM" 1989/3/21 R.H  PC-9801UV11 make by R.H 1989
;       modify 1989/12/08 R.H
;
; public subroutine.

INCLUDE	TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'
	ASSUME	CS:CODE,DS:DATA

	PUBLIC	SETCLR		; color set.
	PUBLIC	CLRSET		; color register set.

; color set.
; -i- CLRCDE : color code.
;     CLRVEW : color.
;     CLRCNS : contrast.
;     CLRBRI : brightness.

SETCLR	PROC	NEAR
;*DBG*;	PRV	"CLRCDE=",CLRCDE
;*DBG*;	PRV	"CLRVEW=",CLRVEW
;*DBG*;	PRV	"CLRCNS=",CLRCNS
;*DBG*;	PRV	"CLRBRI=",CLRBRI
;*DBG*;

	MOV	AX,CLRBRI	; MEIDO
	SHL	AX,1		;
	SHL	AX,1		;
	SHL	AX,1		;
	SHL	AX,1		; AX = CLRBRI * 16
	MOV	UPPER,AX	;

	MOV	AX,CLRCNS	; SAIDO
	MOV	BX,UPPER	;
	CWD			;
	MUL	BX		; AX = UPPER * BL
	DIV	DIV100		; AX = AX / 100

	MOV	BX,UPPER	;
	SUB	BX,AX		; UNDER = UPPER - AX
	MOV	UNDER,BX	;

	MOV	AX,UPPER	;
	SUB	AX,UNDER	; WIDE = UPPER - UNDER
	MOV	WIDE,AX		;

	CMP	WORD PTR CLRVEW,60
	JGE	SETCLR1
	JMP	SETCLRLV1
SETCLR1:
	CMP	WORD PTR CLRVEW,120
	JGE	SETCLR2
	JMP	SETCLRLV2
SETCLR2:
	CMP	WORD PTR CLRVEW,180
	JGE	SETCLR3
	JMP	SETCLRLV3
SETCLR3:
	CMP	WORD PTR CLRVEW,240
	JGE	SETCLR4
	JMP	SETCLRLV4
SETCLR4:
	CMP	WORD PTR CLRVEW,300
	JGE	SETCLR5
	JMP	SETCLRLV5
SETCLR5:
	JMP	SETCLRLV6

SETCLRLV1:
	MOV	AX,CLRVEW		; CLRVEW
	MOV	BX,WIDE			;
	MUL	BX			; CGREEN = CLRVEW * WIDE / 60
	DIV	DIV60			;         + UNDER
	ADD	AX,UNDER		;
	MOV	CGREEN,AX		;

	MOV	AX,UPPER		; CRED = UPPER
	MOV	CRED,AX			;
	MOV	AX,UNDER		; CBLUE = UNDER
	MOV	CBLUE,AX		;

	JMP	SETCLR_SET		;

SETCLRLV2:
	MOV	BX,CLRVEW		;
	SUB	BX,60			;
	MOV	AX,60			;
	SUB	AX,BX			; AX = 60 - ( CLRVEW - 60 )

	MOV	BX,WIDE			;
	MUL	BX			; CRED = AX * WIDE / 60
	DIV	DIV60			;         + UNDER
	ADD	AX,UNDER		;
	MOV	CRED,AX			;

	MOV	AX,UPPER		; CGREEN = UPPER
	MOV	CGREEN,AX		;
	MOV	AX,UNDER		; CBLUE = UNDER
	MOV	CBLUE,AX		;

	JMP	SETCLR_SET		;

SETCLRLV3:
	MOV	AX,CLRVEW		;
	SUB	AX,120			; CLRVEW
	MOV	BX,WIDE			;
	MUL	BX			; CBLUE = AX * WIDE / 60
	DIV	DIV60			;         + UNDER
	ADD	AX,UNDER		;
	MOV	CBLUE,AX		;

	MOV	AX,UPPER		; CGREEN = UPPER
	MOV	CGREEN,AX		;
	MOV	AX,UNDER		; CRED   = UNDER
	MOV	CRED,AX			;

	JMP	SETCLR_SET		;

SETCLRLV4:
	MOV	BX,CLRVEW		;
	SUB	BX,180			;
	MOV	AX,60			;
	SUB	AX,BX			; AX = 60 - ( CLRVEW - 60 )

	MOV	BX,WIDE			;
	MUL	BX			; CGREEN = AX * WIDE / 60
	DIV	DIV60			;         + UNDER
	ADD	AX,UNDER		;
	MOV	CGREEN,AX		;

	MOV	AX,UPPER		; CBLUE = UPPER
	MOV	CBLUE,AX		;
	MOV	AX,UNDER		; CRED  = UNDER
	MOV	CRED,AX			;

	JMP	SETCLR_SET		;

SETCLRLV5:
	MOV	AX,CLRVEW		;
	SUB	AX,240			; CLRVEW
	MOV	BX,WIDE			;
	MUL	BX			; CRED = HI1 * WIDE / 60
	DIV	DIV60			;         + UNDER
	ADD	AX,UNDER		;
	MOV	CRED,AX			;

	MOV	AX,UPPER		; CBLUE = UPPER
	MOV	CBLUE,AX		;
	MOV	AX,UNDER		; CGREEN = UNDER
	MOV	CGREEN,AX		;

	JMP	SETCLR_SET		;

SETCLRLV6:
	MOV	BX,CLRVEW		;
	SUB	BX,300			;
	MOV	AX,60			;
	SUB	AX,BX			; AX = 60 - ( CLRVEW - 60 )

	MOV	BX,WIDE			;
	MUL	BX			; CBLUE = AX * WIDE / 60
	DIV	DIV60			;         + UNDER
	ADD	AX,UNDER		;
	MOV	CBLUE,AX		;

	MOV	AX,UPPER		; CRED = UPPER
	MOV	CRED,AX			;
	MOV	AX,UNDER		; CGREEN = UNDER
	MOV	CGREEN,AX		;

	JMP	SETCLR_SET		;

SETCLR_SET:
	MOV	AX,CBLUE		;
	CWD				;
	DIV	DIV25			; AX = AX / 25
	MOV	CBLUE,AX		;

	MOV	AX,CRED			;
	CWD				;
	DIV	DIV25			; AX = AX / 25
	MOV	CRED,AX			;

	MOV	AX,CGREEN		;
	CWD				;
	DIV	DIV25			; AX = AX / 25
	MOV	CGREEN,AX		;

	MOV	AX,CLRCDE		;
	MOV	CRNUM,AX		; CRNUM = CLRCDE

	CALL	CLRVSET			; color64 register set.
	RET
SETCLR	ENDP


; color register set.
; -i- CRNUM  : color code.
;     CBLUE  : blue  value (0-15)
;     CRED   : red   value (0-15)
;     CGREEN : green value (0-15)

CLRSET	PROC	NEAR
;*;	PR	"NO,B,R,G="
;*;	MOV	DX,CRNUM	; color code.
;*;	CALL	DECSTR
;*;	CALL	PRINT
;*;	PR	","
;*;	MOV	DX,CBLUE	; blue  value (0-15)
;*;	CALL	DECSTR
;*;	CALL	PRINT
;*;	PR	","
;*;	MOV	DX,CRED		; red   value (0-15)
;*;	CALL	DECSTR
;*;	CALL	PRINT
;*;	PR	","
;*;	MOV	DX,CGREEN	; green value (0-15)
;*;	CALL	DECSTR
;*;	CALL	PRINT
;*;	LF

	MOV	BX,CRNUM	; color code.
	MOV	CH,BYTE PTR CGREEN	; green.
	MOV	CL,BYTE PTR CBLUE	; blue.
	MOV	DH,BYTE PTR CRED	; red.

	CMP	CH,16			; GREEN
	JB	CLRSET1			;
	MOV	CH,15			;
CLRSET1:
	CMP	CL,16			; RED
	JB	CLRSET2			;
	MOV	CL,15			;
CLRSET2:
	CMP	DH,16			; BLUE
	JB	CLRSET3			;
	MOV	DH,15			;
CLRSET3:
	SHL	CH,1
	SHL	CH,1
	SHL	CL,1
	SHL	CL,1
	SHL	DH,1
	SHL	DH,1
	MOV	BX,CRNUM		; color code.
	MOV	AL,10H			; DAC color registar rewrite.
	MOV	AH,10H			; palet set.
	INT	10H			; video bios.

	RET

CLRSET	ENDP


; color64 register set.
; -i- CRNUM  : color code.
;     CBLUE  : blue  value (0-63)
;     CRED   : red   value (0-63)
;     CGREEN : green value (0-63)

CLRVSET	PROC	NEAR
	MOV	BX,CRNUM	; color code.
	MOV	CH,BYTE PTR CGREEN	; green.
	MOV	CL,BYTE PTR CBLUE	; blue.
	MOV	DH,BYTE PTR CRED	; red.

	CMP	CH,64			; GREEN
	JB	CLRVSET1		;
	MOV	CH,63			;
CLRVSET1:
	CMP	CL,64			; RED
	JB	CLRVSET2		;
	MOV	CL,63			;
CLRVSET2:
	CMP	DH,64			; BLUE
	JB	CLRVSET3		;
	MOV	DH,63			;
CLRVSET3:
	MOV	BX,CRNUM		; color code.
	MOV	AL,10H			; DAC color registar rewrite.
	MOV	AH,10H			; palet set.
	INT	10H			; video bios.

	RET
CLRVSET	ENDP

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

PUBLIC	CLRCDE		; color code.
PUBLIC	CLRVEW		; color view.
PUBLIC	CLRCNS		; contrast.
PUBLIC	CLRBRI		; brightness.

PUBLIC	CRNUM		; color code.       
PUBLIC	CBLUE		; blue  value (0-15)
PUBLIC	CRED		; red   value (0-15)
PUBLIC	CGREEN		; green value (0-15)

	EVEN

CLRCDE	DW	0	; color code.
CLRVEW	DW	0	; color view.
CLRCNS	DW	0	; contrast.
CLRBRI	DW	0	; brightness.

CRNUM	DW	0	; color code.       
CBLUE	DW	0	; blue  value (0-15)
CRED	DW	0	; red   value (0-15)
CGREEN	DW	0	; green value (0-15)


UPPER	DW	0	;
UNDER	DW	0	;
WIDE	DW	0	;

DIV100	DW	100	;
DIV60	DW	60	;
DIV25	DW	25	;

	EVEN

DATA	ENDS

	END
;
;	end of "ADVPLT.ASM"
;
