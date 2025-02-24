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
		
;putting clock interruption

			mov     	cx,[owner_len]			;n�mero de caracteres
			mov     	bx,0
			mov     	dh,2			;linha 0-29
			mov     	dl,20			;coluna 0-79
			mov		byte[cor],branco_intenso

			xor 	AX, AX
			mov 	ES, AX
			mov     AX, [ES:intr*4];carregou AX com offset anterior
			mov     [offset_dos], AX        ; offset_dos guarda o end. para qual ip de int 9 estava apontando anteriormente
			mov     AX, [ES:intr*4+2]     ; cs_dos guarda o end. anterior de CS
			mov     [cs_dos], AX
			cli     
			mov     [ES:intr*4+2], CS
			mov     WORD [ES:intr*4],relogio
			sti

;putting keyboard interruption
			XOR     AX, AX
        	MOV     ES, AX
			MOV     AX, [ES:int9*4];carregou AX com offset anterior
			MOV     [offset_dos_kb], AX        ; offset_dos guarda o end. para qual ip de int 9 estava apontando anteriormente
			MOV     AX, [ES:int9*4+2]     ; cs_dos guarda o end. anterior de CS
			MOV     [cs_dos_kb], AX
			CLI     
			MOV     [ES:int9*4+2], CS
			MOV     WORD [ES:int9*4],keyint
			STI


program_start:
		call 	write_menu
program_loop:
		cmp 	byte [tique], 0
		jne 	check_kb
		jmp		program_loop
check_kb: ;Needed to copy the "check_kb_press_blocking" but alter it here, to not block the clock display
        mov     ax,[p_i]
        CMP     ax,[p_t]
		call 	converte
		call	write_clock
        je      program_loop
        inc     word[p_t]
        and     word[p_t],7
        mov     bx,[p_t]
        XOR     AX, AX
        MOV     AL, [bx+tecla]
        mov     [tecla_u],al
		call 	clock_functions
		jmp		program_loop


clock_functions:
clock_functions_x:
		cmp		byte[tecla_u],2dh ; "x" press value on the new keyboard interruption
		jne		clock_functions_s
		jmp 	quit
clock_functions_s:
		cmp		byte[tecla_u],1fh  ; "s" press value on the new keyboard interruption
		je		clock_functions_edit_seconds				
		jmp		clock_functions_m

clock_functions_m:
		cmp		byte[tecla_u],32h  ; "m" press value on the new keyboard interruption
		je		clock_functions_edit_minutes				
		jmp		clock_functions_h	

clock_functions_h:
		cmp		byte[tecla_u],23h  ; "h" press value on the new keyboard interruption
		je		clock_functions_edit_hour				
		jmp		clock_functions_ret				

clock_functions_edit_seconds:
		call 	stop_clock
		call 	check_kb_press_blocking

		cmp		byte[tecla_u],0xe0 ; first byte of the "arrow" keys, check if its a arrow key
		jne		clock_functions_edit_seconds_quit

		call 	inc_dec_clock_seconds ;inc or dec seconds
		call 	converte
		call	write_clock
		jmp		clock_functions_edit_seconds 

clock_functions_edit_seconds_quit:
		cmp		byte[tecla_u],1ch ; "ENTER" press value on the new keyboard interruption
		jne		clock_functions_edit_seconds
		call 	resume_clock
		jmp		clock_functions_ret

clock_functions_edit_minutes:
		call 	stop_clock
		call 	check_kb_press_blocking

		cmp		byte[tecla_u],0xe0 ; first byte of the "arrow" keys, check if its a arrow key
		jne		clock_functions_edit_minutes_quit

		call 	inc_dec_clock_minutes ;inc or dec minutes
		call 	converte
		call	write_clock
		jmp		clock_functions_edit_minutes

clock_functions_edit_minutes_quit:
		cmp		byte[tecla_u],1ch ; "ENTER" press value on the new keyboard interruption
		jne		clock_functions_edit_minutes
		call 	resume_clock
		jmp		clock_functions_ret


