#include "ipc.h"
#include "proc.h"
#include "panic.h"
#include "fifo.h"
#include "libc.h"

/* Currently is one to one, after kmalloc, we can have several user send to the sameprocess */
void register_mailbox(pid_t pid, mailbox_t *sender_mailbox) {
    struct process *target_proc = &process_table[pid];
    target_proc->mailbox[current_process->pid] = sender_mailbox;
    return ;
}
/* Blocked and return 0 if nothing write to the buffer */

int mailbox_send(pid_t pid, uint8 *buf, int n) { 
    struct process *target_proc = &process_table[pid];
    struct mailbox_t *sender_mailbox = target_proc->mailbox[current_process->pid];
    assert(sender_mailbox != 0);
    int sent_n = write_fifo(sender_mailbox, buf, n);
    /* Target mailbox is full */
    if (sent_n == 0) {
        block(current_process->pid, pid);
    }
    else {
        if (target_proc->blocked == BLOCKED && target_proc->waitpid == current_process->pid)
            unblock(pid);
    }
    return sent_n;
   
}

int mailbox_receive(pid_t pid, uint8 *buf, int n) {
    struct process *target_proc = &process_table[pid];
    struct mailbox_t *sender_mailbox = current_process->mailbox[pid];
    if (sender_mailbox == 0) {
        block(current_process->pid, pid);
        return 0;
    }
    int recv_n = read_fifo(sender_mailbox, buf, n); 
    if (recv_n == 0) {
        block(current_process->pid, pid);
    }
    else {
         if (target_proc->blocked == BLOCKED && target_proc->waitpid == current_process->pid)
            unblock(pid);
    }
    return recv_n;
}



