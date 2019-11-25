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

include IEMOS.inc


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; -1 = No Mos file, TRUE for MOSCV1, FALSE for MOS V1 or MOS V2 
;------------------------------------------------------------------------------
IEMOSFileCompression PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, -1
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSVersion
    .IF rax == MOS_VERSION_MOSCV10
        mov rax, TRUE
    .ELSE
        mov rax, FALSE
    .ENDIF
    ret
IEMOSFileCompression ENDP



IEMOS_LIBEND

