;avra main.asm

;.include "tn4def.inc"
;.include "tn5def.inc"
;.include "tn9def.inc"
.include "tn10def.inc"

.EQU 	FREQ_CONST		= 742-1	; constant for frequency generator (183us for 50% duty cycle of 2739Hz). -1 for CALL/RET

.EQU	BUZZ_Out_ON		= 1 << PB0 | 1 << PB1 | 1 << PB2	; Tone ON
.EQU	BUZZ_Out_OFF	= 0 << PB0 | 0 << PB1 | 0 << PB2	; Tone ON

.EQU	CONTROL_PIN		= PB3	; Control (RESET pin with voltage divider)


.def	tmp			= r16
.def	pwm_cL	= r18
.def	pwm_cH	= r19

.CSEG
.ORG 0
		cli
		; 8Mhz (Leave 8 mhz osc with no prescaler)
		; Write signature for change enable of protected I/O register
		ldi tmp, 0xD8
		out CCP, tmp
		ldi tmp, (0 << CLKPS3) | (0 << CLKPS2) | (0 << CLKPS1) | (0 << CLKPS0) ;  prescaler is 1 (8mhz)
		out  CLKPSR, tmp
		
		ldi tmp, BUZZ_Out_ON
		out DDRB, tmp 					; configure pins as output
		
PWM_loop:
		; PWM the buzzer at 50% duty cycle
		sbic PINB, CONTROL_PIN		; 1/2
		rjmp PWM_loop				; 2
		out PORTB, BUZZ_Out_ON 		; 1 turn buzzer ON
		rcall DELAY					; 3
		nop							; 1 align for sbic
		nop							; 1 align for sbic
		nop							; 1 align for rjmp
		nop							; 1 align for rjmp
		out PORTB, BUZZ_Out_OFF 	; 1 turn buzzer OFF
		rcall DELAY					; 3
		rjmp PWM_loop				; 2

; 1us = 8 cycles
DELAY:
		ldi  pwm_cL, LOW(FREQ_CONST); 1 
		ldi  pwm_cH, HIGH(FREQ_CONST); 1
PWM_F1:	dec  pwm_cL					; 1
		brne PWM_F1					; 1/2
		dec  pwm_cH					; 1
		brne PWM_F1					; 1/2
		ret							; 4