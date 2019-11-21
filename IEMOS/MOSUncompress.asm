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
;includelib masm64.lib
includelib zlibstat1211.lib


include IEMOS.inc

MOSUncompress PROTO :QWORD, :QWORD, :QWORD


.CODE


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

