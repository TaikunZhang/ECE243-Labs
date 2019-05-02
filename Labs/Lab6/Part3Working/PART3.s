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

_start:
/* Set up stack pointers for IRQ and SVC processor modes */
MOV      R0, #0b11010010    //IRQ mode bits
MSR      CPSR_c, R0        //change to IRQ mode
LDRB     SP, =0x3000    //set SP
MOV      R0, #0b11010011    //SVC mode bits
MSR      CPSR, R0
LDR      SP, =0x3FFFFFFC

BL       CONFIG_GIC       // configure the ARM generic
                          // interrupt controller
BL       CONFIG_TIMER     // configure the Interval Timer
BL       CONFIG_KEYS      // configure the pushbutton
                          // KEYs port

/* Enable IRQ interrupts in the ARM processor */
MOV      R0, #0b01010010    //IRQ mode bits
MSR      CPSR_c, R0        //change to IRQ mode/enable interrupt

LDR      R5, =0xFF200000  // LEDR base address

				  
LOOP:                                          
                  LDR      R3, COUNT        // global variable
                  STR      R3, [R5]         // write to the LEDR lights
                  B        LOOP    
				  
				  
KEY_ISR:
				  LDR      R0, =0xFF200000 //base address for interrupts
				  LDR      R2, [R0, #0x5C]   //read edge capture register
			      STR      R2, [R0, #0x5C]   //RESET INTERUPT
				  
				  
				  CMP      R2,#1
				  BEQ      NORM
				  CMP      R2,#2
				  BEQ      DOUBLE
				  CMP      R2,#4
				  BEQ      HALF
				  MOV	   PC,LR
				  
NORM:
				  LDR      R3, =RUN
			      LDR      R0, [R3]
		          EOR      R0, #1
		          STR      R0, [R3]
			      MOV      PC, LR				  
				  
DOUBLE:
				  LDR      R3, =0xFF202000     //BASE of interval timer register
				  MOV      R0, #11
				  STR      R0, [R3, #4]     //stop timer
				  LDR      R2, [R3, #8]    //LOAD AND SHIFT 
				  LSR      R2, #1
				  STR      R2, [R3, #8]
				  LDR      R2, [R3, #12]
				  LSR      R2, #1
				  STR      R2, [R3, #12]

				  MOV      R0, #7
				  STR      R0, [R3, #4]     //start timer

				  MOV      PC, LR	


HALF:             //ONLY COUNT HALF
				  
				  LDR      R3, =0xFF202000     //BASE of interval timer register
				  MOV      R0, #0b1011
				  STR      R0, [R3, #0x4]     //stop timer

				  LDR      R2, [R3, #8]
				  LSL      R2, #1
				  STR      R2, [R3, #8]
				  LDR      R2, [R3, #12]
				  LSL      R2, #1
				  STR      R2, [R3, #12]

				  MOV      R0, #7
				  STR      R0, [R3, #4]     //start timer

				  MOV      PC, LR
				  

TIMER_ISR:        LDR      R2, =COUNT //get the count value
LDR      R0, [R2]
LDR      R3, =RUN  //get the run value
LDR      R3, [R3]
ADD      R0, R3    //increment the sum
STR      R0, [R2]  //store the new sum
LDR      R0, =0xFF202000
MOV      R2, #0
STR      R2, [R0] //reset the flag for interrupt

MOV      PC, LR

SERVICE_IRQ:      PUSH     {R0-R7, LR}
LDR      R4, =0xFFFEC100 // GIC CPU interface base address
LDR      R1, [R4, #0x0C] // read the ICCIAR in the CPU
                                           // interface
TIMER_HANDLER: CMP R1,#72
BNE      KEYS_HANDLER
BL       TIMER_ISR
B        EXIT_IRQ

KEYS_HANDLER: CMP R1,#73
UNEXPECTED:       BNE      UNEXPECTED
BL       KEY_ISR
EXIT_IRQ:         STR      R1, [R4, #0x10] // write to the End of Interrupt
       // Register (ICCEOIR)
POP      {R0-R7, LR}
SUBS     PC, LR, #4      // return from exception

/* Configure the Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_TIMER:

LDR   R3, =0xFF202000     //BASE of interval timer register
LDR   R2, =0b0111100001000000 //lower bits of .25 second time
STR   R2, [R3, #8]
LDR   R2, =0b0000000101111101 //upper bits of .25 second time
STR   R2, [R3, #0xC]
MOV   R2, #0b111   //enable Interrupt, run, and contnue
STR   R2, [R3, #4]        //start timer
BX       LR

/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:
LDR      R2, =0xFF200058 //base address for interrupts
MOV      R3, #0b1111
STR      R3, [R2]          //set interrupt mask to 0b1111
BX       LR
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

/* Global variables */
.global  COUNT
COUNT:            .word    0x0              // used by timer
.global  RUN              // used by pushbutton KEYs
RUN:              .word    0x1              // initial value to increment
                          // COUNT

.end
				  
				  
				  
				  