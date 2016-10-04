.globl 	drawScore

drawScore:
	push	{r4-r8, lr}

	// Third digit = SCORE mod 10
	ldr 	r0, =score
	ldr 	r0, [r0]

	mov 	r1, #10
	bl 	 	divide

	mov 	r6, r0     				// THIRD DIGIT IN r6

	// Second digit = ((SCORE mod 100) - (SCORE mod 10)) div 10
	mov 	r2, r6 					// r2 = SCORE mod 10

	ldr 	r0, =score
	ldr 	r0, [r0]
	
	mov 	r1, #100
	bl 	 	divide 					// r0 = SCORE mod 100
	mov 	r7, r0 					// r7 = SCORE mod 100

	sub  	r0, r2 					// r0 = (SCORE mod 100) - (SCORE mod 10)
	mov 	r1, #10
	bl 		divide 					// r0 = ((SCORE mod 100) - (SCORE mod 10)) div 10

	mov 	r5, r1					// SECOND DIGIT IN r5

	// First digit = ((SCORE mod 1000) - (SCORE mod 100)) div 100
	mov 	r8, r7					// r8 = SCORE mod 100

	ldr 	r0, =score
	ldr 	r0, [r0]

	mov 	r1, #1000
	bl 	 	divide					// r0 = SCORE mod 1000

	sub  	r0, r8 					// r0 = (SCORE mod 1000) - (SCORE mod 100)
	mov 	r1, #100
	bl 		divide 					// r0 = ((SCORE mod 1000) - (SCORE mod 100)) div 10

	mov 	r4, r1

// First digit of score in r4
firstNumToPrint:
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
	
	mov 	r0, #175	 			// X = 175
	mov 	r1, #0 					// Y = 0
	bl 		DrawSquare	 			// DRAW

// Second digit of score in r5
secondNumToPrint:
	cmp	 	r5, #9 					// If lives == 9
	ldreq 	r2, =nine 				// Address of 9

	cmp	 	r5, #8 					// If lives == 8
	ldreq 	r2, =eight 				// Address of 8

	cmp	 	r5, #7 					// If lives == 7
	ldreq 	r2, =seven 				// Address of 7

	cmp	 	r5, #6 					// If lives == 6
	ldreq 	r2, =six 				// Address of 6

	cmp	 	r5, #5 					// If lives == 5
	ldreq 	r2, =five 				// Address of 5

	cmp	 	r5, #4 					// If lives == 4
	ldreq 	r2, =four 				// Address of 4

	cmp	 	r5, #3 					// If lives == 3
	ldreq 	r2, =three 				// Address of 3

	cmp	 	r5, #2 					// If lives == 2
	ldreq 	r2, =two 				// Address of 2

	cmp	 	r5, #1					// If lives == 1
	ldreq 	r2, =one 				// Address of 1
	
	cmp	 	r5, #0 					// If lives == 0
	ldreq 	r2, =zero 				// Address of 0
	
	mov 	r0, #207	 			// X = 207
	mov 	r1, #0 					// Y = 0
	bl 		DrawSquare	 			// DRAW

// Third digit of score in r6
thirdNumToPrint:
	cmp	 	r6, #9 					// If lives == 9
	ldreq 	r2, =nine 				// Address of 9

	cmp	 	r6, #8 					// If lives == 8
	ldreq 	r2, =eight 				// Address of 8

	cmp	 	r6, #7 					// If lives == 7
	ldreq 	r2, =seven 				// Address of 7

	cmp	 	r6, #6 					// If lives == 6
	ldreq 	r2, =six 				// Address of 6

	cmp	 	r6, #5 					// If lives == 5
	ldreq 	r2, =five 				// Address of 5

	cmp	 	r6, #4 					// If lives == 4
	ldreq 	r2, =four 				// Address of 4

	cmp	 	r6, #3 					// If lives == 3
	ldreq 	r2, =three 				// Address of 3

	cmp	 	r6, #2 					// If lives == 2
	ldreq 	r2, =two 				// Address of 2

	cmp	 	r6, #1					// If lives == 1
	ldreq 	r2, =one 				// Address of 1
	
	cmp	 	r6, #0 					// If lives == 0
	ldreq 	r2, =zero 				// Address of 0
	
	mov 	r0, #239	 			// X = 239
	mov 	r1, #0 					// Y = 0
	bl 		DrawSquare	 			// DRAW

	pop 	{r4-r8, pc}
