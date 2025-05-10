; "SYSSET.ASM" PS55Z/J14 make by R.H/japan 1991/06/13
;
;
;	E X E L O A D    I P L   k i t .
;
;	I P L   &   s y s t e m    w r i t e .
;
;
; public subroutine.

INCLUDE	TSTSET.INC

CODIPL	SEGMENT	PUBLIC	'CODIPL'
	EXTRN	IPLTOP:FAR		; IPL code top.
	EXTRN	IPLHEADER:FAR		; IPL code header.
	EXTRN	IPLEND:FAR		; IPL code end.
CODIPL	ENDS

CODSYS	SEGMENT	PUBLIC	'CODSYS'
	EXTRN	SYSTOP:FAR		; system code top.
	EXTRN	SYSEND:FAR		; system code end.
CODSYS	ENDS

MOVX	MACRO	DEST,SOUR
	MOV	AX,SOUR
	MOV	DEST,AX
	ENDM
ADDX	MACRO	DEST,SOUR
	MOV	AX,SOUR
	ADD	DEST,AX
	ENDM
JMPNE	MACRO	LBL
	LOCAL	L1
	JE	L1
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

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA

PUBLIC	SYSMOD			; system write disk type.
PUBLIC	SYSSET			; system write to disk.

EXTRN	SCWINI:NEAR		; initialize.
EXTRN	SCWSET:NEAR		; start record number set.
EXTRN	SCWSEQ:NEAR		; sequential write of sector.
EXTRN	SCWDRV:NEAR		; set drive.
EXTRN	SCWMOD:NEAR		; drive type.

SYSTEM_SIZE_MAX	EQU	65530	; system size max.

SEC_BYTE	EQU	512	; sector length.

END_SEC_MARK	EQU	0FFFH	; end sector mark.


;	system write disk type.
;	-I- DX : media type 1=360KB,2=1.2MB,3=720KB,4=1.44MB

SYSMOD	PROC	NEAR
	MOV	MEDIA_TYPE,DX				; media type.

	CMP	DX,1					;
	JMPL	SYSMOD_EXIT				;
	CMP	DX,4					;
	JMPG	SYSMOD_EXIT				;

	MOV	BX,MEDIA_TYPE				; media type.
	SHL	BX,1					; word pointer.
	MOVX	REC_FAT		,DS:D_FAT_SEC_TOP[BX]	; FAT sector top.
	MOVX	REC_FAT_CNT	,DS:D_FAT_SEC_CNT[BX]	; FAT sector count.
	MOVX	REC_FAT_COPY	,DS:D_FAT_COPY[BX]	; FAT copy count.
	MOVX	REC_SEC_FAT	,DS:D_SEC_FAT[BX]	; sector/FAT.
	MOVX	REC_ROOT	,DS:D_ROOT_SEC_TOP[BX]	; root sector top.
	MOVX	REC_ROOT_CNT	,DS:D_ROOT_SEC_CNT[BX]	; root sector count.
	MOVX	REC_SYSTEM_TOP	,DS:D_SYSTEM_TOP[BX]	; system top record.
	MOVX	CLAST_SEC_CNT	,DS:D_CLAST_SEC_CNT[BX]	; clast in sector.
	MOVX	CLAST_LEN	,DS:D_CLAST_LEN[BX]	; clast length.
	MOVX	MEDIA_DISC	,DS:D_MEDIA_DISC[BX]	; dos media disc.

	CALL	IPLHED_SET			; IPL header set.

	CALL	SYSTEM_SEC_CNT_SET		; system sector count set.

	MOV	DX,MEDIA_TYPE			; media type.
	CALL	SCWMOD				; drive type.

SYSMOD_EXIT:
	RET
SYSMOD	ENDP



;	IPL header set.
;	-I- MEDIA_TYPE : media type.

