; "PSMAIN.ASM" PC-9801UV11,J-3100GS001 make by R.Hashimoto
; 1989/11/13,1990/10/09,1991/04/04
;
;
;	E X E L O A D    c o m m a n d   s h e l l .
;
;
;
; command.

INCLUDE	TSTSET.INC

CODE	SEGMENT	PUBLIC	'CODE'
	ASSUME	CS:CODE,DS:DATA

PUBLIC	PSMAIN			; programers command shell.

EXTRN	I21HSET:NEAR		; 割込みを設定
EXTRN	I21HRST:NEAR		; 割込み元に戻す
EXTRN	I21HDRV:NEAR		; デフォルトドライブ番号
EXTRN	I21HRET:NEAR		; プロセスへの戻りアドレス設定

EXTRN	CMTYPE:NEAR		; テキストファイルの表示

EXTRN	CMDIR:NEAR		; ＤＩＲ
EXTRN	CMFAT:NEAR		; ＦＡＴダンプ

EXTRN	CMLCOM:NEAR		; ＬＯＡＤ／ＣＯＭファイル
EXTRN	CMLEXE:NEAR		; ＬＯＡＤ／ＥＸＥファイル

EXTRN	CMPCOM:NEAR		; 標準ＣＯＭプロセス
EXTRN	CMPROC:NEAR		; 標準ＤＯＳプロセス

EXTRN	CMMINT:NEAR		; メモリ管理初期化
EXTRN	CMFREE:NEAR		; フリーエリアの開始位置
EXTRN	CMMALC:NEAR		; 使用エリアの確保
EXTRN	CMMCUT:NEAR		; 使用エリアの開放

EXTRN	CMDBIO:NEAR		; バイオスデバック
EXTRN	CMDMPT:NEAR		; ＭＰＴテーブルデバック
EXTRN	CMDDMD:NEAR		; ドライブモード
EXTRN	CMDFDS:NEAR		; ＦＤドライブ情報

EXTRN	CMDVTEST:NEAR		; VIDEO test.

EXTRN	CMDIMAGE:NEAR		; image test.

EXTRN	CMKILL:NEAR		; ＫＩＬＬ
EXTRN	CMFFIL:NEAR		; 真っ白のファイルを作る
EXTRN	CMCOPY:NEAR		; ＣＯＰＹ

EXTRN	PRNAH:NEAR		; print ah reg.
EXTRN	PRINT:NEAR		; print string.
EXTRN	DECSTR:NEAR		; val DX to dec string.
EXTRN	INPUT:NEAR		; string input.
EXTRN	STRDEC:NEAR		; dec string to DX reg.
EXTRN	HEXSTR:NEAR		; val DX to hex string.
EXTRN	STRHEX:NEAR		; hex string to DX reg.
EXTRN	BINSTR:NEAR		; val DX to bin string.
EXTRN	STRBIN:NEAR		; bin string to DX reg.
EXTRN	STRCMP:NEAR		; string compare.
EXTRN	CLS:NEAR		; text clear.
EXTRN	CSLON:NEAR		; cursole on.
EXTRN	CSLOFF:NEAR		; cursole off.
EXTRN	INPCHR:NEAR		; 1 char input.
EXTRN	CHPUT:NEAR		; print of ascii character.
EXTRN	KESCAP:NEAR		; ESC key & break check & pause.
EXTRN	KEYLOD:NEAR		; key buffer read.
EXTRN	PRNAB:NEAR		; print of a register(BIN).
EXTRN	LOCATE:NEAR		; locate.
EXTRN	LFPRN:NEAR		; line feed.
EXTRN	D10STR:NEAR		; i*4 value -> decimal string.

EXTRN	FFDRV:NEAR		; カレントドライブ設定

CHR_SPACE	EQU	20H	; space.
CHR_TAB		EQU	09H	; tab.
CHR_LF		EQU	0AH	; line feed.
CHR_CR		EQU	0DH	; calig return.
EOS		EQU	0	; end of string.
STRING_LEN	EQU	128	; string buffer length.
TOKEN_MAX	EQU	4	; token max.


; *********************************************************
;	programers command shell.
;	-I- DX:cullent drive number.
; *********************************************************

