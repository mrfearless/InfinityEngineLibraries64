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

EXTERNDEF IEBAMFrameDataEntries     :PROTO hIEBAM:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFrameDataEntry - returns in rax pointer to frame data or NULL if not found
;------------------------------------------------------------------------------
IEBAMFrameDataEntry PROC FRAME USES RBX hIEBAM:QWORD, nFrameEntry:QWORD
    LOCAL FrameDataEntriesPtr:QWORD
    .IF hIEBAM == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMFrameDataEntries, hIEBAM
    .IF rax == NULL
        ret
    .ENDIF
    mov FrameDataEntriesPtr, rax
    
    mov rax, nFrameEntry
    mov rbx, SIZEOF FRAMEDATA
    mul rbx
    add rax, FrameDataEntriesPtr
    ret
IEBAMFrameDataEntry ENDP



IEBAM_LIBEND

