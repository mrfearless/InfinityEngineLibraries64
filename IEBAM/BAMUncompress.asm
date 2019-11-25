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
;include masm64.inc
include zlibstat.inc

includelib kernel32.lib
includelib user32.lib

include zlibstat1211.inc
includelib zlibstat1211.lib


include IEBAM.inc

BAMUncompress PROTO :QWORD, :QWORD, :QWORD


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Uncompresses BAMC file to an area of memory that we allocate for the exact 
; size of data
;------------------------------------------------------------------------------
BAMUncompress PROC FRAME USES RBX hBAMFile:QWORD, pBAM:QWORD, qwSize:QWORD
    LOCAL dest:QWORD
    LOCAL src:QWORD
    LOCAL BAMU_Size:QWORD
    LOCAL BytesRead:QWORD
    LOCAL BAMFilesize:QWORD
    LOCAL BAMC_UncompressedSize:QWORD
    LOCAL BAMC_CompressedSize:QWORD
    
    Invoke GetFileSize, hBAMFile, NULL
    mov BAMFilesize, rax
    mov rbx, pBAM
    xor rax, rax
    mov eax, dword ptr [rbx].BAMC_HEADER.UncompressedLength
    mov BAMC_UncompressedSize, rax
    mov rax, BAMFilesize
    sub rax, 0Ch ; take away the BAMC header 12 bytes = 0xC
    mov BAMC_CompressedSize, rax ; set correct compressed size = length of file minus BAMC header length
    
    mov rax, BAMC_UncompressedSize
    add rax, 64
    Invoke GlobalAlloc, GMEM_FIXED or GMEM_ZEROINIT, eax ;BAMC_UncompressedSize
    .IF rax != NULL
        mov dest, rax
        mov rax, pBAM ;BAMMemMapPtr
        add rax, 0Ch ; add BAMC Header to Memory map to start at correct offset for uncompressing
        mov src, rax
        Invoke uncompress, dest, Addr BAMC_UncompressedSize, src, BAMC_CompressedSize
        .IF rax == Z_OK ; ok
            mov rax, BAMC_UncompressedSize
            mov rbx, qwSize
            mov qword ptr [rbx], rax
        
            mov rax, dest
            ret
        .ENDIF
    .ENDIF
    
    mov rax, 0        
    ret
BAMUncompress ENDP


IEBAM_LIBEND

