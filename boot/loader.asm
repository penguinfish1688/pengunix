; *************************************************
; Bootloader 
; 0. Setup GDT for bootloader
; 1. Parse root directory to find 'KERNEL  bin'
; 2. Read FATs to get the sectors of the kernel
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

    jmp short LABEL_START		; Start to boot.
    nop				
    %include "fat12hdr.inc"
    %include "loader.inc"

[SECTION .CODE16]
[BITS 16]
LABEL_START:
    mov	cx, cs  ; cs = 0x8000
	mov	ds, cx  
	mov	es, cx
    mov gs, cx
    
    ; Restore cursor position
    mov byte [cursor_column], al
    mov byte [cursor_row], ah
    
    ; Show booting message
    mov cx, loader_msg_len ; msg len   
    mov bp, loader_msg     ; msg ptr
    mov ax, 1            ; endline after print 
    call print_real
    
    ; Search for bootloader blocks in FAT12 root directory
    push es
    mov ax, kernel_elf_segment  ; Load FAT12 root directory to es:bx = 0x3000:0
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
    mov si, kernel_filename
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
    push gs
    push ax                 ; ax = first FAT entry
    push es
    ; Load FAT table
    mov ax, 0x7000
    mov es, ax              
    mov bx, 0xE000          ; Load FAT to 0x7000:E000. The size of FAT is 0x1800
    mov ax, 1               ; Starting sector of FAT 
    mov cx, word [BPB_FATSz16]
    
    call load_sectors
    pop es
    
    ; Load Kernel ELF
    mov ax, 0x7000  ; gs:bp = 0x7000:0xE000 point to FAT table 
    mov gs, ax
    mov bp, bx  
    xor bx, bx  ; Load to es:bx = 0x5000:0
    pop ax
    call load_fat_file
    %ifdef DEBUG    ; Make sure the kernel ELF is loaded to the memory
    mov bx, 0x0
    mov ax, 0x100
    call print_mem
    %endif
    pop gs
    pop es
    

    call READ_MEM_SIZE
    cmp ax, 0
    je .read_memory_size_success
    ; Show "Read memory size error"
    mov cx, read_mem_err_msg_len   ; msg len
    mov bp, read_mem_err_msg       ; msg ptr
    mov ax, 1                   ; endline
    call print_real
    jmp $
 
.read_memory_size_success:
    ; Show "Read memory size success"
    mov cx, read_mem_msg_len   ; msg len
    mov bp, read_mem_msg       ; msg ptr
    mov ax, 1                   ; endline
    call print_real


    ; Setup page table

    ; Show "Kernel loaded"
    mov cx, kernel_loaded_msg_len   ; msg len
    mov bp, kernel_loaded_msg       ; msg ptr
    mov ax, 1                   ; endline
    call print_real
    
    ; Show "Jumping to protect mode"
    mov cx, start_pm_msg_len   ; msg len
    mov bp, start_pm_msg       ; msg ptr
    mov ax, 1                   ; endline
    call print_real
    
    ; Load gdt
    lgdt [gdt_ptr]
    
    ; Close interrupt
    cli
    
    ; Open A20
    in al, 0x92
    or al, 00000010b
    out 0x92, al

    ; Set cr0 to protect mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    ; Jump to protect mode segment
    jmp dword SelectorFlatCode:(PM_MODE_START+loader_addr)
    
; On success eax = 0
READ_MEM_SIZE:
    push edx
    push ebx
    push ecx
    push es
    push di
    xor ebx, ebx
    mov ax, loader_segment
    mov es, ax
    mov di, memory_map_buf
.loop:
    cmp di, memory_map_buf_end
    jb .not_full
    mov ax, 1   ; No enough buffer for every entry!
    jmp .end_loop
.not_full:
    push di
    mov ax, 0xE820
    mov edx, 0x534D4150
    mov ecx, 20
    int 0x15
    pop di
    add di, 20
    test ebx, ebx   ; If finished ebx = 0
    je .end_loop
    jnc .loop
    
.end_loop:
    cmp eax, 0x534D4150
    jne .error
    xor eax, eax    ; return 0 on success
.error:
    pop di
    pop es
    pop ecx
    pop ebx
    pop edx
    ret
    
    


; Load FAT12 file 
;   es:bx   where to load the file
;   gs:bp   FAT table
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
    mov ax, word gs:[bp+si]
    shr ax, 4
    jmp .load_next_cls
.bottom:
    mov ax, word gs:[bp+si]
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
    mov di, print_mem16_buf
    add di, dx
    mov byte [di], cl
    inc dx
    cmp dx, 2
    jb .byte2ascii
    push es
    mov cx, cs
    mov es, cx
    mov bp, print_mem16_buf
    mov cx, print_mem16_buf_len
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

; ********************************************************
;
; All functions in .CODE32 follow C x86 calling convention
;
; ********************************************************



[SECTION .CODE32]
[BITS 32]
ALIGN 32

%include "gdt.inc"

; GDT                               | base addr | limit | Attributes | 
LABEL_GDT:              Descriptor           0,       0,           0
LABEL_DESC_FLAT_CODE:   Descriptor           0, 0xFFFFF,    DA_RE+DP_DPL0+DA_32+LG_4K
LABEL_DESC_FLAT_DATA:   Descriptor           0, 0xFFFFF,    DA_RW+DP_DPL0+DA_32+LG_4K
LABEL_DESC_VIDEO:       Descriptor     0xB8000,  0x7FFF,    DA_RW+DA_32+DP_DPL3
LABEL_DESC_PAGE_DIR:    Descriptor page_dir_addr,     0,    DA_RW+DA_32
LABEL_DESC_PAGE_TBL:    Descriptor page_tbl_addr,     0,    DA_RW+DA_32+LG_4K
; GDT pointer
gdt_len equ $ - LABEL_GDT
gdt_ptr:
    dw gdt_len
    dd LABEL_GDT + loader_addr

; GDT selectors

SelectorFlatCode    equ LABEL_DESC_FLAT_CODE - LABEL_GDT
SelectorFlatData    equ LABEL_DESC_FLAT_DATA - LABEL_GDT
SelectorVideo       equ LABEL_DESC_VIDEO     - LABEL_GDT + SP_RPL3
SelectorPageDir     equ LABEL_DESC_PAGE_DIR  - LABEL_GDT
SelectorPageTbl     equ LABEL_DESC_PAGE_TBL  - LABEL_GDT



PM_MODE_START:
    mov ax, SelectorFlatData
    mov ds, ax
    mov es, ax
    mov gs, ax

    mov cx, ss  ; Convert stack pointer ss:sp to 32 bit address
    mov ss, ax
    shl cx, 4
    xor edx, edx
    mov dx, sp
    add ecx, edx
    mov esp, ecx
    mov ebp, esp

    xor eax, eax
    mov al, byte [cursor_row+loader_addr]  ; Initialize cursor offset
    mov ecx, eax                ; row * 80 = row * (2^4+2^6)
    shl ecx, 4
    shl eax, 6
    add eax, ecx
    xor ecx, ecx
    mov cl, byte [cursor_column+loader_addr]       ; row*80 + column
    add eax, ecx
    mov dword [cursor_vga_offset+loader_addr], eax    ; Write to memory
        
    
    push dword cursor_vga_offset+loader_addr ; Show "In protect mode..."
    push dword in_pm_msg+loader_addr
    call LABEL_PRT_STR
    add esp, 8

    push dword cursor_vga_offset+loader_addr ; Show "Reading memory size..."
    push dword load_mem_size_msg+loader_addr
    call LABEL_PRT_STR
    add esp, 8

    call PRT_RAM_SIZE
    
    push dword cursor_vga_offset+loader_addr ; Show "Done"
    push dword done_msg+loader_addr
    call LABEL_PRT_STR
    add esp, 8


    push dword cursor_vga_offset+loader_addr ; Show "Setting up page table..."
    push dword set_page_table_msg+loader_addr
    call LABEL_PRT_STR
    add esp, 8

    call INIT_PAGING

    push dword cursor_vga_offset+loader_addr ; Show "Done"
    push dword done_msg+loader_addr
    call LABEL_PRT_STR
    add esp, 8
   

    push dword cursor_vga_offset+loader_addr ; Show "Loading MACROHARD kernel..."
    push dword kernel_elf_loader_msg+loader_addr
    call LABEL_PRT_STR
    add esp, 8
    call INIT_KERNEL

    push dword cursor_vga_offset+loader_addr ; Show "Done"
    push dword done_msg+loader_addr
    call LABEL_PRT_STR
    add esp, 8
    
    ; Set gs to video memory selector
    mov ax, SelectorVideo
    mov gs, ax

    ; Kernel ELF entry point
    mov eax, dword [elf_entry+loader_addr]
    
    ; Save kernel GDT address to ecx
    mov ecx, loader_addr
    add ecx, gdt_ptr
    
    ; Save total memory size
    mov edx, loader_addr+memory_map_buf
    jmp eax

    
    
    ; Place the kernel elf
    ; jmp kernel_segment:kernel_offset

; void MEM_CPY(void *src, void *dst, int n);
; copy n bytes from src to dst
MEM_CPY:
    push ebp
    mov ebp, esp
    push ebx
    mov ecx, dword [ebp+16]
    mov eax, dword [ebp+8]  ; eax: source
    mov edx, dword [ebp+12] ; edx: dest
    add ecx, eax            ; last byte to copy+1
.loop:
    cmp eax, ecx
    jae .end_loop
    mov bl, byte [eax]
    mov [edx], bl
    inc eax
    inc edx
    jmp .loop
.end_loop:
    pop ebx
    pop ebp
    ret

; Load ELF sections to the memory
INIT_KERNEL:
    push ebp
    mov ebp, esp
    mov eax, dword [kernel_elf_addr+elf_entry_offset]
    mov [elf_entry+loader_addr], eax    ; Read kernel ELF entry point
    xor eax, eax
    mov ax, word [kernel_elf_addr+elf_phnum_offset]
    mov ecx, dword [kernel_elf_addr+elf_ph_offset_offset]
    add ecx, kernel_elf_addr
.loop:
    test eax, eax
    je .end_loop
    ; for each program header copy ph_filesz byte to ph_vaddr from ph_offset+kernel_elf_offset
    push eax
    push ecx
    push dword [ecx+ph_filesz_offset] ; n
    push dword [ecx+ph_vaddr_offset]  ; (void *)dst
    mov edx, dword [ecx+ph_offset_offset]
    add edx, kernel_elf_addr
    push edx                          ; (void *)src
    call MEM_CPY
    add esp, 12
    pop ecx
    ; pad ph_memsz-ph_filesz times of 0 to ph_vaddr+ph_filesz
    mov edx, dword [ecx+ph_memsz_offset]
    mov eax, dword [ecx+ph_filesz_offset]
    sub edx, eax ; edx is the number of 0 padding bytes
    push edx
    mov edx, dword [ecx+ph_vaddr_offset]
    add eax, edx ; eax is ph_vaddr+ph_filesz = start of padding addr
    pop edx
.loop_zpad:
    test edx, edx
    je .end_loop_zpad
    mov byte [eax], 0
    dec edx
    inc eax
    jmp .loop_zpad
.end_loop_zpad:
    pop eax
    dec eax
    add ecx, elf_ph_size
    jmp .loop
.end_loop:
    pop ebp
    ret
    
    

; Setup page table
INIT_PAGING:
    push ebp
    mov ebp, esp
    push es
    mov eax, dword [total_ram_size+loader_addr]
    shr eax, 22 ; top 10 bits represent page directory address (-22 bits). 
    inc eax
    shl eax, 2  ; each directory entry has four bytes (+2 bits). 
    mov [page_dir_size+loader_addr], eax
    mov eax, dword [total_ram_size+loader_addr]
    shr eax, 12 ; [21...12] select page table 
    shl eax, 2  ; each table entry has four bytes 
    mov [page_tbl_size+loader_addr], eax
    
    ; patch GDT limit 
    mov eax, dword [page_dir_size+loader_addr]
    dec eax
    mov [LABEL_DESC_PAGE_DIR+loader_addr], ax   ; ax = page_dir_size-1
    inc eax
    shl eax, 10 ; each page dir has 1024 page table entry
    shr eax, 12 ; the unit of GDT's limit is 4k
    inc eax     ; add back the remainder
    mov [LABEL_DESC_PAGE_TBL+loader_addr], ax   ; ax = page_dir_size*1024 - 1  
    
    mov ax, SelectorPageDir ; Start filling page table
    mov es, ax              ; es = SelectorPageDir
    mov eax, dword [page_dir_size+loader_addr] ; limit
    xor ecx, ecx  
    mov edx, page_tbl_addr
    or dl, 00000001b ; Present
    or dl, 00000010b ; Read and Write
    or dl, 00000100b ; User
.loop_dir:
    cmp ecx, eax
    jae .end_loop_dir
    mov es:[ecx], edx
    add ecx, 4
    add edx, 4096
    jmp .loop_dir
.end_loop_dir:
    mov ax, SelectorPageTbl
    mov es, ax
    mov eax, dword [page_dir_size+loader_addr] ;
    shl eax, 10 ; 1 page dir entry = 1024 page table entry = 4096 bytes
    xor ecx, ecx
    xor edx, edx
    or dl, 00000001b ; Present
    or dl, 00000010b ; Read and Write
    or dl, 00000100b ; User
.loop_tbl:
    cmp ecx, eax
    jae .end_loop_tbl
    mov es:[ecx], edx
    add ecx, 4
    add edx, 4096
    jmp .loop_tbl
