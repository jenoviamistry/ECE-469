/* See COPYRIGHT for copyright information. */

#include <inc/x86.h>
#include <inc/error.h>
#include <inc/string.h>
#include <inc/assert.h>

#include <kern/env.h>
#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/syscall.h>
#include <kern/console.h>
#include <kern/sched.h>


// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void
sys_cputs(const char *s, size_t len)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
    user_mem_assert(curenv, s, len, PTE_U|PTE_P);

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
}

// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
}

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
}

// Destroy a given environment (possibly the currently running environment).
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_destroy(envid_t envid)
{
	int ret;
	struct Env *env;

	if ((ret = envid2env(envid, &env, 1)) < 0)
		return ret;
	if (env == curenv)
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, env->env_id);
	env_destroy(env);
	return 0;
}


// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
}

// Allocate a new environment.
// Returns envid of new environment, or < 0 on error.  Errors are:
//	-E_NO_FREE_ENV if no free environment is available.
//	-E_NO_MEM on memory exhaustion.
envid_t
sys_exofork(void)
{
	// Create the new environment with env_alloc(), from kern/env.c.
	// It should be left as env_alloc created it, except that
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env *childEnv;
	
	if (!curenv) panic("sys_exofork: curenv is NULL");
	
	int r = env_alloc(&childEnv, curenv->env_id);
	if (r < 0) {
		cprintf("sys_exofork: env_alloc failed with error %d\n", r);
		return r;
	}
	if (r < 0) return r;

	// cprintf("sys_exofork: Copying trap frame from parent %08x to child %08x\n",
    //     curenv->env_id, childEnv->env_id);
	
		//childEnv->env_tf = *tf;
	childEnv->env_tf = curenv->env_tf;
	childEnv->env_tf.tf_regs.reg_eax = 0;
	childEnv->env_status = ENV_NOT_RUNNABLE;
	childEnv->env_tf.tf_ds = GD_UD | 3; // i added this for sanity checking
	childEnv->env_tf.tf_es = GD_UD | 3;
	childEnv->env_tf.tf_ss = GD_UD | 3;
	childEnv->env_tf.tf_cs = GD_UT | 3;


	// cprintf("sys_exofork: Copying trap frame from parent %08x to child %08x\n",
	// 	curenv->env_id, childEnv->env_id);
	// cprintf("sys_exofork: New child env %08x created\n", childEnv->env_id);
	// cprintf("sys_exofork: Child trap frame - eip: %08x, esp: %08x, cs: %04x, ds: %04x, ss: %04x\n",
	// 	childEnv->env_tf.tf_eip, childEnv->env_tf.tf_esp,
	// 	childEnv->env_tf.tf_cs, childEnv->env_tf.tf_ds, childEnv->env_tf.tf_ss);
	

	// cprintf("sys_exofork: parent returning envid %08x to caller\n", childEnv->env_id);
	// cprintf("sys_exofork: parent trapframe still intact? eip = %08x esp = %08x\n",
    //     curenv->env_tf.tf_eip, curenv->env_tf.tf_esp);

	// 	cprintf("PARENT tf_eip: %08x\n", curenv->env_tf.tf_eip);
	// 	cprintf("CHILD tf_eip:  %08x\n", childEnv->env_tf.tf_eip);
		
	// 	cprintf("CHILD eax:     %08x\n", childEnv->env_tf.tf_regs.reg_eax);
		
	// cprintf("child tf_eip: %08x tf_cs: %x\n", 
	// 		childEnv->env_tf.tf_eip, childEnv->env_tf.tf_cs);
		
		
	return childEnv->env_id;
	


	//panic("sys_exofork not implemented");
}

// Set envid's env_status to status, which must be ENV_RUNNABLE
// or ENV_NOT_RUNNABLE.
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if status is not a valid status for an environment.
static int
sys_env_set_status(envid_t envid, int status)
{
	// Hint: Use the 'envid2env' function from kern/env.c to translate an
	// envid to a struct Env.
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.
	struct Env *env;
	int ret = envid2env(envid, &env, true);
	if (ret < 0) return ret;

	// if (ret < 0 || env->env_parent_id != curenv->env_id) 
	// {
	// 	return -E_BAD_ENV;
	// }
	// if (ret < 0 || env->env_parent_id != curenv->env_id) {
	// 	return -E_BAD_ENV;
	// }
	if (env == NULL) return -E_BAD_ENV; // if env is NULL, it means the envid doesn't exist
	if (status != ENV_NOT_RUNNABLE && status != ENV_RUNNABLE) return -E_INVAL;
	env->env_status = status;
	return 0;
	
	//panic("sys_env_set_status not implemented");
}

// Set the page fault upcall for 'envid' by modifying the corresponding struct
// Env's 'env_pgfault_upcall' field.  When 'envid' causes a page fault, the
// kernel will push a fault record onto the exception stack, then branch to
// 'func'.
//
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	// cprintf("DEBUG: sys_env_set_pgfault_upcall called: envid=0x%08x, func=0x%08x\n",
	// 	envid, (uintptr_t) func);

	struct Env *envStore;
	//if (!envid) envStore = curenv;
	//int checkperm = (curenv->env_id == envid) ? 0 : 1;
	//if (!checkperm) -E_BAD_ENV;
	if (envid == 0) envStore = curenv;
	else 
	{
		int ret = envid2env(envid, &envStore, 1);
		//cprintf("DEBUG: envid2env failed: %e\n", ret);
		if (ret < 0) return -E_BAD_ENV;	
	
	}
	// cprintf("DEBUG: -> assigned to env %08x (env->env_id=0x%08x)\n",
	// 	(uintptr_t)envStore, envStore->env_id);

	envStore->env_pgfault_upcall = func;
	return 0;
	//panic("sys_env_set_pgfault_upcall not implemented");
}

// Allocate a page of memory and map it at 'va' with permission
// 'perm' in the address space of 'envid'.
// The page's contents are set to 0.
// If a page is already mapped at 'va', that page is unmapped as a
// side effect.
//
// perm -- PTE_U | PTE_P must be set, PTE_AVAIL | PTE_W may or may not be set,
//         but no other bits may be set.  See PTE_SYSCALL in inc/mmu.h.
//
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
//	-E_INVAL if perm is inappropriate (see above).
//	-E_NO_MEM if there's no memory to allocate the new page,
//		or to allocate any necessary page tables.
static int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	// Hint: This function is a wrapper around page_alloc() and
	//   page_insert() from kern/pmap.c.
	//   Most of the new code you write should be to check the
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.
	struct Env *env;
	int ret = envid2env(envid, &env, true);
	if (ret<0) return ret;

	if ((uintptr_t)va >= UTOP) return -E_INVAL;
	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P)) return -E_INVAL;

	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if (!page) return -E_NO_MEM;
	
	if ( (ret = page_insert(env->env_pgdir, page, va, perm)) < 0) 
	{
		//cprintf("sys_page_alloc: page_insert failed with error %d, freeing page\n", ret);
		page_free(page);
		return ret;
	}
	return 0;
	
	//panic("sys_page_alloc not implemented");
}

