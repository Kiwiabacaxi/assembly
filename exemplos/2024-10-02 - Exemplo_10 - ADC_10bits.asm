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
	CENTENA
	MILHAR
	CONTADOR
	ADC_H
	ADC_L
	X_H
	X_L
	Y_H
	Y_L
	R_H
	R_L	
	FLAGS
	W_TEMP
	S_TEMP
    ENDC
    
;variáveis
#define	FIM_100MS	FLAGS,0
#define	TROCA_DISPLAY	FLAGS,1
#define	EH_NEGATIVO	FLAGS,2	

;entradas
#define	B_ON		PORTB,0
#define	B_OFF		PORTB,1

;saídas
#define	DISPLAY		PORTD
#define	D_UNIDADE	PORTB,4    
#define	D_DEZENA	PORTB,5  
#define	D_CENTENA	PORTB,6  
#define	D_MILHAR	PORTB,7
#define	HEATER		PORTC,2
    
;constantes
V_TMR0	    equ		.131	
	
RES_VECT  CODE    0x0000    ;vetor de reset,define deve estar a 1ª instrução do programa
    GOTO    START           ;pula a área de armazenamento de interrupção

INT_VECT  CODE    0x0004    ;vetor de interrupção, define deve estar a 1ª instrução da interrupção
    MOVWF   W_TEMP	    ;salvar W em W_TEMP
    MOVF    STATUS,W	    ;W = STATUS
    MOVWF   S_TEMP	    ;salvar STATUS em S_TEMP
    BTFSS   INTCON,T0IF	    ;testa se a interrupção foi por TIMER0
    GOTO    SAI_INTERRUPCAO ;se não foi, pula para SAI_INTERRUPCAO
    BCF	    INTCON,T0IF	    ;limpa o bit de indicação de interrupção por TIMER0
    MOVLW   V_TMR0	    ;W = V_TMR0 -> W = 131
    ADDWF   TMR0,F	    ;TMR0 = TMR0 + V_TMR0 -> TMR0 = TMR0 + 131
    BSF	    TROCA_DISPLAY   ;TROCA_DISPLAY = 1
    DECFSZ  CONTADOR,F	    ;CONTADOR-- e testa se zerou
    GOTO    SAI_INTERRUPCAO ;se não zerou, pula para SAI_INTERRUPCAO
    BSF	    FIM_100MS	    ;FIM_100MS = 1
    MOVLW   .25		    ;W = 25
    MOVWF   CONTADOR	    ;CONTADOR = 25
SAI_INTERRUPCAO
    MOVF    S_TEMP,W	    ;W = S_TEMP
    MOVWF   STATUS	    ;restaura STATUS
    MOVF    W_TEMP,W	    ;restaura W
    RETFIE

START
    BANK1
    CLRF    TRISD	    ;configura todo o PORTD como saída
    MOVLW   B'00001111'	    ;W = 00001111
    MOVWF   TRISB	    ;TRISB = 00001111
    BCF	    TRISC,2	    ;configura o pino 2 da PORTC como saída   
    MOVLW   B'11010100'	    ;palavra de configuração do TIMER0
			    ;bit7: ativa resistores PULL_UP do PORTB
			    ;bit6: define o tipo de borda para RB0
			    ;bit5: define origem do clock do TIMER0				    
			    ;bit4: define borda do clock do TIMER0 qdo clock for externo
			    ;bit3: quem usa o PRESCALER - TMR0 ou WDT
			    ;bit2..0: define o PRESCALER - 100 - 1:32				  
    MOVWF   OPTION_REG	    ;carrega a configuração do TIMER0
    MOVLW   B'11001110'	    ;palavra de configuração do ADCON1
			    ;bit7: ADFM = 1 - Justificado à direita
			    ;bit6: ADCS2 = 1 - clock RC pra a ADC
			    ;bit5..4: não usado				     
			    ;bit3..0:PCFG3..PCFG0 - 1110 - entrada AN0
    MOVWF   ADCON1	    ;carrega a configuração do ADCON1
    BANK0
    MOVLW   B'11000001'	    ;palavra de configuração do ADCON0
			    ;bit7..6 - ADCS1..ADCS0 - 11 - clock RC pra a ADC
			    ;bit5..3 - CHS2..CHS0 - seleção de canal - 000
			    ;bit2 - GO/DONE = 0 				     
			    ;bit1 - não usado
			    ;bit0 - ADON = 1 liga o conversor			    
    MOVWF   ADCON0	    ;carrega a configuração do ADCON0
    MOVLW   .25
    MOVWF   CONTADOR
    CLRF    FLAGS	    ;FLAGS = 0
    BSF	    INTCON,T0IE	    ;habilita o atendimento de interrpção por TIMER0
    BSF	    INTCON,GIE	    ;habilita o atendimento de interrupções
