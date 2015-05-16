import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;
//import controlP5.*;
//import processing.opengl.*;
import java.util.Arrays;
import java.util.Hashtable;

//Serial Comm
Serial port;  // Create object from Serial class
int val;
int valInt;
boolean firstContact = false;
int time;
int keyTime;
int wait = 500;
int keyWait = 100;
int pageAggregate = 0;
long aggregateCounter = 0;
int pageAvg = 0;

int[] aggregateKeyCounter = new int[4];
int[] keyAggregate = new int[4];
int[] keyAvg = new int [4];

boolean adruinoInput = true;

int[] serialInArray = new int[5];
int serialCount = 0;

//Minim
Minim              minim;
MultiChannelBuffer sampleBuffer;
MultiChannelBuffer destinationBuffer;

AudioOutput        output;
//Sampler            sampler;
AudioPlayer        player;
AudioPlayer        playerLoop;

ArrayList<KeySampleNode> bassNotes = new ArrayList<KeySampleNode>();
ArrayList<KeySampleNode> fluteNotes = new ArrayList<KeySampleNode>();
int numBassKeys;
int numFluteKeys;
Sampler[] fluteKeys;
Sampler[] bassKeys;
boolean[] keysSinglePress;

boolean yawnBool = true;
Sampler yawn;

ArrayList<Integer> noteSequence = new ArrayList<Integer>();

//Robot Sequencer

int[] basscRow = new int[16];
int[] bassdRow = new int[16];
int[] bassaRow = new int[16];
int[] bassc2Row = new int[16];

int level = 0;
public float bpm;

int beat; // which beat we're on

class Tick implements Instrument
{
  void noteOn( float dur )
  {
    if ( basscRow[beat] == 1 ) bassKeys[0].trigger();
    if ( bassdRow[beat] == 1 ) bassKeys[1].trigger();
    if ( bassaRow[beat] == 1 ) bassKeys[2].trigger();
    if ( bassc2Row[beat] == 1 ) bassKeys[3].trigger();
  }
  
  void noteOff()
  {
    if ( basscRow[beat] == 0 ) bassKeys[0].stop();
    if ( bassdRow[beat] == 0 ) bassKeys[1].stop();
    if ( bassaRow[beat] == 0 ) bassKeys[2].stop();
    if ( bassc2Row[beat] == 0 ) bassKeys[3].stop();
    
    // next beat
    beat = (beat+1)%32;
    // set the new tempo
    output.setTempo( bpm );
    // play this again right now, with a sixteenth note duration
    output.playNote( 0, 0.50f, this );
  }
}

PageNode[] pages;
int pageValInside = 0;
int pageValOutside = 0;
boolean isLooping = false;
int offset = 0;
int beatTime = 767;//767.75431861804222648752399232246; beat time in miliseconds
//boolean markerCheck[] = new boolean[] {true, true, true, true};
boolean playOnceMain = true;
boolean playOnceLoop = true;
boolean playOnceExit = true;
boolean playOnceExitEnd = false; //used to skip to loop after exit chunk has played

float              sampleRate;
String             sourceFileName = "YoshimiStoryBook_Instrumental.wav"; //yeahhh.wav, 
int                sourceBufferSize;

private class PageNode {
  public int mainStart;
  public int mainEnd;
  public int enterStart;
  public int enterEnd;
  public int exitStart;
  public int exitEnd;
  public int loopStart;
  public int loopEnd;
  
  public PageNode(int mainStart, int mainEnd, int enterStart, int enterEnd, int exitStart, int exitEnd, int loopStart, int loopEnd) {
    this.mainStart =  mainStart;
    this.mainEnd = mainEnd;
    this.enterStart = enterStart;
    this.enterEnd = enterEnd;
    this.exitStart = exitStart;
    this.exitEnd = exitEnd;
    this.loopStart = loopStart;
    this.loopEnd = loopEnd;
  }
}

private class KeySampleNode {
  public String inputKey; 
  public String sampleName;
  
  public KeySampleNode(String inputKey, String sampleName) {
    this.inputKey = inputKey;
    this.sampleName = sampleName; 
  }
}

public enum PosMark {MainStart, MainEnd, EnterStart, EnterEnd, ExitStart, ExitEnd, LoopStart, LoopEnd}
public PosMark positionMarker = PosMark.MainStart;

void setup() 
{
  size(512, 200, P3D);
  //Serial Initialization
//  String portName = Serial.list()[0]; //change the 0 to a 1 or 2 etc. to match your port
//  port = new Serial(this, portName, 9600);
  time = millis();
  keyTime = millis();

  // create Minim and an AudioOutputq
  minim  = new Minim(this);
  output = minim.getLineOut();
  
  sampleBuffer      = new MultiChannelBuffer( 1, 4024 );
  destinationBuffer = new MultiChannelBuffer( 1, 4024 );
  
  bassNotes.add(new KeySampleNode("z", "bassc.wav"));
  bassNotes.add(new KeySampleNode("x", "bassd.wav"));
  bassNotes.add(new KeySampleNode("c", "bassa.wav"));
  bassNotes.add(new KeySampleNode("v", "bassc2.wav"));
  
  fluteNotes.add(new KeySampleNode("z", "bassc.wav"));
  fluteNotes.add(new KeySampleNode("x", "bassd.wav"));
  fluteNotes.add(new KeySampleNode("c", "bassa.wav"));
  fluteNotes.add(new KeySampleNode("v", "bassc2.wav"));
  
  numFluteKeys = bassNotes.size();
  numBassKeys = bassNotes.size();
  bassKeys = new Sampler[numFluteKeys];
  fluteKeys = new Sampler[numFluteKeys];
  keysSinglePress = new boolean[numFluteKeys];
  
  //Initialize Bass Samples
  for (int i=0; i<numBassKeys; i++) {
    sampleRate = minim.loadFileIntoBuffer(bassNotes.get(i).sampleName, sampleBuffer );
    minim.loadFileIntoBuffer(bassNotes.get(i).sampleName, destinationBuffer );
    bassKeys[i] =  new Sampler( destinationBuffer, sampleRate,1);
    bassKeys[i].looping = true;
    bassKeys[i].patch( output );
    
  }
    
  //Initialize Flute Samples
  for (int i=0; i<numFluteKeys; i++) {
    sampleRate = minim.loadFileIntoBuffer(fluteNotes.get(i).sampleName, sampleBuffer );
    minim.loadFileIntoBuffer(fluteNotes.get(i).sampleName, destinationBuffer );
    fluteKeys[i] =  new Sampler( destinationBuffer, sampleRate,1);
    keysSinglePress[i] = true;
    fluteKeys[i].looping = true;
    fluteKeys[i].patch( output );
  }
  
  sampleRate = minim.loadFileIntoBuffer("yawn.wav", sampleBuffer );
  minim.loadFileIntoBuffer("yawn.wav", destinationBuffer );
  yawn = new Sampler (destinationBuffer, sampleRate,1);
  yawn.patch( output );
 
  bpm = 78.2;
  beat = 0;
  
  basscRow = new int[] {1,2,0,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 1,2,0,2, 2,2,2,2, 2,2,2,2, 2,2,2,2};
  bassdRow = new int[] {0,2,1,2, 0,2,1,2, 0,2,2,2, 2,2,2,2, 0,2,1,2, 0,2,1,2, 0,2,2,2, 2,2,2,2};
  bassaRow = new int[] {2,2,2,2, 1,2,0,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 1,2,0,2, 2,2,2,2, 2,2,2,2};
 bassc2Row = new int[] {2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2};
  
  // start the sequencer
  output.setTempo( bpm );
  //output.playNote( 0, 0.25f, new Tick() );

  player = minim.loadFile(sourceFileName);
  playerLoop = minim.loadFile(sourceFileName);
  
  pages = new PageNode[] {
   new PageNode(350,352,-1,-1,-1,-1,350,352), 
   new PageNode(0, 32, -1, -1, -1, -1, 16, 32),   
   new PageNode(32, 64, -1, -1, 54, 56, 16, 32),
   new PageNode(64, 120, -1, -1, -1, -1, 88, 120),
   new PageNode(120, 152, -1, -1, 54, 56, 16, 32),
   new PageNode(152, 208, -1, -1, -1, -1, 178, 208),
   new PageNode(208, 352, -1, -1, -1, -1, 350, 352)
//   new PageNode(240, 352, -1, -1, -1, -1, 350, 352)
  };
  
  
    String portName = Serial.list()[0]; //change the 0 to a 1 or 2 etc. to match your port
  port = new Serial(this, portName, 9600);
}
//   new PageNode(240, 306, -1, -1, -1, -1, 264, 306),
//   new PageNode(328, 272, -1, -1, -1, -1, 370,372)

void draw()
{
  //receiveInput();
  decidePageNum();
  audio();
  
//  for (int i=0; i<4; i++) {
//     decideKeyNum(i);
//  }
}


