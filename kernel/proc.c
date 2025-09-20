#include "proc.h"
#include "irq.h"
#include "libc.h"
#include "desc.h"
#include "types.h"
#include "panic.h"

struct process process_table[NR_MAX_TASK] = {};

struct process *current_process;

pid_t max_pid = 0;

int ticks = 0;

void scheduler() {
    /* update current process */
    ticks++;
    current_process->exec_tick += 1;

    /* scale division so that we don't need float numbers */
    #ifndef SCHED_DIV_SCALE
    #define SCHED_DIV_SCALE 12
    #endif
    int std_exec_time;
    int min_std_exec_time = INT_MAX;
    pid_t next_pid;
    for (int i = 0; i <= max_pid; i++) {
        /* execute the process that has never be */
        if (process_table[i].blocked == BLOCKED)
            continue;
        if (process_table[i].exec_tick == 0) {
            process_table[i].init_tick = ticks;
            next_pid = i;
            break;
        }
        if (process_table[i].exist) {
            std_exec_time = \
                (process_table[i].exec_tick<<SCHED_DIV_SCALE) \
                / ((ticks - process_table[i].init_tick + 1) * process_table[i].priority);
            if (std_exec_time < min_std_exec_time) {
                min_std_exec_time = std_exec_time;
                next_pid = i;
            }
        }
    }
    current_process = &process_table[next_pid];
    //printk("%s", current_process->proc_name);
    return ;
}

int check_deadlock(pid_t pid) {
    pid_t ptr = pid;
    while (!(process_table[ptr].blocked == UNBLOCKED || \
            process_table[ptr].waitpid == WAIT_FOR_KERNEL)) {
        ptr = process_table[ptr].waitpid;
        if (ptr == pid) 
            return 1;
    }
    return 0;
}

void block(pid_t pid, pid_t wait_for_pid) {
    process_table[pid].blocked = BLOCKED;
    process_table[pid].waitpid = wait_for_pid;
    assert(check_deadlock(pid) == 0);
    scheduler();
}

void unblock(pid_t pid) {
    if (process_table[pid].blocked) {
        process_table[pid].blocked = UNBLOCKED;
    }
}


void init_timer_handler() {
    irq_handlers[NR_8259_CLOCK] = scheduler;
    return ;
}


/* add a function to a process */
void add_process(void *func, char *stack, int stack_size, int priority, char *proc_name) {
    pid_t pid;
    struct process *proc;
    struct proc_stack *pstack;
    /* THIS NEED A HEAP TO SAVE UNUSED PID!!!! */
    for (int i = 0; i < NR_MAX_TASK; i++) {
        if (process_table[i].exist == 0) {
            pid = i;
            proc = &process_table[pid];
            proc->pid = pid;
            if (max_pid < pid)
                max_pid = pid;
            proc->exist = 1;
            break;
        }
    }
    /* Set up process.stack */
    
    pstack = &(proc->pstack);
    pstack->gs  = default_ldt_selector[NR_LDT_VIDEO];
    pstack->fs  = default_ldt_selector[NR_LDT_FLAT_DATA];
    pstack->es  = pstack->fs;
    pstack->ds  = pstack->fs;
    pstack->ss  = pstack->fs;
    pstack->kernel_esp = (uint32)&(pstack->eip); // so that after popad it points to proc_stack.eip
    pstack->eip = (uint32)func;
    pstack->cs  = default_ldt_selector[NR_LDT_FLAT_CODE];
    pstack->eflags = 0x1202; /* IF & IOPL */
    pstack->proc_esp = (uint32)stack+(uint32)stack_size;

    /* Set up LDT */
    memcpy((uchar *)&(proc->ldt), (uchar *)default_ldt, sizeof(struct desc)*NR_LDT);
    gdt_selector[NR_GDT_LDT] = GET_SELECTOR(NR_GDT_LDT, SP_RPL0);
    proc->ldt_selector = gdt_selector[NR_GDT_LDT];
    
    /* initialize schuduler entries */
    proc->priority = priority;
    proc->exec_tick = 0; // the execution duration measured in `ticks`
    proc->init_tick = 0; // the absolute start time;
    memcpy(proc->proc_name, proc_name, 20); // 20 is the size of proc_name buffer
    proc->proc_name[19] = '\0';
    return ;
}

/* Set GDT's LDT entry to desc *ldt */
void switch_ldt(struct process *proc) { 
    gdt[NR_GDT_LDT] = GDT_ENTRY((uint)&(proc->ldt), sizeof(struct desc)*NR_LDT, DA_LDT);
}





   
    
    



