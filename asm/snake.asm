assume cs:code,ds:data,ss:stack

data segment

COLOR		dw	0308H
SNAKE_HEAD	dw	0
NEXT_ROW	dw	160
SNAKE_STERN	dw	12
SNAKE		dw	200 dup (0,0,0)
SNAKE_COLOR	dw	0E02H

UP		db	48H
DOWN		db	50H
LEFT		db	4BH
RIGHT		db	4DH

screen_color	dw	0700H

DIRECTION	dw	1
	
DIRECTION_FUN	dw	OFFSET	IsMoveUp - greedy_snake + 7E00H		
		dw	OFFSET	IsMoveDown - greedy_snake + 7E00H
		dw	OFFSET	IsMoveLeft - greedy_snake + 7E00H
		dw	OFFSET	IsMoveRight - greedy_snake + 7E00H

FOOD_LOCATION	dw	160*3+40
FOOD_COLOR	dw	0C03H
NEW_FOOD	dw	18
data ends

stack segment stack

	db   128 dup(0)

stack ends
;===================================================================
code segment

start:
	mov ax,stack
	mov ss,ax
	mov sp,128

	call cpy_greedy_snake
	call save_old_int9
	call set_new_int9

	mov bx,0
	push bx
	mov bx,7E00H
	push bx
	retf

	mov ax,4C00H
	int 21H
;===================================================================
greedy_snake:

	call init_reg
	call clear_screen
	call init_screen
;	call init_food
;	call init_snake

nextA:	call delay
	cli
	call isMoveDIRECTION
	sti
	jmp nextA
	
testA:	mov ax,1000H
	jmp testA	

	mov ax,4C00H
	int 21H
;===================================================================
init_food:
	mov di,FOOD_LOCATION
	push FOOD_COLOR
	pop es:[di]
	
	ret
;===================================================================
isMoveDIRECTION:
	
	mov bx,DIRECTION
	add bx,bx
	call word ptr ds:DIRECTION_FUN[bx]
	ret
;===================================================================
delay:
	push ax
	push dx
	
	mov dx,3000H
	sub ax,ax
	
delaying:
	sub ax,1
	sbb dx,0
	cmp dx,0
	jne delaying
	cmp ax,0
	jne delaying
	pop dx
	pop ax
	ret
;===================================================================
init_snake:
	
	mov bx,OFFSET SNAKE
	add bx,SNAKE_HEAD
	mov si,160*4+20*2
	mov dx,SNAKE_COLOR
	
	mov word ptr ds:[bx+0],0
	mov ds:[bx+2],si
	mov es:[si],dx
	mov word ptr ds:[bx+4],6
	sub si,2
	add bx,6

	mov word ptr ds:[bx+0],0
	mov ds:[bx+2],si
	mov es:[si],dx
	mov word ptr ds:[bx+4],12
 
	sub si,2
	add bx,6

	mov word ptr ds:[bx+0],6
	mov ds:[bx+2],si
	mov es:[si],dx
	mov word ptr ds:[bx+4],18
	
	ret
;===================================================================
init_screen:
	mov dx,COLOR
	call show_up_down_line
	call show_left_right_line
	ret

show_left_right_line:
	mov bx,160
	mov cx,23
	
showleftrightline:
	mov es:[bx],dx
	mov es:[bx+158],dx
	add bx,NEXT_ROW
	loop showleftrightline
	ret

show_up_down_line:
	mov bx,0
	mov cx,80

showUPDownline:
	mov es:[bx],dx
	mov es:[bx+160*23],dx
	add bx,2
	loop showUPDownline
	ret
;===================================================================
clear_screen:
	mov bx,0
	mov dx,screen_color
	mov cx,2000
	
clearscreen:
	mov es:[bx],dx
	add bx,2
	loop clearscreen
	
	ret
;===================================================================
init_reg:

	mov bx,0B800H
	mov es,bx
	
	mov bx,data
	mov ds,bx
	ret
;===================================================================
new_int9:
	push ax
	call clear_buff
	
	in al,60H
	pushf
	call dword ptr cs:[200H]
	
	cmp al,UP
	je IsUp

	cmp al,DOWN
	je IsDown

	cmp al,LEFT
	je IsLeft

	cmp al,RIGHT
	je IsRight
	
	cmp al,3BH
	jne int9Ret
	
	call change_sreen_color

int9Ret:
	pop ax
	iret
;===================================================================
IsUp:
	cmp DIRECTION,1
	je int9Ret
	call IsMoveUp
	jmp int9Ret

IsDown:
	cmp DIRECTION,0
	je int9Ret
	call IsMoveDown
	jmp int9Ret
IsLeft:
	cmp DIRECTION,3
	je int9Ret
	call IsMoveLeft
	jmp int9Ret
IsRight:
	cmp DIRECTION,2
	je int9Ret	
	call IsMoveRight
	jmp int9Ret
;===================================================================
IsMoveUp:
	mov bx,OFFSET SNAKE


	add bx,SNAKE_HEAD
	mov si,ds:[bx+2]

	sub si,NEXT_ROW
	cmp byte ptr es:[si],0
	jne NotMoveUp
	call draw_snake
	mov DIRECTION,0
	ret