clock_functions_edit_hour:
		call 	stop_clock
		call 	check_kb_press_blocking

		cmp		byte[tecla_u],0xe0 ; first byte of the "arrow" keys, check if its a arrow key
		jne		clock_functions_edit_hour_quit	

		call 	inc_dec_clock_hours
		call 	converte
		call	write_clock
		jmp		clock_functions_edit_hour 	

clock_functions_edit_hour_quit:
		cmp		byte[tecla_u],1ch ; "ENTER" press value on the new keyboard interruption
		jne		clock_functions_edit_hour
		call 	resume_clock
		jmp		clock_functions_ret

clock_functions_ret:
		ret

		



relogio:
	push	ax
	push	ds
	mov     ax,data	
	mov     ds,ax	
    
    inc	byte [tique]
    cmp	byte[tique], 18	
    jb		Fimrel
	mov byte [tique], 0
	inc byte [segundo]
	cmp byte [segundo], 60
	jb   	Fimrel
	mov byte [segundo], 0
	inc byte [minuto]
	cmp byte [minuto], 60
	jb   	Fimrel
	mov byte [minuto], 0
	inc byte [hora]
	cmp byte [hora], 24
	jb   	Fimrel
	mov byte [hora], 0	
Fimrel:
    mov		al,20h
	out		20h,al
	pop		ds
	pop		ax
	iret
	
converte:
    push 	ax
	push    ds
	mov     ax, data
	mov     ds, ax
	xor 	ah, ah
	MOV     BL, 10
	mov 	al, byte [segundo]
    DIV     BL
    ADD     AL, 30h                                                                                          
    MOV     byte [horario+6], AL
    ADD     AH, 30h
    mov 	byte [horario+7], AH
    
	xor 	ah, ah
	mov 	al, byte [minuto]
    DIV     BL
    ADD     AL, 30h                                                                                          
    MOV     byte [horario+3], AL
    ADD     AH, 30h
    mov 	byte [horario+4], AH
	
	xor 	ah, ah
	mov 	al, byte [hora]
    DIV     BL
    ADD     AL, 30h                                                                                          
    MOV     byte [horario], AL
    ADD     AH, 30h
    mov 	byte [horario+1], AH
	pop     ds
	pop     ax
	ret  


write_clock:
		mov			byte[cor],branco_intenso
    	mov     	cx,[horario_len];n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,10			;linha 0-29
    	mov     	dl,27			;coluna 0-79
write_clock_loop:
		call	cursor
    	mov     al,[bx+horario]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_clock_loop

		ret


write_menu:

		mov		byte[cor],branco_intenso

    	mov     	cx,[owner_len]			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,2			;linha 0-29
    	mov     	dl,20			;coluna 0-79
write_owner_info:
		call	cursor
    	mov     al,[bx+owner]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_owner_info

    	mov     	cx,[clock_info_str_len]			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,10			;linha 0-29
    	mov     	dl,20			;coluna 0-79
write_clock_info:
		call	cursor
    	mov     al,[bx+clock_info_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_clock_info

    	mov     	cx,[menu_info_str_len]			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,16			;linha 0-29
    	mov     	dl,20			;coluna 0-79
write_menu_info:
		call	cursor
    	mov     al,[bx+menu_info_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_menu_info

    	mov     	cx,[sair_str_len]			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,18			;linha 0-29
    	mov     	dl,28			;coluna 0-79
write_sair_info:
		call	cursor
    	mov     al,[bx+sair_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_sair_info

    	mov     	cx,[seconds_str_len]			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,20			;linha 0-29
    	mov     	dl,28			;coluna 0-79
write_seconds_info:
		call	cursor
    	mov     al,[bx+seconds_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_seconds_info


    	mov     	cx,[minutes_str_len]			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,22			;linha 0-29
    	mov     	dl,28			;coluna 0-79
write_minutes_info:
		call	cursor
    	mov     al,[bx+minutes_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_minutes_info

    	mov     	cx,[hour_str_len]			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,24			;linha 0-29
    	mov     	dl,28			;coluna 0-79
write_hour_info:
		call	cursor
    	mov     al,[bx+hour_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_hour_info


    	mov     	cx,[arrows_str_len]			;n�mero de caracteres
    	mov     	bx,0
    	mov     	dh,26			;linha 0-29
    	mov     	dl,28			;coluna 0-79
write_arrow_info:
		call	cursor
    	mov     al,[bx+arrows_str]
		call	caracter
    	inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
    	loop    write_arrow_info

		ret



quit:
		cli

		;Return original clock interruption
		xor     AX, AX
		mov     ES, AX
		mov     AX, [cs_dos]
		mov     [ES:intr*4+2], AX
		mov     AX, [offset_dos]
		mov     [ES:intr*4], AX 

		;Return original keyboard interruption
        XOR     AX, AX
        MOV     ES, AX
        MOV     AX, [cs_dos_kb]
        MOV     [ES:int9*4+2], AX
        MOV     AX, [offset_dos_kb]
        MOV     [ES:int9*4], AX 

		;waits for a char input
        ; mov ah,08h
        ; int 21h 

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


check_kb_press:	
        mov     ax,[p_i]
        ; CMP     ax,[p_t]
        ; JE      check_kb_press
        inc     word[p_t]
        and     word[p_t],7
        mov     bx,[p_t]
        XOR     AX, AX
        MOV     AL, [bx+tecla]
        mov     [tecla_u],al
		ret

check_kb_press_blocking:	
        mov     ax,[p_i]
        CMP     ax,[p_t]
        JE      check_kb_press_blocking
        inc     word[p_t]
        and     word[p_t],7
        mov     bx,[p_t]
        XOR     AX, AX
        MOV     AL, [bx+tecla]
        mov     [tecla_u],al
		ret


keyint:
        PUSH    AX
        push    bx
        push    ds
        mov     ax,data
        mov     ds,ax
        IN      AL, kb_data
        inc     WORD [p_i]
        and     WORD [p_i],7
        mov     bx,[p_i]
        mov     [bx+tecla],al
        IN      AL, kb_ctl
        OR      AL, 80h
        OUT     kb_ctl, AL
        AND     AL, 7Fh
        OUT     kb_ctl, AL
        MOV     AL, eoi
        OUT     pictrl, AL
        pop     ds
        pop     bx
        POP     AX
        IRET
;*******************************************************************

stop_clock:
		in   al, 21h          ; Read current PIC mask
		or   al, 01h          ; Set bit 0 to disable IRQ0 (Timer)
		out  21h, al          ; Write back to PIC
		ret

resume_clock:
		in   al, 21h          ; Read current PIC mask
    	and  al, 0FEh         ; Clear bit 0 to enable IRQ0 (Timer)
    	out  21h, al          ; Write back to PIC
		ret

inc_dec_clock_seconds:

			call 	check_kb_press_blocking
			cmp 	byte[tecla_u],0x48
			jne		dec_seconds_arrow_up_pressed	

	inc_seconds_arrow_up_pressed:
			cmp		byte[segundo],59
			je 		inc_seconds_arrow_up_pressed_reset_minutes
			inc		byte[segundo]
			jmp 	inc_dec_clock_seconds_ret

	inc_seconds_arrow_up_pressed_reset_minutes:
			mov		byte[segundo],0
			jmp		inc_dec_clock_seconds_ret

	dec_seconds_arrow_up_pressed:
			cmp 	byte[tecla_u],0x50
			jne		inc_dec_clock_seconds_ret
			cmp		byte[segundo],0
			je 		dec_seconds_arrow_up_pressed_reset_minutes
			dec		byte[segundo]
			jmp 	inc_dec_clock_seconds_ret

	dec_seconds_arrow_up_pressed_reset_minutes:
			mov		byte[segundo],59
			jmp		inc_dec_clock_seconds_ret

	inc_dec_clock_seconds_ret:
			mov  	byte[tecla_u],0x00
			ret

		
inc_dec_clock_minutes:

			call 	check_kb_press_blocking
			cmp 	byte[tecla_u],0x48
			jne		dec_minutes_arrow_up_pressed	

	inc_minutes_arrow_up_pressed:
			cmp		byte[minuto],59
			je 		inc_minutes_arrow_up_pressed_reset_minutes
			inc		byte[minuto]
			jmp 	inc_dec_clock_minutes_ret

	inc_minutes_arrow_up_pressed_reset_minutes:
			mov		byte[minuto],0
			jmp		inc_dec_clock_minutes_ret

	dec_minutes_arrow_up_pressed:
			cmp 	byte[tecla_u],0x50
			jne		inc_dec_clock_minutes_ret
			cmp		byte[minuto],0
			je 		dec_minutes_arrow_up_pressed_reset_minutes
			dec		byte[minuto]
			jmp 	inc_dec_clock_minutes_ret

	dec_minutes_arrow_up_pressed_reset_minutes:
			mov		byte[minuto],59
			jmp		inc_dec_clock_minutes_ret

	inc_dec_clock_minutes_ret:
			mov  	byte[tecla_u],0x00
			ret



inc_dec_clock_hours:

			call 	check_kb_press_blocking
			cmp 	byte[tecla_u],0x48
			jne		dec_hours_arrow_up_pressed	

	inc_hours_arrow_up_pressed:
			cmp		byte[hora],23
			je 		inc_hours_arrow_up_pressed_reset_hours
			inc		byte[hora]
			jmp 	inc_dec_clock_hours_ret

	inc_hours_arrow_up_pressed_reset_hours:
			mov		byte[hora],0
			jmp		inc_dec_clock_hours_ret

	dec_hours_arrow_up_pressed:
			cmp 	byte[tecla_u],0x50
			jne		inc_dec_clock_hours_ret
			cmp		byte[hora],0
			je 		dec_hours_arrow_up_pressed_reset_hours
			dec		byte[hora]
			jmp 	inc_dec_clock_hours_ret

	dec_hours_arrow_up_pressed_reset_hours:
			mov		byte[hora],23
			jmp		inc_dec_clock_hours_ret

	inc_dec_clock_hours_ret:
			mov  	byte[tecla_u],0x00
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

	preto			equ		0
	azul			equ		1
	verde			equ		2
	cyan			equ		3
	vermelho		equ		4
	magenta			equ		5
	marrom			equ		6
	branco			equ		7
	cinza			equ		8
	azul_claro		equ		9
	verde_claro		equ		10
	cyan_claro		equ		11
	rosa			equ		12
	magenta_claro	equ		13
	amarelo			equ		14
	branco_intenso	equ		15

	modo_anterior	db		0
	linha   		dw  	0
	coluna  		dw  	0
	deltax			dw		0
	deltay			dw		0

;Strings to print on the interface	

	owner    			db 		'TL_2024/2, RAFAEL FRACALOSSI FREITAS 06.1'
	owner_len			dw		41 

	clock_info_str		db		'Hora:'
	clock_info_str_len	dw		5

	menu_info_str		db		'Menu de teclas:'
	menu_info_str_len	dw		15

	sair_str			db		'x: sair'
	sair_str_len		dw		7

	seconds_str			dw		's: para o contador dos segundos.'
	seconds_str_len		dw		32

	minutes_str			dw		'm: para o contador dos minutos.'
	minutes_str_len		dw		31

	hour_str			dw		'h: para o contador das horas.'
	hour_str_len		dw		30

	arrows_str			db		'^ v: ajuste de horario segundo operacao modulo.'
	arrows_str_len		dw		47		


;Clock variables
	eoi     		EQU 	20h
    intr	   		EQU 	08h
	char			db		0
	offset_dos		dw		0
	cs_dos			dw		0
	tique			db  	0
	segundo			db  	0
	minuto 			db  	0
	hora 			db  	0
	horario			db  	0,0,':',0,0,':',0,0,' ', 13,'$'
	horario_len		dw		8

;Keyboard variables

	kb_data 		EQU 60h  ;PORTA DE LEITURA DE TECLADO
	kb_ctl  		EQU 61h  ;PORTA DE RESET PARA PEDIR NOVA INTERRUPCAO
	pictrl  		EQU 20h
	int9    		EQU 9h
	cs_dos_kb  		DW  1
	offset_dos_kb  	DW 1
	tecla_u 		db 0
	tecla   		resb  8 
	p_i     		dw  0   ;ponteiro p/ interrupcao (qnd pressiona tecla)  
	p_t     		dw  0   ;ponterio p/ interrupcao ( qnd solta tecla)    
	teclasc 		DB  0,0,13,10,'$'

;*************************************************************************
segment stack stack
    		resb 		512
stacktop: