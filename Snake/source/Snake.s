.globl 	snake
.globl 	boundsCheck
.globl 	whereIsDoor
.globl 	whereIsVP
.globl 	numApplesEaten
.globl 	eraseTail
.globl 	queue
.globl 	checkValuePack

.section .text
/**  
 * r4, r5 are used as copies of x,y for the head
 * r6 = SNES direction
 * r7 = current direction 
 * r8 = head pointer
 * r9 = tail pointer
 * r10 = address of queue
 * r11 = Number of lives
 * r12 = wait time
 * 0 = null
 * 1 = up
 * 2 = down
 * 3 = left
 * 4 = right
 */



/** 
 *
 * SNAKE: draws the three snake cells when game starts. Stores coordinates in a queue.
 *
 */
snake:
	push 	{r4-r8, lr}
	mov 	r11, r0 						// Keep track of lives

	mov 	r8, #0 							// head pointer = 0
	mov 	r9, #0 							// tail pointer = 0
	ldr 	r10, =queue						// Queue base address in r10
	
	mov 	r0, #32 
	mov 	r1, #704

	str 	r0, [r10, r8]  					// Storing coordinates of tailX in queue
	add 	r8, #4  						// head pointer += 4
	str 	r1, [r10, r8] 					// Storing coordinates of tailY in queue
	add 	r8, #4  						// head pointer += 4

tail:
	mov 	r4, r0 							// copy of X
	mov 	r5, r1 							// copy of Y
	ldr 	r2, =snakeCell 					// Address of snakeCell
	bl 		DrawSquare 						// Drawing the snake	
	
	add 	r4, #32 						// X+= 32
	mov 	r0, r4 							// restore X
	mov 	r1, r5							// restore Y

	str 	r0, [r10, r8]  					// Storing coordinates of bodyX in queue
	add 	r8, #4  						// head pointer += 4
	str 	r1, [r10, r8] 					// Storing coordinates of bodyY in queue
	add 	r8, #4  						// head pointer += 4

body:
	ldr 	r2, =snakeCell 					// Address of snakeCell
	bl 		DrawSquare 						// Drawing the snake 					
	add 	r4, #32 						// X+= 32
	mov 	r0, r4 							// restore X
	mov 	r1, r5							// restore Y
	
	str 	r0, [r10, r8]  					// Storing coordinates of headX in queue
	add 	r8, #4  						// head pointer += 4
	str 	r1, [r10, r8] 					// Storing coordinates of headY in queue
	add 	r8, #4  						// head pointer += 4

head:
	ldr 	r2, =snakeCell 					// Address of snakeCell
	bl 		DrawSquare 						// Drawing the snake

	mov 	r6, #0 							// Initialize direction flag according to SNES
	mov 	r7, #0 							// Current direction
	mov 	r8, #24 						// Initilizing snake head pointer (offset in queue)



/** 
 *
 * DRAW APPLE: draws the apple in a random cell at start of game, updates coordinates
 *
 */
drawApple:
	bl 		randomNumber 					// Call random number

	// Add coordinates to memory so we know where apple is
	ldr 	r2, =whereIsApple 				// Storing apple ecoords in mem

	str 	r0, [r2], #4 					// Placing X in mem and incrementing address
	str 	r1, [r2] 						// Now apple coords are in "whereIsApple"

	ldr 	r2, =apple 						// address of apple colour
	bl 		DrawSquare  					// Draw the apple at random coordinate



/** 
 *
 * CHECK DOOR: if door was previously unlocked, do not change its location when game restarts
 *
 */
checkDoor:
	push 	{r4,r5}
	ldr 	r0, =whereIsDoor 				// Address of door coords
	ldr 	r4, [r0], #4 					// doorX = r4
	ldr 	r5, [r0]	 					// doorY = r5

	cmp 	r4, #0 							// If X not equal init
	bne 	checkDoorY 						// Then check doorY

	b 		checkDoorDone 					// otherwise nvm

checkDoorY:
	cmp 	r5, #0 	  						// If Y not equal init
	bne 	drawDoorPrev

	b 		checkDoorDone 

