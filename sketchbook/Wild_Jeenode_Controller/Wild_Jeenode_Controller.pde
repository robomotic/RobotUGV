/*

v1.0 RoboSavvy 16/11/2010
Added code to prevent drain of LiPo Batteries.

*/
#include <Servo.h>
#include "IOpins.h"
#include "Constants.h"
#include <LCD4Bit_mod.h> 
//create object to control an LCD.  
//number of lines in display=1
LCD4Bit_mod lcd = LCD4Bit_mod(2); 

//Key message
char msgs[5][15] = {"Right Key OK ", 
                    "Up Key OK    ", 
                    "Down Key OK  ", 
                    "Left Key OK  ", 
                    "Select Key OK" };
int  adc_key_val[5] ={30, 150, 360, 535, 760 };
int NUM_KEYS = 5;
int adc_key_in;
int key=-1;
int oldkey=-1;


//-------------------------------------------------------------- define global variables --------------------------------------------

unsigned int Volts;
unsigned int LeftAmps;
unsigned int RightAmps;
unsigned long chargeTimer;
unsigned long leftoverload;
unsigned long rightoverload;
unsigned long refresh;
//refresh period is 500 msec=0.5 Hz
unsigned long lcd_hz=500;
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
boolean isDebug=true;
char stemp[4];

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
  //optionally, now set up our application-specific display settings, overriding whatever the lcd did in lcd.init()
  //lcd.commandWrite(0x0F);//cursor on, display on, blink on.  (nasty!)
  lcd.clear();
  lcd.printIn("Robot init...");
  delay(1000);
  lcd.clear();
  refresh=millis();
}

// Convert ADC value to key number
int get_key(unsigned int input)
{
  int k;
    
  for (k = 0; k < NUM_KEYS; k++)
  {
    if (input < adc_key_val[k])
    {       
      return k;
    }
   } 
   if (k >= NUM_KEYS)
        k = -1;     // No valid key pressed 
   return k;
}

void loop()
{
  
  //----------- Check screen button
  adc_key_in = analogRead(A1);    // read the value from the sensor  
  key = get_key(adc_key_in);		        // convert into key press
	
  if (key != oldkey)				    // if keypress is detected
	{
    delay(50);		// wait for debounce time
    adc_key_in = analogRead(A1);    // read the value from the sensor  
    key = get_key(adc_key_in);		        // convert into key press
    if (key != oldkey)				
    {			
      oldkey = key;
      if (key >=0){
      lcd.cursorTo(2, 0);  //line=2, x=0
      lcd.printIn(msgs[key]);
      }
    }
  }
  
  //------------------------------------------------------------ Check battery voltage and current draw of motors ---------------------

  Volts=analogRead(Battery);                                  // read the battery voltage
  LeftAmps=analogRead(LmotorC);                               // read left motor current draw
  RightAmps=analogRead(RmotorC);                              // read right motor current draw


  if (LeftAmps>Leftmaxamps)                                   // is motor current draw exceeding safe limit
  {
    analogWrite (LmotorA,0);                                  // turn off motors
    analogWrite (LmotorB,0);                                  // turn off motors
    leftoverload=millis();                                    // record time of overload
    lcd.cursorTo(1, 0);
    lcd.printIn("Left safety on...");
  }

  if (RightAmps>Rightmaxamps)                                 // is motor current draw exceeding safe limit
  {
    analogWrite (RmotorA,0);                                  // turn off motors
    analogWrite (RmotorB,0);                                  // turn off motors
    rightoverload=millis();                                   // record time of overload
    lcd.cursorTo(2, 0);
    lcd.printIn("Right safety on...");
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
   case 3:
      KeyMode();
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
          lcd.cursorTo(1,4);
          lcd.printIn("L FWD");
          break;

        case 1:                                               // left motor brake
          analogWrite(LmotorA,LeftPWM);
          analogWrite(LmotorB,LeftPWM);
          lcd.cursorTo(1,4);
          lcd.printIn("L BRK");
          break;

        case 0:                                               // left motor reverse
          analogWrite(LmotorA,LeftPWM);
          analogWrite(LmotorB,0);
          lcd.cursorTo(1,4);
          lcd.printIn("L BCK");
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
          lcd.cursorTo(1,10);
          lcd.printIn("R FWD");
          break;

        case 1:                                               // right motor brake
          analogWrite(RmotorA,RightPWM);
          analogWrite(RmotorB,RightPWM);
          lcd.cursorTo(1,10);
          lcd.printIn("R BRK");
          break;

        case 0:                                               // right motor reverse
          analogWrite(RmotorA,RightPWM);
          analogWrite(RmotorB,0);
          lcd.cursorTo(1,10);
          lcd.printIn("R BCK");
          break;
        }
      } 
    }
    else                                                      // Battery is flat
    {
      lcd_refresh("STOP Vbatt=",Volts);
      //convert to string volts
      analogWrite (LmotorA,0);                                // turn off motors
      analogWrite (LmotorB,0);                                // turn off motors
      analogWrite (RmotorA,0);                                // turn off motors
      analogWrite (RmotorB,0);                                // turn off motors
    }
  }
}

