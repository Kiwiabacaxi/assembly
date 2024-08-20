; PISCA PISCA
; PIC16F628A Configuration Bit Settings

; Assembly source line config statements

#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define BANK0	BCF STATUS, RP0
#define BANK1	BSF STATUS, RP0

; DEFINIR LAMPADA
#define LAMPADA PORTA, 0

; DEFINIR V_TEMPO1 E V_TEMPO2
V_TEMPO1 equ .250
V_TEMPO2 equ .250


CBLOCK 0X20 
	TEMPO1
	TEMPO2
ENDC
    


RES_VECT  CODE    0x0000            ; processor reset vector
    BANK1
    BCF	    TRISA, 0
    BANK0

LACO_PRINCIPAL
    BSF LAMPADA
    CALL ESPERAR_500MS
    BCF LAMPADA
    CALL ESPERAR_500MS
    GOTO LACO_PRINCIPAL

ESPERAR_500MS
    MOVLW V_TEMPO1		            ; W = V_TEMPO1
    MOVWF TEMPO1		            ; TEMPO1 = W

INICIALIZA_TEMPO2
    MOVLW V_TEMPO2		            ; W = V_TEMPO2
    MOVWF TEMPO2		            ; TEMPO2 = W

DEC_TEMPO2
    NOP
    NOP
    DECFSZ TEMPO2, F		        ; decrementa TEMPO2
    GOTO DEC_TEMPO2		            ; se não zerou, pula para DEC_TEMPO2

DEC_TEMPO1
    DECFSZ TEMPO1, F		        ; decrementa TEMPO1
    GOTO INICIALIZA_TEMPO2		            ; se não zerou, pula para DEC_TEMPO1

    RETURN

    END