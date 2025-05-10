; "DKCOPY.ASM" PC-9801UV11 make by R.H 1991/08/22
;
;
;	disk copy tool.
;
;
; public subroutine.

TITLEX	MACRO
	DB	"DKCOPY ver0.1    one drive disk copy tool.",0DH,0AH
	DB	" (C) R.Hashimoto 1989,1990,1991 in tokyo japan.",0DH,0AH
	DB	0
	ENDM
READMEX	MACRO
	DB "** update.**",0DH,0AH
	DB "1991/10/09 ver0.1 recover : 2DD FD copy error.(40->80)",0DH,0AH
	DB	0
	ENDM

INCLUDE	TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'
CODE	ENDS
DATA	SEGMENT	PUBLIC	'DATA'
DATA	ENDS
STACK	SEGMENT	STACK
	DW	1000 DUP (?)
TOP_OF_STACK	LABEL	WORD
STACK	ENDS


CALL_NM	MACRO	NUM,LBL
	LOCAL	L1
	CMP	DX,NUM
	JNE	L1
	PUSH	DX
	CALL	LBL
	POP	DX
L1:
	ENDM
MOVX	MACRO	DEST,SOU
	MOV	AX,SOU
	MOV	DEST,AX
	ENDM
CMPX	MACRO	DEST,SOU
	MOV	AX,SOU
	CMP	DEST,AX
	ENDM
JMPEQ	MACRO	LBL
	LOCAL	L1
	JNE	L1
	JMP	LBL
L1:
	ENDM

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA

EXTRN	DISKLOAD:NEAR		; disk load.
EXTRN	DISKSAVE:NEAR		; disk save.

EXTRN	TRACKLOAD:NEAR		; track load.
EXTRN	TRACKSAVE:NEAR		; track save.

EXTRN	SSMSRT:NEAR		; ドライブ・モード・スタート
EXTRN	SSMSTP:NEAR		; ドライブ・モード・ストップ
EXTRN	SSMMDE:NEAR		; ドライブ・モード標準設定
EXTRN	SSMMDA:NEAR		; ドライブ・ディスクメディア・チェック

EXTRN	TRACKSECSET:NEAR	; track sector count set .

; ****************************************************
;	START.
; ****************************************************

START:
	PUSH	DS
	MOV	AX,SEG DATA
	MOV	DS,AX
	CALL	MAIN
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
	MOV	SI,OFFSET SYSTEM_NAME		; title.
	CALL	PRINT				; print.

	CALL	DOS_RESET			; DOS reset command.

	CALL	SSMSRT				; ドライブ・モード・スタート

	CALL	MAINMENU			; main menu.

	CALL	SSMSTP				; ドライブ・モード・ストップ
	RET
MAIN	ENDP


; *********************************************************
;	main menu.
; *********************************************************

MAINMENU	PROC	NEAR
MAINMENU_START:
	PRF	"1. FD track    -> binary file."
	PRF	"2. binary file -> FD track."
	PRF	"3. FD track    -> FD track."
	PRF	"4. read me!"
MAINMENU_INP:
	INP	"input function number.[Q:EXIT]="
	CALL	STRDEC
	CMP	DX,0
	JMPEQ	MAINMENU_START

	MOV	AX,0

	CALL_NM	1,FD_TO_FILE		; FD to file.
	CALL_NM	2,FILE_TO_FD		; file to FD.
	CALL_NM	3,FD_TO_FD		; FD to FD.
	CALL_NM	4,README		; readme.

	CMP	AX,0			;
	JNE	MAINMENU_ERROR		;

	JMP	MAINMENU_START

MAINMENU_ERROR:
	PRF	"error!"
	JMP	MAINMENU_START
MAINMENU	ENDP


; *********************************************************
;	readme.
; *********************************************************

README	PROC	NEAR
	LF
	MOV	SI,OFFSET README_TEXT		; readme.
	CALL	PRINT				; print.
	LF
	RET
README	ENDP


; *********************************************************
;	FD to FD.
; *********************************************************

FD_TO_FD	PROC	NEAR
	CALL	FD_TO_FILE		; FD to file.
	INP	"please chenge disket.[Q:EXIT]="
	CALL	FILE_TO_FD		; file to FD.
	RET
FD_TO_FD	ENDP


; *********************************************************
;	FD to file.
;	-O- AX : 0=normal,1=error.
; *********************************************************

