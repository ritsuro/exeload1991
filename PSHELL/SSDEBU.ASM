; "SSDEBU.ASM" PC-9801UV11 make by R.H 1989/11/10
;
;	E X E L O A D     D E B U G   c o m m a n d .
;
;
; command.

INCLUDE	TSTSET.INC

CALL_NM	MACRO	NUM,LBL
	LOCAL	L1
	CMP	DX,NUM
	JNE	L1
	PUSH	DX
	CALL	LBL
	POP	DX
L1:
	ENDM


CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,ES:DATA

PUBLIC	CMDBIO			; バイオスデバック
PUBLIC	CMDMPT			; ＭＰＴテーブルデバック
PUBLIC	CMDDMD			; ドライブモード
PUBLIC	CMDFDS			; ＦＤドライブ情報

EXTRN	FWREST:NEAR		; ディスクのリセット

EXTRN	SSMMDE:NEAR		; ドライブ・モード標準設定


; *********************************************************
;	ＭＰＴテーブルデバック
; *********************************************************

CMDMPT	PROC	NEAR
	MOV	ES,MPT_TABLE_SEG		; ＭＰＴテーブルセグメント
	MOV	DI,MPT_TABLE_OFS		; ＭＰＴテーブルオフセット

	PRBYTE	"トラック間移動   =",ES:[DI]
	LF
	PRBYTE	"DMAﾓｰﾄﾞ時ﾄﾗｯｸ位置=",ES:[DI][1]
	LF
	PRBYTE	"モータＯＦＦ待ち =",ES:[DI][2]
	LF
	PRBYTE	"0=128,1=256,2=512,3=1024:",ES:[DI][3]
	LF
	PRBYTE	"最終セクタ番号   =",ES:[DI][4]
	LF
	PRBYTE	"ギャップ長さ     =",ES:[DI][5]
	LF
	PRBYTE	"データ長さ       =",ES:[DI][6]
	LF
	PRBYTE	"フォーマットギャップ長さ=",ES:[DI][7]
	LF
	PRBYTEH	"フォーマットデータ=",ES:[DI][8]
	PRF	"h"
	PRBYTE	"ヘッドセトル時間 =",ES:[DI][9]
	LF
	PRBYTE	"モータ起動時間　 =",ES:[DI][10]
	LF
	RET
CMDMPT	ENDP


; *********************************************************
;	バイオスデバック
; *********************************************************

CMDBIO	PROC	NEAR

CMDBIO_START:
	PRF	"1.13h/15h disk type read"
	PRF	"2.13h/08h disk drive parameter"
	PRF	"3.13h/16h FD change check"
	PRF	"4.F000:FFFE Bios model"
CMDBIO_INP:
	INP	"[Q:EXIT]="
	CALL	STRDEC
	CMP	DX,0
	JE	CMDBIO_START

	CALL_NM	1,DISK_TYPE_READ		; disk type read.
	CALL_NM	2,DISK_DRIVE_PARA		; disk drive parameter.
	CALL_NM	3,FD_CHANGE_CHK			; FD change check.
	CALL_NM 4,BIOS_MODEL			; Bios model.

	JMP	CMDBIO_INP
	RET
CMDBIO	ENDP


; *********************************************************
;	disk type read.
; *********************************************************

DISK_TYPE_READ	PROC	NEAR

	PRF	"int13H/AH=15H:0none,1:stdFD,2:hiFD,3:HARD"

	MOV	DRVNO,0		; drive number.
	MOV	CX,8
DISK_TYPE_READ_LOOP:
	PUSH	CX

	MOV	DX,DRVNO	; drive number.
	CALL	DECSTR		;
	ADD	SI,4		;
	CALL	PRINT		;
	PR	":"		;

	MOV	DX,DRVNO	; drive number.
	MOV	AH,15H		; ディスクタイプの取得
	INT	13H		; DISK bios.

	JC	DISK_TYPE_READ_CF

	CMP	AH,00H		;
	JE	DISK_TYPE_READ_NONE
	CMP	AH,01H		;
	JE	DISK_TYPE_READ_STDFD
	CMP	AH,02H		;
	JE	DISK_TYPE_READ_HI
	CMP	AH,03H		;
	JE	DISK_TYPE_READ_HARD

	JMP	DISK_TYPE_READ_ANTHER

DISK_TYPE_READ_NONE:
	PR	"none."
	JMP	DISK_TYPE_READ_7
DISK_TYPE_READ_STDFD:
	PR	"stdFD"
	JMP	DISK_TYPE_READ_7
DISK_TYPE_READ_HI:
	PR	"hi-FD"
	JMP	DISK_TYPE_READ_7
DISK_TYPE_READ_HARD:
	PR	"HDisk"
	JMP	DISK_TYPE_READ_7
DISK_TYPE_READ_CF:
	PR	"off"
	JMP	DISK_TYPE_READ_7
DISK_TYPE_READ_ANTHER:
	MOV	DX,AX		;
	CALL	HEXSTR		;
	MOV	BYTE PTR [SI][2],0
	CALL	PRINT		;
	JMP	DISK_TYPE_READ_7
