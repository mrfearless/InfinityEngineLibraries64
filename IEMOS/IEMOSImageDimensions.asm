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
; IEMOSImageDimensions - Returns width and height in pointer to variables 
; provided
;------------------------------------------------------------------------------
IEMOSImageDimensions PROC FRAME USES RBX hIEMOS:QWORD, lpqwImageWidth:QWORD, lpqwImageHeight:QWORD
    LOCAL qwImageWidth:QWORD
    LOCAL qwImageHeight:QWORD
    
    mov qwImageWidth, 0
    mov qwImageHeight, 0
    
    .IF hIEMOS != NULL
        mov rbx, hIEMOS
        mov rbx, [rbx].MOSINFO.MOSHeaderPtr
        .IF rbx != NULL
            movzx eax, word ptr [rbx].MOSV1_HEADER.ImageWidth
            mov qwImageWidth, rax
            movzx rax, word ptr [rbx].MOSV1_HEADER.ImageHeight
            mov qwImageHeight, rax
        .ENDIF
    .ENDIF
    .IF lpqwImageWidth != NULL
        mov rbx, lpqwImageWidth
        mov rax, qwImageWidth
        mov [rbx], rax
    .ENDIF
    .IF lpqwImageHeight != NULL
        mov rbx, lpqwImageHeight
        mov rax, qwImageHeight
        mov [rbx], rax
    .ENDIF
    xor rax, rax
    ret
IEMOSImageDimensions ENDP



IEMOS_LIBEND

