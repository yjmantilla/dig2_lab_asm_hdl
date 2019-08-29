		.orig x3000
BEGIN		ld r6 , SCOPE_STACK		; load initial stack pointer
		br MAIN_MSG

SCOPE_STACK    	.fill x4000



MSG_ENTER_N	.stringz "\n\nFirst enter N"
MSG_ENTER_NUM	.stringz "\n\nEnter nums"


MAIN_MSG	lea r0 , MSG_ENTER_N
		puts
MAIN		jsr INPUT
		jsr CHECK_N
		st r4 , N_STORE
		br INPUT_N_DONE
NUM_DONE	lea r0 , MSG_NUM_OK
		puts	
		br MENU
		MSG_NUM_OK .stringz "\nNums ok!"
INPUT_N_DONE	lea r0 , MSG_N_OK
		puts
		lea r0, MSG_ENTER_NUM
		puts
		br ENTER_NUM
		MSG_N_OK .stringz "\nN ok!"
MENU		lea r0 , MSG_MENU	;Shows menu and ask for option
		puts
		MSG_MENU .stringz "\n\nMENU\n\n1 N again\n2 Higher value\n3 Descending Sort\n4 MUL 4?\n5 Halt\n\nEnter op."
		jsr INPUT	; r4 now has option
		add r1 , r4 , #-5
		brz EXIT
		add r1 , r4 , #-1
		brz MAIN_MSG
		add r1 , r4 , #-2
		brz HIGH_VAL
		add r1 , r4 , #-3
		brz SORT_OPT
		add r1 , r4 , #-4
		brz MUL_4
		; else invalid option
		br WHAT	
WHAT		lea r0 , MSG_WHAT
		puts
		MSG_WHAT .stringz "\nWrong Input!"
		br MENU	


EXIT		halt	; end program
HIGH_VAL	lea r0 MSG_HIGH
		puts
		MSG_HIGH .stringz "\nHIGH VAL:\n"
		jsr SORT
		;show only first pos
		and r4 , r4 , #0
		add r4 , r4 , #1 ; only one
		jsr SHOW_PREP
		br MENU
		
SORT_OPT	lea r0 MSG_SORT
		puts
		MSG_SORT .stringz "\nDES.SORT:\n"
		jsr SORT
		ld r4 , N_STORE ; so SHOW_PREP knows how many to show
		jsr SHOW_PREP
		br MENU
		
SORT		ld r4 , N_STORE
		
OUTERLOOP	add r4, r4, #-1 ; r4 counter outer loop
		brnz SORTED
		add r5, r4, #0	; r5 counter inner loop
		lea r3 , DATA_STORE
		add r3 , r3 , #1 ; is the next because of the push
INNERLOOP	LDR     R1, R3, #0
		brn  NEG_1
      		LDR     R2, R3, #1  
       		brn  	SWAPPED
CONT		NOT     R6, R2       
        	ADD     R6, R6, #1  
         	ADD     R6, R1, R6  ; swap = item - next item
		BRP    SWAPPED     
SWAP          	STR     R2, R3, #0  
           	STR     R1, R3, #1  
SWAPPED   	ADD     R3, R3, #1  
           	ADD     R5, R5, #-1 
          	BRP     INNERLOOP   
         	BRNZP   OUTERLOOP 
  
SORTED		ret

NEG_1		LDR     R2, R3, #1
		brp	SWAP
		br 	CONT

		
SHOW_PREP	; Needs r3 with address of data array
		; Needs r4 with N
		add r1 , r7 , #0
		jsr PUSH_R1_SCOPE		
		lea r3 , DATA_STORE		; r3 <- address of data 
		add r3 , r3 , #1
SHOW_LOOP	lea r0 , MSG_NL
		puts
		add r4, r4, #-1		
		brn SHOW_END	
		ldr r0, r3, #0
		
		jsr DISPD
		add r3, r3, #1
		br SHOW_LOOP

SHOW_END 	jsr POP_R1_SCOPE
		add r7 , r1 , #0
		ret		

MUL_4		lea r0 , MSG_MUL4
		puts
		lea r5 DATA_STORE
		add r5 , r5 , #1
		and r3 , r3 , #0		; will be a counter
		ld  r1 , N_STORE
		jsr NEGATE_R1
		add r4 , r1 , 0
MUL_4_LOOP	ldr r1 , r5 , #0
		add r5 , r5 , #1
		; multiples of 4 finish in 00		
		and r0 , r1 , x0003	; mask with last 2 bits
		brz IS_MUL
CONT_M4		add r3 , r3 , #1
		add r0 , r3 , r4
		brz MUL_4_DONE
		br MUL_4_LOOP
		
IS_MUL		lea r0 , MSG_NL
		puts
		add r0 , r1 , #0
		jsr DISPD
		br CONT_M4
MUL_4_DONE	br MENU
MSG_NL .stringz " "




	
ENTER_NUM	;let r3 be the counter
		ld r3 , N_STORE
		lea r5 , DATA_STORE
ENTER_NUM_LOOP	add r3 , r3 , #-1
		brn NUM_DONE
		jsr INPUT
		add r1 , r4 , #0
		jsr PUSH_R1_DATA
		br ENTER_NUM_LOOP


N_STORE		.blkw 1				
		
NOT_IN_RANGE	lea r0 , MSG_ERROR_N
		puts
		br MAIN

M		.fill #4
DATA_STORE 	.blkw #31 ; because push pushes in the next
MSG_MUL4 .stringz "\n MUL4: \n"	
MSG_ERROR_N     .stringz "\nError: 15 <= N <= 30"
N_LOW		.fill #15 ;15
N_HIGH		.fill #30 ;30
CHECK_N		; check range for N
		; assumes N in r4
		add r1 , r7 , #0
		jsr PUSH_R1_SCOPE
		
		ld r1 , N_LOW
		jsr NEGATE_R1
		add r1 , r4 , r1
		brn NOT_IN_RANGE

		ld r1 , N_HIGH
		jsr NEGATE_R1
		add r1 , r4 , r1
		brp NOT_IN_RANGE
		
		jsr POP_R1_SCOPE
		add r7 , r1 , #0
		; else we are ready to go
		ret

INPUT		; subroutine, leaves stuff in r4
		; push r7 so we dont lose where we came from
		add r1 , r7 , #0 ; since PUSH_R1 pushes R1
		jsr PUSH_R1_SCOPE 


INPUT_NO_PUSH	lea r0 , MSG_ENTER
		
		; we dont need to push r7 so as long we
		; dont go to something that also goes to a subroutine

		MSG_ENTER .stringz "\nEnter it:"

		puts
		
		; R1 will be aux dummy reg
		; R2 will indicate if the number is negative or not
		; R4 will be accumulator, at the end will hold the final number
		
		and r2 , r2 , x0000
		and r4 , r4 , x0000
		
INPUT_I		getc	; gets c in r0
		
		
		add r1 , r0 , #-10	; check if enter was pressed
		brz YES_ENTER
		out	; echo what is in r0 (if not enter)
		
		; check if it is a negative number (-) (45)
		add r1 , r0 , #-15
		add r1 , r1 , #-15
		add r1 , r1 , #-15
		brz NEGATIVE
		

		; check if it is a number indeed
		add r1 , r0 , #0	; copy r0 in r1
		; check it is a number
		; first substract 48, if negative it is lower
		add r1 , r1 , #-16
		add r1 , r1 , #-16
		add r1 , r1 , #-16
		brn INPUT_I
		; we are already sure it is not lower
		; if it was a number we are now within 0 - 9
		; substract 9, if positive it was not a number
		add r1 , r1 , #-9
		brp INPUT_I	

		;convert to number
		and r0 , r0 , xF

