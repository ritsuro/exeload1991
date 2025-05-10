; "IPLTST.ASM" PS55Z/J14 make by R.H/japan 1991/06/12
;
;	E X E L O A D    T O O L S .
;
;	IPL (Initial Program Loarer) test.
;	for world-PC.
;
; test program.

WRITE_RETCOUNT 	EQU	10		; retry max count.

IPL_DCYL	EQU	0		; IPL set cylinder.
IPL_DHEAD	EQU	0		; IPL set head.
IPL_DSECR	EQU	1		; IPL set sector.
IPL_DSCNT	EQU	1		; IPL set sector counter.

IPL_DATA_SEG	EQU	7C0H		; IPL data segment.
IPL_STACK_SEG	EQU	0		; IPL stack segment.
IPL_STACK_TOP	EQU	7C00H		; IPL stack top.

DISPLY_MODE	EQU	2		; disply mode set.(0:40x25,2:80x25)
					; (6:grp640x200)
DISPLY_LIN_MAX	EQU	24		; disply line max.
DISPLY_CLM_MAX	EQU	79		; disply colum nax.

SEC_BYTE	EQU	512		; sector length.
TEXT_ATTR	EQU	0111B		; text attrbute.

CHR_LF		EQU	0AH		; LF.


RETFAR	MACRO				; far return.
	DB	11001011B		; RETF
	ENDM

MOVX	MACRO	DEST,SOUR
	MOV	AX,SOUR
	MOV	DEST,AX
	ENDM

MOVXB	MACRO	DEST,SOUR
	MOV	AL,SOUR
	MOV	DEST,AL
	ENDM


;
;	IPL source code.(512byte)
;

IPL	SEGMENT

	ASSUME	CS:IPL,DS:IPL,ES:IPL,SS:IPL
IPL_TOP:
	JMP	SHORT IPL_CODE_START	;+0 short jump.(2byte)
	NOP				;+2 NOP
		;3456789A		;
	DB	"EXELOAD0"		;+3 naming.
I_BYTE_SEC	DW	512		;+0Bh byte/sector.
I_SEC_CLAST	DB	1		;+0Dh sector/clast.
I_RESERVE_SEC	DW	1		;+0Eh reserved sector.
I_FAT_COPY	DB	2		;+10h FAT copy count.
I_ENTRY_COUNT	DW	224		;+11h root dir entry count.
I_FULL_SEC	DW	2880		;+13h full sector count.
I_MEDIA_DISC	DB	0F0H		;+15h dos media discripta.
I_SEC_FAT	DW	9		;+16h sector/FAT.
I_SEC_TRACK	DW	18		;+18h sector/track.
I_HEAD_COUNT	DW	2		;+1Ah head count.
I_DARK_SEC	DW	0		;+1Ch dark sector.

IPL_CODE_START:
	MOV	AX,IPL_DATA_SEG		; IPL data segment.
	MOV	DS,AX			;
	MOV	ES,AX			;

	CLI				; for i8088
	MOV	AX,IPL_STACK_SEG	; IPL stack segment.
	MOV	SS,AX			; IPL stack segment.
	MOV	SP,IPL_STACK_TOP	; IPL stack top.
	STI				; for i8088

	MOV	BX,OFFSET IPL_CODE_GATE	; IP load offset.

	MOV	AX,IPL_DATA_SEG		; CS load segment.
	PUSH	AX			;
	PUSH	BX			;
	RETFAR				; load CS:IP
IPL_CODE_GATE:				;
	CLD				; direction flag clear.

	CALL	TEXT_INIT		; text init.

	CALL	MESSAGE			; message put.

BLACK_HOLE:				; program end.
	JMP	BLACK_HOLE		;


;	text init.

TEXT_INIT	PROC	NEAR
	MOV	AL,DISPLY_MODE		; disply mode set.
	MOV	AH,00H			; mode set.
	INT	10H			; IBM bios.

	MOV	CH,0			; up line.
	MOV	CL,0			; left side.
	MOV	DH,DISPLY_LIN_MAX	; disply line max.
	MOV	DL,DISPLY_CLM_MAX	; disply colum nax.
	MOV	BH,0			; attrbute.
	MOV	AL,0			; 1 line.
	MOV	AH,06H			; window scroll up.
	INT	10H			; IBM bios.
	RET
