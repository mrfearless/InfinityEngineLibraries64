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
; 0 = No Mos file, 1 = MOS V1, 2 = MOS V2, 3 = MOSCV1 
;------------------------------------------------------------------------------
IEMOSVersion PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSVersion
    ret
IEMOSVersion ENDP



IEMOS_LIBEND

