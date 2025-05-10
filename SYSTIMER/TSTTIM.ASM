; "TSTTIM.ASM"   PS55Z/S14 make by R.H 1991/08/19
;
;
;	system timertick inttarapt test.
;	8253 count/timer LSI
;
;
; public subroutine.

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA

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
	CALL	TMVSRT			; system timer start.

MAIN_LOOP:
	CMP	TIMER_CNT,72*10		; timer counter.
	JB	MAIN_LOOP		;

	CALL	TMVEND			; system timer end.
	RET
MAIN	ENDP



; *********************************************************
;	timer program.
; *********************************************************

COUNT_REG_CH0		EQU	40H	; count register - channel 0.

OUT8253	MACRO	NUM
	OUT	NUM,AL
	JMP	$+2
	ENDM

OUT8259	MACRO	NUM
	OUT	NUM,AL
	JMP	$+2
	ENDM

RETFAR	MACRO			; far return.
	DB	11001011B	; RETF
	ENDM

MOVX	MACRO	DEST,SOUR
	MOV	AX,SOUR
	MOV	DEST,AX
	ENDM


;	system timer start.

TMVSRT	PROC	NEAR
	CALL	VECSET_SSTIME_SAVE	; vector save.
	CALL	VECSET_SSTIME		; int vector set.
	CLI
	MOV	AL,00H			; 72.8tick/second = 1193180Mhz / 4000h
	OUT8253	COUNT_REG_CH0		; count register - channel 0.
	MOV	AL,40H			;
	OUT8253	COUNT_REG_CH0		; count register - channel 0.
	MOV	TIMER_SKIP_CNT,0	; timer skip counter.
	STI
	RET
TMVSRT	ENDP


;	system timer end.

TMVEND	PROC	NEAR
	CALL	VECSET_SSTIME_LOAD	; vector load.
	CLI
	MOV	AL,00H			; 18.2tick/second = 1193180Mhz / 65536
	OUT8253	COUNT_REG_CH0		; count register - channel 0.
	MOV	AL,00H			;
	OUT8253	COUNT_REG_CH0		; count register - channel 0.
	STI
	RET
TMVEND	ENDP


VEC_SSTIME_OFST	EQU	20H		; int 08h
VEC_SSTIME_SEG	EQU	22H		;

;	int vector set.

VECSET_SSTIME	PROC	NEAR
	CLI
	MOV	AX,0			; 0 base.
	MOV	ES,AX			;
	MOV	WORD PTR ES:[VEC_SSTIME_OFST],OFFSET SSTIMEINT
	MOV	WORD PTR ES:[VEC_SSTIME_SEG],SEG CODE
	STI
	RET
VECSET_SSTIME	ENDP

;	vector save.

VECSET_SSTIME_SAVE	PROC	NEAR
	CLI
	MOV	AX,0			; 0 base.
	MOV	ES,AX			;
	MOVX	SAVE_VEC_SSTIME_OFST,<WORD PTR ES:[VEC_SSTIME_OFST]>
	MOVX	SAVE_VEC_SSTIME_SEG,<WORD PTR ES:[VEC_SSTIME_SEG]>
	STI
	RET
VECSET_SSTIME_SAVE	ENDP

;	vector load.

VECSET_SSTIME_LOAD	PROC	NEAR
	CLI
	MOV	AX,0			; 0 base.
	MOV	ES,AX			;
	MOVX	<WORD PTR ES:[VEC_SSTIME_OFST]>,SAVE_VEC_SSTIME_OFST
	MOVX	<WORD PTR ES:[VEC_SSTIME_SEG]>,SAVE_VEC_SSTIME_SEG
	STI
	RET
VECSET_SSTIME_LOAD	ENDP


;	V-SYNC interrapt routine.

SSTIMEINT	PROC	FAR
	PUSH	DS	;16
	PUSH	ES	;14
	PUSH	AX	;12
	PUSH	BX	;10
	PUSH	CX	;8
	PUSH	DX	;6
	PUSH	BP	;4
	PUSH	SI	;2
	PUSH	DI	;0

	MOV	AX,SEG DATA			;
	MOV	DS,AX				;

	INC	TIMER_CNT			; timer counter.
	MOV	AL,'.'				;
	MOV	BX,0				;
	MOV	AH,0EH				; teletype text write.
	INT	10H				; IBM bios.

	INC	TIMER_SKIP_CNT			; timer skip counter.
	CMP	TIMER_SKIP_CNT,4		; timer skip counter.
	JNB	SSTIMEINT_182TICK_INT		;

	MOV	AL,20H				; EOI send.
	OUT8259	20H				;
	JMP	SSTIMEINT_INTER			;

SSTIMEINT_182TICK_INT:				;
	MOV	TIMER_SKIP_CNT,0		; timer skip counter.

	MOV	AX,OFFSET SSTIMEINT_INTER	;
	PUSHF					;[ flags       ]
	PUSH	CS				;[ ret segment ]
	PUSH	AX				;[ ret offset  ]

	MOV	AX,SAVE_VEC_SSTIME_SEG		; save vector segment.
	MOV	BX,SAVE_VEC_SSTIME_OFST		; save vector offset.
	PUSH	AX				;
	PUSH	BX				;
	RETFAR					; ÇeÇ`ÇqÉäÉ^Å[Éì
SSTIMEINT_INTER:				;
	POP	DI
	POP	SI
	POP	BP
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	POP	ES
	POP	DS
	IRET
SSTIMEINT	ENDP

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

FOOK_SSTIME_FAR	LABEL	DWORD		; system time int vector.
SAVE_VEC_SSTIME_OFST	DW	0	; save vector offset.
SAVE_VEC_SSTIME_SEG	DW	0	; save vector segment.

TIMER_SKIP_CNT	DW	0		; timer skip counter.

TIMER_CNT	DW	0		; timer counter.

DATA	ENDS

STACK	SEGMENT	STACK
	DW	1000 DUP (?)
STACK	ENDS

	END	START
;
;	end of "TSTTIM.ASM"
;
