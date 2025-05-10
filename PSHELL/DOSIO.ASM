; "DOSIO.ASM" PC-9801UV11 make by R.H 1989/11/04
;
;	E X E L O A D    D i s k   l i b r a l y .
;
;
;
; public subroutine.


INCLUDE	TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,ES:DATA


PUBLIC	FFOPEN			; ファイルオープン
PUBLIC	FFCLOS			; ファイルクローズ
PUBLIC	FFREAD			; ファイルの読み出し

PUBLIC	FFDRV			; カレントドライブ設定

EXTRN	SSRDRV:NEAR		; ドライブ番号の設定（０ー３）
EXTRN	SSRDNO:NEAR		; ドライブ番号の取得（０ー３）

EXTRN	SSRSRT:NEAR		; ファイルの先頭クラスタ番号の取り出し
EXTRN	SSRRED:NEAR		; クラスタの読み出し

FLALLLEN	EQU	32	; 指定ファイル名最大長さ


;	ファイルオープン
;	-I- DS:SI : ファイル名
;	-O- AX    : 0=正常, 1=該当ファイルがない, 2=ディスクエラー

FFOPEN	PROC	NEAR
	CALL	PATH_GET		; パス名／ファイル名ＧＥＴ

	MOV	AX,FLDRIVE		; ドライブ番号
	CALL	SSRDRV			; ドライブ番号の設定（０ー３）
	CMP	AX,2			; 0=正常, 2=ディスクエラー
	JE	FFOPEN_EXIT		;

	MOV	SI,OFFSET FLNAME	; 指定ファイル名
	CALL	SSRSRT			; ファイルの先頭クラスタ番号の取り出し
	MOV	NOWCLST,DX		; 現在のクラスタ番号

	MOV	FILE_LEN_LOW,CX		; ファイルの長さ
	MOV	FILE_LEN_HI,BX		; (long integer)

	MOV	FILE_PNT_LOW,CX		; 読み出しファイルの残りバイト数
	MOV	FILE_PNT_HI,BX		; (long integer)

	MOV	NOWCOUNT,0		; クラスタバッファ内の残りバイト数
	MOV	NEXT_EOF,0		; next E.O.F

FFOPEN_EXIT:				;
	RET				;
FFOPEN	ENDP


;
;	ファイルクローズ
;

FFCLOS	PROC	NEAR
	RET
FFCLOS	ENDP


;	ファイルの読み出し
;	-I- ES:DI    : データバッファのアドレス
;	    CX       : 読み込みデータのバイト数
;	-O- ES:[DI]  : データ
;	    DX       : 読み込み出来たバイト数
;	    AX       : 1=Ｅ．Ｏ．Ｆ（もう続きのデータは無い）
;		     : 2=ディスクエラー

FFREAD	PROC	NEAR
	PUSH	DI			;
	PUSH	CX			;

	CALL	BUFFCLAER		; es:[di]cx buffer 0 clear.

	CALL	FILE_LEN_CHECK		; ファイル長さチェック

	MOV	NOWBYTE_LEN,CX		; 指定バイト数
	MOV	NOWREAD_LEN,CX		; 読み出し残りバイト数

	CMP	AX,1			; 1=Ｅ．Ｏ．Ｆ
	JMPEQ	FFREAD99
	CMP	NOWBYTE_LEN,0		; data counter=0.
	JMPEQ	FFREAD9			; normal end.
	CMP	NEXT_EOF,1		; next E.O.F
	JMPEQ	FFREAD99		; E.O.F
	CMP	NOWCOUNT,0		; ｸﾗｽﾀバッファ内の残りバイト数
	JNE	FFREAD4			;

;	読み込みループスタート

FFREAD2:
	MOV	DX,NOWCLST		; 現在のクラスタ番号
	MOV	SI,OFFSET CLST_R_BUFF	;

	CALL	SSRRED			; クラスタの読み出し

	MOV	NOWCLST,DX		;
	CMP	AX,2			; 2=ディスクエラー
	JMPEQ	FFREAD_ERROR		;
	CMP	AX,1			; 1=E.O.F
	JMPEQ	FFREAD88		; E.O.F check.

	MOV	AX,CLST_R_LENGTH	; クラスタのバイト数
	MOV	NOWCOUNT,AX		;

