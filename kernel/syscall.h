#ifndef SYSCALL_H
#define SYSCALL_H

#include "proc.h"
#include "types.h"
#define NR_SYSCALL 256

#define ZERO_ARG    0
#define ONE_ARG     1
#define TWO_ARGS    2
#define THREE_ARGS  3
#define FOUR_ARGS   4
#define FIVE_ARGS   5
#define SIX_ARGS    6


#define NR_SYSCALL_MAILBOX  0
#define NR_SYSCALL_SEND     1
#define NR_SYSCALL_RECV     2
#define NR_SYSCALL_FOO      100

void syscall_mailbox(pid_t, mailbox_t *);

int syscall_send(pid_t, uint8 *, int);

int syscall_recv(pid_t, uint8 *, int);

int syscall_foo(char *);


void syscall_handler();

void init_syscall();

extern void *syscall_lst[NR_SYSCALL];

struct syscall {
    void *func;
    int nr_args;
};

#endif
