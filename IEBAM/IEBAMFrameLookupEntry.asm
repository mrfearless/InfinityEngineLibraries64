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

EXTERNDEF IEBAMTotalCycleEntries    :PROTO hIEBAM:QWORD
EXTERNDEF IEBAMFrameLookupEntries   :PROTO hIEBAM:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFrameLookupEntry - Returns in rax a pointer to the frame lookup NULL if not valid
;------------------------------------------------------------------------------
IEBAMFrameLookupEntry PROC FRAME USES RBX hIEBAM:QWORD, nCycle:QWORD
    LOCAL FrameLookupEntries:QWORD
    LOCAL TotalCycleEntries:QWORD
    
    .IF hIEBAM == NULL
        mov rax, NULL
        ret
    .ENDIF

    Invoke IEBAMTotalCycleEntries, hIEBAM
    .IF rax == 0
        mov rax, NULL
        ret
    .ENDIF   
    mov TotalCycleEntries, rax
   
    Invoke IEBAMFrameLookupEntries, hIEBAM
    .IF rax == NULL
        ret
    .ENDIF
    mov FrameLookupEntries, rax  

    mov rax, nCycle
    mov rbx, SIZEOF FRAMELOOKUPTABLE
    mul rbx
    add rax, FrameLookupEntries
    ret
IEBAMFrameLookupEntry ENDP



IEBAM_LIBEND

