.globl 	randomNumber

randomNumber:
	push 	{r4-r8, lr}

randomNumberLoop:
	ldr 	r0, =0x20003004 				// Address of CLO
	ldr 	r0, [r0] 						// x = clock value
	mov 	r4, r0
	
	mov 	r1, #7  						// y = 17
	mov 	r2, #3 							// z = 32
	mov 	r3, #9 							// w = 96 

	mov 	r4, r0 							// t = x

	lsl 	r4, #11 						// t = t << 11
	eor 	r0, r4 							// t ^= t		

	lsr 	r4, #8 							// t = t >> 8
	eor 	r0, r4 							// t ^= t 							

	mov 	r0, r1 							// x = y
	mov 	r1, r2 							// y = z
	mov 	r2, r3 							// z = w

	lsr 	r3, #19 						// w = w >> 19
	eor		r3, r4 							// w ^= w

	lsl 	r4, #21 						// r4 << 21
	lsr 	r4, #21 						// r4 >> 21
	
// Random number is now in r4
	mov 	r0, r4 							
	mov 	r1, #30
	bl 		divide							// random % 30

	mov 	r5, r0 							// X = r5
	
	mov 	r0, r4
	mov 	r1, #21
	bl 		divide 							// random % 21

	mov 	r6, r0 							// Y = r6

// For the bounds
	lsl 	r5, #5 							// To align X to a cell
	lsl 	r6, #5 							// To align Y to a cell
	add 	r6, #32 						// Align Y

// Now we check the X,Y random coords in r5, r6 for collision and loop if needed
	mov 	r0, r5
	mov 	r1, r6
	bl 		boundsCheck

	cmp		r0, #-1
	ble 	randomNumberLoop
	
	mov 	r0, r5
	mov 	r1, r6

	pop 	{r4-r8, pc}
