
#include "spi.h"
//#include <avr/io.h>
/*  
 SPI_Interface_6232010 
 created 6.23.2010 by Greg Surges
 to allow for interfacing between usb/Serial data and 10-bit DAC (MAX5250 currently)
 using Teensy 2.0
 */

#define SELECT_DAC_ONE digitalWrite(2, LOW);
#define DESELECT_DAC_ONE digitalWrite(2, HIGH);
#define SELECT_DAC_TWO digitalWrite(3, LOW);
#define DESELECT_DAC_TWO digitalWrite(3, HIGH);

/*
pin 13	SCK	SPI clock	
pin 12	MISO	SPI master in, slave out
pin 11	MOSI	SPI master out, slave in
pin 10	SS	SPI slave select
*/

byte clr;
byte byteOne, byteTwo;
byte firstByte, secondByte, thirdByte;
boolean data;

void setup(){
  //CPU_PRESCALE(CPU_4MHz);
  pinMode(2, OUTPUT);
  pinMode(3, OUTPUT);
  Serial.begin(115200);
  DESELECT_DAC_ONE;
  DESELECT_DAC_TWO;
  setup_spi(SPI_MODE_0, SPI_MSB, SPI_NO_INTERRUPT, SPI_MSTR_CLK2);
}

void loop(){
  pollAndWrite();
}


void pollAndWrite(){
 data = false;
 while(!data){
  if(Serial.available() > 1) { // look into the receive buffering - not receiving from Max properly
    firstByte = Serial.read();
    delayMicroseconds(100);
    if(firstByte == B00000000) {
      secondByte = Serial.read();
      delayMicroseconds(100);
      thirdByte = Serial.read();
      SELECT_DAC_ONE;
      send_spi(secondByte);
      send_spi(thirdByte);
      delayMicroseconds(10);
      DESELECT_DAC_ONE;
      data = true;
    } 
      if(firstByte == B00000001){
        secondByte = Serial.read();
        delayMicroseconds(100);
        thirdByte = Serial.read();     
        SELECT_DAC_TWO;
        send_spi(secondByte);
        send_spi(thirdByte);
        delayMicroseconds(10);
        DESELECT_DAC_TWO;
        data = true;
    }
  }
 }
}