// Map the page of memory at 'srcva' in srcenvid's address space
// at 'dstva' in dstenvid's address space with permission 'perm'.
// Perm has the same restrictions as in sys_page_alloc, except
// that it also must not grant write access to a read-only
// page.
//
// Return 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if srcenvid and/or dstenvid doesn't currently exist,
//		or the caller doesn't have permission to change one of them.
//	-E_INVAL if srcva >= UTOP or srcva is not page-aligned,
//		or dstva >= UTOP or dstva is not page-aligned.
//	-E_INVAL is srcva is not mapped in srcenvid's address space.
//	-E_INVAL if perm is inappropriate (see sys_page_alloc).
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
//		address space.
//	-E_NO_MEM if there's no memory to allocate any necessary page tables.
static int
sys_page_map(envid_t srcenvid, void *srcva,
	     envid_t dstenvid, void *dstva, int perm)
{

	// Hint: This function is a wrapper around page_lookup() and
	//   page_insert() from kern/pmap.c.
	//   Again, most of the new code you write should be to check the
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.

	struct Env *srcenv;
	struct Env *dstenv;
	pte_t *srcpte;
	pte_t *dstpte;
	pte_t *pte;

	int ret = envid2env(srcenvid, &srcenv, true);
	if (ret < 0) return ret;
		
	ret = envid2env(dstenvid, &dstenv, true);
	if (ret < 0) return ret;

	if ((uintptr_t)dstva >= UTOP || ROUNDUP(dstva, PGSIZE) != dstva) return -E_INVAL;
	if ((uintptr_t)srcva >= UTOP || (srcva != ROUNDDOWN(srcva,PGSIZE))) return -E_INVAL;
		
	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P)) return -E_INVAL;
	if (perm & ~PTE_SYSCALL) return -E_INVAL;
		
	//struct PageInfo *page = page_lookup(srcenv->env_pgdir, srcva, &pte);
	struct PageInfo *page1 = page_lookup(srcenv->env_pgdir, srcva, &srcpte); // soruce page
	
	// unnecccesary check added when trying to fix dumbfork
	// struct PageInfo *page2 = page_lookup(dstenv->env_pgdir, dstva, &dstpte);
	// if (page2 == NULL) 
	// {
	// 	dstpte = pgdir_walk(dstenv->env_pgdir, dstva , 1);
	// 	if (dstpte == NULL) return -E_NO_MEM; // if dstpte is NULL it means we cannot allocate a page table for dstva
	// }

	//cprintf("sys_page_map: srcva=%08x -> dstva=%08x | parent=%08x -> child=%08x\n",
	//srcva, dstva, srcenv->env_id, dstenv->env_id);
	//cprintf("sys_page_map: perm=%08x, pte on src=%08x\n", perm, *pte);

		
	//cprintf("sys_page_map: Found page at srcva=%08x in env %08x with *pte = %08x\n",
	//	(unsigned)srcva, srcenv->env_id, *pte);
	if ((perm & PTE_W) && !(*srcpte & PTE_W)) 
	{
		//cprintf("sys_page_map: Invalid attempt to map read-only page as writable\n");
		return -E_INVAL;
	}
		
	//cprintf("sys_page_map: Mapping page from env %08x (va %08x) to env %08x (va %08x) with perm %08x\n", srcenv->env_id, (unsigned)srcva, dstenv->env_id, (unsigned)dstva, perm);

	ret = page_insert(dstenv->env_pgdir, page1, dstva, perm);
	//ret = page_insert(dstenv->env_pgdir, page, dstva, perm);
	if (ret < 0) return ret;


	return 0;

	//panic("sys_page_map not implemented");
}



// Unmap the page of memory at 'va' in the address space of 'envid'.
// If no page is mapped, the function silently succeeds.
//
// Return 0 on success, indicating the page was successfully unmapped or no page was mapped.
// Return < 0 on error. Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
//	-E_INVAL if va >= UTOP, or va is not page-aligned.
static int
sys_page_unmap(envid_t envid, void *va)
{
    // Hint: This function is a wrapper around page_remove().


    // LAB 4: Your code here.
    struct Env *env;
    int ret = envid2env(envid, &env, true);
    if (ret < 0 ) return ret;
    if ( ROUNDDOWN(va,PGSIZE) != va || (uintptr_t)va >= UTOP) return -E_INVAL;
    page_remove(env->env_pgdir, va);
    return 0;


    //panic("sys_page_unmap not implemented");
}


