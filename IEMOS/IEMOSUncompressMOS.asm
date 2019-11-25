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

includelib kernel32.lib
includelib user32.lib

include masm64.inc
includelib masm64.lib

include zlibstat1211.inc
includelib zlibstat1211.lib

include IEMOS.inc

EXTERNDEF MOSUncompress     :PROTO hMOSFile:QWORD, pMOS:QWORD, qwSize:QWORD
EXTERNDEF MOSSignature      :PROTO pMOS:QWORD
EXTERNDEF MOSJustFname      :PROTO szFilePathName:QWORD, szFileName:QWORD

.DATA
UncompressTmpExt            DB ".tmp",0
UncompressMOSExt            DB ".mos",0

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; Uncompress specified mos file name
;------------------------------------------------------------------------------
IEMOSUncompressMOS PROC FRAME USES RBX lpszMosFilenameIN:QWORD, lpszMosFilenameOUT:QWORD
    LOCAL szMosFilenameOUT[MAX_PATH]:BYTE
    LOCAL szMosFilenameALT[MAX_PATH]:BYTE
    LOCAL hMosIN:QWORD
    LOCAL hMosOUT:QWORD
    LOCAL MosMemMapHandleIN:QWORD
    LOCAL MosMemMapHandleOUT:QWORD
    LOCAL MosMemMapPtrIN:QWORD
    LOCAL MosMemMapPtrOUT:QWORD
    LOCAL MosFilesizeIN:QWORD
    LOCAL MosFilesizeHighIN:QWORD
    LOCAL FilesizeOUT:QWORD
    LOCAL ptrUncompressedData:QWORD
    LOCAL Version:QWORD
    LOCAL TmpFileFlag:QWORD
    
    mov TmpFileFlag, FALSE
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Input File
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke CreateFile, lpszMosFilenameIN, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL ; readonly
    .IF rax == INVALID_HANDLE_VALUE
        mov rax, MU_MOS_INPUTFILE_OPEN
        ret
    .ENDIF
    mov hMosIN, rax
    
    ; check file size is not 0
    Invoke GetFileSize, hMosIN, Addr MosFilesizeHighIN
    mov MosFilesizeIN, rax
    .IF MosFilesizeIN == 0 && MosFilesizeHighIN == 0
        Invoke CloseHandle, hMosIN
        mov rax, MU_MOS_INPUTFILE_ZEROSIZE
        ret
    .ENDIF   
    
    .IF MosFilesizeIN > 20000000h || MosFilesizeHighIN > 0 ; 2^29 = 536870912 = 536,870,912 bytes = 536MB
        mov rax, MU_MOS_TOO_LARGE
        ret
    .ENDIF
    
    Invoke CreateFileMapping, hMosIN, NULL, PAGE_READONLY, 0, 0, NULL ; Create memory mapped file
    .IF rax == NULL
        Invoke CloseHandle, hMosIN
        mov rax, MU_MOS_INPUTFILE_MAPPING
        ret        
    .ENDIF
    mov MosMemMapHandleIN, rax

    Invoke MapViewOfFileEx, MosMemMapHandleIN, FILE_MAP_READ, 0, 0, 0, NULL
    .IF rax == NULL
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN
        mov rax, MU_MOS_INPUTFILE_VIEW
        ret
    .ENDIF
    mov MosMemMapPtrIN, rax
    
    Invoke MOSSignature, MosMemMapPtrIN
    mov Version, rax

    .IF Version == MOS_VERSION_MOSCV10 ; MOSC compressed, ready to uncompress
        Invoke MOSUncompress, hMosIN, MosMemMapPtrIN, Addr FilesizeOUT
        .IF rax == 0
            Invoke UnmapViewOfFile, MosMemMapPtrIN
            Invoke CloseHandle, MosMemMapHandleIN
            Invoke CloseHandle, hMosIN        
            mov rax, MU_MOS_UNCOMPRESS_ERROR
            ret
        .ENDIF
        mov ptrUncompressedData, rax

    .ELSE ; if 0,1,2 or other
        Invoke UnmapViewOfFile, MosMemMapPtrIN
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN
        .IF Version == MOS_VERSION_INVALID ; invalid mos
            mov rax, MU_MOS_INVALID
        .ELSEIF Version == MOS_VERSION_MOS_V10 ; already uncompressed
            mov rax, MU_MOS_ALREADY_UNCOMPRESSED
        .ELSEIF Version == MOS_VERSION_MOS_V20 ; MOS 2.0 not supported
            mov rax, MU_MOS_FORMAT_UNSUPPORTED
        .ELSE
            mov rax, MU_MOS_FORMAT_UNSUPPORTED
        .ENDIF
        ret
    .ENDIF
    
    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Output File 
    ; ---------------------------------------------------------------------------------------------------------------------------
    mov rax, lpszMosFilenameOUT
    .IF rax == NULL ;|| (lpszMosFilenameIN == rax) ; use same name for output, but temporarily use another file name before copying over exiting one
        Invoke szCopy, lpszMosFilenameIN, Addr szMosFilenameOUT
        Invoke szCatStr, Addr szMosFilenameOUT, Addr UncompressTmpExt
        mov TmpFileFlag, TRUE
    .ELSE
        
        Invoke Cmpi, lpszMosFilenameOUT, lpszMosFilenameIN
        .IF rax == 0 ; match        
            Invoke szCopy, lpszMosFilenameIN, Addr szMosFilenameOUT
            Invoke szCatStr, Addr szMosFilenameOUT, Addr UncompressTmpExt
            mov TmpFileFlag, TRUE
        .ELSE
            Invoke szCopy, lpszMosFilenameOUT, Addr szMosFilenameOUT
            mov TmpFileFlag, FALSE
        .ENDIF
    .ENDIF
    
    Invoke CreateFile, Addr szMosFilenameOUT, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY, NULL    
    .IF rax == INVALID_HANDLE_VALUE
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, MosMemMapPtrIN
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN    
        mov rax, MU_MOS_OUTPUTFILE_CREATION
        ret
    .ENDIF
    mov hMosOUT, rax

    Invoke CreateFileMapping, hMosOUT, NULL, PAGE_READWRITE, 0, dword ptr FilesizeOUT, NULL ; Create memory mapped file
    .IF rax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, MosMemMapPtrIN
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN    
        Invoke CloseHandle, hMosOUT
        mov rax, MU_MOS_OUTPUTFILE_MAPPING
        ret        
    .ENDIF
    mov MosMemMapHandleOUT, rax

    Invoke MapViewOfFileEx, MosMemMapHandleOUT, FILE_MAP_ALL_ACCESS, 0, 0, 0, NULL
    .IF rax == NULL
        Invoke GlobalFree, ptrUncompressedData
        Invoke UnmapViewOfFile, MosMemMapPtrIN
        Invoke CloseHandle, MosMemMapHandleIN
        Invoke CloseHandle, hMosIN    
        Invoke CloseHandle, MosMemMapHandleOUT
        Invoke CloseHandle, hMosOUT
        mov rax, MU_MOS_OUTPUTFILE_VIEW
        ret
    .ENDIF
    mov MosMemMapPtrOUT, rax

    ; ---------------------------------------------------------------------------------------------------------------------------
    ; Copy uncompressed data in memory to output file mapping, close files and then copy over filenames if applicable
    ; ---------------------------------------------------------------------------------------------------------------------------
    Invoke RtlMoveMemory, MosMemMapPtrOUT, ptrUncompressedData, FilesizeOUT

    Invoke GlobalFree, ptrUncompressedData
    Invoke UnmapViewOfFile, MosMemMapPtrIN
    Invoke CloseHandle, MosMemMapHandleIN
    Invoke CloseHandle, hMosIN
    Invoke UnmapViewOfFile, MosMemMapPtrOUT
    Invoke CloseHandle, MosMemMapHandleOUT
    Invoke CloseHandle, hMosOUT
    
    ;mov rax, lpszMosFilenameOUT
    .IF TmpFileFlag == TRUE  ;rax == NULL || (lpszMosFilenameIN == rax)  ; we need to copy over outfile to infile
        Invoke CopyFile, Addr szMosFilenameOUT, lpszMosFilenameIN, FALSE
        Invoke DeleteFile, Addr szMosFilenameOUT
    .ENDIF
    
    mov rax, MU_SUCCESS
    ret
IEMOSUncompressMOS ENDP




IEMOS_LIBEND

