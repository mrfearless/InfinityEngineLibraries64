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


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMTotalFrameEntries - Returns in rax the total no of frame entries
;------------------------------------------------------------------------------
IEBAMTotalFrameEntries PROC FRAME USES RBX hIEBAM:QWORD
    .IF hIEBAM == NULL
        mov rax, 0
        ret
    .ENDIF
    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMVersion
    .IF rax == 2 ; BAM V2
        mov rbx, [rbx].BAMINFO.BAMHeaderPtr
        .IF rbx != NULL
            mov eax, [rbx].BAMV2_HEADER.FrameEntriesCount
        .ELSE
            mov rax, 0
        .ENDIF
    .ELSE
        mov rbx, [rbx].BAMINFO.BAMHeaderPtr
        .IF rbx != NULL
            movzx rax, word ptr [rbx].BAMV1_HEADER.FrameEntriesCount
        .ELSE
            mov rax, 0
        .ENDIF
    .ENDIF
    ret
IEBAMTotalFrameEntries ENDP



IEBAM_LIBEND

