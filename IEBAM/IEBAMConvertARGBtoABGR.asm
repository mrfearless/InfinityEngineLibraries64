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


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Convert to RGBQUAD (BGRA) format from RGB ColorRef (ARGB)
;------------------------------------------------------------------------------
IEBAMConvertARGBtoABGR PROC FRAME USES RBX dwARGB:DWORD
    LOCAL clrRed:DWORD
    LOCAL clrGreen:DWORD
    LOCAL clrBlue:DWORD
    LOCAL clrAlpha:DWORD
    
    xor rax, rax
    mov eax, dwARGB

    xor rbx, rbx
    mov bl, al
    mov clrRed, ebx
    xor rbx, rbx
    mov bl, ah
    mov clrGreen, ebx

    shr eax, 16d

    xor rbx, rbx
    mov bl, al
    mov clrBlue, ebx
    xor rbx, rbx
    mov bl, ah
    mov clrAlpha, ebx

    xor rax, rax
    xor rbx, rbx
    mov eax, clrAlpha
    mov ebx, clrRed
    shl eax, 8d
    mov al, bl
    shl eax, 16d ; alpha and red in upper qword
    mov ebx, clrGreen
    mov ah, bl
    mov ebx, clrBlue
    mov al, bl
    ; rax contains BGRA - RGBQUAD
    ret
IEBAMConvertARGBtoABGR ENDP



IEBAM_LIBEND

