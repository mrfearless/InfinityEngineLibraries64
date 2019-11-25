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

EXTERNDEF IEMOSFileName     :PROTO hIEMOS:QWORD
EXTERNDEF MOSJustFname      :PROTO szFilePathName:QWORD, szFileName:QWORD

.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; IEMOSFileNameOnly - returns in rax true or false if it managed to pass to the 
; buffer pointed at lpszFileNameOnly, the stripped filename without extension
;------------------------------------------------------------------------------
IEMOSFileNameOnly PROC FRAME hIEMOS:QWORD, lpszFileNameOnly:QWORD
    Invoke IEMOSFileName, hIEMOS
    .IF rax == NULL
        mov rax, FALSE
        ret
    .ENDIF
    
    Invoke MOSJustFname, rax, lpszFileNameOnly
    
    mov rax, TRUE
    ret
IEMOSFileNameOnly ENDP




IEMOS_LIBEND

