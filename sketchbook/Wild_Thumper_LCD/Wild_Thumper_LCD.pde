#include <Servo.h>
#include "IOpins.h"
#include "Constants.h"

#include <LCD4Bit_mod.h> 
//create object to control an LCD.  
//number of lines in display=1
LCD4Bit_mod lcd = LCD4Bit_mod(2); 
//-------------------------------------------------------------- define global variables --------------------------------------------

unsigned int Volts;
unsigned int LeftAmps;
unsigned int RightAmps;
unsigned long chargeTimer=millis();
unsigned long leftoverload;
unsigned long rightoverload;
int highVolts;
int startVolts;
int Leftspeed=0;
int Rightspeed=0;
int Speed;
int Steer;
byte Charged=1;                                               // 0=Flat battery  1=Charged battery
int Leftmode=0;                                               // 0=reverse, 1=brake, 2=forward
int Rightmode=0;                                              // 0=reverse, 1=brake, 2=forward
byte Leftmodechange=0;                                        // Left input must be 1500 before brake or reverse can occur
byte Rightmodechange=0;                                       // Right input must be 1500 before brake or reverse can occur
int LeftPWM=128;                                                  // PWM value for left  motor speed / brake
int RightPWM=128;                                                 // PWM value for right motor speed / brake
int data=1100;
int servo[7];


void setup()
{
  
  //------------------------------------------------------------ Initialize I/O pins --------------------------------------------------

  pinMode (Charger,OUTPUT);                                   // change Charger pin to output
  digitalWrite (Charger,0);                                   // disable current regulator to charge battery
  //Initialize the LCD debug screen
  lcd.init();
  //optionally, now set up our application-specific display settings, overriding whatever the lcd did in lcd.init()
  lcd.commandWrite(0x0F);//cursor on, display on, blink on.  (nasty!)
  lcd.clear();
  lcd.printIn("KEYPAD testing... pressing");
  Serial.begin(9600);
}


void loop()
{
  //------------------------------------------------------------ Check battery voltage and current draw of motors ---------------------

  Volts=analogRead(Battery);                                  // read the battery voltage
  LeftAmps=analogRead(LmotorC);                               // read left motor current draw
  RightAmps=analogRead(RmotorC);                              // read right motor current draw

  Serial.print("Battery Voltage:");
  Serial.print(Volts);
  Serial.print("   Left motor current:");
  Serial.print(LeftAmps);
  Serial.print("   Right motor current:");
  Serial.println(RightAmps);


  if (data>1900) 
  {
    Leftmode+=2;
    Rightmode+=2;
    Leftmode*=(Leftmode<3);
    Rightmode*=(Rightmode<3);
  }
  data+=10-800*(data>1900);


  // --------------------------------------------------------- Code to drive dual "H" bridges --------------------------------------

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

  switch (Rightmode)                                    
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