IPLHED_SET	PROC	NEAR
	CMP	MEDIA_TYPE,1			;
	JMPL	IPLHED_SET_EXIT			;
	CMP	MEDIA_TYPE,4			;
	JMPG	IPLHED_SET_EXIT			;

	MOV	BX,MEDIA_TYPE			; media type.
	SHL	BX,1				; word pointer.
	MOV	SI,DS:IPL_HEADER_TBL[BX]	; IPL code header.
	MOV	DI,OFFSET IPLHEADER		; IPL code header.
	MOV	AX,SEG CODIPL			; IPL code segment.
	MOV	ES,AX				;
	MOV	CX,29				; 29byte.
	REP	MOVSB				;

IPLHED_SET_EXIT:
	RET
IPLHED_SET	ENDP



;	system sector count set.

SYSTEM_SEC_CNT_SET	PROC	NEAR
	MOV	AX,SEG CODIPL			; IPL code segment.
	MOV	ES,AX				;

	MOV	BX,ES:[0BH]			;+0Bh byte/sector.
	CMP	BX,0				;
	JE	SYSTEM_SEC_CNT_SET_ER		;

	MOV	AX,OFFSET SYSEND		; system code end.
	SUB	AX,OFFSET SYSTOP		; system code top.
	MOV	DX,0				;
	DIV	BX				; (SYSEND - SYSTOP) / BX
	CMP	DX,0				;
	JE	SYSTEM_SEC_CNT_SET_5		;
	INC	AX				;
SYSTEM_SEC_CNT_SET_5:				;

	MOV	ES:[24H],AX			;+24h system sector count.

	MOV	SYSTEM_CNT,AX			; system sector count.

	RET
SYSTEM_SEC_CNT_SET_ER:
	RET
SYSTEM_SEC_CNT_SET	ENDP



;	system write to disk.
;	-I- DX : drive number.
;	-O- AX : 0=normal,1=error

SYSSET	PROC	NEAR
	MOV	DRVNO,DX		; drive number.

	CALL	IPL_SIZE_CHECK		; IPL size check.
	CMP	AX,0			; 0=normal,1=size over.
	JMPNE	SYSSET_IPL_SIZE_OV	;

	CALL	SYS_SIZE_CHECK		; system size check.
	CMP	AX,0			; 0=normal,1=size over.
	JMPNE	SYSSET_SYS_SIZE_OV	;

	CALL	DIR_SET			; directory set.

	CALL	SCWINI			; initialize.

	MOV	AX,DRVNO		; drive number.
	CALL	SCWDRV			; set drive.

	PRF	"IPL"

	CALL	SAVE_IPL		; IPL save.
	CMP	AX,0			;
	JNE	SYSSET_ERROR		;

	PRF	"system"

	CALL	SAVE_SYS		; system save.
	CMP	AX,0			;
	JNE	SYSSET_ERROR		;

	PRF	"FAT"

	CALL	SAVE_FAT		; FAT save.
	CMP	AX,0			;
	JNE	SYSSET_ERROR		;

	PRF	"root"

	CALL	SAVE_ROOT		; root save.
	CMP	AX,0			;
	JNE	SYSSET_ERROR		;

	PRF	"complete."
	MOV	AX,0			; 0=normal.
	RET
SYSSET_ERROR:
	PRF	"error."
	MOV	AX,1			; 1=error.
	RET
SYSSET_SYS_SIZE_OV:
	PRF	"system size error."
	MOV	AX,1			; 1=error.
	RET
SYSSET_IPL_SIZE_OV:
	PRF	"IPL size error."
	MOV	AX,1			; 1=error.
	RET
SYSSET	ENDP


;	IPL size check.
;	-O- AX : 0=normal,1=size over.

IPL_SIZE_CHECK	PROC	NEAR
	MOV	AX,OFFSET IPLEND	; IPL code end.
	SUB	AX,OFFSET IPLTOP	; IPL code top.
	INC	AX			; IPL code size.

	PRV	"IPL code size=",AX

	CMP	AX,SEC_BYTE		; sector length.
	JNBE	IPL_SIZE_CHECK_ER	;

	MOV	AX,0			; 0=normal.
	RET
IPL_SIZE_CHECK_ER:
	MOV	AX,1			; 1=size over.
	RET
IPL_SIZE_CHECK	ENDP


;	system size check.
;	-O- AX : 0=normal,1=size over.

