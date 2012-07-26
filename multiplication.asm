;************************************************************************
;																		*
;    Filename:	template.asm											*
;    Date:	May 10, 2010													*
;    File Version:	0.3													*
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
	
;***** VARIABLE DEFINITIONS

			UDATA				; explicit address specified is not required

risultato24	RES		3
temp24		RES		3			; quanto shiftato
contatore	RES		1
mol			RES		2


			CODE

	global mul13x10


; moltiplica mol:mol+1 con 4883 (00010011 00010011) che è la risoluzione dell'AD Conv

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
	;clrf	mol			;test

	;final version
	;movfw	adresh		; allineato a destra
	;movwf	mol
	;movfw	adresl
	;movwf	mol+1	
	
	banksel	risultato24
	; inizializzazione
	clrf	risultato24			;msb
	clrf	risultato24+1
	clrf	risultato24+2		;lsb

	movlw	00010011B
	movwf	temp24+2
	;movlw	10011B
	movwf	temp24+1
	clrf	temp24
	
	movlw	10
	movwf	contatore

loop
	rrf		mol
	rrf		mol+1
	btfsc	STATUS, C
	call 	addizione		;risultato16 = risultato16_old + temp16

	bcf		STATUS, C
	rlf		temp24+2
	rlf		temp24+1
	rlf		temp24
	decfsz	contatore
	goto 	loop
	movlw	risultato24		; restituisce l'indirizzo dell'MSB della stringa convertita in Volt
	;goto $			; 'risultato16' contiene il valore convertito
	return

addizione
	movfw	risultato24+2		; lsb in wreg
	addwf	temp24+2, W			; carry?
	movwf	risultato24+2		; salviamo l'lsb

	movfw	risultato24+1		; msb in wreg
	btfsc	STATUS, C			; add C direttamente???
	addlw	1			
	addwf	temp24+1, W
	movwf	risultato24+1		; salviamo l'msb

	movfw	risultato24
	btfsc	STATUS, C
	addlw	1
	;incf	W, W
	addwf	temp24, W
	movwf	risultato24
	return



	
	END						; directive 'end of program'

