;---------------------------------------------------------------
; Embedded Project for ATmega328P
; Created: 1/27/2025
; Author: ASUS
;---------------------------------------------------------------

.include "m328pdef.inc"  ; ATmega328P definitions

; Constants
.equ PASSWORD_LENGTH = 4   ; Number of digits in the password
.equ PASSWORD_ATTEMPTS = 3 ; Max attempts before lockout
.equ SUCCESS_LED = 0       ; PORTB bit for success indicator
.equ FAIL_LED = 1          ; PORTB bit for fail indicator
.equ LED2 = 2              ; PORTB second LED
.equ LED3 = 3              ; PORTB third LED
.equ LOCK_BUTTON = PC1  ; LOCK Button on PC1
.equ UNLOCK_BUTTON = PC2  ;UNLOCK Button on PC2

; Define Password (1234 in this case)
.equ DIGIT1 = 1
.equ DIGIT2 = 2
.equ DIGIT3 = 3
.equ DIGIT4 = 4

.equ resetdigit1=9
.equ resetdigit2=8
.equ resetdigit3=7
.equ resetdigit4=6


;---------------------------------------------------------------
; Reset Vector
;---------------------------------------------------------------
.org 0x0000
rjmp main



; Define constants for row digits in program memory
.org 0x020
.CSEG
row1_digits: .DB 1, 2, 3,0    ; Row 1: 1, 2, 3
row2_digits: .DB 4, 5, 6,0    ; Row 2: 4, 5, 6
row3_digits: .DB 7, 8, 9,0    ; Row 3: 7, 8, 9
row4_digits: .DB 10, 0, 11,0  ; Row 4: *, 0, #



;---------------------------------------------------------------
; Main Program
;---------------------------------------------------------------
main:
  
    cbi portB, SUCCESS_LED
	sbi PORTB, FAIL_LED
	cbi DDRC, LOCK_BUTTON   ; Set PC1 (lock Button) as input
	cbi DDRC, UNLOCK_BUTTON    ; Set PC2 (unlock Button) as input
    ; Configure Ports
    ldi r21, 0xFF            ; PORTB as output (for LEDs)
    out DDRB, r21
    ldi r20, 0xF0            ; PORTD: High nibble output, Low nibble input
    out DDRD, r20
	

    ; Initialize Variables
    ldi r28, 0               ; Input counter (R28)
    ldi r19, PASSWORD_ATTEMPTS ; Remaining attempts

    rjmp LED_threeon         ; Start with all LEDs ON






;---------------------------------------------------------------
; Keypad Handling
;---------------------------------------------------------------
gnd_rows:
    
	
    ; Ground All Rows
    ldi r20, 0x0F
    out PORTD, r20

	

wait_release:
    sbic pinc,1
	rjmp main
	sbic pinc,2
	rjmp PASSWORD_SUCCESS

    nop
    in r21, PIND
    andi r21, 0x0F           ; Mask unused bits
    cpi r21, 0x0F            ; Check if no key is pressed
    brne wait_release        ; Wait until all keys are released

wait_keypress:

    sbic pinc,1
	rjmp main
	sbic pinc,2
	rjmp PASSWORD_SUCCESS

    nop
    in r21, PIND
    andi r21, 0x0F
    cpi r21, 0x0F
    breq wait_keypress       ; Wait for key press

    rcall my_delay           ; Debounce delay
    in r21, PIND             ; Confirm key press
    andi r21, 0x0F
    cpi r21, 0x0F
    breq wait_keypress

    ; Check Rows
    ldi r21, 0b01111111      ; Ground Row 1
    out PORTD, r21
    nop
    in r21, PIND
    andi r21, 0x0F
    cpi r21, 0x0F
    brne row1_col

    ldi r21, 0b10111111      ; Ground Row 2
    out PORTD, r21
    nop
    in r21, PIND
    andi r21, 0x0F
    cpi r21, 0x0F
    brne row2_col

    ldi r21, 0b11011111      ; Ground Row 3
    out PORTD, r21
    nop
    in r21, PIND
    andi r21, 0x0F
    cpi r21, 0x0F
    brne row3_col

    ldi r21, 0b11101111      ; Ground Row 4
    out PORTD, r21
    nop
    in r21, PIND
    andi r21, 0x0F
    cpi r21, 0x0F
    brne row4_col

;verify reset

;---------------------------------------------------------------
; Row and Digit Handling
;---------------------------------------------------------------
row1_col:
    
    ldi r30, LOW(row1_digits<<1)
    ldi r31, HIGH(row1_digits<<1)
    rjmp find_digit

row2_col:
    
    ldi r30, LOW(row2_digits<<1)
    ldi r31, HIGH(row2_digits<<1)
    rjmp find_digit

row3_col:
    ldi r30, LOW(row3_digits<<1)
    ldi r31, HIGH(row3_digits<<1)
    rjmp find_digit

row4_col:
   
    ldi r30, LOW(row4_digits<<1)
    ldi r31, HIGH(row4_digits<<1)
    rjmp find_digit



