.title "EL308 Lab#4"
	.sbttl "RS232 Communications through PICkit 2"
	.equ __24FJ256GB110, 1
	.include "p24FJ256GB110.inc"

	.global __reset          ;The label for the first line of code. 
	.global __T1Interrupt    ;Declare Timer 1 ISR name global

.bss
	LCD_line1:	.space 16
	LCD_line2:	.space 16
	LCD_ptr:	.space 2
	LCD_cmd:	.space 2
	LCD_offset: .space 2
	byte_cnt:	.space 2
.section .const,psv
	line1:		.ascii "UART Test       "
	line2:		.ascii "                "
	lookup:		.ascii "0123456789ABCDEF"
.text                             ;Start of Code section
__reset:
	mov 	#__SP_init, W15		; Initalize the Stack Pointer
	mov 	#__SPLIM_init, W0	; Initialize the Stack Pointer Limit Register
	mov 	W0, SPLIM
	nop							; Add NOP to follow SPLIM initialization
        
        ;<<insert more user code here>>

	call	init_PSV
	call	init_LED
	call	init_LCD
	call	init_message
	call	init_keypad
	call	init_buzzer

	call	init_timer
	call	init_timer2



	bset    AD1PCFG, #1

bset 	RPINR19, #U2RXR0
	bclr	RPINR19, #U2RXR1
	bclr	RPINR19, #U2RXR2
	bclr	RPINR19, #U2RXR3
	bclr	RPINR19, #U2RXR4
	bclr	RPINR19, #U2RXR5	; UART2 receive to RP1 (pin 24)

	bset	RPOR0, #RP0R0
	bclr	RPOR0, #RP0R1
	bset	RPOR0, #RP0R2
	bclr	RPOR0, #RP0R3
	bclr	RPOR0, #RP0R4
	bclr	RPOR0, #RP0R5		; UART2 transmit to RP0	(pin 25)

	bclr	RPINR18, #0
	bclr	RPINR18, #1
	bclr	RPINR18, #2
	bset	RPINR18, #3
	bclr	RPINR18, #4
	bset	RPINR18, #5		; UART1 receive to RP40 (pin 8) (40 = 0x28)
					; see Page 124 of the PIC24FJ256GB110 manual

	bset	RPOR9, #8
	bset	RPOR9, #9
	bclr	RPOR9, #10
	bclr	RPOR9, #11
	bclr	RPOR9, #12
	bclr	RPOR9, #13		; UART1 transmit to RP19 (pin 12)
					; see pages 125 and 143 of the PIC24FJ256GB110 manual


	bset	U1MODE, #15		; UART1 enabled
	bset	U1STA,	#10		; UART1 transmit enable
	mov	#12, W0
	mov	W0, U1BRG		; 19.2 BAUD for fcy=4MHz (default)


	; UART initialization goes here
	bset	U2MODE, #15		; UART1 enabled
	bset	U2STA,	#10		; UART1 transmit enable
	mov     #12, W0
	mov     W0, U2BRG		; 9600 BAUD for fcy=2MHz (default)
    bclr    U2MODE, #0      ; for 8-bit and no parity
    bclr    U2MODE, #1
    bclr    U2MODE, #2

  mov     #0x0D, W9
  mov     #0x0A, W8
  mov     #0, W7
  mov 	#LCD_line1,	W13
mov       #0, W6
start:

	btss	PORTD, #6		; keypad entry?
	bra		no_key

	; XMIT code goes here
;waitTXbuff:
;	btst	U2STA, #UTXBF	; buffer empty? (UTXBF = bit 9)
;	bra     NZ, waitTXbuff
 ;   mov     PORTD, W10
  ;  mov     #0x000F,W4
  ;  and     W4,W10,W10
  ;  mov     #psvoffset(lookup),W1
  ;  mov.b   [W10+W1], W10
   ; mov     W10, U2TXREG

wait_release1:
	btsc	PORTD, #6		; key released?
	bra		wait_release1
no_key:
    btst	U2STA, #URXDA	; data available? (URXDA = bit 0)
	bra     NZ, waitRX2data

    btst    U1STA, #URXDA
    bra     NZ, waitRX1data
    bra     start

	; RCV code goes here
waitRX1data:
    mov     U1RXREG,W10
    mov     W10,U2TXREG
    bra     start

waitRX2data:
	;btst	U2STA, #URXDA	; data available? (URXDA = bit 0)
	;bra     Z,start
	mov     U2RXREG, W10	; W0 gets serial data

    btsc    W11, #0
    ;bra     reset_LCD
    mov     W10,U1TXREG
    cp      W10,W7
    bra     Z,start
    cp      W10,W9          ;check 0x0D
    bra     Z, send_back

    mov     #LCD_line1, W13
    mov.b   W10, [W13+W6]
    inc     W6,W6
    bra     start

send_back:
    btst	U2STA, #URXDA       ; data available? (URXDA = bit 0)
	bra     Z, send_back
    mov     U2RXREG, W10
                                ; sends ok
    mov     #'O', W12
    mov     W12, U2TXREG
    mov     #'K', W12
    mov     W12, U2TXREG
    mov     #0x000D, W12
    mov     W12, U2TXREG
    mov     #0x000A, W12
    mov     W12, U2TXREG

    cp.b    W10, W8   ;check 0x0A
    mov     #1,W11
    bra     start


;reset_LCD:                  ;resets LCD and writes the newline
 ;   mov		#' ', W1
;	mov		#LCD_line1, W2
	;repeat	#15
	;mov.b	W1, [W2++]
   ; mov     #0,W6
   ; mov.b   W10,[W13+W6]

   ; inc     W6,W6
   ; mov     #0,W11

   ; bra     start