drawDoorPrev:
	mov 	r0, r4
	mov 	r1, r5
	ldr 	r2, =door
	bl 		DrawSquare

checkDoorDone:
	pop 	{r4, r5}



/** 
 *
 * SNAKE DIRECTION: reads the SNES input, moves the snake accordingly
 *
 */
snakeDirection:
	bl 		Read_SNES 						// Checking input

	mov 	r1, #1 							// Bitmask
	
	lsl 	r1, #3 							// Bitmask for START
	tst 	r0, r1 							// Checking START
	beq 	pausedGame

	lsl 	r1, #1 							// Bitmask for UP
	tst 	r0, r1	 						// Checking UP
	moveq 	r6, #1 							// Setting direction flag

	lsl 	r1, #1 							// Bitmask for DOWN
	tst 	r0, r1 							// Checking DOWN
	moveq 	r6, #2 							// Setting direction flag

	lsl 	r1, #1 							// Bitmask for LEFT
	tst 	r0, r1 							// Checking LEFT
	moveq 	r6, #3 							// Setting direction flag

	lsl 	r1, #1 							// Bitmask for RIGHT
	tst 	r0, r1 							// Checking RIGHT
	moveq 	r6, #4 							// Setting direction flag

pressedUp:
	cmp 	r6, #1 							// Checking currect direction of snake
	bne 	pressedDown 					// Already going in this direction	

	cmp 	r7, #2 							// Checking opposite direction of snake
	beq 	moveDown	 					// Keep going in opposite direction

moveUp:
	//Update direction of snake 
	mov 	r7, #1 							// Snake is going up 
	
	sub 	r5, #32 						// Y -= 32
	mov 	r0, r4 							// X = r4
	mov 	r1, r5 							// Y = r5

	// Check if the snake hit anything
	bl 		boundsCheck
	cmp 	r0, #-2 						// Check if hit door
	beq 	winGame 	
	
	cmp 	r0, #-1 						// If it returns -1
	mov 	r0, r11 						// Copy of lives
	beq 	lostALife 			 			// Hit something, lose a life
	mov 	r11, r0 						// Update lives

	mov 	r0, r9 							// Tail pointer
	mov 	r1, r4 							// X of head
	mov 	r2, r5  						// Y of head
	bl 		eraseTail
	mov 	r9, r0 							// Update tail pointer
	
	//Check Queue
	mov 	r0, r8  						// Head pointer
	mov 	r1, r9 							// Tail pointer
	bl 		checkQueue 						// Check and fix Queue
	mov 	r8, r0 							// Restore HP
	mov 	r9, r1 							// Restore TP

	// Store head coords in queue
	mov 	r0, r4 							// X = r4
	mov 	r1, r5 							// Y = r5

	str 	r0, [r10, r8]  					// Storing coordinates of tailX in queue
	add 	r8, #4  						// head pointer += 4
	str 	r1, [r10, r8] 					// Storing coordinates of tailY in queue
	add 	r8, #4  						// head pointer += 4

	// Move snake body
	ldr 	r2, =snakeCell 					// address of snakeCell
	bl 		DrawSquare 						// Drawing the snake

	// Check VP
	bl 		checkVP

	// Now we wait
	mov 	r0, r12							// ffff microseconds
	bl 		Wait 							// Wait

	b 		snakeDirection

pressedDown:
	cmp 	r6, #2 							// Checking currect direction of snake
	bne 	pressedLeft 					// Already going in this direction	

	cmp 	r7, #1 							// Checking opposite direction of snake
	beq 	moveUp		 					// Keep going in other direction			

moveDown:
	//Update direction of snake 
	mov 	r7, #2							// Snake is going down
	
	add 	r5, #32 						// Y += 32
	mov 	r0, r4 							// X = r4
	mov 	r1, r5 							// Y = r5

	// Check if the snake hit anything
	bl 		boundsCheck
	cmp 	r0, #-2 						// Check if hit door
	beq 	winGame	
	
	cmp 	r0, #-1 						// If it returns -1
	mov 	r0, r11 						// Copy of lives
	beq 	lostALife 			 			// Hit something, lose a life
	mov 	r11, r0 						// Update lives

	mov 	r0, r9 							// Tail pointer
	mov 	r1, r4 							// X of head
	mov 	r2, r5  						// Y of head
	bl 		eraseTail
	mov 	r9, r0 							// Update tail pointer

	//Check Queue
	mov 	r0, r8  						// Head pointer
	mov 	r1, r9 							// Tail pointer
	bl 		checkQueue 						// Check and fix Queue
	mov 	r8, r0 							// Restore HP
	mov 	r9, r1 							// Restore TP
	
	// Store head coords in queue
	mov 	r0, r4 							// X = r4
	mov 	r1, r5 							// Y = r5

	str 	r0, [r10, r8]  					// Storing coordinates of tailX in queue
	add 	r8, #4  						// head pointer += 4
	str 	r1, [r10, r8] 					// Storing coordinates of tailY in queue
	add 	r8, #4  						// head pointer += 4
	
	// Move snake body
	ldr 	r2, =snakeCell 					// address of snakeCell
	bl 		DrawSquare 						// Drawing the snake

	// Check VP
	bl 		checkVP

	// Now we wait
	mov 	r0, r12 						// ffff microseconds
	bl 		Wait 							// Wait
	
	b 		snakeDirection

pressedLeft:
	cmp 	r6, #3 							// Checking currect direction of snake
	bne 	pressedRight 					// Already going in this direction		

	cmp 	r7, #4 							// Checking opposite direction of snake
	beq 	moveRight 						// Keep going in opposite direction						

	cmp 	r7, #0 							// Initially can't go left
	beq 	snakeDirection 					// Check again

moveLeft:
	//Update direction of snake 
	mov 	r7, #3 							// Snake is going left
	
	sub 	r4, #32 						// X -= 32
	mov 	r0, r4 							// X = r4
	mov 	r1, r5 							// Y = r5

	// Check if the snake hit anything
	bl 		boundsCheck
	cmp 	r0, #-2 						// Check if hit door
	beq 	winGame 	
	
	cmp 	r0, #-1 						// If it returns -1
	mov 	r0, r11 						// Copy of lives
	beq 	lostALife 			 			// Hit something, lose a life
	mov 	r11, r0 						// Update lives

	mov 	r0, r9 							// Tail pointer
	mov 	r1, r4 							// X of head
	mov 	r2, r5  						// Y of head
	bl 		eraseTail
	mov 	r9, r0 							// Update tail pointer

	//Check Queue
	mov 	r0, r8  						// Head pointer
	mov 	r1, r9 							// Tail pointer
	bl 		checkQueue 						// Check and fix Queue
	mov 	r8, r0 							// Restore HP
	mov 	r9, r1 							// Restore TP
	
	// Store head coords in queue
	mov 	r0, r4 							// X = r4
	mov 	r1, r5 							// Y = r5
	
	str 	r0, [r10, r8]  					// Storing coordinates of tailX in queue
	add 	r8, #4  						// head pointer += 4
	str 	r1, [r10, r8] 					// Storing coordinates of tailY in queue
	add 	r8, #4  						// head pointer += 4
	
	// Move snake body
	ldr 	r2, =snakeCell 					// address of snakeCell
	bl 		DrawSquare 						// Drawing the snake

	// Check VP
	bl 		checkVP

	// Now we wait
	mov 	r0, r12 						// ffff microseconds
	bl 		Wait 							// Wait
	
	b 		snakeDirection

pressedRight:
	cmp 	r6, #4 							// Checking currect direction of snake
	bne 	snakeDirection 					// Already going in this direction		

	cmp 	r7, #3 							// Checking opposite direction of snake
	beq 	moveLeft 						// Already going in this direction		

moveRight:
	//Update direction of snake 
	mov 	r7, #4 							// Snake is going right

	add 	r4, #32 						// X += 32

	mov 	r0, r4 							// X = r4
	mov 	r1, r5 							// Y = r5

	// Check if the snake hit anything
	bl 		boundsCheck
	cmp 	r0, #-2 						// Check if hit door
	beq 	winGame 	
	
	cmp 	r0, #-1 						// If it returns -1
	mov 	r0, r11 						// Copy of lives
	beq 	lostALife 			 			// Hit something, lose a life
	mov 	r11, r0 						// Update lives

	mov 	r0, r9 							// Tail pointer
	mov 	r1, r4 							// X of head
	mov 	r2, r5  						// Y of head
	bl 		eraseTail
	mov 	r9, r0 							// Update tail pointer

	//Check Queue
	mov 	r0, r8  						// Head pointer
	mov 	r1, r9 							// Tail pointer
	bl 		checkQueue 						// Check and fix Queue
	mov 	r8, r0 							// Restore HP
	mov 	r9, r1 							// Restore TP
	
	// Store head coords in queue
	mov 	r0, r4 							// X = r4
	mov 	r1, r5 							// Y = r5

	str 	r0, [r10, r8]  					// Storing coordinates in queue
	add 	r8, #4  						// head pointer += 4
	str 	r1, [r10, r8] 					// Storing coordinates in queue
	add 	r8, #4  						// head pointer += 4

	// Move snake body
	ldr 	r2, =snakeCell 					// address of snakeCell
	bl 		DrawSquare 						// Drawing the snake

	// Check VP
	bl 		checkVP

	// Now we wait
	mov 	r0, r12 						// ffff microseconds
	bl 		Wait 							// Wait

	b 		snakeDirection

	pop 	{r4-r8, pc}




/** 
 *
 * CHECK VALUEPACK: checks if value pack was eaten by snake, delivers VP power
 *
 */
checkVP:
	push 	{r4-r9, lr}
	
	ldr 	r6, =queue 						// Adress of snake HP coords in mem

	ldr 	r6, =whereIsVP 					// Adress of VP coords in mem
	ldr 	r4, [r6], #4 					// X of VP
	ldr 	r5, [r6]						// Y of VP

	add 	r4, #32
	add 	r5, #32

checkVPx:
	cmp 	r0, r4 							// Checking X coordinate
	beq 	checkVPY

	b 		checkVPDone

checkVPY:
	cmp 	r1, r5 							// X && Y equal to head?
	bne 	checkVPDone

snakeAteVP:
	// UPDATE SCORE
	ldr 	r0, =score 
	ldr 	r1, [r0]
	add 	r1, #5 							// Score increases by 5
	str 	r1, [r0]
	bl 		drawScore
	
	// Add a life
	add 	r11, #1
	mov 	r0, r11
	bl 		drawLives

	// Reset VP coordinates
	mov 	r1, #0
	ldr 	r0, =whereIsVP
	str 	r1, [r0], #4
	str 	r1, [r0]

checkVPDone:
	pop 	{r4-r9, pc}



/** 
 *
 * ERASE TAIL: erases the tail of the snake, updates the tail pointer (TP)
 *
 */
eraseTail:
	push 	{r4-r8, lr}
	mov 	r7, r4
	mov 	r8, r5

	mov 	r4, r0 

	bl 		checkApple 						// r1 and r2 are X,Y for snake head
	cmp 	r1, #-1 						// If apple returns -1
	beq 	eraseTailEnd 					// Do not erase tail if apple eaten (make snake grow)

	ldr 	r1, =queue 						// Address of queue
	
	ldr 	r2, [r1, r0] 					// Loading X of tail
	add 	r0, #4 	  						// Tail pointer += 4
	ldr 	r3, [r1, r0] 					// Leading Y of tail
	add 	r0, #4 							// Tail pointer += 4

	mov 	r4, r0 							// Backup of tail pointer
	mov 	r0, r2 							// X of tail
	mov 	r1, r3 							// Y of tail
	ldr 	r2, =blank						// Grass address
	bl 		DrawSquare 						// Draw blank square at tail

