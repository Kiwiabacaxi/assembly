
; PIC16F628A Configuration Bit Settings

; Assembly source line config statements

#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF


; Fazer um contador que conta apenas de 0 a 9 e reinicia

; Define bank
#define BANK0 BCF STATUS, RP0
#define BANK1 BSF STATUS, RP0

; usar o cblock
CBLOCK 0X20
    FILTRO
    UNIDADE
    FLAGS

    ENDC
    
; variáveis
#define JA_LI FLAGS, 0

; entradas
#define B_UP PORTA, 1
#define B_ZERAR PORTA, 2

; saídas
#define DISPLAY PORTB

; constantes
V_FILTRO EQU .100


; vetor de reset
RES_VECT  CODE    0x0000            ; processor reset vector
    BANK1 ; Seleciona banco 1
    CLRF TRISB ; Configura PORTB como saída
    BANK0 ; Volta para o banco 0

    MOVLW V_FILTRO ; W=100
    MOVWF FILTRO ; FILTRO = 100
    
    ; FAZER JA_LI = 0
    BCF JA_LI ; JA_LI = 0

    ; ZERAR UNIDADE
    CLRF UNIDADE ; UNIDADE = 0

    ; CHAMAR A FUNÇÃO ATUALIZA_DISPLAY
    CALL ATUALIZA_DISPLAY

LAÇO_PRINCIPAL
    ; BTFSC ELE "PULA" SE O BOTÃO ESTIVER ACIONADO
    BTFSC B_ZERAR ; testa se o B_ZERAR = 0 (acionado)
    GOTO B_ZERAR_ACIONADO ; se B_ZERAR = 1, pula para B_ZERAR_ACIONADO

    BTFSC B_UP ; testa se o B_UP = 0 (acionado)
    GOTO B_UP_N_ACIONADO ; se B_UP = 1, pula para B_UP_N_ACIONADO
    
    BTFSC JA_LI ; testa se o JA_LI = 0
    GOTO LAÇO_PRINCIPAL ; se JA_LI = 1, pula para o LAÇO_PRINCIPAL

    ; DECREMENTAR FILTRO
    DECFSZ FILTRO, F ; FILTRO--; testa/verifica se zerou
    GOTO LAÇO_PRINCIPAL ; se FILTRO != 0, pula para LAÇO_PRINCIPAL

    ; se FILTRO = 0
    BSF JA_LI ; JA_LI = 1
    INCF UNIDADE, F ; UNIDADE++

    ; se UNIDADE = 10
    MOVLW .10 ; W=10
    SUBWF UNIDADE, W ; W = W - UNIDADE
    BTFSC STATUS, C ; testa se W < 0
    CLRF UNIDADE ; UNIDADE = 0

    ; CHAMAR A FUNÇÃO ATUALIZA_DISPLAY
    CALL ATUALIZA_DISPLAY

    GOTO LAÇO_PRINCIPAL

B_ZERAR_ACIONADO
    ; ZERAR UNIDADE
    CLRF UNIDADE ; UNIDADE = 0

    ; CHAMAR A SUBROTINA ATUALIZA_DISPLAY
    CALL ATUALIZA_DISPLAY

    GOTO LAÇO_PRINCIPAL

B_UP_N_ACIONADO
    MOVLW V_FILTRO ; W=100
    MOVWF FILTRO ; FILTRO = 100

    BCF JA_LI ; JA_LI = 0

    GOTO LAÇO_PRINCIPAL

ATUALIZA_DISPLAY
    ; ATUALIZAR DISPLAY
    MOVF UNIDADE, W ; W = UNIDADE
    CALL BUSCA_CODIGO ; subrotina que busca o código do display
    MOVWF DISPLAY ; DISPLAY = W

    RETURN

BUSCA_CODIGO
    ; BUSCA CÓDIGO
    ADDWF PCL, F ; Salta para o estado atual
    RETLW 0xFE ; retorna a subrotina com w = 0xFE
    RETLW 0x38 ; retorna a subrotina com w = 0x38
    RETLW 0xDD ; retorna a subrotina com w = 0xDD
    RETLW 0x7D ; retorna a subrotina com w = 0x7D
    RETLW 0x3B ; retorna a subrotina com w = 0x3B
    RETLW 0x77 ; retorna a subrotina com w = 0x77
    RETLW 0xF7 ; retorna a subrotina com w = 0xF7
    RETLW 0x3C ; retorna a subrotina com w = 0x3C
    RETLW 0xFF ; retorna a subrotina com w = 0xFF
    RETLW 0x7F ; retorna a subrotina com w = 0x7F

    RETURN

    END