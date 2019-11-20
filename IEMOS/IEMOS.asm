;==============================================================================
;
; IEMOS x64
;
; Copyright (c) 2018 by fearless
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


;include masm64.inc
include zlibstat.inc

;includelib masm64.lib
includelib zlibstat128.lib


include IEMOS.inc

; Internal functions start with MOS
; External functions start with IEMOS 


;-------------------------------------------------------------------------
; Internal functions:
;-------------------------------------------------------------------------
MOSUncompress           PROTO :QWORD, :QWORD, :QWORD

MOSV1Mem                PROTO :QWORD, :QWORD, :QWORD, :QWORD
MOSV2Mem                PROTO :QWORD, :QWORD, :QWORD, :QWORD

MOSGetTileDataWidth     PROTO :QWORD, :QWORD, :QWORD, :QWORD
MOSGetTileDataHeight    PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD

MOSCalcDwordAligned     PROTO :QWORD
MOSTileDataRAWtoBMP     PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
MOSTileDataBitmap       PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD
MOSBitmapToTiles        PROTO :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD, :QWORD

EXTERNDEF MOSSignature  :PROTO :QWORD
;EXTERNDEF MOSUncompress :PROTO :QWORD, :QWORD, :QWORD
EXTERNDEF MOSJustFname  :PROTO :QWORD, :QWORD


;-------------------------------------------------------------------------
; MOS Structures
;-------------------------------------------------------------------------
IFNDEF MOSV1_HEADER
MOSV1_HEADER            STRUCT
    Signature           DD 0    ; 0x0000 	4 (char array) 	Signature ('MOS ')
    Version             DD 0    ; 0x0004 	4 (char array) 	Version ('V1 ')
    ImageWidth          DW 0    ; 0x0008 	2 (word) 	    Width (pixels)
    ImageHeight         DW 0    ; 0x000a 	2 (word) 	    Height (pixels)
    BlockColumns        DW 0    ; 0x000c 	2 (word) 	    Columns (blocks)
    BlockRows           DW 0    ; 0x000e 	2 (word) 	    Rows (blocks)
    BlockSize           DD 0    ; 0x0010 	4 (dword) 	    Block size (pixels)
    PalettesOffset      DD 0    ; 0x0014 	4 (dword) 	    Offset (from start of file) to palettes
MOSV1_HEADER            ENDS
ENDIF

IFNDEF MOSV2_HEADER
MOSV2_HEADER            STRUCT
    Signature           DD 0    ; 0x0000 	4 (char array) 	Signature ('MOS ')
    Version             DD 0    ; 0x0004 	4 (char array) 	Version ('V2 ')
    ImageWidth          DD 0    ; 0x0008 	4 (dword) 	    Width (pixels)
    ImageHeight         DD 0    ; 0x000c 	4 (dword) 	    Height (pixels)
    BlockEntriesCount   DD 0    ; 0x0010 	4 (dword) 	    Number of data blocks
    BlockEntriesOffset  DD 0    ; 0x0014 	4 (dword) 	    Offset to data blocks
MOSV2_HEADER            ENDS
ENDIF

IFNDEF MOSC_HEADER
MOSC_HEADER             STRUCT
    Signature           DD 0    ; 0x0000   4 (bytes)        Signature ('MOSC')
    Version             DD 0    ; 0x0004   4 (bytes)        Version ('V1 ')
    UncompressedLength  DD 0    ; 0x0008   4 (dword)        Uncompressed data length
MOSC_HEADER             ENDS
ENDIF

IFNDEF DATABLOCK_ENTRY  ; Used in MOS V2
DATABLOCK_ENTRY         STRUCT
    PVRZPage            DD 0
    SourceXCoord        DD 0
    SourceYCoord        DD 0
    FrameWidth          DD 0
    FrameHeight         DD 0
    TargetXCoord        DD 0
    TargetYCoord        DD 0
DATABLOCK_ENTRY         ENDS
ENDIF

