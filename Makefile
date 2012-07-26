# MPLAB IDE generated this makefile for use with GNU make.
# Project: sam_demo.mcp
# Date: Sat Jun 12 23:05:08 2010

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

sam_demo.cof : commons.o main.o lcdctrl.o
	$(CC) "16F877A.lkr" "commons.o" "main.o" "lcdctrl.o" /z__MPLAB_BUILD=1 /o"sam_demo.cof" /M"sam_demo.map" /W

commons.o : commons.asm P16f877A.INC
	$(AS) /q /p16F877A "commons.asm" /l"commons.lst" /e"commons.err" /o"commons.o"

main.o : main.asm P16f877A.INC
	$(AS) /q /p16F877A "main.asm" /l"main.lst" /e"main.err" /o"main.o"

lcdctrl.o : lcdctrl.asm P16f877A.INC
	$(AS) /q /p16F877A "lcdctrl.asm" /l"lcdctrl.lst" /e"lcdctrl.err" /o"lcdctrl.o"

clean : 
	$(CC) "commons.o" "commons.err" "commons.lst" "main.o" "main.err" "main.lst" "lcdctrl.o" "lcdctrl.err" "lcdctrl.lst" "sam_demo.cof" "sam_demo.hex"