; -----------------------------------------------------
; !!!!!!!!!!!!!!!!!! Functions !!!!!!!!!!!!!!!!!!!!!!!!
; -----------------------------------------------------

init_timer2:
	bclr	T2CON, #TON		; turn timer1 OFF
	
	bset	T2CON, #TCKPS1
	bclr	T2CON, #TCKPS0	; set prescaler to 256

	bclr	T1CON, #TCS		; select internal clock

	mov		#0x0000, W0 
	mov		W0, TMR2		; clear TMR1 register
	mov		#31250, W0
	mov		W0, PR2			; set timer1 period to 32150 -> f=2e6/64/31250=1 Hz
	
	bset	T2CON, #TON		; turn timer1 ON
	return


init_PSV:
	mov		#psvpage(line1), W0
	mov		W0, PSVPAG		; set PSVPAG to page that contains hello
	bset.b	CORCONL,#PSV	; enable Program Space Visibility
	return

init_timer:
	bclr	T1CON, #TON		; turn timer1 OFF
	
	bset	T1CON, #TCKPS1
	bset	T1CON, #TCKPS0	; set prescaler to 256

	bclr	T1CON, #TCS		; select internal clock

	mov		#0x0000, W0 
	mov		W0, TMR1		; clear TMR1 register
	mov		#0x0040, W0
	mov		W0, PR1			; set timer1 period to 0x0040 -> f=2e6/256/64=122 Hz

	bclr	IPC0, #14
	bclr	IPC0, #13
	bset	IPC0, #12		; set timer1 priority to 001
	bclr	IFS0, #T1IF		; clear timer1 interrupt status flag
	bset	IEC0, #T1IE		; enable timer1 interrupts
	
	bset	T1CON, #TON		; turn timer1 ON
	return

init_LED:
	bclr	TRISF, #0
	bclr	TRISF, #1
	bclr	TRISF, #2
	bclr	TRISF, #3		; LED array
	return

init_LCD:
	bclr	TRISB, #15
	bclr	PORTD, #4		; make sure LCD is disabled before port is set to output mode
	bclr	TRISD, #4
	bclr	TRISD, #5
	mov		#0xFF00, W0
	mov		W0, TRISE

	bclr	PORTD, #5		; select LCD WR mode

	mov		#0x0038, W0		; init LCD
	call	sendcomm
	call	dly
	call	dly
	call	dly

	mov		#0x000C, W0		; LCD on, cursor off
	call	sendcomm
	mov		#0x0001,W0		; clear LCD
	call 	sendcomm
	return

sendcomm:
	bclr	PORTB,#15	; select LCD command register
	mov		W0, PORTE	; output command
	bset	PORTD, #4
	call	dly
	nop
	bclr	PORTD, #4
	call	dly
	return

dly:
	mov 	#0x2000,W0
dlyloop:
	sub		W0, #1, W0
	bra		NZ, dlyloop
	return

init_message:
	mov		#0x0000, W0
	mov		W0, LCD_ptr
	mov		W0, LCD_offset
	mov		#0x00C0, W0
	mov		W0, LCD_cmd
	mov		#psvoffset(line1), W1
	mov		#LCD_line1, W2
	repeat	#15
	mov.b	[W1++], [W2++]
	mov		#psvoffset(line2), W1
	mov		#LCD_line2, W2
	repeat	#15
	mov.b	[W1++], [W2++]
	return

init_keypad:
	bset	TRISD,#0	; DATA A
	bset	TRISD,#1	; DATA B
	bset	TRISD,#2	; DATA C
	bset	TRISD,#3	; DATA D
	bset	TRISD,#6	; DATA Available
	return

init_buzzer:
	bclr	PORTD, #13	; buzzer initially OFF
	bclr	TRISD, #13	; enable output
	return
	

;..............................................................................
;Timer 1 Interrupt Service Routine
;Example context save/restore in the ISR performed using PUSH.D/POP.D
;instruction. The instruction pushes two words W4 and W5 on to the stack on
;entry into ISR and pops the two words back into W4 and W5 on exit from the ISR
;..............................................................................
__T1Interrupt:
	push.s
	push.d	W4                  ; Save context using double-word PUSH
	
        ;<<insert user code here>>
	bclr	IFS0, #T1IF           ; Clear the Timer1 Interrupt flag Status
                                  ; bit.

	clrwdt	; !!!!!!!!!!!! Very bad practice! !!!!!!!!!!!!!!!!

	mov		LCD_ptr, W2
	mov		#0x0010, W1
	cp		W1, W2
	bra		NZ, send_LCD_data
	mov		LCD_cmd, W0
	bclr	PORTB, #15		; select LCD command register
	mov		W0, PORTE		; output command
	bset	PORTD, #4
	nop
	bclr	PORTD, #4
	btg		W0, #6
	mov		W0, LCD_cmd
	mov		#0x0000, W2
	mov		W2, LCD_ptr
	mov		LCD_offset, W0
	btg		W0, #4
	mov		W0, LCD_offset
	btg		PORTF, #2
	bra		done_T1interrupt
send_LCD_data:
	mov		LCD_offset, W3
	add		W3, W2, W3
	mov		#LCD_line1, W1
	mov.b	[W1+W3], W0
	bset	PORTB, #15		; select LCD data register
	mov		W0, PORTE		; output command
	bset	PORTD, #4
	nop
	bclr	PORTD, #4
	inc		W2, W2
	mov		W2, LCD_ptr

done_T1interrupt:
	pop.d W4                   ;Retrieve context POP-ping from Stack
	pop.s
	retfie                     ;Return from Interrupt Service routine

;--------End of All Code Sections ---------------------------------------------

.end                               ;End of program code in this file
