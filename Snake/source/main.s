.section    .init
.globl     	_start
.globl 		DrawSquare
.globl 		DrawMessage
.globl 		wood_blocks
.globl 		startGame
.globl	 	quitGame
.globl 		winGame
.globl 		LoseGame
.globl 		anyButtonToRestart
.globl 		restartGame

_start:
    b       main
    
.section .text
main:
    //mov     sp, 0x8000 					//Initializing stack pointer
	
	bl 		InstallIntTable 				// Installing the Interrupt table 
	bl		EnableJTAG 						// Enabling JTag 
	bl		InitFrameBuffer					// Initializing Frame Buffer 
 	bl 		disableTimerInterrupt

// Draw menu
	mov 	r0, #0 							// X = 0
	mov 	r1, #0  						// Y = 0
	ldr 	r2, =mainMenu 					// Loading address of pointer picture
	bl 		DrawBackground 					// Drawing Main Menu

	mov 	r0, #300						// X = 300
	mov 	r1, #512 						// Y = 512
	ldr 	r2, =arrow 						// Loading address of pointer picture
	bl 		DrawSquare 						// Drawing pointer to option



/** 
 *
 * INITIALIZE PINS: 9 out, 10 in, 11 out
 *
 */
init:
	mov 	r0, #9 							// r0 = pin#
	mov 	r1, #0b001 						// Output
	bl 		Init_GPIO 						// Initialize pin

	mov 	r0, #10 						// r0 = pin#
	mov 	r1, #0b000 						// Input
	bl 		Init_GPIO 						// Initialize pin

	mov 	r0, #11 						// r0 = pin#
	mov 	r1, #0b001 						// Output
	bl 		Init_GPIO 						// Initialize pin

	pointerState .req 	r4 					// Where the pointer is pointing
	mov 	r4, #0 							// 0 = Start

	// Reset the score
	ldr 	r0, =score
	ldr 	r1, [r0]
	mov 	r1, #0
	str 	r1, [r0]

	// Reset number of apples eaten
	ldr 	r0, =numApplesEaten 
	ldr 	r1, [r0]
	mov 	r1, #0 							
	str 	r1, [r0]

	// Reset the door
	ldr 	r0, =whereIsDoor 
	mov 	r1, #0
	str 	r1, [r0], #4
	str 	r1, [r0]

	ldr 	r12, =70000 					// Iniialize wait time (SPEED OF SNAKE)
	mov 	r11, #5 						// Initialize lives to 5 
	


/** 
 *
 * START MENU: Checks input to update arrows at Start Game and Quit Game
 *
 */
readInput: 									// Loop and keep reading SNES
	bl 		Read_SNES 						// Will read the controller

checkDown:
	cmp 	pointerState, #1 				// Is it already at quit?
	beq 	checkUp 						// Skip checkDown
	
	mov 	r1, #1 							// bitmask
	lsl 	r1, #5 							// Bitmask for DOWN

	tst 	r0, r1 							// Checking bit corresponding to Down 			******beq = pushed Down						
	bne 	checkUp 						// If down not pressed check if up pressed

	mov 	pointerState, #1  				// Changing state of pointer
	
	mov 	r5, r0 
	
	// Erasing arrow at Start
	mov 	r0, #300						// X = 300
	mov 	r1, #512 						// Y = 512
	ldr 	r2, =blank 						// Loading address of empty square to erase pointer
	bl 		DrawSquare 						// Drawing pointer to option

	// Draw the arrow at quit
	mov 	r0, #300						// X = 300
	mov 	r1, #576 						// Y = 576
	ldr 	r2, =arrow 						// Loading address of pointer picture
	bl 		DrawSquare 						// Drawing pointer to option
	mov 	r0, r5 

checkUp:
	cmp 	pointerState, #0 				// Checks if pointer is already pointing at Start
	beq 	checkA		 					// skip up check 

	mov 	r1, #1 							// bitmask
	lsl 	r1, #4 							// Bitmask for UP

	tst 	r0, r1 							// Checking bit corresponding to Up 			******beq = pushed Up						
	bne 	checkA 							// If down not pressed then we done

	mov 	pointerState, #0  				// Changing state of pointer
	
	mov 	r5, r0 
	
	// Erasing arrow at Quit
	mov 	r0, #300						// X = 300
	mov 	r1, #576 						// Y = 576
	ldr 	r2, =blank 						// Loading address of empty square to erase pointer
	bl 		DrawSquare 						// Drawing pointer to option

	// Draw the arrow at Start
	mov 	r0, #300						// X = 300
	mov 	r1, #512 						// Y = 512
	ldr 	r2, =arrow 						// Loading address of pointer picture
	bl 		DrawSquare 						// Drawing pointer to option
	mov 	r0, r5 