.end_loop_tbl:
    mov eax, page_dir_addr
    mov cr3, eax        ; cr3 is the base directory register
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    jmp short .enable_cr3
.enable_cr3:
    nop
    pop es
    pop ebp
    ret
    

; void PRT_RAM_SIZE()
; Show total RAM size and show memory usage to users
PRT_RAM_SIZE:
    push ebp
    mov ebp, esp
    
    ; Print __base__h __size__h __type__h
    push cursor_vga_offset+loader_addr
    push mem_info_buf+loader_addr
    call LABEL_PRT_STR
    add esp, 8
    
    mov eax, loader_addr+memory_map_buf
.loop:
    mov ecx, dword [eax+16]
    test ecx, ecx
    je .end_loop
    cmp ecx, 1
    jne .not_type1
    mov ecx, dword [eax]
    add ecx, dword [eax+8]
    cmp dword [total_ram_size+loader_addr], ecx
    jae .not_greater
    mov [total_ram_size+loader_addr], ecx 
.not_greater:
.not_type1:
    ; Write base
    push eax
    push mem_info_base+loader_addr
    push dword [eax]
    call LABEL_NTOA
    add esp, 8
    pop eax

    ; Write size
    push eax
    push mem_info_size+loader_addr
    push dword [eax+8]
    call LABEL_NTOA
    add esp, 8
    pop eax

    ; Write type
    push eax
    push mem_info_type+loader_addr
    push dword [eax+16]
    call LABEL_NTOA
    add esp, 8 

    ; Print memory info
    push cursor_vga_offset+loader_addr
    push mem_info_buf+loader_addr
    call LABEL_PRT_STR
    add esp, 8
    
    pop eax
    add eax, 20
    jmp .loop 
.end_loop:
    push ram_size_str_num+loader_addr
    push dword [total_ram_size+loader_addr] 
    call LABEL_NTOA
    add esp, 8

    ; Show total_ram_size
    push cursor_vga_offset+loader_addr
    push ram_size_str+loader_addr
    call LABEL_PRT_STR
    add esp, 8
    pop ebp
    ret

; void LABEL_NTOA(int n, char *buf)
; print an int to hex
LABEL_NTOA:
    push ebp
    mov ebp, esp
    push edi
    mov eax, dword [ebp+8]
    mov edi, dword [ebp+12]
    mov ecx, 7
.loop:
    mov dl, al
    and dl, 0x0F
    cmp dl, 9
    jbe .is_num
.is_alph:
    add dl, 'A'-10
    jmp .done_cmp
.is_num:
    add dl, '0'
.done_cmp:
    add edi, ecx
    mov [edi], dl
    sub edi, ecx
    shr eax, 4
    dec ecx
    cmp ecx, 0
    jge .loop
    pop edi
    pop ebp
    ret

; void LABEL_PRT_STR(char *str, int *vga_offset)
; Print a string
; ds:str: String pointer
; ds:vga_offset: Cursor position
LABEL_PRT_STR:
    push ebp
    mov ebp, esp
    mov eax, dword [esp+8]
    mov ecx, dword [esp+12]
    push edi
    mov edi, dword [ecx]
    shl edi, 1
    add edi, 0xB8000    ; edi = 0xB8000 + vga_offset*2

.iter_char:
    mov cl, byte [eax]          ; Move char to ecx
    test cl, cl
    je .end_iter_char       ; Break if NULL ended
    cmp cl, 0x0A            ; Check if it is endline char 
    je .is_endline
    mov ch, 0x0C            ; Font color
    mov [edi], cx        ; Move to display memory
    add edi, 2              ;
    inc eax
    jmp .iter_char          ; }
.is_endline:                ; else (is \n) {
    push edi
    push ecx
    sub edi, 0xB8000          ; write offset back to cursor_vga_offset
    shr edi, 1
    mov ecx, dword [esp+24]   ; ptr to cursor_vga_offset
    mov [ecx], edi
    pop ecx
    pop edi

    push eax
    push ecx
    push dword loader_addr+cursor_vga_offset
    call LABEL_PRT_ENDLINE  ; void LABEL_PRT_ENDLINE(int *cursor_vga_offset)
    add esp, 4
    pop ecx
    pop eax
    
    mov edi, dword [esp+16] ; Reload cursor
    mov edi, dword [edi]
    shl edi, 1
    add edi, 0xB8000
    
    inc eax
    jmp .iter_char          ; }
