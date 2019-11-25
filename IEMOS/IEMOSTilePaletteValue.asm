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

EXTERNDEF IEMOSTilePalette     :PROTO hIEMOS:QWORD, nTile:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTilePaletteValue - Returns in rax a RGBQUAD of the specified 
; palette index of the tile palette or -1 if not valid
;------------------------------------------------------------------------------
IEMOSTilePaletteValue PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD, PaletteIndex:QWORD
    LOCAL TilePaletteOffset:QWORD
    
    .IF hIEMOS == NULL
        mov rax, -1
        ret
    .ENDIF
    
    .IF PaletteIndex > 255
        mov rax, -1
        ret
    .ENDIF
    
    Invoke IEMOSTilePalette, hIEMOS, nTile
    .IF rax == NULL
        mov rax, -1
        ret
    .ENDIF
    mov TilePaletteOffset, rax

    mov rax, PaletteIndex
    mov rbx, 4 ; dword RGBA array size
    mul rbx
    add rax, TilePaletteOffset
    mov eax, dword ptr [rax]

    ret
IEMOSTilePaletteValue ENDP



IEMOS_LIBEND

