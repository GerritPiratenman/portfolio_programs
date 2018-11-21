//Piet created this class in an early stage, after that,
//I worked on it a bit, too so it could also represent the new functionality we created

class Demo {

  float[] location = new float[amountOfDCs]; //will save each motor's y-location

  Demo() {
  }

  void run() {
    background(0);
    //draw colored squares for the LED strips

    noStroke();
    for (int i = 0; i < amountOfLEDs; i++) {
      float Color = colorvalue[i]; //take the color value for the gradient
      float brightness = brightnessvalue[i]; //take the brightness value
      
      //I created this color scheme, very proud of the idea to use cosines for the overlap ghehe
      Color = map(Color, 0, 100, 0, PI);
      //the value will be used in a cosine to create a visually pleasing overlap of red and green
      float r = 210 - cos(Color)*75; //135 - 255
      float g = 150 + cos(Color)*75; //75 - 225
      float b = 100;

      //make all colors darker if the brightness is lower
      brightness /= 100;
      r *= brightness;
      g *= brightness;
      b *= brightness;

      //draw squares
      fill(r, g, b);
      rect(i*50+100, height/2, 50, 50);
    }

    stroke(255);
    fill(0, 0);
    //draw circles for the motors
    for (int i = 0; i < amountOfDCs; i++) {
      float temp = speedvalue[i] - 255;
      if (temp > 0) temp *= 0.9; //simulate gravity by making moving up slower (moving down has been slowed somewhere else in the program)
      temp = map(temp, -255, 255, -10, 10);

      location[i] += temp;//move the demo motor

      //draw inopaque circles for the demo motors
      ellipse(i*150+100, height/2+location[i], 40, 40);
    }
  }
}