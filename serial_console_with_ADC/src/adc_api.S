# ADC1_api
# Yahui Liang
# Date: 11/11/2016

	.syntax unified
	.include "symbolic_names.txt"

	.section .text

	.global adc_init
# Initializes the ADC (Enable the clock and set the mode of the target pin into analog mode).
adc_init:
	push {r0-r1,lr}

	# Enable the clock.
	ldr r0,=RCC_BASE
	ldr r1,[r0,APB2ENR_OFFSET]
	orr r1,r1,#(1<<8) // ADC1 is bit8.
	str r1,[r0,APB2ENR_OFFSET]

	ldr r1,[r0,AHB1ENR_OFFSET]
	orr r1,r1,#1 // GPIOA is bit0.
	str r1,[r0,AHB1ENR_OFFSET]

	# enable analog for PA6
	ldr r0,=GPIOA_BASE
	ldr r1,[r0,MODER_OFFSET]
	bic r1,r1,#(0b11<<12) // make sure PA6 bits are clean.
	orr r1,r1,#(0b11<<12) // PA6 is at bit12.
	str r1,[r0,MODER_OFFSET]

	pop {r0-r1,pc}


	.global set_adc
# Sets the ADC (Turns ADC on and enable the interrupt when the conversion is finished).
set_adc:
	push {r0-r1,lr}

	ldr r0,=ADC1_BASE
	ldr r1,[r0,ADC_CR2_OFFSET]
	orr r1,r1,#(1<<0) // AD converter ON.
	str r1,[r0,ADC_CR2_OFFSET]

	ldr r1,[r0,ADC_SQR3_OFFSET]
	orr r1,r1,#0b0110 // Set the 1st conversion to be ch6.
	str r1,[r0,ADC_SQR3_OFFSET]

	ldr r0,=NVIC_BASE
	ldr r1,[r0,ISER0_OFFSET]
	orr r1,r1,#(1<<18) // Enable the interruptive event in the controller.
	str r1,[r0,ISER0_OFFSET]

	pop {r0-r1,pc}


	.global start_adc
# Starts the ADC conversion.
start_adc:
	push {r0-r1,lr}

	ldr r0,=ADC1_BASE
	ldr r1,[r0,ADC_CR2_OFFSET]
	orr r1,r1,#(1<<1) // Set the ADC into continuous conversion mode.
	orr r1,r1,#(1<<30) // Start conversion of regular channels.
	str r1,[r0,ADC_CR2_OFFSET]

	pop {r0-r1,pc}


	.global enable_EOC_interrupt
# Enables the EOC interrupt.
enable_EOC_interrupt:
	push {r1-r2,lr}

	ldr r1,=ADC1_BASE
	ldr r2,[r1,ADC_CR1_OFFSET]
	orr r2,r2,#(1<<5) // Enable interrupt for EOC.
	str r2,[r1,ADC_CR1_OFFSET]

	pop {r1-r2,pc}


	.global disable_EOC_interrupt
# Disable the EOC interrupt.
disable_EOC_interrupt:
	push {r1-r2,lr}

	ldr r1,=ADC1_BASE
	ldr r2,[r1,ADC_CR1_OFFSET]
	bic r2,r2,#(1<<5) // Disable interrupt for EOC.
	str r2,[r1,ADC_CR1_OFFSET]

	pop {r1-r2,pc}


	.global ADC_Convert_Handler
# The interruptive subroutine which stores the temp data into the memory or
# display the data to the console if the buffer space is not enough.
.thumb_func
ADC_Convert_Handler:
	mov r11,lr

	ldr r4,=ADC1_BASE
	ldr r5,=temp_buffer
	ldr r0,[r4,ADC_DR_OFFSET] // Get the number of counts.
	# Default resolution is 12-bits.
	# The reference voltage is 3.3V(3300mV).
	movw r1,#3300
	movw r2,#4095 // The maximum value the 12-bits number can store.
	mul r1,r1,r0
	udiv r1,r1,r2 // now the r1 stores the voltage which corresponds to a temp.
	mov r0,#250 // Set the standard air temperature.(I multiply 10 to 25 because I want to keep one digit precision)
	movw r2,#750 // Set the output voltage when the temp is 25 degree celcius.
	sub r1,r1,r2 // Calc temp without divided by the scale factor.
	add r1,r1,r0 // calc the temp in (celcius degree * 10).
	# now r1 stores the temperature(current temp * 10) data.
	# r5 is the buffer address.
	# determine if it is in buffer mode.
	ldr r0,=buffer_mode
	ldr r4,=temp_buffer_space
	ldrb r2,[r0]
	cmp r2,#1
	bne display_temp_without_store_into_buffer // skip if the mode is in buffer_off_mode.
	ldr r2,[r4]
	cmp r2,#0
	beq display_temp_without_store_into_buffer
	ldr r0,=position_in_temp_buffer
	ldr r2,[r0] // Get the offset.
	strh r1,[r5,r2] // Store the (current temp * 10) into the memory.
	add r2,r2,#2
	str r2,[r0] // update the offset for the next temp data.
	ldr r2,[r4]
	sub r2,r2,#1
	str r2,[r4] // store the new space into the memory.
	b 1f
display_temp_without_store_into_buffer:
	bl send_temp_data_to_console
1:
	# disable the EOC interrupt.
	bl disable_EOC_interrupt
	mov lr,r11
	bx lr

