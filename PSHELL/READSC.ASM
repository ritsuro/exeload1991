; "READSC.ASM" J-3100GS001 make by R.H 1990/09/25,1991/04/02
;
;	E X E L O A D    S E C T O R   R e a d / W r i t e    c a l l .
;
;
; public subroutine.

INCLUDE	TSTSET.INC

DRIVE_FLAG_CNT	EQU	8		; ドライブ・フラグ数

READ_RETCOUNT 	EQU	3		; ＲＥＡＤ・リトライ回数
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

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,ES:DATA

PUBLIC	SCINIT		; レコードＩ／Ｏ初期化
PUBLIC	SCREAD		; レコード・ＲＥＡＤ
PUBLIC	SCWRITE		; レコード・ＷＲＩＴＥ
PUBLIC	SCFLASH		; レコード・ＦＬＡＳＥ
PUBLIC	SCRDIPL		; ＩＰＬ・ＲＥＡＤ
PUBLIC	SCDRRST		; ドライブ・リセット
PUBLIC	SCDRECA		; ドライブ・リキャリブレート
PUBLIC	SCDRSET		; ドライブ番号の設定
PUBLIC	SCDRNO		; ドライブ番号の取得
PUBLIC	SCDOOR		; ドライブドアチェック


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


;	ＩＰＬ・ＲＥＡＤ
;	-O- ES : ＩＰＬテーブルセグメント
;	    BX : ＩＰＬテーブルオフセット
;	-O- AX : 0=正常,1=エラー

SCRDIPL	PROC	NEAR
	CALL	RDIPL			; ＩＰＬ　ＲＥＡＤ
	MOV	ES,IPL_TABLE_SEG	; ＩＰＬテーブルセグメント
	MOV	BX,IPL_TABLE_OFS	; ＩＰＬテーブルオフセット
	MOV	AX,DERROR		; 0=正常,1=エラー
	RET
SCRDIPL	ENDP


;	ドライブ・リセット
;	-I- AX : １ＭＦＤドライブ番号（０ー３）
;	-O- AX : 0=正常,1=ドライブ番号エラー

SCDRRST	PROC	NEAR
	MOV	NOWCYLINDER,OFF_CYLINDER	; 現在のシリンダー
	MOV	NOWHEAD,OFF_HEAD		; 現在のヘッド

	CMP	AX,DRIVE_FLAG_CNT		; ドライブ・フラグ数
	JNB	SCDRRST_NUM_ERROR		;

	MOV	BX,AX				; １ＭＦＤドライブ番号
	MOV	DS:DISK_DOOR_INI[BX],OFF_FLAG	; ディスク開閉初期ﾌﾗｸﾞ

SCDRRST_NORMAL:
	MOV	AX,0		; 0=正常
	RET
SCDRRST_NUM_ERROR:
	MOV	AX,1		; 1=ドライブ番号エラー
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

;*;	PRVH	"ss DCYL  ",DCYL ; シリンダ番号（Ｃ）
;*;	PRVH	"ss DHEAD ",DHEAD; ヘッド番号（Ｈ）
;*;	PRVH	"ss DSECR ",DSECR; セクタ番号（Ｒ）
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

;*;	PRVH	"ww DCYL  ",DCYL	; シリンダ番号（Ｃ）
;*;	PRVH	"ww DHEAD ",DHEAD	; ヘッド番号（Ｈ）
;*;	PRVH	"ww DSECR ",DSECR	; セクタ番号（Ｒ）
;*DBG*;	CALL	KESCAP

	MOV	AX,DHEAD		; ヘッド番号（Ｈ）
	CMP	AX,NOWHEAD		; 現在のヘッド
	JNE	WRITESSS_2		;

	MOV	AX,DCYL			; シリンダ番号（Ｃ）
	CMP	AX,NOWCYLINDER		; 現在のシリンダー
	JE	WRITESSSGET		; ロード済みならばそのままＧＥＴ
WRITESSS_2:				;

	CALL	FLASHSSS		; シリンダーＦＬＡＳＨ
	CMP	DERROR,0		; 1=エラー
	JNZ	WRITESSS99		;

	CALL	RDCYLN			; 新しいシリンダーＲＥＡＤ
	CMP	DERROR,0		; 1=エラー
	JNZ	WRITESSS99		;

	MOV	AX,DHEAD		; ヘッド番号（Ｈ）
	MOV	NOWHEAD,AX		; 現在のヘッド

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
;*;	PRV	"FLASHSSS MODCYLINDER=",MODCYLINDER
	CMP	MODCYLINDER,1		; 現在のシリンダ内容 1=WRITE
	JNE	FLASHSSS_EXIT		;

	PUSH	DCYL			;
	PUSH	DHEAD			;
	MOV	AX,NOWCYLINDER		; 現在のシリンダーを書き込む
	MOV	DCYL,AX			; シリンダ番号（Ｃ）
	MOV	AX,NOWHEAD		; 現在のヘッド
	MOV	DHEAD,AX		; ヘッド番号（Ｈ）
	CALL	WTCYLN			; シリンダーＷＲＩＴＥ
	POP	DHEAD			;
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
	MOV	BYTE PTR DSTAT,AH	; ステータス情報
	JB	RDCYLN_ERROR		;

RDCYLN_EXIT:
	MOV	DERROR,0		; 0=正常
	RET				;

