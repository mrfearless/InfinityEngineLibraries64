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

EXTERNDEF IEBAMPalette  :PROTO hIEBAM:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in rax pointer to palette RGBAQUAD entry, or NULL otherwise
;------------------------------------------------------------------------------
IEBAMPaletteEntry PROC FRAME USES RBX hIEBAM:QWORD, PaletteIndex:QWORD
    LOCAL PaletteOffset:QWORD

    .IF hIEBAM == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    .IF PaletteIndex > 255
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMPalette, hIEBAM
    .IF rax == NULL
        ret
    .ENDIF
    mov PaletteOffset, rax
    
    mov rax, PaletteIndex
    mov rbx, 4 ; qword RGBA array size
    mul rbx
    add rax, PaletteOffset
    ret
IEBAMPaletteEntry ENDP



IEBAM_LIBEND

