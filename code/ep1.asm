; versão de 10/05/2007
; corrigido erro de arredondamento na rotina line.
; circle e full_circle disponibilizados por Jefferson Moro em 10/2009
;
segment code
..start:
		mov 		ax,data
		mov 		ds,ax
		mov 		ax,stack
		mov 		ss,ax
		mov 		sp,stacktop

; salvar modo corrente de video(vendo como está o modo de video da maquina)
		mov  		ah,0Fh
		int  		10h
		mov  		[modo_anterior],al   

; alterar modo de video para gráfico 640x480 16 cores
		mov     	al,12h
		mov     	ah,0
		int     	10h

; salvando estado inicial do mouse
		; mov			ax,data
		; mov 		es,ax ;usa ES:DX, mas como a variável está em DS, fazemos ES apontar para DS
		; mov			dx,initial_mouse_state
		; mov 		ax, 0016h       ;funcão "16h" da interrupção "33h"
		; int 		33h              

; inicializa o drive do mouse
		mov 		ax, 0
		int 		33h

; posiciona acima do meio da tela para não estragar o desenho da linha do centro
		mov 		ax,4
		mov 		cx,100 	;X
		mov 		dx,30	;Y
		int 		33h

; mostrar o cursor na tela
		mov 		ax, 1
		int 		33h

; O range horizontal é de 640 pixeis por padrão, mas vou setar para 640 por boa prática
		mov 		al,7 ;Numero da função de interrupcao
		mov 		cx,0 ;Range mínimo
		mov 		dx,639 ;Range máximo
		int 		33h

; Aumentando o range vertical do mouse ( uma vez que o padrão é 200 pixeis e a janela é de 480)
		mov 		al,8 ;Numero da função de interrupcao
		mov 		cx,0 ;Range mínimo
		mov 		dx,479 ;Range máximo
		int 		33h
		
menu_start:
	;Doing Borders
        call    draw_border
        call    draw_buttons_borders

        call    draw_graph_borders
		call	draw_graph_text


menu_loop:
	;Printing text on the boxes (need to draw every loop since the color CAN be changed any time)
        call    draw_buttons_text
	;Checks mouse info
		call	get_mouse_info
	
	;Executes button IF it's between X and Y
		call	button_press

        jmp 	menu_loop


execute_convolution_function:
	cmp 	word[convolution_function_option],0
	je 		execute_convolution_function_ret

execute_convolution_function_fir1:
	cmp 	word[convolution_function_option],1
	jne 	execute_convolution_function_fir2
	; call	convolute_fir1
	jmp 	execute_convolution_function_ret

execute_convolution_function_fir2:
	cmp 	word[convolution_function_option],2
	jne		execute_convolution_function_fir3
	; call	convolute_fir2
	jmp 	execute_convolution_function_ret

execute_convolution_function_fir3:
	cmp 	word[convolution_function_option],3
	jne 	execute_convolution_function_negative_one_n_power
	call	convolute_fir3
	jmp 	execute_convolution_function_ret

execute_convolution_function_negative_one_n_power:
	cmp 	word[convolution_function_option],4
	jne 	execute_convolution_function_ret
	call	convolute_negative_one_n_power
	jmp 	execute_convolution_function_ret

execute_convolution_function_ret:
	ret

convolute_fir3:
	push	bp
	mov		bp,sp
convolute_fir3_values:
	mov		cx,word[original_function_values_len]
	mov		bx,0
convolute_fir3_values_loop:
	push	cx
	push	bx
convolute_fir3_values_calculate_window_values:
	movsx	cx,byte[reflected_fir3_function_len]

	mov		si,original_function_values ; Gonna compare pointer values
	add		si,[bp-4] ;Makes the pointer walk

	xor		ax,ax	  ;Makes AX = 0
	xor		dx,dx	  ;Makes DX = 0
	xor		bx,bx	  ;Makes BX = 0
convolute_fir3_values_calculate_window_values_loop:
convolute_fir3_values_calculate_window_values_loop_check_si_going_beyond:

	mov		di,original_function_values
	add		di,word[original_function_values_len]
	dec		di ; makes DI point to the last "original_function_values" memory address

	cmp		si,di
	jg		convolute_fir3_values_calculate_window_values_loop_end

convolute_fir3_values_calculate_window_values_loop_mid:
	mov 	al,byte[si]
	imul	byte[reflected_fir3_function+bx]

	add		dl,al

convolute_fir3_values_calculate_window_values_loop_end:

	; cmp		word[bp-4],1
	; je		convolute_debug
	inc		bx
	dec		si

	cmp		si,original_function_values
	jl		convolute_fir3_values_loop_end ; Pointer points to the memory address behind "original_function_values"
	
	loop 	convolute_fir3_values_calculate_window_values_loop

convolute_fir3_values_loop_end:
	pop		bx
	pop		cx

	mov		byte[convoluted_function_values+bx],dl
	inc		bx

	loop	convolute_fir3_values_loop

	mov		word[convoluted_function_values_len],bx

; convolute_debug:
; 	jmp quit
convolute_fir3_ret:
	pop		bp
	ret

convolute_negative_one_n_power:
convolute_negative_one_n_power_values:
	mov		cx,word[original_function_values_len]
	mov		bx,0
convolute_negative_one_n_power_values_loop:

	mov		ax,word[original_function_values+bx]
	mov		word[convoluted_function_values+bx],ax

	test	bx,1 ; Test if the LSB is 0 or 1
	jz		convolute_negative_one_n_power_values_loop_tail
convolute_negative_one_n_power_values_loop_negate:
	neg		word[convoluted_function_values+bx]
