; ************************************
; Example - Writing Values into Memory
; ************************************

		      .ORIG x0000	    ; For testing using the simulator, change this address to x3000 
          LD R0,MEMADDR
START:    AND R1,R1,#0
  		    ADD R1,R1,#15
LOOP:     ADD R2,R1,#0
		      NOT R2,R2
		      ADD R2,R2,#1
		      STR R2,R0,#0
		      ADD R0,R0,#1
		      ADD R1,R1,#-1
		      BRZ STOP
		      BR  LOOP
STOP:     BR  STOP	

MEMADDR:  .FILL x5000	    ; Instructions should not be at this address
		      .END
		      
