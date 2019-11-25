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
; Convert to RGB ColorRef (ARGB) format from RGBQUAD (BGRA) Returns Alpha as well
; to mask off use AND, 00FFFFFFh for just RGB.
;------------------------------------------------------------------------------
IEBAMConvertABGRtoARGB PROC FRAME USES RBX dwBGRA:DWORD
    LOCAL clrRed:DWORD
    LOCAL clrGreen:DWORD
    LOCAL clrBlue:DWORD
    LOCAL clrAlpha:DWORD
    
    xor rax, rax
    mov eax, dwBGRA ; stored in reverse format ARGB in memory

    xor rbx, rbx
    mov bl, al
    mov clrBlue, ebx
    xor rbx, rbx
    mov bl, ah
    mov clrGreen, ebx

    shr eax, 16d

    xor rbx, rbx
    mov bl, al
    mov clrRed, ebx
    xor rbx, rbx
    mov bl, ah
    mov clrAlpha, ebx

    xor rax, rax
    xor rbx, rbx
    mov eax, clrAlpha
    mov ebx, clrBlue
    shl eax, 8d
    mov al, bl
    shl eax, 16d ; alpha and red in upper qword
    mov ebx, clrGreen
    mov ah, bl
    mov ebx, clrRed
    mov al, bl
    ; rax contains ARGB
    ret
IEBAMConvertABGRtoARGB ENDP




IEBAM_LIBEND

