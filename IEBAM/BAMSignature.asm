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

include IEBAM.inc

BAMSignature            PROTO :QWORD


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Checks the BAM signatures to determine if they are valid and if BAM file is 
; compressed
;------------------------------------------------------------------------------
BAMSignature PROC FRAME USES RBX pBAM:QWORD
    ; check signatures to determine version
    mov rbx, pBAM
    mov eax, [rbx]
    .IF eax == ' MAB' ; BAM
        add rbx, 4
        mov eax, [rbx]
        .IF eax == '  1V' ; V1.0
            mov eax, BAM_VERSION_BAM_V10
        .ELSEIF eax == '  2V' ; V2.0
            mov eax, BAM_VERSION_BAM_V20
        .ELSE
            mov eax, BAM_VERSION_INVALID
        .ENDIF

    .ELSEIF eax == 'CMAB' ; BAMC
        add rbx, 4
        mov eax, [rbx]
        .IF eax == '  1V' ; V1.0
            mov eax, BAM_VERSION_BAMCV10
        .ELSE
            mov eax, BAM_VERSION_INVALID
        .ENDIF            
    .ELSE
        mov eax, BAM_VERSION_INVALID
    .ENDIF
    ret
BAMSignature ENDP


IEBAM_LIBEND