// Try to send 'value' to the target env 'envid'.
// If srcva < UTOP, then also send page currently mapped at 'srcva',
// so that receiver gets a duplicate mapping of the same page.
//
// The send fails with a return value of -E_IPC_NOT_RECV if the
// target is not blocked, waiting for an IPC.
//
// The send also can fail for the other reasons listed below.
//
// Otherwise, the send succeeds, and the target's ipc fields are
// updated as follows:
//    env_ipc_recving is set to 0 to block future sends;
//    env_ipc_from is set to the sending envid;
//    env_ipc_value is set to the 'value' parameter;
//    env_ipc_perm is set to 'perm' if a page was transferred, 0 otherwise.
// The target environment is marked runnable again, returning 0
// from the paused sys_ipc_recv system call.  (Hint: does the
// sys_ipc_recv function ever actually return?)
//
// If the sender wants to send a page but the receiver isn't asking for one,
// then no page mapping is transferred, but no error occurs.
// The ipc only happens when no errors occur.
//
// Returns 0 on success, < 0 on error.
// Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist.
//		(No need to check permissions.)
//	-E_IPC_NOT_RECV if envid is not currently blocked in sys_ipc_recv,
//		or another environment managed to send first.
//	-E_INVAL if srcva < UTOP but srcva is not page-aligned.
//	-E_INVAL if srcva < UTOP and perm is inappropriate
//		(see sys_page_alloc).
//	-E_INVAL if srcva < UTOP but srcva is not mapped in the caller's
//		address space.
//	-E_INVAL if (perm & PTE_W), but srcva is read-only in the
//		current environment's address space.
//	-E_NO_MEM if there's not enough memory to map srcva in envid's
//		address space.
static int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
	// LAB 4: Your code here.
	struct Env *env = NULL;
	int ret = 0; // return value

	ret = envid2env(envid, &env, 0);
	if (ret<0) -E_BAD_ENV;

	if (!env->env_ipc_recving) return -E_IPC_NOT_RECV;
	env->env_ipc_perm = 0;

	if ((uintptr_t)srcva < UTOP)
	{
		if ((uintptr_t)srcva % PGSIZE != 0) return -E_INVAL; // if not page aligned	
		if (((perm & (PTE_P|PTE_U)) != (PTE_U|PTE_P)) || (perm & ~PTE_SYSCALL)) return -E_INVAL;

		pte_t *pagetableentry;
		struct PageInfo *page = page_lookup(curenv->env_pgdir, srcva,&pagetableentry);
		if (!page) return -E_INVAL;

		if ((perm & PTE_W) && !(*pagetableentry & PTE_W)) return -E_INVAL;
		
		if ((uintptr_t)env->env_ipc_dstva < UTOP)
		{
			ret = page_insert(env->env_pgdir, page, env->env_ipc_dstva, perm);
			if (ret < 0) return -E_NO_MEM;
			env->env_ipc_perm = perm;
		}
	}

	env->env_tf.tf_regs.reg_eax = 0;
	env->env_ipc_value = value;
	env->env_ipc_from = curenv->env_id;
	env->env_ipc_recving = 0;
	env->env_status = ENV_RUNNABLE;

	return 0;
	//panic("sys_ipc_try_send not implemented");
}

// Block until a value is ready.  Record that you want to receive
// using the env_ipc_recving and env_ipc_dstva fields of struct Env,
// mark yourself not runnable, and then give up the CPU.
//
// If 'dstva' is < UTOP, then you are willing to receive a page of data.
// 'dstva' is the virtual address at which the sent page should be mapped.
//
// This function only returns on error, but the system call will eventually
// return 0 on success.
// Return < 0 on error.  Errors are:
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
	if ((uintptr_t)dstva < UTOP && (ROUNDDOWN(dstva, PGSIZE) != dstva)) return -E_INVAL;

	curenv->env_ipc_recving = true;
	curenv->env_ipc_dstva = dstva;
	curenv->env_status = ENV_NOT_RUNNABLE;

	sched_yield();

	//panic("sys_ipc_recv not implemented");
	return 0;
}


// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	///panic("syscall not implemented");
	switch (syscallno) 
	{
		case SYS_cputs:
			sys_cputs((const char *) a1, (size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_getenvid:
			return sys_getenvid();
		case SYS_env_destroy:
			return sys_env_destroy((envid_t) a1);
		case SYS_yield:
			//cprintf("sys_yield called from env %08x\n", curenv->env_id);
			sys_yield();
			return 0;
		case SYS_exofork:
			return sys_exofork();
		case SYS_env_set_status: 
			return sys_env_set_status((envid_t) a1, (int)a2);
		case SYS_page_alloc:
			return sys_page_alloc((envid_t)a1, (void*)a2, (int)a3);
		case SYS_page_map:
			return sys_page_map((envid_t)a1, (void*)a2, (envid_t)a3, (void*)a4, (int)a5);
		case SYS_page_unmap:
			return sys_page_unmap((envid_t)a1, (void*)a2);
		case SYS_env_set_pgfault_upcall:
        	return sys_env_set_pgfault_upcall((envid_t) a1, (void *) a2);
		case SYS_ipc_recv:
			return sys_ipc_recv((void *)a1);
		case SYS_ipc_try_send:
			return sys_ipc_try_send((envid_t)a1, (uint32_t)a2, (void *)a3, (unsigned)a4);
		
		default:
			return -E_INVAL;
	}
}



