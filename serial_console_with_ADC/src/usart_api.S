# USART2_api
# Yahui Liang
# Date: 11/11/2016

	.syntax unified
	.include "symbolic_names.txt"

	.section .text

	.global usart_init
# Initiazlies the USART2.
usart_init:
	push {r0-r1,lr}

	# enable clocks.
	ldr r0,=RCC_BASE
	# enable clock to USART2.
	ldr r1,[r0,APB1ENR_OFFSET]
	orr r1,r1,#(1<<17) //USART2 is bit 17.
	str r1,[r0,APB1ENR_OFFSET]

	ldr r1,[r0,AHB1ENR_OFFSET]
	orr r1,r1,#0b01 // GPIOA is bit 0.
	str r1,[r0,AHB1ENR_OFFSET]

	# enable alternate function for PA2 and PA3-USART2 TX and RX.
	ldr r0,=GPIOA_BASE
	ldr r1,[r0,AFRL_OFFSET]
	bic r1,r1,#(0xFF<<8)
	orr r1,r1,#(0x77<<8) // AF7 for both PA2 and PA3
	str r1,[r0,AFRL_OFFSET]

	# set the mode to be alternation function.
	ldr r1,[r0,MODER_OFFSET]
	bic r1,r1,#(0b1111<<4)
	orr r1,r1,#(0b1010<<4)
	str r1,[r0,MODER_OFFSET]

	pop {r0-r1,pc}


	.global set_usart
# Sets up the USART2 (Sets the baud rate, enable interrupts, and enable USART2).
set_usart:
	push {r0-r1,lr}

	# set BAUD rate.
	ldr r0,=USART2_BASE
	movw r1,#(52<<4)|(0b0001) // 19.2kB with 16MHz sys clock.
	str r1,[r0,USARTx_BRR_OFFSET]

	# set CR1.
	movw r1,#(0b11<<2) // Enable transmitter and receiver.
	orr r1,r1,#(1<<7) // Enable the TXE interrupt.
	orr r1,r1,#(1<<13) // Enable USART.
	str r1,[r0,USARTx_CR1_OFFSET]

	# set CR2 and CR3 and make sure all bits are zero.
	movw r1,#0
	str r1,[r0,USARTx_CR2_OFFSET]
	str r1,[r0,USARTx_CR3_OFFSET]

	# enable the USART2 global interrupt in NVIC.
	ldr r0,=NVIC_BASE
	mov r1,#(1<<6)
	str r1,[r0,ISER1_OFFSET]

	pop {r0-r1,pc}


	.global stop_sending_and_start_receiving
# Enable and disable the corresponding interrupt bits.
# Parameter:
# R0: USART base address.
stop_sending_and_start_receiving:
	push {r0-r1,lr}

	ldr r1,[r0,USARTx_CR1_OFFSET]
	bic r1,r1,#(0b1<<7) // Disable TXE interrupt.
	orr r1,r1,#(0b1<<5) // Enable RXNE interrupt.
	str r1,[r0,USARTx_CR1_OFFSET]

	pop {r0-r1,pc}


	.global stop_receiving_and_start_sending
# Enable and disable the corresponding interrupt bits.
# Parameter:
# R0: USART base address.
stop_receiving_and_start_sending:
	push {r0-r1,lr}

	# change the event which causes the interrupt.
	ldr r1,[r0,USARTx_CR1_OFFSET]
	bic r1,r1,#(0b1<<5) // Disable RXNE interrupt.
	orr r1,r1,#(0b1<<7) // Enable TXE interrupt.
	str r1,[r0,USARTx_CR1_OFFSET]

	pop {r0-r1,pc}


# The interrupt subroutine for receiving cmd from the console and sending
# response to the console.
	.global Receive_Send_Handler
.thumb_func
Receive_Send_Handler:
	mov r11,lr

	ldr r0,=USART2_BASE
	# determine which event causes the interrupt.
	ldr r1,[r0,USARTx_CR1_OFFSET]
	ands r1,#(1<<7)
	bne ready_to_send
	ldr r1,[r0,USARTx_CR1_OFFSET]
	ands r1,#(1<<5)
	bne ready_to_receive

# Ready for sending the data to the console.
ready_to_send:
	ldr r1,=received_cmd
	ldr r2,=response
	ldr r6,=turn_on_or_off_buffer

	# determine which cmd the user typed into the console.
	ldrb r3,[r1]
	ldrb r4,[r1,#1]
	cmp r4,#0xD
	bne invalid
	ldrb r4,[r1,#2]
	cmp r4,#0xA
	bne invalid

	# compare the cmd received to each cmd stored in memory.
	# determine if needs to display welcome message.
	cmp r3,#0x77
	beq show_welcome_msg

	# determine if needs to display help information.
	cmp r3,#0x68
	beq show_help_info

	# determine if needs to turn the buffer on or off.
	cmp r3,#0x62
	bne 1f
	ldr r4,=buffer_mode
	ldrb r5,[r4]
	cmp r5,#0
	beq turn_buffer_mode_on
	bne turn_buffer_mode_off

1:
	# determine if needs to slow down the sample rate.
	cmp r3,#0x73
	beq turn_slow_mode_on

	# determine if needs to speed up the sample rate.
	cmp r3,#0x66
	beq turn_fast_mode_on

	# determine if just shows the current temperature.
	cmp r3,#0x74
	beq show_temperature

	# display invalid info when an invalid cmd typed in.
invalid:
	b show_invalid_info

show_welcome_msg:
	# keep the current buffer mode.
	mov r1,#2
	strb r1,[r6]

	# store the respond info reference.
	ldr r1,=greeting
	str r1,[r2]
	b send

show_help_info:
	# keep the current buffer mode.
	mov r1,#2
	strb r1,[r6]

	# store the respond info reference.
	ldr r1,=help_info
	str r1,[r2]
	b send

turn_buffer_mode_on:
	# turn on the buffer.
	mov r1,#1
	strb r1,[r6]

	# store the response info reference.
	ldr r1,=buffer_mode_on_config
	str r1,[r2]
	b send

turn_buffer_mode_off:
	# turn off the buffer.
	mov r1,#0
	strb r1,[r6]
	# set the variable to indicate that it is sending the buffer data to the console.
	ldr r1,=sending_buffer_data
	ldr r3,[r1]
	cmp r3,#0
	bne 1f
	bl append_all_buffer_data_in_buffer_mode_off_response // if there are some data in the buffer, these data will be displayed to console.
	mov r3,#1
	strb r3,[r1]
1:
	# store the resposne info reference.
	ldr r1,=buffer_mode_off_config
	str r1,[r2]
	b send

turn_slow_mode_on:
	# keep the current buffer mode.
	mov r1,#2
	strb r1,[r6]

	# slow down the sampling rate.
	ldr r3,=TIM2_BASE
	movw r4,#0x6800
	movt r4,#0x0989
	sub r4,r4,#1
	str r4,[r3,TIMx_ARR_OFFSET]
	mov r4,#0
	str r4,[r3,TIMx_CNT_OFFSET]

	# store the response info reference.
	ldr r1,=slow_mode_config
	str r1,[r2]
	b send

turn_fast_mode_on:
	# keep the current buffer mode.
	mov r1,#2
	strb r1,[r6]

	# speed up the sampling rate.
	ldr r3,=TIM2_BASE
	movw r4,#0x2400
	movt r4,#0x00F4
	sub r4,r4,#1
	str r4,[r3,TIMx_ARR_OFFSET]
	mov r4,#0
	str r4,[r3,TIMx_CNT_OFFSET]

	# store the response info reference.
	ldr r1,=fast_mode_config
	str r1,[r2]
	b send

show_temperature:
	# keep the current buffer mode.
	mov r1,#2
	strb r1,[r6]

	# store the response info reference.
	ldr r1,=temperature
	str r1,[r2]
	b send

show_invalid_info:
	# keep the current buffer mode.
	mov r1,#2
	strb r1,[r6]

	# store the response info reference.
	ldr r1,=invalid_cmd
	str r1,[r2]
	b send

# send data to the console.
send:
	ldr r4,=cur_byte
	ldr r1,[r4]
	ldr r2,=response
	# load the response address stored in response variable.
	ldr r2,[r2]
	# load a character.
	ldrb r3,[r2,r1]
	# determine if there is no more characters.
	cmp r3,#0
	beq finish_sending
	# copy character to send data register.
	strb r3,[r0,USARTx_DR_OFFSET]
	# update the condition.
	add r1,r1,#1
	str r1,[r4]
	b 1f

# finish sending all characters to the console.
finish_sending:
	# r0 for the USART2 base.
	# r4 for the current byte that is sending.

	# set the buffer mode after send the last character.
	ldr r1,=turn_on_or_off_buffer
	ldrb r1,[r1]
	cmp r1,#0 // Turn off the buffer mode.
	beq set_buffer_mode_to_off
	cmp r1,#1 // Turn on the buffer mode.
	beq set_buffer_mode_to_on
	cmp r1,#2 // Keep the current buffer mode.
	beq 2f
set_buffer_mode_to_off:
	ldr r1,=buffer_mode
	mov r2,#0
	strb r2,[r1]
	b 2f
set_buffer_mode_to_on:
	ldr r1,=buffer_mode
	mov r2,#1
	strb r2,[r1]
	b 2f

2:
	bl stop_sending_and_start_receiving

	# clear the current byte variable.
	mov r1,#0
	str r1,[r4]

	# start the timer and enable the interrupt when the response has been shown.
	bl start_timer

	# clear the sending buffer flag.
	ldr r1,=sending_buffer_data
	mov r2,#0
	strb r2,[r1]

	b 1f

# Ready for recieving cmd from the console.
ready_to_receive:
	ldr r4,=received_cmd
	ldr r2,=cur_byte
	# load one character.
	ldr r1,[r0,USARTx_DR_OFFSET]
	# determine if there is no more characters.
	cmp r1,#10
	beq finish_receiving
	# load the offset of the current character.
	ldr r3,[r2]
	# store the loaded character into the memory.
	strb r1,[r4,r3]
	# update the condition.
	add r3,r3,#1
	str r3,[r2]

	# pause the timer and disable the interrupt when the user type at least one character to the console.
	bl stop_timer

	b 1f

# Finish receiving all characters from the console.
finish_receiving:
	# store the line feeding character.
	ldr r3,[r2]
	strb r1,[r4,r3]
	add r3,r3,#1
	# stores null terminator.
	mov r1,#0
	strb r1,[r4,r3]
	# clear the current byte to zero.
	mov r3,#0
	str r3,[r2]

	bl stop_receiving_and_start_sending
1:
	mov lr,r11
	bx lr
