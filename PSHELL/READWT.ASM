; "READWT.ASM" J-3100GS001 make by R.H 1990/09/25,1991/04/02
;
;	E X E L O A D    D I S K    R e a d / W r i t e    c a l l .
;
;
; public subroutine.

INCLUDE	TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,ES:DATA

PUBLIC	SSRINI		; ドライブ初期処理

PUBLIC	SSRDRV		; ドライブ番号の設定（０ー３）
PUBLIC	SSRDNO		; ドライブ番号の取得（０ー３）
PUBLIC	SSRRST		; ドライブのリセット（０ー３）

			; ＤＩＲ
PUBLIC	SSRDIR		; ＦＡＴ＋ＲＯＯＴの読み出し
PUBLIC	SSWDIR		; ＦＡＴ＋ＲＯＯＴの書き込み

			; ＲＥＡＤ
PUBLIC	SSRSRT		; ファイルの先頭クラスタ番号の取り出し	(OPEN)
PUBLIC	SSRRED		; クラスタの読み出し			(READ)

			; ＷＲＩＴＥ
PUBLIC	SSWENT		; ディレクトリ・エントリの取得		(OPEN)
PUBLIC	SSWWRT		; クラスタの書き込み			(WRITE)
PUBLIC	SSWEOF		; クラスタの書き込み終了		(EOF)
PUBLIC	SSWSET		; エントリ・データの書き込み		(CLOSE)

			; ＫＩＬＬ
PUBLIC	SSKILL		; ファイルの削除

			; ＴＯＯＬＳ
PUBLIC	SSDSKF		; ディスクの空きクラスタ数
PUBLIC	SSDSKS		; ドライブ情報
PUBLIC	SSFDDV		; ＦＤドライブドア開閉チェック

EXTRN	SCINIT:NEAR	; レコードＩ／Ｏ初期化
EXTRN	SCREAD:NEAR	; レコード・ＲＥＡＤ
EXTRN	SCWRITE:NEAR	; レコード・ＷＲＩＴＥ
EXTRN	SCFLASH:NEAR	; レコード・ＦＬＡＳＥ
EXTRN	SCDRRST:NEAR	; ドライブ・リセット
EXTRN	SCDRNO:NEAR	; ドライブ番号の取得
EXTRN	SCDRSET:NEAR	; ドライブ番号の設定
EXTRN	SCDOOR:NEAR	; ドライブドアチェック

EXTRN	SSMMDE:NEAR	; ドライブ・モード標準設定
EXTRN	SSMMDA:NEAR	; ドライブ・ディスクメディア・チェック

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

	CMP	DERROR,1		; 1=エラー
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
	MOV	DERROR,AX		; 0=正常,1=エラー
	CMP	DERROR,0		; 1=エラー
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
	CMP	DERROR,0		; 1=エラー
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

	CMP	DERROR,1		; 1=エラー
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
	CMP	DERROR,0		; 1=エラー
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

	CALL	CNTFRE			; 空きクラスタ数を調べる

	MOV	DX,FRE_CLAST		; 空きクラスタ数
	MOV	AX,0			; 0=正常
	RET				;
SSDSKF_ERROR:
	MOV	DX,0			;
	MOV	AX,2			; 2=ディスクエラー
	RET				;
SSDSKF	ENDP


;	ドライブ情報
;	-O- DS:BX  : ディスク情報テーブルアドレス
;	    AX     : 0=正常, 2=ディスクエラー
;
;	ディスク情報テーブル
;	DS:SI->	[ セクタ数／１クラスタ   ]
;		[ 空きクラスタ数         ]
;		[ バイト数／１セクタ     ]
;		[ クラスタ数／１ドライブ ]

SSDSKS	PROC	NEAR
	MOVX	DISK_INFORMATION,FD_SEC_P_CLAST	  ; クラスタ当りのセクタ数
	MOV	DISK_INFORMATION[2],0		  ; 空きクラスタ数
	MOVX	DISK_INFORMATION[4],FD_LEN_SECTOR ; セクタバイト数
	MOVX	DISK_INFORMATION[6],FD_MAX_CLAST  ; 最大クラスタ番号

	CALL	SSDSKF				; ディスクの空きクラスタ数
	CMP	AX,0				;
	JNE	SSDSKS_ERROR			;

	MOV	DISK_INFORMATION[2],DX		; 空きクラスタ数

SSDSKS_EXIT:
	MOV	SI,OFFSET DISK_INFORMATION	; ディスク情報テーブル
	MOV	AX,0				; 0=正常
	RET
SSDSKS_ERROR:
	MOV	SI,OFFSET DISK_INFORMATION	; ディスク情報テーブル
	MOV	AX,2				; 2=ディスクエラー
	RET
