	.title "EL308 Lab#2"
	.sbttl "Counter example for egg timer"
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
	timer:		.space 2
    timer2:     .space 2
.section .const,psv
	line1:		.ascii "00:00      00:00"
	line2:		.ascii "PLAYER1  PLAYER2"
	lookup:		.ascii "*0*C123*456*789*"
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

	mov		#0, W0
	mov		W0, timer
	mov		#0, W7
	mov		W7, timer2

check_keypad:
    btss	PORTD, #6	; keypad entry?
	bra		check_keypad
	mov     PORTD, W5
    mov     #0x000F, W1
    and     W5,W1,W5
    mov     #0x0005, W6 ;button S10 is the start key
    cp      W5, W6      ;checks if the start key is pressed
    bra     NZ, check_keypad

wait_21:                ;PLAYER 1
	btss	TMR2, #14
	bra		wait_21
	bset	PORTF, #3
    clrwdt
wait_20:
	btsc	TMR2, #14
	bra		wait_20
	bclr	PORTF, #3

	mov		timer2, W7 ;timer of PLAYER 1 is in the register W7
	inc		W7, W7
	daw.b	W7
    mov     #0x0060,W12;checks if the seconds reach to 60
    cpsne   W12,W7     ;if 60 seconds passed, 60=W7, then this command does not skip the below line
    bra     minute2    ;therefore it goes to minute branch of PLAYER 1

	mov		W7, timer2

	mov		#'0', W3
	mov		#LCD_line1, W4

	mov		#0x00F0, W9
	and		W7, W9, W8
	lsr		W8, #4, W8
	add		W8, W3, W8
	mov.b	W8, [W4+3] ;first digit of second count of player 1 are shown in 4th box on the screen

	mov		#0x000F, W9
	and		W7, W9, W8
	add		W8, W3, W8
	mov.b	W8, [W4+4];second digit

    btss    PORTD, #6 ;if a key is pressed, skips the next line...
	bra		wait_21
    bra     check_key2;...and goes to the check key branch of player1
   
check_key2:           ;for player 1, if a key is pressed,
                      ;checks whether it is the reset key or the key that starts the time count for player2
                      ;if it is neither of them sends back to the time count for player 1
	mov     PORTD, W5
    mov     #0x000F, W1
    and     W5,W1,W5
    mov     #0x0009, W6;button S6 is the button that starts the player 2's turn
	mov		#0x0004, W13;button that resets the game is S9
    cpsne   W5, W6
	bra     wait_1
	cpseq	W5, W13
    bra     wait_21
    bra		__reset

wait_1:               ;PLAYER 2 (process is the same except the display part, clock for player 2 is shown at the right)
	btss	TMR2, #14
	bra		wait_1
	bset	PORTF, #3
    clrwdt
wait_0:
	btsc	TMR2, #14
	bra		wait_0
	bclr	PORTF, #3

	mov		timer, W0;timer of the player 2 is in the register W0
	inc		W0, W0
	daw.b	W0
    mov     #0x0060,W12
    cpsne   W12,W0
    bra     minute
	mov		W0, timer

	mov		#'0', W3
	mov		#LCD_line1, W4

	mov		#0x00F0, W2
	and		W0, W2, W1
	lsr		W1, #4, W1
	add		W1, W3, W1
	mov.b	W1, [W4+14];clock for player2 is shown at the right
 	
	mov		#0x000F, W2
	and		W0, W2, W1
	add		W1, W3, W1
	mov.b	W1, [W4+15]

    btss    PORTD, #6
	bra		wait_1
    bra     check_key1

check_key1:             ;for player 2 (same process as check_key1)
	mov     PORTD, W5
    mov     #0x000F, W1
    and     W5,W1,W5
    mov     #0x000A, W6;button S7 starts the turn of player1
    cpsne   W5, W6
	bra     wait_21
	cpseq	W5, W13
    bra     wait_1
    bra		__reset

minute:                ;to count the minutes for player 2
    mov     #0, W0     ;initialized
    mov		W0, timer

    inc     W14, W14   ;counts the minutes
    daw.b   W14

	mov		#'0', W3
	mov		#LCD_line1, W4

    add		W0, W3, W0  ;to display __:00 after __:59
    mov.b   W0, [W4+14]
    mov.b   W0, [W4+15]

    mov		#0x00F0, W2
	and		W14, W2, W1
	lsr		W1, #4, W1
	add		W1, W3, W1
	mov.b	W1, [W4+11];first digit of minutes of player 2

	mov		#0x000F, W2
	and		W14, W2, W1
	add		W1, W3, W1
	mov.b	W1, [W4+12];second digit of minutes of player 2
    bra     wait_1  ;sends to count seconds again

minute2:                ;counts minutes for player 1 (same process)
    mov     #0, W7
    mov		W7, timer2

    inc     W10, W10
    daw.b   W10

	mov		#'0', W3
	mov		#LCD_line1, W4

    add		W7, W3, W7
    mov.b   W7, [W4+3]
    mov.b   W7, [W4+4]

    mov		#0x00F0, W9
	and		W10, W9, W8
	lsr		W8, #4, W8
	add		W8, W3, W8
	mov.b	W8, [W4]

	mov		#0x000F, W9
	and		W10, W9, W8
	add		W8, W3, W8
	mov.b	W8, [W4+1]
    bra     wait_21


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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
