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

EXTERNDEF IEBAMTotalFrameEntries    :PROTO hIEBAM:QWORD
EXTERNDEF IEBAMFrameEntries         :PROTO hIEBAM:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Find the max width and height for all frames stored in bam. TRUE success, FALSE failure
;------------------------------------------------------------------------------
IEBAMFindMaxWidthHeight PROC FRAME USES RBX hIEBAM:QWORD, lpqwMaxWidth:QWORD, lpqwMaxHeight:QWORD
    LOCAL FrameEntries:QWORD
    LOCAL FrameEntryOffset:QWORD
    LOCAL MaxWidth:QWORD
    LOCAL MaxHeight:QWORD
    LOCAL nFrame:QWORD
    LOCAL TotalFrameEntries:QWORD
    
    .IF hIEBAM == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    .IF rax == NULL
        mov rax, FALSE
        ret
    .ENDIF
    mov TotalFrameEntries, rax
    
    Invoke IEBAMFrameEntries, hIEBAM
    .IF rax == NULL
        mov rax, FALSE
        ret
    .ENDIF
    mov FrameEntries, rax
    mov FrameEntryOffset, rax

    mov MaxWidth, 0
    mov MaxHeight, 0
    mov nFrame, 0

    mov rax, 0
    .WHILE rax < TotalFrameEntries
        mov rbx, FrameEntryOffset
        
        movzx rax, word ptr [rbx].FRAMEV1_ENTRY.FrameWidth
        .IF rax > MaxWidth
            mov MaxWidth, rax
        .ENDIF
        movzx rax, word ptr [rbx].FRAMEV1_ENTRY.FrameHeight
        .IF rax > MaxHeight
            mov MaxHeight, rax
        .ENDIF

        add FrameEntryOffset, SIZEOF FRAMEV1_ENTRY
        
        inc nFrame
        mov rax, nFrame
    .ENDW    
    
    mov rbx, lpqwMaxWidth
    mov rax, MaxWidth
    mov [rbx], rax
    
    mov rbx, lpqwMaxHeight
    mov rax, MaxHeight
    mov [rbx], rax
    
    mov rax, 0    
    ret

IEBAMFindMaxWidthHeight ENDP



IEBAM_LIBEND

