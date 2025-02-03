segment code
..start:
    ; iniciar os registros de segmento DS e SS e o ponteiro de pilha SP
    mov 		ax,data
    mov 		ds,ax
    mov 		ax,stack
    mov 		ss,ax
    mov 		sp,stacktop

    ; Open the file
    mov ah, 3Dh         ; Open file function
    mov al, 0           ; Open for reading
    mov dx, filename
    int 21h
    jc  error_op           ; Jump if carry flag is set (error)
    mov word[file_handle], ax

    ; Display success message
    mov ah, 9
    mov dx, msg_op
    int 21h

    ; Read from the file
    mov ah, 3Fh         ; Read file function
    mov bx,word[file_handle]
    mov cx, 128         ; Number of bytes to read
    mov dx, buffer
    int 21h
    jc  error_rd           ; Jump if carry flag is set (error)
    ; AX now contains the number of bytes actually read

    ; Display the read data
    mov byte[buffer+128],13
    mov byte[buffer+129],10
    mov byte[buffer+130],'$'
    mov ah, 09h         ; Teletype output function
    int 21h             ; BIOS interrupt to display character

    ; Display success message
    mov ah, 9
    mov dx, msg_rd
    int 21h

    ; Close the file
    mov ah, 3Eh         ; Close file function
    mov bx,word[file_handle]
    int 21h
    jc  error_cl           ; Jump if carry flag is set (error)

    ; Display success message
    mov ah, 9
    mov dx, msg_cl
    int 21h

    ; Exit program
    mov ax, 4C00h
    int 21h

error_op:
    ; Display error message
    mov     word[err_num], ax
    mov     ah, 9
    mov     dx, err_msg_op
    int     21h

    mov    dx,word[err_num]
    call    imprimenumero

    ; Terminar o programa e voltar para o sistema operacional
    mov		ah,4ch ; função 4ch da interrupção 21h do DOS (termina o programa)
    int     	21h

error_rd:
    ; Display error message
    mov     word[err_num], ax
    mov     ah, 9
    mov     dx, err_msg_rd
    int     21h

    mov    dx,word[err_num]
    call    imprimenumero

    ; Terminar o programa e voltar para o sistema operacional
    mov		ah,4ch ; função 4ch da interrupção 21h do DOS (termina o programa)
    int     	21h

    ; definicao das variaveis

error_cl:
    ; Display error message
    mov     word[err_num], ax
    mov     ah, 9
    mov     dx, err_msg_cl
    int     21h

    mov    dx,word[err_num]
    call    imprimenumero

    ; Terminar o programa e voltar para o sistema operacional
    mov		ah,4ch ; função 4ch da interrupção 21h do DOS (termina o programa)
    int     	21h

    ; definicao das variaveis


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
segment data
    ; Aqui entram as definições das variáveis do programa
    ; 0dh e 0ah são necessários para finalizar e pular uma linha e '$' marca o término de uma string
    CR		equ 		0dh
    LF		equ 		0ah
    mensagem	db		 'Oi, olha eu aqui, to nada hehehe',CR,LF,'$'
    saida: db '00000',13,10,'$'
    tam_vector equ 5h

    filename db 'C:example.txt', 0
    msg_op      db 'File opened successfully', 13, 10, '$'
    msg_rd      db 'File read successfully', 13, 10, '$'
    msg_cl      db 'File closed successfully', 13, 10, '$'
    err_msg_op  db 'Error opening file', 13, 10, '$'
    err_msg_rd  db 'Error reading file', 13, 10, '$'
    err_msg_cl  db 'Error closing file', 13, 10, '$'
    err_num  resw 1
    file_handle resw 1
    buffer      resb 131  ; Buffer to store data read from the file
; definição da pilha com total de 256 bytes
segment stack stack
    resb 256
stacktop: