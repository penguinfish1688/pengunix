#ifndef PROC_H
#define PROC_H

#include "types.h"
#include "desc.h"
#include "fifo.h"


#define NR_MAX_TASK 1024

void init_timer_handler();

void add_process(void *, char *, int, int, char *);


typedef int pid_t;

extern pid_t max_pid;

/* store registers when context switch */
struct __attribute__((packed)) proc_stack {
    uint32 gs;  
    uint32 fs;
    uint32 es;
    uint32 ds;
    uint32 edi;     //************ 
    uint32 esi;     //
    uint32 ebp;     //
    uint32 kernel_esp;     //
    uint32 ebx;     // done by pushad
    uint32 edx;     //
    uint32 ecx;     //
    uint32 eax;     //
    uint32 eip;     //************
    uint32 cs;      
    uint32 eflags;
    uint32 proc_esp;
    uint32 ss;
};

#define WAIT_FOR_KERNEL -1
#define BLOCKED     1
#define UNBLOCKED   0

#ifndef MAILBOX_T
#define MAILBOX_T

#define DEFAULT_MAILBOX_SIZE 4096
DEFINE_FIFO_TYPE(mailbox_t, uint8, DEFAULT_MAILBOX_SIZE);

#endif

struct __attribute__((packed)) process {
    struct proc_stack pstack;
    selector_t ldt_selector;
    struct desc ldt[NR_LDT];
    pid_t pid;
    char proc_name[20];
    int exist;
    int priority;
    int exec_tick;
    int init_tick;
    volatile int blocked;
    volatile pid_t waitpid;     // The process that blocked this process
    mailbox_t *mailbox[NR_MAX_TASK];
};

extern struct process process_table[NR_MAX_TASK];

extern struct process *current_process;


int check_deadlock(pid_t);

void block(pid_t, pid_t);

void unblock(pid_t);

void switch_ldt(struct process *);



#endif
