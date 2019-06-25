# Keypad
# Yahui Liang
# Date: 10/10/2016

.syntax unified

.section .rodata
# Here are ascii values for buttons.
button1:
	.hword 0x31
button2:
	.hword 0x32
button3:
	.hword 0x33
buttonA:
	.hword 0x41
button4:
	.hword 0x34
button5:
	.hword 0x35
button6:
	.hword 0x36
buttonB:
	.hword 0x42
button7:
	.hword 0x37
button8:
	.hword 0x38
button9:
	.hword 0x39
buttonC:
	.hword 0x43
buttonFlower:
	.hword 0x2A
button0:
	.hword 0x30
buttonNum:
	.hword 0x23
buttonD:
	.hword 0x44

.section .text

	.equ GPIOC_BASE, 0x40020800
	.equ MODER_OFFSET, 0x0
	.equ PUPDR_OFFSET, 0xC
	.equ IDR_OFFSET, 0x10
	.equ ODR_OFFSET, 0x14
	.equ BSRR_OFFSET, 0x18

	.equ RCC_BASE, 0x40023800
	.equ AHB1ENR_OFFSET, 0x30
	.equ GPIOC_EN, 0b100

# The subroutine initializes the clock and the mode for pins from
# PC0-PC7. Also, pull up the voltage from PC4-PC7.
	.global key_init
key_init:
	push {r0-r2,lr}

	# enable the clock.
	ldr r0,=RCC_BASE
	ldr r1,[r0,AHB1ENR_OFFSET]
	orr r1,r1,GPIOC_EN
	str r1,[r0,AHB1ENR_OFFSET]

	# set to output(PC0-PC3).
	ldr r0,=GPIOC_BASE
	ldr r1,[r0,MODER_OFFSET]
	movw r2,#0x55
	orr r1,r1,r2
	movw r2,#0xaa
	bic r1,r1,r2
	str r1,[r0,MODER_OFFSET]

	# initialize PC4-PC7 to voltage high.
	ldr r0,=GPIOC_BASE
	ldr r1,[r0,PUPDR_OFFSET]
	orr r1,r1,(0b01010101 << 8)
	str r1,[r0,PUPDR_OFFSET]

	pop {r0-r2,pc}


# The subroutine gets the key code when the user
# releases the button.
# Returns:
# r0: the numeric code of the key which is pressed.
key_getkey_noblock:
	push {r1-r5,lr}

	# r3 for recording the current column.
	mov r3,#4
	# r4 as the starting value for PC0-PC3.
	mov r4,#0b0111
	# r5 as the starting value for PC4-PC7.
	mov r5,#0b0111

	# the main loop is for cols.
change_to_next_col:
	# r2 for recording the current row.
	mov r2,#4

	ldr r0,=GPIOC_BASE
	ldr r1,[r0,ODR_OFFSET]
	# clear bits first.
	bic r1,r1,0xF
	# set bits for ODR.
	orr r1,r1,r4
	str r1,[r0,ODR_OFFSET]
	# give a delay for stabilize the data.
	mov r1,#2
	bl microseconds_delay

	# the inner loop is for rows.
change_to_next_row:
	ldr r1,[r0,IDR_OFFSET]
	bic r1,r1,0xffffff0f
	lsr r1,r1,#4
	# determine if there is a button pushed in this row.
	cmp r1,r5
	beq generate_num_code

	# update the output.
	ror r5,r5,#1
	bic r12,r5,#0xfffffff0
	bic r5,r5,0x0fffffff
	lsr r5,r5,#28
	add r5,r5,r12

	# loop for 4 times and the jump to next column if there is not a
	# button pushed in this column.
	sub r2,r2,#1
	cmp r2,#0
	beq update_cond_for_next_col
	b change_to_next_row

update_cond_for_next_col:
	# update the condition.
	ror r4,r4,#1
	bic r12,r4,#0xfffffff0
	bic r4,r4,0x0fffffff
	lsr r4,r4,#28
	add r4,r4,r12

	sub r3,r3,#1
	cmp r3,#0
	bne change_to_next_col

	# generate the number code.
generate_num_code:
	# determine if there is not any button pushed.
	cmp r3,#0
	beq 1f
	# calculate the number code.
	sub r2,r2,#1
	mov r1,#4
	mul r0,r2,r1
	# now, r0 stores the number code.
	add r0,r0,r3
	b 2f
1:
	# handle the situition if none of the button pushed.
	mov r0,#0
2:
	# return after the key has released.
	ldr r2,=GPIOC_BASE
key_not_released:
	ldr r1,[r2,IDR_OFFSET]
	bic r1,r1,0xffffff0f
	lsr r1,r1,#4
	cmp r1,#0b1111
	bne key_not_released

	pop {r1-r5,pc}


# The subroutine waits for the user presses the button,
# and return the numeric code back.
# Returns:
# r0: the numeric code of the key pressed.
key_getkey:
	push {lr}
1:
	bl key_getkey_noblock
	cmp r0,#0
	beq 1b

	pop {pc}


# The subroutine can determine which key is pressed
# and returns the ASCII value corresponding to that key.
# Returns:
# r0: the ASCII value of the key pressed.
	.global key_getchar
key_getchar:
	push {r1-r3,lr}

	bl key_getkey
	mov r1,#1
	ldr r2,=button1
	mov r3,#0

1:
	cmp r0,r1
	beq 1f
	add r1,r1,#1
	# stored each ascii value as a half word.
	# find out the offset for the specific word.
	add r3,r3,#2
	b 1b

	# load for that character.
1:
	ldrh r1,[r2,r3]
	mov r0,r1

	pop {r1-r3,pc}

