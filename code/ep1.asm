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

; inicializa o drive do mouse
		mov 		ax, 0
		int 		33h

; posiciona acima do meio da tela para não estragar o desenho da linha do centro
		mov 		ax,4
		mov 		cx,239
		mov 		dx,100
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

menu_loop:
	;Printing text on the boxes
        call    draw_buttons_text

	;Checks mouse info
		call	get_mouse_info
	
	;Executes button IF it's between X and Y
		call	button_press

        jmp 	menu_loop

;Execute Buttons Routine
execute_abrir:
	;Pinto todos de branco (pra não precisar salvar qual era o que estava pintado)
	;Menos o botão que foi clicado

	mov 	byte[abrir_color],amarelo
	mov 	byte[arrow_color],branco
	mov 	byte[fir1_color],branco
	mov 	byte[fir2_color],branco
	mov 	byte[fir3_color],branco
	mov 	byte[negative_one_n_power_color], branco
	mov 	byte[sair_color],branco

	;; Faco o que a opcao deve fazer
	;...
	;...
	;...

	;retorno pro loop do menu
	jmp 	menu_loop

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

	;; Faco o que a opcao deve fazer
	;...
	;...
	;...

	;retorno pro loop do menu
	jmp 	menu_loop

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
	jmp 	menu_loop

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
	jmp 	menu_loop

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

	;; Faco o que a opcao deve fazer
	;...
	;...
	;...

	;retorno pro loop do menu
	jmp 	menu_loop

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

	;; Faco o que a opcao deve fazer
	;...
	;...
	;...

	;retorno pro loop do menu
	jmp 	menu_loop

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
button_press:
		cmp 	word[last_mouse_pos_click],127
		jle 	button_abrir_press
		jmp 	button_press_return
button_abrir_press:
	;Clicou em "Abrir"
		cmp 	word[last_mouse_pos_click+2],69
		jg 		button_arrow_press
		jmp 	execute_abrir
button_arrow_press:
	;Clicou em "Arrow"
		cmp 	word[last_mouse_pos_click+2],129
		jg 		button_fir1_press
		jmp 	execute_arrow
button_fir1_press:
	;Clicou em "FIR1"
		cmp 	word[last_mouse_pos_click+2],199
		jg 		button_fir2_press
		jmp 	execute_fir1
button_fir2_press:
	;Clicou em "FIR2"
		cmp 	word[last_mouse_pos_click+2],269
		jg 		button_fir3_press
		jmp 	execute_fir2
button_fir3_press:
	;Clicou em "FIR3"
		cmp 	word[last_mouse_pos_click+2],339
		jg 		button_negative_one_n_power_press
		jmp 	execute_fir3
button_negative_one_n_power_press:
	;Clicou em "(-1)^n"
		cmp 	word[last_mouse_pos_click+2],409
		jg 		button_sair_press
		jmp 	execute_negative_one_n_power
button_sair_press:
	;Clicou em "Sair"
	;Não comparo pois sobrou apenas esse botão
		jmp 	execute_sair

button_press_return:
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
 		mov    	ah,08h
 		int     21h
		mov  	ah,0   			; set video mode
		mov  	al,[modo_anterior]   	; modo anterior
		int  	10h
		mov ax,4c00h ; função de encerrar o programa caso "int 21h" seja chamado depois,
		;o mesmo que fazer "mov ah 4ch", mas provavelmente "al" não é 0, por isso o uso de 2 bytes em "4c00h"
		int 21h ; encerra o programa 


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
	mov cx, word [delay_ammount] ; Carrega “velocidade” em cx (contador para loop)
	del2:
	push cx ; Coloca cx na pilha para usa-lo em outro loop
	mov cx, 0800h ; Teste modificando este valor
del1:
	loop del1 ; No loop del1, cx é decrementado até que volte a ser zero
	pop cx ; Recupera cx da pilha
	loop del2 ; No loop del2, cx é decrementado até que seja zero
	ret

segment data

cor		db		branco_intenso

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

preto		equ		0
azul		equ		1
verde		equ		2
cyan		equ		3
vermelho	equ		4
magenta		equ		5
marrom		equ		6
branco		equ		7
cinza		equ		8
azul_claro	equ		9
verde_claro	equ		10
cyan_claro	equ		11
rosa		equ		12
magenta_claro	equ		13
amarelo		equ		14
branco_intenso	equ		15

modo_anterior	db		0
linha   	dw  		0
coluna  	dw  		0
deltax		dw		0
deltay		dw		0	
mens    	db  		'Funcao Grafica'


;; Declarando Variáveis necessárias para facilitar o desenvolvimento do código
delay_ammount dw 50
last_mouse_pos_click resw 2


;Declarando Textos da Interface
abrir_string        db     'Abrir'
abrir_color			db		branco
arrow_string        db     '--->'
arrow_color			db 		branco
fir1_string         db     'FIR 1'
fir1_color			db		branco
fir2_string         db     'FIR 2'
fir2_color			db		branco
fir3_string         db     'FIR 3'
fir3_color			db		branco
negative_one_n_power_string db '(-1)^n'
negative_one_n_power_color	db		branco
sair_string        db      'Sair'
sair_color	db		branco

;*************************************************************************
segment stack stack
    		resb 		512
stacktop: