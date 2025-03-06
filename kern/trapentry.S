/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



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
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
	TRAPHANDLER_NOEC(divide_handler, T_DIVIDE)       # Divide error (vector 0)
    TRAPHANDLER_NOEC(debug_handler, T_DEBUG)         # Debug exception (vector 1)
    TRAPHANDLER_NOEC(nmi_handler, T_NMI)             # NMI (vector 2)
    TRAPHANDLER_NOEC(brkpt_handler, T_BRKPT)         # Breakpoint (vector 3, DPL 3 in IDT setup)
    TRAPHANDLER_NOEC(oflow_handler, T_OFLOW)         # Overflow (vector 4)
    TRAPHANDLER_NOEC(bound_handler, T_BOUND)         # Bound range exceeded (vector 5)
    TRAPHANDLER_NOEC(illop_handler, T_ILLOP)         # Illegal opcode (vector 6)
    TRAPHANDLER_NOEC(device_handler, T_DEVICE) # Device not available (vector 7)
    TRAPHANDLER(dblflt_handler, T_DBLFLT)            # Double fault (vector 8)
    TRAPHANDLER(tss_handler, T_TSS)                  # Invalid TSS (vector 10)
    TRAPHANDLER(segnp_handler, T_SEGNP)              # Segment not present (vector 11)
    TRAPHANDLER(stack_handler, T_STACK)              # Stack fault (vector 12)
    TRAPHANDLER(gpflt_handler, T_GPFLT)              # General protection fault (vector 13)
    TRAPHANDLER(pgflt_handler, T_PGFLT)              # Page fault (vector 14)
    TRAPHANDLER_NOEC(fperr_handler, T_FPERR)         # Floating-point error (vector 16)
    TRAPHANDLER_NOEC(align_handler, T_ALIGN)         # Alignment check (vector 17)
    TRAPHANDLER_NOEC(mchk_handler, T_MCHK)           # Machine check (vector 18)
    TRAPHANDLER_NOEC(simderr_handler, T_SIMDERR)     # SIMD floating-point exception (vector 19)
    TRAPHANDLER(syscall_handler, T_SYSCALL)          # System call (vector 48, DPL 3)
	TRAPHANDLER_NOEC(t_default, T_DEFAULT)     # Default trap handler


// HINT 1 : TRAPHANDLER_NOEC(t_divide, T_DIVIDE);
//          Do something like this if there is no error code for the trap
// HINT 2 : TRAPHANDLER(t_dblflt, T_DBLFLT);
//          Do something like this if the trap includes an error code..
// HINT 3 : READ Intel's manual to check if the trap includes an error code
//          or not...

/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
    pushl %ds
    pushl %es
	pushal
    mov $GD_KD, %eax
	mov %ax, %ds
	mov %ax, %es
	pushl %esp
	call trap
	# addl $4, %esp   
	# popal          
	# popl %es        
	# popl %ds       
	# addl $8, %esp   
	# iret



