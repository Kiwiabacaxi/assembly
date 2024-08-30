; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR

    
; PIC16F628A Configuration Bit Settings

; Assembly source line config statements

#include "p16f628a.inc"

; CONFIG
; __config 0xFF70
    __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF


#define	BANK0	BCF STATUS,RP0
#define	BANK1	BSF STATUS,RP0
    
    CBLOCK 0X20
	UNIDADE
	DEZENA
	FILTRO
	FLAGS
	W_TEMP
	S_TEMP
	TMR_1S
    ENDC
    
;variáveis
#define	    CONTEI	    FLAGS,0
#define	    TROCA_DISPLAY   FLAGS,1

    
;entradas
#define	    B_INC	    PORTA,1
#define	    B_DEC	    PORTA,2
#define	    B_STOP	    PORTA,3
#define	    B_RESET	    PORTA,4
    
;saídas
#define	    DISPLAY	    PORTB
#define	    QUAL_DISPLAY    PORTB,4
    
;constantes
V_TMR0	    equ		    .131
V_FILTRO    equ		    .100
    
RES_VECT    CODE    0x0000			; processor reset vector

    GOTO    START				;pula a área de armazenamento de iterrupção

INT_VEC	    CODE    0X0004			;vetor de iterrupção
    
    MOVWF   W_TEMP				;salvar w em W_TEMP
    MOVF    STATUS,W				;w = STATUS
    MOVWF   S_TEMP				;salvar SATATUS em S_TEMP
    BTFSS   INTCON,T0IF				;testa se a iterrupção foi por TIMER0
    GOTO    SAI_ITERRUPCAO			;se não foi, pula para SAI_ITERRUPCAO
    BCF	    INTCON,T0IF				;limpa o bit de indicação de iterrupção por TIMER0
    MOVLW   V_TMR0				;W = V_TMR0 -> W = 131
    ADDWF   TMR0,F				;TMR0 = TMR0 + V_TMR0 -> TMR0 = TMR0 + 131
    
    INCF    TMR_1S
    
    BSF	    TROCA_DISPLAY			;TROCA_DISPLAY = 1
    
SAI_ITERRUPCAO
    
    MOVF    S_TEMP,W				;W = S_TEMP
    MOVWF   STATUS				;restaura STATUS
    MOVF    W_TEMP,W				;restaura W
    RETFIE
    
START
    
    BANK1
    CLRF    TRISB				;configura todo o PORTB como saída
    MOVLW   B'11010100'				;palavra de configuração do TIMER0
						;bit7: ativa resistores PULL_UP do PORTB
						;bit6: define o tipo de borda para RB0
						;bit5: define origem do clock do TIMER0
						;bit4: define borda do clock do TIMER0
						;bit3: quem usa o PRESCALER - TMR0 ou WDT
						;bit2..0: define PRESCALER - 100 - 1:32
    MOVWF   OPTION_REG				;carrega a configuração do TIMER0
    BANK0
    CLRF    UNIDADE				;UNIDADE = 0
    CLRF    DEZENA				;DEZENA = 0
    MOVLW   V_FILTRO				;W = V_FILTRO
    MOVWF   FILTRO				;FILTRO = V_FILTRO
    CLRF    FLAGS				;FLAGS = 0
    CLRF    TMR_1S
    BSF	    INTCON,T0IE				;habilita o atendimento de iterrupção por TIMER0
    BSF	    INTCON,GIE				;habilita o atenddimento de iterrupções
 
   
LACO_PRINCIPAL
    
    BTFSC   TROCA_DISPLAY			;testa se já passou 4ms
    CALL    ATUALIZA_DISPLAY			;se já passou 4ms, chama a subrotina ATUALIZA_DISPLAY
    
    BTFSS   B_RESET				;testa se B_RESET está pressionado
    GOTO    B_RESET_ACIONADO			;se pressionado, pula para B_RESET_ACIONADO
    
    BTFSS   B_INC
    GOTO    B_INCREMENTAR
    
    BTFSS   B_DEC
    GOTO    B_DECREMENTAR
    
    GOTO    LACO_PRINCIPAL
    
    
B_INCREMENTAR
    BTFSC   TROCA_DISPLAY			;testa se já passou 4ms
    CALL    ATUALIZA_DISPLAY			;se já passou 4ms, chama a subrotina ATUALIZA_DISPLAY
    
    BTFSS   B_STOP
    GOTO    LACO_PRINCIPAL
    
    MOVLW   .250				; Carrega o valor 250 no registrador W
    SUBWF   TMR_1S,W				; Subtrai W de MINHA_VAR e armazena o resultado em W
    BTFSS   STATUS,Z				; Testa se o bit Z (zero) no STATUS está setado (resultado da subtração foi zero)
    GOTO    B_INCREMENTAR			; Se Z = 0, a variável não é igual a 250
    
    CLRF    TMR_1S
        
