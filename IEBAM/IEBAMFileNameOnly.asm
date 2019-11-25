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

EXTERNDEF IEBAMFileName     :PROTO hIEBAM:QWORD
EXTERNDEF BAMJustFname      :PROTO szFilePathName:QWORD, szFileName:QWORD

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFileNameOnly - returns in rax true or false if it managed to pass to the buffer pointed at lpszFileNameOnly, the stripped filename without extension
;------------------------------------------------------------------------------
IEBAMFileNameOnly PROC FRAME hIEBAM:QWORD, lpszFileNameOnly:QWORD
    Invoke IEBAMFileName, hIEBAM
    .IF rax == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke BAMJustFname, rax, lpszFileNameOnly
    
    mov rax, TRUE
    ret
IEBAMFileNameOnly ENDP




IEBAM_LIBEND

