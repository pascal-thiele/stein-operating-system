.section .text


# in
# rax size
# out
# rax address
heap_allocate:
movq heap_size, %rbx
movq $1073741824, %rcx
subq %rbx, %rcx
cmpq %rax, %rcx
jb heap_allocate_failure
addq %rbx, %rax
movq %rax, heap_size
movq heap_address, %rax
addq %rbx, %rax
ret
heap_allocate_failure:
xorl %eax, %eax
ret


.section .data


.align 8
heap_size:
.quad 0
heap_address:
.quad 0
