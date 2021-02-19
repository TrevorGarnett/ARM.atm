@ Filename: Lab5.s
@ Author:   Trevor Garnett
@ Objective:  To advance student understanding of the basics of ARM Assemby.  
@ History:
@	Created 11/12, adding comments when necessary
@
@ Use these commands to assemble, link, run and debug this program:
@    as -o Lab5.o Lab5.s
@    gcc -o Lab5 Lab5.o
@    ./Lab5 ;echo $?
@    gdb --args ./Lab5 

@ ****************************************************
@ The = (equal sign) is used in the ARM Assembler to get the address of a
@ label declared in the .data section. This takes the place of the ADR
@ instruction used in the textbook. 
@ ****************************************************

.equ READERROR, 0 @Used to check for scanf read error. 

.global main @ Have to use main because of C library uses. 

main:

@*******************
prompt:
@*******************

@ Ask the user to enter a number.
   ldr r9, =withdrawn	   @ Pulling the address to the amount withdrawn thus far.
   ldr r9,[r9]		   @ Pulling the value from memory
   ldr r1,=#1500
   sub r10, r1, r9	   @ Find the amount to be given out
   cmp r10, #0		   @ If = 0, state there are no funds (go to that section)
   beq noFunds
   ldr r0, =numTransactions@ pulling the number of succesful transactions
   ldr r0, [r0]		   @ pulling the value from memory
   cmp r0, #10		   @ Update flags wrt 10
   beq limit		   @ If the max limit on transactions is met, say so and exit
   ldr r0, =welcomeMessage @ Put the address of my string into the first parameter
   bl  printf              @ Call the C printf to display input prompt. 

@*******************
get_input:
@*******************

@ Set up r0 with the address of input pattern
@ scanf puts the input value at the address stored in r1. We are going
@ to use the address for our declared variable in the data section - intInput. 
@ After the call to scanf the input is at the address pointed to by r1 which in this
@ case will be intInput. 

   ldr r0, =numInputPattern @ Setup to read in one number.
   ldr r1, =intInput        @ load r1 with the address of where the
                            @ input value will be stored.
   bl  scanf                @ scan the keyboard.
   cmp r0, #READERROR       @ Check for a read error.
   beq readerror            @ If there was a read error go handle it. 
   ldr r1, =intInput        @ Have to reload r1 because it gets wiped out. 
   ldr r1, [r1]             @ Read the contents of intInput so we can use it
   mov r3, r1		    @ Create a copy of r1 in r3.

   cmp r1, #0		    @ Compare to 0
   beq programEnd	    @ If that is the case, assume no cash is to be dispensed.
   
   cmp r1, #-9		    @ Compare to -9
   beq secretCode	    @ If equal, go there.

   cmp r1, #200             @ Updating flags wrt 200
   bgt readerror            @ The number entered is greater than 200, let readerror handle

@Confirm that the change is divisible by 10
change:
   cmp r1, #10		    @ Updating flags wrt 10
   blt readerror	    @ If r1 < 10, go to readerror
   beq enough		    @ If r1 = 10, exit loop
   sub r1, r1, #10	    @ r1 = r1 - 10
   b change		    @ Go back to see if making change from 10's and 20's is possible

@Now that we know the request is valid, check to see if we have enough to fulfill that request.
enough:
   cmp r10, r3		    @ Comparing r10 to r3
   bge continue		    @ If we have enough funds, continue and make change.
   b fundsDepleted

@Start the process of making change.
continue:   
   mov r1,r3		    @ move the originl input to r1

twenties:		    @ Make 20's first
   ldr r4, =remaining20s    @ Read the address for remaining 20's into r4
   ldr r5, [r4]		    @ Store that number in r5
   cmp r5, #0		    @ Check if there are any 20's to distribute
   beq tens		    @ If there are no 20's,try distributing 10's
   cmp r1, #20		    @ Compare r1 to 20
   blt tens     	    @ And if r1 < 20, attempt to make change with 10s
   sub r1,r1,#20	    @ Else, distribte a 20 and subtract that from the total that needs to be destributed.
   sub r5,r5,#1		    @ Note that a 20 has been distributed
   str r5, [r4]		    @ And store the number of remaining 20s in memory.
   ldr r4,=withdrawn	    @ load the address that contains the total withdrawn
   ldr r5, [r4]		    @ load the value into r5
   add r5, r5, #20	    @ Add 20 to the total withdrawn.
   str r5, [r4]		    @ Store new number in same location.
   ldr r4, =numTwenties     @ read the adress for the number of 20s distributed this transaction
   ldr r5, [r4]		    @ Read the value into r5 
   add r5, r5, #1	    @ Finally, note one more 20 has been distributed this transacion
   str r5, [r4]		    @ And store this in memory
   b twenties		    @ Attempt to make the remaining change out of 20s.

tens:			    @ make 10's if necessary
   cmp r1, #10
   blt changeDone	    @ If the change to be distributed is less than, stop
   sub r1, r1, #10	    @ Distribute a 10 and subtract that from the total that needs to be distributed
   ldr r4, =remaining10s    @ Read the address for remaining 10's into r4
   ldr r5, [r4]		    @ Store the number at this address in r5
   sub r5, r5, #1	    @ Note that a ten was distributed.
   str r5, [r4]		    @ Store the new number of remaing 10s
   ldr r4,=withdrawn	    @ load the address that contains the total withdrawn
   ldr r5, [r4]		    @ load the value into r5
   add r5, r5, #10	    @ Add 20 to the total withdrawn.
   str r5, [r4]		    @ Store new number in same location.
   ldr r4, =numTens	    @ Load in the address of the number of 10's distributed
   ldr r5, [r4]		    @ Load in the value of remaining 10s in r5
   add r5, r5, #1	    @ Add one, noting a 10 was distributed
   str r5, [r4]		    @ Store this new value at the address in r4 is pointing to
   b tens		    @ Attempt to make the remaining change out of 10s.

@All the bellow. Does is print the 20s and 10s required to fulfill the transaction request
changeDone:
   ldr r0, = numTransactions@ Load in the number of transactions so that can be adjusted
   ldr r1, [r0]
   add r1, r1, #1
   str r1, [r0]
   ldr r0, =printTwenty
   ldr r1, =numTwenties
   ldr r1, [r1]
   bl printf
   ldr r0, =printTen
   ldr r1, =numTens
   ldr r1,[r1]
   bl printf
   
@set the number of twenties dispensed to 0
   ldr r0, =numTwenties
   ldr r1, [r0]
   sub r1,r1, r1
   str r1, [r0]
@set the number of tens dispensed to 0
   ldr r0, =numTens
   ldr r1, [r0]
   sub r1,r1, r1
   str r1, [r0]

   cmp r10, r3		    @ compare the total money to requested fund.    
   beq myexit		    @ If the two are equal, then there are no more funds. Exit
   b prompt		    @ (we already no that the request isn't bigger than amount of funds)

@ The bellow section handles if the request is too large for remaining funds, but there are still funds
fundsDepleted:
   ldr r0, =littleMoney   
   bl printf
   b readerror		    @ Readerror will send back to the top of the program, so user can request smaller sum if needed.

@This section handles if there are 0 funds left. Therefore, it prints a statement and then ends the program.
noFunds:
   ldr r0, =zeroFunds
   bl printf
   b programEnd

@This section handles if the maximum amount of transactions was met.
limit:
   ldr r0, =limitReached
   bl printf
   b programEnd

@ This handles the print statements required when the program is ending 
@ either because transaction limit met, there is no more funds, or the user
@ entered 0 (meaning they did not want to withdraw any more funds
programEnd:
   ldr r0, =printTransactions
   ldr r1, =numTransactions
   ldr r1, [r1]
   bl printf
   ldr r2,=#50
   ldr r1, =remaining20s
   ldr r1, [r1]
   sub r1, r2, r1
   ldr r0,=given20s
   bl printf
   ldr r2,=#50
   ldr r1, =remaining10s
   ldr r1, [r1]
   sub r1, r2, r1
   ldr r0,=given10s
   bl printf
   mov r1,r9
   ldr r0, =totalGiven
   bl printf
   mov r1, r10			@ r10 here is calculated at the beginning of each transaction (in prompt)
   ldr r0, =remainingFunds	@ it represents the remaining funds
   bl printf
   b myexit
   
@ This sections handles when the user enters the
@ secret code '-9'. It is essentially just a lot
@ of print statements.
secretCode:
   ldr r0, =secretTwenty
   ldr r1, =remaining20s
   ldr r1, [r1]
   bl printf
   ldr r0, =secretTen
   ldr r1, =remaining10s
   ldr r1, [r1]
   bl printf
   mov r1, r10			@ r10 here is calculated at the beginning of each transaction (in prompt)
   ldr r0, =remainingFunds	@ it represents the remaining funds
   bl printf
   ldr r0, =printTransactions
   ldr r1, =numTransactions
   ldr r1, [r1]
   bl printf
   ldr r0, =printWithdrawn
   ldr r1, =withdrawn
   ldr r1,[r1]
   bl printf
   b prompt

@***********
readerror:
@***********
@ Got a read error from the scanf routine. Clear out the input buffer then
@ branch back for the user to enter a value. 
@ Since an invalid entry was made we now have to clear out the input buffer by
@ reading with this format %[^\n] which will read the buffer until the user 
@ presses the CR. 

   ldr r0, =strInputPattern
   ldr r1, =strInputError   @ Put address into r1 for read.
   bl scanf                 @ scan the keyboard.
@  Not going to do anything with the input. This just cleans up the input buffer.  
@  The input buffer should now be clear so get another input.

   b prompt


@*******************
myexit:
@*******************
@ End of my code. Force the exit and return control to OS

   mov r7, #0x01 @SVC call to exit
   svc 0         @Make the system call. 

.data

@ Declare the stings and data needed

.balign 4
welcomeMessage: .asciz "Greetings. Please input a number less than or equal to $200 that is divisible by $10 in order to receive change. If you would like to end this transaction, enter 0 \n"

.balign 4
printTen: .asciz "%d $10 bills were distributed in this transation. \n"

.balign 4
printTwenty: .asciz "%d $20 bills were distributed in this transation. \n"

@ Format pattern for scanf call.

.balign 4
numInputPattern: .asciz "%d"  @ integer format for read. 

.balign 4
strInputPattern: .asciz "%[^\n]" @ Used to clear the input buffer for invalid input. 

.balign 4
strInputError: .skip 100*4  @ User to clear the input buffer for invalid input. 

.balign 4
intInput: .word 0   @ Location used to store the user input.

.balign 4
numTwenties: .word 0 @ Defining the number of 20s we have distributed

.balign 4
numTens: .word 0 @ Defining the number of 10s we have distributed

.balign 4
remaining20s: .word 50 @ Defining the number of 20s we have

.balign 4
remaining10s: .word 50 @ Defining the number of 10s we have

.balign 4
littleMoney: .asciz "Looks like we do not have enough funds for that request. Please enter a smaller number if you would still like to withdraw money.  \n"

.balign 4
zeroFunds: .asciz "We have no more funds. Sorry, come back tomorrow. \n" 

.balign 4
numTransactions: .word 0 @ Defining the number of transactions.

.balign 4
limitReached: .asciz "The max number of Transactions has been reached. Come back tomorrow. \n"

.balign 4
secretTwenty: .asciz "Num 20's: %d \n"

.balign 4
secretTen: .asciz "Num 10's: %d \n"

.balign 4
printTransactions: .asciz "Number of transactions: %d \n"

.balign 4
printWithdrawn: .asciz "Total amount withdrawn: %d \n"

.balign 4
withdrawn: .word 0 @The amount withdrawn

.balign 4
given20s: .asciz "Twenties dispensed: %d \n"

.balign 4
given10s: .asciz "Tens dispensed: %d \n"

.balign 4
totalGiven: .asciz "A total of %d was distributed \n"

.balign 4
remainingFunds: .asciz "A total of %d remains \n"


@ Let the assembler know these are the C library functions. 

.global printf
@  To use printf:
@     r0 - Contains the starting address of the string to be printed. The string
@          must conform to the C coding standards.
@     r1 - If the string contains an output parameter i.e., %d, %c, etc. register
@          r1 must contain the value to be printed. 
@ When the call returns registers: r0, r1, r2, r3 and r12 are changed. 

.global scanf
@  To use scanf:
@      r0 - Contains the address of the input format string used to read the user
@           input value. In this example it is numInputPattern.  
@      r1 - Must contain the address where the input value is going to be stored.
@           In this example memory location intInput declared in the .data section
@           is being used.  
@ When the call returns registers: r0, r1, r2, r3 and r12 are changed.
@ Important Notes about scanf:
@   If the user entered an input that does NOT conform to the input pattern, 
@   then register r0 will contain a 0. If it is a valid format
@   then r0 will contain a 1. The input buffer will NOT be cleared of the invalid
@   input so that needs to be cleared out before attempting anything else. 
@

@end of code and end of file. Leave a blank line after this.
