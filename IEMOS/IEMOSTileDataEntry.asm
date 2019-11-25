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

EXTERNDEF IEMOSTileDataEntries :PROTO hIEMOS:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileDataEntry - Returns in rax a pointer to a specific TILEDATA entry or
; NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileDataEntry PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    LOCAL TileDataEntries:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSTotalTiles
    .IF nTile >= rax ; 0 based tile index
        mov rax, NULL
        ret
    .ENDIF        
    
    Invoke IEMOSTileDataEntries, hIEMOS
    .IF rax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; rax contains TileDataEntries which is tile 0's start
        ret
    .ENDIF    
    mov TileDataEntries, rax    
    
    mov rax, nTile
    mov rbx, SIZEOF TILEDATA
    mul rbx
    add rax, TileDataEntries    
    
    ret
IEMOSTileDataEntry ENDP



IEMOS_LIBEND

