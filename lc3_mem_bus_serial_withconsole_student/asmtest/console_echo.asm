.ORIG x0000
START: LEA R0,MYMSG ; Load the Message Effective Address
JSR PUTSMSG ; Call the Puts Message subroutine (PUTS)

AGAIN: JSR GETCHAR ; Call the Get Char subroutine (GETC)
JSR PUTCHAR ; Call the Put Char suboutine (OUT)

END: BR AGAIN ; Wait for another character

GETCHAR: LDI r0, KBSR ; Read the Keyboard Status Register (KBSR) to check if there is a new char available (x8000)
brzp GETCHAR ; If KBSR != x8000, jump to GetChar
LDI r0, KBDR ; Read the Keyboard Data Register (KBDR) to take the incoming character
ret ; Subroutine return

PUTCHAR: st r0, PCR0  ; Store R0 into memory to keep a copy of the incoming character

PUTCHAR2: ldi r0, DSR ; Read the Display Status Register (DSR) to check if a character can be transmitted (x8000)
brzp PUTCHAR2 ; If (DSR != x8000), jump to PutChar2
ld r0 PCR0 ; Restore the character taken from the Keyboard to be sent to the display
sti r0, DDR ; Write the Display Data Register (DDR) with the character taken from the Keyboard
ret ; Subroutine return
PCR0: .FILL 0

PUTSMSG: st r0, PMR0 ; Store R0 into memory to keep a copy of the next char address
ldr r0,r0,#0; Load the char to be sent
brz PUTSMSGE ; Return if the char is NULL
st r7, PMR7 ; Store R7 because is needed by RET instruction
jsr PUTCHAR ; Send the char in R0
ld r7, PMR7 ; Restore R7
ld r0, PMR0 ; Restore the address of the char sent
add r0,r0,#1 ; Compute the address of the next char
br PUTSMSG ; Send the next char

PUTSMSGE: ret ; Subroutine return

PMR0 .FILL 0
PMR7 .FILL 0
KBSR: .FILL xFE00 ; Keyboard Status Register Address
KBDR: .FILL xFE02 ; Keyboard Data Register Address
DSR: .FILL xFE04 ; Display Status Register Address
DDR: .FILL xFE06 ; Display Data Register Address
MYMSG: .STRINGZ "\nHello, welcome to the ConsoleEchoing program test.\n\nPlease type any char you want to echo: "
.END