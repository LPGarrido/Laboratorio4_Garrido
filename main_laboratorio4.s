;Archivo:	main_laboratorio4.s
;Dispositivo:	PIC16F887
;Autor:		Luis Garrido
;Compilador:	pic-as (v2.30), MPLABX V5.40
;
;Programa:	Contador de 4 bits en el puerto A
;Hardware:	Leds en el puerto A, Botones en RB0 y RB1
;Creado: 06 feb, 2022 
;Última modificación: 10 feb, 2022
    
    PROCESSOR 16F887
; PIC16F887 Configuration Bit Settings
; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
; -------------- MACROS --------------- 

RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   TMR_VAR
    MOVWF   TMR0	    ; configuramos tiempo de retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    ENDM 
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr			; Memoria compartida
    W_TEMP:		DS 1	
    STATUS_TEMP:	DS 1
    CUENTA:		DS 1

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
    BTFSC   RBIF	    ; Bandera  
    CALL    FUNC_INT_IOCB
    BTFSC   T0IF
    CALL    FUNC_INT_TMR0
    
    
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
    
;------SUBRUTINAS DE INTERRUPCION----------
FUNC_INT_TMR0:
    RESET_TMR0 178
    INCF    CUENTA
    MOVF    CUENTA,W	;W=CUENTA
    SUBLW   50		;W-50
    BTFSS   STATUS,2
    RETURN
    INCF    PORTD
    CLRF    CUENTA
    RETURN

FUNC_INT_IOCB:
    BANKSEL PORTB
    BTFSS   PORTB,0
    INCF    PORTA
    BTFSS   PORTB,1
    DECF    PORTA
    BCF	    RBIF
    RETURN
    
PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo
;------------- CONFIGURACION ------------
MAIN:
    CALL    CONFIG_IO	    ; Configuración de I/O
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador (4MHz)
    CALL    CONFIG_IOCB	    ; Configuración de INTERRUPT-ON-CHANGE PORTB
    CALL    CONFIG_TMR0
    CALL    CONFIG_INT	    ; Configuración de interrupciones
    BANKSEL PORTD	    ; Cambio a banco 00
    
LOOP:
    ; Código que se va a estar ejecutando mientras no hayan interrupciones
    GOTO    LOOP	    
    
;------------- SUBRUTINAS ---------------
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 256
    
    /*RESET_TMR0 178
    RETURN*/
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   178
    MOVWF   TMR0	    ; 20ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    RETURN
    
CONFIG_IOCB:
    BANKSEL IOCB
    MOVLW   0x03	    
    MOVWF   IOCB
    
    BANKSEL PORTA
    MOVF    PORTB,W	    ;Al leer termina la condicion de 'mismatch'
    BCF	    RBIF
    RETURN

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
    MOVWF   TRISA	    ; PORTA como salida
    MOVLW   0xF0
    MOVWF   TRISD	    ; PORTD como salida
    MOVLW   0xFF	    
    MOVWF   TRISB	    ; PORTB como entradas
    BCF	    OPTION_REG,7    ; PORTB pull-ups are enabled
    MOVLW   0x03	    
    MOVWF   WPUB	    ; 
    
    
    BANKSEL PORTA
    CLRF    PORTA	    ; Apagamos PORTD
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
    
END


