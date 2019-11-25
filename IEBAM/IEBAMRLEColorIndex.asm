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

EXTERNDEF IEBAMHeader               :PROTO hIEBAM:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in eax the RLEColorIndex
;------------------------------------------------------------------------------
IEBAMRLEColorIndex PROC FRAME USES RBX hIEBAM:QWORD
    LOCAL BamHeaderPtr:QWORD
    LOCAL RLEColorIndex:QWORD
    LOCAL ABGR:DWORD
    
    .IF hIEBAM == NULL
        mov rax, -1
        ret
    .ENDIF
    
    Invoke IEBAMHeader, hIEBAM
    .IF rax == NULL
        mov rax, -1
        ret
    .ENDIF
    mov BamHeaderPtr, rax
    mov rbx, BamHeaderPtr
    movzx rax, byte ptr [rbx].BAMV1_HEADER.ColorIndexRLE
    
    ret
IEBAMRLEColorIndex ENDP



IEBAM_LIBEND

