; "TSTSET.INC" PC-9801UV11 make by R.H 1989/10/24
;
;	E X E L O A D    p r i n t   m a c r o .
;
;
;
; public subroutine.


;	oq	h\¦Άρh
;	iόs³΅vgj

PR	MACRO	STRING
	LOCAL	L1,L2
	PUSH	SI
	JMP	L2
DATA	SEGMENT	PUBLIC	'DATA'
	EVEN
L1	DB	STRING,0
	EVEN
DATA	ENDS
L2:	MOV	SI,OFFSET L1
	CALL	PRINT
	POP	SI
	ENDM


;	oqe	h\¦Άρh
;	iόsLθvgj

PRF	MACRO	STRING
	LOCAL	L1,L2
	PUSH	SI
	JMP	L2
DATA	SEGMENT	PUBLIC	'DATA'
	EVEN
L1	DB	STRING,0
	EVEN
DATA	ENDS
L2:	MOV	SI,OFFSET L1
	CALL	PRINT
	POP	SI
	CALL	LFPRN
	ENDM


;	hmo
;	iΆρΜόΝj@oΝ@crFrhόΝΆρp
;		ΰobt@ΜζͺAhXiNULL=end of stringj

INP	MACRO	STRING
	LOCAL	L1,L2,L3
	PUSH	SI
	JMP	L2
DATA	SEGMENT	PUBLIC	'DATA'
	EVEN
L1	DB	STRING,0
	EVEN
DATA	ENDS
L2:	MOV	SI,OFFSET L1
	CALL	PRINT
	POP	SI
	CALL	INPUT
	CALL	LFPRN
	CMP	BYTE PTR [SI],'Q'	;exit.
	JNZ	L3
	RET
L3:
	ENDM


;	bnlo	hδrpΆρh
;	icrFrhΖΜδrj@όΝ@crFrhδrΞΖΆρ
;					iNULL=end of stringj
;				oΝ@A

COMP	MACRO	STRING
	LOCAL	L1,L2
	JMP	L2
DATA	SEGMENT	PUBLIC	'DATA'
	EVEN
L1	DB	STRING,0
	EVEN
DATA	ENDS
L2:	MOV	DI,OFFSET L1
	CALL	STRCMP
	ENDM


;	ke
;	iόsj

LF	MACRO
	CALL	LFPRN
	ENDM