;    BTFSS   B_UP				;testa se B_UP está acionado
;    GOTO    B_UP_NAO_ACIONADO			;se não acionado, pula para B_UP_NAO_ACIONADO
;    BTFSC   CONTEI				;testa se CONTEI = 0
;    GOTO    LACO_PRINCIPAL			;se CONTEI = 1, pula para LACO_PRINCIPAL
;    DECFSZ  FILTRO,F				;decrementa o FILTRO e teste se zerou
;    GOTO    LACO_PRINCIPAL			;se não zerou, pula para LACO_PRINCIPAL
;    BSF	    CONTEI				;CONTEI = 1
    
    
    INCF    UNIDADE,F				;UNIDADE++
    MOVLW   .10					;W = 10
    SUBWF   UNIDADE,W				;W = UNIDADE - W
    BTFSS   STATUS,C				;testa se o resultado é negativo (UNIDADE < 10)
    GOTO    B_INCREMENTAR			;se negativo, pula para LACO_PRINCIPAL
    CLRF    UNIDADE				;UNIDADE = 0
    INCF    DEZENA,F				;DEZENA++
    MOVLW   .10					;W = 10
    SUBWF   DEZENA,W				;W = DEZENA - W
    BTFSC   STATUS,C				;testa se o resultado é negativo (DEZENA < 10)
    CLRF    DEZENA				;se positivo DEZENA = 0
    
;    MOVLW   V_FILTRO
;    MOVWF   FILTRO
    BCF	    CONTEI
    
    GOTO    B_INCREMENTAR			;pula para LACO_PRINCIPAL
    
    
B_DECREMENTAR

    BTFSC   TROCA_DISPLAY            ; Testa se já passou 4ms
    CALL    ATUALIZA_DISPLAY         ; Se já passou 4ms, chama a subrotina ATUALIZA_DISPLAY
    
    BTFSS   B_STOP                   ; Testa se B_STOP está pressionado
    GOTO    LACO_PRINCIPAL           ; Se não estiver pressionado, volta para o loop principal
    
    MOVLW   .250                     ; Carrega o valor 250 no registrador W
    SUBWF   TMR_1S,W                 ; Subtrai W de TMR_1S e armazena o resultado em W
    BTFSS   STATUS,Z                 ; Testa se o bit Z (zero) no STATUS está setado (resultado da subtração foi zero)
    GOTO    B_DECREMENTAR            ; Se Z = 0, a variável não é igual a 250
    
    CLRF    TMR_1S                   ; Zera TMR_1S
    
    ; Decrementa as unidades
    DECF    UNIDADE,F                ; UNIDADE--
    BTFSS   STATUS,Z                 ; Testa se UNIDADE chegou a zero
    GOTO    FIM_DECREMENTO           ; Se não chegou a zero, pula para FIM_DECREMENTO
    
    ; Se UNIDADE chegou a zero, decrementa as dezenas
    MOVLW   .09                      ; W = 9
    MOVWF   UNIDADE                  ; UNIDADE = 9
    DECF    DEZENA,F                 ; DEZENA--
    BTFSS   STATUS,Z                 ; Testa se DEZENA chegou a zero
    GOTO    FIM_DECREMENTO           ; Se não chegou a zero, pula para FIM_DECREMENTO
    
    ; Se DEZENA chegou a zero, ajusta para 9
    MOVLW   .09                      ; W = 9
    MOVWF   DEZENA                   ; DEZENA = 9

FIM_DECREMENTO
    BCF     CONTEI                   ; CONTEI = 0
    
    GOTO    B_DECREMENTAR            ; Pula para B_DECREMENTAR

B_RESET_ACIONADO
    
    CLRF    UNIDADE                  ; UNIDADE = 0
    CLRF    DEZENA                   ; DEZENA = 0
    GOTO    LACO_PRINCIPAL           ; Pula para LACO_PRINCIPAL
    
ATUALIZA_DISPLAY
    
    BCF     TROCA_DISPLAY            ; TROCA_DISPLAY = 0
    BTFSS   QUAL_DISPLAY             ; Testa se a UNIDADE está acesa
    GOTO    ACENDE_UNIDADE           ; Se QUAL_DISPLAY = 0, pula para ACENEDE_UNIADE
    MOVF    DEZENA,W                 ; W = DEZENA
    CALL    BUSCA_CODIGO             ; Chama a subrotina para obter o código de 7 segmentos
    ANDLW   B'11101111'              ; W = W & B'11101111'
    
ESCREVE_DISPLAY
    
    MOVWF   DISPLAY                  ; DISPLAY = W -> PORTB = W
    RETURN                           ; Volta para o programa principal
    
ACENDE_UNIDADE
    
    MOVF    UNIDADE,W                ; W = UNIDADE
    CALL    BUSCA_CODIGO             ; Chama a subrotina para obter o código de 7 segmentos
    GOTO    ESCREVE_DISPLAY          ; Pula para ESCREVE_DISPLAY

BUSCA_CODIGO
    ADDWF   PCL,F                    ; PCL = PCL + W
    RETLW   0XFE                     ; Retorna a subrotina com W = 0xFE
    RETLW   0X38                     ; Retorna a subrotina com W = 0x38
    RETLW   0XDD                     ; Retorna a subrotina com W = 0xDD
    RETLW   0X7D                     ; Retorna a subrotina com W = 0x7D
    RETLW   0X3B                     ; Retorna a subrotina com W = 0x3B
    RETLW   0X77                     ; Retorna a subrotina com W = 0x77
    RETLW   0XF7                     ; Retorna a subrotina com W = 0xF7
    RETLW   0X3C                     ; Retorna a subrotina com W = 0x3C
    RETLW   0XFF                     ; Retorna a subrotina com W = 0xFF
    RETLW   0X7F                     ; Retorna a subrotina com W = 0X7F

    END
