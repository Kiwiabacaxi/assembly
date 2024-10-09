;  Montar um programa direcionado para o módulo McLab2 que controle a temperatura da resistência. O potenciômetro é a referência de ajuste de temperatura e o sensor de temperatura indica a temperatura da resistência. Use o conversor com resolução de 8 bits.
; Os botões S1, S2, S3 e S4 têm as seguintes funções:
;     S1 (RB0) - inicia o processo de aquecimento.
;     S2 (RB1) - para o processo de aquecimento.
;     S3 (RB2) - mostra o valor do potenciômetro
;     S4 (RB3) - mostra o valor do sensor de temperatura
; O clock do PIC deve ser de 4MHz.
; Saídas:
; RC2: HEATER (aquecedor/resistência)
; O tipo de controle a ser usado é do tipo ON-OFF (liga-desliga).
; O display de 7 segmentos deve mostrar:
;     O valor lido do potenciômetro (SP - SET-POINT - valor desejado - 0 a 255) ou
;     O valor lido do sensor de temperatura (PV - VARIÁVEL DO PROCESSO - 0 a 255).
;     A seleção é feita através dos botões S3 e S4.
; Quando iniciar o programa, o processo deve começar desligado e, por consequência a resistência também.
; O valor do potenciômetro deve, inicialmente, ser apresentado nos displays de 7 segmentos.
; Os displays devem ser varridos em 4ms, o que significa que cada display fica aceso a cada 1ms.
; As entradas analógicas devem lidas a cada 250ms, justificadas à esquerda e o valor trabalhado pelo programa deve ser de 8 bits.
; O controle ON-OFF consiste em ligar ou desligar a resistência em função da diferença da temperatura desejada e com a medida. Quando o processo for ativado, se a PV for menor que o SP a resistência deve ser ligada até que o valor da PV seja maior que o SP, então a resistência deve ser desligada, voltando a religar se a PV ficar menor que o SP.  
; O valores numéricos mostrados no enunciado referem-se ao valores lidos do conversor AD, seja da entrada analógica do potenciômetro como do sensor de temperatura.
; Quando o processo for desligado a resistência permanece desligada.
; -----------------------// Prova de Microcontroladores //-----------------------
; @ Carlos Alexandre Sousa Silva
; RA = 134 205 286 20 2
; -----------------------// Config Bit //-----------------------
; PIC16F877A Configuration Bit Settings
; Assembly source line config statements
#include "p16f877a.inc"
; CONFIG
; __config 0xFF32
 __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

; Definição de Bancos
#define BANK0   BCF STATUS,RP0
#define BANK1   BSF STATUS,RP0 
 
 ; -----------------------// Código Principal //-----------------------
    
CBLOCK  0x20
    UNIDADE
    DEZENA
    CENTENA
    CONTADOR
    FLAGS
    VALOR_ADC
    VALOR_SP     ; Armazena o valor do Set Point (potenciômetro)
    VALOR_PV     ; Armazena o valor do Process Variable (sensor)
    PROCESS_VAR
    W_TEMP
    S_TEMP
ENDC
    
;variáveis
#define FIM_250MS       FLAGS,0
#define TROCA_DISPLAY   FLAGS,1
#define MODO_MANUAL     FLAGS,2 ; seraq era isso aaaa
#define PROCESSO_ATIVO  FLAGS,3

;entradas
#define B_INICIA    PORTB,0  ; S1 - inicia o processo de aquecimento
#define B_PARA      PORTB,1  ; S2 - para o processo de aquecimento
#define B_SP        PORTB,2  ; S3 - mostra o valor do potenciômetro
#define B_PV        PORTB,3  ; S4 - mostra o valor do sensor de temperatura

;saídas
#define DISPLAY     PORTD
#define D_UNIDADE   PORTB,4    
#define D_DEZENA    PORTB,5  
#define D_CENTENA   PORTB,6  
#define HEATER      PORTC,2
    
;constantes
V_TMR0      equ     .131    ; Valor para gerar interrupção a cada 1ms
    
RES_VECT  CODE    0x0000
    GOTO    START

INT_VECT  CODE    0x0004
    ; Salva contexto
    MOVWF   W_TEMP
    MOVF    STATUS,W
    MOVWF   S_TEMP
    
    ; Verifica se é interrupção do Timer0
    BTFSS   INTCON,T0IF
    GOTO    SAI_INTERRUPCAO
    BCF     INTCON,T0IF
    MOVLW   V_TMR0
    ADDWF   TMR0,F
    BSF     TROCA_DISPLAY
    
    ; Contagem para 250ms
    DECFSZ  CONTADOR,F
    GOTO    SAI_INTERRUPCAO
    BSF     FIM_250MS
    MOVLW   .62
    MOVWF   CONTADOR
    
SAI_INTERRUPCAO
    ; Restaura contexto
    MOVF    S_TEMP,W
    MOVWF   STATUS
    MOVF    W_TEMP,W
    RETFIE

START
    ; Configuração inicial
    BANK1
    CLRF    TRISD           ; PORTD como saída (display)
    MOVLW   B'00001111'     ; RB0-RB3 como entrada, RB4-RB7 como saída
    MOVWF   TRISB
    BCF     TRISC,2         ; RC2 como saída (HEATER)
    MOVLW   B'11010010'     ; Configuração do Timer0
    MOVWF   OPTION_REG
    MOVLW   B'01000100'     ; Configuração do ADC
    MOVWF   ADCON1
    BANK0
    MOVLW   B'11001001'     ; Liga ADC
    MOVWF   ADCON0
    CLRF    FLAGS
    MOVLW   .62
    MOVWF   CONTADOR
    BSF     MODO_MANUAL     ; Inicia mostrando o setpoint
    BCF     PROCESSO_ATIVO  ; Processo inicialmente desligado
    BSF     INTCON,T0IE     ; Habilita interrupção do Timer0
    BSF     INTCON,GIE      ; Habilita interrupções globais
    
LACO_PRINCIPAL
    BTFSC   TROCA_DISPLAY
    CALL    ATUALIZA_DISPLAY
    BTFSS   FIM_250MS
    GOTO    LACO_PRINCIPAL
    BCF     FIM_250MS
    CALL    LER_ADC
    CALL    VERIFICA_BOTOES
    BTFSC   PROCESSO_ATIVO
    CALL    CONTROLE_TEMPERATURA
    BTFSS   PROCESSO_ATIVO
    BCF     HEATER
    BTFSC   MODO_MANUAL
    GOTO    MOSTRAR_SP
    GOTO    MOSTRAR_PV
    
LER_ADC
    CALL    LER_POTENCIOMETRO
    CALL    LER_TEMPERATURA
    RETURN

LER_POTENCIOMETRO
    MOVLW   B'11001001'     ; Seleciona canal 0 (AN0)
    MOVWF   ADCON0
    BSF     ADCON0,GO_DONE
    BTFSC   ADCON0,GO_DONE
    GOTO    $-1
    MOVF    ADRESH,W
    MOVWF   VALOR_SP
    RETURN

LER_TEMPERATURA
    MOVLW   B'11000001'     ; Seleciona canal 1 (AN1)
    MOVWF   ADCON0
    BSF     ADCON0,GO_DONE
    BTFSC   ADCON0,GO_DONE
    GOTO    $-1
    MOVF    ADRESH,W
    MOVWF   VALOR_PV
    RETURN

VERIFICA_BOTOES
    BTFSS   B_INICIA
    CALL    INICIA_PROCESSO
    BTFSS   B_PARA
    CALL    PARA_PROCESSO
    BTFSS   B_SP
    CALL    MOSTRA_SETPOINT
    BTFSS   B_PV
    CALL    MOSTRA_PROCESSO
    RETURN

INICIA_PROCESSO
    BSF     PROCESSO_ATIVO
    RETURN

PARA_PROCESSO
    BCF     PROCESSO_ATIVO
    BCF     HEATER
    RETURN

MOSTRA_SETPOINT
    BSF     MODO_MANUAL
    RETURN

MOSTRA_PROCESSO
    BCF     MODO_MANUAL
    RETURN

CONTROLE_TEMPERATURA
    ; Implementa o controle ON-OFF
    MOVF    VALOR_SP,W
    MOVWF   PROCESS_VAR
    MOVF    VALOR_PV,W
    SUBWF   PROCESS_VAR,W
    BTFSC   STATUS,C    ; Se SP >= PV
    BSF     HEATER      ; Liga o aquecedor
    BTFSS   STATUS,C    ; Se SP < PV
    BCF     HEATER      ; Desliga o aquecedor
    RETURN

MOSTRAR_SP
    MOVF    VALOR_SP,W
    MOVWF   VALOR_ADC
    GOTO    CONVERTE_BCD

MOSTRAR_PV
    MOVF    VALOR_PV,W
    MOVWF   VALOR_ADC
    GOTO    CONVERTE_BCD

CONVERTE_BCD
    CLRF    UNIDADE
    CLRF    DEZENA
    CLRF    CENTENA
    GOTO    VERIFICA_CENTENA

VERIFICA_CENTENA
    MOVLW   .100
    SUBWF   VALOR_ADC,W
    BTFSS   STATUS,C
    GOTO    VERIFICA_DEZENA
    INCF    CENTENA,F
    MOVWF   VALOR_ADC
    GOTO    VERIFICA_CENTENA
    
VERIFICA_DEZENA
    MOVLW   .10
    SUBWF   VALOR_ADC,W
    BTFSS   STATUS,C
    GOTO    VERIFICA_UNIDADE
    INCF    DEZENA,F
    MOVWF   VALOR_ADC
    GOTO    VERIFICA_DEZENA
    
VERIFICA_UNIDADE
    MOVF    VALOR_ADC,W
    MOVWF   UNIDADE
    GOTO    LACO_PRINCIPAL
    
ATUALIZA_DISPLAY
    ; Rotina de multiplexação do display
    BCF     TROCA_DISPLAY
    BTFSS   D_UNIDADE
    GOTO    TESTA_DEZENA
    BCF     D_UNIDADE
    MOVF    DEZENA,W
    CALL    BUSCA_CODIGO
    MOVWF   DISPLAY
    BSF     D_DEZENA
    RETURN
    
TESTA_DEZENA
    BTFSS   D_DEZENA
    GOTO    TESTA_CENTENA
    BCF     D_DEZENA
    MOVF    CENTENA,W
    CALL    BUSCA_CODIGO
    MOVWF   DISPLAY
    BSF     D_CENTENA
    RETURN
    
TESTA_CENTENA
    BCF     D_CENTENA
    MOVF    UNIDADE,W
    CALL    BUSCA_CODIGO
    MOVWF   DISPLAY
    BSF     D_UNIDADE
    RETURN
    
BUSCA_CODIGO
    ; Tabela de conversão para display de 7 segmentos
    ADDWF   PCL,F
    RETLW   0x3F    ; 0
    RETLW   0x06    ; 1
    RETLW   0x5B    ; 2
    RETLW   0x4F    ; 3
    RETLW   0x66    ; 4
    RETLW   0x6D    ; 5
    RETLW   0x7D    ; 6
    RETLW   0x07    ; 7
    RETLW   0x7F    ; 8
    RETLW   0x6F    ; 9
    
    END