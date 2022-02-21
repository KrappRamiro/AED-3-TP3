//--------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "ConfigurationBitsC.h"

#define _XTAL_FREQ 4000000
#define fila1       RB0
#define fila2       RB1
#define fila3       RB2
#define ERROR       RB3
#define columna1    RB4
#define columna2    RB5
#define columna3    RB6
#define columna4    RB7
#define BCD_A       RA0
#define BCD_B       RA1
#define BCD_C       RA2
#define BCD_D       RA3
#define control_A   RA4
#define control_B   RA6
#define cerradura   RA7

void config() {
	// en el TRIS 1--> ENTRADA, 0 -- Salida
	TRISA = 0x20; // Pongo como salida de RA0 a RA4 + RA6.
	TRISB = 0xF0; // Pongo como salida de RB0 a RB3. Pongo como entrada de RB4 a RB7.
	PORTA = 0x00; // Pongo en LOW el estado logico de RA0 a RA7.
	PORTB = 0x00; // Pongo en LOW el estado logico de RB0 a RB7.
	nRBPU = 0;
}

void delay_ms(int milisegundos) { //hice mi propio delay ms porque queria poder usar delay_ms() con variables, este delay_ms() si acepta un delay con variables
	while (milisegundos > 0) {
		__delay_ms(1);
		milisegundos--;
	}
}

void imprimirNumero(int display, int numero) { //imprime un numero en el display indicado
	/*
	esta funcion tiene un funcionamiento sencillo, hay que pasarle dos parametros.
	El primer parametro es a que display queres imprimir
	El segundo parametro es que numero queres imprimir.
	O sea que si queres imprimir el numero 5 en el display 1, seria asi:
	imprimirNumero(1, 5)
	1 siendo el display
	5 siendo el numero a imprimir
	 */
	switch (display) {
		case 0:
			control_A = 0;
			control_B = 0;
			break;
		case 1:
			control_A = 0;
			control_B = 1;
			break;
		case 2:
			control_A = 1;
			control_B = 0;
			break;
		case 3:
			control_A = 1;
			control_B = 1;
			break;
	}
	switch (numero) {
		case 0:
			BCD_A = 0;
			BCD_B = 0;
			BCD_C = 0;
			BCD_D = 0;
			break;
		case 1:
			BCD_A = 0;
			BCD_B = 0;
			BCD_C = 0;
			BCD_D = 1;
			break;
		case 2:
			BCD_A = 0;
			BCD_B = 0;
			BCD_C = 1;
			BCD_D = 0;
			break;
		case 3:
			BCD_A = 0;
			BCD_B = 0;
			BCD_C = 1;
			BCD_D = 1;
			break;
		case 4:
			BCD_A = 0;
			BCD_B = 1;
			BCD_C = 0;
			BCD_D = 0;
			break;
		case 5:
			BCD_A = 0;
			BCD_B = 1;
			BCD_C = 0;
			BCD_D = 1;
			break;
		case 6:
			BCD_A = 0;
			BCD_B = 1;
			BCD_C = 1;
			BCD_D = 0;
			break;
		case 7:
			BCD_A = 0;
			BCD_B = 1;
			BCD_C = 1;
			BCD_D = 1;
			break;
		case 8:
			BCD_A = 1;
			BCD_B = 0;
			BCD_C = 0;
			BCD_D = 0;
			break;
		case 9:
			BCD_A = 1;
			BCD_B = 0;
			BCD_C = 0;
			BCD_D = 1;
			break;
	}
}


void activarAlarma(int tiempo_ms) { //esta funcion activa la alarma durante 1 segundo, es cuando te equivocas 3 veces en el codigo
	ERROR = 1;
	delay_ms(tiempo_ms);
	ERROR = 0;
}

void activarCerradura(int tiempo_ms) { //activa la cerradura, es cuando pones bien el codigo
	cerradura = true;
	delay_ms(tiempo_ms);
	cerradura = false;
}

int consultarFila() { //consulta que fila se pulso del teclado matricial y la retorna
	int filaPulsada;
	if (fila1 == false) {
		filaPulsada = 0;
	} 
    else if (fila2 == false) {
		filaPulsada = 1;
	} 
    else if (fila3 == false) {
		filaPulsada = 2;
	} 
    else {
		ERROR = 1;
	}
	return filaPulsada;
}

int consultarColumna() { //consulta que columna se pulso del teclado matricial y la retorna
	int columnaPulsada;
	if (columna1 == false) {
		columnaPulsada = 0;
	} 
    else if (columna2 == false) {
		columnaPulsada = 1;
	} 
    else if (columna3 == false) {
		columnaPulsada = 2;
	} 
    else if (columna4 == false) {
		columnaPulsada = 3;
	} 
    else {
		ERROR = 1;
	}
	return columnaPulsada;
}

int main() {
	config();
	//----------------------------
	// Declaracion de variables
	int tecladoMatricial[3][4] = {
		{0, 1, 2, 3},
		{4, 5, 6, 7},
		{8, 9, -2, -2}
	};
	int teclaPulsada[4] = {0, 0, 0, 0};
	int intentosFallidos = 0;
	int cantidadMaximaIntentos = 3;
	int contrasena[4] = {5, 7, 1, 3};
    int contador = 0;
	//----------------------------
    while (1){ // Programa sin fin.
        while(contador < 4) { // Hasta que se ingrese 4 digitos.
            if ((fila1 == false) || (fila2 == false) || (fila3 == false)) { // Antirrebote.
                delay_ms(120);
                if ((fila1 == false) || (fila2 == false) || (fila3 == false)) { // Verificacón de Antirrebote.
                    TRISB = 0xF0;
                    PORTB = 0x00;
                    int columnaPulsada = consultarColumna(); // Consigo el valor correspondiente de la columna para la matriz.
                    TRISB = 0x07; // En binario 0000-0111.
                    PORTB = 0x00;
                    int filaPulsada = consultarFila(); // Consigo el valor correspondiente de la fila para la matriz.
                    teclaPulsada[contador] = tecladoMatricial[filaPulsada][columnaPulsada]; // Consigo el valor de tecla.
                    ++contador;
                }
            }
            for(int i = 0; i < 4; ++i){ // Siempre actualizo el display (hasta que se ingrese 4 digitos).
                imprimirNumero(i, teclaPulsada[i]);
                __delay_ms(1);
            }
        }
        contador = 0;
        if ((teclaPulsada[0] == contrasena[0]) && (teclaPulsada[1] == contrasena[1]) && (teclaPulsada[2] == contrasena[2]) && (teclaPulsada[3] == contrasena[3])) { 
			activarCerradura(2000);
		} 
        else { // Contraseña incorrecta.
			++intentosFallidos;
            if (intentosFallidos == cantidadMaximaIntentos) { // 3 Errores.
                activarAlarma(2000);
            }
        } 
        for(int i = 0; i < 4; ++i){ // Borro las teclas.
            teclaPulsada[i] = 0;    
        }
    }
	return (EXIT_SUCCESS);
}

