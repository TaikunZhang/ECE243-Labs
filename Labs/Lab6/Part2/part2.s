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
                  LDRB     SP, =0x30000    //set SP
                  MOV      R0, #0b11010011    //SVC mode bits
                  MSR      CPSR, R0
                  LDR      SP, =0x3FFFFFFC

                  BL       CONFIG_GIC       // configure the ARM generic
                                            // interrupt controller
                  BL       CONFIG_TIMER     // configure the Interval Timer
                  BL       CONFIG_KEYS      // configure the pushbutton
                                            // KEYs port
											
/* Enable IRQ interrupts in the ARM processor */
                  MOV      R0, #0b01010010    //IRQ 
                  MSR      CPSR_c, R0        // interrupt

                  LDR      R5, =0xFF200000  // LEDR base address
LOOP:                                          
                  LDR      R3, COUNT        // global variable
                  STR      R3, [R5]         // write to the LEDR lights
                  B        LOOP    
				  
KEY_ISR:

				LDR      R0, =0xFF200000 //base address for interrupts
				LDR      R2, [R0, #0x5C]   //read edge capture register
				STR      R2, [R0, #0x5C]   //RESET INTERUPT

				LDR      R3,=RUN //run in r3
				LDR      R0,[R3] //RUN into R0

				EOR      R0,#1 //TOGGLE
				STR      R0, [R3] //STORE BACK INTO RUN
				MOV      PC, LR 

TIMER_ISR:

				  LDR      R2, =COUNT //get the count value
                  LDR      R7,[R2]
                  LDR      R3, =RUN  //get the run value
                  LDR      R3, [R3]
				  ADD      R7,R3 //add to sum
				  STR      R7,[R2]//store sum
                  LDR      R0, =0xFF202000
                  MOV      R2, #0
                  STR      R2, [R0] //reset interrupt

				  MOV PC,LR
				  
SERVICE_IRQ:      PUSH     {R0-R7, LR}
                  LDR      R4, =0xFFFEC100 // GIC CPU interface base address
                  LDR      R1, [R4, #0x0C] // read the ICCIAR in the CPU
                                                             // interface

TIMER_HANDLER:    CMP      R1, #72 //compare
                  BNE      KEYS_HANDLER // if not the same go to KEYS
                  BL       TIMER_ISR // check timer 
                  B        EXIT_IRQ

KEYS_HANDLER:                       
                CMP      R1, #73         // check the interrupt ID

UNEXPECTED:     BNE      UNEXPECTED      // if not recognized, stop here
                BL       KEY_ISR         

EXIT_IRQ:       STR      R1, [R4, #0x10] // write to the End of Interrupt
                                         // Register (ICCEOIR)
                POP      {R0-R7, LR}     
                SUBS     PC, LR, #4      // return from exception
											
											
											
											
/* Configure the Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_TIMER:
                  //101111101
                  LDR   R3, =0xFF202000     //BASE of interval timer register
				  //loading twice cause move too small
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
				  BX   	LR
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