IFNDEF TILELOOKUP_ENTRY
TILELOOKUP_ENTRY        STRUCT
    TileDataOffset      DD 0    ; Offset to specific tile's data pixels from start of Tile Data ( Offset Palettes + (Size Palettes) + (Size TilelookupEntries) )
TILELOOKUP_ENTRY        ENDS
ENDIF

IFNDEF TILEDATA
TILEDATA                STRUCT
    TileX               DQ 0
    TileY               DQ 0
    TileW               DQ 0
    TileH               DQ 0
    TileSizeRAW         DQ 0
    TileSizeBMP         DQ 0
    TilePalette         DQ 0
    TileRAW             DQ 0
    TileBMP             DQ 0
    TileBitmapHandle    DQ 0
TILEDATA                ENDS
ENDIF

;-------------------------------------------------------------------------
; Structures for internal use
;-------------------------------------------------------------------------
IFNDEF MOSINFO
MOSINFO                     STRUCT
    MOSOpenMode             DQ 0
    MOSFilename             DB MAX_PATH DUP (0)
    MOSFilesize             DQ 0
    MOSVersion              DQ 0
    MOSCompressed           DQ 0
    MOSHeaderPtr            DQ 0
    MOSHeaderSize           DQ 0
    MOSImageWidth           DQ 0
    MOSImageHeight          DQ 0
    MOSBlockColumns         DQ 0 ; MOS V1
    MOSBlockRows            DQ 0 ; MOS V1
    MOSBlockSize            DQ 0 ; MOS V1
    MOSTotalTiles           DQ 0 ; MOS V1
    MOSPaletteEntriesPtr    DQ 0 ; no interal palette for MOS V2
    MOSPaletteEntriesSize   DQ 0 ; MOS V1
    MOSTileLookupEntriesPtr DQ 0 ; MOS V1 ; TileLookup Entries
    MOSTileLookupEntriesSize DQ 0 ; MOS V1
    MOSTileDataPtr          DQ 0 
    MOSTileDataSize         DQ 0
    MOSBlockEntriesPtr      DQ 0 ; for MOS V2
    MOSBlockEntriesSize     DQ 0 ; for MOS V2
    MOSMemMapPtr            DQ 0
    MOSMemMapHandle         DQ 0
    MOSFileHandle           DQ 0    
MOSINFO                     ENDS
ENDIF

.CONST
BLOCKSIZE_DEFAULT           EQU 64


