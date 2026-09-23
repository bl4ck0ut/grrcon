bits 16
org 100h

start:
    push cs
    pop ds
    ; Find first *.COM
    mov ah, 4Eh
    mov dx, pattern
    xor cx, cx
    int 21h
    jc done

next_file:
    ; Open file from DTA (PSP:9Eh)
    mov ah, 3Dh
    mov dx, 9Eh
    mov al, 2
    int 21h
    jc find_next

    mov bx, ax

    ; Read first 3 bytes
    mov ah, 3Fh
    mov cx, 3
    mov dx, hdr
    int 21h
    jc close_file

    ; Check for E9 jump
    cmp byte [hdr], 0E9h
    jne close_file

    ; Read saved bytes at offset = displacement
    mov ax, [hdr+1]         ; AX = displacement (orig size)
    xor cx, cx
    mov dx, ax
    mov ah, 42h
    mov al, 0
    int 21h                 ; seek to saved bytes

    mov ah, 3Fh
    mov cx, 3
    mov dx, saved
    int 21h
    jc close_file

    ; Restore first 3 bytes at start
    xor cx, cx
    xor dx, dx
    mov ah, 42h
    mov al, 0
    int 21h                 ; seek to start

    mov ah, 40h
    mov cx, 3
    mov dx, saved
    int 21h

    ; Truncate to original size (displacement)
    mov ax, [hdr+1]
    xor cx, cx
    mov dx, ax
    mov ah, 42h
    mov al, 0
    int 21h                 ; seek to orig size

    mov ah, 40h
    xor cx, cx              ; write 0 bytes => truncate
    int 21h

    ; Verbose output: CLEANED <filename>
    push ax
    push bx
    push cx
    push dx
    push si

    mov dx, msg_cleaned
    mov ah, 09h
    int 21h

    mov si, 9Eh             ; filename in DTA
.print_name:
    mov al, [si]
    cmp al, 0
    je .print_crlf
    mov dl, al
    mov ah, 02h
    int 21h
    inc si
    jmp .print_name

.print_crlf:
    mov dx, msg_crlf
    mov ah, 09h
    int 21h

    pop si
    pop dx
    pop cx
    pop bx
    pop ax

close_file:
    mov ah, 3Eh
    int 21h

find_next:
    mov ah, 4Fh
    int 21h
    jnc next_file

done:
    mov ax, 4C00h
    int 21h

pattern db "*.COM",0
hdr     db 0,0,0
saved   db 0,0,0
msg_cleaned db "CLEANED ",'$'
msg_crlf    db 13,10,'$'
