segment code
..start:
; iniciar os registros de segmento DS e SS e o ponteiro de pilha SP
mov 		ax,data
mov 		ds,ax
mov 		ax,stack
mov 		ss,ax
mov 		sp,stacktop

; codigo do programa

;Não é possivel usar ADD ou INC nas varíaveis V1,V2,VRES
;É necessário usar SI,DI e/ou BX para operar em cima dos endereços de memória
mov si,V1
mov di,V2
mov bx,VRES

mov ax,[si]
mov dx,[di]
mul dx    ; DX:AX = AX * OPERADOR , nesse caso OPERADOR=di (valor armazenado nois 2 primeiros bytes)
;caso tenha OverFlow(OF) o restante dos bits são armazenados em DX

mov [bx],ax ;Armazeno nos 2 bits de baixa ordem
add bx,2
mov [bx], dx;Armazeno nos 2 bits de alta ordem

add bx,2
add si,2
add di,2

mov ax,[si]
mov dx,[di]
mul dx    ; DX:AX = AX * OPERADOR , nesse caso OPERADOR=dx (valor armazenado nois 2 primeiros bytes)
;caso tenha OverFlow(OF) o restante dos bits são armazenados em DX

mov [bx],ax ;Armazeno nos 2 bits de baixa ordem
add bx,2
mov [bx], dx;Armazeno nos 2 bits de alta ordem

add bx,2
add si,2
add di,2

mov ax,[si]
mov dx,[di]
mul dx    ; DX:AX = AX * OPERADOR , nesse caso OPERADOR=dx (valor armazenado nois 2 primeiros bytes)
;caso tenha OverFlow(OF) o restante dos bits são armazenados em DX

mov [bx],ax ;Armazeno nos 2 bits de baixa ordem
add bx,2
mov [bx], dx;Armazeno nos 2 bits de alta ordem

add bx,2
add si,2
add di,2

mov ax,[si]
mov dx,[di]
mul dx    ; DX:AX = AX * OPERADOR , nesse caso OPERADOR=dx (valor armazenado nois 2 primeiros bytes)
;caso tenha OverFlow(OF) o restante dos bits são armazenados em DX

mov [bx],ax ;Armazeno nos 2 bits de baixa ordem
add bx,2
mov [bx], dx;Armazeno nos 2 bits de alta ordem

add bx,2
add si,2
add di,2

mov ax,[si]
mov dx,[di]
mul dx    ; DX:AX = AX * OPERADOR , nesse caso OPERADOR=dx (valor armazenado nois 2 primeiros bytes)
;caso tenha OverFlow(OF) o restante dos bits são armazenados em DX

mov [bx],ax ;Armazeno nos 2 bits de baixa ordem
add bx,2
mov [bx], dx;Armazeno nos 2 bits de alta ordem

; Terminar o programa e voltar para o sistema operacional
;mov ah,4ch ;função 4ch (h é de hexadecimal), termina o programa
int 3



; definicao das variaveis
segment data
; Aqui entram as definições das variáveis do programa
V1      dw          1,2,3,4,5
V2      dw          6,7,8,9,10
VRES    resd        5

CR		equ 		0dh
LF		equ 		0ah
mensagem	db		 'Oi, olha eu aqui, to nada hehehe',CR,LF,'$'

; definição da pilha com total de 256 bytes
segment stack stack
    resb 256
stacktop: