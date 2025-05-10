; "CODSYS.ASM" PS55Z/J14 make by R.H/japan 1991/06/13
;
;
;	E X E L O A D    I P L   k i t .
;
;	s y s t e m    c o d e .
;
;
; code data.

CODSYS	SEGMENT	PUBLIC	'CODSYS'

	ASSUME	CS:CODSYS,DS:CODSYS,ES:CODSYS

PUBLIC	SYSTOP				; system code top.
PUBLIC	SYSEND				; system code end.

;	system source code.

SYSTOP	LABEL	FAR			; system code top.

;	calling sequence.
;
;		JMP	DWORD PTR START_ADDRESS
;	START_ADDRESS	LABEL	DWORD		; start address.
;	LOAD_OFSET	DW	0		; system load offset.
;	LOAD_SEG	DW	1000H		; system load segment.
;
;	parameter.
;
;	-I- DX : current drive number.(0-3)
;	    BX : current drive media type.
;		1=360KB
;		2=1.2MB
;		3=720KB
;		4=1.44MB
;
;****************************************************************
;*	E X E L O A D						*
;****************************************************************

EXELOAD_TOP_SEG	EQU	800H		; このシステムの先頭セグメント
STACK_SIZE	EQU	100		; stack size.

DISPLY_MODE	EQU	2		; disply mode set.(0:40x25,2:80x25)
					; (6:grp640x200)
DISPLY_LIN_MAX	EQU	24		; disply line max.
DISPLY_CLM_MAX	EQU	79		; disply colum nax.

TEXT_ATTR	EQU	1111B		; text attrbute.

CHR_LF		EQU	0AH		; LF.

SEC_BYTE	EQU	512		; sector length.

PRF	MACRO	STRING
	LOCAL	L1,L2
	PUSH	SI
	JMP	L2
L1	DB	STRING,0
L2:	MOV	SI,OFFSET L1
	CALL	PRINT
	CALL	LFPRN
	POP	SI
	ENDM

PRVH	MACRO	STRING,VALUE
	LOCAL	L1,L2
	PUSH	DX
	PUSH	SI
	JMP	L2
L1	DB	STRING,0
L2:
	PUSH	SI
	MOV	SI,OFFSET L1
	CALL	PRINT
	POP	SI
	MOV	DX,VALUE
	CALL	HEXSTR
	CALL	PRINT
	CALL	LFPRN
	POP	SI
	POP	DX
	ENDM

LC	MACRO	XX,YY
	PUSH	AX
	PUSH	BX
	MOV	LOCX,XX
	MOV	LOCY,YY
	CALL	COULOC		; locate.
	POP	BX
	POP	AX
	ENDM

;****************************************************************
;*	E X E L O A D						*
;****************************************************************

EXELOAD:
	MOV	AX,CS			;
	MOV	DS,AX			;
	MOV	ES,AX			;
	MOV	RDF_CHASH_SEG,AX	; キャッシュバッファセグメント
	MOV	MPT_TABLE_SEG,AX	; ＭＰＴテーブルセグメント

	CLI				; for i8088
	MOV	AX,CS			; stack segment.
	MOV	SS,AX			; stack segment.
	MOV	SP,OFFSET STACK_TOP	; stack top.
	STI				; for i8088

	MOV	CUR_DRIVE_NUM,DX	; current drive number.
	MOV	CUR_DRIVE_MEDIA,BX	; current drive media type.
	MOV	LOAD_DRIVE,DX		; ロードドライブ番号

	CALL	TEXT_INIT		; text init.

	MOV	SI,OFFSET MESSAGE_TOP	; message.
	CALL	PRINT			; print of string.

	CALL	ALOC_LOAD_SEG		; ロードセグメントの決定

	CALL	ALOC_SYS_SEG		; システム入れ換えセグメントの決定

;*;	PRVH	"DS=",DS
;*;	PRVH	"LOAD_SEGMENT   =",LOAD_SEGMENT
;*;	PRVH	"LOADSYS_SEGMENT=",LOADSYS_SEGMENT
;*;	PRVH	"SYSEND_ALL=",<OFFSET SYSEND_ALL>
;*;
;*;	PRVH	"CUR_DRIVE_NUM=",CUR_DRIVE_NUM
;*;	PRVH	"CUR_DRIVE_MEDIA=",CUR_DRIVE_MEDIA

	CALL	SSMSRT			; ドライブ・モード・スタート

	MOV	DX,CUR_DRIVE_MEDIA	; current drive media type.
	CALL	SSMMDE			; ドライブ・モード標準設定

	CALL	SSRINI			; ドライブ初期処理

	MOV	AX,CUR_DRIVE_NUM	; current drive number.
	CALL	FFDRV			; カレントドライブ設定

;*;	PRVH	"FFDRV AX=",AX

	CALL	SYSSTART		; ＰＳＨＥＬＬ．ＥＸＥの実行

	CALL	EXESTART		; ＡＵＴＯＥＸＥＣ．ＥＸＥの実行

	MOV	SI,OFFSET MESSAGE_ERROR	; error message.
	CALL	PRINT			; print of string.

BLACK_HOLE:				; program end.
	JMP	BLACK_HOLE		;


;****************************************************************
;*	E X E L O A D						*
;****************************************************************

		EVEN
		DW	STACK_SIZE DUP (0)
STACK_TOP	LABEL	WORD		; stack top.

CUR_DRIVE_NUM	DW	0	; current drive number.
CUR_DRIVE_MEDIA	DW	0	; current drive media type.
LOAD_DRIVE	DW	0	; ロードドライブ番号


;****************************************************************
;*	E X E L O A D						*
;****************************************************************

MOVX	MACRO	DEST,SOU
	MOV	AX,SOU
	MOV	DEST,AX
	ENDM
MOVXB	MACRO	DEST,SOU
	MOV	AL,SOU
	MOV	DEST,AL
	ENDM
CMPX	MACRO	DEST,SOU
	MOV	AX,SOU
	CMP	DEST,AX
	ENDM
ADDX	MACRO	DEST,SOU
	MOV	AX,SOU
	ADD	DEST,AX
	ENDM
SUBX	MACRO	DEST,SOU
	MOV	AX,SOU
	SUB	DEST,AX
	ENDM
JMPEQ	MACRO	LBL
	LOCAL	L1
	JNE	L1
	JMP	LBL
L1:
	ENDM
JMPL	MACRO	LBL
	LOCAL	L1
	JGE	L1
	JMP	LBL
L1:
	ENDM
JMPG	MACRO	LBL
	LOCAL	L1
	JLE	L1
	JMP	LBL
L1:
	ENDM


;****************************************************************
;*	E X E L O A D						*
;****************************************************************


;	標準ＤＯＳ用プロセスの実行
;	-I- TOP_LOAD_SEG  : ロード時先頭セグメントアドレス
;	    TOP_RELOC_SEG : リロケート時先頭セグメントアドレス
;	    PROC_SIZE_LOW : 標準ＤＯＳ実行ファイルのサイズ(LOW)
;	    PROC_SIZE_HI  : 標準ＤＯＳ実行ファイルのサイズ(HI)

EXEC_PROCESS	PROC	NEAR

	;	コード転送

	MOV	AX,TOP_LOAD_SEG		; ロード時先頭セグメントアドレス
	CMP	AX,TOP_RELOC_SEG	; リロケート時先頭セグメントアドレス
	JE	EXEC_PROCESS_SET	;

	MOV	CX,PROC_SIZE_HI		; 標準ＤＯＳ実行ファイルのサイズ(HI)
	JCXZ	EXEC_PROCESS_2		;
	PUSH	DS			;
	MOV	ES,TOP_RELOC_SEG	; リロケート時先頭セグメントアドレス
	MOV	AX,TOP_LOAD_SEG		; ロード時先頭セグメントアドレス
	MOV	DS,AX			;
EXEC_PROCESS_1:				;
	PUSH	CX			;
	MOV	CX,8000H		;
	REP	MOVSW			;
	MOV	AX,ES			;
	ADD	AX,1000H		;
	MOV	ES,AX			;
	MOV	AX,DS			;
	ADD	AX,1000H		;
	MOV	DS,AX			;
	POP	CX			;
	LOOP	EXEC_PROCESS_1		;
	POP	DS			;

EXEC_PROCESS_2:				;
	PUSH	DS			;
	MOV	SI,0			;
	MOV	DI,0			;
	MOV	CX,PROC_SIZE_LOW	; 標準ＤＯＳ実行ファイルのサイズ(LOW)
	MOV	ES,TOP_RELOC_SEG	; リロケート時先頭セグメントアドレス
	MOV	AX,TOP_LOAD_SEG		; ロード時先頭セグメントアドレス
	MOV	DS,AX			;
	REP	MOVSB			;
	POP	DS			;


	;	各ポインタ設定

EXEC_PROCESS_SET:			;
	MOV	AX,SS			;
	MOV	EXE_SAVE_SS,AX		;
	MOV	AX,SP			;
	MOV	EXE_SAVE_SP,AX		;

	CLI				; 割り込み禁止

	MOV	AX,TOP_RELOC_SEG	; リロケート時先頭セグメントアドレス
	ADD	AX,EXE_SS		; スタックセグメン（ＳＳ）初期値
	MOV	SS,AX			;

	MOV	AX,EXE_SP		; スタックポインタ（ＳＰ）初期値
	MOV	SP,AX			;

	MOV	AX,TOP_RELOC_SEG	; リロケート時先頭セグメントアドレス
	ADD	AX,EXE_CS		; コードセグメント（ＣＳ）の初期値
	MOV	START_SEG,AX		; スタートセグメントアドレス

	MOV	AX,EXE_IP	; インストラクションポインタ（ＩＰ）の初期値
	MOV	START_OFFSET,AX	; スタートオフセットアドレス


	;	実行コードへジャンプ

	STI				; 割り込み許可
	JMP	DWORD PTR START_ADDRESS	; スタートアドレス

EXEC_PROCESS	ENDP



EXE_SAVE_SS	DW 0	; スタックセグメント退避
EXE_SAVE_SP	DW 0	; スタックポインタ退避

EXE_MARK	DW 0	; ４Ｄｈ，５Ａｈマーク（標準ＤＯＳ）
EXE_END_BYTE	DW 0	; 最終ページ（512byte単位）の有効バイト数
EXE_PAGE	DW 0	; ページ数（512byte単位）
EXE_RELOC_CNT	DW 0	; リロケートの計算を必要とするアドﾚｽ値の個数
EXE_HEAD_SIZE	DW 0	; ヘッダの大きさ（パラグラフ数／16byte単位）
EXE_HEEP_MIN	DW 0	; ヒープエリアの最小数
EXE_HEEP_MAX	DW 0	; ヒープエリアの最大数
EXE_SS		DW 0	; スタックセグメント（ＳＳ）初期値
EXE_SP		DW 0	; スタックポインタ（ＳＰ）初期値
EXE_SUM		DW 0	; チェックサム
EXE_IP		DW 0	; インストラクションポインタ（ＩＰ）の初期値
EXE_CS		DW 0	; コードセグメント（ＣＳ）の初期値
EXE_RELOC_OFSET	DW 0	; リロケーション情報のオフセット
EXE_OVERLAY_NUM	DW 0	; 標準ＤＯＳオーバレイ番号


LOAD_SEG	DW 0	; 標準ＤＯＳ実行ファイルのロードアドレス先頭
RELOC_SEG	DW 0	; 標準ＤＯＳ実行ファイルのリロケートアドレス先頭

TOP_LOAD_SEG	DW 0	; ロード時先頭セグメントアドレス
TOP_RELOC_SEG	DW 0	; リロケート時先頭セグメントアドレス

PROC_SIZE	LABEL	DWORD ; 標準ＤＯＳ実行ファイルのサイズ
PROC_SIZE_LOW	DW 0	; 標準ＤＯＳ実行ファイルのサイズ(LOW)
PROC_SIZE_HI	DW 0	; 標準ＤＯＳ実行ファイルのサイズ(HI)

START_ADDRESS	LABEL	DWORD	; スタートアドレス
START_OFFSET	DW 0	; スタートオフセットアドレス
START_SEG	DW 0	; スタートセグメントアドレス



;	もし新システムへの入れ換えが行われるならば
;	ここから先のエリアは、切り放されます。（オーバライト）

SYSNEW_LOAD_START	LABEL	BYTE	; 新システムのロードアドレス



LOAD_SEGMENT	DW	0		; ロードセグメント
LOADSYS_SEGMENT	DW	0		; ロード新システムセグメント

SYS_FILE_NAME	DB	"PSHELL.EXE",0		; ＳＹＳＴＥＭファイル名
EXE_FILE_NAME	DB	"AUTOEXEC.EXE",0	; 実行ファイル名

;	システム入れ換えセグメントの決定
;	-O- LOADSYS_SEGMENT : ロード新システムセグメント

ALOC_SYS_SEG	PROC	NEAR
	MOV	BX,OFFSET SYSNEW_LOAD_START	; 新システムのロードアドレス
	SUB	BX,OFFSET SYSTOP		; システムの先頭
	INC	BX			;
	MOV	AX,BX			;
	SHR	BX,1			; / 16
	SHR	BX,1			;
	SHR	BX,1			;
	SHR	BX,1			;
	AND	AX,0FH			;
	JZ	ALOC_SYS_SEG2		;
	INC	BX			;
ALOC_SYS_SEG2:				; この値がこのシステムの
					; パラグラフサイズ

	ADD	BX,EXELOAD_TOP_SEG	; このシステムの先頭セグメント
	MOV	LOADSYS_SEGMENT,BX	; ロード新システムセグメント
	RET
ALOC_SYS_SEG	ENDP


;	ロードセグメントの決定
;	-O- LOAD_SEGMENT : ロードセグメント

ALOC_LOAD_SEG	PROC	NEAR
	MOV	BX,OFFSET SYSEND_ALL	; システムの終わり（バッファ含む）
	SUB	BX,OFFSET SYSTOP	; システムの先頭
	INC	BX			;
	MOV	AX,BX			;
	SHR	BX,1			; / 16
	SHR	BX,1			;
	SHR	BX,1			;
	SHR	BX,1			;
	AND	AX,0FH			;
	JZ	ALOC_LOAD_SEG2		;
	INC	BX			;
ALOC_LOAD_SEG2:				; この値がこのシステムの
					; パラグラフサイズ

	ADD	BX,EXELOAD_TOP_SEG	; このシステムの先頭セグメント
	MOV	LOAD_SEGMENT,BX		; ロードセグメント
	RET
ALOC_LOAD_SEG	ENDP


;	ＰＳＨＥＬＬ．ＥＸＥの実行

SYSSTART	PROC	NEAR
	CALL	SRTDRV			; 立ち上がりドライブ番号の設定
	CMP	AX,0			; 0=正常, 2=ディスクエラー
	JNE	SYSSTART_EXIT

	MOV	SI,OFFSET SYS_FILE_NAME	; ＳＹＳＴＥＭファイル名
	MOV	AX,LOAD_SEGMENT		; ロードセグメント
	MOV	ES,AX			; フリーエリアの開始位置
	CALL	CMLOAD			; ＬＯＡＤ

	CMP	AX,0			; 0=正常
	JNE	SYSSTART_EXIT		; 1=該当ファイル無し, 2=ディスクエラー

	MOV	AX,DX			; 読み込みファイル長さ(HI)
					; AX:CX 実行ファイルのサイズ
	MOV	DX,LOAD_SEGMENT 	; 実行ファイルのロードアドレス
	MOV	BX,LOADSYS_SEGMENT	; 実行ファイルのリロケートアドレス
	CALL	CMPROC			; 標準ＤＯＳプロセス

SYSSTART_EXIT:
	RET
SYSSTART	ENDP


;	ＡＵＴＯＥＸＥＣ．ＥＸＥの実行

EXESTART	PROC	NEAR
	CALL	SRTDRV			; 立ち上がりドライブ番号の設定
	CMP	AX,0			; 0=正常, 2=ディスクエラー
	JNE	EXESTART_EXIT

	MOV	SI,OFFSET EXE_FILE_NAME	; 実行ファイル名
	MOV	AX,LOAD_SEGMENT		; ロードセグメント
	MOV	ES,AX			; フリーエリアの開始位置
	CALL	CMLOAD			; ＬＯＡＤ

	CMP	AX,0			; 0=正常
	JNE	EXESTART_EXIT		; 1=該当ファイル無し, 2=ディスクエラー

	MOV	AX,DX			; 読み込みファイル長さ(HI)
					; AX:CX 実行ファイルのサイズ
	MOV	DX,LOAD_SEGMENT 	; 実行ファイルのロードアドレス
	MOV	BX,LOAD_SEGMENT		; 実行ファイルのリロケートアドレス
	CALL	CMPROC			; 標準ＤＯＳプロセス

EXESTART_EXIT:
	RET
EXESTART	ENDP


;	立ち上がりドライブ番号の設定
;	-O- AX : 0=正常, 2=ディスクエラー

SRTDRV	PROC	NEAR
	MOV	AX,LOAD_DRIVE		; ロードドライブ番号
	CALL	SSRDRV			; ドライブ番号の設定（０ー３）
	RET
SRTDRV	ENDP

;****************************************************************
;*	E X E L O A D						*
;****************************************************************

; "SSPROC.ASM" PC-9801UV11 make by R.H 1989/11/23
;
;	E X E L O A D     P R O C   c o m m a n d .
;
;
;
; command.

;***;	CODE	SEGMENT	PUBLIC	'CODE'
;***;	
;***;		ASSUME	CS:CODE,DS:DATA,ES:DATA
;***;	
;***;	PUBLIC	CMPROC		; 標準ＤＯＳプロセス
;***;	

;	標準ＤＯＳプロセス
;	-I- DX    : 標準ＤＯＳ実行ファイルのロードアドレス先頭
;	    BX    : 標準ＤＯＳ実行ファイルのリロケートアドレス先頭
;	    AX:CX : 標準ＤＯＳ実行ファイルのサイズ
;	別のセグメントでリロケート処理をして、実行直前に実行セグメント
;	へコピーするように変更しました。これでＥＸＥＬＯＡＤ本体を
;	実行エリアに使用することが可能になる。

CMPROC	PROC	NEAR
	MOV	LOAD_SEG,DX  ; 標準ＤＯＳ実行ファイルのロードアドレス先頭
	MOV	RELOC_SEG,BX ; 標準ＤＯＳ実行ファイルのリロケートアドレス先頭
	MOV	PROC_SIZE_LOW,CX ; 標準ＤＯＳ実行ファイルのサイズ(LOW)
	MOV	PROC_SIZE_HI,AX  ; 標準ＤＯＳ実行ファイルのサイズ(HI)

;*;	PRVH	"LOAD_SEG     =",LOAD_SEG
;*;	PRVH	"RELOC_SEG    =",RELOC_SEG
;*;	PRVH	"PROC_SIZE_LOW=",PROC_SIZE_LOW
;*;	PRVH	"PROC_SIZE_HI =",PROC_SIZE_HI

	CALL	PARASET      ; 標準ＤＯＳプロセスパラメータセット
	CALL	EXEC_RELOC   ; 標準ＤＯＳ実行ファイルのリロケーション
	CALL	EXEC_PROCESS ; 標準ＤＯＳ用プロセスの実行
	RET
CMPROC	ENDP


;	標準ＤＯＳ実行ファイルのリロケーション
;	-I- LOAD_SEG  : 標準ＤＯＳ実行ファイルのロードアドレス先頭
;	    RELOC_SEG : 標準ＤＯＳ実行ファイルのリロケートアドレス先頭
;	-O- TOP_SEG   : 先頭セグメントアドレス
;	    TOP_LOAD_SEG  : ロード時先頭セグメントアドレス
;	    TOP_RELOC_SEG : リロケート時先頭セグメントアドレス

EXEC_RELOC	PROC	NEAR

			; 標準ＤＯＳ実行ファイルのロードアドレス先頭
	MOV	AX,LOAD_SEG
			; ヘッダの大きさ（パラグラフ数／16byte単位）
	ADD	AX,EXE_HEAD_SIZE
			; ロード時先頭セグメントアドレス
	MOV	TOP_LOAD_SEG,AX


			; 標準ＤＯＳ実行ファイルのリロケートアドレス先頭
	MOV	AX,RELOC_SEG
			; ヘッダの大きさ（パラグラフ数／16byte単位）
	ADD	AX,EXE_HEAD_SIZE
			; リロケート時先頭セグメントアドレス
	MOV	TOP_RELOC_SEG,AX


			; リロケーション情報のオフセット
	MOV	BX,EXE_RELOC_OFSET
			; リロケートの計算を必要とするアドﾚｽ値の個数
	MOV	CX,EXE_RELOC_CNT
	JCXZ	EXEC_RELOC_SKIP
EXEC_RELOC2:
			; 標準ＤＯＳ実行ファイルのロードアドレス先頭
	MOV	AX,LOAD_SEG
	MOV	ES,AX

	MOV	DI,ES:[BX] ; リロケート対象のアドレス（オフセット）
	INC	BX
	INC	BX
	MOV	AX,ES:[BX]	; リロケート対象のアドレス（セグメント）
	ADD	AX,TOP_LOAD_SEG	; ロード時先頭セグメントアドレス
	MOV	ES,AX
	INC	BX
	INC	BX

	MOV	AX,TOP_RELOC_SEG ; リロケート時先頭セグメントアドレス
	ADD	ES:[DI],AX

	LOOP	EXEC_RELOC2
EXEC_RELOC_SKIP:

	RET
EXEC_RELOC	ENDP


;	標準ＤＯＳプロセスパラメータセット
;	-I- LOAD_SEG ; 標準ＤＯＳ実行ファイルのロードアドレス先頭

PARASET	PROC	NEAR
	MOV	AX,LOAD_SEG
	MOV	ES,AX
	MOV	SI,0

	MOV	AX,WORD PTR ES:[SI][00H]
	MOV	EXE_MARK,AX	; ４Ｄｈ，５Ａｈマーク（標準ＤＯＳ）
	MOV	AX,WORD PTR ES:[SI][02H]
	MOV	EXE_END_BYTE,AX	; 最終ページ（512byte単位）の有効バイト数
	MOV	AX,WORD PTR ES:[SI][04H]
	MOV	EXE_PAGE,AX	; ページ数（512byte単位）
	MOV	AX,WORD PTR ES:[SI][06H]
	MOV	EXE_RELOC_CNT,AX ; リロケートの計算を必要とするアドﾚｽ値の個数
	MOV	AX,WORD PTR ES:[SI][08H]
	MOV	EXE_HEAD_SIZE,AX ; ヘッダの大きさ（パラグラフ数／16byte単位）
	MOV	AX,WORD PTR ES:[SI][0AH]
	MOV	EXE_HEEP_MIN,AX	; ヒープエリアの最小数
	MOV	AX,WORD PTR ES:[SI][0CH]
	MOV	EXE_HEEP_MAX,AX	; ヒープエリアの最大数
	MOV	AX,WORD PTR ES:[SI][0EH]
	MOV	EXE_SS,AX	; スタックセグメント（ＳＳ）初期値
	MOV	AX,WORD PTR ES:[SI][10H]
	MOV	EXE_SP,AX	; スタックポインタ（ＳＰ）初期値
	MOV	AX,WORD PTR ES:[SI][12H]
	MOV	EXE_SUM,AX	; チェックサム
	MOV	AX,WORD PTR ES:[SI][14H]
	MOV	EXE_IP,AX	; インストラクションポインタ（ＩＰ）の初期値
	MOV	AX,WORD PTR ES:[SI][16H]
	MOV	EXE_CS,AX	; コードセグメント（ＣＳ）の初期値
	MOV	AX,WORD PTR ES:[SI][18H]
	MOV	EXE_RELOC_OFSET,AX ; リロケーション情報のオフセット
	MOV	AX,WORD PTR ES:[SI][1AH]
	MOV	EXE_OVERLAY_NUM,AX ; 標準ＤＯＳオーバレイ番号
	RET
PARASET	ENDP


;***;	
;***;	CODE	ENDS
;***;	
;***;	
;***;	DATA	SEGMENT	PUBLIC	'DATA'
;***;
;***;	DATA	ENDS
;***;		END
;
;	end of "SSPROC.ASM"
;


;****************************************************************
;*	E X E L O A D						*
;****************************************************************

; "SSLOAD.ASM" PC-9801UV11 make by R.H 1989/11/10
;
;	E X E L O A D     L O A D    c o m m a n d .
;
;
;
; command.

;***;	CODE	SEGMENT	PUBLIC	'CODE'
;***;	
;***;		ASSUME	CS:CODE,DS:DATA,ES:DATA
;***;	
;***;	PUBLIC	CMLOAD			; ＬＯＡＤ
;***;	
;***;	EXTRN	FFOPEN:NEAR		; ファイルオープン
;***;	EXTRN	FFCLOS:NEAR		; ファイルクローズ
;***;	EXTRN	FFREAD:NEAR		; ファイルの読み出し
;***;	EXTRN	PRINT:NEAR		; 文字列の表示
;***;	EXTRN	KESCAP:NEAR		; ESC key & break check & pause.
;***;	
;***;	EXTRN	HEXSTR:NEAR		; DX -> hex string.

READ_PARAGRAPH	EQU	32	; read paragraph length.
READ_LEN	EQU	16*32	; read length.
CHR_CR		EQU	0DH	; calig return.
CHR_LF		EQU	0AH	; line feed.


;
;	ＬＯＡＤ
;	-I- DS:SI : ファイル名
;	    ES    : フリーエリアの開始位置（パラグラフ値）
;	-O- CX    : 読み込みファイル長さ(LOW)
;	    DX    : 読み込みファイル長さ(HI)
;	    AX    : 0=正常, 1=該当ファイル無し, 2=ディスクエラー

CMLOAD	PROC	NEAR
	CALL	FFOPEN			; ファイルオープン
	CMP	AX,1			; file not found.
	JMPEQ	CMLOAD99		;
	CMP	AX,2			; ディスクエラー
	JMPEQ	CMLOAD_ERR_OPEN		;

	MOV	LOAD_LEN_LOW,0		; 読み込みファイル長さ(LOW)
	MOV	LOAD_LEN_HI,0		; 読み込みファイル長さ(HI)

	MOV	DI,0			; load memory area offset = 0 + ES*16
CMLOAD2:
	MOV	CX,READ_LEN		; read length.
	CALL	FFREAD			; ファイルの読み出し
	CMP	AX,2			; ディスクエラー
	JE	CMLOAD_ERROR		;
	CMP	AX,1			; E.O.F
	JE	CMLOAD8			;

	ADD	LOAD_LEN_LOW,DX		; 読み込みファイル長さ(LOW)
	ADC	LOAD_LEN_HI,0		; 読み込みファイル長さ(HI)

	MOV	AX,ES			;
	ADD	AX,READ_PARAGRAPH	; read paragraph length.
	MOV	ES,AX			;

	JMP	CMLOAD2
CMLOAD8:	
	CALL	FFCLOS			; ファイルクローズ

	MOV	CX,LOAD_LEN_LOW		; 読み込みファイル長さ(LOW)
	MOV	DX,LOAD_LEN_HI		; 読み込みファイル長さ(HI)

	MOV	SI,OFFSET MSG_MARK	; Ｅ．Ｏ．Ｆマーク
	CALL	PRINT			;
	MOV	AX,0			; normal.
	RET

CMLOAD99:
	MOV	AX,1			; file not found.
	RET
CMLOAD_ERROR:
	MOV	SI,OFFSET MSG_DISK_ERROR
	CALL	PRINT			;
	MOV	AX,2			; ディスクエラー
	RET
CMLOAD_ERR_OPEN:
	MOV	SI,OFFSET MSG_OPEN_ERROR
	CALL	PRINT			;
	MOV	AX,2			; ディスクエラー
	RET
CMLOAD	ENDP

;***;	CODE	ENDS
;***;	
;***;	
;***;	DATA	SEGMENT	PUBLIC	'DATA'

		EVEN
LOAD_LEN	LABEL	DWORD		; 読み込みファイル長さ
LOAD_LEN_LOW	DW	0		; 読み込みファイル長さ(LOW)
LOAD_LEN_HI	DW	0		; 読み込みファイル長さ(HI)

MSG_MARK	DB	"OK.",CHR_LF,0	; Ｅ．Ｏ．Ｆマーク

MSG_DISK_ERROR	DB	CHR_LF,CHR_LF,CHR_LF,CHR_LF,CHR_LF
		DB	"disk error.",CHR_LF,0
MSG_OPEN_ERROR	DB	CHR_LF,CHR_LF,CHR_LF,CHR_LF,CHR_LF,CHR_LF
		DB	"open error.",CHR_LF,0

;***;	DATA	ENDS
;***;		END
;
;	end of "SSLOAD.ASM"
;


;****************************************************************
;*	E X E L O A D						*
;****************************************************************

;*;; "DOSIO.ASM" PC-9801UV11 make by R.H 1989/11/04
;*;;
;*;;	E X E L O A D    D i s k   l i b r a l y .
;*;;
;*;;
;*;;
;*;; public subroutine.
;*;
;*;
;*;INCLUDE	TSTSET.INC
;*;
;*;CODE	SEGMENT	PUBLIC	'CODE'
;*;
;*;	ASSUME	CS:CODE,DS:DATA,ES:DATA
;*;
;*;
;*;PUBLIC	FFOPEN			; ファイルオープン
;*;PUBLIC	FFCLOS			; ファイルクローズ
;*;PUBLIC	FFREAD			; ファイルの読み出し
;*;
;*;PUBLIC	FFDRV			; カレントドライブ設定
;*;
;*;EXTRN	SSRDRV:NEAR		; ドライブ番号の設定（０ー３）
;*;EXTRN	SSRDNO:NEAR		; ドライブ番号の取得（０ー３）
;*;
;*;EXTRN	SSRSRT:NEAR		; ファイルの先頭クラスタ番号の取り出し
;*;EXTRN	SSRRED:NEAR		; クラスタの読み出し

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

	MOV	SI,OFFSET FFLNAME	; 指定ファイル名
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
;	-O- FFLNAME  : 指定ファイル名
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

	MOV	DI,OFFSET FFLNAME	; 指定ファイル名
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

	MOV	DI,OFFSET FFLNAME	; 指定ファイル名
	MOV	CX,FLALLLEN		; 指定ファイル名最大長さ
	REP	MOVSB			;

	POP	CX			;
	POP	SI			;
	POP	DI			;
	POP	ES			;
	RET
PATH_GET	ENDP

;*;CODE	ENDS
;*;
;*;
;*;
;*;DATA	SEGMENT	PUBLIC	'DATA'
;*;
;*;PUBLIC	FLCURT				; カレントドライブ
;*;
;*;EXTRN	CLST_R_BUFF:BYTE		; 読みクラスタバッファ
;*;EXTRN	CLST_R_BUFF_END:BYTE		; 読みクラスタバッファの後ろ
;*;EXTRN	CLST_R_LENGTH:WORD		; 読みクラスタバイト数

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

FFLNAME		DB	FLALLLEN DUP (' ')	; 指定ファイル名
		DB	0,0			;

