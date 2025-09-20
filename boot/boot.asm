 
; *************************************************
; MBR section
; 1. Parse root directory to find then bootloader
; 2. Read FATs to get the sectors of our bootloader
; 3. Load it to memory and jmp
;
; x86 Real mode layout
; - 0x00000000 - 0x000003FF - Real Mode Interrupt Vector Table
; - 0x00000400 - 0x000004FF - BIOS Data Area
; - 0x00000500 - 0x00007BFF - Unused
; - 0x00007C00 - 0x00007DFF - Our Bootloader
; - 0x00007E00 - 0x0009FFFF - Unused
; - 0x000A0000 - 0x000BFFFF - Video RAM (VRAM) Memory
; - 0x000B0000 - 0x000B7777 - Monochrome Video Memory
; - 0x000B8000 - 0x000BFFFF - Color Video Memory
; - 0x000C0000 - 0x000C7FFF - Video ROM BIOS
; - 0x000C8000 - 0x000EFFFF - BIOS Shadow Area
; - 0x000F0000 - 0x000FFFFF - System BIOS
; 
; OS layout
; 1. boot loader 8000:0
; 2. ss:sp 9000:FFFF
; 
; Calling convention
; 1. caller save
; 2. pass argument into registers
; *************************************************






%ifdef	DEBUG
	org  07c00h			
%else
	org  07c00h			
%endif

	jmp short LABEL_START		; Start to boot.
	nop				

%include "fat12hdr.inc"
%include "loader.inc" 
stack_base  equ 0x9000
stack_top   equ 0xFFFE

LABEL_START:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
    mov gs, ax

    ; Initialize stack to 0x90000 (bottom) to 0x9FFFE (top)
    mov ax, stack_base  
    mov ss, ax
    mov ax, stack_top
    mov sp, ax
   
    ; Show booting message
    mov cx, boot_msg_len ; msg len   
    mov bp, boot_msg     ; msg ptr
    mov ax, 1            ; endline after print 
    call print_real

    ; Search for bootloader blocks in FAT12 root directory
    push es
    mov ax, loader_segment  ; Load FAT12 root directory to es:bx = 0x8000:0
    mov es, ax  
    mov ax, root_sec_num     ; Starting sector number 
    mov cx, root_dir_sec_num ; Load only one sector
    xor bx, bx               ; Load to es:0
    call load_sectors
    xor cx, cx  ; for c in range(0, root_dir_limit, root_entry_size)
.iter_root:
    mov bx, cx  ;   for b in range(c, c+11, 1):
    mov ax, bx  ;       match chars with LOADER..BIN
    add ax, 11
    mov si, loader_filename
.cmp_str:
    mov dl, byte [si]    ; [loader_filename+i]
    cmp dl, byte es:[bx] ; [root_directroy+i]
    jne .unmatched ; When unmatched, search another entry
    inc si
    inc bx
    cmp bx, ax
    jae .matched   ; Exit the loop if all 11 bytes are the same
    jmp .cmp_str    
.unmatched:
    add cx, root_entry_size
    cmp cx, root_dir_limit
    jb .iter_root
    jmp $   ; Failed to find boot loader after searching every entry
.matched:
    ; cx holds the value of the valid entry
    mov bx, cx
    mov si, dir_fst_cls
    mov ax, word es:[bx+si]    ; base of loader's root entry + offset to its cluster info
    push ax
    ; Load FAT table
    mov ax, 1               ; Starting sector of FAT 
    mov cx, word [BPB_FATSz16]
    mov bx, FAT_offset          ; Load FAT to 0x8E000. The size of FAT is 0x1200
    call load_sectors
    ; Load Loader
    mov bp, bx
    xor bx, bx
    pop ax
    call load_fat_file
    %ifdef DEBUG    ; Make sure the loader is loaded to the memory
    mov bx, 0x0
    mov ax, 0x100
    call print_mem
    %endif

    pop es
     
    
    ; Show load root message
    mov cx, load_root_msg_len   ; msg len
    mov bp, load_root_msg       ; msg ptr
    mov ax, 1                   ; endline
    call print_real
    ; Save cursor position
    mov ax, word [cursor_pos]   ; Save cursor position al: column ah: row
    jmp loader_segment:loader_offset

; Load FAT12 file 
;   es:bx   where to load the file
;   es:bp   FAT table
;   ax      First FAT cluster
load_fat_file:
    cmp ax, 0xFFF
    jne .not_eof
    ret
.not_eof:
    push dx
    push si
    push cx
    push ax
    add ax, cls_to_sector_offset
    mov cx, 1            ; Load one sector
    call load_sectors    ; Load ax to es:bx
    add bx, [BPB_BytsPerSec]
    pop ax
    mov si, 3   ; Convert FAT cluster to address
    xor dx, dx
    mul si      ; Calculate ClsNum(ax) * 3 / 2
    mov si, ax  ; ax = ClsNum * 3
    shr si, 1   ;           |---|  
    and ax, 1   ; 000...0101  0   
    je  .bottom ; | byte 1 | byte 2 | byte 3 |
                ; |    FAT 0    |   FAT 1    |
.upper:
    mov ax, word es:[bp+si]
    shr ax, 4
    jmp .load_next_cls
.bottom:
    mov ax, word es:[bp+si]
    and ax, 0x0FFF
.load_next_cls:
    call load_fat_file 
    pop cx
    pop si
    pop dx
    ret

    

; Print memory in real mode
;   es:bx memory position
;   ax: number of bytes to print
%ifdef DEBUG
print_mem:
    push dx
    push cx
    push di
.loop:
    cmp ax, 0
    jbe .end_loop
    mov dx, 0
.byte2ascii:
    mov cl, byte [es:bx]
    cmp dx, 0
    jne .lower4
.upper4:
    shr cl, 4
.lower4:
    and cl, 0x0F
    cmp cl, 9
    ja .a2f
    add cl, '0'
.num:
    jmp .end_chk_val
.a2f:
    add cl, 'A'-10
.end_chk_val:
    mov di, print_mem_buf
    add di, dx
    mov byte [di], cl
    inc dx
    cmp dx, 2
    jb .byte2ascii
    push es
    mov cx, cs
    mov es, cx
    mov bp, print_mem_buf
    mov cx, print_mem_buf_len
    push ax
    mov ax, 0 ; No endline
    call print_real
    pop ax
    pop es
    inc bx
    dec ax
    jmp .loop
.end_loop:
    pop di
    pop cx
    pop dx
    ret
%endif
    
    
; Print string in real mode
;   cx: len
;   bp: offset relative to es
;   ax: if ax = 1 endline line
print_real:
    push bx
    push dx
	push cx
    push ax
    mov	ax, 0x1301		
	mov	bx, 0x000c		
    mov	dx, word [cursor_pos]
	int	0x10			; int 10h
    pop ax
    pop cx
    cmp ax, 1
    jne .no_endline
    mov byte [cursor_column], 0 ; Move cursor to the new line
    inc byte [cursor_row]
    jmp .end
.no_endline:
    mov ax, cx
    mov dx, word [cursor_column]
    and dx, 0x00FF
    add ax, dx
    xor dx, dx
    mov cx, 80    ; 80 chars per row
    div cx          ; ax quotient, dx remainder
    add byte [cursor_row], al
    mov byte [cursor_column], dl
.end:
    pop dx
    pop bx
	ret

; load floppy disk
;   ax: starting sector number
;   cx: number of sectors to read 
;   bx: buffer relative to es
;   Notes: bx remain unchanged after BIOS call 
load_sectors:
    push dx
    push si
    push cx
    xor dx, dx  ; dx:ax / word [BPB_SecPerTrk] = ax...dx
    div word [BPB_SecPerTrk]
    mov cl, dl  ; Sector number in that track
    inc cl
    mov dh, al  
    and dh, 00000001b ; Which side? When track number is even => 0 (up) odd => 1 (down)
    mov ch, al  ; Track number
    shr ch, 1
    xor dl, dl  ; The first floppy disk
    mov si, sp
.try_read_disk:
    mov ax, word ss:[si]
    mov ah, 02h
    int 13h
    jc .try_read_disk
    pop ax
    pop si
    pop dx
    ret

     
; Data Section
cursor_pos:
cursor_column:  db 0
cursor_row:     db 0

boot_msg:		db	"Booting Macrohard..."
boot_msg_len    equ $ - boot_msg

load_root_msg:   db  "Root sector loaded!"
load_root_msg_len   equ $ - load_root_msg

print_mem_buf:   
    dw 0x0000
    db ' '
print_mem_buf_len   equ $ - print_mem_buf

loader_filename:    db "LOADER  BIN"

root_sec_num    equ 19


times 	510-($-$$)	db	0	
dw 	0xaa55			
    

