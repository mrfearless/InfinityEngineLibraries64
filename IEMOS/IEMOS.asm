;==============================================================================
;
; IEMOS x64
;
; Copyright (c) 2019 by fearless
;
; http://github.com/mrfearless/InfinityEngineLibraries64
;
;
; This software is provided 'as-is', without any express or implied warranty. 
; In no event will the author be held liable for any damages arising from the 
; use of this software.
;
; Permission is granted to anyone to use this software for any non-commercial 
; program. If you use the library in an application, an acknowledgement in the
; application or documentation is appreciated but not required. 
;
; You are allowed to make modifications to the source code, but you must leave
; the original copyright notices intact and not misrepresent the origin of the
; software. It is not allowed to claim you wrote the original software. 
; Modified files must have a clear notice that the files are modified, and not
; in the original state. This includes the name of the person(s) who modified 
; the code. 
;
; If you want to distribute or redistribute any portion of this package, you 
; will need to include the full package in it's original state, including this
; license and all the copyrights.  
;
; While distributing this package (in it's original state) is allowed, it is 
; not allowed to charge anything for this. You may not sell or include the 
; package in any commercial package without having permission of the author. 
; Neither is it allowed to redistribute any of the package's components with 
; commercial applications.
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

includelib kernel32.lib
includelib user32.lib


;DEBUG64 EQU 1

;IFDEF DEBUG64
;    PRESERVEXMMREGS equ 1
;    includelib \UASM\lib\x64\Debug64.lib
;    DBG64LIB equ 1
;    DEBUGEXE textequ <'\UASM\bin\DbgWin.exe'>
;    include \UASM\include\debug64.inc
;    .DATA
;    RDBG_DbgWin	DB DEBUGEXE,0
;    .CODE
;ENDIF

include IEMOS.inc

; Internal functions start with MOS
; External functions start with IEMOS 

;-------------------------------------------------------------------------
; Internal functions:
;-------------------------------------------------------------------------
MOSSignature                PROTO pMOS:QWORD
MOSJustFname                PROTO szFilePathName:QWORD, szFileName:QWORD
MOSUncompress               PROTO hMOSFile:QWORD, pMOS:QWORD, qwSize:QWORD

MOSV1Mem                    PROTO pMOSInMemory:QWORD, lpszMosFilename:QWORD, qwMosFilesize:QWORD, qwOpenMode:QWORD
MOSV2Mem                    PROTO pMOSInMemory:QWORD, lpszMosFilename:QWORD, qwMosFilesize:QWORD, qwOpenMode:QWORD

MOSGetTileDataWidth         PROTO nTile:QWORD, qwBlockColumns:QWORD, qwBlockSize:QWORD, qwImageWidth:QWORD
MOSGetTileDataHeight        PROTO nTile:QWORD, qwBlockRows:QWORD, qwBlockColumns:QWORD, qwBlockSize:QWORD, qwImageHeight:QWORD

MOSCalcDwordAligned         PROTO qwWidthOrHeight:QWORD
MOSTileDataRAWtoBMP         PROTO pTileRAW:QWORD, pTileBMP:QWORD, qwTileSizeRAW:QWORD, qwTileSizeBMP:QWORD, qwTileWidth:QWORD
MOSTileDataBitmap           PROTO qwTileWidth:QWORD, qwTileHeight:QWORD, pTileBMP:QWORD, qwTileSizeBMP:QWORD, pTilePalette:QWORD
MOSBitmapToTiles            PROTO hBitmap:QWORD, lpqwTileDataArray:QWORD, lpqwPaletteArray:QWORD, lpqwImageWidth:QWORD, lpqwImageHeight:QWORD, lpqwBlockColumns:QWORD, lpqwBlockRows:QWORD

MOSScaleWidthHeight         PROTO qwImageWidth:QWORD, qwImageHeight:QWORD, qwPreferredWidth:QWORD, qwPreferredHeight:QWORD, lpqwScaledWidth:QWORD, lpqwScaledHeight:QWORD


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSOpen - Returns handle in eax of opened mos file. NULL if could not alloc
; enough mem
;------------------------------------------------------------------------------
IEMOSOpen PROC FRAME USES RBX lpszMosFilename:QWORD, qwOpenMode:QWORD
    LOCAL hIEMOS:QWORD
    LOCAL hMOSFile:QWORD
    LOCAL MOSFilesize:QWORD
    LOCAL SigReturn:QWORD
    LOCAL MOSMemMapHandle:QWORD
    LOCAL MOSMemMapPtr:QWORD
    LOCAL pMOS:QWORD

    .IF qwOpenMode == IEMOS_MODE_READONLY ; readonly
        Invoke CreateFile, lpszMosFilename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszMosFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF
 
    .IF rax == INVALID_HANDLE_VALUE
        mov rax, NULL
        ret
    .ENDIF
    mov hMOSFile, rax

    Invoke GetFileSize, hMOSFile, NULL
    mov MOSFilesize, rax

    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .mos
    ;---------------------------------------------------
    .IF qwOpenMode == IEMOS_MODE_READONLY ; readonly
        Invoke CreateFileMapping, hMOSFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hMOSFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF rax == NULL
        Invoke CloseHandle, hMOSFile      
        mov rax, NULL
        ret
    .ENDIF
    mov MOSMemMapHandle, rax
    
    .IF qwOpenMode == IEMOS_MODE_READONLY ; readonly
        Invoke MapViewOfFileEx, MOSMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, MOSMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF rax == NULL
        Invoke CloseHandle, MOSMemMapHandle
        Invoke CloseHandle, hMOSFile    
        mov rax, NULL
        ret
    .ENDIF
    mov MOSMemMapPtr, rax

    Invoke MOSSignature, MOSMemMapPtr
    mov SigReturn, rax
    .IF SigReturn == MOS_VERSION_INVALID ; not a valid mos file
        Invoke UnmapViewOfFile, MOSMemMapPtr
        Invoke CloseHandle, MOSMemMapHandle
        Invoke CloseHandle, hMOSFile
        mov rax, NULL
        ret    
    
    .ELSEIF SigReturn == MOS_VERSION_MOS_V10 ; MOS
        Invoke IEMOSMem, MOSMemMapPtr, lpszMosFilename, MOSFilesize, qwOpenMode
        mov hIEMOS, rax
        .IF hIEMOS == NULL
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile
            mov rax, NULL
            ret    
        .ENDIF
        .IF qwOpenMode == IEMOS_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov rbx, hIEMOS
            mov rax, MOSMemMapHandle
            mov [rbx].MOSINFO.MOSMemMapHandle, rax
            mov rax, hMOSFile
            mov [rbx].MOSINFO.MOSFileHandle, rax
        .ENDIF

    .ELSEIF SigReturn == MOS_VERSION_MOS_V20 ; MOSV2 - return false for the mo
      Invoke IEMOSMem, MOSMemMapPtr, lpszMosFilename, MOSFilesize, qwOpenMode
        mov hIEMOS, rax
        .IF hIEMOS == NULL
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile
            mov rax, NULL
            ret    
        .ENDIF
        .IF qwOpenMode == IEMOS_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov rbx, hIEMOS
            mov rax, MOSMemMapHandle
            mov [rbx].MOSINFO.MOSMemMapHandle, rax
            mov rax, hMOSFile
            mov [rbx].MOSINFO.MOSFileHandle, rax
        .ENDIF    
;        Invoke UnmapViewOfFile, MOSMemMapPtr
;        Invoke CloseHandle, MOSMemMapHandle
;        Invoke CloseHandle, hMOSFile
;        mov eax, NULL
;        ret    

    .ELSEIF SigReturn == MOS_VERSION_MOSCV10 ; MOSC
        Invoke MOSUncompress, hMOSFile, MOSMemMapPtr, Addr MOSFilesize
        .IF rax == 0
            Invoke UnmapViewOfFile, MOSMemMapPtr
            Invoke CloseHandle, MOSMemMapHandle
            Invoke CloseHandle, hMOSFile        
            mov rax, NULL
            ret
        .ENDIF
        mov pMOS, rax ; save uncompressed location to this var
        Invoke UnmapViewOfFile, MOSMemMapPtr
        Invoke CloseHandle, MOSMemMapHandle
        Invoke CloseHandle, hMOSFile        
        Invoke IEMOSMem, pMOS, lpszMosFilename, MOSFilesize, qwOpenMode
        mov hIEMOS, rax
        .IF hIEMOS == NULL
            Invoke GlobalFree, pMOS
            mov rax, NULL
            ret
        .ENDIF
   
    .ENDIF
    ; save original version to handle for later use so we know if orignal file opened was standard MOS or a compressed MOSC file, if 0 then it was in mem so we assume MOS
    mov rbx, hIEMOS
    mov rax, SigReturn
    mov [rbx].MOSINFO.MOSVersion, rax
    mov rax, hIEMOS
    ret
IEMOSOpen ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSClose - Close MOS File
;------------------------------------------------------------------------------
IEMOSClose PROC FRAME USES RBX hIEMOS:QWORD
    LOCAL qwOpenMode:QWORD
    LOCAL TotalTiles:QWORD
    LOCAL TileDataPtr:QWORD
    LOCAL ptrCurrentTileData:QWORD
    LOCAL nTile:QWORD
    LOCAL TileSizeRAW:QWORD
    
    .IF hIEMOS == NULL
        mov rax, 0
        ret
    .ENDIF

    mov rbx, hIEMOS
    mov rax, [ebx].MOSINFO.MOSOpenMode
    mov qwOpenMode, rax
    
    .IF rax == IEMOS_MODE_WRITE ; Write Mode
        mov rbx, hIEMOS
        mov rax, [rbx].MOSINFO.MOSHeaderPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF
        mov rbx, hIEMOS
        mov rax, [rbx].MOSINFO.MOSPaletteEntriesPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF

        mov rbx, hIEMOS
        mov rax, [rbx].MOSINFO.MOSTileLookupEntriesPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF

        mov rbx, hIEMOS
        mov rax, [rbx].MOSINFO.MOSBlockEntriesPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF        
    .ENDIF
    
    ; Loop through all TILEDATA entries and clear RAW and BMP
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSTileDataPtr
    mov TileDataPtr, rax
    mov ptrCurrentTileData, rax
    mov rax, [rbx].MOSINFO.MOSTotalTiles
    mov TotalTiles, rax
    
    .IF TotalTiles > 0 && TileDataPtr != 0
        mov nTile, 0
        mov rax, 0
        .WHILE rax < TotalTiles
            
            ; Delete Bitmap Handle
            mov rbx, ptrCurrentTileData
            mov rax, [rbx].TILEDATA.TileBitmapHandle
            .IF rax != NULL
                Invoke DeleteObject, rax
            .ENDIF
            
            .IF qwOpenMode == IEMOS_MODE_WRITE
                mov rbx, ptrCurrentTileData
                mov rax, [rbx].TILEDATA.TileRAW
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
            .ENDIF
            
            mov rbx, ptrCurrentTileData
            mov rax, [rbx].TILEDATA.TileBMP
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            
            add ptrCurrentTileData, SIZEOF TILEDATA
            inc nTile
            mov rax, nTile
        .ENDW
        
        ; Clear TILEDATA
        mov rax, TileDataPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF
    .ENDIF

    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSVersion
    .IF rax == MOS_VERSION_MOSCV10 ; MOSC in read or write mode uncompresed bam in memory needs to be cleared
        mov rbx, hIEMOS
        mov rax, [rbx].MOSINFO.MOSMemMapPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF    
    
    .ELSE ; MOS V1 or MOS V2 so if  opened in readonly, unmap file etc, otherwise free mem

        .IF qwOpenMode == IEMOS_MODE_READONLY ; Read Only
            mov rbx, hIEMOS
            mov rax, [rbx].MOSINFO.MOSMemMapPtr
            .IF rax != NULL
                Invoke UnmapViewOfFile, rax
            .ENDIF
            
            mov rbx, hIEMOS
            mov rax, [rbx].MOSINFO.MOSMemMapHandle
            .IF rax != NULL
                Invoke CloseHandle, rax
            .ENDIF

            mov rbx, hIEMOS
            mov rax, [rbx].MOSINFO.MOSFileHandle
            .IF rax != NULL
                Invoke CloseHandle, rax
            .ENDIF
       
        .ELSE ; free mem if write mode
            mov rbx, hIEMOS
            mov rax, [rbx].MOSINFO.MOSMemMapPtr
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
        .ENDIF

    .ENDIF
    
    mov rax, hIEMOS
    .IF rax != NULL
        Invoke GlobalFree, rax
    .ENDIF

    mov rax, 0
    ret
IEMOSClose ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSMem - Returns handle in rax of opened bam file that is already loaded 
; into memory. NULL if could not alloc enough mem calls MOSV1Mem or MOSV2Mem 
; depending on version of file found
;------------------------------------------------------------------------------
IEMOSMem PROC FRAME pMOSInMemory:QWORD, lpszMosFilename:QWORD, qwMosFilesize:QWORD, qwOpenMode:QWORD
    ; check signatures to determine version
    Invoke MOSSignature, pMOSInMemory

    .IF rax == MOS_VERSION_INVALID ; invalid file
        mov rax, NULL
        ret

    .ELSEIF rax == MOS_VERSION_MOS_V10
        Invoke MOSV1Mem, pMOSInMemory, lpszMosFilename, qwMosFilesize, qwOpenMode

    .ELSEIF rax == MOS_VERSION_MOS_V20
        Invoke MOSV2Mem, pMOSInMemory, lpszMosFilename, qwMosFilesize, qwOpenMode

    .ELSEIF rax == MOS_VERSION_MOSCV10
        Invoke MOSV1Mem, pMOSInMemory, lpszMosFilename, qwMosFilesize, qwOpenMode

    .ENDIF
    ret
IEMOSMem ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; MOSV1Mem - Returns handle in rax of opened bam file that is already loaded 
; into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
MOSV1Mem PROC FRAME USES RBX RCX RDX RDI RSI pMOSInMemory:QWORD, lpszMosFilename:QWORD, qwMosFilesize:QWORD, qwOpenMode:QWORD
    LOCAL hIEMOS:QWORD
    LOCAL MOSMemMapPtr:QWORD
    LOCAL OffsetPalettes:QWORD ; From raw mos
    LOCAL OffsetTileEntries:QWORD ; OffsetPalettes + (TotalTiles * 1024)
    LOCAL OffsetTileData:QWORD ; OffsetTileEntries + (TotalTiles * SIZEOF RGBQUAD)
    LOCAL ptrCurrentTileLookupEntry:QWORD ; begins with TileLookupEntriesPtr
    LOCAL ptrCurrentTileLookupEntryData:QWORD ; from TileLookupEntries DWORD pointers
    LOCAL ptrCurrentTileData:QWORD ; Current TILEDATA entry
    LOCAL ptrCurrentTilePalette:QWORD
    LOCAL ImageWidth:QWORD ; From raw mos
    LOCAL ImageHeight:QWORD ; From raw mos
    LOCAL BlockColumns:QWORD ; From raw mos
    LOCAL BlockRows:QWORD ; From raw mos
    LOCAL BlockSize:QWORD ; From raw mos
    LOCAL TotalTiles:QWORD ; BlockColumns * BlockRows
    LOCAL PaletteEntriesPtr:QWORD ; MEMMapped File / Alloced MEM
    LOCAL PaletteEntriesSize:QWORD ; TotalTiles * 1024
    LOCAL TileLookupEntriesPtr:QWORD ; MEMMapped File / Alloced MEM
    LOCAL TileLookupEntriesSize:QWORD ; TotalTiles * SIZEOF RGBQUAD
    LOCAL TileDataPtr:QWORD ; pointer to TILEDATA arrays
    LOCAL TileDataSize:QWORD ; size of all TILEDATA arrays
    LOCAL nTile:QWORD
    LOCAL TileX:QWORD
    LOCAL TileY:QWORD
    LOCAL TileH:QWORD
    LOCAL TileW:QWORD    
    LOCAL TileSizeRAW:QWORD
    LOCAL TileSizeBMP:QWORD
    LOCAL TileRAW:QWORD
    LOCAL TileBMP:QWORD
    LOCAL TileHeightAccumulative:QWORD

    mov rax, pMOSInMemory
    mov MOSMemMapPtr, rax       
    
    ;----------------------------------
    ; Alloc mem for our IEMOS Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF MOSINFO
    .IF rax == NULL
        ret
    .ENDIF
    mov hIEMOS, rax
    
    mov rbx, hIEMOS
    mov rax, qwOpenMode
    mov [rbx].MOSINFO.MOSOpenMode, rax
    mov rax, MOSMemMapPtr
    mov [rbx].MOSINFO.MOSMemMapPtr, rax
    
    lea rax, [rbx].MOSINFO.MOSFilename
    Invoke lstrcpy, rax, lpszMosFilename
    ;Invoke szCopy, lpszMosFilename, rax
    
    mov rbx, hIEMOS
    mov rax, qwMosFilesize
    mov [rbx].MOSINFO.MOSFilesize, rax

    ;----------------------------------
    ; MOS Header
    ;----------------------------------
    .IF qwOpenMode == IEMOS_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF MOSV1_HEADER
        .IF rax == NULL
            Invoke GlobalFree, hIEMOS
            mov rax, NULL
            ret
        .ENDIF    
        mov rbx, hIEMOS
        mov [rbx].MOSINFO.MOSHeaderPtr, rax
        mov rbx, MOSMemMapPtr
        Invoke RtlMoveMemory, rax, rbx, SIZEOF MOSV1_HEADER
    .ELSE
        mov rbx, hIEMOS
        mov rax, MOSMemMapPtr
        mov [rbx].MOSINFO.MOSHeaderPtr, rax
    .ENDIF
    mov rbx, hIEMOS
    mov rax, SIZEOF MOSV1_HEADER
    mov [rbx].MOSINFO.MOSHeaderSize, rax   

;    ;----------------------------------
;    ; Double check file in mem is MOS
;    ;----------------------------------
;    Invoke RtlZeroMemory, Addr MOSXHeader, SIZEOF MOSXHeader
;    Invoke RtlMoveMemory, Addr MOSXHeader, MOSMemMapPtr, 8d
;    Invoke lstrcmp, Addr MOSXHeader, Addr MOSV1Header
;    ;Invoke szCmp, Addr MOSXHeader, Addr MOSV1Header
;    .IF rax != 0 ; no match using lstrcmp
;    ;.IF rax == 0 ; no match using szCmp   
;        mov rbx, hIEMOS
;        mov rax, [rbx].MOSINFO.MOSHeaderPtr
;        .IF rax != NULL
;            Invoke GlobalFree, rax
;        .ENDIF
;        Invoke GlobalFree, hIEMOS
;        mov rax, NULL    
;        ret
;    .ENDIF

    ;----------------------------------
    ; Offsets & Sizes
    ;----------------------------------
    mov rbx, [rbx].MOSINFO.MOSHeaderPtr
    xor rax, rax
    movzx eax, word ptr [rbx].MOSV1_HEADER.ImageWidth
    mov ImageWidth, rax
    movzx eax, word ptr [rbx].MOSV1_HEADER.ImageHeight
    mov ImageHeight, rax
    movzx eax, word ptr [rbx].MOSV1_HEADER.BlockColumns
    mov BlockColumns, rax
    movzx eax, word ptr [rbx].MOSV1_HEADER.BlockRows
    mov BlockRows, rax
    mov eax, dword ptr [rbx].MOSV1_HEADER.BlockSize
    mov BlockSize, rax
    mov eax, dword ptr [rbx].MOSV1_HEADER.PalettesOffset
    mov OffsetPalettes, rax
    
    mov rax, BlockColumns
    mov rbx, BlockRows
    mul rbx
    mov TotalTiles, rax
    
    mov rax, TotalTiles
    mov rbx, SIZEOF DWORD
    mul rbx
    mov TileLookupEntriesSize, rax
    
    mov rax, TotalTiles
    mov rbx, 1024d ; size of palette
    mul rbx
    mov PaletteEntriesSize, rax
    add rax, OffsetPalettes
    mov OffsetTileEntries, rax
    add rax, TileLookupEntriesSize
    mov OffsetTileData, rax

    ; Store back to MOSINFO structure
    mov rbx, hIEMOS
    mov rax, ImageWidth
    mov [rbx].MOSINFO.MOSImageWidth, rax
    mov rax, ImageHeight
    mov [rbx].MOSINFO.MOSImageHeight, rax
    mov rax, BlockColumns
    mov [rbx].MOSINFO.MOSBlockColumns, rax
    mov rax, BlockRows
    mov [rbx].MOSINFO.MOSBlockRows, rax
    mov rax, BlockSize
    mov [rbx].MOSINFO.MOSBlockSize, rax
    mov rax, TotalTiles
    mov [rbx].MOSINFO.MOSTotalTiles, rax

    ;----------------------------------
    ; Palette
    ;----------------------------------      
    .IF qwOpenMode == IEMOS_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, PaletteEntriesSize ; alloc space for palettes
        .IF rax == NULL
            mov rbx, hIEMOS
            mov rax, [rbx].MOSINFO.MOSHeaderPtr
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            Invoke GlobalFree, hIEMOS
            mov rax, NULL    
            ret
        .ENDIF
        mov rbx, hIEMOS
        mov [rbx].MOSINFO.MOSPaletteEntriesPtr, rax
        mov PaletteEntriesPtr, rax

        mov rbx, MOSMemMapPtr
        add rbx, OffsetPalettes
        Invoke RtlMoveMemory, rax, rbx, PaletteEntriesSize
    .ELSE
        mov rbx, hIEMOS
        mov rax, MOSMemMapPtr
        add rax, OffsetPalettes
        mov [rbx].MOSINFO.MOSPaletteEntriesPtr, rax
        mov PaletteEntriesPtr, rax
    .ENDIF
;    ; copy palette to our bitmap header palette var
;    Invoke RtlMoveMemory, Addr MOSBMPPalette, PaletteEntriesPtr, PaletteEntriesSize    

    ;----------------------------------
    ; Tile Entries
    ;----------------------------------
    .IF TotalTiles > 0
        .IF qwOpenMode == IEMOS_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileLookupEntriesSize
            .IF rax == NULL
                mov rbx, hIEMOS
                mov rax, [rbx].MOSINFO.MOSHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rax, [rbx].MOSINFO.MOSPaletteEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                Invoke GlobalFree, hIEMOS
                mov rax, NULL    
                ret
            .ENDIF    
            mov rbx, hIEMOS
            mov [rbx].MOSINFO.MOSTileLookupEntriesPtr, rax
            mov TileLookupEntriesPtr, rax
        
            mov rbx, MOSMemMapPtr
            add rbx, OffsetTileEntries
            Invoke RtlMoveMemory, rax, rbx, TileLookupEntriesSize
        .ELSE
            mov rbx, hIEMOS
            mov rax, MOSMemMapPtr
            add rax, OffsetTileEntries
            mov [rbx].MOSINFO.MOSTileLookupEntriesPtr, rax
            mov TileLookupEntriesPtr, rax
        .ENDIF
        mov rbx, hIEMOS
        mov rax, TileLookupEntriesSize
        mov [rbx].MOSINFO.MOSTileLookupEntriesSize, rax    
    .ELSE
        mov rbx, hIEMOS
        mov [rbx].MOSINFO.MOSTileLookupEntriesPtr, 0
        mov [rbx].MOSINFO.MOSTileLookupEntriesSize, 0
        mov TileLookupEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Alloc space for Tile Data
    ;----------------------------------
    ; loop throught tile data blocks and copy to TILEDATA.TileRAW
    ; Convert TileRAW to TileBMP for blitting later on.
    .IF TotalTiles > 0
        mov rax, TotalTiles
        mov rbx, SIZEOF TILEDATA
        mul rbx
        mov TileDataSize, rax
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileDataSize
        .IF rax == NULL
            mov rbx, hIEMOS
            mov rax, [rbx].MOSINFO.MOSHeaderPtr
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            mov rax, [rbx].MOSINFO.MOSPaletteEntriesPtr
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            mov rax, [rbx].MOSINFO.MOSTileLookupEntriesPtr
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF            
            Invoke GlobalFree, hIEMOS
            mov rax, NULL    
            ret
        .ENDIF
        mov rbx, hIEMOS
        mov [rbx].MOSINFO.MOSTileDataPtr, rax
        mov TileDataPtr, rax
        mov rax, TileDataSize
        mov [rbx].MOSINFO.MOSTileDataSize, rax        
        
        ; Setup for loop
        mov rax, TileLookupEntriesPtr
        mov ptrCurrentTileLookupEntry, rax
     
        mov rax, MOSMemMapPtr
        add rax, OffsetTileData
        mov ptrCurrentTileLookupEntryData, rax
        
        mov rax, TileDataPtr
        mov ptrCurrentTileData, rax
        
        mov rax, PaletteEntriesPtr
        mov ptrCurrentTilePalette, rax
        
        mov TileX, 0
        mov TileY, 0
        
        mov rax, 0
        mov nTile, 0
        .WHILE rax < TotalTiles

            mov rbx, ptrCurrentTileLookupEntry
            mov eax, dword ptr [rbx]
            add rax, MOSMemMapPtr
            add rax, OffsetTileData  
            mov ptrCurrentTileLookupEntryData, rax
            
            ;----------------------------------
            ; Calc Tile Data INFO
            ;----------------------------------
            Invoke MOSGetTileDataHeight, nTile, BlockRows, BlockColumns, BlockSize, ImageHeight ; uses RCX RDX - make sure USES above includes this
            mov TileH, rax
            Invoke MOSGetTileDataWidth, nTile, BlockColumns, BlockSize, ImageWidth ; uses RCX RDX - make sure USES above includes this
            mov TileW, rax
            mov rbx, TileH
            mul rbx
            mov TileSizeRAW, rax
            
            ; Calc BMP DWORD aligned width
            Invoke MOSCalcDwordAligned, TileW
            mov rbx, TileH
            mul rbx
            mov TileSizeBMP, rax

            .IF TileX == 0
                mov rax, TileH
                add TileHeightAccumulative, rax
            .ENDIF

            ;----------------------------------
            ; TILE DATA ENTRY RAW
            ;----------------------------------
            .IF qwOpenMode == IEMOS_MODE_WRITE ; Alloc mem for TileRAW
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileSizeRAW
                mov TileRAW, rax
                .IF rax != NULL
                    Invoke RtlMoveMemory, TileRAW, ptrCurrentTileLookupEntryData, TileSizeRAW
                .ENDIF
            .ELSE
                mov rax, ptrCurrentTileLookupEntryData
                mov TileRAW, rax
            .ENDIF
            mov rbx, ptrCurrentTileData
            mov rax, TileRAW
            mov [rbx].TILEDATA.TileRAW, rax
            mov rax, TileSizeRAW
            mov [rbx].TILEDATA.TileSizeRAW, rax

            ;----------------------------------
            ; TILE DATA ENTRY BMP
            ;----------------------------------
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, TileSizeBMP ; Alloc mem for TileBMP
            mov TileBMP, rax
            .IF rax != NULL
                mov rax, TileSizeBMP
                .IF rax == TileSizeRAW ; raw = bmp, otherwise if not equal size we have to convert to bmp below
                    Invoke RtlMoveMemory, TileBMP, ptrCurrentTileLookupEntryData, TileSizeRAW
                .ENDIF
            .ENDIF
            mov rbx, ptrCurrentTileData
            mov rax, TileBMP
            mov [rbx].TILEDATA.TileBMP, rax
            mov rax, TileSizeBMP
            mov [rbx].TILEDATA.TileSizeBMP, rax
            
            ; convert RAW to BMP
            mov rax, TileSizeBMP
            .IF rax > TileSizeRAW
                ; Only convert raw pixel data to dword aligned bmp palette data if BMP size for dword aligned > RAW size
                Invoke MOSTileDataRAWtoBMP, TileRAW, TileBMP, TileSizeRAW, TileSizeBMP, TileW ; uses RDI RSI - make sure USES above includes this
            .ENDIF            
            
            ;----------------------------------
            ; TILE DATA ENTRY INFO
            ;----------------------------------
            ; Save Tile Data: X,Y,W,H,RAW,BMP,Sizes
            mov rbx, ptrCurrentTileData
            mov rax, TileX
            mov [rbx].TILEDATA.TileX, rax
            mov rax, TileY
            mov [rbx].TILEDATA.TileY, rax
            mov rax, TileH
            mov [rbx].TILEDATA.TileH, rax
            mov rax, TileW
            mov [rbx].TILEDATA.TileW, rax
            mov rax, ptrCurrentTilePalette
            mov [rbx].TILEDATA.TilePalette, rax
            
            ;----------------------------------
            ; TILE DATA BITMAP
            ;----------------------------------
            ;Invoke MOSTileDataBitmap, TileH, TileW, TileBMP, TileSizeBMP, ptrCurrentTilePalette
            ;mov ebx, ptrCurrentTileData
            ;mov [ebx].TILEDATA.TileBitmapHandle, eax
            
            ;----------------------------------
            ; Calc TileX/Y for next entry
            ;----------------------------------
            mov rax, TileW
            add rax, TileX
            .IF rax >= ImageWidth
                mov TileX, 0 ; reset TileX if greater than imagewidth
                mov rax, TileHeightAccumulative
                mov TileY, rax
            .ELSE
                mov TileX, rax
            .ENDIF

            ; Setup stuff for next entry
            add ptrCurrentTilePalette, 1024
            add ptrCurrentTileData, SIZEOF TILEDATA
            add ptrCurrentTileLookupEntry, SIZEOF DWORD
            inc nTile
            mov rax, nTile
        .ENDW

    .ELSE
        mov rbx, hIEMOS
        mov [rbx].MOSINFO.MOSTileDataPtr, 0
        mov [rbx].MOSINFO.MOSTileDataSize, 0
    .ENDIF
 

    mov rax, hIEMOS
    ret
MOSV1Mem ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; MOSV2Mem - Returns handle in rax of opened bam file that is already loaded 
; into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
MOSV2Mem PROC FRAME USES RBX RCX RDX RDI RSI pMOSInMemory:QWORD, lpszMosFilename:QWORD, qwMosFilesize:QWORD, qwOpenMode:QWORD
    LOCAL hIEMOS:QWORD
    LOCAL MOSMemMapPtr:QWORD
    LOCAL TotalBlockEntries:QWORD
    LOCAL BlockEntriesSize:QWORD
    LOCAL OffsetBlockEntries:QWORD
    LOCAL BlockEntriesPtr:QWORD
    LOCAL DataBlockIndex:QWORD
    LOCAL DataBlockCount:QWORD

    mov rax, pMOSInMemory
    mov MOSMemMapPtr, rax      

    ;----------------------------------
    ; Alloc mem for our IEMOS Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF MOSINFO
    .IF rax == NULL
        ret
    .ENDIF
    mov hIEMOS, rax
    
    mov rbx, hIEMOS
    mov rax, qwOpenMode
    mov [rbx].MOSINFO.MOSOpenMode, rax
    mov rax, MOSMemMapPtr
    mov [rbx].MOSINFO.MOSMemMapPtr, rax
    
    lea rax, [rbx].MOSINFO.MOSFilename
    Invoke lstrcpy, rax, lpszMosFilename
    ;Invoke szCopy, lpszMosFilename, rax
    
    mov rbx, hIEMOS
    mov rax, qwMosFilesize
    mov [rbx].MOSINFO.MOSFilesize, rax

    ;----------------------------------
    ; MOS Header
    ;----------------------------------
    .IF qwOpenMode == IEMOS_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF MOSV2_HEADER
        .IF rax == NULL
            Invoke GlobalFree, hIEMOS
            mov rax, NULL
            ret
        .ENDIF    
        mov rbx, hIEMOS
        mov [rbx].MOSINFO.MOSHeaderPtr, rax
        mov rbx, MOSMemMapPtr
        Invoke RtlMoveMemory, rax, rbx, SIZEOF MOSV2_HEADER
    .ELSE
        mov rbx, hIEMOS
        mov rax, MOSMemMapPtr
        mov [rbx].MOSINFO.MOSHeaderPtr, rax
    .ENDIF
    mov rbx, hIEMOS
    mov rax, SIZEOF MOSV2_HEADER
    mov [rbx].MOSINFO.MOSHeaderSize, rax   

    ;----------------------------------
    ; Frame & Cycle Counts, Offsets & Sizes
    ;----------------------------------
    mov rbx, [rbx].MOSINFO.MOSHeaderPtr
    xor rax, rax
    mov eax, dword ptr [rbx].MOSV2_HEADER.BlockEntriesCount
    mov TotalBlockEntries, rax
    mov eax, dword ptr [rbx].MOSV2_HEADER.BlockEntriesOffset
    mov OffsetBlockEntries, rax

    mov rax, TotalBlockEntries
    mov rbx, SIZEOF DATABLOCK_ENTRY
    mul rbx
    mov BlockEntriesSize, rax

    ;----------------------------------
    ; No Palette for MOS V2!
    ;----------------------------------
    mov rbx, hIEMOS
    mov [rbx].MOSINFO.MOSPaletteEntriesPtr, 0
    mov [rbx].MOSINFO.MOSPaletteEntriesSize, 0

    ;----------------------------------
    ; Data Block Entries
    ;----------------------------------
    .IF TotalBlockEntries > 0
        .IF qwOpenMode == IEMOS_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, BlockEntriesSize
            .IF rax == NULL
                mov rbx, hIEMOS
                mov rax, [rbx].MOSINFO.MOSHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                Invoke GlobalFree, hIEMOS
                mov rax, NULL    
                ret
            .ENDIF    
            mov rbx, hIEMOS
            mov [rbx].MOSINFO.MOSBlockEntriesPtr, rax
            mov BlockEntriesPtr, rax
        
            mov rbx, MOSMemMapPtr
            add rbx, OffsetBlockEntries
            Invoke RtlMoveMemory, rax, rbx, BlockEntriesSize
        .ELSE
            mov rbx, hIEMOS
            mov rax, MOSMemMapPtr
            add rax, OffsetBlockEntries
            mov [rbx].MOSINFO.MOSBlockEntriesPtr, rax
            mov BlockEntriesPtr, rax
        .ENDIF
        mov rbx, hIEMOS
        mov rax, BlockEntriesSize
        mov [rbx].MOSINFO.MOSBlockEntriesSize, rax   
    .ELSE
        mov rbx, hIEMOS
        mov [rbx].MOSINFO.MOSBlockEntriesPtr, 0
        mov [rbx].MOSINFO.MOSBlockEntriesSize, 0
        mov BlockEntriesPtr, 0
    .ENDIF

    mov rax, hIEMOS 
    ret
MOSV2Mem ENDP


IEMOS_LIBEND