convolute_negative_one_n_power_values_loop_tail:
	inc		bx
	loop	convolute_negative_one_n_power_values_loop
	
	mov		word[convoluted_function_values_len],bx
convolute_negative_one_n_power_ret:
	ret


get_function_values:
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
		jnc 	get_function_values_read_file_eof_test
		je 		get_function_values_end;Error reading the file
get_function_values_read_file_eof_test:
		cmp 	ax,0 ; is EOF reached?
		jne		get_function_values_read_file_ascii2bin
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
		ret


draw_convoluted_function:
		push 	bp
		mov	 	bp,sp
		pushf                        ;coloca os flags na pilha
;redraw the graphs, so this function can be reused
;"Cor" var needs to be set before using this function 
		cmp 	word[convoluted_function_values_len],0
		je		draw_convoluted_function_end
draw_convoluted_function_truncate_values:
;;Trucating values so graph fits on the scale and window
		mov		cx,word[convoluted_function_values_len]
		mov		bx,0
		xor		ax,ax
draw_convoluted_function_truncate_values_loop:

		mov		al,byte[convoluted_function_values+bx]
		sar		al,1 ;bitshift that mantains sign Shift Aritmetic Right
		mov		byte[convoluted_function_values_truncated+bx],al

		inc 	bx
		loop	draw_convoluted_function_truncate_values_loop

;Drawing a line to test it
		mov		cx,word[convoluted_function_values_len]
		mov		bx,0

;****************************IMPORANT****************************	
;For some weird reason when using "call plot_xy" it was not working properly
;Looking like it was changing the state of the pointer SP/BP and not retuning properly (program freezing)
;When I tried pushing every register before the function call, and then poping on the function end
;It worked, so it will stay this way (need to do ASAP)
;****************************************************************
draw_convoluted_function_loop:
		mov		ax,word[convolution_graph_origin]
		add		ax,bx

		push	ax	;Puts X on the stack

		movsx	ax,byte[convoluted_function_values_truncated+bx] ; Moves with sign extension, replicates the most significant bit to know if its "neg" or "pos"
		add		ax,word[convolution_graph_origin+2] ; Origin reference pixel
		mov		dx,word[graph_height] ; Adds origin offset 
		shr		dx,1
		add 	ax,dx


		push	ax ;Puts Y on the stack

		call 	plot_xy

		inc 	bx
		loop 	draw_convoluted_function_loop
;****************************MAGIC*******************************
		
draw_convoluted_function_end:
		popf
		pop		bp
		ret		


draw_original_function:
		push 	bp
		mov	 	bp,sp
		pushf                        ;coloca os flags na pilha
;redraw the graphs, so this function can be reused
;"Cor" var needs to be set before using this function 
		; cmp		byte[file_open_flag],0
		; je		draw_original_function_end
draw_original_function_truncate_values:
;;Trucating values so graph fits on the scale and window
		mov		cx,word[original_function_values_len]
		mov		bx,0
		xor		ax,ax
draw_original_function_truncate_values_loop:

		mov		al,byte[original_function_values+bx]
		sar		al,1 ;bitshift that mantains sign Shift Aritmetic Right
		mov		byte[original_function_values_truncated+bx],al

		inc 	bx
		loop	draw_original_function_truncate_values_loop

;Drawing a line to test it
		mov		cx,word[original_function_values_len]
		; mov		cx,70
		mov		bx,0

;****************************IMPORANT****************************	
;For some weird reason when using "call plot_xy" it was not working properly
;Looking like it was changing the state of the pointer SP/BP and not retuning properly (program freezing)
;When I tried pushing every register before the function call, and then poping on the function end
;It worked, so it will stay this way (need to do ASAP)
;****************************************************************
draw_original_function_loop:
		mov		ax,word[original_graph_origin]
		add		ax,bx

		push	ax	;Puts X on the stack

		movsx	ax,byte[original_function_values_truncated+bx] ; Moves with sign extension, replicates the most significant bit to know if its "neg" or "pos"
		add		ax,word[original_graph_origin+2] ; Origin reference pixel
		mov		dx,word[graph_height] ; Adds origin offset 
		shr		dx,1
		add 	ax,dx


		push	ax ;Puts Y on the stack

		call 	plot_xy

		inc 	bx
		loop 	draw_original_function_loop
;****************************MAGIC*******************************
		
draw_original_function_end:
		popf
		pop		bp
		ret

;Execute Buttons Routine
execute_abrir:
		mov 	byte[abrir_color],amarelo
		mov 	byte[arrow_color],branco
		mov 	byte[fir1_color],branco
		mov 	byte[fir2_color],branco
		mov 	byte[fir3_color],branco
		mov 	byte[negative_one_n_power_color], branco
		mov 	byte[sair_color],branco
execute_abrir_open_file:
		cmp		byte[file_open_flag],1			;file open
		je		execute_abrir_close_existing_file
		cmp		word[original_function_values_len],0 ;file closed but values are still present
		jg		execute_abrir_draw_after_closing_existing_file
		jmp		execute_abrir_can_open_file
execute_abrir_close_existing_file:
		call	close_file
		mov		word[original_function_ammount_num_read],0
		; ;;Erase old graphs
execute_abrir_draw_after_closing_existing_file:
		mov 	al,preto
		mov 	byte[cor],al
		call	draw_original_function
		call	draw_convoluted_function
		call	draw_graph_borders

		mov		word[convolution_function_option],0
		jc		execute_abrir_ret
execute_abrir_can_open_file:		
;;Opening the file
		mov		byte[file_open_flag],1
		call 	open_file
		jnc 	execute_abrir_get_initial_function_values
		jmp		execute_abrir_ret	;Error with the file
execute_abrir_get_initial_function_values:
		call	get_function_values

		mov 	al,byte[original_function_color]
		mov 	byte[cor],al
		call	draw_original_function

execute_abrir_ret:
		ret

execute_arrow:
	;Pinto todos de branco (pra não precisar salvar qual era o que estava pintado)
	;Menos o botão que foi clicado

		mov 	byte[abrir_color],branco
		mov 	byte[arrow_color],amarelo
		mov 	byte[fir1_color],branco
		mov 	byte[fir2_color],branco
		mov 	byte[fir3_color],branco
		mov 	byte[negative_one_n_power_color], branco
		mov 	byte[sair_color],branco
	
execute_arrow_check_original_len:
		cmp		word[original_function_values_len],0
		je		execute_arrow_ret
execute_arrow_erase_original_graph:
	;;Erase original old graph
		mov 	al,preto
		mov 	byte[cor],al
		call	draw_original_function
		call	draw_graph_borders
		
execute_arrow_check_convoluted_len:
		cmp		word[convolution_function_option],0
		je		execute_arrow_draw_graphs

execute_arrow_erase_convoluted_graph:
	;;Erase convoluted old graph
		mov 	al,preto
		mov 	byte[cor],al
		call	draw_convoluted_function
		call	draw_graph_borders
execute_arrow_draw_graphs:
		call	get_function_values
execute_arrow_draw_next_original_graph:
		mov 	al,byte[original_function_color]
		mov 	byte[cor],al
		call	draw_original_function
		cmp		word[convolution_function_option],0
		je		execute_arrow_ret
execute_arrow_draw_next_convoluted_graph:
		call	execute_convolution_function
		mov 	al,byte[original_function_color]
		mov 	byte[cor],al
		call	draw_convoluted_function
	;retorno pro loop do menu

execute_arrow_ret:
		ret

execute_fir1:
	;Pinto todos de branco (pra não precisar salvar qual era o que estava pintado)
	;Menos o botão que foi clicado

		mov 	byte[abrir_color],branco
		mov 	byte[arrow_color],branco
		mov 	byte[fir1_color],amarelo
		mov 	byte[fir2_color],branco
		mov 	byte[fir3_color],branco
		mov 	byte[negative_one_n_power_color], branco
		mov 	byte[sair_color],branco

	;; Faco o que a opcao deve fazer
	;...
	;...
	;...

	;retorno pro loop do menu
	ret

execute_fir2:
	;Pinto todos de branco (pra não precisar salvar qual era o que estava pintado)
	;Menos o botão que foi clicado

	mov 	byte[abrir_color],branco
	mov 	byte[arrow_color],branco
	mov 	byte[fir1_color],branco
	mov 	byte[fir2_color],amarelo
	mov 	byte[fir3_color],branco
	mov 	byte[negative_one_n_power_color], branco
	mov 	byte[sair_color],branco

	;; Faco o que a opcao deve fazer
	;...
	;...
	;...

	;retorno pro loop do menu
	ret

execute_fir3:
	;Pinto todos de branco (pra não precisar salvar qual era o que estava pintado)
	;Menos o botão que foi clicado

	mov 	byte[abrir_color],branco
	mov 	byte[arrow_color],branco
	mov 	byte[fir1_color],branco
	mov 	byte[fir2_color],branco
	mov 	byte[fir3_color],amarelo
	mov 	byte[negative_one_n_power_color], branco
	mov 	byte[sair_color],branco

execute_fir3_check_function_value:
	cmp		word[convolution_function_option],0
	je		execute_fir3_start
	cmp		word[convolution_function_option],3
	je		execute_fir3_start

	;Clears old graph from another convulution option
	mov 	al,preto
	mov 	byte[cor],al
	call	draw_convoluted_function


execute_fir3_start:
	mov		word[convolution_function_option],3;Choses convolution option
	cmp		word[original_function_values_len],0
	jne		execute_fir3_convolution

	mov		word[convolution_function_option],0
	jmp 	execute_fir3_ret
execute_fir3_convolution:
	call	execute_convolution_function
	mov 	al,byte[original_function_color]
	mov 	byte[cor],al
	call	draw_convoluted_function

execute_fir3_ret:
	;retorno pro loop do menu
	ret

execute_negative_one_n_power:
	;Pinto todos de branco (pra não precisar salvar qual era o que estava pintado)
	;Menos o botão que foi clicado

	mov 	byte[abrir_color],branco
	mov 	byte[arrow_color],branco
	mov 	byte[fir1_color],branco
	mov 	byte[fir2_color],branco
	mov 	byte[fir3_color],branco
	mov 	byte[negative_one_n_power_color], amarelo
	mov 	byte[sair_color],branco

execute_negative_one_n_power_check_function_value:
	cmp		word[convolution_function_option],0
	je		execute_negative_one_n_power_start
	cmp		word[convolution_function_option],4
	je		execute_negative_one_n_power_start

	;Clears old graph from another convulution option
	mov 	al,preto
	mov 	byte[cor],al
	call	draw_convoluted_function

execute_negative_one_n_power_start:
	mov		word[convolution_function_option],4 ;Choses convolution option
	cmp		word[original_function_values_len],0
	jne		execute_negative_one_n_power_convolution

	mov		word[convolution_function_option],0
	jmp 	execute_negative_one_n_power_ret
execute_negative_one_n_power_convolution:
	call	execute_convolution_function
	mov 	al,byte[original_function_color]
	mov 	byte[cor],al
	call	draw_convoluted_function

execute_negative_one_n_power_ret:
	;retorno pro loop do menu
	ret

execute_sair:
	;Pinto todos de branco (pra não precisar salvar qual era o que estava pintado)
	;Menos o botão que foi clicado

	mov 	byte[abrir_color],branco
	mov 	byte[arrow_color],branco
	mov 	byte[fir1_color],branco
	mov 	byte[fir2_color],branco
	mov 	byte[fir3_color],branco
	mov 	byte[negative_one_n_power_color],branco
	mov 	byte[sair_color],amarelo

	call	draw_buttons_text


	jmp 	quit

;Button Press Routines
;A referencia do mouse é no canto superior esquerdo, e a referência da biblioteca gráfica é no canto inferior
;****************************IMPORANT****************************	
;For some weird reason when using "call plot_xy" it was not working properly
;Looking like it was changing the state of the pointer SP/BP and not retuning properly (program freezing)
;When I tried pushing every register before the function call, and then poping on the function end
;It worked, so it will stay this way (need to do ASAP)
;****************************************************************
button_press:
		push 	bp
		mov	 	bp,sp
		push 	ax

button_press_start:
		cmp 	word[last_mouse_pos_click],127
		jle 	button_abrir_press
		jmp 	button_press_return
button_abrir_press:
	;Clicou em "Abrir"
		cmp 	word[last_mouse_pos_click+2],69
		jg 		button_arrow_press
		call 	execute_abrir
		jmp 	button_press_return
button_arrow_press:
	;Clicou em "Arrow"
		cmp 	word[last_mouse_pos_click+2],129
		jg 		button_fir1_press
		call 	execute_arrow
		jmp 	button_press_return
button_fir1_press:
	;Clicou em "FIR1"
		cmp 	word[last_mouse_pos_click+2],199
		jg 		button_fir2_press
		call 	execute_fir1
		jmp 	button_press_return
button_fir2_press:
	;Clicou em "FIR2"
		cmp 	word[last_mouse_pos_click+2],269
		jg 		button_fir3_press
		call 	execute_fir2
		jmp 	button_press_return
button_fir3_press:
	;Clicou em "FIR3"
		cmp 	word[last_mouse_pos_click+2],339
		jg 		button_negative_one_n_power_press
		call 	execute_fir3
		jmp 	button_press_return
button_negative_one_n_power_press:
	;Clicou em "(-1)^n"
		cmp 	word[last_mouse_pos_click+2],409
		jg 		button_sair_press
		call 	execute_negative_one_n_power
		jmp 	button_press_return
button_sair_press:
	;Clicou em "Sair"
	;Não comparo pois sobrou apenas esse botão
		jmp 	execute_sair

button_press_return:
		pop		ax
		pop		bp
		ret
		

get_mouse_info:

		mov 	al,3 ;Número da função que pega a informação do mouse
		int 	33h

		cmp 	bx,0001h ;checa se teve algum click do botão esquerdo
		jne 	get_mouse_info

		;Guardo a informação da posição x e y do mouse, aonde foi clicado por último (com botão esquerdo)

		mov 	word[last_mouse_pos_click],cx ;X
		mov 	word[last_mouse_pos_click+2],dx;Y
		;Lembrando que pulo 2 bytes já que são 2 variáveis word .

		ret


draw_buttons_text:
        ;;Drawing "Abrir"
    	mov     	cx,5			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,2			;linha 0-29
    	mov     	dl,5			;coluna 0-79

		mov		al,[abrir_color]
		mov		byte[cor],al
draw_abrir_str_loop:
		call	cursor
    	mov     al,[bx+abrir_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_abrir_str_loop

        ;;Drawing "--->"
    	mov     	cx,4			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,6			;linha 0-29
    	mov     	dl,5			;coluna 0-79
		mov		al,[arrow_color]
		mov		byte[cor],al
draw_arrow_str_loop:
		call	cursor
    	mov     al,[bx+arrow_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_arrow_str_loop

        ;;Drawing "FIR 1"
    	mov     	cx,5			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,10			;linha 0-29
    	mov     	dl,5			;coluna 0-79
		mov		al,[fir1_color]
		mov		byte[cor],al
draw_fir1_str_loop:
		call	cursor
    	mov     al,[bx+fir1_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_fir1_str_loop

        ;;Drawing "FIR 2"
    	mov     	cx,5			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,14			;linha 0-29
    	mov     	dl,5			;coluna 0-79
		mov		al,[fir2_color]
		mov		byte[cor],al
draw_fir2_str_loop:
		call	cursor
    	mov     al,[bx+fir2_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_fir2_str_loop

        ;;Drawing "FIR 3"
    	mov     	cx,5			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,19			;linha 0-29
    	mov     	dl,5			;coluna 0-79
		mov		al,[fir3_color]
		mov		byte[cor],al
draw_fir3_str_loop:
		call	cursor
    	mov     al,[bx+fir3_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_fir3_str_loop

        ;;Drawing "(-1)^n"
    	mov     	cx,6			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,23			;linha 0-29
    	mov     	dl,5			;coluna 0-79
		mov		al,[negative_one_n_power_color]
		mov		byte[cor],al
draw_negative_one_n_power_string_loop:
		call	cursor
    	mov     al,[bx+negative_one_n_power_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop	draw_negative_one_n_power_string_loop

        ;;Drawing "Sair"
    	mov     	cx,4			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,27			;linha 0-29
    	mov     	dl,5			;coluna 0-79
		mov		al,[sair_color]
		mov		byte[cor],al
draw_sair_str_loop:
		call	cursor
    	mov     al,[bx+sair_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_sair_str_loop
    
        ret

draw_graph_text:

		;;DRAWING ON ORIGINAL GRAPH
        ;;Drawing "-140"
    	mov     	cx,4			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,14			;linha 0-29
    	mov     	dl,17			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_original_min_y_value_str_loop:
		call	cursor
    	mov     al,[bx+min_y_value_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_original_min_y_value_str_loop

        ;;Drawing "0"
    	mov     	cx,1			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,9			;linha 0-29
    	mov     	dl,17			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_original_zero_str_loop:
		call	cursor
    	mov     al,[bx+zero_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_original_zero_str_loop

        ;;Drawing "140"
    	mov     	cx,3			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,3		;linha 0-29
    	mov     	dl,17			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_original_max_y_value_str_loop:
		call	cursor
    	mov     al,[bx+max_y_value_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_original_max_y_value_str_loop

        ;;Drawing "490"
    	mov     	cx,3			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,14			;linha 0-29
    	mov     	dl,77			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_original_max_x_value_str_loop:
		call	cursor
    	mov     al,[bx+max_x_value_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_original_max_x_value_str_loop


        ;;Drawing "Sinal Original"
    	mov     	cx,14			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,1			;linha 0-29
    	mov     	dl,39			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_sinal_original_str_loop:
		call	cursor
    	mov     al,[bx+sinal_original_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_sinal_original_str_loop

		;;DRAWING ON CONVOLUTION GRAPH
        ;;Drawing "-140"
    	mov     	cx,4			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,29			;linha 0-29
    	mov     	dl,17			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_convolution_min_y_value_str_loop:
		call	cursor
    	mov     al,[bx+min_y_value_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_convolution_min_y_value_str_loop

		;;Drawing "0"
    	mov     	cx,1			;numero de caracteres
    	mov     	bx,0
    	mov     	dh,24			;linha 0-29
    	mov     	dl,17			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_convolution_zero_str_loop:
		call	cursor
    	mov     al,[bx+zero_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_convolution_zero_str_loop

        ;;Drawing "140"
    	mov     	cx,3			;numero de caracteres
    	mov     	bx,0
    	mov     	dh,18			;linha 0-29
    	mov     	dl,17			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_convolution_max_y_value_str_loop:
		call	cursor
    	mov     al,[bx+max_y_value_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_convolution_max_y_value_str_loop

        ;;Drawing "490"
    	mov     	cx,3			;numero de caracteres
    	mov     	bx,0
    	mov     	dh,29			;linha 0-29
    	mov     	dl,77			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_convolution_max_x_value_str_loop:
		call	cursor
    	mov     al,[bx+max_x_value_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_convolution_max_x_value_str_loop

        ;;Drawing "Sinal Convoluido"
    	mov     	cx,16			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,16			;linha 0-29
    	mov     	dl,39			;coluna 0-79

		mov		al,branco
		mov		byte[cor],al
draw_sinal_convoluido_str_loop:
		call	cursor
    	mov     al,[bx+sinal_convoluido_string]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    draw_sinal_convoluido_str_loop

		ret

draw_graph_borders:
        ;Since almost all borders are already drawn
        ;It's needed just to put the middle line between both graphs

        mov		byte[cor],branco
		mov		ax,127 ;x1
		push	ax
		mov		ax,239 ;y1
		push	ax
		mov		ax,639 ;x2 
		push	ax
		mov		ax,239 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

		;Drawing Graph Lines
		;Drawing ORIGINAL GRAPH VERTICAL/HORIZONTAL LINES

		xor		cx,cx
		mov		cx,15 ;vai desenhar 16 vezes
		mov		bx,word[original_graph_origin+2]
draw_original_graph_borders_horizontal_loop:
		;Horizontal lines
		mov		al,byte[graph_color]
        mov		byte[cor],al
		mov		ax,word[original_graph_origin] ;x1
		push	ax
		mov		ax,bx ;y1
		push	ax
		mov		ax,word[original_graph_origin] ;x2 
		add		ax,[graph_length]
		push	ax
		mov		ax,bx  ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

		add 	bx,10 	;pulo 10 pixeis
		loop draw_original_graph_borders_horizontal_loop

		xor		cx,cx
		mov		cx,50	;vai desenhar 20 vezes
		mov		bx,word[original_graph_origin]
draw_original_graph_borders_vertical_loop:
		;Horizontal lines
		mov		al,byte[graph_color]
        mov		byte[cor],al
		mov		ax,bx ;x1
		push	ax
		mov		ax,word[original_graph_origin+2] ;y1
		push	ax
		mov		ax,bx;x2 
		push	ax
		mov		ax,word[original_graph_origin+2]   ;y2
		add		ax,[graph_height]
		push	ax
		call	line 	;line(x1,y1,x2,y2)

		add 	bx,10	;pulo 10 pixeis
		loop draw_original_graph_borders_vertical_loop

	;Drawing CONVOLUTION GRAPH VERTICAL/HORIZONTAL LINES
		xor		cx,cx
		mov		cx,15 ;vai desenhar 16 vezes
		mov		bx,word[convolution_graph_origin+2]

draw_convulution_graph_borders_horizontal_loop:
		;Horizontal lines
		mov		al,byte[graph_color]
        mov		byte[cor],al
		mov		ax,word[convolution_graph_origin] ;x1
		push	ax
		mov		ax,bx ;y1
		push	ax
		mov		ax,word[convolution_graph_origin] ;x2 
		add		ax,[graph_length]
		push	ax
		mov		ax,bx  ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

		add 	bx,10 	;pulo 10 pixeis
		loop draw_convulution_graph_borders_horizontal_loop

		xor		cx,cx
		mov		cx,50	;vai desenhar 20 vezes
		mov		bx,word[convolution_graph_origin]
draw_convolution_graph_borders_vertical_loop:
		;Horizontal lines
		mov		al,byte[graph_color]
        mov		byte[cor],al
		mov		ax,bx ;x1
		push	ax
		mov		ax,word[convolution_graph_origin+2] ;y1
		push	ax
		mov		ax,bx;x2 
		push	ax
		mov		ax,word[convolution_graph_origin+2]   ;y2
		add		ax,[graph_height]
		push	ax
		call	line 	;line(x1,y1,x2,y2)

		add 	bx,10	;pulo 10 pixeis
		loop draw_convolution_graph_borders_vertical_loop

        ret


draw_buttons_borders:
;Argumentos da função "line" são line(x1,y1,x2,y2)

        ;Draws right line
		mov		byte[cor],branco
		mov		ax,127 ;x1
		push	ax
		mov		ax,0 ;y1
		push	ax
		mov		ax,127 ;x2 
		push	ax
		mov		ax,479 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)
        
        ;"Abrir" border
        mov		byte[cor],branco
		mov		ax,0 ;x1
		push	ax
		mov		ax,409 ;y1
		push	ax
		mov		ax,127 ;x2 
		push	ax
		mov		ax,409 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

        ;"Arrow" border
        mov		byte[cor],branco
		mov		ax,0 ;x1
		push	ax
		mov		ax,349 ;y1
		push	ax
		mov		ax,127 ;x2 
		push	ax
		mov		ax,349 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

        ;"FIR1" border
        mov		byte[cor],branco
		mov		ax,0 ;x1
		push	ax
		mov		ax,279 ;y1
		push	ax
		mov		ax,127 ;x2 
		push	ax
		mov		ax,279 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

        ;"FIR2" border
        mov		byte[cor],branco
		mov		ax,0 ;x1
		push	ax
		mov		ax,209 ;y1
		push	ax
		mov		ax,127 ;x2 
		push	ax
		mov		ax,209 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

        ;"FIR3" border
        mov		byte[cor],branco
		mov		ax,0 ;x1
		push	ax
		mov		ax,139 ;y1
		push	ax
		mov		ax,127 ;x2 
		push	ax
		mov		ax,139 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

        ;"(-1)^n" border
        mov		byte[cor],branco
		mov		ax,0 ;x1
		push	ax
		mov		ax,69 ;y1
		push	ax
		mov		ax,127 ;x2 
		push	ax
		mov		ax,69 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

        ;"Sair" border already draws when drawing "(-1)^n" border
        ;since it's lower part already is a draw line (draw_border draws the lower bound)

        ret


draw_border:
;Argumentos da função "line" são line(x1,y1,x2,y2)
		mov		byte[cor],branco
		mov		ax,0 ;x1
		push	ax
		mov		ax,0 ;y1
		push	ax
		mov		ax,0 ;x2 
		push	ax
		mov		ax,479 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)
		
		mov		byte[cor],branco
		mov		ax,0 ;x1
		push	ax
		mov		ax,479 ;y1
		push	ax
		mov		ax,639 ;x2
		push	ax
		mov		ax,479 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

		mov		byte[cor],branco	
		mov		ax,639 ;x1
		push	ax
		mov		ax,479 ;y1
		push	ax
		mov		ax,639 ;x2
		push	ax
		mov		ax,0 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)


		mov		byte[cor],branco	
		mov		ax,639 ;x1
		push	ax
		mov		ax,0 ;y1
		push	ax
		mov		ax,0 ;x2
		push	ax
		mov		ax,0 ;y2
		push	ax
		call	line ;line(x1,y1,x2,y2)

        ret

		
quit:
		mov  	ah,0   			; set video mode
		mov  	al,[modo_anterior]   	; modo anterior
		int  	10h

		;recuperando estado inicial do mouse
		; mov			ax,data
		; mov 		es,ax ;usa ES:DX, mas como a variável está em DS, fazemos ES apontar para DS
		; mov			dx,initial_mouse_state
		; mov 		ax, 0017h       ;funcão "17h" da interrupção "33h"
		; int 		33h 

		; mostrar o cursor na tela
		; mov 		ax, 1
		; int 		33h

		;DEBUGAR
		; mov		dx,cx
		; call	imprimenumero

		; mov		dx,original_function_values
		; call	imprimenumero

		; ; mov		bx,word[original_function_values_len]
		; ; dec		bx
		; movsx	dx,byte[convoluted_function_values+2]
		; call	imprimenumero

		cmp		byte[file_open_flag],0
		je		quit_end
quit_close_file:
		call	close_file
quit_end:
		mov 	ax,4c00h ; função de encerrar o programa caso "int 21h" seja chamado depois,
		;o mesmo que fazer "mov ah 4ch", mas provavelmente "al" não é 0, por isso o uso de 2 bytes em "4c00h"
		int 	21h ; encerra o programa 


;***************************************************************************
;
;   fun��o cursor
;
; dh = linha (0-29) e  dl=coluna  (0-79)
cursor:
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		push		bp
		mov     	ah,2
		mov     	bh,0
		int     	10h
		pop		bp
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		ret
;_____________________________________________________________________________
;
;   fun��o caracter escrito na posi��o do cursor
;
; al= caracter a ser escrito
; cor definida na variavel cor
caracter:
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		push		bp
    		mov     	ah,9
    		mov     	bh,0
    		mov     	cx,1
   		mov     	bl,[cor]
    		int     	10h
		pop		bp
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		ret
;_____________________________________________________________________________
;
;   fun��o plot_xy
;
; push x; push y; call plot_xy;  (x<639, y<479)
; cor definida na variavel cor
plot_xy:
		push		bp
		mov		bp,sp
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
	    mov     	ah,0ch
	    mov     	al,[cor]
	    mov     	bh,0
	    mov     	dx,479
		sub		dx,[bp+4]
	    mov     	cx,[bp+6]
	    int     	10h
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		4
;_____________________________________________________________________________
;    fun��o circle
;	 push xc; push yc; push r; call circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor
circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di
	
	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r
	
	mov 	dx,bx	
	add		dx,cx       ;ponto extremo superior
	push    ax			
	push	dx
	call plot_xy
	
	mov		dx,bx
	sub		dx,cx       ;ponto extremo inferior
	push    ax			
	push	dx
	call plot_xy
	
	mov 	dx,ax	
	add		dx,cx       ;ponto extremo direita
	push    dx			
	push	bx
	call plot_xy
	
	mov		dx,ax
	sub		dx,cx       ;ponto extremo esquerda
	push    dx			
	push	bx
	call plot_xy
		
	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante 
;valores positivos para d

stay:				;loop
	mov		si,di
	cmp		si,0
	jg		inf       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar
inf:	
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di 
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)
	
plotar:	
	mov		si,dx
	add		si,ax
	push    si			;coloca a abcisa x+xc na pilha
	mov		si,cx
	add		si,bx
	push    si			;coloca a ordenada y+yc na pilha
	call plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,dx
	push    si			;coloca a abcisa xc+x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do s�timo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc+x na pilha
	call plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do oitavo octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	add		si,cx
	push    si			;coloca a ordenada yc+y na pilha
	call plot_xy		;toma conta do terceiro octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do sexto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quinto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quarto octante
	
	cmp		cx,dx
	jb		fim_circle  ;se cx (y) est� abaixo de dx (x), termina     
	jmp		stay		;se cx (y) est� acima de dx (x), continua no loop
	
	
fim_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6
;-----------------------------------------------------------------------------
;    fun��o full_circle
;	 push xc; push yc; push r; call full_circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor					  
full_circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di

	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r
	
	mov		si,bx
	sub		si,cx
	push    ax			;coloca xc na pilha			
	push	si			;coloca yc-r na pilha
	mov		si,bx
	add		si,cx
	push	ax		;coloca xc na pilha
	push	si		;coloca yc+r na pilha
	call line
	
		
	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y
	
;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante 
;valores positivos para d

stay_full:				;loop
	mov		si,di
	cmp		si,0
	jg		inf_full       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar_full
inf_full:	
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di 
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)
	
plotar_full:	
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	add		si,cx
	push	si		;coloca a abcisa y+xc na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call 	line
	
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	add		si,dx
	push	si		;coloca a abcisa xc+x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha			
	mov		si,bx
	sub		si,cx
	push    si		;coloca a ordenada yc-y na pilha
	mov		si,ax
	sub		si,dx
	push	si		;coloca a abcisa xc-x na pilha	
	mov		si,bx
	add		si,cx
	push    si		;coloca a ordenada yc+y na pilha	
	call	line
	
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha			
	mov		si,bx
	sub		si,dx
	push    si		;coloca a ordenada yc-x na pilha
	mov		si,ax
	sub		si,cx
	push	si		;coloca a abcisa xc-y na pilha	
	mov		si,bx
	add		si,dx
	push    si		;coloca a ordenada yc+x na pilha	
	call	line
	
	cmp		cx,dx
	jb		fim_full_circle  ;se cx (y) est� abaixo de dx (x), termina     
	jmp		stay_full		;se cx (y) est� acima de dx (x), continua no loop
	
	
fim_full_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6
;-----------------------------------------------------------------------------
;
;   fun��o line
;
; push x1; push y1; push x2; push y2; call line;  (x<639, y<479)
line:
		push		bp
		mov		bp,sp
		pushf                        ;coloca os flags na pilha
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		mov		ax,[bp+10]   ; resgata os valores das coordenadas
		mov		bx,[bp+8]    ; resgata os valores das coordenadas
		mov		cx,[bp+6]    ; resgata os valores das coordenadas
		mov		dx,[bp+4]    ; resgata os valores das coordenadas
		cmp		ax,cx
		je		line2
		jb		line1
		xchg		ax,cx
		xchg		bx,dx
		jmp		line1
line2:		; deltax=0
		cmp		bx,dx  ;subtrai dx de bx
		jb		line3
		xchg		bx,dx        ;troca os valores de bx e dx entre eles
line3:	; dx > bx
		push		ax
		push		bx
		call 		plot_xy
		cmp		bx,dx
		jne		line31
		jmp		fim_line
line31:		inc		bx
		jmp		line3
;deltax <>0
line1:
; comparar m�dulos de deltax e deltay sabendo que cx>ax
	; cx > ax
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		ja		line32
		neg		dx
line32:		
		mov		[deltay],dx
		pop		dx

		push		ax
		mov		ax,[deltax]
		cmp		ax,[deltay]
		pop		ax
		jb		line5

	; cx > ax e deltax>deltay
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx

		mov		si,ax
line4:
		push		ax
		push		dx
		push		si
		sub		si,ax	;(x-x1)
		mov		ax,[deltay]
		imul		si
		mov		si,[deltax]		;arredondar
		shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar1
		add		ax,si
		adc		dx,0
		jmp		arc1
ar1:		sub		ax,si
		sbb		dx,0
arc1:
		idiv		word [deltax]
		add		ax,bx
		pop		si
		push		si
		push		ax
		call		plot_xy
		pop		dx
		pop		ax
		cmp		si,cx
		je		fim_line
		inc		si
		jmp		line4

line5:		cmp		bx,dx
		jb 		line7
		xchg		ax,cx
		xchg		bx,dx
line7:
		push		cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push		dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx



		mov		si,bx
line6:
		push		dx
		push		si
		push		ax
		sub		si,bx	;(y-y1)
		mov		ax,[deltax]
		imul		si
		mov		si,[deltay]		;arredondar
		shr		si,1
; se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar2
		add		ax,si
		adc		dx,0
		jmp		arc2
ar2:		sub		ax,si
		sbb		dx,0
arc2:
		idiv		word [deltay]
		mov		di,ax
		pop		ax
		add		di,ax
		pop		si
		push		di
		push		si
		call		plot_xy
		pop		dx
		cmp		si,dx
		je		fim_line
		inc		si
		jmp		line6

fim_line:
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		8
;*******************************************************************


delay: ; Esteja atento pois talvez seja importante salvar contexto (no caso, CX, o que NÃO foi feito aqui).
	push	cx
	mov cx, word [delay_ammount] ; Carrega “velocidade” em cx (contador para loop)
	del2:
	push cx ; Coloca cx na pilha para usa-lo em outro loop
	mov cx, 0800h ; Teste modificando este valor
del1:
	loop del1 ; No loop del1, cx é decrementado até que volte a ser zero
	pop cx ; Recupera cx da pilha
	loop del2 ; No loop del2, cx é decrementado até que seja zero
	pop	cx
	ret

;;Funcoes para facilitar abrir,ler e fechar arquivo
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

;; Funcoes para debugar
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

cor						db		branco_intenso

;	I R G B COR
;	0 0 0 0 preto
;	0 0 0 1 azul
;	0 0 1 0 verde
;	0 0 1 1 cyan
;	0 1 0 0 vermelho
;	0 1 0 1 magenta
;	0 1 1 0 marrom
;	0 1 1 1 branco
;	1 0 0 0 cinza
;	1 0 0 1 azul claro
;	1 0 1 0 verde claro
;	1 0 1 1 cyan claro
;	1 1 0 0 rosa
;	1 1 0 1 magenta claro
;	1 1 1 0 amarelo
;	1 1 1 1 branco intenso

	preto				equ		0
	azul				equ		1
	verde				equ		2
	cyan				equ		3
	vermelho			equ		4
	magenta				equ		5
	marrom				equ		6
	branco				equ		7
	cinza				equ		8
	azul_claro			equ		9
	verde_claro			equ		10
	cyan_claro			equ		11
	rosa				equ		12
	magenta_claro		equ		13
	amarelo				equ		14
	branco_intenso		equ		15

	modo_anterior		db		0
	linha   			dw  	0
	coluna  			dw  	0
	deltax				dw		0
	deltay				dw		0	
	mens    			db  	'Funcao Grafica'


;; Declarando Variáveis necessárias para facilitar o desenvolvimento do código
	delay_ammount dw 5
	last_mouse_pos_click resw 2


;Declarando Textos da Interface
	abrir_string        			db     		'Abrir'
	abrir_color						db			branco
	arrow_string        			db     		'--->'
	arrow_color						db 			branco
	fir1_string         			db     		'FIR 1'
	fir1_color						db			branco
	fir2_string         			db     		'FIR 2'
	fir2_color						db			branco
	fir3_string         			db     		'FIR 3'
	fir3_color						db			branco
	negative_one_n_power_string		db 			'(-1)^n'
	negative_one_n_power_color		db			branco
	sair_string        				db      	'Sair'
	sair_color						db			branco

;Declarando Textos E Origem dos Gráficos

	sinal_original_string		db			'Sinal Original'
	sinal_convoluido_string		db			'Sinal Convoluido'
	zero_string					db			'0'
	max_y_value_string			db			'140'
	min_y_value_string			db			'-140'
	max_x_value_string			db			'490'

	graph_color					db			verde
	graph_height				dw			140
	graph_length				dw			490 ;o programa lê de 485 em 485, mas a escala tem que ser de 10 em 10

	original_graph_origin 		dw			147,263 
	convolution_graph_origin 	dw			147,23 

;Declarando estado que o mouse estava antes de iniciar o DOSBOX

	initial_mouse_state 		resb 		496 ;Usei o programa de printar numero em ASCII pra ver antes

;Declarando variáveis necessárias para calcular os pontos do grafico
	file_line_len							equ			18
	file_line_buffer						resb		18
	file_max_line_read						equ			485
	file_handler							resw		1
	file_values								db 			'C:sinalep.txt',0
	file_open_flag							db			0

	original_function_values 				resb 		485
	original_function_values_truncated 		resb 		485
	original_function_values_len			dw			0
	original_function_color					db			amarelo
	original_function_ammount_num_read		dw			0

	convoluted_function_values 				resb 		485
	convoluted_function_values_truncated 	resb 		485
	convoluted_function_values_len			dw			0
	convoluted_function_color				db			amarelo

;Variables for the filters

;Option = 0 (None), Option = 1 (FIR1), Option = 2 (FIR2), Option = 3 (FIR3), Option = 4 ((-1)^n)
	convolution_function_option		dw		0
	reflected_fir3_function			db		1,-1
	reflected_fir3_function_len		db		2				

;Declarando pra debugar 
    saida: db '00000',13,10,'$'
    tam_vector equ 5h

;*************************************************************************
segment stack stack
    		resb 		512
stacktop: