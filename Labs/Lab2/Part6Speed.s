
.define LED_ADDRESS 0x1000
.define HEX_ADDRESS 0x2000
.define SW_ADDRESS 0x3000
.define STACK 255
					mvi r1,#1
	
Reset:              mvi  r3,#0
					
IncrementCounter: 	mvi r0,#SW_ADDRESS
					ld 	r2,[r0]
					mvi r0,#LED_ADDRESS
					st  r3,[r0]
					add r3,r1
					
					
					
DelayLoop:			mvi r4,#2000
					mv  r5,r7
					mvi r0,#100
					add r4,r0
					sub r2,r1
					mvnz r7,r5
					
					mv   r5,r7
				    sub  r4,r1
					mvnz r7,r5
	
				
					mvi r6,#IncrementCounter
					mvnc r7,r6
					mvi r7,#Reset