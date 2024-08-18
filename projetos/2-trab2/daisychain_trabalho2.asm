    processor 16F628A
    include "p16f628a.inc"

    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

    CBLOCK 0x20
        state    ; Armazena o estado atual 0-8 (0-3 acendendo, 4-7 apagando, 8 reiniciando)
    ENDC

    ORG 0x00
        GOTO Start

Start:
    ; Inicialização
    CLRF PORTB       ; Apaga todos os LEDs
    CLRF state       ; Inicializa o estado como 0
    BSF STATUS, RP0  ; Seleciona banco 1
    CLRF TRISB       ; Configura PORTB como saída
    BSF TRISA, 1     ; Configura RA1 como entrada
    BSF TRISA, 2     ; Configura RA2 como entrada
    BSF TRISA, 3     ; Configura RA3 como entrada
    BSF TRISA, 4     ; Configura RA4 como entrada
    BCF STATUS, RP0  ; Volta para banco 0

MainLoop:
    MOVF state, W
    ADDWF PCL, F    ; Salta para o estado atual
    GOTO State0     ; Estado 0: Esperando RA1 para acender RB0
    GOTO State1     ; Estado 1: Esperando RA2 para acender RB1
    GOTO State2     ; Estado 2: Esperando RA3 para acender RB2
    GOTO State3     ; Estado 3: Esperando RA4 para acender RB3
    GOTO State4     ; Estado 4: Esperando RA4 para apagar RB3
    GOTO State5     ; Estado 5: Esperando RA3 para apagar RB2
    GOTO State6     ; Estado 6: Esperando RA2 para apagar RB1
    GOTO State7     ; Estado 7: Esperando RA1 para apagar RB0
    GOTO ResetState ; Estado 8: Finaliza e reinicia o ciclo

State0:
    BTFSC PORTA, 1  ; Verifica se RA1 foi pressionado
    GOTO MainLoop
    BSF PORTB, 0    ; Acende RB0
    INCF state, F   ; Avança para o próximo estado
    GOTO MainLoop

State1:
    BTFSC PORTA, 2  ; Verifica se RA2 foi pressionado
    GOTO MainLoop
    BSF PORTB, 1    ; Acende RB1
    INCF state, F   ; Avança para o próximo estado
    GOTO MainLoop

State2:
    BTFSC PORTA, 3  ; Verifica se RA3 foi pressionado
    GOTO MainLoop
    BSF PORTB, 2    ; Acende RB2
    INCF state, F   ; Avança para o próximo estado
    GOTO MainLoop

State3:
    BTFSC PORTA, 4  ; Verifica se RA4 foi pressionado
    GOTO MainLoop
    BSF PORTB, 3    ; Acende RB3
    INCF state, F   ; Avança para o próximo estado (fase de desligamento)
    GOTO MainLoop

; AQUI A GENTE COMEÇA A DESLIGAR OS LEDS NA ORDEM INVERSA
State4:
    BTFSC PORTA, 1 ; Verifica se RA1 foi pressionado para apagar RB0
    GOTO MainLoop
    BCF PORTB, 0   ; Apaga RB0
    INCF state, F  ; Avança para o próximo estado
    GOTO MainLoop

State5:
    BTFSC PORTA, 2 ; Verifica se RA2 foi pressionado para apagar RB1
    GOTO MainLoop
    BCF PORTB, 1   ; Apaga RB1
    INCF state, F  ; Avança para o próximo estado
    GOTO MainLoop

State6:
    BTFSC PORTA, 3 ; Verifica se RA3 foi pressionado para apagar RB2
    GOTO MainLoop
    BCF PORTB, 2   ; Apaga RB2
    INCF state, F  ; Avança para o próximo estado
    GOTO MainLoop

State7:
    BTFSC PORTA, 4 ; Verifica se RA4 foi pressionado para apagar RB3
    GOTO MainLoop
    BCF PORTB, 3   ; Apaga RB3
    INCF state, F  ; Avança para o próximo estado
    GOTO MainLoop

ResetState:
    CLRF state      ; Reinicia o estado para 0
    GOTO MainLoop

    END
