import processing.serial.*;

Serial myPort;  // Create object from Serial class
String val;
int time;
int wait = 500;
int pageAggregate = 0;
long aggregateCounter = 0;
int pageAvg = 0;

void setup() 
{
  size(200,200); //make our canvas 200 x 200 pixels big
  String portName = Serial.list()[0]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 9600);
   time = millis();
}

void draw()
{
  receiveInput();
  decidePageNum();
}

void receiveInput() {
  if ( myPort.available() > 0) 
  {  // If data is available,
    val = myPort.readStringUntil('\n');         // read it and store it in val
   // println("val: " + val);
    if (val != null) {
      val = trim(val);
      pageAggregate += Integer.parseInt(val);
      aggregateCounter++;
    }
  } 
  //println(val); //print it out in the console

}

long decidePageNum() {
  if(millis() - time >= wait){
    time = millis();//also update the stored time
    if (aggregateCounter != 0) {
      pageAvg = (int)(pageAggregate / aggregateCounter);
      println("pageAve: " + pageAvg);
    }
    pageAggregate = 0;
    aggregateCounter = 0;
  }
  return pageAvg;
}