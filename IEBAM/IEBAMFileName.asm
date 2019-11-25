;==============================================================================
;
; IEBAM x64 Library
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

include IEBAM.inc


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFileName - returns in rax pointer to zero terminated string contained filename that is open or NULL if not opened
;------------------------------------------------------------------------------
IEBAMFileName PROC FRAME USES RBX hIEBAM:QWORD
    LOCAL BamFilename:QWORD
    .IF hIEBAM == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEBAM
    lea rax, [rbx].BAMINFO.BAMFilename
    mov BamFilename, rax
    Invoke lstrlen, BamFilename
    ;Invoke szLen, BamFilename
    .IF rax == 0
        mov rax, NULL
    .ELSE
        mov rax, BamFilename
    .ENDIF
    ret
IEBAMFileName ENDP



IEBAM_LIBEND

