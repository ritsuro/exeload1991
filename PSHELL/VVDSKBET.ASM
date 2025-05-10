; "VVDSKBET.ASM" PC-9801UV11 make by R.H 1991/06/19
;
;
;	ベタファイルのアクセス
;
;
; public subroutine.

INCLUDE	TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'
	ASSUME	CS:CODE,DS:DATA

PUBLIC	LODBET			; ベタファイルロード

EXTRN	VV_PLEAN_SLCT:NEAR	; plean select.

EXTRN	DSKLD:NEAR		; file load.

PLEAN_LEN	EQU	32000	; １プレーンのバイト数


;	ベタファイルロード
;	-I- DS:SI  : ファイル名 (null=end of string)
;	-o- AX : 0:normal.
;	         1:error.

LODBET	PROC	NEAR
	PUSH	SI

	CALL	BFLNSET			; ベタファイル名セット

	MOV	DX,0001B		; vram plean select.
	CALL	VV_PLEAN_SLCT		; plean select.

	MOV	SI,OFFSET FLPLN0	; プレーン０ファイル名
	MOV	DI,0			; vram offset.
	MOV	DX,ARAVRM[0]		; vram segment.
	MOV	CX,PLEAN_LEN		; １プレーンのバイト数
	CALL	DSKLD			; file load.

	MOV	DX,0010B		; vram plean select.
	CALL	VV_PLEAN_SLCT		; plean select.

	MOV	SI,OFFSET FLPLN1	; プレーン１ファイル名
	MOV	DI,0			; vram offset.
	MOV	DX,ARAVRM[2]		; vram segment.
	MOV	CX,PLEAN_LEN		; １プレーンのバイト数
	CALL	DSKLD			; file load.

	MOV	DX,0100B		; vram plean select.
	CALL	VV_PLEAN_SLCT		; plean select.

	MOV	SI,OFFSET FLPLN2	; プレーン２ファイル名
	MOV	DI,0			; vram offset.
	MOV	DX,ARAVRM[4]		; vram segment.
	MOV	CX,PLEAN_LEN		; １プレーンのバイト数
	CALL	DSKLD			; file load.

	MOV	DX,1000B		; vram plean select.
	CALL	VV_PLEAN_SLCT		; plean select.

	MOV	SI,OFFSET FLPLN3	; プレーン３ファイル名
	MOV	DI,0			; vram offset.
	MOV	DX,ARAVRM[6]		; vram segment.
	MOV	CX,PLEAN_LEN		; １プレーンのバイト数
	CALL	DSKLD			; file load.

	POP	SI
	RET
LODBET	ENDP


;	ベタファイル名セット
;	-I- DS:SI : ファイル名

BFLNSET	PROC	NEAR
	PUSH	SI

	MOV	AX,DS
	MOV	ES,AX

	MOV	DI,OFFSET FLNAME	; ファイル名クリア
	MOV	CX,8
	MOV	AL,' '
	REP	STOSB

	MOV	DI,OFFSET FLNAME	; ファイル名
	MOV	CX,8
BFLNSET2:
	LODSB
	CMP	AL,' '			; end of string.
	JB	BFLNSET3		;
	STOSB
	LOOP	BFLNSET2
BFLNSET3:
	MOV	SI,OFFSET FLNAME	; ファイル名
	MOV	DI,OFFSET FLPLN0	; プレーン０ファイル名
	MOV	CX,8
	REP	MOVSB
	MOV	SI,OFFSET FLNAME	; ファイル名
	MOV	DI,OFFSET FLPLN1	; プレーン１ファイル名
	MOV	CX,8
	REP	MOVSB
	MOV	SI,OFFSET FLNAME	; ファイル名
	MOV	DI,OFFSET FLPLN2	; プレーン２ファイル名
	MOV	CX,8
	REP	MOVSB
	MOV	SI,OFFSET FLNAME	; ファイル名
	MOV	DI,OFFSET FLPLN3	; プレーン３ファイル名
	MOV	CX,8
	REP	MOVSB

	POP	SI
	RET
BFLNSET	ENDP

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

ARAVRM	LABEL	WORD		; vram area.
	DW	0A000H		; vram plean 0.
	DW	0A000H		; vram plean 1.
	DW	0A000H		; vram plean 2.
	DW	0A000H		; vram plean 3.

FLNAME	DB	"        ",0		; ファイル名
FLPLN0	DB	"        ","B1 ",0	; プレーン０ファイル名
FLPLN1	DB	"        ","R1 ",0	; プレーン１ファイル名
FLPLN2	DB	"        ","G1 ",0	; プレーン２ファイル名
FLPLN3	DB	"        ","E1 ",0	; プレーン３ファイル名

DATA	ENDS

	END
;
;	end of "VVDSKBET.ASM"
;
