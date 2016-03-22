	.title "EL308"
	.sbttl "Simple example on timer1 interrupt"
	.equ __24FJ256GB110, 1
	.include "p24FJ256GB110.inc"

	.global __reset          ;The label for the first line of code. 
	.global __T2Interrupt    ;Declare Timer 1 ISR name global
	.global	__CNInterrupt


.bss
    LCD_line1:	.space 16
	LCD_line2:	.space 16
	LCD_ptr:	.space 2
	LCD_cmd:	.space 2
	LCD_offset: .space 2
    Timer_Count:		.space 2
    Intensity:	.space 2

.section .const,psv
	line1:		.ascii "                "
	line2:		.ascii "                "
	lookup:		.ascii "0123456789ABCDEF"

.text                             ;Start of Code section
__reset:
	mov 	#__SP_init, W15		; Initalize the Stack Pointer
	mov 	#__SPLIM_init, W0	; Initialize the Stack Pointer Limit Register
	mov 	W0, SPLIM
	nop							; Add NOP to follow SPLIM initialization     

	call	init_LED
	call	init_timer2

	bset	CNEN1, #CN15IE		; enable interrupts for CN15 (port D bit 6)
	bset	IEC1, #CNIE			; enable CN interrupt

    mov     #0,W0
    mov     W0,Timer_Count

check_keypad:
    btss	PORTD, #6
	bra		check_keypad

    mov     #64,W2
    mov     #0,W3
    mov     #256,W4
    mov     Intensity,W1
    add     W1,W2,W1            ;increase intensity by 64 whenever a key is pressed
    mov     W1,Intensity

    cp      W1,W4
    bra     LE, wait_release
    mov     W3,Intensity        ;if intensity is greater than 256, initialize it to zero

wait_release:
	btsc	PORTD, #6		; key released?
	bra		wait_release
;	bclr	PORTD, #13		; turn the buzzer off

	bra		check_keypad


; -----------------------------------------------------
; !!!!!!!!!!!!!!!!!! Functions !!!!!!!!!!!!!!!!!!!!!!!!
; -----------------------------------------------------

init_timer2:
	bclr	T2CON, #TON		; turn timer1 OFF
	
	bset	T2CON, #TCKPS1
	bclr	T2CON, #TCKPS0	; set prescaler to 256

	bclr	T2CON, #TCS		; select internal clock

	mov		#0x0000, W0 
	mov		W0, TMR2		; clear TMR2 register
	mov		#1, W0
	mov		W0, PR2			; set timer2 period to  -> f=2e6/256/1=7812 Hz

	bclr	IPC0, #14
	bclr	IPC0, #13
	bset	IPC0, #12		; set timer1 priority to 001
	bclr	IFS0, #T2IF		; clear timer1 interrupt status flag
	bset	IEC0, #T2IE		; enable timer1 interrupts
	bset	T2CON, #TON		; turn timer1 ON
	return

init_LED:
	bclr	TRISF, #0
	bclr	TRISF, #1
	bclr	TRISF, #2
	bclr	TRISF, #3		; LED array
	return


; ----------------------------------T2 Interrupt--------------------------------------

__T2Interrupt:
	push.s						; push shadow registers
	push    W1
	push    W2
	push    W3
;<<insert user code here>>

	bclr	IFS0, #T2IF			; Clear the Timer2 Interrupt flag Status

    mov		Timer_Count, W0
	inc		W0, W0              ; increase timer count

    mov     Intensity,W1
    cpslt      W0,W1
    bra     off

       ; ON-- if timer count is less than intensity the led turns on
    bset	PORTF, #0
    mov		W0, Timer_Count
    bra     done_T2Interrupt

off:   ; OFF--if timer count is greater than intensity the led turns off
    bclr	PORTF, #0
    mov		W0, Timer_Count
    mov     #255,W2
    mov     #0,W3


    cpsgt   W2,W0
    mov     W3,Timer_Count          ;reset timer count when it becomes 256
done_T2Interrupt:
    pop    W3
    pop    W2
    pop    W1
    pop.s						; pop shadow registers
	retfie						; Return from Interrupt Service routine

;--------End of All Code Sections ---------------------------------------------

.end							; End of program code in this file

