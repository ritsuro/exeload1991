; "PSHELL.ASM" PC-9801UV11,J-3100GS001 make by R.Hashimoto
; 1989/10/23,1991/04/04
; 1991/09/20
;
;	E X E L O A D    S h e l l.
;
;
; command shell.

TITLEX	MACRO
	DB		"[ ] PSHELL/world-PC ver0.13"
	DB	" (C) R.Hashimoto 1989,1990,1991 in tokyo japan."
	DB	0
	ENDM

MY_SYSTEM_SIZE	EQU	01000H	; このプログラムのサイズ（パラグラフ）

CHASH1	SEGMENT	PUBLIC	'CHASH1'
CHASH1	ENDS
CODE	SEGMENT	PUBLIC	'CODE'
CODE	ENDS
DATA	SEGMENT	PUBLIC	'DATA'
DATA	ENDS
STACK	SEGMENT	STACK
	DW	1000 DUP (?)
TOP_OF_STACK	LABEL	WORD
STACK	ENDS


INCLUDE TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,SS:STACK,ES:DATA

EXTRN	CMMINT:NEAR		; メモリ管理初期化
EXTRN	FFOPEN:NEAR		; ファイルオープン
EXTRN	FFCLOS:NEAR		; ファイルクローズ
EXTRN	FFREAD:NEAR		; ファイルの読み出し

EXTRN	SSMSRT:NEAR		; ドライブ・モード・スタート
EXTRN	SSMSTP:NEAR		; ドライブ・モード・ストップ
EXTRN	SSMMDE:NEAR		; ドライブ・モード標準設定

EXTRN	SSRINI:NEAR		; ドライブ初期処理
EXTRN	SSRDRV:NEAR		; ドライブ番号の設定（０ー３）
EXTRN	CLS:NEAR		; text clear.
EXTRN	CSLON:NEAR		; cursole on.
EXTRN	CSLOFF:NEAR		; cursole off.
EXTRN	PSMAIN:NEAR		; programers command shell.


; *********************************************************
;	START.
; *********************************************************

START:
	PUSH	DS			;

	MOV	AX,SEG DATA		;
	MOV	DS,AX			;

	MOV	AX,SS			; stack segment.
	MOV	SAVE_SS,AX		;
	MOV	SAVE_SP,SP		; stack pointer.

	CLI				; for i8088
	MOV	AX,SEG STACK		; stack segment.
	MOV	SS,AX			;
	MOV	SP,OFFSET TOP_OF_STACK	; stack pointer.
	STI				; for i8088

	PUSH	DX
	PUSH	DI
	PUSH	ES
	CALL	MAIN
	POP	ES
	POP	DI
	POP	DX

	CLI				; for i8088
	MOV	AX,SAVE_SS		;
	MOV	SS,AX			; stack segment.
	MOV	SP,SAVE_SP		; stack pointer.
	STI				; for i8088

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

;*;	CALL	CLS		; text clear.

	LF
	LF
	MOV	SI,OFFSET SYSTEM_NAME
	CALL	PRINT
	LF
	PRVH	"  SEG CODE :",<SEG CODE>

	CALL	CSLON		; cursole on.

	CALL	SSMSRT			; ドライブ・モード・スタート

;*;	MOV	DX,2			; モード  2=1.2MB
	MOV	DX,4			; モード  4=1.44MB
;*;	MOV	DX,5			; モード  5=1.2MB/1024
	CALL	SSMMDE			; ドライブ・モード標準設定

	CALL	SSRINI			; ドライブ初期処理

	MOV	DX,MY_SYSTEM_SIZE	; このプログラムのサイズ（パラグラフ）
	CALL	CMMINT			; メモリ管理初期化

	MOV	DX,1			; -I- DX:cullent drive number.
	CALL	PSMAIN			; programers command shell.

	CALL	SSMSTP			; ドライブ・モード・ストップ

	RET
MAIN	ENDP

CODE	ENDS


; *********************************************************
;	DATA.
; *********************************************************

DATA	SEGMENT	PUBLIC	'DATA'

SYSTEM_NAME	LABEL	BYTE
	TITLEX

SAVE_SS	DW	0	; stack segment.
SAVE_SP	DW	0	; stack pointer.

DATA	ENDS

	END	START
;
;	end of "PSHELL.ASM"
;
