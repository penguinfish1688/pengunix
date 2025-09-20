[SECTION .data]


[SECTION .text]
[BITS 32]
extern gdt
extern gdt_ptr
extern gdt_selector
extern idt_ptr
extern tss
extern kernel_main
extern memcpy
extern strcpy
extern disp_num
extern disp_str
extern disp_mem
extern output_addr
extern exception_handler
extern enable_8259a
extern disable_8259a
extern current_process
extern irq_handlers
extern switch_ldt
extern meminfo_tbl

extern syscall_lst

; Panic show register
extern disp_regs

global _start
global load_gdt
global load_ldt
global load_idt
global disp_char
global del_char
global irq_on
global irq_off
global in
global out

; Exception handlers
global	divide_error
global	single_step_exception
global	nmi
global	breakpoint_exception
global	overflow
global	bounds_check
global	inval_opcode
global	copr_not_available
global	double_fault
global	copr_seg_overrun
global	inval_tss
global	segment_not_present
global	stack_exception
global	general_protection
global	page_fault
global  copr_presv
global	copr_error
global  align_check
global  machine_check
global  simd_error

global  raise_exception

global current_esp
global current_ss
global load_tss

; IRQ handler
global  run
global  irq00
global  irq01
global  irq02
global  irq03
global  irq04
global  irq05
global  irq06
global  irq07
global  irq08
global  irq09
global  irq10
global  irq11
global  irq12
global  irq13
global  irq14
global  irq15

; Syscall context switch handler
global  syscall_handler

; Kernel Panic
global  panic


kernel_stack_base equ 0x9F000
gdt_size equ 256    ; 8 bytes * 32 entries
meminfo_tbl_size equ 320  ; 20 bytes * 16 entries

; Entry point of the kernel. 
;  ecx = address of gdt_ptr
;  cs  = SelectorFlatCode
;  ds, ss, es = SelectorFlatData
;  gs  = SelectorVideo
;
_start:
    ; Reset the stack pointer to 0x9F000
    mov esp, kernel_stack_base
    
    ; Pointer to memory info
    push edx

    ; Copy kernel GDT in boot loader to struct desc *gdt
    ; memcpy(struct desc *gdt, dword [ecx+2], word [ecx])
    push ecx
    push word 0
    push word [ecx]
    push dword [ecx+2] ; base of gdt
    push dword gdt
    call memcpy
    add esp, 12
    pop ecx
    

    ; Update GDT pointer
    mov [gdt_ptr], word gdt_size
    mov [gdt_ptr+2], dword gdt

    ; Reload gdt
    push dword gdt_ptr
    call load_gdt
    add esp, 4
    
    ; Load total RAM size
    pop edx
    push dword meminfo_tbl_size
    push edx
    push dword meminfo_tbl
    call memcpy
    add esp, 12
    

    ; jump to kernel routine in kernel.c
    call kernel_main
    
    jmp $

panic:
    push word 0
    push cs
    push word 0
    push ss
    push esp
    push ebp
    push edi
    push esi
    push edx
    push ecx
    push ebx
    push eax
    call disp_regs
    jmp $
    hlt 



; void load_gdt(struct desc_ptr*)
load_gdt:
    mov eax, dword [esp+4]
    lgdt [eax]
    ret

; void load_ldt(uint16 ldt_selector)
load_ldt:
    mov ax, word [esp+4]
    lldt ax
    ret

; void load_idt(struct desc_ptr*)
load_idt:
    mov eax, dword [esp+4]
    lidt [eax]
    ret

; Offset in TSS
tss_esp0    equ     4
tss_ss0     equ     tss_esp0 + 4
tss_esp1    equ     tss_ss0  + 4
tss_ss1     equ     tss_esp1 + 4
tss_esp2    equ     tss_ss1  + 4
tss_ss2     equ     tss_esp2 + 4

; uint32 current_ss()
current_ss:
    xor eax, eax
    mov ax, ss
    ret
; uint32 current_esp()
current_esp:
    mov eax, esp
    ret
; void load_tss(uint16 tss_selector)
load_tss:
    mov ax, word [esp+4]
    ltr ax
    ret

; void irq_on()
irq_on:
    sti
    ret

; void irq_off()
irq_off:
    cli
    ret

; void send_eoi(int port)
; send eoi to 8259A
EOI  equ  0x20
send_eoi:
    mov eax, dword [esp+4]
    cmp eax, 7
    ja .slave
.master:
    mov ax, EOI
    out 0x20, ax ; 0x20 is master IO port
    jmp .end
.slave:
    mov ax, EOI
    out 0xA0, ax ; 0xA0 is slave IO port
.end:
    ret
    

raise_exception:
    ud2
    ret

; uchar in(uint16 port)
in:
    mov dx, word [esp+4]
    in al, dx
    ret

; void out(uchar val, uint16 port);
out:
    mov dx, word [esp+8]
    mov al, byte [esp+4]
    out dx, al
    ret

; elements in struct task offset
task_stack          equ 0
task_stack_eax      equ task_stack+11*4
task_stack_top      equ task_stack_eax+6*4
task_ldt_selector   equ task_stack_top
task_ldt            equ task_ldt_selector+2
task_pid            equ task_ldt+8*32

; IRQ handler
%macro irq_entry 1
    ; When an IRQ occur, the kernel stack pointer points to task_table
    ; Save registers
    pushad
    push ds
    push es
    push fs
    push gs
    ; Switch to kernel stack if reentry = 0
    mov eax, dword [reentry]
    cmp eax, 0
    jne .reentry0
    mov esp, kernel_stack_base 
.reentry0:
    inc dword [reentry]
    ; disable_8259a(int port_nr)
    push dword %1
    call disable_8259a
    add esp, 4
    
    ; send_eoi(int port_nr)
    push dword %1
    call send_eoi
    add esp, 4

    sti
    call [irq_handlers + ((%1)*4)]      ; irq_handler[NR_IRQ];
    cli
    
    ; enable_8259a(int port_nr)
    push dword %1
    call enable_8259a
    add esp, 4
    dec dword [reentry]
    jmp run
%endmacro

; syscall handler
syscall_handler:
    ; When an IRQ occur, the kernel stack pointer points to task_table
    ; Save registers
    pushad
    push ds
    push es
    push fs
    push gs
    ; Switch to kernel stack. Syscall must occur in userspace, so we always change stack
    mov esp, kernel_stack_base 
    inc dword [reentry]
    
    ; Restore register
    push dword [current_process]
    push ebp
    push edi
    push esi
    push edx
    push ecx
    push ebx
    sti
    call [syscall_lst+eax*4]
    cli
    add esp, 24
    pop ecx
    ; Change the eax stored in the stack frame
    mov [ecx+task_stack_eax], eax

    dec dword [reentry]
    jmp run

run:
    ; Switch to current_process if renetry = 0
    mov eax, dword [reentry]
    cmp eax, 0
    jne .reentry1
.run_current_process: 
    ; Set GDT's LDT entry to the current process
    push dword [current_process]
    call switch_ldt
    add esp, 4
    ; Set esp to current process table
    mov esp, dword [current_process]
    ; Load the current process's LDT
    lldt word [esp+task_ldt_selector]
    ; Set TSS esp0 to process table's stack top
    mov eax, esp
    add eax, task_stack_top
    mov [tss+tss_esp0], eax
    
.reentry1:
    pop gs
    pop fs
    pop es
    pop ds
    popad
    iretd



; reentry is the number of interupt currently handling 
reentry:    dd  0

irq00:
    irq_entry   0
irq01:
    irq_entry   1
irq02:
    irq_entry   2
irq03:
    irq_entry   3
irq04:
    irq_entry   4
irq05:
    irq_entry   5
irq06:
    irq_entry   6
irq07:
    irq_entry   7
irq08:
    irq_entry   8
irq09:
    irq_entry   9
irq10:
    irq_entry   10
irq11:
    irq_entry   11
irq12:
    irq_entry   12
irq13:
    irq_entry   13
irq14:
    irq_entry   14
irq15:
    irq_entry   15


; Exception handlers
divide_error:
	push	0xFFFFFFFF	; no err code
	push	0		; vector_no	= 0
	jmp	exception
single_step_exception:
	push	0xFFFFFFFF	; no err code
	push	1		; vector_no	= 1
	jmp	exception
nmi:
	push	0xFFFFFFFF	; no err code
	push	2		; vector_no	= 2
	jmp	exception
breakpoint_exception:
	push	0xFFFFFFFF	; no err code
	push	3		; vector_no	= 3
	jmp	exception
overflow:
	push	0xFFFFFFFF	; no err code
	push	4		; vector_no	= 4
	jmp	exception
bounds_check:
	push	0xFFFFFFFF	; no err code
	push	5		; vector_no	= 5
	jmp	exception
inval_opcode:
	push	0xFFFFFFFF	; no err code
	push	6		; vector_no	= 6
	jmp	exception
copr_not_available:
	push	0xFFFFFFFF	; no err code
	push	7		; vector_no	= 7
	jmp	exception
double_fault:
	push	8		; vector_no	= 8
	jmp	exception
copr_seg_overrun:
	push	0xFFFFFFFF	; no err code
	push	9		; vector_no	= 9
	jmp	exception
inval_tss:
	push	10		; vector_no	= A
	jmp	exception
segment_not_present:
	push	11		; vector_no	= B
	jmp	exception
stack_exception:
	push	12		; vector_no	= C
	jmp	exception
general_protection:
	push	13		; vector_no	= D
	jmp	exception
page_fault:
	push	14		; vector_no	= E
	jmp	exception
copr_presv:
    push    0xFFFFFFFF
    push    15      ; vector_no = F
    jmp exception   
copr_error:
	push	0xFFFFFFFF	; no err code
	push	16		; vector_no	= 10h
	jmp	exception
align_check:
    push    17      ; vector_no = 11h
    jmp exception
machine_check:
    push    0xFFFFFFFF
    push    18      ; vector_no = 12h
    jmp exception
simd_error:
    push    0xFFFFFFFF
    push    19      ; vector_no = 13h
    jmp exception   

exception:
	call exception_handler
	add	esp, 4*2	
	hlt





; void disp_char(char c)
; display the char to gs:output_addr and increase output_addr by 1
disp_char:
    mov al, byte [esp+4]
    mov ah, 0x0A
    mov ecx, dword [output_addr]
    mov gs:[ecx], ax
    mov eax, dword [output_addr]
    add eax, 2
    mov dword [output_addr], eax
    ret

; void del_char()
; delete one char
del_char:
    mov eax, dword [output_addr]
    sub eax, 2
    mov dword [output_addr], eax
    xor eax, eax
    mov ecx, dword [output_addr]
    mov gs:[ecx], ax
    ret













