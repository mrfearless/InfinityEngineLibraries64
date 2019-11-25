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

EXTERNDEF IEMOSTileLookupEntries :PROTO hIEMOS:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSTileLookupEntry - Returns in rax a pointer to specific TileLookup entry
; which if read (DWORD) is an offset to the Tile Data from start of tile pixel 
; data.
;------------------------------------------------------------------------------
IEMOSTileLookupEntry PROC FRAME USES RBX hIEMOS:QWORD, nTile:QWORD
    LOCAL TileLookupEntries:QWORD
    
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
    
    Invoke IEMOSTileLookupEntries, hIEMOS
    .IF rax == NULL
        ret
    .ENDIF
    .IF nTile == 0
        ; eax contains TileLookupEntries which is tile 0's start
        ret
    .ENDIF    
    mov TileLookupEntries, rax
    
    mov rax, nTile
    mov rbx, SIZEOF DWORD
    mul rbx
    add rax, TileLookupEntries
    
    ret
IEMOSTileLookupEntry ENDP



IEMOS_LIBEND