NotMoveUp:	call isFood
	ret
;===================================================================
IsMoveDown:
	mov bx,OFFSET SNAKE
	add bx,SNAKE_HEAD
	mov si,ds:[bx+2]
	add si,NEXT_ROW
	cmp byte ptr es:[si],0
	jne NotMoveDown
	call draw_snake
	mov DIRECTION,1
	ret
NotMoveDown:	call isFood
	ret
;===================================================================
IsMoveLeft:
	mov bx,OFFSET SNAKE
	add bx,SNAKE_HEAD
	mov si,ds:[bx+2]
	sub si,2
	cmp byte ptr es:[si],0
	jne NotMoveLeft
	call draw_snake
	mov DIRECTION,2
	ret
NotMoveLeft:	call isFood
	ret
;===================================================================
IsMoveRight:
	mov bx,OFFSET SNAKE
	add bx,SNAKE_HEAD
	mov si,ds:[bx+2]
	add si,2
	cmp byte ptr es:[si],0
	jne NotMoveRight
	call draw_snake
	mov DIRECTION,3
	ret
NotMoveRight:	call isFood
	ret
;===================================================================
IsFood:
	cmp byte ptr es:[si],3	;�����ʳ��ͼ���ִ��
	jne noFood		;�������������������������

	push FOOD		;��ʳ��ѹ��ջ��
	pop ds:[bx+0]		;

	mov bx,OFFSET SNAKE	
	add bx,FOOD
	mov word ptr ds:[bx+0],0
	
	mov ds:[bx+2],si	;ԭ��ʳ��ĵط��ĳ���ͷ
	push SNAKE_COLOR
	pop es:[si]
	
	push SNAKE_HEAD		;�����µ�����
	pop ds:[bx+4]

	push NEW_FOOD		
	pop SNAKE_HEAD
	add NEW_FOOD,6
	
	call new_food		;���������µ�ʳ��
	noFood:	ret
;===================================================================
new_food:		
			
	mov al,0 	;����CMOS RAM
	out 70H,al	;��ȡʱ�䣨������
	in al,71H	;ͨ���������ﵽ�������ʳ��ĵ�ַ
	
	mov dl,al
	and dl,00001111B
	shr al,1
	shr al,1
	shr al,1
	shr al,1
	
	mov bl,10
	mul bl
	add al,dl
	
	mul al
	
	shr al,1	;������һλ��������һλ���������ܱ�֤��0λһ���Ǹ�0
	shl al,1	;�����е�Ŀ����Ϊ��ȷ�����һ��Ҫ�Ǹ�ż��
	mov bx,ax	;��Ϊֻ��ż����ַ������ʾ����Ļ��


	cmp byte ptr es:[bx],0 ;����������ɵ�λ���ǲ��ǿյ�
	jne new_food           ;���������������ʳ��
	push FOOD_COLOR
	pop es:[bx]	       ;������ɳɹ�����ʾ

	ret
;====================================================================
draw_snake:
	push SNAKE_STERN
	pop ds:[bx+0]
	mov bx,OFFSET SNAKE
	add bx,SNAKE_STERN
	push ds:[bx+0]
	
	mov word ptr ds:[bx+0],0
	mov di,ds:[bx+2]
	
	push screen_color
	pop es:[di]
	mov ds:[bx+2],si
	push SNAKE_COLOR
	pop es:[si]
	push SNAKE_HEAD
	pop ds:[bx+4]

	push SNAKE_STERN
	pop SNAKE_HEAD
	pop SNAKE_STERN
	
	ret
;===================================================================
clear_buff:
	mov ah,1
	int 16H
	jz clearBuffRet

	mov ah,0
	int 16H
	jmp clear_buff
clearBuffRet:
	ret
;===================================================================
change_sreen_color:
	push bx
	push cx
	push es
	

	mov bx,0B800H
	mov es,bx
	mov bx,1
	
	mov cx,2000

changeSreen:
	
	inc byte ptr es:[bx]
	add bx,2
	loop changeSreen

	pop es
	pop cx
	pop bx

	ret
greedy_snake_end: nop
;===================================================================
set_new_int9:
	
	mov bx,0
	mov es,bx
	
	cli
	mov word ptr es:[9*4],OFFSET new_int9 - OFFSET greedy_snake + 7E00H
	mov word ptr es:[9*4+2],0
	sti

	ret
;===================================================================
save_old_int9:
	mov bx,0
	mov es,bx
	
	cli
	push es:[9*4]
	pop es:[200H]
	push es:[9*4+2]
	pop es:[202H]
	sti
	ret
;===================================================================
cpy_greedy_snake:

	mov bx,cs
	mov ds,bx
	mov si,OFFSET greedy_snake
	
	mov bx,0
	mov es,bx
	mov di,7E00H

	mov cx,OFFSET greedy_snake_end - OFFSET greedy_snake
	cld
	rep movsb
	ret
;===================================================================
code ends
end start