TEXT_INIT	ENDP


;	message put.

MESSAGE	PROC	NEAR
	MOV	SI,OFFSET MESSAGE_TOP	; message.
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
	MOV	DL,LOCX			; locate X.
	MOV	DH,LOCY			; locate Y.
	MOV	BX,0			; page.
	MOV	AH,02H			; coursole set.
	INT	10H			; IBM bios.
	POP	SI
	RET
COULOC	ENDP


;	data.

LOCX		DB	0		; locate X.
LOCY		DB	0		; locate Y.

;	message.

MESSAGE_TOP:
DB	"EXELOAD/world-PC ver0.24 (C) R.Hashimoto 1991 in tokyo japan."
DB	CHR_LF
DB	" Hello world!!"
DB	CHR_LF
DB	" (make by ipltst.exe)"
DB	SEC_BYTE DUP (0)

IPL	ENDS

;
;	write program.
;

INCLUDE	TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA,SS:STACK,ES:IPL

START:
	PUSH	DS

	MOV	AX,SEG DATA		;
	MOV	DS,AX			;

	MOV	SAVE_SS,SS		; stack segment.
	MOV	SAVE_SP,SP		; stack pointer.

	CLI				; for i8088
	MOV	AX,SEG STACK		; stack segment.
	MOV	SS,AX			;
	MOV	SP,OFFSET TOP_OF_STACK	; stack pointer.
	STI				; for i8088

	CALL	MAIN			; main proceduer.

	CLI				; for i8088
	MOV	SS,SAVE_SS		; stack segment.
	MOV	SP,SAVE_SP		; stack pointer.
	STI				; for i8088

	POP	DS

FINALE:	MOV	AH,4CH
	MOV	AL,0
	INT	21H


;	main proceduer.

MAIN	PROC	NEAR
	LF
	PRF	"E X E L O A D    T O O L S ."
	PRF	"IPL (Initial Program Loarer) test."
	PRF	"for world-PC."

	INP	" IPL write FD drive number.['Q':exit]:"

	CALL	STRDEC			; string -> decimal.
	MOV	AX,DX			; drive number.
	DEC	AX			; unit number.
	CALL	SSRDRV			; set drive number.

MAIN_LOOP:
	INP	"1=360KB,2=1.2MB,3=720KB,4=1.44MB ['Q':exit]:"
	CALL	STRDEC			; string -> decimal.
	MOV	MEDIA_NUM,DX		; 1=360KB,2=1.2MB,3=720KB,4=1.44MB

	CALL	MEDIA_HEADER_SET	; IPL media header set.
	CALL	MEDIA_HEADER_PRINT	; IPL media header print.

	INP	" write ok ? ['Y'es/No `Q`:exit]:"
	CMP	BYTE PTR DS:[SI],'Y'
	JE	MAIN_WRITE
	CMP	BYTE PTR DS:[SI],'y'
	JE	MAIN_WRITE

	JMP	MAIN_LOOP

MAIN_WRITE:
	CALL	SCWRITE			; sector write.

	RET
MAIN	ENDP


;	IPL media header set.
;	-I- MEDIA_NUM : 1=360KB,2=1.2MB,3=720KB,4=1.44MB

MEDIA_HEADER_SET	PROC	NEAR
	CMP	MEDIA_NUM,1		;
	JL	MEDIA_HEADER_00		;
	CMP	MEDIA_NUM,4		;
	JG	MEDIA_HEADER_00		;
	JMP	MEDIA_HEADER_SET_START	;
MEDIA_HEADER_00:			;
	RET				;
