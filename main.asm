;
; Final_Asm.asm
;
; Created: 9/10/2019 4:42:42 PM
; Author : s3721711
;
;	0x63 - c
;	0x6d - m

.def  temp  = r16
.equ SP = 0xDF   ;EQU assigns value to label making it a constant that can not be redefined
.def pulse = r17
.equ echo = PORTC2 
.def count = r23
.def digits = r18

; Define here Reset and interrupt vectors, if any
;
reset:
   rjmp start
   reti      ; Addr $01
   reti      ; Addr $02
   reti      ; Addr $03
   reti      ; Addr $04
   reti      ; Addr $05
   reti      ; Addr $06        Use 'rjmp myVector'
   reti      ; Addr $07        to define a interrupt vector
   reti      ; Addr $08
   reti      ; Addr $09
   reti      ; Addr $0A
   reti      ; Addr $0B        This is just an example
   reti      ; Addr $0C        Not all MCUs have the same
   reti      ; Addr $0D        number of interrupt vectors
   reti      ; Addr $0E
   reti      ; Addr $0F
   reti      ; Addr $10

;***********************************************************
; 
;   
;	
;*******************************
;
; Program starts here after Reset
start:
	LDI  TEMP,  SP    		; First, initialise the Stack pointer before we use it
	OUT  0x3D,  TEMP        ; stores data from register temp to i/o space(ports, timers,configuration register)


	ldi temp, 0xFF
    out $17, temp // set port b as output

	; LCD CONFIG
tx_config:
	; baud rate - 9600 bps
	clr temp	;h
	ldi r17, 0x4d; ;l

	out UBRRH, temp
	out UBRRL, r17


	;enable transceiver
	clr r16	; necessary?
	ldi r16, (1 << TXEN)
	out UCSRB, r16

	; setting frame length, parity, stop bits
	clr r16
	ldi r16, (1 << URSEL) | (1 << UCSZ1) | (1<< UCSZ0)
    
	;SENSOR PULSE FROM OUSB
sendpulse:
    ldi r16, 0x04
	out 0x14, r16	//sets ddrc bit2 to putput to send output trigger pulse
	out 0x15, r16	//sets portc bit2 high to initialise pulse

    PUSH R16			; save R16 and 17 as we're going to use them
    PUSH R0        ; we'll also use R0 as a zero value
    CLR R0
    ldi R16, 0x0B        ; init inner counter

L1:     
	DEC R16         ; counts down from 0 to FF to 0
	CPSE R16, R0    ; equal to zero?
	RJMP L1			 ; if not, do it again
	CLR R16			 ; reinit inner counter

    POP R0          ; done, clean up and return
    POP R16

	clr r16
	out 0x15, r16	// lowers the pulse back to zero at portc bit2
	out 0x14, r16	// sets ddrc bit2 back to input for echo pulse

	// receiving the echo pulse width
	ldi r16, 0x05
L2:	                       // short delay 
	
    dec r16       
	cpse r16, r0
	jmp L2

	ldi r16, 0x04
	out 0x15, r16          // enable pull up resistor in portc
	in r16, 0x13          // reading the value of pin2 portc

nothing2:
    call waitecho        // call waitecho to wait until pulse ends
	call getpulse        // call get pulse to get cycles of the pulse length6

	tst pulse            // check pulse for 0 which meas no object detected
	breq nothing

; conv to dist

loop:

    cpi pulse, 25  //cm away from sensor
    brlo a        // closest to sensor all LEDS on

    
    cpi pulse, 50
    brlo b

   
    cpi pulse, 75
    brlo c

    cpi pulse, 100
    brlo d

   
    cpi pulse, 125
    brlo e

 
    cpi pulse, 150
    brlo f

    cpi pulse, 175
    brlo g


    cpi pulse, 200
    brlo h

   
    cpi pulse, 200
    brge i
    brne loop

a:
   ldi temp, 0xff
   out $18, temp
   brne ascii

b:
  ldi temp, 0xfe
  out $18, temp 
  brne ascii

c:
  ldi temp, 0xfc
  out $18, temp
  brne ascii

d:
  ldi temp, 0xf8
  out $18, temp
  brne ascii

e:
  ldi temp, 0xf0
  out $18, temp
  brne ascii

f:
  ldi temp, 0xe0
  out $18, temp
  brne ascii

g:
  ldi temp, 0xc0
  out $18, temp
  brne ascii

h:
  ldi temp, 0x80
  out $18, temp
  brne ascii

i:
  ldi temp, 0x80		// should this be 0x40? or 0x20?
  out $18, temp
  brne ascii
  
  rjmp sendpulse

nothing:
    rjmp nothing2


waitecho:
    sbic 0x13, echo        /// skips the next instruction if pinc2 goes to 0 (sbic 0x13, PORTC2)
	jmp waitecho        // jumps back to waiting for echo
	ret

getpulse:
    clr pulse
Q:
    inc pulse            // increment pulse 
	clr r0                // 
	tst pulse  	    // compre to 0 
    breq W
	rcall Bdelay

	sbis 0x13, echo          // checks to makes sure echo is still 0

	rjmp Q

W:
    ret	



Bdelay:                    // # of clks to call here
   ldi count, 0x06
S:
   dec      count          //    Decrement counter
   brne     S                //  Loop back up if not zero
                           //     Timing: false:1clks, true:2clks
   ret                     //  Else return

; SERIAL LCD 
ascii:
	clr digits

done:
	mov ZL, pulse
	clr pulse
	cpi ZL,10
	inc pulse
	brlo pushing

mod10:
	subi ZL, 0x0a ;number in r16
	cpi  ZL,10
	inc pulse
	brsh mod10
	
pushing:
	dec pulse
	inc digits              ; count digits
	cpi digits, 1
	breq digit1
	cpi digits, 2
	breq digit2
	cpi digits, 3
	breq digit3
check:
    tst pulse      ; pulse is 0? - check counter ?
    brne done          ; no, continue

    ; POP digits from stack in reverse order - need stack pointer modified
first_digit:
	mov temp, r21
	ori temp, 0x30      //  ; convert to ASCII - adding 0x30?
transmit:
	sbis UCSRA, UDRE	; waits till buffer is empty (so everything is sent)
	rjmp transmit	
	out UDR, temp	;transmits data out, need to loop, see below

second_digit:
	mov temp, r20
	ori temp, 0x30
	sectrans:
	sbis UCSRA, UDRE	; waits till buffer is empty (so everything is sent)
	rjmp sectrans
	out UDR, temp	;transmits data out, need to loop, see below

third_digit:
	mov temp, r19
	ori temp, 0x30
thrtrans:
	sbis UCSRA, UDRE	; waits till buffer is empty (so everything is sent)
	rjmp thrtrans	
	out UDR, temp	;transmits data out, need to loop, see below
	ldi temp, 0x63
	sbis UCSRA, UDRE	; waits till buffer is empty (so everything is sent)
	out UDR, temp
	ldi temp, 0x6d
	sbis UCSRA, UDRE	; waits till buffer is empty (so everything is sent)
	out UDR, temp
	jmp sendpulse

digit1:
	mov r19, ZL
	jmp check

digit2:
	mov r20, ZL
	jmp check

digit3:
	mov r21, ZL
	jmp check

end:
