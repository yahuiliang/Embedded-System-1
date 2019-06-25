# Subroutines
# Name: Yahui Liang
# Date: 10/03/2016

	.syntax unified
	.section .text

	# Symbolic names
	.equ RCC_AHB1ENR,0x40023830
	.equ GPIOA_BASE,0x40020000
	.equ GPIO_MODER_OFFSET,0x00
	.equ GPIO_ODR_OFFSET,0x14
	.equ GPIO_BSRR_OFFSET,0x18
	.equ GPIOB_BASE,0x40020400

	.global num_to_ASCII
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


# The subroutine will display the number that R0 contains to LEDS.
# Parameter:
# R0: the number you want to display
num_to_LED:
	PUSH {R1,R2,R3,LR}

	# Get the GPIOA base address.
	MOVW R1,#(GPIOA_BASE & 0xFFFF)
	MOVT R1,#(GPIOA_BASE >> 16)
	#Set bits to turn the LED on.
	LDR R2,[R1,GPIO_ODR_OFFSET]
	BIC R2,R2,#0xFFFFFFFF
	# Save the least 10 bits.
	BIC R0,R0,#0xFF000000
	BIC R0,R0,#0x00FF0000
	BIC R0,R0,#0x0000FC00
	# Keep the last 5 bits for the first 5 LEDS.
	BIC R3,R0,#0x0FE0
	# Set the first five LEDS.
	LSL R3,R3,#7
	ORR R2,R2,R3
	STR R2,[R1,GPIO_ODR_OFFSET]

	# The part above has set the first five LEDS.

	# Now we set middle three LEDS.
	MOVW R1,#(GPIOB_BASE & 0xFFFF)
	MOVT R1,#(GPIOB_BASE >> 16)
	LDR R2,[R1,GPIO_ODR_OFFSET]
	BIC R3,R0,#0xFF00
	BIC R3,R0,#0x001F
	LSL R3,R3,#3
	ORR R2,R2,R3
	STR R2,[R1,GPIO_ODR_OFFSET]

	# Set the last two LEDS.
	LDR R2,[R1,GPIO_ODR_OFFSET]
	BIC R3,R0,#0xFC00
	BIC R3,R0,#0x00FF
	LSL R3,R3,#4
	ORR R2,R2,R3
	STR R2,[R1,GPIO_ODR_OFFSET]

	POP {R1,R2,R3,PC}


# The subroutine causes the delay in milliseconds.
# Parameter:
# R0: The millisecond that you want to delay.
delay_ms:
	PUSH {R1,LR}

	# Calculate num of loops.
	# Convert R0 to nanoseconds.
	MOVW R1,#0x4240
	MOVT R1,#0xF
	MUL R0,R0,R1
	# Get the number of iterations.
	MOV R1,#190
	UDIV R0,R0,R1
	# Loop causes the delay
1:
	SUBS R0,R0,#1
	BNE 1b

	POP {R1,PC}


# The subroutine initializes GPIO port pins to be outputs.
num_to_LED_init:
	PUSH {R1,R2,LR}

	# Enable clocks for GPIOA and GPIOB
	MOVW R1,#(RCC_AHB1ENR & 0xFFFF)
	MOVT R1,#(RCC_AHB1ENR >> 16)
	LDR R2,=RCC_AHB1ENR

	# Enable both clocks
	ORR R2,R2,#0x03
	STR R2,[R1]

	# Set GPIOA and GPIOB
	# Set GPIOA
	MOVW R1,#(GPIOA_BASE & 0xFFFF)
	MOVT R1,#(GPIOA_BASE >> 16)

	# Enable the output
	LDR R2,[R1,GPIO_MODER_OFFSET]
	ORR R2,R2,#0x4000
	ORR R2,R2,#0x550000
	BIC R2,R2,#0x8000
	BIC R2,R2,#0xAA0000
	STR R2,[R1,GPIO_MODER_OFFSET]

	# Set GPIOB
	MOVW R1,#(GPIOB_BASE & 0xFFFF)
	MOVT R1,#(GPIOB_BASE >> 16)

	# Enable the output
	LDR R2,[R1,GPIO_MODER_OFFSET]
	ORR R2,R2,#0x150000
	ORR R2,R2,#0x5000000
	BIC R2,R2,#0x2A0000
	BIC R2,R2,#0xA000000
	STR R2,[R1,GPIO_MODER_OFFSET]

	POP {R1,R2,PC}


