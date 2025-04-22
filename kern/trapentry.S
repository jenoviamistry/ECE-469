/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
 // i changed the traphandler definition to creat a trap array so that i can easily skip the reserved ones for sanity as i could not pass dumbfork until i did this
#define TRAPHANDLER(name, num)						\
        .data;              /*for setting trap array, reseves space for it*/      \
        .long name;              /*get the setgate name symbol to set the trap array name*/                                       \
        .text;                                                             \
        .globl name;            /* define global symbol for 'name' */   \
        .type name, @function;  /* symbol type is function */           \
        .align 2;               /* align function definition */         \
        name:                   /* function starts here */              \
        pushl $(num);                                                   \
        jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
        .data;              /*for setting trap array, reseves space for it*/      \
        .long name;                                                     \
        .text;                         \
        .globl name;                                                    \
        .type name, @function;                                          \
        .align 2;                                                       \
        name:                                                           \
        pushl $0;                    /*dummy err code sent before trap number*/                                   \
        pushl $(num);                 /*trap number*/                                  \
        jmp _alltraps

//.text // not text section anymore since i added the trap array

/*
 * Lab 3: Your code here for generating entry points for the different traps.
*/
 
// HINT 1 : TRAPHANDLER_NOEC(t_divide, T_DIVIDE);
//          Do something like this if there is no error code for the trap
// HINT 2 : TRAPHANDLER(t_dblflt, T_DBLFLT);
//          Do something like this if the trap includes an error code..
// HINT 3 : READ Intel's manual to check if the trap includes an error code
//          or not...
.data // to build the trap array in assembly
.globl trapArr // create array of trap handler addresses to have in trap.c correctly as well
trapArr: // the start of the array
        TRAPHANDLER_NOEC(t_divide, T_DIVIDE);    
        TRAPHANDLER_NOEC(t_debug, T_DEBUG);      
        TRAPHANDLER_NOEC(t_nmi, T_NMI);          
        TRAPHANDLER_NOEC(t_brkpt, T_BRKPT);      
        TRAPHANDLER_NOEC(t_oflow, T_OFLOW);      
        TRAPHANDLER_NOEC(t_bound, T_BOUND);      
        TRAPHANDLER_NOEC(t_illop, T_ILLOP);     
        TRAPHANDLER_NOEC(t_device, T_DEVICE);
        TRAPHANDLER(t_dblflt, T_DBLFLT); 

        .data // this helps skip trap 9 since its reserved
        .long 0 // skips the resever trap num with a zero

        TRAPHANDLER(t_tss, T_TSS);          
        TRAPHANDLER(t_segnp, T_SEGNP);      
        TRAPHANDLER(t_stack, T_STACK);      
        TRAPHANDLER(t_gpflt, T_GPFLT);      
        TRAPHANDLER(t_pgflt, T_PGFLT);      

        .data // skips 15 in arr with zero as its reserved
        .long 0

        TRAPHANDLER_NOEC(t_fperr, T_FPERR);   
        TRAPHANDLER(t_align, T_ALIGN);     
        TRAPHANDLER_NOEC(t_mchk, T_MCHK);        
        TRAPHANDLER_NOEC(t_simderr, T_SIMDERR);  


        .data
        // reserve space 
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0
        .long 0

        TRAPHANDLER_NOEC(trap_irq0, IRQ_OFFSET + 0)
        TRAPHANDLER_NOEC(trap_irq1, IRQ_OFFSET + 1)
        TRAPHANDLER_NOEC(trap_irq2, IRQ_OFFSET + 2)
        TRAPHANDLER_NOEC(trap_irq3, IRQ_OFFSET + 3)
        TRAPHANDLER_NOEC(trap_irq4, IRQ_OFFSET + 4)
        TRAPHANDLER_NOEC(trap_irq5, IRQ_OFFSET + 5)
        TRAPHANDLER_NOEC(trap_irq6, IRQ_OFFSET + 6)
        TRAPHANDLER_NOEC(trap_irq7, IRQ_OFFSET + 7)
        TRAPHANDLER_NOEC(trap_irq8, IRQ_OFFSET + 8)
        TRAPHANDLER_NOEC(trap_irq9, IRQ_OFFSET + 9)
        TRAPHANDLER_NOEC(trap_irq10, IRQ_OFFSET + 10)
        TRAPHANDLER_NOEC(trap_irq11, IRQ_OFFSET + 11)
        TRAPHANDLER_NOEC(trap_irq12, IRQ_OFFSET + 12)
        TRAPHANDLER_NOEC(trap_irq13, IRQ_OFFSET + 13)
        TRAPHANDLER_NOEC(trap_irq14, IRQ_OFFSET + 14)
        TRAPHANDLER_NOEC(trap_irq15, IRQ_OFFSET + 15)

        TRAPHANDLER_NOEC(t_syscall, T_SYSCALL);

        .data
        TRAPHANDLER_NOEC(t_default, T_DEFAULT);

/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
    pushl %ds
    pushl %es
    pushal
    mov $GD_KD, %eax
    mov %eax, %ds
    mov %eax, %es
    pushl %esp
    call trap // call trap handler func
    addl $4, %esp   
    popal        // restore the registers  
    popl %es        
    popl %ds       
    addl $8, %esp   
    iret // correct eip returned properly 



