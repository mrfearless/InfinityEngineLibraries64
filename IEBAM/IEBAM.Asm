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

;DEBUG32 EQU 1
;IFDEF DEBUG32
;    PRESERVEXMMREGS equ 1
;    includelib M:\Masm32\lib\Debug32.lib
;    DBG32LIB equ 1
;    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
;    include M:\Masm32\include\debug32.inc
;ENDIF

include IEBAM.inc

; Internal functions start with BAM
; External functions start with IEBAM

;-------------------------------------------------------------------------
; Internal functions:
;-------------------------------------------------------------------------
BAMSignature              PROTO pBAM:QWORD
BAMUncompress             PROTO hBAMFile:QWORD, pBAM:QWORD, qwSize:QWORD
BAMJustFname              PROTO szFilePathName:QWORD, szFileName:QWORD

BAMV1Mem                  PROTO pBAMInMemory:QWORD, lpszBamFilename:QWORD, qwBamFilesize:QWORD, qwOpenMode:QWORD
BAMV2Mem                  PROTO pBAMInMemory:QWORD, lpszBamFilename:QWORD, qwBamFilesize:QWORD, qwOpenMode:QWORD

BAMCalcDwordAligned       PROTO qwWidthOrHeight:QWORD
BAMFrameDataBitmap        PROTO qwFrameWidth:QWORD, qwFrameHeight:QWORD, pFrameBMP:QWORD, qwFrameSizeBMP:QWORD, pFramePalette:QWORD

BAMFrameUnRLESize         PROTO pFrameRLE:QWORD, FrameRLESize:QWORD
BAMFrameUnRLE             PROTO pFrameRLE:QWORD, FrameRLESize:QWORD, pFrameRAW:QWORD, FrameRAWSize:QWORD

BAMFrameRAWToFrameBMP     PROTO pFrameRAW:QWORD, pFrameBMP:QWORD, FrameRAWSize:QWORD, FrameBMPSize:QWORD, FrameWidth:QWORD





.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMOpen - Returns handle in eax of opened bam file. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
IEBAMOpen PROC FRAME USES RBX lpszBamFilename:QWORD, qwOpenMode:QWORD
    LOCAL hIEBAM:QWORD
    LOCAL hBAMFile:QWORD
    LOCAL BAMFilesize:QWORD
    LOCAL SigReturn:QWORD
    LOCAL BAMMemMapHandle:QWORD
    LOCAL BAMMemMapPtr:QWORD
    LOCAL pBAM:QWORD

    .IF qwOpenMode == IEBAM_MODE_READONLY ; readonly
        Invoke CreateFile, lpszBamFilename, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ELSE
        Invoke CreateFile, lpszBamFilename, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL
    .ENDIF
 
    .IF rax == INVALID_HANDLE_VALUE
        mov rax, NULL
        ret
    .ENDIF
    mov hBAMFile, rax

    Invoke GetFileSize, hBAMFile, NULL
    mov BAMFilesize, rax

    ;---------------------------------------------------                
    ; File Mapping: Create file mapping for main .bam
    ;---------------------------------------------------
    .IF qwOpenMode == IEBAM_MODE_READONLY ; readonly
        Invoke CreateFileMapping, hBAMFile, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .ELSE
        Invoke CreateFileMapping, hBAMFile, NULL, PAGE_READWRITE, 0, 0, NULL ; Create memory mapped file
    .ENDIF   
    .IF rax == NULL
        Invoke CloseHandle, hBAMFile
        mov rax, NULL
        ret
    .ENDIF
    mov BAMMemMapHandle, rax
    
    .IF qwOpenMode == IEBAM_MODE_READONLY ; readonly
        Invoke MapViewOfFileEx, BAMMemMapHandle, FILE_MAP_READ, 0, 0, 0, NULL
    .ELSE
        Invoke MapViewOfFileEx, BAMMemMapHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .ENDIF
    .IF rax == NULL
        Invoke CloseHandle, BAMMemMapHandle
        Invoke CloseHandle, hBAMFile
        mov rax, NULL
        ret
    .ENDIF
    mov BAMMemMapPtr, rax

    Invoke BAMSignature, BAMMemMapPtr
    mov SigReturn, rax
    .IF SigReturn == BAM_VERSION_INVALID ; not a valid bam file
        Invoke UnmapViewOfFile, BAMMemMapPtr
        Invoke CloseHandle, BAMMemMapHandle
        Invoke CloseHandle, hBAMFile
        mov rax, NULL
        ret    
    
    .ELSEIF SigReturn == BAM_VERSION_BAM_V10 ; BAM
        Invoke IEBAMMem, BAMMemMapPtr, lpszBamFilename, BAMFilesize, qwOpenMode
        mov hIEBAM, rax
        .IF hIEBAM == NULL
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile
            mov rax, NULL
            ret    
        .ENDIF
        .IF qwOpenMode == IEBAM_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov rbx, hIEBAM
            mov rax, BAMMemMapHandle
            mov [rbx].BAMINFO.BAMMemMapHandle, rax
            mov rax, hBAMFile
            mov [rbx].BAMINFO.BAMFileHandle, rax
        .ENDIF

    .ELSEIF SigReturn == BAM_VERSION_BAM_V20 ; BAMV2 - return false for the mo
      Invoke IEBAMMem, BAMMemMapPtr, lpszBamFilename, BAMFilesize, qwOpenMode
        mov hIEBAM, rax
        .IF hIEBAM == NULL
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile
            mov rax, NULL
            ret    
        .ENDIF
        .IF qwOpenMode == IEBAM_MODE_WRITE ; write (default)
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile
        .ELSE ; else readonly, so keep mapping around till we close file
            mov rbx, hIEBAM
            mov rax, BAMMemMapHandle
            mov [rbx].BAMINFO.BAMMemMapHandle, rax
            mov rax, hBAMFile
            mov [rbx].BAMINFO.BAMFileHandle, rax
        .ENDIF    
;        Invoke UnmapViewOfFile, BAMMemMapPtr
;        Invoke CloseHandle, BAMMemMapHandle
;        Invoke CloseHandle, hBAMFile
;        mov rax, NULL
;        ret    

    .ELSEIF SigReturn == BAM_VERSION_BAMCV10 ; BAMC
        Invoke BAMUncompress, hBAMFile, BAMMemMapPtr, Addr BAMFilesize
        .IF rax == 0
            Invoke UnmapViewOfFile, BAMMemMapPtr
            Invoke CloseHandle, BAMMemMapHandle
            Invoke CloseHandle, hBAMFile        
            mov rax, NULL
            ret
        .ENDIF
        mov pBAM, rax ; save uncompressed location to this var
        Invoke UnmapViewOfFile, BAMMemMapPtr
        Invoke CloseHandle, BAMMemMapHandle
        Invoke CloseHandle, hBAMFile        
        Invoke IEBAMMem, pBAM, lpszBamFilename, BAMFilesize, qwOpenMode
        mov hIEBAM, rax
        .IF hIEBAM == NULL
            Invoke GlobalFree, pBAM
            mov rax, NULL
            ret
        .ENDIF
   
    .ENDIF
    ; save original version to handle for later use so we know if orignal file opened was standard BIFF or a compressed BIF_ or BIFC file, if 0 then it was in mem so we assume BIFF
    mov rbx, hIEBAM
    mov rax, SigReturn
    mov [rbx].BAMINFO.BAMVersion, rax
    mov rax, hIEBAM
    ret
IEBAMOpen ENDP


IEBAM_ALIGN
;----------------------------------------------------------------------------
; IEBAMClose - Close BAM File
;----------------------------------------------------------------------------
IEBAMClose PROC FRAME USES RBX hIEBAM:QWORD
    LOCAL FrameDataEntriesPtr:QWORD
    LOCAL FrameDataOffset:QWORD
    LOCAL FrameLookupEntriesPtr:QWORD
    LOCAL FrameLookupOffset:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL TotalCycles:QWORD
    LOCAL nFrame:QWORD
    LOCAL nCycle:QWORD
    LOCAL qwOpenMode:QWORD
    
    .IF hIEBAM == NULL
        mov rax, 0
        ret
    .ENDIF

    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMOpenMode
    mov qwOpenMode, rax
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    mov TotalFrames, rax

    Invoke IEBAMTotalCycleEntries, hIEBAM
    mov TotalCycles, rax

    ; clear mem for alloc'd cycle sequence lookups, and clear mem for the whole lookup data structure
    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMFrameLookupPtr
    .IF rax != NULL
        mov FrameLookupEntriesPtr, rax
        mov FrameLookupOffset, rax

        mov nCycle, 0
        mov rax, 0
        .WHILE rax < TotalCycles
            mov rbx, FrameLookupOffset
            mov rax, [rbx].FRAMELOOKUPTABLE.SequenceData
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            
            add FrameLookupOffset, SIZEOF FRAMELOOKUPTABLE
            inc nCycle
            mov rax, nCycle
        .ENDW
    .ENDIF        

    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMFrameLookupPtr   
    .IF rax != NULL
        Invoke GlobalFree, rax
    .ENDIF

    ; clear mem for alloc'd frames, delete handle to bitmaps for each frame if there is one and clear mem for the whole frame data structure
    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMFrameDataEntriesPtr
    .IF rax != NULL
        mov FrameDataEntriesPtr, rax
        mov FrameDataOffset, rax

        mov nFrame, 0
        mov rax, 0
        .WHILE rax < TotalFrames
            .IF qwOpenMode == IEBAM_MODE_WRITE
                mov rbx, FrameDataOffset
                mov rax, [rbx].FRAMEDATA.FrameRAW
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
            .ENDIF
            mov rbx, FrameDataOffset
            mov rax, [rbx].FRAMEDATA.FrameRLE
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            mov rbx, FrameDataOffset
            mov rax, [rbx].FRAMEDATA.FrameBitmapHandle
            .IF rax != NULL
                Invoke DeleteObject, rax
            .ENDIF
            mov rbx, FrameDataOffset
            mov rax, [rbx].FRAMEDATA.FrameBMP
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            
            add FrameDataOffset, SIZEOF FRAMEDATA
            inc nFrame
            mov rax, nFrame
        .ENDW
    .ENDIF

    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMFrameDataEntriesPtr
    .IF rax != NULL
        Invoke GlobalFree, rax
    .ENDIF

    .IF qwOpenMode == IEBAM_MODE_WRITE ; Write Mode
        mov rbx, hIEBAM
        mov rax, [rbx].BAMINFO.BAMHeaderPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF

        mov rbx, hIEBAM
        mov rax, [rbx].BAMINFO.BAMPalettePtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF
        
        mov rbx, hIEBAM
        mov rax, [rbx].BAMINFO.BAMBlockEntriesPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF        
        
        mov rbx, hIEBAM
        mov rax, [rbx].BAMINFO.BAMFrameEntriesPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF
        
        mov rbx, hIEBAM
        mov rax, [rbx].BAMINFO.BAMCycleEntriesPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF
    .ENDIF

    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMVersion
    .IF rax == BAM_VERSION_BAMCV10 ; BAMC in read or write mode uncompresed bam in memory needs to be cleared
        mov rbx, hIEBAM
        mov rax, [rbx].BAMINFO.BAMMemMapPtr
        .IF rax != NULL
            Invoke GlobalFree, rax
        .ENDIF    
    
    .ELSE ; BAM V1 or BAM V2 so if  opened in readonly, unmap file etc, otherwise free mem

        .IF qwOpenMode == IEBAM_MODE_READONLY ; Read Only
            mov rbx, hIEBAM
            mov rax, [rbx].BAMINFO.BAMMemMapPtr
            .IF rax != NULL
                Invoke UnmapViewOfFile, rax
            .ENDIF
            
            mov rbx, hIEBAM
            mov rax, [rbx].BAMINFO.BAMMemMapHandle
            .IF rax != NULL
                Invoke CloseHandle, rax
            .ENDIF

            mov rbx, hIEBAM
            mov rax, [rbx].BAMINFO.BAMFileHandle
            .IF rax != NULL
                Invoke CloseHandle, rax
            .ENDIF
       
        .ELSE ; free mem if write mode
            mov rbx, hIEBAM
            mov rax, [rbx].BAMINFO.BAMMemMapPtr
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
        .ENDIF

    .ENDIF
    
    mov rax, hIEBAM
    .IF rax != NULL
        Invoke GlobalFree, rax
    .ENDIF

    mov rax, 0
    ret
IEBAMClose ENDP


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMMem - Returns handle in rax of opened bam file that is already loaded into memory. NULL if could not alloc enough mem
; calls BAMV1Mem or BAMV2Mem depending on version of file found
;------------------------------------------------------------------------------
IEBAMMem PROC FRAME pBAMInMemory:QWORD, lpszBamFilename:QWORD, qwBamFilesize:QWORD, qwOpenMode:QWORD
    ; check signatures to determine version
    Invoke BAMSignature, pBAMInMemory

    .IF rax == BAM_VERSION_INVALID ; invalid file
        mov rax, NULL
        ret

    .ELSEIF rax == BAM_VERSION_BAM_V10
        Invoke BAMV1Mem, pBAMInMemory, lpszBamFilename, qwBamFilesize, qwOpenMode

    .ELSEIF rax == BAM_VERSION_BAM_V20
        Invoke BAMV2Mem, pBAMInMemory, lpszBamFilename, qwBamFilesize, qwOpenMode

    .ELSEIF rax == BAM_VERSION_BAMCV10
        Invoke BAMV1Mem, pBAMInMemory, lpszBamFilename, qwBamFilesize, qwOpenMode

    .ENDIF
    ret
IEBAMMem ENDP


IEBAM_ALIGN
;------------------------------------------------------------------------------
; BAMV1Mem - Returns handle in rax of opened bam file that is already loaded into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
BAMV1Mem PROC FRAME USES RBX RCX RDX RDI RSI pBAMInMemory:QWORD, lpszBamFilename:QWORD, qwBamFilesize:QWORD, qwOpenMode:QWORD
    LOCAL hIEBAM:QWORD
    LOCAL BAMMemMapPtr:QWORD
    LOCAL TotalFrameEntries:QWORD
    LOCAL TotalCycleEntries:QWORD
    LOCAL FrameEntriesSize:QWORD
    LOCAL CycleEntriesSize:QWORD
    LOCAL FrameLookupSize:QWORD
    LOCAL OffsetFrameEntries:QWORD
    LOCAL OffsetCycleEntries:QWORD
    LOCAL OffsetPalette:QWORD
    LOCAL OffsetFrameLookup:QWORD
    LOCAL FrameLookupOriginal:QWORD
    LOCAL FrameEntriesPtr:QWORD
    LOCAL FrameEntryPtr:QWORD
    LOCAL CycleEntriesPtr:QWORD
    LOCAL CycleEntryPtr:QWORD
    LOCAL PalettePtr:QWORD
    LOCAL FrameLookupEntriesPtr:QWORD
    LOCAL FrameLookupEntryPtr:QWORD
    LOCAL FrameDataEntriesPtr:QWORD
    LOCAL FrameDataEntryPtr:QWORD
    LOCAL nCycle:QWORD
    LOCAL nFrame:QWORD
    LOCAL nCycleIndexStart:QWORD
    LOCAL nCycleIndexCount:QWORD
    LOCAL SequenceSize:QWORD
    LOCAL SequencePtr:QWORD
    LOCAL AllFramesDataSize:QWORD
    LOCAL tFrameDataRawPtr:QWORD
    LOCAL tFrameDataRlePtr:QWORD
    LOCAL tFrameDataBmpPtr:QWORD
    LOCAL FrameCompressed:QWORD
    LOCAL FrameDataOffset:QWORD
    LOCAL FrameDataOffsetN1:QWORD
    LOCAL FrameDataRLE:QWORD
    LOCAL FrameWidth:QWORD
    LOCAL FrameHeight:QWORD
    LOCAL FrameXcoord:QWORD
    LOCAL FrameYcoord:QWORD
    LOCAL FrameWidthDwordAligned:QWORD
    LOCAL FrameInfo:QWORD
    LOCAL FrameSize:QWORD
    LOCAL FrameSizeRAW:QWORD
    LOCAL FrameSizeRLE:QWORD
    LOCAL FrameSizeBMP:QWORD
    LOCAL FrameDataRawPtr:QWORD
    LOCAL FrameDataRlePtr:QWORD
    LOCAL FrameDataBmpPtr:QWORD

    mov rax, pBAMInMemory
    mov BAMMemMapPtr, rax       
    
    ;----------------------------------
    ; Alloc mem for our IEBAM Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BAMINFO
    .IF rax == NULL
        ret
    .ENDIF
    mov hIEBAM, rax
    
    mov rbx, hIEBAM
    mov rax, qwOpenMode
    mov [rbx].BAMINFO.BAMOpenMode, rax
    mov rax, BAMMemMapPtr
    mov [rbx].BAMINFO.BAMMemMapPtr, rax
    
    lea rax, [rbx].BAMINFO.BAMFilename
    Invoke lstrcpyn, rax, lpszBamFilename, MAX_PATH
    
    mov rbx, hIEBAM
    mov rax, qwBamFilesize
    mov [rbx].BAMINFO.BAMFilesize, rax

    ;----------------------------------
    ; BAM Header
    ;----------------------------------
    .IF qwOpenMode == IEBAM_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BAMV1_HEADER
        .IF rax == NULL
            Invoke GlobalFree, hIEBAM
            mov rax, NULL
            ret
        .ENDIF    
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMHeaderPtr, rax
        mov rbx, BAMMemMapPtr
        Invoke RtlMoveMemory, rax, rbx, SIZEOF BAMV1_HEADER
    .ELSE
        mov rbx, hIEBAM
        mov rax, BAMMemMapPtr
        mov [rbx].BAMINFO.BAMHeaderPtr, rax
    .ENDIF
    mov rbx, hIEBAM
    mov rax, SIZEOF BAMV1_HEADER
    mov [rbx].BAMINFO.BAMHeaderSize, rax   

    ;----------------------------------
    ; Double check file in mem is BAM
    ;----------------------------------
