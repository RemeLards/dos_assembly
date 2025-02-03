segment code
..start:
    ; iniciar os registros de segmento DS e SS e o ponteiro de pilha SP
    mov 		ax,data
    mov 		ds,ax
    mov 		ax,stack
    mov 		ss,ax
    mov 		sp,stacktop

    ; codigo do programa
    ; aqui entram as instruções do programa
    mov		ah,9 ; função 9 da interrupção 21h do DOS (printa uma string)
    mov		dx,mensagem
    int		21h


    ; Terminar o programa e voltar para o sistema operacional
    mov		ah,4ch ; função 4ch da interrupção 21h do DOS (termina o programa)
    int     	21h

    ; definicao das variaveis
    segment data
    ; Aqui entram as definições das variáveis do programa
    ; 0dh e 0ah são necessários para finalizar e pular uma linha e '$' marca o término de uma string
    CR		equ 		0dh
    LF		equ 		0ah
    mensagem	db		 'Oi, olha eu aqui, to nada hehehe',CR,LF,'$'

; definição da pilha com total de 256 bytes
segment stack stack
    resb 256
stacktop: