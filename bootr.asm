CPU 386
[CPU 386]

%define IMAGE_SEC	20
%define IMAGE_KB	IMAGE_SEC/2

%define drive		bp+03h		;byte  Drive number
%define oldSP		bp+04h
%define oldSS		bp+06h
%define mem_off		0413h		;byte  KB of conventional memory

	org	0x0600

entry:
	jmp	short begin

brINT13Flag     DB      90H             ; 0002h - 0EH for INT13 AH=42 READ
brDrive		    DB      0               ; 0003h - Physical drive no.
brOldSP			DW 		0h				; 0004h
brOldSS			DW 		0h				; 0006h

begin:
	cli                         ; We do not want to be interrupted
	xor ax, ax                  ; 0 AX
	mov bx, ss
	mov cx, sp
	mov ds, ax                  ; Set Data Segment to 0
	mov es, ax                  ; Set Extra Segment to 0
	mov ss, ax                  ; Set Stack Segment to 0
	mov sp, 0x7C00              ; Set Stack Pointer to 0x7c00
	mov	bp, sp
	mov [oldSP], cx
	mov [oldSS], bx
  .CopyLower:
    mov cx, 0x0100            ; 256 WORDs in MBR
    mov si, 0x7C00            ; Current MBR Address
    mov di, 0x0600            ; New MBR Address
    rep movsw                 ; Copy MBR
  jmp 0:LowStart              ; Jump to new Address

LowStart:
	;push sp
	sti
	mov	[drive], dl	;Drive number

	mov	ax, 0xE42	;Start message with B
	mov	bx, 0
	int	10h

	mov ax, [mem_off]
	cmp ax, 639
	jne chainload
	sub ax, IMAGE_KB
	mov [mem_off], ax
	mov cl, 6
	shl ax, cl
	mov bx, ax
	
	mov ah, 02h
	mov al, IMAGE_SEC
	mov ch, 00h
	mov cl, 11h
	mov dh, 00h
	mov dl, [drive]
	mov es, bx
	mov bx, 00h
	int 13h
	jnc	noerror
	mov	ax, 0xE45	;Start message with E
	mov	bx, 0
	int	10h
loop:
	hlt
	jmp loop
noerror:
	mov	ax, 0xE4C	;Start message with L
	mov	bx, 0
	int	10h
	
	mov ax, [mem_off]
	mov cl, 6
	shl ax, cl
	mov word [.1+3], ax

.1:	call 0xa000:3
	mov	ax, 0xE52	;Start message with R
	mov	bx, 0
	int	10h
	cli
	mov ss, [oldSS]
	mov sp, [oldSP]
	sti
	int	19h		;Try to reboot

chainload:
	mov	ax, 0xE43	;Start message with C
	mov	bx, 0
	int	10h


	mov ax, [0x07c6]
	mov [offset], ax
	mov ax, [0x07c8]
	mov [offset+2], ax
	mov ah, 42h
	mov dl, 0x80
	mov si, int1342
	int 13h
	jc	error2
	mov	ax, 0xE4C	;Start message with L
	mov	bx, 0
	int	10h
	cmp WORD [0x7DFE], 0xAA55
	jne error2
	mov	ax, 0xE42	;Start message with B
	mov	bx, 0
	int	10h
	jmp 0x0000:0x7c00
error2:
	mov	ax, 0xE45	;Start message with E
	mov	bx, 0
	int	10h
loop2:
	hlt
	jmp loop2

int1342:
db 10h
db 0h
dw 1h
dw 0x7c00
dw 0h
offset:
dd 0
dd 0

size	equ	$ - entry
%if size+2 > 440
  %error "code is too large for boot sector"
%endif
	times	(512 - size - 2) db 0

	db	0x55, 0xAA		;2  byte boot signature
