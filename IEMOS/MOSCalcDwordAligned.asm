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


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; Calc dword aligned size for height or width value
;------------------------------------------------------------------------------
MOSCalcDwordAligned PROC FRAME USES RCX RDX qwWidthOrHeight:QWORD
    .IF qwWidthOrHeight == 0
        mov rax, 0
        ret
    .ENDIF
    mov rax, qwWidthOrHeight
    and rax, 1 ; ( a AND (b-1) )
    .IF rax == 0 ; if divisable by 2, use: and eax 3 - to div by 4    
        mov rax, qwWidthOrHeight
        and rax, 3 ; div by 4, get remainder
        add rax, qwWidthOrHeight
    .ELSE ; else use div to get remainder and add to qwWidthOrHeight
        xor rdx, rdx
        mov rax, qwWidthOrHeight
        mov rcx, 4
        div rcx ;edx contains remainder
        .IF rdx != 0
            mov rax, 4
            sub rax, rdx
            add rax, qwWidthOrHeight
        .ELSE
            mov rax, qwWidthOrHeight
        .ENDIF
    .ENDIF
    ; rax contains dword aligned value   
    ret
MOSCalcDwordAligned ENDP


IEMOS_LIBEND

