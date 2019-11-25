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
; Unroll RLE compressed bam frame to RAW data. Returns Frame Size or NULL
;------------------------------------------------------------------------------
BAMFrameUnRLE PROC FRAME USES RCX RDI RSI pFrameRLE:QWORD, FrameRLESize:QWORD, pFrameRAW:QWORD, FrameRAWSize:QWORD
    LOCAL RLECurrentPos:QWORD
    LOCAL RAWCurrentPos:QWORD
    LOCAL ZeroCount:QWORD
    LOCAL ZeroTotal:QWORD
    LOCAL FrameSize:QWORD

    .IF pFrameRLE == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    .IF pFrameRAW == NULL
        mov rax, NULL
        ret
    .ENDIF

    mov RLECurrentPos, 0
    mov RAWCurrentPos, 0
    mov FrameSize, 0
    
    mov rax, 0
    .WHILE rax < FrameRLESize
        mov rsi, pFrameRLE
        add rsi, RLECurrentPos
        
        movzx rax, byte ptr [rsi]
        .IF al == 0h
            mov rcx, RLECurrentPos ; check not at end for next char
            inc rcx
            .IF rcx < FrameRLESize
                inc rsi
                movzx rax, byte ptr [rsi] ; al contains amount of 0's to copy
                inc rax ; for +1 count
                mov ZeroTotal, rax
                mov ZeroCount, 0
                mov rax, 0
                mov rdi, pFrameRAW
                add rdi, RAWCurrentPos
                .WHILE rax < ZeroTotal
                    mov byte ptr [rdi], 0h
                    inc rdi
                    inc RAWCurrentPos
                    
                    ; check frame size
                    mov rax, FrameSize
                    inc rax
                    .IF rax > FrameRAWSize
                        .BREAK
                    .ENDIF
                    
                    inc FrameSize
                    inc ZeroCount
                    mov rax, ZeroCount
                .ENDW
                
                ; check frame size
                mov rax, FrameSize
                inc rax
                .IF rax > FrameRAWSize
                    .BREAK
                .ENDIF
                inc RLECurrentPos
                inc RLECurrentPos

            .ELSE ; if this char is the last one and we have a 0 then just copy it
                mov rdi, pFrameRAW
                add rdi, RAWCurrentPos
                mov byte ptr [rdi], al
                inc RAWCurrentPos
                inc FrameSize
                inc RLECurrentPos
            .ENDIF
        .ELSE
            mov rdi, pFrameRAW
            add rdi, RAWCurrentPos
            mov byte ptr [rdi], al
            inc RAWCurrentPos
            inc FrameSize
            inc RLECurrentPos
        .ENDIF
    
        mov rax, RLECurrentPos
    .ENDW

    mov rax, FrameSize
    ret
BAMFrameUnRLE ENDP


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Check the size of the Unroll RLE compressed bam frame. Returns RAW Frame Size
;------------------------------------------------------------------------------
BAMFrameUnRLESize PROC FRAME USES RCX RSI pFrameRLE:QWORD, FrameRLESize:QWORD
    LOCAL RLECurrentPos:QWORD
    LOCAL ZeroCount:QWORD
    LOCAL ZeroTotal:QWORD
    LOCAL FrameSize:QWORD

    .IF pFrameRLE == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    mov RLECurrentPos, 0
    mov FrameSize, 0
    
    mov rax, 0
    .WHILE rax < FrameRLESize
        mov rsi, pFrameRLE
        add rsi, RLECurrentPos
        
        movzx rax, byte ptr [rsi]
        .IF al == 0h
            mov rcx, RLECurrentPos ; check not at end for next char
            inc rcx
            .IF rcx < FrameRLESize
                inc rsi
                movzx rax, byte ptr [rsi] ; al contains amount of 0's to copy
                inc rax ; for +1 count
                mov ZeroTotal, rax
                mov ZeroCount, 0
                mov rax, 0

                .WHILE rax < ZeroTotal
                    inc FrameSize
                    inc ZeroCount
                    mov rax, ZeroCount
                .ENDW
                inc RLECurrentPos
                inc RLECurrentPos

            .ELSE ; if this char is the last one and we have a 0 then just copy it
                inc FrameSize
                inc RLECurrentPos
            .ENDIF
        .ELSE
            inc FrameSize
            inc RLECurrentPos
        .ENDIF
    
        mov rax, RLECurrentPos
    .ENDW

    mov rax, FrameSize
    ret
BAMFrameUnRLESize ENDP


IEBAM_LIBEND

