; "CODIPL.ASM" PS55Z/J14 make by R.H/japan 1991/06/13
;
;
;	E X E L O A D    I P L   k i t .
;
;	I P L   c o d e .
;
;
; code data.

CODIPL	SEGMENT	PUBLIC	'CODIPL'

	ASSUME	CS:CODIPL,DS:CODIPL

PUBLIC	IPLTOP				; IPL code top.
PUBLIC	IPLHEADER			; IPL code header.
PUBLIC	IPLEND				; IPL code end.

;	IPL source code (512byte)

IPLTOP		LABEL	FAR		; IPL code top.

SYSMAIN_OFSET	EQU	0		; system offset.
SYSMAIN_SEG	EQU	800H		; system segment.

SEC_BYTE	EQU	512		; sector length.

READ_RETCOUNT 	EQU	1		; read retry count.

IPL_DATA_SEG	EQU	7C0H		; IPL data segment.
IPL_STACK_SEG	EQU	0		; IPL stack segment.
IPL_STACK_TOP	EQU	7C00H		; IPL stack top.

DISPLY_MODE	EQU	2		; disply mode set.(0:40x25,2:80x25)
					; (6:grp640x200)
DISPLY_LIN_MAX	EQU	24		; disply line max.
DISPLY_CLM_MAX	EQU	79		; disply colum nax.

TEXT_ATTR	EQU	0111B		; text attrbute.

CHR_LF		EQU	0AH		; LF.

RETFAR	MACRO				; far return.
	DB	11001011B		; RETF
	ENDM

CMPX	MACRO	DEST,SOUR
	MOV	AX,SOUR
	CMP	DEST,AX
	ENDM


;
;	IPL source code.(512byte)
;

IPL_TOP:
	JMP	SHORT IPL_CODE_START	;+0 short jump.(2byte)
	NOP				;+2 NOP
		;3456789A		;
	DB	"EXELOAD0"		;+3 naming.
IPLHEADER	LABEL	BYTE		; IPL code header.
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
					; system top sector.
READ_CYLINDER	DW	0		;+1Eh cylinder.
READ_HEAD	DW	1		;+20h head.
READ_SECTOR	DW	16		;+22h sector.
SYS_SEC_CNT	DW	5		;+24h system sector count.
MEDIA_TYPE	DW	4		;+26h drive media type.

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

	MOV	AX,SYSMAIN_OFSET	; system offset.
	MOV	LOAD_OFSET,AX		; system load offset.

	MOV	AX,SYSMAIN_SEG		; system segment.
	MOV	LOAD_SEG,AX		; system load segment.

	CALL	SYSLOAD			; system load.

	MOV	AX,SYSMAIN_OFSET	; system offset.
	MOV	LOAD_OFSET,AX		; system load offset.

	MOV	AX,SYSMAIN_SEG		; system segment.
	MOV	LOAD_SEG,AX		; system load segment.

	MOV	DX,DUNIT		; DX : current drive number.(0-3)
	MOV	BX,MEDIA_TYPE		; BX : current drive media type.

	JMP	DWORD PTR START_ADDRESS	; start address.

BLACK_HOLE:				; program end.
	JMP	BLACK_HOLE		;



;	system load.
;	-I- LOAD_OFSET	; system load offset.
;	    LOAD_SEG	; system load segment.
;	-O- AX 		: 0=normal,1=error.

SYSLOAD	PROC	NEAR
	MOV	CX,SYS_SEC_CNT		; system sector count.
SYSLOAD2:
	PUSH	CX			;
	MOV	DX,LOAD_SEG		; system load segment.
	MOV	BX,LOAD_OFSET		; system load offset.
	CALL	SCSEQ			;
	POP	CX			;

	CMP	AX,0			; 0=normal.
	JNE	SYSLOAD_ERROR		;

	ADD	LOAD_OFSET,SEC_BYTE	; sector length.

	LOOP	SYSLOAD2		;

	MOV	AX,0			; normal.
	RET				;
SYSLOAD_ERROR:
	MOV	AX,1			; error.
	RET				;
SYSLOAD	ENDP



;	sector sequential read.
;	-I- DX : buffer segment.
;	    BX : buffer offset.
;	-O- AX : 0=normal,1=error,2=end sector write.

SCSEQ	PROC	NEAR
	MOV	BUFF_SEG,DX		; buffer segment.
	MOV	BUFF_OFSET,BX		; buffer offset.

	MOV	AX,READ_CYLINDER	; cylinder.
	MOV	DCYL,AX			;
	MOV	AX,READ_HEAD		; head.
	MOV	DHEAD,AX		;
	MOV	AX,READ_SECTOR		; sector.
	MOV	DSECR,AX		;

	CALL	SCREAD			; sector read.
	CMP	DERROR,0		; 0=normal,1=error.
	JNE	SCSEQ_ERROR

	INC	READ_SECTOR		; sector.
	CMPX	READ_SECTOR,I_SEC_TRACK	;+18h sector/track.
	JBE	SCSEQ_EXIT		;

	MOV	READ_SECTOR,1		;

	INC	READ_HEAD		; head.
	CMPX	READ_HEAD,I_HEAD_COUNT	;+1Ah head count.
	JB	SCSEQ_EXIT		;

	MOV	READ_HEAD,0		;

	INC	READ_CYLINDER		; cylinder.

;*;	CMP	READ_CYLINDER,MAX_CYLINDER
;*;	JBE	SCSEQEXIT		;
;*;	JMP	SCSEQ_ENDSEC		;

SCSEQ_EXIT:
	MOV	AX,0			; 0=normal.
	RET				;
SCSEQ_ERROR:
	MOV	AX,1			; 1=error.
	RET				;
SCSEQ_ENDSEC:
	MOV	AX,2			; 2=end sector write.
	RET				;
SCSEQ	ENDP



;	sector read.
;	-I- DCYL        : cylinder.
;	    DHEAD       : head.
;	    DSECR       : sector.
;	    BUFF_SEG	: buffer segment.
;	    BUFF_OFSET	: buffer offset.
;	-O- BUFF_SEG_OF[BUFF_OFSET] ; sector data.
;	    DERROR      : 0=normal,1=error.

SCREAD	PROC	NEAR
	MOV	DERROR,0		; 0=normal.

	MOV	AX,READ_RETCOUNT	; read retry count.
	MOV	READ_RETRY,AX		;

SCREAD_RETRY:				;
	MOV	ES,BUFF_SEG		; buffer segment.
	MOV	BP,BUFF_OFSET		; buffer offset.

	MOV	DL,BYTE PTR DUNIT	; unit number.
	MOV	DH,BYTE PTR DHEAD	; head.
	MOV	CH,BYTE PTR DCYL	; cylinder.
	MOV	CL,BYTE PTR DSECR	; sector.
	MOV	AL,BYTE PTR DSCNT	; sector counter.
	MOV	AH,BYTE PTR DREAD	; read data.
	INT	13H			; disk bios.
	MOV	BYTE PTR DSTAT,AH	; disk status.
	JB	SCREAD_ERROR		;

SCREAD_EXIT:
	MOV	DERROR,0		; 0=normal.
	RET				;

SCREAD_ERROR:				;
	DEC	READ_RETRY		; read retry counter.
	JZ	SCREAD_ER_END		;

	CALL	RECALIBRATE		; recalibrate.

	JMP	SCREAD_RETRY		;

SCREAD_ER_END:				;
	MOV	DERROR,1		; 1=error.
	RET				;
SCREAD	ENDP


;	recalibrate.

RECALIBRATE	PROC	NEAR
	MOV	DL,BYTE PTR DUNIT	; unit number PS/2 only.
	MOV	AH,00H			; DISK RESET.
	INT	13H			; disk bios.
	RET
RECALIBRATE	ENDP


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


DREAD		DW	02H		; read data.

DUNIT		DW	0		; unit number.
DCYL		DW	0		; cylinder.
DHEAD		DW	0		; head.
DSECR		DW	1		; sector.
DSCNT		DW	1		; sector counter.
DSTAT		DW	0		; disk status.
DERROR		DW	0		; disk error 0=normal,1=error

START_ADDRESS	LABEL	DWORD		; start address.
LOAD_OFSET	DW	0		; system load offset.
LOAD_SEG	DW	0		; system load segment.

BUFF_OFSET	DW	0		; buffer segment.
BUFF_SEG	DW	0		; buffer offset.

READ_RETRY	DW	0		; read retry counter.

LOCX		DB	0		; locate X.
LOCY		DB	0		; locate Y.

;	message.

MESSAGE_TOP:
DB	" Hello world!!",CHR_LF,0
DB	0

IPLEND		LABEL	FAR		; IPL code end.

	DB	SEC_BYTE DUP (0)

CODIPL	ENDS

	END
;
;	end of "CODIPL.ASM"
;

