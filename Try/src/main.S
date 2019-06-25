.syntax unified

.section .data
string1:
	.asciz "Yahui Liang"
string2:
	.asciz "Ziwei Chen"
string3:
	.asciz ""

	.section .text

	.global main
main:
	ldr r0,=0x20000000
	mov r1,#0b10000000
	str r1,[r0]
	ldrsb r1,[r0]
	b main

convert_to_capital:
	push {r1-r2,lr}

	mov r1,#0
next_chr:
	ldrb r2,[r0,r1]
	cmp r2,#0
	beq 2f
	cmp r2,#0x61
	bmi 1f
	cmp r2,#0x7A
	bhi 1f
	sub r2,r2,0x20
	strb r2,[r0,r1]
1:
	add r1,r1,#1
	b next_chr
2:
	pop {r1-r2,pc}