checkA:
	mov 	r1, #1 							// bitmask
	lsl 	r1, #8 							// Bitmask for A

	tst 	r0, r1 							// Checking bit corresponding to A				
	bne 	done 							// If A not pressed then we done

	cmp 	pointerState, #0 	 			// Is pointer at Start?
	beq 	startGame

	cmp 	pointerState, #1 				// Is poitner at Quit?
	beq 	quitGame
	
	b 		done

done: 
	b 		readInput 						// Keep looping to read the SNES input



/** 
 *
 * INITIALIZE GAME: Draw the grass, borders, walls, and score/lives when game starts
 *
 */
startGame:
	// Reset the interrupts 
	bl 		enableInterrupts 				// enable Timer IRQ
	bl 		enableTimerIRQ
	ldr 	r0, =30000000 					// Should wait 30 seconds
	bl 		waiter 

	// Reset the VP
	ldr 	r0, =whereIsVP 
	mov 	r1, #-32 
	str 	r1, [r0], #4
	str 	r1, [r0]

	mov 	r0, #0 	 						// X = 0
	mov 	r1, #0							// Y = 32

drawGrass:						
	ldr 	r2, =blank 						// Address of image

	mov 	r4, r0 							// Backup of X
	mov 	r5, r1 							// Backup of Y
	bl 		DrawSquare 				
	mov 	r0, r4 							// Restore X
	mov 	r1, r5 							// Restore Y

	bl 		drawBorder 				
	mov 	r0, r4 							// Restore X
	mov 	r1, r5 							// Restore Y

	add 	r0, #32 						// X += 32

	cmp 	r0, #1024 						// Check width
	blt 	drawGrass 						// Keep drawing

	mov 	r0, #0 							// reset X
	add 	r1, #32 						// Y += 32

	cmp 	r1, #768 						// Check height
	blt 	drawGrass						// Keep drawing

	// Draw Wooden Blocks
	mov 	r4, #0 							// Loop counter = 0
	ldr 	r5, =wood_blocks 				// Address of coordinates array

drawBlocksLoop:
	ldr 	r0, [r5], #4 					// Getting BlocksX
	ldr 	r1, [r5], #4 					// Getting BlocksY 
	ldr 	r2, =blocks						// Addres of wooden blocks
	bl 		DrawSquare 						// Drawing at the cell

	add 	r4, #1 	 						// r4++
	cmp 	r4, #20 						// counter == r6?
	blt  	drawBlocksLoop

drawScoreAndLivesText:
	mov 	r0, #544 						// X = 544
	mov 	r1, #0 							// Y = 0
	ldr 	r2, =livesText
	bl 		DrawTexts 						//Draw the text there

	mov 	r0, #32 						// X = 32
	mov 	r1, #0 							// Y = 0
	ldr 	r2, =scoreText
	bl 		DrawTexts 						//Draw the text there

drawLivesValue:
	mov 	r0, r11
	bl 		drawLives 						// Draw 5 at lives

drawScoreValue:
	bl 		drawScore 						// Draw the score

callingSnake:
	mov 	r0, r11
	bl 		snake 		 				 	// Continue to Snake



/** 
 *
 * QUIT GAME: Clears the screen and ends in infinite loop
 *
 */
quitGame:						
	mov 	r0, #0 							// X
	mov 	r1, #0 							// Y

quitGameLoop:
	ldr 	r2, =black 						// Address of image
	mov 	r4, r0 							// Backup of X
	mov 	r5, r1 							// Backup of Y
	bl 		DrawSquare 				
	mov 	r0, r4 							// Restore X
	mov 	r1, r5 							// Restore Y

	add 	r0, #32 						// X += 32

	cmp 	r0, #1024 						// Check width
	blt 	quitGameLoop					// Keep drawing

	mov 	r0, #0 							// reset X
	add 	r1, #32 						// Y += 32

	cmp 	r1, #768 						// Check height
	blt 	quitGameLoop					// Keep drawing

.globl 	haltLoop$
haltLoop$:
	b	 	haltLoop$



/** 
 *
 * RESTART GAME: Sets everything back to initial values, starts game
 *
 */
restartGame:
	// Reset the score
	ldr 	r0, =score
	ldr 	r1, [r0]
	mov 	r1, #0
	str 	r1, [r0]

	// Reset number of apples eaten
	ldr 	r0, =numApplesEaten 
	ldr 	r1, [r0]
	mov 	r1, #0 							
	str 	r1, [r0]

	// Reset the door
	ldr 	r0, =whereIsDoor 
	mov 	r1, #0
	str 	r1, [r0], #4
	str 	r1, [r0]

	// Reset the VP
	ldr 	r0, =whereIsVP 
	mov 	r1, #0
	str 	r1, [r0], #4
	str 	r1, [r0]

	ldr 	r12, =70000 					// Iniialize wait time
	mov 	r11, #5 						// Initialize lives to 5 
	
	b 		startGame



/** 
 *
 * WIN GAME/LOSE GAME: Prints winning/losing message, waits for any button to be pressed and restarts game
 *
 */
winGame:
	// Make snake overlap with door
	mov 	r0, r4 							// X
	mov 	r1, r5 							// Y
	ldr 	r2, =snakeCell 					// snake img
	bl 		DrawSquare 						// Draw new head

	mov 	r0, r9 							// Tail pointer
	mov 	r1, r4 							// X of head
	mov 	r2, r5  						// Y of head
	bl 		eraseTail

	// Display win game
	mov 	r0, #272						// X 
	mov 	r1, #240 						// Y 
	ldr 	r2, =gameWon 				
	bl 		DrawMessage						
	
anyButtonToRestart:
	bl 		Read_SNES

	ldr 	r1, =0xFFFF						// Fill r1 with 16 1's
	and 	r0, r1 							// Checking for anything but all 1's
	cmp 	r0, r1
	bne 	_start

	b 		anyButtonToRestart

LoseGame:
	// Display lose game
	mov 	r0, #272						// X 
	mov 	r1, #240 						// Y 
	ldr 	r2, =gameLost 				
	bl 		DrawMessage						

 	b 		anyButtonToRestart



/** 
 *
 * DRAWS BORDER: draws the border around the edges
 *
 */
drawBorder:
	push {r4-r8, lr}

	cmp 	r0, #0 							// X == 0?
	beq 	drawBorderThere

	cmp 	r1, #32							// Y == 32?
	beq 	drawBorderThere 						

	cmp 	r0, #992 						// X == 992?
	beq 	drawBorderThere 						

	cmp 	r1, #736 						// Y == 736?
	beq 	drawBorderThere 				

	b 		endDrawBorder

drawBorderThere:
	cmp 	r1, #0 							// Y == 0?
	beq 	endDrawBorder 

	ldr 	r2, =brick 						// Address of brick
	bl 		DrawSquare 						// Draw it there

endDrawBorder:
	pop	{r4-r8, pc}



/**
 *
 * DRAW TEXTS: Used for "Score" and "Lives". Draws a 143x32 rectangle image at Px, Py (r0, r1)
 *
 */
DrawTexts:
	push	{r4-r12, lr}

	mov 	r3, r2							// Moving the 3rd arg into address reg
	px      .req    r0
    py      .req    r1
	color	.req	r2
	addr    .req    r3

	mov 	r9, px 							// Backup of X
	mov 	r4, #0 							// r4 = 0 ( Y counter)

DrawTexts_Loop:			
	mov 	r5, #0 							// r5 = 0 (X counter)
	mov 	px, r9

DrawTexts_InnerLoop:
	ldrh 	color, [addr], #2				// r2 = pixel colour
	
	mov 	r6, px 							// backup of X
	mov 	r7, py  						// backup of Y
	mov 	r8, addr 						// backup of addr			

	bl 		DrawPixel 						// Draw pixel of that color at Px, Py

	mov 	px, r6 							// restore of X
	mov 	py, r7  						// restore of Y
	mov 	addr, r8 						// restore the arrd

	add 	r5, #1 							// r5++
	add 	px, #1 							// x++

	cmp 	r5, #143 			
	blt 	DrawTexts_InnerLoop			 // Draws horizontally

	add 	r4, #1 							// r4++
	add 	py, #1 							// y++

	cmp 	r4, #32 			
	blt 	DrawTexts_Loop 				// Outer loop

	.unreq 	px
	.unreq 	py
	.unreq 	color
	.unreq 	addr 

	pop		{r4-r12, pc}



/** 
 *
 * DRAW SQUARE: draws a 32x32 square image at Px, Py (r0, r1)
 *
 */
DrawSquare:
	push	{r4-r12, lr}

	mov 	r3, r2							// Moving the 3rd arg into address reg
	px      .req    r0
    py      .req    r1
	color	.req	r2
	addr    .req    r3

	mov 	r9, px 							// Backup of X
	mov 	r4, #0 							// r4 = 0 ( Y counter)

DrawSquare_Loop:			
	mov 	r5, #0 							// r5 = 0 (X counter)
	mov 	px, r9

