#ifndef IPC_H
#define IPC_H

#include "fifo.h"
#include "types.h"
#include "proc.h"

#ifndef MAILBOX_T
#define MAILBOX_T

#define DEFAULT_MAILBOX_SIZE 8192
DEFINE_FIFO_TYPE(mailbox_t, uint8, DEFAULT_MAILBOX_SIZE);

#endif

void register_mailbox(pid_t, mailbox_t *);

int mailbox_send(pid_t, uint8 *, int);

int mailbox_receive(pid_t, uint8 *, int);



#endif
