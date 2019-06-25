# LCD API Routines
# Yahui Liang
# Date: 10/10/2016

.syntax unified

.section .text

	.equ GPIOB_BASE, 0x40020400
	.equ GPIOC_BASE, 0x40020800
	.equ MODER_OFFSET, 0x0
	.equ IDR_OFFSET, 0x10
	.equ ODR_OFFSET, 0x14
	.equ BSRR_OFFSET, 0x18

	.equ RCC_BASE, 0x40023800
	.equ AHB1ENR_OFFSET, 0x30
	.equ GPIOB_EN, 0b10
	.equ GPIOC_EN, 0b100

	# lcd pins - for BSRR use
	.equ LCD_E_SET,  0b100
	.equ LCD_RW_SET, 0b010
	.equ LCD_RS_SET, 0b001

	.equ LCD_E_CLR,  LCD_E_SET << 16
	.equ LCD_RW_CLR, LCD_RW_SET << 16
	.equ LCD_RS_CLR, LCD_RS_SET << 16

	.equ CLEAR_DATA_NIBBLE, 0x0F00 << 16

# lcd_init - set up all GPIO pins, reset, and init display
# to 4-bit mode

	.global lcd_init
lcd_init:
	push {r4-r5,lr}

	movw r1, #5000	// power-on delay
	bl microseconds_delay

	# enable GPIOB and GPIOC
	ldr r4,=RCC_BASE
	ldr r5,[r4,#AHB1ENR_OFFSET]
	orr r5,r5,#(GPIOB_EN|GPIOC_EN)
	str r5,[r4,#AHB1ENR_OFFSET]

	# set PB0-2 to output
	ldr r4,=GPIOB_BASE
	ldr r5,[r4,#MODER_OFFSET]

	# clear low 6 bits
	bfc r5, #0, #6
	# set 010101
	orr r5, r5, 0b010101
	str r5,[r4,#MODER_OFFSET]

	# set PC8-11 to output
	ldr r4,=GPIOC_BASE
	ldr r5,[r4,#MODER_OFFSET]

	# clear bits 16-23
	bfc r5, #16, #8
	# set 01010101 in high byte
	orr r5, r5, 0x550000
	str r5,[r4,#MODER_OFFSET]

	# ports are setup, ready to init display
	mov r0, #0x30  // 8-bit mode
	bl lcd_cmd

	mov r0, #0x28  // 4-bit mode
	bl lcd_cmd
	mov r0, #0x01	// clear
	bl lcd_cmd
	movw r1, #1500	// clear needs extra time
	bl microseconds_delay
	mov r0, #0x02	// home
	bl lcd_cmd
	bl microseconds_delay	// home needs extra time
	mov r0, #0x06	// Entry mode, move right, no shift
	bl lcd_cmd
	mov r0, #0x0C	// Display on, no cursor
	bl lcd_cmd

	pop {r4-r5,pc}


# command byte comes in LSB of R0
lcd_cmd:
	# stack
	push {r0,r4-r5,lr}

	# make sure rw and rs are low
	ldr r4,=GPIOB_BASE
	mov r5, #(LCD_RW_CLR|LCD_RS_CLR)
	str r5,[r4, #BSRR_OFFSET]

	bl lcd_exec

	# return
	pop {r0,r4-r5,pc}


# data byte comes in LSB of R0
	.global lcd_data
lcd_data:
	# stack
	push {r4-r5,lr}

	# make sure rw is low, and rs is high, bring E high
	ldr r4,=GPIOB_BASE
	mov r5,#0
	orr r5, r5, #LCD_RW_CLR
	orr r5, r5, #LCD_RS_SET
	str r5,[r4, #BSRR_OFFSET]

	bl lcd_exec

	# return
	pop {r4-r5,pc}


# command or data byte comes in LSB of R0
# only called from lcd_cmd or lcd_data - need GPIOB_BASE
# to be in r4, can overwrite r5
lcd_exec:
	# stack
	push {r1,r6-r7,lr}

	# need to use GPIOC
	ldr r6,=GPIOC_BASE

	# place upper nibble of command/data byte on output
	bl lcd_set_upper_nibble

	bl lcd_latch

	# place lower nibble of command/data byte on output.
	bl lcd_set_lower_nibble

	bl lcd_latch

	mov r1, #40	// delay 40 uS
	bl microseconds_delay

	# return
	pop {r1,r6-r7,pc}

lcd_set_upper_nibble:
	push {r1-r3,lr}

 	# place upper nibble of command/data byte on output
	# port pins (PC8-11)
	ldr r1,=GPIOC_BASE
	ldr r2,[r1,ODR_OFFSET]
	mov r2,#0
	bic r3,r0,#0x0f
	lsl r3,r3,#4
	orr r2,r2,r3
	str r2,[r1,ODR_OFFSET]

	pop {r1-r3,pc}

lcd_set_lower_nibble:
	push {r1-r3,lr}

	# place lower nibble of command/data byte on output
	# port pins (PC8-11)
	ldr r1,=GPIOC_BASE
	ldr r2,[r1,ODR_OFFSET]
	mov r2,#0
	bic r3,r0,#0xf0
	lsl r3,r3,#8
	orr r2,r2,r3
	str r2,[r1,ODR_OFFSET]

	pop {r1-r3,pc}

	
lcd_latch:
	push {lr}

	# bring E high
	mov r5, #LCD_E_SET
	str r5, [r4, #BSRR_OFFSET]

	mov r1, #1	// about 1 us
	bl microseconds_delay

	# bring E low to latch
	mov r5, #LCD_E_CLR
	str r5, [r4, #BSRR_OFFSET]

	bl microseconds_delay	// about 1 us

	pop {pc}


	.global microseconds_delay
# about r1 mircoseonds
microseconds_delay:
	# stack
	push {r1,lr}

	lsl r1, r1, #3

1:
	subs r1, r1, #1
	bne 1b

	# return
	pop {r1,pc}

	.global lcd_clear
# The subroutine will clear the content on the screen.
lcd_clear:
	push {r0-r1,lr}

	# The instruction for clear display is 0000000001.
	mov r0,#0x1
	bl lcd_cmd
	# delay for 1.52ms
	movw r1,#0x05f0
	bl microseconds_delay

	pop {r0-r1,pc}


	.global lcd_home
# The subroutine moves the cursor to the original position.
lcd_home:
	push {r0-r1,lr}

	# The instruction for return home is 0000000010
	mov r0,#0x2
	bl lcd_cmd
	# delay for 1.52ms
	movw r1,#0x05f0
	bl microseconds_delay

	pop {r0-r1,pc}


	.global lcd_set_position
# The subroutine moves the cursor to a specific position.
# Parameter:
# r0: the zero based row
# r1: the zero based column
lcd_set_position:
	push {r2,lr}

	# let the cursor starts from the original point.
	bl lcd_home
	# use r2 to store the column temporarily.
	mov r2,r1
	# determine if it is the first row or the second row.
	cmp r0,#0
	beq no_change_line
	# the second line starts from 41st digit.
	add r2,r2,#40

no_change_line:
	# determine if necessary to move the cursor.
	cmp r2,#0
	beq not_move_cursor

	# the command for shifting the cursor is 0000010100.
1:
	mov r0,#0b10100
 	bl lcd_cmd
 	# delay for 37 microseconds.
	mov r1,#37
	bl microseconds_delay
	subs r2,r2,#1
	bne 1b

not_move_cursor:
	pop {r2,pc}


	.global lcd_print_num
# The subroutines displays a value.
# Parameter:
# r0: the number to be printed.
lcd_print_num:
	push {r0-r3,r12,lr}

	# determine if the number is out of range.
	movw r1,0x270f
	cmp r0,r1
	# print "Err" if the number is out of range.
	bhi print_error
	# print number if it is valid.
	bls print

print_error:
	mov r0,'E'
	bl lcd_data
	mov r0,'r'
	bl lcd_data
	mov r0,'r'
	bl lcd_data
	b end

print:
	bl num_to_ASCII
	# Now, r1 stores the number in ASCII format.
	mov r0,r1
	# remove head zeros for ASCII number.
	bl remove_zeros_for_ASCIIs
	# r2 holds the ascii value without head zeros.
	mov r2,r0
	# determine if r2 holds 0.
	cmp r2,#0
	beq print_zero

	bl determine_num_zeros

	# r1 holds the number of zero bit that the ascii value has now.
	# calc num of bits need to be shifted to the left.
	mov r0,#32
	sub r1,r0,r1

	# read one digit each iteration.
1:
	sub r1,r1,#8
	mov r3,#0
	lsr r3,r2,r1
	# clear useless bits.
	bic r3,r3,0xFFFFFF00
	mov r0,r3
	bl lcd_data
	cmp r1,#0
	bne 1b
	b end

print_zero:
	mov r0,'0'
	bl lcd_data

end:
	pop {r0-r3,r12,pc}


# The subroutine determines how many zeros in the top of the register.
# Parameter:
# r0: the number you want to check (ASCII value without head zeros).
# Return:
# r1: the number of bits
determine_num_zeros:
	push {r2-r3,lr}

	# set 31 bit in r2 in order to determine if the
	# non-zero digit has reached.
	movw r2,#0x0000
	movt r2,#0x1000

	mov r3,#0
1:	lsl r1,r0,r3
	cmp r1,r2
	# brach if the non-zero digit has reached.
	bhi exit_loop
	# goes to next byte.
	add r3,r3,#8
	b 1b

exit_loop:
	mov r1,r3

	pop {r2-r3,pc}


	.global remove_zeros_for_ASCIIs
# The subroutine removes useless zeros('\x30') for the 4-digit ASCII number.
# Parameter:
# r0: the ascii number with head zeros.
# Return:
# r0: the ascii number without head zeros.
remove_zeros_for_ASCIIs:
	push {r1-r3,lr}

	mov r1,#0
1:	lsl r2,r0,r1
	mov r3,r2
	bic r2,r2,#0x00FFFFFF
	# determine if the ASCII digit is zero.
	cmp r2,#0x30000000
	beq remove_zero
	b 1f

	# remove ASCII zero.
remove_zero:
	bic r3,r3,0xFF000000
	lsr r0,r3,r1
	# update condition for loading next ASCII digit.
	add r1,r1,#8
	b 1b

1:
	pop {r1-r3,pc}


	.global lcd_print_string
# The subroutine prints a null terminated string
# to the display.
# Parameter:
# r0: the address of the string you want to display.
lcd_print_string:
	push {r1-r5,r12,lr}

	# temporarily stores the address.
	mov r12,r0
	# used for storing the number of characters.
	mov r5,#0
	# set up the offset.
	mov r4,#0

ld_next_mul_4_address:
	ldr r3,[r12,r4]
	cmp r3,#0
	# set the number of bits that need to shift to the left
	# in order to get one character.
	mov r2,#0

1:
	lsr r1,r3,r2
	# clear bits for the character which is being displayed.
	bic r1,r1,#0xFFFFFF00
	cmp r1,#0
	beq finish_displaying_string

	mov r0,r1
	bl lcd_data

	# record one character after it is displayed.
	add r5,r5,#1

	# determine if the string is read completely,
	# then go to next mul-4 address
	cmp r2,#24
	beq 1f

	# update condition in order to read next character.
	add r2,#8
	b 1b

1:
	add r4,r4,#4
	b ld_next_mul_4_address

finish_displaying_string:
	mov r0,r5

	pop {r1-r5,r12,pc}

# Convert num into ASCII format.
# Parameter:
# R0: the integer that you want to convert into ASCII format.
# Return:
# R1: the number in the ASCII format.
num_to_ASCII:
	PUSH {R2-R5,LR}

	MOV R1,R0
	MOV R3,#0
	MOV R4,#0
	MOV R5,#0
	BL num_to_BCD
	# Now, R0 stores the number in BCD format
	# initialize the first four bits of an ASCII letter.
1:
	# Get one BCD digit(start from the unit digit)
	LSR R1,R0,R3
	BIC R2,R1,#0xFF00
	BIC R2,R2,#0x00F0
	# Form ASCII letter for one BCD digit
	ADDS R2,R2,0x30
	LSL R2,R2,R4
	ADDS R5,R5,R2
	# Update the shift bit in order to get the next BCD digit.
	ADDS R3,R3,#4
	ADDS R4,R4,#8
	CMP R3,#16
	BNE 1b
	MOV R1,R5

	POP {R2-R5,PC}


# Convert a number into BCD.
# Parameter:
# R1: the number you want to convert.
# Return:
# R0: The number in BCD.
num_to_BCD:
	PUSH {R2-R5,LR}
	# For recording the number of rotations.
	MOV R4,#0
	MOV R5,#0
1:
	# Set the divisor to be 10
	MOV R2,#10
	BL divide_with_remainder
	# Reset the quotient because we need repeat the loop until the quotient becomes zero.
	MOV R1,R3
	# Move one BCD digit into a register.
	MOV R12,R0
	LSL R12,R12,R4
	ADDS R4,R4,#4
	# R5 is used for saving result temporarily
	ADDS R5,R5,R12
	CMP R1,#0
	BNE 1b
	MOV R0,R5
	POP {R2-R5,PC}


# The algorithm for finding the remainder.
# Parameter:
# R1: Divident
# R2: Divisor
# Return:
# R0: Remainder
# R3: Quotient
divide_with_remainder:
	PUSH {LR}
	MOV R0,#0
	MOV R3,#0

1:
	# If the divident is smaller than the divisor,
	# the quotient should be zero(We shoud skip the first loop),
	# and the remainder is the divident itself.
	CMP R1,R2
	MOV R0,R1
	BLT 1f

	ADDS R3,R3,#1
	SUB R1,R1,R2
	MOV R0,R1
	CMP R1,R2
	BGE 1b
1:
	POP {PC}


