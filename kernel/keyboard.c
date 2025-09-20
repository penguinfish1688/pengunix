#include "keyboard.h"
#include "keymap.h"
#include "types.h"
#include "libc.h"
#include "io.h"
#include "irq.h"
#include "proc.h"
#include "fifo.h"
#include "global.h"

#define KB_BUF_SIZE 32

DEFINE_FIFO_TYPE(kb_buf_t, int, KB_BUF_SIZE);
kb_buf_t kb_buf;

/* status is either NORMAL_COL SHIFT_COL E0_COL */
char scancode2key(int scan_code, int status) {
    if (scan_code < 0 || scan_code >= NR_SCAN_CODES || status < 0 || status > 2) {
        return 0;
    }
    return keymap[scan_code * MAP_COLS + status];
}

/* Save scan code into a buffer */
void keyboard_irq_handler() {
    int scan_code = in((uint16)0x60);
    write_fifo(&kb_buf, &scan_code, 1);
    return ;
}

/* Print the scan code in the buffer */
void keyboard_output() {
    int scan_code;
    int shift_on = 0;
    int e0_on = 0;
    char key[2] = {};
    while (1) {
        //disp_str("yee");
        //disp_num(scan_code);
        //while (1) {}
        /* Break key */
        if (read_fifo(&kb_buf, &scan_code, 1) == 1) {
            if (scan_code > MAX_SCAN_CODE) {
                if ((scan_code == (SHIFT_L_CODE | BRK_MASK) \
                        || scan_code == (SHIFT_R_CODE | BRK_MASK)) ) {
                    shift_on = 0;
                }
                else if (scan_code == 0xE0) {
                    e0_on = 1;
                }
            }
            else {
                
                if (e0_on) {
                    key[0] = scancode2key(scan_code, E0_COL);
                    disp_str(key);
                    e0_on = 0;
                }
                else if (scan_code == SHIFT_L_CODE || scan_code == SHIFT_R_CODE) {
                    shift_on = 1;
                }
                else if (shift_on) {
                    key[0] = scancode2key(scan_code, SHIFT_COL);
                    disp_str(key); 
                }
                else {
                    if (scan_code == BS_CODE) {
                        del_char();
                    }
                    else if (scan_code == TAB_CODE) {
                        disp_str("    ");
                    }
                    else {
                        key[0] = scancode2key(scan_code, NORMAL_COL);
                        disp_str(key);
                    }
                }
            } 
        }
    }
}

char keyword_output_stack[1000]; 

void init_keyboard() {
    /* register handler for IRQ */
    irq_handlers[NR_8259_KEYBOARD] = keyboard_irq_handler;
    
    /* 8259A accepts key interrupt  */
    enable_8259a(NR_8259_KEYBOARD);
    
    init_fifo(&kb_buf);

    /* Add display process */
    add_process(keyboard_output, keyword_output_stack, 1000, 40, "K");

    return ;
}


