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
; -1 = No Bam file, TRUE for BAMCV1, FALSE for BAM V1 or BAM V2 
;------------------------------------------------------------------------------
IEBAMFileCompression PROC FRAME USES RBX hIEBAM:QWORD
    .IF hIEBAM == NULL
        mov rax, -1
        ret
    .ENDIF
    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMVersion
    .IF rax == BAM_VERSION_BAMCV10
        mov rax, TRUE
    .ELSE
        mov rax, FALSE
    .ENDIF
    ret
IEBAMFileCompression ENDP



IEBAM_LIBEND

