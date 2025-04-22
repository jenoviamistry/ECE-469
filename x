[1mdiff --git a/kern/trap.c b/kern/trap.c[m
[1mindex ffe86f0..2dfaa17 100644[m
[1m--- a/kern/trap.c[m
[1m+++ b/kern/trap.c[m
[36m@@ -8,6 +8,11 @@[m
 #include <kern/monitor.h>[m
 #include <kern/env.h>[m
 #include <kern/syscall.h>[m
[32m+[m[32m#include <kern/sched.h>[m
[32m+[m[32m#include <kern/kclock.h>[m
[32m+[m[32m#include <kern/picirq.h>[m
[32m+[m[32m#include <kern/cpu.h>[m
[32m+[m[32m#include <kern/spinlock.h>[m
 [m
 static struct Taskstate ts;[m
 [m
[36m@@ -55,60 +60,30 @@[m [mstatic const char *trapname(int trapno)[m
 		return excnames[trapno];[m
 	if (trapno == T_SYSCALL)[m
 		return "System call";[m
[32m+[m	[32mif (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)[m
[32m+[m		[32mreturn "Hardware Interrupt";[m
 	return "(unknown trap)";[m
 }[m
 [m
[31m-void t_divide();[m
[31m-void t_debug();[m
[31m-void t_nmi();[m
[31m-void t_brkpt();[m
[31m-void t_oflow();[m
[31m-void t_bound();[m
[31m-void t_illop();[m
[31m-void t_device();[m
[31m-void t_dblflt();[m
[31m-[m
[31m-void t_tss();[m
[31m-void t_segnp();[m
[31m-void t_stack();[m
[31m-void t_gpflt();[m
[31m-void t_pgflt();[m
[31m-[m
[31m-void t_fperr();[m
[31m-void t_align();[m
[31m-void t_mchk();[m
[31m-void t_simderr();[m
[31m-[m
[31m-void t_syscall();[m
[32m+[m
[32m+[m[32m// XYZ: write a function declaration here...[m
[32m+[m[32m// e.g., void t_divide();[m
 [m
 void[m
 trap_init(void)[m
 {[m
 	extern struct Segdesc gdt[];[m
 [m
[32m+[m[32m    /*[m
[32m+[m[32m     *[m
[32m+[m[32m     * HINT[m
[32m+[m[32m     * Do something like this: SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);[m
[32m+[m[32m     * if your trap handler's name for divide by zero is t_device.[m
[32m+[m[32m     * Additionally, you should declare trap handler as a function[m
[32m+[m[32m     * to refer that in C code... (see the comment XYZ above)[m
[32m+[m[32m     *[m
[32m+[m[32m     */[m
 	// LAB 3: Your code here.[m
[31m-    SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);[m
[31m-    SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);[m
[31m-    SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);[m
[31m-    SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);[m
[31m-    SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);[m
[31m-    SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);[m
[31m-    SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);[m
[31m-    SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);[m
[31m-    SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);[m
[31m-[m
[31m-    SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);[m
[31m-    SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);[m
[31m-    SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);[m
[31m-    SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);[m
[31m-    SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);[m
[31m-[m
[31m-    SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);[m
[31m-    SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);[m
[31m-    SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);[m
[31m-    SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);[m
[31m-[m
[31m-    SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);[m
 [m
 	// Per-CPU setup[m
 	trap_init_percpu();[m
[36m@@ -118,6 +93,31 @@[m [mtrap_init(void)[m
 void[m
 trap_init_percpu(void)[m
 {[m
[32m+[m	[32m// The example code here sets up the Task State Segment (TSS) and[m
[32m+[m	[32m// the TSS descriptor for CPU 0. But it is incorrect if we are[m
[32m+[m	[32m// running on other CPUs because each CPU has its own kernel stack.[m
[32m+[m	[32m// Fix the code so that it works for all CPUs.[m
[32m+[m	[32m//[m
[32m+[m	[32m// Hints:[m
[32m+[m	[32m//   - The macro "thiscpu" always refers to the current CPU's[m
[32m+[m	[32m//     struct CpuInfo;[m
[32m+[m	[32m//   - The ID of the current CPU is given by cpunum() or[m
[32m+[m	[32m//     thiscpu->cpu_id;[m
[32m+[m	[32m//   - Use "thiscpu->cpu_ts" as the TSS for the current CPU,[m
[32m+[m	[32m//     rather than the global "ts" variable;[m
[32m+[m	[32m//   - Use gdt[(GD_TSS0 >> 3) + i] for CPU i's TSS descriptor;[m
[32m+[m	[32m//   - You mapped the per-CPU kernel stacks in mem_init_mp()[m
[32m+[m	[32m//   - Initialize cpu_ts.ts_iomb to prevent unauthorized environments[m
[32m+[m	[32m//     from doing IO (0 is not the correct value!)[m
[32m+[m	[32m//[m
[32m+[m	[32m// ltr sets a 'busy' flag in the TSS selector, so if you[m
[32m+[m	[32m// accidentally load the same TSS on more than one CPU, you'll[m
[32m+[m	[32m// get a triple fault.  If you set up an individual CPU's TSS[m
[32m+[m	[32m// wrong, you may not get a fault until you try to return from[m
[32m+[m	[32m// user space on that CPU.[m
[32m+[m	[32m//[m
[32m+[m	[32m// LAB 4: Your code here:[m
[32m+[m
 	// Setup a TSS so that we get the right stack[m
 	// when we trap to the kernel.[m
 	ts.ts_esp0 = KSTACKTOP;[m
[36m@@ -140,7 +140,7 @@[m [mtrap_init_percpu(void)[m
 void[m
 print_trapframe(struct Trapframe *tf)[m
 {[m
[31m-	cprintf("TRAP frame at %p\n", tf);[m
[32m+[m	[32mcprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());[m
 	print_regs(&tf->tf_regs);[m
 	cprintf("  es   0x----%04x\n", tf->tf_es);[m
 	cprintf("  ds   0x----%04x\n", tf->tf_ds);[m
[36m@@ -189,32 +189,18 @@[m [mtrap_dispatch(struct Trapframe *tf)[m
 	// Handle processor exceptions.[m
 	// LAB 3: Your code here.[m
 [m
[31m-    // dispatch page_fault[m
[31m-    switch (tf->tf_trapno) {[m
[31m-        case T_PGFLT:[m
[31m-        {[m
[31m-            return page_fault_handler(tf);[m
[31m-        }[m
[31m-        case T_BRKPT:[m
[31m-        {[m
[31m-            return monitor(tf);[m
[31m-        }[m
[31m-        case T_SYSCALL:[m
[31m-        {[m
[31m-            int32_t ret = syscall(tf->tf_regs.reg_eax,[m
[31m-                    tf->tf_regs.reg_edx,[m
[31m-                    tf->tf_regs.reg_ecx,[m
[31m-                    tf->tf_regs.reg_ebx,[m
[31m-                    tf->tf_regs.reg_edi,[m
[31m-                    tf->tf_regs.reg_esi[m
[31m-                    );[m
[31m-            tf->tf_regs.reg_eax = ret;[m
[31m-            return;[m
[31m-        }[m
[31m-        default:[m
[31m-        {[m
[31m-        }[m
[31m-    }[m
[32m+[m	[32m// Handle spurious interrupts[m
[32m+[m	[32m// The hardware sometimes raises these because of noise on the[m
[32m+[m	[32m// IRQ line or other reasons. We don't care.[m
[32m+[m	[32mif (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {[m
[32m+[m		[32mcprintf("Spurious interrupt on irq 7\n");[m
[32m+[m		[32mprint_trapframe(tf);[m
[32m+[m		[32mreturn;[m
[32m+[m	[32m}[m
[32m+[m
[32m+[m	[32m// Handle clock interrupts. Don't forget to acknowledge the[m
[32m+[m	[32m// interrupt using lapic_eoi() before calling the scheduler![m
[32m+[m	[32m// LAB 4: Your code here.[m
 [m
 	// Unexpected trap: The user process or the kernel has a bug.[m
 	print_trapframe(tf);[m
[36m@@ -233,17 +219,34 @@[m [mtrap(struct Trapframe *tf)[m
 	// of GCC rely on DF being clear[m
 	asm volatile("cld" ::: "cc");[m
 [m
[32m+[m	[32m// Halt the CPU if some other CPU has called panic()[m
[32m+[m	[32mextern char *panicstr;[m
[32m+[m	[32mif (panicstr)[m
[32m+[m		[32masm volatile("hlt");[m
[32m+[m
[32m+[m	[32m// Re-acqurie the big kernel lock if we were halted in[m
[32m+[m	[32m// sched_yield()[m
[32m+[m	[32mif (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)[m
[32m+[m		[32mlock_kernel();[m
 	// Check that interrupts are disabled.  If this assertion[m
 	// fails, DO NOT be tempted to fix it by inserting a "cli" in[m
 	// the interrupt path.[m
 	assert(!(read_eflags() & FL_IF));[m
 [m
[31m-	cprintf("Incoming TRAP frame at %p\n", tf);[m
[31m-[m
 	if ((tf->tf_cs & 3) == 3) {[m
 		// Trapped from user mode.[m
[32m+[m		[32m// Acquire the big kernel lock before doing any[m
[32m+[m		[32m// serious kernel work.[m
[32m+[m		[32m// LAB 4: Your code here.[m
 		assert(curenv);[m
 [m
[32m+[m		[32m// Garbage collect if current enviroment is a zombie[m
[32m+[m		[32mif (curenv->env_status == ENV_DYING) {[m
[32m+[m			[32menv_free(curenv);[m
[32m+[m			[32mcurenv = NULL;[m
[32m+[m			[32msched_yield();[m
[32m+[m		[32m}[m
[32m+[m
 		// Copy trap frame (which is currently on the stack)[m
 		// into 'curenv->env_tf', so that running the environment[m
 		// will restart at the trap point.[m
[36m@@ -259,9 +262,13 @@[m [mtrap(struct Trapframe *tf)[m
 	// Dispatch based on what type of trap occurred[m
 	trap_dispatch(tf);[m
 [m
[31m-	// Return to the current environment, which should be running.[m
[31m-	assert(curenv && curenv->env_status == ENV_RUNNING);[m
[31m-	env_run(curenv);[m
[32m+[m	[32m// If we made it to this point, then no other environment was[m
[32m+[m	[32m// scheduled, so we should return to the current environment[m
[32m+[m	[32m// if doing so makes sense.[m
[32m+[m	[32mif (curenv && curenv->env_status == ENV_RUNNING)[m
[32m+[m		[32menv_run(curenv);[m
[32m+[m	[32melse[m
[32m+[m		[32msched_yield();[m
 }[m
 [m
 [m
[36m@@ -276,16 +283,41 @@[m [mpage_fault_handler(struct Trapframe *tf)[m
 	// Handle kernel-mode page faults.[m
 [m
 	// LAB 3: Your code here.[m
[31m-    if ((tf->tf_cs&0x3) == 0) {[m
[31m-        // in kernel[m
[31m-        print_trapframe(tf);[m
[31m-        panic("page_fault_handler: kernel page fault at %p\n", rcr2());[m
[31m-    }[m
[31m-[m
 [m
 	// We've already handled kernel-mode exceptions, so if we get here,[m
 	// the page fault happened in user mode.[m
 [m
[32m+[m	[32m// Call the environment's page fault upcall, if one exists.  Set up a[m
[32m+[m	[32m// page fault stack frame on the user exception stack (below[m
[32m+[m	[32m// UXSTACKTOP), then branch to curenv->env_pgfault_upcall.[m
[32m+[m	[32m//[m
[32m+[m	[32m// The page fault upcall might cause another page fault, in which case[m
[32m+[m	[32m// we branch to the page fault upcall recursively, pushing another[m
[32m+[m	[32m// page fault stack frame on top of the user exception stack.[m
[32m+[m	[32m//[m
[32m+[m	[32m// It is convenient for our code which returns from a page fault[m
[32m+[m	[32m// (lib/pfentry.S) to have one word of scratch space at the top of the[m
[32m+[m	[32m// trap-time stack; it allows us to more easily restore the eip/esp. In[m
[32m+[m	[32m// the non-recursive case, we don't have to worry about this because[m
[32m+[m	[32m// the top of the regular user stack is free.  In the recursive case,[m
[32m+[m	[32m// this means we have to leave an extra word between the current top of[m
[32m+[m	[32m// the exception stack and the new stack frame because the exception[m
[32m+[m	[32m// stack _is_ the trap-time stack.[m
[32m+[m	[32m//[m
[32m+[m	[32m// If there's no page fault upcall, the environment didn't allocate a[m
[32m+[m	[32m// page for its exception stack or can't write to it, or the exception[m
[32m+[m	[32m// stack overflows, then destroy the environment that caused the fault.[m
[32m+[m	[32m// Note that the grade script assumes you will first check for the page[m
[32m+[m	[32m// fault upcall and print the "user fault va" message below if there is[m
[32m+[m	[32m// none.  The remaining three checks can be combined into a single test.[m
[32m+[m	[32m//[m
[32m+[m	[32m// Hints:[m
[32m+[m	[32m//   user_mem_assert() and env_run() are useful here.[m
[32m+[m	[32m//   To change what the user environment runs, modify 'curenv->env_tf'[m
[32m+[m	[32m//   (the 'tf' variable points at 'curenv->env_tf').[m
[32m+[m
[32m+[m	[32m// LAB 4: Your code here.[m
[32m+[m
 	// Destroy the environment that caused the fault.[m
 	cprintf("[%08x] user fault va %08x ip %08x\n",[m
 		curenv->env_id, fault_va, tf->tf_eip);[m