ACCUM		add r1 , r4 , #0 ; r1 <- 1 r4
		brn OVERFLOW
		add r4 , r4 , r4 ; r4 <- 2 r1
		brn OVERFLOW
		add r4 , r4 , r4 ; r4 <- 4 r1
		brn OVERFLOW
		add r4 , r4 , r1 ; r4 <- 5 r1
		brn OVERFLOW
		add r4 , r4 , r4 ; r4 <- 10 r1
		brn OVERFLOW		
		add r4 , r4 , r0 ; r4 <= 10 r1 + r0
		brn OVERFLOW
		; check overflow for bubblesort-comparisons
		;add r1 , r4 , r4 ; 2 times the number have to be representable
		;brn OVERFLOW_BUBBLE

		; check overflow for ascii display
		;add r1 , r1 , r1 ; 4 times the number has to be representable
		; actually this is a bit too harsh, it will pass up to 8192
		; but the disp code admits up to 9999
		; currently trying to improve ascii conversion subroutine
		; done this no longer necessary
		; ascci conversion works up to 32767 
		;brn OVERFLOW_ASCII

		br INPUT_I
		
NEGATIVE	not r2 , r2
		br INPUT_I		

OVERFLOW	add r1 , r4 , r4
		brz CASE
OVERFLOW_2		lea r0 , MSG_OVERFLOW
		MSG_OVERFLOW .stringz "\nOverflow, try with a lower number."
		puts
		br INPUT_NO_PUSH
CASE		add r1, r2, #0
		brzp OVERFLOW_2
		br INPUT_I
OVERFLOW_BUBBLE lea r0 , MSG_B_OVERFLOW
		MSG_B_OVERFLOW .stringz "\nOverflow for comparison, try with a lower number."
		puts
		br INPUT_NO_PUSH
OVERFLOW_ASCII	lea r0 , MSG_A_OVERFLOW
		MSG_A_OVERFLOW .stringz "\nOverflow for ASCII decimal representation,try with a lower number."
		puts
		br INPUT_NO_PUSH		
INPUT_READY	; pop r7 to return (pop stack)
		
		jsr POP_R1_SCOPE
		add r7 , r1 , #0
		add r0 , r4 , #0
		

		ret	; go home boy

YES_ENTER 	; if enter was first char, it will just assume thats a 0
	
		; check if we need to negate
		add r1 , r4 , #0
		add r2 , r2 , #0
		brz DONT_NEGATE
		not r1 , r1
		add r1 , r1 , #1
		; either way we have the correct stuff in r1
		; move it back to r4
DONT_NEGATE	add r4 , r1 , #0
		br INPUT_READY







NEGATE_R1	; places in r1 the 2complement of r1
		not r1 , r1
		add r1 , r1 , #1
		ret


;LIFO STACK uses r1 as auxiliar register
PUSH_R1_SCOPE	;r6 is used as stack register
		add r6, r6, #1
		str r1, r6, #0
		ret	

POP_R1_SCOPE	;r6 used as an stack register
		ldr r1, r6, #0
		add r6, r6, #-1
		ret
PUSH_R1_DATA	;r5 us used as stack register
		add r5 , r5, #1
		str r1 , r5 ,#0
		ret
POP_R1_DATA	ldr r1 , r5 , #0
		add r5 , r5 ,#-1

; Following subroutines are from https://github.com/jrcurtis/lc3/blob/master/tests/lab5.asm
;
; Takes a 2's complement integer and displays its DECIMAL representation.
;
; THIS FUNCTION IS DIRECTLY DERIVED FROM DISPLAY ABOVE.
; THE ONLY MODIFICATION IS SIMPLIFIED OUTPUT. THE ALGORITHM IS THE SAME.
; BLOCK COMMENTS HAVE BEEN REMOVED FOR REDUNDANCY AND SPACE SAVING.
; THIS EXPECTS IN R0 THE NUMBER TO BE DISPLAYED

DISPD	ADD R0, R0, #0		; to assert if the number is not zero
	BRnp DISPD_NON_ZERO
	ST r7, DISPD_R7			; store home
	LD R0, DISPD_0		; load 0 in ascii
	OUT			; display to console
	LD R7, DISPD_R7		; load r7 again to return
	ret
