/*   
 USB_Octomod_P5.pde
 USB-Octomod OSC Host Program
 Version 2 - updated 11.13.2010
 Copyright 2010, Greg Surges
 surgesg@gmail.com
 http://www.gregsurges.com/
 
 Copyright (c) 2010, Greg Surges
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name Greg Surges nor the names of any contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, 
 BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
 SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import themidibus.*;
import controlP5.*;
import oscP5.*;
import netP5.*;
import processing.serial.*;

ControlP5 controlP5;
Serial teensy;
OscP5 oscP5;

ListBox l, midiList;
Numberbox portBox;
MidiBus midi;

int channel; // first osc argument, corresponds to DAC output channel (0 - 7) 
int inputData; // second osc argument, 10-bit number to output
int updateBits = 3; // dac update behavior register, update immediately when data received
int dacChip; // used to select one of the two chips
int spiWord; // the assembled 16-bit word is stored here before output over serial
String binaryString; 
ArrayList <Byte> outputData = new ArrayList();
byte outputBytes[];
int dataIndex = 0;
int data[];
double previousUpdate = 0;
double currentTime;
String portName;
boolean serialConnected = false;
int newPort = 9999;
boolean portNeedsUpdate = false;

int channelData[]; // store current output value for each channel
boolean newData[];
Slider sliders[];
Slider sliderOne, sliderTwo, sliderThree, sliderFour, sliderFive, sliderSix, sliderSeven, sliderEight;

PFont font;

void setup() {
  size(710, 175);
  frameRate(16);
  midi = new MidiBus(this, 0, 0);
  controlP5 = new ControlP5(this);

  l = controlP5.addListBox("serialPorts", 550, 65, 140, 140);
  l.setItemHeight(15);
  l.setBarHeight(15);

  l.captionLabel().toUpperCase(true);
  l.captionLabel().set("serial ports");
  l.captionLabel().style().marginTop = 3;
  l.valueLabel().style().marginTop = 3; // the +/- sign
  for(int i=0; i < Serial.list().length; i++) {
    l.addItem(Serial.list()[i],i);
  }
  
  midiList = controlP5.addListBox("midiPorts", 15, 33, 140, 140);
  midiList.setItemHeight(15);
  midiList.setBarHeight(15);
  midiList.captionLabel().toUpperCase(true);
  midiList.captionLabel().set("MIDI inputs");
  midiList.captionLabel().style().marginTop = 3;
  midiList.valueLabel().style().marginTop = 3;
  for(int i=0; i < midi.availableInputs().length; i++) {
    midiList.addItem(midi.availableInputs()[i],i);
  }  
  //l.setColorLabel(color(100, 200, 50));
  //l.close();

  portBox = controlP5.addNumberbox("port", 550, 15, 140, 15);
  portBox.setValue(9999);
  portBox.setId(1);
  portBox.setColorLabel(color(0, 0, 0));
  portBox.setDecimalPrecision(0);

  oscP5 = new OscP5(this, 9999); // start oscp5 listen on port 9999
  outputData = new ArrayList();
  outputBytes = new byte[1];
  channelData = new int[8];
  newData = new boolean[8];
  data = new int[8];
  font = loadFont("Monaco-9.vlw");
  textFont(font, 9);
  fill(100, 200, 50);
  stroke(100, 200, 50);
  sliders = new Slider[8];
  sliders[0] = new Slider(270, 40, 275);
  sliders[1] = new Slider(270, 55, 275);
  sliders[2] = new Slider(270, 70, 275);
  sliders[3] = new Slider(270, 85, 275);    
  sliders[4] = new Slider(270, 100, 275);
  sliders[5] = new Slider(270, 115, 275);
  sliders[6] = new Slider(270, 130, 275);
  sliders[7] = new Slider(270, 145, 275);
}

void draw() {
  if(!mousePressed && portNeedsUpdate) {
    oscP5.dispose();      
    oscP5 = new OscP5(this, newPort); // start oscp5 listen on port 9999
    portNeedsUpdate = false;
  }
  background(250, 250, 255); 
  fill(0, 0, 0, 100);
  rect(10, 10, width - 20, height - 20);
  fill(250, 255, 255, 200);
  rect(160, 15, 385, 144);
  fill(0, 0, 0);
  stroke(0, 0, 0);
  text("SERIAL: "+ portName +" OSC: LISTENING ON PORT: "+ newPort +".", 165, 30);
  text("/CHANNEL 1: " + channelData[0], 165, 45);
  text("/CHANNEL 2: " + channelData[1], 165, 60);
  text("/CHANNEL 3: " + channelData[2], 165, 75);
  text("/CHANNEL 4: " + channelData[3], 165, 90);
  text("/CHANNEL 5: " + channelData[4], 165, 105);
  text("/CHANNEL 6: " + channelData[5], 165, 120);
  text("/CHANNEL 7: " + channelData[6], 165, 135);
  text("/CHANNEL 8: " + channelData[7], 165, 150); 
  for(int i = 0; i < 8; i++) {
    sliders[i].update(channelData[i]);
  }
}


// need to update to select midi in port. MidiBus.list() will list them, this should be in a listbox
void controllerChange(int channel, int number, int value){
  if(number >= 20 && number <= 27){
    channelData[number - 20] = (int)map(value, 0, 127, 0, 1023);
    writeValue(number - 20, int(map(value, 0, 127, 0, 1023)));  
  }
}

void oscEvent(OscMessage theOscMessage) {
  println(theOscMessage);
  if(serialConnected) { 
    if(theOscMessage.checkAddrPattern("/dac")==true) {
      for(int i = 0; i < 8; i++) {
        data[i] = (int)theOscMessage.get(i).intValue();
        if(data[i] != channelData[i]) {
          channelData[i] = data[i];
          newData[i] = true;
        } 
        else {
          newData[i] = false;
        }
      }
      for(int i = 0; i < 8; i++) {  
          println(data[i] + " " + channelData[i] + " " + newData[i]);
         if(newData[i] == true) {
           println("new data sent over serial");
          writeValue(i, channelData[i]); // should probably only call this function if the value has changed (save a lot of time)
          }
      }
    }
  }
}

void writeValue(int _channel, int _data) {
  if(_channel > 3) { // assign one of two dac chips to respond
    dacChip = 1;
  } 
  else {
    dacChip = 0;
  }

  /* bit shifting and masking to assemble proper list of bits */
  _channel = _channel << 14;
  updateBits = 3 << 12;
  _channel = _channel | updateBits; // OR to combine
  _data = _data << 2;
  spiWord = _channel | _data;
  binaryString = binary(spiWord, 16);

  outputData.add(byte(dacChip));
  outputData.add(byte(unbinary(binaryString.substring(0, 8))));
  outputData.add(byte(unbinary(binaryString.substring(8, 16))));
  currentTime = millis();
  if(outputData.size() >= 24 || currentTime - previousUpdate >= 10) {
    outputBytes = new byte[outputData.size()];
    for(int i = 0; i < outputData.size(); i++) {
      outputBytes[i] = outputData.get(i);
    }
    teensy.write(outputBytes);
   // println(outputBytes);
    dataIndex = 0;
    outputData = new ArrayList();
    previousUpdate = currentTime;
    }
}

class Slider {
  int x, y, value, center;
  int w = 265;
  int h = 12;

  Slider() {
  }

  Slider(int _x, int _y, int _value) {
    x = _x;
    y = _y;
    value = _value;
  }

  int getX() {
    return x;
  }

  int getY() {
    return y;
  }

  void setX(int _x) {
    x = _x;
  }

  void setY(int _y) {
    y = _y;
  }

  int getValue() {
    return value;
  }

  void setValue(int _value) {
    value = _value;
  }
  void update(int _value) {
    setValue(_value);
    drawLine();
    drawPuck();
  }

  void drawLine() {
    line(x, y, x + w, y);
  }
  void drawPuck() {
    center = (int)map(value, 0, 1023, 0, w);
    ellipse(x + center, y, 6, 6);
  }
}

void controlEvent(ControlEvent theEvent) {
  if(theEvent.isGroup()) {
    if(theEvent.group().name() == "serialPorts") { 
      teensy = new Serial(this, Serial.list()[(int)theEvent.group().value()], 115200); // open serial port, 115200 rate
      teensy.buffer(1); // seems like this should make transmission more robust, not probably necessary
      portName = ""+ Serial.list()[(int)theEvent.group().value()];
      serialConnected = true;
      return;
    }
    if(theEvent.group().name() == "midiPorts"){
      midi = new MidiBus(this, midi.availableInputs()[(int)theEvent.group().value()], 1);
      println("MIDI port: " + midi.availableInputs()[(int)theEvent.group().value()] + " connected.");   
      midi.clearOutputs();
      return;
    }
  }
  if(theEvent.controller().id() == 1) {
    newPort = (int)theEvent.controller().value();
    portNeedsUpdate = true;
  }
}

