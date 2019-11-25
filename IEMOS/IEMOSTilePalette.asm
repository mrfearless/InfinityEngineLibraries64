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

EXTERNDEF IEMOSPalettes     :PROTO hIEMOS:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTilePalette - Returns in rax a pointer to the tile palette or NULL if 
; not valid
;------------------------------------------------------------------------------
IEMOSTilePalette PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    LOCAL PaletteOffset:QWORD

    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSTotalTiles
    .IF nTile >= rax ; 0 based tile index
        mov rax, NULL
        ret
    .ENDIF

    Invoke IEMOSPalettes, hIEMOS
    .IF rax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; rax contains PaletteOffset which is tile 0's palette start
        ret
    .ENDIF
    mov PaletteOffset, rax    
    
    mov rax, nTile
    mov rbx, 1024 ;(256 * SIZEOF DWORD)
    mul rbx
    add rax, PaletteOffset
    
    ret
IEMOSTilePalette ENDP



IEMOS_LIBEND

