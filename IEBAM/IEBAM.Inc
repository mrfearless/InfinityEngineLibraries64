;==============================================================================
;
; IEBAM x64
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
; IEBAM Prototypes
;------------------------------------------------------------------------------
IEBAMOpen                   PROTO lpszBamFilename:QWORD, qwOpenMode:QWORD ; rax = handle used in other functions: hIEBAM
IEBAMMem                    PROTO pBAMInMemory:QWORD, lpszBamFilename:QWORD, qwBamFilesize:QWORD, qwOpenMode:QWORD ; Returns in rax a handle used in other functions: hIEBAM
IEBAMClose                  PROTO hIEBAM:QWORD

; Pointers to parts of BAM file:
IEBAMHeader                 PROTO hIEBAM:QWORD ; rax = pointer to a BAMV1_HEADER structure.
IEBAMFrameEntry             PROTO hIEBAM:QWORD, nFrameEntry:QWORD ; rax = pointer to a FRAMEV1_ENTRY or FRAMEV2_ENTRY structure.
IEBAMCycleEntry             PROTO hIEBAM:QWORD, nCycleEntry:QWORD ; rax = pointer to a CYCLEV1_ENTRY or CYCLEV2_ENTRY structure.
IEBAMBlockEntry             PROTO hIEBAM:QWORD, nBlockEntry:QWORD ; rax = pointer to a DATABLOCK_ENTRY structure. For BAM V2 Only
IEBAMFrameEntries           PROTO hIEBAM:QWORD ; rax = pointer to Frame Entries
IEBAMCycleEntries           PROTO hIEBAM:QWORD ; rax = pointer to Cycle Entries
IEBAMBlockEntries           PROTO hIEBAM:QWORD ; rax = pointer to Datablock Entries. For BAM V2 Only
IEBAMFrameDataEntries       PROTO hIEBAM:QWORD ; rax = pointer to FrameData Entries
IEBAMFrameDataEntry         PROTO hIEBAM:QWORD, nFrameEntry:QWORD ; rax = pointer to frame data
IEBAMFrameLookupEntry       PROTO hIEBAM:QWORD, nCycle:QWORD ; rax = frame lookup 
IEBAMFrameLookupEntries     PROTO hIEBAM:QWORD ; rax = pointer to the frame lookup indexes
IEBAMPalette                PROTO hIEBAM:QWORD ; rax = pointer to the palette of 256 x RQBQUADs

; BAM Basic Information:
IEBAMTotalFrameEntries      PROTO hIEBAM:QWORD ; rax = total no of Frame entries.
IEBAMTotalCycleEntries      PROTO hIEBAM:QWORD ; rax = total no of Cycle entries.
IEBAMTotalBlockEntries      PROTO hIEBAM:QWORD ; rax = total no of Datablock entries. For BAM V2 Only
IEBAMRLEColorIndex          PROTO hIEBAM:QWORD ; rax = RLE color index

; BAM File & Version Information:
IEBAMFileName               PROTO hIEBAM:QWORD ; rax = pointer to bam full path filename
IEBAMFileNameOnly           PROTO hIEBAM:QWORD, lpszFileNameOnly:QWORD ; rax = True or false if successfull. strips filename of path and ext information.
IEBAMFileSize               PROTO hIEBAM:QWORD ; rax = size of bam file in bytes
IEBAMFileCompression        PROTO hIEBAM:QWORD ; rax = -1 - No Bam file, TRUE for BAMCV1, FALSE for BAM V1 or BAM V2 
IEBAMVersion                PROTO hIEBAM:QWORD ; rax = 0 no bam, 1 = BAM V1, 2 = BAM V2, 3 = BAMC 

; BAM Frame / Cycle Information:
IEBAMFrameLookupSequence    PROTO hIEBAM:QWORD, nCycle:QWORD, CycleIndex:QWORD ; rax = frame no in rax or -1 otherwise
IEBAMCycleFrameCount        PROTO hIEBAM:QWORD, nCycle:QWORD ; rax = frame count for cycle in rax or 0 otherwise
IEBAMFrameDimensions        PROTO hIEBAM:QWORD, nFrame:QWORD, lpqwFrameWidth:QWORD, lpqwFrameHeight:QWORD ; rax = TRUE if successful or FALSE otherwise. lpqwX contain values
IEBAMFindMaxWidthHeight     PROTO hIEBAM:QWORD, lpqwMaxWidth:QWORD, lpqwMaxHeight:QWORD ; rax = TRUE if successful or FALSE otherwise. lpqwX contain max values on success

; BAM Palette / Color Functions:
IEBAMPaletteEntry           PROTO hIEBAM:QWORD, PaletteIndex:QWORD ; rax = pointer to RGBAQUAD for index 0-255 (256 entries) or NULL if unsuccessful
IEBAMRLEColorIndexColorRef  PROTO hIEBAM:QWORD ; Returns in rax ColorRef RGB of RLEColorIndex.
IEBAMConvertABGRtoARGB      PROTO dwBGRA:DWORD ; Returns ColorRef RGB in rax
IEBAMConvertARGBtoABGR      PROTO dwARGB:DWORD ; Returns RGBQUAD (ABGR) in rax

; BAM Frame Bitmap Functions:
IEBAMFrameBitmap            PROTO hIEBAM:QWORD, nFrame:QWORD, lpqwFrameWidth:QWORD, lpqwFrameHeight:QWORD, lpqwFrameXCoord:QWORD, lpqwFrameYCoord:QWORD, qwTransColor:QWORD
IEBAMBitmap                 PROTO hIEBAM:QWORD, nFrame:QWORD, qwBackColor:QWORD, qwGridColor:QWORD ; rax = handle to bitmap of frame data or NULL. if nFrame == -1 create preview of all frames

; BAM Compression Functions:
IEBAMUncompressBAM          PROTO lpszBamFilenameIN:QWORD, lpszBamFilenameOUT:QWORD ; lpszBamInputFilename to uncompress, lpszBamOutputFilename (optional) to write out uncompressed Bam as (null=same filename as lpszBamInputFilename)

;------------------------------------------------------------------------------
; IEBAM Structures
;------------------------------------------------------------------------------

IFNDEF BAMV1_HEADER
BAMV1_HEADER            STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BAM ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1 ')
    FrameEntriesCount   DW 0 ; 0x0008   2 (word)        Count of frames
    CycleEntriesCount   DB 0 ; 0x000a   1 (byte)        Count of cycles
    ColorIndexRLE       DB 0 ; 0x000b   1 (byte)        The compressed colour index for RLE encoded bams (ie. this is the colour that is compressed)
    FrameEntriesOffset  DD 0 ; 0x000c   4 (dword)       Offset (from start of file) to frame entries (which are immediately followed by cycle entries)
    PaletteOffset       DD 0 ; 0x0010   4 (dword)       Offset (from start of file) to palette
    FrameLookupOffset   DD 0 ; 0x0014   4 (dword)       Offset (from start of file) to frame lookup table
BAMV1_HEADER            ENDS
ENDIF

IFNDEF BAMV2_HEADER
BAMV2_HEADER            STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BAM ')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V2 ')
    FrameEntriesCount   DD 0 ; 0x0008   4 (dword)       Number of frames
    CycleEntriesCount   DD 0 ; 0x000C   4 (dword)       Number of cycles
    BlockEntriesCount   DD 0 ; 0x0010   4 (dword)       Number of data blocks
    FrameEntriesOffset  DD 0 ; 0x0014   4 (dword)       Start offset of frame entries
    CycleEntriesOffset  DD 0 ; 0x0018   4 (dword)       Start offset of cycle entries
    BlockEntriesOffset  DD 0 ; 0x001C   4 (dword)       Start offset of data blocks
BAMV2_HEADER            ENDS
ENDIF

IFNDEF BAMC_HEADER
BAMC_HEADER             STRUCT
    Signature           DD 0 ; 0x0000   4 (bytes)       Signature ('BAMC')
    Version             DD 0 ; 0x0004   4 (bytes)       Version ('V1 ')
    UncompressedLength  DD 0 ; 0x0008   4 (dword)       Uncompressed data length
BAMC_HEADER             ENDS
ENDIF

IFNDEF FRAMEV1_ENTRY
FRAMEV1_ENTRY           STRUCT
    FrameWidth          DW 0 ; 0x0000   2 (word)        Frame width
    FrameHeight         DW 0 ; 0x0002   2 (word)        Frame height
    FrameXcoord         DW 0 ; 0x0004   2 (signed word) Frame center X coordinate
    FrameYcoord         DW 0 ; 0x0006   2 (signed word) Frame center Y coordinate
    FrameInfo           DD 0 ; 0x0008   4 (dword)       * bits 30-0: Offset to frame data * bit 31: 0=Compressed (RLE), 1=Uncompressed    
FRAMEV1_ENTRY           ENDS
ENDIF

IFNDEF FRAMEV2_ENTRY
FRAMEV2_ENTRY           STRUCT
    FrameWidth          DW 0 ; 0x0000   2 (word)        Frame width
    FrameHeight         DW 0 ; 0x0002   2 (word)        Frame height
    FrameXcoord         DW 0 ; 0x0004   2 (signed word) Frame center X coordinate
    FrameYcoord         DW 0 ; 0x0006   2 (signed word) Frame center Y coordinate
    DataBlockIndex      DW 0 
    DataBlockCount      DW 0
FRAMEV2_ENTRY           ENDS
ENDIF

IFNDEF CYCLEV1_ENTRY
CYCLEV1_ENTRY           STRUCT
    CycleFrameCount     DW 0 ; 0x0000   2 (word)        Count of frame indices in this cycle
    CycleStartFrame     DW 0 ; 0x0002   2 (word)        Index into frame lookup table of first frame index in this cycle
CYCLEV1_ENTRY           ENDS
ENDIF

IFNDEF CYCLEV2_ENTRY
CYCLEV2_ENTRY           STRUCT
    CycleFrameCount     DW 0 ; 0x0000   2 (word)        Number of frame entries in this cycle
    CycleStartFrame     DW 0 ; 0x0002   2 (word)        Start index of frame entries in this cycle
CYCLEV2_ENTRY           ENDS
ENDIF

IFNDEF DATABLOCK_ENTRY  ; Used in BAM V2
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


IFNDEF FRAMELOOKUPTABLE
FRAMELOOKUPTABLE        STRUCT
    SequenceSize        DQ 0 ; length of sequence data - same as CycleFrameCount
    SequenceData        DQ 0 ; pointer to word array that has sequence of frame indicies in it
FRAMELOOKUPTABLE        ENDS
ENDIF

IFNDEF FRAMEDATA
FRAMEDATA               STRUCT
    FrameCompressed     DQ 0 ; Flag for compressed RLE encoding or not
    FrameWidth          DQ 0
    FrameHeight         DQ 0
    FrameXcoord         DQ 0
    FrameYcoord         DQ 0    
    FrameSizeRAW        DQ 0 ; total dimension size of FrameRAW = width * height
    FrameSizeRLE        DQ 0
    FrameSizeBMP        DQ 0
    FrameRAW            DQ 0 ; Pointer to RAW unRLE'd frame data
    FrameRLE            DQ 0
    FrameBMP            DQ 0 ; memory for bitmap pixels, (unrle'd data) raw data converted to bmp pixel data.  
    FrameBitmapHandle   DQ 0 ; bitmap handle from CreateDibBitmap
    FrameDataBlockIndex DQ 0 ; BAM V2 only
    FrameDataBlockCount DQ 0 ; BAM V2 only
FRAMEDATA               ENDS
ENDIF

IFNDEF BAMINFO
BAMINFO                     STRUCT
    BAMOpenMode             DQ 0
    BAMFilename             DB MAX_PATH DUP (0)
    BAMFilesize             DQ 0
    BAMVersion              DQ 0
    BAMCompressed           DQ 0
    BAMHeaderPtr            DQ 0
    BAMHeaderSize           DQ 0
    BAMTotalFrames          DQ 0
    BAMTotalCycles          DQ 0
    BAMTotalBlocks          DQ 0 ; for BAM V2
    BAMFrameEntriesPtr      DQ 0
    BAMFrameEntriesSize     DQ 0
    BAMCycleEntriesPtr      DQ 0
    BAMCycleEntriesSize     DQ 0
    BAMBlockEntriesPtr      DQ 0 ; for BAM V2
    BAMBlockEntriesSize     DQ 0 ; for BAM V2
    BAMPalettePtr           DQ 0 ; no interal palette for BAM V2
    BAMPaletteSize          DQ 1024d
    BAMFrameLookupPtr       DQ 0
    BAMFrameLookupSize      DQ 0
    BAMFrameDataEntriesPtr  DQ 0 ; custom array of FRAMEDATA
    BAMFrameDataEntriesSize DQ 0
    BAMMemMapPtr            DQ 0
    BAMMemMapHandle         DQ 0
    BAMFileHandle           DQ 0    
BAMINFO                     ENDS
ENDIF

.CONST
;------------------------------------------
; Conditional for IEBAM Library DLL compiling
;------------------------------------------
IFDEF IEBAM_DLL
    IEBAM_LIBEND TEXTEQU <>
ELSE
    IEBAM_LIBEND TEXTEQU <END>
ENDIF
IEBAM_ALIGN                 TEXTEQU <ALIGN 16>
; IEBAMOpen open mode:
IEBAM_MODE_WRITE            EQU 0
IEBAM_MODE_READONLY         EQU 1
; BAM Versions:
BAM_VERSION_INVALID         EQU 0 ; Not a BAM or invalid
BAM_VERSION_BAM_V10         EQU 1 ; BAM_V1.0
BAM_VERSION_BAM_V20         EQU 2 ; BAM_V2.0
BAM_VERSION_BAMCV10         EQU 3 ; BAMCV1.0 (Compressed Blocks)

; IEBAMUncompress return values
BU_SUCCESS                  EQU 0
BU_BAM_INVALID              EQU -1
BU_BAM_ALREADY_UNCOMPRESSED EQU -2
BU_BAM_FORMAT_UNSUPPORTED   EQU -3
BU_BAM_TOO_LARGE            EQU -4
BU_BAM_OUTPUTFILE_CREATION  EQU -5
BU_BAM_OUTPUTFILE_MAPPING   EQU -6
BU_BAM_OUTPUTFILE_VIEW      EQU -7
BU_BAM_INPUTFILE_OPEN       EQU -8
BU_BAM_INPUTFILE_MAPPING    EQU -9
BU_BAM_INPUTFILE_VIEW       EQU -10
BU_BAM_INPUTFILE_ZEROSIZE   EQU -11
BU_BAM_UNCOMPRESS_ERROR     EQU -12

















