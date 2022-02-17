;Archivo:	main_laboratorio4.s
;Dispositivo:	PIC16F887
;Autor:		Luis Garrido
;Compilador:	pic-as (v2.30), MPLABX V5.40
;
;Programa:	Contador de 4 bits, Contador de segundos, Display que muestra en conteo de segundos
;Hardware:	Leds en el PORTA y PORTB (bit 0 a 3), Botones RB6 y RB7; Display en paralelo PORTC con conexión al RD0 y RD1
;Creado: 06 feb, 2022 
;Última modificación: 10 feb, 2022
    
PROCESSOR 16F887
; PIC16F887 Configuration Bit Settings
; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
; -------------- MACROS --------------- 

RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   TMR_VAR	    ; 
    MOVWF   TMR0	    ; TMR0= TMR_VAR - configuramos tiempo de retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    ENDM 
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr			; Memoria compartida
    W_TEMP:		DS 1	
    STATUS_TEMP:	DS 1
    
PSECT udata_bank0		; Memoria en el bank0
    CUENTA:		DS 1	; CUENTA para el contador de int del tmr0
    UNIDADES:		DS 1	; UNIDADES de los segundos
    DECENAS:		DS 1	; DECENAS de los segundos
    VALOR:		DS 1	; VALOR a mostrar
    BANDERAS:		DS 1	; BANDERAS
    NIBBLES:		DS 2	; NIBBLES alto y bajo del valor a mostrar
    DISPLAY:		DS 2	; DISPLAY - valores a colocar en el display

PSECT resVect, class=CODE, abs, delta=2
ORG 00h				; posición 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL MAIN		; Cambio de pagina
    GOTO    MAIN
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h				; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    BTFSC   RBIF	    ; RBIF=1 FUNC_INT_IOCB; RBIF=0 Evaluar
    CALL    FUNC_INT_IOCB   ; Funcion INT IOCB
    BTFSC   T0IF	    ; T0IF=1 FUNC_INT_TMR0; T0IF=0 Recuperar W y STATUS
    CALL    FUNC_INT_TMR0   ; Funcion INT TMR0
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
    
;------SUBRUTINAS DE INTERRUPCION----------
FUNC_INT_TMR0:
    RESET_TMR0 178	    ;Resetear TMR0 con un valor de 178
    CALL    MOSTRAR_VALORES ;MOSTRAR VALORES en el display
    INCF    CUENTA	    ;Incrementar CUENTA cada vez que se llegue a la int del tmr0
    MOVF    CUENTA,W	    ;W=CUENTA
    SUBLW   50		    ;W-50
    BTFSS   STATUS,2	    ;Si Z=0, RETURN; si Z=1, funcion
    RETURN		    ;regresa
    INCF    PORTB	    ;incrementar PORTB
    INCF    UNIDADES	    ;Incrementar unidades
    CLRF    CUENTA	    ;Limpiar cuenta
    RETURN		    ;regresa

FUNC_INT_IOCB:
    BANKSEL PORTB	    ;
    BTFSS   PORTB,6	    ;Si RB6=0, INCF PORTA; si RB6=1, Evaluar
    INCF    PORTA	    ;PORTA+1
    BTFSS   PORTB,7	    ;Si RB7=0, DECF PORTA; si RB7=1, Evaluar
    DECF    PORTA	    ;PORTA-1
    BCF	    RBIF	    ;Limpiar la bandera de interupción
    RETURN
    
PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo
;------------- TABLA ------------
TABLA_7SEG:
    CLRF    PCLATH	; Limpiar PCLATH
    BSF	    PCLATH,0	; PCLATH = 01	PC = 02
    ANDLW   0x0F	; Solo permitir valores iguales o menores a 0x0F
    ADDWF   PCL,F	; PC = PCLATH + PCL + W
    ;HGFEDCBA		
    RETLW   00111111B	; 0
    RETLW   00000110B	; 1
    RETLW   01011011B	; 2
    RETLW   01001111B	; 3
    RETLW   01100110B	; 4
    RETLW   01101101B	; 5
    RETLW   01111101B	; 6
    RETLW   00000111B	; 7
    RETLW   01111111B	; 8
    RETLW   01100111B	; 9
    RETLW   01110111B	; A
    RETLW   01111100B	; B
    RETLW   00111001B	; C
    RETLW   01011110B	; D
    RETLW   01111001B	; E
    RETLW   01110001B	; F
 
 ;------------- CONFIGURACION ------------
MAIN:
    CALL    CONFIG_IO	    ; Configuración de I/O
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador (4MHz)
    CALL    CONFIG_IOCB	    ; Configuración de INTERRUPT-ON-CHANGE PORTB
    CALL    CONFIG_TMR0	    ; Configuración de TMR0
    CALL    CONFIG_INT	    ; Configuración de interrupciones
    BANKSEL PORTD	    ; Cambio a banco 00
    
LOOP:
    ; Código que se va a estar ejecutando mientras no hayan interrupciones
    CALL    CHECK_UNI	    ;Chequeo Unidades
    CALL    CHECK_DEC	    ;Chequeo Decenas
    
    MOVF    DECENAS,W	    ;W = DECENAS (0-6)
    MOVWF   VALOR	    ;VALOR = DECENAS (0-6) - 0000 (Num 0 al 6)
    SWAPF   VALOR	    ;VALOR = (Num 0 al 6) 0000
    MOVF    UNIDADES,W	    ;W = UNIDADES
    ADDWF   VALOR	    ;VALOR = (Num 0 al 6) (Num 0 al 9)
    
    CALL    OBTENER_NIBBLE  ;Obtener nibbles
    CALL    SET_DISPLAY	    ;Set Display
    
    GOTO    LOOP	    
    
;------------- SUBRUTINAS ---------------
CHECK_UNI:
    MOVF    UNIDADES,W	;W=UNIDADES
    SUBLW   10		;W-10 = UNIDADES - 10
    BTFSS   STATUS,2	;Si Z=0, regresa; si Z=1 funcion
    RETURN		;regresa
    INCF    DECENAS	;incrementar decenas
    CLRF    UNIDADES	;limpiar unidades
    RETURN
    
CHECK_DEC:
    MOVF    DECENAS,W	;W=DECENAS
    SUBLW   6		;W = DECENAS - 6
    BTFSS   STATUS,2	;Si Z=0, regresa; si Z=1 funcion
    RETURN		;regresa
    CLRF    DECENAS	;limpiar decenas
    RETURN		;regresa

CONFIG_TMR0:
    BANKSEL OPTION_REG	; cambiamos de banco
    BCF	    T0CS	; TMR0 como temporizador
    BCF	    PSA		; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		; PS<2:0> -> 111 prescaler 1 : 256
    
    BANKSEL TMR0	; cambiamos de banco
    MOVLW   178
    MOVWF   TMR0	; 20ms retardo
    BCF	    T0IF	; limpiamos bandera de interrupción
    RETURN
    
CONFIG_IOCB:
    BANKSEL IOCB
    MOVLW   0xC0	
    MOVWF   IOCB	;Habilitamos IOC para los bit RB6 y RB7
    
    BANKSEL PORTA
    MOVF    PORTB,W	;Al leer termina la condicion de 'mismatch'
    BCF	    RBIF	;Limpiar la bandera
    RETURN		;regresar

CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 1
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BSF	    OSCCON, 5
    BCF	    OSCCON, 4	    ; IRCF<2:0> -> 110 4MHz
    RETURN
    
 CONFIG_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	    ; I/O digitales
    
    BANKSEL TRISA
    MOVLW   0xF0
    MOVWF   TRISA	    ; PORTA como salida (RA0,RA1,RA2,RA3)
    MOVLW   0xF0	    
    MOVWF   TRISB	    ; PORTB como entradas (RB6,RB7) y salidas (RB3,RB2,RB1,RB0)
    CLRF    TRISC	    ; PORTC como salida
    MOVLW   0xFC	    
    MOVWF   TRISD	    ; PORTD como salida (RD0,RD1)
    BCF	    OPTION_REG,7    ; PORTB pull-ups are enabled
    MOVLW   0xC0	    
    MOVWF   WPUB	    ; Habilita RB6 y RB7 los pull-ups internos
    
    
    BANKSEL PORTA
    CLRF    PORTA	    ; Apagamos PORTA, PORTB, PORTC, PORTD
    CLRF    PORTB	    
    CLRF    PORTC
    CLRF    PORTD
    RETURN
    
CONFIG_INT:
    BANKSEL INTCON
    BSF	    GIE		    ; Habilitamos interrupciones
    BSF	    RBIE	    ; Habilitamos interrupcion PORTB Change Interrupt
    BCF	    RBIF	    ; Limpiamos bandera de PORTB Change Interrupt 
    BSF	    T0IE	    ; Habilitamos interrupcion TMR0
    BCF	    T0IF	    ; Limpiamos bandera de TMR0
    RETURN
   
    
OBTENER_NIBBLE:		    ;VALOR = 0110 1101
    MOVLW   0x0F	    ;W = 0000 1111
    ANDWF   VALOR,W	    ;AND Valor y W = 0000 Nibble_bajo
    MOVWF   NIBBLES	    ;Guardar valor en NIBBLES
    
    MOVLW   0xF0	    ;W = 1111 0000
    ANDWF   VALOR,W	    ;AND Valor y W = Nibble_alto 0000
    MOVWF   NIBBLES+1	    ;Guardar valor en NIBBLES+1
    SWAPF   NIBBLES+1	    ;NIBBLES+1 = 0000 Nibble_alto
    RETURN
    
SET_DISPLAY:
    MOVF    NIBBLES,W	    ;W = NIBBLES
    CALL    TABLA_7SEG	    ;Llamar la tabla de 7seg
    MOVWF   DISPLAY	    ;DISPLAY = valor con el que regresa la tabla
    
    MOVF    NIBBLES+1,W	    ;W = NIBBLES+1
    CALL    TABLA_7SEG	    ;Llamar la tabla de 7seg
    MOVWF   DISPLAY+1	    ;DISPLAY+1 = alor con el que regresa la tabla
    
    RETURN
    
MOSTRAR_VALORES:    
    BCF	    PORTD,0	    ;Limpiar RD0
    BCF	    PORTD,1	    ;Limpiar RD1
    BTFSC   BANDERAS,0	    ;Si Banderas0=1, GOTO DISPLAY_1; si Banderas0=0 DISPLAY_0
    GOTO    DISPLAY_1
    ;GOTO    DISPLAY_0
    
    DISPLAY_0:
	MOVF    DISPLAY,W   ;W = DISPLAY
	MOVWF   PORTC	    ;PORTC = DISPLAY
	BSF	PORTD,1	    ;RD1=1 
	BSF	BANDERAS,0  ;BANDERAS0=1 - para que cuando regrese ejecute luego el DISPLAY_1
	RETURN

    DISPLAY_1:
	MOVF    DISPLAY+1,W ;W = DISPLAY+1
	MOVWF   PORTC	    ;PORTC = DISPLAY+1
	BSF	PORTD,0	    ;RD0=1
	BCF	BANDERAS,0  ;BANDERAS0=0 - para que cuando regrese ejecute luego el DISPLAY_0
	RETURN
    
    
    
END


