@ Created by Muhammad Wahaj Taseer and Hannah Rueb

/**
.globl 	StartDriver
.globl 	Init_GPIO
.globl 	WriteStringUART
.globl  InitUART
.globl 	pressed_B
.globl 	pressed_Y
.globl 	pressed_SELECT
.globl 	pressed_START
.globl 	pressed_UP
.globl 	pressed_DOWN
.globl 	pressed_LEFT
.globl 	pressed_RIGHT
.globl 	pressed_A
.globl 	pressed_X
.globl 	pressed_L
.globl 	pressed_R
.globl 	Determine_Button
*/

.globl 		Read_SNES
.globl 		Init_GPIO
.globl 		Wait
.globl 		divide

.section    .init
.globl    	_startDriver


_startDriver:
    b       StartDriver
.section 	.text

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         StrLength         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
strLength:
		push 	{lr} 													// Pushing link register
		add		r2, r0, #1 												// r2 = r0 + 1

strLength_loop:
		ldrb 	r1, [r0], #1 											// Load single byte from r0 into r1, and incrementing it

		cmp 	r1, #0 													// Check for null terminator
		bne 	strLength_loop 											// Loop back to top if not equal

		sub 	r0, r2 													// r0 = r0 - r2
		pop 	{pc} 													// Popping program counter

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         Divide         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
divide:
//Numerator in r0, denominator in r1
		push 	{r4,lr} 												// Pushing link register
		mov 	r4, #0 													// Initialize r4 = counter
modulo:
		mov 	r2, #0 													// Initialize r2 = quotient
		mov 	r3, #0 													// Initialize r3 = remainder

modulo_loop:
		cmp 	r0, r1 													// num < denom
		blt 	modulo_done 											// if true, done

		add 	r2, #1 													// quotient++
		sub 	r0, r1 													// numerator = numerator - denominator

		b 		modulo_loop 											// Loop

