.globl 	drawLives

drawLives:
	push	{r4-r8, lr}

	mov 	r4, r0 					// Copy of lives 






	cmp	 	r4, #9 					// If lives == 9
	ldreq 	r2, =nine 				// Address of 9

	cmp	 	r4, #8 					// If lives == 8
	ldreq 	r2, =eight 				// Address of 8

	cmp	 	r4, #7 					// If lives == 7
	ldreq 	r2, =seven 				// Address of 7

	cmp	 	r4, #6 					// If lives == 6
	ldreq 	r2, =six 				// Address of 6







	cmp	 	r4, #5 					// If lives == 5
	ldreq 	r2, =five 				// Address of 5

	cmp	 	r4, #4 					// If lives == 4
	ldreq 	r2, =four 				// Address of 4

	cmp	 	r4, #3 					// If lives == 3
	ldreq 	r2, =three 				// Address of 3

	cmp	 	r4, #2 					// If lives == 2
	ldreq 	r2, =two 				// Address of 2

	cmp	 	r4, #1					// If lives == 1
	ldreq 	r2, =one 				// Address of 1
	
	cmp	 	r4, #0 					// If lives == 0
	ldreq 	r2, =zero 				// Address of 0

	mov 	r0, #684	 			// X = 687
	mov 	r1, #0 					// Y = 0

	bl 		DrawSquare	 			// DRAW
	
	mov 	r0, r4 					// Return lives again

	pop 	{r4-r8, pc}
