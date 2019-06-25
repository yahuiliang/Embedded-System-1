# Serial_console_with_ADC
# Yahui Liang
# Date: 11/11/2016

	.syntax unified
	.include "symbolic_names.txt"

	.section .data

	.global greeting
# The greeting message which is sent from the start.
greeting:
	.asciz "Greetings from STM32F446RE\r\n"

	.global help_info
# The help information.
help_info:
	.ascii "b-buffer on/off\r\n"
	.ascii "s-slow mode\r\n"
	.ascii "f-fast mode\r\n"
	.asciz "h-help\r\n"

	.global buffer_mode_on_config
# The buffer mode on configuration information.
buffer_mode_on_config:
	.asciz "buffer mode on\r\n"

	.global buffer_mode_off_config
# The buffer mode off configuration information.
buffer_mode_off_config:
	.ascii "buffer mode off\r\n"
	.space 1000

	.global slow_mode_config
# The message which indicates the slow mode is enabled.
slow_mode_config:
	.asciz "slow mode enabled\r\n"

	.global fast_mode_config
# The message which indicates the fast mode is enabled.
fast_mode_config:
	.asciz "fast mode enabled\r\n"

	.global invalid_cmd
# The message which indicates that an invalid command is entered by the user.
invalid_cmd:
	.asciz "invalid cmd!\r\n"

	.global temperature
# The format for displaying temperature data.
temperature:
	.space 2
	.ascii "."
	.space 1
	.asciz "celcius degree\r\n"

	.global buffer_mode
# The variable which shows the current buffer mode.
# 1: on
# 0: off
buffer_mode:
	.byte 0

	.global turn_on_or_off_buffer
# The variable for determining if we are going to turn on the
# buffer(1) or turn off the buffer(0) or keep the current buffer mode(2).
turn_on_or_off_buffer:
	.byte 0

	.global cur_byte
# The variable which records the offset of the character when we read in the command
# from the console.
cur_byte:
	.word 0

	.global response
# The vairable which contains the reference of the response message.
response:
	.word greeting

	.global received_cmd
# The vairable for storing the command recieved from the console.
received_cmd:
	.space 50

	.global temp_received_from_ADC
# The memory for storing the current temp that the sensor records.
.align 4
temp_received_from_ADC:
	.word 0

	.global temp_buffer
# The buffer for storing temp in Celcius degree.
.align 4
temp_buffer:
	.space 100

	.global position_in_temp_buffer
# The variable determines where the new data should be put.
position_in_temp_buffer:
	.word 0

	.global temp_buffer_space
# The variable means how many temp values(In ASCII) this buffer can store.
temp_buffer_space:
	.word 50

	.global sending_buffer_data
# The variable which records the status of sending buffer data.
# 0: not sending buffer data.
# 1: sending buffer data.
sending_buffer_data:
	.byte 0

	.section .text

# The program is the data logger which logs the temperature data
# recorded by ADC to the console. This program contains all functions
# mentioned in the instruction, so you can feel free to use it.
	.global main
main:
	# let the board to send welcome message to the console at the begining.
	ldr r0,=received_cmd
	mov r1,#0x77
	strb r1,[r0]
	mov r1,#0x0D
	strb r1,[r0,#1]
	mov r1,#0x0A
	strb r1,[r0,#2]

	# initializations.
	bl usart_init
	bl set_usart
	bl one_sec_delay_by_using_systick
	bl adc_init
	bl set_adc
	bl tim2_init
	bl start_adc

	# The infinite loop which waits ISRs occur.
1:
	b 1b
