; include byte layout
; 0 path
; 512 address
; 520 size
; 528

.code


; out
; rax include address
include_allocate:
xor eax, eax
movzx rbx, include_list_size
cmp bx, 256
je include_allocate_return
mov eax, 528
mul rbx
lea rcx, include_list
add rax, rcx
add bx, 1
mov include_list_size, bx
include_allocate_return:
ret


; in
; rax path address
; out
; rax include address
include_seek:
mov bx, include_list_size
test bx, bx
jz include_seek_failure
lea rcx, include_list
include_seek_loop:
mov rdx, [rax]
cmp [rcx], rdx
jne include_seek_next
mov rdx, [rax+8]
cmp [rcx+8], rdx
jne include_seek_next
mov rdx, [rax+16]
cmp [rcx+16], rdx
jne include_seek_next
mov rdx, [rax+24]
cmp [rcx+24], rdx
jne include_seek_next
mov rdx, [rax+32]
cmp [rcx+32], rdx
jne include_seek_next
mov rdx, [rax+40]
cmp [rcx+40], rdx
jne include_seek_next
mov rdx, [rax+48]
cmp [rcx+48], rdx
jne include_seek_next
mov rdx, [rax+56]
cmp [rcx+56], rdx
jne include_seek_next
mov rdx, [rax+64]
cmp [rcx+64], rdx
jne include_seek_next
mov rdx, [rax+72]
cmp [rcx+72], rdx
jne include_seek_next
mov rdx, [rax+80]
cmp [rcx+80], rdx
jne include_seek_next
mov rdx, [rax+88]
cmp [rcx+88], rdx
jne include_seek_next
mov rdx, [rax+96]
cmp [rcx+96], rdx
jne include_seek_next
mov rdx, [rax+104]
cmp [rcx+104], rdx
jne include_seek_next
mov rdx, [rax+112]
cmp [rcx+112], rdx
jne include_seek_next
mov rdx, [rax+120]
cmp [rcx+120], rdx
jne include_seek_next
mov rdx, [rax+128]
cmp [rcx+128], rdx
jne include_seek_next
mov rdx, [rax+136]
cmp [rcx+136], rdx
jne include_seek_next
mov rdx, [rax+144]
cmp [rcx+144], rdx
jne include_seek_next
mov rdx, [rax+152]
cmp [rcx+152], rdx
jne include_seek_next
mov rdx, [rax+160]
cmp [rcx+160], rdx
jne include_seek_next
mov rdx, [rax+168]
cmp [rcx+168], rdx
jne include_seek_next
mov rdx, [rax+176]
cmp [rcx+176], rdx
jne include_seek_next
mov rdx, [rax+184]
cmp [rcx+184], rdx
jne include_seek_next
mov rdx, [rax+192]
cmp [rcx+192], rdx
jne include_seek_next
mov rdx, [rax+200]
cmp [rcx+200], rdx
jne include_seek_next
mov rdx, [rax+208]
cmp [rcx+208], rdx
jne include_seek_next
mov rdx, [rax+216]
cmp [rcx+216], rdx
jne include_seek_next
mov rdx, [rax+224]
cmp [rcx+224], rdx
jne include_seek_next
mov rdx, [rax+232]
cmp [rcx+232], rdx
jne include_seek_next
mov rdx, [rax+240]
cmp [rcx+240], rdx
jne include_seek_next
mov rdx, [rax+248]
cmp [rcx+248], rdx
jne include_seek_next
mov rdx, [rax+256]
cmp [rcx+256], rdx
jne include_seek_next
mov rdx, [rax+264]
cmp [rcx+264], rdx
jne include_seek_next
mov rdx, [rax+272]
cmp [rcx+272], rdx
jne include_seek_next
mov rdx, [rax+280]
cmp [rcx+280], rdx
jne include_seek_next
mov rdx, [rax+288]
cmp [rcx+288], rdx
jne include_seek_next
mov rdx, [rax+296]
cmp [rcx+296], rdx
jne include_seek_next
mov rdx, [rax+304]
cmp [rcx+304], rdx
jne include_seek_next
mov rdx, [rax+312]
cmp [rcx+312], rdx
jne include_seek_next
mov rdx, [rax+320]
cmp [rcx+320], rdx
jne include_seek_next
mov rdx, [rax+328]
cmp [rcx+328], rdx
jne include_seek_next
mov rdx, [rax+336]
cmp [rcx+336], rdx
jne include_seek_next
mov rdx, [rax+344]
cmp [rcx+344], rdx
jne include_seek_next
mov rdx, [rax+352]
cmp [rcx+352], rdx
jne include_seek_next
mov rdx, [rax+360]
cmp [rcx+360], rdx
jne include_seek_next
mov rdx, [rax+368]
cmp [rcx+368], rdx
jne include_seek_next
mov rdx, [rax+376]
cmp [rcx+376], rdx
jne include_seek_next
mov rdx, [rax+384]
cmp [rcx+384], rdx
jne include_seek_next
mov rdx, [rax+392]
cmp [rcx+392], rdx
jne include_seek_next
mov rdx, [rax+400]
cmp [rcx+400], rdx
jne include_seek_next
mov rdx, [rax+408]
cmp [rcx+408], rdx
jne include_seek_next
mov rdx, [rax+416]
cmp [rcx+416], rdx
jne include_seek_next
mov rdx, [rax+424]
cmp [rcx+424], rdx
jne include_seek_next
mov rdx, [rax+432]
cmp [rcx+432], rdx
jne include_seek_next
mov rdx, [rax+440]
cmp [rcx+440], rdx
jne include_seek_next
mov rdx, [rax+448]
cmp [rcx+448], rdx
jne include_seek_next
mov rdx, [rax+456]
cmp [rcx+456], rdx
jne include_seek_next
mov rdx, [rax+464]
cmp [rcx+464], rdx
jne include_seek_next
mov rdx, [rax+472]
cmp [rcx+472], rdx
jne include_seek_next
mov rdx, [rax+480]
cmp [rcx+480], rdx
jne include_seek_next
mov rdx, [rax+488]
cmp [rcx+488], rdx
jne include_seek_next
mov rdx, [rax+496]
cmp [rcx+496], rdx
jne include_seek_next
mov rdx, [rax+504]
cmp [rcx+504], rdx
jne include_seek_next
mov rax, rcx
ret
include_seek_next:
add rcx, 528
add bx, -1
jnz include_seek_loop
include_seek_failure:
xor eax, eax
ret


.data

align 2
include_list_size word 0

align 8
include_list byte 135168 dup(0) ; 256 includes