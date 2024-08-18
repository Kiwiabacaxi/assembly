; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

; PIC16F628A Configuration Bit Settings

; Assembly source line config statements

#include "p16f628a.inc"

; CONFIG
; __config 0x3F70
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF


; MATHEUS CALEGARI MOIZINHO - 14/08/2024


#define BANK0	BCF STATUS,RP0
#define BANK1	BSF STATUS,RP0

CBLOCK 0X20
    FILTRO
    UNIDADE
    FLAGS
ENDC

; variáveis
#define JA_LI	FLAGS,0

; entradas
#define B_UP	PORTA,1
#define B_ZERAR	PORTA,2

; saídas
#define DISPLAY PORTB

; constantes
V_FILTRO	equ .100


RES_VECT  CODE    0x0000            ; processor reset vector
    
    BANK1			    ; seleciona banco 1 da memória
    CLRF    TRISB		    ; configura PORTB como saída
    BANK0			    ; seleciona banco 0 da memória
    
    MOVLW   V_FILTRO		    ; W = V_FILTRO (100)
    MOVWF   FILTRO		    ; FILTRO = W
    
    BCF	    JA_LI		    ; JA_LI = 0
    CLRF    UNIDADE		    ; UNIDADE = 0
    
    CALL    ATUALIZA_DISPLAY	    ; chama subrotina ATUALIZA_DISPLAY

    
LACO_PRINCIPAL
    
    BTFSS   B_ZERAR		    ; verifica B_ZERAR
    GOTO    B_ZERAR_ACIONADO	    ; se acionado, pula para B_ZERAR_ACIONADO
    
    BTFSC   B_UP		    ; verifica B_UP
    GOTO    B_UP_N_ACIONADO	    ; se não acionado, pula para B_UP_N_ACIONADO

    BTFSC   JA_LI		    ; verifica JA_LI
    GOTO    LACO_PRINCIPAL	    ; se JA_LI = 1, pula para LACO_PRINCIPAL
    
    DECFSZ  FILTRO,F		    ; decrementa FILTRO e verifica se zerou
    GOTO    LACO_PRINCIPAL	    ; se não zerou, pula para LACO_PRINCIPAL
    
    BSF	    JA_LI		    ; JA_LI = 1
    INCF    UNIDADE,F		    ; UNIDADE++
    
    MOVLW   .10			    ; W = 10
    SUBWF   UNIDADE,W		    ; W = UNIDADE - W
    
    BTFSC   STATUS,C		    ; testa resultado negativo
    CLRF    UNIDADE		    ; UNIDADE = 0
    
    CALL    ATUALIZA_DISPLAY	    ; chama subrotina ATUALIZA_DISPLAY
    
    GOTO    LACO_PRINCIPAL	    ; volta para início
    

B_ZERAR_ACIONADO
    
    CLRF    UNIDADE		    ; zera UNIDADE
    CALL    ATUALIZA_DISPLAY	    ; chama subrotina ATUALIZA_DISPLAY
    
    GOTO    LACO_PRINCIPAL	    ; pula para LACO_PRINCIPAL
    
    
B_UP_N_ACIONADO
    
    MOVLW   V_FILTRO		    ; W = V_FILTRO (100)
    MOVWF   FILTRO		    ; FILTRO = W
    
    BCF	    JA_LI		    ; JA_LI = 0
    
    GOTO    LACO_PRINCIPAL	    ; pula para LACO_PRINCIPAL
   
    
ATUALIZA_DISPLAY
    
    MOVF    UNIDADE,W		    ; W = UNIDADE
    
    CALL    BUSCA_CODIGO	    ; chama subrotina BUSCAR_CODIGO
    
    MOVWF   DISPLAY		    ; DISPLAY = W (PORTB = W)
    
    RETURN			    ; retorna de uma subrotina
    

BUSCA_CODIGO
    
    ADDWF   PCL,F		    ; PCL = PCL + W
    
    RETLW   0xFE		    ; retorna da subrotina com W = 0xFE
    RETLW   0x38		    ; retorna da subrotina com W = 0x38
    RETLW   0xDD		    ; retorna da subrotina com W = 0xDD
    RETLW   0x7D	    	    ; retorna da subrotina com W = 0x7D
    RETLW   0x3B		    ; retorna da subrotina com W = 0x3B
    RETLW   0x77		    ; retorna da subrotina com W = 0x77
    RETLW   0xF7		    ; retorna da subrotina com W = 0xF7
    RETLW   0x3C		    ; retorna da subrotina com W = 0x3C
    RETLW   0xFF		    ; retorna da subrotina com W = 0xFF
    RETLW   0x7F		    ; retorna da subrotina com W = 0x7F
    
    END