; "SCWRT.ASM" PS55Z/J14 make by R.H/japan 1991/06/14
;
;
;	E X E L O A D    I P L   k i t .
;
;	h e a d e r   s e c t o r   w r i t e .
;
;
; public subroutine.

INCLUDE	TSTSET.INC

MOVX	MACRO	DEST,SOUR
	MOV	AX,SOUR
	MOV	DEST,AX
	ENDM
ADDX	MACRO	DEST,SOUR
	MOV	AX,SOUR
	ADD	DEST,AX
	ENDM
CMPX	MACRO	DEST,SOUR
	MOV	AX,SOUR
	CMP	DEST,AX
	ENDM

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA

PUBLIC	SCWINI			; initialize.
PUBLIC	SCWSET			; start record number set.
PUBLIC	SCWSEQ			; sequential write of sector.
PUBLIC	SCWDRV			; set drive.
PUBLIC	SCWMOD			; drive type.

SEC_BYTE	EQU	512	; sector length.
FDMA_BYTE	EQU	512	; DMA buffer length.

WRITE_RETCOUNT 	EQU	10	; write retry count.


;	initialize.

SCWINI	PROC	NEAR
	MOVX	WRITE_CYLINDER	,MIN_CYLINDER	; min cylinder.
	MOVX	WRITE_HEAD	,MIN_HEAD	; min head.
	MOVX	WRITE_SECTOR	,MIN_SECTOR	; min sector.
	RET
SCWINI	ENDP


;	start record number set.
;	-I- AX : record number.

SCWSET	PROC	NEAR
	MOV	DX,0			;
	DIV	MAX_SECTOR		; max sector.

	INC	DX			; + 1
	MOV	WRITE_SECTOR,DX		; write sector.

	MOV	WRITE_HEAD,AX		; write head.
	AND	WRITE_HEAD,0001H	; even or odd.

	SHR	AX,1			; / 2
	MOV	WRITE_CYLINDER,AX	; write cylinder.

	RET
SCWSET	ENDP


;	sequential write of sector.
;	-I- DX : buffer segment.
;	    BX : buffer offset.
;	-O- AX : 0=normal,1=error,2=end sector write.

SCWSEQ	PROC	NEAR
	MOV	BUFF_SEG,DX		; buffer segment.
	MOV	BUFF_OFFSET,BX		; buffer offset.

	MOV	AX,WRITE_CYLINDER	; write cylinder.
	MOV	DCYL,AX			;
	MOV	AX,WRITE_HEAD		; write head.
	MOV	DHEAD,AX		;
	MOV	AX,WRITE_SECTOR		; write sector.
	MOV	DSECR,AX		;

	CALL	SCWRITE			; sector write.
	CMP	DERROR,0		; 0=normal,1=error.
	JNE	SCWSEQ_ERROR		;

	INC	WRITE_SECTOR		; write sector.
	CMPX	WRITE_SECTOR,MAX_SECTOR
	JBE	SCWSEQ8

	MOVX	WRITE_SECTOR,MIN_SECTOR
	INC	WRITE_HEAD		; write head.
	CMPX	WRITE_HEAD,MAX_HEAD
	JBE	SCWSEQ8

	MOVX	WRITE_HEAD,MIN_HEAD
	INC	WRITE_CYLINDER		; write cylinder.
	CMPX	WRITE_CYLINDER,MAX_CYLINDER
	JBE	SCWSEQ8

	JMP	SCWSEQ_ENDSEC
SCWSEQ8:
	MOV	AX,0			; 0=normal.
	RET
SCWSEQ_ERROR:
	MOV	AX,1			; 1=error.
	RET
SCWSEQ_ENDSEC:
	MOV	AX,2			; 2=end sector write.
	RET
SCWSEQ	ENDP


;	set drive.
;	-I- AX : drive number.

SCWDRV	PROC	NEAR
	MOV	DUNIT,AX		; drive number.
	RET
SCWDRV	ENDP


;	drive type.
;	-I- DX : media type 1=360KB,2=1.2MB,3=720KB,4=1.44MB

SCWMOD	PROC	NEAR
	MOV	MEDIA_TYPE,DX				; media type.

	MOV	BX,MEDIA_TYPE				; media type.
	SHL	BX,1					; word pointer.

	MOVX	MAX_CYLINDER	,DS:D_MAX_CYLINDER[BX]	; max cylinder.
	MOVX	MAX_HEAD	,DS:D_MAX_HEAD[BX]	; max head.
	MOVX	MAX_SECTOR	,DS:D_MAX_SECTOR[BX]	; max sector.

	RET
SCWMOD	ENDP


;	sector write.
;	-I- BUFF_SEG    : buffer segment.
;	    BUFF_OFFSET : buffer offset.
;	    DCYL        : cylinder.
;	    DHEAD       : head.
;	    DSECR       : sector.
;	-O- DERROR	: 0=normal,1=error.

SCWRITE	PROC	NEAR
	PRV	"cylinder=",DCYL
	PRV	"head    =",DHEAD
	PRV	"sector  =",DSECR

	MOV	AX,WRITE_RETCOUNT	; write retry count.
	MOV	WRITE_RETRY,AX		; sector write retry counter.

SCWRITE_RETRY:				;
	CALL	DMA_BUFSET		; DMA buffer set.

	MOV	AX,SEG DATA		; DMA buffer segment.
	MOV	ES,AX			;
	MOV	BX,DMA_ADRS		; DMA buffer offset.

	MOV	DL,BYTE PTR DUNIT	; unit number.
	AND	DL,11B			; not haed disk!
	MOV	DH,BYTE PTR DHEAD	; head.
	MOV	CH,BYTE PTR DCYL	; cylinder.
	MOV	CL,BYTE PTR DSECR	; sector.
	MOV	AL,1			; sector count.

	MOV	AH,BYTE PTR DWRITE	; write data.
	INT	13H			; disk bios.
	MOV	BYTE PTR DSTAT,AH	; status.
	JB	SCWRITE_ERROR		;

SCWRITE_EXIT:
	MOV	DERROR,0		; 0=normal.
	RET				;

SCWRITE_ERROR:				;
	DEC	WRITE_RETRY		; sector write retry counter.
	JZ	SCWRITE_ER_END		;
	
	CALL	RECALIBRATE		; recalibrate.

	JMP	SCWRITE_RETRY		;

SCWRITE_ER_END:
	MOV	DERROR,1		; 1=error.
	RET
SCWRITE	ENDP


;	recalibrate.

RECALIBRATE	PROC	NEAR
	MOV	DL,BYTE PTR DUNIT	; unit number PS/2 only.
	AND	DL,11B			; not haed disk!
	MOV	AH,00H			; DISK RESET.
	INT	13H			; disk bios.
	RET
RECALIBRATE	ENDP



;	DMA buffer set.
;	-I- BUFF_SEG    : buffer segment.
;	    BUFF_OFFSET	: buffer offset.
;	-O- DATA:[DMA_ADRS] : DMA buffer.

DMA_BUFSET	PROC	NEAR
	PUSH	DS
	MOV	CX,FDMA_BYTE		; DMA buffer length.

	MOV	AX,SEG DATA		;
	MOV	ES,AX			;
	MOV	DI,DMA_ADRS		; DMA buffer.

	MOV	SI,BUFF_OFFSET		; buffer offset.
	MOV	AX,BUFF_SEG		;
	MOV	DS,AX			;

	REP	MOVSB			;
	POP	DS
	RET
DMA_BUFSET	ENDP


CODE	ENDS



DATA	SEGMENT	PUBLIC	'DATA'

MIN_CYLINDER	DW	0		; min cylinder.
MIN_HEAD	DW	0		; min head.
MIN_SECTOR	DW	1		; min sector.

MAX_CYLINDER	DW	80		; max cylinder.
MAX_HEAD	DW	1		; max head.
MAX_SECTOR	DW	18		; max sector.

MEDIA_TYPE	DW	4	; media type 1=360KB,2=1.2MB,3=720KB,4=1.44MB

;			PC/XT	,AT	,Convert,PS/2
;			360KB	1.2MB	720KB	1.44KB
D_MAX_CYLINDER	DW 0,	40,	80,	40,	80	; max cylinder.
D_MAX_HEAD	DW 0,	1,	1,	1,	1	; max head.
D_MAX_SECTOR	DW 0,	9,	15,	9,	18	; max sector.

DWRITE		DW	03H		; write data.
DUNIT		DW	0		; drive number.

DLEN		DW	SEC_BYTE	; data length.
DCYL		DW	0		; cylinder.
DHEAD		DW	0		; head.
DSECR		DW	1		; sector.
DSTAT		DW	0		; status.
DERROR		DW	0		; 0=normal,1=error.

DMA_ADRS	DW	OFFSET DMA_BUFF		; DMA buffer address.
DMA_BUFF	DB	FDMA_BYTE DUP (0)	; DMA buffer.

BUFF_SEG	DW	0		; buffer segment.
BUFF_OFFSET	DW	0		; buffer offset.

WRITE_RETRY	DW	0		; sector write retry counter.

WRITE_CYLINDER	DW	0		; write cylinder.
WRITE_HEAD	DW	0		; write head.
WRITE_SECTOR	DW	0		; write sector.

DATA	ENDS
	END
;
;	end of "SCWRT.ASM"
;

