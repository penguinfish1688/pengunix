[SECTION .data]

[SECTION .text]
[BITS 32]

NR_SYSCALL_MAILBOX  equ     0
NR_SYSCALL_SEND     equ     1
NR_SYSCALL_RECV     equ     2
NR_SYSCALL_FOO      equ     100


; System Call
global  syscall_mailbox
global  syscall_send
global  syscall_recv
global  syscall_foo

syscall_mailbox:
    push ebp
    mov ebp, esp
    push ebx
    mov ecx, dword [ebp+12]
    mov ebx, dword [ebp+8]
    mov eax, NR_SYSCALL_MAILBOX
    int 0x80
    pop ebx
    pop ebp
    ret

syscall_send:
    push ebp
    mov ebp, esp
    push ebx
    mov edx, dword [ebp+16]
    mov ecx, dword [ebp+12]
    mov ebx, dword [ebp+8]
    mov eax, NR_SYSCALL_SEND
    int 0x80
    pop ebx
    pop ebp
    ret

syscall_recv:
    push ebp
    mov ebp, esp
    push ebx
    mov edx, dword [ebp+16]
    mov ecx, dword [ebp+12]
    mov ebx, dword [ebp+8]
    mov eax, NR_SYSCALL_RECV
    int 0x80
    pop ebx
    pop ebp
    ret

syscall_foo:
    push ebp
    mov ebp, esp
    push ebx
    mov ebx, dword [ebp+8] 
    mov eax, NR_SYSCALL_FOO
    int 0x80
    pop ebx
    pop ebp
    ret




