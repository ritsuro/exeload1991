; "FDTRACK.ASM" PC-9801UV11 make by R.H 1991/08/22
;
;
;	FDD track load & save.
;
;
; public subroutine.

INCLUDE	TSTSET.INC

READ_RETCOUNT 	EQU	3		; read retry.
WRITE_RETCOUNT 	EQU	3		; write retry.

MOVX	MACRO	DEST,SOU
	MOV	AX,SOU
	MOV	DEST,AX
	ENDM

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE,DS:DATA

PUBLIC	TRACKLOAD		; track load.
PUBLIC	TRACKSAVE		; track save.
PUBLIC	TRACKSECSET		; track sector count set .
PUBLIC	TRACKRDIPL		; IPL read.
PUBLIC	TRACKRESET		; drive reset.

; ****************************************************
;	track load.
;	-I- AX : track number.
;	    DX : source segment address.
;	    DI : source offset  address.
;	-O- AX : 0=normal,1=error.
; ****************************************************

TRACKLOAD	PROC	NEAR
	MOV	RDF_CHASH_SEG,DX	; track buffer segment.
	MOV	RDF_CHASH_OFS,DI	; track buffer offset.

	MOV	DX,0			;
	MOV	BX,2			; head count = 2
	DIV	BX			; AX = AX  /  2
	MOV	DHEAD,DX		; head number.
	MOV	DCYL,AX			; cylinder number.

	CALL	RDCYLN			; cylinder read.
	CMP	DERROR,0		; 0=normal,1=error.
	JNE	TRACKLOAD_ERROR		;

	MOV	AX,0			; 0=normal.
	RET
TRACKLOAD_ERROR:
	MOV	AX,1			; 1=error.
	RET
TRACKLOAD	ENDP


; ****************************************************
;	track save.
;	-I- AX : track number.
;	    DX : source segment address.
;	    DI : source offset  address.
;	-O- AX : 0=normal,1=error.
; ****************************************************

TRACKSAVE	PROC	NEAR
	MOV	RDF_CHASH_SEG,DX	; track buffer segment.
	MOV	RDF_CHASH_OFS,DI	; track buffer offset.

	MOV	DX,0			;
	MOV	BX,2			; head count = 2
	DIV	BX			; AX = AX  /  2
	MOV	DHEAD,DX		; head number.
	MOV	DCYL,AX			; cylinder number.

	CALL	WTCYLN			; cylinder write.
	CMP	DERROR,0		; 0=normal,1=error.
	JNE	TRACKSAVE_ERROR		;

	MOV	AX,0			; 0=normal.
	RET
TRACKSAVE_ERROR:
	MOV	AX,1			; 1=error.
	RET
TRACKSAVE	ENDP


; ****************************************************
;	track sector count set .
;	-I- AX : sector/track.
; ****************************************************

TRACKSECSET	PROC	NEAR
	MOV	FD_MAX_SECTOR,AX		; sector/track.
	RET
TRACKSECSET	ENDP


; ****************************************************
;	IPL read.
;	-I- DX : IPL buffer segment.
;	    DI : IPL buffer offset.
;	-O- AX : 0=normal,1=error.
; ****************************************************

TRACKRDIPL	PROC	NEAR
	MOV	IPL_BUFFER_SEG,DX	; source segment address.
	MOV	IPL_BUFFER_OFS,DI	; source offset  address.
	CALL	RDIPL			; IPL read.
	MOV	AX,DERROR		; 0=normal,1=error.
	RET
TRACKRDIPL	ENDP


; ****************************************************
;	drive reset.
; ****************************************************

TRACKRESET	PROC	NEAR
	CALL	RECALIBRATE		; recalibrate.
	RET
TRACKRESET	ENDP


; ****************************************************
;	cylinder read.
;	-I-   DCYL   : cylinder number.
;	      DHEAD  : head number.
;	-O-   RDF_CHASH_SEG:[RDF_CHASH_OFS] : track buffer.
;	      DERROR : 0=normal,1=error.
; ****************************************************

RDCYLN	PROC	NEAR
	MOV	DERROR,0		; 0=normal.

	MOVX	DSCNT,FD_MAX_SECTOR	; sector/track.

;*;	PRVH	"RDF_CHASH_SEG=",RDF_CHASH_SEG
;*;	PRVH	"RDF_CHASH_OFS=",RDF_CHASH_OFS
;*;	PRV	"DUNIT=",DUNIT
;*;	PRV	"DHEAD=",DHEAD
;*;	PRV	"DCYL =",DCYL
;*;	PRV	"DSCNT=",DSCNT

	MOV	READ_RETRY,READ_RETCOUNT ; read retry.
RDCYLN_RETRY:
	MOV	ES,RDF_CHASH_SEG	; track buffer segment.
	MOV	BX,RDF_CHASH_OFS	; track buffer offset.

	MOV	DL,BYTE PTR DUNIT	; unit number.
	AND	DL,11B			;
	MOV	DH,BYTE PTR DHEAD 	; head number.
	MOV	CH,BYTE PTR DCYL 	; cylinder number.
	MOV	CL,1		 	; start sector.
	MOV	AL,BYTE PTR DSCNT	; sector.
	MOV	AH,BYTE PTR 02H		; read data.
	INT	13H			; disk BIOS.
	MOV	BYTE PTR DSTAT,AH	; status.
	JB	RDCYLN_ERROR		;

RDCYLN_EXIT:
	MOV	DERROR,0		; 0=normal.
	RET				;

RDCYLN_ERROR:				;
	PRVH	"read sec error AX=",AX

	DEC	READ_RETRY		; read retry counter.
	JZ	RDCYLN_ER_END		;

	CALL	RECALIBRATE		; recalibrate.

	JMP	RDCYLN_RETRY		;

RDCYLN_ER_END:				;
	MOV	DERROR,1		; 1=error.
	RET				;
RDCYLN	ENDP


; ****************************************************
;	cylinder write.
;	-I-   DCYL   : cylinder number.
;	      DHEAD  : head number.
;	      RDF_CHASH_SEG:[RDF_CHASH_OFS] : track buffer.
;	-O-   DERROR : 0=normal,1=error.
; ****************************************************

WTCYLN	PROC	NEAR
	MOV	DERROR,0		; 0=normal.

	MOVX	DSCNT,FD_MAX_SECTOR	; sector/track.

	MOV	WRITE_RETRY,WRITE_RETCOUNT ; write retry.
WTCYLN_RETRY:
	MOV	ES,RDF_CHASH_SEG	; track buffer segment.
	MOV	BX,RDF_CHASH_OFS	; track buffer offset.

	MOV	DL,BYTE PTR DUNIT	; unit number.
	AND	DL,11B			;
	MOV	DH,BYTE PTR DHEAD 	; head number.
	MOV	CH,BYTE PTR DCYL 	; cylinder number.
	MOV	CL,1		 	; start sector.
	MOV	AL,BYTE PTR DSCNT	; sector.
	MOV	AH,BYTE PTR 03H		; write data.
	INT	13H			; disk BIOS.
	MOV	BYTE PTR DSTAT,AH	; status.
	JB	WTCYLN_ERROR		;

WTCYLN_EXIT:
	MOV	DERROR,0		; 0=normal.
	RET				;

WTCYLN_ERROR:				;
;*;	PRVH	"write sec error AX=",AX

	DEC	WRITE_RETRY		; write retry counter.
	JZ	WTCYLN_ER_END		;
	
	CALL	RECALIBRATE		; recalibrate.

	JMP	WTCYLN_RETRY		;

WTCYLN_ER_END:
	MOV	DERROR,1		; 1=error.
	RET
WTCYLN	ENDP


; ****************************************************
;	IPL read.
;	-I- IPL_BUFFER_SEG:[IPL_BUFFER_OFS] : IPL buffer.
;	-O- DERROR : 0=normal,1=error.
; ****************************************************

RDIPL	PROC	NEAR
	MOV	DERROR,0		; 0=normal.

	MOVX	DSCNT,FD_MAX_SECTOR	; sector/track.

	MOV	READ_RETRY,READ_RETCOUNT ; read retry.
RDIPL_RETRY:
	MOV	ES,IPL_BUFFER_SEG	; IPL buffer segment.
	MOV	BX,IPL_BUFFER_OFS	; IPL buffer offset.

	MOV	DL,BYTE PTR DUNIT	; unit number.
	MOV	DH,0			; 0=head number.
	MOV	CH,0			; 0=cylinder.
	MOV	CL,1		 	; 1=sector.
	MOV	AL,1			; 1=sector count.
	MOV	AH,BYTE PTR 02H		; read data.
	INT	13H			; disk BIOS.
	MOV	BYTE PTR DSTAT,AH	; status.
	JB	RDIPL_ERROR		;

RDIPL_EXIT:
	MOV	DERROR,0		; 0=normal.
	RET				;
RDIPL_ERROR:				;
	DEC	READ_RETRY		; read retry counter.
	JZ	RDIPL_ER_END		;
	CALL	RECALIBRATE		; recalibrate.
	JMP	RDIPL_RETRY		;
RDIPL_ER_END:				;
	MOV	DERROR,1		; 1=error.
	RET				;
RDIPL	ENDP


; ****************************************************
;	recalibrate.
; ****************************************************

RECALIBRATE	PROC	NEAR
	MOV	DL,BYTE PTR DUNIT	; unit number PS/2 only.
	MOV	AH,00H			; disk reset.
	INT	13H			; disk BIOS.
	RET
RECALIBRATE	ENDP

CODE	ENDS


DATA	SEGMENT	PUBLIC	'DATA'

RDF_CHASH_SEG	DW	0		; track buffer segment.
RDF_CHASH_OFS	DW	0		; track buffer offset.

IPL_BUFFER_SEG	DW	0		; IPL buffer segment.
IPL_BUFFER_OFS	DW	0		; IPL buffer offset.

FD_MAX_SECTOR	DW	18		; sector/track.

DUNIT		DW	0		; unit number.
DCYL		DW	0		; cylinder number.
DHEAD		DW	0		; head number.
DSCNT		DW	0		; sector.
DSTAT		DW	0		; status.
DERROR		DW	0		; 0=normal,1=error.

READ_RETRY	DW	0		; read retry counter.
WRITE_RETRY	DW	0		; write retry counter.

DATA	ENDS

	END
;
;	end of "FDTRACK.ASM"
;
