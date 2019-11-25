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

EXTERNDEF IEBAMTotalBlockEntries    :PROTO hIEBAM:QWORD
EXTERNDEF IEBAMBlockEntries         :PROTO hIEBAM:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMBlockEntry - Returns in rax a pointer to the specified Datablock entry or NULL 
;------------------------------------------------------------------------------
IEBAMBlockEntry PROC FRAME USES RBX hIEBAM:QWORD, nBlockEntry:QWORD
    LOCAL TotalBlockEntries:QWORD
    LOCAL BlockEntriesPtr:QWORD
    
    .IF hIEBAM == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMTotalBlockEntries, hIEBAM
    .IF rax == 0
        mov rax, NULL
        ret
    .ENDIF    
    mov TotalBlockEntries, rax
    
    .IF nBlockEntry >= rax
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMBlockEntries, hIEBAM
    .IF rax == NULL
        ret
    .ENDIF    
    mov BlockEntriesPtr, rax    
    
    mov rax, nBlockEntry
    mov rbx, SIZEOF DATABLOCK_ENTRY
    mul rbx
    add rax, BlockEntriesPtr
    ret
IEBAMBlockEntry ENDP



IEBAM_LIBEND

