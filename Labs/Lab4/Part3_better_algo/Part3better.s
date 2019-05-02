/* Program that counts multiple words for consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:                             
						MOV     R3, #TEST_NUM   // load the data word ...
						LDR     R8, =0xffffffff
						LDR     R10, =0xaaaaaaaa
						MOV     R5, #0          // holds greatest count of ones in a row
						MOV     R6, #0          // holds greatest count of zeros in a row
						MOV     R7, #0
					
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
						B  		NEXT
		  
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

N: .word 10 
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