eraseTailEnd:
	mov 	r0, r4 
	pop 	{r4-r8, pc}



/**
 * 
 * CHECK QUEUE: Takes in HP (r0) and TP (r1) and checks/fixrs queue so it stays within the bounds
 *
 */
checkQueue:
	push 	{r4-r8, lr}

	sub 	r7, r0, r1 						// update hp at the end r4 = hp - tp

	add 	r4, r0, #8 						// r1 = hp + 8
	cmp		r4, #192						// Compare hp + 8 to 192
	bge		resetQueue

	b  		checkQueueDone 					// Check is OK

resetQueue:
	mov 	r6, #0 							// Keeps track of offset for storing back at base of queue

resetQueueLoop:
	ldr 	r4, =queue 						// r4 = address of queue
	ldr 	r5, [r4, r1] 					// r5 = X of tail
	add 	r1, #4 							// Tail pointer += 4

	str 	r5, [r4, r6] 	 				// Storing elements at base
	add 	r6, #4 							// r6 += 4

	cmp 	r1, r0 							// tail pointer == head pointer
	blt 	resetQueueLoop 					// Until tp = hp

	// When tp == hp
	mov 	r0, r7	 						// HP = 0
	mov 	r1, #0 							// TP = 0

checkQueueDone:
	pop 	{r4-r8, pc}



/**
 * 
 * BOUNDS CHECK: checks for collisions of the snake's head with borders, walls, or snake's body/tail
 *
 */
boundsCheck:
	push 	{r4-r9, lr}

	cmp 	r0, #0 							// X == 0?
	beq 	hitBorder

	cmp 	r1, #32							// Y == 32?
	beq 	hitBorder 						

	cmp 	r0, #992 						// X == 992?
	beq 	hitBorder 						

	cmp 	r1, #736 						// Y == 736?
	beq 	hitBorder 				

// CHECK BLOCKS
checkBlocks:
	ldr 	r4, =wood_blocks 				// Wood blocks array

checkBlocksLoop:
	ldr 	r5, [r4], #4 					// Load X in r5 

	cmp 	r5, #-1 						// Check if array is finished
	beq 	checkSnake 						// If array finished then done Checking
				
	ldr 	r6, [r4], #4					// Load Y in r6

checkX:
	cmp 	r0, r5 							// If X is equal then check Y
	beq 	checkY
	
	b 		checkBlocksLoop 				// Otherwise done Checking

checkY:
	cmp 	r1, r6 							// If Y is also equal
	beq 	hitBorder						// Then there is a collision

	b 		checkBlocksLoop					

// CHECK SNAKE
checkSnake:
	ldr 	r4, =queue 						// Base address of Snake
 	add 	r4, r9 							// r4 includes Tp offset

checkSnakeLoop:
	ldr 	r5, [r4], #4					// Loading X of Snake
 	ldr 	r6, [r4], #4 					// Loading Y of Snake 

 	add 	r9, #8 							// Tail += 8

ckeckSnakeX:
 	cmp 	r0, r5 							// Checking if X collision
 	beq 	checkSnakeY 					// If X then check Y

 	cmp 	r8, r9 							// If TP == HP?
 	bgt 	checkSnakeLoop

 	b 		checkDoor2
 
checkSnakeY:
 	cmp 	r1, r6 							// Checking Y collision
 	beq 	hitBorder						// Collision with snake

  	cmp 	r8, r9 							// If TP == HP?
 	bgt 	checkSnakeLoop

// CHECK DOOR
checkDoor2:
	ldr 	r6, =whereIsDoor 				// Address of door coords
	ldr 	r4, [r6], #4 					// doorX = r4
	ldr 	r5, [r6]	 					// doorY = r5

	cmp 	r0, r4 							// If X equal door
	beq 	checkDoorY2						// Then check doorY

	b 		checkDoorDone2 					// otherwise nvm

checkDoorY2:
	cmp 	r1, r5 	  						// Checking Y equal door
	moveq 	r0, #-2 						// return -2 for door 

	b 		boundsCheckDone 				// Finish

checkDoorDone2:
	b 		boundsCheckDone

hitBorder:
	mov 	r0, #-1 						// Returns -1 if you hit the border

boundsCheckDone:
	pop 	{r4-r9, pc}



/**
 *
 * LOST A LIFE: Takes in current # of lives (r0), decrements lives, and determine if game
 * needs to reset (no more lives left), or continue (with updates lives printed)
 *
 */
lostALife:
	push 	{r4-r8}

	mov 	r4, r0 							// Copy of lives
	sub 	r4, #1 							// Lives--
	
	mov 	r0, r4 							// Num of lives
	bl 		drawLives 						// Draws remaining lives
	
	cmp 	r4, #0 							// Lives == 0?
	ble 	LoseGame 						// Lost the Game sorry

	b 		resetState 						// Resets the game state



/**
 * 
 * RESET STATE: When snake dies: update lives, redraw snake/apple/door, keep score
 *
 */
resetState:
	mov 	r11, r4 						// Now it's a recursive program and we're updating lives so it 
											// follows ACPS convention
	bl 		startGame 						// Restart game
	
	mov 	r0, r4 							// return lives left to update lives
	pop 	{r4-r8, pc}



/**
 * 
 * CHECK APPLE: checks if snake ate apple. Updates score/numApplesEaten, and spawns new apple
 *
 */
checkApple:
	push 	{r4-r6, lr}

	ldr 	r6, =whereIsApple 				// Adress of apple coords in mem
	ldr 	r4, [r6], #4 					// X of apple
	ldr 	r5, [r6]						// Y of apple

	cmp 	r1, r4 							//  checking X coordinate
	beq 	checkAppleY

	b 		checkAppleDone

checkAppleY:
	cmp 	r2, r5 							// X && Y equal to head?
	bne 	checkAppleDone

resetApple:
	// UPDATE SCORE
	ldr 	r0, =score 
	ldr 	r1, [r0]
	add 	r1, #10 						// Score increases by 10
	str 	r1, [r0]

	bl 		drawScore

	ldr 	r0, =numApplesEaten 
	ldr 	r1, [r0]
	add 	r1, #1 							// One more apple eaten
	str 	r1, [r0]

resetAppleLoop:
	bl 		randomNumber

	ldr 	r2, =whereIsApple 				// Storing apple coords in mem
	ldr 	r4, [r2], #4 					// Getting X of previous apple
	ldr 	r5, [r2] 						// Getting Y on previous apple

	cmp 	r4, r0 							// Compare prev X with new X
	beq 	resetAppleY 					// If X equal then check Y
	b 		resetAppleContinue

resetAppleY:
	cmp 	r5, r1 							// Compare prev Y with new Y
	beq 	resetAppleLoop 					// If the coordinates are the same then generate different coordinates

	// Check for the head of the snake in r7 and r8
	cmp 	r0, r7
	bne 	checkSnake2

	cmp 	r1, r8
	beq 	resetAppleLoop

checkSnake2:
	ldr 	r4, =queue 						// Base address of Snake
 	add 	r4, r9 							// r4 includes Tp offset

checkSnakeLoop2:
	ldr 	r5, [r4], #4					// Loading X of Snake
 	ldr 	r6, [r4], #4 					// Loading Y of Snake 

 	add 	r9, #8 							// Tail += 8

ckeckSnakeX2:
 	cmp 	r0, r5 							// Checking if X collision
 	beq 	checkSnakeY2 					// If X then check Y

 	cmp 	r8, r9 							// If TP == HP?
 	bgt 	checkSnakeLoop2

 	b 		resetAppleContinue
 
checkSnakeY2:
 	cmp 	r1, r6 							// Checking Y collision
 	beq 	resetAppleLoop					// Collision with snake

  	cmp 	r8, r9 							// If TP == HP?
 	bgt 	checkSnakeLoop2

