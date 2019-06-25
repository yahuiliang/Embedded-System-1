# Blinky LED - the embedded version of "Hello World"
# ...not the best way - just a way

  	# some assembler directives which may or may not be needed
	.syntax unified
	.cpu cortex-m4
	.thumb
	.section .text

 	# need to expose the label "main" to linker
	.global main

# the start of our program
main:
	# TODO List:
	# Enable clock for GPIOA
	# Configure GPIOA pin for output
	# Begin Loop
	#   Turn LED on
	#   Delay
	#   Turn LED off
	#   Delay
	#
	# LEDs are on PA7-PA11 and PB8-PB10,PB12-PB13
	# We will just use the single LED on PA7

	# !!!! If you wish to run this on the Nucleo alone,
	# !!!! change to PA5 for the on-board LED.  Look for
	# "!!!!" comments for the changes.

	# RCC's AHB1ENR = 0x40023830
	# GPIOA's MODER = 0x40020000
	# GPIOA's ODR = 0x40020014

	# We need get the address of the I/O registers into a GP
	# register in order to interact with that I/O register.
	#
	# The issue is that the I/O register's address is a 32-bit
	# value, but, we cannot handle a 32-bit immediate since
	# all of our instructions are just 16-bits each and limited
	# in most cases to an immedate value of 8-bits or less.
	#
	# There are various approaches to acheive the desired effect.
	# See:  http://www.keil.com/support/man/docs/armasm/armasm_dom1359731145835.htm
	# Note, MOV will not work with 0x3830..., need MOVW
	MOVW R1, #0x3830
	MOVT R1, #0x4002

	# enable the clock for GPIOA
	# be sure to read-modify-write

	# load AHB1ENR into R2
	LDR R2,[R1]
	# set Bit 0 of R2, and only bit 0
	ORR R2,R2,#0x01
	# store value back to AHB1ENR
	STR R2,[R1]

	# We will now work with GPIOA - get its base address into R1
	MOVW R1, #0x0000
	MOVT R1, #0x4002

	# Set the mode to output, which requires a '01' in the port in PA7's
	# position.  As before, read-modify-write.  Read in GPIOA's MODER
	# register to R2.
	LDR R2,[R1]
	# set bit 14 and ensure bit 15 is clear
	ORR R2,R2,#0x4000
	BIC R2,R2,#0x8000

	# !!!! Comment out the previous two lines and use these for PA5
	# !!!! ORR R2,R2,#0x400
	# !!!! BIC R2,R2,#0x800

	# store value back to MODER
	STR R2,[R1]

	# Now we can write to GPIOA's ODR register to set pins high/low.  We can
	# use an offset with LDR to "reuse" the base address already in R1.
	# For now, we will continue to RMW, but there is a better way...

# label to be able to branch back here
begin:
	# read-modify-write ODR to set bit 7 high
	LDR R2,[R1,#0x14]

	ORR R2,R2,#0x80

	# !!!! Comment out the previous line and use the next line for PA5
	# !!!! ORR R2, R2, #0x20

	STR R2,[R1,#0x14]

	# now a delay..
	#
	# There are much better ways to do this, but for now we will do a simple
	# loop that counts down from some large number.  This keeps the processor
	# busy for awhile, hence the term "busy wait."  The trick is knowing how
	# long the delay will be in real time.  We can estimate the delay
	# by knowing the clock speed of the processor and how many clock cycles
	# each operation takes.  We can also just guess...
	# Based on measurment, the loop here takes about 190 nS per iteration
	# with the default startup code.
	#
	# Cycle counts are documented here:
	# http://infocenter.arm.com/help/topic/com.arm.doc.100166_0001_00_en/ric1417175924567.html
	MOVW R3, #0x0000
	MOVT R3, #0x0020
1:
	SUBS R3,R3,#1
	# branch backward to local label '1' (1b) if not equal (NE) to 0
	BNE 1b

	# read-modify-write ODR to clear bit 7 high
	LDR R2,[R1,#0x14]
	BIC R2,R2,#0x80

	# !!!! Comment out the previous line and use the next line for PA5
	# !!!! BIC R2, R2, #0x20

	STR R2,[R1,#0x14]

	# another delay
	MOVW R3, #0x0000
	MOVT R3, #0x0020
1:
	SUBS R3,R3,#1
	# branch backward to local label '1' (1b) if not equal (NE) to 0
	BNE 1b

	# branch always to start of loop - the 'begin' label
	B begin
