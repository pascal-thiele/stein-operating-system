.section .text


terminal_out:
addq $-48, %rsp
movq %r10, (%rsp)
movq %r11, 8(%rsp)
movq %r12, 16(%rsp)
movq %r13, 24(%rsp)
movq %r14, 32(%rsp)
movq %r15, 40(%rsp)
movl $1, %eax
movl $1, %edi
leaq terminal_buffer, %rsi
movzwq terminal_buffer_size, %rdx
syscall
movw $0, terminal_buffer_size
movq (%rsp), %r10
movq 8(%rsp), %r11
movq 16(%rsp), %r12
movq 24(%rsp), %r13
movq 32(%rsp), %r14
movq 40(%rsp), %r15
addq $48, %rsp
ret


# in
# al character to append
terminal_append_character:
leaq terminal_buffer, %rbx
movzwq terminal_buffer_size, %rcx
addq %rcx, %rbx
movb %al, (%rbx)
# increment size
addw $1, %cx
movw %cx, terminal_buffer_size
ret


# in
# rax string address
# bx string size
terminal_append_string:
leaq terminal_buffer, %rcx
movzwq terminal_buffer_size, %rdx
addq %rdx, %rcx
addw %bx, %dx
movw %dx, terminal_buffer_size
terminal_append_string_loop:
movb (%rax), %sil
movb %sil, (%rcx)
addq $1, %rax
addq $1, %rcx
addw $-1, %bx
jnz terminal_append_string_loop
ret


# in
# rax signed integer
terminal_append_integer:
leaq terminal_buffer, %rbx
movzwq terminal_buffer_size, %rcx
addq %rcx, %rbx

# check for negative
testq %rax, %rax
jns terminal_append_integer_negative_end
negq %rax
movb $45, (%rbx)
addq $1, %rbx
addq $1, %rcx
terminal_append_integer_negative_end:

# extract digits
xorl %esi, %esi # digit count
movl $10, %edi
terminal_append_integer_extract_digit:
xorl %edx, %edx
divq %rdi
addq $48, %rdx
pushq %rdx
addq $1, %rsi
test %rax, %rax
jnz terminal_append_integer_extract_digit

# increment the buffer size
addq %rsi, %rcx
movw %cx, terminal_buffer_size
terminal_append_integer_digit:
popq %rax
movb %al, (%rbx)
addq $1, %rbx
addq $-1, %rsi
test %rsi, %rsi
jnz terminal_append_integer_digit
ret


.section .data

.align 2
terminal_buffer_size:
.word 0

.align 8
terminal_buffer:
.zero 1024