modulo_done:
		mov 	r0, r0													// Copy remainder into r0
		mov 	r1, r2 													// Copy quotient into r1
		pop 	{r4,pc} 												// Popping program counter


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         START         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
StartDriver:
    	mov     sp, #0x8000 											// Initializing the stack pointer
		bl		EnableJTAG 												// Enable JTAG


		// NEED TO INITIALIZE PINS 9 out, 10 in, 11 out
		mov 	r0, #9 													// r0 = pin#
		mov 	r1, #0b001 												// Output
		bl 		Init_GPIO 												// Initialize pin

		mov 	r0, #10 												// r0 = pin#
		mov 	r1, #0b000 												// Input
		bl 		Init_GPIO 												// Initialize pin

		mov 	r0, #11 												// r0 = pin#
		mov 	r1, #0b001 												// Output
		bl 		Init_GPIO 												// Initialize pin

		b 		Determine_Button 											// Branching to where printing happens

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       Init_GPIO       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//Initializes a GPIO line, the line number and function code must be passed as parameters (r0-pin#, r1-function ex#0b001)
Init_GPIO:
		push 	{r4-r8, lr} 													// Pushing link register

		mov 	r5, r0 													// Saving r0
		mov 	r6, r1
		//Need to put function bits in r3 corresponding to pin#

		mov 	r1, #10 												// denom = 10
		bl 		divide 													// remainder of pin#/10 in r0
 		mov 	r3, r0 													// Copy remainder
 		mov 	r2, r1 													// Copy quotient

		mov 	r1, #3 													// r1 = 3
		mul 	r3, r1 													// r3 = ((remainder of pin#)/10)*3

		// r0 = pin# passed in
		lsl 	r0, r2, #2 												// r0 = pin/10 *4

		ldr 	r1, =0x20200000 										// Address of GPFSET0
		add 	r1, r0													// r1 = base address + offset
		ldr 	r2, [r1]												// To read GPFSET0:

		mov 	r0, #0b111 												// r0 = 111
		bic 	r2, r0, lsl r3 											// Clear bits for function code

		orr 	r2, r6, lsl r3 											// Setting function code for the pin
		str 	r2, [r1]

		pop 	{r4-r8, pc} 													// Popping program counter

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     Reading and Writing      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Write_Latch:
		push 	{lr} 													// Pushing link register

		// r0 = value to write {0,1}
		mov 	r1, r0
		mov 	r0, #9 													// r0 = #9, pin#9 = LATCH line
		ldr 	r2, =0x20200000 										// base GPIO reg
		mov 	r3, #1
		lsl 	r3, r0 													// align bit for pin#9

		teq 	r1, #0
		streq 	r3, [r2, #40] 											// GPCLR0
		strne 	r3, [r2, #28] 											// GPSET0
		pop 	{pc} 													// Popping program counter

Write_Clock:
		push 	{lr} 													// Pushing link register

		// r0 = value to write {0,1}
		mov 	r1, r0
		mov 	r0, #11 												// r0 = #9, pin#9 = LATCH line
		ldr 	r2, =0x20200000 										// address for GPFSEL1
		mov 	r3, #1
		lsl 	r3, r0 													// align bit for pin#9

		teq 	r1, #0
		streq 	r3, [r2, #40] 											// GPCLR0
		strne 	r3, [r2, #28] 											// GPSET0
		pop 	{pc} 													// Popping program counter

Read_Data:
		push 	{r4-r12, lr}											// Saving contents of registers
		
		mov 	r0, #10 												// r0 = #10, pin#10 = DATA line
		ldr 	r2, =0x20200000 										// Base GPIO reg
		ldr 	r1, [r2, #52] 											// GPLEV0
		mov 	r3, #1
		lsl 	r3, r0 													// Align pin10 bit
		and 	r1, r3 													// Mask everything else
		teq 	r1, #0
		moveq	r7, #0 													// Return 0
		movne 	r7, #1 													// Return 1
		mov 	r0, r7 													// Return value in r0 = r4

		pop 	{r4-r12, pc}											// Getting original contents of those registers												// Popping program counter

Wait:
		push 	{lr} 													// Pushing link register
		mov 	r3, r0 													// x microseconds in r3

		ldr 	r0, =0x20003004 										// Address of CLO
		ldr 	r1, [r0] 												// Read CLO
		add 	r1, r3 													// Add x micros

waitLoop:
		ldr 	r2, [r0] 												// Read CLO
		cmp 	r1, r2 													// Stop when CLO = r1
		bhi 	waitLoop 												// Loop

waitLoopDone:
		pop 	{pc} 													// Popping program counter

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      Read_SNES       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Read_SNES:
		push 	{lr, r4-r8} 													// Pushing link register

		mov 	r4, #0 													// r4 = Buttons array
		
		// Write_Clock(1)
		mov 	r0, #1 													// r0 is param passed in
		bl 		Write_Clock 											// Go to Write_Clock

		// Write_Latch(1)
		mov 	r0, #1 													// r0 is param passed in
		bl 		Write_Latch 											// Go to Write_Latch

		// Wait(12)
		mov 	r0, #12 												// r0 is param passed in
		bl 		Wait 													// Wait

		// Write_Latch(0)
		mov 	r0, #0 													// r0 is param passed in
		bl 		Write_Latch 											// Go to Write_Latch

		mov 	r5, #0 													// i=0

pulseLoop:
		// Wait(6)
		mov 	r0, #6													// r0 is param passed in
		bl 		Wait 													// Wait

		// Write_Clock(0)
		mov 	r0, #0 													// r0 is param passed in
		bl 		Write_Clock 											// Go to Write_Clock

		// Wait(6)
		mov 	r0, #6 													// r0 is param passed in
		bl 		Wait 													// Wait

		// Read_Data, return b={1,0} in r0
		bl 		Read_Data 												// b={1,0} in r0

		lsl 	r0, r5 													// Shifting the bit by the counter to add the value to buttons array
		orr 	r4, r0 													// r4 = r0 or r4

		// Write_Clock(1)
		mov 	r0, #1 													// r0 is param passed in
		bl 		Write_Clock 											// Go to Write_Clock

		add 	r5, #1 													// inc counter i
		cmp 	r5, #16 												// Is i < 16?
		blt	 	pulseLoop 												// If yes, then loop

		mov 	r0, r4 													// Return the buttons array

		pop 	{r4-r8, pc} 													// Popping program counter

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   Determine Button Pressed   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/**
 * Takes in an array of buttons (passed in by r0)
 *
 * Returns a number in r0 that corresponds to which button was pressed:
 *		0 = B
 *		1 = Y
 *		2 = Select
 *		3 = Start
 *		4 = Up
 *		5 = Down
 *		6 = Left
 *		7 = Right
 *		8 = A
 *		9 = X
 *		10 = L
 *		11 = R
 */
Determine_Button:
		// Delay for if button is HELD 								
		ldr 	r0, =0xff00 											// WAIT TIME FOR WHEN BUTTON IS HELD
		bl 		Wait 													// Wait

		bl 		Read_SNES												// Branch to reading SNES
		
		// r0 = all the bits for the buttons

		// Was B pressed?
		mov 	r2, #1 													// To read  button
		and 	r3, r2, r0 												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_B 												// If yes, print button

		// Was Y pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0 												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_Y 												// If yes, print button

		// Was SELECT pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0 												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_SELECT											// If yes, print button

		// Was START pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0 												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?	
		beq 	pressed_START											// If yes, print button

		// Was UP pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0 												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_UP 												// If yes, print button

		// Was DOWN pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_DOWN 											// If yes, print button

		// Was LEFT pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_LEFT 											// If yes, print button

		// Was RIGHT pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_RIGHT											// If yes, print button

		// Was A pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_A 												// If yes, print button

		// Was X pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0 												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_X 												// If yes, print button

		// Was L pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0 												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?

		beq 	pressed_L 												// If yes, print button

		// Was R pressed?
		lsl 	r2, #1 													// Shift to read next button
		and 	r3, r2, r0 												// Checking if corresponding button was pressed
		cmp 	r3, #0 													// Was button pressed?
		beq 	pressed_R 												// If yes, print button

		b 		Determine_Button											// Keep reading

// Now do stuff with the button
pressed_B:
		mov 	r0, #0
		b 		Determine_Button 											// Prompt again

pressed_Y:
		mov 	r0, #1
		b 		Determine_Button 											// Prompt again

pressed_SELECT:
		mov 	r0, #2
		b 		Determine_Button 											// Prompt again

pressed_START:
		mov 	r0, #3
		b 		Determine_Button 											// Prompt again

pressed_UP:
		mov 	r0, #4
		b 		Determine_Button 											// Prompt again

pressed_DOWN:
		mov 	r0, #5
		b 		Determine_Button 											// Prompt again

pressed_LEFT:
		mov 	r0, #6
		b 		Determine_Button 											// Prompt again

pressed_RIGHT:
		mov 	r0, #7
		b 		Determine_Button 											// Prompt again

pressed_A:
		mov 	r0, #8
		b 		Determine_Button 											// Prompt again

pressed_X:
		mov 	r0, #9
		b 		Determine_Button 											// Prompt again

pressed_L:
		mov 	r0, #10
		b 		Determine_Button 											// Prompt again

pressed_R:
		mov 	r0, #11
		b 		Determine_Button 											// Prompt again

.section 		.data
