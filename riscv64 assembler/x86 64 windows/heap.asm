.code


; in
; rax size
; out
; rax address
heap_allocate:
mov rbx, heap_size
mov rcx, 1073741824
sub rcx, rbx
cmp rcx, rax
jb heap_allocate_failure
add rax, rbx
mov heap_size, rax
mov rax, heap_address
add rax, rbx
ret
heap_allocate_failure:
xor eax, eax
ret


.data

align 8
heap_size qword 0
heap_address qword 0