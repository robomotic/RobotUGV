
/*
*
Copyright Robomotic 2011
Author: Paolo Di Prodi
This code is for the Wild Thumper controller.
The gripper is connected to the servo receiver.
There is an additional LCD module whose libraries
were adapted for the use.
*/
#include <TimerOne.h>
#include <Servo.h>
#include "IOpins.h"
#include "Constants.h"
#include <LCD4Bit_mod.h> 

//create object to control an LCD.  
//number of lines in display=2
LCD4Bit_mod lcd = LCD4Bit_mod(2); 

//-------------------------------------------------------------- define global variables --------------------------------------------

unsigned int Volts;
unsigned int LeftAmps;
unsigned int RightAmps;
unsigned long chargeTimer;
unsigned long leftoverload;
unsigned long rightoverload;
int highVolts;
int startVolts;
int Leftspeed=0;
int Rightspeed=0;
int Speed;
int Steer;
byte Charged=1;                                               // 0=Flat battery  1=Charged battery
int Leftmode=1;                                               // 0=reverse, 1=brake, 2=forward
int Rightmode=1;                                              // 0=reverse, 1=brake, 2=forward
byte Leftmodechange=0;                                        // Left input must be 1500 before brake or reverse can occur
byte Rightmodechange=0;                                       // Right input must be 1500 before brake or reverse can occur
int LeftPWM;                                                  // PWM value for left  motor speed / brake
int RightPWM;                                                 // PWM value for right motor speed / brake
int data;
int servo[7];

int lcd_count=0;

void setup()
{

  //------------------------------------------------------------ Initialize I/O pins --------------------------------------------------

  pinMode (Charger,OUTPUT);                                   // change Charger pin to output
  digitalWrite (Charger,1);                                   // disable current regulator to charge battery

  if (Cmode==1) 
  {
    Serial.begin(Brate);                                      // enable serial communications if Cmode=1
    Serial.flush();                                           // flush buffer
  } 
  //Serial.begin(57600);

  //Initialize the LCD debug screen
  lcd.init();
  //optionally, now set up our application-specific display settings, overriding whatever the lcd did in lcd.init(
  lcd.clear();
  lcd.printIn("Checker Bot init");
  //Timer1.initialize(5000);
  //Timer1.setPeriod(5000);
  //Timer1.attachInterrupt(callback);
 
}


void loop()
{
  //------------------------------------------------------------ Check battery voltage and current draw of motors ---------------------

  Volts=analogRead(Battery);                                  // read the battery voltage
  LeftAmps=analogRead(LmotorC);                               // read left motor current draw
  RightAmps=analogRead(RmotorC);                              // read right motor current draw


  if (LeftAmps>Leftmaxamps)                                   // is motor current draw exceeding safe limit
  {
    analogWrite (LmotorA,0);                                  // turn off motors
    analogWrite (LmotorB,0);                                  // turn off motors
    lcd.clear();
    lcd.printIn("Overload left");
    leftoverload=millis();                                    // record time of overload
  }

  if (RightAmps>Rightmaxamps)                                 // is motor current draw exceeding safe limit
  {
    analogWrite (RmotorA,0);                                  // turn off motors
    analogWrite (RmotorB,0);                                  // turn off motors
    lcd.clear();
    lcd.printIn("Overload left");
    rightoverload=millis();                                   // record time of overload
  }

  
  if ((Volts<lowvolt) && (Charged==1))                        // check condition of the battery
  {                                                           // change battery status from charged to flat

    //---------------------------------------------------------- FLAT BATTERY speed controller shuts down until battery is recharged ----
    //---------------------------------------------------------- This is a safety feature to prevent malfunction at low voltages!! ------

    Charged=0;                                                // battery is flat
    highVolts=Volts;                                          // record the voltage
    startVolts=Volts;
    chargeTimer=millis();                                     // record the time
	
	if(lipoBatt==0)											  // checks if LiPo is being used, if not enable the charge circuit
	{
		digitalWrite (Charger,0);                                 // enable current regulator to charge battery
	}
  }

  //------------------------------------------------------------ CHARGE BATTERY -------------------------------------------------------

  if ((Charged==0) && (Volts-startVolts>67) && (lipoBatt == 0)) // if battery is flat and charger has been connected (voltage has increased by at least 1V) and there is no LiPo
  {
    if (Volts>highVolts)                                      // has battery voltage increased?
    {
      highVolts=Volts;                                        // record the highest voltage. Used to detect peak charging.
      chargeTimer=millis();                                   // when voltage increases record the time
    }

    if (Volts>batvolt)                                        // battery voltage must be higher than this before peak charging can occur.
    {
      if ((highVolts-Volts)>5 || (millis()-chargeTimer)>chargetimeout) // has voltage begun to drop or levelled out?
      {
        Charged=1;                                            // battery voltage has peaked
        digitalWrite (Charger,1);                             // turn off current regulator
      }
    } 
  }

  else

  {//----------------------------------------------------------- GOOD BATTERY speed controller opperates normally ----------------------

    switch(Cmode)
    {
    case 0:                                                   // RC mode via D0 and D1
      RCmode();
      break;

    case 1:                                                   // Serial mode via D0(RX) and D1(TX)
      SCmode();
      break;

    case 2:                                                   // I2C mode via A4(SDA) and A5(SCL)
      I2Cmode();
      break;
    }

    // --------------------------------------------------------- Code to drive dual "H" bridges --------------------------------------

    if (Charged==1)                                           // Only power motors if battery voltage is good
    {
      if ((millis()-leftoverload)>overloadtime)             
      {
        switch (Leftmode)                                     // if left motor has not overloaded recently
        {
        case 2:                                               // left motor forward
          analogWrite(LmotorA,0);
          analogWrite(LmotorB,LeftPWM);
          break;

        case 1:                                               // left motor brake
          analogWrite(LmotorA,LeftPWM);
          analogWrite(LmotorB,LeftPWM);
          break;

        case 0:                                               // left motor reverse
          analogWrite(LmotorA,LeftPWM);
          analogWrite(LmotorB,0);
          break;
        }
      }
      if ((millis()-rightoverload)>overloadtime)
      {
        switch (Rightmode)                                    // if right motor has not overloaded recently
        {
        case 2:                                               // right motor forward
          analogWrite(RmotorA,0);
          analogWrite(RmotorB,RightPWM);
          break;

        case 1:                                               // right motor brake
          analogWrite(RmotorA,RightPWM);
          analogWrite(RmotorB,RightPWM);
          break;

        case 0:                                               // right motor reverse
          analogWrite(RmotorA,RightPWM);
          analogWrite(RmotorB,0);
          break;
        }
      } 
    }
    else                                                      // Battery is flat
    {
      analogWrite (LmotorA,0);                                // turn off motors
      analogWrite (LmotorB,0);                                // turn off motors
      analogWrite (RmotorA,0);                                // turn off motors
      analogWrite (RmotorB,0);                                // turn off motors
      
    if(lcd_count==10000)
    {  
      lcd.clear();
      lcd.cursorTo(1, 0);  
      lcd.printIn("Stopped!");
    }

    }
  }
  
  if(lcd_count<=10000)
    lcd_count+=1;
  else if (lcd_count>10000)
   lcd_count=0;

}


