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
includelib kernel32.lib
includelib gdi32.lib

include IEBAM.inc

EXTERNDEF BAMCalcDwordAligned   :PROTO dwWidthOrHeight:QWORD

.DATA
BAMFrameBitmap              DB (SIZEOF BITMAPINFOHEADER + 1024) dup (0)


.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in eax handle to frame data bitmap or NULL
;------------------------------------------------------------------------------
BAMFrameDataBitmap PROC FRAME USES RBX qwFrameWidth:QWORD, qwFrameHeight:QWORD, pFrameBMP:QWORD, qwFrameSizeBMP:QWORD, pFramePalette:QWORD
    LOCAL qwFrameWidthDword:QWORD
    LOCAL hdc:QWORD
    LOCAL FrameBitmapHandle:QWORD
    
    Invoke RtlZeroMemory, Addr BAMFrameBitmap, (SIZEOF BITMAPINFOHEADER + 1024)

    Invoke BAMCalcDwordAligned, qwFrameWidth
    mov qwFrameWidthDword, rax

    lea rbx, BAMFrameBitmap
    mov [rbx].BITMAPINFOHEADER.biSize, 40d
    
    mov rax, qwFrameWidthDword
    mov [rbx].BITMAPINFOHEADER.biWidth, eax
    mov rax, qwFrameHeight
    ;neg eax
    mov [rbx].BITMAPINFOHEADER.biHeight, eax
    mov [rbx].BITMAPINFOHEADER.biPlanes, 1
    mov [rbx].BITMAPINFOHEADER.biBitCount, 8
    mov [rbx].BITMAPINFOHEADER.biCompression, BI_RGB
    mov rax, qwFrameSizeBMP
    mov [rbx].BITMAPINFOHEADER.biSizeImage, eax
    mov [rbx].BITMAPINFOHEADER.biXPelsPerMeter, 2835d
    mov [rbx].BITMAPINFOHEADER.biYPelsPerMeter, 2835d
    lea rax, BAMFrameBitmap
    lea rbx, [rax].BITMAPINFO.bmiColors
    Invoke RtlMoveMemory, rbx, pFramePalette, 1024d
    
    ;Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    Invoke GetDC, 0
    mov hdc, rax
    Invoke CreateDIBitmap, hdc, Addr BAMFrameBitmap, CBM_INIT, pFrameBMP, Addr BAMFrameBitmap, DIB_RGB_COLORS
    .IF rax == NULL
        IFDEF DEBUG64
            PrintText 'CreateDIBitmap Failed'
        ENDIF
    .ENDIF
    mov FrameBitmapHandle, rax
    ;Invoke DeleteDC, hdc
    Invoke ReleaseDC, 0, hdc
    mov rax, FrameBitmapHandle
    ret
BAMFrameDataBitmap ENDP


IEBAM_LIBEND

