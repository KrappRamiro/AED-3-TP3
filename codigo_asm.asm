	----------------------------------------------------------------
	 Links de Interes: 
	- https://drive.google.com/file/d/1ZZ_PkKAMHkiPFsBQH1RG-QCuwhHDrB09/view?usp=sharing    [2021/04/29 (Subrutina)]
	- https://www.youtube.com/watch?v=P2d1vcJXiKo       									[Teclado Matricial (N°1)]
	- https://www.youtube.com/watch?v=FKH4VzvnSIA 											[Teclado Matricial (N°2)]
	- https://drive.google.com/file/d/1gRnxLs02jr1anoHdlwI4Nu9IDc3Q3f7H/view?usp=sharing 	[2021/06/24 (Direccionamiento indirecto)]
	- https://drive.google.com/file/d/1MCJOSUEMAwAOi8mT45195ngJOqF3UO4N/view?usp=sharing 	[2021/06/10 (Display 7-segmentos)]
	- https://blog.ars-electronica.com.ar/2017/08/cd4511-decodificador-para-display-7.html 	[Display 7 - seg con CD4511 (Decodificador BCD)]
	- https://pdf1.alldatasheet.es/datasheet-pdf/view/66469/INTERSIL/CD4555.html 			[Datasheet CD4555 (Demultiplexor 1 a 4)]
	- https://www.youtube.com/watch?v=XElUJawQXho											[Multiplexado de displays]
	----------------------------------------------------------------

	Datos:

	- Recordatorios:
		TRISX, 1 = Entrada.
		TRISX, 0 = Salida.
		PORTX, 1 = HIGH.
		PORTX, 0 = LOW.

	- La funcion SWAPF "registro", 0 ---> cambia los primeros 4 valores 
	  por los ultimos 4 valores y guarda la combinacion en el "acumulador" (W)
	  Pero el "file" (F) queda igual.
	- La funcion SWAPF "registro", 1 ---> cambia los primeros 4 valores 
	  por los ultimos 4 valores y sobreescribe la combinacion en "file" (F).
	
	- Teclado Matricial 4x4:
		- Tecla oprimida = Fila + Columna
		- Cada pin de "fila" tiene un peso que va de 0 a 12. 
		- Cada pin de "columna" tiene un peso que va de 0 a 3.
		- Para detectar Fila:
	 		* Pongo los pines de columna a 0 (salida).
	  		* Pongo los pines de fila a 1, o "nada" y activo el "pull up" de estos pines (entrada)
	  		* Cuando se activa una tecla, el pin de fila se pondra a 0 (pasa de 1 [pull up] a 0).
	  		* Valores posibles en binario para fila (en decimal): 0000-1110 (.14) / 0000-1101 (.13) / 0000-1011 (.11) / 0000-0111 (.7)
		
		- Para detectar Columna: swapear tanto el Tris como los pull ups o estados logicos
	 		* Pongo los pines de columna a 1, o "nada" y activo el "pull up" de estos pines (entrada).
	  		* Pongo los pines de fila a 0 (salida)
	  		* Cuando se activa una tecla, el pin de columna se pondra a 0 (pasa de 1 [pull up] a 0).
	  		* Swapear el TRISx y el PORTx(LOS DECIMALES):
	  		 Valores posibles en binario para columna (en decimal): 0000-0001 (.1) / 0000-0010 (.2) / 0000-0100 (.4) / 0000-1000 (.8)
	  		 El caso anterior es swapear y complementar los valores de Fila.
	
;---------------------------------------------------------------------------------------------------------------

#include "configurationBits.h"				; Incluyo la configuración para los pines RB4, RA6 y RA7 (I/O).

;---------------------------------------------------------------------------------------------------------------					
; Las siguentes asignaciones corresponden a REGISTROS deL programa:
PCL					equ 	0x02		; Direccion dentro de "DATA MEMORY" para PCL	(banco 0, posicion 0x02).
STATUS				equ 	0x03		; Direccion dentro de "DATA MEMORY" para STATUS (banco 0, posicion 0x03).
PORTA				equ 	0x05		; Direccion dentro de "DATA MEMORY" para PORTAx (banco 0, posicion 0x05).
PORTB				equ 	0x06		; Direccion dentro de "DATA MEMORY" para PORTBx (banco 0, posicion 0x06).
TRISA				equ 	0x85		; Direccion dentro de "DATA MEMORY" para TRISAx (banco 1, posicion 0x85).
TRISB				equ 	0x86		; Direccion dentro de "DATA MEMORY" para TRISBx (banco 1, posicion 0x86).
OPTION_REG			equ 	0x81		; Direccion para acceder al pull up del puerto B interno del PIC.

;---------------------------------------------------------------------------------------------------------------			
; Las siguentes asignaciones corresponden a VARIABLES de la aplicación:
_AUX1 				equ 	0x20		; Direcciones para variables auxiliares necesarias para el DELAY original.
_AUX2 				equ 	0x21
_AUX3 				equ 	0x22		
TECLA				equ 	0x23		; Direccion para acceder a la tecla [fila + columna].
ERROR_ACUM			equ 	0x24		; Direccion para acceder al contador de errores.
TECLA_1 			equ 	0x25		; Direcciones para variables auxiliares necesarias para el DISPLAY.
TECLA_2 			equ 	0x26
TECLA_3 			equ 	0x27
TECLA_4 			equ 	0x28
FLAG 				equ 	0x29		; Direccion para acceder a las banderas (para TECLADO y CONTRASEÑA).
AUXILIAR			equ		0x30		; Direccion para acceder al auxiliar (para todo tipo de cuentas/procesos).
CONTADOR_DPY		equ		0x31		; Direccion para acceder al contador que multiplica el DELAY sobre un el DISPLAY.
POSICION			equ		0x33		; Direccion para acceder a la posicion de la tecla [1 a 5].
CODIGO_1			equ 	0x34		; Direccion para acceder al primer numero de la contraseña.
CODIGO_2			equ 	0x35		; Direccion para acceder al segundo numero de la contraseña.
CODIGO_3			equ 	0x36		; Direccion para acceder al tercer numero de la contraseña.
CODIGO_4			equ 	0x37		; Direccion para acceder al cuarto numero de la contraseña.
_AUX11				equ 	0x38		; Direcciones para variables auxiliares necesarias para el DELAY modificado.
_AUX33				equ 	0x39
_AUX22				equ   	0x40
;---------------------------------------------------------------------------------------------------------------			
; Las siguentes asignaciones corresponden a MACROS de la aplicación:
SAVE_IN_W			equ 	0 			; Destino.
SAVE_IN_F			equ 	1 			; Destino.
DELAY				equ		0  			; Flag nuevo.
PASSWORD_VERIFIED	equ		1			; Flag nuevo.
ERROR_TECLA			equ		2  			; Flag nuevo.
CARRY				equ		0 			; Flag.
ZERO				equ		2 			; Flag.
RP0					equ 	5
RP1					equ 	6
RBPU 				equ 	7
;---------------------------------------------------------------------------------------------------------------			
; Las siguentes asignaciones corresponden a ESPECIFICACIONES deL programa:
RES_VECT			CODE	0x0000            
					GOTO	INICIO
MAIN_PROG			CODE

;---------------------------------------------------------------------------------------------------------------
; Subrutina de Configuracion

CONFIGURACION		BCF			STATUS, RP1					; Banco 1 para Trisx.
					BSF			STATUS, RP0					; Banco 1 para Trisx.
					MOVLW		0x20						; Pongo como salida de RA0 a RA4 + RA6 a RA7 (RA5 = NO BIDIRECCIONAL).
					MOVWF		TRISA
					BCF			OPTION_REG, RBPU			; Activo los pull-ups internos del PIC del puerto B (pines RBx).
					BCF			STATUS, RP0				
					;-----------------------------
					CLRF		FLAG
					CLRF		ERROR_ACUM						
					CLRF		POSICION
					CLRF		TECLA_1
					CLRF		TECLA_2
					CLRF		TECLA_3
					CLRF		TECLA_4
					CLRF		CONTADOR_DPY
					CLRW									; Limpio el acumulador.
					MOVLW		.5							; Valor del CODIGO_1.
					MOVWF		CODIGO_1		
					MOVLW		.7							; Valor del CODIGO_2.
					MOVWF		CODIGO_2		
					MOVLW		.1							; Valor del CODIGO_3.
					MOVWF		CODIGO_3		
					MOVLW		.3							; Valor del CODIGO_4.
					MOVWF		CODIGO_4		
					CLRW						
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Subrutina del Teclado Matricial (10 teclas, 3x4 modificado)

TECLAS				CLRF		TECLA
					CLRW
					BSF			STATUS, RP0			
					MOVLW		0xF0						; High PORTB como entrada.
					MOVWF		TRISB	
					BCF 		STATUS, RP0					
					MOVLW		0x00						; Escribir 1 en Low PORTB.
					MOVWF		PORTB							
					;---------------------					; Antirebote.
					BTFSS		PORTB, 4
					GOTO		QUIZAS_TOCO_TECLA		
					BTFSS		PORTB, 5
					GOTO		QUIZAS_TOCO_TECLA						
					BTFSS		PORTB, 6
					GOTO		QUIZAS_TOCO_TECLA
					BTFSS		PORTB, 7
					GOTO		QUIZAS_TOCO_TECLA
					GOTO	  	NO_TOCO_TECLA
					;---------------------
QUIZAS_TOCO_TECLA	CALL		DELAY_100ms					; CALIBRADO PARA PROTEUS.
					;---------------------	
					BTFSS		PORTB, 4	
					GOTO		TOCO_TECLA				
					BTFSS		PORTB, 5	
					GOTO		TOCO_TECLA							
					BTFSS		PORTB, 6	
					GOTO		TOCO_TECLA	
					BTFSS		PORTB, 7	
					GOTO		TOCO_TECLA	
					GOTO	  	NO_TOCO_TECLA	
					;---------------------					; Detecto Columna.
TOCO_TECLA			CLRW
					CLRF		TECLA
					ADDWF		PORTB, SAVE_IN_W
					MOVWF		AUXILIAR
					COMF		AUXILIAR, SAVE_IN_F			; Complemente después de leer puerto.
					CLRW
					SWAPF		AUXILIAR, SAVE_IN_W
					CLRF		AUXILIAR
					ANDLW		0x0F
					CALL		PESO_COLUMNA
					ADDWF		TECLA, SAVE_IN_F
					CLRW
					;---------------------
					BTFSC		FLAG, ERROR_TECLA
					GOTO		NO_TOCO_TECLA				; Error de doble tecla.
					;---------------------					; Detecto Fila.
					CALL		TECLADO_SWAP
					ADDWF		PORTB, SAVE_IN_W
					MOVWF		AUXILIAR
					COMF		AUXILIAR, SAVE_IN_F			; Complemento después de leer puerto.
					CLRW
					ADDWF		AUXILIAR, SAVE_IN_W
					CLRF		AUXILIAR
					ANDLW		0x07
					CALL		PESO_FILA
					;---------------------
					BTFSC		FLAG, ERROR_TECLA
					GOTO		NO_TOCO_TECLA				; Error de doble tecla.
					;---------------------				
					ADDWF		TECLA, SAVE_IN_F			; TECLA = COLUMNA + FILA 
					CLRW
					;---------------------							
					ADDWF		POSICION, SAVE_IN_W 		; Paso el contenido de POSICION al acumulador (sin perder POSICION).
					CALL		PESO_DERIVADO				; Asigna el valor de TECLA a otra variable que corresponde con su posición.
					INCF		POSICION, SAVE_IN_F 		; Incremento la posición para la siguiente tecla.
					;---------------------
NO_TOCO_TECLA		BCF			FLAG, ERROR_TECLA
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Subrutina (procedimiento) para SWAPEAR el registro TRISB y PORTB.
; Solo se usa 1 vez por TECLADO cuando se quiere detectar FILA.
				
TECLADO_SWAP		BSF			STATUS, RP0					; Cambio de banco para el TRISx.
					MOVLW		0x0F
					MOVWF		TRISB
					BCF 		STATUS, RP0					; Cambio de banco para el PORTx.
					MOVLW		0x00
					MOVWF		PORTB
					CLRW
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Sub-subrutina de Tabla de PESO de COLUMNA (anidada en TECLAS).
; NOTA = esta pensada de forma en que PC tiene la direccion actual.

