; | sector 0 | sector 1-9 | sector 10-18 | sector 19-32 | data 33... 
; |   MBR    |   FAT 1    |    FAT 2     |   root dir   | 
;     ...          ...           ...           ...      | cluster 2...
;      1           9             9              14 

BPB_BytsPerSec	DW 512
BPB_FATSz16	DW 9	
BPB_SecPerTrk	DW 18

dir_fst_cls          equ 0x1A     ; Offset to the word in the root directory entry that store the first cluster number
cls_to_sector_offset equ 14+19-2  ; Cluster no.2 is the 19th sector
root_entry_size      equ 32       ; 32 bytes per entry
root_dir_limit       equ 32 * 224 ; Root directory size in bytes
root_dir_sec_num     equ 14       ; Number of sectors root directory occupied

