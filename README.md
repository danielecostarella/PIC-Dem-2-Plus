Microchip PICDEM 2 Plus Demonstration Board Clone
=================================================

This repository contains the firmware and hardware schematic for a Microchip PICDEM 2 Plus demonstration board clone. The PICDEM 2 Plus is a simple board that demonstrates the capabilities of the 18, 28 and 40-pin PIC16 and PIC18 devices.

Features
--------

The PICDEM 2 Plus demonstration board clone has the following hardware features:

* On-board, +5V regulator for direct input from 9V, 100 mA AC/DC wall adapter or 9V battery, or hooks for a +5V, 100 mA regulated DC supply
* RS-232 socket and associated hardware for direct connection to an RS-232 interface
* In-Circuit Debugger (ICD) connector
* 5 kΩ pot for devices with analog inputs
* Three pushbutton switches for external stimulus and Reset
* Green power-on indicator LED
* Four red LEDs connected to PORTB
* Jumper J6 to disconnect LEDs from PORTB
* 4 MHz, canned crystal oscillator
* Unpopulated holes provided for crystal connection
* 32.768 kHz crystal for Timer1 clock operation
* Jumper J7 to disconnect on-board RC oscillator (approximately 2 MHz)
* 32K x 8 Serial EEPROM
* LCD display
* Piezo buzzer
* Prototype area for user hardware
* Microchip TC74 thermal sensor

It can be used as a standalone demonstration board with a programmed part. Alternatively, it can be used with an in-circuit emulator (for example, MPLAB® Real ICETM) or with an in-circuit programmer/debugger (such as MPLAB® ICD 3 or PICkitTM 3).

In this clone, we used a PIC16F877A, a 28/40-Pin 8-Bit CMOS FLASH Microcontroller. The demo was about displaying a real-time clock, ambient temperature, and a voltmeter. We used the PICkit3 programmer.

Getting Started
---------------

To get started, you can clone this repository and use it as a reference for your own projects. If you want to recreate the board, you can follow the instructions in the hardware schematic. If you want to modify the firmware, you can use the provided code as a starting point.

Contributing
------------

Contributions are always welcome! If you find a bug or want to suggest an improvement, please open an issue or submit a pull request.

License
-------

This project is licensed under the MIT License.

Disclaimer
----------

This project is intended for educational purposes only. Use it at your own risk. The authors of this project are not responsible for any damages or injuries that may occur as a result of using this project.