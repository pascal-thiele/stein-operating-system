# include byte layout
# 0 path
# 512 address
# 520 size
# 528

.section .text


# out
# rax include address
include_allocate:
xorl %eax, %eax
movzwq include_list_size, %rbx
cmpw $256, %bx
je include_allocate_return
movl $528, %eax
mulq %rbx
leaq include_list, %rcx
addq %rcx, %rax
addw $1, %bx
movw %bx, include_list_size
include_allocate_return:
ret


# in
# rax path address
# out
# rax include address
include_seek:
movw include_list_size, %bx
testw %bx, %bx
jz include_seek_failure
leaq include_list, %rcx
include_seek_loop:
movq (%rax), %rdx
cmpq %rdx, (%rcx)
jne include_seek_next
movq 8(%rax), %rdx
cmpq %rdx, 8(%rcx)
jne include_seek_next
movq 16(%rax), %rdx
cmpq %rdx, 16(%rcx)
jne include_seek_next
movq 24(%rax), %rdx
cmpq %rdx, 24(%rcx)
jne include_seek_next
movq 32(%rax), %rdx
cmpq %rdx, 32(%rcx)
jne include_seek_next
movq 40(%rax), %rdx
cmpq %rdx, 40(%rcx)
jne include_seek_next
movq 48(%rax), %rdx
cmpq %rdx, 48(%rcx)
jne include_seek_next
movq 56(%rax), %rdx
cmpq %rdx, 56(%rcx)
jne include_seek_next
movq 64(%rax), %rdx
cmpq %rdx, 64(%rcx)
jne include_seek_next
movq 72(%rax), %rdx
cmpq %rdx, 72(%rcx)
jne include_seek_next
movq 80(%rax), %rdx
cmpq %rdx, 80(%rcx)
jne include_seek_next
movq 88(%rax), %rdx
cmpq %rdx, 88(%rcx)
jne include_seek_next
movq 96(%rax), %rdx
cmpq %rdx, 96(%rcx)
jne include_seek_next
movq 104(%rax), %rdx
cmpq %rdx, 104(%rcx)
jne include_seek_next
movq 112(%rax), %rdx
cmpq %rdx, 112(%rcx)
jne include_seek_next
movq 120(%rax), %rdx
cmpq %rdx, 120(%rcx)
jne include_seek_next
movq 128(%rax), %rdx
cmpq %rdx, 128(%rcx)
jne include_seek_next
movq 136(%rax), %rdx
cmpq %rdx, 136(%rcx)
jne include_seek_next
movq 144(%rax), %rdx
cmpq %rdx, 144(%rcx)
jne include_seek_next
movq 152(%rax), %rdx
cmpq %rdx, 152(%rcx)
jne include_seek_next
movq 160(%rax), %rdx
cmpq %rdx, 160(%rcx)
jne include_seek_next
movq 168(%rax), %rdx
cmpq %rdx, 168(%rcx)
jne include_seek_next
movq 176(%rax), %rdx
cmpq %rdx, 176(%rcx)
jne include_seek_next
movq 184(%rax), %rdx
cmpq %rdx, 184(%rcx)
jne include_seek_next
movq 192(%rax), %rdx
cmpq %rdx, 192(%rcx)
jne include_seek_next
movq 200(%rax), %rdx
cmpq %rdx, 200(%rcx)
jne include_seek_next
movq 208(%rax), %rdx
cmpq %rdx, 208(%rcx)
jne include_seek_next
movq 216(%rax), %rdx
cmpq %rdx, 216(%rcx)
jne include_seek_next
movq 224(%rax), %rdx
cmpq %rdx, 224(%rcx)
jne include_seek_next
movq 232(%rax), %rdx
cmpq %rdx, 232(%rcx)
jne include_seek_next
movq 240(%rax), %rdx
cmpq %rdx, 240(%rcx)
jne include_seek_next
movq 248(%rax), %rdx
cmpq %rdx, 248(%rcx)
jne include_seek_next
movq 256(%rax), %rdx
cmpq %rdx, 256(%rcx)
jne include_seek_next
movq 264(%rax), %rdx
cmpq %rdx, 264(%rcx)
jne include_seek_next
movq 272(%rax), %rdx
cmpq %rdx, 272(%rcx)
jne include_seek_next
movq 280(%rax), %rdx
cmpq %rdx, 280(%rcx)
jne include_seek_next
movq 288(%rax), %rdx
cmpq %rdx, 288(%rcx)
jne include_seek_next
movq 296(%rax), %rdx
cmpq %rdx, 296(%rcx)
jne include_seek_next
movq 304(%rax), %rdx
cmpq %rdx, 304(%rcx)
jne include_seek_next
movq 312(%rax), %rdx
cmpq %rdx, 312(%rcx)
jne include_seek_next
movq 320(%rax), %rdx
cmpq %rdx, 320(%rcx)
jne include_seek_next
movq 328(%rax), %rdx
cmpq %rdx, 328(%rcx)
jne include_seek_next
movq 336(%rax), %rdx
cmpq %rdx, 336(%rcx)
jne include_seek_next
movq 344(%rax), %rdx
cmpq %rdx, 344(%rcx)
jne include_seek_next
movq 352(%rax), %rdx
cmpq %rdx, 352(%rcx)
jne include_seek_next
movq 360(%rax), %rdx
cmpq %rdx, 360(%rcx)
jne include_seek_next
movq 368(%rax), %rdx
cmpq %rdx, 368(%rcx)
jne include_seek_next
movq 376(%rax), %rdx
cmpq %rdx, 376(%rcx)
jne include_seek_next
movq 384(%rax), %rdx
cmpq %rdx, 384(%rcx)
jne include_seek_next
movq 392(%rax), %rdx
cmpq %rdx, 392(%rcx)
jne include_seek_next
movq 400(%rax), %rdx
cmpq %rdx, 400(%rcx)
jne include_seek_next
movq 408(%rax), %rdx
cmpq %rdx, 408(%rcx)
jne include_seek_next
movq 416(%rax), %rdx
cmpq %rdx, 416(%rcx)
jne include_seek_next
movq 424(%rax), %rdx
cmpq %rdx, 424(%rcx)
jne include_seek_next
movq 432(%rax), %rdx
cmpq %rdx, 432(%rcx)
jne include_seek_next
movq 440(%rax), %rdx
cmpq %rdx, 440(%rcx)
jne include_seek_next
movq 448(%rax), %rdx
cmpq %rdx, 448(%rcx)
jne include_seek_next
movq 456(%rax), %rdx
cmpq %rdx, 456(%rcx)
jne include_seek_next
movq 464(%rax), %rdx
cmpq %rdx, 464(%rcx)
jne include_seek_next
movq 472(%rax), %rdx
cmpq %rdx, 472(%rcx)
jne include_seek_next
movq 480(%rax), %rdx
cmpq %rdx, 480(%rcx)
jne include_seek_next
movq 488(%rax), %rdx
cmpq %rdx, 488(%rcx)
jne include_seek_next
movq 496(%rax), %rdx
cmpq %rdx, 496(%rcx)
jne include_seek_next
movq 504(%rax), %rdx
cmpq %rdx, 504(%rcx)
jne include_seek_next
movq %rcx, %rax
ret
include_seek_next:
addq $528, %rcx
addw $-1, %bx
jnz include_seek_loop
include_seek_failure:
xorl %eax, %eax
ret


.section .data

.align 2
include_list_size:
.word 0

.align 8
include_list:
.zero 135168 # 256 includes
