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
; IEBAMBlockEntries - Returns in rax a pointer to data block entries or NULL if not valid
;------------------------------------------------------------------------------
IEBAMBlockEntries PROC FRAME USES RBX hIEBAM:QWORD
    .IF hIEBAM == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMBlockEntriesPtr
    ret
IEBAMBlockEntries ENDP



IEBAM_LIBEND