void serialEvent(Serial port) {
  try {
 // read a byte from the serial port:
 int inByte = port.read();
 //println(inByte);
 // if this is the first byte received, and it's an A,
 // clear the serial buffer and note that you've
 // had first contact from the microcontroller.
 // Otherwise, add the incoming byte to the array:
 if (firstContact == false) {
   if (inByte == 'A') {
     port.clear();   // clear the serial port buffer
     firstContact = true;  // you've had first contact from the microcontroller
     port.write('A');  // ask for more
   }
 }
 else {
   //val = port.readStringUntil('\n');         // read it and store it in val
   //inByte = -1;
   //inByte = port.read();
//    if (val != null) {
//      val = trim(val);
//      serialInArray[serialCount] = Integer.parseInt(val);
      if (inByte != -1) {
        serialInArray[serialCount] = inByte;
      serialCount++;
      }
      if (serialCount > 4 ) {
        println(Arrays.toString(serialInArray));
         println("keyAvg: " + Arrays.toString(keyAvg));
        pageAggregate += serialInArray[0];
        aggregateCounter++;
        
        for (int i=0; i<4; i++) {
           keyAggregate[i] += serialInArray[i+1];
          aggregateKeyCounter[i]++; 
        }
        
       if (adruinoInput) {
        if (serialInArray[1] == 1) {
          if ( sampleRate > 0 ) {
            keySinglePress(0); 
          }
        } else {
          keySingleRelease(0);
        }
        
        if (serialInArray[2] == 1) {
          if ( sampleRate > 0 ) {
            keySinglePress(1); 
          }
        } else {
          keySingleRelease(1);
        }
        
        if (serialInArray[3] == 1) {
          if ( sampleRate > 0 ) {
            keySinglePress(2); 
          }
        } else {
          keySingleRelease(2);
        }
        
        if (serialInArray[4] == 1) {
          if ( sampleRate > 0 ) {
            keySinglePress(3); 
          }
        } else {
          keySingleRelease(3);
        }
       }
        
        // Send a capital A to request new sensor readings:
        //delay(200);
        port.write('A');
        // Reset serialCount:
        serialCount = 0;
        //println("val: " + val);
      }
   
//   // Add the latest byte from the serial port to array:
//   serialInArray[serialCount] = inByte;
//   serialCount++;
//   // If we have 3 bytes:
//   if (serialCount > 11 ) {
//     // print the values (for debugging purposes only):
//     println(Arrays.toString(serialInArray));
//     // Send a capital A to request new sensor readings:
//     delay(200);
//     port.write('A');
//     // Reset serialCount:
//     serialCount = 0;
   }
  } catch (Exception e) {
    println("Initialization exception");
//    String portName = Serial.list()[0]; //change the 0 to a 1 or 2 etc. to match your port
//    port = new Serial(this, portName, 9600);
    port.write('A');
//    decide what to do here
  }
}

//void receiveInput() {
//  if ( myPort.available() > 0) 
//  {  // If data is available,
//    val = myPort.readStringUntil('\n');         // read it and store it in val
//    println("val: " + val);
//    if (val != null) {
//      val = trim(val);
//      //println("val: " + val);
//      pageAggregate += Integer.parseInt(val);
//      aggregateCounter++;
//    }
//  } 
//  //println(val); //print it out in the console
//
//}

long decidePageNum() {
  if(millis() - time >= wait){
    //println("yo");
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

long decideKeyNum(int keyNum) {
  if(millis() - keyTime >= keyWait){
    println("yo");
    keyTime = millis();//also update the stored time
    if (aggregateKeyCounter[keyNum] != 0) {
      keyAvg[keyNum] = (int)(keyAggregate[keyNum] / aggregateKeyCounter[keyNum]);
      println("keyAvg: " + keyNum + " " + keyAvg[keyNum]);
    }
    keyAggregate[keyNum] = 0;
    aggregateKeyCounter[keyNum] = 0;
  }
  return pageAvg;
}

void audio() {
  background(0);
  stroke(255);
  text("pageValInside: " + pageValInside + " pagValOutside: " + pageValOutside,0,height-5);
  text("isLooping: " + isLooping,0,height-20);
  text("playOnceMain: " + playOnceMain + " playOnceLoop: " + playOnceLoop,0,height-35);
  text("Player Position: " + player.position(),0,height-50);
  text("pageVal loop start: " + getSongPosition(PosMark.LoopStart) + " pageVal loop end: " + getSongPosition(PosMark.LoopEnd),0,height-65);
  text("pageVal loop start: " + getSongPosition(PosMark.ExitStart) + " pageVal loop end: " + getSongPosition(PosMark.LoopEnd),0,height-65);
 
  pageValOutside = pageAvg;
 
   if (pageValInside != pageValOutside) {
     float tempPosMark;
     if (isLooping) {
       tempPosMark = getSongPosition(PosMark.LoopEnd)-20;
     } 
     //else if (player.position() > getSongPosition(PosMark.ExitStart) && getSongPosition(PosMark.ExitStart) > 0) {
       //tempPosMark = getSongPosition(PosMark.MainEnd); //player.play(pages[pageValInside].exitStart);
     //}
     else {
       tempPosMark = getSongPosition(PosMark.LoopEnd)-20;
     }
     if ((player.position() >= tempPosMark)) {
       pageValInside = pageValOutside;
       isLooping = false;
       playOnceMain = true;
       playOnceLoop = true;
       playOnceExit = true;
     }
   } else {
     if (isLooping && playOnceLoop) {
         if (player.isPlaying()){}
//         
//         player.setLoopPoints(getSongPosition(PosMark.LoopStart), getSongPosition(PosMark.LoopEnd));
//           player.loop();
//         playOnceLoop = false;
     } else {
       if (playOnceMain) { //player.position() <= getSongPosition(PosMark.MainStart) && 
        player.play(getSongPosition(PosMark.MainStart)); 
        playOnceMain = false;
         if (pageValInside == 5) {
           output.playNote( 0.3f, 0.25f, new Tick() );
         } else if (pageValInside == 6) {
           output.pauseNotes();
         }
       }
       if (player.position() > (getSongPosition(PosMark.MainEnd) - (2 * beatTime + offset)) && playOnceExit && getSongPosition(PosMark.ExitStart) > 0) {
         player.play(getSongPosition(PosMark.ExitStart));
         playOnceExit = false;
         playOnceExitEnd = true;
       }
       if ((player.position() >= getSongPosition(PosMark.MainEnd) && playOnceLoop) || 
           (player.position() >= getSongPosition(PosMark.ExitEnd) && playOnceExitEnd)) {
//         player.play(getSongPosition(PosMark.LoopStart));
         player.setLoopPoints(getSongPosition(PosMark.LoopStart), getSongPosition(PosMark.LoopEnd));
         player.loop();
         isLooping = true;
         playOnceLoop = false;
         playOnceExitEnd = false;
       }
     }
   }
   
   
  switch(level) {
     case 0:
      // println();
//       for (int s : noteSequence) {
//         print(s);
//       }
       if (noteSequence.size() > 4 && noteSequence.get(1) == 0 && noteSequence.get(2) == 1 && noteSequence.get(3) == 2 && noteSequence.get(4) == 1 ) {
         level++; 
       }
       break;
     case 1:
       if (noteSequence.size() > 3 && noteSequence.get(0) == 2 && noteSequence.get(1) == 1 && noteSequence.get(2) == 0 && noteSequence.get(3) == 0 
           && noteSequence.get(4) == 2) {
         level++; 
       }
       basscRow = new int[] {2,2,2,1, 1,2,0,2, 0,2,2,2, 2,2,2,2, 2,2,2,1, 1,2,0,2, 0,2,2,2, 2,2,2,2};
       bassdRow = new int[] {0,2,1,0, 2,2,2,2, 0,2,2,2, 2,2,2,2, 0,2,1,0, 2,2,2,2, 0,2,2,2, 2,2,2,2};
       bassaRow = new int[] {1,2,0,2, 2,2,1,2, 0,2,2,2, 2,2,2,2, 1,2,0,2, 2,2,1,2, 0,2,2,2, 2,2,2,2};
      bassc2Row = new int[] {2,2,2,2, 2,2,2,2, 0,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 0,2,2,2, 2,2,2,2};
      break;
     case 2:
      if (noteSequence.size() > 3 && noteSequence.get(0) == 2 && noteSequence.get(1) == 1 && noteSequence.get(2) == 0 && noteSequence.get(3) == 0 
           && noteSequence.get(4) == 2) {         level++; 
       }
       basscRow = new int[] {2,2,2,1, 0,2,2,1, 2,2,2,2, 2,2,2,2, 2,2,2,1, 0,2,2,1, 2,2,2,2, 2,2,2,2};
       bassdRow = new int[] {0,2,1,0, 0,2,1,0, 0,2,2,2, 2,2,2,2, 0,2,1,0, 0,2,1,0, 0,2,2,2, 2,2,2,2};
       bassaRow = new int[] {1,2,0,2, 1,2,0,2, 2,2,2,2, 2,2,2,2, 1,2,0,2, 1,2,0,2, 2,2,2,2, 2,2,2,2};
      bassc2Row = new int[] {2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2};
      break;
     case 3:
       basscRow = new int[] {2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2};
       bassdRow = new int[] {2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2};
       bassaRow = new int[] {2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2};
      bassc2Row = new int[] {2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2, 2,2,2,2};
       
  }
   
   if (pageValInside != pageValOutside) {
     switch (pageValOutside)
    {
      case 0:
        break;
      case 1: //space bar  
        if (yawnBool) {      
          yawn.trigger();
          yawnBool = false;
        }
        break;
      case 2:
  
        break;  
      case 3:
  
        break;
      case 4:
  
        break;
      case 5:
  
        break;
      case 6:
  
        break;
      case 7:
        player.pause();
        break;
    }
   }
   
  // use the mix buffer to draw the waveforms.
//  for (int i = 0; i < output.bufferSize() - 1; i++)
//  {
//    float x1 = map(i, 0, output.bufferSize(), 0, width);
//    float x2 = map(i+1, 0, output.bufferSize(), 0, width);
//    line(x1, 50 - output.left.get(i)*50, x2, 50 - output.left.get(i+1)*50);
//    line(x1, 150 - output.right.get(i)*50, x2, 150 - output.right.get(i+1)*50);
//  }

  for (int i = 0; i < player.bufferSize() - 1; i++)
  {
    float x1 = map(i, 0, player.bufferSize(), 0, width);
    float x2 = map(i+1, 0, player.bufferSize(), 0, width);
    line(x1, 50 - player.left.get(i)*50, x2, 50 - player.left.get(i+1)*50);
    line(x1, 150 - player.right.get(i)*50, x2, 150 - player.right.get(i+1)*50);
  }
}

int getSongPosition(PosMark mark) {
  int pos = 0;
  switch (mark) {
    case MainStart:
      pos = pages[pageValInside].mainStart * beatTime + offset;
      break;
    case MainEnd:
      pos =pages[pageValInside].mainEnd * beatTime + offset;
      break;
    case EnterStart:
      pos = pages[pageValInside].enterStart * beatTime + offset;
      break;
    case EnterEnd:
      pos = pages[pageValInside].enterEnd * beatTime + offset;
      break;
    case ExitStart:
      pos = pages[pageValInside].exitStart * beatTime + offset;
      break;
    case ExitEnd:
      pos = pages[pageValInside].exitEnd * beatTime + offset;
      break;
    case LoopStart:
      pos = pages[pageValInside].loopStart * beatTime + offset;
      break;
    case LoopEnd:
      pos = pages[pageValInside].loopEnd * beatTime + offset;
      break;
  }
  return pos;
}

void keyPressed()
{
  switch (key)
  {
    case '1': //space bar
      pageValOutside = 1;
//      player.play(0);
////      player.setLoopPoints(0, 3000);
//      player.loop();
//      player.setLoopPoints(16 * beatTime + offset, 32 * beatTime + offset);

//      player.play();
      
      println("key 1 " + pageValOutside);
      break;
    case '2':
      pageValOutside = 2;
      break;  
    case '3':
      pageValOutside = 3;
      break;
    case '4':
      pageValOutside = 4;
      break;
    case '5':
      pageValOutside = 5;
      break;
    case '6':
      pageValOutside = 6;
      break;
    case '7':
      pageValOutside = 7;
      break;
    case '8':
      pageValOutside = 8;
      break;
    case '9':
      pageValOutside = 9;
      break;
    case 'z': //space bar
      keySinglePress(0);
      break;
    case 'x':
      keySinglePress(1);
      break;  
    case 'c':
      keySinglePress(2);
      break;
    case 'v':
      keySinglePress(3);
      break;
    case 'q':
      adruinoInput = !adruinoInput;
      break;
  }
  
}

void keyReleased() {
  switch(key) {
   case 'z': //space bar
      keySingleRelease(0);
      break;
    case 'x':
      keySingleRelease(1);
      break; 
    case 'c':
      keySingleRelease(2);
      break;
    case 'v':
      keySingleRelease(3);
      break; 
  }
}

void keySinglePress(int keyNum) {
  if (keysSinglePress[keyNum]) {
    fluteKeys[keyNum].trigger();
    keysSinglePress[keyNum] = false;
    if (noteSequence.size() > 4)
      noteSequence.remove(0);
    noteSequence.add(keyNum);
  }
}

void keySingleRelease(int keyNum) {
  fluteKeys[keyNum].stop();
  keysSinglePress[keyNum] = true;
}

void delay(int delay)
{
  int time = millis();
  while(millis() - time <= delay);
}
