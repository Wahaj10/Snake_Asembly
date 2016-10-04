.globl 	InstallIntTable
.globl 	enableInterrupts
.globl 	enableTimerIRQ
.globl 	disableTimerInterrupt
.globl 	waiter
.globl 	checkVP

.section .text

enableInterrupts:
	push	{lr}

	// Enable IRQ
	mrs		r0, cpsr
	bic		r0, #0x80
	msr		cpsr_c, r0

	pop		{pc}

enableTimerIRQ:
	push 	{lr}

	ldr 	r0, =0x2000B210 				// Enable IRQ register 1
	mov 	r1, #2  						// bit #1
	str 	r1, [r0] 					

	pop 	{pc}

disableTimerInterrupt:
	push 	{lr}

	ldr 	r0, =0x2000b21C 				// Disable IRQ register 1
	mov 	r1, #2  						// bit #1
	str 	r1, [r0] 
	
	ldr 	r0, =0x20003004 				// Timer thingy
	ldr 	r0, [r0]  

	sub 	r0, #1
	
	ldr 	r1, =0x20003010 		
	str 	r0, [r1]

	pop 	{pc}

// Spawn value packs here
irq:
	push	{r0-r3, lr}

	ldr 	r0, =0x20003000 		
	mov	 	r1, #2 	
	str 	r1, [r0] 						// Cleared pending interrupt

spawnValuePack:
	bl 		randomNumber 					// Call random number

	// Add coordinates to memory so we know where VP is
	ldr 	r2, =whereIsVP 					// Storing value pack coords in mem

	str 	r0, [r2], #4 					// Placing X in mem and incrementing address
	str 	r1, [r2] 						// Now VP coords are in "whereIsVP"

	ldr 	r2, =heart 	 					// address of VP image
	bl 		DrawSquare  					// Draw the VP at random coordinate	*/

irqEnd:
	pop		{r0-r3, lr}
	subs	pc, lr, #4



/**
  * takes r0 as arg for time in microsecs
  */
waiter:
	push 	{lr}

	ldr 	r1, =0x20003004 				// Timer 
	ldr 	r1, [r1]  						// Get current time

	add 	r0, r1 							// Time offset

	ldr 	r1, =0x20003010 				// At this time fire an interrupt
	str 	r0, [r1]

	pop 	{pc}


InstallIntTable:
	ldr		r0, =IntTable
	mov		r1, #0x00000000

	// load the first 8 words and store at the 0 address
	ldmia	r0!, {r2-r9}
	stmia	r1!, {r2-r9}

	// load the second 8 words and store at the next address
	ldmia	r0!, {r2-r9}
	stmia	r1!, {r2-r9}

	// switch to IRQ mode and set stack pointer
	mov		r0, #0xD2
	msr		cpsr_c, r0
	mov		sp, #0x8000

	// switch back to Supervisor mode, set the stack pointer
	mov		r0, #0xD3
	msr		cpsr_c, r0
	mov		sp, #0x8000000

	bx		lr	

hang:
	b		hang

.section .data
IntTable:
	// Interrupt Vector Table (16 words)
	ldr		pc, reset_handler
	ldr		pc, undefined_handler
	ldr		pc, swi_handler
	ldr		pc, prefetch_handler
	ldr		pc, data_handler
	ldr		pc, unused_handler
	ldr		pc, irq_handler
	ldr		pc, fiq_handler

reset_handler:		.word hang // This was InstallIntTable
undefined_handler:	.word hang
swi_handler:		.word hang
prefetch_handler:	.word hang
data_handler:		.word hang
unused_handler:		.word hang
irq_handler:		.word irq
fiq_handler:		.word hang
