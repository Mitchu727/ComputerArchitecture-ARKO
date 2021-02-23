section .text
global rotate

rotate:
	push ebp
	mov ebp, esp
	
	push ebx
	push esi
	push edi
	
	mov edi, [ebp+8]		;adres pierwotny
	mov esi, [ebp+12]		;adres docelowy
	mov edx, [ebp+16]		;szerokosc (w bajtach)
	mov ecx, [ebp+20]		;wysokosc (w bajtach)
	mov al, byte[edi]
	ror eax, 8
	add edi, edx
	mov al, byte[edi]
	ror eax, 8
	add edi, edx
	mov al, byte[edi]
	ror eax, 8
	add edi, edx
	mov al, byte[edi]
	add edi, edx
	ror eax, 8
	
	mov bl, byte[edi]
	ror ebx, 8
	add edi, edx
	mov bl, byte[edi]
	ror ebx, 8
	add edi, edx
	mov bl, byte[edi]
	ror ebx, 8
	add edi, edx
	mov bl, byte[edi]
	add edi, edx
	ror ebx, 8
	mov ecx, $0
bit:
	; eax - dolna połowa kwadratu 8x8
	; ebx - górna połowa kwadratu 8x8
	; ch - baj do zapisu
	; cl - licznik pętli
	; edx - maska (10000000100000001000000010000000)
	mov edx, 2155905152
	shr edx, cl
	and edx, eax
	shl edx, cl
	or ch, dl 
	shr edx, 9
	or ch, dl 
	shr edx, 9
	or ch, dl 
	shr edx, 9
	or ch, dl 
	mov edx, 2155905152
	shr edx, cl
	and edx, ebx
	shl edx, cl
	shr edx, 4
	or ch, dl 
	shr edx, 9
	or ch, dl 
	shr edx, 9
	or ch, dl 
	shr edx, 9
	or ch, dl 
	mov [esi], ch
	sub esi, [ebp + 20]
	mov ch, $0
	inc cl
	cmp cl, 8
	jne bit

	
end:
	pop edi
	pop esi
	pop ebx
	
	pop ebp
	ret

	