; Macros for GDT
;
; GDT descripter struct
; To describe the segment attributes in the memory layout
; Descriptor base (32 bits), limit (20 bits), option (4 bits, 4 padding, 8 bits)
%macro Descriptor 3
    dw %2 & 0xffff                          ; limit bit[0,15]
    dw %1 & 0xffff                          ; base bit[0,15]
    db (%1>>16) & 0xff                        ; base bit[16,23]
    dw ((%2>>8) & 0x0f00) | (%3 & 0xf0ff)     ; option and limit[16,19]
    db (%1>>24) & 0xff                        ; base bit[24,31]
%endmacro

; Macro for gate
; |  7  6  |  5      4   | 3      2 | 1     0 |
; | offset |  attributes | selector | offset  | 
; Usage: Gate Selector dw, Offset dd, Dcount db, Attribute db
%macro Gate 4
    dw (%2 & 0xFFFF)
    dw %1
    db (%3 & 0x1F)
    db %4
    dw (%2 >> 16) & 0xFFFF
%endmacro






; Segment options
; Byte 6 & 7, the third argument of GDT descriptor struct
; 
; |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
; |  G  | D/B |  0  | AVL | segment limit 16..19  |  P  |    DPL    |  S  |         TYPE          |


; Address Access Type
DA_32       EQU    0x4000   ; Access the code/stack segment in 32. For expand down data segment, the size limit is set to 32Gb rather than 64 Kb

; Limit granularity
LG_4K       EQU    0x8000   ; Data limit granularity set to 4K

; Request Privilege Type (Selector)
SP_RPL0     EQU     0
SP_RPL1     EQU     1
SP_RPL2     EQU     2
SP_RPL3     EQU     3

; Descriptor Privilege Type (Descriptor)
DP_DPL0     EQU    0x0000   ; ring 0
DP_DPL1     EQU    0x0020   ; ring 1
DP_DPL2     EQU    0x0040   ; ring 2
DP_DPL3     EQU    0x0060   ; ring 3

; Code/Data Access Type
; P=1 means present. S=1 means this is code or data.
; R=read, A=access, W=write, D=expand down, E=execute
DA_R        EQU 0x90
DA_RW       EQU 0x92
DA_RD       EQU 0x94
DA_RWD      EQU 0x96
DA_E        EQU 0x98
DA_RE       EQU 0x9A
DA_ECO      EQU 0x9C
DA_RECO     EQU 0x9E

DA_RA       EQU 0x91
DA_RWA      EQU 0x93
DA_RDA      EQU 0x95
DA_RWDA     EQU 0x97
DA_EA       EQU 0x99
DA_REA      EQU 0x9B
DA_ECOA     EQU 0x9D
DA_RECOA    EQU 0x9F



; System segment
DA_LDT          EQU     82h
DA_TaskGate     EQU     85h 
DA_386TSS       EQU     89h ; TSS
DA_386CGate     EQU     8Ch ; Call Gate
DA_386IGate     EQU     8Eh ; Interrupt Gate
DA_386TGate     EQU     8Fh ; Trap Gate















