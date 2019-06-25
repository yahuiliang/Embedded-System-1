.syntax unified
.include "symbolic_names.txt"

.section .data

# the variable for representing the state.
cur_state:
	.word 0

# the variable for recording the last falling edge
# time stamp.
last_timestamp:
	.word 0

# the variable for recording the instruction sent by the
# remote controller.
instruction_32bits:
	.word 0

# the variable for showing which bit you are recording.
cur_bit:
	.word 0

# the vairable for determining if the instruction is
# finished sending from the remote controller.
finished_bits:
	.word 0

# all instructions for buttons.
all_instructions:
	.word 0b11100100000110110110000110000110
	.word 0b11100011000111000110000110000110
	.word 0b11100010000111010110000110000110
	.word 0b11111001000001100110000110000110
	.word 0b11100001000111100110000110000110
	.word 0b11100000000111110110000110000110
	.word 0b11111101000000100110000110000110
	.word 0b11101101000100100110000110000110
	.word 0b11101100000100110110000110000110
	.word 0b11101110000100010110000110000110
	.word 0b11110101000010100110000110000110
	.word 0b11101111000100000110000110000110
	.word 0b11110000000011110110000110000110
	.word 0b11100111000110000110000110000110
	.word 0b11110001000011100110000110000110
	.word 0b11101000000101110110000110000110
	.word 0b11101011000101000110000110000110
	.word 0b11101010000101010110000110000110
	.word 0b11111000000001110110000110000110
	.word 0b11101001000101100110000110000110
	.word 0b11110100000010110110000110000110
	.word 0b11100110000110010110000110000110
	.word 0b11100101000110100110000110000110
	.word 0b11110010000011010110000110000110
	.word 0b11110011000011000110000110000110
	.word 0b11111011000001000110000110000110
	.word 0b11111111000000000110000110000110
	.word 0b11110110000010010110000110000110
	.word 0b11111010000001010110000110000110
	.word 0b11110111000010000110000110000110

# the following variables are messages that should
# be displayed when we press a button.
disc_1:
	.asciz "DISC 1"
disc_2:
	.asciz "DISC 2"
disc_3:
	.asciz "DISC 3"
shuffle:
	.asciz "SHUFFLE"
disc_4:
	.asciz "DISC 4"
disc_5:
	.asciz "DISC 5"
disc_skip:
	.asciz "DISC SKIP"
track_1:
	.asciz "TRACK 1"
track_2:
	.asciz "TRACK 2"
track_3:
	.asciz "TRACK 3"
time:
	.asciz "TIME"
track_4:
	.asciz "TRACK 4"
track_5:
	.asciz "TRACK 5"
track_6:
	.asciz "TRACK 6"
repeat:
	.asciz "REPEAT"
track_7:
	.asciz "TRACK 7"
track_8:
	.asciz "TRACK 8"
track_9:
	.asciz "TRACK 9"
intro_check:
	.asciz "INTRO CHECK"
track_0:
	.asciz "TRACK 0"
memory:
	.asciz "MEMORY"
clear:
	.asciz "CLEAR"
memory_check:
	.asciz "MEM CHECK"
search_back:
	.asciz "<<"
search_forward:
	.asciz ">>"
music_skip_back:
	.asciz "|<<"
music_skip_forward:
	.asciz ">>|"
stop:
	.asciz "STOP"
pause:
	.asciz "PAUSE"
play:
	.asciz "PLAY"

# all addresses for button messages.
.align 4
msg_addresses:
	.word disc_1
	.word disc_2
	.word disc_3
	.word shuffle
	.word disc_4
	.word disc_5
	.word disc_skip
	.word track_1
	.word track_2
	.word track_3
	.word time
	.word track_4
	.word track_5
	.word track_6
	.word repeat
	.word track_7
	.word track_8
	.word track_9
	.word intro_check
	.word track_0
	.word memory
	.word clear
	.word memory_check
	.word search_back
	.word search_forward
	.word music_skip_back
	.word music_skip_forward
	.word stop
	.word pause
	.word play


.section .text


# The program is for receiving the command sent from the remote
# controller and giving the correspond response.
	.global main
main:
	# initializations.
	bl GPIOB_TIM12_CLK_init
	bl lcd_init

	# the loop for repeating determining if
	# a 32-bits instruction is received.