DISK_TYPE_READ_7:
	PR	" "

	INC	DRVNO		; drive number.
	POP	CX
	LOOPX	DISK_TYPE_READ_LOOP
	LF
	RET
DISK_TYPE_READ	ENDP


; *********************************************************
;	disk drive parameter.
; *********************************************************

DISK_DRIVE_PARA	PROC	NEAR
 PRF	"int13H/AH=08H"
 PR	"type 1=5inch360KB,2=5inch1.2MB,3=3.5inch720KB,4=3.5inch1.44MB"

	MOV	DRVNO,0		; drive number.
	MOV	CX,8
DISK_DRIVE_PARA_LOOP:
	PUSH	CX

	TEST	DRVNO,1		; drive number.
	JNZ	DISK_DRIVE_PARA_2
	LF
DISK_DRIVE_PARA_2:


	PR	"("		;
	MOV	DX,DRVNO	; drive number.
	CALL	DECSTR		;
	ADD	SI,4		;
	CALL	PRINT		;
	PR	":"		;

	MOV	DX,DRVNO	; drive number.
	MOV	AH,08H		; ディスクドライブのパラメータ取得
	INT	13H		; DISK bios.

	PRBYTE	"count",DL
	PRBYTE	"hd",DH
	PRBYTE	"cyl",CH
	PRBYTE	"secmx",CL
	PRBYTE	"typ",BL
	PR	")"		;

	INC	DRVNO		; drive number.
	POP	CX
	LOOPX	DISK_DRIVE_PARA_LOOP
	LF
	RET
DISK_DRIVE_PARA	ENDP


; *********************************************************
;	FD change check
; *********************************************************

FD_CHANGE_CHK	PROC	NEAR

	PRF	"int13H/AH=16H"

	MOV	DRVNO,0		; drive number.
	MOV	CX,8
FD_CHANGE_CHK_LOOP:
	PUSH	CX

	MOV	DX,DRVNO	; drive number.
	CALL	DECSTR		;
	ADD	SI,4		;
	CALL	PRINT		;
	PR	":"		;

	MOV	DX,DRVNO	; drive number.
	MOV	AH,16H		; フロッピーディスクの変更状態の取得
	INT	13H		; DISK bios.

	CMP	AH,00H		;
	JE	FD_CHANGE_CHK_SET
	CMP	AH,01H		;
	JE	FD_CHANGE_CHK_ERR
	CMP	AH,06H		;
	JE	FD_CHANGE_CHK_DOOR
	CMP	AH,80H		;
	JE	FD_CHANGE_CHK_NOTRDY

	JMP	FD_CHANGE_CHK_ANTHER
FD_CHANGE_CHK_SET:
	PR	"Set"
	JMP	FD_CHANGE_CHK_7
FD_CHANGE_CHK_ERR:
	PR	"Err"
	JMP	FD_CHANGE_CHK_7	;
FD_CHANGE_CHK_DOOR:
	PR	"Dor"
	JMP	FD_CHANGE_CHK_7	;
FD_CHANGE_CHK_NOTRDY:
	PR	"Not"
	JMP	FD_CHANGE_CHK_7	;
FD_CHANGE_CHK_ANTHER:
	MOV	DX,AX		;
	CALL	HEXSTR		;
	MOV	BYTE PTR [SI][2],0
	CALL	PRINT		;
	JMP	FD_CHANGE_CHK_7	;

FD_CHANGE_CHK_7:
	PR	" "

	INC	DRVNO		; drive number.
	POP	CX
	LOOPX	FD_CHANGE_CHK_LOOP
	LF
	RET
FD_CHANGE_CHK	ENDP


; *********************************************************
;	Bios model.
; *********************************************************

BIOS_MODEL	PROC	NEAR
	MOVX	ES,0F000H
	MOV	DI,0FFFEH
	MOV	DL,ES:[DI]		; model number byte.

	CALL	HEXSTR
	ADD	SI,2
	CALL	PRINT
	PR	":"

	MOV	AH,0C0H			; system parameter.
	INT	15H			;

	MOV	AH,ES:[BX][3]		; sub model byte.
	CALL	PRNAH			; print ah reg.
	PR	":"

	MOV	AH,ES:[BX][4]		; release.
	CALL	PRNAH			; print ah reg.
	PR	":"

	MOV	DL,ES:[BX][4]		; status bit.
	CALL	BINSTR
	ADD	SI,8
	CALL	PRINT
	LF

	PRF	"FF -- -- IBM PC (all)"
	PRF	"FE -- -- IBM PC/XT & PORTABLE PC (1982/11/8)"
	PRF	"FD -- -- IBM PCjr (all)"
	PRF	"FC -- -- IBM PC/AT (1984/1/10)"
	PRF	"   00 01 IBM PC/AT (1985/6/10)"
	PRF	"   01 00 IBM PC/AT (1985/11/15)"
	PRF	"   04 00 IBM PS/2 Model 50 (first model)"
	PRF	"   05 00 IBM PS/2 Model 60 (first model)"
	PRF	"   02 00 IBM PC/XT286 (all)"
	PRF	"FB 00 01 IBM PC/XT (1986/1/10)"
	PRF	"   00 02 IBM PC/XT (1986/5/9)"
	PRF	"FA 00 00 IBM PS/2 Model 30 (1986/9/2)"
	PRF	"F9 00 00 IBM PC Convertible (1985/9/13)"
	PRF	"F8 00 00 IBM PS/2 Model 80 (first)"
	PRF	"   01 00 IBM PS/2 Model 80 (first)"
	PRF	"FE -- -- Compaq DeskPro"
	PRF	"2D -- -- Compaq PORTABLE"
	PRF	"9A -- -- Compaq PORTABLE Puls"
	PRF	"4B -- -- MegaBIOS ROM (Disply Telecom)"
	PRF	"B6 -- -- HP110 PORTABLE (original)"

	RET
