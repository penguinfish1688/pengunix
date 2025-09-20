#include "syscall.h"
#include "libc.h"
#include "ipc.h"

void *syscall_lst[NR_SYSCALL];

int foo(char *str) {
    disp_str(str);
    return 100;
}


void init_syscall() {
    for (int i = 0; i < NR_SYSCALL; i++) {
        syscall_lst[i] = 0;
    }
    syscall_lst[NR_SYSCALL_MAILBOX] = (void *)register_mailbox;
    syscall_lst[NR_SYSCALL_SEND]    = (void *)mailbox_send;
    syscall_lst[NR_SYSCALL_RECV]    = (void *)mailbox_receive;
    syscall_lst[NR_SYSCALL_FOO]     = (void *)foo;
}


