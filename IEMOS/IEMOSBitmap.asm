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
includelib kernel32.Lib
includelib gdi32.Lib

include IEMOS.inc

EXTERNDEF IEMOSTotalTiles       :PROTO hIEMOS:QWORD
EXTERNDEF IEMOSImageDimensions  :PROTO hIEMOS:QWORD, lpqwImageWidth:QWORD, lpqwImageHeight:QWORD
EXTERNDEF IEMOSTileBitmap       :PROTO hIEMOS:QWORD, nTile:QWORD, lpqwTileWidth:QWORD, lpqwTileHeight:QWORD, lpqwTileXCoord:QWORD, lpqwTileYCoord:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileBitmap - Returns HBITMAP (of all combined tile bitmaps) or NULL.
; This HBITMAP is not freed when IEMOS library is closed, it should be freed
; by DeleteObject when no longer needed
;------------------------------------------------------------------------------
IEMOSBitmap PROC FRAME hIEMOS:QWORD, qwPreferWidth:QWORD, qwPreferHeight:QWORD
    LOCAL hdc:QWORD
    LOCAL hdcMem:QWORD
    LOCAL hdcTile:QWORD
    LOCAL hdcResized:QWORD
    LOCAL SavedDCTile:QWORD
    LOCAL hBitmap:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL hBitmapResized:QWORD
    LOCAL hBitmapResizedOld:QWORD
    LOCAL hTileBitmap:QWORD
    LOCAL hTileBitmapOld:QWORD
    LOCAL qwImageWidth:QWORD
    LOCAL qwImageHeight:QWORD
    LOCAL TileX:QWORD
    LOCAL TileY:QWORD
    LOCAL TileW:QWORD
    LOCAL TileH:QWORD
    LOCAL TotalTiles:QWORD
    LOCAL nTile:QWORD
    
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF  
    
    Invoke IEMOSTotalTiles, hIEMOS
    .IF rax == 0
        ret
    .ENDIF
    mov TotalTiles, rax
    
    Invoke IEMOSImageDimensions, hIEMOS, Addr qwImageWidth, Addr qwImageHeight
    .IF qwImageWidth == 0 && qwImageHeight == 0
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke GetDC, 0
    ;Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    mov hdc, rax

    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax

    Invoke CreateCompatibleDC, hdc
    mov hdcTile, rax

    Invoke CreateCompatibleBitmap, hdc, dword ptr qwImageWidth, dword ptr qwImageHeight
    mov hBitmap, rax
    
    Invoke SelectObject, hdcMem, hBitmap
    mov hOldBitmap, rax
    
    Invoke SaveDC, hdcTile
    mov SavedDCTile, rax
    
    mov rax, 0
    mov nTile, 0
    .WHILE rax < TotalTiles
        Invoke IEMOSTileBitmap, hIEMOS, nTile, Addr TileW, Addr TileH, Addr TileX, Addr TileY
        .IF rax != NULL
            mov hTileBitmap, rax
            Invoke SelectObject, hdcTile, hTileBitmap
            mov hTileBitmapOld, rax
            Invoke BitBlt, hdcMem, dword ptr TileX, dword ptr TileY, dword ptr TileW, dword ptr TileH, hdcTile, 0, 0, SRCCOPY
            Invoke SelectObject, hdcTile, hTileBitmapOld
            Invoke DeleteObject, hTileBitmapOld
        .ENDIF

        inc nTile
        mov rax, nTile
    .ENDW
    
    .IF qwPreferWidth == 0 && qwPreferHeight == 0
        .IF hOldBitmap != 0
            Invoke SelectObject, hdcMem, hOldBitmap
            Invoke DeleteObject, hOldBitmap
        .ENDIF
        Invoke RestoreDC, hdcTile, dword ptr SavedDCTile
        Invoke DeleteDC, hdcTile
        Invoke DeleteDC, hdcMem
        ;Invoke DeleteDC, hdc
        Invoke ReleaseDC, 0, hdc
        mov rax, hBitmap
    .ELSE
        
        Invoke CreateCompatibleDC, hdc
        mov hdcResized, rax
        
        Invoke CreateCompatibleBitmap, hdc, dword ptr qwPreferWidth, dword ptr qwPreferHeight
        mov hBitmapResized, rax
        
        Invoke SelectObject, hdcResized, hBitmapResized
        mov hBitmapResizedOld, rax
        ;Invoke SetStretchBltMode, hdcResized, HALFTONE
        ;Invoke SetBrushOrgEx, hdcResized, 0, 0, 0
        Invoke StretchBlt, hdcResized, 0, 0, dword ptr qwPreferWidth, dword ptr qwPreferHeight, hdcMem, 0, 0, dword ptr qwImageWidth, dword ptr qwImageHeight, SRCCOPY
        
        .IF hOldBitmap != 0
            Invoke SelectObject, hdcMem, hOldBitmap
            Invoke DeleteObject, hOldBitmap
            Invoke DeleteObject, hBitmap
        .ENDIF
        .IF hBitmapResizedOld != 0
            Invoke SelectObject, hdcResized, hBitmapResizedOld
            Invoke DeleteObject, hBitmapResizedOld
        .ENDIF
        Invoke RestoreDC, hdcTile, dword ptr SavedDCTile
        Invoke DeleteDC, hdcResized
        Invoke DeleteDC, hdcTile
        Invoke DeleteDC, hdcMem
        ;Invoke DeleteDC, hdc
        Invoke ReleaseDC, 0, hdc
        mov rax, hBitmapResized
    .ENDIF
    
    ret
IEMOSBitmap ENDP



IEMOS_LIBEND

