/*
 * Final_C.c
 *
 * Created: 9/10/2019 4:48:20 PM
 * Author : s3721711
 */ 

#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>
#include <stdlib.h>

#define F_CPU = 12000000

int main(void)
{
	// CONVERTING PING TO DIST
	volatile float pulse = 0x00;
	volatile float dist = 0;
	float speed = 34340; // in cm/s
	float clknano = (83) * (0.000000001) * (115);
	unsigned char transmit = 0x00;
	int distint = 0;

	
	//PORT B SET UP FOR TESTING
	DDRB = 0xFF;
	
	//TRANSMITTING TO SERIAL LCD
	// BAUD RATE - 9600 BPS
	UCSRC = (0 << URSEL);
	UBRRH = 0x00;
	UBRRL = 0x4D;


	UCSRB = (1 << TXEN);

	//UCSRC REG 1 - NO PARITY, 1 STOP BIT
	UCSRC = (1 << URSEL) | (0 << UPM1) | (0 << UPM0) | (1 << UCSZ1) | (1 << UCSZ0) | (0<< UCSZ2);
	
    while (1) 
    {
		_delay_us(200);
		// INITIALISE PULSE
		DDRC = (1 << DDRB2);
		PORTC = (1 << PORTC2);
		_delay_us(8);
		DDRC = (0 << DDRB2);
		PORTC = (0 << PORTC2);
		
		// converting output pulse to dist
		if (PORTC != 0x00)
		{
			while (PORTC != 0x00)
			{
				pulse++;

			}
			
			//pulse = 500;	//testing purposes only, what if dist is larger than 255?
			pulse = pulse * clknano;
			dist = speed * pulse;
			distint = (int)dist;		//converting to integer
			
			// NEED TO BREAK DOWN INTO DIGITS AND TRANSMIT
			char digits[4];
			itoa(distint, digits, 10); // converts integer to ascii value
			for (int i = 0; (digits[i] != NULL); i++)
			{
				transmit = digits[i];	// transmits digits individually 
				UDR = transmit;
			}
			UDR = 0x63;
			UDR = 0x6d;
			// FOR THE PITCH TONE 
			UDR = 0xD5;		//sets note length to 1.2 note
			if (distint < 25)
			{
				//a note
				UDR = 0xDC;
				PORTB =0xff;
			}
			else if (distint < 50 )
			{
				//b note
				UDR = 0xDE;
				PORTB = 0xfe;

			}
			else if (distint < 75 )
			{
				//c note
				UDR = 0xDF;
				PORTB = 0xfe;

			}
			else if (distint < 100 )
			{
				//d note
				UDR = 0xE1;
				PORTB = 0xf8;

			}
			else if (distint < 125 )
			{
				//e note
				UDR = 0xE3;
				PORTB = 0xf0;

			}
			else if (distint < 150 )
			{
				//f note
				UDR = 0xE4;
				PORTB = 0xe0;

			}
			else if (distint < 175 )
			{
				//g note
				UDR = 0xE6;
				PORTB = 0xc0;

			}
			else if (distint < 200 )
			{
				//g# note
				UDR = 0xE7;
				PORTB = 0x80;

			}		
			
			
		}
    }
}

/*



*/
