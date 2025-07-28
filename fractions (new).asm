.orig x3000

;Subroutine Instructions (code for them below main):

; Multiply (MULT):
; R0 is one of the numbers to multiply (A)
; R1 is the other (B)
; they are interchangable since A*B = B*A
; R2 is output

; Division (DIVIDE):
; R0 has numerator (A)
; R1 has denominator (B)
; R3 has result (A/B)
; R0 will return the remainder

; Exponentiation (EXP): 
;R0 is base (A)
;R1 is exponent (B). 
;R2 is our result (A^B)

; Logarithm (LOG):
;R0 is input to log (A) 
;R1 is base (B)
;R2 is output (log base B of A)
;R5 is "Round" or "Floor" mode - set R5 to 0 for "Round" and to 1 for "Floor"
; Round will round using "standard rounding rules" (up if the result has a half or greater, down otherwise)
; Floor will *always* round down


; We are assuming the user will use valid input

; R0 is our numerator
; R1 is our denominator

AND R5, R5, #0 ; clear R5 for our loop below

AND R2, R2, #0 ; clear our storage for getting the numerator/denom
LD R3, DIGIT_ASCII_OFFSET ; load the ascii offset for digits so we can convert to numbers

NOT R3, R3 ;negate the offset for comparison below
ADD R3, R3, #1 

NUMERATOR_INPUT GETC
OUT
ADD R5, R0, R3 ; compare input with / and loop if we haven't hit it yet
BRN NUM_INPUT_END

AND R0, R0, #0 ; clear R0 & set to our current numerator for multiplication
ADD R0, R2, #0 

AND R1, R1, #0 ; set R1 to 10 for multiplying to get correct positioning
ADD R1, R1, #10 

JSR MULT ; multiply

ADD R2, R2, R5 ; add digit to our current numerator

BRNZP NUMERATOR_INPUT ; branch back

NUM_INPUT_END ST R2, STORE_NUM ;store numerator so we don't erase it later

AND R2, R2, #0 ; clear R2 again
AND R5, R5, #0 ; clear R5 for our loop below

DENOM_INPUT GETC
OUT
ADD R5, R0, R3 ; compare input with enter and loop if we haven't hit it yet
BRN DENOM_INPUT_END

AND R0, R0, #0 ; clear R0 & set to our current numerator for multiplication
ADD R0, R2, #0 

AND R1, R1, #0 ; set R1 to 10 for multiplying to get correct positioning
ADD R1, R1, #10 

JSR MULT ; multiply

ADD R2, R2, R5 ; add digit to our current numerator

BRNZP DENOM_INPUT ; branch back

DENOM_INPUT_END ST R2, STORE_DENOM ;store denominator so we don't erase it later

AND R1, R1, #0 ; clear R1 and set to 2 for log2(x)
ADD R1, R1, #2

ADD R0, R2, #0 ; set our input to the log (i.e. the x in log2(x)) to our denominator

AND R5, R5, #0 ; set Log to Round 
JSR LOG ; take the log2 of our denominator

ADD R6, R2, #-1 ; store the exponent so we can retrieve it later after 5^x. Offset of -1 since you can't ever hit 5^0 representing non-zero fractions  
ST R6, STORE_R6 ; store for safekeeping since Exp subroutine uses R6

ADD R1, R2, #0 ; set the exponent input for the exp subroutine to our log result
AND R0, R0, #0 ; clear R0 and set it to 5 for exponentiation
ADD R0, R0, #5

JSR EXP ; do 5^x, where x is the result from our log

; adjusting the value for numerator by multiplying exponentiation result by the numerator (ex: if we have 2 as the numerator and 25 as the result above, we will multiply 25*2)
ADD R1, R2, #0 ;set R1 to our result from exponentiation so we can feed it into our multiplication algo 
LD R0, STORE_NUM ; load the numerator
JSR MULT ; multiply 

;left shift by 2 to fit the exponent bits
ADD R1, R2, #0 
AND R0, R0, #0
ADD R0, R0, #4
JSR MULT

LD R6, STORE_R6 ; restore exponent value

;add the exponent info to the number so we can differentiate numbers that end up encoded to the same thing (ex: 5/2 = 5 *(5^1) = 25 and 1/4 = 1*(5^2) = 25 )
ADD R2, R2, R6

ST R2, RESULT ;store result & Store the exponent so we can reconstruct the correct decimal placement later, even with fractions that have an "extra" power of five like 5/2


; human-readable output:
LD R0, RESULT ; load the fraction into R0
AND R5, R0, #3 ; mask to get exponent bits
ADD R5, R5, #1 ; 10^x has 1 more digit than exponent. We need how many digits 10^x contains for ensuring we put the decimal place in the right spot

AND R1, R1, #0 ; set divisor to 4 so we can right shift by 2 bits
ADD R1, R1, #4 

JSR DIVIDE ; right shift value by 2 bits to get the fraction representation
ADD R2, R3, #0 ; copy value from division t0 R2 so we can do the following loop without destruction

; loop to check how many digits we have in our representation of our fraction (because we need to compare it to how many digits 10^x has for correct decimal placement)
AND R4, R4, #0 ; clear R4, our counter


LEA R7, DIGIT_CHARS ;load address of DIGIT_CHARS array (R7 will be our pointer to next available location in array)
ADD R7, R7, #6 ; put pointer at the last character spot

DIGIT_COUNT_LOOP ST R4, STORE_R4 ; store R4 since divide will destroy it
ST R7, STORE_CONTEXT ;store R7 since our division subroutine will destroy it
ADD R0, R3, #0 ; copy value from division to R0 so we can divide by 10 repeatedly to see how many digits we have

AND R1, R1, #0 ; clear R1 and set to 10
ADD R1, R1, #10 

JSR DIVIDE ; divide number by 10

LD R7, STORE_CONTEXT ; restore our ASCII digit counter
LD R6, DIGIT_ASCII_OFFSET ;load 0x30 into R6 since its the offset between numbers and ascii digit chars

ADD R0, R0, R6 ; convert remainder into digit char

STR R0, R7, #0 ; store digit char into the DIGIT_CHAR char array, with R7 used as pointer to next available location

ADD R7, R7, #-1 ; decrement pointer

LD R4, STORE_R4 ; restore counter
ADD R4, R4, #1 ; increment counter

ADD R3, R3, #0 ; set condition code based on the value of division. 0 means we chopped off all the digits and need to exit. 
BRP DIGIT_COUNT_LOOP ; if the number is still positive, we still have more digits left

NOT R5, R5 ; negate the number of digits our corresponding power of 10 has so we can subtract the number of digits it has and our fraction representation to have the correct decimal placement
ADD R5, R5, #1

ADD R5, R5, R4 ; subtract the  number of digits our corresponding power of 10 has and our fraction representation to have the correct decimal placement. This will tell us whether we need to put it at the start ("0 places after leftmost digit"), 1 digit after the leftmost digit, etc. All negative values will be set to 0 since it just implies that we put the decimal at the start
BRZP #1 ; if the result was zero or positive, skip the setting of negative result to 0
AND R5, R5, #0 ; set result of "how many digits after leftmost digit to put decimal point" to 0 

; outputting to the screen
LEA R1, DIGIT_CHARS ; load address of the string/array for custom output handling

FIND_CHAR_LOOP LDR R0, R1, #0 ; load the character R1 is pointing to in the DIGIT_CHARS array
BRNP DISPLAY_LOOP ; if it exists and isn't null terminator, proceed to displaying it
ADD R1, R1, #1 ; advance pointer
BRNZP FIND_CHAR_LOOP

DISPLAY_LOOP ADD R5, R5, #-1 ; decrement the amount of spaces before we need to put a decimal place (yes this would *theoretically* lead to an extra decimal point but there's not nearly enough characters we could print in this loop for that to happen)
BRZP #3 ; skip displaying decimal point if we still have digits before decimal place unprinted or have printed the decimal point

LD R0, DECIMAL_POINT ; load the ascii value for decimal point into R0
OUT ; output decimal point
ADD R5, R5, #15 ; will never trigger printing decimal point again

LDR R0, R1, #0 ; load R0 with the next digit char
BRZ FINISHED_OUTPUT ; if we hit the null terminator, we are done


OUT ; output char
ADD R1, R1, #1 ; increment pointer into string/array 
BRNZP DISPLAY_LOOP ; unconditional branch back to top of loop

