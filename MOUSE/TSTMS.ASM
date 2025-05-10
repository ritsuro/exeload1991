; "TSTMS.ASM" PS55Z/S14 make by R.H 1991/08/01
;
;
;	PS/2 MOUSE I/O.
;
;	mouse data format.
;
;		D7	D6	D5	D4	D3	D2	D1	D0
;  1packet	Yover	Xover	Ysign	Xsign	Zover	Zsign	RIGHT	LEFT
;  2packet	X7	X6	X5	X4	X3	X2	X1	X0
;  3packet	Y7	Y6	Y5	Y4	Y3	Y2	Y1	Y0
;
;
;	PS2MOUSE_INIT		; mouse init.
;	PS2MOUSE_END		; mouse end.
;
; test main.


MOVX	MACRO	DEST,SOUR
	MOV	AX,SOUR
	MOV	DEST,AX
	ENDM

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,SS:STACK,ES:DATA

; *********************************************************
;	START.
; *********************************************************

START:
	PUSH	DS
	MOV	AX,SEG DATA
	MOV	DS,AX
	CALL	MAIN
	POP	DS
FINALE:
	MOV	AH,4CH
	MOV	AL,0
	INT	21H
	JMP	$

; *********************************************************
;	main proc.
; *********************************************************

MAIN	PROC	NEAR
	CALL	PS2MOUSE_INIT		; mouse init.

MAIN_LOOP:
	CMP	FLAGINT,0		; intalpt flag.
	JE	MAIN_NEXT		;

	MOV	FLAGINT,0		; intalpt flag.

	MOV	DX,PACKET1
	CALL	BINSTR
	CALL	PRINT

	MOV	SI,OFFSET DLM1
	CALL	PRINT

	MOV	DX,PACKET2
	CALL	BINSTR
	CALL	PRINT

	MOV	SI,OFFSET DLM1
	CALL	PRINT

	MOV	DX,PACKET3
	CALL	BINSTR
	CALL	PRINT

	MOV	SI,OFFSET LFP1
	CALL	PRINT

MAIN_NEXT:
	TEST	PACKET1,10B		; right bottan.
	JZ	MAIN_LOOP		;

	CALL	PS2MOUSE_END		; mouse end.

	RET
MAIN	ENDP


; *********************************************************
;	i*2 value -> string(bin format).
;	-I- DX :i*2 value.
;	-O- SI :string address.
;	        NULL=end of string.
; *********************************************************

BINSTR	PROC	NEAR
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX

	MOV	SI,OFFSET BUFFER
	MOV	BX,8000H
	MOV	CX,16
BINSTR1:
	MOV	AX,DX
	AND	AX,BX			; if bitX = 1 then
	JZ	BINSTR2			;   [si] = '1'
	MOV	BYTE PTR[SI],'1'	;
	JMP	BINSTR3			; else
BINSTR2:				;   [si] = '0'
	MOV	BYTE PTR[SI],'0'	;
BINSTR3:				; endif
	SHR	BX,1
	INC	SI
	LOOP	BINSTR1

	MOV	BYTE PTR [SI],0		; end of string.
	MOV	SI,OFFSET BUFFER	; string adrs.

	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
BINSTR	ENDP


; *********************************************************
;	print of string.
;	-I- SI : string address.
;	       NULL=end of string.
; *********************************************************

PRINT	PROC	NEAR
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
PRINT1:
	MOV	AL,[SI]
	CMP	AL,0		; end of string
	JE	PRINT2

	MOV	DL,AL		; put char=DL
	MOV	AH,02H		; 
	INT	21H		; DOS call.

	INC	SI
	JMP	PRINT1
PRINT2:
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
PRINT	ENDP


; *********************************************************
;	mouse init.
; *********************************************************

PS2MOUSE_INIT	PROC	NEAR
	CLI				;

	MOV	AX,0C201H		; pointing device reset.
	INT	15H			; device bios.

	MOV	AX,0C205H		; data package byte length.
	MOV	BH,3			; 3 byte.
	INT	15H			; device bios.

	MOV	AX,0C203H		; resolution.
	MOV	BH,1			; 1=2count/mm
					; 00=1,01=2,02=4,03=8
	INT	15H			; device bios.

	MOV	AX,0C206H		; extended command.
	MOV	BH,1			; 1=1:1
	INT	15H			; device bios.

	MOV	AX,0C202H		; sample rate set.
	MOV	BH,1			; 1=20report/sec.
					; 0=10,1=20,2=40,3=60,4=80,5=100,6=200
	INT	15H			; device bios.

	MOVX	ES,CS			;
	MOV	AX,0C207H		; pointing device driver init.
	MOV	BX,OFFSET INT_PNT_DEVICE ; pointing device int.
	INT	15H			; device bios.

	MOV	AX,0C200H		; pointing device enable/disable.
	MOV	BH,1			; 1=enable.
	INT	15H			; device bios.

	STI
	RET
PS2MOUSE_INIT	ENDP


; *********************************************************
;	mouse end.
; *********************************************************

PS2MOUSE_END	PROC	NEAR
	CLI
	MOV	AX,0C200H		; pointing device enable/disable.
	MOV	BH,0			; 0=disable.
	INT	15H			; device bios.
	STI
	RET
PS2MOUSE_END	ENDP


; *********************************************************
;	pointing device int.
; *********************************************************

INT_PNT_DEVICE	PROC	FAR
	CLI
	PUSH	BP
	MOV	BP,SP
	PUSHF
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	PUSH	DI
	PUSH	ES
	PUSH	DS

	MOV	AX,SEG DATA
	MOV	DS,AX

	MOV	FLAGINT,1		; intalpt flag.

	; [BP+2] = BP
	; [BP+4] = ret offset.
	; [BP+6] = ret segment.
	; [BP+8] = [3packet]
	; [BP+A] = [2packet]
	; [BP+C] = [1packet]

	MOVX	PACKET1,[BP][12]
	MOVX	PACKET2,[BP][10]
	MOVX	PACKET3,[BP][8]

	POP	DS
	POP	ES
	POP	DI
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	POPF
	POP	BP
	STI
	RET
INT_PNT_DEVICE	ENDP

CODE	ENDS

DATA	SEGMENT	PUBLIC	'DATA'

PACKET1		DW	0		; 1packet.
PACKET2		DW	0		; 2packet.
PACKET3		DW	0		; 3packet.
FLAGINT		DW	0		; intalpt flag.

;		0 1 2 3 4 5 6 7 8 9 A B C D E F . .
BUFFER	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DLM1	DB	',',0
LFP1	DB	0DH,0AH,0

DATA	ENDS

STACK	SEGMENT	STACK
	DW	1000 DUP (?)
STACK	ENDS

	END	START
;
;	end of "TSTMS.ASM"
;
