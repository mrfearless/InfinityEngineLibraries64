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

EXTERNDEF IEMOSTileDataEntry    :PROTO hIEMOS:QWORD, nTile:QWORD
EXTERNDEF IEMOSTilePalette      :PROTO hIEMOS:QWORD, nTile:QWORD
EXTERNDEF MOSTileDataBitmap     :PROTO qwTileWidth:QWORD, qwTileHeight:QWORD, pTileBMP:QWORD, qwTileSizeBMP:QWORD, pTilePalette:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileBitmap - Returns in rax HBITMAP or NULL. Optional variables pointed 
; to, are filled in if rax is a HBITMAP (!NULL), otherwise vars (if supplied) 
; will be set to 0
; Bitmaps created with this function are freed by the IEMOS library when it
; is closed
;------------------------------------------------------------------------------
IEMOSTileBitmap PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD, lpqwTileWidth:QWORD, lpqwTileHeight:QWORD, lpqwTileXCoord:QWORD, lpqwTileYCoord:QWORD
    LOCAL TilePaletteEntry:QWORD
    LOCAL TileDataEntry:QWORD
    LOCAL TileWidth:QWORD
    LOCAL TileHeight:QWORD
    LOCAL TileXCoord:QWORD
    LOCAL TileYCoord:QWORD
    LOCAL TileSizeBMP:QWORD
    LOCAL TileBMP:QWORD
    LOCAL TileBitmapHandle:QWORD
    
    mov TileWidth, 0
    mov TileHeight, 0
    mov TileXCoord, 0
    mov TileYCoord, 0
    mov TileBitmapHandle, 0
    
    .IF hIEMOS == NULL
        jmp IEMOSTileBitmapExit
    .ENDIF    
    
    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF rax == NULL
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileDataEntry, rax

    mov rbx, TileDataEntry
    mov rax, [rbx].TILEDATA.TileW
    .IF rax == 0
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileWidth, rax
    mov rax, [rbx].TILEDATA.TileH
    .IF rax == 0
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileHeight, rax
    mov rax, [rbx].TILEDATA.TileX
    mov TileXCoord, rax
    mov rax, [rbx].TILEDATA.TileY
    mov TileYCoord, rax
    
    mov rax, [rbx].TILEDATA.TileBitmapHandle
    .IF rax != 0
        mov TileBitmapHandle, rax
        jmp IEMOSTileBitmapExit
    .ENDIF    
    
    mov rax, [rbx].TILEDATA.TileSizeBMP
    .IF rax == 0
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileSizeBMP, rax
    mov rax, [rbx].TILEDATA.TileBMP
    .IF rax == 0
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TileBMP, rax

    Invoke IEMOSTilePalette, hIEMOS, nTile
    .IF rax == NULL
        jmp IEMOSTileBitmapExit
    .ENDIF
    mov TilePaletteEntry, rax

    Invoke MOSTileDataBitmap, TileWidth, TileHeight, TileBMP, TileSizeBMP, TilePaletteEntry
    .IF rax != NULL ; save bitmap handle back to TILEDATA struct
        mov TileBitmapHandle, rax
        mov rbx, TileDataEntry
        mov [rbx].TILEDATA.TileBitmapHandle, rax
    .ENDIF

IEMOSTileBitmapExit:

    .IF lpqwTileWidth != NULL
        mov rbx, lpqwTileWidth
        mov rax, TileWidth
        mov [rbx], rax
    .ENDIF
    
    .IF lpqwTileHeight != NULL
        mov rbx, lpqwTileHeight
        mov rax, TileHeight
        mov [rbx], rax
    .ENDIF
   
    .IF lpqwTileXCoord != NULL
        mov rbx, lpqwTileXCoord
        mov rax, TileXCoord
        mov [rbx], rax
    .ENDIF
    
    .IF lpqwTileYCoord != NULL
        mov rbx, lpqwTileYCoord
        mov rax, TileYCoord
        mov [rbx], rax
    .ENDIF
    
    mov rax, TileBitmapHandle
    ret
IEMOSTileBitmap ENDP



IEMOS_LIBEND

