; "TSTBEEP.ASM" PS55Z/S14 make by R.H 1991/07/25
;
;
;	BEEP TEST.
;
;
;	é¸îgêîÅ@ÅÅÅ@ÇPÇPÇXÇRÇPÇWÇOÅ@ÅÄÅ@ÉJÉEÉìÉg
;
;	ÇaÇ`ÇrÇhÇbÉTÉìÉuÉã
;
;	10  ' 3000 Hz sound.
;	20  COUNT = 1193180! / 3000		' ÇRÇOÇOÇOÇgÇö
;	30  LO.COUNT = COUNT MOD 256		'
;	40  HI.COUNT = COUNT / 256		'
;	50  OUT &H43,&HB6			' É^ÉCÉ}ÇÉåÉfÉBÇ…Ç∑ÇÈÅB
;	60  OUT &H42,LO.COUNT			' â∫à ÉoÉCÉg
;	70  OUT &H42,HI.COUNT			' è„à ÉoÉCÉg
;	80  OLD.PORT = INP(&H61)		'
;	90  NEW.PORT = (OLD.PORT OR &H3)	' speaker on.
;	100 'NEW.PORT = (OLD.PORT AND  NOT(3))	' speaker off.
;	110 OUT &H61,NEW.PORT			' ÉXÉsÅ[ÉJÅ[Çñ¬ÇÁÇ∑ÅB
;
;
; test main.

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
;	MAIN PROC.
; *********************************************************

MAIN	PROC	NEAR

	CALL	SPEAKER_ON		; speaker on.

	MOV	CX,261			; frequency.
	CALL	POOOOO_SET		; pooo.. sound set.
	CALL	TIME_WAIT		; time wait.

	MOV	CX,293			; frequency.
	CALL	POOOOO_SET		; pooo.. sound set.
	CALL	TIME_WAIT		; time wait.

	MOV	CX,329			; frequency.
	CALL	POOOOO_SET		; pooo.. sound set.
	CALL	TIME_WAIT		; time wait.

	MOV	CX,349			; frequency.
	CALL	POOOOO_SET		; pooo.. sound set.
	CALL	TIME_WAIT		; time wait.

	MOV	CX,392			; frequency.
	CALL	POOOOO_SET		; pooo.. sound set.
	CALL	TIME_WAIT		; time wait.

	MOV	CX,440			; frequency.
	CALL	POOOOO_SET		; pooo.. sound set.
	CALL	TIME_WAIT		; time wait.

	MOV	CX,493			; frequency.
	CALL	POOOOO_SET		; pooo.. sound set.
	CALL	TIME_WAIT		; time wait.

	MOV	CX,523			; frequency.
	CALL	POOOOO_SET		; pooo.. sound set.
	CALL	TIME_WAIT		; time wait.

	CALL	SPEAKER_OFF		; speaker off.

	RET
MAIN	ENDP


;	pooo.. sound set.
;	-I- CX : frequency.

POOOOO_SET	PROC	NEAR
	JCXZ	POOOOO_SET_EXIT		; if  CX=0  then exit.

	MOV	AX,34DCH		; 1193180 lower word.
	MOV	DX,12H			; 1193180 upper word.
	DIV	CX			; AX = DX:AX / CX

	MOV	DX,AX			;

	MOV	AL,0B6H			; timer ready.
	OUT	43H,AL			;

	MOV	AL,DL			; low byte.
	OUT	42H,AL			;

	MOV	AL,DH			; hi byte.
	OUT	42H,AL			;

POOOOO_SET_EXIT:
	RET
POOOOO_SET	ENDP


;	speaker on.

SPEAKER_ON	PROC	NEAR
	IN	AL,61H			;
	OR	AL,00000011B		; speaker on.
	OUT	61H,AL			;
	RET
SPEAKER_ON	ENDP


;	speaker off.

SPEAKER_OFF	PROC	NEAR
	IN	AL,61H			;
	AND	AL,11111100B		; speaker off.
	OUT	61H,AL			;
	RET
SPEAKER_OFF	ENDP


;	time wait.

TIME_WAIT	PROC	NEAR
	MOV	CX,10
TIME_WAIT_LOOP:
	PUSH	CX
	MOV	CX,10000
TIME_WAIT_LOOP2:
	NOP
	NOP
	NOP
	NOP
	LOOP	TIME_WAIT_LOOP2
	POP	CX
	LOOP	TIME_WAIT_LOOP
	RET
TIME_WAIT	ENDP

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'
DATA	ENDS

STACK	SEGMENT	STACK
	DW	1000 DUP (?)
STACK	ENDS


	END	START
;
;	end of "TSTBEEP.ASM"
;
