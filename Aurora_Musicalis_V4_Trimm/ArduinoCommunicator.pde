//I came up with the idea of this class, it made sending the protocols to the Arduino's easier

class ArduinoCommunicator {

  Serial port; //the port through which the Pi communicates with the Arduino
  boolean identityCrisis = true; //whether the communicator knows with which Arduino it communicates
  int name; //the number of the communicator, indicating with which Arduino it communicates

  ArduinoCommunicator(Serial portnumber) {
    port = portnumber;
  }

  void run(String data) {
    //if the communicator knows with which arduino it is communicating, communicate; 
    if (!identityCrisis) {
      port.write(data);
    } else { //otherwise,
      waitForName(); //read the serial until you see a number indicating a name
    }
  }

  void waitForName() { //the arduino will write a number from 1 to 3 in its setup, indicating which part of the installation it controls
    if (port.available() > 0) { //if the arduino writes something
      //read the first character and indicate that you know who you are.
      String received = port.readStringUntil('\n');
      name = int(received.trim().charAt(0));
      identityCrisis = false;
      println("My name is: "+name);
    }
  }
}