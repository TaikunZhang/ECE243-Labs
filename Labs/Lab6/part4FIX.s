/*
 * Assembly Program that uses hardware interrupts to have a varied speed of binary counter 
 * depending on KEY input
 *
 * Part3 of Lab6 for ECE243
 */

// Exception Vector Table:
  .section .vectors, "ax"  
        B        _start              // reset vector
        B        SERVICE_UND         // undefined instruction vector
        B        SERVICE_SVC         // software interrupt vector
        B        SERVICE_ABT_INST    // aborted prefetch vector
        B        SERVICE_ABT_DATA    // aborted data vector
        .word    0                   // unused vector
        B        SERVICE_IRQ         // IRQ interrupt vector
        B        SERVICE_FIQ         // FIQ interrupt vector

// Main Executable Code:
    .text    
    .global  _start 

_start: 
    // Set up stack pointers for IRQ and SVC processor modes
    MOV   R0, #0b11010010     // load IRQ mode bits, interrupts masked
    MSR   CPSR, R0            // enter IRQ mode
    LDR   SP, =0x1FFFFFFC     // load stack pointer

    MOV   R0, #0b11010011     // load SVC mode bits, interrupts masked
    MSR   CPSR, R0            // enter SVC mode
    LDR   SP, =0x3FFFFFFC     // load stack pointer

    // Configure the General Interrupt Controller
    BL    CONFIG_GIC

    // Configure key push buttons to generate interrupts
    BL    CONFIG_KEYS

    // Configure the interval timer to generate one interrupt every 0.25 seconds
    BL    CONFIG_TIMER

    // Configure the private timer to generate one interrupt every 1/100 seconds
    BL 	  CONFIG_PRIV_TIMER

    // Configure ARM Processor to enable interrupts
    MOV   R0, #1
    LSL   R0, R0, #7
    LDR   R1, =0xFFFFFFFF
    EOR   R0, R0, R1          // sets up the value of R0 to be all ones except for the 7th digit which is 0
    MRS   R2, CPSR            // copy CPSR into R1
    AND   R2, R2, R0          // change bit 7 (I) to a 0
    MSR   CPSR, R2            // move into CPSR register configured interrupt mask bit


  // Program loop
    LDR   R9, =0xFF200000     // load base address for LED lights
    LDR   R10, =0xFF200020 	  // load base address for HEX3-0 lights
  MAIN:
    LDR   R3, COUNT             // global variable
    STR   R3, [R9]
    LDR   R3, HEX_CODE
    STR   R3, [R10] 			// show the time in the right format
    B     MAIN


  // Configure KEYS
  CONFIG_KEYS:
    LDR   R0, =0xFF200058     // load KEY interrupt mask register address into R0
    LDR   R1, [R0]            // load value in mask register into R1
    ORR   R1, R1, #0xF        // set all bits in mask register to 1
    STR   R1, [R0]            // store value of R1 to mask register
    MOV   PC, LR

  // Configure Timer
  CONFIG_TIMER:
    LDR   R0, =0xFF202000     // load FPGA Interval timer base address
    MOV   R1, #0b0111         // settings for timer control register. Start = 1, Cont = 1, ITO = 1
    LDR   R2, =0x7840         // counter start value lower bits
    STR   R2, [R0, #8]
    LDR   R2, =0x17D          // counter start value upper bits
    STR   R2, [R0, #12]   
    STR   R1, [R0, #4]        // load control register
    MOV   PC, LR 

  // Configure private timer
  CONFIG_PRIV_TIMER:
    LDR   R0, =0xFFFEC600     // load base address of A9 private timer
    LDR   R1, =1000000        // initial value to start decrementing from
    STR   R1, [R0]            // set load value for the timer
    MOV   R2, #0b111          // allow timer to loop back, allow timer to set interrupts, start timer
    STR   R2, [R0, #8]        // start timer

  // Configure GIC
  CONFIG_GIC:
          PUSH    {LR}
          /* Configure the A9 Private Timer interrupt, FPGA KEYs, and FPGA Timer */
          /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
          MOV   R0, #MPCORE_PRIV_TIMER_IRQ
          MOV   R1, #CPU0
          BL      CONFIG_INTERRUPT
          MOV   R0, #INTERVAL_TIMER_IRQ
          MOV   R1, #CPU0
          BL      CONFIG_INTERRUPT
          MOV   R0, #KEYS_IRQ
          MOV   R1, #CPU0
          BL      CONFIG_INTERRUPT

        /* configure the GIC CPU interface */
          LDR   R0, =0xFFFEC100   // base address of CPU interface
          /* Set Interrupt Priority Mask Register (ICCPMR) */
          LDR   R1, =0xFFFF       // enable interrupts of all priorities levels
          STR   R1, [R0, #0x04]
          /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
         * allows interrupts to be forwarded to the CPU(s) */
          MOV   R1, #1
          STR   R1, [R0]
    
          /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
         * allows the distributor to forward interrupts to the CPU interface(s) */
          LDR   R0, =0xFFFED000
          STR   R1, [R0]    
    
          POP       {PC}
  /* 
  * Configure registers in the GIC for an individual interrupt ID
  * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
  * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
  * other registers in the GIC
  * Arguments: R0 = interrupt ID, N
  *            R1 = CPU target
  */
  CONFIG_INTERRUPT:
          PUSH    {R4-R5, LR}
    
          /* Configure Interrupt Set-Enable Registers (ICDISERn). 
         * reg_offset = (integer_div(N / 32) * 4
         * value = 1 << (N mod 32) */
          LSR   R4, R0, #3              // calculate reg_offset
          BIC   R4, R4, #3              // R4 = reg_offset
          LDR   R2, =0xFFFED100
          ADD   R4, R2, R4              // R4 = address of ICDISER
    
          AND   R2, R0, #0x1F             // N mod 32
          MOV   R5, #1                // enable
          LSL   R2, R5, R2              // R2 = value

        /* now that we have the register address (R4) and value (R2), we need to set the
         * correct bit in the GIC register */
          LDR   R3, [R4]                // read current register value
          ORR   R3, R3, R2              // set the enable bit
          STR   R3, [R4]                // store the new register value

          /* Configure Interrupt Processor Targets Register (ICDIPTRn)
           * reg_offset = integer_div(N / 4) * 4
           * index = N mod 4 */
          BIC   R4, R0, #3              // R4 = reg_offset
          LDR   R2, =0xFFFED800
          ADD   R4, R2, R4              // R4 = word address of ICDIPTR
          AND   R2, R0, #0x3            // N mod 4
          ADD   R4, R2, R4              // R4 = byte address in ICDIPTR

        /* now that we have the register address (R4) and value (R2), write to (only)
         * the appropriate byte */
          STRB    R1, [R4]
    
          POP   {R4-R5, PC}

/*
 * Handles all hardware interrupts
 */
SERVICE_IRQ:      
    PUSH     {R0-R7, LR}                // Save values of these registers 
    LDR      R4, =0xFFFEC100            // GIC CPU interface base address
    LDR      R5, [R4, #0x0C]            // read the ICCIAR in the CPU interface

    CMP    R5, #INTERVAL_TIMER_IRQ      // check if interrupt id matches interval timer
    BLEQ   COUNTER_ISR

    CMP    R5, #KEYS_IRQ                // check if interrupt id matches keys
    BLEQ   KEYS_ISR

    CMP    R5, #MPCORE_PRIV_TIMER_IRQ   // check if interrupt id matches priv timer
    BLEQ   PRIV_ISR

    // Exit the IRQ
    STR   R5, [R4, #0x10]               // clear the IICEOIR register in the CPU interface
    POP   {R0-R7, LR}
    SUBS  PC, LR, #4                    // return to main program

/*
 * Interrupt service routine for the keys
 */
KEYS_ISR:
    LDR   R0, =0xFF200050   // load base address of KEY
    LDR   R1, [R0, #0x0C]   // load the value of the edge capture register
    STR   R1, [R0, #0x0C]   // clear the edge capture register

    CMP 	R1, #0b1000 		// check if KEY3 was pressed
	  BEQ 	KEY3_ISR

	  CMP 	R1, #0b100 			// check if KEY2 was pressed
	  BEQ 	KEY2_ISR

	  CMP 	R1, #0b10 			// check if KEY1 was pressed
	  BEQ 	KEY1_ISR 

	  CMP 	R1, #0b1 			// check if KEY0 was pressed
	  BEQ 	KEY0_ISR 

	  MOV 	PC, LR				// return from KEY_ISR

	KEY0_ISR:
		PUSH 	{R0-R4}
    LDR   	R2, RUN
    EOR   	R2, R2, #1        	// change the state of R2
    STR   	R2, RUN
    POP 	{R0-R4}
		MOV 	PC, LR 				// return to KEY_ISR

	KEY1_ISR:
		PUSH 	{R0-R4}
		LDR 	R0, =0xFF202000 	// load base address of interval timer
		MOV 	R1, #0b1000 		// bit code to stop counter
		STR 	R1, [R0, #4]		// stop the counter
		LDR 	R1, [R0, #8] 		// load in lower bits
		LDR 	R2, [R0, #12] 		// load in upper bits
		LSL 	R2, #16 			// shift the bits where they belong
		ORR 	R1, R1, R2 			// combined lower and upper bits
		LSR 	R1, #1 				// shift right is divide by 2
		LDR 	R2, =0xFFFF0000 	
		AND 	R2, R2, R1 			// load in the top 16 bits
		LSR 	R2, #16 			// shift properly
		LDR 	R3, =0xFFFF 		
		AND 	R1, R1, R3 			// filter for the first 16 bits, at this point, R1 hold lower bits, R2, holds upper bits
		STR 	R1, [R0, #8]
		STR 	R2, [R0, #12]
		MOV 	R1, #0b0111 		// bit code for starting timer
		STR 	R1, [R0, #4]
		POP 	{R0-R4}
		MOV 	PC, LR 				// return to KEY_ISR

	KEY2_ISR:
		PUSH 	{R0-R4}
		LDR 	R0, =0xFF202000 	// load base address of interval timer
		MOV 	R1, #0b1000 		// bit code to stop counter
		STR 	R1, [R0, #4]		// stop the counter
		LDR 	R1, [R0, #8] 		// load in lower bits
		LDR 	R2, [R0, #12] 		// load in upper bits
		LSL 	R2, #16 			// shift the bits where they belong
		ORR 	R1, R1, R2 			// combined lower and upper bits
		LSL 	R1, #1 				// shift left is multiply by 2
		LDR 	R2, =0xFFFF0000 	
		AND 	R2, R2, R1 			// load in the top 16 bits
		LSR 	R2, #16 			// shift properly
		LDR 	R3, =0xFFFF 		
		AND 	R1, R1, R3 			// filter for the first 16 bits, at this point, R1 hold lower bits, R2, holds upper bits
		STR 	R1, [R0, #8]
		STR 	R2, [R0, #12]
		MOV 	R1, #0b0111 		// bit code for starting timer
		STR 	R1, [R0, #4]
		POP 	{R0-R4}
		MOV 	PC, LR 				// return to KEY_ISR

	KEY3_ISR:
		PUSH 	{R0-R4}
    LDR   R2, =RUN_PRIV
    LDR   R2, [R2]
    EOR   R2, R2, #1          // change the state of R2
    LDR   R3, =RUN_PRIV
    STR   R2, [R3]
		POP 	{R0-R4}
		MOV 	PC, LR 				// return to KEY_ISR

/*
 * Interrupt service routine for interval timer
 */

COUNTER_ISR: 
    LDR     R0, =0xFF202000     // base address of interval counter
    MOV     R1, #10
    STR     R1, [R0]            // clear the interrupt flag by writing to status register
    LDR     R0, COUNT           // increment count
    LDR     R2, RUN
    ADD     R0, R0, R2
    STR     R0, COUNT
    MOV     PC, LR              // return back to caller

/*
 * Interrupt service routine for private timer
 */

PRIV_ISR:
    PUSH    {R0-R4, LR}
    LDR     R0, =0xFFFEC600     // base address of private timer
    MOV     R1, #1
    STR     R1, [R0, #12]       // clear interrupt status register
    
    LDR     R1, =TIME            // increment the TIME variable
    LDR     R1, [R1]
    LDR     R2, =RUN_PRIV
    LDR     R2, [R2]
    ADD     R1, R1, R2
    LDR     R2, =TIME
    STR     R1, [R2]

    LDR     R1, =TIME            // reset the TIME to 0 if 6000 is reached
    LDR     R1, [R1]
    LDR     R2, =6000
    MOV     R3, #0
    CMP     R1, R2
    MOVEQ   R1, R3
    LDR     R2, =TIME
    STR     R1, [R2] 

    LDR     R0, =TIME            // update the hex displays
    LDR     R0, [R0]
    BL      DIVIDE    
    BL      SEG7_CODE   
    MOV     R4, R0

    MOV     R0, R1    
    BL      DIVIDE
    BL      SEG7_CODE
    LSL     R0, R0, #8
    ORR     R4, R4, R0

    MOV     R0, R1
    BL      DIVIDE
    BL      SEG7_CODE
    LSL     R0, R0, #16
    ORR     R4, R4, R0

    MOV     R0, R1
    BL      DIVIDE
    BL      SEG7_CODE
    LSL     R0, R0, #24
    ORR     R4, R4, R0

    STR     R4, HEX_CODE              // store in global variable for display

    POP     {R0-R4, LR}
    MOV     PC, LR                    // return from ISR


/* 
 * Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0
 */
DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, #10
            BLT    DIV_END
            SUB    R0, #10
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR


/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  PUSH    {R1}
            LDR     R1, =BIT_CODES
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            POP     {R1}
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment


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

/*
 * Global variables for counter
 */
          .global COUNT
COUNT:    .word   0x0       // used by interval timer

          .global RUN       // used by pushbutton KEYS
RUN:      .word   0x1       // initial value to increment

		      .global TIME 
TIME: 	  .word   0x0 		// used by private timer

		      .global HEX_CODE
HEX_CODE: .word   0x0  		// used to read the proper time

          .global RUN_PRIV
RUN_PRIV: .word   0x1 

/*
 * Beyond this point, its just DEFINITIONS
 */

/* FPGA interrupts (there are 64 in total; only a few are defined below) */
      .equ  INTERVAL_TIMER_IRQ,       72
      .equ  KEYS_IRQ,                 73
      .equ  FPGA_IRQ2,                74
      .equ  FPGA_IRQ3,                75
      .equ  FPGA_IRQ4,                76
      .equ  FPGA_IRQ5,                77
      .equ  AUDIO_IRQ,                78
      .equ  PS2_IRQ,                  79
      .equ  JTAG_IRQ,                 80
      .equ  IrDA_IRQ,                 81
      .equ  FPGA_IRQ10,               82
      .equ  JP1_IRQ,                  83
      .equ  JP2_IRQ,                  84
      .equ  FPGA_IRQ13,               85
      .equ  FPGA_IRQ14,               86
      .equ  FPGA_IRQ15,               87
      .equ  FPGA_IRQ16,               88
      .equ  PS2_DUAL_IRQ,             89
      .equ  FPGA_IRQ18,               90
      .equ  FPGA_IRQ19,               91

/* ARM A9 MPCORE devices (there are many; only a few are defined below) */
      .equ  MPCORE_GLOBAL_TIMER_IRQ,  27
      .equ  MPCORE_PRIV_TIMER_IRQ,    29
      .equ  MPCORE_WATCHDOG_IRQ,      30

/* HPS devices (there are many; only a few are defined below) */
      .equ  HPS_UART0_IRQ,            194
      .equ  HPS_UART1_IRQ,            195
      .equ  HPS_GPIO0_IRQ,            196
      .equ  HPS_GPIO1_IRQ,            197
      .equ  HPS_GPIO2_IRQ,            198
      .equ  HPS_TIMER0_IRQ,           199
      .equ  HPS_TIMER1_IRQ,           200
      .equ  HPS_TIMER2_IRQ,           201
      .equ  HPS_TIMER3_IRQ,           202
      .equ  HPS_WATCHDOG0_IRQ,        203
      .equ  HPS_WATCHDOG1_IRQ,        204
       

/* Address values that exist in the system */

/* Memory */
        .equ  DDR_BASE,              0x00000000
        .equ  DDR_END,               0x3FFFFFFF
        .equ  A9_ONCHIP_BASE,        0xFFFF0000
        .equ  A9_ONCHIP_END,         0xFFFFFFFF
        .equ  SDRAM_BASE,            0xC0000000
        .equ  SDRAM_END,             0xC3FFFFFF
        .equ  FPGA_ONCHIP_BASE,      0xC8000000
        .equ  FPGA_ONCHIP_END,       0xC803FFFF
        .equ  FPGA_CHAR_BASE,        0xC9000000
        .equ  FPGA_CHAR_END,         0xC9001FFF

/* Cyclone V FPGA devices */
        .equ  LEDR_BASE,             0xFF200000
        .equ  HEX3_HEX0_BASE,        0xFF200020
        .equ  HEX5_HEX4_BASE,        0xFF200030
        .equ  SW_BASE,               0xFF200040
        .equ  KEY_BASE,              0xFF200050
        .equ  JP1_BASE,              0xFF200060
        .equ  JP2_BASE,              0xFF200070
        .equ  PS2_BASE,              0xFF200100
        .equ  PS2_DUAL_BASE,         0xFF200108
        .equ  JTAG_UART_BASE,        0xFF201000
        .equ  JTAG_UART_2_BASE,      0xFF201008
        .equ  IrDA_BASE,             0xFF201020
        .equ  TIMER_BASE,            0xFF202000
        .equ  AV_CONFIG_BASE,        0xFF203000
        .equ  PIXEL_BUF_CTRL_BASE,   0xFF203020
        .equ  CHAR_BUF_CTRL_BASE,    0xFF203030
        .equ  AUDIO_BASE,            0xFF203040
        .equ  VIDEO_IN_BASE,         0xFF203060
        .equ  ADC_BASE,              0xFF204000

/* Cyclone V HPS devices */
        .equ   HPS_GPIO1_BASE,       0xFF709000
        .equ   HPS_TIMER0_BASE,      0xFFC08000
        .equ   HPS_TIMER1_BASE,      0xFFC09000
        .equ   HPS_TIMER2_BASE,      0xFFD00000
        .equ   HPS_TIMER3_BASE,      0xFFD01000
        .equ   FPGA_BRIDGE,          0xFFD0501C

/* ARM A9 MPCORE devices */
        .equ   PERIPH_BASE,          0xFFFEC000   /* base address of peripheral devices */
        .equ   MPCORE_PRIV_TIMER,    0xFFFEC600   /* PERIPH_BASE + 0x0600 */

        /* Interrupt controller (GIC) CPU interface(s) */
        .equ   MPCORE_GIC_CPUIF,     0xFFFEC100   /* PERIPH_BASE + 0x100 */
        .equ   ICCICR,               0x00         /* CPU interface control register */
        .equ   ICCPMR,               0x04         /* interrupt priority mask register */
        .equ   ICCIAR,               0x0C         /* interrupt acknowledge register */
        .equ   ICCEOIR,              0x10         /* end of interrupt register */
        /* Interrupt controller (GIC) distributor interface(s) */
        .equ   MPCORE_GIC_DIST,      0xFFFED000   /* PERIPH_BASE + 0x1000 */
        .equ   ICDDCR,               0x00         /* distributor control register */
        .equ   ICDISER,              0x100        /* interrupt set-enable registers */
        .equ   ICDICER,              0x180        /* interrupt clear-enable registers */
        .equ   ICDIPTR,              0x800        /* interrupt processor targets registers */
        .equ   ICDICFR,              0xC00        /* interrupt configuration registers */

/* Random Definitions*/
        .equ    EDGE_TRIGGERED,      0x1
        .equ    LEVEL_SENSITIVE,     0x0
        .equ    CPU0,                0x01  // bit-mask; bit 0 represents cpu0
        .equ    ENABLE,              0x1
        .equ    KEY0,                0b0001
        .equ    KEY1,                0b0010
        .equ    KEY2,                0b0100
        .equ    KEY3,                0b1000

        .equ    RIGHT,               1
        .equ    LEFT,                2

        .equ    USER_MODE,           0b10000
        .equ    FIQ_MODE,            0b10001
        .equ    IRQ_MODE,            0b10010
        .equ    SVC_MODE,            0b10011
        .equ    ABORT_MODE,          0b10111
        .equ    UNDEF_MODE,          0b11011
        .equ    SYS_MODE,            0b11111

        .equ    INT_ENABLE,          0b01000000
        .equ    INT_DISABLE,         0b11000000

.end