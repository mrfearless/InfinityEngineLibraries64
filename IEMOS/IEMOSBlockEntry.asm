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

EXTERNDEF IEMOSTotalBlockEntries    :PROTO hIEMOS:QWORD
EXTERNDEF IEMOSBlockEntries         :PROTO hIEMOS:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSBlockEntry - Returns in rax a pointer to the specified Datablock entry 
; or NULL
;------------------------------------------------------------------------------
IEMOSBlockEntry PROC FRAME USES RBX hIEMOS:QWORD, nBlockEntry:QWORD
    LOCAL BlockEntriesPtr:QWORD
    
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEMOSTotalBlockEntries, hIEMOS
    .IF rax == 0
        mov rax, NULL
        ret
    .ENDIF
    ; rax contains TotalBlockEntries
     .IF nBlockEntry >= rax
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEMOSBlockEntries, hIEMOS
    .IF rax == NULL
        ret
    .ENDIF
    mov BlockEntriesPtr, rax
    
    mov rax, nBlockEntry
    mov rbx, SIZEOF DATABLOCK_ENTRY
    mul rbx
    add rax, BlockEntriesPtr
    ret
IEMOSBlockEntry ENDP



IEMOS_LIBEND

