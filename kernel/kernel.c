#include "types.h"
#include "global.h"
#include "desc.h"
#include "libc.h"
#include "io.h"
#include "irq.h"
#include "proc.h"
#include "keyboard.h"
#include "vm.h"
#include "syscall.h"
#include "panic.h"
#include "ipc.h"

void run();

void irq_on();


/* address (relative to video segment) in the video memory for the next output char */ 
int output_addr;

void raise_exception();

void process_A() {
    char *msg = "12345";
    mailbox_t A_mailbox;
    init_fifo(&A_mailbox);
    syscall_mailbox(2, &A_mailbox);
    while(1) {
        for (int i =0; i < 50000000; i++){
            
            int a = i/563;
        }
        int n;
        while (!(n = syscall_send(2, (uint8 *)msg, 5))) {}
        printk("A send %s\n", msg);

    }
}
char A_stack[10000];

void process_B() {
    while(1) {
        disp_str("");
        for (int i =0; i < 50000000; i++){

            int a = i/563;
        }
        char msg[10] = {};
        for (int i = 0; i < 10; i++)
            msg[i] = 0;
        int n; 
        while (!(n = syscall_recv(1, (uint8 *)msg, 6))) {}
        printk("B receive %s\n", msg);
    }
}
char B_stack[10000];

void process_C() {
    while(1) {
        disp_str("");
        for (int i =0; i < 50000000; i++){

            int a = i/563;
        }
    }
}
char C_stack[1000];


void process_D() {
    while(1) {
        disp_str("");
        for (int i =0; i < 50000000; i++){

            int a = i/563;
        }
    }
}
char D_stack[1000];



void kernel_main() {
    /* clear the screen and reset cursor */
    int a = 0;
    for(int i = 0; i < 10000000; i++){
        for(int j = 0; j < 10; j++)
           a += (i%2)*(i%1536);
    }

    output_addr = 0;
    clear_screen();
    output_addr = 0;
    

    /* Restore GDT Selector used in bootloader */
    bootloader_gdt_selector();
    
    
    /* Load TSS */
    init_tss();
    
    /* Initialize template for LTD */
    init_ldt();

    /* initialize 8259A */ 
    init8259a();
    
    /* setup interrupt table */
    init_idt();
   
    /* Setup keyboard driver and interrupt handler */
    init_keyboard();

    /* Initialze syscall handler */
    init_syscall();
    /* Show memory info */
    //show_mem_info();
    //disp_num(get_max_addr());
    //disp_str("\n");
    /* setup process table and timer handler */
    
    add_process(process_A, A_stack, 1000, 10, "A");
    add_process(process_B, B_stack, 1000, 20, "B");
    add_process(process_C, C_stack, 1000, 30, "C");
    add_process(process_D, D_stack, 1000, 40, "D");
    
    /* choose a process to run */
    current_process = &(process_table[0]);
    
    enable_8259a(0);
    disp_8259a();
    disp_str("\n$macrohard> schedule\n");
    disp_str("$macrohard> mailbox\n");
    init_timer_handler();    
    /* run */
    run();

}

