# LC3-Fractions
This project will take a fraction and output the closest power of two fraction representation (ex: "1/2" -> "0.5") on a machine where the only logic instructions are "ADD", "AND", and "NOT" (but contains data movement and control flow instructions) and also does not natively support fractions. It does this by encoding $\frac{x}{2^n}$ as $5^n$. Division, Multiplication, Exponentiation, and Rounding/Floor Logarithm were all implemented by hand with the 3 above logic instructions and load/store/branches.
I did it for fun in the summer before sophomore year because I like algorithms and wanted to see if I could bend the LC-3 to my will. I did - and it only took me a few days to do it. 

Table of Contents:
* [Main Code](#main-code)
  * [Representation of Fractions](#representation)
    * [Why storage of n is necessary](#why-storage-of-n-is-necessary)
  * [Input Handling](#input-handling)
  * [Output Handling](#output-handling)
    * [Implementation Details](#implementation-details)
* [Subroutines](#subroutines)
  * [Division](#division-truncates-result)
    * [In more detail](#in-more-detail)
    * [Division for negative numerators](#division-for-negative-numerators)
    * [Example Usage](#example-usage)
  * [Multiplication](#multiplication)
    * [In more detail](#in-more-detail-1)
    * [Why can only R0 be negative if the subroutine is otherwise commutative?](#why-can-only-r0-be-negative-if-the-subroutine-is-otherwise-commutative)
    * [Example Usage](#example-usage-1)
  * [Exponentiation](#exponentiation)
    * [In more detail](#in-more-detail-2)
    * [Example Usage](#example-usage-2)
  * [Logarithms](#logarithm)
    * [In more detail](#in-more-detail-3)
    * [Example Usage](#example-usage-3)
    * [Logarithm Mode Switching Algorithm](#logarithm-mode-switching-algorithm)
    * [Rounding trick](#rounding-trick)
    
## Main Code
The main purpose of this code is to take fractions like "1/2", "3/4", or "5/16" and have the LC-3 both represent and display them as decimals (so "0.5","0.75", or "0.3125" respectively). This was an exceptionally challenging and fun problem, as the LC-3 doesn't natively support anything beyond integers and to top if off the only arithmetic and logic instructions the LC-3 has are "ADD", "AND", and "NOT". This means that I had to create nearly everything from scratch - from input handling to the representation itself (by far the most fun and interesting part) to output. 

>[!NOTE]
> This code only perfectly represents $\frac{x}{2^n}$ due to the represenation. Anything else will be approximated to nearest power of two fraction.
>
> This also applies to fractions like "5/10" or others that are *nominally* different but still equal power of two fractions since I didn't implement a GCD in the code either.  

### Representation
$\frac{x}{2^n}$ can be represented as $x * (5^n)$ combined with a few bits to encode n effectively because $\frac{x}{2^n} = x*\frac{1}{2^n} = x*\frac{5^n}{10^n}$, so if you store the exponent and the value given by $5^n$ you can represent $\frac{x}{2^n}$ with only integers. Furthermore, in the decimal representation that $10^n$ effectively only controls the leading zeroes after the decimal point, so you can also do arithmetic with the representation as well by adding the $5^n$'s and storing only the largest n in the representation of the result (although not implemented here in this project). The representation is as follows:
 in a N bit representation, bits N through X are used to store the component ${5^n}$ and bits X through 0 are used to store the exponent n. 
 X is chosen by doing $B = log_{5}(2^R)$ (R for "representation bits", where we intially assign R as N) and then seeing how many bits are needed to represent B, recursively adjusting R by subtracting the number of bits needed to represent B (since we would need to store B at most).
In other words:
1. $B = \lceil log_{2}(5^{\lfloor log_{5} (2^R) \rfloor} \rceil$ <- tells us bits needed to store maximum power of 5 given R
2. $E = \lceil log_{2}(\lfloor log_{5} (2^R) \rfloor) \rceil$ <- tells us bits needed to store the maximum n
3. R = N-E <- Adjust R by E, since we must represent n and that uses up at most E bits
4. $B = \lceil log_{2}(5^{\lfloor log_{5} (2^R) \rfloor} \rceil$ <- Recalculate B
5. $E = \lceil log_{2}(\lfloor log_{5} (2^R) \rfloor) \rceil$ <- Recalculate E
6. Repeat until you maximize both storage capacity for $5^n$ and n itself

An example (how I did this for the LC-3's 16 bits): 
> note: I treat the LC-3 as 15 bits since I didn't want to implement negative fractions
> 
> $B = log_{2}(5^{\lfloor log_{5} (2^15) \rfloor} ≈ 14$
> 
> $E = \lceil log_{2}(\lfloor log_{5} (2^15) \rfloor) \rceil ≈ 3$
>
> but if we need 3 bits to store the bits for the exponent, then we must decrement the bit count for storage of info to 12:
> 
> $B = log_{2}(5^{\lfloor log_{5} (2^12) \rfloor} ≈ 12$
>
> $E = \lceil log_{2}(\lfloor log_{5} (2^12) \rfloor) \rceil ≈ 3$
> 
>
> Ultimately I decided that being able to represent a broader range of fractions with smaller powers of two was more important than being able to represent larger power of two fractions, so I settled on 2 bits for exponent and 13 bits for $5^n$ fraction representation.

> [!NOTE]
> The maximum n you can store with n bits is 2^n in this represenation, not 2^n - 1 because we have chosen to omit 5^0 since it is irrelevant. As an example, using my 2 bits for exponent in LC-3:
>
> 00 = 5^1
> 
> 01 = 5^2
> 
> 10 = 5^3
> 
> 11 = 5^4

#### Why storage of n is necessary
In our encoding scheme, there are many potential collisions that can only be resolved by storing n along with the $5^n$ representation. For example, if we didn't include n "1/4" and "5/2" would encode to *exactly* the same thing and therefore be indistinguishable. This is not acceptable, so we store the exponent bits to differentiate between the two.

The way you would represent $\frac{x}{2^n}$ instead of $\frac{1}{2^n}$ is by multiplying $5^n$ by the numerator (i.e. $x * (5)^n$ ). 
  * Doing this though means your fraction representation is no longer an exact power of 5 though, unless your numerator is a power of 5 itself. We will still refer to this encoded representation as "the $5^n$ representation" for simplicity and continuity, even if it may contain additional factors.

### Input Handling 
This is a more rote part, where we:
1. read one character at a time
2. convert from ASCII input to digits
3.  multiply the current result by 10
  * The result is initialized to 0 so the first multiplication by 10 does nothing.
4. add to the result

> Example: inputting 15
>
> 1. Result is 0
> 
> 2. Input: "1"
>
> 3. Convert ASCII "1" to 1
>
> 4. 0 * 10 = 0
>   
> 5. 0 + 1 = 1
>
> 6. Input: "5"
>
> 7. Convert ASCII "5" to 5
>
> 8. 1 * 10 = 10
>   
> 9. 10 + 5 = 15

This algorithm is used in numerator input (where we loop until we see the "/" character) and in denominator input (where we loop until we see the "newline" character")

### Output Handling
Whenever we want to output the fraction result, we need to ensure the decimal point is put in the correct position. To do this we use n (stored as part of the representation, see [representation section for details](#representation)) and count the number of digits in $10^n$, since "number of digits in $10^n$ - number of digits in our representation of the fraction via $5^n$" will tell us where to put the decimal point. In other words:
* Let D (for "decimal digits", since the number is a power of 10) = number of decimal digits in $10^n$
  * an easy way to calculate this is adding 1 to n, since $10^n$ is a "1" followed by n zeroes.
* Let F (for "Five's digits", since the number is based on a power of 5 even if the numerator may make it not an exact power of five) = number of decimal digits in $x * 5^n$
* F - D is how many positions away the decimal point is from the leftmost digit

Interpretation:
* if F-D > 0, then you have F-D+1 digits before the decimal point
* if F-D = 0, the decimal point comes right after the first digit.
* if F-D < 0, the decimal point is followed by (absolute value of F-D)-1 zeroes before the digits.

Example: 100/2
* $10^1$ = 10 <- 2 digits
* $100*(5^1)$ = 500 <- 3 digits
* 3-2 = 1
* Since it is positive, that means we have F-D+1 digits before the decimal point (in this case 1+1 = 2 digits)
* final result: "50.0"

Example: 3/2
* $10^1$ = 10 <- 2 digits
* $3*(5^1)$ = 15 <- 2 digits
* 2-2 = 0
* This means we have one character before the decimal point
* final result "1.5"

Example: 1/16
* $10^4$ = 10000 <- has 5 digits
* $5^4$ = 625 <- 3 digits
* 3-5 = -2
* this means we need 2 characters until we print the digits (i.e. ".0")
* final result: ".0625"

#### Implementation Details
We count the number of digits in $10^n$ by adding 1 to n, since $10^n$ is a "1" followed by n zeroes.
We count the number of digits in our representation of $5^n$ via a digit slicing and counting loop.
<br/>
Due to the way we store the exponent in the representation (the representation is offset by -1 compared to the number it represents - for example "00" represents n=1), the LC-3 code that is written will actually use a *slightly* different set of rules. This is because when we do not add that extra one to the representation before considering D, D is effectively decremented by one:

* If F-D > 0, we print F-D digits and then print a decimal point, and then continue printing digits
* If F-D = 0, we immediately print a decimal point, then all the digits
* If F-D < 0, we have a loop to print leading zeroes and increment the register we stored F-D in until the register hits 0. Only then do we enter the standard "output loop" and start printing digits.
  * In this case, there is no leading zero before the decimal point printed. 

Example: 100/2
* exponent "1" is represented as "00", so without adding the one before doing $10^n$, the amount of digits is reduced by one.
* $10^0$ = 1 <- 1 digit
* $100*(5^1)$ = 500 <- 3 digits
* 3-1 = 2
* Since it is positive, that means we have 2 digits before the decimal point 
* final result: "50.0"

Example: 3/2
* exponent "1" is represented as "00", so without adding the one before doing $10^n$, the amount of digits is reduced by one.
* $10^0$ = 1 <- 1 digit
* $3 * (5^1)$ = 15 <- 2 digits
* 2-1 = 1
* This means we have one character before the decimal point
* final result "1.5"

Example: 1/16
* exponent "4" is represented as "11", so without adding the one before doing $10^n$, the amount of digits is reduced by one.
* $10^3$ = 1000 <- has 4 digits
* $5^4$ = 625 <- 3 digits
* 3-5 = -1
* this means we need 1 zero until we print the digits (i.e. ".0")
* final result: ".0625"


## Subroutines
There are 4 subroutines: Division (named DIVIDE), Multiplication (named MULT), Exponentiation (named EXP), and Logarithm (LOG). All are arbitrary inputs, and the first two are primitives used by the latter.
All subroutines in LC-3 *will* destroy/change R7 due to the way subroutines are implemented in the architecture.
### Division (Truncates result)

 * R0 has the numerator
 * R1 has the denominator
 * R3 will contain the result
 * R0 will return the remainder (remainder matches sign of numerator)
 * Destroys R0, R1, R3, R4
<br/>

 * Input Limitations:
 * Numerator may be either positive or negative. Denominator may only be positive
 * 0 as denominator is considered invalid and will cause infinite loop.

> [!NOTE]
> This subroutine will transparently select the correct loop to divide positive or negative numbers, no action is necessary by user.

This subroutine implements division by repeated subtraction.
What we do here is subtract the denominator from the numerator until the remainder is less than our denominator and return how many times we subtracted. The remainder is returned in R0 automatically because we store the remainder in R0 by default (no moving it needed, just subtract where it is input)
  * This behavior differs slightly from the literal definition of division, but I needed a division function that would truncate the result.
  *  The reason that we stop as soon as the numerator is less than the denominator is because this way we will count the number of times we can subtract the denominator from the numerator wholly. This means by definition that we will truncate.

#### In more detail

* Preprocessing (in order):
  1. Reset loop counter (R3) to 0 
  2. Check if the numerator is negative, and if so branch to the negative division loop (explained further down under ["Division for negative numerators"](#division-for-negative-numerators))
  3. If positive, negate the denominator to prepare for repeated subtraction (LC-3 uses 2's complement so this process goes invert bits -> add 1)
 
* Division Loop:
  1. Check if current remainder is smaller than denominator. If so, exit
  2. Subtract denominator from current remainder <--- the reason 0 as denominator will cause infinite loop
  3. Increment loop counter by 1
  4. Check if current remainder is > 0. If so, loop back to Step 1

> EXAMPLE: 9/2
> 
> R0: 9
> 
> R1: 2
>
> Preprocessing:
> * Is 9 negative? No
> * Negate R1, so it now contains -2
> 
> Loop (loop counter initialized to 0):
>
> 9-2 = 7 (loop counter: 0 -> 1)
>
> 7-2 = 5 (loop counter 1 -> 2)
>
> 5-2 = 3 (loop counter 2 -> 3)
>
> 3-2 = 1 (loop counter 3 -> 4)
> 
> 1 is less than 2, so return to user
>
> Returned values:
> 
> R0: 1 (Remainder)
>
> R3: 4 (truncated division result)

#### Division for negative numerators
Here the behavior is nearly the same as the "normal" division code, but it will *add* the denominator to the numerator until the remainder hits 0 or becomes smaller than the denominator. Our "loop counter" decrements from 0 downwards into negative numbers as an implementation detail to get the correct sign (we return the value of the loop counter as the result, so to get the correct value with negative numbers the loop counter must decrement)

> EXAMPLE: -9/2
> 
> R0: -9
> 
> R1: 2
>
> Preprocessing:
> * Is 9 negative? Yes, so skip to negative numerator division
> 
> Loop (loop counter initialized to 0):
>
> -9+2 = -7 (loop counter: 0 -> -1)
>
> -7+2 = -5 (loop counter -1 -> -2)
>
> -5+2 = -3 (loop counter -2 -> -3)
>
> -3+2 = -1 (loop counter -3 -> -4)
>
> absolute value of -1 is less than 2, so return to user
>
> Returned values:
> 
> R0: -1 (Remainder)
>
> R3: -4 (truncated division result)

##### Example Usage
1. Example using the 9/2 scenario above: 
```
AND R0, R0, #0
ADD R0, R0, #9 ; set R0 to 9

AND R1, R1, #0
ADD R1, R1, #2 ; set R1 to 2

JSR DIVIDE ; call division subroutine
```
 > at this point, R0 contains 1 and R3 contains 4.


2. Example using the -9/2 scenario above: 
```
AND R0, R0, #0
ADD R0, R0, #-9 ; set R0 to -9

AND R1, R1, #0
ADD R1, R1, #2 ; set R1 to 2

JSR DIVIDE ; call division subroutine
```
 > at this point, R0 contains -1 and R3 contains -4.


### Multiplication
* R0 is one of the numbers to multiply
* R1 is the other 
  * they are interchangeable due to commutative property of multiplication
* R2 is output
* Destroys R1, R2
<br/>

* Input Limitations:
* R1 may not be negative.
  * Doing so will mean you will get an erroneous result due to the multiplication loop's stop condition (explained in detail below).

> [!WARNING]
> Due to LC-3's limited memory, multiplication with large numbers (ex: 200x200) will overflow into negatives or otherwise yield erroneous results!!
> The LC-3 can store -32768 to 32,767, so ensure multiplication results will fall in this boundary. If multiplication would end with > +32767, it ***will overflow*** into negative numbers and vice versa.

This subroutine implements multiplication by repeated addition. What we do here is add R0 to R2 the number of times specified by R1.


#### In more detail

* Preprocessing (in order):
  1. Reset result holder (R2) to 0 
  2. Check if *either* of the inputs is 0. If so, immediately exit and return 0 

* Multiplication Loop:
  1. Add our input in R0 to R2
  2. Decrement loop counter (given as input in R1)
  3. If loop counter > 0, loop back to Step 1

> EXAMPLE: 3*5
>
> R0: 3
>
> R1: 5
>
> Preprocessing :
>  * set R2 to 0
>  * is 3 = 0? No, continue
>  * is 5 = 0? No, continue
>
> Loop: 
> 3 = 0 + 3 (loop counter 5 -> 4)
>
> 6 = 3 + 3 (loop counter 4 -> 3)
> 
> 9 = 6 + 3 (loop counter 3 -> 2)
>
> 12 = 9 + 3 (loop counter 2 -> 1)
>
> 15 = 12 + 3 (loop counter 1 -> 0)
>
> loop counter ≤ 0, so exit loop and return 15 in R2.
>
> in the case of 5*3, we will just add *5 3 times* instead of *3 5 times*


> EXAMPLE: -3*5
>
> R0: -3
>
> R1: 5
>
> Preprocessing :
>  * set R2 to 0
>  * is -3 = 0? No, continue
>  * is 5 = 0? No, continue
>
> Loop: 
> -3 = 0 - 3 (loop counter 5 -> 4)
>
> -6 = -3 - 3 (loop counter 4 -> 3)
> 
> -9 = -6 - 3 (loop counter 3 -> 2)
>
> -12 = -9 - 3 (loop counter 2 -> 1)
>
> -15 = -12 - 3 (loop counter 1 -> 0)
>
> loop counter ≤ 0, so exit loop and return -15 in R2.

> EXAMPLE: 3 * -5 (or, a demonstration of what happens if you put a negative number in R1 as input)
>
> R0: 3
>
> R1: -5
>
> Preprocessing :
>  * set R2 to 0
>  * is 3 = 0? No, continue
>  * is -5 = 0? No, continue
>
> Loop: 
>
> 3 = 0 + 3 (loop counter -5 -> -6)
>
> loop counter ≤ 0, so exit loop and return 3 in R2.


> EXAMPLE: 0*4
>
> R0: 0
>
> R1: 4
>
> Preprocessing :
>  * set R2 to 0
>  * is 0 = 0? Yes, skip loop and return 0 in R2
>  * the check for "is R1 = 0?" is skipped since R0 was already found to be 0.
>
> Loop: skipped over
>
> exit loop and return 0 in R2.
>


> EXAMPLE: 4*0
>
> R0: 4
>
> R1: 0
>
> Preprocessing :
>  * set R2 to 0
>  * is 4 = 0? No, continue
>  * is 0 = 0? Yes, skip loop return 0 in R2
> Loop: skipped over
>
> exit loop and return 0 in R2.
>

##### Why can only R0 be negative if the subroutine is otherwise commutative? 
 The way the subroutine is implemented, we treat the number given in R1 as our loop counter (i.e. how many times we need to add R0 to get our result) and stop looping when R1 ≤ 0. To do this, we decrement R1 after adding R0 to R2. This means that if you were to attempt 5 x -2 (i.e. R0: 5, R1: -2) instead of -2 x 5 (R0: -2, R1: 5), we would only loop once. I did not fix this because it was unnecessary for the project at hand.

##### Example Usage

1. Example using the 3*5 scenario above: 
```
AND R0, R0, #0
ADD R0, R0, #3 ; set R0 to 3

AND R1, R1, #0
ADD R1, R1, #5 ; set R1 to 5

JSR MULT ; call multiplication subroutine
```
 > at this point, R0 contains 3, R1 contains 0, and R2 contains 15.


2. Example using the -3*5 scenario above: 
```
AND R0, R0, #0
ADD R0, R0, #-3 ; set R0 to -3

AND R1, R1, #0
ADD R1, R1, #5 ; set R1 to 5

JSR MULT ; call multiplication subroutine
```
 > at this point, R0 contains -3, R1 contains 0, and R2 contains -15.

### Exponentiation
* R0 has the base
* R1 has the exponent
* R2 will contain the result
* Destroys R0, R1, R2, R6
<br/>

* Input Limitations:
* Base must be positive, exponent must be non-negative.
  * Base being negative will trigger [invalid input to multiplication since we feed the base in via R1](#why-can-only-r0-be-negative-if-the-subroutine-is-otherwise-commutative)
  * Exponent being negative will cause excessive iterations since we use the exponent as the loop counter and stop when R1 = 0. (i.e. calling it with a negative exponent will mean we will overflow from negative -> positive, and then finally exit when we go positive -> 0)

> [!WARNING]
> Due to LC-3's limited memory, exponentiation with even small numbers (ex: 5^7) will overflow into negatives or otherwise yield erroneous results!
> The LC-3 can store -32768 to 32,767, so ensure exponentiation results will fall in this boundary. If exponentiation would end with > +32767, it ***will overflow*** into negative numbers.

This subroutine implements exponentiation via repeated [multiplication](#multiplication). We multiply the base by itself the number of times given in R1.

#### In more detail

* Preprocessing (in order):
  1. Store callback/return address (address of caller instruction) so multiplication doesn't destroy/overwrite it and we can properly return. 
  2. Reset result holder (R2) to 0 
  3. Check if exponent is 0. If so, immediately exit and return 1
  4. If exponent > 0, set result to base
  5. Save base (copy into R6) so it isn't destroyed

* Exponentiation Loop:
  1. Decrement loop counter (given as input in R1)
  2. If loop counter = 0, exit and return result in R2
  3. Store loop counter (R1) and current result (R2) to prevent destruction from multiplication
  4. Copy base from R6 to R1 to feed into multiplication
  5. Multiply
  6. Set multiplication result to multiplication input (R0)
  7. Restore loop counter and current result
  8. Loop back to Step 1

* Are you sure this works for $b^1$? 
Yes, this will handle $b^1$ perfectly fine because we set the running result to the base by default. When we evaluate the loop condition (which functionally has the condition of "run when exponent > 1"), we will fail and skip the loop. This means we will return the default result (the base itself) as the result.

* Why are you using R6 to store the base? Why not just store it in memory and load/store when necessary?
This way, we need less instructions (no pair of LD/ST per loop) *and* store/load takes more time than just copying from R6 into R1.
  * Ok but why are you saving R1 and R2 in memory then? Doesn't that pose the same drawbacks?
    Yes, it does. It's a tradeoff because the LC-3 has only 8 registers and I didn't want to do callee save (it's quicker to just store the required values in the preserved registers).

> EXAMPLE: $2^2$
>
> R0: 2
>
> R1: 2
>
> Preprocessing:
> * Store callback
> * Reset result holder to 0
> * Is 2 = 0? No, so continue
> * Set current result to 2
> * Copy 2 into R6 from R0
>
> At this point:
> R0: 2
> 
> R1: 2
>
> R2: 0
>
> R6: 2
> 
> Loop:
> 
> **1st Iteration**
>
> loop counter 2 -> 1
>
> Is loop counter = 0? No, so continue
>
> Store loop counter (R1) and current result (R2) in memory
> 
> Copy 2 from R6 into R1 (base at this point is now in *two* registers - R0 and R1)
>
> Call multiplication subroutine with inputs 2 (R0), 2 (R1) and get result of 4
>
> Set multiplication input #1 (R0) to 4
>
> Restore loop counter (R1) and current result (R2) from memory
> > At this point, R0 has 4 since we did 2*2
> 
> **2nd Iteration***
>
> loop counter 1 -> 0
>
> Is loop counter = 0? Yes, skip the loop and return
>
> Set R2 to 4 and return


> EXAMPLE: $2^3$
>
> R0: 2
>
> R1: 3
>
> Preprocessing:
> * Store callback
> * Reset result holder to 0
> * Is 2 = 0? No, so continue
> * Set current result to 2
> * Copy 2 into R6 from R0
>
> At this point:
> R0: 2
> 
> R1: 3
>
> R2: 0
>
> R6: 2
> 
> Loop:
> 
> **1st Iteration**
>
> loop counter 3 -> 2
>
> Is loop counter = 0? No, so continue
>
> Store loop counter (R1) and current result (R2) in memory
> 
> Copy 2 from R6 into R1 (base at this point is now in *two* registers - R0 and R1)
>
> Call multiplication subroutine with inputs 2 (R0), 2 (R1) and get result of 4
>
> Set multiplication input #1 (R0) to 4
>
> Restore loop counter (R1) and current result (R2) from memory
> > At this point, R0 has 4 since we did 2*2
> 
> **2nd Iteration***
>
> loop counter 2 -> 1
>
> Is loop counter = 0? No, so continue
>
> Store loop counter (R1) and current result (R2) in memory
> 
> Copy 2 from R6 into R1 (now we have 4 in R0 and 2 in R1)
>
> Call multiplication subroutine with inputs 4 (R0), 2 (R1) and get result of 8
>
> Set multiplication input #1 (R0) to 8
>
> Restore loop counter (R1) and current result (R2) from memory
> > At this point, R0 has 8 since we did 4*2
>
> 
> **3rd Iteration***
>
> loop counter 1 -> 0
>
> Is loop counter = 0? Yes, skip the loop and return
>
> Set R2 to 8 and return

> EXAMPLE: $5^1$
>
> R0: 5
>
> R1: 1
>
> Preprocessing:
> * Store callback
> * Reset result holder to 0
> * Is 1 = 0? No, so continue
> * Set current result to 5
> * Copy 5 into R6 from R0
>
> At this point:
> R0: 5
> 
> R1: 1
>
> R2: 0
>
> R6: 5
> 
> Loop:
> 
> **1st Iteration**
>
> loop counter 1 -> 0
>
> Is loop counter = 0? Yes, skip the loop and return
>
> Set R2 to 5 and return

> EXAMPLE: $5^0$
>
> R0: 5
>
> R1: 0
>
> Preprocessing:
> * Store callback
> * Reset result holder to 0
> * Is 0 = 0? Yes, so set result to 1 and return
> * {Rest of preprocessing and subsequent loop skipped}
>   
> At this point:
> R0: 5
> 
> R1: 0
>
> R2: 1
>
> R6: untouched
>
> loop: skipped

##### Example Usage
1. Example using the 2^3 scenario above: 
```
AND R0, R0, #0
ADD R0, R0, #2 ; set R0 to 2

AND R1, R1, #0
ADD R1, R1, #3 ; set R1 to 3

JSR EXP ; call exponentiation subroutine
```
 > at this point, R0 contains 8, R1 contains 0, and R2 contains 8.

2. Example using the 5^1 scenario above: 
```
AND R0, R0, #0
ADD R0, R0, #5 ; set R0 to 5

AND R1, R1, #0
ADD R1, R1, #1 ; set R1 to 1

JSR EXP ; call exponentiation subroutine
```
 > at this point, R0 contains 5, R1 contains 0, and R2 contains 5.

### Logarithm
* R0 has the input to the log (A)
* R1 has the log base (B)
* R2 will contain the result ( $log_{B}(A)$ )
  * Results are always integers 
* R5 is "Round" or "Floor" mode
  * R5 = 0 is "Round" (round to nearest integer - e.g. if the result would contain fraction parts ≥ 0.5 round up. Round down otherwise)
  * R5 = 1 is "Floor" (always truncate result)
>[!CAUTION]
> Destroys *all* registers, so *save* what you need in memory *before calling*

>[!WARNING]
> R5 *must be* either 0 or 1. Anything else ***will*** cause unintended behavior (and potentially even *hardfaults/"program crashes"* due to prohibited memory access attempts) due to the way the switching between Round/Floor works.

* Input Limitations:
* Base must be positive (as in a "real" log), Input to the base B log must be positive

This subroutine implements logarithms by repeated [division](#division-truncates-result), with output rounded to nearest integer or truncated depending on user selection.
What we do here is divide the input to the log by the base until the quotient is less than the base itself
  * This behavior differs slightly from the literal definition of logarithms, but I needed a logarithm function that would truncate the result *or* round.
  *  The reason that we stop as soon as the quotient is less than the base is because this way we will count the number of times we can divide the number by the base wholly. This means by definition that we will truncate.

#### In more detail
The rounding behavior is done by simulating fixed point in a way that forces the loop to run an extra time if the result would have a fractional part ≥ 0.5 ([see "Rounding trick" below](#rounding-trick))

* Preprocessing (in order):
  1. Store callback/return address (address of caller instruction) so division doesn't destroy/overwrite it and we can properly return. 
  2. Calculate address of the instruction to set Round/Floor mode by jumping
    * *in further details*: Rounding mode will left shift input by 1 bit to simulate fixed point, Floor mode will not. (see ["Logarithm Mode Switching Algorithm"](#logarithm-mode-switching-algorithm) and ["Rounding trick"](#rounding-trick))
  3. Clear result storage (R2) 
  4. Check if input to log is 1. If so, immediately exit and return 0
  5. Jump to instruction that sets Round/Floor

* Logarithm Loop:
  1. Store log base (R1) and loop counter (R2)
  3. Divide (log input in R0 and log base in R1 naturally aligns with division subroutine inputs)
  4. Set numerator for division to division output
  5. Restore log base (R1) and loop counter (R2)
  6. Increment loop counter
  7. Check if our quotient is less than the base
  8. Check against the appropriate loop condition (changes based on mode, see ["Logarithm Mode Switching Algorithm"](#logarithm-mode-switching-algorithm) for more details)
    8.1 In rounding mode the loop condition is "quotient greater than base" since our mock fixed point values are treated as twice their intended value by the architecture
    8.2 In floor mode the loop condition is "quotient greater or equal than base" because we have not shifted the values so no need to have special handling
  9. Loop back to Step 1 if appropriate
 
> EXAMPLE: $log_{2}(4)$ (in rounding mode)
>
> R0: 4
>
> R1: 2
>
> R5: 0
> 
> Preprocessing:
> * Store callback
> * Calculate address of instruction to set Round/Floor mode
> * Reset result holder (R2) to 0
> * Is 4 = 1? No, so continue
> * R5 = 0 -> Rounding mode -> left shift input by one bit to simulate fixed point (so our "4" now reads as "8" to the computer)
>
> Loop:
> 
> ***1st Iteration***
>
> Store log base (R1 = 2) and loop counter (R2 = 0)
>
> Divide 8/2 and get result 4
>
> Set 4 as the numerator for the next iteration
>
> Restore log base (R1 = 2) and loop counter (R2 = 0)
>
> loop counter 0 -> 1
>
> Is 4 > 2? Yes, so loop back
> 
>  * (in rounding mode, so checking "quotient greater than base?")
>
> ***2nd Iteration***
>
> Store log base (R1 = 2) and loop counter (R2 = 1)
>
> Divide 4/2 and get result 2
>
> Set 2 as the numerator for the next iteration
>
> Restore log base (R1 = 2) and loop counter (R2 = 1)
>
> loop counter 1 -> 2
>
> Is 2 > 2? No, so exit and return 2 in R2

> EXAMPLE: $log_{2}(4)$ (in floor mode)
>
> R0: 4
>
> R1: 2
>
> R5: 1
> 
> Preprocessing:
> * Store callback
> * Calculate address of instruction to set Round/Floor mode
> * Reset result holder (R2) to 0
> * Is 4 = 1? No, so continue
> * R5 = 1 -> Floor mode -> no special handling
>
> Loop:
> 
> ***1st Iteration***
>
> Store log base (R1 = 2) and loop counter (R2 = 0)
>
> Divide 4/2 and get result 2
>
> Set 2 as the numerator for the next iteration
>
> Restore log base (R1 = 2) and loop counter (R2 = 0)
>
> loop counter 0 -> 1
>
> Is 2 ≥ 2? Yes, so loop back
> 
>  * (in floor mode, so checking "quotient ≥ base?")
>
> ***2nd Iteration***
>
> Store log base (R1 = 2) and loop counter (R2 = 1)
>
> Divide 2/2 and get result 1
>
> Set 1 as the numerator for the next iteration
>
> Restore log base (R1 = 2) and loop counter (R2 = 1)
>
> loop counter 1 -> 2
>
> Is 1 ≥ 2? No, so exit and return 2 in R2
>

> EXAMPLE: $log_{3}(1)$ (in rounding mode)
>
> R0: 1
>
> R1: 3
>
> R5: 0
> 
> Preprocessing:
> * Store callback
> * Calculate address of instruction to set Round/Floor mode
> * Reset result holder (R2) to 0
> * Is 1 = 1? Yes, so skip loop and return 0 in R2

> EXAMPLE: $log_{3}(6)$ (in rounding mode)
>
> R0: 6
>
> R1: 3
>
> R5: 0
> 
> Preprocessing:
> * Store callback
> * Calculate address of instruction to set Round/Floor mode
> * Reset result holder (R2) to 0
> * Is 6 = 1? No, so continue
> * R5 = 0 -> Rounding mode -> left shift input by one bit to simulate fixed point (so our "6" now reads as "12" to the computer)
>
> Loop:
> 
> ***1st Iteration***
>
> Store log base (R1 = 3) and loop counter (R2 = 0)
>
> Divide 12/3 and get result 4
>
> Set 4 as the numerator for the next iteration
>
> Restore log base (R1 = 3) and loop counter (R2 = 0)
>
> loop counter 0 -> 1
>
> Is 4 > 3? Yes, so loop back
>  * (in rounding mode, so checking "quotient greater than base?")
>
> ***2nd Iteration***
>
> Store log base (R1 = 3) and loop counter (R2 = 1)
>
> Divide 4/3 and get result 1
>
> Set 1 as the numerator for the next iteration
>
> Restore log base (R1 = 3) and loop counter (R2 = 1)
>
> loop counter 1 -> 2
>
> Is 1 > 2? No, so exit and return 2 in R2
>





> EXAMPLE: log base 3 of 6 (in floor mode)
>
> R0: 6
>
> R1: 3
>
> R5: 1
> 
> Preprocessing:
> * Store callback
> * Calculate address of instruction to set Round/Floor mode
> * Reset result holder (R2) to 0
> * Is 6 = 1? No, so continue
> * R5 = 1 -> Floor mode -> no special handling
>
> Loop:
> 
> ***1st Iteration***
>
> Store log base (R1 = 3) and loop counter (R2 = 0)
>
> Divide 6/3 and get result 2
>
> Set 2 as the numerator for the next iteration
>
> Restore log base (R1 = 3) and loop counter (R2 = 0)
>
> loop counter 0 -> 1
>
> Is 2 ≥ 3? No, so exit and return 1 in R2
> 
>  * (in floor mode, so checking "quotient ≥ base?")

##### Example Usage
1. Example using the rounding $log_{2}(8)$ scenario above: 
```
AND R0, R0, #0
ADD R0, R0, #8 ; set R0 to 8

AND R1, R1, #0
ADD R1, R1, #2 ; set R1 to 2

AND R5, R5, #0 ; set R5 to 0 (rounding)

JSR LOG ; call logarithm subroutine
```
 > at this point:
 > * R0 contains 2
 > * R1 contains 2
 > * R2 contains 3
 > * R3 contains 2
 > * R4 contains 0
 > * R5 contains 0
 > * R6 contains {memory location for switching modes}

 
2. Example using the floor $log_{2}(8)$ scenario above: 
```
AND R0, R0, #0
ADD R0, R0, #8 ; set R0 to 8

AND R1, R1, #0
ADD R1, R1, #2 ; set R1 to 2

AND R5, R5, #0 ; set R5 to 1 (floor)
ADD R5, R5, #1

JSR LOG ; call logarithm subroutine
```
 > at this point:
 > * R0 contains 1
 > * R1 contains 2
 > * R2 contains 3
 > * R3 contains 1
 > * R4 contains -1
 > * R5 contains 1
 > * R6 contains {memory location for switching modes}

##### Logarithm Mode Switching Algorithm
The way we do this mode switching between rounding and floor is by essentially using a dynamic jump instruction. We need this because the LC-3 doesn't have a way to conditionally execute instructions built in and I wanted to find an elegant solution that avoided repeated code. How it works:
(at the start of the subroutine)
1. User inputs 0 or 1 into R5 as the "switch bit"
2. We fetch the address of the line that left shifts the input by 1 bit
3. We add the user's input in R5 to that address and jump to that calculated address.
This way if the user inputs "0" into R5 the jump functions as a no-op and we pass onto the next instruction (the left shift), but if they input 1 in R5 the jump will skip over the left shift line and then continue business as usual.
  * The reason that this one line decides the behavior of the log is described in ["Rounding trick"](#rounding-trick) below.

(at the end of the loop)
1. We fetch the address of the line that evaluates the loop condition for round mode
2. We add the user's input in R5 to that address and jump to that calculated address.
  * there are 2 branch instructions one after another:
    * The first one (this one is for rounding mode) will branch back if quotient > base
    * The second one (this one is for floor mode) will branch back if quotient ≥ base
    * Because of the way this is coded (the first branch is "more restrictive" in what condition codes it allows to fall through), if we fall through the first branch we can *not* erroneously trigger the second one in rounding mode.
3. We loop back to the top of the loop depending on the branch we executed

##### Rounding trick
The way we implement rounding in the logarithm is by left shifting the input by one bit to simulate a "1/2 bit" in fixed point. The reason this works is because the computer effectively treats our value as twice the intended value, which means that we will go through one more loop *if and only if* the fractional parts would be ≥ 0.5 since 0.5*2 = 1 (and so we actually add 1 to the computer's representation of our number). If the fractional part would be less than 0.5, multiplying it by 2 would still yield less than one and due to the LC-3 only supporting integers that fractional part would not be represented then.
> Example ( $log_{3} (6)$ which for reference ≈ 1.6):
> 
> Without left shifting:
> 
> 6/3 = 2 (represented as 0000 0000 0000 0010)
>
> 2/3 ≈ 0.67 (represented as 0000 0000 0000 0000 since LC-3 doesn't support fractions and the [division subroutine](#division-truncates-result) truncates)
>  * this iteration doesn't take place in the algorithm since 2 < 3 (see algorithm above), this is just for comparison with the below code
> 
> Result: 1
> 
> With left shifting:
>
> 6 left shifted by 1 bit = 6 * 2 = 12
>
> 12/3 = 4 (represented as 0000 0000 0000 0100)
>
> 4/3 = 1 (represented as 0000 0000 0000 0001 since the LC-3 doesn't support fractions and the [division subroutine](#division-truncates-result) truncates)
>
> Result: 2
> 
> * Here, the computer treats this as "1" but our rounding code will still treat this as "1/2" since we have chosen to say that bit 0 represents 1/2. This is in fact also why 4/3 is approximated to 1/2 in our representation - there is only one fraction bit, so all the extra precision is lost.
> * This is also why we chose "loop back only if quotient > base" for rounding mode, since all our values are treated as twice their represented value by the computer. If we ever got to quotient = base, that means the quotient is actually closer to half of the base than the base itself, and we need to exit. Why exit if the quotient is less than the base? Because this way you can get how many times the base will wholly divide your input, while waiting until 1 could cause it to loop an extra time here or in other special cases. This trick is essentially "prompting" that behavior but in a very controlled manner so that it only runs an extra time if the output would have a fractional part ≥ 0.5. This conditional extra iteration is why we don't left shift in floor mode, since it would cause results for some inputs to be 1 greater than expected.

Example ( $log_{3} (9)$ which for reference = 2):
> 
> Without left shifting:
> 
> 9/3 = 3 (represented as 0000 0000 0000 0011)
>
> 3/3 ≈ 1 (represented as 0000 0000 0000 0001)
> 
> Result: 2
> 
> With left shifting:
>
> 9 left shifted by 1 bit = 9 * 2 = 18
>
> 18/3 = 6 (represented as 0000 0000 0000 0110)
>
> 6/3 = 2 (represented as 0000 0000 0000 0010)
>  * remember since we left shifted everything by 1 and treat bit 0 as the "1/2" bit, 1 is represented as "2"
> Result: 2