DISPD_NON_ZERO
	; PREPARATION
	ST R0, DISPD_R0		; store original value of registers
	ST R1, DISPD_R1
	ST R2, DISPD_R2
	ST R3, DISPD_R3
	ST R4, DISPD_R4
	ST R5, DISPD_R5
	ST R7, DISPD_R7
	ADD r1, r0,r0
	brz SPECIAL_CASE
	AND R1, R1, #0	; clear r1
	ADD R1, R1, #1	; R1 holds current multiple of ten
	AND R2, R2, #0	; clear r2
	ADD R2, R2, #1	; R2 used by multiply and divide routines
	AND R3, R3, #0	; R3 holds current power of ten
	AND R4, R4, #0	; R4 holds plurality of current multiple
	AND R5, R5, #0	; R5 holds original number from R0
	ADD R5, R5, R0	; (because R0 needed for output)
	BRzp DISPD_LOOP_ASC ; assert number is not negative
	NOT R5, R5	; if it is negate it
	ADD R5, R5, #1	; Negate to positive
	LD R0, DISPD_NEG	; Input is negative. Display negative sign.
	OUT		; Now we may continue with de ascending loop
DISPD_LOOP_ASC		; this loop is to find the largest power of 10 used by the number
			; but it actually overshoots...
	AND R1, R1, #0	; clear r1
	ADD R1, R1, R5	; Set R1 to number
			; first cycle do note that r2 = 1
	JSR DIV		; How many times does ten*x go into number?
	add r1,r1,#-10
	BRn DISPD_LOOP_DESC	; If zero, then exit loop , here r3 is max power of 10 + 1 and r2 is 10 to that power (overshoots)
	AND R1, R1, #0		; Otherwise, keep multiplying, clear r1
	ADD R1, R1, #10		; set r1 to 10
	JSR MUL		; Highest multiple of ten up by one
			; first cycle r1 <= r1=10 * r2=1
	ADD R3, R3, #1	; One more power of ten
	AND R2, R2, #0	; clear r2
	ADD R2, R2, R1	; Store mul result in R2 for next loop, it is 10 to the power
	BR DISPD_LOOP_ASC
DISPD_LOOP_DESC		; by here r2 and r3 are overshooting (1 more power than it is actually)
	AND R1, R1, #0	; clear r1
	ADD R1, R1, R2	; Here R1 is current multiple of ten we're looking at
	LD R4, DISPD_0
DISPD_LOOP_DESC_AGAIN
	AND R2, R2, #0	; clear r2
	ADD R2, R2, R1	; Now we have a multiple of ten in R2 (divisor)
	AND R1, R1, #0
	ADD R1, R1, R5	; So we get our input number in R1 (dividend)
	JSR DIV		; And see how many times the one fits in the other
; Here is where we actually display something
	ADD R0, R1, R4	; ascii 0 + offset of the number
	OUT
	JSR MUL		; Multiply power of ten by result of integer division
	NOT R1, R1
	ADD R1, R1, #1	; And negate result
	ADD R5, R5, R1	; And subtract it from input number
	ADD R3, R3, #0	; If power of ten is zero
	BRz DISPD_END	; then we've output the last digit
	AND r1, r1, x0000
	add r1, r2, #0
	and r2,r2,#0
	add r2,r2,#10
	jsr DIV	; Divide our multiple of ten by ten
	; result is already in r1 for beginning of the loop
	add r3, r3, #-1
	
	BR DISPD_LOOP_DESC_AGAIN
DISPD_END
	LD R0, DISPD_R0
	LD R1, DISPD_R1
	LD R2, DISPD_R2
	LD R3, DISPD_R3
	LD R4, DISPD_R4
	LD R5, DISPD_R5
	LD R7, DISPD_R7
	RET
SPECIAL_CASE
	lea r0, CASE_STR
	puts
	br DISPD_END
DISPD_NEG	.FILL #45	; Negative sign
DISPD_0		.FILL #48	; ASCII 0
DISPD_R0	.FILL 0
DISPD_R1	.FILL 0
DISPD_R2	.FILL 0
DISPD_R3	.FILL 0
DISPD_R4	.FILL 0
DISPD_R5	.FILL 0
DISPD_R7	.FILL 0
CASE_STR	.stringz "-32768"