SYS_SIZE_CHECK	PROC	NEAR
	MOV	AX,OFFSET SYSEND	; system code end.
	SUB	AX,OFFSET SYSTOP	; system code top.
	INC	AX			; 

	PRV	"system code size=",AX

	CMP	AX,SYSTEM_SIZE_MAX	; system size max.
	JNBE	SYS_SIZE_CHECK_ER	;

	MOV	AX,0			; 0=normal.
	RET				;
SYS_SIZE_CHECK_ER:
	MOV	AX,1			; 1=error.
	RET
SYS_SIZE_CHECK	ENDP



;	IPL save.
;	-O- AX : 0=normal,1=error.

SAVE_IPL	PROC	NEAR
	MOV	AX,REC_IPL		; IPL record.
	CALL	SCWSET			; start record number set.

	MOV	DX,SEG CODIPL		; IPL code segment.
	MOV	BX,OFFSET IPLTOP	; IPL code top.
	CALL	SCWSEQ			; sequential write of sector.
	CMP	AX,0			; 0=normal,1=error,2=end sector write.
	JNE	SAVE_IPL_ERROR		;

	MOV	AX,0			; 0=normal.
	RET
SAVE_IPL_ERROR:
	PRF	"IPL write error."
	MOV	AX,1			; 1=error.
	RET
SAVE_IPL	ENDP



;	system save.
;	-I/O- FAT_SEC_TOP : FAT buffer write.
;	-O-   AX          : 0=normal,1=error.

SAVE_SYS	PROC	NEAR
	MOV	AX,REC_SYSTEM_TOP	; system top record.
	CALL	SCWSET			;

	MOV	AX,CLAST_TOP		; clast start number.
	MOV	PNTNXT,AX		; next clast number.

	MOV	AX,OFFSET SYSTOP	; system code top.
	MOV	NOWOFFSET,AX		; write pointer.
SAVE_SYS_LOOP:
	MOV	AX,PNTNXT		; next clast number.
	MOV	PNTNOW,AX		; now clast number.
	INC	PNTNXT			; next clast number.
	CALL	FATSET			; FAT clast number set.

	MOV	DX,SEG CODSYS		; system code segment.
	MOV	BX,NOWOFFSET		; write pointer.
	MOV	CX,CLAST_SEC_CNT	; clast in sector.
	CALL	MULT_SECTOR_WRITE	; multi sector write.
	CMP	AX,0			; 0=normal,1=error.
	JNE	SAVE_SYS_ERROR		;

	ADDX	NOWOFFSET,CLAST_LEN	; clast length.

	MOV	AX,NOWOFFSET		;
	CMP	AX,OFFSET SYSEND	; system code end.
	JBE	SAVE_SYS_LOOP		; loop end.

	MOV	PNTNXT,END_SEC_MARK	; end sector mark.
	CALL	FATSET			; FAT clast number set.

	MOV	AX,0			; 0=normal.
	RET
SAVE_SYS_ERROR:
	PRF	"system write error."
	MOV	AX,1			; 1=error.
	RET
SAVE_SYS	ENDP



;	FAT save.
;	-I- FAT_SEC_TOP : FAT buffer.
;	-O- AX          : 0=normal,1=error.

SAVE_FAT	PROC	NEAR
	CMP	REC_FAT_COPY,0		; FAT copy count.
	JE	SAVE_FAT_EXIT		;

	MOV	AX,REC_FAT		; FAT record.
	CALL	SCWSET			;

	MOVX	LOOPCNT,REC_FAT_COPY	; FAT copy count.
SAVE_FAT_LOOP:				;
	CMP	LOOPCNT,0		; FAT copy count.
	JE	SAVE_FAT_LOOP_E		;
	MOV	DX,SEG DATA		; FAT segment.
	MOV	BX,OFFSET FAT_SEC_TOP	; FAT offset.
	MOV	CX,REC_SEC_FAT		; sector/FAT.
	CALL	MULT_SECTOR_WRITE	; multi sector write.
	CMP	AX,0			; 0=normal,1=error.
	JNE	SAVE_FAT_ERROR		;
	DEC	LOOPCNT			;
	JMP	SAVE_FAT_LOOP		;
