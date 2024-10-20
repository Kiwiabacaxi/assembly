#include <16F628A.h>
#use delay(internal=4MHz)
#use FIXED_IO( B_outputs=PIN_B7,PIN_B6,PIN_B5,PIN_B4,PIN_B3,PIN_B2,PIN_B1,PIN_B0 )
#define BOT_RESET   PIN_A1
#define BOT_INCREMENTA   PIN_A2
#define BOT_DECREMENTA   PIN_A3