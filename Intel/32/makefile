CC=gcc
ASMBIN=nasm

all: asm cc link clean
asm:
	$(ASMBIN) -o rotate.o -f  elf -g -l rotate.lst rotate.asm
cc:
	$(CC) -c -g -O0 rot.c
link:
	$(CC) -m32 rot.o rotate.o -o rotation
clean:
	rm *.o
	rm rotate.lst
