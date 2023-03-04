; ------------------------------------------------------------------------	;
; TITLE: Demonstration of A/D converter and I2C use on a PicDem board		;
;																			;
; Author: 	Daniele Costarella												;
; Filename:		main.asm													;
; Revision:		1.0.4														;
; ------------------------------------------------------------------------	;

; This is the main program file for a demonstration of A/D converter and
; I2C usage on a PicDem board. The program is written in assembly language
; for the PIC16F877a microcontroller.

; ------------------------------------------------------------------------ ;
; Required system files:
; lcdctrl.asm
; commons.asm
; P16F877A.inc
; 16F877A.lkr
; ------------------------------------------------------------------------ ;

; ***************************************************************************
; * 																		*
; *	Part used = PIC16F877a on a PicDem clone								*
; * [for information about PicDem visit http://www.microchip.com]			*
; *																			*
; * Note: All timings are based on a reference crystal frequency of 4Mhz	*
; * which is equivalent to an instruction of 1us							*
; *																			*
; ***************************************************************************
 

		list            p=16f877a
		#include        P16f877A.INC
		radix           dec
		ErrorLevel      -302
     	__CONFIG   h'3D31'					; Configuration register value for Power On Reset

; ------------------------------------------------------------------------ ;
; Config register bits
; CP1 CP0 DBG NIL WRT CPD LVP BOR CP1 CP0   WDT OS1 OS0
;  1   1   1   1   0   1   0   0   1   1   0   0   0   1
; ------------------------------------------------------------------------ ;

; The configuration register is set to enable various options on the microcontroller.

		extern		delayLoop, wait
		extern		lcdInit, lcdWrite, waitBusyFlag, setXAddress
		extern		printString
		extern		return2home	; non usata
		extern		hex2ascii, lcdClear, lcdRxShift
		extern		mul13x10

         
;***** VARIABLE DEFINITIONS *****
 
SHARED				UDATA_SHR   
w_temp				RES			1		; Variable used for context saving 
stat_temp			RES			1		; Variable used for context saving
 
 
RAM0				UDATA				; Explicit address specified is not required
count				RES			1		; Temporary variable (example)
 
index				EQU			242		; Initialize count variable
delayCount			EQU			15
;BITTEST			EQU			H'01'
char				RES			1		; Char to print
point2Char			RES			1
temp3				RES			1		; Unused

binvalue			RES			3		; Binary value to convert to BCD
untten				RES			1
hdrthd				RES			1
tensOfThousands		RES			1 
milions				RES			1

temp				RES			3		; Used for multiplication
cmd_byte			RES 		1
mode				RES			1		; Selected mode (voltmeter or thermometer)
										; 00000001 => main menu
										; 00000010 => voltmeter
										; 00000100 => thermometer

; daa function
num1		RES	2						; First number to add 
num2		RES 2						; Second number to add
adjflag		RES	1						; Flag to adjust the result of the addition
sum			RES	2						; Result of the addition
number		RES 1						; Temporary variable used in the DAA function 
 
; Example of using Overlayed Uninitialized Data Section
G_DATA				UDATA_OVR			; Explicit address can be specified
flag				RES			2		; Temporary variable shared between different sections of the program (shared locations - G_DATA)
 
G_DATA				UDATA_OVR   
count1				RES			1		; Temporary variable shared between different sections of the program (shared locations - G_DATA)
var					RES			1
var2				RES			2
resconv				RES			2		; Result of a hexadecimal conversion
SW_STATUS			RES			1		; Status register of switch ******11 or 00 (pushed)

#DEFINE				EN			6

; sw1 and sw2 are the switches on the demo board
SW1					EQU			0		; RB0
SW2					EQU			4		; RA4

TC74ADD_R			EQU			10011011B		;TC74 address (read)
TC74ADD_W			EQU			10011010B		;TC74 address (write)
				


;**********************************************************************
STARTUP CODE									; processor reset vector
         movlw   high start						; load upper byte of 'start' label
         movwf   PCLATH							; initialize PCLATH
         goto    start							; go to beginning of program
 
 
INTVECT CODE					 				; interrupt vector location
		movwf   w_temp							; save off current W register contents
		movf    STATUS,w						; move status register into W register
		movwf   stat_temp						; save off contents of STATUS register 

		banksel	PIR1
		bcf		PIR1, TMR1IF

		banksel	count
		decfsz	count, f
		goto	skipShifts
		movlw	27-16
		banksel	count
		movwf	count
indietro
		call	lcdRxShift
		decfsz	count, f
		goto	indietro
		banksel	count
		movlw	53+16
		movwf	count
		
skipShifts
		call	lcdRxShift

		

		banksel	TMR1H
		movlw	0xDF
		movwf	TMR1H
		movlw	0xFF

		; ritorno dall'interrupt
		movf    stat_temp,w						; retrieve copy of STATUS register
		movwf   STATUS							; restore pre-isr STATUS register contents
		swapf   w_temp,f
		swapf   w_temp,w						; restore pre-isr W register contents
		retfie									; return from interrupt
												; put GIE bit up again
 


text1 DT "Hello PIC!", 0
text2 DT "Data received", 0
text6 DT "Select function >>> 1: Voltmeter *** 2: Thermometer", 0

textMenu1	DT 	"Select function"
textMenu2	DT	"1.


; -------------------------------------------------------------------------	;
;      *****************  MAIN CODE START LOCATION  *****************		;
; -------------------------------------------------------------------------	;
MAIN 	CODE
start
		; init TIMER1
		clrf	 T1CON 						; Stop Timer1, Internal Clock Source,
											; T1 oscillator disabled, prescaler = 1:1
		;banksel	TMR1H
		clrf	TMR1H
		clrf	TMR1L

		clrf	INTCON

		bsf 	STATUS, RP0 				; Bank1
		clrf 	PIE1 						; Disable peripheral interrupts
		bsf		PIE1, TMR1IE

		bcf 	STATUS, RP0 				; Bank0
		clrf 	PIR1 						; Clear peripheral interrupts Flags

		banksel T1CON
		movlw	00001010B					; Set Prescaler to 1
		movwf	T1CON

		bsf T1CON, TMR1ON 					; Timer1 starts to increment
	
; ------------------------------------------------------------------------- ;
;      Display A/D Converter and I2C init routine calls							;
; ------------------------------------------------------------------------- ;
		call 	lcdInit						; call Display Init SubRoutine
		call 	convInit					; A/D converter initialization
		call 	wait
		
		call	tc74Init					; tc74 AND I2C INIT
		call	i2cIdle
		call	tc74StandBy					; put TC74 in StandBy mode (I < 5uA)

		call	lcdClear
		call	wait
		
		bsf		STATUS, RP0
		movfw	TRISB
		iorlw	000000001B
		movwf	TRISB

		movfw	TRISA
		iorlw	00010000B
		movwf	TRISA
		bcf		STATUS, RP0					; return to Bank0


menu
		call	lcdClear
		movlw	0
		call	setXAddress
		movlw	text6
		call	printString
		movlw	53							; welcome string chars number (for scroll)
		banksel	count
		movwf	count
		
		clrf	PIR1						; clear Peripheral Interrupt Flag register (PIR1)

		banksel	INTCON
		movlw	11000000B					; GIE and PEIE up (turn interrupt on RP port off)
		movwf	INTCON

; ------------------------------------------------------------------------ ;
;      *****************   MAIN LOOP BEGINS HERE   *****************	   ;
; ------------------------------------------------------------------------ ;		
mainLoop
		nop
		banksel	mode
		clrf	mode

		banksel	mode
		btfss	PORTB, SW1
		bsf		mode, 1						; usage as voltmeter

		btfss	PORTA, SW2
		bsf		mode, 2						; usage as thermometer

		btfsc	mode, 1
		call	voltmeter

		btfsc	mode, 2
		call	thermometer

		goto	mainLoop
		


; -------------------------------------------------------------------------	;
;        ********************** THERMOMETER  **********************			;
; -------------------------------------------------------------------------	;

thermometer
		nop
		bcf		INTCON, PEIE				; all pheripheral interrupts disabled

		call	lcdClear

		bcf		mode, 2						; drop to zero thermometer bit mode

		movlw	5
		call	setXAddress
		movlw	11011111B
		call	lcdWrite

		movlw	'C'
		call	lcdWrite
		movlw	0
		call	setXAddress
		
		
		call 	i2cIdle
		bsf		SSPCON2, SEN				; start condition enable bit	
		btfsc	SSPCON2, SEN
		goto	$-1

		call 	i2cIdle				
		banksel	SSPBUF
		movlw	TC74ADD_W					; TC74 address (default) <6:0> (write)
		movwf	SSPBUF
		call	waitAck
		
		call 	i2cIdle	
		banksel	SSPBUF
		movlw	0x01						;TC74 r/w config command byte
		movwf	SSPBUF
		call	waitAck

		call 	i2cIdle			
		movlw	0x00						; Write 0x00 to DATA config register
		banksel	SSPBUF
		movwf	SSPBUF
		call	waitAck

		call	i2cIdle
		banksel	SSPCON2
		bsf		SSPCON2, PEN
		btfsc	SSPCON2, PEN
		goto	$-1
		
		;call	i2cIdle
		banksel	SSPCON2
		bsf		SSPCON2, SEN
		btfsc	SSPCON2, SEN
		goto	$-1
	
		; TEMP register addressing	
		movlw	TC74ADD_W
		banksel	SSPBUF
		movwf	SSPBUF
		call	waitAck
		
		call	i2cIdle
		banksel	SSPBUF
		movlw	0x00
		movwf	SSPBUF							; addressing TEMP
		call	waitAck

		
getTemp	
		call	i2cIdle
		banksel	SSPCON2	
		bsf		SSPCON2, RSEN
		btfsc	SSPCON2, RSEN
		goto	$-1
			
		movlw	TC74ADD_R						; TC74 address in read mode
		banksel	SSPBUF	
		movwf	SSPBUF
		call	waitAck
		
		call 	i2cIdle
		call	readByte
		banksel	SSPBUF
		movfw	SSPBUF	
		; at this point read value is in W
		

		; check Button Status
		banksel	mode
		btfss	PORTB, SW1
		bsf		mode, 1

		btfsc	mode, 1
		call	sw2voltmeter					; call voltmeter routine
	
		call	convert_temp


convert_temp
		banksel	binvalue
		clrf	binvalue
		clrf	binvalue+1
		movwf	binvalue+2

		; tests
		;movlw	10111111B
		;movlw	00000000B
		;movlw	01111111B
		;movlw	-11
		
		movlw	"-"
		btfss	binvalue+2, 7
		movlw	"+"
		call	lcdWrite

		btfsc	binvalue+2, 7						; is value negative?
		call	twoComplement						; 2's complement conversion

		call	bin2bcd
		
		movfw	hdrthd
		iorlw	0
		movlw	" "									; if value is zero
		btfsc	STATUS, Z
		goto	hundreds
		
		movfw	hdrthd
		andlw	00001111B
		addlw	48
hundreds
		call 	lcdWrite

		movfw	untten
		andlw	11110000B
		iorlw	0
		movlw	" "									; if value is zero
		btfsc	STATUS, Z
		goto	tensAndUnits

		movfw	untten
		swapf	untten, W
		andlw	00001111B
		addlw	48
tensAndUnits
		call 	lcdWrite

		movfw	untten
		andlw	00001111B
		addlw	48
		call 	lcdWrite
			movlw	0
		call	setXAddress
		goto	getTemp		

; The binary value is in 2�s complement format so it needs to be converted
; twoComplement writes the correct value in binvalue+2
twoComplement				
		;movlw	"-"
		;call	lcdWrite
		comf	binvalue+2, f
		incf	binvalue+2, f
		return


waitAck
		;call	i2cIdle
		nop
		banksel	SSPCON2
		btfsc	SSPCON2, ACKSTAT
		goto	$-1								; ACKSTAT will be cleared by hardware
		call	delayLoop
		return

readByte										; read by TEMP register
		nop
		banksel	SSPSTAT
		bcf		SSPSTAT, BF

		call	i2cIdle
		banksel	SSPCON2
		bsf		SSPCON2, RCEN					; enable receive mode

		btfsc	SSPCON2, RCEN
		goto $-1

		banksel	SSPSTAT
		btfss	SSPSTAT, BF
		goto	$-1

		;btfss	SSPSTAT, BF						; check if buffer full
		;goto	readByte
		;movfw	SSPBUF

		; send ack from master
		banksel SSPCON2
		bsf		SSPCON2, ACKDT					; preset the NACK bit
		bsf		SSPCON2, ACKEN					; Initiate Acknowledge sequence
		btfsc	SSPCON2,ACKEN
		goto	$-1

		return

tc74Init
		banksel	TRISC
		movfw	TRISC							; set RC3, 4 as input		
		iorlw	00011000B
		movwf	TRISC
		
		; SYNC SERIAL PORT CONTROL REGISTER config
		banksel	SSPCON
		movlw	00101000B
		movwf	SSPCON

		banksel	SSPSTAT
		;clrf	SSPSTAT
		bsf		SSPSTAT, SMP

		
		banksel	SSPADD
		movlw	00001001B						; setup 100Khz I2C clock
												; SSPADD = 9  Clock = fosc/(4(SSPADD+1))
												; set Clock freq to 100Khz
		movwf	SSPADD							; Baud Rate Divisor generator in Master Mode

		clrf	SSPCON2							; Clear control bits
		return

tc74StandBy										; put tc74 in standby mode	
		banksel	SSPCON2	
		bsf		SSPCON2, PEN
		btfsc	SSPCON2, PEN
		goto	$-1
		call 	i2cIdle
tcStandBy
		bsf		SSPCON2, SEN
		btfsc	SSPCON, SEN
		goto $-1
		call	i2cIdle
		banksel	SSPBUF
		movlw	TC74ADD_W						; TC74 address (default) <6:0> (write)
		movwf	SSPBUF
		call	waitAck
		call	i2cIdle	
		banksel	SSPBUF
		movlw	0x01							; TC74 r/w config command byte
		movwf	SSPBUF
		call	waitAck
		call 	i2cIdle			
		movlw	0x80							; conf reg string for standby mode
		banksel	SSPBUF
		movwf	SSPBUF
		call	waitAck	
		banksel	SSPCON2	
		bsf		SSPCON2, PEN
		btfsc	SSPCON2, PEN
		goto	$-1
		return

; IDLE module
i2cIdle
	banksel	SSPSTAT
	btfsc	SSPSTAT, R_W
	goto	$-1

	banksel	SSPCON2
	movf	SSPCON2, W
	andlw	0x1f
	btfss	STATUS, Z
	goto	$-3
	return

; -------------------------------------------------------------------------	;
;        **********************  VOLTMETER  **********************			;
; -------------------------------------------------------------------------	;


voltmeter
		nop
		banksel	INTCON
		bcf		INTCON, PEIE			; all pheripheral interrupts disabled
		call	lcdClear

voltmeterInit
		banksel	mode
		bcf		mode, 1					; drop to zero voltmeter bit mode

		movlw	6
		call	setXAddress
		movlw	'V'
		call	lcdWrite
		
		movlw	0						; set display address to zero
		call	setXAddress
		banksel ADCON0
		bsf		ADCON0, GO_DONE			; start the conversion
waitEOC									; wait end of conversion		
		btfss	ADCON0, GO_DONE
		goto	waitEOC
;		
		call	mul13x10
		movwf	FSR						; copy MSB address into FSR
		movfw	INDF					; load working with its content
		movwf	temp
	
		incf	FSR, f
		movfw	INDF
		movwf	temp+1
	
		incf	FSR, f
		movfw	INDF
		movwf	temp+2
		nop

		; copy temp to binvalue
		movfw	temp
		movwf	binvalue
		movfw	temp+1
		movwf	binvalue+1
		movfw	temp+2
		movwf	binvalue+2

		call	bin2bcd
; NUOVA FUNZIONE

		banksel num1

		clrf	sum
		clrf	sum+1

		; verifico se i 4 bit meno significati sono maggiori di 556 (BCD)
		movfw	untten
		movwf	num1+1

		movfw	hdrthd
		andlw	0x0F		; mask for lsn
		movwf	num1

		; carico il numero di test 444 (556+444= 1000 setterebbe a 1
		; il nibble pi� significatico

		movlw	0x04
		movwf	num2
		movlw	0x44
		movwf	num2+1

		; addiziono num1 a num2
		bcf		STATUS, C
		addwf	num1+1, W
		
		movwf	number
		call	daa
		
		; store ls bcd byte
		movwf	sum+1
		
		movfw	num2
		btfsc	STATUS, C
		addlw	1						; Add one for carry
		
		addwf	num1, W  				; in W c'� num1 + (num2 + C)
		
		movwf	number
		call	daa

		movwf	sum

		; controllo il l'ms nibble di sum. Se 1 significa che
		; il risultato della somma � maggiore o uguale a 1000;
		; allora mi preparo per incrementare le restanti cifre
		; pi� significative
	
		btfsc	sum, 4
		goto 	rounding

		; else, print as they like
		; (without rounding)
		movfw	milions
		andlw	00001111B
		addlw	48
		call	lcdWrite

		movlw	'.'
		call	lcdWrite

		movfw	tensOfThousands		
		swapf	tensOfThousands, W
		andlw	00001111B
		addlw	48
		call	lcdWrite

		movfw	tensOfThousands		
		andlw	00001111B
		addlw	48
		call	lcdWrite

		movfw	hdrthd
		swapf	hdrthd, W
		andlw	00001111B
		addlw	48
		call	lcdWrite
		
		
checkButton2
		; check if sw2 is pushed; if it occurs switch to thermometer
		banksel	mode
		btfss	PORTA, SW2
		bsf		mode, 2
	
		btfsc	mode, 2
		call	thermometer

		goto	voltmeterInit


; funzione di arrotondamento a 3 cifre dopo a virgola
rounding
		banksel num1
		clrf	sum
		clrf	sum+1

		bcf		STATUS, C
		rlf		hdrthd
		rlf		tensOfThousands
		rlf		milions

		rlf		hdrthd
		rlf		tensOfThousands
		rlf		milions

		rlf		hdrthd
		rlf		tensOfThousands
		rlf		milions

		rlf		hdrthd
		rlf		tensOfThousands
		rlf		milions

		; risultato temporaneo in tensOfThousand e milions
		
		movfw	tensOfThousands
		movwf	num1+1
		movfw	milions
		movwf	num1

		movlw	0x00
		movwf	num2
		movlw	0x01			; incrementa di uno
		movwf	num2+1

		bcf		STATUS, C
		addwf	num1+1, W		; (num1+1)+(num2+1) parti meno significative
		
		movwf	number
		call	daa

		; store ls bcd byte
		;movfw	number
		movwf	sum+1

		movfw	num1

		btfsc	STATUS, C
		addlw	1				; Add one for carry
		
		addwf	num2, W	
		
		movwf	number
		call	daa

		movwf	sum

		; print
		movfw	sum
		swapf	sum, W
		andlw	00001111B
		addlw	48
		call	lcdWrite

		movlw	'.'
		call	lcdWrite
		
		movfw	sum
		andlw	00001111B
		addlw	48
		call	lcdWrite
		
		movfw	sum+1
		swapf	sum+1, W
		andlw	00001111B
		addlw	48
		call	lcdWrite

		movfw	sum+1
		andlw	00001111B
		addlw	48
		call	lcdWrite
		
		goto	checkButton2





; *****************************************
; ******************************************
		
		


; A/D Converter Initialization
;
; Preset values:  
; clock rate 4Mhz/32, 
; Vref+=Vdd Vref-=GND, right justified, all analog inputs
convInit
	movlw 	10000001B		 					; 4Mhz/32, channel 0, go/!done=0, adon = 1
	banksel ADCON0
	movwf 	ADCON0
	movlw 	10000000B							; ADFM = 1 (right justified), all analog inputs, Vref+=Vdd Vref-=Vss
	banksel ADCON1
	movwf 	ADCON1
	banksel PIR1

	; for using with interrupts
	;bcf		PIR1, ADIF						; A/D converter interrupt flag bit to zero
	;bsf 	INTCON, GIE
	;bsf		INTCON, PEIE
	;banksel PIE1
	;bsf		PIE1, ADIE
	return
	


; -------------------------------------------------------------------------	;
; 					 Binary to BCD conversion subroutine					;
; -------------------------------------------------------------------------	;

bin2bcd
	clrf	untten
 	clrf	hdrthd
	clrf	tensOfThousands
	clrf	milions

	movlw	24					; N iterations where N is bits number
 	movwf	count

lshift
	call 	leftShift			; rotate both bytes to left
	decfsz	count, 1			; counter
	goto	adjNibbles			;
	return						; result is in 'untten' and 'hdrthd'



; sum 3 to all nibble, check ms bits. If msb is high update nibbles with result, 
; otherwise discard the result
adjNibbles
	; adjust byte containing unities and tens
	movfw	untten
	addlw	0x03
	movwf	temp							; bit test on WREG is not allowed
	btfsc	temp, 3
	movwf	untten
	
	movfw	untten							; restore
	addlw	0x30
	movwf	temp
	btfsc	temp, 7
	movwf	untten

	; adjust byte containing hundreds and thousands
	movfw	hdrthd
	addlw	0x03
	movwf	temp
	btfsc	temp, 3
	movwf	hdrthd
	
	movfw	hdrthd							; restore
	addlw	0x30
	movwf	temp
	btfsc	temp, 7
	movwf	hdrthd

	; adjust byte containing tens of thousands
	movfw	tensOfThousands
	addlw	0x03
	movwf	temp
	btfsc	temp, 3
	movwf	tensOfThousands
	
	; 
	movfw	tensOfThousands					; restore
	addlw	0x30
	movwf	temp
	btfsc	temp, 7
	movwf	tensOfThousands

	;
	movfw	milions
	addlw	0x03
	movwf	temp
	btfsc	temp, 3
	movwf	milions
	
	movfw	milions							; restore
	addlw	0x30
	movwf	temp
	btfsc	temp, 7
	movwf	milions
	

	; both bytes is ok, let's continue with the next shift
	goto 	lshift	

leftShift
	bcf		STATUS, C						; 'cause rotation is through the carry bit
	rlf		binvalue+2, 1
	rlf		binvalue+1, 1
	rlf		binvalue, 1						; most significant bit is now the carry bit
	rlf		untten, 1	
	rlf		hdrthd, 1
	rlf		tensOfThousands, 1
	rlf		milions, 1
	return



sw2voltmeter 								; switch to Voltmeter putting the TC74 in standby mode
		call	tc74StandBy
		call	voltmeter



; -------------------------------------------------------------------------	;
; Decimal adjust accumulator. Use after a bcd addition						;
; -------------------------------------------------------------------------	;

daa		; decimal adjust accumulator (after addition)
		BCF 	adjflag, 0
		BTFSC 	STATUS, C
		BSF 	adjflag, 0
		MOVLW 	06h
		BTFSC 	STATUS, DC
		ADDWF 	number, f
		ADDWF	number, f
		BTFSS 	STATUS, DC
		SUBWF 	number, F
		MOVLW 	60h
		ADDWF 	number, F
		BTFSS 	STATUS, C
		BTFSC 	adjflag, 0
		goto	setCarry
		subwf	number, F
		bcf		STATUS, C
		
		movfw	number
		return

setCarry
		bsf		STATUS, C
		movfw	number
		return

		END									; directive 'end of program'