;*;DATA	ENDS
;*;	END
;*;;
;*;;	end of "DOSIO.ASM"
;*;;
;*;
;*;
;*;; "READWT.ASM" J-3100GS001 make by R.H 1990/09/25,1991/04/02
;*;;
;*;;	E X E L O A D    D I S K    R e a d / W r i t e    c a l l .
;*;;
;*;;
;*;; public subroutine.
;*;
;*;INCLUDE	TSTSET.INC
;*;
;*;CODE	SEGMENT	PUBLIC	'CODE'
;*;
;*;	ASSUME	CS:CODE,DS:DATA,ES:DATA
;*;
;*;PUBLIC	SSRINI		; ドライブ初期処理
;*;
;*;PUBLIC	SSRDRV		; ドライブ番号の設定（０ー３）
;*;PUBLIC	SSRDNO		; ドライブ番号の取得（０ー３）
;*;
;*;			; ＤＩＲ
;*;PUBLIC	SSRDIR		; ＦＡＴ＋ＲＯＯＴの読み出し
;*;PUBLIC	SSWDIR		; ＦＡＴ＋ＲＯＯＴの書き込み
;*;
;*;			; ＲＥＡＤ
;*;PUBLIC	SSRSRT		; ファイルの先頭クラスタ番号の取り出し	(OPEN)
;*;PUBLIC	SSRRED		; クラスタの読み出し			(READ)
;*;
;*;			; ＷＲＩＴＥ
;*;PUBLIC	SSWENT		; ディレクトリ・エントリの取得		(OPEN)
;*;PUBLIC	SSWWRT		; クラスタの書き込み			(WRITE)
;*;PUBLIC	SSWEOF		; クラスタの書き込み終了		(EOF)
;*;PUBLIC	SSWSET		; エントリ・データの書き込み		(CLOSE)
;*;
;*;			; ＫＩＬＬ
;*;PUBLIC	SSKILL		; ファイルの削除
;*;
;*;			; ＴＯＯＬＳ
;*;PUBLIC	SSDSKF		; ディスクの空きクラスタ数
;*;PUBLIC	SSFDDV		; ＦＤドライブドア開閉チェック
;*;
;*;EXTRN	SCINIT:NEAR	; レコードＩ／Ｏ初期化
;*;EXTRN	SCREAD:NEAR	; レコード・ＲＥＡＤ
;*;EXTRN	SCWRITE:NEAR	; レコード・ＷＲＩＴＥ
;*;EXTRN	SCFLASH:NEAR	; レコード・ＦＬＡＳＥ
;*;EXTRN	SCDRRST:NEAR	; ドライブ・リセット
;*;EXTRN	SCDRNO:NEAR	; ドライブ番号の取得
;*;EXTRN	SCDRSET:NEAR	; ドライブ番号の設定
;*;EXTRN	SCDOOR:NEAR	; ドライブドアチェック

DIRENTLEN	EQU	20H		; １つのディレクトリ・エントリの長さ

FLNLEN		EQU	8		; ファイル名の長さ
FLTLEN		EQU	3		; 拡張子の長さ

;					; 各オフセット値
FDMNAM		EQU	0		; ファイル名
FDMTYP		EQU	8H		; 拡張子
FDMATR		EQU	0BH		; ファイル属性
FDMSYS		EQU	0CH		; システム予約
FDMTIM		EQU	16H		; ファイル更新時刻
FDMDAT		EQU	18H		; ファイル更新年月日
FDMCLS		EQU	1AH		; ファイルの最初のクラスタ
FDMSIZ		EQU	1CH		; ファイルサイズ

DIR_ERASE	EQU	0E5H		; ディレクトリ削除マーク

FAT_FREE_CLAST	EQU	0		; 空きクラスタ(FAT)
FAT_EOF_CLAST	EQU	0FFFH		; ファイルの最後のクラスタ(FAT)
FAT_END_CLAST	EQU	0FF8H		; ファイル本体クラスタの最小値(FAT)



;	ファイルの先頭クラスタ番号の取り出し
;	-I- DS:SI : ファイル名
;	-O- DX    : クラスタ番号
;	    CX    : ファイルサイズ（下位ワード）
;	    BX    : ファイルサイズ（上位ワード）
;	    AX    : 0=正常, 1=該当ファイルがない, 2=ディスクエラー

SSRSRT	PROC	NEAR
	PUSH	ES			;
	PUSH	DI			;
	PUSH	SI			;

;*98*;	CALL	LOAD_FDTOP		; ＦＡＴ＋ＲＯＯＴのロード
;*98*;	CMP	DDERROR,1		; 0=正常,1=エラー
;*98*;	JE	SSRSRT_ERROR		;

	CALL	FLNSET			; 指定ファイル名のカラム合わせ
	CALL	ROOTCK			; 指定ファイル名をＲＯＯＴから検索
	CMP	AX,0			; 0=見つからない
	JE	SSRSRT8			;

	MOV	SI,ETADRS 		; ディレクトリ・エントリのオフセット
	MOV	DX,WORD PTR DS:[SI][FDMCLS]	; ファイルの最初のクラスタ
	MOV	CX,WORD PTR DS:[SI][FDMSIZ]	; ファイルサイズ下位
	MOV	BX,WORD PTR DS:[SI][FDMSIZ+2]	; ファイルサイズ上位

	MOV	AX,0			; 0=正常
	POP	SI			;
	POP	DI			;
	POP	ES			;
	RET				;
SSRSRT8:
	MOV	DX,0			;
	MOV	AX,1			; 1=該当ファイルがない
	POP	SI			;
	POP	DI			;
	POP	ES			;
	RET				;
SSRSRT_ERROR:
	MOV	DX,0			;
	MOV	AX,2			; 2=ディスクエラー
	POP	SI			;
	POP	DI			;
	POP	ES			;
	RET				;
SSRSRT	ENDP


;	クラスタの読み出し
;	-I- DX      : 読み出すクラスタ番号
;	    DATA:SI : クラスタバッファ
;	-O- DX      : 次のクラスタ番号
;	    DATA:[SI] : クラスタバッファ
;	    AX      : 0=正常, 1=E.O.F, 2=ディスクエラー

SSRRED	PROC	NEAR
	PUSH	ES			;
	PUSH	DI			;
	PUSH	SI			;

	CMP	DX,FD_MAX_CLAST		; 最大クラスタ番号
	JNBE	SSRRED99		;
	CMP	DX,FD_MIN_CLAST		; 最小クラスタ番号
	JB	SSRRED99		;

	MOV	CLAST_ADRS,SI		; クラスタバッファアドレス

	MOV	PNTNOW,DX		; 現在のクラスタ番号
	CALL	LODCLS			; クラスタロード
	CALL	NXTNUM			; 次のクラスタ番号を取り出す
	MOV	DX,PNTNXT		; 続きのクラスタ番号

	CMP	DDERROR,1		; 1=エラー
	JE	SSRRED_ERROR		;

	MOV	AX,0			; 0=正常
	POP	SI			;
	POP	DI			;
	POP	ES			;
	RET				;
SSRRED99:
	MOV	AX,1			; 1=E.O.F
	POP	SI			;
	POP	DI			;
	POP	ES			;
	RET				;
SSRRED_ERROR:
	MOV	AX,2			; 2=ディスクエラー
	POP	SI			;
	POP	DI			;
	POP	ES			;
	RET				;
SSRRED	ENDP



;	ディレクトリ・エントリの取得
;	-I- DS:SI : ファイル名
;	-O- DX    : ディレクトリ・エントリＩＤ
;	    AX    : 0=正常, 1=ディレクトリに空きがない, 2=ディスクエラー

SSWENT	PROC	NEAR
	CALL	LOAD_FDTOP		; ＦＡＴ＋ＲＯＯＴのロード
	CMP	DDERROR,1		; 1=エラー
	JE	SSWENT_ERROR		;

	CALL	FLNSET			; 指定ファイル名のカラム合わせ

	CALL	ROOTFR			; 空きエントリをＲＯＯＴから検索
	CMP	AX,0			; 0=空きエントリが無い
	JE	SSWENT_NONE		;

	MOV	DX,BX			; 見つかったディレクトリの通し番号
					; DX = エントリＩＤ

	MOV	SI,ETADRS 		; ディレクトリ・エントリのオフセット
	MOV	WORD PTR DS:[SI][FDMCLS],0	; ファイルの最初のクラスタ
	MOV	WORD PTR DS:[SI][FDMSIZ],0	; ファイルサイズ下位
	MOV	WORD PTR DS:[SI][FDMSIZ+2],0	; ファイルサイズ上位
	MOV	BYTE PTR DS:[SI][FDMATR],20H	; ファイル属性

	MOV	DI,ETADRS 		; ディレクトリ・エントリのオフセット
	ADD	DI,FDMNAM		; ファイル名(offset)
	MOV	CX,FLNLEN+FLTLEN	; ファイル名の長さ＋拡張子の長さ
	MOV	SI,OFFSET FLNAME	; ファイル名
	MOVX	ES,DS			;
	REP	MOVSB			; ファイル名セット

	MOV	MODROOTFAT,1		; 現在のROOT&FAT内容(0=READ,1=WRITE)

	MOV	AX,0			; 0=正常
	RET				;
SSWENT_NONE:
	MOV	AX,1			; 1=ディレクトリに空きがない
	RET				;
SSWENT_ERROR:
	MOV	AX,2			; 2=ディスクエラー
	RET				;
SSWENT	ENDP



;	クラスタの書き込み終了
;	-I- DX : 前回のクラスタ番号
;	-O- AX : 0=正常, 2=ディスクエラー

SSWEOF	PROC	NEAR
	MOV	PNTNOW,DX		; 書き込むＦＡＴのクラスタ位置
	CMPX	PNTNOW,FD_MIN_CLAST	; 最小クラスタ番号
	JB	SSWEOF_SKIP		;
	MOV	DX,FAT_EOF_CLAST	; ファイルの最後のクラスタ(FAT)
	CALL	FATSET			; ＦＡＴへクラスタ番号を書き込む
SSWEOF_SKIP:

	CALL	SCFLASH			; レコード・ＦＬＡＳＥ
	MOV	DDERROR,AX		; 0=正常,1=エラー
	CMP	DDERROR,0		; 1=エラー
	JNE	SSWEOF_ERROR		;

	MOV	AX,0			; 0=正常
	RET				;
SSWEOF_ERROR:
	MOV	AX,2			; 2=ディスクエラー
	RET				;
SSWEOF	ENDP



;	エントリ・データの書き込み
;	-I- DX    : ファイルの最初のクラスタ
;	    CX    : ファイルサイズ（下位ワード）
;	    BX    : ファイルサイズ（上位ワード）
;	    AX    : ディレクトリ・エントリＩＤ
;	-O- AX    : 0=正常, 2=ディスクエラー

SSWSET	PROC	NEAR
	PUSH	DX			;
	PUSH	BX			;
	CWD				; ディレクトリ・エントリＩＤ=AX
	MOV	BX,DIRENTLEN		; ディレクトリ・エントリの長さ
	IMUL	BX			;
	ADD	AX,RDF_ROOT		; ＲＯＯＴグローバルアドレス
	MOV	ETADRS,AX		; ディレクトリ・エントリのオフセット
	POP	BX			;
	POP	DX			;

	MOV	SI,ETADRS			;
	MOV	WORD PTR DS:[SI][FDMCLS],DX	; ファイルの最初のクラスタ
	MOV	WORD PTR DS:[SI][FDMSIZ],CX	; ファイルサイズ下位
	MOV	WORD PTR DS:[SI][FDMSIZ+2],BX	; ファイルサイズ上位

	MOV	MODROOTFAT,1		; 現在のROOT&FAT内容(0=READ,1=WRITE)

	CALL	SAVE_FDTOP		; ＦＡＴ＋ＲＯＯＴのセーブ
	CMP	DDERROR,0		; 1=エラー
	JNE	SSWSET_ERROR		;

	MOV	AX,0			; 0=正常
	RET				;
SSWSET_ERROR:
	MOV	AX,2			; 2=ディスクエラー
	RET				;
SSWSET	ENDP



;	クラスタの書き込み
;	-I- DX : 前回のクラスタ番号 （０か１ならば最初の書き込み）
;	    DATA:SI : クラスタバッファ
;	-O- DX : 書き込みクラスタ番号
;	    AX : 0=正常, 1=ディスクに空き無し, 2=ディスクエラー

SSWWRT	PROC	NEAR
	PUSH	ES			;
	PUSH	DI			;

	CMP	DX,FD_MAX_CLAST		; 最大クラスタ番号
	JNBE	SSWWRT_ERROR		;

	MOV	CLAST_ADRS,SI		; クラスタバッファアドレス

	MOV	PNTNOW,DX		; 現在のクラスタ番号
	CALL	NXTFRE			; 次の空きクラスタを捜す
	CMP	AX,1			; 1=空きクラスタ無し
	JE	SSWWRT_FULL		;

	CMPX	PNTNOW,FD_MIN_CLAST	; 最小クラスタ番号
	JB	SSWWRT_SKIP		;
	MOV	DX,PNTFRE		; 書き込むクラスタ番号
	CALL	FATSET			; ＦＡＴへクラスタ番号を書き込む
SSWWRT_SKIP:

	MOV	DX,PNTFRE		; 次の空きクラスタ番号
	MOV	PNTNOW,DX		; 現在のクラスタ番号
	CALL	SAVCLS			; クラスタセーブ

	CMP	DDERROR,1		; 1=エラー
	JE	SSWWRT_ERROR		;

	MOV	DX,PNTFRE		; 次の空きクラスタ番号

	MOV	AX,0			; 0=正常
	POP	DI			;
	POP	ES			;
	RET				;
SSWWRT_FULL:
	MOV	AX,1			; 1=ディスクに空き無し
	POP	DI			;
	POP	ES			;
	RET				;
SSWWRT_ERROR:
	MOV	AX,2			; 2=ディスクエラー
	POP	DI			;
	POP	ES			;
	RET				;
SSWWRT	ENDP



;	ファイルの削除
;	-I- DS:SI : ファイル名
;	-O- AX    : 0=正常, 1=該当ファイルがない, 2=ディスクエラー

SSKILL	PROC	NEAR
	PUSH	SI

	CALL	LOAD_FDTOP		; ＦＡＴ＋ＲＯＯＴのロード
	CMP	DDERROR,1		; 0=正常,1=エラー
	JE	SSKILL_ERROR		;

	CALL	FLNSET			; 指定ファイル名のカラム合わせ
	CALL	ROOTCK			; 指定ファイル名をＲＯＯＴから検索
	CMP	AX,0			; 0=見つからない
	JE	SSKILL_NONE		;

	MOV	SI,ETADRS 		; ディレクトリ・エントリのオフセット
	MOV	DX,WORD PTR DS:[SI][FDMCLS]	; ファイルの最初のクラスタ
	CALL	FATCUT			; ＦＡＴ中のチェインをクリアする

	MOV	SI,ETADRS 		; ディレクトリ・エントリのオフセット
	MOV	BYTE PTR DS:[SI][FDMNAM],DIR_ERASE ; ディレクトリ削除マーク

	MOV	MODROOTFAT,1		; 現在のROOT&FAT内容(0=READ,1=WRITE)

	CALL	SAVE_FDTOP		; ＦＡＴ＋ＲＯＯＴのセーブ
	CMP	DDERROR,0		; 1=エラー
	JNE	SSKILL_ERROR		;

SSKILL_EXIT:
	MOV	AX,0			; 0=正常
	POP	SI			;
	RET				;
SSKILL_NONE:
	MOV	AX,1			; 1=該当ファイルがない
	POP	SI			;
	RET				;
SSKILL_ERROR:
	MOV	AX,2			; 2=ディスクエラー
	POP	SI			;
	RET				;
SSKILL	ENDP



;	ディスクの空きクラスタ数
;	-O- DX  : 空きクラスタ数
;	    AX  : 0=正常, 2=ディスクエラー

SSDSKF	PROC	NEAR
	CALL	LOAD_FDTOP		; ＦＡＴ＋ＲＯＯＴのロード
	CMP	DDERROR,1		; 0=正常,1=エラー
	JE	SSDSKF_ERROR		;

	CALL	CNTFRE			; 空きクラスタ数を調べる

	MOV	DX,FRE_CLAST		; 空きクラスタ数
	MOV	AX,0			; 0=正常
	RET				;
SSDSKF_ERROR:
	MOV	DX,0			;
	MOV	AX,2			; 2=ディスクエラー
	RET				;
SSDSKF	ENDP



;	ＦＤドライブドア開閉チェック
;	-I- AX : １ＭＦＤドライブ番号（０ー３）
;	-O- AX : 0=前と変わらず,1=ドアを開閉した,2=ドアが開きっぱなし

SSFDDV	PROC	NEAR
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	DI
	PUSH	SI
	PUSH	ES
	CALL	FDRSLT	; ＦＤドライブドア開閉チェック(ﾘｻﾞﾙﾄｽﾃｰﾀｽﾁｪｯｸ)
	POP	ES
	POP	SI
	POP	DI
	POP	DX
	POP	CX
	POP	BX
	RET
SSFDDV	ENDP



;	ＦＡＴ中のチェインをクリアする
;	-I- DX : チェイン先頭

FATCUT	PROC	NEAR
FATCUT_LOOP:
	CMP	DX,FD_MAX_CLAST		; 最大クラスタ番号
	JNBE	FATCUT_LOOPEND		;
	CMP	DX,FD_MIN_CLAST		; 最小クラスタ番号
	JB	FATCUT_LOOPEND		;

	MOV	PNTNOW,DX		; 現在のクラスタ番号
	CALL	NXTNUM			; 次のクラスタ番号を取り出す
	MOV	DX,FAT_FREE_CLAST	; 空きクラスタ(FAT)
	CALL	FATSET			; ＦＡＴへクラスタ番号を書き込む

	MOV	DX,PNTNXT		; 続きのクラスタ番号

	JMP	FATCUT_LOOP		;
FATCUT_LOOPEND:				;
	RET
FATCUT	ENDP



;	指定ファイル名をＲＯＯＴディレクトリから検索
;	-I- FLNAME : ファイル名
;	-O- AX     : 0=見つからない,1=見つかった
;	    ETADRS : ディレクトリ・エントリのオフセットアドレス
;	    BX     : 見つかったディレクトリの通し番号

ROOTCK	PROC	NEAR
	MOVX	ES,DS			;

	MOV	BX,0			; 見つかったディレクトリの通し番号
	MOV	DI,RDF_ROOT		; ＲＯＯＴグローバルアドレス

	MOV	CX,FD_DIRMAX		; ディレクトリ最大数
ROOTCK1:				;
	MOV	ETADRS,DI		; エントリのオフセットアドレス
	MOV	SI,OFFSET FLNAME	;
	CMP	BYTE PTR ES:[DI],0	; end of dir.
	JE	ROOTCK8			;

	PUSH	CX			;
	MOV	CX,FLNLEN+FLTLEN	; ファイル名の長さ
ROOTCK2:CMPSB				; 文字列の照合
	JNE	ROOTCK3			;
	LOOP	ROOTCK2			;
	POP	CX			;
	JMP	ROOTCK9			;

ROOTCK3:				;
	DEC	CX			;
	ADD	DI,CX			; ＲＯＯＴＤＩＲのポインタを進める
	ADD	DI,DIRENTLEN - ( FLNLEN + FLTLEN )
	INC	BX			; 見つかったディレクトリの通し番号
	POP	CX			;
	LOOP	ROOTCK1			;

ROOTCK8:
	MOV	AX,0			; 0=見つからない
	RET				;
ROOTCK9:
	MOV	AX,1			; 1=見つかった
	RET				;
ROOTCK	ENDP



;	空きエントリをＲＯＯＴディレクトリから検索
;	-O- AX     : 0=空きエントリが無い,1=見つかった
;	    ETADRS : ディレクトリ・エントリのオフセットアドレス
;	    BX     : 見つかったディレクトリの通し番号

ROOTFR	PROC	NEAR
	MOV	BX,0			; 見つかったディレクトリの通し番号
	MOV	SI,RDF_ROOT		; ＲＯＯＴグローバルアドレス

	MOV	CX,FD_DIRMAX		; ディレクトリ最大数
ROOTFR_LOOP:				;
	MOV	ETADRS,SI		; エントリのオフセットアドレス
	CMP	BYTE PTR DS:[SI],0	; end of dir.
	JE	ROOTCK9			;
	CMP	BYTE PTR DS:[SI],DIR_ERASE ; ディレクトリ削除マーク
	JE	ROOTCK9			;

	ADD	SI,DIRENTLEN		; ＲＯＯＴＤＩＲのポインタを進める
	INC	BX			; 見つかったディレクトリの通し番号
	LOOP	ROOTFR_LOOP		;
ROOTFR8:
	MOV	AX,0			; 0=空きエントリが無い
	RET				;
ROOTFR9:
	MOV	AX,1			; 1=見つかった
	RET				;
ROOTFR	ENDP



;	次のクラスタ番号を取り出す
;	-I- PNTNOW : 現在のクラスタ番号
;	-O- PNTNXT : 続きのクラスタ番号

NXTNUM	PROC	NEAR
	MOV	AX,PNTNOW		; 現在のクラスタ番号
	SHR	AX,1			; / 2
	MOV	SI,AX			; ＦＡＴテーブルのアドレスポインタ
	ADD	SI,AX			;
	ADD	SI,AX			; ( * 3 )

	ADD	SI,RDF_FAT		; ＦＡＴグローバルアドレス

	MOV	AX,PNTNOW		; 現在のクラスタ番号
	SHR	AX,1			; 奇数か偶数かの判定
	JB	NXTNUM2			;

					; 偶数の場合
	MOV	AX,DS:[SI]		;
	AND	AX,0FFFH		; 3 nible.
	MOV	PNTNXT,AX		; 続きのクラスタ番号
	RET				;

NXTNUM2:				; 奇数の場合
	MOV	AX,DS:[SI+1]		;
	SHR	AX,1			;
	SHR	AX,1			; 1 nible shift.
	SHR	AX,1			;
	SHR	AX,1			;
	MOV	PNTNXT,AX		; 続きのクラスタ番号
	RET
NXTNUM	ENDP



;	次の空きクラスタを捜す
;	-I- PNTNOW : 現在のクラスタ番号
;	-O- PNTFRE : 次の空きクラスタ番号
;	    AX     : 0=通常,1=空きセクタ無し

NXTFRE	PROC	NEAR
	MOV	AX,PNTNOW		; 現在のクラスタ番号
	INC	AX			;
	MOV	PNTFRE,AX		; 次の空きクラスタ番号

NXTFRE_LOOP:				;
	CMPX	PNTFRE,FD_MAX_CLAST	; 最大クラスタ番号ならば
	JNBE	NXTFRE_RESEARECH	; もう一度先頭から検索

	MOV	AX,PNTFRE		; 次の空きクラスタ番号
	SHR	AX,1			; / 2
	MOV	SI,AX			; ＦＡＴテーブルのアドレスポインタ
	ADD	SI,AX			;
	ADD	SI,AX			; ( * 3 )

	ADD	SI,RDF_FAT		; ＦＡＴグローバルアドレス

	MOV	AX,PNTFRE		; 次の空きクラスタ番号
	SHR	AX,1			; 奇数か偶数かの判定
	JB	NXTFRE2			;

					; 偶数の場合
	MOV	AX,DS:[SI]		;
	AND	AX,0FFFH		; 3 nible.
	JMP	NXTFRE3			;
NXTFRE2:				; 奇数の場合
	MOV	AX,DS:[SI+1]		;
	SHR	AX,1			;
	SHR	AX,1			; 1 nible shift.
	SHR	AX,1			;
	SHR	AX,1			;
NXTFRE3:				;
	CMP	AX,FAT_FREE_CLAST	; 空きクラスタ(FAT)
	JE	NXTFRE_HIT		;

	INC	PNTFRE			; 次の空きクラスタ番号
	JMP	NXTFRE_LOOP		; LOOP END.


NXTFRE_RESEARECH:			;
	MOVX	PNTFRE,FD_MIN_CLAST	; 最小クラスタ番号
NXTFRE_LOOP2:				;
	MOV	AX,PNTFRE		;
	CMP	AX,PNTNOW		; 現在のクラスタ番号ならば
	JNB	NXTFRE_NONE		; 空きクラスタ無し

	MOV	AX,PNTFRE		; 次の空きクラスタ番号
	SHR	AX,1			; / 2
	MOV	SI,AX			; ＦＡＴテーブルのアドレスポインタ
	ADD	SI,AX			;
	ADD	SI,AX			; ( * 3 )

	ADD	SI,RDF_FAT		; ＦＡＴグローバルアドレス

	MOV	AX,PNTFRE		; 次の空きクラスタ番号
	SHR	AX,1			; 奇数か偶数かの判定
	JB	NXTFRE4			;

					; 偶数の場合
	MOV	AX,DS:[SI]		;
	AND	AX,0FFFH		; 3 nible.
	JMP	NXTFRE5			;
NXTFRE4:				; 奇数の場合
	MOV	AX,DS:[SI+1]		;
	SHR	AX,1			;
	SHR	AX,1			; 1 nible shift.
	SHR	AX,1			;
	SHR	AX,1			;
NXTFRE5:				;
	CMP	AX,0FF8H		; クラスタ番号は空きクラスタか？
	JNB	NXTFRE_HIT		;

	INC	PNTFRE			; 次の空きクラスタ番号
	JMP	NXTFRE_LOOP2		;

NXTFRE_HIT:
	MOV	AX,0			; 0=通常
	RET				;
NXTFRE_NONE:
	MOV	AX,1			; 1=空きクラスタ無し
	RET				;
NXTFRE	ENDP



;	空きクラスタ数を調べる
;	-O- FRE_CLAST : 空きクラスタ数

CNTFRE	PROC	NEAR
	PUSH	PNTNOW			; 現在のクラスタ番号
	PUSH	PNTNXT			; 続きのクラスタ番号

	MOV	FRE_CLAST,0		; 空きクラスタ数

	MOV	AX,FD_MIN_CLAST		; 最小クラスタ番号
	MOV	PNTNOW,AX		; 現在のクラスタ番号

CNTFRE_LOOP:
	MOV	AX,PNTNOW		; 現在のクラスタ番号
	CMP	AX,FD_MAX_CLAST		; 最大クラスタ番号を越えたら終り
	JNBE	CNTFRE_EXIT		;

	CALL	NXTNUM			; 次のクラスタ番号を取り出す

	CMP	PNTNXT,FAT_FREE_CLAST	; 空きクラスタ(FAT)か？
	JNE	CNTFRE_SKIP		;
	INC	FRE_CLAST		; 空きクラスタ数インクリメント
CNTFRE_SKIP:				;
	INC	PNTNOW			; 現在のクラスタ番号

	JMP	CNTFRE_LOOP		;

CNTFRE_EXIT:
	POP	PNTNXT			;
	POP	PNTNOW			;
	RET
CNTFRE	ENDP



;	ＦＡＴへクラスタ番号を書き込む
;	-I- PNTNOW : 書き込むＦＡＴのクラスタ位置
;	    DX     : 書き込むクラスタ番号
;
;	-I/O- MODROOTFAT : 現在のROOT&FAT内容(0=READ,1=WRITE)
;
;	    PNTNOW（ＦＡＴのクラスタ位置）がＦＦＦｈの場合は書き込まない

FATSET	PROC	NEAR
	CMP	PNTNOW,FAT_END_CLAST	; ファイル本体クラスタの最小値(FAT)
	JNB	FATSET_EXIT		;

	AND	DX,0FFFH		; 3 nible mask.

	MOV	AX,PNTNOW		; 現在のクラスタ番号
	SHR	AX,1			; / 2
	MOV	SI,AX			; ＦＡＴテーブルのアドレスポインタ
	ADD	SI,AX			;
	ADD	SI,AX			; ( * 3 )

	ADD	SI,RDF_FAT		; ＦＡＴグローバルアドレス

	MOV	AX,PNTNOW		; 現在のクラスタ番号
	SHR	AX,1			; 奇数か偶数かの判定
	JB	FATSET2			;

					; 偶数の場合
	AND	WORD PTR DS:[SI],0F000H	; 1 nible mask.
	OR	WORD PTR DS:[SI],DX	;
	JMP	FATSET3			;
FATSET2:				; 奇数の場合
	AND	WORD PTR DS:[SI+1],0FH	; 1 nible mask.
	SHL	DX,1			;
	SHL	DX,1			; 1 nible shift.
	SHL	DX,1			;
	SHL	DX,1			;
	OR	WORD PTR DS:[SI+1],DX	;
FATSET3:				;
	MOV	MODROOTFAT,1		; 現在のROOT&FAT内容(0=READ,1=WRITE)
FATSET_EXIT:				;
	RET				;
FATSET	ENDP


;	クラスタロード
;	-I- PNTNOW	: 現在のクラスタ番号
;	    CLAST_ADRS  : クラスタバッファアドレス
;	-O- DATA:[CLAST_ADRS] : クラスタのデータ
;	    DDERROR	: 0=正常,1=エラー

LODCLS	PROC	NEAR
	CALL	CLAST_TO_RECORD		; クラスタ番号からレコード番号へ

	MOVX	CLAST_PNT,CLAST_ADRS	; クラスタバッファアドレス

	MOV	CX,RECCNT		; レコード数
	JCXZ	LODCLS_EXIT		;
LODCLS_LOOP:				;
	PUSH	CX			;

	MOV	AX,RECNUM		; レコード番号
	CALL	SCREAD			; レコード・ＲＥＡＤ
	CMP	AX,0			; 0=正常,1=エラー
	JNE	LODCLS_ERROR		;

	MOVX	ES,DS			;
	MOV	DI,CLAST_PNT		; クラスタデータポインタ
	MOV	SI,OFFSET SCDATA	; セクタバッファ
	MOV	CX,FD_LEN_SECTOR	; セクタバイト数
	REP	MOVSB			;

	ADDX	CLAST_PNT,FD_LEN_SECTOR	; クラスタデータポインタ

	INC	RECNUM			; レコード番号
	POP	CX			;
	LOOP	LODCLS_LOOP		;
LODCLS_EXIT:
	MOV	DDERROR,0		; 0=正常
	RET				;
LODCLS_ERROR:
	POP	CX
	MOV	DDERROR,1		; 1=エラー
	RET
LODCLS	ENDP


;	クラスタセーブ
;	-I- PNTNOW	: 現在のクラスタ番号
;	    CLAST_ADRS  : クラスタバッファアドレス
;	-O- DDERROR	: 0=正常,1=エラー

SAVCLS	PROC	NEAR
	CALL	CLAST_TO_RECORD		; クラスタ番号からレコード番号へ

	MOVX	CLAST_PNT,CLAST_ADRS	; クラスタバッファアドレス

	MOV	CX,RECCNT		; レコード数
	JCXZ	SAVCLS_EXIT		;
SAVCLS_LOOP:				;
	PUSH	CX			;

	MOVX	ES,DS			;
	MOV	SI,CLAST_PNT		; クラスタデータポインタ
	MOV	DI,OFFSET SCDATA	; セクタバッファ
	MOV	CX,FD_LEN_SECTOR	; セクタバイト数
	REP	MOVSB			;

	ADDX	CLAST_PNT,FD_LEN_SECTOR	; クラスタデータポインタ

	MOV	AX,RECNUM		; レコード番号
	CALL	SCWRITE			; レコード・ＷＲＩＴＥ
	CMP	AX,0			; 0=正常,1=エラー
	JNE	SAVCLS_ERROR		;

	INC	RECNUM			; レコード番号
	POP	CX			;
	LOOP	SAVCLS_LOOP		;
SAVCLS_EXIT:
	MOV	DDERROR,0		; 0=正常
	RET				;
SAVCLS_ERROR:
	POP	CX			;
	MOV	DDERROR,1		; 1=エラー
	RET
