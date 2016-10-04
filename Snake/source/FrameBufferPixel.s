.section .data
.align 4

.globl FrameBufferInfo
FrameBufferInfo:
    .int    1024    // 0 - Width
    .int    768     // 4 - Height
    .int    1024    // 8 - vWidth
    .int    768   	// 12 - vHeight
    .int    0       // 16 - GPU - Pitch
    .int    16      // 20 - Bit Depth
    .int    0       // 24 - X
    .int    0       // 28 - Y
    .int    0       // 32 - GPU - Pointer
    .int    0       // 36 - GPU - Size

	
.align 2
.globl FrameBufferPointer
FrameBufferPointer:
	.int	0

.section .text

/* Initialize the Frame Buffer
 * Return:
 *  r0 - result
 */
.globl InitFrameBuffer
InitFrameBuffer:
    infoAdr .req r4
    push    {r4, lr}
    ldr     infoAdr, =FrameBufferInfo       // get framebuffer info address
    
	result  .req r0

    mov     r0, infoAdr                     // store fb info address as mail message
	add		r0,	#0x40000000					// set bit 30; tell GPU not to cache changes
    mov     r1, #1                          // mailbox channel 1
    bl      MailboxWrite                    // write message
    
    mov     r0, #1                          // mailbox channel 1
    bl      MailboxRead                     // read message
    
    teq     result, #0
    movne   result, #0
    popne   {r4, pc}                        // return 0 if message from mailbox is 0
    
pointerWait$:
    ldr     result, [infoAdr, #32]
    teq     result, #0
    beq     pointerWait$                    // loop until the pointer is set
	
	ldr		r1,		=FrameBufferPointer
	str		result,	[r1]					// store the framebuffer pointer
    
    mov     result, infoAdr                 // set result to address of fb info struct
    pop     {r4, pc}                        // return
    
    .unreq  result
    .unreq  infoAdr


/* Draw Pixel
 *  r0 - x
 *  r1 - y
 *	r2 - color
 */
.globl DrawPixel
DrawPixel:
    px      .req    r0
    py      .req    r1
	color	.req	r2
    addr    .req    r3

	push	{r4}
    
    ldr     addr,   =FrameBufferInfo
    
    height  .req    r4
    ldr     height, [addr, #4]
    sub     height, #1
    cmp     py,     height
    bhi     DrawPixelEnd$
    .unreq  height
    
    width   .req    r4
    ldr     width,  [addr, #0]
    sub     width,  #1
    cmp     px,     width
    bhi     DrawPixelEnd$

    ldr     addr,   =FrameBufferPointer
	ldr		addr,	[addr]
	
    add     width,  #1
    
    mla     px,     py, width, px       // px = (py * width) + px

    .unreq  width
    .unreq  py
    
    add     addr,   px, lsl #1			// addr += (px * 2) (ie: 16bpp = 2 bytes per pixel)
    .unreq  px
    
    strh    color,  [addr]
    
    .unreq  addr

DrawPixelEnd$:
	pop		{r4}
    bx		lr

    
/* Write to mailbox
 * Args:
 *  r0 - value (4 LSB must be 0)
 *  r1 - channel
 */
.globl MailboxWrite
MailboxWrite:
    tst     r0, #0b1111                     // if lower 4 bits of r0 != 0 (must be a valid message)
    movne   pc, lr                          //  return
    
    cmp     r1, #15                         // if r1 > 15 (must be a valid channel)
    movhi   pc, lr                          //  return
    
    channel .req r1
    value   .req r2
    mov     value, r0
    
    mailbox .req r0
	ldr     mailbox,=0x2000B880
    
wait1$:
    status  .req r3
    ldr     status, [mailbox, #0x18]        // load mailbox status
    
    tst     status, #0x80000000             // test bit 32
    .unreq  status
    bne     wait1$                          // loop while status bit 32 != 0
    
    add     value, channel                  // value += channel
    .unreq  channel
    
    str     value, [mailbox, #0x20]         // store message to write offset
    
    .unreq  value
    .unreq  mailbox
    
    bx		lr


/* Read from mailbox
 * Args:
 *  r0 - channel
 * Return:
 *  r0 - message
 */
.globl MailboxRead
MailboxRead:
    cmp     r0, #15                         // return if invalid channel (> 15)
    movhi   pc, lr
    
    channel .req r1
    mov     channel, r0
    
    mailbox .req r0
	ldr     mailbox,=0x2000B880
    
rightmail$:
wait2$:
    status  .req r2
    ldr     status, [mailbox, #0x18]        // load mailbox status
    
    tst     status, #0x4000000              // test bit 30
    .unreq  status
    bne     wait2$                          // loop while status bit 30 != 0
    
    mail    .req r2
    ldr     mail, [mailbox, #0]             // retrieve message
    
    inchan  .req r3
    and     inchan, mail, #0b1111           // mask out lower 4 bits of message into inchan
    
    teq     inchan, channel
    .unreq  inchan
    bne     rightmail$                      // if not the right channel, loop
    
    .unreq  mailbox
    .unreq  channel
    
    and     r0, mail, #0xfffffff0           // mask out channel from message, store in return (r0)
    .unreq  mail
    
	bx		lr

