; Um engenheiro foi contratado para automatizar um sistema de partida Estrela Triângulo. Para isso usou o módulo McLab1 para simular a operação do programa de controle.
; A partida estrela triângulo é usada para reduzir a corrente de partida dos motores assíncronos trifásicos. O processo consiste em usar 3 contatores (relés trifásicos de potência) para alimentar e alterar as ligações da bobina do motor trifásico. O contator principal alimenta o motor, o contator estrela faz a ligação no formato estrela e o contator triângulo muda a ligação para formato triângulo ou delta.
; Na ligação estrela a corrente é menor pois as bobinas são ligadas em série e na ligação triângulo a corrente é maior pois as bobinas estão em paralelo. Na realidade, o motor é feito para trabalhar com ligação triângulo, a ligação estrela (série) é usada apenas para reduzir a corrente de partida, como o torque cai nesta situação é necessário voltar a ligação normal (triângulo) após um período de tempo após a partida.
; Abaixo tem as entradas e saídas definidas no módulo para o funcionamento do sistema de controle de partida:
; Entradas:
; - RA3- Botão LIGA - liga o motor
; - RA4 - Botão DESLIGA - desliga o motor em qualquer situação - este botão tem prioridade sobre o botão LIGA, ou seja, se ele estiver ativo o "LIGA" não é lido.
; Saídas:
; - RA0 - acionamento do contator principal, responsável pelo alimentação elétrica do motor.
; - RA1 - acionamento do contator da ligação estrela, responsável pela conexão série das bobinas do motor.
; - RA2 - acionamento do contator da ligação triângulo, responsável pela conexão paralela das bobinas do motor..
; - RB7...RB0 - Display de 7 segmentos, indicador de fase do processo
; Funcionamento:
; - ao energizar, nenhum acionamento do motor deve estar ativo, somente a indicação de motor desligado, que será feita no display de 7 segmentos através no número "0" (zero).
; - se o botão LIGA (RA3) for acionado, as saídas dos contatores principal (RA0) e estrela (RA1) devem ser ativados, e o display de 7 segmentos deve mostrar "1" (um) indicando que a ligação é estrela. Também deve-se iniciar a temporização para a mudança de estrela para triângulo. O cálculo do tempo é dado abaixo.
; - ao terminar a temporização, o contator estrela (RA1) é desligado e o triângulo (RA2) ligado e o display deve mostrar "2" (dois) indicando que a ligação é triângulo.
; - o botão DESLIGA (RA4) tem ação imediata, independe do momento que o sistema está operando, se ele for pressionado, a saída principal (RA0), a estrela (RA1) ou a triângulo (RA2) devem ser desligados e o display deve voltar a mostrar "0" (zero).

; -----------------------// Prova de Microcontroladores //-----------------------
; @ Carlos Alexandre Sousa Silva
; -----------------------// Cálculo do intervalo de tempo //-----------------------
; Cálculo do intervalo de tempo para mudança de estrela para triângulo:
; A temporização deve ser o seu TIMER0, para determinar o tempo, use o seu RA e sua data de nascimento,
; some todos os algarismos e multiplique resultado por 150. Informe o valor encontrado na área de texto da prova.
; RA = 134 205 286 20 2
; Data 26 09 1999
; 1+3+4+2+0+5+2+8+6+2+0+ 2 + 2+6+0+9+1+9+9+9 = 80
; 80 * 150 = 12000 -> = 12s ou 12000ms
    
; prescaler 1:256
; 12_000_000 / 65536 ~= 183

; -----------------------// Config Bit //-----------------------
; PIC16F628A Configuration Bit Settings
; Assembly source line config statements
#include "p16f628a.inc"
; CONFIG
; __config 0xFF70
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

; -----------------------// Código Principal //-----------------------

; Definição de Bancos
#define BANK0   BCF STATUS,RP0
#define BANK1   BSF STATUS,RP0    

; Variáveis
CBLOCK  0x20
    FLAGS
    FILTRO
    DISPLAY_VALOR
    TMR_CONTADOR
    S_TEMP
    W_TEMP
ENDC

; Definição de Flags
#define JA_LI   FLAGS,0
#define LIGADO  FLAGS,1

; Entradas
#define BOTAO_LIGA      PORTA,3
#define BOTAO_DESLIGA   PORTA,4

; Saídas
#define CONTATOR_PRINC  PORTA,0
#define CONTATOR_ESTRELA PORTA,1
#define CONTATOR_TRIANG PORTA,2
#define DISPLAY     PORTB

; Constantes
V_FILTRO    equ .100
V_TMR0      equ .0
TEMPO_MAX   equ .183    ; Valor calculado para 12 segundos

; Vetores de Interrupção e Reset
    org 0x0000
    goto    inicio

    org 0x0004
    goto    interrupcao