FINISHED_OUTPUT

HALT

; *********************************************************************
; *********************************************************************
; *********************************************************************
; subroutines



;Exponentiation subroutine. Only takes integers as input, returns only integers as output
;R0 is base (A)
;R1 is exponent (B). This also functions as our loop counter
;R2 is our result (A^B)

EXP ST R7, STORE_CONTEXT ;store callback address
AND R2, R2, x0 ; clear result

; "special cases"
ADD R1, R1, #0 ; set condition code based off R1
BRP EXP_NOSPECIAL ; if B is >0, proceed. Otherwise, set result to 1 and return

ADD R2, R2, #1 ;set result to 1
BRNZP EXP_FINISH ; unconditional branch to finish

EXP_NOSPECIAL ADD R2, R2, R0 ; set the base "result" to the base, since n^1 is n and we've covered n^0 above
ADD R6, R0 , #0 ; copy base value into R6 for safekeeping

;exponentiation loop
EXP_LOOP ADD R1, R1, #-1 ; cbeck if the loop is done by setting the condition code based on the "number of multiplications left" counter. We decrement by one because we need to multiply A by itself one less times than the exponent would indicate (since A^1 is just A).
BRZ EXP_FINISH ; if the counter is zero, then we are finished.

ST R1, STORE_R1 ; store R1 and R2 since they shouldn't be modified by mult subroutine
ST R2, STORE_R2

ADD R1, R6, #0 ; copy the base into R1 for repeated multiplication

JSR MULT ; multiply
ADD R0, R2, #0 ; set the multplication result to our current A, so we can just loop again with the same code if need be

LD R1, STORE_R1 ; restore R1 and R2 to pre-subroutine values
LD R2, STORE_R2

BRNZP EXP_LOOP 

EXP_FINISH ADD R2, R0, #0 ; store the result in R2 and return
LD R7, STORE_CONTEXT ; restore callback/return address
RET

;multiplication subroutine
;R0 is one of the numbers to multiply (A)
;R1 is the other (B)
;they are interchangable since A*B = B*A
; R2 is output

;what is multiplication? it's repeated addition -- add A to itself B times
MULT AND R2, R2, x0 ; clear R2

MULT_LOOP ADD R2, R2, R0 ; add R0 to itself (first pass we set R2=R0, then R2=R0+R0, etc)
ADD R1, R1, #-1 ; count the number of times we multiplied
BRP MULT_LOOP ; loop back if we still have more addiitons left
RET


;Log subroutine (rounding or floor). Only takes integers as input, only returns integers as output
;R0 is A 
;R1 is B
;R2 is output (log base B of A)
;R5 is "Round" or "Floor" mode (0 and 1 respectively). 
; EXTRA DETAILS:
; * bit 0 is treated as the "1/2" bit here to allow rounding
; * no left shifting or other action is necessary to prepare the input, just feed it like you would a normal log. Left shifting is done in the preprocessing shown below (specifically the line "ADD R0, R0, R0 ; Left shift R0 by 1 bit ...")
; * no left shift will occur when set to "Floor" mode since we are not using bit 0 as the "1/2 bit"

LOG ST R7, STORE_CONTEXT ; store return address
LEA R6, LOG_SWITCH_INSTR ; load the address of the left shift instruction so we can use our Round/Floor bit.
ADD R6, R6, R5 ; set address of correct line for Floor/Round mode (i.e. the JMP R6 skips the ADD R0, R0, R0 line if in floor mode)
AND R2, R2, x0000 ; clear result / counter

ADD R4, R0, #-1 ; check if A is 1, if it is, the result is 0.
BRZ FINISH ;if we are doing log(1), the result will always be 0 no matter the base
JMP R6 ;if the floor bit is set, skip over the next line (i.e. do not left shift by 1 bit and do not treat input as fixed pt)

LOG_SWITCH_INSTR ADD R0, R0, R0 ; Left shift R0 by 1 bit (internally we are using fixed point where bit 0 is 1/2 to implement rounding). Skipped if in floor mode


LOG_LOOP ST R1, STORE_R1
ST R2, STORE_R2

JSR DIVIDE ; our result of A/B will be stored in R3
ADD R0, R3, #0 ; set R0 to our the result of A/B (so if the divsion we did was 8/2, we set R0 to 4)
LD R1, STORE_R1 ; Restore R1, R2
LD R2, STORE_R2
ADD R2, R2, #1 ; increment number of times A is divisble by B


NOT R6, R1 ; negate the base so we can subtract to check if we should exit the log loop
ADD R6, R6, #1
 
ADD R4, R3, R6 ; check if the result of the division is less than the base. If it is, we've reached the end and finish (since we are "floor"/rounding down if not using fixed point). In the case of rounding / using fixed point, the number is treated as "2x" by the computer since its left shifted by one, so this line will never trigger until we've hit 1/2 of the base (at which point we know to round up/down)

LEA R6, LOG_SWITCH_LOOP_INSTR ; load the address of the next line into R6 so we can use our R5 switch bit as an offset to skip / not skip if we're in floor / rounnd
ADD R6, R6, R5
ADD R4, R4, #0 ; set condition code based on R4 and *not* the address of the BR line
JMP R6
LOG_SWITCH_LOOP_INSTR BRNZ FINISH ; branch back to loop only if the result of division > base (in case of rounding, since remember - everything was left shifted by 1 so equaling the base means it's actually 1/2 the base)
BRN FINISH ; branch back to loop only if the result of division >= base 
BRNZP LOG_LOOP

FINISH ;finished, restore callback register and return
LD R7, STORE_CONTEXT
RET

DIVIDE ; R0 has A, R1 has B. R3 has result (A/B). R0 returns remainder
AND R3, R3, #0 ; reset our division result storage

ADD R0, R0, #0 ; check if input is negative (if so, jump to alternate loop)
BRN NEGATIVE_DIV ; if numerator negative, jump to alt loop

; find the complement of B
NOT R1, R1
ADD R1, R1, #1

; loop: do A-B
DIV_LOOP ;check for remainders (i.e. is the number in R0 smaller in magnitude than R1)
ADD R4, R0, R1 ; this will add A and -B (i.e do A-B) and store result in R4. If this is negative, we have a remainder and we'll instantly finish. 
BRN FIN_DIV ;if we have a remainder, then exit the loop

ADD R0, R0, R1 ;add A and -B to get A-B

ADD R3, R3,#1 ;increment counter by 1

ADD R0, R0, #0 ;set the condition code bit based on how much we have left to subtract
BRP DIV_LOOP ; jump back to top of the loop if CC = P (ie R0 still has a positive number)

;return
FIN_DIV RET

NEGATIVE_DIV ; loop: do A-B
 ;check for remainders (i.e. is the number in R0 smaller in magnitude than R1)
ADD R4, R0, R1 ; this will add A and -B (i.e do A-B) and store result in R4. If this is positive, we have a remainder and we'll instantly finish. 
BRP FIN_DIV ;if we have a remainder, then exit the loop

ADD R0, R0, R1 ;add A and -B to get A-B

ADD R3, R3,#1 ;increment counter by 1

ADD R0, R0, #0 ;set the condition code bit based on how much we have left to subtract
BRN NEGATIVE_DIV ; jump back to top of the loop if CC = N (ie R0 still has a negative number)

RET ; return for negative div loop





NUMBER .FILL #12 ;this is our number to feed into the log (i.e. x in log(x)) but left shifted by one since we are treating bit 0 as the 1/2 bit
BASE .FILL #2
RESULT .BLKW #1 ;where we store our result

; Store original fraction bits so we don't over write
STORE_NUM .BLKW #1 ;numerator
STORE_DENOM .BLKW #1 ;denominator

;store registers for when we go into subroutine (caller save)
STORE_R1 .BLKW #1
STORE_R2 .BLKW #1 
STORE_R4 .BLKW #1
STORE_R6 .BLKW #1
STORE_CONTEXT .BLKW #1 ; save R7, our callback register

;store offset between ASCII digit chars and digits themselves 
DIGIT_ASCII_OFFSET .FILL x30

; store ascii value for decimal point
DECIMAL_POINT .FILL x2E
;store digits as ASCII chars for human output
DIGIT_CHARS .BLKW #8 ; allocated 8 spaces because 6 digits, +1 from decimal point , +1 for zero terminator

.end