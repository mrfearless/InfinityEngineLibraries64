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

include IEMOS.inc


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTotalBlockEntries - Returns in rax the total no of data block entries
;------------------------------------------------------------------------------
IEMOSTotalBlockEntries PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, 0
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rbx, [rbx].MOSINFO.MOSHeaderPtr
    mov eax, dword ptr [rbx].MOSV2_HEADER.BlockEntriesCount
    ret
IEMOSTotalBlockEntries ENDP



IEMOS_LIBEND

