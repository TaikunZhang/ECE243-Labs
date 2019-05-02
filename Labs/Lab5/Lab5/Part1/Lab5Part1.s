		  .text                   // executable code follows
          .global _start          
		  
_start: ldr r5,=0xff200020   //hex address
		mov r6,#Blank
		ldrb r6,[r6]
		mov r2,#0   //count on hex
		mov r8,#0x3f
		mov r7,#0
		str r8,[r5]
		
display: ldr r4,[r5,#0x30] //key in r4	
	     cmp r4,#1
		 addeq r7,#1
		 beq setzero
		 cmp r4,#2
		 beq increment
		 cmp r4,#4
		 beq decrement
		 cmp r4,#8
		 beq blank
		 
displaycheck: ldr r4,[r5,#0x30]
		ands r4,#0
		bne displaycheck
		 b display
		 
setzero: mov r2,#0
		 mov r0,r2
		 bl SEG7_CODE
		 str r0,[r5]
		 b displaycheck
		 
increment: cmp r2,#9
		   moveq r2,#0
		   addne r2,#1
		   mov r0,r2
		   bl SEG7_CODE
		   str r0,[r5]
		   b displaycheck
		   
decrement: cmp r2,#0
		   moveq r2,#9
		   subne r2,#1
		   mov r0,r2
		   bl SEG7_CODE
		   str r0,[r5]
		   b displaycheck
		   
blank:     strb r6,[r5]
		   b displaycheck
		    


SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              
		
BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment		

Blank: .byte 0b00000000