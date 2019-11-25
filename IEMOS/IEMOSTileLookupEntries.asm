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
; IEMOSTileLookupEntries - Returns in rax a pointer to the array of TileLookup 
; entries (DWORDs) or NULL if not valid
;------------------------------------------------------------------------------
IEMOSTileLookupEntries PROC FRAME USES RBX hIEMOS:QWORD
    .IF hIEMOS == NULL
        mov rax, NULL
        ret
    .ENDIF
    mov rbx, hIEMOS
    mov rax, [rbx].MOSINFO.MOSTileLookupEntriesPtr
    ret
IEMOSTileLookupEntries ENDP




IEMOS_LIBEND

