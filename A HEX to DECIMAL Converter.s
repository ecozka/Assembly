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
    Buffer2:    .space 2
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

	call	init_PSV
	call	init_LED
	call	init_LCD
	call	init_message
	call	init_keypad
	call	init_buzzer

	call	init_timer

	bset	CNEN1, #CN15IE		; enable interrupts for CN15 (port D bit 6)
	bset	IEC1, #CNIE			; enable CN interrupt

	bclr	Buffer, #15

	mov		#LCD_line1, W5		; W5 acts as pointer to 1st line of LCD
    mov     #0, W7
    mov     #0, W8
 mov     #0, W2
 mov     #0, W9
 mov     #0, W10
 mov     #0, W11
 mov     #0, W12
 mov     #0, W13
 mov     #0, W14


main_loop:
	btss	Buffer, #15
	bra		no_key

	bclr	Buffer, #15
    sl      W2, #4, W2
    mov     Buffer2, W0         ; Buffer2 saves the pressed keys but not converting them into ascii
    add     W0, W2, W2          ; shifting and adding to obtain each byte each press
	mov		Buffer, W0
	mov.b	W0, [W5++]			; display on LCD

cont:                           ;checks if the fourth digit is pressed
    mov		#LCD_line1, W8
    add     W8,#0x04, W8
    cp      W8, W5
    bra     NZ, main_loop
    bra     convert             ; if the fourth key is pressed sends to convert

no_key:
	bra		main_loop

convert:                        ; converts hex to decimal and obtains ascii code

    mov     #10, W12
    mov     #100, W11
    mov     #1000, W10
    mov     #10000, W9

    repeat  #17                 ; first digit is obtained [10binler basamagi]
    div.u   W2, W9              ; div.u sends quotient to W0 and remainder to W1
    mov     W0, W6              ; quotient is saved to W6 (first(biggest) digit)

    repeat  #17
    div.u   W1, W10             ; by dividing the remainder into 1000 the second digit is obtained
    mov     W0, W7

    repeat  #17                 ; same process continues for the third digit
    div.u   W1, W11
    mov     W0, W8

    repeat  #17                 ; same process for the fourth digit
    div.u   W1, W12             ; remainder of this operation (which is the last/smallest digit)is in W1 register
    mov     W0, W13

    mov #'0', W9                ; all digits are converted into their ascii code and sent to display on LCD
    mov #LCD_line2, W10
    add W6, W9, W6
    mov.b W6, [W10++]
    add W7, W9, W7
    mov.b W7, [W10++]

    add W8, W9, W8
    mov.b W8, [W10++]

    add W13, W9, W13
    mov.b W13, [W10++]

    add W1, W9, W1
    mov.b W1, [W10++]

clear:                          ; after the conversion and display if another key is pressed resets
    btss Buffer, #15
    bra clear
    bra __reset



    

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
    mov     W0, Buffer2         ; Buffer2 saves without ascii code!!!

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