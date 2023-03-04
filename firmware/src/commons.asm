;************************************************************************
;																		*
;    Filename:	commons.asm												*
;    Date:	June 10, 2010												*
;    File Version:	0.0.4												*
;																		*
;    Author: Daniele Costarella											*
;    Company:															*
;																		* 
;																		*
;************************************************************************

	list		p=16f877a
	#include	P16f877A.INC
	radix		dec
	ErrorLevel 	-302
	
; -------------------------------------------------------------------------
; File Register Assignment	
; -------------------------------------------------------------------------


			UDATA
delayCount	EQU			15
count		RES			1					; counter variable
index		EQU			242					; initial value for count variable
var			RES			1					; variable for temporary storage
resconv		RES			2					; resconv is the result of hexconv
temp		RES			1					; temporary storage variable

; multiplication 13x10 reserved bytes
risultato24	RES			3					; 24-bit result of multiplication
temp24		RES			3					; shifted "quanto"
contatore	RES			1					; counter variable for multiplication loop
mol			RES			2					; multiplier

			CODE

		global 	wait, delayLoop
		global	hex2ascii
		global	mul13x10

; -------------------------------------------------------------------------
; Delay Subroutines start here	
; -------------------------------------------------------------------------
; These subroutines implement a delay, which can be used for timing purposes.

wait                         					; wait for a specified duration
         call	delayLoop						; call delay function 15 times, worst case
         decfsz	delayCount, f					; decrement the delay counter
         goto	wait							; loop until delayCount is zero
         return

delayLoop										 ; wait for about 2ms
		nop
		banksel	count 
		movlw	index
		movwf	 count
		CALL 	delay
		return
 
delay
		nop
		goto	$+1
		goto	$+1
		decfsz	count, f
		goto	delay
		return

; ******************************************************************
; A/D Converter Subroutines
; ******************************************************************

; ******************************************************************
; hex to ascii subroutine
; ******************************************************************

; This subroutine converts a byte (2 hexadecimal digits) into the corresponding ASCII characters.
; It stores the characters in consecutive variables resconv and resconv+1 and returns the memory address
; of resconv in the accumulator.

; USAGE:
; call	hex2ascii
; movwf	FSR				; copy the address of the MSB into FSR
; movfw	INDF			; load the content into the working register
; call 	lcdWrite		; write the MSB of the hexadecimal number
; incf	FSR, f			; increment the FSR to point to the LSB
; movfw	INDF			; load the content into the working register
; call	lcdWrite		 ; write the LSB of the hexadecimal number
;
; ******************************************************************
 
hex2ascii
		banksel	var
		movwf	var
		swapf 	var, W				
		andlw	00001111B				; mask for the first hex digit
		addlw	H'30'
		banksel temp
		movwf	temp
		sublw	00111001B				; compare with 39h
		btfss	STATUS, 0				; check the carry flag --> result is greater than 9 
		call	add7					; is A, B, C, D, E, F --> goto conv
		movf	temp, W
		movwf	resconv
		;return							; it will print only the msd char
		movf 	var, W
		andlw 	00001111B				; mask for the second hex
		addlw 	H'30'
		movwf 	temp
		sublw	H'39'					; compare with 39h
		btfss	STATUS, 0
		call	add7					; is A, B, C, D, E, F --> goto conv
		movf	temp, W
		movwf	resconv+1
		movlw	resconv					; give to the main program the memory address of resconv var
		return
add7									; convert to binary values > (sum 7 to bin)
		movf 	temp, W
		addlw	00000111B				; sum 7 (the adj value is in W)
		movwf 	temp
		return


; -------------------------------------------------------------------------	;
;      						MULTIPLICATION 13x10							;
; -------------------------------------------------------------------------	;
; This subroutine multiplies the 16-bit value stored in 'mol' (mol:mol+1) 
; with 4883 (00010011 00010011) which is the resolution of the AD converter.
; 
; The subroutine 'mul13x10' returns the address of the result in 'risultato24'.
; The result is available using indirect addressing.
;
mul13x10
	banksel	ADRESL
	movf	ADRESL, W					; Store the value of ADRESL in W
	banksel	mol
	movwf	mol+1						; Store the contents of W in mol+1

	banksel	ADRESH
	movf	ADRESL, W
	banksel	mol
	movwf	mol
	
	banksel	risultato24
	; initialization
	clrf	risultato24					; Clear the most significant byte
	clrf	risultato24+1
	clrf	risultato24+2				; Clear the least significant byte

	movlw	00010011B
	movwf	temp24+2
	movwf	temp24+1
	clrf	temp24
	
	movlw	10
	movwf	contatore					; Set the loop counter to 10

loop
	rrf		mol							; Rotate right mol:mol+1 by 1 bit
	rrf		mol+1
	btfsc	STATUS, C					; Check if there was a carry during rotation
	call 	addizione					; Add temp24 to risultato24 if there was a carry

	bcf		STATUS, C					; Clear the carry flag
	rlf		temp24+2					; Rotate left temp24 by 1 bit
	rlf		temp24+1
	rlf		temp24						; Shift in the new bit
	decfsz	contatore					; Decrement the loop counter and continue looping if it is not zero
	goto 	loop
	
	movlw	risultato24					; Return the address of the most significant byte of the converted string in 'risultato24'
	return

addizione
	movfw	risultato24+2				; Load the least significant byte into WREG
	addwf	temp24+2, W					; Add the least significant byte of temp24 to WREG and set carry flag if needed
	movwf	risultato24+2				; Store the sum in the least significant byte of 'risultato24'

	movfw	risultato24+1				; Load the most significant byte into WREG
	btfsc	STATUS, C					; Check if there was a carry during the last addition
	addlw	1							; Add 1 to WREG if there was a carry
	addwf	temp24+1, W					; Add the middle byte of temp24 to WREG and set carry flag if needed
	movwf	risultato24+1				; Store the sum in the most significant byte of 'risultato24'

	movfw	risultato24					; Load the most significant byte into WREG
	btfsc	STATUS, C
	addlw	1
	addwf	temp24, W
	movwf	risultato24
	return

		END