DrawSquare_InnerLoop:
	ldrh 	color, [addr], #2				// r2 = pixel colour
	
	mov 	r6, px 							// backup of X
	mov 	r7, py  						// backup of Y
	mov 	r8, addr 						// backup of addr			

	bl 		DrawPixel 						// Draw pixel of that color at Px, Py

	mov 	px, r6 							// restore of X
	mov 	py, r7  						// restore of Y
	mov 	addr, r8 						// restore the arrd

	add 	r5, #1 							// r5++
	add 	px, #1 							// x++

	cmp 	r5, #32 			
	blt 	DrawSquare_InnerLoop			 // Draws horizontally

	add 	r4, #1 							// r4++
	add 	py, #1 							// y++

	cmp 	r4, #32 			
	blt 	DrawSquare_Loop 				// Outer loop

	.unreq 	px
	.unreq 	py
	.unreq 	color
	.unreq 	addr 

	pop		{r4-r12, pc}



/** 
 *
 * DRAW MESSAGE: Used for "Game Won", "Game Lost", and "Pause". Draws a 480x320 image
 *
 */
DrawMessage:
	push	{r4-r12, lr}

	mov 	r3, r2							// Moving the 3rd arg into address reg
	px      .req    r0
    py      .req    r1
	color	.req	r2
	addr    .req    r3

	mov 	r9, px 							// Backup of X
	mov 	r4, #0 							// r4 = 0 ( Y counter)

DrawMessage_Loop:			
	mov 	r5, #0 							// r5 = 0 (X counter)
	mov 	px, r9

DrawMessage_InnerLoop:
	ldrh 	color, [addr], #2				// r2 = pixel colour
	
	mov 	r6, px 							// backup of X
	mov 	r7, py  						// backup of Y
	mov 	r8, addr 						// backup of addr			

	bl 		DrawPixel 						// Draw pixel of that color at Px, Py

	mov 	px, r6 							// restore of X
	mov 	py, r7  						// restore of Y
	mov 	addr, r8 						// restore the arrd

	add 	r5, #1 							// r5++
	add 	px, #1 							// x++

	cmp 	r5, #480 			
	blt 	DrawMessage_InnerLoop			 // Draws horizontally

	add 	r4, #1 							// r4++
	add 	py, #1 							// y++

	cmp 	r4, #320 			
	blt 	DrawMessage_Loop 				// Outer loop

	.unreq 	px
	.unreq 	py
	.unreq 	color
	.unreq 	addr 

	pop		{r4-r12, pc}



/** 
 *
 * DRAW BACKGROUND: Used for main menu. Draws a 1024x768 image
 *
 */
DrawBackground:
	push	{r4-r12, lr}

	mov 	r3, r2							// Moving the 3rd arg into address reg
	px      .req    r0
    py      .req    r1
	color	.req	r2
	addr    .req    r3

	//ldr 	addr, =menu 					// r3 = address of menu data

	mov 	r9, px 							// Backup of X
	mov 	r4, #0 							// r4 = 0 ( Y counter)
DrawBackground_Loop:

	mov 	r5, #0 							// r5 = 0 (X counter)
	mov 	px, r9
DrawBackground_InnerLoop:

	ldrh 	color, [addr], #2				// r2 = pixel colour
	
	mov 	r6, px 							// backup of X
	mov 	r7, py  						// backup of Y
	mov 	r8, addr 						// backup of addr			

	bl 		DrawPixel 						// Draw pixel of that color at Px, Py

	mov 	px, r6 							// restore of X
	mov 	py, r7  						// restore of Y
	mov 	addr, r8 						// restore the arrd

	add 	r5, #1 							// r5++
	add 	px, #1 							// x++

	cmp 	r5, #1024 			
	blt 	DrawBackground_InnerLoop 		// Draws horizontally

	add 	r4, #1 							// r4++
	add 	py, #1 							// y++

	cmp 	r4, #768 			
	blt 	DrawBackground_Loop 			// Outer loop

	.unreq 	px
	.unreq 	py
	.unreq 	color
	.unreq 	addr 

	pop		{r4-r12, pc}


.section .data
wood_blocks:
	.word 	224,192, 256,192, 224,224
	.word 	736,192, 768,192, 768,224
	.word 	224,544, 224,576, 256,576
	.word 	768,544, 736,576, 768,576
	.word 	224,352, 224,384, 768,352, 768,384 
	//.word 	480,352, 512,352, 480,384, 512,384
	.word 	480,192, 512,192, 480,576, 512,576
	.word 	-1

.globl score
score: 		
	.word 	0
