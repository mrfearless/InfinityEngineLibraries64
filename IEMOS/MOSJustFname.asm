.686
.MMX
.XMM
.x64

option casemap : none
option win64 : 11
option frame : auto
option stackbase : rsp

_WIN64 EQU 1
WINVER equ 0501h

include windows.inc
includelib user32.lib

include IEMOS.inc

MOSJustFname            PROTO :QWORD, :QWORD


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; Strip path name to just filename Without extention
;------------------------------------------------------------------------------
MOSJustFname PROC FRAME USES RSI RDI FilePathName:QWORD, FileName:QWORD
	LOCAL LenFilePathName:QWORD
	LOCAL nPosition:QWORD
	
	Invoke lstrlen, FilePathName
	mov LenFilePathName, rax
	mov nPosition, rax
	
	.IF LenFilePathName == 0
	    mov rdi, FileName
		mov byte ptr [rdi], 0
		mov rax, FALSE
		ret
	.ENDIF
	
	mov rsi, FilePathName
	add rsi, rax
	
	mov rax, nPosition
	.WHILE rax != 0
		movzx rax, byte ptr [rsi]
		.IF al == '\' || al == ':' || al == '/'
			inc rsi
			.BREAK
		.ENDIF
		dec rsi
		dec nPosition
		mov rax, nPosition
	.ENDW
	mov rdi, FileName
	mov rax, nPosition
	.WHILE rax != LenFilePathName
		movzx rax, byte ptr [rsi]
		.IF al == '.' ; stop here
		    .BREAK
		.ENDIF
		mov byte ptr [rdi], al
		inc rdi
		inc rsi
		inc nPosition
		mov rax, nPosition
	.ENDW
	mov byte ptr [rdi], 0h
	mov rax, TRUE
	ret
MOSJustFname ENDP



END