1:
	ldr r0,=finished_bits
	ldr r1,[r0]
	cmp r1,#32
	bne 1b

	# load stored instruction.
	ldr r0,=instruction_32bits
	ldr r1,[r0]

	mov r3,#0
	# compare the read instruction with
	# stored instructions.
	ldr r0,=all_instructions
	ldr r2,[r0,r3]
repeat_comparing:
	cmp r1,r2
	beq display_message
	# set a timeout variable.
	# the loop will exit if times out.
	cmp r3,#120
	bpl re_receive
	add r3,r3,#4
	ldr r0,=all_instructions
	ldr r2,[r0,r3]
	b repeat_comparing

	# the respond will be shown at here.
display_message:
	bl lcd_clear
	ldr r0,=msg_addresses
	ldr r0,[r0,r3]
	bl lcd_print_string

	# try to receive the instruction again if
	# there is some problems occur in the previous
	# instruction.
re_receive:
	# clear finished_bits.
	ldr r0,=finished_bits
	mov r1,#0
	str r1,[r0]
	# clear stored instruction.
	ldr r0,=instruction_32bits
	mov r2,#0
	str r2,[r0]

	b 1b


# Initializes GPIOB and TIM12.
GPIOB_TIM12_CLK_init:
	push {r0-r1,lr}

	# enable the clock for GPIOB.
	ldr r0,=RCC_BASE
	ldr r1,[r0,AHB1ENR_OFFSET]
	orr r1,r1,GPIOB_EN
	str r1,[r0,AHB1ENR_OFFSET]
	# enable the clock for TIM12.
	ldr r0,=RCC_BASE
	ldr r1,[r0,APB1ENR_OFFSET]
	orr r1,r1,TIM12_EN
	str r1,[r0,APB1ENR_OFFSET]
	# sets the mode of PB14.
	ldr r0,=GPIOB_BASE
	ldr r1,[r0,MODER_OFFSET]
	orr r1,r1,#(ALT_MODE<<28)
	str r1,[r0,MODER_OFFSET]

	# select TIM12 to be the alternate function.
	ldr r1,[r0,AFRH_OFFSET]
	orr r1,r1,#(0b1001<<24)
	str r1,[r0,AFRH_OFFSET]

	ldr r0,=TIM12_BASE
	# input capture mode - falling edge only.
	ldr r1,[r0,CCMR1_OFFSET]
	orr r1,r1,#0b01
	str r1,[r0,CCMR1_OFFSET]
	# falling edge only.
	mov r1,#(0b1<<1)
	str r1,[r0,CCER_OFFSET]
	# enable capture from the counter
	# into the capture register by setting
	# this bit.
	ldr r1,[r0,CCER_OFFSET]
	orr r1,r1,#1
	str r1,[r0,CCER_OFFSET]
	# interrupt request on input capture, channel 1.
	ldr r1,[r0,DIER_OFFSET]
	orr r1,r1,0b10
	str r1,[r0,DIER_OFFSET]
	# auto reload value.
	mov r1,#0xFFFFFFFF
	str r1,[r0,ARR_OFFSET]
	# set prescaler, the speed of the counter is 20000Hz now.
	mov r1,#800
	str r1,[r0,PSC_OFFSET]
	# connect to Channel 1 and enable counter.
	mov r1,#1
	str r1,[r0,CR1_OFFSET]

	# configure NVIC to enable TIM12 interrupt.
	ldr r0,=NVIC_BASE
	mov r1,#(1<<11)
	str r1,[r0,ISER1_OFFSET]

	pop {r0-r1,pc}


# The handler for the falling edge interruptive event.
	.global ISR_for_Remote_Decoder
.thumb_func
ISR_for_Remote_Decoder:
	mov r12,lr

	# reset interrupt flag.
	ldr r0,=TIM12_BASE
	mov r1,#0
	str r1,[r0,SR_OFFSET]

	# load state from .data.
	ldr r0,=cur_state
	ldrb r1,[r0]

# the WAITING_FOR_START state.
waiting_for_start:
	# If state == WAITING_FOR_START.
	cmp r1,#0
	bne waiting_for_endstart
	# store CCR1 into last_timestamp.
	bl store_CCR1_to_last_timestamp
	# state <= WAITING_FOR_ENDSTART.
	mov r1,#1
	# store state to .data.
	ldr r0,=cur_state
	str r1,[r0]
	b end

# the WAITING_FOR_ENDSTART state.
waiting_for_endstart:
	# elseif state == WAITING_FOR_ENDSTART.
	cmp r1,#1
	bne waiting_for_bits_logic
	# get the width
	bl get_width
	# If width > 12 ms and width < 15 ms.
	cmp r1,#240
	bls stop_reading
	cmp r1,#300
	bpl stop_reading
	# then...
	# store CCR1 to last_timestamp.
	bl store_CCR1_to_last_timestamp
	# state <= WAITING_FOR_LOGIC_BITS.
	mov r1,#2
	# store state to .data.
	ldr r0,=cur_state
	str r1,[r0]
	b end

# the state for WAITING_BITS_LOGIC.
waiting_for_bits_logic:
	# get width.
	bl get_width
	# If width > 1 ms and width < 1.5 ms.
	cmp r1,#0
	bls 1f
	cmp r1,#30
	bpl 1f
	# store CCR1 to last_timestamp.
	bl store_CCR1_to_last_timestamp
	# set the logic 0 of the corresponding bit.
	bl set_logic_0
	# load in the current bit and determine if 32 bits
	# have been decoded.
	ldr r0,=cur_bit
	ldr r1,[r0]
	bl update_finished_bits
	cmp r1,#31
	bne 2f
	b stop_reading
2:
	# update the state.
	# state <= next_bit.
	bl update_cur_bit
	b end

1:
	# If width > 1.5 ms and width < 3 ms.
	bl get_width
	cmp r1,#30
	bls stop_reading
	cmp r1,#100
	bpl stop_reading
	# store CCR1 to last timestamp.
	bl store_CCR1_to_last_timestamp
	# set bit to 1.
	bl set_logic_1
	# load in the current bit and determine if 32 bits
	# have been decoded.
	ldr r0,=cur_bit
	ldr r1,[r0]
	bl update_finished_bits
	cmp r1,#31
	bne 2f
	b stop_reading
2:
	# update the state.
	# state <= next_bit.
	bl update_cur_bit
	b end

# reset all states back to state 0.
stop_reading:
	ldr r0,=cur_state
	mov r1,#0
	str r1,[r0]
	ldr r0,=cur_bit
	mov r1,#0
	str r1,[r0]

# go back to the main.
end:
	mov lr,r12
	bx lr


# Stores the value in CCR1(current falling edge event time stamp)
# into the memory.
store_CCR1_to_last_timestamp:
	push {r0-r1,lr}

	ldr r0,=TIM12_BASE
	ldr r1,[r0,CCR1_OFFSET]
	ldr r0,=last_timestamp
	str r1,[r0]

	pop {r0-r1,pc}


# Sets the logic of the corresponding bit to 0.
set_logic_0:
	push {r0-r4,lr}

	# set the logic of the corresponding logic.
	ldr r0,=instruction_32bits
	ldr r1,=cur_bit
	# r2 = current bit.
	ldr r2,[r1]
	# r3 = instruction.
	ldr r3,[r0]
	mov r4,#0
	lsl r4,r4,r2
	orr r3,r3,r4
	str r3,[r0]

	pop {r0-r4,pc}


# Sets the logic of the corresponding bit to 1.
set_logic_1:
	push {r0-r4,lr}

	# set the logic of the corresponding logic.
	ldr r0,=instruction_32bits
	ldr r1,=cur_bit
	# r2 = current bit.
	ldr r2,[r1]
	# r3 = instruction.
	ldr r3,[r0]
	mov r4,#1
	lsl r4,r4,r2
	orr r3,r3,r4
	str r3,[r0]

	pop {r0-r4,pc}


# Update the state for the current bit that the program
# is receiving.
update_cur_bit:
	push {r0-r1,lr}

	ldr r0,=cur_bit
	ldr r1,[r0]
	add r1,r1,#1
	str r1,[r0]

	pop {r0-r1,pc}


# Gets the width between the previous falling edge
# and the current falling edge.
#
# Returns the width in r1.
get_width:
	push {r0,r2,lr}

	# get the current time stamp.
	ldr r0,=TIM12_BASE
	ldr r1,[r0,CCR1_OFFSET]
	# get the last time stamp.
	ldr r0,=last_timestamp
	ldr r2,[r0]
	cmp r2,r1
	# get the wave width if there is not any overflow.
	sub r1,r1,r2

	pop {r0,r2,pc}


# Updates the variable which is used for determining if
# all bits of the command are read in.
update_finished_bits:
	push {r0-r1,lr}

	ldr r0,=finished_bits
	ldr r1,[r0]
	add r1,r1,#1
	str r1,[r0]

	pop {r0-r1,pc}

