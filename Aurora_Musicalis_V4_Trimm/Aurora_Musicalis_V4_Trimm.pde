/**
  Most of this program was conceived together, then cleaned and structured by me.
  I'll note who came up with which part at the beginning of every function.
  Do note that nothing was actually created by one person, we always worked together.

 Aurora Musicalis core program
 Piet van Tiggelen and Yorrick van der Ouw
 Created for Hybrid Worlds in module 8 of Creative Technology
 This program uses the minim library to create a DFT of 10 milliseconds of an inputted piece of music every 10 milliseconds.
 The DFT is used to measure the volume of each frequency and write data to three Arduinos accordingly.
 Arduinos 1 and 2 are Unos which control LED strips, and Arduino 3 is a Mega controlling eight DC motors
 
 If this program is used without the installation attached, comment out anything referring to Arduinos or it will crash
 */

//LIBRARIES
//import minim, fourier, and serial library
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.serial.*;

//STATICS
//statics noting the amount of each part are to be controlled
int amountOfArduinos = 3;
int amountOfLEDs = 20;
int amountOfDCs = 8;
int minAmp = -160;     //the amplitude under which sound is viewed as nonexisting

//OBJECTS
//call objects
Minim minim;
FFT fft;
AudioPlayer music;    //will contain the music that is being analyzed
AudioPlayer startup;  //will contain the startup sound
AudioPlayer feedback; //will contain the confirmation sound
Demo demo;

//call object arrays
ArduinoCommunicator[] arduinos = new ArduinoCommunicator[amountOfArduinos];
Motor[] motors = new Motor[amountOfDCs];

//VARIABLES
//this two-dimensional array will contain the filtered and sampled data of the DFT, plit into 20 segments
float[][] freqAmp; //data per frequency segment will be saved as follows: [average frequency][average volume]

//these arrays will contain the translated data, ready to be sent to the arduinos
int[] brightnessvalue = new int[amountOfLEDs]; //0 - 100, where 0 is off and 100 is full brightness
int[] colorvalue = new int[amountOfLEDs];      //0 - 100, where 0 is green and 100 is red
int[] speedvalue = new int[amountOfDCs];       //0 - 510 (2 bytes), where 0 is moving down, 510 is moving up, and 255 is not moving

String mp3name = "hptheme.mp3"; //will save which musical piece will be played

float average_volume; //will save the average volume of all audible frequencies per frame, used to calculate motorSpeed (Motor class)

int chosenMotor = 0; //will save the number of the motor that is selected (for calibration)

boolean ready = false; //will be set to true when calibration is done. Allowing the program to run.
//This boolean is also used for efficiency, making sure calibrating() does not have to be called every frame.

void setup() {   //not sure who actually wrote this, but it's just a setup
  size(1500, 700);
  frameRate(10); //The framerate needs to be low because the Raspberry Pi has trouble with fast Serial communication.

  //initialize arduinocommunicators, including which port they should communicate over (ArduinoCommunicator class)
  println(Serial.list());
  for (int i = 0; i < arduinos.length; i++) {
    Serial comm = new Serial (this, Serial.list()[i+2], 9600); //the first two ports of the Raspberry Pi are not used for Serial
    arduinos[i] = new ArduinoCommunicator(comm);
  }

  delay(2000); //give the Arduinos some time to accept the communication

  //let the Communicators know with which part of the installation they are communicating
  for (ArduinoCommunicator a : arduinos) {
    a.waitForName();
  }

  //initialize motors (Motor class)
  for (int i = 0; i < motors.length; i++) {
    motors[i] = new Motor(i);
  }

  //just to be sure, so the motors won't move at initialization  
  for (int i = 0; i<amountOfDCs; i++) {
    speedvalue[i] = 255;
  }

  //initialize the minim and load mp3s into the audioplayers
  minim = new Minim(this);
  startup = minim.loadFile("r2d2screm.mp3", 1024);
  feedback = minim.loadFile("coin.mp3", 1024);
  music = minim.loadFile(mp3name, 1024);

  //initialize the demo visualization
  demo = new Demo();

  //feed back that initializing has been completed with screaming R2D2
  startup.play();
}

void draw() {  //not sure who actually wrote this but it's just the draw function
  if (ready) {
    run(); //line 106
  } else if (!calibrating()) { //boolean function (line 261)
    get_ready(); //start displaying (line 241)
  } else {
    calibrate(); //line 251
  }
  demo.run(); //Demo class
}

void run() {  //I wrote this, a run() function is usually what I do
  fft.forward(music.mix);    //analyze the next part of the music
  freqAmp = getScaledData(); //fill freqAmp with the scaled input (line 119)

  for (int i = amountOfDCs-1; i >= 0; i--) { //this for-loop goes backwards so motors won't copy the speed of motors with lower numbers, which proved problematic in the sense that motors kept going at the same speed
    motors[i].run();
  }

  whatToSerial();            //map the values in freqAmp (line 176)
  writeProtocol();          //construct the protocol and write it to the Arduinos (line 194)
}

float[][] getScaledData() { //The division and scaling of data is my work, making the data of higher frequencies more visible is Piet's work

  float[][] input = new float[music.bufferSize()/3][2]; //saves only the useful frequencies
  float[][] scaled_data = new float[amountOfLEDs][2];   //saves the segmented data

  float total_volume = 0; //saves the total volume of all hearable frequencies, used to scale perceived loudness if the music is softer, since the human hearing system does so too

  int segment_size; //saves the size of segments for scaled_data

  //this is from the original FFT program, although the numbers have been edited a little
  for (int i = 0; i < input.length; i++) {
    //convert the amplitude to a dB value, remove unaudible values and normalize the data
    float bandDB = 20 * log(2*fft.getBand(i) / fft.timeSize());
    if (bandDB < minAmp || i < 10 || i > 20000) bandDB = minAmp; //if the amplitude is below the minimum or the frequency is out of hearing range, regard the frequency as inaudible
    bandDB -= minAmp; //normalize the data (otherwise it is far below 0)

    input[i][0] = i;
    input[i][1] = bandDB;
  }

  //this nested for-loop where j influences i was my idea so the data could be gathered the way we needed it
  segment_size = calculateSegmentSize(input); //

  for (int i = 0; i < scaled_data.length; i++) { //for each segment
    float averagef = 0; //average frequency
    float averageA = 0; //average amplitude

    //calculate the average frequency and amplitude for this segment
    for (int j = i*segment_size; j < (i+1)*segment_size; j++) {
      averagef += input[j][0];
      averageA += input[j][1];
      total_volume += input[j][1]; //intermezzo step: add the amplitude of this frequency to the total_volume variable
    }

    averagef /= segment_size;
    averageA /= segment_size;

    //now that we have the averages, put them in scaled_data
    scaled_data[i][0] = averagef;
    scaled_data[i][1] = averageA;
  }

  //this was Piet's idea, it made the results better-looking
  for (int i = 0; i < scaled_data.length; i++) {
    if (scaled_data[i][1] > 0) scaled_data[i][1] += sqrt(total_volume/1000); //if this segment's frequencies are audible, add a little scaler to it depending on the total volume so higher frequencies, which usually have a smaller amplitude, are still visible
  }

  average_volume = total_volume / (scaled_data.length * segment_size); //save the average volume
  return scaled_data;
}

int calculateSegmentSize(float[][] input) { //my idea
  int highestf = 0; //will save which is the highest audible frequency

  for (int i = 0; i < input.length; i++) {
    if (input[i][1] > 0) { //if the frequency is audible
      highestf = i;        //save this as the highest audible frequency
    }
  }
  return int(highestf/amountOfLEDs); //return how many frequencies there should be per LED strip
}

//not sure anymore who came up with this system.
void whatToSerial() { //map the values in freqAmp
  for (int i = 0; i < amountOfDCs; i++) {
    speedvalue[i] = round(map(motors[i].motorSpeed, -10, 10, 0, 510)); //map the speed to a value useful for the communication protocol
    //failsafes
    if (speedvalue[i] > 510) speedvalue[i] = 510;
    if (speedvalue[i] < 0) speedvalue[i] = 0;
    //make moving down a little slower because moving up is slowed by gravity NOTE: THIS IS PROBABLY WHERE SOMETHING WENT WRONG WITH THE MOTORS DURING THE DEMODAY
    if (speedvalue[i] > 0 && speedvalue[i] < 255) speedvalue[i] *= 1.1;
  }

  for (int i = 0; i<amountOfLEDs; i++) {
    colorvalue[i] = round(map(freqAmp[i][0], 0, music.bufferSize()/3, 0, 100));
    brightnessvalue[i] = round(map(freqAmp[i][1], 0, 110, 0, 100));
    if (colorvalue[i] > 100) colorvalue[i] = 100;
    if (brightnessvalue[i] > 100) brightnessvalue[i] = 100;
  }
}

//the protocol was designed by Gijs, our Arduino-man. How we wrote it was Piet's idea
void writeProtocol() {
  //fill the strings with the communication protocol
  String LEDString1  = LEDProtocol(0); //line 209
  String LEDString2  = LEDProtocol(amountOfLEDs/2); //line 209
  String motorString = motorProtocol(); //line 228

  //send the strings to the correct 
  for (ArduinoCommunicator a : arduinos) { 
    //the numbering is a little weird, we know, but there was no way to read a character into a string except for reading it's ascii value
    if (a.name == 49) a.run(LEDString1); //write to the arduino uno with the low frequency LED strips
    else if (a.name == 50) a.run(LEDString2); //write to the arduino uno with the high frequency LED strips
    else if (a.name == 51) a.run(motorString); //write to the funduino mega with the motors
    else println("This is not an existing arduino.");
  }
}

//also Piet's idea
String LEDProtocol(int starting_point) {
  int StringLength = amountOfLEDs/2; //length of each LED protocol String
  String[] LEDs = new String[amountOfLEDs/2]; //saves the protocol for each LED
  String LEDString = ""; //the return string  

  for (int i = 0; i < StringLength; i++) {
    //save data (0 - 100) as color (C) and brightness (B) values
    LEDs[i] = "C" + colorvalue[i+starting_point] +"B" + brightnessvalue[i+starting_point];
  }

  for (int i =0; i < StringLength; i++) {
    //separate the values (C[color]B[brightness]) for each LED strip by commas
    LEDString += LEDs[i] + ",";
  }
  LEDString += ";"; //end with a semicolon

  return LEDString;
}

//Also Piet's idea
String motorProtocol() {
  String motorString = ""; //the return string

  for (int i = 0; i<amountOfDCs; i++) {
    //separate the values (0 - 510) for each motor by commas
    motorString += speedvalue[i] + ",";
  }
  motorString += ";"; //end with a semicolon

  return motorString;
}

//my idea. This function makes sure the installation would not break because of it starting while in a bad position
void get_ready() { //set everything from calibration mode to run mode
  music.loop(); //start the music

  fft = new FFT(music.bufferSize(), music.sampleRate()); //initialize the fft analysis
  fft.window(FFT.BLACKMAN); //set the analysis style to a precise one

  println("Motors set, ready for music!");
  ready = true; //tell the program it is ready to run
}

//my idea
void calibrate() { //manually set the motors in a good starting position
  writeProtocol(); //write the protocol so the motors can actually move

  //write information about calibration on the demo screen
  fill(255);
  text("Press a number to choose that motor.\n\n<up> : Move motor up.\n<down> : Move motor down.\n<Space> : Pause motor\n<Enter> : set motor in this position.", 20, 20);
  fill(0);
}

//my idea
boolean calibrating() {
  for (Motor m : motors) {
    if (!m.in_position) return true; //if any motor is not yet in position, return that calibration is still in progress
  }
  return false; //otherwise, return calibration is done
}

//my work, but not anything impressive
//allows the user to interact with the program, either to calibrate motors or to select a new song
void keyPressed() {
  switch(key) {
  case ',':
    if (calibrating()) 
      motors[chosenMotor].calibrate(key);
    break;

  case '.':
    if (calibrating()) 
      motors[chosenMotor].calibrate(key);
    break;
  }
}

void keyReleased()
{
  String prevname = mp3name; //used to check whether the chosen song has changed

  switch(key) {

    //MUSIC CHOOSING COMMANDS
  case 'a':
    mp3name = "Mariah Carey - All I Want For Christmas Is You.mp3";
    break;

  case 's':
    mp3name = "Apocalyptica - Farewell copy.mp3";
    break;

  case 'd':
    mp3name = "hptheme.mp3";
    break;

  case 'f':
    mp3name = "newalbion.mp3";
    break;

  case 'g':
    mp3name = "Kraftwerk - Das Model.mp3";
    break;

  case 'h':
    mp3name = "America, Fuck Yeah! Ultimate Edition copy.mp3";
    break;

  case 'j':
    mp3name = "feelgood.mp3";
    break;

  case 'k':
    mp3name = "Daydream_Bliss.mp3";
    break;

  case 'l':
    mp3name = "DarthVadersTheme.mp3";
    break;

  case 'z':
    mp3name = "more star wars.mp3";
    break;

  case 'x':
    mp3name = "beethoven.mp3";
    break;

  case 'c':
    mp3name = "vivaldi.mp3";
    break;

  case 'v':
    mp3name = "pie.mp3";
    break;

  case 'b':
    mp3name = "potc.mp3";
    break;

  case 'n':
    mp3name = "africa.mp3";
    break;

  case 'm':
    mp3name = "dovahkiin.mp3";
    break;

  case 'q':
    mp3name = "tron.mp3";
    break;

    //MOTOR CHOOSING COMMANDS
  case '0':
    chosenMotor = 0;
    break;

  case '1':
    chosenMotor = 1;
    break;

  case '2':
    chosenMotor = 2;
    break;

  case '3':
    chosenMotor = 3;
    break;

  case '4':
    chosenMotor = 4;
    break;

  case '5':
    chosenMotor = 5;
    break;

  case '6':
    chosenMotor = 6;
    break;

  case '7':
    chosenMotor = 7;
    break;

    //VOLUME COMMANDS
  case '-':
    if (ready) {
      music.setGain(-21);
      break;
    }

  case '[':
    if (ready) {
      music.setGain(-12);
      break;
    }

  case ']':
    if (ready) {
      music.setGain(-6);
      break;
    }

  case '#':
    if (ready) {
      music.setGain(2);
      break;
    }

  case '=':
    if (ready) {
      music.setGain(7);
      break;
    }

    //CALIBRATION COMMANDS
  case ' ': //manual reset to calibration
    if (ready) {
      ready = false;
      for (int i =0; i<amountOfDCs; i++) {
        speedvalue[i] = 255;
        motors[i].motorSpeed = 0;
        motors[i].in_position = false;
      }
    }
    break;

  case ENTER:
    if (calibrating()) 
      motors[chosenMotor].calibrate(key);
    break;

  default:
    if (calibrating()) 
      motors[chosenMotor].calibrate(' ');
    break;
  }

  if (mp3name != prevname && ready) { //if calibration is not happening and the chosen song has changed:
    //close the current audioplayer and open a new one playing the new song
    music.close();
    music = minim.loadFile(mp3name, 1024);
    music.loop();
  }
}