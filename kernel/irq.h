#ifndef IRQ_H
#define IRQ_H


#define EXCEPT_NUM  20
#define IRQ_NUM     16

extern void *irq_handlers[IRQ_NUM];


#define NR_8259_BASE     0x20
#define NR_8259_CLOCK    0
#define NR_8259_KEYBOARD 1
#define NR_8259_NONE     2
#define NR_8259_PORT2    3
#define NR_8259_PORT1    4
#define NR_8259_LPT2     5
#define NR_8259_FLOPPY   6
#define NR_8259_LPT1     7
#define NR_8259_RT_CLOCK 8
#define NR_8259_RD_IRQ2  9
#define NR_8259_TBD1     10
#define NR_8259_TBD2     11
#define NR_8259_MOUSE    12
#define NR_8259_FPU      13  
#define NR_8259_AT       14
#define NR_IRQ_TBD3     15


/* IDT value */
#define NR_DE  0
#define NR_DB  1
#define NR_NI  2
#define NR_BP  3
#define NR_OF  4
#define NR_BR  5 
#define NR_UD  6
#define NR_NM  7
#define NR_DF  8
#define NR_SO  9
#define NR_TS  10
#define NR_NP  11
#define NR_SS  12
#define NR_GP  13 
#define NR_PF  14 
#define NR_PS  15
#define NR_MF  16
#define NR_AC  17
#define NR_MC  18
#define NR_XF  19

#define NR_IRQ_00  0x20
#define NR_IRQ_01  0x21
#define NR_IRQ_02  0x22
#define NR_IRQ_03  0x23
#define NR_IRQ_04  0x24
#define NR_IRQ_05  0x25
#define NR_IRQ_06  0x26
#define NR_IRQ_07  0x27
#define NR_IRQ_08  0x28
#define NR_IRQ_09  0x29
#define NR_IRQ_10  0x2A
#define NR_IRQ_11  0x2B
#define NR_IRQ_12  0x2C
#define NR_IRQ_13  0x2D
#define NR_IRQ_14  0x2E
#define NR_IRQ_15  0x2F

/* excepntion handler entries defined in kernel/kernel.asm */

void divide_error();

void single_step_exception();

void nmi();

void breakpoint_exception();

void overflow();

void bounds_check();

void inval_opcode();

void copr_not_available();

void double_fault();

void copr_seg_overrun();

void inval_tss();

void segment_not_present();

void stack_exception();

void general_protection();

void page_fault();

void copr_presv();

void copr_error();

void align_check();

void machine_check();

void simd_error();
/* exception handler end */


/* irq handler */

void irq00();

void irq01();

void irq02();

void irq03();

void irq04();

void irq05();

void irq06();

void irq07();

void irq08();

void irq09();

void irq10();

void irq11();

void irq12();

void irq13();

void irq14();

void irq15();

/* irq handler end */

void irq_on();      // sti instruction

void irq_off();     // cli instruction

void init8259a();

void init_idt();

int enable_8259a(int);

int disable_8259a(int);

void disp_8259a();

#endif