FFREAD4:
	MOV	CX,NOWREAD_LEN		; 読み出し残りバイト数
	CMP	CX,NOWCOUNT		; バッファ内の残りバイト数
	JBE	FFREAD5			; バッファ内のデータで足りる？

	MOV	CX,NOWCOUNT		; バッファ内の残りバイト数
	MOV	SI,OFFSET CLST_R_BUFF	; 読みクラスタバッファ
	ADD	SI,CLST_R_LENGTH	; クラスタのバイト数
	SUB	SI,CX			;
	SUB	NOWREAD_LEN,CX		; 読み出し残りバイト数
	MOV	NOWCOUNT,0		; バッファ内の残りバイト数
	REP	MOVSB			; 転送

	JMP	FFREAD2			; 次のクラスタの読み込み

;	読み込みループ終わり

FFREAD5:
	MOV	CX,NOWREAD_LEN		; 読み出し残りバイト数
	MOV	SI,OFFSET CLST_R_BUFF	; 読みクラスタバッファ
	ADD	SI,CLST_R_LENGTH	; クラスタのバイト数
	SUB	SI,NOWCOUNT		;
	MOV	NOWREAD_LEN,0		; 読み出し残りバイト数
	SUB	NOWCOUNT,CX		; バッファ内の残りバイト数
	REP	MOVSB			; 転送

	JMP	FFREAD9			; 読み込み終わり
FFREAD88:
	MOV	CX,NOWBYTE_LEN		; 指定バイト数と
	CMP	CX,NOWREAD_LEN		; 読み出し残りバイト数が同じ？
	JE	FFREAD99		;  E.O.F
	CMP	NOWREAD_LEN,0		; 読み出し残りバイト数が余る？
	JNE	FFREAD999		;  next E.O.F

FFREAD9:
	MOV	AX,0			; normal.
	JMP	FFREAD_EXIT		;
FFREAD99:
	MOV	AX,1			; E.O.F
	JMP	FFREAD_EXIT		;
FFREAD999:
	MOV	AX,0			; normal.
	MOV	NEXT_EOF,1		; next E.O.F
	JMP	FFREAD_EXIT		;
FFREAD_ERROR:
	MOV	AX,2			; ディスクエラー
FFREAD_EXIT:
	MOV	DX,NOWBYTE_LEN		; 指定バイト数
	SUB	DX,NOWREAD_LEN		; 読み出し残りバイト数
	POP	CX			;
	POP	DI			;
	RET				;
FFREAD	ENDP


;	カレントドライブ設定
;	-I- AX     : １ＭＦＤドライブ番号
;	-O- FLCURT : カレントドライブ
;	-O- AX : 0=正常, 2=ディスクエラー

FFDRV	PROC	NEAR
;*DBG*;	PRV	"１ＭＦＤドライブ番号 AX=",AX
	MOV	FLCURT,AX		; カレントドライブ
	CALL	SSRDRV			; ドライブ番号の設定（０ー３）
	RET
FFDRV	ENDP


;
;	ファイル長さチェック
;	-I/O-  CX  : 読み出しバイト数
;	-O-    AX  : 0=正常, 1=Ｅ．Ｏ．Ｆ

FILE_LEN_CHECK	PROC	NEAR
	CMP	FILE_PNT_HI,0	; 読み出しファイルの残りバイト数(HI)
	JNE	FILE_LEN_CHECK5	;
	CMP	FILE_PNT_LOW,0	; 読み出しファイルの残りバイト数(LOW)
	JNE	FILE_LEN_CHECK2	;

	MOV	AX,1		; E.O.F
	RET

FILE_LEN_CHECK2:
	CMP	CX,FILE_PNT_LOW	; 読み出しバイト数と残りバイト数(LOW)
	JBE	FILE_LEN_CHECK5	; 読み出すバイト数が小さい？

	MOV	CX,FILE_PNT_LOW	; 残りの読み出しバイト数はこれだけ
