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
    mov cx, buffer_len   ; Number of bytes to read
    mov dx, buffer
    int 21h
    jc  error_rd           ; Jump if carry flag is set (error)
    ; AX now contains the number of bytes actually read

    ; Display the read data
    mov byte[buffer+buffer_len],13
    mov byte[buffer+buffer_len+1],10
    mov byte[buffer+buffer_len+2],'$'
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
    int 21

    call    open_file
    mov     byte[file_open_flag],1
    xor     cx,cx
    mov     cx,11
read_loop_test:
    call    get_function_values
    loop    read_loop_test

    call    close_file


    mov     dx,word[original_function_ammount_num_read]
    call    imprimenumero

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

get_function_values:
        push    cx
		cmp		byte[file_open_flag],0
		je		get_function_values_ret
get_function_values_read_file:
		mov		bx,0
        mov     cx,file_max_line_read
get_function_values_read_file_loop_start:
	;Reading the file
        push    cx
		push	bx
		call	read_file
        cmp 	ax,0 ; is EOF reached?
		je  	get_function_values_read_file_eof;Error reading the file
		jmp		get_function_values_read_file_ascii2bin
get_function_values_read_file_eof:
        pop     bx
        pop     cx

		call	close_file
		mov		byte[file_open_flag],0
		je 		get_function_values_end ;EOF reached

get_function_values_read_file_ascii2bin:

		;;Converter ASCII em numero
		xor		cx,cx ;So the loop value in correctly CL
		mov		cl,byte[file_line_buffer+15]
		sub		cl,'0'

		xor		ax,ax ;So the value is correctly AL
		mov 	al,byte[file_line_buffer+3]
		sub 	al,'0' ;; On AX contains the first value of the number

		xor		bx,bx ;So BX starts at 0
		mov		dl,10 ;; MUL Operand

		cmp cl,0
		je get_function_values_read_file_ascii2bin_loop_end ;; means CL was 0
get_function_values_read_file_ascii2bin_loop:

		mul		dl
		add		al,byte[file_line_buffer+5+bx]
        sub     al,'0'

		inc 	bx
		loop	get_function_values_read_file_ascii2bin_loop
get_function_values_read_file_ascii2bin_loop_end:
; 		;;Moves the value to the vector
		pop		bx
		mov		byte[original_function_values+bx],al

		;;Check if it's negative
		mov 	al,byte[file_line_buffer+2]
		cmp 	al,'-'
		jne 	get_function_values_read_file_loop_end
get_function_values_is_negative:
		neg		byte[original_function_values+bx]
get_function_values_read_file_loop_end:
		inc		bx ;
        pop		cx 	;If EOF not reached, recover context and keep reading
		loop	get_function_values_read_file_loop_start
get_function_values_end:
		mov		word[original_function_values_len],bx
		add		word[original_function_ammount_num_read],bx
get_function_values_ret:
        pop    cx
		ret


open_file:
		mov 	dx,file_values ;Filename
		mov 	al,0 ; access mode, 0 = read, 1 = write, 2 = read/write
		mov 	ah, 3dh ;int21h function number
		int 	21h

		mov		word[file_handler],ax

		ret

read_file:
	;File with no error means AX contains the file handler pointer
		mov 	bx,word[file_handler] ; passing the handler to BX
		mov 	cx,file_line_len ;numbers of byte to read
		mov 	dx,file_line_buffer ;pointer to buffer

		mov 	ah,3fh ;function 3fh
		int		21h

		ret

close_file:
	;;Carry set if failed to close
	    mov ah, 3eh         ; Close file function
		mov bx,word[file_handler]
		int 21h

		ret

segment data
    ; Aqui entram as definições das variáveis do programa
    ; 0dh e 0ah são necessários para finalizar e pular uma linha e '$' marca o término de uma string
    CR		equ 		0dh
    LF		equ 		0ah
    mensagem	db		 'Oi, olha eu aqui, to nada hehehe',CR,LF,'$'
    saida: db '00000',13,10,'$'
    tam_vector equ 5h

    filename db 'C:sinalep.txt', 0
    msg_op      db 'File opened successfully', 13, 10, '$'
    msg_rd      db 'File read successfully', 13, 10, '$'
    msg_cl      db 'File closed successfully', 13, 10, '$'
    err_msg_op  db 'Error opening file', 13, 10, '$'
    err_msg_rd  db 'Error reading file', 13, 10, '$'
    err_msg_cl  db 'Error closing file', 13, 10, '$'
    err_num  resw 1
    file_handle resw 1
    buffer      resb 7  ; Buffer to store data read from the file buffer_len + 3
    buffer_len  equ  4 



    ;Declarando variáveis necessárias para calcular os pontos do grafico
	file_line_len							equ			18
	file_line_buffer						resb		18
	file_max_line_read						equ			485
	file_handler							resw		1
	file_bytes_read							resw		1
	file_values								db 			'C:sinalep.txt',0
    file_open_flag							db			0


    original_function_values 				resb 		485
	original_function_values_truncated 		resb 		485
	original_function_values_len			dw			0
    original_function_ammount_num_read      dw          0

; definição da pilha com total de 256 bytes
segment stack stack
    resb 256
stacktop: