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

EXTERNDEF IEBAMTotalCycleEntries    :PROTO hIEBAM:QWORD
EXTERNDEF IEBAMCycleEntries         :PROTO hIEBAM:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMCycleEntry - Returns in rax a pointer to the specified cycle entry or NULL 
;------------------------------------------------------------------------------
IEBAMCycleEntry PROC FRAME USES RBX hIEBAM:QWORD, nCycleEntry:QWORD
    LOCAL TotalCycleEntries:QWORD
    LOCAL CycleEntriesPtr:QWORD
    
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

    .IF nCycleEntry >= rax
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMCycleEntries, hIEBAM
    .IF rax == NULL
        ret
    .ENDIF    
    mov CycleEntriesPtr, rax
    
    mov rax, nCycleEntry
    mov rbx, SIZEOF CYCLEV1_ENTRY
    mul rbx
    add rax, CycleEntriesPtr
    ret
IEBAMCycleEntry ENDP



IEBAM_LIBEND

