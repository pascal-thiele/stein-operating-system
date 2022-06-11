# constant byte layout
# 0 identifier
# 256 value
# 264

.section .text


# out
# rax address
constant_allocate:
xorl %eax, %eax
movzwq constant_list_size, %rbx
cmpw $256, %bx
je constant_allocate_return
movl $264, %eax
mulq %rbx
leaq constant_list, %rcx
addq %rcx, %rax
addw $1, %bx
movw %bx, constant_list_size
constant_allocate_return:
ret


# in
# rax identifier address
# out
# rax amount of constants with matching identifier
constant_count:
xorl %ebx, %ebx
movw constant_list_size, %cx
testw %cx, %cx
jz constant_count_return
leaq constant_list, %rdx
constant_count_loop:
movq (%rax), %rsi
cmpq %rsi, (%rdx)
jne constant_count_next
movq 8(%rax), %rsi
cmpq %rsi, 8(%rdx)
jne constant_count_next
movq 16(%rax), %rsi
cmpq %rsi, 16(%rdx)
jne constant_count_next
movq 24(%rax), %rsi
cmpq %rsi, 24(%rdx)
jne constant_count_next
movq 32(%rax), %rsi
cmpq %rsi, 32(%rdx)
jne constant_count_next
movq 40(%rax), %rsi
cmpq %rsi, 40(%rdx)
jne constant_count_next
movq 48(%rax), %rsi
cmpq %rsi, 48(%rdx)
jne constant_count_next
movq 56(%rax), %rsi
cmpq %rsi, 56(%rdx)
jne constant_count_next
movq 64(%rax), %rsi
cmpq %rsi, 64(%rdx)
jne constant_count_next
movq 72(%rax), %rsi
cmpq %rsi, 72(%rdx)
jne constant_count_next
movq 80(%rax), %rsi
cmpq %rsi, 80(%rdx)
jne constant_count_next
movq 88(%rax), %rsi
cmpq %rsi, 88(%rdx)
jne constant_count_next
movq 96(%rax), %rsi
cmpq %rsi, 96(%rdx)
jne constant_count_next
movq 104(%rax), %rsi
cmpq %rsi, 104(%rdx)
jne constant_count_next
movq 112(%rax), %rsi
cmpq %rsi, 112(%rdx)
jne constant_count_next
movq 120(%rax), %rsi
cmpq %rsi, 120(%rdx)
jne constant_count_next
movq 128(%rax), %rsi
cmpq %rsi, 128(%rdx)
jne constant_count_next
movq 136(%rax), %rsi
cmpq %rsi, 136(%rdx)
jne constant_count_next
movq 144(%rax), %rsi
cmpq %rsi, 144(%rdx)
jne constant_count_next
movq 152(%rax), %rsi
cmpq %rsi, 152(%rdx)
jne constant_count_next
movq 160(%rax), %rsi
cmpq %rsi, 160(%rdx)
jne constant_count_next
movq 168(%rax), %rsi
cmpq %rsi, 168(%rdx)
jne constant_count_next
movq 176(%rax), %rsi
cmpq %rsi, 176(%rdx)
jne constant_count_next
movq 184(%rax), %rsi
cmpq %rsi, 184(%rdx)
jne constant_count_next
movq 192(%rax), %rsi
cmpq %rsi, 192(%rdx)
jne constant_count_next
movq 200(%rax), %rsi
cmpq %rsi, 200(%rdx)
jne constant_count_next
movq 208(%rax), %rsi
cmpq %rsi, 208(%rdx)
jne constant_count_next
movq 216(%rax), %rsi
cmpq %rsi, 216(%rdx)
jne constant_count_next
movq 224(%rax), %rsi
cmpq %rsi, 224(%rdx)
jne constant_count_next
movq 232(%rax), %rsi
cmpq %rsi, 232(%rdx)
jne constant_count_next
movq 240(%rax), %rsi
cmpq %rsi, 240(%rdx)
jne constant_count_next
movq 248(%rax), %rsi
cmpq %rsi, 248(%rdx)
jne constant_count_next
addl $1, %ebx
constant_count_next:
addq $264, %rdx
addw $-1, %cx
jnz constant_count_loop
constant_count_return:
movq %rbx, %rax
ret


