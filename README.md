## Summary ##

Microchip PICDEM 2 Plus demonstration board clone. The PICDEM 2 Plus is a simple board that demonstrates the capabilities of the 18, 28 and 40-pin PIC16 and PIC18 devices.

## Features ##

The PICDEM 2 Plus demonstration board clone has the following hardware features:
- On-board, +5V regulator for direct input from 9V, 100 mA AC/DC wall adapter or
9V battery, or hooks for a +5V, 100 mA regulated DC supply
- RS-232 socket and associated hardware for direct connection to an RS-232
interface
- In-Circuit Debugger (ICD) connector
-  5 kΩ pot for devices with analog inputs
- Three pushbutton switches for external stimulus and Reset
- Green power-on indicator LED
- Four red LEDs connected to PORTB
- Jumper J6 to disconnect LEDs from PORTB
- 4 MHz, canned crystal oscillator
- Unpopulated holes provided for crystal connection
- 32.768 kHz crystal for Timer1 clock operation
- Jumper J7 to disconnect on-board RC oscillator (approximately 2 MHz)
- 32K x 8 Serial EEPROM
- LCD display
- Piezo buzzer
- Prototype area for user hardware
- Microchip TC74 thermal sensor
<br>
<br>
It can be used as a standalone demonstration board with a programmed part. Alternatively, it can be used with an in-circuit emulator (for example, MPLAB® Real ICETM) or with an in-circuit programmer/debugger (such as MPLAB® ICD 3 or PICkitTM 3).

In this clone I used a PIC16F877A , a 28/40-Pin 8-Bit CMOS FLASH Microcontroller.

The demo was about displaying a real time clock, ambient temperature and a voltmeter. I used the PICkit3 programmer.
