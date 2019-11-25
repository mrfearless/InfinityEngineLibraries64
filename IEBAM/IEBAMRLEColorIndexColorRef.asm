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

include IEBAM.inc

EXTERNDEF IEBAMHeader               :PROTO hIEBAM:QWORD
EXTERNDEF IEBAMPaletteEntry         :PROTO hIEBAM:QWORD, PaletteIndex:QWORD
EXTERNDEF IEBAMConvertABGRtoARGB    :PROTO dwBGRA:DWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in eax ColorRef of the RLEColorIndex or -1 otherwise
;------------------------------------------------------------------------------
IEBAMRLEColorIndexColorRef PROC FRAME USES RBX hIEBAM:QWORD
    LOCAL BamHeaderPtr:QWORD
    LOCAL RLEColorIndex:QWORD
    LOCAL ABGR:DWORD
    
    .IF hIEBAM == NULL
        mov rax, -1
        ret
    .ENDIF
    
    Invoke IEBAMHeader, hIEBAM
    .IF rax == NULL
        mov rax, -1
        ret
    .ENDIF
    mov BamHeaderPtr, rax
    mov rbx, BamHeaderPtr
    
    movzx rax, byte ptr [rbx].BAMV1_HEADER.ColorIndexRLE
    mov RLEColorIndex, rax
    
    Invoke IEBAMPaletteEntry, hIEBAM, RLEColorIndex
    xor rbx, rbx
    mov ebx, dword ptr [rax]
    mov ABGR, ebx
    
    Invoke IEBAMConvertABGRtoARGB, ABGR
    AND eax, 00FFFFFFh ; to mask off alpha
    ret
IEBAMRLEColorIndexColorRef ENDP



IEBAM_LIBEND

