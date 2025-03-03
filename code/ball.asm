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
		
draw_limit_lines:
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

	;Argumentos da função "full_circle" são full_circle(xr,yr,r)
		mov		byte[cor],vermelho
		mov 	word[current_x],319 ;xr
		push	word[current_x]
		mov		word[current_y],239 ;yr
		push	word[current_y]
		mov		word[current_r],10 ;r
		push	word[current_r]
		call full_circle ; full_circle(xr,yr,r)


;AQUI COMEÇA A ANIMAÇÃO DE VERDADE
animate_ball:
		mov ah,0bh
		int 21h ; Le buffer de teclado
		cmp al,0 ; Se AL =0 nada foi digitado. Se AL =255 então há algum caracter na STDIN
		jne adelante
		jmp delete_old_ball ; se AL = 0 então nada foi digitado e a animação do jogo deve continuar
adelante:
		mov ah, 08H ;Ler caracter da STDIN
		int 21H
		cmp al, 's' ;Verifica se foi 's'. Se foi, finaliza o programa
		jne delete_old_ball
		jmp quit
delete_old_ball:
	;Delete old ball

		mov		byte[cor],preto
		push	word[current_x]
		push	word[current_y]
		push	word[current_r]
		call full_circle	
update_ball_pos:
		;Atualizo as posições X e Y da bola
		;Para depois checar colisão e depois desenha-lá
		mov ax,word[velocidade_x] 
		add word[current_x],ax
		mov	ax,word[velocidade_y]
		add word[current_y],ax

hit_wall:
		;Checks if hit the right wall
		mov ax,[current_x]
		add ax,[current_r]
		cmp ax,639 ; levanta as flags para usar com os jumps condicionais
		jge hit_right_wall; jge = "jump if greater or equal"

		;Checks if hit the left wall
		mov ax,[current_x]
		sub ax,[current_r]
		cmp ax,0 ; levanta as flags para usar com os jumps condicionais
		jle hit_left_wall ;jle = "jump if less or equal"

		;Se colide com as paredes ainda temos que checar se colide com o chão/teto
		;por isso não posso da um "jmp move_ball" dentro de cada uma dessas duas labels
		;e sim um "jmp hit_floor_ceiling"
		;se ambos os jumps não forem executados, o programa ainda prossegue para o label "hit_floor_ceiling"
		;já que ele está logo abaixo (labels só servem para saber para onde "pular na execução")
		;caso o jump não seja executado, o programa prossegue para a proxima linha
hit_floor_ceiling:
		; Y = 0 é o topo da tela
		; Y = 479 é o "chão" da tela
		;Checks if hit the ceiling
		mov ax,[current_y]
		add ax,[current_r]
		cmp ax,479 ; levanta as flags para usar com os jumps condicionais
		jge hit_ceiling ; jge = "jump if greater or equal"

		;Se colide com o chão não colide com o teto
		;por isso posso da um "jmp move_ball" dentro de cada uma dessas duas labels

		;Checks if hit the floor
		mov ax,[current_y]
		sub ax,[current_r]
		cmp ax,0 ; levanta as flags para usar com os jumps condicionais
		jle hit_floor; jle = "jump if less or equal"

		;Aqui é necessário o uso do "jmp move_ball", se não o programa prosseguiria para o "hit_right_wall"
		jmp move_ball
hit_right_wall:
		;Atualizo a posição X da bola novamente
		;Caso ela bata na parede da direita
		call reverse_x_vel
		mov ax,639
		sub ax,[current_r]
		mov [current_x],ax
		jmp hit_floor_ceiling
hit_left_wall:
		call reverse_x_vel
		mov ax,[current_r]
		mov [current_x],ax
		jmp hit_floor_ceiling
reverse_x_vel:
		neg word[velocidade_x] ;Nega com complemento de 2, no caso é igual a fazer "not x" e depois "inc x"
		ret
hit_floor:
		call reverse_y_vel
		mov ax,[current_r]
		mov [current_y],ax
		jmp move_ball
hit_ceiling:
		call reverse_y_vel
		mov ax,479
		sub ax,[current_r]
		mov [current_y],ax
		jmp move_ball
reverse_y_vel:
		neg word[velocidade_y] ; Nega com complemento de 2, no caso é igual a fazer "not x" e depois "inc x"
		ret
	
	;Actually Draws it
move_ball:
		mov byte[cor],vermelho
		push	word[current_x]
		push	word[current_y]
		push	word[current_r]
		call full_circle
		call delay
		jmp animate_ball ;returns to the start
		;O "Flickering" da bola (bola piscando) ocorre porque desenho uma bola preta e vermelha ao mesmo tempo
		;Mas a sensação de movimento é o que é importante para esse lab


		
quit:
		mov  	ah,0   			; set video mode
		mov  	al,[modo_anterior]   	; modo anterior
		int  	10h
		mov ax,4c00h ; função de encerrar o programa caso "int 21h" seja chamado depois,
		;o mesmo que fazer "mov ah 4ch", mas provavelmente "al" não é 0, por isso o uso de 2 bytes em "4c00h"
		int 21h ; encerra o programa 



;escrever uma mensagem

    	mov     	cx,14			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,0			;linha 0-29
    	mov     	dl,30			;coluna 0-79
		mov		byte[cor],azul
l4:
		call	cursor
    	mov     al,[bx+mens]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
		inc		byte [cor]		;mudar a cor para a seguinte
    	loop    l4

		mov    	ah,08h
		int     21h
	    mov  	ah,0   			; set video mode
	    mov  	al,[modo_anterior]   	; modo anterior
	    int  	10h
		mov     ax,4c00h
		int     21h

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
	mov cx, word [velocidade] ; Carrega “velocidade” em cx (contador para loop)
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

velocidade dw 100
velocidade_x dw 5
velocidade_y dw -5
current_x resw 1
current_y resw 1
current_r resw 1
;*************************************************************************
segment stack stack
    		resb 		512
stacktop: