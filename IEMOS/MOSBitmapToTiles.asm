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

.CONST
BLOCKSIZE_DEFAULT           EQU 64

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; Returns in rax total tiles.
;------------------------------------------------------------------------------
MOSBitmapToTiles PROC FRAME USES RBX hBitmap:QWORD, lpqwTileDataArray:QWORD, lpqwPaletteArray:QWORD, lpqwImageWidth:QWORD, lpqwImageHeight:QWORD, lpqwBlockColumns:QWORD, lpqwBlockRows:QWORD
    LOCAL bm:BITMAP
    LOCAL qwImageWidth:QWORD
    LOCAL qwImageHeight:QWORD
    LOCAL Columns:QWORD
    LOCAL Rows:QWORD
    LOCAL TileRightWidth:QWORD
    LOCAL TileBottomHeight:QWORD
    LOCAL TileW:QWORD    
    LOCAL TileH:QWORD
    LOCAL TotalTiles:QWORD
    
    ;GetDIBits https://docs.microsoft.com/en-us/windows/desktop/api/wingdi/nf-wingdi-getdibits
    ; https://www.autoitscript.com/forum/topic/74330-getdibits/
    ;https://stackoverflow.com/questions/46562369/winapi-gdi-how-to-use-getdibits-to-get-color-table-synthesized-for-a-bitmap
    ;http://forums.codeguru.com/showthread.php?175394-How-to-save-a-bitmap-correctly
    ; do it in reverse
    
    ; get bitmap image width and height

    ; calc columns, rows, blocksize and total tiles
    
    ; alloc TILEDATA for total tiles
    ; loop through tiles and
    ; get tile width, height, x, y, tilesizebmp, tileBMP
    ; get tileBMP GDIBits and GDI color table for tile palette
    ; strip dword alignment from tileBMP to convert to tileRAW and find tilesizeraw
    ; 

    .IF hBitmap == NULL
        mov rax, 0
        ret
    .ENDIF
    
    Invoke RtlZeroMemory, Addr bm, SIZEOF BITMAP
    Invoke GetObject, hBitmap, SIZEOF bm, Addr bm
    .IF rax == 0
        ret
    .ENDIF
    
    xor rax, rax
    mov eax, bm.bmWidth
    mov qwImageWidth, rax
    mov eax, bm.bmHeight
    mov qwImageHeight, rax

    .IF qwImageWidth == 0 || qwImageHeight == 0
        mov rax, 0
        ret
    .ENDIF
    
    ; 200 x 36
    ; If imagewidth >= BLOCKSIZE_DEFAULT
    ;   imagewidth % BLOCKSIZE_DEFAULT = no of columns
    ;   if remainder != 0
    ;       then inc no columns and last col is this width TileRightWidth
    ;       TileRightWidth = remainder
    ;   else
    ;       TileRightWidth = BLOCKSIZE_DEFAULT
    ;   endif
    ;   TileW = BLOCKSIZE_DEFAULT
    ; else ; imagewidth < BLOCKSIZE_DEFAULT
    ;   columns = 1
    ;   TileW = imagewidth
    ; endif
    
    ; If imageheight >= BLOCKSIZE_DEFAULT
    ;   imageheight % BLOCKSIZE_DEFAULT = no of rows
    ;   if remainder != 0
    ;       then inc no rows and last rows is this width TileBottomHeight
    ;   endif
    ;   TileH = BLOCKSIZE_DEFAULT
    ; else
    ;   TileH = imageheight
    ; endif
    ;
    ; TotalTiles = columns x rows
    
    
    ret

MOSBitmapToTiles ENDP


IEMOS_LIBEND