RDCYLN_ERROR:				;
;*DBG*;	PRVH	"read sec error AX=",AX

	DEC	READ_RETRY		; ＲＥＡＤ・リトライカウンタ
	JZ	RDCYLN_ER_END		;

	CALL	RECALIBRATE		; ＲＥＣＡＬＩＢＲＡＴＥ

	JMP	RDCYLN_RETRY		;

RDCYLN_ER_END:				;
	MOV	DERROR,1		; 1=エラー
	RET				;
RDCYLN	ENDP



;	シリンダーＷＲＩＴＥ（高速処理／キャッシュバッファの内容出力）
;	このルーチンは大変デリケートなので扱いに注意して下さい
;
;	-I-   DCYL   : シリンダ番号（Ｃ）
;	      DHEAD  : ヘッド番号（Ｈ）
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
	AND	DL,11B			;
	MOV	DH,BYTE PTR DHEAD 	; ヘッド番号（Ｈ）
	MOV	CH,BYTE PTR DCYL 	; シリンダ番号（Ｃ）
	MOV	CL,1		 	; セクタ番号（Ｒ）
	MOV	AL,BYTE PTR DSCNT	; セクタ数
	MOV	AH,BYTE PTR DWRITE	; ＷＲＩＴＥ　ＤＡＴＡ
	INT	13H			; ディスクＢＩＯＳ
	MOV	BYTE PTR DSTAT,AH	; ステータス情報
	JB	WTCYLN_ERROR		;

WTCYLN_EXIT:
	MOV	DERROR,0		; 0=正常
	RET				;

WTCYLN_ERROR:				;
;*;	PRVH	"write sec error AX=",AX

	DEC	WRITE_RETRY		; ＷＲＩＴＥ・リトライカウンタ
	JZ	WTCYLN_ER_END		;
	
	CALL	RECALIBRATE		; ＲＥＣＡＬＩＢＲＡＴＥ

	JMP	WTCYLN_RETRY		;

WTCYLN_ER_END:
	MOV	DERROR,1		; 1=エラー
	RET
WTCYLN	ENDP


;	ＩＰＬ　ＲＥＡＤ
;	このルーチンは大変デリケートなので扱いに注意して下さい
;
;	-O-   IPL_TABLE_SEG:[IPL_TABLE_OFS]	; ＩＰＬテーブル
;	      DERROR : 0=正常,1=エラー

RDIPL	PROC	NEAR
	MOV	DERROR,0		; 0=正常

	MOVX	DSCNT,FD_MAX_SECTOR	; トラック当りのセクタ数
	MOV	READ_RETRY,READ_RETCOUNT ; ＲＥＡＤ・リトライ回数
RDIPL_RETRY:
	MOV	ES,IPL_TABLE_SEG	; ＩＰＬテーブルセグメント
	MOV	BX,IPL_TABLE_OFS	; ＩＰＬテーブルオフセット

	MOV	DL,BYTE PTR DUNIT	; ユニット番号
	MOV	DH,0			; 0=ヘッド番号（Ｈ）
	MOV	CH,0			; 0=シリンダ番号（Ｃ）
	MOV	CL,1		 	; 1=セクタ番号（Ｒ）
	MOV	AL,1			; 1=セクタ数
	MOV	AH,BYTE PTR DREAD	; ＲＥＡＤ　ＤＡＴＡ
	INT	13H			; ディスクＢＩＯＳ
	MOV	BYTE PTR DSTAT,AH	; ステータス情報
	JB	RDIPL_ERROR		;

RDIPL_EXIT:
	MOV	DERROR,0		; 0=正常
	RET				;
RDIPL_ERROR:				;
	DEC	READ_RETRY		; ＲＥＡＤ・リトライカウンタ
	JZ	RDIPL_ER_END		;
	CALL	RECALIBRATE		; ＲＥＣＡＬＩＢＲＡＴＥ
	JMP	RDIPL_RETRY		;
RDIPL_ER_END:				;
	MOV	DERROR,1		; 1=エラー
	RET				;
RDIPL	ENDP


;	ＲＥＣＡＬＩＢＲＡＴＥ

RECALIBRATE	PROC	NEAR
	MOV	DL,BYTE PTR DUNIT	; ユニット番号 PS/2 only.
	MOV	AH,00H			; DISK RESET.
	INT	13H			; ディスクＢＩＯＳ
	RET
RECALIBRATE	ENDP

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

EXTRN	RDF_CHASH_SEG:WORD		; キャッシュバッファセグメント
EXTRN	RDF_CHASH_OFS:WORD		; キャッシュバッファオフセット

EXTRN	IPL_TABLE_LEN:WORD		; ＩＰＬテーブル長さ
EXTRN	IPL_TABLE_SEG:WORD		; ＩＰＬテーブルセグメント
EXTRN	IPL_TABLE_OFS:WORD		; ＩＰＬテーブルオフセット

EXTRN	FD_LEN_SECTOR:WORD		; セクタバイト数
EXTRN	FD_MAX_SECTOR:WORD		; トラック当りのセクタ数
EXTRN	FD_SEC_P_CLAST:WORD		; クラスタ当りのセクタ数

EXTRN	SCDATA:BYTE			; セクタバッファ

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

DATA	ENDS

	END
;
;	end of "READSC.ASM"
;
