#!/bin/bash

dd if=bootr.img of="$1" bs=1 count=446 conv=notrunc
dd if=ide_386l.bin of="$1" bs=512 seek=16 conv=notrunc

