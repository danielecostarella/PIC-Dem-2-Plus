;************************************************************************
;																		*
;    Filename:	lcdctlr.asm												*
;    Date:	June 10, 2010												*
;    File Version:	1.0.1												*
;																		*
;    Author: Daniele Costarella											*
;    																	*
;************************************************************************

	list		p=16f877a
	#include	P16f877A.INC
	radix		dec
	ErrorLevel 	-302

; -------------------------------------------------------------------------
; File Register Assignment	
; -------------------------------------------------------------------------

			UDATA
char		RES			1
point2Char	RES			1
temp		RES			1



#define		EN			6			; PORTD enable pin for Hitachi

			CODE

			global 	lcdInit, lcdWrite, waitBusyFlag, setXAddress, printString
			global	return2home, lcdClear, lcdRxShift
			extern delayLoop, wait	


; -------------------------------------------------------------------------	;
;      *****************  LCD Control for HITACHI  *****************		;
; -------------------------------------------------------------------------	;


; ******************************************************************
; LCD Initialization for Hitachi SubRoutine
; ******************************************************************
lcdInit
		banksel TRISD
		clrf 	TRISD							; Sets all bits as output
		banksel PORTD
		bsf 	PORTD, 7						; Power supply to lcd
		call 	wait
		MOVLW 	10000011B						; Function set
		MOVWF 	PORTD
		call 	clockCycle
		call 	delayLoop
		call 	delayLoop
		call 	delayLoop   
		call 	clockCycle 
		call 	delayLoop
		call 	clockCycle
		call 	delayLoop
         
		; Start function set
		MOVLW	10000010B						; Most significant part for 4 bit
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop

		MOVLW	10000010B						; Most significant part 2nd time
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop
		MOVLW	10000100B						; LSB with N=0 (1 line) F =1 (font 1)
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop

		; Display off
		;MOVLW	10000000B
		;MOVWF	PORTD
		;call	clockCycle
		;call	delayLoop
		;MOVLW	10001000B
		;;MOVLW	10001110B
		;MOVWF	PORTD
		;call	clockCycle
		;call	delayLoop
 
		; Display Clear
		MOVLW	10000000B
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop
		MOVLW	10000001B
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop
 
		; Entry mode set
		MOVLW	10000000B
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop
		MOVLW	10000110B
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop
         
		; Display On
		MOVLW	10000000B
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop
		MOVLW	10001100B						; Turns off the cursor (10001110 for cursor on)
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop
		return

lcdClear
		;call	waitBusyFlag
		call	delayLoop
		MOVLW	10000000B
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop
		MOVLW	10000001B
		MOVWF	PORTD
		call	clockCycle
		call 	delayLoop
		return

lcdRxShift
		call	delayLoop
		MOVLW	10000001B
		MOVWF	PORTD
		call	clockCycle
		call	delayLoop
		MOVLW	10001000B
		MOVWF	PORTD
		call	clockCycle
		call 	delayLoop
		return


; ******************************************************************
; Check if the display is ready
; ******************************************************************
waitBusyFlag
        BANKSEL	TRISD
		MOVLW 	00001111B						; Mask for TRISD
		MOVWF 	TRISD
		BANKSEL	PORTD
		BCF 	PORTD, 4						; Sets RS low (command mode)
		BSF		PORTD, 5						; Write mode
		
waitBF

		bsf 	PORTD, EN						; Set enable high
		BTFSS 	PORTD, 3						; Busy flag bit: 1 = busy
		goto 	exit
		bcf 	PORTD, EN						; Set enable low
		call 	clockCycle						; LS nibble reading (dummy)
		goto 	waitBF
exit
		bcf 	PORTD, EN
		call 	clockCycle						; LS nibble reading (dummy)
		BANKSEL	TRISD
		CLRF 	TRISD
		BANKSEL PORTD
		return

return2home										; DEPRECATED. Use setXAddress instead of this
		; return to home
		call	waitBusyFlag
		call 	delayLoop
		call 	delayLoop
		MOVLW 	10000000B
		MOVWF	PORTD
		call	clockCycle
		MOVLW	10000010B
		MOVWF	PORTD
		call	clockCycle
		call 	delayLoop
		call 	delayLoop
		;call	wait
		return


; Set cursor position on the lcd
setXAddress
		banksel	temp
		movwf	temp							; Store dd address
		call	delayLoop
		;call 	waitBusyFlag
		swapf	temp, W
		andlw	0x0F
		iorlw	0x88							; Set power supply on and DB7 high
		;movlw 	10001000B
		banksel	PORTD
		movwf	PORTD
		call 	clockCycle
		banksel	temp
		movfw	temp
		andlw	0x0F
		iorlw	0x80
		;movlw	10000011B
		banksel	PORTD
		movwf	PORTD
		call 	clockCycle
		return


; Example of use of lcdWrite
; movlw 'D'
; call lcdWrite
lcdWrite 
		MOVWF 	char
		call 	waitBusyFlag
		;call	delayLoop
		SWAPF 	char, W
		ANDLW 	00001111B
		IORLW 	10010000B
        MOVWF 	PORTD
		call 	clockCycle
		;call 	delayLoop
		call 	waitBusyFlag
		MOVF 	char, W
        ANDLW 	00001111B
        IORLW 	10010000B
		MOVWF 	PORTD
		CALL 	clockCycle
		;call 	delayLoop
		call 	waitBusyFlag
		return

printString
		movwf 	point2Char
		call 	nextChar
		IORLW 	0
		BTFSC 	STATUS, Z
		return
		call 	lcdWrite
		incf 	point2Char, f
		goto 	printString + 1
		
nextChar
		movfw	point2Char
		movwf 	PCL
		call 	delayLoop
		return

lcdDemo1
		call	lcdClear
		
		movlw 	'H'
		call 	lcdWrite

		movlw 	'e'
		call 	lcdWrite

		movlw 	'l'
		call 	lcdWrite

		movlw 	'l'
		call 	lcdWrite

		movlw 	'o'
		call 	lcdWrite

		movlw 	' '
		call 	lcdWrite

		movlw 	'P'
		call 	lcdWrite

		movlw 	'I'
		call 	lcdWrite

		movlw 	'C'
		call 	lcdWrite
 		 
		movlw 	' '
		call 	lcdWrite
 		 
		movlw 	' '
		call 	lcdWrite
 		 
		movlw 	' '
		call 	lcdWrite
 		 
		movlw 	' '
		call 	lcdWrite
 		 
		movlw 	' '
		call 	lcdWrite
 		 
		movlw 	' '
		call 	lcdWrite
 		 
		movlw 	' '
		call 	lcdWrite
 		 
		movlw 	'!'
		call lcdWrite		


clockCycle
		bsf PORTD, EN
		nop
		bcf PORTD, EN
		return		


		END