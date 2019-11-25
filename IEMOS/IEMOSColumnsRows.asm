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
; IEMOSColumnsRows - Returns columns and rows in pointer to variables 
; provided
;------------------------------------------------------------------------------
IEMOSColumnsRows PROC FRAME USES RBX hIEMOS:QWORD, lpqwColumns:QWORD, lpqwRows:QWORD
    LOCAL qwColumns:QWORD
    LOCAL qwRows:QWORD
    
    mov qwColumns, 0
    mov qwRows, 0
    .IF hIEMOS != NULL
        mov rbx, hIEMOS
        mov rbx, [rbx].MOSINFO.MOSHeaderPtr
        .IF rbx != NULL
            movzx rax, word ptr [rbx].MOSV1_HEADER.BlockColumns
            mov qwColumns, rax
            movzx rax, word ptr [rbx].MOSV1_HEADER.BlockRows
            mov qwRows, rax
        .ENDIF
    .ENDIF
    .IF lpqwColumns != NULL
        mov rbx, lpqwColumns
        mov rax, qwColumns
        mov [rbx], rax
    .ENDIF
    .IF lpqwRows != NULL
        mov rbx, lpqwRows
        mov rax, qwRows
        mov [rbx], rax
    .ENDIF
    xor rax, rax
    ret
IEMOSColumnsRows ENDP



IEMOS_LIBEND

