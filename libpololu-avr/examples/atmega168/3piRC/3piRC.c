/**
 * RC 3pi
 *
 * This 3pi robot program reads two standard radio-control (RC) channels and mixes 
 * them into motor control. Channel zero (connected to the PD0 input) 
 * handles forward and reverse, and channel one (connected to the 
 * PC5 input) handles turning.
 *
 */
#include <avr/io.h>
#include <avr/interrupt.h>
#include <pololu/3pi.h>

/**
 * Receiver pulse timings
 *
 * Standard RC receivers output high pulses between 0.5 ms and 2.5 ms with a neutral
 * position of about 1.5 ms. If your RC receiver operates with different pulse
 * widths, change these constants below.
 *
 * The units of these constants is ticks of Timer1 which is set to tick every 3.2
 * microseconds.
 *
 */
const int minPulseTime     = 156;  // 0.5 ms
const int neutralPulseTime = 469;  // 1.5 ms
const int maxPulseTime     = 782;  // 2.5ms
const int maxLowPulseTime  = 3000; // 9.6ms

struct ChannelStruct
{
	volatile unsigned int prevTime;
	volatile unsigned int lowDur;
	volatile unsigned int highDur;
	volatile unsigned char newPulse;

	unsigned int pulse;
	unsigned char error;
};

struct ChannelStruct ch[2];

/*
 * Pin Change interrupts
 * PCI0 triggers on PCINT7..0
 * PCI1 triggers on PCINT14..8
 * PCI2 triggers on PCINT23..16
 * PCMSK2, PCMSK1, PCMSK0 registers control which pins contribute.
 *
 * The following table is useful:
 *
 * AVR pin    PCINT #            PCI #
 * ---------  -----------------  -----
 * PB0 - PB5  PCINT0 - PCINT5    PCI0
 * PC0 - PC5  PCINT8 - PCINT13   PCI1
 * PD0 - PD7  PCINT16 - PCINT23  PCI2
 *
 */

// This interrupt service routine is for the channel connected to PD0
ISR(PCINT2_vect)
{
	// Save a snapshot of PIND at the current time
	unsigned char pind = PIND;
	unsigned int time = TCNT1;

	if (pind & (1 << PORTD0)) 
	{
		// PD0 has changed to high so record the low pulse's duration
		ch[0].lowDur = time - ch[0].prevTime;
	}
	else
	{
		// PD0 has changed to low so record the high pulse's duration
		ch[0].highDur = time - ch[0].prevTime;
		ch[0].newPulse = 1; // The high pulse just finished so we can process it now
	}
	ch[0].prevTime = time;
}

// This interrupt service routine is for the channel connected to PC5
ISR(PCINT1_vect)
{
	// Save a snapshot of PINC at the current time
	unsigned char pinc = PINC;
	unsigned int time = TCNT1;

	if (pinc & (1 << PORTC5))
	{
		// PC5 has changed to high so record the low pulse's duration
		ch[1].lowDur = time - ch[1].prevTime;
	}
	else
	{
		// PC5 has changed to low so record the high pulse's duration
		ch[1].highDur = time - ch[1].prevTime;
		ch[1].newPulse = 1; // The high pulse just finished so we can process it now
	}
	ch[1].prevTime = time;
}


/**
 * updateChannels ensures the recevied signals are valid, and if they are valid 
 * it stores the most recent high pulse for each channel.
 */ 
void updateChannels()
{
	unsigned char i;

	for (i = 0; i < 2; i++)
	{
		cli(); // Disable interrupts
		if (TCNT1 - ch[i].prevTime > 35000)
		{
			// The pulse is too long (longer than 112 ms); register an error 
			// before it causes possible problems.
			ch[i].error = 5; // wait for 5 good pulses before trusting the signal

		}
		sei(); // Enable interrupts

		if (ch[i].newPulse)
		{
			cli(); // Disable interrupts while reading highDur and lowDur
			ch[i].newPulse = 0;
			unsigned int highDuration = ch[i].highDur;
			unsigned int lowDuration = ch[i].lowDur;
			sei(); // Enable interrupts

			ch[i].pulse = 0;

			if (lowDuration < maxLowPulseTime ||
				highDuration < minPulseTime ||		
				highDuration > maxPulseTime)
			{
				// The low pulse was too short or the high pulse was too long or too short
				ch[i].error = 5; // Wait for 5 good pulses before trusting the signal
			}
			else
			{
				// Wait for error number of good pulses
				if (ch[i].error)
					ch[i].error--;
				else
				{
					// Save the duration of the high pulse for use in the channel mixing
					// calculation below
					ch[i].pulse = highDuration; 
				}
			}
		}
	}
}