SAVCLS	ENDP


;	クラスタ番号からレコード番号へ
;	-I- PNTNOW : 現在のクラスタ番号
;	-O- RECNUM : レコード番号
;	    RECCNT : レコード数

CLAST_TO_RECORD	PROC	NEAR
	MOV	AX,PNTNOW		; 現在のクラスタ番号
	SUB	AX,FD_MIN_CLAST		; 最小クラスタ番号
	MOV	DX,0			;
	MUL	FD_SEC_P_CLAST		; ×クラスタ当りのセクタ数
	ADD	AX,FD_MIN_CLAST		; 最小クラスタ番号
	ADD	AX,FD_CLAST_OFFSET	; ＋クラスタ開始位置のセクタオフセット

	MOV	RECNUM,AX		; レコード番号
	MOVX	RECCNT,FD_SEC_P_CLAST	; クラスタ当りのセクタ数

	RET
CLAST_TO_RECORD	ENDP


;	ＦＡＴ＋ＲＯＯＴの読み出し
;	-O- AX : 0=正常, 2=ディスクエラー

SSRDIR	PROC	NEAR
	PUSH	BX			;
	PUSH	CX			;
	PUSH	DX			;
	PUSH	DI			;
	PUSH	SI			;
	PUSH	ES			;

	CALL	LOAD_FDTOP		; ＦＡＴ＋ＲＯＯＴのロード
	CMP	DDERROR,1		; ディスクエラー
	JE	SSRDIR_ERROR		;

	MOV	AX,0			; 0=正常
	POP	ES			;
	POP	SI			;
	POP	DI			;
	POP	DX			;
	POP	CX			;
	POP	BX			;
	RET				;
SSRDIR_ERROR:
	MOV	AX,2			; 2=ディスクエラー
	POP	ES			;
	POP	SI			;
	POP	DI			;
	POP	DX			;
	POP	CX			;
	POP	BX			;
	RET				;
SSRDIR	ENDP



;	ＦＡＴ＋ＲＯＯＴの書き込み
;	-O- AX : 0=正常, 2=ディスクエラー

SSWDIR	PROC	NEAR
	PUSH	BX			;
	PUSH	CX			;
	PUSH	DX			;
	PUSH	DI			;
	PUSH	SI			;
	PUSH	ES			;

	CALL	SAVE_FDTOP		; ＦＡＴ＋ＲＯＯＴのセーブ
	CMP	DDERROR,0		; 1=エラー
	JNE	SSWDIR_ERROR		;

	MOV	AX,0			; 0=正常
	POP	ES			;
	POP	SI			;
	POP	DI			;
	POP	DX			;
	POP	CX			;
	POP	BX			;
	RET				;
SSWDIR_ERROR:
	MOV	AX,2			; 2=ディスクエラー
	POP	ES			;
	POP	SI			;
	POP	DI			;
	POP	DX			;
	POP	CX			;
	POP	BX			;
	RET				;
SSWDIR	ENDP



;	ＦＡＴ＋ＲＯＯＴのロード
;	-O-   DDERROR 		: 0=正常,1=エラー

LOAD_FDTOP	PROC	NEAR
	PUSH	SI			;

	MOV	DDERROR,0		; 0=正常

	CALL	SCDRNO			; ドライブ番号の取得
	MOV	DNUMBER,AX		; ドライブ番号

	CALL	FDDOOR			; ＦＤドライブドア開閉チェック

	CMP	AX,0			; 0=前と変わらず,1=ドアを開閉した
	JNE	LOAD_FDTOP_LOAD		; 2=ドアが開きっぱなし

	CMPX	NOW_FAT_DRIVE,DNUMBER	; 現在のＦＡＴドライブ番号
	JE	LOAD_FDTOP_EXIT		;

LOAD_FDTOP_LOAD:			;
	MOVX	NOW_FAT_DRIVE,DNUMBER	; 現在のＦＡＴドライブ番号

	CALL	SCDRRST			; ドライブ・リセット
	CALL	FDDOOR			; ＦＤドライブドア開閉チェック

	CALL	LODFAT			; ＦＡＴ＆ＲＯＯＴロード

LOAD_FDTOP_EXIT:
	POP	SI			;
	RET				;
LOAD_FDTOP	ENDP



;	ＦＡＴ＋ＲＯＯＴのセーブ
;	-I/O- MODROOTFAT : 現在のROOT&FAT内容(0=READ,1=WRITE)
;	-O-   DDERROR : 0=正常,1=エラー

SAVE_FDTOP	PROC	NEAR
	MOV	DDERROR,0		; 0=正常,1=エラー

	CMP	MODROOTFAT,1		; 現在のROOT&FAT内容(0=READ,1=WRITE)
	JNE	SAVE_FDTOP_EXIT		;

	CALL	SAVFAT			; ＦＡＴ＆ＲＯＯＴセーブ
	CMP	DDERROR,0		; 1=エラー
	JNE	SAVE_FDTOP_EXIT		;

	CALL	SCFLASH			; レコード・ＦＬＡＳＥ
	MOV	DDERROR,AX		; 0=正常,1=エラー
	CMP	DDERROR,0		; 1=エラー
	JNE	SAVE_FDTOP_EXIT		;

	MOV	MODROOTFAT,0		; 現在のROOT&FAT内容(0=READ,1=WRITE)
SAVE_FDTOP_EXIT:
	RET
SAVE_FDTOP	ENDP



;	ＦＡＴ＆ＲＯＯＴロード
;	（ＦＡＴとＲＯＯＴディレクトリは連続しています）
;	-O- DDERROR 	: 0=正常,1=エラー

LODFAT	PROC	NEAR
	MOV	DDERROR,0		; 0=正常

	MOVX	ES,DS			;
	MOV	DI,RDF_FAT		; ＦＡＴグローバルアドレス

	MOV	RECNUM,1		; レコード番号
	MOV	CX,FD_FAT_CLAST		; ＦＡＴ＋ＲＯＯＴクラスタ数
	ADD	CX,FD_ROOT_CLAST		;
LODFAT2:				;
	PUSH	CX			;
	MOV	AX,RECNUM		; レコード番号
	PUSH	ES			;
	PUSH	DI			;
	CALL	SCREAD			; レコード・ＲＥＡＤ
	MOV	DDERROR,AX		; 0=正常,1=エラー
	POP	DI			;
	POP	ES			;
	MOV	SI,OFFSET SCDATA	;
	MOV	CX,FD_LEN_CLAST		; クラスタの内容－＞ＦＡＴテーブル
	REP	MOVSB			;
	POP	CX			;
	CMP	DDERROR,1		; エラー
	JE	LODFAT_ERROR		;
	INC	RECNUM			; レコード番号
	LOOP	LODFAT2			;
	RET
LODFAT_ERROR:				; エラー
	RET				;
LODFAT	ENDP


;	ＦＡＴ＆ＲＯＯＴセーブ
;	（ＦＡＴとＲＯＯＴディレクトリは連続しています）
;	-O- DDERROR 	: 0=正常,1=エラー

SAVFAT	PROC	NEAR
	MOV	DDERROR,0		; 0=正常

	MOV	SI,RDF_FAT		; ＦＡＴグローバルアドレス

	MOV	RECNUM,1		; レコード番号
	MOV	CX,FD_FAT_CLAST		; ＦＡＴ＋ＲＯＯＴクラスタ数
	ADD	CX,FD_ROOT_CLAST		;
SAVFAT2:				;
	PUSH	CX			;
	MOVX	ES,DS			;
	MOV	DI,OFFSET SCDATA	;
	MOV	CX,FD_LEN_CLAST		; クラスタの内容－＞ＦＡＴテーブル
	REP	MOVSB			;
	MOV	AX,RECNUM		; レコード番号
	PUSH	SI			;
	CALL	SCWRITE			; レコード・ＷＲＩＴＥ
	MOV	DDERROR,AX		; 0=正常,1=エラー
	POP	SI			;
	POP	CX			;
	CMP	DDERROR,1		; エラー
	JE	LODFAT_ERROR		;
	INC	RECNUM			; レコード番号
	LOOP	SAVFAT2			;
	RET
SAVFAT_ERROR:				; エラー
	RET				;
SAVFAT	ENDP


;	ドライブ初期処理

SSRINI	PROC	NEAR
	CALL	SCINIT			; レコードＩ／Ｏ初期化
	RET
SSRINI	ENDP


;	ドライブ番号の設定（０ー３）
;	-I- AX : １ＭＦＤドライブ番号
;	-O- AX : 0=正常, 2=ディスクエラー

SSRDRV	PROC	NEAR
	PUSH	BX			;
	PUSH	CX			;
	PUSH	DX			;
	PUSH	DI			;
	PUSH	SI			;
	PUSH	ES			;

	MOV	BX,AX			; ドライブ番号
	CALL	SCDRNO			; ドライブ番号の取得
	CMP	BX,AX			; ドライブ番号変更無しか？
	JE	SSRDRV2			;

	PUSH	BX			;
	CALL	SAVE_FDTOP		; ＦＡＴ＋ＲＯＯＴのセーブ
	POP	BX			;
	CMP	DDERROR,1		; ディスクエラー
	JE	SSRDRV_ERROR		;

SSRDRV2:
	MOV	AX,BX			; １ＭＦＤドライブ番号
	CALL	SCDRSET			; ドライブ番号の設定

	CALL	LOAD_FDTOP		; ＦＡＴ＋ＲＯＯＴのロード

	CMP	DDERROR,1		; ディスクエラー
	JE	SSRDRV_ERROR		;

	POP	ES			;
	POP	SI			;
	POP	DI			;
	POP	DX			;
	POP	CX			;
	POP	BX			;
	MOV	AX,0			; 0=正常
	RET				;
SSRDRV_ERROR:
	POP	ES			;
	POP	SI			;
	POP	DI			;
	POP	DX			;
	POP	CX			;
	POP	BX			;
	MOV	AX,2			; 2=ディスクエラー
	RET				;
SSRDRV	ENDP


;	ドライブ番号の取得（０ー３）
;	-O- AX : １ＭＦＤドライブ番号

SSRDNO	PROC	NEAR
	CALL	SCDRNO			; ドライブ番号の取得
	RET
SSRDNO	ENDP



;	ＦＤドライブドア開閉チェック
;	-I- AX : １ＭＦＤドライブ番号（０ー３）
;	-O- AX : 0=前と変わらず,1=ドアを開閉した,2=ドアが開きっぱなし

FDDOOR	PROC	NEAR
	PUSH	DX			;
	PUSH	BX			;
	PUSH	ES			;
	CALL	FDRSLT			; ＦＤドライブドア開閉チェック(ﾘｻﾞﾙﾄ)
	CMP	AX,2			; 2=ドアが開きっぱなし
	JNE	FDDOOR_9		;
	MOV	AX,1			;
FDDOOR_9:
	POP	ES			;
	POP	BX			;
	POP	DX			;
	RET				;
FDDOOR	ENDP




;	ＦＤドライブドア開閉チェック（リザルトステータスチェック）
;	-I- AX : １ＭＦＤドライブ番号（０ー３）
;	-O- AX : 0=前と変わらず,1=ドアを開閉した,2=ドアが開きっぱなし

FDRSLT	PROC	NEAR
	CALL	SCDOOR		; ドライブドアチェック
	RET
FDRSLT	ENDP



;	指定ファイル名のカラム合わせ ex. "TEST.ASM"->"TEST____ASM"
;	-I- DS:SI  : ファイル名
;	-O- FLNAME : ファイル名

FLNSET	PROC	NEAR
	PUSH	SI			;

	MOVX	ES,DS			;
	MOV	DI,OFFSET FLNAME	;
	MOV	CX,FLNLEN+FLTLEN	;
	MOV	AL,' '			;
	REP	STOSB			;

	MOV	DI,OFFSET FLNAME	;
	MOV	CX,FLNLEN+FLTLEN	;
FLNSET2:LODSB				;
	CMP	AL,'.'			; next type.
	JE	FLNSET4			;
	CMP	AL,20H			; end of string.
	JB	FLNSET9			;
	STOSB				;
	LOOP	FLNSET2			;
	JMP	FLNSET9			;

FLNSET4:				;
	MOV	DI,OFFSET FLTYPE	;
	MOV	CX,FLTLEN		;
FLNSET5:LODSB				;
	CMP	AL,'.'			; next type.
	JE	FLNSET9			;
	CMP	AL,20H			; end of string.
	JB	FLNSET9			;
	STOSB				;
	LOOP	FLNSET5			;

FLNSET9:				;
	POP	SI			;
	RET				;
FLNSET	ENDP

;*;CODE	ENDS
;*;
;*;
;*;
;*;DATA	SEGMENT	PUBLIC	'DATA'
;*;
;*;EXTRN	FD_FAT_CLAST:WORD		; ＦＡＴテーブルクラスタ数
;*;EXTRN	FD_ROOT_CLAST:WORD		; ＲＯＯＴＤＩＲクラスタ数
;*;EXTRN	FD_DIRMAX:WORD			; ディレクトリ最大数
;*;EXTRN	FD_CLAST_OFFSET:WORD	; クラスタ開始位置のセクタオフセット
;*;EXTRN	FD_MIN_CLAST:WORD		; 最小クラスタ番号
;*;EXTRN	FD_MAX_CLAST:WORD		; 最大クラスタ番号
;*;EXTRN	FD_LEN_CLAST:WORD		; クラスタバイト数
;*;
;*;EXTRN	FD_SEC_P_CLAST:WORD		; クラスタ当りのセクタ数
;*;
;*;EXTRN	FD_LEN_SECTOR:WORD		; セクタバイト数
;*;
;*;EXTRN	RDF_FAT:WORD			; ＦＡＴグローバルアドレス
;*;EXTRN	RDF_ROOT:WORD			; ＲＯＯＴグローバルアドレス
;*;EXTRN	SCDATA:BYTE			; セクタバッファ

NOW_FAT_DRIVE	DW	0FFFFH		; 現在のＦＡＴドライブ番号


ETADRS		DW	0		; ディレクトリ・エントリのオフセット
RECNUM		DW	0		; レコード番号
RECCNT		DW	0		; レコード数

PNTNOW		DW	0		; 現在のクラスタ番号
PNTNXT		DW	0		; 続きのクラスタ番号
PNTFRE		DW	0		; 次の空きクラスタ番号
FRE_CLAST	DW	0		; 空きクラスタ数

CLAST_ADRS	DW	0		; クラスタバッファアドレス
CLAST_PNT	DW	0		; クラスタデータポインタ

MODROOTFAT	DW	0		; 現在のROOT&FAT内容(0=READ,1=WRITE)

DNUMBER		DW	0		; ドライブ番号
DDERROR		DW	0		; 0=正常,1=エラー


FLNAME		DB	FLNLEN DUP (20H)	; ファイル名
FLTYPE		DB	FLTLEN DUP (20H)	; 拡張子
		DB	0,0			;

;*;DATA	ENDS
;*;
;*;	END
;*;
;*;;
;*;;	end of "READWT.ASM"
;*;;
;*;; "READSC.ASM" J-3100GS001 make by R.H 1990/09/25,1991/04/02
;*;;
;*;;	E X E L O A D    S E C T O R   R e a d / W r i t e    c a l l .
;*;;
;*;;
;*;; public subroutine.
;*;
;*;INCLUDE	TSTSET.INC

DRIVE_FLAG_CNT	EQU	8		; ドライブ・フラグ数

READ_RETCOUNT 	EQU	10		; ＲＥＡＤ・リトライ回数
WRITE_RETCOUNT 	EQU	3		; ＷＲＩＴＥ・リトライ回数
					; メーカー推奨値は、３回

OFF_CYLINDER	EQU	9999		; シリンダはロードされていない
OFF_HEAD	EQU	9999		; ヘッドはロードされていない
OFF_FLAG	EQU	0FFH		; ＯＦＦフラグ

