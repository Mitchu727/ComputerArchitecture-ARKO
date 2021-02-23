CC=gcc
ASMBIN=nasm

all : asm cc link
asm : 
	$(ASMBIN) -o rotate.o -g -f elf64 rotate.asm
cc :
	$(CC) -c -g -O0 rot.c
link :
	$(CC) -o rotation rot.o rotate.o
clean :
	rm *.o
	rm rotation
