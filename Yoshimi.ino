//int page1=1, page2=2, page3=3, page4=4, page5=5, page6=6, page7=7, page8=8;
#include <CapacitiveSensor.h>

#define COMMON_PIN      2    // The common 'send' pin for all keys
#define BUZZER_PIN      A4   // The output pin for the piezo buzzer
#define NUM_OF_SAMPLES  1   // Higher number whens more delay but more consistent readings
#define CAP_THRESHOLD   50  // Capactive reading that triggers a note (adjust to fit your needs)
#define NUM_OF_KEYS     6    // Number of keys that are on the keyboard
#define CS(Y) CapacitiveSensor(analog_pins[0], Y)
static const uint8_t analog_pins[] = {A0,A1,A2,A3,A4,A5};

//CapacitiveSensor keys[] = {CS(3), CS(4), CS(5), CS(6), CS(7), CS(8), CS(9), CS(10)};
CapacitiveSensor keys[] = {CS(analog_pins[1]), CS(analog_pins[2]), CS(analog_pins[3]), CS(analog_pins[4]), CS(analog_pins[5])};


#define numPages 6
int pages[numPages];
int states[numPages];
int currentPage = -1;
int ledPin = 13;
int inByte = 0;

void setup() {
  for (int i=0; i<numPages; i++) {
    pages[i] = i+2;
    pinMode(i+2, INPUT_PULLUP); //digital, not analog
    //digitalWrite(pages[i+2], HIGH); //plus 2 for tx rx pins
    //pinMode(analog_pins[i], INPUT);
    //digitalWrite(analog_pins[i], HIGH);
  }
  
  pinMode(ledPin, OUTPUT);
  
  for(int i=0; i<10; ++i) {
    keys[i].set_CS_AutocaL_Millis(0xFFFFFFFF);
  }
  //initialize serial communications at a 9600 baud rate
  
  Serial.begin(9600);
  while (!Serial) {
   ; // wait for serial port to connect. Needed for Leonardo only
  }
  establishContact();
}

void loop()
{
 //delayed(50);
 // if we get a valid byte, read analog ins:
 digitalWrite(ledPin, LOW);
  if (Serial.available() > 0) {
    
    // get incoming byte:
    inByte = Serial.read();
  
    //Get current page
    currentPage = -1;
    for (int i=0; i<numPages; i++) {
      if (digitalRead(i+2) == HIGH) {
        currentPage = i;
        states[i] = 1;
      } else {
        //break;
        states[i] = 0;
      }
    }
 
  
    Serial.write(currentPage+1); //currentPage

    for (int i = 0; i < 4; ++i) {
      if (keys[i].capacitiveSensor(5) > CAP_THRESHOLD) {
//        //tone(BUZZER_PIN, notes[i]); // Plays the note corresponding to the key pressed
        digitalWrite(ledPin, HIGH);
        Serial.write(1);
      } else {
        Serial.write(0);
      }
    }
//  } else {
//    digitalWrite(ledPin, HIGH);
//    digitalWrite(ledPin, LOW);
  }
//  delay(400);
}

void establishContact() {
 while (Serial.available() <= 0) {
   Serial.print('A'); // send a capital A
 delay(300);
 }
}

void delayed(int wait) {
  digitalWrite(ledPin, HIGH);
  delay(wait);
  digitalWrite(ledPin, LOW);
  delay(wait);
  digitalWrite(ledPin, HIGH);
  delay(wait);
  digitalWrite(ledPin, LOW);
  delay(wait);
}
