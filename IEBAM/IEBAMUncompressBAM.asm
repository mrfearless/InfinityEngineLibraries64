;==============================================================================
;
; IEBAM x64 Library
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

include Masm64.Inc
includelib Masm64.lib

include zlibstat1211.inc
includelib zlibstat1211.lib

include IEBAM.inc

EXTERNDEF BAMUncompress     :PROTO hBAMFile:QWORD, pBAM:QWORD, qwSize:QWORD
EXTERNDEF BAMSignature      :PROTO pBAM:QWORD
EXTERNDEF BAMJustFname      :PROTO szFilePathName:QWORD, szFileName:QWORD

.DATA
UncompressTmpExt            DB ".tmp",0
UncompressBAMExt            DB ".bam",0

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Uncompress specified bam file name
;------------------------------------------------------------------------------
IEBAMUncompressBAM PROC FRAME USES RBX lpszBamFilenameIN:QWORD, lpszBamFilenameOUT:QWORD
    LOCAL szBamFilenameOUT[MAX_PATH]:BYTE
    LOCAL szBamFilenameALT[MAX_PATH]:BYTE
    LOCAL hBamIN:QWORD
    LOCAL hBamOUT:QWORD
    LOCAL BamMemMapHandleIN:QWORD
    LOCAL BamMemMapHandleOUT:QWORD
    LOCAL BamMemMapPtrIN:QWORD
    LOCAL BamMemMapPtrOUT:QWORD
    LOCAL BamFilesizeIN:QWORD
    LOCAL BamFilesizeHighIN:QWORD
    LOCAL FilesizeOUT:QWORD
    LOCAL ptrUncompressedData:QWORD
    LOCAL Version:QWORD
    LOCAL TmpFileFlag:QWORD
    
    mov TmpFileFlag, FALSE
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Input File
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke CreateFile, lpszBamFilenameIN, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL ; readonly
    .IF rax == INVALID_HANDLE_VALUE
        mov rax, BU_BAM_INPUTFILE_OPEN
        ret
    .ENDIF
    mov hBamIN, rax
    
    ; check file size is not 0
    Invoke GetFileSize, hBamIN, Addr BamFilesizeHighIN
    mov BamFilesizeIN, rax
    .IF BamFilesizeIN == 0 && BamFilesizeHighIN == 0
        Invoke CloseHandle, hBamIN
        mov rax, BU_BAM_INPUTFILE_ZEROSIZE
        ret
    .ENDIF   
    
    .IF BamFilesizeIN > 20000000h || BamFilesizeHighIN > 0 ; 2^29 = 536870912 = 536,870,912 bytes = 536MB
        mov rax, BU_BAM_TOO_LARGE
        ret
    .ENDIF
    
    Invoke CreateFileMapping, hBamIN, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .IF rax == NULL
        Invoke CloseHandle, hBamIN
        mov rax, BU_BAM_INPUTFILE_MAPPING
        ret        
    .ENDIF
    mov BamMemMapHandleIN, rax

    Invoke MapViewOfFileEx, BamMemMapHandleIN, FILE_MAP_READ, 0, 0, 0, NULL
    .IF rax == NULL
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN
        mov rax, BU_BAM_INPUTFILE_VIEW
        ret
    .ENDIF
    mov BamMemMapPtrIN, rax
    
    Invoke BAMSignature, BamMemMapPtrIN
    mov Version, rax

    .IF Version == BAM_VERSION_BAMCV10 ; BAMC compressed, ready to uncompress
        Invoke BAMUncompress, hBamIN, BamMemMapPtrIN, Addr FilesizeOUT
        .IF rax == 0
            Invoke UnmapViewOfFile, BamMemMapPtrIN
            Invoke CloseHandle, BamMemMapHandleIN
            Invoke CloseHandle, hBamIN        
            mov rax, BU_BAM_UNCOMPRESS_ERROR
            ret
        .ENDIF
        mov ptrUncompressedData, rax

    .ELSE ; if 0,1,2 or other
        Invoke UnmapViewOfFile, BamMemMapPtrIN
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN
        .IF Version == BAM_VERSION_INVALID ; invalid bam
            mov rax, BU_BAM_INVALID
        .ELSEIF Version == BAM_VERSION_BAM_V10 ; already uncompressed
            mov rax, BU_BAM_ALREADY_UNCOMPRESSED
        .ELSEIF Version == BAM_VERSION_BAM_V20 ; BAM 2.0 not supported
            mov rax, BU_BAM_FORMAT_UNSUPPORTED
        .ELSE
            mov rax, BU_BAM_FORMAT_UNSUPPORTED
        .ENDIF
        ret
    .ENDIF
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Output File 
    ; ---------------------------------------------------------------------------------------------------------------------------
    mov rax, lpszBamFilenameOUT
    .IF rax == NULL ;|| (lpszBamFilenameIN == rax) ; use same name for output, but temporarily use another file name before copying over exiting one
        Invoke szCopy, lpszBamFilenameIN, Addr szBamFilenameOUT
        Invoke szCatStr, Addr szBamFilenameOUT, Addr UncompressTmpExt
        mov TmpFileFlag, TRUE
    .ELSE
        
        Invoke Cmpi, lpszBamFilenameOUT, lpszBamFilenameIN
        .IF rax == 0 ; match        
            Invoke szCopy, lpszBamFilenameIN, Addr szBamFilenameOUT
            Invoke szCatStr, Addr szBamFilenameOUT, Addr UncompressTmpExt
            mov TmpFileFlag, TRUE
        .ELSE
            Invoke szCopy, lpszBamFilenameOUT, Addr szBamFilenameOUT
            mov TmpFileFlag, FALSE
        .ENDIF
    .ENDIF
    
    Invoke CreateFile, Addr szBamFilenameOUT, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, NULL    
    .IF rax == INVALID_HANDLE_VALUE
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, BamMemMapPtrIN
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN    
        mov rax, BU_BAM_OUTPUTFILE_CREATION
        ret
    .ENDIF
    mov hBamOUT, rax

    Invoke CreateFileMapping, hBamOUT, NULL, PAGE_READWRITE, 0, dword ptr FilesizeOUT, NULL ; Create memory mapped file
    .IF rax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, BamMemMapPtrIN
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN    
        Invoke CloseHandle, hBamOUT
        mov rax, BU_BAM_OUTPUTFILE_MAPPING
        ret        
    .ENDIF
    mov BamMemMapHandleOUT, rax

    Invoke MapViewOfFileEx, BamMemMapHandleOUT, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .IF rax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, BamMemMapPtrIN
        Invoke CloseHandle, BamMemMapHandleIN
        Invoke CloseHandle, hBamIN    
        Invoke CloseHandle, BamMemMapHandleOUT
        Invoke CloseHandle, hBamOUT
        mov rax, BU_BAM_OUTPUTFILE_VIEW
        ret
    .ENDIF
    mov BamMemMapPtrOUT, rax

    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Copy uncompressed data in memory to output file mapping, close files and then copy over filenames if applicable
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke RtlMoveMemory, BamMemMapPtrOUT, ptrUncompressedData, FilesizeOUT

    Invoke GlobalFree, ptrUncompressedData
    Invoke UnmapViewOfFile, BamMemMapPtrIN
    Invoke CloseHandle, BamMemMapHandleIN
    Invoke CloseHandle, hBamIN
    Invoke UnmapViewOfFile, BamMemMapPtrOUT
    Invoke CloseHandle, BamMemMapHandleOUT
    Invoke CloseHandle, hBamOUT
    
    ;mov rax, lpszBamFilenameOUT
    .IF TmpFileFlag == TRUE  ;rax == NULL || (lpszBamFilenameIN == eax)  ; we need to copy over outfile to infile
        Invoke CopyFile, Addr szBamFilenameOUT, lpszBamFilenameIN, FALSE
        Invoke DeleteFile, Addr szBamFilenameOUT
    .ENDIF
    
    mov rax, BU_SUCCESS
    ret
IEBAMUncompressBAM ENDP


IEBAM_LIBEND

