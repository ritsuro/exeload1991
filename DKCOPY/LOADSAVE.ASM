; "LOADSAVE.ASM" PC-9801UV11 make by R.H 1991/08/22
;
;
;	load & save.
;
;
; public subroutine.

CODE	SEGMENT	PUBLIC	'CODE'

	ASSUME	CS:CODE

PUBLIC	DISKLOAD		; disk load.
PUBLIC	DISKSAVE		; disk save.

; ****************************************************
;	disk load.
;	-I- SI : file name.
;	    DX : dest segment address.
;	    DI : dest offset  address.
;	    CX : data length.
;	-O- AX : 0=normal,1=error.
; ****************************************************

DISKLOAD	PROC	NEAR
	PUSH	DX
	PUSH	DI
	PUSH	CX
	MOV	DX,SI		; file name.
	MOV	AL,0		; read mode.
	MOV	AH,3DH		; open handle.
	INT	21H		; dos call.
	POP	CX
	POP	DI
	POP	DX
	JC	DISKLOAD_ERROR	;

	PUSH	DS
	PUSH	AX
	MOV	BX,AX		; open handle.
	MOV	DS,DX		; buffer segment.
	MOV	DX,DI		; buffer offset.
	MOV	AH,3FH		; read handle.
	INT	21H		; dos call.
	POP	AX
	POP	DS
	JC	DISKLOAD_ERROR	;

	MOV	BX,AX		; open handle.
	MOV	AH,3EH		; close handle.
	INT	21H		; dos call.

DISKLOAD_EXIT:
	MOV	AX,0		; 0=normal
	RET
DISKLOAD_ERROR:
	MOV	AX,1		; 1=error
	RET
DISKLOAD	ENDP


; ****************************************************
;	disk save.
;	-I- SI : file name.
;	    DX : source segment address.
;	    DI : source offset  address.
;	    CX : data length.
;	-O- AX : 0=normal,1=error.
; ****************************************************

DISKSAVE	PROC	NEAR
	PUSH	DX
	PUSH	DI
	PUSH	CX
	MOV	DX,SI		; file name.
	MOV	CX,0		; file attribute.
	MOV	AH,3CH		; create handle.
	INT	21H		; dos call.
	POP	CX
	POP	DI
	POP	DX
	JC	DISKSAVE_ERROR	;

	PUSH	DS
	PUSH	AX
	MOV	BX,AX		; open handle.
	MOV	DS,DX		; buffer segment.
	MOV	DX,DI		; buffer offset.
	MOV	AH,40H		; write handle.
	INT	21H		; dos call.
	POP	AX
	POP	DS
	JC	DISKSAVE_ERROR	;

	MOV	BX,AX		; open handle.
	MOV	AH,3EH		; close handle.
	INT	21H		; dos call.
	JC	DISKSAVE_ERROR	;

DISKSAVE_EXIT:
	MOV	AX,0		; 0=normal
	RET
DISKSAVE_ERROR:
	MOV	AX,1		; 1=error
	RET
DISKSAVE	ENDP

CODE	ENDS

	END
;
;	end of "LOADSAVE.ASM"
;