void RCmode()
{
  //------------------------------------------------------------ Code for RC inputs ---------------------------------------------------------

  Speed=pulseIn(RCleft,HIGH,25000);                           // read throttle/left stick
  Steer=pulseIn(RCright,HIGH,25000);                          // read steering/right stick

  if (Speed==0) Speed=1500;                                   // if pulseIn times out (25mS) then set speed to stop
  if (Steer==0) Steer=1500;                                   // if pulseIn times out (25mS) then set steer to centre

  if (abs(Speed-1500)<RCdeadband) Speed=1500;                 // if Speed input is within deadband set to 1500 (1500uS=center position for most servos)
  if (abs(Steer-1500)<RCdeadband) Steer=1500;                 // if Steer input is within deadband set to 1500 (1500uS=center position for most servos)

  if (Mix==1)                                                 // Mixes speed and steering signals
  {
    Steer=Steer-1500;
    Leftspeed=Speed-Steer;
    Rightspeed=Speed+Steer;
  }
  else                                                        // Individual stick control
  {
    Leftspeed=Speed;
    Rightspeed=Steer;
  }
  /*
  Serial.print("Left:");
  Serial.print(Leftspeed);
  Serial.print(" -- Right:");
  Serial.println(Rightspeed);
  */
  Leftmode=2;
  Rightmode=2;
  if (Leftspeed>(Leftcenter+RCdeadband)) Leftmode=0;          // if left input is forward then set left mode to forward
  if (Rightspeed>(Rightcenter+RCdeadband)) Rightmode=0;       // if right input is forward then set right mode to forward

  LeftPWM=abs(Leftspeed-Leftcenter)*10/scale;                 // scale 1000-2000uS to 0-255
  LeftPWM=min(LeftPWM,255);                                   // set maximum limit 255

  RightPWM=abs(Rightspeed-Rightcenter)*10/scale;              // scale 1000-2000uS to 0-255
  RightPWM=min(RightPWM,255);                                 // set maximum limit 255

  if(lcd_count==10000)
  {
  lcd.clear();
  lcd.cursorTo(1, 0);  
  lcd.printIn("RPWM=");
  if (RightPWM>=250)
  lcd.printIn("max");
  else lcd.printIn("min");
  lcd.cursorTo(2, 0);  
  lcd.printIn("LPWM=");
  if (LeftPWM>=250)
  lcd.printIn("max");
  else lcd.printIn("min");
  }
}







void SCmode()
{// ------------------------------------------------------------ Code for Serial Communications --------------------------------------
}

void Serialread() 
{//---------------------------------------------------------- Read serial port until data has been received -----------------------------------
  do 
  {
    data=Serial.read();
  } while (data<0);
}
    






void I2Cmode()
{//----------------------------------------------------------- Your code goes here ------------------------------------------------------------

}











