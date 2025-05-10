; "DKLDSV.ASM" PC-9801UV11 make by R.H 1991/06/19
;
;
;	disk load.
;
;
; public subroutine.

INCLUDE	TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA

PUBLIC	DSKLD			; file load.

EXTRN	FFOPEN:NEAR		; ファイルオープン
EXTRN	FFCLOS:NEAR		; ファイルクローズ
EXTRN	FFREAD:NEAR		; ファイルの読み出し

PATH_LENGTH	EQU	20;128		; path line length.


;	file load.
;	-i- SI : file name.
;		NULL = end of string.
;	    DX : dest segment address.
;	    DI : dest offset  address.
;	    CX : data length.
;
;	-o- AX : 0:normal.
;	         1:error.

DSKLD	PROC	NEAR
	MOV	DEST_SEG,DX		; dest segment address.
	MOV	DEST_OFS,DI		; dest offset  address.
	MOV	DEST_LEN,CX		; data length.

	CALL	FNSET			; file name set.
	MOV	SI,OFFSET PATH_LINE	; path name line.

	CALL	FFOPEN			; ファイルオープン
	CMP	AX,0			; 0=正常, 1=該当ファイルがない
					; 2=ディスクエラー
	JNE	DSKLD_EXIT

	MOV	ES,DEST_SEG		; dest segment address.
	MOV	DI,DEST_OFS		; dest offset  address.
	MOV	CX,DEST_LEN		; data length.
	CALL	FFREAD			; ファイルの読み出し
	CMP	AX,0			;1=Ｅ．Ｏ．Ｆ（もう続きのデータは無い）
					;2=ディスクエラー
	JNE	DSKLD_EXIT		;

	CALL	FFCLOS			; ファイルクローズ

	MOV	AX,0			; 0:normal.
	RET
DSKLD_EXIT:
	PRF	"read error."

	MOV	AX,1			; 1:error.
	RET
DSKLD	ENDP


;	file name set.
;	-I- SI :file name.

FNSET	PROC	NEAR
	PUSH	DS
	PUSH	ES
	PUSH	SI

	PUSH	DI
	PUSH	DX
	PUSH	CX

	; path line clear.

	MOV	AX,DS			;
	MOV	ES,AX			;
	MOV	DI,OFFSET PATH_LINE	; path name line.
	MOV	CX,PATH_LENGTH		; path line length.
	MOV	AL,0			;
	REP	STOSB			;

	; length check.

	MOV	AX,DS			;
	MOV	ES,AX			;
	MOV	DI,SI			; path name line.
	MOV	CX,PATH_LENGTH		; path line length.
	MOV	AL,0			;
	REPNE	SCASB			;
	MOV	CX,DI			;
	SUB	CX,SI			; CX=string length.

	PUSH	CX			;

	MOV	AX,DS			; copy string to path_line.
	MOV	ES,AX			; data segment.
	MOV	DI,OFFSET PATH_LINE	; path name line.
	REP	MOVSB			;

	POP	CX			;

	MOV	DI,OFFSET PATH_LINE	; path name line.
	MOV	AL,' '			; space.
	REPNE	SCASB			;
	JNE	FNSET_9			;

	; "ABC     TXT" -> "ABC.TXT",0

	MOV	ES:[DI][-1],BYTE PTR '.'

	MOV	SI,DI			;

	MOV	AL,' '			; space.
	REPE	SCASB			;
	JE	FNSET_9			;

	DEC	DI			;
	INC	CX			;

	XCHG	SI,DI			;
	REP	MOVSB			;

FNSET_9:
	POP	CX
	POP	DX
	POP	DI
	POP	SI
	POP	ES
	POP	DS
	RET
FNSET	ENDP


CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

DEST_SEG	DW	0		; dest segment address.
DEST_OFS	DW	0		; dest offset  address.
DEST_LEN	DW	0		; data length.

PATH_LINE	DB	20 DUP (0)	; path name line.

DATA	ENDS

	END
;
;	end of "DKLDSV.ASM"
;
