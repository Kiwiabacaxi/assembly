; CONTADOR UNIDADE E DEZENA
; PIC16F628A Configuration Bit Settings


#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

#define BANK0	BCF STATUS, RP0
#define BANK1	BSF STATUS, RP0

; CBLOC
    CBLOCK 0X20
        W_TEMP
        S_TEMP
        FLAGS
        FILTRO
        UNIDADE
        DEZENA
    ENDC

; variáveis
#define CONTEI    FLAGS,0
#define TROCA_DISPLAY FLAGS,1

; entradas
#define B_UP	PORTA,1
#define B_RESET	PORTA,2

; saídas
#define DISPLAY PORTB ; PORTB = DISPLAY
#define QUAL_DISPLAY PORTA,4 ; 0 = UNIDADE, 1 = DEZENA

; constantes
V_TMR0 EQU .131 ; 131 para 1ms
V_FILTRO EQU .100 ; 100 para 1ms

RES_VECT CODE 0x000
    GOTO START      ; Pula a area de armazenamento da interupção

INT_VECT CODE 0x004 ; Vetor de interrupção
    MOVWF W_TEMP   ; Salva o W em W_TEMP
    MOVF STATUS, W ; W = STATUS
    MOVWF S_TEMP ; Salva o STATUS em STATUS_TEMP

    BTFSS INTCON, T0IF ; Testa se a flag de interrupção do timer0 está setada
    GOTO SAI_INTERRUPCAO ; Se não estiver setada, pula para SAI_INTERRUPCAO
    BCF INTCON, T0IF ; Limpa a flag de interrupção do timer0

    MOVLW V_TMR0 ; W = V_TMR0
    ADDWF TMR0, F ; TMR0 = TMR0 + W
    BSF TROCA_DISPLAY ; TROCA_DISPLAY = 1

SAI_INTERRUPCAO
    MOVF S_TEMP, W ; W = STATUS_TEMP

    ; Restaura o STATUS
    MOVWF STATUS ; Restaura o STATUS
    MOVF W_TEMP, W ; Restaura o W

    RETFIE ; Retorna da interrupção


START
    ; Fazer minhas configurações
    BANK1 ; Seleciona banco 1
    CLRF TRISB ; Configura PORTB como saída
    MOVLW B'11010011' ; palavra de 8 bits de config
    MOVWF OPTION_REG ; Carrega a configuração no OPTION_REG

    BANK0 ; Seleciona banco 0

    CLRF UNIDADE ; Zera UNIDADE
    CLRF DEZENA ; Zera DEZENA
    MOVLW V_FILTRO ; W = V_FILTRO
    MOVWF FILTRO ; FILTRO = W
    CLRF FLAGS ; FLAGS = 0

    BSF INTCON, T0IE ; Habilita a interrupção do timer0
    BSF INTCON, GIE ; Habilita as interrupções

LACO_PRINCIPAL
    BTFSC TROCA_DISPLAY ; Testa se TROCA_DISPLAY = 0, SE JA PASSOU 4MS
    CALL ATUALIZA_DISPLAY ; Se ja passou 4ms, chama a função ATUALIZA_DISPLAY

    BTFSS B_RESET ; Testa se B_RESET = 0, se acionado
    GOTO B_RESET_ACIONADO ; Se acionado, pula para B_RESET_ACIONADO
     
    BTFSC B_UP ; Testa se B_UP = 0, se acionado
    GOTO B_UP_NAO_ACIONADO ; Se acionado, pula para B_UP_NAO_ACIONADO

    BTFSC CONTEI ; Testa se CONTEI = 0
    GOTO LACO_PRINCIPAL ; Se CONTEI = 1, pula para LACO_PRINCIPAL
    DECFSZ FILTRO, F ; FILTRO--; Decrementa e testa se zerou, se não zerou pula para LACO_PRINCIPAL
    GOTO LACO_PRINCIPAL

    BSF CONTEI ; CONTEI = 1
    INCF UNIDADE, F ; UNIDADE++, incrementa UNIDADE
    MOVLW .10 ; W = 10
    SUBWF UNIDADE, W ; W = UNIDADE - W
    BTFSS STATUS, C ; Testa se W < 0
    CLRF UNIDADE ; UNIDADE = 0
    GOTO LACO_PRINCIPAL ; Se W < 0, pula para LACO_PRINCIPAL

    CLRF UNIDADE ; Zera UNIDADE
    INCF DEZENA, F ; DEZENA++
    MOVLW .10 ; W = 10
    SUBWF DEZENA, W ; W = DEZENA - W
    BTFSC STATUS, C ; Testa se W < 0
    CLRF DEZENA ; DEZENA = 0
    GOTO LACO_PRINCIPAL ; Se W < 0, pula para LACO_PRINCIPAL

B_RESET_ACIONADO
    CLRF UNIDADE ; Zera UNIDADE
    CLRF DEZENA ; Zera DEZENA
    GOTO LACO_PRINCIPAL ; Pula para LACO_PRINCIPAL

B_UP_NAO_ACIONADO
    MOVLW V_FILTRO ; W = V_FILTRO
    MOVWF FILTRO ; FILTRO = W
    BCF CONTEI ; CONTEI = 0
    GOTO LACO_PRINCIPAL ; Pula para LACO_PRINCIPAL

ATUALIZA_DISPLAY
    BCF TROCA_DISPLAY ; TROCA_DISPLAY = 0
    BTFSC QUAL_DISPLAY ; Testa se QUAL_DISPLAY = 0
    GOTO ACENDE_UNIDADE ; Se QUAL_DISPLAY = 0, pula para ACENDE_UNIDADE
    MOVWF DEZENA,W ; W = DEZENA
    CALL BUSCA_CODIGO ; Chama a função BUSCA_CODIGO
    ANDLW B'11101111' ; W = W AND B'11101111'

ESCREVE_DISPLAY
    MOVWF DISPLAY ; DISPLAY = W
    RETURN

ACENDE_UNIDADE
    MOVF UNIDADE, W ; W = UNIDADE
    CALL BUSCA_CODIGO ; Chama a função BUSCA_CODIGO
    GOTO ESCREVE_DISPLAY ; Pula para ESCREVE_DISPLAY






    END