DASD_NONE	EQU	00H		; 無効ドライブ
DASD_NO_LINE	EQU	01H		; ドライブ交換判定できない
DASD_CHGLINE	EQU	02H		; ドライブ交換判定可
DASD_HARDDISK	EQU	03H		; ハードディスク

MOVX	MACRO	DEST,SOU
	MOV	AX,SOU
	MOV	DEST,AX
	ENDM

CMPX	MACRO	DEST,SOU
	MOV	AX,SOU
	CMP	DEST,AX
	ENDM

;*;CODE	SEGMENT	PUBLIC	'CODE'
;*;
;*;	ASSUME	CS:CODE,DS:DATA,ES:DATA
;*;
;*;PUBLIC	SCINIT		; レコードＩ／Ｏ初期化
;*;PUBLIC	SCREAD		; レコード・ＲＥＡＤ
;*;PUBLIC	SCWRITE		; レコード・ＷＲＩＴＥ
;*;PUBLIC	SCFLASH		; レコード・ＦＬＡＳＥ
;*;PUBLIC	SCDRRST		; ドライブ・リセット
;*;PUBLIC	SCDRECA		; ドライブ・リキャリブレート
;*;PUBLIC	SCDRSET		; ドライブ番号の設定
;*;PUBLIC	SCDRNO		; ドライブ番号の取得
;*;PUBLIC	SCDOOR		; ドライブドアチェック


;	レコードＩ／Ｏ初期化

SCINIT	PROC	NEAR
	MOV	DRVNO,0				; drive number.
	MOV	BX,0				; byte pointer.
	MOV	CX,DRIVE_FLAG_CNT		; ドライブ・フラグ数
	JCXZ	SCINIT_LOOP_E			;
SCINIT_LOOP:
	PUSH	BX
	PUSH	CX
	MOV	DS:DISK_DOOR_INI[BX],OFF_FLAG	; ディスク開閉初期ﾌﾗｸﾞ

	MOV	DX,DRVNO			; drive number.
	MOV	AH,15H				; ディスクタイプの取得
	INT	13H				; DISK bios.
	POP	CX
	POP	BX
	JC	SCINIT_LOOP_E

	MOV	DS:DISK_DASD_TBL[BX],AH		; ディスクＤＡＳＤタイプ

;*;	CALL	PRNAH				; print ah reg.
;*;	PR	" "

	INC	DRVNO				; drive number.
	INC	BX				; byte pointer.
	LOOP	SCINIT_LOOP
SCINIT_LOOP_E:
	RET
SCINIT	ENDP


;	レコード・ＲＥＡＤ
;	-I- AX		: 論理レコード番号
;	-O- DATA:[SCDATA] : セクタのデータ
;	    AX		: 0=正常,1=エラー

SCREAD	PROC	NEAR
	CALL	LODSEC			; 論理レコード・ＲＥＡＤ
	MOV	AX,DERROR		; 0=正常,1=エラー
	RET
SCREAD	ENDP


;	レコード・ＷＲＩＴＥ
;	-I- AX		: 論理レコード番号
;	    DATA:[SCDATA] : セクタのデータ
;	-O- AX		: 0=正常,1=エラー

SCWRITE	PROC	NEAR
	CALL	SAVSEC			; 論理レコード・ＷＲＩＴＥ
	MOV	AX,DERROR		; 0=正常,1=エラー
	RET
SCWRITE	ENDP


;	レコード・ＦＬＡＳＥ
;	-O- AX	: 0=正常,1=エラー

SCFLASH	PROC	NEAR
	CALL	FLASHSSS		; シリンダーＦＬＡＳＨ
	MOV	AX,DERROR		; 0=正常,1=エラー
	RET
SCFLASH	ENDP


;	ドライブ・リセット

SCDRRST	PROC	NEAR

	MOV	NOWCYLINDER,OFF_CYLINDER	; 現在のシリンダー
	MOV	NOWHEAD,OFF_HEAD		; 現在のヘッド

	MOV	BX,0				; byte pointer.
	MOV	CX,DRIVE_FLAG_CNT		; ドライブ・フラグ数
	JCXZ	SCDRRST_LOOP_E			;
SCDRRST_LOOP:					;
	MOV	DS:DISK_DOOR_INI[BX],OFF_FLAG	; ディスク開閉初期ﾌﾗｸﾞ
	INC	BX				;
	LOOP	SCDRRST_LOOP			;
SCDRRST_LOOP_E:					;
	RET
SCDRRST	ENDP


;	ドライブ・リキャリブレート

SCDRECA	PROC	NEAR
	CALL	RECALIBRATE		; ＲＥＣＡＬＩＢＲＡＴＥ
	RET
SCDRECA	ENDP



;	ドライブ番号の設定
;	-I- AX : １ＭＦＤドライブ番号

SCDRSET	PROC	NEAR
	MOV	DUNIT,AX		; ユニット番号
	RET
SCDRSET	ENDP


;	ドライブ番号の取得
;	-O- AX : １ＭＦＤドライブ番号

SCDRNO	PROC	NEAR
	MOV	AX,DUNIT		; ユニット番号
	RET				;
SCDRNO	ENDP


;	ドライブドアチェック
;	-O- AX : 0=前と変わらず,1=ドアを開閉した,2=ドアが開きっぱなし

SCDOOR	PROC	NEAR
	MOV	BX,DUNIT		; ユニット番号
	CMP	DS:DISK_DOOR_INI[BX],0	;
	MOV	DS:DISK_DOOR_INI[BX],0	;
	JNE	SCDOOR_OPNCLS		;

	CMP	DS:DISK_DASD_TBL[BX],DASD_NONE	; 無効ドライブ
	JE	SCDOOR_OPEN		;
	CMP	DS:DISK_DASD_TBL[BX],DASD_NO_LINE  ; ドライブ交換判定できない
	JE	SCDOOR_OPNCLS		;
	CMP	DS:DISK_DASD_TBL[BX],DASD_HARDDISK ; ハードディスク
	JE	SCDOOR_EXIT		;
	CMP	DS:DISK_DASD_TBL[BX],DASD_CHGLINE  ; ドライブ交換判定可
	JNE	SCDOOR_OPNCLS		;

	MOV	DX,DUNIT		; ユニット番号
	MOV	AH,16H			; フロッピーディスクの変更状態の取得
	INT	13H			; DISK bios.

	CMP	AH,00H			; 前と変わらず
	JE	SCDOOR_EXIT		;
	CMP	AH,01H			; 無効
	JE	SCDOOR_OPEN		;
	CMP	AH,06H			; 交換された
	JE	SCDOOR_OPNCLS		;
	CMP	AH,80H			; ドア開きっぱなし
	JE	SCDOOR_OPEN		;

	JMP	SCDOOR_OPEN		;

SCDOOR_EXIT:
	MOV	AX,0			; 0=前と変わらず
	RET
SCDOOR_OPNCLS:
	MOV	AX,1			; 1=ドアを開閉した
	RET
SCDOOR_OPEN:
	MOV	AX,2			; 2=ドアが開きっぱなし
	RET
SCDOOR	ENDP


;	論理レコード・ＲＥＡＤ
;	-I- AX		: 論理レコード番号
;	-O- DATA:[SCDATA] : セクタのデータ
;	    DERROR 	: 0=正常,1=エラー

LODSEC	PROC	NEAR
	MOV	DERROR,0		; 0=正常

	MOV	DX,0			;
	MOV	BX,FD_MAX_SECTOR	; トラック当りのセクタ数
	DIV	BX			; （ＡＸ答え、ＤＸ余り）

	INC	DX			;
	MOV	DSECR,DX		; セクタ番号（Ｒ）

	MOV	DHEAD,AX		; ヘッド番号（Ｈ）
	AND	DHEAD,0001H		; 偶数と奇数

	SHR	AX,1			;
	MOV	DCYL,AX			; シリンダ番号（Ｃ）

	CALL	READSSS			; セクターＲＥＡＤ

	RET
LODSEC	ENDP


;	論理レコード・ＷＲＩＴＥ
;	-I- AX		: 論理レコード番号
;	    DATA:[SCDATA] : セクタのデータ
;	-O- DERROR 	: 0=正常,1=エラー

SAVSEC	PROC	NEAR
	MOV	DERROR,0		; 0=正常

	MOV	DX,0			;
	MOV	BX,FD_MAX_SECTOR	; トラック当りのセクタ数
	DIV	BX			; （ＡＸ答え、ＤＸ余り）

	INC	DX			;
	MOV	DSECR,DX		; セクタ番号（Ｒ）

	MOV	DHEAD,AX		; ヘッド番号（Ｈ）
	AND	DHEAD,0001H		; 偶数と奇数

	SHR	AX,1			;
	MOV	DCYL,AX			; シリンダ番号（Ｃ）

	CALL	WRITESSS		; セクターＷＲＩＴＥ

	RET				;
SAVSEC	ENDP



;	セクターＲＥＡＤ
;	-I- DCYL  : シリンダ番号（Ｃ）０ー７６
;	    DHEAD : ヘッド番号（Ｈ）０ー１
;	    DSECR : セクタ番号（Ｒ）１ー８（２６）
;	-O- DATA:[SCDATA] : セクタのデータ
;	    DERROR : 0=正常,1=エラー
;	-I/O- NOWCYLINDER : 現在のシリンダー
;	      NOWHEAD     : 現在のヘッド

READSSS	PROC	NEAR
	PUSH	DI			;
	PUSH	SI			;
	MOV	DERROR,0		; 0=正常

;*DBG*;	PRVH	"ss DCYL  ",DCYL ; シリンダ番号（Ｃ）
;*DBG*;	PRVH	"ss DHEAD ",DHEAD; ヘッド番号（Ｈ）
;*DBG*;	PRVH	"ss DSECR ",DSECR; セクタ番号（Ｒ）
;*DBG*;	CALL	KESCAP

	MOV	AX,DHEAD		; ヘッド番号（Ｈ）
	CMP	AX,NOWHEAD		; 現在のヘッド
	JNE	READSSS_2		;

	MOV	AX,DCYL			; シリンダ番号（Ｃ）
	CMP	AX,NOWCYLINDER		; 現在のシリンダー
	JE	READSSSGET		;
READSSS_2:

	CALL	FLASHSSS		; シリンダーＦＬＡＳＨ
	CMP	DERROR,0		; 1=エラー
	JNZ	READSSS99		;

	CALL	RDCYLN			; シリンダーＲＥＡＤ
	CMP	DERROR,0		; 1=エラー
	JNZ	READSSS99		;

	MOV	AX,DHEAD		; ヘッド番号（Ｈ）
	MOV	NOWHEAD,AX		; 現在のヘッド

	MOV	AX,DCYL			; シリンダ番号（Ｃ）
	MOV	NOWCYLINDER,AX		; 現在のシリンダー
READSSSGET:
	PUSH	DS			;
	MOV	AX,DSECR		; セクタ番号（Ｒ）
	DEC	AX			; -1
	MUL	FD_LEN_SECTOR		; ×セクタバイト数
	MOV	SI,AX			;
	ADD	SI,RDF_CHASH_OFS	; キャッシュバッファオフセット
	MOVX	ES,DS			; セクタバッファ
	MOV	DI,OFFSET SCDATA	;
	MOV	CX,FD_LEN_SECTOR	; セクタバイト数
	MOVX	DS,RDF_CHASH_SEG	; キャッシュバッファセグメント
	REP	MOVSB			;
	POP	DS			;
READSSS99:
	POP	SI			;
	POP	DI			;
	RET				;
READSSS	ENDP



;	セクターＷＲＩＴＥ
;	-I- DCYL  : シリンダ番号（Ｃ）０ー７６
;	    DHEAD : ヘッド番号（Ｈ）０ー１
;	    DSECR : セクタ番号（Ｒ）１ー８（２６）
;	    DATA:[SCDATA] : セクタのデータ
;	-O- DERROR : 0=正常,1=エラー
;	-I/O- NOWCYLINDER : 現在のシリンダー
;	      MODCYLINDER : 現在のシリンダ内容(0=READ,1=WRITE)

WRITESSS	PROC	NEAR
	PUSH	DI			;
	PUSH	SI			;
	MOV	DERROR,0		; 0=正常

;*DBG*;	PRVH	"ww DCYL  ",DCYL	; シリンダ番号（Ｃ）
;*DBG*;	PRVH	"ww DHEAD ",DHEAD	; ヘッド番号（Ｈ）
;*DBG*;	PRVH	"ww DSECR ",DSECR	; セクタ番号（Ｒ）
;*DBG*;	CALL	KESCAP

	MOV	AX,DCYL			; シリンダ番号（Ｃ）
	CMP	AX,NOWCYLINDER		; 現在のシリンダー
	JE	WRITESSSGET		; ロード済みならばそのままＧＥＴ

	CALL	FLASHSSS		; シリンダーＦＬＡＳＨ
	CMP	DERROR,0		; 1=エラー
	JNZ	WRITESSS99		;

	CALL	RDCYLN			; 新しいシリンダーＲＥＡＤ
	CMP	DERROR,0		; 1=エラー
	JNZ	WRITESSS99		;

	MOV	AX,DCYL			; シリンダ番号（Ｃ）
	MOV	NOWCYLINDER,AX		; 現在のシリンダー
WRITESSSGET:
	MOV	AX,DSECR		; セクタ番号（Ｒ）
	DEC	AX			; -1
	MUL	FD_LEN_SECTOR		; ×セクタバイト数
	MOV	DI,AX			;
	ADD	DI,RDF_CHASH_OFS	; キャッシュバッファオフセット
	MOV	ES,RDF_CHASH_SEG	; キャッシュバッファセグメント
	MOV	SI,OFFSET SCDATA	; セクタバッファ
	MOV	CX,FD_LEN_SECTOR	; セクタバイト数
	REP	MOVSB			;
	MOV	MODCYLINDER,1		; 現在のシリンダ内容 1=WRITE
WRITESSS99:
	POP	SI			;
	POP	DI			;
	RET				;
WRITESSS	ENDP



;	シリンダーＦＬＡＳＨ
;	-I/O- MODCYLINDER : 現在のシリンダ内容(0=READ,1=WRITE)
;	-O-   DERROR : 0=正常,1=エラー

FLASHSSS	PROC	NEAR
	CMP	MODCYLINDER,1		; 現在のシリンダ内容 1=WRITE
	JNE	FLASHSSS_EXIT		;

	PUSH	DCYL			;
	MOV	AX,NOWCYLINDER		; 現在のシリンダーを書き込む
	MOV	DCYL,AX			; シリンダ番号（Ｃ）
	CALL	WTCYLN			; シリンダーＷＲＩＴＥ
	POP	DCYL			;

	MOV	MODCYLINDER,0		; 現在のシリンダ内容 0=READ
FLASHSSS_EXIT:
	RET
FLASHSSS	ENDP



;	シリンダーＲＥＡＤ（高速処理／出力はキャッシュバッファへ）
;	このルーチンは大変デリケートなので扱いに注意して下さい
;
;	-I-   DCYL   : シリンダ番号（Ｃ）
;	      DHEAD  : ヘッド番号（Ｈ）
;	-O-   RDF_CHASH_SEG:[RDF_CHASH_OFS]	: キャッシュバッファ
;	      DERROR : 0=正常,1=エラー

RDCYLN	PROC	NEAR
	MOV	DERROR,0		; 0=正常

	MOVX	DSCNT,FD_MAX_SECTOR	; トラック当りのセクタ数

;*;	PRVH	"RDF_CHASH_SEG",RDF_CHASH_SEG
;*;	PRVH	"RDF_CHASH_OFS=",RDF_CHASH_OFS
;*;	PRVH	"DUNIT=",DUNIT
;*;	PRVH	"DHEAD=",DHEAD
;*;	PRVH	"DCYL=",DCYL
;*;	PRVH	"DSCNT=",DSCNT

	MOV	READ_RETRY,READ_RETCOUNT ; ＲＥＡＤ・リトライ回数