resetAppleContinue:
	ldr 	r2, =whereIsApple 				// Storing apple coords in mem
	str 	r0, [r2], #4 					// Placing X in mem and incrementing address
	str 	r1, [r2] 						// Now apple coords are in "whereIsApple"

	ldr 	r2, =apple 						// address of apple colour
	bl 		DrawSquare  					// Draw the apple at random coordinate

	ldr 	r0, =numApplesEaten 			// Check number of apples eaten
	ldr 	r1, [r0]
	cmp 	r1, #20 						// Unlock door after 20 apples eaten
	beq 	doorUnlocked
	
	// Set the flag
	mov 	r1, #-1 						// Snake ate apple
	
	b 		checkAppleDone

doorUnlocked:
	bl 		randomNumber

	ldr 	r2, =whereIsDoor 				// Storing door coords in mem
	str 	r0, [r2], #4 					// Placing X in mem and incrementing address
	str 	r1, [r2] 						// Now door coords are in "whereIsDoor"

	ldr 	r2, =door 						// address of door colour
	bl 		DrawSquare  					// Draw the door at random coordinate

	// Set the flag
	mov 	r1, #-1

checkAppleDone:
	pop 	{r4-r6, pc}



/**
 *
 * PAUSE GAME: if start is pressed, display pause menu. If pressed again, reset state.
 * 
 */
pausedGame:
	push 	{r4-r9}
	mov 	r4, #0

	bl 		disableTimerInterrupt 			// pause the interrupt timer

	// Draw the pause screen 
	mov 	r0, #272						// X 
	mov 	r1, #240 						// Y 
	ldr 	r2, =pauseScreen 				
	bl 		DrawMessage						

	// Draw the arrow at restart game
	mov 	r0, #372 						// X for arrow
	mov 	r1, #420 						// Y for arrow
	ldr 	r2, =whiteArrow 				// arrow image resource
	bl 		DrawSquare 						// Draw Arrow there

	ldr 	r0, =500000
	bl		Wait

readPause: 									//Loop and keep reading SNES
	bl 		Read_SNES 						// Will read the controller

	mov 	r5, r0
	mov 	r1, #1 							// bitmask
	lsl 	r1, #3 							// Bitmask for Start

	tst 	r0, r1 							// Checking bit corresponding to A				
	beq 	checkPauseStart					// If Start not pressed then we done

	mov 	r0, r5

	state 	.req 	r4

checkPauseDown:
	cmp 	state, #1 	 					// Is it already at quit?
	beq 	checkPauseUp 					// Skip checkDown
	
	mov 	r1, #1 							// bitmask
	lsl 	r1, #5 							// Bitmask for DOWN

	tst 	r0, r1 							// Checking bit corresponding to Down 			******beq = pushed Down						
	bne 	checkPauseUp 					// If down not pressed check if up pressed

	mov 	state, #1  						// Changing state of pointer
	
	mov 	r5, r0 
	
	// Erasing arrow at Restart
	mov 	r0, #372						// X = 300
	mov 	r1, #420 						// Y = 512
	ldr 	r2, =black 						// Loading address of empty square to erase pointer
	bl 		DrawSquare 						// Drawing pointer to option

	// Draw the arrow at quit
	mov 	r0, #372						// X = 300
	mov 	r1, #456 						// Y = 576
	ldr 	r2, =whiteArrow 						// Loading address of pointer picture
	bl 		DrawSquare 						// Drawing pointer to option
	mov 	r0, r5 

checkPauseUp:
	cmp 	state, #0 						// Checks if pointer is already pointing at Start
	beq 	checkPauseA		 				// skip up check 

	mov 	r1, #1 							// bitmask
	lsl 	r1, #4 							// Bitmask for UP

	tst 	r0, r1 							// Checking bit corresponding to Up 			******beq = pushed Up						
	bne 	checkPauseA 					// If down not pressed then we done

	mov 	state, #0  						// Changing state of pointer
	
	mov 	r5, r0 
	// Erasing arrow at Quit
	mov 	r0, #372						// X
	mov 	r1, #456 						// Y
	ldr 	r2, =black 						// Loading address
	bl 		DrawSquare 						

	// Draw the arrow at Restart
	mov 	r0, #372						// X = 300
	mov 	r1, #420 						// Y = 512
	ldr 	r2, =whiteArrow 				// Loading address
	bl 		DrawSquare 						
	mov 	r0, r5 

