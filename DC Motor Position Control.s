.title "EL308 with CNint"
	.sbttl "Keyboard Buffer Example - 1 word buffer"
	.equ __24FJ256GB110, 1
	.include "p24FJ256GB110.inc"

	.global __reset          ;The label for the first line of code.
	.global __T1Interrupt    ;Declare Timer 1 ISR name global
	.global	__CNInterrupt

.bss
	LCD_line1:	.space 16
	LCD_line2:	.space 16
	LCD_ptr:	.space 2
	LCD_cmd:	.space 2
	LCD_offset: .space 2
	Buffer:		.space 2
.section .const,psv
	line1:		.ascii "                "
	line2:		.ascii "               0"
	lookup:		.ascii "0123456789ABCDEF"
.text                             ;Start of Code section
__reset:
	mov 	#__SP_init, W15		; Initalize the Stack Pointer
	mov 	#__SPLIM_init, W0	; Initialize the Stack Pointer Limit Register
	mov 	W0, SPLIM
	nop							; Add NOP to follow SPLIM initialization

	call	init_PSV

	call	init_LED
	call	init_LCD
	call	init_message
	call	init_keypad
	call	init_buzzer
    call    init_timer2
	call	init_timer
    
;PWM initialization

    bclr	RPOR3, #RP6R0
	bset	RPOR3, #RP6R1
	bclr	RPOR3, #RP6R2
	bclr	RPOR3, #RP6R3
	bset	RPOR3, #RP6R4
	bclr	RPOR3, #RP6R5		; OC1 output assigned to pin RB6 (pin#26, RP6)

	mov		#2048, W0
	mov		W0, OC1RS			; PWM frequency 2e6/2048 = 977Hz (fosc=4e6, fcy=2e6)

	mov		#0, W0
	mov		W0, OC1R			; PWM OFF (0% duty cycle)

	bset	OC1CON2, #SYNCSEL0
	bset	OC1CON2, #SYNCSEL1
	bset	OC1CON2, #SYNCSEL2
	bset	OC1CON2, #SYNCSEL3
	bset	OC1CON2, #SYNCSEL4	; sync source = this OC module

	bset	OC1CON1, #OCTSEL0
	bset	OC1CON1, #OCTSEL1
	bset	OC1CON1, #OCTSEL2	; clock source = system clock

	bclr	OC1CON1, #OCM0
	bset	OC1CON1, #OCM1
	bset	OC1CON1, #OCM2		; edge aligned PWM mode

; PWM settings for OC2

	bset	RPOR4, #RP8R0
	bset	RPOR4, #RP8R1
	bclr	RPOR4, #RP8R2
	bclr	RPOR4, #RP8R3
	bset	RPOR4, #RP8R4		; OC2 output function number = 19
	bclr	RPOR4, #RP8R5		; OC2 output assigned to pin RB9 (pin#32, RP8)

	mov		#2048, W0
	mov		W0, OC2RS			; PWM frequency 2e6/2048 = 977Hz (fosc=4e6, fcy=2e6)

	mov		#0, W0
	mov		W0, OC2R			; PWM OFF (0% duty cycle)

	bset	OC2CON2, #SYNCSEL0
	bset	OC2CON2, #SYNCSEL1
	bset	OC2CON2, #SYNCSEL2
	bset	OC2CON2, #SYNCSEL3
	bset	OC2CON2, #SYNCSEL4	; sync source = this OC2 module

	bset	OC2CON1, #OCTSEL0
	bset	OC2CON1, #OCTSEL1
	bset	OC2CON1, #OCTSEL2	; clock source = system clock

	bclr	OC2CON1, #OCM0
	bset	OC2CON1, #OCM1
	bset	OC2CON1, #OCM2		; edge aligned PWM mode
    bclr	AD1CON1, #9
	bclr	AD1CON1, #8	; integer output
	bset	AD1CON1, #15	; enable ADC

	bset	CNEN1, #CN15IE		; enable interrupts for CN15 (port D bit 6)
	bset	IEC1, #CNIE			; enable CN interrupt


start:
	btss	TMR2, #14
	bra		start

wait_1:
	btsc	TMR2, #15
	bra		wait_1
    bset    PORTF,#1
    bset	AD1CHS,	#0
	bset	AD1CHS,	#1
	bset	AD1CHS,	#2
	bclr	AD1CHS,	#3	; channel 7

    bset	AD1CON1, #1		; start sampling
	nop
	nop
	nop
	nop
	bclr	AD1CON1, #1		; start conversion

wait_2:
	btst	AD1CON1, #0
	bra     Z, wait_2
	mov     ADC1BUF0, W1	; W1 holds ADC reading

    bset	AD1CHS,	#0
	bclr	AD1CHS,	#1
	bset	AD1CHS,	#2
	bset	AD1CHS,	#3	; channel 13

    bset	AD1CON1, #1		; start sampling
	nop
	nop
	nop
	nop
	bclr	AD1CON1, #1		; start conversion

wait_3:

	btst	AD1CON1, #0
	bra     Z, wait_3
	mov     ADC1BUF0, W2	; W2 holds ADC reading

    lsr     W2,#6,W2
    lsr     W1,#6,W1
    cp      W1, W2
    bra     Z, case_0       ;if W1 is equal to W2 goes to branch case_0
    cp      W1, W2
    bra     GT,case_gt      ;if W1 is greater than W2 goes to branch case_gt
    cp      W1, W2
    bra     LT, case_lt     ;;if W1 is less than W2 goes to branch case_lt
	bra		start

case_0:
	mov		#0, W0
	mov		W0, OC1R			; PWM OFF (0% duty cycle)
    mov		#0, W5
	mov		W5, OC2R			; PWM OFF (0% duty cycle)
    bra     start

case_gt:
    sub     W1, W2, W3
    repeat  #3
    add     W3, W3, W3
    mov		#0, W0
	mov		W0, OC1R			; PWM OFF (0% duty cycle
	mov		W3, OC2R			; PWM OFF (0% duty cycle)
    bra     start

case_lt:
    sub     W2, W1, W3
    repeat  #3
    add     W3, W3, W3

    mov		W3, OC1R			; PWM OFF (0% duty cycle)
    mov		#0, W0
	mov		W0, OC2R			; PWM OFF (0% duty cycle)
    bra     start

; -------------------------------------------------------
; !!!!!!!!!!!!!!!!!! CNInterrupt !!!!!!!!!!!!!!!!!!!!!!!!
; -------------------------------------------------------

__CNInterrupt:
	push	W0
	push	W1
	push	W2

	btss	PORTD, #6			; is the key pressed or released?
	bra		done_CNint			; releases

	mov		PORTD, W0
	and		W0, #0x000F, W0
	mov		#psvoffset(lookup), W1
	mov.b	[W0+W1], W2			; get character code
	mov		W2, Buffer
	bset	Buffer, #15			; there is a character in the buffer



done_CNint:
	bclr	IFS1, #CNIF			; clear CNInterrupt flag

	pop		W2
	pop		W1
	pop		W0					; restore registers
	retfie

; -----------------------------------------------------
; !!!!!!!!!!!!!!!!!! Functions !!!!!!!!!!!!!!!!!!!!!!!!
; -----------------------------------------------------

init_PSV:
	mov		#psvpage(line1), W0
	mov		W0, PSVPAG		; set PSVPAG to page that contains hello
	bset.b	CORCONL,#PSV	; enable Program Space Visibility
	return


init_timer2:
	bclr	T2CON, #TON		; turn timer1 OFF

	bclr	T2CON, #TCKPS1
	bclr	T2CON, #TCKPS0	; set prescaler to 256

	bclr	T1CON, #TCS		; select internal clock

	mov		#0x0000, W0
	mov		W0, TMR2		; clear TMR1 register
	mov		#20000, W0          ;set to 100 Hz
	mov		W0, PR2			; set timer1 period to 32150 -> f=2e6/64/31250=1 Hz

	bset	T2CON, #TON		; turn timer1 ON
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
;	btg		PORTF, #2
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