RDCYLN_RETRY:
	MOV	ES,RDF_CHASH_SEG	; キャッシュバッファセグメント
	MOV	BX,RDF_CHASH_OFS	; キャッシュバッファオフセット

	MOV	DL,BYTE PTR DUNIT	; ユニット番号
	MOV	DH,BYTE PTR DHEAD 	; ヘッド番号（Ｈ）
	MOV	CH,BYTE PTR DCYL 	; シリンダ番号（Ｃ）
	MOV	CL,1		 	; セクタ番号（Ｒ）
	MOV	AL,BYTE PTR DSCNT	; セクタ数
	MOV	AH,BYTE PTR DREAD	; ＲＥＡＤ　ＤＡＴＡ
	INT	13H			; ディスクＢＩＯＳ
	JB	RDCYLN_ERROR		;

RDCYLN_EXIT:
	MOV	DERROR,0		; 0=正常
	RET				;

RDCYLN_ERROR:				;
;*;	PRVH	"read sec error AX=",AX

	DEC	READ_RETRY		; ＲＥＡＤ・リトライカウンタ
	JZ	RDCYLN_ER_END		;

	CALL	RECALIBRATE		; ＲＥＣＡＬＩＢＲＡＴＥ

	JMP	RDCYLN_RETRY		;

RDCYLN_ER_END:				;
	MOV	BYTE PTR DSTAT,AH	; ステータス情報
	MOV	DERROR,1		; 1=エラー
	RET				;
RDCYLN	ENDP



;	シリンダーＷＲＩＴＥ（高速処理／キャッシュバッファの内容出力）
;	このルーチンは大変デリケートなので扱いに注意して下さい
;
;	-I-   DCYL   : シリンダ番号（Ｃ）
;	      RDF_CHASH_SEG:[RDF_CHASH_OFS]	: キャッシュバッファ
;	-O-   DERROR : 0=正常,1=エラー

WTCYLN	PROC	NEAR
	MOV	DERROR,0		; 0=正常

	MOVX	DSCNT,FD_MAX_SECTOR	; トラック当りのセクタ数

	MOV	WRITE_RETRY,WRITE_RETCOUNT ; ＷＲＩＴＥ・リトライ回数
WTCYLN_RETRY:
	MOV	ES,RDF_CHASH_SEG	; キャッシュバッファセグメント
	MOV	BX,RDF_CHASH_OFS	; キャッシュバッファオフセット

	MOV	DL,BYTE PTR DUNIT	; ユニット番号
	MOV	DH,0		 	; ヘッド番号（Ｈ）
	MOV	CH,BYTE PTR DCYL 	; シリンダ番号（Ｃ）
	MOV	CL,1		 	; セクタ番号（Ｒ）
	MOV	AL,BYTE PTR DSCNT	; セクタ数
	MOV	AH,BYTE PTR DWRITE	; ＷＲＩＴＥ　ＤＡＴＡ
	INT	13H			; ディスクＢＩＯＳ
	JB	WTCYLN_ERROR		;

WTCYLN_EXIT:
	MOV	DERROR,0		; 0=正常
	RET				;

WTCYLN_ERROR:				;
	DEC	READ_RETRY		; ＲＥＡＤ・リトライカウンタ
	JZ	WTCYLN_ER_END		;
	
	CALL	RECALIBRATE		; ＲＥＣＡＬＩＢＲＡＴＥ

	JMP	WTCYLN_RETRY		;

WTCYLN_ER_END:
	MOV	BYTE PTR DSTAT,AH	; ステータス情報
	MOV	DERROR,1		; 1=エラー
	RET
WTCYLN	ENDP


;	ＲＥＣＡＬＩＢＲＡＴＥ

RECALIBRATE	PROC	NEAR
	MOV	DL,BYTE PTR DUNIT	; ユニット番号 PS/2 only.
	MOV	AH,00H			; DISK RESET.
	INT	13H			; ディスクＢＩＯＳ
	RET
RECALIBRATE	ENDP

;*;CODE	ENDS
;*;
;*;
;*;DATA	SEGMENT	PUBLIC	'DATA'
;*;
;*;EXTRN	RDF_CHASH_SEG:WORD		; キャッシュバッファセグメント
;*;EXTRN	RDF_CHASH_OFS:WORD		; キャッシュバッファオフセット
;*;
;*;EXTRN	FD_LEN_SECTOR:WORD		; セクタバイト数
;*;EXTRN	FD_MAX_SECTOR:WORD		; トラック当りのセクタ数
;*;EXTRN	FD_SEC_P_CLAST:WORD		; クラスタ当りのセクタ数
;*;
;*;EXTRN	SCDATA:BYTE			; セクタバッファ

READ_RETRY	DW	0		; ＲＥＡＤ・リトライカウンタ
WRITE_RETRY	DW	0		; ＷＲＩＴＥ・リトライカウンタ

;		ＢＩＯＳコマンド識別コード

DREAD		DW	02H		; ＲＥＡＤ　ＤＡＴＡ
DWRITE		DW	03H		; ＷＲＩＴＥ　ＤＡＴＡ
DUNIT		DW	0		; ユニット番号

;		ＩＤＲ（ＩＤ情報）

DCYL		DW	0		; シリンダ番号（Ｃ）０ー７６
DHEAD		DW	0		; ヘッド番号（Ｈ）０ー１
DSECR		DW	1		; セクタ番号（Ｒ）１ー８（２６）
DSCNT		DW	15 ;18		; セクタ数
DSTAT		DW	0		; ステータス情報
DERROR		DW	0		; 0=正常,1=エラー

DISK_DOOR_INI	DB	DRIVE_FLAG_CNT DUP (OFF_FLAG) ; ディスク開閉初期ﾌﾗｸﾞ
DISK_DASD_TBL	DB	DRIVE_FLAG_CNT DUP (OFF_FLAG) ; ディスクＤＡＳＤ

NOWCYLINDER	DW	OFF_CYLINDER	; 現在のシリンダー
NOWHEAD		DW	OFF_HEAD	; 現在のヘッド
MODCYLINDER	DW	0		; 現在のシリンダ内容(0=READ,1=WRITE)

DRVNO		DW	0		; drive number.

;*;DATA	ENDS
;*;
;*;	END
;*;;
;*;;	end of "READSC.ASM"
;*;;
;*;; "READCH.ASM" J-3100GS001 make by R.H 1991/05/23
;*;;
;*;;	E X E L O A D    D R I V E    M O D E    c h e n g e .
;*;;
;*;;
;*;; public subroutine.
;*;
;*;INCLUDE	TSTSET.INC

VEC_MPT_OFS	EQU	0078H		; ＭＰＴテーブル・オフセット
VEC_MPT_SEG	EQU	007AH		; ＭＰＴテーブル・セグメント

MPT_TRKTIM1	EQU	0		;0 指定バイト１:トラック間移動時間
MPT_TRKTIM2	EQU	1		;1 指定バイト２:DMAﾓｰﾄﾞ時ﾄﾗｯｸ位置時間
MPT_MOTOROFF	EQU	2		;2 モータＯＦＦ待ち時間
MPT_SECTYP	EQU	3		;3 0=128,1=256,2=512,3=1024
MPT_ENDSEC	EQU	4		;4 最終セクタ番号
MPT_GAPLEN	EQU	5		;5 ギャップ長さ
MPT_DATLEN	EQU	6		;6 データ長さ
MPT_FMTGAP	EQU	7		;7 フォーマットギャップ長さ
MPT_FMTDAT	EQU	8		;8 フォーマットデータ
MPT_HEDSTL	EQU	9		;9 ヘッドセトル時間　単位1/100秒
MPT_MOTORSRT	EQU	10		;A モータ起動時間　単位1/8秒


;*;CODE	SEGMENT	PUBLIC	'CODE'
;*;
;*;	ASSUME	CS:CODE,DS:DATA,ES:DATA
;*;
;*;PUBLIC	SSMSRT		; ドライブ・モード・スタート
;*;PUBLIC	SSMSTP		; ドライブ・モード・ストップ
;*;PUBLIC	SSMMDE		; ドライブ・モード標準設定
;*;
;*;EXTRN	SCDRECA:NEAR	; ドライブ・リキャリブレート

;	ドライブ・モード・スタート

SSMSRT	PROC	NEAR
	CALL	MPT_TBL_COPY		; ＭＰＴテーブルコピー
	CALL	SAVE_VEC_MPT		; ＭＰＴアドレス退避
	CALL	SET_VEC_MPT		; ＭＰＴアドレス設定
	CALL	DISK_RESET		; ディスク・リセット
	RET
SSMSRT	ENDP


;	ドライブ・モード・ストップ

SSMSTP	PROC	NEAR
	CALL	LOAD_VEC_MPT		; ＭＰＴアドレス復元
	CALL	DISK_RESET		; ディスク・リセット
	RET
SSMSTP	ENDP


;	ドライブ・モード標準設定
;	-I- DX : モード
;		1=360KB
;		2=1.2MB
;		3=720KB
;		4=1.44MB
;		5=1.2MB/1024

SSMMDE	PROC	NEAR
	CMP	DX,1
	JMPL	SSMMDE_EXIT
	CMP	DX,5
	JMPG	SSMMDE_EXIT

	MOV	DRVMODE,DX			; モード

	MOV	ES,MPT_TABLE_SEG		; ＭＰＴテーブルセグメント
	MOV	DI,MPT_TABLE_OFS		; ＭＰＴテーブルオフセット
	MOV	SI,DRVMODE			; モード
	SHL	SI,1				; word pointer.
	MOVXB	ES:[DI][MPT_SECTYP],<BYTE PTR DS:TBD_MPT_SECTYP[SI]> ;ｾｸﾀﾀｲﾌﾟ
	MOVXB	ES:[DI][MPT_ENDSEC],<BYTE PTR DS:TBD_MPT_ENDSEC[SI]> ;最終ｾｸﾀ

	MOVX	FD_FAT_CLAST,	DS:TBD_FAT_CLAST[SI] ; ＦＡＴテーブルクラスタ
	MOVX	FD_ROOT_CLAST,	DS:TBD_ROOT_CLAST[SI]; ＲＯＯＴＤＩＲクラスタ		MOVX	FD_DIRMAX,	DS:TBD_DIRMAX[SI]    ; ディレクトリ最大数
	MOVX	FD_CLAST_OFFSET,DS:TBD_CLAST_OFS[SI] ; 開始セクタオフセット
	MOVX	FD_MIN_CLAST,	DS:TBD_MIN_CLAST[SI] ; 最小クラスタ番号
	MOVX	FD_MAX_CLAST,	DS:TBD_MAX_CLAST[SI] ; 最大クラスタ番号
	MOVX	FD_LEN_CLAST,	DS:TBD_LEN_CLAST[SI] ; クラスタバイト数
	MOVX	FD_LEN_SECTOR,	DS:TBD_LEN_SECTOR[SI] ; セクタバイト数
	MOVX	FD_MAX_SECTOR,	DS:TBD_MAX_SECTOR[SI] ; トラック当りのセクタ数
	MOVX	FD_SEC_P_CLAST,	DS:TBD_SEC_P_CLAST[SI]; クラスタ当りのセクタ数

	MOV	AX,OFFSET ROOTBUF	; ＦＡＴ＋ＲＯＯＴバッファ
	MOV	RDF_FAT,AX		; ＦＡＴグローバルアドレス

	MOV	DX,0			;
	MOV	AX,FD_FAT_CLAST 	; ＦＡＴテーブルクラスタ数
	MUL	FD_LEN_CLAST		; クラスタバイト数
	ADD	AX,OFFSET ROOTBUF	; ＦＡＴ＋ＲＯＯＴバッファ
	MOV	RDF_ROOT,AX		; ＲＯＯＴグローバルアドレス

	MOV	AX,FD_LEN_CLAST		; クラスタバイト数
	MOV	CLST_R_LENGTH,AX	; 読みクラスタバイト数
	MOV	CLST_W_LENGTH,AX	; 書きクラスタバイト数

	CALL	DISK_RESET		; ディスク・リセット

SSMMDE_EXIT:
	RET
SSMMDE	ENDP


;	ＭＰＴテーブルコピー

MPT_TBL_COPY	PROC	NEAR
	PUSH	DS

	MOV	AX,0			;
	MOV	ES,AX			;
	MOV	SI,ES:[VEC_MPT_OFS]	; ＭＰＴテーブル・オフセット
	MOV	AX,ES:[VEC_MPT_SEG]	; ＭＰＴテーブル・セグメント
	MOV	DI,MPT_TABLE_OFS	; ＭＰＴテーブルオフセット
	MOV	BX,MPT_TABLE_SEG	; ＭＰＴテーブルセグメント

	MOV	CX,MPT_TABLE_LEN	; ＭＰＴテーブル長さ
	MOV	DS,AX			;
	MOV	ES,BX			;
	REP	MOVSB			;

	POP	DS
	RET
MPT_TBL_COPY	ENDP


;	ＭＰＴアドレス設定

SET_VEC_MPT	PROC	NEAR
	CLI
	MOV	AX,0			;
	MOV	ES,AX			;

	MOV	AX,MPT_TABLE_OFS	; ＭＰＴテーブルオフセット
	MOV	BX,MPT_TABLE_SEG	; ＭＰＴテーブルセグメント
	MOV	ES:[VEC_MPT_OFS],AX	; ＭＰＴテーブル・オフセット
	MOV	ES:[VEC_MPT_SEG],BX	; ＭＰＴテーブル・セグメント
	STI
	RET
SET_VEC_MPT	ENDP


;	ＭＰＴアドレス退避

SAVE_VEC_MPT	PROC	NEAR
	CLI
	MOV	AX,0
	MOV	ES,AX
	MOV	AX,ES:[VEC_MPT_OFS]	; ＭＰＴテーブル・オフセット
	MOV	BX,ES:[VEC_MPT_SEG]	; ＭＰＴテーブル・セグメント
	MOV	SAVE_MPT_OFS,AX		; ＭＰＴオフセット退避
	MOV	SAVE_MPT_SEG,BX		; ＭＰＴセグメント退避
	STI
	RET
SAVE_VEC_MPT	ENDP


;	ＭＰＴアドレス復元

LOAD_VEC_MPT	PROC	NEAR
	CLI
	MOV	AX,0			;
	MOV	ES,AX			;
	MOV	AX,SAVE_MPT_OFS		; ＭＰＴオフセット退避
	MOV	BX,SAVE_MPT_SEG		; ＭＰＴセグメント退避
	MOV	ES:[VEC_MPT_OFS],AX	; ＭＰＴテーブル・オフセット
	MOV	ES:[VEC_MPT_SEG],BX	; ＭＰＴテーブル・セグメント
	STI
	RET
LOAD_VEC_MPT	ENDP


;	ディスク・リセット

DISK_RESET	PROC	NEAR
	CALL	SCDRECA			; ドライブ・リキャリブレート
	RET
DISK_RESET	ENDP


