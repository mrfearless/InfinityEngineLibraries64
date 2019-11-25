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
includelib kernel32.lib

include IEBAM.inc

EXTERNDEF BAMCalcDwordAligned   :PROTO qwWidthOrHeight:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Converts FrameRAW data to FrameBMP for use in bitmap creation
;------------------------------------------------------------------------------
BAMFrameRAWToFrameBMP PROC FRAME USES RDI RSI pFrameRAW:QWORD, pFrameBMP:QWORD, FrameRAWSize:QWORD, FrameBMPSize:QWORD, FrameWidth:QWORD
    LOCAL TotalBytesWritten:QWORD
    LOCAL RAWCurrentPos:QWORD
    LOCAL BMPCurrentPos:QWORD
    LOCAL LastWidth:QWORD
    LOCAL FrameWidthDwordAligned:QWORD
    
    Invoke RtlZeroMemory, pFrameBMP, FrameBMPSize
    
    Invoke BAMCalcDwordAligned, FrameWidth
    mov FrameWidthDwordAligned, rax

    mov TotalBytesWritten, 0
    mov RAWCurrentPos, 0
    mov rax, FrameRAWSize
    mov BMPCurrentPos, rax
    .WHILE sqword ptr rax > 0
        
        mov rax, BMPCurrentPos
        .IF rax < FrameWidth
            mov rax, FrameWidth
            sub rax, BMPCurrentPos
            ;mov ebx, BMPCurrentPos
            ;sub eax, ebx
            mov LastWidth, rax
            add TotalBytesWritten, rax
 
            mov rsi, pFrameRAW
            mov rdi, pFrameBMP
            add rdi, RAWCurrentPos
            Invoke RtlMoveMemory, rdi, rsi, LastWidth
            .BREAK

        .ELSE
            mov rsi, pFrameRAW
            add rsi, BMPCurrentPos
            sub rsi, FrameWidth
            
            mov rdi, pFrameBMP
            add rdi, RAWCurrentPos
            
            Invoke RtlMoveMemory, rdi, rsi, FrameWidth
            mov rax, FrameWidthDwordAligned
            add TotalBytesWritten, rax
            
            mov rax, RAWCurrentPos
            add rax, FrameWidthDwordAligned
            mov RAWCurrentPos, rax
            mov rax, BMPCurrentPos
            sub rax, FrameWidth
            mov BMPCurrentPos, rax
        .ENDIF
        
        mov rax, BMPCurrentPos
    .ENDW
    ret
BAMFrameRAWToFrameBMP ENDP



IEBAM_LIBEND

