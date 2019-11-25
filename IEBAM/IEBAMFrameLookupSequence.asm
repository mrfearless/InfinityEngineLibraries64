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

EXTERNDEF IEBAMFrameLookupEntry     :PROTO hIEBAM:QWORD, nCycle:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns frame no for particular cycle and index into sequence or -1
;------------------------------------------------------------------------------
IEBAMFrameLookupSequence PROC FRAME USES RBX hIEBAM:QWORD, nCycle:QWORD, CycleIndex:QWORD
    LOCAL FrameLookupOffset:QWORD
    LOCAL SequenceSize:QWORD
    LOCAL SequenceData:QWORD
    LOCAL Index:QWORD
    
    .IF hIEBAM == NULL
        mov rax, -1
        ret
    .ENDIF
    
    Invoke IEBAMFrameLookupEntry, hIEBAM, nCycle
    .IF rax == -1
        ret
    .ENDIF
    mov FrameLookupOffset, rax
    
    mov rbx, FrameLookupOffset
    mov rax, [rbx].FRAMELOOKUPTABLE.SequenceSize
    mov SequenceSize, rax
    mov rax, [rbx].FRAMELOOKUPTABLE.SequenceData
    mov SequenceData, rax
    
    .IF SequenceSize > 0
        
        mov rax, CycleIndex
        shl rax, 1 ; x2
        mov Index, rax
    
        .IF rax >= SequenceSize
            mov rax, -1
            ret
        .ENDIF
        
        .IF SequenceData != NULL
            mov rbx, SequenceData
            add rbx, Index ; for qword array 
            movzx rax, word ptr [rbx]
        .ELSE
            mov rax, -1
        .ENDIF
    .ELSE
        mov rax, -1
    .ENDIF    
    ret
IEBAMFrameLookupSequence ENDP



IEBAM_LIBEND