PESO_COLUMNA		ADDWF		PCL, SAVE_IN_F				; Lo que esta en el acumulador (W) se lo sumo a PCL (F).
					GOTO		DOBLE_TECLA			; 0		; ERROR.
					RETLW		.0					; 1		; Columna 1
					RETLW		.1					; 2		; Columna 2
					GOTO		DOBLE_TECLA			; 3		; ERROR.
					RETLW		.2					; 4		; Columna 3
					GOTO		DOBLE_TECLA			; 5		; ERROR.
					GOTO		DOBLE_TECLA			; 6		; ERROR.
					GOTO		DOBLE_TECLA			; 7		; ERROR.
					RETLW		.3					; 8		; Columna 4
					GOTO		DOBLE_TECLA			; 9		; ERROR.
					GOTO		DOBLE_TECLA			; 10	; ERROR.
					GOTO		DOBLE_TECLA			; 11	; Fila 3.
					GOTO		DOBLE_TECLA			; 12	; ERROR.
					GOTO		DOBLE_TECLA			; 13	; Fila 2.
					GOTO		DOBLE_TECLA			; 14	; Fila 1.
DOBLE_TECLA			BSF			FLAG, 2				; 15	; ERROR. Seteo FLAG de error de doble tecla.						
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Sub-subrutina de Tabla de PESO de FILA (anidada en TECLAS).
; NOTA = esta pensada de forma en que PC tiene la direccion actual.

PESO_FILA			ADDWF		PCL, 1 						; Lo que esta en el acumulador (W) se lo sumo a PCL (F).
					GOTO		DOBLE_TECLA			; 0		; ERROR.
					RETLW		.0					; 1		; Fila 1.
					RETLW		.4					; 2		; Fila 2.
					GOTO		DOBLE_TECLA			; 3		; ERROR.
					RETLW		.8					; 4		; Fila 3.
					GOTO		DOBLE_TECLA			; 5 	; ERROR.
					GOTO		DOBLE_TECLA			; 6 	; ERROR.
					RETLW		.0					; 7		; Si es un error, muestro un 0 por defecto.
					BSF			FLAG, 2						; Seteo FLAG de error de doble tecla.			
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Sub-subrutina de Tabla de PESO de TECLA DERIVADO (anidada en TECLADO).
; NOTA = esta pensada de forma en que PC tiene la direccion actual.

PESO_DERIVADO		ADDWF		PCL, 1 						; Lo que esta en el acumulador (W) se lo sumo a PCL (F).
					GOTO		TECLA_N1				
					GOTO		TECLA_N2 
					GOTO		TECLA_N3 
					GOTO		TECLA_N4  					
					;---------------------		
TECLA_N1			CLRW									; Limpio el acumulador.
					ADDWF		TECLA, SAVE_IN_W 			; Paso el contenido de TECLA al acumulador (sin perder TECLA).
					ADDWF		TECLA_1, SAVE_IN_F  		; Paso el contenido del acumulador a la TECLA_1.
					GOTO		END_PESO_DERIVADO
					;---------------------		
TECLA_N2			CLRW									; Limpio el acumulador.
					ADDWF		TECLA, SAVE_IN_W 			; Paso el contenido de TECLA al acumulador (sin perder TECLA).
					ADDWF		TECLA_2, SAVE_IN_F  		; Paso el contenido del acumulador a la TECLA_2.		
					GOTO		END_PESO_DERIVADO
					;---------------------		
TECLA_N3			CLRW									; Limpio el acumulador.
					ADDWF		TECLA, SAVE_IN_W 			; Paso el contenido de TECLA al acumulador (sin perder TECLA).
					ADDWF		TECLA_3, SAVE_IN_F 			; Paso el contenido del acumulador a la TECLA_3.		
					GOTO		END_PESO_DERIVADO
					;---------------------
TECLA_N4			CLRW									; Limpio el acumulador.
					ADDWF		TECLA, SAVE_IN_W			; Paso el contenido de TECLA al acumulador (sin perder TECLA).
					ADDWF		TECLA_4, SAVE_IN_F  		; Paso el contenido del acumulador a la TECLA_4.		
					;---------------------								
END_PESO_DERIVADO	RETURN

;---------------------------------------------------------------------------------------------------------------
; Subrutina de CONTRASEÑA.
				
