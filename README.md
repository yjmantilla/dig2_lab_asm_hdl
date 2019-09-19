# lab_asm_hdl

#NOTES
1 completar codigo en ensamblador completamente funcional
2 completar funciones trap con hacking o con los comentarios ayuda
3 ensamblamos el codigo a hexadecimal


console echo wcmd


#cuteCom

pasar el ensamblador a la direccion 0

probar primero el echo del serial

CUTECOM

send program with hexoutput and hexinput
send numbers with lf end and script mode but hexoutput deactivated
crlf doesnt matter because program ignores cr character
doesnt matter how many stuff is in each line
10ms of delay for keeping good behaviour 
https://www.cyberciti.biz/faq/find-out-linux-serial-ports-with-setserial/
/dev/ttyS0, UART: 16550A, Port: 0x03f8, IRQ: 4
/dev/ttyS1, UART: 16550A, Port: 0x1020, IRQ: 18
/dev/ttyS2, UART: unknown, Port: 0x03e8, IRQ: 4
/dev/ttyS3, UART: unknown, Port: 0x02e8, IRQ: 3
IF YOU HAS 4 HEX VALUES PER LINE YOU DONT ACTUALLY NEED TO DIVIDE BY 2; IS JUST THAT NUMBER

input 1000 numbers in 100 sec(10ms delay) -> 10 numb/s or 60 char/s
highest 3 seconds 1000 nums
lowest  3 seconds 1000 nums (but was already ordered because of highest AO)
desc sort 46 sec 1000 nums AO
asc sort 46 sec 1000 nums AO
--> disp 1000 nums/ 46 sec = display vel=21.7 nums/s
show multiples : 37 seconds 1000 numbers (dont know multiple distribution)

55 - synchronize clock for communication
FF - start protocol
01 write 00 read
NNNN number of words (of 2 bytes) to write,  each line of assembler is a single word 1hex = 4 bits, --> 4 hex 16 bits which is a single asm instruction in the lc3
AAAA origin address to start
FA stop protocol
FF start protocol
S to start processor

 Once
the LC3 has started, the protocol is disabled and the serial communication
system allows your LC3 program to interact with the serial terminal interface.

delays of chars needed because of status register and sync logic, making a cross put get subroutine optimized for it may work