checkPauseA:
	mov 	r1, #1 							// bitmask
	lsl 	r1, #8 							// Bitmask for A

	tst 	r0, r1 							// Checking bit corresponding to A				
	bne 	done 							// If A not pressed then we done

	cmp 	state, #0 	 					// Is pointer at restart?
	beq 	restartGame

	cmp 	state, #1 						// Is poitner at Quit?
	beq 	_start
	
	b 		done

checkPauseStart:
	// If start was pressed...
	ldr 	r0, =100000
	bl 		Wait

	bl 		enableInterrupts 				// enable Timer IRQ
	bl 		enableTimerIRQ
	
	ldr 	r0, =whereIsVP
	ldr 	r0, [r0]
	cmp 	r0, #-32 
	bne 	skipWaiter

	ldr 	r0, =10000000 					// Should wait 30 seconds
	bl 		waiter 

skipWaiter:
	mov 	r0, #256 						// X
	mov 	r1, #224 						// Y					

redrawGrass:
	ldr 	r2, =blank 						// Address of image

	mov 	r4, r0 							// Backup of X
	mov 	r5, r1 							// Backup of Y
	bl 		DrawSquare 				

	mov 	r0, r4 							// Restore X
	mov 	r1, r5 							// Restore Y

	add 	r0, #32 						// X += 32

	cmp 	r0, #768 						// Check width
	blt 	redrawGrass 					// Keep drawing

	mov 	r0, #256						// reset X
	add 	r1, #32 						// Y += 32

	cmp 	r1, #576 						// Check height
	blt 	redrawGrass						// Keep drawing
	
redrawSnake:
	ldr 	r4, =queue 						// Address of queue
	add 	r4, r9 							// Addign tail pointer

redrawSnakeLoop:
	ldr 	r0, [r4], #4 					// Load X
	ldr 	r1, [r4], #4 					// Load Y

	add 	r9, #8 							// Incrementing by one coordinate
	ldr 	r2, =snakeCell 					// img of snek 
	bl 		DrawSquare

	cmp 	r9, r8 							// compare current address to hp
	blt 	redrawSnakeLoop 				// Redraw the snek until full

redrawApple:
	ldr 	r4, =whereIsApple 				// getting address of apple array
	ldr 	r0, [r4], #4 					// X 
	ldr 	r1, [r4] 						// Y
	ldr 	r2, =apple 						// apple image
	bl 		DrawSquare 

redrawDoor:
	ldr 	r4, =whereIsDoor 				// getting address of door array
	ldr 	r0, [r4], #4 					// X 
	ldr 	r1, [r4] 						// Y
	
	cmp 	r0, #0 							// check X
	bne 	redrawDoorContinue

	cmp 	r1, #0 							// check Y
	beq 	redrawVP 

redrawDoorContinue:
	ldr 	r2, =door 						// door image
	bl 		DrawSquare 

redrawVP:
	ldr 	r4, =whereIsVP 					// getting address of VP array
	ldr 	r0, [r4], #4 					// X 
	ldr 	r1, [r4] 						// Y
	
	cmp 	r0, #0 							// check X
	bne 	redrawVPContinue

	cmp 	r1, #0 							// check Y
	beq 	dontDrawVP 

redrawVPContinue:
	ldr 	r2, =heart 						// door image
	bl 		DrawSquare 

dontDrawVP:
	pop 	{r4-r9}
	b 		snakeDirection

done: 
	b 		readPause 						// Keep looping to read the SNES input



.section .data
.align 4
font:	.incbin	"font.bin"

queue:
	.rept 	192 													
	.byte 	0
	.endr

whereIsApple:
	.word 	0,0

whereIsDoor:
	.word 	0,0

whereIsVP:
	.word 	-32, -32 

numApplesEaten:
	.word 	0
