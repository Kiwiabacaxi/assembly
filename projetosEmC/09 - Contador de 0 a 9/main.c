#include <main.h>


const BYTE LED_MAP[10] = {0xFE,0x38,0xDD,0x7D,0x3B,0x77,0xF7,0x3C,0xFF,0x7F};

void mostrarDisplay(int8 valor) {
    output_b(LED_MAP[valor]);
}

signed int8 ajustarContador(signed int8 contador, signed int8 ajuste) {
    contador += ajuste;
    if (contador > 9) contador = 0;
    if (contador < 0) contador = 9;
    return contador;
}

int1 botaoPressionado(int16 pin) {
    if (input(pin) == 0) {
        delay_ms(50);  // Debounce
        return (input(pin) == 0);
    }
    return 0;
}

void main() {
    signed int8 contador = 0;
    mostrarDisplay(contador);

    while(TRUE) {
        if (botaoPressionado(BOT_RESET)) {
            contador = 0;
        } else if (botaoPressionado(BOT_INCREMENTA)) {
            contador = ajustarContador(contador, 1);
        } else if (botaoPressionado(BOT_DECREMENTA)) {
            contador = ajustarContador(contador, -1);
        } else {
            continue;  // Nenhum botão pressionado, volta ao início do loop
        }
        
        mostrarDisplay(contador);
        delay_ms(200);  // Delay após a ação
    }
}