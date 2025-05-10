; "IPLSYS.ASM" PS55Z/J14 make by R.H/japan 1991/06/13
;
;
;	E X E L O A D    I P L   k i t .
;
;	I P L   &   s y s t e m    w r i t e .
;
;
; main program.

INCLUDE	TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,SS:STACK,ES:DATA

EXTRN	SYSMOD:NEAR		; system write disk type.
EXTRN	SYSSET:NEAR		; system write to disk.

START:
	PUSH	DS

	MOV	AX,SEG DATA		;
	MOV	DS,AX			;

	MOV	SAVE_SS,SS		; stack segment.
	MOV	SAVE_SP,SP		; stack pointer.

	CLI				; for i8088
	MOV	AX,SEG STACK		; stack segment.
	MOV	SS,AX			;
	MOV	SP,OFFSET TOP_OF_STACK	; stack pointer.
	STI				; for i8088

	CALL	MAIN			; main proceduer.

	CLI				; for i8088
	MOV	SS,SAVE_SS		; stack segment.
	MOV	SP,SAVE_SP		; stack pointer.
	STI				; for i8088

	POP	DS

FINALE:	MOV	AH,4CH
	MOV	AL,0
	INT	21H


;	main proceduer.

MAIN	PROC	NEAR
	LF

PRF "IPLSYS/EXELOAD/world-PC ver0.25 (C) R.Hashimoto 1991 in tokyo japan."

	INP	" media type 1=360KB,2=1.2MB,3=720KB,4=1.44MB['Q':exit]:"
	CALL	STRDEC			; string -> dec.
	MOV	AX,DX			;
	MOV	MEDIA_TYPE,AX		; media type.

	INP	" system write FD drive number.['Q':exit]:"
	CALL	STRDEC			; string -> dec.
	MOV	AX,DX			;
	DEC	AX			;
	MOV	DRIVE_NUMBER,AX		; drive number.

	INP " system write ok? ['Q':exit]"

	CALL	SYSTEM_WRITE		; system write to disk.

	RET
MAIN	ENDP


;	system write to disk.

SYSTEM_WRITE	PROC	NEAR
	CALL	DISKRESET		; ディスクのリセット

	MOV	DX,MEDIA_TYPE		; media type.
	CALL	SYSMOD			; system write disk type.

	MOV	DX,DRIVE_NUMBER		; drive number.
	CALL	SYSSET			; system write to disk.

	RET
SYSTEM_WRITE	ENDP


;	ディスクのリセット

DISKRESET	PROC	NEAR
	MOV	AH,0DH		; disk reset.
	INT	21H		; dos function.
	RET
DISKRESET	ENDP

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

SAVE_SS		DW	0	; stack segment.
SAVE_SP		DW	0	; stack pointer.

DRIVE_NUMBER	DW	0	; drive number.
MEDIA_TYPE	DW	4	; media type 1=360KB,2=1.2MB,3=720KB,4=1.44MB

DATA	ENDS

STACK	SEGMENT	STACK
	DW	200 DUP (?)
TOP_OF_STACK	LABEL	WORD
STACK	ENDS

	END	START
;
;	end of "IPLSYS.ASM"
;
