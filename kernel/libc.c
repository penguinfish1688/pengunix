#include "global.h"
#include "types.h"
#include "libc.h"
#include "vararg.h"

uchar *memcpy(uchar *dst, uchar *src, int n) {
    for (int i = 0; i < n; i++) {
        *(dst + i) = *(src + i);
    }
    return dst;
}

int strcpy(char *dst, char *src) {
    int n = 0;
    while (*src != '\0') {
        *dst = *src;
        dst++;
        src++;
        n++;
    }
    /* return the number of bytes copied */
    return n;
}

uchar *disp_mem(uchar *ptr, int n) {
    uint8 hex_digi;
    for (int i = 0; i < n; i++) {
        // print upper-half of a byte
        hex_digi = *(ptr+i) & 0xF0;
        hex_digi = hex_digi >> 4;
        if (hex_digi > 9)
            hex_digi += 'A' - 10;
        else
            hex_digi += '0';
        disp_char(hex_digi);

        // print lower-half of a byte
        hex_digi = *(ptr+i) & 0x0F;
        if (hex_digi > 9)
            hex_digi += 'A' - 10;
        else 
            hex_digi += '0';
        disp_char(hex_digi);
        
        // space
        disp_char(' ');
    }
    return ptr; 
}

char *disp_str(char *str) {
    char *ptr = str;
    while (*ptr != 0) {
        if (*ptr == '\n')
            output_addr = ((output_addr/160)+1)*160;
        else
            disp_char(*ptr);
        ptr++;
    }
    return str;
}

int disp_num(int n) {
    char num_str[11];
    num_str[0] = '0';
    num_str[1] = 'x';
    num_str[10] = '\0';
    char digi;
    for (int i = 0; i < 8; i++) {
        digi = n & 0x0F;
        if (digi > 9)
            digi += 'A'-10;
        else
            digi += '0';
        num_str[9-i] = digi;
        n >>= 4;
    }
    disp_str(num_str);
    return n;
}

int disp_dec(int n) {
    int m = n;
    int idx = 19;
    char num_str[20];
    num_str[idx] = 0;
    idx--;
    while (m != 0) {
        num_str[idx] = abs(m % 10) + '0';
        m /= 10;
        idx--;
    }
    if (n < 0)
        num_str[idx] = '-';
    else
        idx++;
    disp_str(num_str+idx);
    return n;
}

void disp_regs(int eax, int ebx, int ecx, int edx, int esi, int edi, int ebp, int esp, int ss, int cs) {
    printk(
        "eax: %x ebx: %x ecx: %x edx: %x\nesi: %x edi: %x ebp: %x esp: %x\nss: %x cs: %x",
        eax, ebx, ecx, edx, esi, edi, ebp, esp, ss, cs
    );
    return ;
}

void printk(char *fmt, ...) {
    va_list vargs;
    va_start(vargs, fmt);
    char *crt = fmt;
    while (*crt) {
        if (*crt == '%') {
            crt++;
            if (*crt == 'd') {
                disp_dec(va_arg(vargs, int));
            }
            else if (*crt == 's') {
                disp_str(va_arg(vargs, char *));
            }
            else if (*crt == 'x') {
                disp_num(va_arg(vargs, int));
            }
            else if (*crt == '%') {
                disp_char('%');
            }
        }
        else if (*crt == '\n')
            output_addr = ((output_addr/160)+1)*160;
        else
            disp_char(*crt);
        crt++;
    }
    va_end(vargs);
}

void clear_screen() {
    for (int i = 0; i < 80*24; i++) {
        disp_char(' ');
    }
}






