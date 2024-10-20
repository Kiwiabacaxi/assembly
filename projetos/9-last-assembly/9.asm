; PIC16F877A Configuration Bit Settings
#include "p16f877a.inc"

; CONFIG
 __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

#define BANK0   BCF STATUS,RP0
#define BANK1   BSF STATUS,RP0 

    CBLOCK  0x20
        FLAGS
        CONTADOR
    ENDC
    
; Flags
#define FIM_250MS   FLAGS,0
#define TROCA_DISPLAY   FLAGS,1

; Constantes
V_TMR0      equ     .131    ; Para 4ms com prescaler 1:32

    ORG     0x0000
    GOTO    START

    ORG     0x0004
    GOTO    ISR

START
    BANK1
    MOVLW   B'00001111'     ; RB0-RB3 como entradas, RB4-RB7 como saídas
    MOVWF   TRISB
    CLRF    TRISD           ; PORTD como saída (display)
    BCF     TRISC,2         ; RC2 como saída (HEATER)
    
    MOVLW   B'11010100'     ; Configuração do TIMER0: prescaler 1:32
    MOVWF   OPTION_REG
    
    BANK0
    CLRF    FLAGS
    MOVLW   .63             ; Para 250ms (63 * 4ms = 252ms)
    MOVWF   CONTADOR
    
    BSF     INTCON,GIE      ; Habilita interrupções globais
    BSF     INTCON,T0IE     ; Habilita interrupção do Timer0

MAIN_LOOP
    ; Aqui iremos adicionar a lógica principal posteriormente
    GOTO    MAIN_LOOP

ISR
    BCF     INTCON,T0IF     ; Limpa a flag de interrupção do Timer0
    MOVLW   V_TMR0
    ADDWF   TMR0,F          ; Reinicia o Timer0
    
    BSF     TROCA_DISPLAY   ; Sinaliza para trocar o display
    
    DECFSZ  CONTADOR,F      ; Decrementa o contador
    GOTO    END_ISR
    
    BSF     FIM_250MS       ; Sinaliza que passaram 250ms
    MOVLW   .63
    MOVWF   CONTADOR        ; Reinicia o contador

END_ISR
    RETFIE

    END