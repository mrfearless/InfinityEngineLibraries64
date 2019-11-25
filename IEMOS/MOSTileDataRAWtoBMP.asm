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
includelib user32.lib
includelib kernel32.lib

include IEMOS.inc

EXTERNDEF MOSCalcDwordAligned :PROTO qwWidthOrHeight:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------
MOSTileDataRAWtoBMP PROC FRAME USES RDI RSI pTileRAW:QWORD, pTileBMP:QWORD, qwTileSizeRAW:QWORD, qwTileSizeBMP:QWORD, qwTileWidth:QWORD
    LOCAL RAWCurrentPos:QWORD
    LOCAL BMPCurrentPos:QWORD
    LOCAL WidthDwordAligned:QWORD
    
    Invoke RtlZeroMemory, pTileBMP, qwTileSizeBMP

    Invoke MOSCalcDwordAligned, qwTileWidth
    mov WidthDwordAligned, rax

    mov RAWCurrentPos, 0
    mov BMPCurrentPos, 0
    mov rax, 0
    .WHILE sqword ptr rax < qwTileSizeRAW
    
        mov rsi, pTileRAW
        add rsi, RAWCurrentPos
        mov rdi, pTileBMP
        add rdi, BMPCurrentPos
        
        Invoke RtlMoveMemory, rdi, rsi, qwTileWidth
    
        mov rax, WidthDwordAligned
        add BMPCurrentPos, rax
        mov rax, qwTileWidth
        add RAWCurrentPos, rax
        
        mov rax, RAWCurrentPos
    .ENDW

    ret
MOSTileDataRAWtoBMP ENDP


IEMOS_LIBEND

