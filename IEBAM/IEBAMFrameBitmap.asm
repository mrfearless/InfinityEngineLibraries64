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
includelib kernel32.Lib

include IEBAM.inc

EXTERNDEF IEBAMFrameDataEntry   :PROTO hIEBAM:QWORD, nFrameEntry:QWORD
EXTERNDEF IEBAMPalette          :PROTO hIEBAM:QWORD
EXTERNDEF BAMFrameDataBitmap    :PROTO qwFrameWidth:QWORD, qwFrameHeight:QWORD, pFrameBMP:QWORD, qwFrameSizeBMP:QWORD, pFramePalette:QWORD

.DATA
BAMPaletteTmp DB 1024 DUP (0)

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; IEBAMFrameBitmap - Returns in rax HBITMAP or NULL. Optional variables pointed 
; to, are filled in if rax is a HBITMAP (!NULL), otherwise vars (if supplied) 
; will be set to 0
;------------------------------------------------------------------------------
IEBAMFrameBitmap PROC FRAME USES RBX hIEBAM:QWORD, nFrame:QWORD, lpqwFrameWidth:QWORD, lpqwFrameHeight:QWORD, lpqwFrameXCoord:QWORD, lpqwFrameYCoord:QWORD, qwTransColor:QWORD
    LOCAL FramePalette:QWORD
    LOCAL FrameDataEntry:QWORD
    LOCAL FrameWidth:QWORD
    LOCAL FrameHeight:QWORD
    LOCAL FrameXCoord:QWORD
    LOCAL FrameYCoord:QWORD
    LOCAL FrameSizeBMP:QWORD
    LOCAL FrameBMP:QWORD
    LOCAL FrameBitmapHandle:QWORD

    mov FrameWidth, 0
    mov FrameHeight, 0
    mov FrameXCoord, 0
    mov FrameYCoord, 0
    mov FrameBitmapHandle, 0

    .IF hIEBAM == NULL
        jmp IEBAMFrameBitmapExit
    .ENDIF
    
    Invoke IEBAMFrameDataEntry, hIEBAM, nFrame
    .IF rax == NULL
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameDataEntry, rax

    mov rbx, FrameDataEntry
    mov rax, [rbx].FRAMEDATA.FrameWidth
    .IF rax == 0
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameWidth, rax
    mov rax, [ebx].FRAMEDATA.FrameHeight
    .IF rax == 0
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameHeight, rax
    mov rax, [rbx].FRAMEDATA.FrameXcoord
    mov FrameXCoord, rax
    mov rax, [rbx].FRAMEDATA.FrameYcoord
    mov FrameYCoord, rax
    
    mov rax, [rbx].FRAMEDATA.FrameBitmapHandle
    .IF rax != 0
        mov FrameBitmapHandle, rax
        jmp IEBAMFrameBitmapExit
    .ENDIF    
    
    mov rax, [rbx].FRAMEDATA.FrameSizeBMP
    .IF rax == 0
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameSizeBMP, rax
    mov rax, [rbx].FRAMEDATA.FrameBMP
    .IF rax == 0
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FrameBMP, rax

    Invoke IEBAMPalette, hIEBAM
    .IF rax == NULL
        jmp IEBAMFrameBitmapExit
    .ENDIF
    mov FramePalette, rax

   ; Set palette transparency if dwTransColor is not -1
    .IF qwTransColor != -1
        Invoke RtlMoveMemory, Addr BAMPaletteTmp, FramePalette, 1024
        Invoke IEBAMRLEColorIndex, hIEBAM
        lea rbx, BAMPaletteTmp
        lea rbx, [rbx+rax*4]
        Invoke IEBAMConvertARGBtoABGR, dword ptr qwTransColor
        ;mov eax, dwTransColor
        mov dword ptr [rbx], eax
        Invoke BAMFrameDataBitmap, FrameWidth, FrameHeight, FrameBMP, FrameSizeBMP, Addr BAMPaletteTmp
        mov FrameBitmapHandle, rax
    .ELSE
        Invoke BAMFrameDataBitmap, FrameWidth, FrameHeight, FrameBMP, FrameSizeBMP, FramePalette
        .IF rax != NULL ; save bitmap handle back to TILEDATA struct
            mov FrameBitmapHandle, rax
            mov rbx, FrameDataEntry
            mov [rbx].FRAMEDATA.FrameBitmapHandle, rax
        .ENDIF
    .ENDIF

IEBAMFrameBitmapExit:

    .IF lpqwFrameWidth != NULL
        mov rbx, lpqwFrameWidth
        mov rax, FrameWidth
        mov [rbx], rax
    .ENDIF
    
    .IF lpqwFrameHeight != NULL
        mov rbx, lpqwFrameHeight
        mov rax, FrameHeight
        mov [rbx], rax
    .ENDIF
   
    .IF lpqwFrameXCoord != NULL
        mov rbx, lpqwFrameXCoord
        mov rax, FrameXCoord
        mov [rbx], rax
    .ENDIF
    
    .IF lpqwFrameYCoord != NULL
        mov rbx, lpqwFrameYCoord
        mov rax, FrameYCoord
        mov [rbx], rax
    .ENDIF
    
    mov rax, FrameBitmapHandle
    ret
IEBAMFrameBitmap ENDP



IEBAM_LIBEND

