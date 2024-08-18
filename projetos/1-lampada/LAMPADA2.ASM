; Configurações do processador
    processor 16F628A
    include "p16f628a.inc"

; CONFIGURAÇÕES
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

; Definições de variáveis
    CBLOCK 0x20
    FLAGS       ; Armazena o estado de acionamento do botão
    FILTRO      ; Filtro para o debounce
    ENDC

; Definições de pinos
#define B_ACIONADO  FLAGS, 0
#define BOTAO       PORTA, 1
#define LAMPADA     PORTB, 0

; Vetor de reset
RES_VECT  CODE    0x0000
    BSF        STATUS,RP0            ; Seleciona o banco 1 da memória RAM
    BCF        TRISB,0               ; Configura o bit 0 de TRISB como saída (RB0)
    BCF        STATUS,RP0            ; Seleciona o banco 0 da memória RAM
    BCF        LAMPADA               ; Apaga o LED em RB0
    MOVLW      .100                  ; W = 100
    MOVWF      FILTRO                ; FILTRO = 100
    BCF        B_ACIONADO            ; B_ACIONADO = 0
    
LOOP
    BTFSC   BOTAO            ; Verifica se o BOTAO está pressionado (0)
    GOTO    NAO_ACIONADO     ; Se não pressionado (1), vai para NAO_ACIONADO  
    BTFSC   B_ACIONADO       ; Verifica se já foi acionado
    GOTO    LOOP             ; Se já foi acionado, volta para LOOP
    DECFSZ  FILTRO, F        ; Decrementa o FILTRO
    GOTO    LOOP             ; Se FILTRO não chegou a 0, volta para LOOP
    BSF     B_ACIONADO       ; Marca que o botão foi acionado
    BTFSS   LAMPADA          ; Verifica se a LAMPADA está acesa
    CALL    AcendeLampada    ; Se apagada, acende
    GOTO    DesligaLampada   ; Se acesa, apaga

NAO_ACIONADO
    BCF     B_ACIONADO       ; Reseta o estado de acionamento
    MOVLW   .100             ; Recarrega o FILTRO
    MOVWF   FILTRO
    GOTO    LOOP

AcendeLampada
    BSF     LAMPADA          ; Acende a LAMPADA (RB0)
    RETURN

DesligaLampada
    BCF     LAMPADA          ; Apaga a LAMPADA (RB0)
    GOTO    LOOP

    END
