
; PIC16F877A Configuration Bit Settings

; Assembly source line config statements

#include "p16f877a.inc"

; CONFIG
; __config 0xFF71
 __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF



#define	BANK0	BCF STATUS,RP0
#define	BANK1	BSF STATUS,RP0 
 
    CBLOCK  0x20
	UNIDADE
	DEZENA
	FILTRO
	FLAGS
	W_TEMP
	S_TEMP
    ENDC
    
;variaeis
#define	CONTEI		FLAGS,0
#define	TROCA_DISPLAY	FLAGS,1

;entradas
#define	B_UP		PORTA,1
#define	B_RESET		PORTA,2

;saidas
#define	DISPLAY		PORTB
#define	D_UNIDADE    PORTB,4
#define	D_DEZENA     PORTB,5
#define	D_CENTENA    PORTB,6
#define	D_MILHAR     PORTB,7
    
;constantes
V_TMR0	    equ		.131
V_FILTRO    equ		.100	
	
RES_VECT  CODE    0x0000    ;vetor de reset,define deve estar a 1� instru��o do programa
    GOTO    START           ;pula a �rea de armazenamento de interrup��o

INT_VECT  CODE    0x0004    ;vetor de interrup��o, define deve estar a 1� instru��o da interrup��o
    MOVWF   W_TEMP	    ;salvar W em W_TEMP
    MOVF    STATUS,W	    ;W = STATUS
    MOVWF   S_TEMP	    ;salvar STATUS em S_TEMP
    BTFSS   INTCON,T0IF	    ;testa se a interrup��o foi por TIMER0
    GOTO    SAI_INTERRUPCAO ;se n�o foi, pula para SAI_INTERRUPCAO
    BCF	    INTCON,T0IF	    ;limpa o bit de indica��o de interrup��o por TIMER0
    MOVLW   V_TMR0	    ;W = V_TMR0 -> W = 131
    ADDWF   TMR0,F	    ;TMR0 = TMR0 + V_TMR0 -> TMR0 = TMR0 + 131
    BSF	    TROCA_DISPLAY   ;TROCA_DISPLAY = 1
SAI_INTERRUPCAO
    MOVF    S_TEMP,W	    ;W = S_TEMP
    MOVWF   STATUS	    ;restaura STATUS
    MOVF    W_TEMP,W	    ;restaura W
    RETFIE

START
    BANK1
    CLRF    TRISD	    ;configura todo o PORTB como sa�da
    MOVLW   B'00001111' ;OS RB0, RB1, RB2 e RB3 sao entradas E OS RB4, RB5, RB6 e RB7 sao saidas
    CLRF    TRISB	    ;configura todo o PORTB como sa�da
    MOVLW   B'11010100'


    MOVWF   OPTION_REG	    ;carrega a configura��o do TIMER0
    BANK0
    CLRF    UNIDADE	    ;UNIDADE = 0
    CLRF    DEZENA	    ;DEZENA = 0
    MOVLW   V_FILTRO	    ;W = V_FILTRO
    MOVWF   FILTRO	    ;FILTRO = V_FILTRO
    CLRF    FLAGS	    ;FLAGS = 0
    BSF	    INTCON,T0IE	    ;habilita o atendimento de interrp��o por TIMER0
    BSF	    INTCON,GIE	    ;habilita o atendimento de interrup��es
LACO_PRINCIPAL
    BTFSC   TROCA_DISPLAY	;testa se j� passou 4ms
    CALL    ATUALIZA_DISPLAY	;se j� passou 4ms,chama a subrotina ATUALIZA_DISPLAY
    BTFSS   B_RESET		;testa se B_RESET est� acionado
    GOTO    B_RESET_ACIONADO	;se acionado, pula para B_RESET_ACIONADO
    BTFSC   B_UP		;testa se B_UP est� acionado
    GOTO    B_UP_NAO_ACIONADO	;se n�o acionado, pula para B_UP_NAO_ACIONADO
    BTFSC   CONTEI		;testa se CONTEI = 0
    GOTO    LACO_PRINCIPAL	;se CONTEI = 1, pula para LACO_PRINCIPAL
    DECFSZ  FILTRO,F		;decrementa FILTRO e testa se zerou
    GOTO    LACO_PRINCIPAL	;se n�o zerou, pula para LACO_PRINCIPAL
    BSF	    CONTEI		;CONTEI = 1
    INCF    UNIDADE,F		;UNIDADE++
    MOVLW   .10			;W = 10
    SUBWF   UNIDADE,W		;W = UNIDADE - W
    BTFSS   STATUS,C		;testa se o resultado � negativo (UNIDADE < 10)
    GOTO    LACO_PRINCIPAL	;se negativo, pula para LACO_PRINCIPAL
    CLRF    UNIDADE		;UNIDADE = 0
    INCF    DEZENA,F		;DEZENA++
    MOVLW   .10			;W = 10
    SUBWF   DEZENA,W		;W = DEZENA - W
    BTFSC   STATUS,C		;testa se o resultado � negativo (DEZENA < 10)
    CLRF    DEZENA		;se positivo (DEZENA >= 10), DEZENA = 0
    GOTO    LACO_PRINCIPAL	;pula para LACO_PRINCIPAL
B_RESET_ACIONADO
    CLRF    UNIDADE		;UNIDADE = 0
    CLRF    DEZENA		;DEZENA = 0    
    GOTO    LACO_PRINCIPAL	;pula para LACO_PRINCIPAL
B_UP_NAO_ACIONADO
    MOVLW   V_FILTRO		;W = V_FILTRO
    MOVWF   FILTRO		;FILTRO = V_FILTRO
    BCF	    CONTEI		;CONTEI = 0    
    GOTO    LACO_PRINCIPAL	;pula para LACO_PRINCIPAL
    
ATUALIZA_DISPLAY
    BCF	    TROCA_DISPLAY	;TROCA_DISPLAY = 0
    BTFSS   D_UNIDADE	;testa se D_UNIDADE = 1
    GOTO    ACENDE_UNIDADE	;se QUAL_DISPLAY = 0, pula para ACENDE_UNIDADE
    BCF     D_UNIDADE		;D_UNIDADE = 0
    MOVF    DEZENA,W		;W = DEZENA
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o c�digo de 7 segmentos

    MOVWF   DISPLAY		    ;DISPLAY = W -> PORTB = W
    BSF     D_DEZENA		;D_DEZENA = 1
    RETURN			        ;volta para o programa principal


ACENDE_UNIDADE
    BCF     D_DEZENA		;D_DEZENA = 0
    MOVF    UNIDADE,W		;W = UNIDADE
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o c�digo de 7 segmentos
    MOVWF   DISPLAY		;DISPLAY = W -> PORTB = W
    BSF    D_UNIDADE		;D_UNIDADE = 1
    RETURN			;volta para o programa principal

BUSCA_CODIGO
    ADDWF   PCL,F		;PCL = PCL + W
    RETLW   0x3F		;retorna da subrotina com W = 0xFE
    RETLW   0x06		;retorna da subrotina com W = 0x38    
    RETLW   0x5B		;retorna da subrotina com W = 0xDD    
    RETLW   0x4F		;retorna da subrotina com W = 0x7D
    RETLW   0x66		;retorna da subrotina com W = 0x3B
    RETLW   0x6D		;retorna da subrotina com W = 0x77    
    RETLW   0x7D		;retorna da subrotina com W = 0xF7    
    RETLW   0x07		;retorna da subrotina com W = 0x3C    
    RETLW   0x7F		;retorna da subrotina com W = 0xFF
    RETLW   0x6F		;retorna da subrotina com W = 0x7F    
    
    
    
    
    END