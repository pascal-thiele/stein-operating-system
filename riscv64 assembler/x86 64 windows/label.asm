; label byte layout
; 0 identifier
; 256 value
; 264

.code


; out
; rax address
label_allocate:
xor eax, eax
movzx rbx, label_list_size
cmp bx, 16384
je label_allocate_return
mov eax, 264
mul rbx
lea rcx, label_list
add rax, rcx
add bx, 1
mov label_list_size, bx
label_allocate_return:
ret


; in
; rax identifier address
; out
; rax amount of labels with matching identifier
label_count:
xor ebx, ebx
mov cx, label_list_size
test cx, cx
jz label_count_return
lea rdx, label_list
label_count_loop:
mov rsi, [rax]
cmp [rdx], rsi
jne label_count_next
mov rsi, [rax+8]
cmp [rdx+8], rsi
jne label_count_next
mov rsi, [rax+16]
cmp [rdx+16], rsi
jne label_count_next
mov rsi, [rax+24]
cmp [rdx+24], rsi
jne label_count_next
mov rsi, [rax+32]
cmp [rdx+32], rsi
jne label_count_next
mov rsi, [rax+40]
cmp [rdx+40], rsi
jne label_count_next
mov rsi, [rax+48]
cmp [rdx+48], rsi
jne label_count_next
mov rsi, [rax+56]
cmp [rdx+56], rsi
jne label_count_next
mov rsi, [rax+64]
cmp [rdx+64], rsi
jne label_count_next
mov rsi, [rax+72]
cmp [rdx+72], rsi
jne label_count_next
mov rsi, [rax+80]
cmp [rdx+80], rsi
jne label_count_next
mov rsi, [rax+88]
cmp [rdx+88], rsi
jne label_count_next
mov rsi, [rax+96]
cmp [rdx+96], rsi
jne label_count_next
mov rsi, [rax+104]
cmp [rdx+104], rsi
jne label_count_next
mov rsi, [rax+112]
cmp [rdx+112], rsi
jne label_count_next
mov rsi, [rax+120]
cmp [rdx+120], rsi
jne label_count_next
mov rsi, [rax+128]
cmp [rdx+128], rsi
jne label_count_next
mov rsi, [rax+136]
cmp [rdx+136], rsi
jne label_count_next
mov rsi, [rax+144]
cmp [rdx+144], rsi
jne label_count_next
mov rsi, [rax+152]
cmp [rdx+152], rsi
jne label_count_next
mov rsi, [rax+160]
cmp [rdx+160], rsi
jne label_count_next
mov rsi, [rax+168]
cmp [rdx+168], rsi
jne label_count_next
mov rsi, [rax+176]
cmp [rdx+176], rsi
jne label_count_next
mov rsi, [rax+184]
cmp [rdx+184], rsi
jne label_count_next
mov rsi, [rax+192]
cmp [rdx+192], rsi
jne label_count_next
mov rsi, [rax+200]
cmp [rdx+200], rsi
jne label_count_next
mov rsi, [rax+208]
cmp [rdx+208], rsi
jne label_count_next
mov rsi, [rax+216]
cmp [rdx+216], rsi
jne label_count_next
mov rsi, [rax+224]
cmp [rdx+224], rsi
jne label_count_next
mov rsi, [rax+232]
cmp [rdx+232], rsi
jne label_count_next
mov rsi, [rax+240]
cmp [rdx+240], rsi
jne label_count_next
mov rsi, [rax+248]
cmp [rdx+248], rsi
jne label_count_next
add ebx, 1
label_count_next:
add rdx, 264
add cx, -1
jnz label_count_loop
label_count_return:
mov rax, rbx
ret


; in
; rax identifier address
; out
; rax label address
label_seek:
mov bx, label_list_size
test bx, bx
jz label_seek_failure
lea rcx, label_list
label_seek_loop:
mov rdx, [rax]
cmp [rcx], rdx
jne label_seek_next
mov rdx, [rax+8]
cmp [rcx+8], rdx
jne label_seek_next
mov rdx, [rax+16]
cmp [rcx+16], rdx
jne label_seek_next
mov rdx, [rax+24]
cmp [rcx+24], rdx
jne label_seek_next
mov rdx, [rax+32]
cmp [rcx+32], rdx
jne label_seek_next
mov rdx, [rax+40]
cmp [rcx+40], rdx
jne label_seek_next
mov rdx, [rax+48]
cmp [rcx+48], rdx
jne label_seek_next
mov rdx, [rax+56]
cmp [rcx+56], rdx
jne label_seek_next
mov rdx, [rax+64]
cmp [rcx+64], rdx
jne label_seek_next
mov rdx, [rax+72]
cmp [rcx+72], rdx
jne label_seek_next
mov rdx, [rax+80]
cmp [rcx+80], rdx
jne label_seek_next
mov rdx, [rax+88]
cmp [rcx+88], rdx
jne label_seek_next
mov rdx, [rax+96]
cmp [rcx+96], rdx
jne label_seek_next
mov rdx, [rax+104]
cmp [rcx+104], rdx
jne label_seek_next
mov rdx, [rax+112]
cmp [rcx+112], rdx
jne label_seek_next
mov rdx, [rax+120]
cmp [rcx+120], rdx
jne label_seek_next
mov rdx, [rax+128]
cmp [rcx+128], rdx
jne label_seek_next
mov rdx, [rax+136]
cmp [rcx+136], rdx
jne label_seek_next
mov rdx, [rax+144]
cmp [rcx+144], rdx
jne label_seek_next
mov rdx, [rax+152]
cmp [rcx+152], rdx
jne label_seek_next
mov rdx, [rax+160]
cmp [rcx+160], rdx
jne label_seek_next
mov rdx, [rax+168]
cmp [rcx+168], rdx
jne label_seek_next
mov rdx, [rax+176]
cmp [rcx+176], rdx
jne label_seek_next
mov rdx, [rax+184]
cmp [rcx+184], rdx
jne label_seek_next
mov rdx, [rax+192]
cmp [rcx+192], rdx
jne label_seek_next
mov rdx, [rax+200]
cmp [rcx+200], rdx
jne label_seek_next
mov rdx, [rax+208]
cmp [rcx+208], rdx
jne label_seek_next
mov rdx, [rax+216]
cmp [rcx+216], rdx
jne label_seek_next
mov rdx, [rax+224]
cmp [rcx+224], rdx
jne label_seek_next
mov rdx, [rax+232]
cmp [rcx+232], rdx
jne label_seek_next
mov rdx, [rax+240]
cmp [rax+240], rdx
jne label_seek_next
mov rdx, [rax+248]
cmp [rax+248], rdx
jne label_seek_next
mov rax, rcx
ret
label_seek_next:
add rcx, 264
add bx, -1
jnz label_seek_loop
label_seek_failure:
xor eax, eax
ret


.data

align 2
label_list_size word 0

align 8
label_list byte 4325376 dup(0) ; 16384 labels