SAVE_FAT_LOOP_E:			;

SAVE_FAT_EXIT:				;
	MOV	AX,0			; 0=normal.
	RET
SAVE_FAT_ERROR:
	PRF	"FAT write error."
	MOV	AX,1			; 1=error.
	RET
SAVE_FAT	ENDP



;	root save.
;	-I- FDIR_SYS_ENTRY : start directory set.
;	    FDIR_FULL_SET  : repert directory set.
;	-O- AX             : 0=normal,1=error.

SAVE_ROOT	PROC	NEAR
	CMP	REC_ROOT_CNT,0		; root record count.
	JE	SAVE_ROOT_EXIT		;

	MOV	AX,REC_ROOT		; root record.
	CALL	SCWSET			;

	MOV	DX,SEG DATA		 ; segment.
	MOV	BX,OFFSET FDIR_SYS_ENTRY ; start directory set.
	CALL	SCWSEQ			; sequential write of sector.
	CMP	AX,0
	JNE	SAVE_ROOT_ERROR

	MOVX	LOOPCNT,REC_ROOT_CNT	; root record count.
	DEC	LOOPCNT			; -1
SAVE_ROOT_LOOP:				;
	CMP	LOOPCNT,0		;
	JE	SAVE_ROOT_LOOP_END	;
	MOV	DX,SEG DATA		; segment.
	MOV	BX,OFFSET FDIR_FULL_SET	; anther directory set.
	CALL	SCWSEQ			; sequential write of sector.
	CMP	AX,0
	JNE	SAVE_ROOT_ERROR
	DEC	LOOPCNT			; -1
	JMP	SAVE_ROOT_LOOP		;
SAVE_ROOT_LOOP_END:

SAVE_ROOT_EXIT:
	MOV	AX,0			; 0=normal.
	RET
SAVE_ROOT_ERROR:
	PRF	"root write error."
	MOV	AX,1			; 1=error.
	RET
SAVE_ROOT	ENDP



;	FAT clast number set.
;	-I- PNTNOW : now clast number.
;	    PNTNXT : next clast number.

FATSET	PROC	NEAR
	MOV	AX,PNTNOW		; now clast number.
	SHR	AX,1			; /2
	MOV	SI,AX			; FAT table address pointer.
	ADD	SI,AX			;
	ADD	SI,AX			; ( *3 )

	MOV	AX,PNTNOW		; now clast number.
	SHR	AX,1			; check even.
	JB	FATSET2			;

					; case: even.
	MOV	AX,PNTNXT		; next clast number.
	AND	WORD PTR FAT_SEC_TOP[SI],0F000H ; 3 nible
	OR	WORD PTR FAT_SEC_TOP[SI],AX	; 3 nible
	RET
FATSET2:				; case: odd.
	MOV	AX,PNTNXT		; next clast number.
	SHL	AX,1			;
	SHL	AX,1			; 1 nible shift.
	SHL	AX,1			;
	SHL	AX,1			;
	
	AND	WORD PTR FAT_SEC_TOP[SI+1],000FH ; 3 nible
	OR	WORD PTR FAT_SEC_TOP[SI+1],AX	; 3 nible
	RET
FATSET	ENDP


;	directory set.

DIR_SET	PROC	NEAR
	MOV	AX,OFFSET SYSEND	; system code end.
	SUB	AX,OFFSET SYSTOP	; system code top.
	INC	AX			; system code size.
	MOV	WORD PTR FSIZE,AX	; file size.
	MOVX	FCLST,CLAST_TOP		; clast start number.

	MOV	AL,BYTE PTR MEDIA_DISC	; dos media discript.
	MOV	FAT_SEC_TOP,AL		; FAT buffer.
	RET
DIR_SET	ENDP


;	multi sector write.
;	-I- DX : buffer segment.
;	    BX : buffer offset.
;	    CX : sector.
;	-O- AX : 0=normal,1=error.

MULT_SECTOR_WRITE	PROC	NEAR
	JCXZ	MULT_SECTOR_WRITE_EXIT	;
