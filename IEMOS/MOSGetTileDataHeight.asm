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
; Returns in rax height of data block as blocksize if row < rows -1
; (row = nTile / columns)
;
; otherwise returns in rax: imageheight - (row * blocksize)
;------------------------------------------------------------------------------
MOSGetTileDataHeight PROC FRAME USES RBX RCX RDX nTile:QWORD, qwBlockRows:QWORD, qwBlockColumns:QWORD, qwBlockSize:QWORD, qwImageHeight:QWORD
    LOCAL ROWSmod:QWORD
    
    mov rax, qwBlockRows
    dec rax
    mov ROWSmod, rax
    
    ; row = nTile / columns
    xor rdx, rdx
    mov rax, nTile
    mov rcx, qwBlockColumns
    div rcx
    ; rax is row
    .IF sqword ptr rax < ROWSmod
        mov rax, qwBlockSize
    .ELSE
        ; rax is row
        mov rbx, qwBlockSize
        mul rbx
        mov rbx, rax
        mov rax, qwImageHeight
        sub rax, rbx
        ; rax = imageheight - (row * blocksize)
    .ENDIF
    
    ret
MOSGetTileDataHeight ENDP


IEMOS_LIBEND

