# Electronic Lock
# Yahui Liang
# Date: 10/24/2016

.syntax unified

.section .data
# display message.
message_for_enter_password:
	.asciz "Enter Password:"

.section .rodata
# The correct password.
password:
	.asciz "ABCD123"

.section .bss
entered_password:
	.space 7

.section .text
	.equ SYSTICK_BASE, 0xE000E010
	.equ STK_CTRL, 0x00
	.equ STK_LOAD, 0x04
	.equ STK_VAL, 0x08
	.equ STK_CALIB, 0x0C
	.equ COUNTFLAG, 1<<16
	.equ CLKSOURCE, 1<<2
	.equ TICKINT, 1<<1
	.equ ENABLE, 1<<0

	.equ GPIOA_BASE, 0x40020000
	.equ GPIOB_BASE, 0x40020400
	.equ GPIOC_BASE, 0x40020800
	.equ TIM3_BASE, 0x40000400
	.equ TIMx_ARR_OFFSET, 0x2C
	.equ TIMx_CCR1_OFFSET, 0x34
	.equ TIMx_CCR2_OFFSET, 0x38
	.equ TIMx_CCMR1_OFFSET, 0x18
	.equ TIMx_CCER_OFFSET, 0x20
	.equ TIMx_CR1_OFFSET, 0x00
	.equ MODER_OFFSET, 0x0
	.equ IDR_OFFSET, 0x10
	.equ ODR_OFFSET, 0x14
	.equ BSRR_OFFSET, 0x18

	.equ RCC_BASE, 0x40023800
	.equ AHB1ENR_OFFSET, 0x30
	.equ APB1ENR_OFFSET, 0x40
	.equ GPIOB_EN, 0b10
	.equ TIM3_EN, 0b10
	.equ AFRL_OFFSET, 0x20


# The subroutine initializes the timer3.
timer3_init:
	push {r0-r1,lr}

	# init clock for GPIOB.
	ldr r0,=RCC_BASE
	ldr r1,[r0,AHB1ENR_OFFSET]
	orr r1,r1,GPIOB_EN
	str r1,[r0,AHB1ENR_OFFSET]

	# init clock for TIM3
	ldr r0,=RCC_BASE
	ldr r1,[r0,APB1ENR_OFFSET]
	orr r1,r1,TIM3_EN
	str r1,[r0,APB1ENR_OFFSET]

	# enable alternate function for PB4.
	ldr r0,=GPIOB_BASE
	# PB4 is between bit 19 and bit 16.
	ldr r1,[r0,AFRL_OFFSET]
	orr r1,r1,#(0b0010<<16)
	str r1,[r0,AFRL_OFFSET]

	# set GPIOB into alternate function mode.
	ldr r0,=GPIOB_BASE
	ldr r1,[r0,MODER_OFFSET]
	# PB4 is between bit 9 and bit 8.
	bic r1,r1,#(0b11<<8)
	orr r1,r1,#(0b10<<8)
	str r1,[r0,MODER_OFFSET]

	pop {r0-r1,pc}

# Initialize the right most led.
led_init:
	push {r0-r1,lr}

	ldr r0,=RCC_BASE
	ldr r1,[r0,AHB1ENR_OFFSET]
	# enable the clock for the led.
	orr r1,r1,#0x01
	str r1,[r0,AHB1ENR_OFFSET]

	ldr r0,=GPIOA_BASE
	ldr r1,[r0,MODER_OFFSET]
	# set to general purpose output mode.
	orr r1,r1,#(0b1<<14)
	bic r1,r1,#(0b1<<15)
	str r1,[r0,MODER_OFFSET]

	pop {r0-r1,pc}

# The subroutine turns on the right most led.
turn_on_led:
	push {r0-r1,lr}

	ldr r0,=GPIOA_BASE
	ldr r1,[r0,ODR_OFFSET]
	orr r1,r1,#(0b1<<7)
	str r1,[r0,ODR_OFFSET]

	pop {r0-r1,pc}

# The subroutine turns off the right most led.
turn_off_led:
	push {r0-r1,lr}

	ldr r0,=GPIOA_BASE
	ldr r1,[r0,ODR_OFFSET]
	bic r1,r1,#(0b1<<7)
	str r1,[r0,ODR_OFFSET]

	pop {r0-r1,pc}


# The subroutine sets the timer3 to be in toggle ouput mode.
# Also, it sets the half period of the counter.
# Parameter:
# r1: the number of ticks that a half period needs to be.
set_timer3:
	push {r0-r1,lr}

	ldr r0,=TIM3_BASE

	# 8000 ticks for 500us high.
	# set the auto reload value and the
	# compare value of TIM3.

	# set the reset count.
	str r1,[r0,TIMx_ARR_OFFSET]

	# set the position of the toggle.
	mov r1,#0
	str r1,[r0,TIMx_CCR1_OFFSET]

	# select output mode - toggle.
	movw r1,#(0b011 << 4)
	str r1,[r0,TIMx_CCMR1_OFFSET]

	# compare output enable
	movw r1,#1
	str r1,[r0,TIMx_CCER_OFFSET]

	pop {r0-r1,pc}


# The subroutine starts the tim3.
enable_tim3:
	push {r0-r1,lr}

	# enable counter.
	ldr r0,=TIM3_BASE
	ldr r1,[r0,TIMx_CR1_OFFSET]
	mov r1,#1
	str r1,[r0,TIMx_CR1_OFFSET]

	pop {r0-r1,pc}


# The subroutine stops the tim3.
disable_tim3:
	push {r0-r1,lr}

	# stop making sound.
	ldr r0,=TIM3_BASE
	ldr r1,[r0,TIMx_CR1_OFFSET]
	mov r1,#0
	str r1,[r0,TIMx_CR1_OFFSET]

	pop {r0-r1,pc}


# The subroutine asks the user to enter the password
# and save the input into the memory.
prompt_enter:
	push {r0-r2,lr}

	ldr r0,=message_for_enter_password
	bl lcd_print_string
	# set the position to the next line.
	mov r0,#1
	mov r1,#0
	bl lcd_set_position
	mov r2,#7
	# offset of the memory.
	mov r3,#0
repeat_7_times:
	# store the one character of the password into the memory.
	bl key_getchar
	ldr r1,=entered_password
	strb r0,[r1,r3]
	# the ascii value of the key is stored in r0.
	mov r0,'*'
	bl lcd_data
	subs r2,r2,#1
	add r3,r3,#1
	bne repeat_7_times

	pop {r0-r2,pc}


# The subroutine checks if the password is right or wrong.
# Returns:
# r0: 	1 if the password is correct.
# 		0 if the password is incorrect.
check_password:
	push {r1-r4,lr}

	# r0 for the address of the password
	# that the user entered.
	ldr r0,=entered_password
	# r1 for the address of the expect password.
	ldr r1,=password

	mov r4,#0
next_character:
	ldrb r2,[r0,r4]
	ldrb r3,[r1,r4]
	# compare each character of the password.
	cmp r2,r3
	bne incorrect_password
	add r4,r4,#1
	cmp r4,#8
	bne next_character

	b correct_password

incorrect_password:
	mov r0,#0
	b 1f
correct_password:
	mov r0,#1
1:
	pop {r1-r4,pc}


# Clear the memory which stores the previous password entered.
clear_previous_entered_password:
	push {r0-r2,lr}

	ldr r0,=entered_password
	mov r2,#0
1:
	ldrb r1,[r0,r2]
	# clear password.
	and r1,r1,#0
	strb r1,[r0,r2]
	add r2,r2,#1
	cmp r2,#8
	bne 1b

	pop {r0-r2,pc}


# The subroutine resets all the bits for the
# STK_CTRL and the STK_LOAD.
reset_bits_for_systick:
	push {r0-r1,lr}

	# reset all bits.
	ldr r0,=SYSTICK_BASE
	ldr r1,[r0,STK_CTRL]
	and r1,r1,#0
	str r1,[r0,STK_CTRL]
	ldr r1,[r0,STK_LOAD]
	and r1,r1,#0
	str r1,[r0,STK_LOAD]

	pop {r0-r1,pc}


	.global one_sec_delay_by_using_systick
# Cause a delay for 1 second by using systick counter.
one_sec_delay_by_using_systick:
	push {r0-r1,lr}

	bl reset_bits_for_systick

	# cause a delay by using the systick.
	ldr r0,=SYSTICK_BASE
	ldr r1,=16000000
	str r1,[r0,STK_LOAD]
	# start the clock.
	mov r1,ENABLE|CLKSOURCE
	str r1,[r0,STK_CTRL]
	# determine when is timeout.
1:
	ldr r1,[r0,STK_CTRL]
	ands r1,r1,COUNTFLAG
	beq 1b

	pop {r0-r1,pc}