MEDIA_HEADER_SET_START:
	MOV	BX,MEDIA_NUM		; 1=360KB,2=1.2MB,3=720KB,4=1.44MB
	DEC	BX			;
	MOV	SI,MEDIA_NUM		;
	DEC	SI			;
	SHL	SI,1			; word pointer.

	MOVX	ES,<SEG IPL>		; IPL code segment.

	MOVX	ES:I_BYTE_SEC	,DS:H_BYTE_SEC[SI]	;+0Bh byte/sector.
	MOVXB	ES:I_SEC_CLAST	,DS:B_SEC_CLAST[BX]	;+0Dh sector/clast.
	MOVX	ES:I_RESERVE_SEC,DS:H_RESERVE_SEC[SI]	;+0Eh reserved sector.
	MOVXB	ES:I_FAT_COPY	,DS:B_FAT_COPY[BX]	;+10h FAT copy count.
	MOVX	ES:I_ENTRY_COUNT,DS:H_ENTRY_COUNT[SI]	;+11h root entry cnt.
	MOVX	ES:I_FULL_SEC	,DS:H_FULL_SEC[SI]	;+13h full sec count.
	MOVXB	ES:I_MEDIA_DISC	,DS:B_MEDIA_DISC[BX]	;+15h dos media disc.
	MOVX	ES:I_SEC_FAT	,DS:H_SEC_FAT[SI]	;+16h sector/FAT
	MOVX	ES:I_SEC_TRACK	,DS:H_SEC_TRACK[SI]	;+18h sector/track.
	MOVX	ES:I_HEAD_COUNT	,DS:H_HEAD_COUNT[SI]	;+1Ah head count.
	MOVX	ES:I_DARK_SEC	,DS:H_DARK_SEC[SI]	;+1Ch dark sector.

	RET
MEDIA_HEADER_SET	ENDP


;	IPL media header print.

MEDIA_HEADER_PRINT	PROC	NEAR
	MOVX	ES,<SEG IPL>		; IPL code segment.

	PRV	"+0Bh byte/sector.    ",ES:I_BYTE_SEC
	PRBYTE	"+0Dh sector/clast.     ",ES:I_SEC_CLAST
	LF
	PRV	"+0Eh reserved sector.",ES:I_RESERVE_SEC
	PRBYTE	"+10h FAT copy count.   ",ES:I_FAT_COPY
	LF
	PRV	"+11h root entry cnt. ",ES:I_ENTRY_COUNT
	PRV	"+13h full sec count. ",ES:I_FULL_SEC
	PRBYTE	"+15h dos media disc.   ",ES:I_MEDIA_DISC
	LF
	PRV	"+16h sector/FAT.     ",ES:I_SEC_FAT
	PRV	"+18h sector/track.   ",ES:I_SEC_TRACK
	PRV	"+1Ah head count.     ",ES:I_HEAD_COUNT
	PRV	"+1Ch dark sector.    ",ES:I_DARK_SEC
	RET
MEDIA_HEADER_PRINT	ENDP


;	set drive number.
;	-I- AX : unit number.

SSRDRV	PROC	NEAR
	MOV	DUNIT,AX		; unit number.
	RET
SSRDRV	ENDP


;	sector write.

SCWRITE	PROC	NEAR
	MOV	DCYL,IPL_DCYL			; IPL set cylinder.
	MOV	DHEAD,IPL_DHEAD			; IPL set head.
	MOV	DSECR,IPL_DSECR			; IPL set sector.
	MOV	DSCNT,IPL_DSCNT			; IPL set sector counter.

	MOV	BUFF_ADRS_SEG,SEG IPL		; IPL source code.(512byte)
	MOV	BUFF_ADRS_OFS,OFFSET IPL_TOP	; IPL top offset.
	CALL	WRTSEC				; write sector.

	PRV	"DERROR=",DERROR

	RET
SCWRITE	ENDP


;	write sector.
;	-I- DCYL  : cylinder.
;	    DHEAD : head.
;	    DSECR : sector.
;	    DSCNT : sector counter.
;	    BUFF_ADRS_SEG : buffer segment.
;	    BUFF_ADRS_OFS : buffer offset.
;	-O- DSTAT : disk status.
;	    DERROR: disk error 0=normal,1=error