MULT_SECTOR_WRITE_LOOP:			;
	PUSH	DX			; segment.
	PUSH	BX			; write pointer.
	PUSH	CX			;
	CALL	SCWSEQ			; sequential write of sector.
	POP	CX			;
	POP	BX			; write pointer.
	POP	DX			; segment.
	CMP	AX,0
	JNE	MULT_SECTOR_WRITE_ERROR	;
	ADD	BX,SEC_BYTE		; sector length.
	LOOP	MULT_SECTOR_WRITE_LOOP	;

MULT_SECTOR_WRITE_EXIT:			;
	MOV	AX,0			; 0=normal.
	RET
MULT_SECTOR_WRITE_ERROR:		;
	MOV	AX,1			; 1=error.
	RET
MULT_SECTOR_WRITE	ENDP

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

;	IPL header table.

IPL_HEADER_TBL	LABEL	WORD		; IPL code header.
	DW	0			;
	DW	IPL_HEADER_360KB	; 360KB
	DW	IPL_HEADER_12MB		; 1.2MB
	DW	IPL_HEADER_720KB	; 720KB
	DW	IPL_HEADER_144MB	; 1.44MB

;	360KB

IPL_HEADER_360KB	LABEL	BYTE
	DW	512		;+0  +0Bh byte/sector.
	DB	2		;+2  +0Dh sector/clast.
	DW	1		;+3  +0Eh reserved sector.
	DB	2		;+5  +10h FAT copy count.
	DW	112		;+6  +11h root dir entry count.
	DW	720		;+8  +13h full sector count.
	DB	0FDH		;+10 +15h dos media discripta.
	DW	2		;+11 +16h sector/FAT.
	DW	9		;+13 +18h sector/track.
	DW	2		;+15 +1Ah head count.
	DW	0		;+17 +1Ch dark sector.								; system top sector.
	DW	0		;+19  cylinder.
	DW	1		;+21  head.
	DW	4		;+23  sector.
	DW	5		;+25  system sector count.
	DW	1		;+27 drive media type.

;	1.2MB

IPL_HEADER_12MB		LABEL	BYTE
	DW	512		;+0Bh byte/sector.
	DB	1		;+0Dh sector/clast.
	DW	1		;+0Eh reserved sector.
	DB	2		;+10h FAT copy count.
	DW	224		;+11h root dir entry count.
	DW	2400		;+13h full sector count.
	DB	0F9H		;+15h dos media discripta.
	DW	7		;+16h sector/FAT.
	DW	15		;+18h sector/track.
	DW	2		;+1Ah head count.
	DW	0		;+1Ch dark sector.
				; system top sector.
	DW	0		; cylinder.
	DW	1		; head.
	DW	15		; sector.
	DW	5		; system sector count.
	DW	2		; drive media type.

;	720KB

IPL_HEADER_720KB		LABEL	BYTE
	DW	512		;+0Bh byte/sector.
	DB	2		;+0Dh sector/clast.
	DW	1		;+0Eh reserved sector.
	DB	2		;+10h FAT copy count.
	DW	112		;+11h root dir entry count.
	DW	1440		;+13h full sector count.
	DB	0F9H		;+15h dos media discripta.
	DW	3		;+16h sector/FAT.
	DW	9		;+18h sector/track.
	DW	2		;+1Ah head count.
	DW	0		;+1Ch dark sector.
				; system top sector.
	DW	0		; cylinder.
	DW	1		; head.
	DW	6		; sector.
	DW	5		; system sector count.
	DW	3		; drive media type.

;	1.44MB

IPL_HEADER_144MB		LABEL	BYTE
	DW	512		;+0Bh byte/sector.
	DB	1		;+0Dh sector/clast.
	DW	1		;+0Eh reserved sector.
	DB	2		;+10h FAT copy count.
	DW	224		;+11h root dir entry count.
	DW	2880		;+13h full sector count.
	DB	0F0H		;+15h dos media discripta.
	DW	9		;+16h sector/FAT.
	DW	18		;+18h sector/track.
	DW	2		;+1Ah head count.
	DW	0		;+1Ch dark sector.
				; system top sector.
	DW	0		; cylinder.
	DW	1		; head.
	DW	16		; sector.
	DW	5		; system sector count.
	DW	4		; drive media type.

