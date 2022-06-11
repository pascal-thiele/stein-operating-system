.code


terminal_out:
add rsp, -88
mov [rsp+40], r10
mov [rsp+48], r11
mov [rsp+56], r12
mov [rsp+64], r13
mov [rsp+72], r14
mov [rsp+80], r15

mov ecx, -11
call GetStdHandle
test rax, rax
jz terminal_out_clear

mov rcx, rax
lea rdx, terminal_buffer
movzx r8, terminal_buffer_size
xor r9d, r9d
mov qword ptr[rsp+32], 0
call WriteConsoleA

terminal_out_clear:
mov terminal_buffer_size, 0

mov r10, [rsp+40]
mov r11, [rsp+48]
mov r12, [rsp+56]
mov r13, [rsp+64]
mov r14, [rsp+72]
mov r15, [rsp+80]
add rsp, 88
ret


; in
; al character to append
terminal_append_character:
lea rbx, terminal_buffer
movzx rcx, terminal_buffer_size
add rbx, rcx
mov [rbx], al
add cx, 1
mov terminal_buffer_size, cx
ret


; in
; rax string address
; bx string size
terminal_append_string:
lea rcx, terminal_buffer
movzx rdx, terminal_buffer_size
add rcx, rdx
add dx, bx
mov terminal_buffer_size, dx
terminal_append_string_loop:
mov sil, [rax]
mov [rcx], sil
add rax, 1
add rcx, 1
add bx, -1
jnz terminal_append_string_loop
ret


; in
; rax signed integer
terminal_append_integer:
lea rbx, terminal_buffer
movzx rcx, terminal_buffer_size
add rbx, rcx

; check for negative
test rax, rax
jns terminal_append_integer_digit
neg rax
mov byte ptr[rbx], 45
add rbx, 1
add cx, 1

terminal_append_integer_digit:
xor si, si ; digit count
mov edi, 10
terminal_append_integer_digit_loop:
xor edx, edx
div rdi
add dl, 48
add rsp, -1
mov [rsp], dl
add si, 1
test rax, rax
jnz terminal_append_integer_digit_loop
add cx, si
mov terminal_buffer_size, cx

terminal_append_integer_reverse:
mov dl, [rsp]
add rsp, 1
mov [rbx], dl
add rbx, 1
add si, -1
jnz terminal_append_integer_reverse
ret


.data

align 2
terminal_buffer_size word 0

align 8
terminal_buffer byte 1024 dup(0)