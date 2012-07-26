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
count		RES			1
index		EQU			242			; init count var
var			RES			1
resconv		RES			2			; resconv è il risultato di hexconv
temp		RES			1

;; multiplication 13x10 reserved bytes
risultato24	RES			3
temp24		RES			3			; shifted "quanto"
contatore	RES			1
mol			RES			2

			CODE

		global 	wait, delayLoop
		global	hex2ascii
		global	mul13x10

; -------------------------------------------------------------------------
; Delay Subroutines start here	
; -------------------------------------------------------------------------


wait                         					; routine da adattare
         call	delayLoop						; to call 15 times, worst case
         decfsz	delayCount, f
         goto	wait
         return

 
delayLoop										; about 2ms delay
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


;
; Others
;


; ******************************************************************
; hex to ascii subroutine
; ******************************************************************


; converte un byte (2 esadecimali) nei corrispondenti caratteri ascii
; li memorizza nelle variabili consecutive resconv e resconv+1
; restituisce l'indirizzo di resconv nell'accomulatore

; USAGE:
; call	hex2ascii
; movwf	FSR				; copia l'indirizzo dell'MSB nel FSR
; movfw	INDF			; carico il contenuto nel working
; call 	lcdWrite		; write msb of hex number
; incf	FSR, f
; movfw	INDF
; call	lcdWrite		; write lsb of hex number
;
; ******************************************************************
 
hex2ascii
		banksel	var
		movwf	var
		swapf 	var, W				
		andlw	00001111B				; mask for the first hex
		addlw	H'30'
		banksel temp
		movwf	temp
		;movwf   var					; var contiene il carattere da stampare
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
; moltiplica mol:mol+1 con 4883 (00010011 00010011) che è la risoluzione dell'AD Conv
;
; 'mul13x10' restituisce l'indirizzo di risultato24
; Il risultato è disponibile con indirizzamento indiretto
mul13x10
	banksel	ADRESL
	movf	ADRESL, W
	;movlw	0xff
	;movlw	10101110B	;test ADRESL
	banksel	mol
	movwf	mol+1		;test
	banksel	ADRESH
	movf	ADRESL, W
	;movlw	00000011B	;test ADRESH
	;movlw	0x03
	banksel	mol
	movwf	mol
	
	banksel	risultato24
	; initialization
	clrf	risultato24			;msb
	clrf	risultato24+1
	clrf	risultato24+2		;lsb

	movlw	00010011B
	movwf	temp24+2
	;movlw	10011B				; it's the same :)
	movwf	temp24+1
	clrf	temp24
	
	movlw	10
	movwf	contatore

loop
	rrf		mol
	rrf		mol+1
	btfsc	STATUS, C
	call 	addizione			;risultato24 = risultato24_old + temp24

	bcf		STATUS, C
	rlf		temp24+2
	rlf		temp24+1
	rlf		temp24
	decfsz	contatore
	goto 	loop
	movlw	risultato24			; restituisce l'indirizzo dell'MSB della stringa convertita in Volt
	;goto $						; 'risultato24' contiene il valore convertito
	return

addizione
	movfw	risultato24+2		; lsb in wreg
	addwf	temp24+2, W			; carry?
	movwf	risultato24+2		; salviamo l'lsb

	movfw	risultato24+1		; msb in wreg
	btfsc	STATUS, C			
	addlw	1			
	addwf	temp24+1, W
	movwf	risultato24+1		; saving the msb

	movfw	risultato24
	btfsc	STATUS, C
	addlw	1
	;incf	W, W
	addwf	temp24, W
	movwf	risultato24
	return

		END