find_digit:
    
    sbic pinc,1
	rjmp main
	sbic pinc,2
	rjmp PASSWORD_SUCCESS
    lsr r21                  ; Locate column
    brcc digit_located
    lpm r20, Z+
    rjmp find_digit

digit_located:
    sbic pinc,1
	rjmp main
	sbic pinc,2
	rjmp PASSWORD_SUCCESS
  

    cpi r19,0 
	breq digit_located_reset 
	brlt digit_located_reset 
    lpm r20, Z               ; Get digit
    cpi r20, 11              ; Check if '#'
    breq VERIFY_PASSWORD
	cpi r20,10
	breq stat
	
    ; Store Input Digit
    mov r22, r28
    cpi r22, 0
    breq store_r27
    cpi r22, 1
    breq store_r26
    cpi r22, 2
    breq store_r25
    cpi r22, 3
    breq store_r24
    rjmp gnd_rows

stat:
	rjmp main

digit_located_reset:
    sbic pinc,1
	rjmp main
	sbic pinc,2
	rjmp PASSWORD_SUCCESS
    
    lpm r20, Z               ; Get digit
    cpi r20, 11              ; Check if '#'
    breq VERIFY_reset
    ; Store Input Digit
    mov r22, r28
    cpi r22, 0
    breq store_r27
    cpi r22, 1
    breq store_r26
    cpi r22, 2
    breq store_r25
    cpi r22, 3
    breq store_r24
    rjmp gnd_rows



VERIFY_reset:
    sbic pinc,1
	rjmp main
	sbic pinc,2
	rjmp PASSWORD_SUCCESS
    
    cpi r28, PASSWORD_LENGTH
    brne resetfail
    ; rest Verify against 9876
    ldi r22, resetdigit1
    cp r27, r22
    brne resetfail
    ldi r22, resetdigit2
    cp r26, r22
    brne resetfail
    ldi r22, resetdigit3
    cp r25, r22
    brne resetfail
    ldi r22, resetdigit4
    cp r24, r22
    brne resetfail
    rjmp main 

resetfail:
    ldi r28,0
    rjmp gnd_rows

store_r27:
    mov r27, r20
    rjmp increment_counter

store_r26:
    mov r26, r20
    rjmp increment_counter

store_r25:
    mov r25, r20
    rjmp increment_counter

store_r24:
    mov r24, r20
    rjmp increment_counter

increment_counter:
    
    inc r28                  ; Increment counter
    rjmp gnd_rows

VERIFY_PASSWORD:
    sbic pinc,1
	rjmp main
	sbic pinc,2
	rjmp PASSWORD_SUCCESS
    
    cpi r28, PASSWORD_LENGTH
    brne PASSWORD_FAIL

    ; Verify against 1234
	
    ldi r22, DIGIT1
    cp r27, r22
    brne PASSWORD_FAIL
    ldi r22, DIGIT2
    cp r26, r22
    brne PASSWORD_FAIL
    ldi r22, DIGIT3
    cp r25, r22
    brne PASSWORD_FAIL
    ldi r22, DIGIT4
    cp r24, r22
    brne PASSWORD_FAIL
    rjmp PASSWORD_SUCCESS



PASSWORD_SUCCESS:
    sbi PORTB, SUCCESS_LED
    cbi PORTB, FAIL_LED
    ldi r28, 0
    rjmp gnd_rows

PASSWORD_FAIL:
    sbic pinc,1
	rjmp main
	sbic pinc,2
	rjmp PASSWORD_SUCCESS
    
    cbi PORTB, SUCCESS_LED
    sbi PORTB, FAIL_LED
	dec r19

    out portc,r19  ;;
    cpi r19, 2
    breq LED_twoon
    cpi r19, 1
    breq LED_oneon
	cpi r19,0
	breq LED_zeroon
	ldi r28, 0
    rjmp gnd_rows

    
	
;---------------------------------------------------------------
; LED Control
;---------------------------------------------------------------
LED_threeon:
    sbi PORTB, LED2
    sbi PORTB, LED3
    rjmp gnd_rows

LED_twoon:
    cbi PORTB, LED2
    sbi PORTB, LED3
    rjmp gnd_rows

LED_oneon:
    sbi PORTB, LED2
    cbi PORTB, LED3
    rjmp gnd_rows

LED_zeroon:
    cbi PORTB, LED2
    cbi PORTB, LED3
    rjmp gnd_rows







;---------------------------------------------------------------
; Delay Subroutine for 16 MHz
;---------------------------------------------------------------
my_delay:
    ldi r21, 20    ; Outer loop counter (same)
delay_outer:
    ldi r22, 50    ; Middle loop counter (same)
delay_inner:
    ldi r23, 80    ; Increased from 5 to 80 (scaled by ~16)
delay_loop:
    dec r23
    brne delay_loop
    dec r22
    brne delay_inner
    dec r21
    brne delay_outer
    ret
