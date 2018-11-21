//This class was my idea

class Motor {

  //STATICS
  int extra_delay; //how much extra time the motor should wait to change its protocol
  int myNumber;   //the motor's name
  float maxDiff = 10; //how much this motor's speed can differ from that of a motor adjacent to this one
  float maxPos = 100; //how far this motor can move from the middle

  //VARIABLES
  float position = 0;    //will try to near the position the motor is in
  float motorSpeed = 0;  //saves the speed the motor actually has
  float wantedSpeed = 0; //saves the speed the motor would have in an ideal world

  float timeStamp = 0;   //saves when the motor stops moving
  int counter = 0; //saves how many frames the motor has moved
  int timer;

  //BOOLEANS
  boolean in_position = false; //motor is in a good starting position, set to true during calibration
  boolean toggle = true; //motor should receive a new speed or move back to starting position
  boolean stop = false; //motor went too far outward and should stop moving
  boolean moving_back = false; //motor is going back to its starting position

  Motor(int number) {
    myNumber = number;
    extra_delay = number*100;
  }

  void run() {
    changeSpeed(); //changes the motor's speed once per second (line 34)
    checkPosition(); //checks whether the motor moved too far (line 92)
  }

  void changeSpeed() { //I believe this was my idea

    if (millis() >= timer) {
      timer += 1000; //set timer to over one second

      if (toggle) { //change speed  

        motorSpeed = -average_volume/2;   
        wantedSpeed = motorSpeed;

        checkOtherMotors(); //check whether the speed does not differ too much from that of other motors (line 70)

        timer = 0; //reset timer
        //reset booleans
        toggle = false;
        moving_back = false;
      } else { //change direction

        if (stop) { //if the motor went too far
          wantedSpeed *= timeStamp/10; //move back with a speed depending on previous speed and when the motor stopped, so it will end up exactly in the middle
          stop = false; //reset boolean
        }

        //change direction
        motorSpeed = -wantedSpeed;
        wantedSpeed = motorSpeed; //save new speed as desired speed

        timer = 0; //reset timer
        //reset booleans
        toggle = true;
        moving_back = true;
      }
    }
  }

  void checkOtherMotors() { //The way to check the other motors was Piets idea, but this function was designed by me
    if (myNumber % 2 == 0) { //if I'm even
      for (int i=0; i<amountOfDCs; i++) {
        //check whether speed of adjacent motors differs a lot
        if (motors[i].myNumber == myNumber-1 || motors[i].myNumber == myNumber+1 || motors[i].myNumber == myNumber+3) {
          if (motors[i].motorSpeed - motorSpeed > maxDiff || motors[i].motorSpeed - motorSpeed < -maxDiff) {
            motorSpeed = motors[i].motorSpeed; //if the speed differs too much, change my speed to that of the motor with which I differ too much
          }
        }
      }
    } else { //if I'm odd
      for (int i=0; i<amountOfDCs; i++) {
        //check whether speed of adjacent motors differs a lot
        if (motors[i].myNumber == myNumber-3 || motors[i].myNumber == myNumber-1 || motors[i].myNumber == myNumber+1) {
          if (motors[i].motorSpeed - motorSpeed > maxDiff || motors[i].motorSpeed - motorSpeed < -maxDiff) {
            motorSpeed = motors[i].motorSpeed; //if the speed differs too much, change my speed to that of the motor with which I differ too much
          }
        }
      }
    }
  }

  //my idea. We used DC motors (because Steppers are pricy) but we still wanted a bit of insight on where the motor could be.
  void checkPosition() {
    //update position and timer
    position += motorSpeed;
    timer++;

    println(position);
    if ((position > maxPos || position < -maxPos) && !stop && !moving_back) { //if the motor hasn't already stopped, is not moving back, and has moved too far out
      //stop the motor and save when it stopped
      stop = true;
      motorSpeed = 0;
      timeStamp = timer;
    }
  }

  //my idea
  void calibrate(char input) { //not called in Motor.run() but in the main run()
    switch(input) {
    case ',': //if the input is <, move the motor up with half speed
      motorSpeed = 5;
      break;

    case '.': //if the input is >, move the motor down with half speed
      motorSpeed = -5;
      break;

    case ENTER: //if the input is enter, accept this position as the correct position
      in_position = true;
      //feed back the motor is in position with a mario coin sound
      feedback.rewind();
      feedback.play();
      //set the timer from this moment
      timer = millis() + 1000 + extra_delay;
      break;

    default: //if there is no known input, don't move the motor
      motorSpeed = 0;
      break;
    }
    //save data for protocolwriting and see this position as the starting position
    speedvalue[myNumber] = round(map(motorSpeed, -10, 10, 0, 510));
    position = 0;
  }
}