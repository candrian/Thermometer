; Avr based digital thermometer, 2009
; (c) Andrianakis Charalampos
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
; THE SOFTWARE.
 
.NOLIST					;Don't list the following in the list file 
.INCLUDE "m8def.inc"	;Import of the file 
.LIST 					;Switch list on again 
	
.equ   RS=2 
.equ   RW=1 
.equ   E=0 

.def	temp1	=r16 
.def	temp2	=r17 
.def	temp3	=r18 
.def	temp4	=r19 
.def	temp5	=r20
.def	drem8u	=r21		;remainder 
.def	dres8u	=r22		;result 
.def	dd8u	=r23		;dividend 
.def	dv8u	=r24		;divisor 
.def	dcnt8u	=r25		;loop counter 

.cseg 
.org   0 

rjmp   RESET 

.org   INT0addr    
RETI 
.org   INT1addr 
RETI 

rjmp   RESET 
rjmp   RESET 

.org   ADCCaddr    
rjmp   ADC_INT    			  ;ADC Interupt 

  	msg1:   .db   "Thermometer V1.0" 
  	msg2:   .db   " Copyright 2010 " 
   	msg3:   .db   " By Andrianakis " 
   	msg4:   .db   "     Haris      " 
   	msg5:   .db   "Inside :      C" 
   	msg6:   .db   "Outside:      C" 


RESET: 

   	ldi   temp1, low(RAMEND)	;Init Stack Pointer 
   	out   spl,temp1 

   	ldi   temp1,   high(RAMEND) 
	out   sph,temp1 
       
   	ldi temp1,0xFF				;Configure PORTD as output 
	out DDRD, temp1 
								;Configure PORTB 
   	ldi   temp1, (1<<PB2)   | (1<<PB1)   | (1<<PB0) 
	out   DDRB, temp1         	;PB2,PB1,PB0 as output 


 	ldi   temp1, (1<<PC2) | (1<<PC3)      	;Set Output Pin for switching LCD Backlight 
   	out   DDRC, temp1 

	sbi   PORTC,PC2				;Turn On LCD Backlight     
	sbi		PORTC,PC3			;Turn On LCD
	rcall   init_LCD      		;Initialize LCD 
;	rcall   init_ADC    		;Initialize ADC    
;	rcall	init_Sleep			;Initialize Sleep

	rcall	Welcome_msg

	main:               		;Main program 
		rcall   init_ADC    			;Initialize ADC    
		rcall	ADC_Channel0
		rcall	ADC_Start
		rcall	delay
		rcall	ADC_Channel1
		rcall	ADC_Start
		rcall	delay
;		rcall	Disable_ADC
;		rcall	Huge_Delay
;		rcall	Huge_Delay
;		rcall	Huge_Delay
;		rcall	Huge_Delay
;		rcall	Huge_Delay
;		rcall	Huge_Delay
;
;		cbi   	PORTC,PC2				;Turn Off LCD Backlight 
;		cbi		PORTC,PC3				;Turn Off LCD
 ; 
;		cbi	DDRD, PD2					;Turn PD2 Output
;		sbi	PORTD, PD2					;Turn on Pull up Resistor
;
;		rcall	init_Sleep				;Initialize Sleep
;
;		sleep
;
;		rcall	Clear_Sleep
;
;		sbi DDRD, PD2
;		cbi	PORTD, PD2
;
;		sbi   	PORTC,PC2				;Turn On LCD Backlight     
	rjmp   main 

		;*********************************************** 
		;*************** Initialize Sleep ************** 
		;*********************************************** 

	init_Sleep:

		ldi	temp1,(1<<SE) | (1<<SM1)
		out	MCUCR,temp1

		ldi	temp1,(1<<INT0)
		out	GICR,temp1

	ret

		;*********************************************** 
		;***************** Clear Sleep ***************** 
		;*********************************************** 

	Clear_Sleep:

		ldi	temp1,0
		out	MCUCR,temp1
		out	GICR,temp1

	ret
		;*********************************************** 
		;****************  Disable ADC  **************** 
		;*********************************************** 

	Disable_ADC:

		ldi	temp1,0
		out	ADCSRA,temp1
		out ADMUX,temp1

	ret

		;*********************************************** 
		;**************** Initialize ADC *************** 
		;*********************************************** 

	init_ADC:
		
		push	temp1		;Backup Temp1

		;Enable ADC, Enable ADC interrupt, Prescaler 64
		ldi	temp1, (1<<ADEN) | (1<<ADIE) | (1<<ADPS2) | (1<<ADPS1)
		out	ADCSRA, temp1

		pop		temp1		;Restore Temp1

	ret
		;*********************************************** 
		;************ Change Channel ADC0 ************** 
		;*********************************************** 

	ADC_Channel0:

		ldi	temp1, (1<<REFS0)				;Vref = VCC, ADC0 pin 
		out	ADMUX,temp1			
		
		ldi	temp1,0xC9						;Select "Pixel" to Write
		rcall	LCD_SendCommand
			
	ret

		;*********************************************** 
		;************ Change Channel ADC1 ************** 
		;*********************************************** 

	ADC_Channel1:

		ldi	temp1, (1<<REFS0) | (1<<MUX0)   ;Vref = VCC, ADC1 pin
		out	ADMUX,temp1		
		
		ldi	temp1,0x89						;Select "Pixel" to Write
		rcall	LCD_SendCommand

	ret

		;*********************************************** 
		;****************** Start ADC ****************** 
		;*********************************************** 

	ADC_Start:

		push	temp1			;Backup Temp1

		in      temp1, ADCSRA 
		ori     temp1,(1<<ADSC)	;Start A2D Conversion 
		out     ADCSRA,temp1		
		sei

		pop		temp1			;Restore Temp1

	ret

		;*********************************************** 
		;**************** Initialize ADC *************** 
		;*********************************************** 

	ADC_Int:
		
		in		temp1,ADCL				;Read ADCL
		in		temp4,ADCH				;Read ADCH to clear ADC

		mov	dd8u,temp1
		ldi	dv8u,2
		rcall	div8u

		mov	temp1,dres8u
		dec	temp1

		rcall	Print_ADC

		mov	temp1,drem8u
		rcall	Print_ADC_Decimal


	reti

		;***********************************************
		;**************** Initialize LCD ***************
		;***********************************************
		;Initialization by Instruction

	init_LCD:

		push	temp1			;Backup Temp1
		
		rcall	delay			;Delay	15ms

		ldi	temp1,0b00110000
		rcall	LCD_SendCommand_Init
		rcall	delay			;Delay	4.1ms

		ldi	temp1,0b00110000
		rcall	LCD_SendCommand_Init
		rcall	delay			;Delay	100ms

		ldi	temp1,0b00110000
		rcall	LCD_SendCommand_Init
		rcall	delay			;Delay	100ms

		ldi	temp1,0b00111000	;8-bit, 2-lines, 5x8 dots
		rcall	LCD_SendCommand

		ldi	temp1,0b00001000	;Now is NOT the time to set the display up the way we want it
		rcall	LCD_SendCommand

		rcall	LCD_Clear		;Clear & Return home

		ldi	temp1,0b00000110	;Cursor increament, No display shift 
		rcall	LCD_SendCommand

		ldi	temp1,0b00001100	;Display on, don't show Cursor, don't blink
		rcall	LCD_SendCommand

		pop	temp1			;Restore Temp1	
	ret

		;***********************************************
		;****** Convert ADC To Decimal and Print *******
		;***********************************************
		
	Print_ADC:
										;Input Temp1
		rcall	Binary_to_Decimal		;Returns Temp2,Temp3,Temp4

;		mov		temp1,temp2
;		rcall	Conv_Dec_to_ASCII
;		rcall	LCD_SendChar

		mov		temp1,temp3
		rcall	Conv_Dec_to_ASCII
		rcall	LCD_SendChar

		mov		temp1,temp4
		rcall	Conv_Dec_to_ASCII
		rcall	LCD_SendChar

	ret

		;***********************************************
		;*********** Print ADC Decimal Digits **********
		;***********************************************
		
	Print_ADC_Decimal:
										;Input Temp1
		rcall	Binary_to_Decimal		;Returns Temp2,Temp3,Temp4

;		mov		temp1,temp2
;		rcall	Conv_Dec_to_ASCII
;		rcall	LCD_SendChar

		ldi		temp1,'.'
		rcall	LCD_SendChar

		mov		temp1,temp4
		rcall	Conv_Dec_to_ASCII
		rcall	LCD_SendChar

	ret



		;***********************************************
		;******* Commands for Initialize to LCD ********
		;***********************************************

	LCD_SendCommand_Init:

		cbi	PORTB,RS	;Turn in command mode

		out	PORTD,temp1	;Send Command

		rcall	LCD_Pulse

	ret

		;***********************************************
		;*************** Commands to LCD ***************
		;***********************************************

	LCD_SendCommand:

		cbi	PORTB,RS	;Turn in command mode

		out	PORTD,temp1	;Send Command

		rcall	LCD_Pulse

		rcall	LCD_Wait
	ret

		;***********************************************
		;************** SendChar to LCD ****************
		;***********************************************

	LCD_SendChar:
		
		sbi	PORTB,RS	;Turn in data mode

		out PORTD,temp1	;Send char 

		rcall	LCD_Pulse

		rcall	LCD_Wait

	ret

		;***********************************************
		;************* SendString to LCD ***************
		;***********************************************

	LCD_SendString: 
	  
		push   r0			;Backup Program Counter
		push   Temp1

	    LCD_PMRead: 

			lpm 			;Load Program Memory
	    	mov   Temp1, r0	 
	    	rcall   LCD_SendChar 
	    	adiw   r30, 1 
	    	dec   Temp2 

	    brne   LCD_PMRead 

	    pop   Temp1 		;Restore Backup
	    pop   r0 

 	ret 

		;***********************************************
		;****************** LCD Pulse ******************
		;***********************************************

	LCD_Pulse:

		sbi	PORTB,E		;Set E
		nop
		nop
		cbi	PORTB,E		;Clear E

	ret

		;***********************************************
		;*************** LCD New Line ******************
		;***********************************************

	LCD_NewLine:
		
		push	temp1				;BackUp Temp1

		ldi		temp1,0xC0			;New Line
		rcall	LCD_SendCommand

		pop		temp1				;Restore BackUp

	ret

		;***********************************************
		;***************** Wait for LCD ****************
		;***********************************************

	LCD_Wait:
		
		push	temp2			;Backup	Temp1 & Temp2

		LCD_Wait_Start:

			rcall	LCD_Read
			sbrc temp2,7		;Check Busy Flag
	
		rjmp LCD_Wait_Start

		pop		temp2			;Restore Backup

	ret

		;***********************************************
		;****************** Clear LCD ******************
		;***********************************************

	LCD_Clear:

		push	temp1	;Backup	Temp1

		ldi		temp1,0x01
		rcall	LCD_SendCommand

		pop		temp1	;Restore	Backup
		
	ret

		;***********************************************
		;******************  LCD Read  *****************
		;***********************************************

	LCD_Read:

		push	temp1	;Backup	temp1

		sbi	PORTB,RW	;Turn in read mode
		cbi	PORTB,RS	;Turn in command mode

		ldi	temp1,0x00	;Turn PortD input
		out	DDRD,temp1	
		
		sbi	PORTB,E 	;Take E high	
		nop
		nop
		in	temp2,PIND	;Get address and busy flag

		cbi	PORTB,E		;Take E low

		ldi	temp1,0xFF	;Turn PortD output
		out	DDRD,temp1
		
		cbi	PORTB,RW	;Turn in write mode

		pop		temp1	;Restore backup

	ret
	

        ;***********************************************
        ;*************** Welcome Messege ***************
        ;***********************************************

	Welcome_MSG:
		push	temp2				;Backup Temp2

		;Print	String to LCD
		ldi     r30, low(msg1*2) 	;Load msg offset
		ldi     r31, high(msg1*2) 
		ldi     temp2,16 			;Load char number
		rcall   LCD_SendString
		rcall	LCD_NewLine

		ldi     r30, low(msg2*2) 	;Load msg offset
		ldi     r31, high(msg2*2) 
		ldi     temp2,16 			;Load char number
		rcall   LCD_SendString

		rcall	Message_Delay
		rcall	LCD_Clear

		ldi     r30, low(msg3*2) 	;Load msg offset
		ldi     r31, high(msg3*2) 
		ldi     temp2,16 			;Load char number
		rcall   LCD_SendString
		rcall	LCD_NewLine

		ldi     r30, low(msg4*2) 	;Load msg offset
		ldi     r31, high(msg4*2) 
		ldi     temp2,16 			;Load char number
		rcall   LCD_SendString

		rcall	Message_Delay
		rcall	LCD_Clear

		ldi     r30, low(msg5*2) 	;Load msg offset
		ldi     r31, high(msg5*2) 
		ldi     temp2,15 			;Load char number
		rcall   LCD_SendString

		rcall	LCD_NewLine

		ldi     r30, low(msg6*2) 	;Load msg offset
		ldi     r31, high(msg6*2) 
		ldi     temp2,15 			;Load char number
		rcall   LCD_SendString

		ldi		temp1,0x8D
		rcall	LCD_SendCommand

		ldi		temp1,0xDF
		rcall	LCD_SendChar

		ldi		temp1,0xCD
		rcall	LCD_SendCommand

		ldi		temp1,0xDF
		rcall	LCD_SendChar

		pop		temp2				;Restore Temp2

	ret

		;***********************************************
		;****************** Delay Loop *****************
		;***********************************************

	delay:

		; ============================= 
		;    delay loop generator 
		;     400000 cycles:
		; ----------------------------- 
		; delaying 399999 cycles:
		          ldi  R20, $97
		WGLOOP0:  ldi  R21, $06
		WGLOOP1:  ldi  R22, $92
		WGLOOP2:  dec  R22
		          brne WGLOOP2
		          dec  R21
		          brne WGLOOP1
		          dec  R20
		          brne WGLOOP0
		; ----------------------------- 
		; delaying 1 cycle:
		          nop
		; ============================= 

	ret

		;***********************************************
		;*************** Huge Delay Loop ***************
		;***********************************************

	Huge_Delay:

		push	temp1

		ldi	temp1,0x0A
		Huge_Delay_Loop:
			rcall delay
			dec	temp1
		Brne Huge_Delay_Loop
		
		pop		temp1

	ret

		;***********************************************
		;************* Messege Delay Loop **************
		;***********************************************

	Message_Delay:

		push	temp1

		ldi	temp1,0x1f
		Message_Delay_Loop:
			rcall delay
			dec	temp1
		Brne Message_Delay_Loop

		pop		temp1

	ret

		;***********************************************
		;************* Binary to Decimal ***************
		;***********************************************

	Binary_to_Decimal:
		
		mov	dd8u,temp1		;k/0x64
		ldi	dv8u,0x64
		rcall	div8u		;Divide

		mov	temp2,dres8u	;Ekatontades

		mov	dd8u,drem8u
		ldi	dv8u,0x0a		
		rcall	div8u		;Divide

		mov	temp3,dres8u	;Dekades
		mov	temp4,drem8u	;Monades
	ret

	    ;***********************************************
        ;*********** Convert Decimal to ASCII **********
        ;***********************************************

	Conv_Dec_to_Ascii:
		
		push	temp2		;Backup temp2
		
		ldi	temp2,0x30
		add	temp1,temp2

		pop		temp2		;Restore temp2

	ret

	    ;***********************************************
        ;******** Unsigned Division 8-bit/8-bit ********
        ;***********************************************

	div8u:	
		sub	drem8u,drem8u	;clear remainder and carry 
		ldi	dcnt8u,9		;init loop counter 
	d8u_1:	
		rol	dd8u			;shift left dividend 
		dec	dcnt8u			;decrement counter 
		brne	d8u_2		;if done 
		mov	dres8u,dd8u
		ret					;return 
	d8u_2:	
		rol	drem8u			;shift dividend into remainder 
		sub	drem8u,dv8u		;remainder = remainder - divisor 
		brcc	d8u_3		;if result negative 
		add	drem8u,dv8u		;restore remainder 
		clc					;clear carry to be shifted into result 
		rjmp	d8u_1		;else 
	d8u_3:	
		sec					;set carry to be shifted into result 
		rjmp	d8u_1 
 