WRTSEC	PROC	NEAR
	PRV	"DUNIT=",DUNIT
	PRV	"DCYL =",DCYL
	PRV	"DHEAD=",DHEAD
	PRV	"DSECR=",DSECR
	PRV	"DSCNT=",DSCNT

	MOV	DERROR,0		; 0=normal.

	MOV	WRITE_RETRY,WRITE_RETCOUNT ; write retry count.
WRTSEC_RETRY:
	MOV	ES,BUFF_ADRS_SEG	; buffer segment.
	MOV	BX,BUFF_ADRS_OFS	; buffer offset.

	MOV	DL,BYTE PTR DUNIT	; unit number.
	AND	DL,11B			; not haed disk!
	MOV	DH,BYTE PTR DHEAD	; head.
	MOV	CH,BYTE PTR DCYL	; cylinder.
	MOV	CL,BYTE PTR DSECR	; sector.
	MOV	AL,BYTE PTR DSCNT	; sector counter.

	MOV	AH,03H			; write data.
	INT	13H			; disk bios.
	MOV	BYTE PTR DSTAT,AH	; status.
	JB	WRTSEC_ERROR		;

WRTSEC_EXIT:
	MOV	DERROR,0		; 0=normal.
	RET				;

WRTSEC_ERROR:				;
	DEC	WRITE_RETRY		; write retry count.
	JZ	WRTSEC_ER_END		;

	CALL	RECALIBRATE		; recalibrate.

	JMP	WRTSEC_RETRY		;

WRTSEC_ER_END:
	MOV	DERROR,1		; 1=error.
	RET
WRTSEC	ENDP


;	recaliblate.

RECALIBRATE	PROC	NEAR
	MOV	DL,BYTE PTR DUNIT	; drive.(PS/2 only)
	MOV	AH,00H			; DISK RESET.
	INT	13H			; disk bios.
	RET
RECALIBRATE	ENDP


CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

SAVE_SS		DW	0		; stack segment.
SAVE_SP		DW	0		; stack pointer.

DUNIT		DW	0		; unit number.
DCYL		DW	0		; cylinder.
DHEAD		DW	0		; head.
DSECR		DW	1		; sector.
DSCNT		DW	1		; sector counter.
DSTAT		DW	0		; disk status.
DERROR		DW	0		; disk error 0=normal,1=error

BUFF_ADRS_SEG	DW	0		; buffer segment.
BUFF_ADRS_OFS	DW	0		; buffer offset.

WRITE_RETRY	DW	0		; write retry count.

MEDIA_NUM	DW	0		; 1=360KB,2=1.2MB,3=720KB,4=1.44MB
;			PC/XT	,AT	,Convert,PS/2
;			360KB	1.2MB	720KB	1.44KB
H_BYTE_SEC	DW	512	,512	,512	,512	;+0Bh byte/sector.
B_SEC_CLAST	DB	2	,1	,2	,1	;+0Dh sector/clast.
H_RESERVE_SEC	DW	1	,1	,1	,1	;+0Eh reserved sector.
B_FAT_COPY	DB	2	,2	,2	,2	;+10h FAT copy count.
H_ENTRY_COUNT	DW	112	,224	,112	,224	;+11h root entry cnt.
H_FULL_SEC	DW	720	,2400	,1440	,2880	;+13h full sec count.
B_MEDIA_DISC	DB	0FDH	,0F9H	,0F9H	,0F0H	;+15h dos media disc.
H_SEC_FAT	DW	2	,7	,3	,9	;+16h sector/FAT.
H_SEC_TRACK	DW	9	,15	,9	,18	;+18h sector/track.
H_HEAD_COUNT	DW	2	,2	,2	,2	;+1Ah head count.
H_DARK_SEC	DW	0	,0	,0	,0	;+1Ch dark sector.

DATA	ENDS

STACK	SEGMENT	STACK
	DW	100 DUP (?)
TOP_OF_STACK	LABEL	WORD
STACK	ENDS

	END	START
;
;	end of "IPLTST.ASM"
;