;    Invoke RtlZeroMemory, Addr BAMXHeader, SIZEOF BAMXHeader
;    Invoke RtlMoveMemory, Addr BAMXHeader, BAMMemMapPtr, 8d
;    Invoke lstrcmp, Addr BAMXHeader, Addr BAMV1Header
;    ;Invoke szCmp, Addr BAMXHeader, Addr BAMV1Header
;    .IF rax != 0 ; no match using lstrcmp
;    ;.IF rax == 0 ; no match using szCmp   
;        mov rbx, hIEBAM
;        mov rax, [rbx].BAMINFO.BAMHeaderPtr
;        .IF rax != NULL
;            Invoke GlobalFree, rax
;        .ENDIF
;        Invoke GlobalFree, hIEBAM
;        mov rax, NULL    
;        ret
;    .ENDIF

    ;----------------------------------
    ; Frame & Cycle Counts, Offsets & Sizes
    ;----------------------------------
    mov rbx, [rbx].BAMINFO.BAMHeaderPtr
    movzx rax, word ptr [rbx].BAMV1_HEADER.FrameEntriesCount
    mov TotalFrameEntries, rax
    movzx rax, byte ptr [rbx].BAMV1_HEADER.CycleEntriesCount
    mov TotalCycleEntries, rax
    mov eax, dword ptr [rbx].BAMV1_HEADER.FrameEntriesOffset
    mov OffsetFrameEntries, rax
    mov eax, dword ptr [rbx].BAMV1_HEADER.PaletteOffset
    mov OffsetPalette, rax    
    mov eax, dword ptr [rbx].BAMV1_HEADER.FrameLookupOffset
    mov OffsetFrameLookup, rax
    add rax, BAMMemMapPtr
    mov FrameLookupOriginal, rax
    
    ;mov rax, [rbx].BIFV1_HEADER.OffsetResEntries
    ;mov OffsetResEntries, rax
    
    mov rax, TotalFrameEntries
    mov rbx, SIZEOF FRAMEV1_ENTRY
    mul rbx
    mov FrameEntriesSize, rax
    
    mov rax, TotalCycleEntries
    mov rbx, SIZEOF CYCLEV1_ENTRY
    mul rbx
    mov CycleEntriesSize, rax
    
    mov rax, FrameEntriesSize
    add rax, OffsetFrameEntries ;SIZEOF BAMV1_HEADER
    mov OffsetCycleEntries, rax

    ;----------------------------------
    ; Frame Entries
    ;----------------------------------
    .IF TotalFrameEntries > 0
        .IF qwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameEntriesSize
            .IF rax == NULL
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov rax, NULL    
                ret
            .ENDIF    
            mov rbx, hIEBAM
            mov [rbx].BAMINFO.BAMFrameEntriesPtr, rax
            mov FrameEntriesPtr, rax
        
            mov rbx, BAMMemMapPtr
            add rbx, OffsetFrameEntries
            Invoke RtlMoveMemory, rax, rbx, FrameEntriesSize
        .ELSE
            mov rbx, hIEBAM
            mov rax, BAMMemMapPtr
            add rax, OffsetFrameEntries
            mov [rbx].BAMINFO.BAMFrameEntriesPtr, rax
            mov FrameEntriesPtr, rax
        .ENDIF
        mov rbx, hIEBAM
        mov rax, FrameEntriesSize
        mov [rbx].BAMINFO.BAMFrameEntriesSize, rax    
    .ELSE
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameEntriesPtr, 0
        mov [rbx].BAMINFO.BAMFrameEntriesSize, 0
        mov FrameEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Cycle Entries
    ;----------------------------------
    .IF TotalCycleEntries > 0
        .IF qwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, CycleEntriesSize
            .IF rax == NULL
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMFrameEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov rax, NULL    
                ret
            .ENDIF    
            mov rbx, hIEBAM
            mov [rbx].BAMINFO.BAMCycleEntriesPtr, rax
            mov CycleEntriesPtr, rax
        
            mov rbx, BAMMemMapPtr
            add rbx, OffsetCycleEntries
            Invoke RtlMoveMemory, rax, rbx, CycleEntriesSize
        .ELSE
            mov rbx, hIEBAM
            mov rax, BAMMemMapPtr
            add rax, OffsetCycleEntries
            mov [rbx].BAMINFO.BAMCycleEntriesPtr, rax
            mov CycleEntriesPtr, rax
        .ENDIF
        mov rbx, hIEBAM
        mov rax, CycleEntriesSize
        mov [rbx].BAMINFO.BAMCycleEntriesSize, rax   
    .ELSE
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMCycleEntriesPtr, 0
        mov [rbx].BAMINFO.BAMCycleEntriesSize, 0
        mov CycleEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Palette
    ;----------------------------------      
    .IF qwOpenMode == IEBAM_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, 1024d ; alloc space for palette
        .IF rax == NULL
            mov rbx, hIEBAM
            mov rax, [rbx].BAMINFO.BAMCycleEntriesPtr
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            mov rbx, hIEBAM
            mov rax, [rbx].BAMINFO.BAMFrameEntriesPtr
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            mov rbx, hIEBAM
            mov rax, [rbx].BAMINFO.BAMHeaderPtr
            .IF rax != NULL
                Invoke GlobalFree, rax
            .ENDIF
            Invoke GlobalFree, hIEBAM
            mov rax, NULL    
            ret
        .ENDIF
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMPalettePtr, rax
        mov PalettePtr, rax

        mov rbx, BAMMemMapPtr
        add rbx, OffsetPalette
        Invoke RtlMoveMemory, rax, rbx, 1024d
    .ELSE
        mov rbx, hIEBAM
        mov rax, BAMMemMapPtr
        add rax, OffsetPalette
        mov [rbx].BAMINFO.BAMPalettePtr, rax
        mov PalettePtr, rax
    .ENDIF
    ; copy palette to our bitmap header palette var
    ;Invoke RtlMoveMemory, Addr BAMBMPPalette, PalettePtr, 1024    
    
    ;mov rbx, hIEBAM
    ;mov rax, 1024d
    ;mov [rbx].BAMINFO.BAMPaletteSize, rax   

    ;----------------------------------
    ; Alloc space for FrameLookup
    ;----------------------------------
    ; Calc size of FrameLookup Table
    .IF TotalCycleEntries > 0
        mov rax, TotalCycleEntries
        mov rbx, SIZEOF FRAMELOOKUPTABLE
        mul rbx
        mov FrameLookupSize, rax 

        ; Alloc space for framelookup table
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameLookupSize
        .IF rax == NULL
            .IF qwOpenMode == IEBAM_MODE_WRITE
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMPalettePtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMCycleEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMFrameEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
            .ENDIF
            Invoke GlobalFree, hIEBAM
            mov rax, NULL    
            ret
        .ENDIF
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameLookupPtr, rax
        mov FrameLookupEntriesPtr, rax
        mov rax, FrameLookupSize
        mov [rbx].BAMINFO.BAMFrameLookupSize, rax
        
        mov rax, CycleEntriesPtr
        mov CycleEntryPtr, rax
        
        mov rax, FrameLookupEntriesPtr
        mov FrameLookupEntryPtr, rax

        ; loop through cycles, get framelookup start index and count, get this data and copy it to a mem entry of our own lookup table
        mov nCycle, 0
        mov rax, 0
        .WHILE rax < TotalCycleEntries
            mov rbx, CycleEntryPtr
            movzx rax, word ptr [rbx].CYCLEV1_ENTRY.CycleFrameCount
            mov nCycleIndexCount, rax
            movzx rax, word ptr [rbx].CYCLEV1_ENTRY.CycleStartFrame
            mov nCycleIndexStart, rax

            .IF nCycleIndexCount > 0
                ; calc size of sequence
                mov rax, nCycleIndexCount
                mov rbx, 2d ; word sized array
                mul rbx
                mov SequenceSize, rax
            .ELSE
                mov SequenceSize, 0
            .ENDIF

            ; alloc mem for sequence
            .IF nCycleIndexCount > 0 
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SequenceSize ;nCycleIndexCount ;SequenceSize
                .IF rax == NULL
                    ret
                .ENDIF
                mov SequencePtr, rax
                mov rax, nCycleIndexStart
                mov rbx, 2d ; word array size
                mul rbx
                add rax, FrameLookupOriginal ; offset to index of cycle sequence is now in rax  
                ; copy sequence memory data
                Invoke RtlMoveMemory, SequencePtr, rax, SequenceSize ;nCycleIndexCount ;SequenceSize
            .ELSE
                mov SequencePtr, 0
            .ENDIF

            ; Assign memory ptr of sequence to our own lookup table entry
            mov rbx, FrameLookupEntryPtr
            mov rax, SequenceSize ;nCycleIndexCount ;SequenceSize
            mov [rbx].FRAMELOOKUPTABLE.SequenceSize, rax
            mov rax, SequencePtr
            mov [rbx].FRAMELOOKUPTABLE.SequenceData, rax
            
            add CycleEntryPtr, SIZEOF CYCLEV1_ENTRY
            add FrameLookupEntryPtr, SIZEOF FRAMELOOKUPTABLE
            
            inc nCycle
            mov rax, nCycle
        .ENDW

    .ELSE
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameLookupPtr, 0
        mov [rbx].BAMINFO.BAMFrameLookupSize, 0
    .ENDIF

    ;----------------------------------
    ; Alloc space for FrameDataEntries
    ;----------------------------------
    ; loop through frame entries, get frame data for each frame and save to our own structure
    .IF TotalFrameEntries > 0
        mov rax, TotalFrameEntries
        mov rbx, SIZEOF FRAMEDATA
        mul rbx
        mov AllFramesDataSize, rax
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, AllFramesDataSize
        .IF rax == NULL
            .IF qwOpenMode == IEBAM_MODE_WRITE
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMFrameLookupPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF    
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMPalettePtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMCycleEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMFrameEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
            .ENDIF    
            Invoke GlobalFree, hIEBAM
            mov rax, NULL    
            ret
        .ENDIF
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameDataEntriesPtr, rax
        mov FrameDataEntriesPtr, rax
        mov rax, AllFramesDataSize
        mov [rbx].BAMINFO.BAMFrameDataEntriesSize, rax

        mov rax, FrameEntriesPtr
        mov FrameEntryPtr, rax
        mov rax, FrameDataEntriesPtr
        mov FrameDataEntryPtr, rax

        mov nFrame, 0
        mov rax, 0
        .WHILE rax < TotalFrameEntries
            mov rbx, FrameEntryPtr
            movzx rax, word ptr [rbx].FRAMEV1_ENTRY.FrameWidth
            mov FrameWidth, rax
            movzx rax, word ptr [rbx].FRAMEV1_ENTRY.FrameHeight
            mov FrameHeight, rax
            movzx eax, word ptr [rbx].FRAMEV1_ENTRY.FrameXcoord
            mov FrameXcoord, rax
            movzx eax, word ptr [rbx].FRAMEV1_ENTRY.FrameYcoord
            mov FrameYcoord, rax
            mov eax, dword ptr [rbx].FRAMEV1_ENTRY.FrameInfo
            mov FrameInfo, rax

            .IF FrameWidth != 0 && FrameHeight != 0
                Invoke BAMCalcDwordAligned, FrameWidth
                mov FrameWidthDwordAligned, rax
            .ELSE
                mov FrameWidthDwordAligned, 0
            .ENDIF    

            ; Get FrameOffset to data and compression status
            mov rax, FrameInfo
            AND eax, 80000000h ; mask for compression bit
            shr eax, 31d
            mov FrameCompressed, rax
            .IF FrameCompressed == 1
                ;PrintText 'Uncompressed Frame'
            .ENDIF
            mov rax, FrameInfo
            AND eax, 7FFFFFFFh ; mask for offset to frame data
            mov FrameDataOffset, rax

            ; Get framedata entry (our structure) for specified frame
            mov rax, TotalFrameEntries
            dec rax ; for 0 based frame index
            .IF nFrame == rax ; end of frames, use filesize instead
                mov rax, qwBamFilesize
                mov FrameDataOffsetN1, rax
            .ELSE 
                mov rax, FrameEntryPtr
                add rax, SIZEOF FRAMEV1_ENTRY ; frame N + 1
                mov rbx, rax
                mov eax, dword ptr [rbx].FRAMEV1_ENTRY.FrameInfo
                AND eax, 7FFFFFFFh; mask for offset to frame data
                mov FrameDataOffsetN1, rax
            .ENDIF
            mov rbx, FrameDataOffset
            sub rax, rbx
            .IF FrameCompressed == 1 ; uncompressed
                mov FrameSizeRAW, rax
                mov FrameSizeRLE, 0
            .ELSE ; else compressed
                mov FrameSizeRLE, rax
                mov rax, FrameWidthDwordAligned
                mov rbx, FrameHeight
                mul rbx
                mov FrameSizeRAW, rax ; got to set max to what would be max qword width x height as raw size is unknown - during unrle we get the actual size
            .ENDIF
            mov rax, FrameWidthDwordAligned
            mov rbx, FrameHeight
            mul rbx
            mov FrameSizeBMP, rax

            .IF FrameSizeRAW != 0
                mov rax, FrameSizeRAW
                add rax, 8d ; extra margin for overread
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax ;FrameSizeRAW
                mov FrameDataRawPtr, rax
            .ELSE
                mov FrameDataRawPtr, 0
            .ENDIF
            .IF FrameSizeRLE != 0
                mov rax, FrameSizeRLE
                add rax, 8d ; extra margin for overread
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax ;FrameSizeRLE
                mov FrameDataRlePtr, rax
            .ELSE
                mov FrameDataRlePtr, 0
            .ENDIF
            .IF FrameSizeBMP != 0
                mov rax, FrameSizeBMP
                add rax, 1024d
                ; added for bad BAMC compressed rle bam frames: sphorpuf.bam frame 97 etc - to prevent stack/heap corruption 0xc0000374 on exit
                ; classic sphorpuf.bam seems to be issue, EE version is different - resized (and doesnt crash)
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, rax ;FrameSizeBMP
                mov FrameDataBmpPtr, rax
            .ELSE
                mov FrameDataBmpPtr, 0
            .ENDIF

            mov rbx, FrameDataEntryPtr
            mov rax, FrameCompressed
            mov [rbx].FRAMEDATA.FrameCompressed, rax
            mov rax, FrameSizeRAW
            mov [rbx].FRAMEDATA.FrameSizeRAW, rax
            mov rax, FrameSizeRLE
            mov [rbx].FRAMEDATA.FrameSizeRLE, rax
            mov rax, FrameSizeBMP
            mov [rbx].FRAMEDATA.FrameSizeBMP, rax
            mov rax, FrameWidth
            mov [rbx].FRAMEDATA.FrameWidth, rax
            mov rax, FrameHeight
            mov [rbx].FRAMEDATA.FrameHeight, rax
            mov rax, FrameXcoord
            mov [rbx].FRAMEDATA.FrameXcoord, rax
            mov rax, FrameYcoord
            mov [rbx].FRAMEDATA.FrameYcoord, rax
            mov rax, FrameDataRawPtr
            mov [rbx].FRAMEDATA.FrameRAW, rax
            mov rax, FrameDataRlePtr
            mov [rbx].FRAMEDATA.FrameRLE, rax
            mov rax, FrameDataBmpPtr
            mov [rbx].FRAMEDATA.FrameBMP, rax
            
            mov rax, BAMMemMapPtr
            add rax, FrameDataOffset
            .IF FrameCompressed == 1 ; uncompressed
                .IF FrameDataRawPtr != 0
                    Invoke RtlMoveMemory, FrameDataRawPtr, rax, FrameSizeRAW
                .ENDIF
                Invoke BAMFrameRAWToFrameBMP, FrameDataRawPtr, FrameDataBmpPtr, FrameSizeRAW, FrameSizeBMP, FrameWidth

            .ELSE ; compressed
                Invoke RtlMoveMemory, FrameDataRlePtr, rax, FrameSizeRLE
                mov rax, FrameSizeRLE
                .IF rax == FrameSizeRAW ; already uncompressed so just copy memory
                    Invoke RtlMoveMemory, FrameDataRawPtr, FrameDataRlePtr, FrameSizeRLE
                    Invoke RtlMoveMemory, FrameDataBmpPtr, FrameDataRlePtr, FrameSizeRLE
                
                .ELSEIF rax > FrameSizeRAW ; invalid bam, copy last bam frame to this
                    mov rax, nFrame
                    inc rax
                    .IF rax == TotalFrameEntries ; last frame problem RIPPLES_2.BAM
                        ; save pointers to current frame data info raw and rle data
                        mov rax, FrameDataRawPtr
                        mov tFrameDataRawPtr, rax
                        mov rax, FrameDataRlePtr
                        mov tFrameDataRlePtr, rax
                        mov rax, FrameDataBmpPtr
                        mov tFrameDataBmpPtr, rax
                        
                        mov rbx, FrameDataEntryPtr
                        sub rbx, SIZEOF FRAMEDATA ; get frame before
                        mov rax, [rbx].FRAMEDATA.FrameSizeRLE
                        mov FrameSizeRLE, rax
                        mov rax, [rbx].FRAMEDATA.FrameSizeBMP
                        mov FrameSizeBMP, rax
                        mov rax, [rbx].FRAMEDATA.FrameWidth
                        mov FrameWidth, rax
                        mov rax, [rbx].FRAMEDATA.FrameHeight
                        mov FrameHeight, rax
                        mov rax, [rbx].FRAMEDATA.FrameXcoord
                        mov FrameXcoord, rax
                        mov rax, [rbx].FRAMEDATA.FrameYcoord
                        mov FrameYcoord, rax
                        mov rax, [rbx].FRAMEDATA.FrameRAW
                        mov FrameDataRawPtr, rax
                        mov rax, [rbx].FRAMEDATA.FrameRLE
                        mov FrameDataRlePtr, rax
                        mov rax, [rbx].FRAMEDATA.FrameBMP
                        mov FrameDataBmpPtr, rax

                        .IF FrameDataRawPtr != 0
                            Invoke RtlMoveMemory, tFrameDataRawPtr, FrameDataRawPtr, FrameSizeRAW
                            Invoke RtlMoveMemory, tFrameDataBmpPtr, FrameDataBmpPtr, FrameSizeBMP
                        .ENDIF
                        .IF FrameDataRlePtr != 0
                            Invoke RtlMoveMemory, tFrameDataRlePtr, FrameDataRlePtr, FrameSizeRLE
                        .ENDIF
                        
                        mov rbx, FrameDataEntryPtr ; back to current frame to update sizes
                        mov rax, FrameSizeRLE
                        mov [rbx].FRAMEDATA.FrameSizeRLE, rax

                    .ENDIF
                        
                .ELSE ; otherwise unRLE mem to raw storage
                    Invoke BAMFrameUnRLE, FrameDataRlePtr, FrameSizeRLE, FrameDataRawPtr, FrameSizeRAW
                    mov FrameSizeRAW, rax
                    mov rbx, FrameDataEntryPtr
                    mov [rbx].FRAMEDATA.FrameSizeRAW, rax ; put correct raw size here
                    Invoke BAMFrameRAWToFrameBMP, FrameDataRawPtr, FrameDataBmpPtr, FrameSizeRAW, FrameSizeBMP, FrameWidth
                .ENDIF
            .ENDIF
            
            ; copy data to our framedata entry.
            add FrameEntryPtr, SIZEOF FRAMEV1_ENTRY
            add FrameDataEntryPtr, SIZEOF FRAMEDATA
            
            inc nFrame
            mov rax, nFrame
        .ENDW

    .ELSE
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameDataEntriesPtr, 0
        mov [rbx].BAMINFO.BAMFrameDataEntriesSize, 0
    .ENDIF

    mov rax, hIEBAM
    ret
BAMV1Mem ENDP


IEBAM_ALIGN
;------------------------------------------------------------------------------
; BAMV2Mem - Returns handle in rax of opened bam file that is already loaded into memory. NULL if could not alloc enough mem
;------------------------------------------------------------------------------
BAMV2Mem PROC FRAME USES RBX RCX RDX RDI RSI pBAMInMemory:QWORD, lpszBamFilename:QWORD, qwBamFilesize:QWORD, qwOpenMode:QWORD
    LOCAL hIEBAM:QWORD
    LOCAL BAMMemMapPtr:QWORD
    LOCAL TotalFrameEntries:QWORD
    LOCAL TotalCycleEntries:QWORD
    LOCAL TotalBlockEntries:QWORD
    LOCAL FrameEntriesSize:QWORD
    LOCAL CycleEntriesSize:QWORD
    LOCAL BlockEntriesSize:QWORD
    LOCAL FrameLookupSize:QWORD
    LOCAL OffsetFrameEntries:QWORD
    LOCAL OffsetCycleEntries:QWORD
    LOCAL OffsetBlockEntries:QWORD
    LOCAL FrameEntriesPtr:QWORD
    LOCAL FrameEntryPtr:QWORD
    LOCAL CycleEntriesPtr:QWORD
    LOCAL CycleEntryPtr:QWORD
    LOCAL BlockEntriesPtr:QWORD
    LOCAL FrameLookupEntriesPtr:QWORD
    LOCAL FrameLookupEntryPtr:QWORD
    LOCAL AllFramesDataSize:QWORD
    LOCAL FrameDataEntriesPtr:QWORD
    LOCAL FrameDataEntryPtr:QWORD
    LOCAL nCycle:QWORD
    LOCAL nFrame:QWORD
    LOCAL nCycleIndexStart:QWORD
    LOCAL nCycleIndexCount:QWORD
    LOCAL SequenceSize:QWORD
    LOCAL SequencePtr:QWORD
    LOCAL FrameCompressed:QWORD
    LOCAL FrameDataOffset:QWORD
    LOCAL FrameDataRLE:QWORD
    LOCAL FrameWidth:QWORD
    LOCAL FrameHeight:QWORD
    LOCAL FrameXcoord:QWORD
    LOCAL FrameYcoord:QWORD
    LOCAL FrameWidthDwordAligned:QWORD
    LOCAL FrameHeightDwordAligned:QWORD
    LOCAL FrameSize:QWORD
    LOCAL FrameSizeRAW:QWORD
    LOCAL FrameSizeRLE:QWORD
    LOCAL FrameSizeBMP:QWORD
    LOCAL FrameDataRawPtr:QWORD
    LOCAL FrameDataRlePtr:QWORD
    LOCAL FrameDataBmpPtr:QWORD
    LOCAL DataBlockIndex:QWORD
    LOCAL DataBlockCount:QWORD

    mov rax, pBAMInMemory
    mov BAMMemMapPtr, rax      

    ;----------------------------------
    ; Alloc mem for our IEBAM Handle
    ;----------------------------------
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BAMINFO
    .IF rax == NULL
        ret
    .ENDIF
    mov hIEBAM, rax
    
    mov rbx, hIEBAM
    mov rax, qwOpenMode
    mov [rbx].BAMINFO.BAMOpenMode, rax
    mov rax, BAMMemMapPtr
    mov [rbx].BAMINFO.BAMMemMapPtr, rax
    
    lea rax, [rbx].BAMINFO.BAMFilename
    Invoke lstrcpy, rax, lpszBamFilename
    ;Invoke szCopy, lpszBamFilename, rax
    
    mov rbx, hIEBAM
    mov rax, qwBamFilesize
    mov [rbx].BAMINFO.BAMFilesize, rax

    ;----------------------------------
    ; BAM Header
    ;----------------------------------
    .IF qwOpenMode == IEBAM_MODE_WRITE
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SIZEOF BAMV2_HEADER
        .IF rax == NULL
            Invoke GlobalFree, hIEBAM
            mov rax, NULL
            ret
        .ENDIF    
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMHeaderPtr, rax
        mov rbx, BAMMemMapPtr
        Invoke RtlMoveMemory, rax, rbx, SIZEOF BAMV2_HEADER
    .ELSE
        mov rbx, hIEBAM
        mov rax, BAMMemMapPtr
        mov [rbx].BAMINFO.BAMHeaderPtr, rax
    .ENDIF
    mov rbx, hIEBAM
    mov rax, SIZEOF BAMV2_HEADER
    mov [rbx].BAMINFO.BAMHeaderSize, rax   

    ;----------------------------------
    ; Frame & Cycle Counts, Offsets & Sizes
    ;----------------------------------
    mov rbx, [rbx].BAMINFO.BAMHeaderPtr
    mov eax, dword ptr [rbx].BAMV2_HEADER.FrameEntriesCount
    mov TotalFrameEntries, rax
    mov eax, dword ptr [rbx].BAMV2_HEADER.CycleEntriesCount
    mov TotalCycleEntries, rax
    mov eax, dword ptr [rbx].BAMV2_HEADER.BlockEntriesCount
    mov TotalBlockEntries, rax
    mov eax, dword ptr [rbx].BAMV2_HEADER.FrameEntriesOffset
    mov OffsetFrameEntries, rax
    mov eax, dword ptr [rbx].BAMV2_HEADER.CycleEntriesOffset
    mov OffsetCycleEntries, rax    
    mov eax, dword ptr [rbx].BAMV2_HEADER.BlockEntriesOffset
    mov OffsetBlockEntries, rax
    
    mov rax, TotalFrameEntries
    mov rbx, SIZEOF FRAMEV2_ENTRY
    mul rbx
    mov FrameEntriesSize, rax
    
    mov rax, TotalCycleEntries
    mov rbx, SIZEOF CYCLEV2_ENTRY
    mul rbx
    mov CycleEntriesSize, rax
    
    mov rax, TotalBlockEntries
    mov rbx, SIZEOF DATABLOCK_ENTRY
    mul rbx
    mov BlockEntriesSize, rax

    ;----------------------------------
    ; No Palette for BAM V2!
    ;----------------------------------
    mov rbx, hIEBAM
    mov [rbx].BAMINFO.BAMPalettePtr, 0
    mov [rbx].BAMINFO.BAMPaletteSize, 0

    ;----------------------------------
    ; Frame Entries
    ;----------------------------------
    .IF TotalFrameEntries > 0
        .IF qwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameEntriesSize
            .IF rax == NULL
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov rax, NULL    
                ret
            .ENDIF    
            mov rbx, hIEBAM
            mov [rbx].BAMINFO.BAMFrameEntriesPtr, rax
            mov FrameEntriesPtr, rax
        
            mov rbx, BAMMemMapPtr
            add rbx, OffsetFrameEntries
            Invoke RtlMoveMemory, rax, rbx, FrameEntriesSize
        .ELSE
            mov rbx, hIEBAM
            mov rax, BAMMemMapPtr
            add rax, OffsetFrameEntries
            mov [rbx].BAMINFO.BAMFrameEntriesPtr, rax
            mov FrameEntriesPtr, rax
        .ENDIF
        mov rbx, hIEBAM
        mov rax, FrameEntriesSize
        mov [rbx].BAMINFO.BAMFrameEntriesSize, rax    
    .ELSE
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameEntriesPtr, 0
        mov [rbx].BAMINFO.BAMFrameEntriesSize, 0
        mov FrameEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Cycle Entries
    ;----------------------------------
    .IF TotalCycleEntries > 0
        .IF qwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, CycleEntriesSize
            .IF rax == NULL
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMFrameEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov rax, NULL    
                ret
            .ENDIF    
            mov rbx, hIEBAM
            mov [rbx].BAMINFO.BAMCycleEntriesPtr, rax
            mov CycleEntriesPtr, rax
        
            mov rbx, BAMMemMapPtr
            add rbx, OffsetCycleEntries
            Invoke RtlMoveMemory, rax, rbx, CycleEntriesSize
        .ELSE
            mov rbx, hIEBAM
            mov rax, BAMMemMapPtr
            add rax, OffsetCycleEntries
            mov [rbx].BAMINFO.BAMCycleEntriesPtr, rax
            mov CycleEntriesPtr, rax
        .ENDIF
        mov rbx, hIEBAM
        mov rax, CycleEntriesSize
        mov [rbx].BAMINFO.BAMCycleEntriesSize, rax   
    .ELSE
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMCycleEntriesPtr, 0
        mov [rbx].BAMINFO.BAMCycleEntriesSize, 0
        mov CycleEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Data Block Entries
    ;----------------------------------
    .IF TotalBlockEntries > 0
        .IF qwOpenMode == IEBAM_MODE_WRITE
            Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, BlockEntriesSize
            .IF rax == NULL
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMCycleEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF            
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMFrameEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                Invoke GlobalFree, hIEBAM
                mov rax, NULL    
                ret
            .ENDIF    
            mov rbx, hIEBAM
            mov [rbx].BAMINFO.BAMBlockEntriesPtr, rax
            mov BlockEntriesPtr, rax
        
            mov rbx, BAMMemMapPtr
            add rbx, OffsetBlockEntries
            Invoke RtlMoveMemory, rax, rbx, BlockEntriesSize
        .ELSE
            mov rbx, hIEBAM
            mov rax, BAMMemMapPtr
            add rax, OffsetBlockEntries
            mov [rbx].BAMINFO.BAMBlockEntriesPtr, rax
            mov BlockEntriesPtr, rax
        .ENDIF
        mov rbx, hIEBAM
        mov rax, BlockEntriesSize
        mov [rbx].BAMINFO.BAMBlockEntriesSize, rax   
    .ELSE
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMBlockEntriesPtr, 0
        mov [rbx].BAMINFO.BAMBlockEntriesSize, 0
        mov BlockEntriesPtr, 0
    .ENDIF

    ;----------------------------------
    ; Alloc space for FrameLookup
    ;----------------------------------
    ; Calc size of FrameLookup Table
    .IF TotalCycleEntries > 0
        mov rax, TotalCycleEntries
        mov rbx, SIZEOF FRAMELOOKUPTABLE
        mul rbx
        mov FrameLookupSize, rax 

        ; Alloc space for framelookup table
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameLookupSize
        .IF rax == NULL
            .IF qwOpenMode == IEBAM_MODE_WRITE
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMBlockEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMCycleEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMFrameEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
            .ENDIF
            Invoke GlobalFree, hIEBAM
            mov rax, NULL    
            ret
        .ENDIF
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameLookupPtr, rax
        mov FrameLookupEntriesPtr, rax
        mov rax, FrameLookupSize
        mov [rbx].BAMINFO.BAMFrameLookupSize, rax
        
        mov rax, FrameLookupEntriesPtr
        mov FrameLookupEntryPtr, rax
        
        mov rax, CycleEntriesPtr
        mov CycleEntryPtr, rax

        ; loop through cycles, get framelookup start index and count, get this data and copy it to a mem entry of our own lookup table
        mov nCycle, 0
        mov rax, 0
        .WHILE rax < TotalCycleEntries
            mov rbx, CycleEntryPtr
            movzx rax, word ptr [rbx].CYCLEV1_ENTRY.CycleFrameCount
            mov nCycleIndexCount, rax
            movzx rax, word ptr [rbx].CYCLEV1_ENTRY.CycleStartFrame
            mov nCycleIndexStart, rax

            .IF nCycleIndexCount > 0
                ; calc size of sequence
                mov rax, nCycleIndexCount
                mov rbx, 2d ; word sized array
                mul rbx
                mov SequenceSize, rax
            .ELSE
                mov SequenceSize, 0
            .ENDIF

            ; alloc mem for sequence
            .IF nCycleIndexCount > 0 
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, SequenceSize ;nCycleIndexCount ;SequenceSize
                mov SequencePtr, rax
                
                ; create fake lookup table for each cycles sequence - BAM V2 has start frame in cycle, and count - no lookup
                ; loop cycle count amount of times, place a word value for sequence, incremented each loop till end of loop
                mov rax, nCycleIndexStart
                mov rbx, SequencePtr
                mov rcx, 0
                .WHILE rcx < nCycleIndexCount
                    mov word ptr [rbx], ax
                    add rbx, 2d ; word array size
                    inc rax ; increment frame index for next iteration
                    inc rcx ; inc counter
                .ENDW
                
            .ELSE
                mov SequencePtr, 0
            .ENDIF
            
            ; Assign memory ptr of sequence to our own lookup table entry
            mov rbx, FrameLookupEntryPtr
            mov rax, SequenceSize ;nCycleIndexCount ;SequenceSize
            mov [rbx].FRAMELOOKUPTABLE.SequenceSize, rax
            mov rax, SequencePtr
            mov [rbx].FRAMELOOKUPTABLE.SequenceData, rax

            add CycleEntryPtr, SIZEOF CYCLEV2_ENTRY
            add FrameLookupEntryPtr, SIZEOF FRAMELOOKUPTABLE            
            
            inc nCycle
            mov rax, nCycle
        .ENDW
    .ELSE
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameLookupPtr, 0
        mov [rbx].BAMINFO.BAMFrameLookupSize, 0
    .ENDIF

    ;----------------------------------
    ; Alloc space for FrameDataEntries
    ;----------------------------------
    ; loop through frame entries, get frame data for each frame and save to our own structure
    .IF TotalFrameEntries > 0
        mov rax, TotalFrameEntries
        mov rbx, SIZEOF FRAMEDATA
        mul rbx
        mov AllFramesDataSize, rax
      
        Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, AllFramesDataSize
        .IF rax == NULL
            .IF qwOpenMode == IEBAM_MODE_WRITE
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMFrameLookupPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF    
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMBlockEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMCycleEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMFrameEntriesPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
                mov rbx, hIEBAM
                mov rax, [rbx].BAMINFO.BAMHeaderPtr
                .IF rax != NULL
                    Invoke GlobalFree, rax
                .ENDIF
            .ENDIF    
            Invoke GlobalFree, hIEBAM
            mov rax, NULL    
            ret
        .ENDIF
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameDataEntriesPtr, rax
        mov FrameDataEntriesPtr, rax
        mov rax, AllFramesDataSize
        mov [rbx].BAMINFO.BAMFrameDataEntriesSize, rax

        mov rax, FrameEntriesPtr
        mov FrameEntryPtr, rax
        
        mov rax, FrameDataEntriesPtr
        mov FrameDataEntryPtr, rax
        
        mov nFrame, 0
        mov rax, 0
        .WHILE rax < TotalFrameEntries
            mov rbx, FrameEntryPtr
            movzx rax, word ptr [rbx].FRAMEV2_ENTRY.FrameWidth
            mov FrameWidth, rax
            movzx rax, word ptr [rbx].FRAMEV2_ENTRY.FrameHeight
            mov FrameHeight, rax
            movzx rax, word ptr [rbx].FRAMEV2_ENTRY.FrameXcoord
            mov FrameXcoord, rax
            movzx rax, word ptr [rbx].FRAMEV2_ENTRY.FrameYcoord
            mov FrameYcoord, rax
            movzx rax, word ptr [rbx].FRAMEV2_ENTRY.DataBlockIndex
            mov DataBlockIndex, rax
            movzx rax, word ptr [rbx].FRAMEV2_ENTRY.DataBlockCount
            mov DataBlockCount, rax
            
            ; calc qword aligned width and height
            Invoke BAMCalcDwordAligned, FrameWidth
            mov FrameWidthDwordAligned, rax
            
            Invoke BAMCalcDwordAligned, FrameHeight
            mov FrameHeightDwordAligned, rax

            mov FrameCompressed, -1 ; not applicable
            mov FrameSizeRLE, 0

            mov rax, FrameWidthDwordAligned
            mov rbx, FrameHeightDwordAligned
            mul rbx
            mov FrameSizeRAW, rax ; set max qword size for pvrz textures
            mov FrameSizeBMP, rax
            
            .IF FrameSizeRAW != 0
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameSizeRAW
                mov FrameDataRawPtr, rax
            .ELSE
                mov FrameDataRawPtr, 0
            .ENDIF
            mov FrameDataRlePtr, 0

            .IF FrameSizeBMP != 0
                Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, FrameSizeBMP
                mov FrameDataBmpPtr, rax
            .ELSE
                mov FrameDataBmpPtr, 0
            .ENDIF

            ; calc offset to our frame data array, 
            mov rbx, FrameDataEntryPtr

            mov rax, FrameCompressed
            mov [rbx].FRAMEDATA.FrameCompressed, rax
            mov rax, FrameSizeRAW
            mov [rbx].FRAMEDATA.FrameSizeRAW, rax
            mov rax, FrameSizeRLE
            mov [rbx].FRAMEDATA.FrameSizeRLE, rax
            mov rax, FrameSizeBMP
            mov [rbx].FRAMEDATA.FrameSizeBMP, rax
            mov rax, FrameWidth
            mov [rbx].FRAMEDATA.FrameWidth, rax
            mov rax, FrameHeight
            mov [rbx].FRAMEDATA.FrameHeight, rax
            mov rax, FrameXcoord
            mov [rbx].FRAMEDATA.FrameXcoord, rax
            mov rax, FrameYcoord
            mov [rbx].FRAMEDATA.FrameYcoord, rax
            mov rax, FrameDataRawPtr
            mov [rbx].FRAMEDATA.FrameRAW, rax
            mov rax, FrameDataRlePtr
            mov [rbx].FRAMEDATA.FrameRLE, rax
            mov rax, FrameDataBmpPtr
            mov [rbx].FRAMEDATA.FrameBMP, rax
            mov rax, DataBlockIndex
            mov [rbx].FRAMEDATA.FrameDataBlockIndex, rax
            mov rax, DataBlockCount
            mov [rbx].FRAMEDATA.FrameDataBlockCount, rax
            
            add FrameEntryPtr, SIZEOF FRAMEV2_ENTRY
            add FrameDataEntryPtr, SIZEOF FRAMEDATA
            
            inc nFrame
            mov rax, nFrame
        .ENDW

    .ELSE
        mov rbx, hIEBAM
        mov [rbx].BAMINFO.BAMFrameDataEntriesPtr, 0
        mov [rbx].BAMINFO.BAMFrameDataEntriesSize, 0
    .ENDIF
    
    mov rax, hIEBAM 
    ret
BAMV2Mem ENDP




IEBAM_LIBEND






