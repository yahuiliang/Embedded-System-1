# TIM2_api
# Yahui Liang
# Date: 11/11/2016

	.syntax unified
	.include "symbolic_names.txt"

	.section .text

	.global tim2_init
# Initializes the TIM2 (Enable the clock, set ARR, enable interrupt, and starts the clock).
tim2_init:
	push {r0,r4-r5,lr}

	# enable the clock for the timer.
	ldr r4,=RCC_BASE
	ldr r0,[r4,APB1ENR_OFFSET]
	orr r0,r0,#1 // Enable TIM2 clock.
	str r0,[r4,APB1ENR_OFFSET]

	ldr r4,=TIM2_BASE
	ldr r5,=NVIC_BASE

	# set the value in ARR (default to be 16000000).
	movw r0,#0x2400
	movt r0,#0x00F4
	sub r0,r0,#1
	str r0,[r4,TIMx_ARR_OFFSET] // Default the sample rate to be 1/s

	mov r0,#1
	str r0,[r4,TIMx_DIER_OFFSET] // Enable the update interrupt.

	ldr r0,[r5,ISER0_OFFSET]
	orr r0,r0,#(1<<28) // Enable the TIM2 global interrupt in NVIC controller.
	str r0,[r5,ISER0_OFFSET]

	ldr r0,[r4,TIMx_CR1_OFFSET]
	orr r0,r0,#1 // starts the timer.
	str r0,[r4,TIMx_CR1_OFFSET]

	pop {r0,r4-r5,pc}


# Start the TIM2.
	.global start_timer
start_timer:
	push {r1,r3,lr}

	ldr r1,=TIM2_BASE
	ldr r3,[r1,TIMx_CR1_OFFSET]
	orr r3,r3,#1
	str r3,[r1,TIMx_CR1_OFFSET] // starts the timer.
	ldr r3,[r1,TIMx_DIER_OFFSET]
	orr r3,r3,#1
	str r3,[r1,TIMx_DIER_OFFSET] // enable the interrupt.

	pop {r1,r3,pc}


# Stop the TIM2 and reset the count back to zero.
	.global stop_timer
stop_timer:
	push {r1,r3,lr}

	ldr r1,=TIM2_BASE
	ldr r3,[r1,TIMx_CR1_OFFSET]
	bic r3,r3,#1
	str r3,[r1,TIMx_CR1_OFFSET] // pause the timer.
	ldr r3,[r1,TIMx_DIER_OFFSET]
	bic r3,r3,#1
	str r3,[r1,TIMx_DIER_OFFSET] // disable the interrupt.
	mov r3,#0
	str r3,[r1,TIMx_CNT_OFFSET] // reset the count number back to 0.

	pop {r1,r3,pc}


# The interruptive subroutine which limits the rate of sampling temp data.
	.global TIM2_Interrupt_Handler
.thumb_func
TIM2_Interrupt_Handler:
	mov r11,lr
	# clear the interruptive flag.
	ldr r0,=TIM2_BASE
	ldr r1,[r0,TIMx_SR_OFFSET]
	bic r1,r1,#1
	str r1,[r0,TIMx_SR_OFFSET]
	# enable the EOC interrupt.
	bl enable_EOC_interrupt
	mov lr,r11
	bx lr
