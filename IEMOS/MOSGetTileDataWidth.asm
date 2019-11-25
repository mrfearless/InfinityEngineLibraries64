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
; Returns in rax width of data block as blocksize if column < columns -1
; (column = nTile % columns)
; 
; otherwise returns in rax: imagewidth - (column * blocksize)
;------------------------------------------------------------------------------
MOSGetTileDataWidth PROC FRAME USES RBX RCX RDX nTile:QWORD, qwBlockColumns:QWORD, qwBlockSize:QWORD, qwImageWidth:QWORD
    LOCAL COLSmod:QWORD
    
    mov rax, qwBlockColumns
    dec rax
    mov COLSmod, rax
    
    mov rax, qwBlockColumns
    and rax, 1 ; ( a AND (b-1) = mod )
    .IF rax == 0 ; is divisable by 2?
        mov rax, nTile
        and rax, COLSmod ; then use (a AND (b-1)) instead of div to get modulus
        ; rax = column
        .IF rax < COLSmod
            mov rax, qwBlockSize
            ret
        .ENDIF
    .ELSE ; Use div for modulus otherwise
        xor rdx, rdx
        mov rax, nTile
        mov rcx, qwBlockColumns
        div rcx
        mov rax, rdx
        ; rax = column
        .IF rax < COLSmod
            mov rax, qwBlockSize
            ret
        .ENDIF
    .ENDIF
    ; rax is column
    mov rbx, qwBlockSize
    mul rbx
    mov rbx, rax
    mov rax, qwImageWidth
    sub rax, rbx
    ; rax = imagewidth - (columns * blocksize)
    ret
MOSGetTileDataWidth ENDP


IEMOS_LIBEND

