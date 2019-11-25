;==============================================================================
;
; IEMOS Library
;
; Copyright (c) 2019 by fearless
;
; http://github.com/mrfearless/InfinityEngineLibraries64
;
;==============================================================================
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
includelib kernel32.lib

include IEMOS.inc


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileName - returns in rax pointer to zero terminated string contained 
; filename that is open or NULL if not opened
;------------------------------------------------------------------------------
IEMOSFileName PROC FRAME USES RBX hIEMOS:QWORD
    LOCAL MosFilename:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    lea rax, [rbx].MOSINFO.MOSFilename
    mov MosFilename, rax
    Invoke lstrlen, MosFilename
    ;Invoke szLen, MosFilename
    .IF rax == 0
        mov rax, NULL
    .ELSE
        mov rax, MosFilename
    .ENDIF
    ret
IEMOSFileName ENDP



IEMOS_LIBEND

