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

include IEBAM.inc


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMTotalBlockEntries - Returns in rax the total no of data block entries
;------------------------------------------------------------------------------
IEBAMTotalBlockEntries PROC FRAME USES RBX hIEBAM:QWORD
    .IF hIEBAM == NULL
        mov rax, 0
        ret
    .ENDIF
    mov rbx, hIEBAM
    mov rbx, [rbx].BAMINFO.BAMHeaderPtr
    .IF rbx != NULL
        mov eax, dword ptr [rbx].BAMV2_HEADER.BlockEntriesCount
    .ELSE
        mov rax, 0
    .ENDIF
    ret
IEBAMTotalBlockEntries ENDP



IEBAM_LIBEND