.end_iter_char:
    sub edi, 0xB8000          ; restore cursor_vga_offset
    shr edi, 1
    mov ecx, dword [esp+16]   ; ptr to cursor_vga_offset
    mov [ecx], edi
    pop edi
    pop ebp
    ret

; Print bytes in hex
; es: number's segment
; eax: offset of the number
; ecx: number of bytes
; edi: cursor position
LABEL_PRT_NUM:
    push ebx
    xor ebx, ebx
.loop:
    mov bl, byte [es:eax]
    shr bl, 4
    add bx, '0'

; void LABEL_PRT_ENDLINE(int *cursor_vga_offset)
; Print the endline character
; vga_offset: pointer to cursor position
LABEL_PRT_ENDLINE:
    push ebp
    mov ebp, esp
    mov eax, dword [esp+8]
    mov eax, dword [eax]    ; load *cursor_vga_offset to eax

    xor edx, edx            ; edx:eax / r32 = eax...edx
    mov ecx, 80
    div ecx                  ; After division eax = row, edx = column
    inc eax
    mov ecx, 80
    mul ecx
    
    mov ecx, dword [esp+8]  ; write back to cursor_vga_offset
    mov [ecx], eax             
    pop ebp
    ret

; Print a character
; eax: Charactor that will be printed
; edi: The position of the cursor
LABEL_PRT_CHAR:
    push ecx
    push gs
    mov cx, SelectorVideo
    mov gs, cx
    mov ah, 0x0C      ; Red Font color
    mov [gs:edi], ax  ; Print to display memory
    add edi, 2
    pop gs
    pop ecx
    ret
  

; Data Section
cursor_pos:
cursor_column:  db 0
cursor_row:     db 0
cursor_vga_offset: dd 0

; int 15h memory map buffer
memory_map_buf:
    times 320 db 0
memory_map_buf_end:
    times 20 db 0   ; 0 terminated
total_ram_size: 
    dd 0
ram_size_str:
    db "total ram size:"
    db 0x0A
ram_size_str_num:
    times 8 db 0
    db 'h', 0x0A, 0

page_dir_addr equ 0x100000
page_tbl_addr equ 0x101000
page_dir_size: dd 0
page_tbl_size: dd 0

elf_entry_offset        equ 24
elf_ph_offset_offset    equ 28
elf_phnum_offset        equ 44
elf_ph_size             equ 32
elf_entry:      dd 0
elf_ph_offset:  dd 0
elf_phnum:     dw 0
ph_offset_offset        equ 4
ph_vaddr_offset         equ 8
ph_filesz_offset        equ 16
ph_memsz_offset         equ 20
ph_offset:      dd 0
ph_vaddr:       dd 0
ph_filesz:      dd 0
ph_memsz:       dd 0

loader_msg:		db	"Bootloader is running..."
loader_msg_len  equ $ - loader_msg

kernel_loaded_msg:   db  "MACROHARD kernel loaded!"
kernel_loaded_msg_len   equ $ - kernel_loaded_msg

read_mem_err_msg:   db "Read memory size error!"
read_mem_err_msg_len    equ $ - read_mem_err_msg

read_mem_msg:   db "Read memory success!"
read_mem_msg_len    equ $ - read_mem_msg

start_pm_msg:   db "Jumping to protect mode..."
start_pm_msg_len    equ $ - start_pm_msg

in_pm_msg:      db "In protect mode...", 0x0A, 0
in_pm_msg_len  equ $ - in_pm_msg

done_msg:      db "Done.", 0x0A, 0
done_msg_len   equ $ - done_msg

set_page_table_msg:      db "Setting up page table...", 0x0A, 0
set_page_table_msg_len   equ $ - set_page_table_msg

load_mem_size_msg:      db "Reading memory size...", 0x0A, 0
load_mem_size_msg_len   equ $ - load_mem_size_msg

kernel_elf_loader_msg: db "Organizing MACROHARD kernel ELF...", 0x0A, 0
kernel_elf_loader_msg_len equ $ - kernel_elf_loader_msg

print_mem16_buf:   
    dw 0x0000
    db ' '
print_mem16_buf_len   equ $ - print_mem16_buf

ntoa_buf:
    times 8 db 0
    db "h", 0
ntoa_buf_len    equ $ - ntoa_buf

ntoa_buf_endline:
    times 8 db 0
    db 'h', 0x0A, 0

; __BASE__h __SIZE__h __TYPE__h
mem_info_buf:
mem_info_base: db "__BASE__h "
mem_info_size: db "__SIZE__h "
mem_info_type: db "__TYPE__h "
    db 0x0A
    db 0

kernel_filename:    db "KERNEL  BIN"

root_sec_num    equ 19


    

