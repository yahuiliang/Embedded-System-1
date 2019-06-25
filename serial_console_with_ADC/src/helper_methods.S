# Helper_methods
# Yahui Liang
# Date: 11/11/2016

	.syntax unified
	.include "symbolic_names.txt"

	.section .text

	.global send_temp_data_to_console
# The subroutine sends one temp data to the console.
# Parameter:
# R1: The temperature data that you want to display.
send_temp_data_to_console:
	push {r0,r2-r4,lr}

	bl convert_temp_data_into_display_format

	ldr r0,=received_cmd
	mov r1,#0x74
	strb r1,[r0]
	mov r1,#0x0D
	strb r1,[r0,#1]
	mov r1,#0x0A
	strb r1,[r0,#2]

	ldr r0,=USART2_BASE
	# change the interruptive event in order to send the temperature data.
	bl stop_receiving_and_start_sending

	pop {r0,r2-r4,pc}


	.global convert_temp_data_into_display_format
# The subroutine converts the temp data into human readable format and store it
# into the memory.
# Parameter:
# R1: The temperature data that you want to convert.
convert_temp_data_into_display_format:
	push {r0,r2-r3,lr}

	ldr r3,=temperature

	mov r0,r1 // Set parameter for converting the num into ASCII format.
	bl num_to_ASCII
	# loop 2 times, and save digits which are before the decimal point.
	mov r2,#16
	mov r4,#0
1:
	lsr r0,r1,r2
	bic r0,r0,#0xFFFFFF00
	strb r0,[r3,r4]
	add r4,r4,#1
	sub r2,r2,#8
	cmp r2,#0
	bne 1b

	# store one digit after the decimal point.
	lsr r0,r1,r2
	bic r0,r0,#0xFFFFFF00
	strb r0,[r3,#3]

	pop {r0,r2-r3,pc}


	.global append_all_buffer_data_in_buffer_mode_off_response
# This subroutine appends all buffer data after the buffer mode off response string.
append_all_buffer_data_in_buffer_mode_off_response:
	push {r0-r5,lr}

	ldr r0,=temp_buffer
	ldr r1,=temp_buffer_space

	mov r5,#17 // set the start offset for appending the temp data into the b mode off response.
	ldr r3,[r1] // load the current buffer space.
	mov r2,#50 // set r2 to be the total buffer space.
	sub r2,r2,r3 // get how many spaces we have used.
	# skip the subroutine if no buffer space has been used.
	cmp r2,#0
	beq finish_appending_buffer_data_into_response
	# calc offset now.
	sub r2,r2,#1
	mov r3,#2
	mul r2,r2,r3 // calculate the max offset of the temperature buffer.
	mov r3,#0 // set the start offset for getting data from the buffer.
1:
	ldrh r4,[r0,r3] // get the buffer data correspond to that offset.
	mov r1,r4 // set the parameter.
	bl convert_temp_data_into_display_format
	mov r1,r5
	bl append_one_temp_data
	# update the offset.
	add r5,r5,#20
	cmp r3,r2
	add r3,r3,#2
	bne 1b
# append the null terminator and reset the buffer space back to 50.
finish_appending_buffer_data_into_response:
	ldr r0,=buffer_mode_off_config
	mov r1,#0
	strb r1,[r0,r5]

	ldr r0,=position_in_temp_buffer
	ldr r1,=temp_buffer_space
	mov r2,#50
	str r2,[r1]
	mov r2,#0
	str r2,[r0]

	pop {r0-r5,pc}


# The subroutine only appends one buffer data after the buffer mode off response string.
# parameter:
# r1: the offset for placing this temp data based on buffer mode off response base address.
append_one_temp_data:
	push {r0,r2-r4,lr}

	ldr r0,=temperature
	ldr r4,=buffer_mode_off_config
	mov r2,#0 // let r2 to be the offset.
1:
	ldrb r3,[r0,r2] // load one character
	cmp r3,#0 // determine if it is the null terminator.
	beq 1f
	strb r3,[r4,r1] // append one character.
	add r1,r1,#1
	add r2,r2,#1
	b 1b
1:
	// finished appending one temperature data.
	pop {r0,r2-r4,pc}

