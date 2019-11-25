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
; IEMOSPixelBlockSize - Returns size of pixels used in each block
;------------------------------------------------------------------------------
IEMOSPixelBlockSize PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rbx, [rbx].MOSINFO.MOSHeaderPtr
    .IF rbx != NULL
        movzx rax, word ptr [rbx].MOSV1_HEADER.BlockSize
    .ELSE
        mov rax, 0
    .ENDIF
    ret
IEMOSPixelBlockSize ENDP



IEMOS_LIBEND