SSDSKS	ENDP


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
;	    DERROR	: 0=正常,1=エラー

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
	MOV	DERROR,0		; 0=正常
	RET				;
LODCLS_ERROR:
	POP	CX
	MOV	DERROR,1		; 1=エラー
	RET
LODCLS	ENDP


;	クラスタセーブ
;	-I- PNTNOW	: 現在のクラスタ番号
;	    CLAST_ADRS  : クラスタバッファアドレス
;	-O- DERROR	: 0=正常,1=エラー

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
	MOV	DERROR,0		; 0=正常
	RET				;
SAVCLS_ERROR:
	POP	CX			;
	MOV	DERROR,1		; 1=エラー
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
	CMP	DERROR,1		; ディスクエラー
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
	CMP	DERROR,0		; 1=エラー
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
;	-O-   DERROR 		: 0=正常,1=エラー

LOAD_FDTOP	PROC	NEAR
	PUSH	SI			;

	MOV	DERROR,0		; 0=正常

	CALL	SCDRNO			; ドライブ番号の取得
	MOV	DNUMBER,AX		; ドライブ番号

	CALL	FDDOOR			; ＦＤドライブドア開閉チェック

	CMP	AX,0			; 0=前と変わらず,1=ドアを開閉した
	JNE	LOAD_FDTOP_LOAD		; 2=ドアが開きっぱなし

	CMPX	NOW_FAT_DRIVE,DNUMBER	; 現在のＦＡＴドライブ番号
	JE	LOAD_FDTOP_EXIT		;

LOAD_FDTOP_LOAD:			;
	MOVX	NOW_FAT_DRIVE,DNUMBER	; 現在のＦＡＴドライブ番号

	MOV	AX,DNUMBER		; 現在のＦＡＴドライブ番号
	CALL	SCDRRST			; ドライブ・リセット

	MOV	AX,DNUMBER		; 現在のＦＡＴドライブ番号
	CALL	FDDOOR			; ＦＤドライブドア開閉チェック

	CALL	SSMMDA			; ドライブ・ディスクメディア・チェック
	CALL	SSMMDE			; ドライブ・モード標準設定

	CALL	LODFAT			; ＦＡＴ＆ＲＯＯＴロード

LOAD_FDTOP_EXIT:
	POP	SI			;
	RET				;
LOAD_FDTOP	ENDP



;	ＦＡＴ＋ＲＯＯＴのセーブ
;	-I/O- MODROOTFAT : 現在のROOT&FAT内容(0=READ,1=WRITE)
;	-O-   DERROR : 0=正常,1=エラー

SAVE_FDTOP	PROC	NEAR
	MOV	DERROR,0		; 0=正常,1=エラー

;*;	PRV	"#### SAVE_FDTOP MODROOTFAT=",MODROOTFAT
;*;	INP	"WAIT"

	CMP	MODROOTFAT,1		; 現在のROOT&FAT内容(0=READ,1=WRITE)
	JNE	SAVE_FDTOP_EXIT		;

	CALL	SAVFAT			; ＦＡＴ＆ＲＯＯＴセーブ
	CMP	DERROR,0		; 1=エラー
	JNE	SAVE_FDTOP_EXIT		;

	CALL	SCFLASH			; レコード・ＦＬＡＳＥ
	MOV	DERROR,AX		; 0=正常,1=エラー
	CMP	DERROR,0		; 1=エラー
	JNE	SAVE_FDTOP_EXIT		;

	MOV	MODROOTFAT,0		; 現在のROOT&FAT内容(0=READ,1=WRITE)
SAVE_FDTOP_EXIT:
	RET
SAVE_FDTOP	ENDP



;	ＦＡＴ＆ＲＯＯＴロード
;	（ＦＡＴとＲＯＯＴディレクトリは連続しています）
;	-O- DERROR 	: 0=正常,1=エラー

LODFAT	PROC	NEAR
	MOV	DERROR,0		; 0=正常

;*;	PRV	"FD_LEN_CLAST=",FD_LEN_CLAST
;*;	PRV	"FD_LEN_SECTOR=",FD_LEN_SECTOR
;*;	INP	"WAIT"

	MOVX	ES,DS			;
	MOV	DI,RDF_FAT		; ＦＡＴグローバルアドレス

	MOV	RECNUM,1		; レコード番号
	MOV	CX,FD_FAT_SECTOR	; ＦＡＴ＋ＲＯＯＴセクタ数
	ADD	CX,FD_ROOT_SECTOR	;
LODFAT2:				;
	PUSH	CX			;
	MOV	AX,RECNUM		; レコード番号
	PUSH	ES			;
	PUSH	DI			;
	CALL	SCREAD			; レコード・ＲＥＡＤ
	MOV	DERROR,AX		; 0=正常,1=エラー
	POP	DI			;
	POP	ES			;
	MOV	SI,OFFSET SCDATA	;
	MOV	CX,FD_LEN_SECTOR	; セクタバイト数
	REP	MOVSB			;
	POP	CX			;
	CMP	DERROR,1		; エラー
	JE	LODFAT_ERROR		;
	INC	RECNUM			; レコード番号
	LOOP	LODFAT2			;
	RET
LODFAT_ERROR:				; エラー
	RET				;
LODFAT	ENDP


;	ＦＡＴ＆ＲＯＯＴセーブ
;	（ＦＡＴとＲＯＯＴディレクトリは連続しています）
;	-O- DERROR 	: 0=正常,1=エラー

SAVFAT	PROC	NEAR
	MOV	DERROR,0		; 0=正常

	MOV	SI,RDF_FAT		; ＦＡＴグローバルアドレス

	MOV	RECNUM,1		; レコード番号
	MOV	CX,FD_FAT_SECTOR	; ＦＡＴ＋ＲＯＯＴセクタ数
	ADD	CX,FD_ROOT_SECTOR	;
SAVFAT2:				;
	PUSH	CX			;
	MOVX	ES,DS			;
	MOV	DI,OFFSET SCDATA	;
	MOV	CX,FD_LEN_SECTOR	; セクタバイト数
	REP	MOVSB			;
	MOV	AX,RECNUM		; レコード番号
	PUSH	SI			;
	CALL	SCWRITE			; レコード・ＷＲＩＴＥ
	MOV	DERROR,AX		; 0=正常,1=エラー
	POP	SI			;
	POP	CX			;
	CMP	DERROR,1		; エラー
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
	CMP	DERROR,1		; ディスクエラー
	JE	SSRDRV_ERROR		;

SSRDRV2:
	MOV	AX,BX			; １ＭＦＤドライブ番号
	CALL	SCDRSET			; ドライブ番号の設定

	CALL	LOAD_FDTOP		; ＦＡＴ＋ＲＯＯＴのロード

	CMP	DERROR,1		; ディスクエラー
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


;	ドライブのリセット（０ー３）
;	-I- AX : １ＭＦＤドライブ番号（０ー３）
;	-O- AX : 0=正常,1=ドライブ番号エラー,2=ディスクエラー

SSRRST	PROC	NEAR
	PUSH	BX			;
	PUSH	CX			;
	PUSH	DX			;
	PUSH	DI			;
	PUSH	SI			;
	PUSH	ES			;

	MOV	RESET_DRIVE,AX		; リセットドライブ番号
	CALL	SCDRRST			; ドライブ・リセット

	POP	ES			;
	POP	SI			;
	POP	DI			;
	POP	DX			;
	POP	CX			;
	POP	BX			;
	RET
SSRRST	ENDP



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

CODE	ENDS



DATA	SEGMENT	PUBLIC	'DATA'

EXTRN	FD_FAT_SECTOR:WORD		; ＦＡＴテーブルセクタ数
EXTRN	FD_ROOT_SECTOR:WORD		; ＲＯＯＴＤＩＲセクタ数
EXTRN	FD_DIRMAX:WORD			; ディレクトリ最大数
EXTRN	FD_CLAST_OFFSET:WORD		; クラスタ開始位置のセクタオフセット
EXTRN	FD_MIN_CLAST:WORD		; 最小クラスタ番号
EXTRN	FD_MAX_CLAST:WORD		; 最大クラスタ番号
EXTRN	FD_LEN_CLAST:WORD		; クラスタバイト数

EXTRN	FD_SEC_P_CLAST:WORD		; クラスタ当りのセクタ数

EXTRN	FD_LEN_SECTOR:WORD		; セクタバイト数

EXTRN	RDF_FAT:WORD			; ＦＡＴグローバルアドレス
EXTRN	RDF_ROOT:WORD			; ＲＯＯＴグローバルアドレス
EXTRN	SCDATA:BYTE			; セクタバッファ

DISK_INFORMATION	LABEL	WORD	; ディスク情報テーブル
		DW	0		;[ セクタ数／１クラスタ   ]
		DW	0		;[ 空きクラスタ数         ]
		DW	0		;[ バイト数／１セクタ     ]
		DW	0		;[ クラスタ数／１ドライブ ]

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
DERROR		DW	0		; 0=正常,1=エラー

RESET_DRIVE	DW	0		; リセットドライブ番号

FLNAME		DB	FLNLEN DUP (20H)	; ファイル名
FLTYPE		DB	FLTLEN DUP (20H)	; 拡張子
		DB	0,0			;

DATA	ENDS

	END

;
;	end of "READWT.ASM"
;