;
; Multiplies two integers.
;
; Preconditions: The number in R1 is multiplied with the number in R2.
; Postconditions: The number in R1 will be the product.
;
MUL	ST R0, MUL_R0
	ST R2, MUL_R2
	ST R3, MUL_R3
	AND R3, R3, #0	; R3 holds flag for negative
	ADD R1, R1, #0
	BRn MUL_NEG_1	; If operand 1 is negative, flip flag
MUL_CHECK_NEG_2
	ADD R2, R2, #0
	BRn MUL_NEG_2	; And if operand 2 is negative
MUL_POST_CHECK_NEG	; Now we know our arguments are positive
	AND R0, R0, #0	; R0 holds original number (absolute value)
	ADD R0, R0, R1
	AND R1, R1, #0	; R1 to 0 so adding R0 R2 times gives correct result
	BRnzp MUL_LOOP
MUL_NEG_1 ; First operand is negative
	NOT R3, R3	; Negative flag is negative when answer is negative
	NOT R1, R1	; Negate operand 1 (both numbers must be positive)
	ADD R1, R1, #1
	BRnzp MUL_CHECK_NEG_2
MUL_NEG_2 ; Second operand is negative
	NOT R3, R3
	NOT R2, R2	; Negate operand 2
	ADD R2, R2, #1
	BRnzp MUL_POST_CHECK_NEG
MUL_LOOP
	ADD R2, R2, #-1
	BRn MUL_POST_LOOP
	ADD R1, R1, R0	; Add R1 to itself (original saved in R0) R2 times
	BRnzp MUL_LOOP
MUL_POST_LOOP
	ADD R3, R3, #0
	BRzp MUL_CLEANUP	; If negative flag not set
	NOT R1, R1		; If it is, negate answer
	ADD R1, R1, #1
MUL_CLEANUP
	LD R0, MUL_R0
	LD R2, MUL_R2
	LD R3, MUL_R3
	RET
MUL_R0	.FILL 0
MUL_R2	.FILL 0
MUL_R3	.FILL 0


;
; Divides two integers.
;
; Preconditions: R1 is the dividen, R2 the divisor.
; Postconditions: R1 holds the quotient.
;
DIV	ST R0, DIV_R0
	ST R2, DIV_R2
	ST R3, DIV_R3
	AND R0, R0, #0	; R0 holds our quotient
	AND R3, R3, #0	; R3 holds negative flag
	ADD R1, R1, #0
	BRn DIV_NEG_1	; If first argument is negative flip flag
DIV_CHECK_NEG_2
	ADD R2, R2, #0
	Brn DIV_NEG_2	; Or the second
DIV_POST_CHECK_NEG
	NOT R2, R2
	ADD R2, R2, #1	; R2 (divisor) negated for repeated subtraction
	BRnzp DIV_LOOP
DIV_NEG_1 ; First operand is negative
	NOT R1, R1	; Negate first argument (both must be positive)
	ADD R1, R1, #1
	NOT R3, R3
	BRnzp DIV_CHECK_NEG_2
DIV_NEG_2 ; Second operand is negative
	NOT R2, R2	; Negate second argument
	ADD R2, R2, #1
	NOT R3, R3
	BRnzp DIV_POST_CHECK_NEG
DIV_LOOP
	ADD R1, R1, R2
	BRn DIV_CLEANUP	; We've subtracted once too many
	ADD R0, R0, #1	; Number of times it fits in goes up
	BRnzp DIV_LOOP
DIV_CLEANUP
	ADD R3, R3, #0
	BRzp DIV_NOT_NEG
	NOT R0, R0	; Here we know the output is negative, so negate it!
	ADD R0, R0, #1
DIV_NOT_NEG
	AND R1, R1, #0
	ADD R1, R1, R0	; Put our result in R1 for return
	LD R0, DIV_R0
	LD R2, DIV_R2
	LD R3, DIV_R3
	ADD R1, R1, #0	; Set condition codes for calling routine
	RET
DIV_R0	.FILL 0
DIV_R2	.FILL 0
DIV_R3	.FILL 0
.end