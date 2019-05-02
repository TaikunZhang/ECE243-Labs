		  .text                   // executable code follows
          .global _start                  
_start:                             
						MOV     R3, #TEST_NUM   // load the data word ...
						LDR     R8, =0xffffffff 
						LDR     R10, =0xaaaaaaaa
						MOV     R5, #0          // holds greatest count of ones in a row
						MOV     R6, #0          // holds greatest count of zeros in a row
						MOV     R7, #0          // holds greatest count of 10 patterns
						MOV     R4, #0
					
NEXT: 					LDR     R9,[R3],#4 //get next word

MAIN:              		CMP     R9,#0
						BEQ     END
						MOV     R1,R9
						BL      COUNT_ZEROS
						
STORE_ZERO_COUNT:   	CMP     R6,R0
						MOVLT   R6,R0
						MOV     R1,R9
						BL      COUNT_ONES
						CMP     R5,R0
						MOVLT   R5,R0
						MOV     R1,R9
						BL      COUNT_SEQUENCE
						
STORE_SEQUENCE_COUNT:	CMP     R7,R11
						MOVLT   R7,R11

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R12, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R5          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0
			     
            //code for R6 
            MOV     R0,R6
			BL      DIVIDE
			
			MOV     R9, R1
			BL 		SEG7_CODE
			LSL     R0, #16
			ORR     R4, R0
			MOV     R0,R9
			
			BL      SEG7_CODE
			LSL     R0,#24
			ORR     R4, R0
			
            STR     R4, [R12]        // display the numbers from R6 and R5
			
            LDR     R12, =0xFF200030 // base address of HEX5-HEX4
      
            MOV     R0, R7          // display R on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0
            
            STR     R4, [R12]        // display the number from R7
						
						
						
			B NEXT
		  
		  
COUNT_ZEROS:      		MOV     R0, #0
						EOR     R1, R8
						BL      COUNT_ONES
						B       STORE_ZERO_COUNT
		  		  
COUNT_ONES:         	MOV     R0, #0          // R0 will hold the result
LOOP_ONES:          	CMP     R1, #0          // loop until the data contains no more 1's
						BEQ     COUNT_ONES_END             
						LSR     R2, R1, #1      // perform SHIFT, followed by AND
						AND     R1, R1, R2      
						ADD     R0, #1          // count the string length so far
						B       LOOP_ONES 
					
COUNT_ONES_END:     	MOV     PC,LR		
					
COUNT_SEQUENCE:     	MOV     R0, #0
						MOV     R11, #0
						EOR     R1, R10
						EOR     R1, R8
						BL      COUNT_ONES
						CMP     R11,R0
						MOVLT   R11,R0
						MOV     R1, R9
						EOR     R1, R10
						BL      COUNT_ONES
						CMP     R11,R0
						MOVLT   R11,R0
						B       STORE_SEQUENCE_COUNT
									
END:      				B       END             

DIVIDE:     			MOV    R2, #0
CONT:       			CMP    R0, #10
						BLT    DIV_END
						SUB    R0, #10
						ADD    R2, #1
						B      CONT
DIV_END:    			MOV    R1, R2     // quotient in R1 (remainder in R0)
						MOV    PC, LR       

/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment



TEST_NUM: .word   0xff000b51  
          .word   0x00000002
		  .word   0x00000007
		  .word   0x0000000f
          .word   0x0000001f
          .word   0x0000002f
          .word   0x0000007f
          .word   0x100000ff
          .word   0x100001ff
          .word   0xfffff2ff
		  .word   0xffffffff
		  .word   0x00000000
          .end   