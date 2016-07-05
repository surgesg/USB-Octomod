// added to svn
#include "spi.h"
#include <avr/io.h>
/*  
 SPI_Interface_6232010 
 created 6.23.2010 by Greg Surges
 to allow for interfacing between usb/Serial data and 10-bit DAC (MAX5250 currently)
 using Teensy 2.0
 */

#define SELECT_DAC_ONE digitalWrite(PORTB0, LOW);
#define DESELECT_DAC_ONE digitalWrite(PORTB0, HIGH);
#define SELECT_DAC_TWO digitalWrite(PIN_D0, LOW);
#define DESELECT_DAC_TWO digitalWrite(PIN_D0, HIGH);

#define CPU_PRESCALE(n) (CLKPR = 0x80, CLKPR = (n))
#define CPU_16MHz       0x00
#define CPU_8MHz        0x01
#define CPU_4MHz        0x02
#define CPU_2MHz        0x03
#define CPU_1MHz        0x04
#define CPU_500kHz      0x05
#define CPU_250kHz      0x06
#define CPU_125kHz      0x07
#define CPU_62kHz       0x08


byte clr;
byte byteOne, byteTwo;
byte firstByte, secondByte, thirdByte;
boolean data;

void setup(){
  CPU_PRESCALE(CPU_4MHz);
  pinMode(PORTB0, OUTPUT);
  pinMode(PIN_D0, OUTPUT);
  Serial.begin(9600);
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
  if(Serial.available()) { // look into the receive buffering - not receiving from Max properly
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

