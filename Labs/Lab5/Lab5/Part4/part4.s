	  .text                   // executable code follows
          .global _start          
		  
_start: ldr r5,=0xff200020   //hex address
		ldr r6,=2000000   //load 2mill
		ldr r9,=0xfffec600
		str r6,[r9]  //str 2mill in load register 
		mov r6,#3
		str r6,[r9,#0x8] //load A bit and E bit
		mov r7,#0     //count register
		mov r11,#0
		mov r12,#0   //state register
		mov r10,#0xf  //overwrite


display: ldr r4,[r5,#0x3C] //key in r4	
		 ands r6,r4,#0b1111
		 blne set_bit
		 cmp  r6,#0
		 eorgt r12,#1 //flip bit
		 cmp r12,#1
		 beq count
		 b   display
		 

count:  cmp r7,#99
		moveq r7,#0
		addeq r11,#1
		cmp r11,#59
		moveq r11,#0
		add r7,#1
		
		mov r0,r7
		bl DIVIDE
		mov r8,r1
		bl SEG7_CODE
		strb r0,[r5]
		mov r0,r8
		bl SEG7_CODE
		strb r0,[r5,#1]
		
		mov r0,r11
		bl DIVIDE
		mov r8,r1
		bl SEG7_CODE
		strb r0,[r5,#2]
		mov r0,r8
		bl SEG7_CODE
		strb r0,[r5,#3]

delay:  ldr r4,[r9,#0xc]
		and r4,#1
		cmp r4,#1
		bne delay
		str r4,[r9,#0xc]
		b display

set_bit: str r10,[r5,#0x3C]
		 mov pc,lr


DIVIDE:     			MOV    R2, #0
CONT:       			CMP    R0, #10
						BLT    DIV_END
						SUB    R0, #10
						ADD    R2, #1
						B      CONT
DIV_END:    			MOV    R1, R2     // quotient in R1 (remainder in R0)
						MOV    PC, LR       




SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              
		
BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment	