CONTRASEÑA			;---------------------					; Este indica si CONTRASEÑA se ignora (en ese caso, sigue DISPLAY).
					CLRW									; Limpio el acumulador.
					ADDWF		POSICION, SAVE_IN_W 		; Paso el contenido de POSICION al acumulador (sin perder POSICION). 				
					SUBLW		.4							; Testeo si el literal sustraido del acumulador es igual a 0.
					BTFSS		STATUS, ZERO  				; Reviso si el "flag Zero" se activo (skip if (ZERO) == 1 / next if (ZERO) == 0).
					GOTO		END_CONTRASEÑA
					CLRF		POSICION					; Borro el contenido de POSICION.
					;---------------------					; Dirreccionamiento indirecto.
					CLRW
					CLRF		FSR
					MOVLW		0x34
					MOVWF		FSR 
					;---------------------
					CLRW									; Limpio el acumulador.
					ADDWF		TECLA_1, SAVE_IN_W 			; Paso el contenido de TECLA_1 al acumulador (sin perder TECLA_1).
					SUBWF		INDF, SAVE_IN_W 			; Testeo si el literal sustraido del acumulador es igual a 0.
					BTFSS		STATUS, ZERO
					GOTO		CONTRASEÑA_FALSA
					;---------------------	
					CLRW
					INCF		FSR							
					ADDWF		TECLA_2, SAVE_IN_W 			; Paso el contenido de TECLA_2 al acumulador (sin perder TECLA_2).
					SUBWF		INDF, SAVE_IN_W  			; Testeo si el literal sustraido del acumulador es igual a 0.
					BTFSS		STATUS, ZERO
					GOTO		CONTRASEÑA_FALSA
					;---------------------
					CLRW							
					INCF		FSR
					ADDWF		TECLA_3, SAVE_IN_W			; Paso el contenido de TECLA_3 al acumulador (sin perder TECLA_3).
					SUBWF		INDF, SAVE_IN_W				; Testeo si el literal sustraido del acumulador es igual a 0.
					BTFSS		STATUS, ZERO
					GOTO		CONTRASEÑA_FALSA
					;---------------------	
					CLRW									; Limpio el acumulador.
					INCF		FSR
					ADDWF		TECLA_4, SAVE_IN_W 			; Paso el contenido de TECLA_4 al acumulador (sin perder TECLA_4).
					SUBWF		INDF, SAVE_IN_W				; Testeo si el literal sustraido del acumulador es igual a 0.
					BTFSS		STATUS, ZERO
					GOTO		CONTRASEÑA_FALSA
					;---------------------					; La contraseña es igual al codigo ingresado.	
					BSF 		PORTA, 7 					; Activo el Solenoide o Cerradura...
					CALL		DELAY_500ms				
					CALL		DELAY_500ms								
					BCF  		PORTA, 7 					; Desactivo el Solenoide.
					CLRF		ERROR_ACUM
					GOTO 		FLAG_P_V
					;---------------------					; Testeo si la contraseña fue errada 3 veces.	
CONTRASEÑA_FALSA	CLRW
					INCF		ERROR_ACUM, SAVE_IN_F		; Incremento el contador de errores de ingreso de codigo.
					ADDWF		ERROR_ACUM, SAVE_IN_W		; Paso el contenido de ERROR_ACUM al acumulador (sin perder ERROR_ACUM). 				
					SUBLW		.3							; Testeo si el literal sustraido del acumulador es igual a 0.
					BTFSS		STATUS, ZERO  				; Reviso si el "flag Zero" se activo (skip if (ZERO) == 1 / next if (ZERO) == 0.		
					GOTO 		FLAG_P_V		
					;---------------------					; Contraseña equívoca 3 veces.
					CLRF		ERROR_ACUM
					BSF			STATUS, RP0					; Banco 1 para Trisx.
					MOVLW		0xF7						; Pongo como salida RB3 (1111-0111).
					MOVWF		TRISB
					BCF			STATUS, RP0
					BSF			PORTB, 3					; Activo el Zumbador.
					CALL		DELAY_500ms
					CALL		DELAY_500ms
					BCF			PORTB, 3					; Desactivo el Zumbador.												
					;---------------------				
FLAG_P_V			BSF 		FLAG, PASSWORD_VERIFIED		; Activo un Flag que indica que el codigo llego hasta aqui.						
END_CONTRASEÑA		RETURN				
				
;---------------------------------------------------------------------------------------------------------------
; Subrutina de DISPLAY.

DISPLAY				BCF  		PORTA, 4 					; Primer display.
					BCF  		PORTA, 6
					CLRW	
					ADDWF		TECLA_1, SAVE_IN_W 			; Paso el contenido de TECLA_1 al acumulador (sin perder TECLA_1).
					CALL 		NUMERO_DISPLAY				; Elije la configuracion de pines para mostrar el numero.
					CALL		DELAY_500us
					CLRW
					;---------------------
					BCF  		PORTA, 4 					; Segundo display.
					BSF  		PORTA, 6
					ADDWF		TECLA_2, SAVE_IN_W 			; Paso el contenido de TECLA_2 al acumulador (sin perder TECLA_2).
					CALL 		NUMERO_DISPLAY				; Elije la configuracion de pines para mostrar el numero.
					CALL		DELAY_500us
					CLRW
					;---------------------				
					BSF  		PORTA, 4 					; Tercer display.
					BCF  		PORTA, 6
					ADDWF		TECLA_3, SAVE_IN_W 			; Paso el contenido de TECLA_3 al acumulador (sin perder TECLA_3).
					CALL 		NUMERO_DISPLAY				; Elije la configuracion de pines para mostrar el numero.
					CALL		DELAY_500us
					CLRW
					;---------------------
					BSF  		PORTA, 4 					 Cuarto display.
					BSF  		PORTA, 6
					ADDWF		TECLA_4, SAVE_IN_W 			; Paso el contenido de TECLA_4 al acumulador (sin perder TECLA_4).
					CALL 		NUMERO_DISPLAY				; Elije la configuracion de pines para mostrar el numero.
					CALL		DELAY_500us
					CLRW
					;---------------------					; Testeo el estado del FLAG que me indica si el codigo paso por CONTRASEÑA.
					BTFSS		FLAG, PASSWORD_VERIFIED		; Reviso si FLAG se activo (skip if (FLAG, 1) == 0 / next if (FLAG, 1) == 1.)
					GOTO 		END_DISPLAY
					;---------------------					; El siguiente codigo hace que se retrase por un tiempo determinado
					INCF		CONTADOR_DPY, SAVE_IN_F 	; el "borrado" de los displays (sin que pare todo el programa). Cuando 	
					CALL		DELAY_2_5ms					; termina ese delay, se actualiza a 0 todos los digitos.
					ADDWF		CONTADOR_DPY, SAVE_IN_W 							
					SUBLW		.150								
					BTFSS		STATUS, ZERO 
					GOTO		END_DISPLAY					
					CLRF		CONTADOR_DPY				; Borro por las dudas el contador.
					;---------------------		
					CLRF		TECLA_1 					; Limpio el contenido de las TECLA_X.
					CLRF		TECLA_2
					CLRF		TECLA_3
					CLRF		TECLA_4
					CLRW
					BCF			FLAG, PASSWORD_VERIFIED				
END_DISPLAY			RETURN
				
;---------------------------------------------------------------------------------------------------------------
; Sub-subrutina de numeros para display (se encarga de eligir la configuracion de pines para
; mostrar el numero)
; La siguiente subrutina esta pensada de forma en que PC tiene la direccion actual.

NUMERO_DISPLAY		ADDWF		PCL, 1 						; Lo que esta en el acumulador (W) se lo sumo a PCL (F).
					GOTO		N0_DISPLAY
					GOTO		N1_DISPLAY
					GOTO		N2_DISPLAY
					GOTO		N3_DISPLAY		
					GOTO		N4_DISPLAY
					GOTO		N5_DISPLAY
					GOTO		N6_DISPLAY
					GOTO		N7_DISPLAY
					GOTO		N8_DISPLAY
					GOTO		N9_DISPLAY
					;---------------------					; Numero 0.
N0_DISPLAY			BCF			PORTA, 0				
					BCF			PORTA, 1	
					BCF			PORTA, 2	
					BCF			PORTA, 3
					GOTO		END_NUM 	
					;---------------------					; Numero 1.
N1_DISPLAY			BCF			PORTA, 0				
					BCF			PORTA, 1	
					BCF			PORTA, 2	
					BSF			PORTA, 3	
					GOTO		END_NUM	
					;---------------------					; Numero 2.
N2_DISPLAY			BCF			PORTA, 0				
					BCF			PORTA, 1	
					BSF			PORTA, 2	
					BCF			PORTA, 3	
					GOTO		END_NUM		
					;---------------------					; Numero 3.
N3_DISPLAY			BCF			PORTA, 0				
					BCF			PORTA, 1	
					BSF			PORTA, 2	
					BSF			PORTA, 3	
					GOTO		END_NUM	
					;---------------------					; Numero 4.
N4_DISPLAY			BCF			PORTA, 0		
					BSF			PORTA, 1	
					BCF			PORTA, 2	
					BCF			PORTA, 3	
					GOTO		END_NUM	
					;---------------------					; Numero 5.
N5_DISPLAY			BCF			PORTA, 0				
					BSF			PORTA, 1	
					BCF			PORTA, 2	
					BSF			PORTA, 3	
					GOTO		END_NUM		
					;---------------------					; Numero 6.
N6_DISPLAY			BCF			PORTA, 0				
					BSF			PORTA, 1	
					BSF			PORTA, 2	
					BCF			PORTA, 3	
					GOTO		END_NUM		
					;---------------------					; Numero 7.
N7_DISPLAY			BCF			PORTA, 0		
					BSF			PORTA, 1	
					BSF			PORTA, 2	
					BSF			PORTA, 3	
					GOTO		END_NUM		
					;---------------------					; Numero 8.
N8_DISPLAY			BSF			PORTA, 0			
					BCF			PORTA, 1	
					BCF			PORTA, 2	
					BCF			PORTA, 3	
					GOTO		END_NUM		
					;---------------------					; Numero 9.
N9_DISPLAY			BSF			PORTA, 0			
					BCF			PORTA, 1
					BCF			PORTA, 2
					BSF			PORTA, 3
					;---------------------
END_NUM				RETURN

;---------------------------------------------------------------------------------------------------------------
; Subrutina del Delay (base de 500 ms).

DELAY_500ms			MOVLW		.5
					MOVWF		_AUX11
_LOOP11				CALL		DELAY_100ms				
					DECFSZ		_AUX11, 1
					GOTO		_LOOP11
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Subrutina del Delay (base de 100 ms)

DELAY_100ms			MOVLW		.40
					MOVWF		_AUX1
_LOOP1				CALL		DELAY_2_5ms					; El guion bajo lo tomo como un punto o una coma (2,5 ms).
					DECFSZ		_AUX1, 1
					GOTO		_LOOP1
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Subrutina del Delay (base de 25 ms)

DELAY_25ms			MOVLW		.10
					MOVWF		_AUX22
_LOOP22				CALL		DELAY_2_5ms					; El guion bajo lo tomo como un punto o una coma (2,5 ms).
					DECFSZ		_AUX22, 1
					GOTO		_LOOP22
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Subrutina del Delay (base de 2,5 ms)

DELAY_2_5ms			MOVLW		.250
					MOVWF		_AUX2
_LOOP2				CALL		DELAY_10us					; Retardo de 10 micro segundos (us).
					DECFSZ		_AUX2, 1
					GOTO		_LOOP2
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Subrutina del Delay (base de 500 us)

DELAY_500us			MOVLW		.50
					MOVWF		_AUX33
_LOOP33				CALL		DELAY_10us				
					DECFSZ		_AUX33, 1
					GOTO		_LOOP33
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Subrutina del Delay (base de 10 us)

DELAY_10us			MOVLW		.2
					MOVWF		_AUX3				
_LOOP3				DECFSZ		_AUX3, 1
					GOTO		_LOOP3
					NOP
					RETURN

;---------------------------------------------------------------------------------------------------------------
; Rutina Principal
			
INICIO				CALL		CONFIGURACION
LOOP				CALL		TECLAS
					CALL		CONTRASEÑA
DPY					CALL		DISPLAY
					GOTO		LOOP
					END


--------------------------------------------------------------			
