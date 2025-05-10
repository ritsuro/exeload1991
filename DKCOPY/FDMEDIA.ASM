; "FDMEDIA.ASM" J-3100GS001 make by R.H 1991/05/23
;
;	E X E L O A D    D R I V E    M O D E    c h e n g e .
;
;
; public subroutine.

INCLUDE	TSTSET.INC

SIZE_SECTOR_BUF	EQU	512		; セクタバッファサイズ

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

IPL_BYTE_SEC_W	EQU	0BH		;+0Bh byte/sector.
IPL_SEC_CLAST_B	EQU	0DH		;+0Dh sector/clast.
IPL_RESRV_SEC_W	EQU	0EH		;+0Eh reserved sector.
IPL_FAT_COPY_B	EQU	10H		;+10h FAT copy count.
IPL_ROOT_DIR_W	EQU	11H		;+11h root dir entry count.
IPL_FULL_SEC_W	EQU	13H		;+13h full sector count.
IPL_MEDIA_DSC_B	EQU	15H		;+15h dos media discripta.
IPL_SEC_FAT_W	EQU	16H		;+16h sector/FAT.
IPL_SEC_TRK_W	EQU	18H		;+18h sector/track.
IPL_HEAD_CNT_W	EQU	1AH		;+1Ah head count.
IPL_DARK_SEC_W	EQU	1CH		;+1Ch dark sector.


CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,ES:DATA

PUBLIC	SSMSRT		; ドライブ・モード・スタート
PUBLIC	SSMSTP		; ドライブ・モード・ストップ
PUBLIC	SSMMDE		; ドライブ・モード標準設定
PUBLIC	SSMMDA		; ドライブ・ディスクメディア・チェック

EXTRN	TRACKRDIPL:NEAR	; IPL read.
EXTRN	TRACKRESET:NEAR	; drive reset.


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

	CALL	DISK_RESET			; ディスク・リセット

	MOV	ES,MPT_TABLE_SEG		; ＭＰＴテーブルセグメント
	MOV	DI,MPT_TABLE_OFS		; ＭＰＴテーブルオフセット
	MOV	SI,DRVMODE			; モード
	SHL	SI,1				; word pointer.
	MOVXB	ES:[DI][MPT_SECTYP],<BYTE PTR DS:TBD_MPT_SECTYP[SI]> ;ｾｸﾀﾀｲﾌﾟ
	MOVXB	ES:[DI][MPT_ENDSEC],<BYTE PTR DS:TBD_MPT_ENDSEC[SI]> ;最終ｾｸﾀ

 MOV BYTE PTR ES:[DI][MPT_TRKTIM1],223 ;0 指定バイト１:トラック間移動時間
 MOV BYTE PTR ES:[DI][MPT_TRKTIM2],2	 ;1 指定バイト２:DMAﾓｰﾄﾞ時ﾄﾗｯｸ位置時間
 MOV BYTE PTR ES:[DI][MPT_MOTOROFF],37 ;2 モータＯＦＦ待ち時間
 MOV BYTE PTR ES:[DI][MPT_GAPLEN],27	 ;5 ギャップ長さ
 MOV BYTE PTR ES:[DI][MPT_DATLEN],255	 ;6 データ長さ
 MOV BYTE PTR ES:[DI][MPT_FMTGAP],100	 ;7 フォーマットギャップ長さ
 MOV BYTE PTR ES:[DI][MPT_FMTDAT],0F6H ;8 フォーマットデータ
 MOV BYTE PTR ES:[DI][MPT_HEDSTL],15	 ;9 ヘッドセトル時間　単位1/100秒
 MOV BYTE PTR ES:[DI][MPT_MOTORSRT],4	 ;A モータ起動時間　単位1/8秒

	MOVX	FD_FAT_SECTOR,	DS:TBD_FAT_SECTOR[SI] ; ＦＡＴテーブルセクタ
	MOVX	FD_ROOT_SECTOR,	DS:TBD_ROOT_SECTOR[SI]; ＲＯＯＴＤＩＲクラスタ		MOVX	FD_DIRMAX,	DS:TBD_DIRMAX[SI]    ; ディレクトリ最大数
	MOVX	FD_CLAST_OFFSET,DS:TBD_CLAST_OFS[SI] ; 開始セクタオフセット
	MOVX	FD_MIN_CLAST,	DS:TBD_MIN_CLAST[SI] ; 最小クラスタ番号
	MOVX	FD_MAX_CLAST,	DS:TBD_MAX_CLAST[SI] ; 最大クラスタ番号
	MOVX	FD_LEN_CLAST,	DS:TBD_LEN_CLAST[SI] ; クラスタバイト数
	MOVX	FD_LEN_SECTOR,	DS:TBD_LEN_SECTOR[SI] ; セクタバイト数
	MOVX	FD_MAX_SECTOR,	DS:TBD_MAX_SECTOR[SI] ; トラック当りのセクタ数
	MOVX	FD_SEC_P_CLAST,	DS:TBD_SEC_P_CLAST[SI]; クラスタ当りのセクタ数

	MOV	DX,0			;
	MOV	AX,FD_FAT_SECTOR 	; ＦＡＴテーブルセクタ数
	MUL	FD_LEN_SECTOR		; セクタバイト数

	MOV	AX,FD_LEN_CLAST		; クラスタバイト数
	MOV	CLST_R_LENGTH,AX	; 読みクラスタバイト数
	MOV	CLST_W_LENGTH,AX	; 書きクラスタバイト数

	CALL	DISK_RESET		; ディスク・リセット

SSMMDE_EXIT:
	RET
SSMMDE	ENDP


;	ドライブ・ディスクメディア・チェック
;	-O- DX : ディスクメディア
;		1=360KB
;		2=1.2MB
;		3=720KB
;		4=1.44MB
;		5=1.2MB/1024
;	    AX : 0=正常,1=エラー

SSMMDA	PROC	NEAR
	MOV	DX,IPL_TABLE_SEG	; ＩＰＬテーブルセグメント
	MOV	DI,IPL_TABLE_OFS	; ＩＰＬテーブルオフセット
	CALL	TRACKRDIPL		; IPL read.
	CMP	AX,0			; 0=正常,1=エラー
	JNE	SSMMDA_ERROR		;

	MOV	ES,IPL_TABLE_SEG	; ＩＰＬテーブルセグメント
	MOV	BX,IPL_TABLE_OFS	; ＩＰＬテーブルオフセット
	MOV	AL,ES:[BX][IPL_MEDIA_DSC_B]	;+15h dos media discripta.
	MOV	AH,ES:[BX][IPL_SEC_TRK_W]	;+18h sector/track.

SSMMDA_CHK1:
	CMP	AL,0FDH			; dos media discripta.
	JNE	SSMMDA_CHK2		;
	CMP	AH,9			; 9=sector/track.
	JNE	SSMMDA_CHK2		;
	JMP	SSMMDA_360K
SSMMDA_CHK2:
	CMP	AL,0F9H			; dos media discripta.
	JNE	SSMMDA_CHK3		;
	CMP	AH,15			; 15=sector/track.
	JNE	SSMMDA_CHK3		;
	JMP	SSMMDA_12MB
SSMMDA_CHK3:
	CMP	AL,0F9H			; dos media discripta.
	JNE	SSMMDA_CHK4		;
	CMP	AH,9			; 9=sector/track.
	JNE	SSMMDA_CHK4		;
	JMP	SSMMDA_720K
SSMMDA_CHK4:
	CMP	AL,0F0H			; dos media discripta.
	JNE	SSMMDA_CHK5		;
	CMP	AH,18			; 18=sector/track.
	JNE	SSMMDA_CHK5		;
	JMP	SSMMDA_144MB
SSMMDA_CHK5:
	CMP	AL,0FEH			; dos media discripta.
	JNE	SSMMDA_CHK6		;
	CMP	AH,8			; 8=sector/track.
	JNE	SSMMDA_CHK6		;
	JMP	SSMMDA_12MB1024
SSMMDA_CHK6:

	JMP	SSMMDA_ERROR

SSMMDA_360K:
	MOV	DX,1			; 1=360KB
	JMP	SSMMDA_EXIT		;
SSMMDA_12MB:
	MOV	DX,2			; 2=1.2MB
	JMP	SSMMDA_EXIT		;
SSMMDA_720K:
	MOV	DX,3			; 3=720KB
	JMP	SSMMDA_EXIT		;
SSMMDA_144MB:
	MOV	DX,4			; 4=1.44MB
	JMP	SSMMDA_EXIT		;
SSMMDA_12MB1024:
	MOV	DX,5			; 5=1.2MB/1024
	JMP	SSMMDA_EXIT		;
SSMMDA_EXIT:
	MOV	AX,0			; 0=正常
	RET
SSMMDA_ERROR:
	MOV	AX,1			; 1=エラー
	RET
SSMMDA	ENDP


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
	CALL	TRACKRESET		; drive reset.
	RET
DISK_RESET	ENDP


CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

PUBLIC	FD_FAT_SECTOR 			; ＦＡＴテーブルセクタ数
PUBLIC	FD_ROOT_SECTOR 			; ＲＯＯＴＤＩＲセクタ数
PUBLIC	FD_DIRMAX			; ディレクトリ最大数
PUBLIC	FD_CLAST_OFFSET			; クラスタ開始位置のセクタオフセット
PUBLIC	FD_MIN_CLAST			; 最小クラスタ番号
PUBLIC	FD_MAX_CLAST			; 最大クラスタ番号
PUBLIC	FD_LEN_CLAST			; クラスタバイト数

PUBLIC	FD_LEN_SECTOR			; セクタバイト数
PUBLIC	FD_MAX_SECTOR			; トラック当りのセクタ数
PUBLIC	FD_SEC_P_CLAST			; クラスタ当りのセクタ数

PUBLIC	CLST_R_LENGTH			; 読みクラスタバイト数
PUBLIC	CLST_W_LENGTH			; 書きクラスタバイト数


;	ＦＤドライブ情報

FD_FAT_SECTOR 	DW	14		; ＦＡＴテーブルセクタ数
FD_ROOT_SECTOR 	DW	14		; ＲＯＯＴＤＩＲセクタ数
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
TBD_FAT_SECTOR 	DW	  0,  4, 14,  6, 18,  4	; ＦＡＴテーブルセクタ数
TBD_ROOT_SECTOR	DW	  0,  7, 14,  7, 14,  6	; ＲＯＯＴＤＩＲセクタ数
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
		DW	(9*2*40-10)/2		;1
		DW	15*2*80-27		;2
		DW	(9*2*80-12)/2		;3
		DW	18*2*80-31		;4
		DW	8*2*77-9-1		;5
TBD_LEN_CLAST	DW	  0,1024,512,1024,512,1024	; クラスタバイト数
TBD_LEN_SECTOR	DW	  0,512,512,512,512,1024	; セクタバイト数
TBD_MAX_SECTOR	DW	  0,  9, 15,  9, 18,  8	; トラック当りのセクタ数
TBD_SEC_P_CLAST	DW	  0,  2,  1,  2,  1,  1	; クラスタ当りのセクタ数

CLST_R_LENGTH	DW	512			; 読みクラスタバイト数
CLST_W_LENGTH	DW	512			; 書きクラスタバイト数

MPT_TABLE_LEN	DW	11		; ＭＰＴテーブル長さ
MPT_TABLE_SEG	DW	SEG DATA	; ＭＰＴテーブルセグメント
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

IPL_TABLE_SEG	DW	SEG DATA		; ＩＰＬテーブルセグメント
IPL_TABLE_OFS	DW	IPL_BUFFER		; ＩＰＬテーブルオフセット
IPL_BUFFER	DB	SIZE_SECTOR_BUF DUP (0)	; ＩＰＬセクタバッファ

DATA	ENDS

	END
;
;	end of "FDMEDIA.ASM"
;
