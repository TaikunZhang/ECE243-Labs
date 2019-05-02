.define HEX4_ADDRESS 0x2004
.define HEX_ADDRESS 0x2000
.define SW_ADDRESS 0x3000
.define STACK 256

				mvi r6,#STACK
				mv  r5,r7
				mvi r7,#BLANK
				
MAIN:   		mvi r0,#0   //intitialize counter
				
LOOP:           mvi r1,#1 //initialze register with value 1
				sub r6,r1 //stack->255
				st  r0,[r6] //stpre count into stack
				
				mvi r4,HEX4_ADDRESS

DISPLAY:        mv r5,r7
				mvi r7,#DIV10 
				
				sub r6,r1
				st  r0,[r6] //store remainder into stack
				mv 	r0,r2 //store quotient into r0
				//first digit
				
				mv r5,r7
				mvi r7,#DIV10
				
				sub r6,r1
				st  r0,[r6]
				mv 	r0,r2
				//second digit
				
				mv r5,r7
				mvi r7,#DIV10
				
				sub r6,r1
				st  r0,[r6]
				mv 	r0,r2
				//third digit
				
				mv r5,r7
				mvi r7,#DIV10
				
				sub r6,r1
				st  r0,[r6]
				mv 	r0,r2
				//fourth digit
				
				mv r5,r7
				mvi r7,#DIV10
				
				//r0 has fifth digit
				
				mvi r3,#DATA //access data (has 7seg)
				add r3,r0   //add to first digit
				ld  r3,[r3] //load into memory
				st  r3,[r4] //light up HEX4
				
				sub r4,r1
				ld 	r0,[r6]
				add r6,r1
				
				mvi r3,#DATA
				add r3,r0
				ld  r3,[r3]
				st  r3,[r4] //light up HEX3
				
				sub r4,r1
				ld 	r0,[r6]
				add r6,r1
				
				mvi r3,#DATA
				add r3,r0
				ld  r3,[r3]
				st  r3,[r4] //light up HEX2
				
				sub r4,r1
				ld 	r0,[r6]
				add r6,r1
				
				mvi r3,#DATA
				add r3,r0
				ld  r3,[r3]
				st  r3,[r4] //light up HEX1
				
				sub r4,r1
				ld 	r0,[r6]
				add r6,r1
				
				mvi r3,#DATA
				add r3,r0
				ld  r3,[r3]
				st  r3,[r4] //light up HEX0
				
				ld  r0,[r6]
				add r6,r1
				
COUNT:          add r0,r1
				mvi r2,#SW_ADDRESS
				ld r3,[r2]
				
				mvi r4,#2000 //set delay count
				add r4,r3
				add r4,r3
				add r4,r3
				add r4,r3
				add r4,r3
				add r4,r3
				add r4,r3
				add r4,r3
				add r4,r3
				add r4,r3
				add r4,r3
				
				
				
DELAY:			mv   r5,r7
				sub  r4,r1
				mvnz r7,r5
				
				mvi  r5,#LOOP
				
CHECK65535:     mvi r4,#65535 //check if 65535 has been reached
				sub r4,r0
				mvnz r7,r5
				mvi r7,#MAIN //go back to main if not zero
				
				
DIV10:  		mvi r1, #1
				sub r6, r1 // save registers that are modified
				st 	r3, [r6]
				sub r6, r1
				st 	r4, [r6] // end of register saving
				mvi r2, #0 // init Q
				mvi r3, RETDIV // for branching
		
		
DLOOP:  		mvi r4, #9 // check if r0 is < 10 yet
				sub r4, r0
				mvnc r7, r3 // if so, then return
				INC: add r2, r1 // but if not, then increment Q
				mvi r4, #10
				sub r0, r4 // r0 -= 10
				mvi r7, DLOOP // continue loop


RETDIV:			ld r4, [r6] // restore saved regs
				add r6, r1
				ld r3, [r6] // restore the return address
				add r6, r1
				add r5, r1 // adjust the return address by 2
				add r5, r1
				mv r7, r5 // return results
			
BLANK:
                  mvi	r0, #0				      // used for clearing
                  mvi	r1, #1				      // used to add/sub 1
                  mvi	r2, #HEX_ADDRESS	  // point to HEX displays
                  st		r0, [r2]			   	// clear HEX0
                  add	r2, r1
                  st		r0, [r2]				  // clear HEX1
                  add	r2, r1
                  st		r0, [r2]				  // clear HEX2
                  add	r2, r1
                  st		r0, [r2]				  // clear HEX3
                  add	r2, r1
                  st		r0, [r2]			 	  // clear HEX4
                  add	r2, r1
                  st		r0, [r2]				  // clear HEX5

                  add	r5, r1
                  add	r5, r1              // update address of return
                  mv		r7, r5				    // return from subroutine


DATA:                 .word 0b00111111		// '0'
			          .word 0b00000110		// '1'
			          .word 0b01011011		// '2'
			          .word 0b01001111		// '3'
			          .word 0b01100110		// '4'
			          .word 0b01101101		// '5'
					  .word 0b11111101      // '6'
                      .word 0b10000111      // '7'
                  	  .word 0b11111111      // '8'
                  	  .word 0b11100111      // '9'