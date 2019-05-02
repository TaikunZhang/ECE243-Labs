/* Program that finds the largest number in a list of integers	*/

            .text                   // executable code follows
            .global _start
_start:                             
            MOV     R4, #RESULT     // R4 points to result location
            LDR     R5, [R4, #4]    // R5 holds the number of elements in the list
            MOV     R1, #NUMBERS    // R1 points to the start of the list
            BL      LARGE  
STORE:    	STR     R0, [R4]        // R0 holds the subroutine return value
END:		B       END             

/* Subroutine to find the largest integer in a list
 * Parameters: R0 has the number of elements in the lisst
 *             R1 has the address of the start of the list
 * Returns: R0 returns the largest item in the list
 */
LARGE:   SUBS     R5, #1        // decrement the loop counter
         BEQ      LARGE_END       // if result is equal to 0, go back
         LDR      R3, [R1]      // get the next number
         CMP      R0, R3        // check if larger number found
		 ADD      R1, #4
         BGE      LARGE
         MOV      R0, R3        // update the largest number
         B        LARGE
LARGE_END: MOV PC,LR

RESULT:     .word   0           
N:          .word   7           // number of entries in the list
NUMBERS:    .word   4, 5, 3, 6  // the data
            .word   1, 8, 2                 

            .end                            