# in
# rax identifier address
# out
# rax constant address
constant_seek:
movw constant_list_size, %bx
testw %bx, %bx
jz constant_seek_failure
leaq constant_list, %rcx
constant_seek_loop:
movq (%rax), %rdx
cmpq %rdx, (%rcx)
jne constant_seek_next
movq 8(%rax), %rdx
cmpq %rdx, 8(%rcx)
jne constant_seek_next
movq 16(%rax), %rdx
cmpq %rdx, 16(%rcx)
jne constant_seek_next
movq 24(%rax), %rdx
cmpq %rdx, 24(%rcx)
jne constant_seek_next
movq 32(%rax), %rdx
cmpq %rdx, 32(%rcx)
jne constant_seek_next
movq 40(%rax), %rdx
cmpq %rdx, 40(%rcx)
jne constant_seek_next
movq 48(%rax), %rdx
cmpq %rdx, 48(%rcx)
jne constant_seek_next
movq 56(%rax), %rdx
cmpq %rdx, 56(%rcx)
jne constant_seek_next
movq 64(%rax), %rdx
cmpq %rdx, 64(%rcx)
jne constant_seek_next
movq 72(%rax), %rdx
cmpq %rdx, 72(%rcx)
jne constant_seek_next
movq 80(%rax), %rdx
cmpq %rdx, 80(%rcx)
jne constant_seek_next
movq 88(%rax), %rdx
cmpq %rdx, 88(%rcx)
jne constant_seek_next
movq 96(%rax), %rdx
cmpq %rdx, 96(%rcx)
jne constant_seek_next
movq 104(%rax), %rdx
cmpq %rdx, 104(%rcx)
jne constant_seek_next
movq 112(%rax), %rdx
cmpq %rdx, 112(%rcx)
jne constant_seek_next
movq 120(%rax), %rdx
cmpq %rdx, 120(%rcx)
jne constant_seek_next
movq 128(%rax), %rdx
cmpq %rdx, 128(%rcx)
jne constant_seek_next
movq 136(%rax), %rdx
cmpq %rdx, 136(%rcx)
jne constant_seek_next
movq 144(%rax), %rdx
cmpq %rdx, 144(%rcx)
jne constant_seek_next
movq 152(%rax), %rdx
cmpq %rdx, 152(%rcx)
jne constant_seek_next
movq 160(%rax), %rdx
cmpq %rdx, 160(%rcx)
jne constant_seek_next
movq 168(%rax), %rdx
cmpq %rdx, 168(%rcx)
jne constant_seek_next
movq 176(%rax), %rdx
cmpq %rdx, 176(%rcx)
jne constant_seek_next
movq 184(%rax), %rdx
cmpq %rdx, 184(%rcx)
jne constant_seek_next
movq 192(%rax), %rdx
cmpq %rdx, 192(%rcx)
jne constant_seek_next
movq 200(%rax), %rdx
cmpq %rdx, 200(%rcx)
jne constant_seek_next
movq 208(%rax), %rdx
cmpq %rdx, 208(%rcx)
jne constant_seek_next
movq 216(%rax), %rdx
cmpq %rdx, 216(%rcx)
jne constant_seek_next
movq 224(%rax), %rdx
cmpq %rdx, 224(%rcx)
jne constant_seek_next
movq 232(%rax), %rdx
cmpq %rdx, 232(%rcx)
jne constant_seek_next
movq 240(%rax), %rdx
cmpq %rdx, 240(%rcx)
jne constant_seek_next
movq 248(%rax), %rdx
cmpq %rdx, 248(%rcx)
jne constant_seek_next
movq %rcx, %rax
ret
constant_seek_next:
addq $264, %rcx
addw $-1, %bx
jnz constant_seek_loop
constant_seek_failure:
xorl %eax, %eax
ret


.section .data

.align 2
constant_list_size:
.word 0

.align 8
constant_list:
.zero 67584 # 256 constants