LACO_PRINCIPAL
    BTFSC   TROCA_DISPLAY	;testa se já passou 4ms
    CALL    ATUALIZA_DISPLAY	;se já passou 4ms, chama a subrotina ATUALIZA_DISPLAY
    BTFSC   FIM_100MS		;testa se já passou 100ms
    GOTO    LE_ADC
    BTFSS   B_ON		;testa se o B_ON não está pressionado
    BSF	    HEATER		;se estiver, liga a resistência
    BTFSS   B_OFF		;testa se o B_OFF não está pressionado
    BCF	    HEATER		;se estiver, desliga a resistência    
    GOTO    LACO_PRINCIPAL	;se não passou 100ms, pula para LACO_PRINCIPAL
    
LE_ADC    
    BCF	    FIM_100MS
    BSF	    ADCON0,GO_DONE	;inicia a conversão
    BTFSC   ADCON0,GO_DONE	;testa se a conversão foi feita
    GOTO    $-1			;se não acabou, teste de novo
    MOVF    ADRESH,W		;W = ADRESH
    MOVWF   X_H			;X_H = ADRESH
    BANK1			;seleciona o BNAK1 para ler o ADRESL
    MOVF    ADRESL,W		;W = ADRESL
    BANK0			;volta parao BANK0 para guardar o ADRESL
    MOVWF   X_L			;X_L = ADRESL
    CLRF    UNIDADE		;UNIDADE = 0
    CLRF    DEZENA		;DEZENA = 0
    CLRF    CENTENA		;CENTENA = 0
    CLRF    MILHAR		;MILHAR = 0
    
VERIFICA_MILHAR
    MOVLW   0x03		;
    MOVWF   Y_H			;Y_H = 0x03
    MOVLW   0xE8		;
    MOVWF   Y_L			;Y_L = 0xE8 // Y = 0x03E8 = 1000
    CALL    SUB_16BITS		;chama subrotina para subtrair numeros de 16bits
    BTFSC   EH_NEGATIVO		;testa se o resultado é negativo
    GOTO    VERIFICA_CENTENA	;se for, pula para VERIFICA_CENTENA
    INCF    MILHAR,F		;MILHAR++
    MOVF    R_H,W		;   
    MOVWF   X_H			;X_H = R_H			
    MOVF    R_L,W		;
    MOVWF   X_L			;X_L = R_L
    GOTO    VERIFICA_MILHAR	;pula para VERIFICA_MILHAR
  
VERIFICA_CENTENA
    MOVLW   0x00		;
    MOVWF   Y_H			;Y_H = 0x00
    MOVLW   0x64		;
    MOVWF   Y_L			;Y_L = 0x64 // Y = 0x0064 = 100
    CALL    SUB_16BITS		;chama subrotina para subtrair numeros de 16bits
    BTFSC   EH_NEGATIVO		;testa se o resultado é negativo
    GOTO    VERIFICA_DEZENA	;se for, pula para VERIFICA_DEZENA
    INCF    CENTENA,F		;CENTENA++
    MOVF    R_H,W		;   
    MOVWF   X_H			;X_H = R_H			
    MOVF    R_L,W		;
    MOVWF   X_L			;X_L = R_L
    GOTO    VERIFICA_CENTENA	;pula para VERIFICA_CENTENA
    
VERIFICA_DEZENA
    MOVLW   .10			;W = 10
    SUBWF   X_L,W		;W = X_L - 10
    BTFSS   STATUS,C		;testa se X_L >= 10
    GOTO    VERIFICA_UNIDADE	;se X_L < 10, pula para VERIFICA_UNIDADE
    INCF    DEZENA,F		;DEZENA++
    MOVWF   X_L			;X_L = X_L - 10
    GOTO    VERIFICA_DEZENA	;pula para VERIFICA_DEZENA
    
VERIFICA_UNIDADE
    MOVF    X_L,W		;carrega o resto para W
    MOVWF   UNIDADE		;carrega o resto para UNIDADE
    GOTO    LACO_PRINCIPAL	;
    