void lcd_refresh(char *str,byte value)
{
      if ((millis()-refresh)>lcd_hz)
      {
      lcd.clear();
      lcd.printIn(str);
      //convert to string volts
      convert_byte(value,stemp);
      lcd.printIn(stemp);  
      refresh=millis();
      }
      
  
}

void KeyMode()
{
  
  if (key==1) 
  {
    Leftmode=2;
    Rightmode=2;
    LeftPWM+=10;                         
    RightPWM+=10;                                   
  }
  else if (key==2) 
  {
    Leftmode=0;
    Rightmode=0;
    LeftPWM-=10;                         
    RightPWM-=10;                                   
  }
  
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
}



void convert_byte(byte b,char *s)
{
 snprintf(s,4,"%d",b); 
}



void SCmode()
{// ------------------------------------------------------------ Code for Serial Communications --------------------------------------

                                                              // FL = flush serial buffer
 
                                                              // AN = report Analog inputs 1-5
                                                              
                                                              // SV = next 7 integers will be position information for servos 0-6
 
                                                              // HB = "H" bridge data - next 4 bytes will be:
                                                              //      left  motor mode 0-2
                                                              //      left  motor PWM  0-255
                                                              //      right motor mode 0-2
                                                              //      right motor PWM  0-255
   
 
  if (Serial.available()>1)                                   // command available
  {
    int A=Serial.read();
    int B=Serial.read();
    int command=A*256+B;
    switch (command)
    {
      case 17996:                                             // FL
        Serial.flush();                                       // flush buffer
        lcd.clear();
        lcd.printIn("Buffer flushed");
        break;
        
      case 16718:                                             // AN - return values of analog inputs 1-5
        lcd.clear();
        lcd.printIn("Analog reading");
        for (int i=1;i<6;i++)                                 // index analog inputs 1-5
        {
          data=analogRead(i);                                 // read 10bit analog input 
          Serial.write(highByte(data));                       // transmit high byte
          Serial.write(lowByte(data));                        // transmit low byte
        }
        break;
              
       case 21334:                                            // SV - receive postion information for servos 0-6
        lcd.clear();
        lcd.printIn("SV control");
         for (int i=0;i<15;i++)                               // read 14 bytes of data
         {
           Serialread();                                      
           servo[i]=data;
         }
         break;
       
       case 18498:                                            // HB - mode and PWM data for left and right motors
         lcd.clear();
         lcd.printIn("HB=");
         Serialread();
         Leftmode=data;
         Serialread();
         LeftPWM=data;
         Serialread();
         Rightmode=data;
         Serialread();
         RightPWM=data;
         
         convert_byte(LeftPWM,stemp);
         lcd.cursorTo(2,0);
         lcd.printIn("LP=");
         lcd.printIn(stemp);
         lcd.printIn(" ");
         convert_byte(RightPWM,stemp);
         lcd.printIn("RP=");
         lcd.printIn(stemp);
         break;
         
       default:                                                // invalid command
        lcd.clear();
        lcd.printIn("Cmd error");
         Serial.flush();                                       // flush buffer
    }
  }
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