;*;CODE	ENDS
;*;
;*;
;*;DATA	SEGMENT	PUBLIC	'DATA'
;*;
;*;PUBLIC	FD_FAT_CLAST 			; ＦＡＴテーブルクラスタ数
;*;PUBLIC	FD_ROOT_CLAST 			; ＲＯＯＴＤＩＲクラスタ数
;*;PUBLIC	FD_DIRMAX			; ディレクトリ最大数
;*;PUBLIC	FD_CLAST_OFFSET		; クラスタ開始位置のセクタオフセット
;*;PUBLIC	FD_MIN_CLAST			; 最小クラスタ番号
;*;PUBLIC	FD_MAX_CLAST			; 最大クラスタ番号
;*;PUBLIC	FD_LEN_CLAST			; クラスタバイト数
;*;
;*;PUBLIC	FD_LEN_SECTOR			; セクタバイト数
;*;PUBLIC	FD_MAX_SECTOR			; トラック当りのセクタ数
;*;PUBLIC	FD_SEC_P_CLAST			; クラスタ当りのセクタ数
;*;
;*;EXTRN	CLST_R_LENGTH:WORD		; 読みクラスタバイト数
;*;EXTRN	CLST_W_LENGTH:WORD		; 書きクラスタバイト数
;*;
;*;EXTRN	MPT_TABLE_LEN:WORD		; ＭＰＴテーブル長さ
;*;EXTRN	MPT_TABLE_SEG:WORD		; ＭＰＴテーブルセグメント
;*;EXTRN	MPT_TABLE_OFS:WORD		; ＭＰＴテーブルオフセット
;*;
;*;EXTRN	RDF_FAT:WORD			; ＦＡＴグローバルアドレス
;*;EXTRN	RDF_ROOT:WORD			; ＲＯＯＴグローバルアドレス
;*;EXTRN	ROOTBUF:BYTE			; ＦＡＴ＋ＲＯＯＴバッファ
;*;

;	ＦＤドライブ情報

FD_FAT_CLAST 	DW	14		; ＦＡＴテーブルクラスタ数
FD_ROOT_CLAST 	DW	14		; ＲＯＯＴＤＩＲクラスタ数
FD_DIRMAX	DW	224		; ディレクトリ最大数
FD_CLAST_OFFSET	DW	1+14+14-2	; クラスタ開始位置のセクタオフセット
FD_MIN_CLAST	DW	2		; 最小クラスタ番号
FD_MAX_CLAST	DW	18*2*80-27-1	; 最大クラスタ番号
FD_LEN_CLAST	DW	512		; クラスタバイト数

FD_LEN_SECTOR	DW	512		; セクタバイト数
FD_MAX_SECTOR	DW	18		; トラック当りのセクタ数
FD_SEC_P_CLAST	DW	1		; クラスタ当りのセクタ数


SAVE_MPT_OFS	DW	0		; ＭＰＴオフセット退避
SAVE_MPT_SEG	DW	0		; ＭＰＴセグメント退避

DRVMODE		DW	0		; モード

;	ドライブタイプテーブル
;	この情報は、まだ未確認の部分が多いので注意して下さい。
;		1=360KB
;		2=1.2MB
;		3=720KB
;		4=1.44MB
;		5=1.2MB/1024
;			  0   1   2   3   4   5
TBD_MPT_SECTYP	DW	  0,  2,  2,  2,  2,  3	; 0=128,1=256,2=512,3=1024
TBD_MPT_ENDSEC	DW	  0,  9, 15,  9, 18,  8	; 最終セクタ番号
TBD_FAT_CLAST 	DW	  0,  4, 14,  6, 18,  4	; ＦＡＴテーブルクラスタ数
TBD_ROOT_CLAST 	DW	  0,  7, 14,  7, 14,  6	; ＲＯＯＴＤＩＲクラスタ数
TBD_DIRMAX	DW	  0,112,224,112,224,192	; ディレクトリ最大数
TBD_CLAST_OFS	LABEL	WORD		; クラスタ開始位置のセクタオフセット
		DW	0			;0
		DW	1+  4+  7- 2		;1
		DW	1+ 14+ 14- 2		;2
		DW	1+  6+  7- 2		;3
		DW	1+ 18+ 14- 2		;4
		DW	1+  4+  6- 2 		;5
;		1=360KB
;		2=1.2MB
;		3=720KB
;		4=1.44MB
;		5=1.2MB/1024
TBD_MIN_CLAST	DW	  0,  2,  2,  2,  2,  2	; 最小クラスタ番号
TBD_MAX_CLAST	LABEL	WORD			; 最大クラスタ番号
		DW	0			;0
		DW	9*2*40-27-1		;1
		DW	15*2*80-27-1		;2
		DW	9*2*80-27-1		;3
		DW	18*2*80-27-1		;4
		DW	8*2*77-9-1		;5
TBD_LEN_CLAST	DW	  0,1024,512,1024,512,1024	; クラスタバイト数
TBD_LEN_SECTOR	DW	  0,512,512,512,512,1024	; セクタバイト数
TBD_MAX_SECTOR	DW	  0,  9, 15,  9, 18,  8	; トラック当りのセクタ数
TBD_SEC_P_CLAST	DW	  0,  2,  1,  2,  1,  1	; クラスタ当りのセクタ数

;*;DATA	ENDS
;*;
;*;	END
;*;;
;*;;	end of "READCH.ASM"
;*;;
;*;; "READBF.ASM" J-3100GS001 make by R.H 1990/09/25,1991/04/05
;*;;
;*;;	E X E L O A D    D I S K    b u f f e r.
;*;;
;*;;
;*;; public subroutine.

SIZE_FAT_ROOT	EQU	512*40 ;14*2		; FAT+ROOTテーブルサイズ
SIZE_CHASH_BUFF	EQU	512*18			; キャッシュバッファサイズ
SIZE_SECTOR_BUF	EQU	1024 ;512		; セクタバッファサイズ
SIZE_CLAST_BUFF	EQU	1024 ;512		; クラスタバッファのサイズ

;*;;	ディスクキャッシュバッファ
;*;
;*;CHASH1	SEGMENT	PUBLIC	'CHASH1'
;*;
;*;CHASH_BUFFER1	DB	SIZE_CHASH_BUFF	DUP (0)
;*;
;*;CHASH1	ENDS
;*;
;*;
;*;DATA	SEGMENT	PUBLIC	'DATA'
;*;
;*;PUBLIC	RDF_CHASH_SEG			; キャッシュバッファセグメント
;*;PUBLIC	RDF_CHASH_OFS			; キャッシュバッファオフセット
;*;PUBLIC	MPT_TABLE_LEN			; ＭＰＴテーブル長さ
;*;PUBLIC	MPT_TABLE_SEG			; ＭＰＴテーブルセグメント
;*;PUBLIC	MPT_TABLE_OFS			; ＭＰＴテーブルオフセット
;*;PUBLIC	RDF_FAT				; ＦＡＴグローバルアドレス
;*;PUBLIC	RDF_ROOT			; ＲＯＯＴグローバルアドレス
;*;PUBLIC	ROOTBUF				; ＦＡＴ＋ＲＯＯＴバッファ
;*;PUBLIC	SCDATA				; セクタバッファ
;*;PUBLIC	CLST_R_BUFF			; 読みクラスタバッファ
;*;PUBLIC	CLST_R_BUFF_END			; 読みクラスタバッファの後ろ
;*;PUBLIC	CLST_R_LENGTH			; 読みクラスタバイト数
;*;PUBLIC	CLST_W_BUFF			; 書きクラスタバッファ
;*;PUBLIC	CLST_W_BUFF_END			; 書きクラスタバッファの後ろ
;*;PUBLIC	CLST_W_LENGTH			; 書きクラスタバイト数


;*;RDF_CHASH_SEG DW	SEG CHASH1	; キャッシュバッファセグメント
RDF_CHASH_SEG	DW	0		; キャッシュバッファセグメント
RDF_CHASH_OFS	DW	CHASH_BUFFER1	; キャッシュバッファオフセット

MPT_TABLE_LEN	DW	11		; ＭＰＴテーブル長さ
;*;MPT_TABLE_SEG DW	SEG DATA	; ＭＰＴテーブルセグメント
MPT_TABLE_SEG	DW	0		; ＭＰＴテーブルセグメント
MPT_TABLE_OFS	DW	MPT_TABLE	; ＭＰＴテーブルオフセット
MPT_TABLE	LABEL	BYTE		; ＭＰＴテーブル
		DB	0		;0 指定バイト１:トラック間移動時間
		DB	0		;1 指定バイト２:DMAﾓｰﾄﾞ時ﾄﾗｯｸ位置時間
		DB	0		;2 モータＯＦＦ待ち時間
		DB	0		;3 0=128,1=256,2=512,3=1024
		DB	0		;4 最終セクタ番号
		DB	0		;5 ギャップ長さ
		DB	0		;6 データ長さ
		DB	0		;7 フォーマットギャップ長さ
		DB	0		;8 フォーマットデータ
		DB	0		;9 ヘッドセトル時間　単位1/100秒
		DB	0		;A モータ起動時間　単位1/8秒
		DB	0		;dummy.

		EVEN
RDF_FAT		DW	ROOTBUF			; ＦＡＴグローバルアドレス
RDF_ROOT	DW	ROOTBUF+512*14		; ＲＯＯＴグローバルアドレス

CLST_R_LENGTH	DW	512			; 読みクラスタバイト数
CLST_W_LENGTH	DW	512			; 書きクラスタバイト数
;*;
;*;ROOTBUF	DB	SIZE_FAT_ROOT DUP (0)	; ＦＡＴ＋ＲＯＯＴバッファ
;*;
;*;SCDATA		DB	SIZE_SECTOR_BUF DUP (0)	; セクタバッファ
;*;		DB	0,0			;
;*;
;*;CLST_R_BUFF	DB	SIZE_CLAST_BUFF DUP (0)	; 読みクラスタバッファ
;*;CLST_R_BUFF_END	LABEL	BYTE		; 読みクラスタバッファの後ろ
;*;
;*;CLST_W_BUFF	DB	SIZE_CLAST_BUFF DUP (0)	; 書きクラスタバッファ
;*;CLST_W_BUFF_END	LABEL	BYTE		; 書きクラスタバッファの後ろ
;*;
;*;DATA	ENDS
;*;
;*;	END
;*;;
;*;;	end of "READBF.ASM"
;*;;




;****************************************************************
;*	E X E L O A D						*
;****************************************************************


;	text init.

TEXT_INIT	PROC	NEAR
	MOV	AL,DISPLY_MODE		; disply mode set.
	MOV	AH,00H			; mode set.
	INT	10H			; IBM bios.

	MOV	CH,0			; up line.
	MOV	CL,0			; left side.
	MOV	DH,DISPLY_LIN_MAX	; disply line max.
	MOV	DL,DISPLY_CLM_MAX	; disply colum nax.
	MOV	BH,00001111B		; attrbute.
	MOV	AL,0			; 1 line.
	MOV	AH,06H			; window scroll up.
	INT	10H			; IBM bios.
	RET
TEXT_INIT	ENDP


;	i*2 value -> hexdecimal string.
;	-i- DX : i*2 value
;	-o- SI : string address.
;	        NULL=end of string.

HEXSTR	PROC	NEAR
	PUSH	AX
	PUSH	BX
	PUSH	CX

	MOV	SI,OFFSET BUFFER

	MOV	AL,DH
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	CALL	HEXSTR3
	MOV	AL,DH
	CALL	HEXSTR3

	MOV	AL,DL
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	SHR	AL,1
	CALL	HEXSTR3
	MOV	AL,DL
	CALL	HEXSTR3

	MOV	BYTE PTR [SI],0	;null.
	MOV	SI,OFFSET BUFFER		;string adrs.

	POP	CX
	POP	BX
	POP	AX
	RET

HEXSTR3:AND	AL,0FH
	CMP	AL,0AH	;if AL<0ah then
	JB	HEXSTR4
	ADD	AL,07H  ; ascii 'A'-'F'
HEXSTR4:ADD	AL,30H  ; ascii '0'-'9'
	MOV	BYTE PTR [SI],AL
	INC	SI
	RET

HEXSTR	ENDP



;	print of string.
;	-i- SI : string address.
;		NULL=end of string.

PRINT	PROC	NEAR

	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX

	PUSH	DI
	PUSH	SI
	PUSH	ES

	CALL	MESSAGE

	POP	ES
	POP	SI
	POP	DI

	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET
PRINT	ENDP


;	message put.
;	-i- SI : string address.
;		NULL=end of string.

MESSAGE	PROC	NEAR
MESSAGE_LOOP:
	CALL	COULOC			; locate.
	LODSB				; get 1 char.
	CMP	AL,0			; end of string?
	JE	MESSAGE_LP_E		;
	CMP	AL,CHR_LF		; LF.
	JE	MESSAGE_LF		;

	CALL	PUTCHR			; put character.
	INC	LOCX			; locate X.
	CMP	LOCX,DISPLY_CLM_MAX	; disply colum nax.
	JLE	MESSAGE_NEXT		;
MESSAGE_LF:
	MOV	LOCX,0			;
	INC	LOCY
MESSAGE_NEXT:
	JMP	MESSAGE_LOOP		;
MESSAGE_LP_E:				;
	RET
MESSAGE	ENDP


;	put character.
;	-i- AL : character.

PUTCHR	PROC	NEAR
	PUSH	SI

	MOV	BX,TEXT_ATTR		; text attrbute.
	MOV	CX,1			; character length.

	MOV	AH,09H			; character & attrbute write.
	INT	10H			; IBM bios.

	POP	SI
	RET
PUTCHR	ENDP


;	locate.
;	-i- LOCX : locate X.
;	    LOCY : locate Y.

COULOC	PROC	NEAR
	PUSH	SI
	PUSH	DX
	PUSH	BX
	MOV	DL,LOCX			; locate X.
	MOV	DH,LOCY			; locate Y.
	MOV	BX,0			; page.
	MOV	AH,02H			; coursole set.
	INT	10H			; IBM bios.
	POP	BX
	POP	DX
	POP	SI
	RET
COULOC	ENDP


; line feed.

LFPRN	PROC	NEAR
	PUSH	SI
	MOV	SI,OFFSET LFP1
	CALL	PRINT
	POP	SI
	RET
LFPRN	ENDP

LFP1	DB	0DH,0AH,0

;	data.

LOCX		DB	0		; locate X.
LOCY		DB	0		; locate Y.

;	message.

MESSAGE_TOP:
DB	"[ ] EXELOAD/world-PC ver0.25"
DB	" (C) R.Hashimoto 1989,1990,1991 in tokyo japan."
DB	CHR_LF
DB	0

MESSAGE_ERROR:
DB	"************************************************",CHR_LF
DB	"* system error.                                *",CHR_LF
DB	"* 1.'AUTOEXEC.EXE' not found ?                 *",CHR_LF
DB	"* 2. floppy crash ?                            *",CHR_LF
DB	"* 3. not PC ?                                  *",CHR_LF
DB	"*   E X E L O A D . S Y S   break.             *",CHR_LF
DB	"************************************************",CHR_LF
DB	CHR_LF
DB	0


DBGTAG	DB	"SYSTEM END",0


;****************************************************************
;*	E X E L O A D						*
;****************************************************************

SYSEND		LABEL	FAR			; system code end.

;****************************************************************
;*	E X E L O A D						*
;****************************************************************

;	not load area.

		EVEN

;	ディスクキャッシュバッファ
		EVEN
CHASH_BUFFER1	DB	SIZE_CHASH_BUFF	DUP (0)

ROOTBUF		DB	SIZE_FAT_ROOT DUP (0)	; ＦＡＴ＋ＲＯＯＴバッファ
SCDATA		DB	SIZE_SECTOR_BUF DUP (0)	; セクタバッファ
		DB	0,0			;
CLST_R_BUFF	DB	SIZE_CLAST_BUFF DUP (0)	; 読みクラスタバッファ
CLST_R_BUFF_END	LABEL	BYTE			; 読みクラスタバッファの後ろ
CLST_W_BUFF	DB	SIZE_CLAST_BUFF DUP (0)	; 書きクラスタバッファ
CLST_W_BUFF_END	LABEL	BYTE			; 書きクラスタバッファの後ろ
BUFFER		DB	256 DUP (0)		; buffer.

;****************************************************************
;*	E X E L O A D						*
;****************************************************************

		EVEN
SYSEND_ALL	LABEL	BYTE		; システムの終わり（空きバッファ含む）

;****************************************************************
;*	E X E L O A D						*
;****************************************************************

		DB	SEC_BYTE DUP (0)	; clear after.

CODSYS	ENDS

	END
;
;	end of "CODSYS.ASM"
;
