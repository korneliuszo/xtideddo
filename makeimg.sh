#!/bin/bash

set -ex

nasm bootr.asm -o bootr.bin

#nasm bootr.asm -f elf -g -o bootr.o
#ld -m elf_i386 -Ttext=0x7c00 -o bootr.elf bootr.o
#objcopy -O binary bootr.elf bootr.bin

cp bootr.bin bootr.img
dd if=ide_386l.bin of=bootr.img bs=512 seek=16
cp bootr.img bootr.img.padded
truncate -s 10M bootr.img.padded
(
echo n # Add a new partition
echo p # Primary partition
echo 1 # Partition number
echo   # First sector (Accept default: 1)
echo   # Last sector (Accept default: varies)
echo t
echo c
echo w # Write changes
) | fdisk bootr.img.padded
