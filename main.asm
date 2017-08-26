;avra main.asm

;.include "tn5def.inc"
;.include "tn9def.inc"
.include "tn10def.inc"

;#define MOSFET_VERSION_HWPWM
#define MOSFET_VERSION_SWPWM	; comment if no mosfet PCB

.EQU 	FREQ_CONST		= 742-1	; constant for frequency generator (183us for 50% duty cycle of 2739Hz). -1 for CALL/RET

#ifdef MOSFET_VERSION_SWPWM
.EQU	BUZZ_Out_ON		= 1 << PB0 	; Tone ON
.EQU	BUZZ_Out_OFF	= 0 << PB0 	; Tone OFF
.EQU	CONTROL_PIN		= PB1	; Control 
#else
.EQU	BUZZ_Out_ON		= 1 << PB0 | 1 << PB1 | 1 << PB2	; Tone ON
.EQU	BUZZ_Out_OFF	= 0 << PB0 | 0 << PB1 | 0 << PB2	; Tone OFF
.EQU	CONTROL_PIN		= PB3	; Control (RESET pin with voltage divider)
#endif



.def	tmp		= r16
.def	tmp1	= r17
.def	pwm_cL	= r18
.def	pwm_cH	= r19

.CSEG
.ORG 0
		cli
		; 8Mhz (Leave 8 mhz osc with no prescaler)
		; Write signature for change enable of protected I/O register
		ldi tmp, high (RAMEND) ; Main program start
		out SPH,tmp ; Set Stack Pointer
		ldi tmp, low (RAMEND) ; to top of RAM
		out SPL,tmp

		ldi tmp, 0xD8
		out CCP, tmp
		ldi tmp, (0 << CLKPS3) | (0 << CLKPS2) | (0 << CLKPS1) | (0 << CLKPS0) ;  prescaler is 1 (8mhz)
		out  CLKPSR, tmp
		
		ldi tmp, BUZZ_Out_ON
		out DDRB, tmp 					; configure pins as output

;
		ldi tmp, 	(1 << CONTROL_PIN)	; enable pull-up to protect floating input when no power on FC
		out PUEB,	tmp				; 
		out PORTB, tmp				; all pins to LOW except pull-up
;
		
PWM_loop:
		; PWM the buzzer at 50% duty cycle
		sbic PINB, CONTROL_PIN		; 1/2
		rjmp PWM_loop				; 2
		ldi tmp, BUZZ_Out_ON		; 1
		out PORTB, tmp		 		; 1 turn buzzer ON
		rcall DELAY					; 3
		nop							; 1 align for sbic
		nop							; 1 align for sbic
		nop							; 1 align for rjmp
		nop							; 1 align for rjmp
		ldi tmp, BUZZ_Out_OFF		; 1
		out PORTB, tmp 				; 1 turn buzzer OFF
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

#ifdef MOSFET_VERSION_HWPWM		
PWM_init:
		ldi tmp, (1<<COM0A1) | (1<<WGM01) | (1<<WGM00)	; Phase correct (OCR0A), mode 11
		out TCCR0A, tmp
		ldi tmp, (1<<WGM03) | (0<<WGM02) | (0<<CS02) | (0<<CS01) | (1<<CS00)	; ; Phase correct (OCR0A), mode 11
		out TCCR0B, tmp
		ldi tmp, LOW(FREQ_CONST)
		ldi tmp1, HIGH(FREQ_CONST)
		out OCR0AH, tmp1
		out OCR0AL, tmp
		ret
#endif
