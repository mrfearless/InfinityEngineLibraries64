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

;------------------------------------------------------------------------------
; IEMOS Prototypes
;------------------------------------------------------------------------------
IEMOSOpen                   PROTO lpszMosFilename:QWORD, qwOpenMode:QWORD ; rax = handle used in other functions: hIEMOS
IEMOSMem                    PROTO pMOSInMemory:QWORD, lpszMosFilename:QWORD, qwMosFilesize:QWORD, qwOpenMode:QWORD ; rax = handle used in other functions: hIEMOS
IEMOSClose                  PROTO hIEMOS:QWORD

; Pointers to parts of MOS file:
IEMOSHeader                 PROTO hIEMOS:QWORD ; rax = pointer to a MOSV1_HEADER structure.
IEMOSPalettes               PROTO hIEMOS:QWORD ; rax = pointer to the palettes array
IEMOSTileLookupEntries      PROTO hIEMOS:QWORD ; rax = pointer to TileLookup array entries
IEMOSTileLookupEntry        PROTO hIEMOS:QWORD, nTile:QWORD ; rax = pointer to specific TileLookup entry
IEMOSTileDataEntries        PROTO hIEMOS:QWORD ; rax = pointer to TILEDATA array entries
IEMOSTileDataEntry          PROTO hIEMOS:QWORD, nTile:QWORD ; rax = pointer to specific TILEDATA entry
IEMOSBlockEntries           PROTO hIEMOS:QWORD ; rax = pointer to DATABLOCK_ENTRY array entries. For MOS V2 Only
IEMOSBlockEntry             PROTO hIEMOS:QWORD, nBlockEntry:QWORD ; rax = pointer to a DATABLOCK_ENTRY structure. For MOS V2 Only

; MOS Basic Information:
IEMOSTotalTiles             PROTO hIEMOS:QWORD ; rax = total tiles in MOS
IEMOSTotalPalettes          PROTO hIEMOS:QWORD ; rax = total palettes in MOS (same as total tiles)
IEMOSTotalBlockEntries      PROTO hIEMOS:QWORD ; rax = total no of Datablock entries. For MOS V2 Only
IEMOSImageDimensions        PROTO hIEMOS:QWORD, lpqwImageWidth:QWORD, lpqwImageHeight:QWORD
IEMOSColumnsRows            PROTO hIEMOS:QWORD, lpqwColumns:QWORD, lpqwRows:QWORD
IEMOSPixelBlockSize         PROTO hIEMOS:QWORD ; rax = pixel block size

; MOS Tile Data Information:
IEMOSTileWidth              PROTO hIEMOS:QWORD, nTile:QWORD ; rax = tile width
IEMOSTileHeight             PROTO hIEMOS:QWORD, nTile:QWORD ; rax = tile height
IEMOSTileXCoord             PROTO hIEMOS:QWORD, nTile:QWORD ; rax = tile x coord
IEMOSTileYCoord             PROTO hIEMOS:QWORD, nTile:QWORD ; rax = tile y coord
IEMOSTileRAW                PROTO hIEMOS:QWORD, nTile:QWORD ; rax = pointer to RAW tile data.
IEMOSTilePalette            PROTO hIEMOS:QWORD, nTile:QWORD ; rax = pointer to the tile's specific palette (256 entries of RGBQUADs)
IEMOSTilePaletteValue       PROTO hIEMOS:QWORD, nTile:QWORD, PaletteIndex:QWORD ; rax = RGBQUAD or -1 if not valid.

; MOS File & Version Information:
IEMOSFileName               PROTO hIEMOS:QWORD ; rax = pointer to mos full path filename
IEMOSFileNameOnly           PROTO hIEMOS:QWORD, lpszFileNameOnly:QWORD ; rax = True or false if successfull. strips filename of path and ext information.
IEMOSFileSize               PROTO hIEMOS:QWORD ; rax = size of mos file in bytes
IEMOSFileCompression        PROTO hIEMOS:QWORD ; rax = -1 = No Mos file, TRUE for MOSCV1, FALSE for MOS V1 or MOS V2 
IEMOSVersion                PROTO hIEMOS:QWORD ; rax = 0 no mos, 1 = MOS V1, 2 = MOS V2, 3 = MOSC 

; MOS Bitmap Functions:
IEMOSTileBitmap             PROTO hIEMOS:QWORD, nTile:QWORD, lpqwTileWidth:QWORD, lpqwTileHeight:QWORD, lpqwTileXCoord:QWORD, lpqwTileYCoord:QWORD ; rax = HBITMAP or NULL
IEMOSBitmap                 PROTO hIEMOS:QWORD, qwPreferWidth:QWORD, qwPreferHeight:QWORD ; rax = HBITMAP (of all combined tiles to create the whole bitmap) or NULL.

; MOS Compression Functions:
IEMOSUncompressMOS          PROTO lpszMosFilenameIN:QWORD, lpszMosFilenameOUT:QWORD ; lpszMosInputFilename to uncompress, lpszMosOutputFilename (optional) to write out uncompressed mos as (null=same filename as lpszMosInputFilename)



;------------------------------------------------------------------------------
; IEMOS Structures
;------------------------------------------------------------------------------
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

IFNDEF TILELOOKUP_ENTRY
TILELOOKUP_ENTRY        STRUCT
    TileDataOffset      DD 0    ; Offset to specific tile's data pixels from start of Tile Data ( Offset Palettes + (Size Palettes) + (Size TilelookupEntries) )
TILELOOKUP_ENTRY        ENDS
ENDIF

IFNDEF TILEDATA
TILEDATA                STRUCT 8
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

IFNDEF MOSINFO
MOSINFO                     STRUCT 8
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
;------------------------------------------
; Conditional for IEMOS Library DLL compiling
;------------------------------------------
IFDEF IEMOS_DLL
    IEMOS_LIBEND TEXTEQU <>
ELSE
    IEMOS_LIBEND TEXTEQU <END>
ENDIF
IEMOS_ALIGN                 TEXTEQU <ALIGN 16>
; IEMOSOpen open mode:
IEMOS_MODE_WRITE            EQU 0
IEMOS_MODE_READONLY         EQU 1
; MOS Versions:
MOS_VERSION_INVALID         EQU 0 ; Not a MOS or invalid
MOS_VERSION_MOS_V10         EQU 1 ; MOS_V1.0
MOS_VERSION_MOS_V20         EQU 2 ; MOS_V2.0
MOS_VERSION_MOSCV10         EQU 3 ; MOSCV1.0 (Compressed Blocks)

; IEMOSUncompressMOS return values
MU_SUCCESS                  EQU 0
MU_MOS_INVALID              EQU -1
MU_MOS_ALREADY_UNCOMPRESSED EQU -2
MU_MOS_FORMAT_UNSUPPORTED   EQU -3
MU_MOS_TOO_LARGE            EQU -4
MU_MOS_OUTPUTFILE_CREATION  EQU -5
MU_MOS_OUTPUTFILE_MAPPING   EQU -6
MU_MOS_OUTPUTFILE_VIEW      EQU -7
MU_MOS_INPUTFILE_OPEN       EQU -8
MU_MOS_INPUTFILE_MAPPING    EQU -9
MU_MOS_INPUTFILE_VIEW       EQU -10
MU_MOS_INPUTFILE_ZEROSIZE   EQU -11
MU_MOS_UNCOMPRESS_ERROR     EQU -12