BIOS_MODEL	ENDP


; *********************************************************
;	ドライブモード
; *********************************************************

CMDDMD	PROC	NEAR

	INP	"1=360KB,2=1.2MB,3=720KB,4=1.44MB,5=1.2MB/1024 : "
	CALL	STRDEC
				; -I- DX : モード
	CALL	SSMMDE		; ドライブ・モード標準設定
	CALL	FWREST		; ディスクのリセット
	RET
CMDDMD	ENDP


; *********************************************************
;	ＦＤドライブ情報
; *********************************************************

CMDFDS	PROC	NEAR

	PRV	"ＦＡＴテーブルｾｸﾀ数  FD_FAT_SECTOR   =",FD_FAT_SECTOR
	PRV	"ＲＯＯＴＤＩＲｾｸﾀ数  FD_ROOT_SECTOR  =",FD_ROOT_SECTOR
	PRV	"ディレクトリ最大数   FD_DIRMAX      =",FD_DIRMAX
	PRV	"ｸﾗｽﾀ開始位置ｾｸﾀｵﾌｾｯﾄ FD_CLAST_OFFSET=",FD_CLAST_OFFSET
	PRV	"最小クラスタ番号     FD_MIN_CLAST   =",FD_MIN_CLAST
	PRV	"最大クラスタ番号     FD_MAX_CLAST   =",FD_MAX_CLAST
	PRV	"クラスタバイト数     FD_LEN_CLAST   =",FD_LEN_CLAST

	PRV	"セクタバイト数         FD_LEN_SECTOR=",FD_LEN_SECTOR
	PRV	"トラック当りのセクタ数 FD_MAX_SECTOR=",FD_MAX_SECTOR
	PRV	"クラスタ当りのセクタ数 FD_SEC_P_CLAST=",FD_SEC_P_CLAST

	PRV	"読みクラスタバイト数   CLST_R_LENGTH=",CLST_R_LENGTH
	PRV	"書きクラスタバイト数   CLST_W_LENGTH=",CLST_W_LENGTH

	PRVH	"FAT グローバルアドレス RDF_FAT =",RDF_FAT
	PRVH	"ROOTグローバルアドレス RDF_ROOT=",RDF_ROOT

	RET
CMDFDS	ENDP


CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

EXTRN	FD_FAT_SECTOR:WORD		; ＦＡＴテーブルセクタ数
EXTRN	FD_ROOT_SECTOR:WORD		; ＲＯＯＴＤＩＲセクタ数
EXTRN	FD_DIRMAX:WORD			; ディレクトリ最大数
EXTRN	FD_CLAST_OFFSET:WORD		; クラスタ開始位置のセクタオフセット
EXTRN	FD_MIN_CLAST:WORD		; 最小クラスタ番号
EXTRN	FD_MAX_CLAST:WORD		; 最大クラスタ番号
EXTRN	FD_LEN_CLAST:WORD		; クラスタバイト数

EXTRN	FD_LEN_SECTOR:WORD		; セクタバイト数
EXTRN	FD_MAX_SECTOR:WORD		; トラック当りのセクタ数
EXTRN	FD_SEC_P_CLAST:WORD		; クラスタ当りのセクタ数

EXTRN	CLST_R_LENGTH:WORD		; 読みクラスタバイト数
EXTRN	CLST_W_LENGTH:WORD		; 書きクラスタバイト数


EXTRN	RDF_FAT:WORD			; ＦＡＴグローバルアドレス
EXTRN	RDF_ROOT:WORD			; ＲＯＯＴグローバルアドレス
EXTRN	SCDATA:BYTE			; セクタバッファ

EXTRN	MPT_TABLE_LEN:WORD		; ＭＰＴテーブル長さ
EXTRN	MPT_TABLE_SEG:WORD		; ＭＰＴテーブルセグメント
EXTRN	MPT_TABLE_OFS:WORD		; ＭＰＴテーブルオフセット

DRVNO	DW	0		; drive number.

DATA	ENDS

	END
;
;	end of "SSDEBU.ASM"
;
