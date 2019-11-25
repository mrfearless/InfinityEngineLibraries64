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

EXTERNDEF IEMOSTileDataEntry    :PROTO hIEMOS:QWORD, nTile:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileRAW - Returns in rax pointer to RAW tile data.
;------------------------------------------------------------------------------
IEMOSTileRAW PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF    

    Invoke IEMOSTileDataEntry, hIEMOS, nTile
    .IF rax == NULL
        ret
    .ENDIF
    mov rbx, rax
    mov rax, [rbx].TILEDATA.TileRAW
    ret
IEMOSTileRAW ENDP



IEMOS_LIBEND