FILE_LEN_CHECK5:
	SUB	FILE_PNT_LOW,CX	; 読み出しファイルの残りバイト数計算
	SBB	FILE_PNT_HI,0	; 
	MOV	AX,0		; normal.
	RET
FILE_LEN_CHECK	ENDP



;	バッファ０クリア
;	-I- ES:DI    : データバッファのアドレス
;	    CX       : 読み込みデータのバイト数

BUFFCLAER	PROC	NEAR
	PUSH	DI
	PUSH	CX

	MOV	AL,0
	REP	STOSB

	POP	CX
	POP	DI	
	RET
BUFFCLAER	ENDP


;	パス名／ファイル名ＧＥＴ
;	-I- DS:SI   : 指定ファイル名
;	-O- FLNAME  : 指定ファイル名
;	    FLPATH  : パス名
;	    FLDRIVE : ドライブ番号

PATH_GET	PROC	NEAR
	PUSH	ES			;
	PUSH	DI			;
	PUSH	SI			;
	PUSH	CX			;

	MOVX	ES,DS			;

	CMP	BYTE PTR DS:[SI][1],':'	; ドライブデリミタ
	JNE	PATH_GET_CUR		;

	MOV	AX,DS:[SI]		; ドライブ  "A:", "B:", "C:", "D:"
	MOV	WORD PTR FLPATH,AX	; パス名
	SUB	AL,'A'			; 0 <- 'A', 1 <- 'B', 2 <- 'C' 
	MOV	BYTE PTR FLDRIVE,AL	; ドライブ番号

	INC	SI			;
	INC	SI			;

	MOV	DI,OFFSET FLNAME	; 指定ファイル名
	MOV	CX,FLALLLEN		; 指定ファイル名最大長さ
	REP	MOVSB			;

PATH_GET_EXIT:				;
	POP	CX			;
	POP	SI			;
	POP	DI			;
	POP	ES			;
	RET
PATH_GET_CUR:				;
	MOV	AX,FLCURT		; カレントドライブ
	MOV	FLDRIVE,AX		; ドライブ番号
	MOV	FLPATH,' '		; パス名
	MOV	FLPATH[1],' '		;

	MOV	DI,OFFSET FLNAME	; 指定ファイル名
	MOV	CX,FLALLLEN		; 指定ファイル名最大長さ
	REP	MOVSB			;

	POP	CX			;
	POP	SI			;
	POP	DI			;
	POP	ES			;
	RET
PATH_GET	ENDP

CODE	ENDS



DATA	SEGMENT	PUBLIC	'DATA'

PUBLIC	FLCURT				; カレントドライブ

EXTRN	CLST_R_BUFF:BYTE		; 読みクラスタバッファ
EXTRN	CLST_R_BUFF_END:BYTE		; 読みクラスタバッファの後ろ
EXTRN	CLST_R_LENGTH:WORD		; 読みクラスタバイト数

NEXT_EOF	DW	0	; next E.O.F=1

NOWCLST		DW	0	; 現在のクラスタ番号

NOWCOUNT	DW	0	; クラスタバッファ内の残りバイト数

NOWBYTE_LEN	DW	0	; 指定バイト数

NOWREAD_LEN	DW	0	; 読み出し残りバイト数

FILE_LEN_LOW	DW	0	; ファイルの長さ
FILE_LEN_HI	DW	0	; (long integer)

FILE_PNT_LOW	DW	0	; 読み出しファイルの残りバイト数
FILE_PNT_HI	DW	0	; (long integer)


FLCURT		DW	0			; カレントドライブ
FLDRIVE		DW	0			; ドライブ番号
FLPATH		DB	"  ",0,0		; パス名

FLNAME		DB	FLALLLEN DUP (' ')	; 指定ファイル名
		DB	0,0			;

DATA	ENDS
	END
;
;	end of "DOSIO.ASM"
;