; Código principal
MAIN_PROG CODE

inicio
    ; Configuração dos ports
    BANK1
    MOVLW   B'00011000'     ; RA3 e RA4 como entradas, resto como saídas
    MOVWF   TRISA
    MOVLW   B'00000111'     ; Configuração do TIMER0: prescaler 1:256
    MOVWF   OPTION_REG

    CLRF    TRISB           ; PORTB como saída (display)
    BANK0
    
    MOVLW   V_FILTRO
    MOVWF   FILTRO
    
    BCF     JA_LI
    BCF     LIGADO
    
    CLRF    DISPLAY_VALOR
    BCF     CONTATOR_PRINC
    BCF     CONTATOR_ESTRELA
    BCF     CONTATOR_TRIANG
    
    CALL    atualiza_display
    CLRF    TMR_CONTADOR
    
    MOVLW   B'10100000'     ; Habilita interrupção global e do Timer0
    MOVWF   INTCON

    GOTO    loop_principal

loop_principal
    BTFSS   BOTAO_DESLIGA   ; Verifica se o botão DESLIGA está pressionado
    GOTO    desligar        ; Se estiver, desliga o sistema
    
    BTFSS   BOTAO_LIGA      ; Verifica se o botão LIGA está pressionado
    CALL    verificar_ligar ; Se estiver, verifica se deve ligar
    
    GOTO    loop_principal

desligar
    BCF     CONTATOR_PRINC
    BCF     CONTATOR_ESTRELA
    BCF     CONTATOR_TRIANG
    CLRF    DISPLAY_VALOR
    CALL    atualiza_display
    BCF     LIGADO
    BCF     INTCON,T0IE     ; Desabilita interrupção por Timer0
    GOTO    inicio          ; Reinicia o sistema

verificar_ligar
    BTFSC   LIGADO          ; Se já está ligado, não faz nada
    RETURN
    
    BTFSC   JA_LI           ; Verifica se já foi lido
    RETURN                  ; Se já foi, retorna sem fazer nada
    
    DECFSZ  FILTRO,F        ; Decrementa o filtro de debounce
    RETURN                  ; Se não zerou, retorna
    
    GOTO    ligar_motor     ; Se zerou, liga o motor

ligar_motor
    BSF     JA_LI           ; Marca que foi lido
    BSF     LIGADO          ; Marca que está ligado
    
    MOVLW   .1
    MOVWF   DISPLAY_VALOR   ; Define o display para mostrar 1
    CALL    atualiza_display
    
    BSF     CONTATOR_PRINC  ; Liga o contator principal
    BSF     CONTATOR_ESTRELA ; Liga o contator estrela
    
    CLRF    TMR_CONTADOR    ; Zera o contador do timer
    BSF     INTCON,T0IE     ; Habilita interrupção por Timer0
    
    RETURN

interrupcao
    MOVWF   W_TEMP          ; Salva W
    MOVF    STATUS,W
    MOVWF   S_TEMP          ; Salva STATUS
    
    BTFSS   INTCON,T0IF     ; Verifica se é interrupção do Timer0
    GOTO    sai_interrupcao
    
    BCF     INTCON,T0IF     ; Limpa flag de interrupção
    MOVLW   V_TMR0
    ADDWF   TMR0,F          ; Ajusta o valor do TMR0

    INCF    TMR_CONTADOR,F  ; Incrementa o contador
    CALL    verifica_tempo  ; Verifica se atingiu o tempo máximo

sai_interrupcao
    MOVF    S_TEMP,W        ; Restaura STATUS
    MOVWF   STATUS
    SWAPF   W_TEMP,F
    SWAPF   W_TEMP,W        ; Restaura W
    RETFIE

verifica_tempo
    MOVLW   TEMPO_MAX
    SUBWF   TMR_CONTADOR,W
    BTFSS   STATUS,Z        ; Verifica se atingiu TEMPO_MAX
    RETURN
    
    BCF     INTCON,T0IE     ; Desabilita interrupção por Timer0
    BCF     CONTATOR_ESTRELA ; Desliga contator estrela
    BSF     CONTATOR_TRIANG ; Liga contator triângulo
    
    MOVLW   .2
    MOVWF   DISPLAY_VALOR   ; Define o display para mostrar 2
    CALL    atualiza_display
    
    RETURN

atualiza_display
    MOVF    DISPLAY_VALOR,W
    CALL    busca_codigo
    MOVWF   DISPLAY
    RETURN

; apenas os numeros que a gente usa
busca_codigo
    ADDWF   PCL,F
    RETLW   0xFE    ; Código para 0
    RETLW   0x38    ; Código para 1
    RETLW   0xDD    ; Código para 2

    END