; constant byte layout
; 0 identifier
; 256 value
; 264

.code


; out
; rax address
constant_allocate:
xor eax, eax
movzx rbx, constant_list_size
cmp bx, 256
je constant_allocate_return
mov eax, 264
mul rbx
lea rcx, constant_list
add rax, rcx
add bx, 1
mov constant_list_size, bx
constant_allocate_return:
ret


; in
; rax identifier address
; out
; rax amount of constants with matching identifier
constant_count:
xor ebx, ebx
mov cx, constant_list_size
test cx, cx
jz constant_count_return
lea rdx, constant_list
constant_count_loop:
mov rsi, [rax]
cmp [rdx], rsi
jne constant_count_next
mov rsi, [rax+8]
cmp [rdx+8], rsi
jne constant_count_next
mov rsi, [rax+16]
cmp [rdx+16], rsi
jne constant_count_next
mov rsi, [rax+24]
cmp [rdx+24], rsi
jne constant_count_next
mov rsi, [rax+32]
cmp [rdx+32], rsi
jne constant_count_next
mov rsi, [rax+40]
cmp [rdx+40], rsi
jne constant_count_next
mov rsi, [rax+48]
cmp [rdx+48], rsi
jne constant_count_next
mov rsi, [rax+56]
cmp [rdx+56], rsi
jne constant_count_next
mov rsi, [rax+64]
cmp [rdx+64], rsi
jne constant_count_next
mov rsi, [rax+72]
cmp [rdx+72], rsi
jne constant_count_next
mov rsi, [rax+80]
cmp [rdx+80], rsi
jne constant_count_next
mov rsi, [rax+88]
cmp [rdx+88], rsi
jne constant_count_next
mov rsi, [rax+96]
cmp [rdx+96], rsi
jne constant_count_next
mov rsi, [rax+104]
cmp [rdx+104], rsi
jne constant_count_next
mov rsi, [rax+112]
cmp [rdx+112], rsi
jne constant_count_next
mov rsi, [rax+120]
cmp [rdx+120], rsi
jne constant_count_next
mov rsi, [rax+128]
cmp [rdx+128], rsi
jne constant_count_next
mov rsi, [rax+136]
cmp [rdx+136], rsi
jne constant_count_next
mov rsi, [rax+144]
cmp [rdx+144], rsi
jne constant_count_next
mov rsi, [rax+152]
cmp [rdx+152], rsi
jne constant_count_next
mov rsi, [rax+160]
cmp [rdx+160], rsi
jne constant_count_next
mov rsi, [rax+168]
cmp [rdx+168], rsi
jne constant_count_next
mov rsi, [rax+176]
cmp [rdx+176], rsi
jne constant_count_next
mov rsi, [rax+184]
cmp [rdx+184], rsi
jne constant_count_next
mov rsi, [rax+192]
cmp [rdx+192], rsi
jne constant_count_next
mov rsi, [rax+200]
cmp [rdx+200], rsi
jne constant_count_next
mov rsi, [rax+208]
cmp [rdx+208], rsi
jne constant_count_next
mov rsi, [rax+216]
cmp [rdx+216], rsi
jne constant_count_next
mov rsi, [rax+224]
cmp [rdx+224], rsi
jne constant_count_next
mov rsi, [rax+232]
cmp [rdx+232], rsi
jne constant_count_next
mov rsi, [rax+240]
cmp [rdx+240], rsi
jne constant_count_next
mov rsi, [rax+248]
cmp [rdx+248], rsi
jne constant_count_next
add ebx, 1
constant_count_next:
add rdx, 264
add cx, -1
jnz constant_count_loop
constant_count_return:
mov rax, rbx
ret


; in
; rax identifier address
; out
; rax constant address
constant_seek:
mov bx, constant_list_size
test bx, bx
jz constant_seek_failure
lea rcx, constant_list
constant_seek_loop:
mov rdx, [rax]
cmp [rcx], rdx
jne constant_seek_next
mov rdx, [rax+8]
cmp [rcx+8], rdx
jne constant_seek_next
mov rdx, [rax+16]
cmp [rcx+16], rdx
jne constant_seek_next
mov rdx, [rax+24]
cmp [rcx+24], rdx
jne constant_seek_next
mov rdx, [rax+32]
cmp [rcx+32], rdx
jne constant_seek_next
mov rdx, [rax+40]
cmp [rcx+40], rdx
jne constant_seek_next
mov rdx, [rax+48]
cmp [rcx+48], rdx
jne constant_seek_next
mov rdx, [rax+56]
cmp [rcx+56], rdx
jne constant_seek_next
mov rdx, [rax+64]
cmp [rcx+64], rdx
jne constant_seek_next
mov rdx, [rax+72]
cmp [rcx+72], rdx
jne constant_seek_next
mov rdx, [rax+80]
cmp [rcx+80], rdx
jne constant_seek_next
mov rdx, [rax+88]
cmp [rcx+88], rdx
jne constant_seek_next
mov rdx, [rax+96]
cmp [rcx+96], rdx
jne constant_seek_next
mov rdx, [rax+104]
cmp [rcx+104], rdx
jne constant_seek_next
mov rdx, [rax+112]
cmp [rcx+112], rdx
jne constant_seek_next
mov rdx, [rax+120]
cmp [rcx+120], rdx
jne constant_seek_next
mov rdx, [rax+128]
cmp [rcx+128], rdx
jne constant_seek_next
mov rdx, [rax+136]
cmp [rcx+136], rdx
jne constant_seek_next
mov rdx, [rax+144]
cmp [rcx+144], rdx
jne constant_seek_next
mov rdx, [rax+152]
cmp [rcx+152], rdx
jne constant_seek_next
mov rdx, [rax+160]
cmp [rcx+160], rdx
jne constant_seek_next
mov rdx, [rax+168]
cmp [rcx+168], rdx
jne constant_seek_next
mov rdx, [rax+176]
cmp [rcx+176], rdx
jne constant_seek_next
mov rdx, [rax+184]
cmp [rcx+184], rdx
jne constant_seek_next
mov rdx, [rax+192]
cmp [rcx+192], rdx
jne constant_seek_next
mov rdx, [rax+200]
cmp [rcx+200], rdx
jne constant_seek_next
mov rdx, [rax+208]
cmp [rcx+208], rdx
jne constant_seek_next
mov rdx, [rax+216]
cmp [rcx+216], rdx
jne constant_seek_next
mov rdx, [rax+224]
cmp [rcx+224], rdx
jne constant_seek_next
mov rdx, [rax+232]
cmp [rcx+232], rdx
jne constant_seek_next
mov rdx, [rax+240]
cmp [rcx+240], rdx
jne constant_seek_next
mov rdx, [rax+248]
cmp [rcx+248], rdx
jne constant_seek_next
mov rax, rcx
ret
constant_seek_next:
add rcx, 264
add bx, -1
jnz constant_seek_loop
constant_seek_failure:
xor eax, eax
ret


.data

align 2
constant_list_size word 0

align 8
constant_list byte 67584 dup(0) ; 256 constants