.DATA
MOSV1Header                 DB "MOS V1  ",0
MOSV2Header                 DB "MOS V2  ",0
MOSCHeader                  DB "MOSCV1  ",0
MOSXHeader                  DB 12 dup (0)
MOSTileBitmap               DB (SIZEOF BITMAPINFOHEADER + 1024) dup (0)
szMOSDisplayDC              DB 'DISPLAY',0

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
        .IF eax == 0
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
    
    .IF TotalTiles > 0
        mov nTile, 0
        mov rax, 0
        .WHILE rax < TotalTiles
            mov rbx, ptrCurrentTileData
            .IF qwOpenMode == IEMOS_MODE_WRITE ; Write Mode
                mov rax, [rbx].TILEDATA.TileRAW
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
            .ENDIF
            
            mov rbx, ptrCurrentTileData
            mov rax, [rbx].TILEDATA.TileSizeRAW
            mov TileSizeRAW, rax
            
            ; Clear memory of TileBMP if we had to convert TileRAW to a DWORD aligned TileBMP
            ; File size will be greater in TileBMP if this is so.
            mov rax, [rbx].TILEDATA.TileSizeBMP
            .IF rax > TileSizeRAW            
                mov rax, [rbx].TILEDATA.TileBMP
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
            .ENDIF
            
            ; Delete Bitmap Handle
            mov rbx, ptrCurrentTileData
            mov rax, [rbx].TILEDATA.TileBitmapHandle
            .IF rax != NULL
                Invoke DeleteObject, rax
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
; IEMOSMem - Returns handle in eax of opened bam file that is already loaded 
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
; MOSV1Mem - Returns handle in eax of opened bam file that is already loaded 
; into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
MOSV1Mem PROC FRAME USES RBX RCX RDX RDX pMOSInMemory:QWORD, lpszMosFilename:QWORD, qwMosFilesize:QWORD, qwOpenMode:QWORD
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

    ;----------------------------------
    ; Double check file in mem is MOS
    ;----------------------------------
    Invoke RtlZeroMemory, Addr MOSXHeader, SIZEOF MOSXHeader
    Invoke RtlMoveMemory, Addr MOSXHeader, MOSMemMapPtr, 8d
    Invoke lstrcmp, Addr MOSXHeader, Addr MOSV1Header
    ;Invoke szCmp, Addr MOSXHeader, Addr MOSV1Header
    .IF rax != 0 ; no match using lstrcmp
    ;.IF rax == 0 ; no match using szCmp   
        mov rbx, hIEMOS
        mov rax, [rbx].MOSINFO.MOSHeaderPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF
        Invoke GlobalFree, hIEMOS
        mov rax, NULL    
        ret
    .ENDIF

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
            Invoke MOSGetTileDataHeight, nTile, BlockRows, BlockColumns, BlockSize, ImageHeight
            mov TileH, rax
            Invoke MOSGetTileDataWidth, nTile, BlockColumns, BlockSize, ImageWidth
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
                Invoke MOSTileDataRAWtoBMP, TileRAW, TileBMP, TileSizeRAW, TileSizeBMP, TileW
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
; MOSV2Mem - Returns handle in eax of opened bam file that is already loaded 
; into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
MOSV2Mem PROC FRAME USES RBX RCX RDX pMOSInMemory:QWORD, lpszMosFilename:QWORD, qwMosFilesize:QWORD, qwOpenMode:QWORD
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


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSHeader - Returns in eax a pointer to header or NULL if not valid
;------------------------------------------------------------------------------
IEMOSHeader PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSHeaderPtr
    ret
IEMOSHeader ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileLookupEntries - Returns in eax a pointer to the array of TileLookup 
; entries (DWORDs) or NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileLookupEntries PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSTileLookupEntriesPtr
    ret
IEMOSTileLookupEntries ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileLookupEntry - Returns in eax a pointer to specific TileLookup entry
; which if read (DWORD) is an offset to the Tile Data from start of tile pixel 
; data.
;------------------------------------------------------------------------------
IEMOSTileLookupEntry PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    LOCAL TileLookupEntries:QWORD
    
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
    
    Invoke IEMOSTileLookupEntries, hIEMOS
    .IF rax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains TileLookupEntries which is tile 0's start
        ret
    .ENDIF    
    mov TileLookupEntries, rax
    
    mov rax, nTile
    mov rbx, SIZEOF DWORD
    mul rbx
    add rax, TileLookupEntries
    
    ret
IEMOSTileLookupEntry ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileDataEntries - Returns in eax a pointer to the array of TILEDATA or 
; NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileDataEntries PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSTileDataPtr
    ret
IEMOSTileDataEntries ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileDataEntry - Returns in eax a pointer to a specific TILEDATA entry or
; NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileDataEntry PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    LOCAL TileDataEntries:QWORD
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
    
    Invoke IEMOSTileDataEntries, hIEMOS
    .IF rax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains TileDataEntries which is tile 0's start
        ret
    .ENDIF    
    mov TileDataEntries, rax    
    
    mov rax, nTile
    mov rbx, SIZEOF TILEDATA
    mul rbx
    add rax, TileDataEntries    
    
    ret
IEMOSTileDataEntry ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTotalTiles - Returns in eax total tiles in mos
;------------------------------------------------------------------------------
IEMOSTotalTiles PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSTotalTiles
    ret
IEMOSTotalTiles ENDP


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


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSColumnsRows - Returns columns and rows in pointer to variables 
; provided
;------------------------------------------------------------------------------
IEMOSColumnsRows PROC FRAME USES RBX hIEMOS:QWORD, lpqwColumns:QWORD, lpqwRows:QWORD
    LOCAL qwColumns:QWORD
    LOCAL qwRows:QWORD
    mov qwColumns, 0
    mov qwRows, 0
    .IF hIEMOS != NULL
        mov rbx, hIEMOS
        mov rbx, [rbx].MOSINFO.MOSHeaderPtr
        .IF rbx != NULL
            movzx rax, word ptr [rbx].MOSV1_HEADER.BlockColumns
            mov qwColumns, rax
            movzx rax, word ptr [rbx].MOSV1_HEADER.BlockRows
            mov qwRows, rax
        .ENDIF
    .ENDIF
    .IF lpqwColumns != NULL
        mov rbx, lpqwColumns
        mov rax, qwColumns
        mov [rbx], rax
    .ENDIF
    .IF lpqwRows != NULL
        mov rbx, lpqwRows
        mov rax, qwRows
        mov [rbx], rax
    .ENDIF
    xor rax, rax
    ret
IEMOSColumnsRows ENDP


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


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSPalettes - Returns in eax a pointer to the palettes or NULL if not valid
;------------------------------------------------------------------------------
IEMOSPalettes PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSPaletteEntriesPtr
    ret
IEMOSPalettes ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTilePalette - Returns in eax a pointer to the tile palette or NULL if 
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
        ; eax contains PaletteOffset which is tile 0's palette start
        ret
    .ENDIF
    mov PaletteOffset, rax    
    
    mov rax, nTile
    mov rbx, 1024 ;(256 * SIZEOF DWORD)
    mul rbx
    add rax, PaletteOffset
    
    ret
IEMOSTilePalette ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTilePaletteValue - Returns in eax a RGBQUAD of the specified 
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


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTotalPalettes - Returns in eax total palettes (= total tiles) in mos
;------------------------------------------------------------------------------
IEMOSTotalPalettes PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSTotalTiles
    ret
IEMOSTotalPalettes ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTotalBlockEntries - Returns in eax the total no of data block entries
;------------------------------------------------------------------------------
IEMOSTotalBlockEntries PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, 0
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rbx, [rbx].MOSINFO.MOSHeaderPtr
    mov eax, dword ptr [rbx].MOSV2_HEADER.BlockEntriesCount
    ret
IEMOSTotalBlockEntries ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSBlockEntries - Returns in eax a pointer to data block entries or NULL if
; not valid
;------------------------------------------------------------------------------
IEMOSBlockEntries PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSBlockEntriesPtr
    .IF rax == NULL
        mov rax, NULL
    .ENDIF    
    ret
IEMOSBlockEntries ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSBlockEntry - Returns in eax a pointer to the specified Datablock entry 
; or NULL
;------------------------------------------------------------------------------
IEMOSBlockEntry PROC FRAME USES RBX hIEMOS:QWORD, nBlockEntry:QWORD
    LOCAL BlockEntriesPtr:QWORD
    
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEMOSTotalBlockEntries, hIEMOS
    .IF rax == 0
        mov rax, NULL
        ret
    .ENDIF
    ; eax contains TotalBlockEntries
     .IF nBlockEntry >= rax
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEMOSBlockEntries, hIEMOS
    .IF rax == NULL
        ret
    .ENDIF
    mov BlockEntriesPtr, rax
    
    mov rax, nBlockEntry
    mov rbx, SIZEOF DATABLOCK_ENTRY
    mul rbx
    add rax, BlockEntriesPtr
    ret
IEMOSBlockEntry ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileBitmap - Returns in eax HBITMAP or NULL. Optional variables pointed 
; to, are filled in if eax is a HBITMAP (!NULL), otherwise vars (if supplied) 
; will be set to 0
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
    .IF eax == NULL
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


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileBitmap - Returns HBITMAP (of all combined tile bitmaps) or NULL.
;------------------------------------------------------------------------------
IEMOSBitmap PROC FRAME hIEMOS:QWORD
    LOCAL hdc:QWORD
    LOCAL hdcMem:QWORD
    LOCAL hdcTile:QWORD
    LOCAL SavedDCTile:QWORD
    LOCAL hBitmap:QWORD
    LOCAL hOldBitmap:QWORD
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
    
    Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
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
        .ENDIF

        inc nTile
        mov rax, nTile
    .ENDW
    
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
    .ENDIF
    Invoke RestoreDC, hdcTile, dword ptr SavedDCTile
    Invoke DeleteDC, hdcTile
    Invoke DeleteDC, hdcMem
    Invoke DeleteDC, hdc
    
    mov rax, hBitmap
    ret
IEMOSBitmap ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileWidth - Returns in eax width of tile.
;------------------------------------------------------------------------------
IEMOSTileWidth PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF rax == NULL
        ret
    .ENDIF
    mov rbx, rax
    mov rax, [rbx].TILEDATA.TileW
    ret
IEMOSTileWidth ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileHeight - Returns in eax height of tile.
;------------------------------------------------------------------------------
IEMOSTileHeight PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF rax == NULL
        ret
    .ENDIF
    mov rbx, rax
    mov rax, [rbx].TILEDATA.TileH
    ret
IEMOSTileHeight ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileXCoord - Returns in eax x coord of tile.
;------------------------------------------------------------------------------
IEMOSTileXCoord PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF rax == NULL
        ret
    .ENDIF
    mov rbx, rax
    mov rax, [rbx].TILEDATA.TileX
    ret
IEMOSTileXCoord ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileYCoord - Returns in eax y coord of tile.
;------------------------------------------------------------------------------
IEMOSTileYCoord PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF rax == NULL
        ret
    .ENDIF
    mov rbx, rax
    mov rax, [rbx].TILEDATA.TileY
    ret
IEMOSTileYCoord ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileRAW - Returns in eax pointer to RAW tile data.
;------------------------------------------------------------------------------
IEMOSTileRAW PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF rax == NULL
        ret
    .ENDIF
    mov rbx, rax
    mov rax, [rbx].TILEDATA.TileRAW
    ret
IEMOSTileRAW ENDP


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileName - returns in eax pointer to zero terminated string contained 
; filename that is open or NULL if not opened
;------------------------------------------------------------------------------
IEMOSFileName PROC FRAME USES RBX hIEMOS:QWORD
    LOCAL MosFilename:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    lea rax, [rbx].MOSINFO.MOSFilename
    mov MosFilename, rax
    Invoke lstrlen, MosFilename
    ;Invoke szLen, MosFilename
    .IF rax == 0
        mov rax, NULL
    .ELSE
        mov rax, MosFilename
    .ENDIF
    ret
IEMOSFileName endp


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileNameOnly - returns in eax true or false if it managed to pass to the 
; buffer pointed at lpszFileNameOnly, the stripped filename without extension
;------------------------------------------------------------------------------
IEMOSFileNameOnly PROC FRAME hIEMOS:QWORD, lpszFileNameOnly:QWORD
    Invoke IEMOSFileName, hIEMOS
    .IF rax == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MOSJustFname, rax, lpszFileNameOnly
    
    mov rax, TRUE
    ret
IEMOSFileNameOnly endp


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileSize - returns in eax size of file or NULL
;------------------------------------------------------------------------------
IEMOSFileSize PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSFilesize
    ret
IEMOSFileSize endp


IEMOS_ALIGN
;------------------------------------------------------------------------------
; -1 = No Mos file, TRUE for MOSCV1, FALSE for MOS V1 or MOS V2 
;------------------------------------------------------------------------------
IEMOSFileCompression PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, -1
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSVersion
    .IF rax == MOS_VERSION_MOSCV10
        mov rax, TRUE
    .ELSE
        mov rax, FALSE
    .ENDIF
    ret
IEMOSFileCompression endp


IEMOS_ALIGN
;------------------------------------------------------------------------------
; 0 = No Mos file, 1 = MOS V1, 2 = MOS V2, 3 = MOSCV1 
;------------------------------------------------------------------------------
IEMOSVersion PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSVersion
    ret
IEMOSVersion ENDP



; INTERNAL FUNCTIONS




IEMOS_ALIGN
;******************************************************************************
; Returns in eax width of data block as blocksize if column < columns -1
; (column = nTile % columns)
; 
; otherwise returns in eax: imagewidth - (column * blocksize)
;******************************************************************************
MOSGetTileDataWidth PROC FRAME USES RBX RCX RDX nTile:QWORD, qwBlockColumns:QWORD, qwBlockSize:QWORD, qwImageWidth:QWORD
    LOCAL COLSmod:QWORD
    
    mov rax, qwBlockColumns
    dec rax
    mov COLSmod, rax
    
    mov rax, qwBlockColumns
    and rax, 1 ; ( a AND (b-1) = mod )
    .IF rax == 0 ; is divisable by 2?
        mov rax, nTile
        and rax, COLSmod ; then use (a AND (b-1)) instead of div to get modulus
        ; eax = column
        .IF rax < COLSmod
            mov rax, qwBlockSize
            ret
        .ENDIF
    .ELSE ; Use div for modulus otherwise
        xor rdx, rdx
        mov rax, nTile
        mov rcx, qwBlockColumns
        div rcx
        mov rax, rdx
        ; eax = column
        .IF rax < COLSmod
            mov rax, qwBlockSize
            ret
        .ENDIF
    .ENDIF
    ; eax is column
    mov rbx, qwBlockSize
    mul rbx
    mov rbx, rax
    mov rax, qwImageWidth
    sub rax, rbx
    ; eax = imagewidth - (columns * blocksize)
    ret
MOSGetTileDataWidth ENDP


IEMOS_ALIGN
;******************************************************************************
; Returns in eax height of data block as blocksize if row < rows -1
; (row = nTile / columns)
;
; otherwise returns in eax: imageheight - (row * blocksize)
;******************************************************************************
MOSGetTileDataHeight PROC FRAME USES RBX RCX RDX nTile:QWORD, qwBlockRows:QWORD, qwBlockColumns:QWORD, qwBlockSize:QWORD, qwImageHeight:QWORD
    LOCAL ROWSmod:QWORD
    
    mov rax, qwBlockRows
    dec rax
    mov ROWSmod, rax
    
    ; row = nTile / columns
    xor rdx, rdx
    mov rax, nTile
    mov rcx, qwBlockColumns
    div rcx
    ; eax is row
    .IF rax < ROWSmod
        mov rax, qwBlockSize
    .ELSE
        ; eax is row
        mov rbx, qwBlockSize
        mul rbx
        mov rbx, rax
        mov rax, qwImageHeight
        sub rax, rbx
        ; eax = imageheight - (row * blocksize)
    .ENDIF
    
    ret
MOSGetTileDataHeight ENDP


IEMOS_ALIGN
;******************************************************************************
; Calc dword aligned size for height or width value
;******************************************************************************
MOSCalcDwordAligned PROC FRAME USES RCX RDX qwWidthOrHeight:QWORD
    .IF qwWidthOrHeight == 0
        mov rax, 0
        ret
    .ENDIF
    mov rax, qwWidthOrHeight
    and rax, 1 ; ( a AND (b-1) )
    .IF rax == 0 ; if divisable by 2, use: and eax 3 - to div by 4    
        mov rax, qwWidthOrHeight
        and rax, 3 ; div by 4, get remainder
        add rax, qwWidthOrHeight
    .ELSE ; else use div to get remainder and add to qwWidthOrHeight
        xor rdx, rdx
        mov rax, qwWidthOrHeight
        mov rcx, 4
        div rcx ;edx contains remainder
        .IF rdx != 0
            mov rax, 4
            sub rax, rdx
            add rax, qwWidthOrHeight
        .ELSE
            mov rax, qwWidthOrHeight
        .ENDIF
    .ENDIF
    ; eax contains dword aligned value   
    ret
MOSCalcDwordAligned endp


IEMOS_ALIGN
;******************************************************************************

