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
includelib gdi32.lib

include IEMOS.inc

EXTERNDEF MOSCalcDwordAligned :PROTO qwWidthOrHeight:QWORD

.DATA
MOSTileBitmap               DB (SIZEOF BITMAPINFOHEADER + 1024) dup (0)

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; Returns in rax handle to tile data bitmap or NULL. 
;------------------------------------------------------------------------------
MOSTileDataBitmap PROC FRAME USES RBX qwTileWidth:QWORD, qwTileHeight:QWORD, pTileBMP:QWORD, qwTileSizeBMP:QWORD, pTilePalette:QWORD
    LOCAL hdc:QWORD
    LOCAL TileBitmapHandle:QWORD
    
    Invoke RtlZeroMemory, Addr MOSTileBitmap, (SIZEOF BITMAPINFOHEADER + 1024)

    lea rbx, MOSTileBitmap
    mov [rbx].BITMAPINFOHEADER.biSize, 40d
    mov rax, qwTileWidth
    mov [rbx].BITMAPINFOHEADER.biWidth, eax
    mov rax, qwTileHeight
    neg rax
    mov [rbx].BITMAPINFOHEADER.biHeight, eax
    mov [rbx].BITMAPINFOHEADER.biPlanes, 1
    mov [rbx].BITMAPINFOHEADER.biBitCount, 8
    mov [rbx].BITMAPINFOHEADER.biCompression, BI_RGB
    mov rax, qwTileSizeBMP
    mov [rbx].BITMAPINFOHEADER.biSizeImage, eax
    mov [rbx].BITMAPINFOHEADER.biXPelsPerMeter, 2835d
    mov [rbx].BITMAPINFOHEADER.biYPelsPerMeter, 2835d
    lea rax, MOSTileBitmap
    lea rbx, [rax].BITMAPINFO.bmiColors
    Invoke RtlMoveMemory, rbx, pTilePalette, 1024d
    
    ;Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    Invoke GetDC, 0
    mov hdc, rax
    Invoke CreateDIBitmap, hdc, Addr MOSTileBitmap, CBM_INIT, pTileBMP, Addr MOSTileBitmap, DIB_RGB_COLORS
    .IF rax == NULL
        IFDEF DEBUG32
            PrintText 'CreateDIBitmap Failed'
        ENDIF
    .ENDIF
    mov TileBitmapHandle, rax
    ;Invoke DeleteDC, hdc
    Invoke ReleaseDC, 0, hdc
    mov rax, TileBitmapHandle
    ret
MOSTileDataBitmap ENDP


IEMOS_LIBEND

