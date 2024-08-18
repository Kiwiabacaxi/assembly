; Programa para controle de LEDs utilizando o PIC16F628A com filtro anti-bounce
; Cada botão (RA1, RA2, RA3, RA4) acende e depois desliga o LED correspondente (RB0, RB1, RB2, RB3)

; Configurações do processador
    processor 16F628A
    include "p16f628a.inc"

; CONFIGURAÇÕES
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF

; Definições de variáveis (em uma seção de dados)
    UDATA
    estado      res 1 ; Variável para armazenar o estado do sistema
    filtroRA1   res 1 ; Filtro para o botão RA1
    filtroRA2   res 1 ; Filtro para o botão RA2
    filtroRA3   res 1 ; Filtro para o botão RA3
    filtroRA4   res 1 ; Filtro para o botão RA4
    acionadoRA1 res 1 ; Flag para indicar se o RA1 foi acionado
    acionadoRA2 res 1 ; Flag para indicar se o RA2 foi acionado
    acionadoRA3 res 1 ; Flag para indicar se o RA3 foi acionado
    acionadoRA4 res 1 ; Flag para indicar se o RA4 foi acionado

; Definições de Pinos
#define BOTAO_RA1 PORTA, 1
#define BOTAO_RA2 PORTA, 2
#define BOTAO_RA3 PORTA, 3
#define BOTAO_RA4 PORTA, 4

; Seção de código
    CODE
    ORG 0x00

    ; Vetor de reset
    GOTO Inicio

Inicio:
    ; Configuração dos registradores TRIS
    banksel TRISB
    movlw 0xF0  ; Configura RB0-RB3 como saídas e RB4-RB7 como entradas
    movwf TRISB
    banksel TRISA
    movlw 0x1E  ; Configura RA1-RA4 como entradas e RA0 como saída (RA0 não utilizado)
    movwf TRISA

    ; Inicialização dos LEDs (todos apagados) e variáveis
    banksel PORTB
    clrf PORTB  ; Apaga todos os LEDs
    clrf estado ; Começa no estado 0 (todos os LEDs apagados)
    clrf acionadoRA1
    clrf acionadoRA2
    clrf acionadoRA3
    clrf acionadoRA4
    movlw .50  ; Inicializa o filtro com 50
    movwf filtroRA1
    movwf filtroRA2
    movwf filtroRA3
    movwf filtroRA4

LoopPrincipal:
    ; Verifica cada botão e aciona ou desliga o LED correspondente
    call VerificaBotaoRA1
    btfsc acionadoRA1, 0
    goto Ascende_RB0

    call VerificaBotaoRA1
    btfsc acionadoRA1, 0
    goto Apaga_RB0

    call VerificaBotaoRA2
    btfsc acionadoRA2, 0
    goto Ascende_RB1

    call VerificaBotaoRA2
    btfsc acionadoRA2, 0
    goto Apaga_RB1

    call VerificaBotaoRA3
    btfsc acionadoRA3, 0
    goto Ascende_RB2

    call VerificaBotaoRA3
    btfsc acionadoRA3, 0
    goto Apaga_RB2

    call VerificaBotaoRA4
    btfsc acionadoRA4, 0
    goto Ascende_RB3

    call VerificaBotaoRA4
    btfsc acionadoRA4, 0
    goto Apaga_RB3

    goto LoopPrincipal

Ascende_RB0:
    banksel PORTB
    btfss PORTB, 0  ; Verifica se RB0 está apagado
    bsf PORTB, 0    ; Se apagado, acende RB0
    btfss PORTB, 0  ; Verifica se RB0 está apagado
    goto LoopPrincipal  ; Volta para o loop principal

Apaga_RB0:
    banksel PORTB
    btfsc PORTB, 3  ; Verifica se RB3 está aceso
    bcf PORTB, 0    ; Se aceso, apaga RB0
    goto LoopPrincipal

Ascende_RB1:
    banksel PORTB
    btfsc PORTB, 0  ; Verifica se RB0 está aceso
    bsf PORTB, 1    ; Se aceso, acende RB1
    goto LoopPrincipal

Apaga_RB1:
    banksel PORTB
    btfss PORTB, 0  ; Verifica se RB0 está apagado
    bcf PORTB, 1    ; Se apagado, apaga RB1
    goto LoopPrincipal

Ascende_RB2:
    banksel PORTB
    btfsc PORTB, 1  ; Verifica se RB1 está aceso
    bsf PORTB, 2    ; Se aceso, acende RB2
    goto LoopPrincipal

Apaga_RB2:
    banksel PORTB
    btfss PORTB, 1  ; Verifica se RB1 está apagado
    bcf PORTB, 2    ; Se apagado, apaga RB2
    goto LoopPrincipal

Ascende_RB3:
    banksel PORTB
    btfsc PORTB, 2  ; Verifica se RB2 está aceso
    bsf PORTB, 3    ; Se aceso, acende RB3
    goto LoopPrincipal

Apaga_RB3:
    banksel PORTB
    btfss PORTB, 2  ; Verifica se RB2 está apagado
    bcf PORTB, 3    ; Se apagado, apaga RB3
    goto LoopPrincipal

VerificaBotaoRA1:
    banksel PORTA
    btfsc BOTAO_RA1  ; Verifica se RA1 está pressionado
    goto NAO_ACIONADO_RA1
    decfsz filtroRA1, f ; Decrementa o filtro
    goto RETORNO_RA1
    bsf acionadoRA1, 0 ; Botão acionado
    movlw .50
    movwf filtroRA1
RETORNO_RA1:
    return

NAO_ACIONADO_RA1:
    clrf acionadoRA1 ; Botão não acionado
    movlw .50
    movwf filtroRA1
    return

VerificaBotaoRA2:
    banksel PORTA
    btfsc BOTAO_RA2  ; Verifica se RA2 está pressionado
    goto NAO_ACIONADO_RA2
    decfsz filtroRA2, f ; Decrementa o filtro
    goto RETORNO_RA2
    bsf acionadoRA2, 0 ; Botão acionado
    movlw .50
    movwf filtroRA2
RETORNO_RA2:
    return

NAO_ACIONADO_RA2:
    clrf acionadoRA2 ; Botão não acionado
    movlw .50
    movwf filtroRA2
    return

VerificaBotaoRA3:
    banksel PORTA
    btfsc BOTAO_RA3  ; Verifica se RA3 está pressionado
    goto NAO_ACIONADO_RA3
    decfsz filtroRA3, f ; Decrementa o filtro
    goto RETORNO_RA3
    bsf acionadoRA3, 0 ; Botão acionado
    movlw .50
    movwf filtroRA3
RETORNO_RA3:
    return

NAO_ACIONADO_RA3:
    clrf acionadoRA3 ; Botão não acionado
    movlw .50
    movwf filtroRA3
    return

VerificaBotaoRA4:
    banksel PORTA
    btfsc BOTAO_RA4  ; Verifica se RA4 está pressionado
    goto NAO_ACIONADO_RA4
    decfsz filtroRA4, f ; Decrementa o filtro
    goto RETORNO_RA4
    bsf acionadoRA4, 0 ; Botão acionado
    movlw .50
    movwf filtroRA4
RETORNO_RA4:
    return

NAO_ACIONADO_RA4:
    clrf acionadoRA4 ; Botão não acionado
    movlw .50
    movwf filtroRA4
    return

    END