SUB_16BITS
    BCF	    EH_NEGATIVO
    MOVF    Y_L,W		;W = Y_L
    SUBWF   X_L,W		;W = X_L - Y_L
    MOVWF   R_L			;R_L = X_L - Y_L
    BTFSS   STATUS,C		;testa se o resultado é negativo
    BSF	    EH_NEGATIVO		;se for, EH_NEGATIVO = 1
    MOVF    Y_H,W		;W = Y_H
    SUBWF   X_H,W		;W = X_H - Y_H
    MOVWF   R_H			;R_L = X_H - Y_H   
    BTFSS   STATUS,C		;testa se o resultado é negativo
    GOTO    X_EH_MENOR_Y	;se for, pula para X_EH_MENOR_Y
    BTFSS   EH_NEGATIVO		;testa se foi pedido emprestado
    RETURN			;se não foi pedido emprestado,retorne
    MOVLW   .1			;W = 1
    SUBWF   R_H,F		;R_H = R_H - 1
    BTFSC   STATUS,C		;testa se o resultado é negativo
    BCF	    EH_NEGATIVO		;se for positivo, EH_NEGATIVO = 0
    RETURN			;retorne
X_EH_MENOR_Y
    BSF	    EH_NEGATIVO		;EH_NEGATIVO = 1
    RETURN			;retorne
ATUALIZA_DISPLAY
    BCF	    TROCA_DISPLAY	;TROCA_DISPLAY = 0
    BTFSS   D_UNIDADE		;testa se a UNIDADE está acesa
    GOTO    TESTA_DEZENA	;se D_UNIDADE = 0, pula para TESTA_DEZENA
    BCF	    D_UNIDADE		;apaga display da UNIDADE
    MOVF    DEZENA,W		;W = DEZENA
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o código de 7 segmentos   	       
    MOVWF   DISPLAY		;DISPLAY = W -> PORTD = W
    BSF	    D_DEZENA		;acende o display da DEZENA   
    RETURN			;volta para o programa principal    
TESTA_DEZENA
    BTFSS   D_DEZENA		;testa se a DEZENA está acesa 
    GOTO    TESTA_CENTENA	;se D_DEZENA = 0, pula para TESTA_CENTENA
    BCF	    D_DEZENA		;apaga o display da DEZENA
    MOVF    CENTENA,W		;W = CENTENA
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY		;DISPLAY = W -> PORTD = W
    BSF	    D_CENTENA		;acende display da CENTENA
    RETURN			;volta para o programa principal
TESTA_CENTENA
    BTFSS   D_CENTENA		;testa se a CENTENA está acesa
    GOTO    TESTA_MILHAR	;se D_CENTENA = 0, pula para TESTA_MILHAR
    BCF	    D_CENTENA		;apaga o display da CENTENA
    MOVF    MILHAR,W		;W = MILHAR
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY		;DISPLAY = W -> PORTD = W
    BSF	    D_MILHAR		;acende display da MILHAR
    RETURN			;volta para o programa principal
TESTA_MILHAR
    BCF	    D_MILHAR		;apaga o display da MILHAR
    MOVF    UNIDADE,W		;W = UNIDADE
    CALL    BUSCA_CODIGO	;chama a subrotina para obter o código de 7 segmentos
    MOVWF   DISPLAY		;DISPLAY = W -> PORTD = W
    BSF	    D_UNIDADE		;acende display da UNIDADE
    RETURN			;volta para o programa principal    
    
BUSCA_CODIGO
    ADDWF   PCL,F		;PCL = PCL + W
    RETLW   0x3F		;retorna da subrotina com W = 0x3F
    RETLW   0x06		;retorna da subrotina com W = 0x06    
    RETLW   0x5B		;retorna da subrotina com W = 0x5B    
    RETLW   0x4F		;retorna da subrotina com W = 0x4F
    RETLW   0x66		;retorna da subrotina com W = 0x66
    RETLW   0x6D		;retorna da subrotina com W = 0x6D    
    RETLW   0x7D		;retorna da subrotina com W = 0x7D    
    RETLW   0x07		;retorna da subrotina com W = 0x07    
    RETLW   0x7F		;retorna da subrotina com W = 0x7F
    RETLW   0x6F		;retorna da subrotina com W = 0x6F    
    
    
    
    
    END