;	data.
		EVEN
MEDIA_TYPE	DW	4	; media type 1=360KB,2=1.2MB,3=720KB,4=1.44MB

REC_IPL		DW	0	; IPL record.
REC_FAT		DW	1	; FAT record.
REC_FAT_CNT	DW	18	; FAT record count.
REC_FAT_COPY	DW	2	; FAT copy count.
REC_SEC_FAT	DW	9	; sector/FAT.
REC_ROOT	DW	19	; root record.
REC_ROOT_CNT	DW	14	; root record count.
REC_SYSTEM_TOP	DW	34	; system top record.
CLAST_TOP	DW	2	; clast start number.
CLAST_SEC_CNT	DW	1	; clast in sector.
CLAST_LEN	DW	512	; clast length.
MEDIA_DISC	DW	0F0H	; dos media discript.

;			PC/XT	,AT	,Convert,PS/2
;			360KB	1.2MB	720KB	1.44KB
D_FAT_SEC_TOP 	DW 0,	1,	1,	1,	1	; FAT sector top.
D_FAT_SEC_CNT	DW 0,	4,	14,	6,	18	; FAT sector count.
D_FAT_COPY	DW 0,	2,	2,	2,	2	; FAT copy count.
D_SEC_FAT	DW 0,	2,	7,	3,	9	; sector/FAT.
D_ROOT_SEC_TOP	DW 0,	5,	15,	7,	19	; root sector top.
D_ROOT_SEC_CNT	DW 0,	7,	14,	7,	14	; root sector count.
D_SYSTEM_TOP	DW 0,	12,	29,	14,	33	; system top record.
D_CLAST_SEC_CNT	DW 0,	2,	1,	2,	1	; clast in sector.
D_CLAST_LEN	DW 0,	1024,	512,	1024,	512	; clast length.
D_MEDIA_DISC	DW 0,	0FDH,	0F9H,	0F9H,	0F0H	; dos media disc.

FDIR_SYS_ENTRY	LABEL	BYTE	; start directory set.
FNAME	DB	"EXELOAD "	; file name.
FTYPE	DB	"SYS"		; file type.
FATR	DB	0		; file attribute.
FSYS	DB	10 DUP (0)	; system reserve.
FTIME	DW	0		; file update time.
FDATE	DW	0		; file update date.
FCLST	DW	2		; file start clast.
FSIZE	DD	0		; file size.
FDIR_FULL_SET	LABEL	BYTE	; anther directory set.
FSET01	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET02	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET03	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET04	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET05	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET06	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET07	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET08	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET09	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET10	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET11	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET12	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET13	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET14	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET15	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET16	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET17	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET18	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET19	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET20	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET21	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET22	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET23	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET24	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET25	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET26	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET27	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET28	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET29	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET30	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET31	DB	0,"EXELOAD","NON",0,20 DUP (0)
FSET32	DB	0,"EXELOAD","NON",0,20 DUP (0)

;	FAT buffer.

FAT_SEC_TOP	LABEL	BYTE
	DB	0FEH,0FFH,0FFH			;
	DB	SEC_BYTE-3	DUP (0)		;1
	DB	SEC_BYTE	DUP (0)		;2
	DB	SEC_BYTE	DUP (0)		;3
	DB	SEC_BYTE	DUP (0)		;4
	DB	SEC_BYTE	DUP (0)		;5
	DB	SEC_BYTE	DUP (0)		;6
	DB	SEC_BYTE	DUP (0)		;7
	DB	SEC_BYTE	DUP (0)		;8
	DB	SEC_BYTE	DUP (0)		;9

SYSTEM_CNT	DW	0	; system sector count.

NOWOFFSET	DW	0	; write pointer.

PNTNOW		DW	0	; now clast number.
PNTNXT		DW	0	; next clast number.

DRVNO		DW	0	; drive number.

LOOPCNT		DW	0	; loop counter.



DATA	ENDS

	END
;
;	end of "SYSSET.ASM"
;
