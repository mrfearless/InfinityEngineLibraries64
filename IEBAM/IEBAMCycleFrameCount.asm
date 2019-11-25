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

include IEBAM.inc

EXTERNDEF IEBAMCycleEntry   :PROTO hIEBAM:QWORD, nCycleEntry:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns count of frames in particular cycle or 0
;------------------------------------------------------------------------------
IEBAMCycleFrameCount PROC FRAME USES RBX hIEBAM:QWORD, nCycle:QWORD
    .IF hIEBAM == NULL
        mov rax, 0
        ret
    .ENDIF
    
    Invoke IEBAMCycleEntry, hIEBAM, nCycle
    .IF rax == 0
        ret
    .ENDIF
    mov rbx, rax
    movzx rax, word ptr [rbx].CYCLEV1_ENTRY.CycleFrameCount
    ret
IEBAMCycleFrameCount ENDP



IEBAM_LIBEND