FD_TO_FILE	PROC	NEAR
	LF

	CALL	FD_MEDIA_CHECK			; FD media check.
	CMP	AX,0				; 0=normal,1=error.
	JNE	FD_TO_FILE_ERROR		;

	MOV	BUFFER_SEG,DS			; source segment address.
	MOV	BUFFER_OFS,OFFSET TRKBUFFER	; track buffer.

	MOV	TRACK_NUMBER,0		; track number.
FD_TO_FILE_LOOP:
	PR	"."

	MOV	DX,BUFFER_SEG		; source segment address.
	MOV	DI,BUFFER_OFS		; track buffer.
	MOV	AX,TRACK_NUMBER		; track number.
	CALL	TRACKLOAD		; track load.
	CMP	AX,0			; 0=normal,1=error.
	JNE	FD_TO_FILE_ERRORTRK	;

	MOVX	FILENUM,TRACK_NUMBER	; track number.
	CALL	PATH_NAME_MAKER		; path name maker.

	MOV	SI,OFFSET PATHNAME	; path name.
	MOV	DX,BUFFER_SEG		; source segment address.
	MOV	DI,BUFFER_OFS		; track buffer.
	MOV	CX,TRK1DATALEN		; track data length.
	CALL	DISKSAVE		; disk save.
	CMP	AX,0			; 0=normal,1=error.
	JNE	FD_TO_FILE_ERROR	;

	INC	TRACK_NUMBER		; track number.

	CMPX	TRACK_NUMBER,MAX_TRACK_CNT ; max track count.
	JB	FD_TO_FILE_LOOP		;

FD_TO_FILE_EXIT:
	LF
	MOV	AX,0			; 0=normal.
	RET
FD_TO_FILE_ERROR:
	LF
	MOV	AX,1			; 1=error.
	RET
FD_TO_FILE_ERRORTRK:
	LF
	PRF	"track read error."
	MOV	AX,1			; 1=error.
	RET
FD_TO_FILE	ENDP


; *********************************************************
;	file to FD.
;	-O- AX : 0=normal,1=error.
; *********************************************************

FILE_TO_FD	PROC	NEAR
	LF

	CALL	FD_MEDIA_CHECK			; FD media check.
	CMP	AX,0				; 0=normal,1=error.
	JNE	FILE_TO_FD_ERROR		;

	MOV	BUFFER_SEG,DS			; source segment address.
	MOV	BUFFER_OFS,OFFSET TRKBUFFER	; track buffer.

	MOV	TRACK_NUMBER,0		; track number.
FILE_TO_FD_LOOP:
	PR	"."

	MOVX	FILENUM,TRACK_NUMBER	; track number.
	CALL	PATH_NAME_MAKER		; path name maker.

	MOV	SI,OFFSET PATHNAME	; path name.
	MOV	DX,BUFFER_SEG		; source segment address.
	MOV	DI,BUFFER_OFS		; track buffer.
	MOV	CX,TRK1DATALEN		; track data length.
	CALL	DISKLOAD		; disk load.
	CMP	AX,0			; 0=normal,1=error.
	JNE	FILE_TO_FD_ERROR	;

	MOV	DX,BUFFER_SEG		; source segment address.
	MOV	DI,BUFFER_OFS		; track buffer.
	MOV	AX,TRACK_NUMBER		; track number.
	CALL	TRACKSAVE		; track save.
	CMP	AX,0			; 0=normal,1=error.
	JNE	FILE_TO_FD_ERRORTRK	;

	INC	TRACK_NUMBER		; track number.

	CMPX	TRACK_NUMBER,MAX_TRACK_CNT ; max track count.
	JB	FILE_TO_FD_LOOP		;

FILE_TO_FD_EXIT:
	LF
	MOV	AX,0			; 0=normal.
	RET
FILE_TO_FD_ERROR:
	LF
	MOV	AX,1			; 1=error.
	RET
FILE_TO_FD_ERRORTRK:
	LF
	PRF	"track write error."
	MOV	AX,1			; 1=error.
	RET
FILE_TO_FD	ENDP


; *********************************************************
;	FD media check.
;	-O- AX : 0=normal,1=error.
;	    MAX_TRACK_CNT : max track count.
;	    MEDIA_TYPE    : media type.
;				1=360KB,2=1.2MB,3=720KB,4=1.44MB
;				5=1.2MB/1024
; *********************************************************

FD_MEDIA_CHECK	PROC	NEAR
	CALL	SSMMDA			; ドライブ・ディスクメディア・チェック
	CMP	AX,0			; 0=normal,1=error.
	JMPNE	FD_MEDIA_CHECK_ERROR	;

	MOV	MEDIA_TYPE,DX		; media type.

	MOV	BX,DX			;
	SHL	BX,1			; word pointer.
	MOVX	MAX_TRACK_CNT,DS:D_MAX_TRACK[BX] ; max track.

	MOV	DX,MEDIA_TYPE		; media type.
	CALL	SSMMDE			; ドライブ・モード標準設定

	MOV	AX,FD_MAX_SECTOR	; トラック当りのセクタ数
	CALL	TRACKSECSET		; track sector count set .

	MOV	DX,MEDIA_TYPE		; media type.
	CMP	DX,1
	JE	FD_MEDIA_CHECK_1
	CMP	DX,2
	JE	FD_MEDIA_CHECK_2
	CMP	DX,3
	JE	FD_MEDIA_CHECK_3
	CMP	DX,4
	JE	FD_MEDIA_CHECK_4
	CMP	DX,5
	JE	FD_MEDIA_CHECK_5
	JMP	FD_MEDIA_CHECK_ERROR
FD_MEDIA_CHECK_1:
	PRF	"360KB"
	MOV	AX,0		; 0=normal.
	RET
FD_MEDIA_CHECK_2:
	PRF	"1.2MB"
	MOV	AX,0		; 0=normal.
	RET
FD_MEDIA_CHECK_3:
	PRF	"720KB"
	MOV	AX,0		; 0=normal.
	RET
FD_MEDIA_CHECK_4:
	PRF	"1.44MB"
	MOV	AX,0		; 0=normal.
	RET
FD_MEDIA_CHECK_5:
	PRF	"1.2MB/1024"
	MOV	AX,0		; 0=normal.
	RET
FD_MEDIA_CHECK_ERROR:
	PRF	"error"
	MOV	AX,1		; 1=error.
	RET
FD_MEDIA_CHECK	ENDP


; *********************************************************
;	path name maker.
;	-I- DRIVENUM : drive number.(0=current)
;	    FILENUM  : file number.
;	-O- PATHNAME : path name.
; *********************************************************

PATH_NAME_MAKER	PROC	NEAR
	MOV	DI,OFFSET PATHNAME	; path name.
	MOVX	ES,DS			;

	CMP	DRIVENUM,0		; drive number.(0=current)
	JE	PATH_NAME_MAKER_2	;

	MOV	AL,BYTE PTR DRIVENUM	; drive number.(0=current)
	ADD	AL,'A'-1		;
	STOSB				; "A:"
	MOV	AL,':'			;
	STOSB				;
PATH_NAME_MAKER_2:			;
	MOV	AL,'F'			; "FD"
	STOSB				;
	MOV	AL,'D'			;
	STOSB				;

	MOV	DX,FILENUM		; file number.
	CALL	DECSTR			; dec -> string.
	MOVSW				;
	MOVSW				;
	MOVSB				; "12345"

	MOV	AL,'.'			;
	STOSB				;
	MOV	AL,'W'			; ".WWW",0
	STOSB				;
	STOSB				;
	STOSB				;
	MOV	AL,0			;
	STOSB				;

	RET
PATH_NAME_MAKER	ENDP


; *********************************************************
;	DOS reset command.
; *********************************************************

DOS_RESET	PROC	NEAR
	MOV	AH,0DH		; disk reset.
	INT	21H		; dos function.
	RET
DOS_RESET	ENDP


CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

EXTRN	FD_MAX_SECTOR:WORD		; トラック当りのセクタ数

DRIVENUM	DW	0		; drive number.(0=current)
FILENUM		DW	0		; file number.
PATHNAME	DB	256 DUP (0),0,0	; path name.

MAX_TRACK_CNT	DW	160		; max track count.

TRACK_NUMBER	DW	0		; track number.

MEDIA_TYPE	DW	0		; media type.
					; 1=360KB,2=1.2MB,3=720KB,4=1.44MB
					; 5=1.2MB/1024

;			PC/XT	,AT	,Convert,PS/2  ,PC98
;			360KB	1.2MB	720KB	1.44KB  1.2MB(1024)

D_MAX_TRACK	DW 0,	40*2,	80*2,	80*2,	80*2,	77*2	; max track.

BUFFER_SEG	DW	0		; source segment address.
BUFFER_OFS	DW	0		; source offset  address.

TRK1DATALEN	DW	512*18		; track data length.
TRKBUFFER	DB	512*18 DUP (0)	; track buffer.

SYSTEM_NAME	LABEL	BYTE		; title.
		TITLEX
README_TEXT	LABEL	BYTE		; readme.
		READMEX

DATA	ENDS

	END
;
;	end of "DKCOPY.ASM"
;
