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

; DEFINIR BOTÕES
#define BOTAO_INICIO PORTA, 1
#define BOTAO_PARAR PORTA, 2

; DEFINIR V_TEMPO1 E V_TEMPO2
V_TEMPO1 equ .250
V_TEMPO2 equ .250

CBLOCK 0X20 
    TEMPO1
    TEMPO2
    ESTADO_PISCA
ENDC

RES_VECT  CODE    0x0000            ; processor reset vector
    BANK1
    BCF	    TRISA, 0               ; Configura RA0 como saída (LAMPADA)
    BSF     TRISA, 1               ; Configura RA1 como entrada (BOTAO_INICIO)
    BSF     TRISA, 2               ; Configura RA2 como entrada (BOTAO_PARAR)
    BANK0

LACO_PRINCIPAL
    BTFSC BOTAO_INICIO             ; Verifica se o botão de início foi pressionado
    CALL INICIAR_PISCA

    BTFSC BOTAO_PARAR              ; Verifica se o botão de parar foi pressionado
    CALL PARAR_PISCA

    MOVF ESTADO_PISCA, W
    BTFSC STATUS, Z                ; Verifica se ESTADO_PISCA é zero
    GOTO LACO_PRINCIPAL            ; Se for zero, continua no loop principal

    BSF LAMPADA
    CALL ESPERAR_500MS
    BCF LAMPADA
    CALL ESPERAR_500MS
    GOTO LACO_PRINCIPAL

INICIAR_PISCA
    MOVLW 0x01
    MOVWF ESTADO_PISCA
    RETURN

PARAR_PISCA
    CLRF ESTADO_PISCA
    RETURN

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
    GOTO DEC_TEMPO2		        ; se não zerou, pula para DEC_TEMPO2

DEC_TEMPO1
    DECFSZ TEMPO1, F		        ; decrementa TEMPO1
    GOTO INICIALIZA_TEMPO2		    ; se não zerou, pula para INICIALIZA_TEMPO2

    RETURN

    END