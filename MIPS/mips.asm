#--------------------------------------------------------------------------------------------------------
#	Micha� Matak grupa 101
# Kod jest d�ugi, poniewa� zdecydowa�em si� aby funkcj� by�y jak najbardziej uniwersalne i reu�ywalne 
#--------------------------------------------------------------------------------------------------------
.eqv	headeraddr 	0
.eqv    filesize   	4
.eqv	imgaddr    	8
.eqv	imgwidth   	12
.eqv    imgheight  	16
.eqv    rowsize    	20
.eqv	new_rowsize	24

	.data
imgdescriptor:	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0
	.word 0

img:	.space 	1024
fname:	.asciiz "wtest.bmp"
outfname: .asciiz "outfile.bmp"
	.text
main:
	la $a0 img
	la $a1 outfname
	la $a2 fname
	jal rotation_left
	j main_exit

rotation_left:
	# wywo�anie funkjci - obr�t obrazka o 90 w lewo
	# $a0 / $s5 img
	# $a1 / $s6 nazwa wyj�ciowa obrazka
	# $a2 / $s7 nazwa obrazka
	# uwaga - funkcja dzia�a na zasadzie odbicia symetrycznego obrazu wzgl�dem osi 45, a nast�pnie wzgl�dem osi poziomej, 
	# t� kolejno�� mo�na zmieni� i wtedy obrazek obraca si� w prawo o 90 stopni (change dimension musi zawsze nast�powa� po reflection45)
	move $s5, $a0
	move $s6, $a1
	move $s7, $a2
	
	sw $ra, 0($sp)
	move $a0, $s7
	move $a1, $s5
	jal read_bmp_file
	bltz $v0, main_exit
	
	move $a0, $v1
	move $a1, $s5
	la $a2 imgdescriptor
	jal load	
	
	la $a0 imgdescriptor
	jal allocate_memory
	
	la $a0 imgdescriptor
	lw $a1, imgaddr($a0)
	move $a2, $v0
	jal reflection45
	la $a0 imgdescriptor
	move $a1, $s5
	jal change_dimension
	
	la $a0 imgdescriptor
	move $a1, $v0
	lw $a2, imgaddr($a0)
	jal reflection_horizontal
	
	move $a0, $s6
	la $a1 imgdescriptor
	jal saving
	lw $ra, 0($sp)
	jr $ra

main_exit:	
	li $v0, 10
	syscall
	
read_bmp_file:
	# funkcja czytaj�ca plik
	# $a0 - adres nazwy pliku do odczytania
	# $a1 - adres miejsca w pami�ci na obraz
	# $v0 - informacja o b��dzie
	# $v1 - rozmiar odczytanego pliku (w bajtach)  
	move $t1, $a1
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	move $t0, $v0
	move $a0, $v0
	move $a1, $t1
	li $a2, 1024
	li $v0, 14
	syscall
	move $t1, $v0
	li $v0, 16
	syscall
	move $v0, $t0
	move $v1, $t1
	jr $ra
load:
	# funkcja wczytaj�ca dane o pliku do tablicy - deskryptora
	# $a0 - rozmiar pliku
	# $a1 - adres miejsca w pami�ci na obraz - adres obrazu
	# $a2 - adres deskryptora
	# brak wyj�cia w rejestrach $v, funkcja wype�nia deksryptor danymi o obrazie 
	sw $a0, filesize($a2)
	sw $a1, headeraddr($a2)
	lhu $t0, 10($a1)
	addu $t0, $a1, $t0
	sw $t0, imgaddr($a2)
	lhu $t0, 18($a1)
	sw $t0, imgwidth($a2) 
	addiu $t0, $t0, 31
	srl $t0, $t0, 5
	sll $t0, $t0, 2
	sw $t0, rowsize($a2)
	lhu $t0, 22($a1)
	sw $t0, imgheight($a2) 
	addiu $t0, $t0, 31
	srl $t0, $t0, 5
	sll $t0, $t0, 2
	sw $t0, new_rowsize($a2)
	jr $ra
	
allocate_memory:
	# alokacja pami�ci dla obrazka, kt�rego dane s� w deskryptorze
	# $a0 - adres deskryptora obrazu 
	# $v0 - adres zaalokowanej pami�ci
	move $t1, $a0
	lw $t0, filesize($a0)
	subiu $t0, $t0, 62
	sll $t0, $t0, 3
	move $a0, $t0
	li $v0, 9
	syscall
	jr $ra 	

reflection45:
	# funkcja odbijaj�ca obraz zapisany w $a1 wzgl�dem osi osi o nachyleniu 45 stopni i zapisuj�ca go w $a2
	# $a0 - adres deskryptora obrazu - sta�y wska�nik na imgdescriptor
	# $a1 - adres obrazu do odbicia
	# $a2 - adres docelowy
	# funkcja nie posiada wyj�cia w rejestrach $v
	# $a3 - rowsize - nie jest argumentem funkcji, u�ywany jako rejestr pomocniczy
	# $t0 - rejestr, do kt�reo wczytywany jest bajt
	# $t1 - rejestr, kt�ry wskazuje bajt do odczytania
	# $t2 - bajt przeznaczony do zapisu
	# $t3 - licznik p�tli dla bajtu
	# $t4 - licznik p�tli - bajty w kwadracie 8x8
	# $t5 - licznik p�tli - kwadraty 8x8 w kolumnie
	# $t6 - licznik p�tli - kolumny w ca�ej szeroko�ci obrazka
	# $t7 - rejestr, kt�ry wskazuje kwadrat do odczytania
	# $t8 - maska bitowa
	# $t9 - miejsce zapisu
	# $s0 - ograniczenie dla 3 p�tli
	# $s1 - ograniczenie dla 4 p�tli
	# $s2 - liczba pokazuj�ca o ile bajt�w trzeba skoczy� do przodu/ty�u by odczyta� kwadrat powy�ej/poni�ej = 8*rowsize
	# $s3 - new_rowsize liczba bajt�w okre�laj�ca ile bajt�w zajmie wysoko�� przekszta�cona w rz�d
	# $s4 - liczba pokazuj�ca o ile bajt�w trzeba skoczy� do przodu/ty�u by zapisa� kwadrat powy�ej/poni�ej = 8*rowsize (po przekszta�ceniu)
	lw $t5, imgwidth($a0)
	lw $t6, imgheight($a0) 
	srl $s0, $t6, 3	 
	srl $s1, $t5, 3
	lw $a3, rowsize($a0)
	sll $s2, $a3, 3
	lw $s3, new_rowsize($a0)
	sll $s4, $s3, 3 
	move $t1, $a1
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	move $t7, $a1
	li $t8, 1
	sll $t8, $t8, 7
	move $t9, $a2
