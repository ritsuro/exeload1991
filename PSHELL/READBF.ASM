; "READBF.ASM" J-3100GS001 make by R.H 1990/09/25,1991/04/05
;
;	E X E L O A D    D I S K    b u f f e r.
;
;
; public subroutine.

SIZE_FAT_ROOT	EQU	512*40 ;14*2		; FAT+ROOTテーブルサイズ
SIZE_CHASH_BUFF	EQU	512*18			; キャッシュバッファサイズ
SIZE_SECTOR_BUF	EQU	1024 ;512		; セクタバッファサイズ
SIZE_CLAST_BUFF	EQU	1024 ;512		; クラスタバッファのサイズ

;	ディスクキャッシュバッファ

CHASH1	SEGMENT	PUBLIC	'CHASH1'

CHASH_BUFFER1	DB	SIZE_CHASH_BUFF	DUP (0)

CHASH1	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

PUBLIC	RDF_CHASH_SEG			; キャッシュバッファセグメント
PUBLIC	RDF_CHASH_OFS			; キャッシュバッファオフセット
PUBLIC	MPT_TABLE_LEN			; ＭＰＴテーブル長さ
PUBLIC	MPT_TABLE_SEG			; ＭＰＴテーブルセグメント
PUBLIC	MPT_TABLE_OFS			; ＭＰＴテーブルオフセット
PUBLIC	IPL_TABLE_LEN			; ＩＰＬテーブル長さ
PUBLIC	IPL_TABLE_SEG			; ＩＰＬテーブルセグメント
PUBLIC	IPL_TABLE_OFS			; ＩＰＬテーブルオフセット
PUBLIC	RDF_FAT				; ＦＡＴグローバルアドレス
PUBLIC	RDF_ROOT			; ＲＯＯＴグローバルアドレス
PUBLIC	ROOTBUF				; ＦＡＴ＋ＲＯＯＴバッファ
PUBLIC	SCDATA				; セクタバッファ
PUBLIC	CLST_R_BUFF			; 読みクラスタバッファ
PUBLIC	CLST_R_BUFF_END			; 読みクラスタバッファの後ろ
PUBLIC	CLST_R_LENGTH			; 読みクラスタバイト数
PUBLIC	CLST_W_BUFF			; 書きクラスタバッファ
PUBLIC	CLST_W_BUFF_END			; 書きクラスタバッファの後ろ
PUBLIC	CLST_W_LENGTH			; 書きクラスタバイト数


RDF_CHASH_SEG	DW	SEG CHASH1	; キャッシュバッファセグメント
RDF_CHASH_OFS	DW	CHASH_BUFFER1	; キャッシュバッファオフセット

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

IPL_TABLE_LEN	DW	11			; ＩＰＬテーブル長さ
IPL_TABLE_SEG	DW	SEG DATA		; ＩＰＬテーブルセグメント
IPL_TABLE_OFS	DW	IPL_BUFFER		; ＩＰＬテーブルオフセット
IPL_BUFFER	DB	SIZE_SECTOR_BUF DUP (0)	; ＩＰＬセクタバッファ

		EVEN
RDF_FAT		DW	ROOTBUF			; ＦＡＴグローバルアドレス
RDF_ROOT	DW	ROOTBUF+512*14		; ＲＯＯＴグローバルアドレス

CLST_R_LENGTH	DW	512			; 読みクラスタバイト数
CLST_W_LENGTH	DW	512			; 書きクラスタバイト数

ROOTBUF		DB	SIZE_FAT_ROOT DUP (0)	; ＦＡＴ＋ＲＯＯＴバッファ

SCDATA		DB	SIZE_SECTOR_BUF DUP (0)	; セクタバッファ
		DB	0,0			;

CLST_R_BUFF	DB	SIZE_CLAST_BUFF DUP (0)	; 読みクラスタバッファ
CLST_R_BUFF_END	LABEL	BYTE			; 読みクラスタバッファの後ろ

CLST_W_BUFF	DB	SIZE_CLAST_BUFF DUP (0)	; 書きクラスタバッファ
CLST_W_BUFF_END	LABEL	BYTE			; 書きクラスタバッファの後ろ

DATA	ENDS

	END
;
;	end of "READBF.ASM"
;
