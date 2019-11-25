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
includelib gdi32.lib

include IEBAM.inc

RGBCOLOR macro r:REQ,g:REQ,b:REQ    
exitm <( ( ( ( r )  or  ( ( ( g ) )  shl  8 ) )  or  ( ( ( b ) )  shl  16 ) ) ) >
ENDM

.CODE


IEBAM_ALIGN
;------------------------------------------------------------------------------
; Returns in eax HBITMAP of bam frame specified or bam frames if nFrame = -1
; HBITMAP returned in not freed when library closes, use DeleteObject when it
; is no longer required.
; Bitmap is formatted to max width and height of all frames 
;------------------------------------------------------------------------------
IEBAMBitmap PROC FRAME USES RBX hIEBAM:QWORD, nFrame:QWORD, qwBackColor:QWORD, qwGridColor:QWORD
    LOCAL hdc:QWORD
    LOCAL hdcMem:QWORD
    LOCAL hdcFrame:QWORD
    LOCAL SavedDCFrame:QWORD
    LOCAL hBitmap:QWORD
    LOCAL hOldBitmap:QWORD
    LOCAL hFrameBitmap:QWORD
    LOCAL hFrameBitmapOld:QWORD
    LOCAL hBrush:QWORD
    LOCAL hBrushOld:QWORD
    LOCAL qwImageWidth:QWORD
    LOCAL qwImageHeight:QWORD
    LOCAL FrameX:QWORD
    LOCAL FrameY:QWORD
    LOCAL FrameW:QWORD
    LOCAL FrameH:QWORD
    LOCAL TotalFrames:QWORD
    LOCAL nFrameCnt:QWORD
    LOCAL RowXadjust:QWORD
    LOCAL ColYadjust:QWORD
    LOCAL nRow:QWORD
    LOCAL nCol:QWORD
    LOCAL RowX:QWORD
    LOCAL ColY:QWORD
    LOCAL xpos:QWORD
    LOCAL ypos:QWORD
    LOCAL rect:RECT
    
    .IF hIEBAM == NULL
        mov rax, NULL
        ret
    .ENDIF  
    
    Invoke IEBAMTotalFrameEntries, hIEBAM
    .IF rax == 0
        ret
    .ENDIF
    mov TotalFrames, rax
    
    Invoke IEBAMFindMaxWidthHeight, hIEBAM, Addr qwImageWidth, Addr qwImageHeight
    .IF qwImageWidth == 0 && qwImageHeight == 0
        mov rax, NULL
        ret
    .ENDIF
    
    ;Invoke CreateDC, Addr szMOSDisplayDC, NULL, NULL, NULL
    Invoke GetDC, 0
    mov hdc, rax

    Invoke CreateCompatibleDC, hdc
    mov hdcMem, rax

    Invoke CreateCompatibleDC, hdc
    mov hdcFrame, rax
    
    .IF nFrame == -1
        mov rax, qwImageWidth
        mov RowXadjust, rax
        mov rax, qwImageHeight
        mov ColYadjust, rax
        ;.IF TotalFrames >= 16 ; create a 4x4 grid of bam frames
        
        ;.ELSE ; create a 4
            
        ;.ENDIF
        shl qwImageWidth, 2 ; x4
        shl qwImageHeight, 2 ; x4
    .ELSE    
        
    .ENDIF
    Invoke CreateCompatibleBitmap, hdc, dword ptr qwImageWidth, dword ptr qwImageHeight
    mov hBitmap, rax
    
    Invoke SelectObject, hdcMem, hBitmap
    mov hOldBitmap, rax
    
    ; fill background of grid image
    mov rect.left, 0
    mov rect.top, 0
    mov rax, qwImageWidth
    mov rect.right, eax
    mov rax, qwImageHeight
    mov rect.bottom, eax
    
    inc rect.right
    inc rect.bottom
    Invoke GetStockObject, DC_BRUSH
    mov hBrush, rax
    Invoke SelectObject, hdcMem, rax
    mov hBrushOld, rax
    .IF qwBackColor == -1
        Invoke IEBAMRLEColorIndexColorRef, hIEBAM
        Invoke SetDCBrushColor, hdcMem, eax ;RGBCOLOR(0,0,0)
    .ELSE
        Invoke SetDCBrushColor, hdcMem, dword ptr qwBackColor;RGBCOLOR(0,0,0)
    .ENDIF
    Invoke FillRect, hdcMem, Addr rect, hBrush
    Invoke SelectObject, hdcMem, hBrushOld
    Invoke DeleteObject, hBrushOld
    Invoke DeleteObject, hBrush
    
    Invoke SaveDC, hdcFrame
    mov SavedDCFrame, rax
    
    .IF nFrame == -1

        mov nCol, 0
        mov nRow, 0
        mov RowX, 0
        mov ColY, 0
        
        mov rax, 0
        mov nFrameCnt, 0
        .WHILE rax < TotalFrames
            Invoke IEBAMFrameBitmap, hIEBAM, nFrameCnt, Addr FrameW, Addr FrameH, Addr FrameX, Addr FrameY, qwBackColor
            .IF eax != NULL
                mov hFrameBitmap, rax
                Invoke SelectObject, hdcFrame, hFrameBitmap
                mov hFrameBitmapOld, rax
                
                ; center in frame if less than max width and height
                mov rax, FrameW
                .IF sqword ptr rax < RowXadjust
                    mov rax, RowXadjust
                    shr rax, 1
                    mov rbx, FrameW
                    shr rbx, 1
                    sub rax, rbx
                    add rax, RowX
                .ELSE
                    mov rax, RowX
                .ENDIF
                mov xpos, rax
                
                mov rax, FrameH
                .IF sqword ptr rax < ColYadjust
                    mov rax, ColYadjust
                    shr rax, 1
                    mov rbx, FrameH
                    shr rbx, 1
                    sub rax, rbx
                    add rax, ColY
                .ELSE
                    mov rax, ColY
                .ENDIF
                mov ypos, rax
                
                ;mov eax, FrameX
                ;add eax, RowX
                ;mov xpos, eax
                
                ;mov eax, FrameY
                ;add eax, ColY
                ;mov ypos, eax
                
                IFDEF DEBUG64
                PrintText '---------'
                PrintDec nFrameCnt
                PrintDec FrameX
                PrintDec FrameY
                PrintDec FrameW
                PrintDec FrameH
                PrintDec RowX
                PrintDec ColY
                PrintDec xpos
                PrintDec ypos
                PrintText '---------'
                ENDIF
                
                
                Invoke BitBlt, hdcMem, dword ptr xpos, dword ptr ypos, dword ptr FrameW, dword ptr FrameH, hdcFrame, 0, 0, SRCCOPY
                Invoke SelectObject, hdcFrame, hFrameBitmapOld
                Invoke DeleteObject, hFrameBitmapOld
                
                .IF qwGridColor != -1
                    mov rax, RowX
                    ;inc eax
                    mov rect.left, eax
                    mov rax, ColY
                    ;inc eax
                    mov rect.top, eax
    
                    mov rax, RowXadjust
                    add rax, RowX
                    ;sub eax, 2
                    mov rect.right, eax
                    mov rax, ColYadjust
                    add rax, ColY
                    ;sub eax, 2
                    mov rect.bottom, eax
    
                    Invoke GetStockObject, DC_BRUSH
                    mov hBrush, rax
                    Invoke SelectObject, hdcMem, rax
                    mov hBrushOld, rax
                    Invoke SetDCBrushColor, hdcMem, dword ptr qwGridColor ;RGBCOLOR(255,255,255)
                    Invoke FrameRect, hdcMem, Addr rect, hBrush
                    Invoke SelectObject, hdcMem, hBrushOld
                    Invoke DeleteObject, hBrushOld
                    Invoke DeleteObject, hBrush
                .ENDIF
                
            .ENDIF
            
            inc nRow
            .IF nRow == 4
                mov nRow, 0
                mov RowX, 0
                inc nCol
                .IF nCol == 4 ; end of 4 x 4 grid
                    .BREAK
                .ENDIF
                mov rax, ColYadjust
                add ColY, rax
            .ELSE
                mov rax, RowXadjust
                add RowX, rax
            .ENDIF

            inc nFrameCnt
            mov rax, nFrameCnt
        .ENDW
        
    .ELSE
        
        Invoke IEBAMFrameBitmap, hIEBAM, nFrame, Addr FrameW, Addr FrameH, Addr FrameX, Addr FrameY, qwBackColor
        .IF eax != NULL
            mov hFrameBitmap, rax
            Invoke SelectObject, hdcFrame, hFrameBitmap
            mov hFrameBitmapOld, rax
            Invoke BitBlt, hdcMem, dword ptr FrameX, dword ptr FrameY, dword ptr FrameW, dword ptr FrameH, hdcFrame, 0, 0, SRCCOPY
            Invoke SelectObject, hdcFrame, hFrameBitmapOld
            Invoke DeleteObject, hFrameBitmapOld
        .ENDIF
        
    .ENDIF
    
    .IF hOldBitmap != 0
        Invoke SelectObject, hdcMem, hOldBitmap
        Invoke DeleteObject, hOldBitmap
    .ENDIF
    Invoke RestoreDC, hdcFrame, dword ptr SavedDCFrame
    Invoke DeleteDC, hdcFrame
    Invoke DeleteDC, hdcMem
    ;Invoke DeleteDC, hdc
    Invoke ReleaseDC, 0, hdc
    
    mov rax, hBitmap
    ret
IEBAMBitmap ENDP


IEBAM_LIBEND