PSMAIN	PROC	NEAR
	PUSH	DX
	CALL	I21HSET			; 割込みを設定
	POP	DX

	CALL	SETUNIT			; unit name set.

	CMP	AX,2			; disk error.
	JNE	PSMAIN_2		;
	MOV	SI,OFFSET MES_NOT_DIR	;
	CALL	PRINT			;
PSMAIN_2:
	CALL	CINIT			; shell init.

	CALL	AUTOEXEC		; autoexec
PSHELL_INP:
	CALL	CINP			; console input.
	CALL	CCHECK			; check.
	CMP	NONE,1			; none?
	JE	PSHELL_INP		;

	CALL	CCMP			; comp. -> COMMAND_NUM
	CMP	NOT_FOUND,1		; 1=not found.
	JE	PSHELL_PROCESS		;

	CALL	TOKADR			; token get address.

	CALL	SPACE_CUT		; space cut.

	CALL	CCOMMAND		; command processer.
	CMP	EXIT,1			; exit?
	JE	PSHELL_END		;

	JMP	PSHELL_INP		; next.

PSHELL_PROCESS:
	CALL	CPROCESS		; EXE process.

	JMP	PSHELL_INP		; next.
PSHELL_END:
	CALL	CFIN			; shell finale.

	CALL	I21HRST			; 割込み元に戻す
	RET
PSMAIN	ENDP


; *********************************************************
;	shell init.
; *********************************************************

CINIT	PROC	NEAR
	MOV	SI,OFFSET MES_WELCOME
	CALL	PRINT
	RET
CINIT	ENDP


; *********************************************************
;	console input.
;	-O- DS:SI :string address.
; *********************************************************

CINP	PROC	NEAR
	CALL	CLR_CLINE
	MOV	SI,OFFSET MES_PROMPT
	CALL	PRINT
	CALL	INPUT
	PUSH	SI
	MOV	SI,OFFSET MES_CRLF
	CALL	PRINT
	POP	SI
	RET
CINP	ENDP


; *********************************************************
;	check.
;	-I- DS:SI : string address.
;	-O- CLINE : command line.
;	    NONE  : 1=none, 0=normal.
; *********************************************************

CCHECK	PROC	NEAR
	CALL	CNTL_SPACE		; control code -> space.
	CALL	COLUM_SET		; string colum set.
	MOV	DI,OFFSET CLINE		;
	CALL	STRING_COPY		;
	CMP	CLINE,EOS		; none string ?
	JE	CCHECK_NONE		;
	CALL	COLUM_ESE		; special command colum.
	MOV	NONE,0			; normal.
	RET
CCHECK_NONE:
	MOV	NONE,1			; none!
	RET
CCHECK	ENDP


; *********************************************************
;	comp.
;	-I-   CLINE       : command line.
;	-O-   COMMAND_NUM : command number.
;	      NOT_FOUND   : 0=normal, 1=not found.
; *********************************************************

CCMP	PROC	NEAR
	MOV	COMMAND_NUM,0		; command number.
CCMP_LOOP:
	MOV	BX,COMMAND_NUM		;
	CMP	BX,COMMAND_MAX		; command max.
	JE	CCMP_NOT_FOUND		;

	SHL	BX,1			;
	MOV	DI,OFFSET CLINE		; command line.
	MOV	SI,DS:COMMAND_TABLE[BX]	; token table.
	ADD	SI,2			; skip address.

	CALL	TOKEN_COMP		; token comp.
	CMP	AX,1			; 1=same
	JE	CCMP_FIND		;

	INC	COMMAND_NUM		;
	JMP	CCMP_LOOP		;

CCMP_FIND:
	MOV	NOT_FOUND,0		; normal.
	RET
CCMP_NOT_FOUND:
	MOV	NOT_FOUND,1		; not found.
	RET
CCMP	ENDP


; *********************************************************
;	EXE process.
;	-I- CLINE     : コマンドライン
; *********************************************************

