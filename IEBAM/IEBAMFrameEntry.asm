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

EXTERNDEF IEBAMTotalFrameEntries    :PROTO hIEBAM:QWORD
EXTERNDEF IEBAMFrameEntries         :PROTO hIEBAM:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFrameEntry - Returns in rax a pointer to the specified frame entry or NULL
;------------------------------------------------------------------------------
IEBAMFrameEntry PROC FRAME USES RBX hIEBAM:QWORD, nFrameEntry:QWORD
    LOCAL TotalFrameEntries:QWORD
    LOCAL FrameEntriesPtr:QWORD
    
    .IF hIEBAM == NULL
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    .IF rax == 0
        mov rax, NULL
        ret
    .ENDIF    
    mov TotalFrameEntries, rax

    .IF nFrameEntry >= rax
        mov rax, NULL
        ret
    .ENDIF
    
    Invoke IEBAMFrameEntries, hIEBAM
    .IF rax == NULL
        ret
    .ENDIF
    mov FrameEntriesPtr, rax
    
    mov rbx, hIEBAM
    mov rax, [rbx].BAMINFO.BAMVersion
    .IF rax == BAM_VERSION_BAM_V20 ; BAM V2
        mov rax, nFrameEntry
        mov rbx, SIZEOF FRAMEV2_ENTRY
    .ELSE
        mov rax, nFrameEntry
        mov rbx, SIZEOF FRAMEV1_ENTRY
    .ENDIF
    mul rbx
    add rax, FrameEntriesPtr
    
    ret
IEBAMFrameEntry ENDP



IEBAM_LIBEND

