segment code
..start:
; iniciar os registros de segmento DS e SS e o ponteiro de pilha SP
    mov ax,data
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,stacktop


    mov bx,three_chars ;Aponta para o endereço do primeiro byte do vetor "three_chars"
    mov ah,1 ; função 1 da interrupção 21h (h é de hexadecimal) ( espera um caracter do teclado ser digitado )
    int 21h ; função do dos de entrada de carcater. Retorna em Als

    dec al ; diminui o valor do caracter em um ( o caracter digitado vem para o AL)
    mov [bx],al ; move o valor de AL para o endereco apontado por BX
    inc bx ; incrementa BX para apontar para o próximo byte do vetor the 3 bytes


    ;REPETE
    int 21h
    dec al
    mov [bx],al
    inc bx

    ;REPETE
    int 21h
    dec al
    mov [bx],al

    ;PRINTA
    mov dx,display_string
    mov ah,9 ;função 9 (printa a string na tela)
    int 21h

    ; Terminar o programa e voltar para o sistema operacional
    mov ah,4ch ;função 4ch (h é de hexadecimal), termina o programa
    int 21h

segment data
    CR equ 0dh
    LF equ 0ah
    display_string db CR,LF
    three_chars resb 3
                db '$'

segment stack stack
    resb 256
stacktop: