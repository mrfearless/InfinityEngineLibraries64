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

include IEMOS.inc

MOSSignature            PROTO :QWORD


.CODE


IEMOS_ALIGN
;------------------------------------------------------------------------------
; Checks the MOS signatures to determine if they are valid and if MOS file is 
; compressed
;------------------------------------------------------------------------------
MOSSignature PROC FRAME USES RBX pMOS:QWORD
    ; check signatures to determine version
    mov rbx, pMOS
    mov eax, [rbx]
    .IF eax == ' SOM' ; MOS
        add rbx, 4
        mov eax, [rbx]
        .IF eax == '  1V' ; V1.0
            mov eax, MOS_VERSION_MOS_V10
        .ELSEIF eax == '  2V' ; V2.0
            mov eax, MOS_VERSION_MOS_V20
        .ELSE
            mov eax, MOS_VERSION_INVALID
        .ENDIF

    .ELSEIF eax == 'CSOM' ; MOSC
        add rbx, 4
        mov eax, [rbx]
        .IF eax == '  1V' ; V1.0
            mov eax, MOS_VERSION_MOSCV10
        .ELSE
            mov eax, MOS_VERSION_INVALID
        .ENDIF            
    .ELSE
        mov eax, MOS_VERSION_INVALID
    .ENDIF
    ret
MOSSignature endp


end

