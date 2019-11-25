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

EXTERNDEF IEBAMFrameEntry   :PROTO hIEBAM:QWORD, nFrameEntry:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in rax TRUE if sucessful or FALSE otherwise. On return lpqwFrameHeight and 
; lpqwFrameWidth will contain the values
;------------------------------------------------------------------------------
IEBAMFrameDimensions PROC FRAME USES RBX hIEBAM:QWORD, nFrame:QWORD, lpqwFrameWidth:QWORD, lpqwFrameHeight:QWORD
    LOCAL FrameEntryOffset:QWORD
    LOCAL FrameWidth:QWORD
    LOCAL FrameHeight:QWORD
    
    .IF hIEBAM == NULL
        mov rax, FALSE
        ret
    .ENDIF

    Invoke IEBAMFrameEntry, hIEBAM, nFrame
    .IF rax == NULL
        mov rax, FALSE
        ret
    .ENDIF
    mov FrameEntryOffset, rax
    mov rbx, FrameEntryOffset
    
    movzx rax, word ptr [rbx].FRAMEV1_ENTRY.FrameWidth
    mov FrameWidth, rax
    movzx rax, word ptr [rbx].FRAMEV1_ENTRY.FrameHeight
    mov FrameHeight, rax
    
    .IF lpqwFrameWidth != NULL
        mov rbx, lpqwFrameWidth
        mov rax, FrameWidth
        mov [rbx], rax
    .ENDIF
    .IF lpqwFrameHeight != NULL
        mov rbx, lpqwFrameHeight
        mov rax, FrameHeight
        mov [rbx], rax
    .ENDIF
    
    mov rax, TRUE
    ret
IEBAMFrameDimensions ENDP



IEBAM_LIBEND