int main()
{
	ch[0].error = 5; // Wait for 5 good pulses before trusting the signal
	ch[1].error = 5; 

	DDRD &= ~(1 << PORTD0);	// Set pin PD0 as an input
	PORTD |= 1 << PORTD0;	// Enable pull-up on pin PD0 so that it isn't floating
	DDRC &= ~(1 << PORTC5); // Set pin PC5 as an input
	PORTC |= 1 << PORTC5;	// Enable pull-up on pin PC5 so that it isn't floating
	delay_ms(1);			// Give the pull-up voltage time to rise
	
	PCMSK1 = (1 << PORTC5);	// Set pin-change interrupt mask for pin PC5
	PCMSK2 = (1 << PORTD0);	// Set pin-change interrupt mask for pin PD0
	PCIFR = 0xFF;			// Clear all pin-change interrupt flags
	PCICR = 0x06;			// Enable pin-change interrupt for masked pins of PORTD
							//  and PORTC; disable pin-change interrupts for PORTB
	sei();					// Interrupts are off by default so enable them

	TCCR1B = 0x03;	// Timer 1 ticks at 20MHz/64 = 312.5kHz (1 tick per 3.2us)

	while (1) // Loop forever
	{
		updateChannels();

		// Every 100 ms display the pulse timings on the LCD
		// this is good for debugging your RC 3pi but not necessary if
		// you remove the LCD
		if (get_ms() % 100) 
		{
			lcd_goto_xy(0, 0);
			print("ch1 ");
			// Multiplying by 32/10 converts ticks to microseconds
			print_unsigned_long(ch[0].pulse * 32 / 10);  
			print("    ");
			lcd_goto_xy(0, 1);
			print("ch2 ");
			print_unsigned_long(ch[1].pulse * 32 / 10);
		}

		if (ch[0].error || ch[1].error)
		{
			// If either channel is not getting a good signal, stop
			set_motors(0, 0);
		}
		else
		{
			/**
			 * Mix calculation
			 * 
			 * This calculation mixes the pulses from the two channels 
			 * to make control intuitive. Channel 0 controls foward and 
			 * reverse. When the pulse is longer than neutralPulseTime it
			 * adds to m1 and m2; when the pulse is shorter than nuetralPulseTime
			 * it subtracts from m1 and m2. Channel 1 controls rotation. When the
			 * pulse is longer than neutralPulseTime it subtracts from m1 and adds
			 * to m2; when the pulse is shorter than neutralPulseTime it adds to m1 
			 * and subtracts from m2. m1 and m2 are then scaled so they fit within 
			 * -255 to 255 range.
			 * 
			 * Calibration
			 *
			 * Your transmitter/receiver might treat channels 0 and 1 differently 
			 * than the receiver this code was developed for. If your 3pi turns 
			 * when you expect it to go straight or vice versa, you may need to flip 
			 * a sign in the calculation below or swap the connections at the receiver.
			 *
			 */
			long m1 = (neutralPulseTime - (int)ch[0].pulse) + ((int)ch[1].pulse - neutralPulseTime);
			long m2 = (neutralPulseTime - (int)ch[0].pulse) - ((int)ch[1].pulse - neutralPulseTime);
			m1 = m1 * 255 / minPulseTime;
			m2 = m2 * 255 / minPulseTime;
			set_motors(m1, m2);
		}
	}

    // This part of the code is never reached.  A robot should
    // never reach the end of its program, or unpredictable behavior
    // will result as random code starts getting executed.  If you
    // really want to stop all actions at some point, set your motors
    // to 0,0 and run the following command to loop forever:
    //
	// set_motors(0,0);
    // while(1);
}
