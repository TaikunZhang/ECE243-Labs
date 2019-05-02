                .section .vectors, "ax"  
                B        _start              // reset vector
                B        SERVICE_UND         // undefined instruction vector
                B        SERVICE_SVC         // software interrupt vector
                B        SERVICE_ABT_INST    // aborted prefetch vector
                B        SERVICE_ABT_DATA    // aborted data vector
                .word    0                   // unused vector
                B        SERVICE_IRQ         // IRQ interrupt vector
                B        SERVICE_FIQ         // FIQ interrupt vector

                .text    
                .global  _start 

_start:         MOV R1, #0b11010010 // IRQ 
				MSR CPSR_c, R1                       
				LDRB SP,=0x30000
                MOV R1, #0b11010011 // SVC
				MSR CPSR_c, R1 // change to IRQ mode
				LDR SP,=0xFFFFFFFC

                BL CONFIG_GIC      // configure the ARM generic
                                         // interrupt controller

				LDR R0, =0xFF200050 // pushbutton key base address
				MOV R1, #0xF // set interrupt mask bits
				STR R1, [R0, #0x8] // interrupt mask register is (base + 8)
				
				BL CONFIG_GIC
				MOV R1, #0b01010010 // IRQ 
				MSR CPSR_c, R1
                
IDLE:           B        IDLE  


KEY_ISR:
LDR      R0, =0xFF200000 //base address for interrupts
LDR      R2, [R0, #0x5C]   //read edge capture register
STR      R2, [R0, #0x5C]   //RESET INTERUPT
LDR      R0, =0b0000000 //default blank
LDR      R1, [R0]
EOR      R2, R1, R2
STR      R2, [R0]

LDR      R0, =0xFF200020 //HEX3-0
MOV      R1, #0

CHK_KEY3:
TST      R2, #8      //KEY3 pressed
BEQ      CHK_KEY2

MOV      R3, #0b01001111 //load 3
ORR      R1, R1, R3, LSL #24

CHK_KEY2:
TST      R2, #4      //KEY2 pressed
BEQ      CHK_KEY1
MOV      R3, #0b01011011 //load 2
ORR      R1, R1, R3, LSL #16

CHK_KEY1:
TST      R2, #2      //KEY1 pressed
BEQ      CHK_KEY0
MOV      R3, #0b00000110
ORR      R1, R1, R3, LSL #8 //load 1

CHK_KEY0:
TST      R2, #1      //KEY0 pressed
BEQ      END_KEY_ISR
MOV      R3, #0b00111111 //load 0
ORR      R1, R1, R3


END_KEY_ISR:
STR      R1, [R0]
MOV      PC, LR
		
				
				
SERVICE_IRQ:    PUSH     {R0-R7, LR}     
                LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                LDR      R5, [R4, #0x0C] // read the ICCIAR in the CPU
                                         // interface

KEYS_HANDLER:                       
                CMP      R5, #73         // check the interrupt ID

UNEXPECTED:     BNE      UNEXPECTED      // if not recognized, stop here
                BL       KEY_ISR         

EXIT_IRQ:       STR      R5, [R4, #0x10] // write to the End of Interrupt
                                         // Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception
				
/* Undefined instructions */
SERVICE_UND:
                    B   SERVICE_UND
/* Software interrupts */
SERVICE_SVC:
                    B   SERVICE_SVC
/* Aborted data reads */
SERVICE_ABT_DATA:
                    B   SERVICE_ABT_DATA
/* Aborted instruction fetch */
SERVICE_ABT_INST:
                    B   SERVICE_ABT_INST
SERVICE_FIQ:
                    B   SERVICE_FIQ

                    .end				