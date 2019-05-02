/* Program that converts a binary number to decimal */
           .text               // executable code follows
           .global _start
_start:
            MOV    R4, #N
            MOV    R5, #Digits  // R5 points to the decimal digits storage location
			MOV    R6, #DIVISOR
            LDR    R4, [R4]     // R4 holds N
			LDR    R1, [R6]
            MOV    R0, R4       // parameter for DIVIDE goes in R0
			LDR    R1, [R6]
            BL     DIVIDE
            STRB   R0, [R5]     // Ones digit is in R0
			MOV    R0, R1       //move quotient into r0
			LDR    R1, [R6]
			BL     DIVIDE
			STRB   R0, [R5,#1]  //move quotient 1 into r5
			MOV    R0, R1
			LDR    R1, [R6]
			BL     DIVIDE
			STRB   R0, [R5,#2] 
			STRB   R1, [R5,#3]
			
END:        B      END

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0
*/
DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, R1
            BLT    DIV_END
            SUB    R0, R1
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR

DIVISOR:    .word 10			
			
N:          .word  9876        // the decimal number to be converted
Digits:     .space 4          // storage space for the decimal digits

            .end