;******************************************************************************
MOSTileDataRAWtoBMP PROC FRAME USES RDI RSI pTileRAW:QWORD, pTileBMP:QWORD, qwTileSizeRAW:QWORD, qwTileSizeBMP:QWORD, qwTileWidth:QWORD
    LOCAL RAWCurrentPos:QWORD
    LOCAL BMPCurrentPos:QWORD
    LOCAL WidthDwordAligned:QWORD
    
    Invoke RtlZeroMemory, pTileBMP, qwTileSizeBMP

    Invoke MOSCalcDwordAligned, qwTileWidth
    mov WidthDwordAligned, rax

    mov RAWCurrentPos, 0
    mov BMPCurrentPos, 0
    mov rax, 0
    .WHILE rax < qwTileSizeRAW
    
        mov rsi, pTileRAW
        add rsi, RAWCurrentPos
        mov rdi, pTileBMP
        add rdi, BMPCurrentPos
        
        Invoke RtlMoveMemory, rdi, rsi, qwTileWidth
    
        mov rax, WidthDwordAligned
        add BMPCurrentPos, rax
        mov rax, qwTileWidth
        add RAWCurrentPos, rax
        
        mov rax, RAWCurrentPos
    .ENDW

    ret
MOSTileDataRAWtoBMP ENDP


IEMOS_ALIGN
;******************************************************************************
; Returns in eax handle to tile data bitmap or NULL
;******************************************************************************
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
    
    Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    ;Invoke GetDC, NULL
    mov hdc, rax
    Invoke CreateDIBitmap, hdc, Addr MOSTileBitmap, CBM_INIT, pTileBMP, Addr MOSTileBitmap, DIB_RGB_COLORS
    .IF rax == NULL
        IFDEF DEBUG32
            PrintText 'CreateDIBitmap Failed'
        ENDIF
    .ENDIF
    mov TileBitmapHandle, rax
    Invoke DeleteDC, hdc
    ;Invoke ReleaseDC, NULL, hdc
    mov rax, TileBitmapHandle
    ret
MOSTileDataBitmap ENDP


IEMOS_ALIGN
;******************************************************************************
; Returns in eax total tiles.
;******************************************************************************
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

IEMOS_ALIGN
;------------------------------------------------------------------------------
; Uncompresses MOSC file to an area of memory that we allocate for the exact 
; size of data
;------------------------------------------------------------------------------
MOSUncompress PROC FRAME USES RBX hMOSFile:QWORD, pMOS:QWORD, qwSize:QWORD
    LOCAL dest:QWORD
    LOCAL src:QWORD
    LOCAL MOSU_Size:QWORD
    LOCAL BytesRead:QWORD
    LOCAL MOSFilesize:QWORD
    LOCAL MOSC_UncompressedSize:QWORD
    LOCAL MOSC_CompressedSize:QWORD
    
    Invoke GetFileSize, hMOSFile, NULL
    mov MOSFilesize, rax
    mov rbx, pMOS
    xor rax, rax
    mov eax, dword ptr [rbx].MOSC_HEADER.UncompressedLength
    mov MOSC_UncompressedSize, rax
    mov rax, MOSFilesize
    sub rax, 0Ch ; take away the MOSC header 12 bytes = 0xC
    mov MOSC_CompressedSize, rax ; set correct compressed size = length of file minus MOSC header length

    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, MOSC_UncompressedSize
    .IF rax != NULL
        mov dest, rax
        mov rax, pMOS ;MOSMemMapPtr
        add rax, 0Ch ; add MOSC Header to Memory map to start at correct offset for uncompressing
        mov src, rax
        Invoke uncompress, dest, Addr MOSC_UncompressedSize, src, MOSC_CompressedSize
        .IF rax == Z_OK ; ok
            mov rax, MOSC_UncompressedSize
            mov rbx, qwSize
            mov qword ptr [rbx], rax
        
            mov rax, dest
            ret
        .ENDIF
    .ENDIF
    
    mov rax, 0        
    ret
MOSUncompress ENDP

END
















