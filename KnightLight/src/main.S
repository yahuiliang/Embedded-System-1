	.syntax unified
	.cpu cortex-m4
	.thumb
	.section .text

	.global main

	.equ RCC_AHB1ENR,0x40023830
	.equ GPIOA_BASE,0x40020000
	.equ GPIO_MODER_OFFSET,0x00
	.equ GPIO_ODR_OFFSET,0x14
	.equ GPIO_BSRR_OFFSET,0x18
	.equ GPIOB_BASE,0x40020400

main:
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


begin:

	# Get GPIOA address
	MOVW R1, #0x0000
	MOVT R1, #0x4002

	LDR R2,[R1,#0x14]


	# Set num of loops
	MOVW R3,#0x0005
	MOVT R3,#0x0000

	# Start set bits from bit 7
	MOVW R4,#0x0080
	MOVT R4,#0x0000

	# Start the loop
	nextLightForFirstFive:

	# Turn the LED on
	ORR R2,R2,R4
	STR R2,[R1,#0x14]

	# Cause the delay
	MOVW R5, #0x0000
	MOVT R5, #0x0020

	1:
	SUBS R5,R5,#1
	BNE 1b

	# Turn the LED off
	LDR R2,[R1,#0x14]
	BIC R2,R2,R4
	STR R2,[R1,#0x14]

	# Update conditions
	# Set next bit to one
	ADDS R4,R4,R4

	SUBS R3,R3,#1
	BNE nextLightForFirstFive

	# Get GPIOB address
	MOVW R1, #0x0400
	MOVT R1, #0x4002

	LDR R2,[R1,#0x14]

	# Set num of loops again
	MOVW R3,#0x0003
	MOVT R3,#0x0000

	# Start set bits from bit 8
	MOVW R4,#0x0100
	MOVT R4,#0x0000

	nextLightForMiddleThree:

	# Turn the LED on
	ORR R2,R2,R4
	STR R2,[R1,#0x14]

	# Cause the delay
	MOVW R5, #0x0000
	MOVT R5, #0x0020

	1:
	SUBS R5,R5,#1
	BNE 1b

	# Turn the LED off
	LDR R2,[R1,#0x14]
	BIC R2,R2,R4
	STR R2,[R1,#0x14]

	# Update conditions
	# Set next bit to one
	ADDS R4,R4,R4

	SUBS R3,R3,#1
	BNE nextLightForMiddleThree

	# Get GPIOB address
	MOVW R1, #0x0400
	MOVT R1, #0x4002

	LDR R2,[R1,#0x14]

	# Set num of loops again
	MOVW R3,#0x0002
	MOVT R3,#0x0000

	# Start set bits from bit 12
	MOVW R4,#0x1000
	MOVT R4,#0x0000

	nextLightForLastTwo:

	# Turn the LED on
	ORR R2,R2,R4
	STR R2,[R1,#0x14]

	# Cause the delay
	MOVW R5, #0x0000
	MOVT R5, #0x0020

	1:
	SUBS R5,R5,#1
	BNE 1b

	# Turn the LED off
	LDR R2,[R1,#0x14]
	BIC R2,R2,R4
	STR R2,[R1,#0x14]

	# Update conditions
	# Set next bit to one
	ADDS R4,R4,R4

	SUBS R3,R3,#1
	BNE nextLightForLastTwo



	# Set a constant 2
	MOVW R6,#0x0002
	MOVT R6,#0x0000



	# The light goes back from here
	# Get GPIOB address
	MOVW R1, #0x0400
	MOVT R1, #0x4002

	LDR R2,[R1,#0x14]

	# Set num of loops again
	MOVW R3,#0x0002
	MOVT R3,#0x0000

	# Start set bits from bit 12
	MOVW R4,#0x1000
	MOVT R4,#0x0000

	# Turn the LED on
	ORR R2,R2,R4
	STR R2,[R1,#0x14]

	# Cause the delay
	MOVW R5, #0x0000
	MOVT R5, #0x0020

	1:
	SUBS R5,R5,#1
	BNE 1b

	# Turn the LED off
	LDR R2,[R1,#0x14]
	BIC R2,R2,R4
	STR R2,[R1,#0x14]



	# Get GPIOB address
	MOVW R1, #0x0400
	MOVT R1, #0x4002

	LDR R2,[R1,#0x14]

	# Set num of loops again
	MOVW R3,#0x0003
	MOVT R3,#0x0000

	# Start set bits from bit 10
	MOVW R4,#0x0400
	MOVT R4,#0x0000

	nextLightForMiddleThreeBack:
	# Turn the LED on
	ORR R2,R2,R4
	STR R2,[R1,#0x14]

	# Cause the delay
	MOVW R5, #0x0000
	MOVT R5, #0x0020

	1:
	SUBS R5,R5,#1
	BNE 1b

	# Turn the LED off
	LDR R2,[R1,#0x14]
	BIC R2,R2,R4
	STR R2,[R1,#0x14]

	# Update conditions
	# Set next bit to one

	UDIV R4,R4,R6

	SUBS R3,R3,#1
	BNE nextLightForMiddleThreeBack



	# Get GPIOA address
	MOVW R1, #0x0000
	MOVT R1, #0x4002

	LDR R2,[R1,#0x14]

	# Set num of loops
	MOVW R3,#0x0004
	MOVT R3,#0x0000

	# Start set bits from bit 11
	MOVW R4,#0x0800
	MOVT R4,#0x0000

	nextLightForFirstFiveBack:

	# Turn the LED on
	ORR R2,R2,R4
	STR R2,[R1,#0x14]

	# Cause the delay
	MOVW R5, #0x0000
	MOVT R5, #0x0020

	1:
	SUBS R5,R5,#1
	BNE 1b

	# Turn the LED off
	LDR R2,[R1,#0x14]
	BIC R2,R2,R4
	STR R2,[R1,#0x14]

	# Update conditions
	# Set next bit to one
	UDIV R4,R4,R6

	SUBS R3,R3,#1
	BNE nextLightForFirstFiveBack

	B main