new_bite:
	lbu $t0 0($t1)
	and $t0, $t0, $t8
	sllv $t0,$t0, $t4
	srlv $t0,$t0, $t3
	or $t2, $t0, $t2

	addiu $t3, $t3, 1
	addu $t1, $t1, $a3
	bne $t3, 8, new_bite
	#koniec pierwszej p�tli - zape�nienie bajtu
	
	sb $t2, 0($t9)
	addu $t9, $t9, $s3
	addiu $t4, $t4, 1
	srl $t8, $t8, 1
	li $t2, 0
	li $t3, 0
	move $t1, $t7
	bne $t4, 8, new_bite
	#koniec drugiej p�tli - wpisanie kwadratu 8x8		
	
	subu $t9, $t9, $s4
	addiu $t9, $t9, 1
	addu $t7, $t7, $s2
	li $t8, 1
	sll $t8, $t8, 7
	move $t1, $t7
	li $t4, 0
	addiu $t5, $t5, 1
	bne $t5,$s0, new_bite
	# koniec 3 p�tli - kolumna pierwotnego obrazka przkeszta�cona
	
	move $t7, $a1
	addiu $t6, $t6, 1
	addu $t7, $t7, $t6
	li $t5, 0	
	move $t1, $t7
	subu $t9, $t9, $s0 
	addu $t9, $t9, $s4
	bne $t6,$s1, new_bite
	# koniec 4 p�tli - ca�y obrazek przkeszta�cony
	jr $ra

change_dimension:
	# $a0 - adres deskryptora
	# $a1 - adres obrazu
	# funkcja nie ma wyj��ia w rejestrach $v
	# funkcja stawia do danych obrazka zmienione odpowiednio dane z deskrytprora oraz zmienia dane w deskryptorze
	move $t0, $a0
	lw $t0, imgheight($a0)
	lw $t1, imgwidth($a0)
	lw $t2, new_rowsize($a0)
	lw $t3, rowsize($a0)
	sw $t1, imgheight($a0)
	sw $t0, imgwidth($a0)
	sw $t3, new_rowsize($a0)
	sw $t2, rowsize($a0)	
	sh $t1, 22($a1)
	sh $t0, 18($a1)
	mul $t0, $t2, $t1
	addiu $t0, $t0, 62
	sw $t0, filesize($a0)	
	jr $ra	
reflection_horizontal:
	# funkcja odbijaj�ca obraz zapisany w $a1 wzgl�dem osi poziomej i zapisuj�ca go w $a2
	# $a0 - adres deskryptora obrazu
	# $a1 - adres obrazu do odbicia
	# $a2 - adres docelowy
	# funkcja nie ma wyj��ia w rejestrach $v
	# $t0 - wska�nik na adres obrazu pierwotnego
	# $t1 - wska�nik na adres obrazu docelowego
	# $t2 - na pocz�tku u�yty aby obliczy� wielko�� obrazu, p�niej bajt wczytywany i zapisywany
	# $t3 - licznik 1 p�tli - sprawdza czy zosta� przepisany ca�y wiersz - je�li nie to przepisuje nast�pny bajt
	# $t4 - licznik 2 p�tli - sprawdza czy zosta� przepisany ca�y obrazek - je�li nie odpowiednio modyfikuje wska�niki i przechodzi do nast�pnego wiersza 
	# $t5 -  ograniczenie dla pierwszej p�tli - wpisywanie jednego wiersza
	# $t6 -  ograniczenie dla drugiej p�tli - wpisanie ca�ego obrazka
	move $t0, $a1
	move $t1, $a2
	li $t3, 0
	li $t4, 0
	lw $t5, rowsize($a0)
	lw $t6 imgheight($a0)
	lw $t2, filesize($a0)
	subiu $t2, $t2, 62
	addu $t0, $t0, $t2
	subu $t0, $t0, $t5
write_byte:
	lbu $t2, 0($t0)							
	sb $t2, 0($t1)
	addiu $t0, $t0, 1
	addiu $t1, $t1, 1
	addiu $t3, $t3, 1	
	bne $t3, $t5, write_byte
	li $t3, 0
	subu $t0, $t0, $t5
	subu $t0, $t0, $t5	
	addiu $t4, $t4, 1
	bne $t4, $t6, write_byte
	jr $ra

saving:
	# zapisywanie pliku
	# $a0 - nazwa zapisanego pliku
	# $a1 - adres deskryptora obrazu 
	move $t0, $a1
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	move $a0, $v0
	lw $a1, headeraddr($t0)
	lw $a2, filesize($t0)
	li $v0, 15
	syscall
	li $v0, 16
	syscall
	jr $ra
