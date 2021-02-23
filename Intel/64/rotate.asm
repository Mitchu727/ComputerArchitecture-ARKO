;=====================================================================
; ARKOC x86-64 - obracanie obrazka Michał Matak
;=====================================================================

section	.text
global  rotate

rotate:
	push rbp
	mov rbp, rsp
	push rbx
	;parametry 
	;rdi adres pierwotny
	;rsi adres docelowy
	;rdx szerokosc (w bajtach)
	;rcx wysokosc (w bajtach) - przeniseione do rbx
	mov rbx, rcx
	
	mov al, byte[rdi]
	ror rax, 8
	add rdi, rdx
	mov al, byte[rdi]
	ror rax, 8
	add rdi, rdx
	mov al, byte[rdi]
	ror rax, 8
	add rdi, rdx
	mov al, byte[rdi]
	ror rax, 8
	add rdi, rdx
	mov al, byte[rdi]
	ror rax, 8
	add rdi, rdx
	mov al, byte[rdi]
	ror rax, 8
	add rdi, rdx
	mov al, byte[rdi]
	ror rax, 8
	add rdi, rdx
	mov al, byte[rdi]
	ror rax, 8
	add rdi, rdx
	mov rcx, 8
bit:
	; rax - kwadrat 8x8
	; rdx - maska
	; ch - bajt do zapisu
	; cl - licznik pętli
	mov rdx, 80808080h
	shl rdx, 32
	mov rdi, 80808080h
	or rdx, rdi
	; dziwne ładowanie maski - nie udało się od razu załadować 8080808080808080h do rdx
	and rdx, rax
	or ch, dl 
	shr rdx, 9
	or ch, dl 
	shr rdx, 9
	or ch, dl 
	shr rdx, 9
	or ch, dl 
	shr rdx, 9
	or ch, dl 
	shr rdx, 9
	or ch, dl 
	shr rdx, 9
	or ch, dl 
	shr rdx, 9
	or ch, dl
	
	mov [rsi], ch
	sub rsi, rbx
	mov ch, $0
	rol rax, 1
	dec cl
	jne bit
	
	pop rbx
	pop rbp
	ret