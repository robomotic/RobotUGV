/*
  servos.h - Library for generating servo control pulses with digital
	outputs on the Orangutan LV, SV, SVP, X2, Baby Orangutan B, or 3pi robot.  Note
	that only the Orangutan SV and SVP can supply enough current to power servos
	off of their regulated voltage.  All other devices can supply the control
	signals only (you must power the servos from a separate source).  This
	library relies on Timer1, so it will conflict with any other libraries that
	use Timer1 (e.g. OrangutanBuzzer).  You cannot use the OrangutanBuzzer
	library to play music while using the OrangutanServo library to control
	servos.
	
	This library can generate up to 16 servo control pulses.  On the Orangutan
	SVP, eight of these pulses must be via the servo pulse mux output.  The other
	eight are optional servo pulse outputs on digital I/O pins themselves.  On
	all other devices, all sixteen servo outputs are on digital I/O pins.
*/

/*
 * Written by Ben Schmidel, August 11, 2009.
 * Copyright (c) 2009 Pololu Corporation. For more information, see
 *
 *   http://www.pololu.com
 *   http://forum.pololu.com
 *   http://www.pololu.com/docs/0J18
 *
 * You may freely modify and share this code, as long as you keep this
 * notice intact (including the two links above).  Licensed under the
 * Creative Commons BY-SA 3.0 license:
 *
 *   http://creativecommons.org/licenses/by-sa/3.0/
 *
 * Disclaimer: To the extent permitted by law, Pololu provides this work
 * without any warranty.  It might be defective, in which case you agree
 * to be responsible for all resulting costs and damages.
 */

#ifndef OrangutanServos_h
#define OrangutanServos_h

// use of servos_init() is discouraged; use servos_start() instead
unsigned char servos_init(const unsigned char servoPins[], unsigned char numPins) __attribute__ ((deprecated));

// use of servos_init_extended() is discouraged; use servos_start_extended() instead
unsigned char servos_init_extended(const unsigned char servoPins[], unsigned char numPins, 
	const unsigned char servoPinsB[], unsigned char numPinsB) __attribute__ ((deprecated));

unsigned char servos_start(const unsigned char servoPins[], unsigned char numPins);

unsigned char servos_start_extended(const unsigned char servoPins[], unsigned char numPins, 
	const unsigned char servoPinsB[], unsigned char numPinsB);

unsigned int get_servo_position(unsigned char servoNum);

void set_servo_target(unsigned char servoNum, unsigned int pos_us);

unsigned int get_servo_target(unsigned char servoNum);

void set_servo_speed(unsigned char servoNum, unsigned int speed);

unsigned int get_servo_speed(unsigned char servoNum);

unsigned int get_servo_positionB(unsigned char servoNum);
static inline unsigned int get_servo_position_b(unsigned char servoNum)
{
	return get_servo_position_b(servoNum);
}

void set_servo_targetB(unsigned char servoNum, unsigned int pos_us);
static inline void set_servo_target_b(unsigned char servoNum, unsigned int pos_us)
{
	set_servo_targetB(servoNum, pos_us);
}

unsigned int get_servo_targetB(unsigned char servoNum);
static inline unsigned int get_servo_tartget_b(unsigned char servoNum)
{
	return get_servo_targetB(servoNum);
}

void set_servo_speedB(unsigned char servoNum, unsigned int speed);
static inline void set_servo_speed_b(unsigned char servoNum, unsigned int speed)
{
	set_servo_speedB(servoNum, speed);
}

unsigned int get_servo_speedB(unsigned char servoNum);
static inline unsigned int get_servo_speed_b(unsigned char servoNum)
{
	return get_servo_speedB(servoNum);
}

void servos_stop();

#endif