;	oqu	h\¦ΆρhCvnqcQu`k
;	iόsLθ[hlvgPOij

PRV	MACRO	STRING,PARAM
	LOCAL	L1,L2
	PUSH	SI
	PUSH	DX
	PUSH	SI
	JMP	L2
DATA	SEGMENT	PUBLIC	'DATA'
	EVEN
L1	DB	STRING,0
	EVEN
DATA	ENDS
L2:	MOV	SI,OFFSET L1
	CALL	PRINT
	POP	SI
	MOV	DX,PARAM
	CALL	DECSTR
	CALL	STRZTS	; zero to space. "00123" - > "  123"
	CALL	PRINT
	POP	DX
	POP	SI
	CALL	LFPRN
	ENDM


;	oqug	h\¦ΆρhCvnqcQu`k
;	iόsLθ[hlvgPUij

PRVH	MACRO	STRING,PARAM
	LOCAL	L1,L2
	PUSH	SI
	PUSH	DX
	PUSH	SI
	JMP	L2
DATA	SEGMENT	PUBLIC	'DATA'
	EVEN
L1	DB	STRING,0
	EVEN
DATA	ENDS
L2:	MOV	SI,OFFSET L1
	CALL	PRINT
	POP	SI
	MOV	DX,PARAM
	CALL	HEXSTR
	CALL	PRINT
	POP	DX
	POP	SI
	CALL	LFPRN
	ENDM


;	oqua	h\¦ΆρhCvnqcQu`k
;	iόsLθ[hlvgQij

PRVB	MACRO	STRING,PARAM
	LOCAL	L1,L2
	PUSH	SI
	PUSH	DX
	PUSH	SI
	JMP	L2
DATA	SEGMENT	PUBLIC	'DATA'
	EVEN
L1	DB	STRING,0
	EVEN
DATA	ENDS
L2:	MOV	SI,OFFSET L1
	CALL	PRINT
	POP	SI
	MOV	DX,PARAM
	CALL	BINSTR
	CALL	PRINT
	POP	DX
	POP	SI
	CALL	LFPRN
	ENDM


;	oqaxsd	h\¦ΆρhCaxsdQu`k
;	ioCglvgPOij

PRBYTE	MACRO	STRING,PARAM
	LOCAL	L1,L2
	PUSH	SI
	PUSH	AX
	PUSH	SI
	JMP	L2
DATA	SEGMENT	PUBLIC	'DATA'
L1	DB	STRING,0
	EVEN
DATA	ENDS
L2:	MOV	SI,OFFSET L1
	CALL	PRINT
	POP	SI
	MOV	DH,0
	MOV	DL,PARAM
	CALL	DECSTR
	CALL	STRZTS	; zero to space. "00123" - > "  123"
	ADD	SI,2
	CALL	PRINT
	POP	AX
	POP	SI
	ENDM

;	oqaxsdg	h\¦ΆρhCaxsdQu`k
;	ioCglvgPUij

PRBYTEH	MACRO	STRING,PARAM
	LOCAL	L1,L2
	PUSH	SI
	PUSH	AX
	PUSH	SI
	JMP	L2
DATA	SEGMENT	PUBLIC	'DATA'
L1	DB	STRING,0
	EVEN
DATA	ENDS
L2:	MOV	SI,OFFSET L1
	CALL	PRINT
	POP	SI
	MOV	AH,PARAM
	CALL	PRNAH	; print ah reg.
	POP	AX
	POP	SI
	ENDM

;	oqbg
;	iPLN^vgj@όΝ@`gLN^R[h

PRCH	MACRO
	LOCAL	L1
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	CMP	AH,20H
	JNB	L1
	MOV	AH,'.'
L1:
	MOV	AL,AH
	CALL	CHPUT	;print of ascii character.
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	ENDM


;	rdsr	ΆρΌ
;	icrFrhΜΆρπΆρΌΜGAΦRs[j
;		όΝ@crFrhZbgΆρ

SETS	MACRO	SNAME
	LOCAL	L1,L2
	PUSH	ES
	PUSH	SI
	MOV	AX,DS
	MOV	ES,AX
	CLD
	MOV	DI,OFFSET SNAME
L1:	LODSB
	CMP	AL,' '		; space.
	JB	L2
	STOSB
	JMP	L1
L2:	POP	SI
	POP	ES
	ENDM

;	kb	wCx
;	eLXg\¦ΐW

LC	MACRO	XX,YY
	PUSH	AX
	PUSH	BX
	MOV	AX,XX
	MOV	BX,YY
	CALL	LOCATE		; locate.
	POP	BX
	POP	AX
	ENDM


CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,ES:CODE,SS:CODE

	EXTRN	PRNAH:NEAR
	EXTRN	PRINT:NEAR
	EXTRN	INPUT:NEAR
	EXTRN	DECSTR:NEAR
	EXTRN	STRDEC:NEAR
	EXTRN	HEXSTR:NEAR
	EXTRN	STRHEX:NEAR
	EXTRN	BINSTR:NEAR
	EXTRN	STRBIN:NEAR
	EXTRN	STRCMP:NEAR
	EXTRN	CLS:NEAR
	EXTRN	CSLON:NEAR
	EXTRN	CSLOFF:NEAR
	EXTRN	INPCHR:NEAR
	EXTRN	CHPUT:NEAR
	EXTRN	KESCAP:NEAR
	EXTRN	KEYLOD:NEAR
	EXTRN	PRNAB:NEAR
	EXTRN	LOCATE:NEAR
	EXTRN	LFPRN:NEAR
	EXTRN	D10STR:NEAR
	EXTRN	STRZTS:NEAR

CODE	ENDS

;
;	end of "TSTSET.INC"
;
