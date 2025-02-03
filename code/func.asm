segment code
..start:
    mov ax, dados
    mov ds, ax
    mov ax, stack
    mov ss,ax
    mov sp,stacktop

    ; AQUI COMECA A EXECUCAO DO PROGRAMA PRINCIPAL
    mov dx,mensini ; mensagem de inicio
    mov ah,9
    int 21h
    mov ax,0 ; primeiro elemento da série
    mov bx,1 ; segundo elemento da série


L10:
    mov dx,ax
    add dx,bx ; calcula novo elemento da série
    mov ax,bx
    mov bx,dx
    cmp dx, 0x0008
    jb L10


; AQUI TERMINA A EXECUCAO DO PROGRAMA PRINCIPAL
exit:
    call imprimenumero
    mov dx,mensfim ; mensagem de fim
    mov ah,9
    int 21h

    quit:
    mov ah,4CH ; retorna para o DOS com código 0
    int 21h

imprimenumero:
    ;;Aqui, você deve salvar o contexto

    xor cx,cx ; "zero" CX
    mov cx,tam_vector ; EQU é uma constante, é substituido pelo valor em tempo de compilação

    mov ax,dx ;; Number on DX
    mov di,saida

    push di
    push bp
    call bin2ascii_loop

    pop bp ;recupera antigo valor de "bp"
    pop di ;recupera antigo valor de "di"

    mov dx,saida
    mov ah,9
    int 21h
    ;;recuperar o contexto
    ret

bin2ascii_loop:
    mov bp, sp ;bp aponta para SP, de maneira que conseguimos andar sob SP
    mov di,[bp+4] ; acessamos a "saida" [bp+2] é o antigo valor de BP, e [bp] é o endereço de retorno para a função que chamou "bin2ascii_loop"

    add di,cx
    dec di ;

    mov bx,10
    xor dx,dx ;zerar o registrador para ter certeza que ambos os bytes são 0

    div bx ; DIV de duas words (2 bytes), o resultado fica em AX e o resto fica em DX, como o Resto nesse caso ocupa 1 byte, logo acesso somente DL
    add dl,'0'
    mov [di],dl

    loop bin2ascii_loop ; Decrementa de CX

    ret


segment dados ;segmento de dados inicializados
    mensini: db 'Programa que calcula a Serie de Fibonacci. ',13,10,'$'
    mensfim: db 'bye',13,10,'$'
    saida: db '00000',13,10,'$'
    tam_vector equ 5h

segment stack stack
    resb 256 ; reserva 256 bytes para formar a pilha
stacktop: ; posição de memória que indica o topo da pilha=SP