CPROCESS	PROC	NEAR
	CALL	CMFREE			; フリーエリアの開始位置

	PUSH	ES			;
	MOV	SI,OFFSET CLINE		; コマンドライン
	CALL	CMLCOM			; ＬＯＡＤ／ＣＯＭファイル
	POP	ES			;
	CMP	AX,0			; 0=正常, 1=ファイル無し, 2=エラー
	JE	CPROCESS_COM		;

	PUSH	ES			;
	MOV	SI,OFFSET CLINE		; コマンドライン
	CALL	CMLEXE			; ＬＯＡＤ／ＥＸＥファイル
	POP	ES			;
	CMP	AX,0			; 0=正常, 1=ファイル無し, 2=エラー
	JE	CPROCESS_EXE		;

	JMP	CPROCESS_EXIT		;

CPROCESS_COM:
	CALL	CMPCOM			; 標準ＣＯＭプロセス
	JMP	CPROCESS_EXIT		;

CPROCESS_EXE:
	CALL	CMPROC			; 標準ＤＯＳプロセス

CPROCESS_EXIT:
	RET
CPROCESS	ENDP


; *********************************************************
;	command processer.
;	-I-   COMMAND_NUM : command number.
;	      CLINE       : command line.
;	      CTOKEN[]    : token address table.
;	      TOKEN_CNT   : token count.
;	-O-   EXIT        : 1=exit, 0=normal.
; *********************************************************

CCOMMAND	PROC	NEAR
	MOV	BX,COMMAND_NUM
	CMP	BX,COMMAND_MAX
	JL	CCOMMAND_JUMP
	RET

CCOMMAND_JUMP:
	SHL	BX,1			; word pointer.
	MOV	DI,DS:COMMAND_TABLE[BX]	;
	MOV	SI,CTOKEN[2]		; token address table.
	MOV	BX,CTOKEN[4]		; token address table.
	CALL	WORD PTR DS:[DI]	;
	RET
CCOMMAND	ENDP


; *********************************************************
;	exit shell.
; *********************************************************

CM_EXIT	PROC	NEAR
	MOV	EXIT,1			; exit.
	RET
CM_EXIT	ENDP


; *********************************************************
;	drive number(1-4)
; *********************************************************

CM_DNO	PROC	NEAR
	MOV	SI,CTOKEN[2]		; token address table.
	CALL	STRDEC			; dec string to DX reg.
	CMP	DX,0			;
	JE	CM_DNO_EXIT		;
	CMP	DX,5			;
	JNB	CM_DNO_EXIT		;

	CALL	SETUNIT			; unit name set.
	CMP	AX,2			; disk error.
	JNE	CM_DNO_EXIT		;

	MOV	SI,OFFSET MES_NOT_DIR	;
	CALL	PRINT			; print.
CM_DNO_EXIT:
	RET
CM_DNO	ENDP


; *********************************************************
;	free area.
; *********************************************************

CM_FREE	PROC	NEAR
	CALL	CMFREE			; フリーエリアの開始位置
	MOV	SI,OFFSET MSG_FREE	;
	CALL	PRINT			;
	MOV	DX,ES			; フリーエリアの開始パラグラフ値
	CALL	HEXSTR			;
	CALL	PRINT			;
	MOV	SI,OFFSET MSG_SEGUNIT	;
	CALL	PRINT			;
	CALL	LFPRN			; line feed.
	RET
CM_FREE	ENDP



; *********************************************************
;	shell finale.
; *********************************************************

CFIN	PROC	NEAR
	MOV	SI,OFFSET MES_BYE
	CALL	PRINT
	RET
CFIN	ENDP


; *********************************************************
;	string calum set.
;	-I- DS:SI  : string address.
; *********************************************************

COLUM_SET	PROC	NEAR
	PUSH	SI

	MOV	AX,DS
	MOV	ES,AX

	MOV	DI,SI
	MOV	BX,SI
COLUM_SET2:
	LODSB				; 1 char get.
	CMP	AL,EOS
	JE	COLUM_SET9

	CMP	AL,CHR_SPACE
	JNE	COLUM_SET5
COLUM_SET3:
	LODSB				; 1 char get.
	CMP	AL,EOS
	JE	COLUM_SET9
	CMP	AL,CHR_SPACE
	JE	COLUM_SET3

	CMP	DI,BX			; command line top?
	JE	COLUM_SET5		;
	MOV	BYTE PTR DS:[DI],CHR_SPACE
	INC	DI
COLUM_SET5:
	STOSB				; 1 char put.
	JMP	COLUM_SET2
COLUM_SET9:
;;;;	MOV	BYTE PTR DS:[DI],CHR_CR	; calig return.
	MOV	BYTE PTR DS:[DI],EOS	; end of string.
	POP	SI
	RET
COLUM_SET	ENDP


; *********************************************************
;	token get address.
;	-I- CLINE     : string address.
;	-O- CTOKEN    : token address table.
;	    TOKEN_CNT : token count.
; *********************************************************

TOKADR	PROC	NEAR
	MOV	BX,0			;
	MOV	CX,TOKEN_MAX		; token max.
TOKADR_1:				;
	MOV	DS:CTOKEN[BX],OFFSET CLINE_END ; token address table.
	INC	BX			;
	INC	BX			;
	LOOP	TOKADR_1		;

	MOV	TOKEN_CNT,0		; token count.
	MOV	SI,OFFSET CLINE		; string address.
TOKADR_LOOP:
	CMP	TOKEN_CNT,TOKEN_MAX	; token max.
	JNB	TOKADR_EXIT		; max token!

TOKADR_LOOP2:
	LODSB				; 1 character get.
	CMP	AL,EOS			;
	JE	TOKADR_EXIT		; check EOS.
	CMP	AL,CHR_SPACE		; space.
	JE	TOKADR_LOOP2		;

	DEC	SI			;
	MOV	BX,TOKEN_CNT		; token count.
	SHL	BX,1			; word pointer.
	MOV	DS:CTOKEN[BX],SI	; token address table.
	INC	SI			;
	INC	TOKEN_CNT		; token count.

TOKADR_LOOP3:
	LODSB				; 1 character get.
	CMP	AL,EOS			;
	JE	TOKADR_EXIT		; check EOS.
	CMP	AL,CHR_SPACE		; space.
	JNE	TOKADR_LOOP3		;

	JMP	TOKADR_LOOP		;
TOKADR_EXIT:
	RET
TOKADR	ENDP


; *********************************************************
;	space cut.
;	-I/O- CLINE : string address.
; *********************************************************

SPACE_CUT	PROC	NEAR
	MOV	SI,OFFSET CLINE		; string address.
	MOV	CX,STRING_LEN		; string buffer length.
SPACE_CUT_LOOP:
	CMP	DS:[SI],BYTE PTR CHR_SPACE ; space.
	JNE	SPACE_CUT_NEXT		;
	MOV	DS:[SI],BYTE PTR EOS	; EOS.
SPACE_CUT_NEXT:
	INC	SI			;
	LOOP	SPACE_CUT_LOOP		;
	RET
SPACE_CUT	ENDP


; *********************************************************
;	special command colum.
;	-I- CLINE  : string address.
; *********************************************************

COLUM_ESE	PROC	NEAR
	PUSH	SI

	MOV	SI,OFFSET CLINE		; command line.
	MOV	AL,DS:[SI]
	CMP	AL,'='
	JE	COLUM_ESE_1CHR
	CMP	AL,'?'
	JE	COLUM_ESE_1CHR
	JMP	COLUM_ESE9

COLUM_ESE_1CHR:
	MOV	AX,DS			;
	MOV	ES,AX			;
	MOV	DI,OFFSET CLINE		; command line.
	ADD	DI,STRING_LEN-2		; string buffer length - 2
	MOV	SI,DI			;
	DEC	SI			;
	MOV	CX,STRING_LEN-3		;
	STD				; dec pointer.
	REP	MOVSB			;
	CLD				; inc pointer.
	INC	SI
	MOV	BYTE PTR DS:[SI],CHR_SPACE
	DEC	SI
	CALL	PRINT
COLUM_ESE9:
	POP	SI
	RET
COLUM_ESE	ENDP


; *********************************************************
;	control code -> space.
;	-I- DS:SI : string address.
; *********************************************************

CNTL_SPACE	PROC	NEAR
	PUSH	SI
CNTL_SPACE1:
	MOV	AL,BYTE PTR DS:[SI]	; 1 char get.
	CMP	AL,EOS
	JE	CNTL_SPACE_EXIT

	CMP	AL,CHR_SPACE
	JNB	CNTL_SPACE2
	MOV	BYTE PTR DS:[SI],CHR_SPACE	; cntl -> space.
CNTL_SPACE2:
	INC	SI
	JMP	CNTL_SPACE1

CNTL_SPACE_EXIT:
	POP	SI
	RET
CNTL_SPACE	ENDP


; *********************************************************
;	string copy.( max : STRING_LEN )
;	-I- DS:SI : source index.
;	    DS:DI : dest index.
; *********************************************************

STRING_COPY	PROC	NEAR
	PUSH	SI
	PUSH	DI

	MOV	AX,DS
	MOV	ES,AX
	MOV	CX,0
STRING_COPY2:
	INC	CX
	CMP	CX,STRING_LEN		; string buffer length.
	JGE	STRING_COPY9
	LODSB
	CMP	AL,EOS
	JE	STRING_COPY9
	STOSB
	JMP	STRING_COPY2
STRING_COPY9:
	MOV	BYTE PTR ES:[DI],EOS	; end of string.
	POP	DI
	POP	SI
	RET
STRING_COPY	ENDP


; *********************************************************
;	token comp.
;	-I- DS:SI : token 1.
;	    DS:DI : token 2.
;	-O- AX    : 1=same, 0=not equl.
; *********************************************************

TOKEN_COMP	PROC	NEAR
	PUSH	SI
	PUSH	DI
TOKEN_COMP2:
	MOV	AL,DS:[SI]
	CMP	AL,EOS
	JE	TOKEN_COMP4
	CMP	AL,CHR_SPACE
	JE	TOKEN_COMP4

	CMP	AL,DS:[DI]
	JNE	TOKEN_COMP_NOT
	INC	SI
	INC	DI
	JMP	TOKEN_COMP2

TOKEN_COMP4:
	MOV	AL,DS:[DI]
	CMP	AL,EOS
	JE	TOKEN_COMP_OK
	CMP	AL,CHR_SPACE
	JE	TOKEN_COMP_OK

TOKEN_COMP_NOT:
	MOV	AX,0			; not equl.
	JMP	TOKEN_COMP9		;
TOKEN_COMP_OK:
	MOV	AX,1			; same.
TOKEN_COMP9:
	POP	DI
	POP	SI
	RET
TOKEN_COMP	ENDP


; *********************************************************
;	command line clear.
;	-I/O- CLINE : command line.
; *********************************************************

CLR_CLINE 	PROC	NEAR
	MOV	AX,DS
	MOV	ES,AX
	MOV	AL,0
	MOV	DI,OFFSET CLINE		; command line.
	MOV	CX,STRING_LEN		; command line length.
	REP	STOSB
	RET
CLR_CLINE 	ENDP


; *********************************************************
;	help.
; *********************************************************

HELPDSP	PROC	NEAR
	MOV	BX,0
	MOV	CX,COMMAND_MAX
	MOV	NUM,0
HELPDSP2:
	MOV	SI,DS:COMMAND_TABLE[BX]	; token table.
	ADD	SI,2			; skip address.
	CALL	PRINT
	MOV	SI,OFFSET MES_CRLF
	CALL	PRINT
	INC	BX
	INC	BX
	INC	NUM
	CMP	NUM,20
	JL	HELPDSP6
	MOV	SI,OFFSET MES_WAIT
	CALL	PRINT
	CALL	INPUT
	CALL	LFPRN			; line feed.
	MOV	NUM,0
HELPDSP6:
	LOOP	HELPDSP2

	RET
HELPDSP	ENDP


; *********************************************************
;	autoexec
; *********************************************************

AUTOEXEC	PROC	NEAR

	MOV	CLINE[0],'D'			; コマンドライン
	MOV	CLINE[1],'R'			; コマンドライン
	MOV	CLINE[2],'V'			; コマンドライン
	MOV	CLINE[3],'K'			; コマンドライン
	MOV	CLINE[4],'A'			; コマンドライン
	MOV	CLINE[5],'N'			; コマンドライン
	MOV	CLINE[6],'J'			; コマンドライン
	MOV	CLINE[7],'I'			; コマンドライン
	MOV	CLINE[8],' '			; コマンドライン
	MOV	CLINE[9],'S'			; コマンドライン
	MOV	CLINE[10],'E'			; コマンドライン
	MOV	CLINE[11],'T'			; コマンドライン
	MOV	CLINE[12],0			; コマンドライン
	CALL	CPROCESS			; EXE process.

	MOV	CLINE[0],'A'			; コマンドライン
	MOV	CLINE[1],'U'			; コマンドライン
	MOV	CLINE[2],'T'			; コマンドライン
	MOV	CLINE[3],'O'			; コマンドライン
	MOV	CLINE[4],'E'			; コマンドライン
	MOV	CLINE[5],'X'			; コマンドライン
	MOV	CLINE[6],'E'			; コマンドライン
	MOV	CLINE[7],'C'			; コマンドライン
	MOV	CLINE[8],0			; コマンドライン
	CALL	CPROCESS			; EXE process.
	RET
AUTOEXEC	ENDP



; *********************************************************
;	unit name set.
;	-I- DX : 1=1MFD#0,2=1MFD#1,3=1MFD#2,4=1MFD#3
;	-O- MES_PROMPT : prompt meggage.
;	    AX : 0=正常, 2=ディスクエラー
; *********************************************************


SETUNIT	PROC	NEAR
	PUSH	SI
	PUSH	DX

	CALL	HEXSTR			; val DX to hex string.
	MOV	AL,BYTE PTR DS:[SI][3]	;
	MOV	BYTE PTR MES_PROMPT[1],AL

	DEC	DX			;
	CALL	I21HDRV			; デフォルトドライブ番号
	MOV	AX,DX			; １ＭＦＤドライブ番号
	CALL	FFDRV			; カレントドライブ設定

	POP	DX
	POP	SI
	RET
SETUNIT	ENDP


; *********************************************************
;	address string -> ES:DI
;	-I- DS:SI  : address string.     XXXXX
;	-O- ES     : segment address.
;	    DI     : offset address.
; *********************************************************

STRADRS	PROC	NEAR
	PUSH	SI

	MOV	HEXADRS,SI		; hex buffer address.

	CMP	BYTE PTR DS:[SI][4],'0'	;
	JL	STRADRS3

	MOV	AL,DS:[SI]		;
	MOV	HEXBUF,AL		;
	MOV	SI,OFFSET HEXBUF	;
	CALL	STRHEX			; offset=DX
	MOV	ES,DX			; segment=ES

	MOV	SI,HEXADRS		; hex buffer address.
	ADD	SI,1			;
	CALL	STRHEX			; offset=DI
	MOV	DI,DX			;

	JMP	STRADRS4
STRADRS3:
	CALL	STRHEX			; offset=DX
	MOV	DI,DX			;
	MOV	AX,0			;
	MOV	ES,AX			; segment=0
STRADRS4:
	POP	SI
	RET
STRADRS	ENDP


CODE	ENDS



DATA	SEGMENT	PUBLIC	'DATA'

CLINE 		DB	STRING_LEN DUP (0)	; （先頭１バイトは文字列長さ）
CLINE_END	DB	EOS,EOS			;

TOKEN_CNT	DW	0			; token count.
CTOKEN		DW	TOKEN_MAX DUP (0)	; token address table.

		EVEN
COMMAND_NUM	DW	0			; command number.
COMMAND_MAX	DW	17			; command max.
COMMAND_TABLE	LABEL	WORD
	DW	LL00,LL01,LL02,LL03,LL04,LL05,LL06,LL07,LL08,LL09
	DW	LL10,LL11,LL12,LL13,LL14,LL15,LL16
;		torkn, help message
LL00	DW	OFFSET CMDIR
	DB	"DIR   directory list."					,EOS
;*;	DB	"DIR   ＤＩＲ"						,EOS
LL01	DW	OFFSET CMFAT
	DB	"FAT   FAT dump."					,EOS
;*;	DB	"FAT   ＦＡＴダンプ"					,EOS
LL02	DW	OFFSET CMTYPE
	DB	"TYPE  <filename> show text file."			,EOS
;*;	DB	"TYPE  <filename> テキストファイルの表示"		,EOS
LL03	DW	OFFSET CLS
	DB	"CLS   clear screen."					,EOS
;*;	DB	"CLS   クリア"						,EOS
LL04	DW	OFFSET CM_DNO
	DB	"DNO   <drive number> change current drive.(1-4)"	,EOS
;*;	DB	"DNO   <drive number> カレントドライブの変更（１－４）"	,EOS
LL05	DW	OFFSET CM_EXIT
	DB	"EXIT  shell exit."					,EOS
;*;	DB	"EXIT  シェルの終了"					,EOS
LL06	DW	OFFSET HELPDSP
	DB	"HELP  help list."					,EOS
;*;	DB	"HELP  ＨＥＬＰ"					,EOS
LL07	DW	OFFSET CM_FREE
	DB	"FREE  free area address."				,EOS
;*;	DB	"FREE  フリーエリアの開始位置"				,EOS
LL08	DW	OFFSET CMDBIO
	DB	"BIOS  BIOS debug."					,EOS
;*;	DB	"BIOS  バイオスデバック"				,EOS
LL09	DW	OFFSET CMDMPT
	DB	"MPT   MPT table debug."				,EOS
;*;	DB	"MPT   ＭＰＴテーブルデバック"				,EOS
LL10	DW	OFFSET CMDDMD
	DB	"DMD   drive mode."					,EOS
;*;	DB	"DMD   ドライブモード"					,EOS
LL11	DW	OFFSET CMDFDS
	DB	"FDS   FD drive parameters."				,EOS
;*;	DB	"FDS   ＦＤドライブ情報"				,EOS
LL12	DW	OFFSET CMDVTEST
	DB	"VTS   VIDEO test.(danger)"				,EOS
;*;	DB	"VTS   VIDEO test.(危険)"				,EOS
LL13	DW	OFFSET CMKILL
	DB	"KILL  <filename> file delete."				,EOS
;*;	DB	"KILL  <filename> ＫＩＬＬ"				,EOS
LL14	DW	OFFSET CMFFIL
	DB	"FFIL  <filename> make of white file."			,EOS
;*;	DB	"FFIL  <filename> 真っ白のファイルを作る"		,EOS
LL15	DW	OFFSET CMCOPY
	DB	"COPY  <file1> <file2> copy"				,EOS
;*;	DB	"COPY  <file1> <file2> ＣＯＰＹ"			,EOS
LL16	DW	OFFSET CMDIMAGE		; image test.
	DB	"IMG   image test."					,EOS
;*;	DB	"IMG   image test."					,EOS

MES_PROMPT	DB	"[ ]",EOS
MES_CRLF	DB	CHR_CR,CHR_LF,EOS
MES_WELCOME	DB	"wellcame to PSHELL world !",CHR_CR,CHR_LF
		DB	"PLEASE [CAPS LOCK] ON",CHR_CR,CHR_LF,EOS
MES_BYE		DB	"bye.",CHR_CR,CHR_LF,EOS
MES_NOT_DIR	DB	"unload directory.",CHR_CR,CHR_LF,EOS
MES_WAIT	DB	"　next page",EOS
MSG_FREE	DB	"free area start address=",EOS
MSG_SEGUNIT	DB	"0h",EOS

;*;MES_WELCOME	DB	"ようこそピーシェルの世界へ",CHR_CR,CHR_LF
;*;		DB	"大文字と小文字の区別があります。"
;*;		DB	"ＣＡＰＳロックを忘れないように・・",CHR_CR,CHR_LF,EOS
;*;MES_BYE		DB	"さようなら・・・",CHR_CR,CHR_LF,EOS
;*;MES_NOT_DIR	DB	"ディレクトリィがロード出来ない",CHR_CR,CHR_LF,EOS
;*;MES_WAIT	DB	"　次ページ",EOS
;*;MSG_FREE	DB	"フリーエリアの先頭=",EOS
;*;MSG_SEGUNIT	DB	"0h",EOS

		EVEN
HEXBUF		DB	"0000",0,0	; hex conv buffer.
HEXADRS		DW	0		; hex buffer address.

NONE		DW	0		; 1=none
EXIT		DW	0		; 1=exit?
NOT_FOUND	DW	0		; 1=not found.

NUM		DW	0		; 通し番号

DATA	ENDS

	END
;
;	end of "PSMAIN.ASM"
;

