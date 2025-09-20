#ifndef FIFO_H
#define FIFO_H

#include "types.h"
/* upgrade to support semaphore in the future (comsumer-producer problem) */


#define DEFINE_FIFO_TYPE(_type_name, _type, _size) typedef struct _type_name { \
    volatile _type buffer[_size]; \
    volatile int tail; \
    volatile int head; \
    volatile int size; \
    volatile int esize; \
    volatile int count; \
} _type_name

#define init_fifo(_fifo_ptr) ({ \
    (_fifo_ptr)->tail = 0; \
    (_fifo_ptr)->head = 0; \
    (_fifo_ptr)->size = sizeof((_fifo_ptr)->buffer) / \
                        sizeof(*((_fifo_ptr)->buffer)); \
    (_fifo_ptr)->esize = sizeof(*((_fifo_ptr)->buffer)); \
    (_fifo_ptr)->count = 0; \
})
 
#define read_fifo(_fifo_ptr, _buf_ptr, n) ({ \
    int _ret = 0;\
    while ((_fifo_ptr)->count != 0 && _ret < (n)) { \
         (_buf_ptr)[_ret] = (_fifo_ptr)->buffer[(_fifo_ptr)->tail]; \
         (_fifo_ptr)->tail = ((_fifo_ptr)->tail+1) % (_fifo_ptr)->size; \
         _ret++; \
         (_fifo_ptr)->count--; \
    } \
    _ret; \
})

#define write_fifo(_fifo_ptr, _buf_ptr, n) ({ \
    int _ret = 0; \
    while ((_fifo_ptr)->count != (_fifo_ptr)->size && _ret < (n)) { \
        (_fifo_ptr)->buffer[(_fifo_ptr)->head] = ((_buf_ptr)[_ret]); \
        (_fifo_ptr)->head = ((_fifo_ptr)->head+1) % (_fifo_ptr)->size; \
        _ret++; \
        (_fifo_ptr)->count++; \
    } \
    _ret; \
}) 

#define peek_fifo(_fifo_ptr, _buf_ptr, n) ({ \
    int _ret = min((n), (_fifo_ptr)->count)); \
    for (int i = 0; i < _ret; i++) \
        (_buf_ptr)[i] = (_fifo_ptr)->buffer[((_fifo_ptr)->tail+i) % (_fifo_ptr)->size]; \
    _ret; \
})

#define fifo_empty(_fifo_ptr) ((_fifo_ptr)->count ? 1 : 0)

#endif
