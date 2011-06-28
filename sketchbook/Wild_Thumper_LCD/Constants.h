//=================================== MODE OF COMMUNICATIONS ========================================================================


#define Cmode                0     // Sets communication mode: 0=RC    1=Serial    2=I2C
#define Brate           115200     // Baud rate for serial communications


//=================================== RC MODE OPTIONS ===============================================================================


#define Mix                  1     // Set to 1 if L/R and F/R signals from RC need to be mixed
#define Leftcenter        1500     // when RC inputs are centered then input should be 1.5mS
#define Rightcenter       1500     // when RC inputs are centered then input should be 1.5mS
#define RCdeadband          30     // inputs do not have to be perfectly centered to stop motors
#define scale               13     // scale factor for RC signal to PWM


//=================================== BATTERY CHARGER SETTINGS ======================================================================


#define batvolt            487     // This is the nominal battery voltage reading. Peak charge can only occur above this voltage.
#define lowvolt            410     // This is the voltage at which the speed controller goes into recharge mode.
#define chargetimeout   300000     // If the battery voltage does not change in this number of milliseconds then stop charging.


//=================================== H BRIDGE SETTINGS =============================================================================


#define Leftmaxamps        600     // set overload current for left motor 
#define Rightmaxamps       600     // set overload current for right motor 
#define overloadtime       100     // time in mS before motor is re-enabled after overload occurs


//=================================== SERVO SETTINGS ================================================================================


#define DServo0           1500     // default position for servo0 on "power up" - 1500uS is center position on most servos
#define DServo1           1500     // default position for servo1 on "power up" - 1500uS is center position on most servos
#define DServo2           1500     // default position for servo2 on "power up" - 1500uS is center position on most servos
#define DServo3           1500     // default position for servo3 on "power up" - 1500uS is center position on most servos
#define DServo4           1500     // default position for servo4 on "power up" - 1500uS is center position on most servos
#define DServo5           1500     // default position for servo5 on "power up" - 1500uS is center position on most servos
#define DServo6           1500     // default position for servo6 on "power up" - 1500uS is center position on most servos



