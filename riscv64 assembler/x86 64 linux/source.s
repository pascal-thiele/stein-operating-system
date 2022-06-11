# source byte layout
# 0 path
# 512 address
# 520 size
# 528

.section .text


# out
# rax source address
source_allocate:
xorl %eax, %eax
movzwq source_list_size, %rbx
cmpw $256, %bx
je source_allocate_return
movl $528, %eax
mulq %rbx
leaq source_list, %rcx
addq %rcx, %rax
addw $1, %bx
movw %bx, source_list_size
source_allocate_return:
ret


source_iterator:
leaq source_list, %rax
movq %rax, source_address
movw source_list_size, %bx
movw %bx, source_count
movq 512(%rax), %rcx
movq 520(%rax), %rdx
movq %rcx, source_character_address
movq %rdx, source_character_count
movq $1, source_line_index
ret


# out
# al status
source_iterator_increment:
addw $-1, source_count
jz source_iterator_increment_failure
movq source_address, %rax
addq $528, %rax
movq %rax, source_address
movq 512(%rax), %rbx
movq 520(%rax), %rcx
movq %rbx, source_character_address
movq %rcx, source_character_count
movq $1, source_line_index
xorb %al, %al
ret
source_iterator_increment_failure:
movb $1, %al
ret


source_to_terminal:
movq source_address, %rax
xorw %bx, %bx
movq %rax, %rcx
source_to_terminal_compare_path:
cmpb $0, (%rcx)
je source_to_terminal_append_path
addq $1, %rcx
addw $1, %bx
cmpw $512, %bx
jne source_to_terminal_compare_path
source_to_terminal_append_path:
call terminal_append_string
movb $58, %al
call terminal_append_character
movb $32, %al
call terminal_append_character
movq source_line_index, %rax
call terminal_append_integer
movb $58, %al
call terminal_append_character
movb $32, %al
call terminal_append_character
ret


# out
# al status
source_jump_line:
movq source_character_address, %rax
movq source_character_count, %rbx
source_jump_line_loop:
addq $-1, %rbx
jz source_jump_line_failure
movb (%rax), %cl
addq $1, %rax
cmpb $10, %cl
jne source_jump_line_loop

movq %rax, source_character_address
movq %rbx, source_character_count
addq $1, source_line_index
xorb %al, %al
ret

source_jump_line_failure:
mov $1, %al
ret


# A token is terminated by space, new line or a hastag.

# out
# rax token address
# rbx token size
source_token:
movq source_character_address, %rax
xorl %ebx, %ebx
movq %rax, %rcx
movq source_character_count, %rdx
source_token_loop:
cmpb $10, (%rcx)
je source_token_return
cmpb $32, (%rcx)
je source_token_return
cmpb $35, (%rcx)
je source_token_return
addq $1, %rbx
addq $1, %rcx
addq $-1, %rdx
jnz source_token_loop
source_token_return:
ret


# out
# al status
source_seek_token:
movq source_character_address, %rax
movq source_character_count, %rbx
source_seek_token_loop:
cmpb $32, (%rax)
jne source_seek_token_end
addq $1, %rax
addq $-1, %rbx
jnz source_seek_token_loop
movb $1, %al
ret

source_seek_token_end:
cmpb $10, (%rax)
je source_seek_token_failure
cmpb $35, (%rax)
je source_seek_token_failure
movq %rax, source_character_address
movq %rbx, source_character_count
xorb %al, %al
ret

source_seek_token_failure:
movb $1, %al
ret


# out
# al status
source_jump_token:
movq source_character_address, %rax
movq source_character_count, %rbx
source_jump_token_loop:
cmpb $10, (%rax)
je source_jump_token_end
cmpb $32, (%rax)
je source_jump_token_end
cmpb $35, (%rax)
je source_jump_token_end
addq $1, %rax
addq $-1, %rbx
jnz source_jump_token_loop
movb $1, %al
ret

source_jump_token_end:
movq %rax, source_character_address
movq %rbx, source_character_count
xorb %al, %al
ret


# in
# rax extended token address
# out
# al status
source_extend_token:
movq $0, (%rax)
movq $0, 8(%rax)
movq $0, 16(%rax)
movq $0, 24(%rax)
movq $0, 32(%rax)
movq $0, 40(%rax)
movq $0, 48(%rax)
movq $0, 56(%rax)
movq $0, 64(%rax)
movq $0, 72(%rax)
movq $0, 80(%rax)
movq $0, 88(%rax)
movq $0, 96(%rax)
movq $0, 104(%rax)
movq $0, 112(%rax)
movq $0, 120(%rax)
movq $0, 128(%rax)
movq $0, 136(%rax)
movq $0, 144(%rax)
movq $0, 152(%rax)
movq $0, 160(%rax)
movq $0, 168(%rax)
movq $0, 176(%rax)
movq $0, 184(%rax)
movq $0, 192(%rax)
movq $0, 200(%rax)
movq $0, 208(%rax)
movq $0, 216(%rax)
movq $0, 224(%rax)
movq $0, 232(%rax)
movq $0, 240(%rax)
movq $0, 248(%rax)
movq source_character_address, %rbx
movq source_character_count, %rcx
movw $256, %dx
source_extend_token_loop:
movb (%rbx), %sil
cmpb $10, %sil
je source_extend_token_end
cmpb $32, %sil
je source_extend_token_end
cmpb $35, %sil
je source_extend_token_end
movb %sil, (%rax)
addq $-1, %rcx
jz source_extend_token_end
addq $1, %rax
addq $1, %rbx
addw $-1, %dx
jnz source_extend_token_loop
movb $1, %al
ret
source_extend_token_end:
xorb %al, %al
ret


# The first and last character of a quote are quotation marks and the entire quote is terminated by space, a new line or a hashtag.

# out
# rax quote address
# rbx quote size
source_quote:
movq source_character_address, %rax
cmpb $34, (%rax)
jne source_quote_failure
movl $1, %ebx
movq %rax, %rcx
movq source_character_count, %rdx
source_quote_loop:
addq $-1, %rdx
jz source_quote_failure
addq $1, %rcx
cmpb $10, (%rcx)
je source_quote_failure
cmpb $35, (%rcx)
je source_quote_failure
addq $1, %rbx
cmpb $34, (%rcx)
jne source_quote_loop

addq $-1, %rdx
jz source_quote_return
cmpb $10, 1(%rcx)
je source_quote_return
cmpb $32, 1(%rcx)
je source_quote_return
cmpb $35, 1(%rcx)
je source_quote_return
source_quote_failure:
xorl %eax, %eax
xorl %ebx, %ebx
source_quote_return:
ret


# out
# al status
source_jump_quote:
movq source_character_address, %rax
cmpb $34, (%rax)
jne source_jump_quote_failure
movq source_character_count, %rbx
source_jump_quote_loop:
addq $-1, %rbx
jz source_jump_quote_failure
addq $1, %rax
cmpb $10, (%rax)
je source_jump_quote_failure
cmpb $35, (%rax)
je source_jump_quote_failure
cmpb $34, (%rax)
jne source_jump_quote_loop

addq $-1, %rbx
jz source_jump_quote_failure
addq $1, %rax
cmpb $10, (%rax)
je source_jump_quote_success
cmpb $32, (%rax)
je source_jump_quote_success
cmpb $35, (%rax)
je source_jump_quote_success
source_jump_quote_failure:
movb $1, %al
ret

source_jump_quote_success:
movq %rax, source_character_address
movq %rbx, source_character_count
xorb %al, %al
ret


# in
# rax extended quote address
# out
# al status
source_extend_quote:
movq $0, (%rax)
movq $0, 8(%rax)
movq $0, 16(%rax)
movq $0, 24(%rax)
movq $0, 32(%rax)
movq $0, 40(%rax)
movq $0, 48(%rax)
movq $0, 56(%rax)
movq $0, 64(%rax)
movq $0, 72(%rax)
movq $0, 80(%rax)
movq $0, 88(%rax)
movq $0, 96(%rax)
movq $0, 104(%rax)
movq $0, 112(%rax)
movq $0, 120(%rax)
movq $0, 128(%rax)
movq $0, 136(%rax)
movq $0, 144(%rax)
movq $0, 152(%rax)
movq $0, 160(%rax)
movq $0, 168(%rax)
movq $0, 176(%rax)
movq $0, 184(%rax)
movq $0, 192(%rax)
movq $0, 200(%rax)
movq $0, 208(%rax)
movq $0, 216(%rax)
movq $0, 224(%rax)
movq $0, 232(%rax)
movq $0, 240(%rax)
movq $0, 248(%rax)
movq $0, 256(%rax)
movq $0, 264(%rax)
movq $0, 272(%rax)
movq $0, 280(%rax)
movq $0, 288(%rax)
movq $0, 296(%rax)
movq $0, 304(%rax)
movq $0, 312(%rax)
movq $0, 320(%rax)
movq $0, 328(%rax)
movq $0, 336(%rax)
movq $0, 344(%rax)
movq $0, 352(%rax)
movq $0, 360(%rax)
movq $0, 368(%rax)
movq $0, 376(%rax)
movq $0, 384(%rax)
movq $0, 392(%rax)
movq $0, 400(%rax)
movq $0, 408(%rax)
movq $0, 416(%rax)
movq $0, 424(%rax)
movq $0, 432(%rax)
movq $0, 440(%rax)
movq $0, 448(%rax)
movq $0, 456(%rax)
movq $0, 464(%rax)
movq $0, 472(%rax)
movq $0, 480(%rax)
movq $0, 488(%rax)
movq $0, 496(%rax)
movq $0, 504(%rax)

movq source_character_address, %rbx
cmpb $34, (%rbx)
jne source_extend_quote_failure
movq source_character_count, %rcx
movw $512, %dx
source_extend_quote_loop:
addq $-1, %rcx
jz source_extend_quote_failure
addq $1, %rbx
movb (%rbx), %sil
cmpb $10, %sil
je source_extend_quote_failure
cmpb $32, %sil
je source_extend_quote_end
cmpb $35, %sil
je source_extend_quote_failure
movb %sil, (%rax)
addq $1, %rax
addw $-1, %dx
jnz source_extend_quote_loop
source_extend_quote_failure:
movb $1, %al
ret

source_extend_quote_end:
addq $-1, %rcx
jz source_extend_quote_success
addq $1, %rbx
cmpb $10, (%rbx)
je source_extend_quote_success
cmpb $32, (%rbx)
je source_extend_quote_success
cmpb $35, (%rbx)
je source_extend_quote_success
movb $1, %al
ret

source_extend_quote_success:
xorb %al, %al
ret


# out
# al status
# rbx integer
source_integer:
movq source_character_address, %rcx
movzbq (%rcx), %rbx
cmpb $45, %bl
je source_integer_negative
cmpb $48, %bl
jb source_integer_failure
cmpb $58, %bl
jae source_integer_failure
addb $-48, %bl
movq source_character_count, %rsi
addq $-1, %rsi
jz source_integer_positive_success
xorl %edx, %edx
movl $10, %edi
source_integer_positive_digit:
addq $1, %rcx
movzbq (%rcx), %r8
cmpb $10, %r8b
je source_integer_positive_success
cmpb $32, %r8b
je source_integer_positive_success
cmpb $35, %r8b
je source_integer_positive_success
cmpb $48, %r8b
jb source_integer_failure
cmpb $58, %r8b
jae source_integer_failure
addb $-48, %r8b
# check for integer overflow
movq $18446744073709551615, %rax
subq %r8, %rax
divq %rdi
cmpq %rbx, %rax
jb source_integer_failure
# add digit
movq %rbx, %rax
mulq %rdi
addq %r8, %rax
movq %rax, %rbx
addq $-1, %rsi
jnz source_integer_positive_digit
source_integer_positive_success:
xorb %al, %al
ret

source_integer_negative:
movq source_character_count, %rsi
addq $-1, %rsi
jz source_integer_failure
addq $1, %rcx
movzbq (%rcx), %rbx
cmpb $48, %bl
jb source_integer_failure
cmpb $58, %bl
jae source_integer_failure
addb $-48, %bl
addq $-1, %rsi
jz source_integer_negative_success
xorl %edx, %edx
movl $10, %edi
source_integer_negative_digit:
addq $1, %rcx
movzbq (%rcx), %r8
cmpb $10, %r8b
je source_integer_negative_success
cmpb $32, %r8b
je source_integer_negative_success
cmpb $35, %r8b
je source_integer_negative_success
cmpb $48, %r8b
jb source_integer_failure
cmpb $58, %r8b
jae source_integer_failure
addb $-48, %r8b
# check for integer overflow
movq $9223372036854775808, %rax
subq %r8, %rax
divq %rdi
cmpq %rbx, %rax
jb source_integer_failure
# add digit
movq %rbx, %rax
mulq %rdi
addq %r8, %rax
movq %rax, %rbx
addq $-1, %rsi
jnz source_integer_negative_digit
source_integer_negative_success:
negq %rbx
xorb %al, %al
ret

source_integer_failure:
movb $1, %al
ret


# out
# al status
# rbx signed integer
source_signed_integer:
movq source_character_address, %rcx
movzbq (%rcx), %rbx
cmpb $45, %bl
je source_signed_integer_negative
cmpb $48, %bl
jb source_signed_integer_failure
cmpb $58, %bl
jae source_signed_integer_failure
addb $-48, %bl
movq source_character_count, %rsi
addq $-1, %rsi
jz source_signed_integer_positive_success
xorl %edx, %edx
movl $10, %edi
source_signed_integer_positive_digit:
addq $1, %rcx
movzbq (%rcx), %r8
cmpb $10, %r8b
je source_signed_integer_positive_success
cmpb $32, %r8b
je source_signed_integer_positive_success
cmpb $35, %r8b
je source_signed_integer_positive_success
cmpb $48, %r8b
jb source_signed_integer_failure
cmpb $58, %r8b
jae source_signed_integer_failure
addb $-48, %r8b
# check for integer overflow
movq $9223372036854775807, %rax
subq %r8, %rax
divq %rdi
cmpq %rbx, %rax
jb source_signed_integer_failure
# add digit
movq %rbx, %rax
mulq %rdi
addq %r8, %rax
movq %rax, %rbx
addq $-1, %rsi
jnz source_signed_integer_positive_digit
source_signed_integer_positive_success:
xorb %al, %al
ret

source_signed_integer_negative:
movq source_character_count, %rsi
addq $-1, %rsi
jz source_signed_integer_failure
addq $1, %rcx
movzbq (%rcx), %rbx
cmpb $48, %bl
jb source_signed_integer_failure
cmpb $58, %bl
jae source_signed_integer_failure
addb $-48, %bl
addq $-1, %rsi
jz source_signed_integer_negative_success
xorl %edx, %edx
movl $10, %edi
source_signed_integer_negative_digit:
addq $1, %rcx
movzbq (%rcx), %r8
cmpb $10, %r8b
je source_signed_integer_negative_success
cmpb $32, %r8b
je source_signed_integer_negative_success
cmpb $35, %r8b
je source_signed_integer_negative_success
cmpb $48, %r8b
jb source_signed_integer_failure
cmpb $58, %r8b
jae source_signed_integer_failure
addb $-48, %r8b
# check for integer overflow
movq $9223372036854775808, %rax
subq %r8, %rax
divq %rdi
cmpq %rbx, %rax
jb source_signed_integer_failure
# add digit
movq %rbx, %rax
mulq %rdi
addq %r8, %rax
movq %rax, %rbx
addq $-1, %rsi
jnz source_signed_integer_negative_digit
source_signed_integer_negative_success:
negq %rbx
xorb %al, %al
ret

source_signed_integer_failure:
movb $1, %al
ret


# out
# al status
# rbx unsigned integer
source_unsigned_integer:
movq source_character_address, %rcx
movzbq (%rcx), %rbx
cmpb $48, %bl
jb source_unsigned_integer_failure
cmpb $58, %bl
jae source_unsigned_integer_failure
addb $-48, %bl
movq source_character_count, %rsi
addq $-1, %rsi
jz source_unsigned_integer_success
xorl %edx, %edx
movl $10, %edi
source_unsigned_integer_digit:
addq $1, %rcx
movzbq (%rcx), %r8
cmpb $10, %r8b
je source_unsigned_integer_success
cmpb $32, %r8b
je source_unsigned_integer_success
cmpb $35, %r8b
je source_unsigned_integer_success
cmpb $48, %r8b
jb source_unsigned_integer_failure
cmpb $58, %r8b
jae source_unsigned_integer_failure
addb $-48, %r8b
# check for integer overflow
movq $18446744073709551615, %rax
subq %r8, %rax
divq %rdi
cmpq %rbx, %rax
jb source_unsigned_integer_failure
# add digit
movq %rbx, %rax
mulq %rdi
addq %r8, %rax
movq %rax, %rbx
addq $-1, %rsi
jnz source_unsigned_integer_digit
source_unsigned_integer_success:
xorb %al, %al
ret
source_unsigned_integer_failure:
movb $1, %al
ret


# out
# al status
# bl input flag
# cl output flag
# dl read flag
# sil write flag
source_fence_mask:
movq source_character_address, %rax
# input
cmpb $105, (%rax)
jne source_fence_mask_first_flag_output
movb $1, %bl
xorb %cl, %cl
xorb %dl, %dl
xorb %sil, %sil
jmp source_fence_mask_second_flag
source_fence_mask_first_flag_output:
cmpb $111, (%rax)
jne source_fence_mask_first_flag_read
xorb %bl, %bl
movb $1, %cl
xorb %dl, %dl
xorb %sil, %sil
jmp source_fence_mask_second_flag
source_fence_mask_first_flag_read:
cmpb $114, (%rax)
jne source_fence_mask_first_flag_write
xorb %bl, %bl
xorb %cl, %cl
movb $1, %dl
xorb %sil, %sil
jmp source_fence_mask_second_flag
source_fence_mask_first_flag_write:
cmpb $119, (%rax)
jne source_fence_mask_failure
xorb %bl, %bl
xorb %cl, %cl
xorb %dl, %dl
movb $1, %sil

source_fence_mask_second_flag:
cmpq $1, source_character_count
je source_fence_mask_success
cmpb $10, 1(%rax)
je source_fence_mask_success
cmpb $32, 1(%rax)
je source_fence_mask_success
cmpb $35, 1(%rax)
je source_fence_mask_success
# input
cmpb $105, 1(%rax)
jne source_fence_mask_second_flag_output
xorb $1, %bl
jz source_fence_mask_failure
jmp source_fence_mask_third_flag
source_fence_mask_second_flag_output:
cmpb $111, 1(%rax)
jne source_fence_mask_second_flag_read
xorb $1, %cl
jz source_fence_mask_failure
jmp source_fence_mask_third_flag
source_fence_mask_second_flag_read:
cmpb $114, 1(%rax)
jne source_fence_mask_second_flag_write
xorb $1, %dl
jz source_fence_mask_failure
jmp source_fence_mask_third_flag
source_fence_mask_second_flag_write:
cmpb $119, 1(%rax)
jne source_fence_mask_failure
xorb $1, %sil
jz source_fence_mask_failure

source_fence_mask_third_flag:
cmpq $2, source_character_count
je source_fence_mask_success
cmpb $10, 2(%rax)
je source_fence_mask_success
cmpb $32, 2(%rax)
je source_fence_mask_success
cmpb $35, 2(%rax)
je source_fence_mask_success
# input
cmpb $105, 2(%rax)
jne source_fence_mask_third_flag_output
xorb $1, %bl
jz source_fence_mask_failure
jmp source_fence_mask_fourth_flag
source_fence_mask_third_flag_output:
cmpb $111, 2(%rax)
jne source_fence_mask_third_flag_read
xorb $1, %cl
jz source_fence_mask_failure
jmp source_fence_mask_fourth_flag
source_fence_mask_third_flag_read:
cmpb $114, 2(%rax)
jne source_fence_mask_third_flag_write
xorb $1, %dl
jz source_fence_mask_failure
jmp source_fence_mask_fourth_flag
source_fence_mask_third_flag_write:
cmpb $119, 2(%rax)
jne source_fence_mask_failure
xorb $1, %sil
jz source_fence_mask_failure

source_fence_mask_fourth_flag:
cmpq $3, source_character_count
je source_fence_mask_success
cmpb $10, 3(%rax)
je source_fence_mask_success
cmpb $32, 3(%rax)
je source_fence_mask_success
cmpb $35, 3(%rax)
je source_fence_mask_success
# fourth flag input
cmpb $105, 3(%rax)
jne source_fence_mask_fourth_flag_output
xorb $1, %bl
jz source_fence_mask_failure
jmp source_fence_mask_end
source_fence_mask_fourth_flag_output:
cmpb $111, 3(%rax)
jne source_fence_mask_fourth_flag_read
xorb $1, %cl
jz source_fence_mask_failure
jmp source_fence_mask_end
source_fence_mask_fourth_flag_read:
cmpb $114, 3(%rax)
jne source_fence_mask_fourth_flag_write
xorb $1, %dl
jz source_fence_mask_failure
jmp source_fence_mask_end
source_fence_mask_fourth_flag_write:
cmpb $119, 3(%rax)
jne source_fence_mask_failure
xorb $1, %sil
jz source_fence_mask_failure

source_fence_mask_end:
cmpq $4, source_character_count
je source_fence_mask_success
cmpb $10, 4(%rax)
je source_fence_mask_success
cmpb $32, 4(%rax)
je source_fence_mask_success
cmpb $35, 4(%rax)
je source_fence_mask_success
source_fence_mask_failure:
movb $1, %al
ret

source_fence_mask_success:
xorb %al, %al
ret


# out
# al status
source_compare_add:
cmpq $3, source_character_count
jb source_compare_add_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_add_failure
cmpb $100, 1(%rax)
jne source_compare_add_failure
cmpb $100, 2(%rax)
jne source_compare_add_failure
cmpq $3, source_character_count
je source_compare_add_success
cmpb $10, 3(%rax)
je source_compare_add_success
cmpb $32, 3(%rax)
je source_compare_add_success
cmpb $35, 3(%rax)
je source_compare_add_success
source_compare_add_failure:
movb $1, %al
ret
source_compare_add_success:
xorb %al, %al
ret


# out
# al status
source_compare_addi:
cmpq $4, source_character_count
jb source_compare_addi_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_addi_failure
cmpb $100, 1(%rax)
jne source_compare_addi_failure
cmpb $100, 2(%rax)
jne source_compare_addi_failure
cmpb $105, 3(%rax)
jne source_compare_addi_failure
cmpq $4, source_character_count
je source_compare_addi_success
cmpb $10, 4(%rax)
je source_compare_addi_success
cmpb $32, 4(%rax)
je source_compare_addi_success
cmpb $35, 4(%rax)
je source_compare_addi_success
source_compare_addi_failure:
movb $1, %al
ret
source_compare_addi_success:
xorb %al, %al
ret


# out
# al status
source_compare_addiw:
cmpq $5, source_character_count
jb source_compare_addiw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_addiw_failure
cmpb $100, 1(%rax)
jne source_compare_addiw_failure
cmpb $100, 2(%rax)
jne source_compare_addiw_failure
cmpb $105, 3(%rax)
jne source_compare_addiw_failure
cmpb $119, 4(%rax)
jne source_compare_addiw_failure
cmpq $5, source_character_count
je source_compare_addiw_success
cmpb $10, 5(%rax)
je source_compare_addiw_success
cmpb $32, 5(%rax)
je source_compare_addiw_success
cmpb $35, 5(%rax)
je source_compare_addiw_success
source_compare_addiw_failure:
movb $1, %al
ret
source_compare_addiw_success:
xorb %al, %al
ret


# out
# al status
source_compare_addw:
cmpq $4, source_character_count
jb source_compare_addw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_addw_failure
cmpb $100, 1(%rax)
jne source_compare_addw_failure
cmpb $100, 2(%rax)
jne source_compare_addw_failure
cmpb $119, 3(%rax)
jne source_compare_addw_failure
cmpq $4, source_character_count
je source_compare_addw_success
cmpb $10, 4(%rax)
je source_compare_addw_success
cmpb $32, 4(%rax)
je source_compare_addw_success
cmpb $35, 4(%rax)
je source_compare_addw_success
source_compare_addw_failure:
movb $1, %al
ret
source_compare_addw_success:
xorb %al, %al
ret


# out
# al status
source_compare_align:
cmpq $5, source_character_count
jb source_compare_align_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_align_failure
cmpb $108, 1(%rax)
jne source_compare_align_failure
cmpb $105, 2(%rax)
jne source_compare_align_failure
cmpb $103, 3(%rax)
jne source_compare_align_failure
cmpb $110, 4(%rax)
jne source_compare_align_failure
cmpq $5, source_character_count
je source_compare_align_success
cmpb $10, 5(%rax)
je source_compare_align_success
cmpb $32, 5(%rax)
je source_compare_align_success
cmpb $35, 5(%rax)
je source_compare_align_success
source_compare_align_failure:
movb $1, %al
ret
source_compare_align_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoaddd:
cmpq $7, source_character_count
jb source_compare_amoaddd_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoaddd_failure
cmpb $109, 1(%rax)
jne source_compare_amoaddd_failure
cmpb $111, 2(%rax)
jne source_compare_amoaddd_failure
cmpb $97, 3(%rax)
jne source_compare_amoaddd_failure
cmpb $100, 4(%rax)
jne source_compare_amoaddd_failure
cmpb $100, 5(%rax)
jne source_compare_amoaddd_failure
cmpb $100, 6(%rax)
jne source_compare_amoaddd_failure
cmpq $7, source_character_count
je source_compare_amoaddd_success
cmpb $10, 7(%rax)
je source_compare_amoaddd_success
cmpb $32, 7(%rax)
je source_compare_amoaddd_success
cmpb $35, 7(%rax)
je source_compare_amoaddd_success
source_compare_amoaddd_failure:
movb $1, %al
ret
source_compare_amoaddd_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoadddaq:
cmpq $9, source_character_count
jb source_compare_amoadddaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoadddaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoadddaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoadddaq_failure
cmpb $97, 3(%rax)
jne source_compare_amoadddaq_failure
cmpb $100, 4(%rax)
jne source_compare_amoadddaq_failure
cmpb $100, 5(%rax)
jne source_compare_amoadddaq_failure
cmpb $100, 6(%rax)
jne source_compare_amoadddaq_failure
cmpb $97, 7(%rax)
jne source_compare_amoadddaq_failure
cmpb $113, 8(%rax)
jne source_compare_amoadddaq_failure
cmpq $9, source_character_count
je source_compare_amoadddaq_success
cmpb $10, 9(%rax)
je source_compare_amoadddaq_success
cmpb $32, 9(%rax)
je source_compare_amoadddaq_success
cmpb $35, 9(%rax)
je source_compare_amoadddaq_success
source_compare_amoadddaq_failure:
movb $1, %al
ret
source_compare_amoadddaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoadddaqrl:
cmpq $11, source_character_count
jb source_compare_amoadddaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoadddaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoadddaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoadddaqrl_failure
cmpb $97, 3(%rax)
jne source_compare_amoadddaqrl_failure
cmpb $100, 4(%rax)
jne source_compare_amoadddaqrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoadddaqrl_failure
cmpb $100, 6(%rax)
jne source_compare_amoadddaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amoadddaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amoadddaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amoadddaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amoadddaqrl_failure
cmpq $11, source_character_count
je source_compare_amoadddaqrl_success
cmpb $10, 11(%rax)
je source_compare_amoadddaqrl_success
cmpb $32, 11(%rax)
je source_compare_amoadddaqrl_success
cmpb $35, 11(%rax)
je source_compare_amoadddaqrl_success
source_compare_amoadddaqrl_failure:
movb $1, %al
ret
source_compare_amoadddaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoadddrl:
cmpq $9, source_character_count
jb source_compare_amoadddrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoadddrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoadddrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoadddrl_failure
cmpb $97, 3(%rax)
jne source_compare_amoadddrl_failure
cmpb $100, 4(%rax)
jne source_compare_amoadddrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoadddrl_failure
cmpb $100, 6(%rax)
jne source_compare_amoadddrl_failure
cmpb $114, 7(%rax)
jne source_compare_amoadddrl_failure
cmpb $108, 8(%rax)
jne source_compare_amoadddrl_failure
cmpq $9, source_character_count
je source_compare_amoadddrl_success
cmpb $10, 9(%rax)
je source_compare_amoadddrl_success
cmpb $32, 9(%rax)
je source_compare_amoadddrl_success
cmpb $35, 9(%rax)
je source_compare_amoadddrl_success
source_compare_amoadddrl_failure:
movb $1, %al
ret
source_compare_amoadddrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoaddw:
cmpq $7, source_character_count
jb source_compare_amoaddw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoaddw_failure
cmpb $109, 1(%rax)
jne source_compare_amoaddw_failure
cmpb $111, 2(%rax)
jne source_compare_amoaddw_failure
cmpb $97, 3(%rax)
jne source_compare_amoaddw_failure
cmpb $100, 4(%rax)
jne source_compare_amoaddw_failure
cmpb $100, 5(%rax)
jne source_compare_amoaddw_failure
cmpb $119, 6(%rax)
jne source_compare_amoaddw_failure
cmpq $7, source_character_count
je source_compare_amoaddw_success
cmpb $10, 7(%rax)
je source_compare_amoaddw_success
cmpb $32, 7(%rax)
je source_compare_amoaddw_success
cmpb $35, 7(%rax)
je source_compare_amoaddw_success
source_compare_amoaddw_failure:
movb $1, %al
ret
source_compare_amoaddw_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoaddwaq:
cmpq $9, source_character_count
jb source_compare_amoaddwaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoaddwaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoaddwaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoaddwaq_failure
cmpb $97, 3(%rax)
jne source_compare_amoaddwaq_failure
cmpb $100, 4(%rax)
jne source_compare_amoaddwaq_failure
cmpb $100, 5(%rax)
jne source_compare_amoaddwaq_failure
cmpb $119, 6(%rax)
jne source_compare_amoaddwaq_failure
cmpb $97, 7(%rax)
jne source_compare_amoaddwaq_failure
cmpb $113, 8(%rax)
jne source_compare_amoaddwaq_failure
cmpq $9, source_character_count
je source_compare_amoaddwaq_success
cmpb $10, 9(%rax)
je source_compare_amoaddwaq_success
cmpb $32, 9(%rax)
je source_compare_amoaddwaq_success
cmpb $35, 9(%rax)
je source_compare_amoaddwaq_success
source_compare_amoaddwaq_failure:
movb $1, %al
ret
source_compare_amoaddwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoaddwaqrl:
cmpq $11, source_character_count
jb source_compare_amoaddwaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $97, 3(%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $100, 4(%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $119, 6(%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amoaddwaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amoaddwaqrl_failure
cmpq $11, source_character_count
je source_compare_amoaddwaqrl_success
cmpb $10, 11(%rax)
je source_compare_amoaddwaqrl_success
cmpb $32, 11(%rax)
je source_compare_amoaddwaqrl_success
cmpb $35, 11(%rax)
je source_compare_amoaddwaqrl_success
source_compare_amoaddwaqrl_failure:
movb $1, %al
ret
source_compare_amoaddwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoaddwrl:
cmpq $9, source_character_count
jb source_compare_amoaddwrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoaddwrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoaddwrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoaddwrl_failure
cmpb $97, 3(%rax)
jne source_compare_amoaddwrl_failure
cmpb $100, 4(%rax)
jne source_compare_amoaddwrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoaddwrl_failure
cmpb $119, 6(%rax)
jne source_compare_amoaddwrl_failure
cmpb $114, 7(%rax)
jne source_compare_amoaddwrl_failure
cmpb $108, 8(%rax)
jne source_compare_amoaddwrl_failure
cmpq $9, source_character_count
je source_compare_amoaddwrl_success
cmpb $10, 9(%rax)
je source_compare_amoaddwrl_success
cmpb $32, 9(%rax)
je source_compare_amoaddwrl_success
cmpb $35, 9(%rax)
je source_compare_amoaddwrl_success
source_compare_amoaddwrl_failure:
movb $1, %al
ret
source_compare_amoaddwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoandd:
cmpq $7, source_character_count
jb source_compare_amoandd_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoandd_failure
cmpb $109, 1(%rax)
jne source_compare_amoandd_failure
cmpb $111, 2(%rax)
jne source_compare_amoandd_failure
cmpb $97, 3(%rax)
jne source_compare_amoandd_failure
cmpb $110, 4(%rax)
jne source_compare_amoandd_failure
cmpb $100, 5(%rax)
jne source_compare_amoandd_failure
cmpb $100, 6(%rax)
jne source_compare_amoandd_failure
cmpq $7, source_character_count
je source_compare_amoandd_success
cmpb $10, 7(%rax)
je source_compare_amoandd_success
cmpb $32, 7(%rax)
je source_compare_amoandd_success
cmpb $35, 7(%rax)
je source_compare_amoandd_success
source_compare_amoandd_failure:
movb $1, %al
ret
source_compare_amoandd_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoanddaq:
cmpq $9, source_character_count
jb source_compare_amoanddaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoanddaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoanddaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoanddaq_failure
cmpb $97, 3(%rax)
jne source_compare_amoanddaq_failure
cmpb $110, 4(%rax)
jne source_compare_amoanddaq_failure
cmpb $100, 5(%rax)
jne source_compare_amoanddaq_failure
cmpb $100, 6(%rax)
jne source_compare_amoanddaq_failure
cmpb $97, 7(%rax)
jne source_compare_amoanddaq_failure
cmpb $113, 8(%rax)
jne source_compare_amoanddaq_failure
cmpq $9, source_character_count
je source_compare_amoanddaq_success
cmpb $10, 9(%rax)
je source_compare_amoanddaq_success
cmpb $32, 9(%rax)
je source_compare_amoanddaq_success
cmpb $35, 9(%rax)
je source_compare_amoanddaq_success
source_compare_amoanddaq_failure:
movb $1, %al
ret
source_compare_amoanddaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoanddaqrl:
cmpq $11, source_character_count
jb source_compare_amoanddaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoanddaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoanddaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoanddaqrl_failure
cmpb $97, 3(%rax)
jne source_compare_amoanddaqrl_failure
cmpb $110, 4(%rax)
jne source_compare_amoanddaqrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoanddaqrl_failure
cmpb $100, 6(%rax)
jne source_compare_amoanddaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amoanddaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amoanddaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amoanddaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amoanddaqrl_failure
cmpq $11, source_character_count
je source_compare_amoanddaqrl_success
cmpb $10, 11(%rax)
je source_compare_amoanddaqrl_success
cmpb $32, 11(%rax)
je source_compare_amoanddaqrl_success
cmpb $35, 11(%rax)
je source_compare_amoanddaqrl_success
source_compare_amoanddaqrl_failure:
movb $1, %al
ret
source_compare_amoanddaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoanddrl:
cmpq $9, source_character_count
jb source_compare_amoanddrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoanddrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoanddrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoanddrl_failure
cmpb $97, 3(%rax)
jne source_compare_amoanddrl_failure
cmpb $110, 4(%rax)
jne source_compare_amoanddrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoanddrl_failure
cmpb $100, 6(%rax)
jne source_compare_amoanddrl_failure
cmpb $114, 7(%rax)
jne source_compare_amoanddrl_failure
cmpb $108, 8(%rax)
jne source_compare_amoanddrl_failure
cmpq $9, source_character_count
je source_compare_amoanddrl_success
cmpb $10, 9(%rax)
je source_compare_amoanddrl_success
cmpb $32, 9(%rax)
je source_compare_amoanddrl_success
cmpb $35, 9(%rax)
je source_compare_amoanddrl_success
source_compare_amoanddrl_failure:
movb $1, %al
ret
source_compare_amoanddrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoandw:
cmpq $7, source_character_count
jb source_compare_amoandw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoandw_failure
cmpb $109, 1(%rax)
jne source_compare_amoandw_failure
cmpb $111, 2(%rax)
jne source_compare_amoandw_failure
cmpb $97, 3(%rax)
jne source_compare_amoandw_failure
cmpb $110, 4(%rax)
jne source_compare_amoandw_failure
cmpb $100, 5(%rax)
jne source_compare_amoandw_failure
cmpb $119, 6(%rax)
jne source_compare_amoandw_failure
cmpq $7, source_character_count
je source_compare_amoandw_success
cmpb $10, 7(%rax)
je source_compare_amoandw_success
cmpb $32, 7(%rax)
je source_compare_amoandw_success
cmpb $35, 7(%rax)
je source_compare_amoandw_success
source_compare_amoandw_failure:
movb $1, %al
ret
source_compare_amoandw_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoandwaq:
cmpq $9, source_character_count
jb source_compare_amoandwaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoandwaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoandwaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoandwaq_failure
cmpb $97, 3(%rax)
jne source_compare_amoandwaq_failure
cmpb $110, 4(%rax)
jne source_compare_amoandwaq_failure
cmpb $100, 5(%rax)
jne source_compare_amoandwaq_failure
cmpb $119, 6(%rax)
jne source_compare_amoandwaq_failure
cmpb $97, 7(%rax)
jne source_compare_amoandwaq_failure
cmpb $113, 8(%rax)
jne source_compare_amoandwaq_failure
cmpq $9, source_character_count
je source_compare_amoandwaq_success
cmpb $10, 9(%rax)
je source_compare_amoandwaq_success
cmpb $32, 9(%rax)
je source_compare_amoandwaq_success
cmpb $35, 9(%rax)
je source_compare_amoandwaq_success
source_compare_amoandwaq_failure:
movb $1, %al
ret
source_compare_amoandwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoandwaqrl:
cmpq $11, source_character_count
jb source_compare_amoandwaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoandwaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoandwaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoandwaqrl_failure
cmpb $97, 3(%rax)
jne source_compare_amoandwaqrl_failure
cmpb $110, 4(%rax)
jne source_compare_amoandwaqrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoandwaqrl_failure
cmpb $119, 6(%rax)
jne source_compare_amoandwaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amoandwaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amoandwaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amoandwaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amoandwaqrl_failure
cmpq $11, source_character_count
je source_compare_amoandwaqrl_success
cmpb $10, 11(%rax)
je source_compare_amoandwaqrl_success
cmpb $32, 11(%rax)
je source_compare_amoandwaqrl_success
cmpb $35, 11(%rax)
je source_compare_amoandwaqrl_success
source_compare_amoandwaqrl_failure:
movb $1, %al
ret
source_compare_amoandwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoandwrl:
cmpq $9, source_character_count
jb source_compare_amoandwrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoandwrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoandwrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoandwrl_failure
cmpb $97, 3(%rax)
jne source_compare_amoandwrl_failure
cmpb $110, 4(%rax)
jne source_compare_amoandwrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoandwrl_failure
cmpb $119, 6(%rax)
jne source_compare_amoandwrl_failure
cmpb $114, 7(%rax)
jne source_compare_amoandwrl_failure
cmpb $108, 8(%rax)
jne source_compare_amoandwrl_failure
cmpq $9, source_character_count
je source_compare_amoandwrl_success
cmpb $10, 9(%rax)
je source_compare_amoandwrl_success
cmpb $32, 9(%rax)
je source_compare_amoandwrl_success
cmpb $35, 9(%rax)
je source_compare_amoandwrl_success
source_compare_amoandwrl_failure:
movb $1, %al
ret
source_compare_amoandwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxd:
cmpq $7, source_character_count
jb source_compare_amomaxd_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxd_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxd_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxd_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxd_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxd_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxd_failure
cmpb $100, 6(%rax)
jne source_compare_amomaxd_failure
cmpq $7, source_character_count
je source_compare_amomaxd_success
cmpb $10, 7(%rax)
je source_compare_amomaxd_success
cmpb $32, 7(%rax)
je source_compare_amomaxd_success
cmpb $35, 7(%rax)
je source_compare_amomaxd_success
source_compare_amomaxd_failure:
movb $1, %al
ret
source_compare_amomaxd_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxdaq:
cmpq $9, source_character_count
jb source_compare_amomaxdaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxdaq_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxdaq_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxdaq_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxdaq_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxdaq_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxdaq_failure
cmpb $100, 6(%rax)
jne source_compare_amomaxdaq_failure
cmpb $97, 7(%rax)
jne source_compare_amomaxdaq_failure
cmpb $113, 8(%rax)
jne source_compare_amomaxdaq_failure
cmpq $9, source_character_count
je source_compare_amomaxdaq_success
cmpb $10, 9(%rax)
je source_compare_amomaxdaq_success
cmpb $32, 9(%rax)
je source_compare_amomaxdaq_success
cmpb $35, 9(%rax)
je source_compare_amomaxdaq_success
source_compare_amomaxdaq_failure:
movb $1, %al
ret
source_compare_amomaxdaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxdaqrl:
cmpq $11, source_character_count
jb source_compare_amomaxdaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $100, 6(%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amomaxdaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amomaxdaqrl_failure
cmpq $11, source_character_count
je source_compare_amomaxdaqrl_success
cmpb $10, 11(%rax)
je source_compare_amomaxdaqrl_success
cmpb $32, 11(%rax)
je source_compare_amomaxdaqrl_success
cmpb $35, 11(%rax)
je source_compare_amomaxdaqrl_success
source_compare_amomaxdaqrl_failure:
movb $1, %al
ret
source_compare_amomaxdaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxdrl:
cmpq $9, source_character_count
jb source_compare_amomaxdrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxdrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxdrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxdrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxdrl_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxdrl_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxdrl_failure
cmpb $100, 6(%rax)
jne source_compare_amomaxdrl_failure
cmpb $114, 7(%rax)
jne source_compare_amomaxdrl_failure
cmpb $108, 8(%rax)
jne source_compare_amomaxdrl_failure
cmpq $9, source_character_count
je source_compare_amomaxdrl_success
cmpb $10, 9(%rax)
je source_compare_amomaxdrl_success
cmpb $32, 9(%rax)
je source_compare_amomaxdrl_success
cmpb $35, 9(%rax)
je source_compare_amomaxdrl_success
source_compare_amomaxdrl_failure:
movb $1, %al
ret
source_compare_amomaxdrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxw:
cmpq $7, source_character_count
jb source_compare_amomaxw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxw_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxw_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxw_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxw_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxw_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxw_failure
cmpb $119, 6(%rax)
jne source_compare_amomaxw_failure
cmpq $7, source_character_count
je source_compare_amomaxw_success
cmpb $10, 7(%rax)
je source_compare_amomaxw_success
cmpb $32, 7(%rax)
je source_compare_amomaxw_success
cmpb $35, 7(%rax)
je source_compare_amomaxw_success
source_compare_amomaxw_failure:
movb $1, %al
ret
source_compare_amomaxw_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxwaq:
cmpq $9, source_character_count
jb source_compare_amomaxwaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxwaq_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxwaq_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxwaq_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxwaq_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxwaq_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxwaq_failure
cmpb $119, 6(%rax)
jne source_compare_amomaxwaq_failure
cmpb $97, 7(%rax)
jne source_compare_amomaxwaq_failure
cmpb $113, 8(%rax)
jne source_compare_amomaxwaq_failure
cmpq $9, source_character_count
je source_compare_amomaxwaq_success
cmpb $10, 9(%rax)
je source_compare_amomaxwaq_success
cmpb $32, 9(%rax)
je source_compare_amomaxwaq_success
cmpb $35, 9(%rax)
je source_compare_amomaxwaq_success
source_compare_amomaxwaq_failure:
movb $1, %al
ret
source_compare_amomaxwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxwaqrl:
cmpq $11, source_character_count
jb source_compare_amomaxwaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $119, 6(%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amomaxwaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amomaxwaqrl_failure
cmpq $11, source_character_count
je source_compare_amomaxwaqrl_success
cmpb $10, 11(%rax)
je source_compare_amomaxwaqrl_success
cmpb $32, 11(%rax)
je source_compare_amomaxwaqrl_success
cmpb $35, 11(%rax)
je source_compare_amomaxwaqrl_success
source_compare_amomaxwaqrl_failure:
movb $1, %al
ret
source_compare_amomaxwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxwrl:
cmpq $9, source_character_count
jb source_compare_amomaxwrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxwrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxwrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxwrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxwrl_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxwrl_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxwrl_failure
cmpb $119, 6(%rax)
jne source_compare_amomaxwrl_failure
cmpb $114, 7(%rax)
jne source_compare_amomaxwrl_failure
cmpb $108, 8(%rax)
jne source_compare_amomaxwrl_failure
cmpq $9, source_character_count
je source_compare_amomaxwrl_success
cmpb $10, 9(%rax)
je source_compare_amomaxwrl_success
cmpb $32, 9(%rax)
je source_compare_amomaxwrl_success
cmpb $35, 9(%rax)
je source_compare_amomaxwrl_success
source_compare_amomaxwrl_failure:
movb $1, %al
ret
source_compare_amomaxwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxud:
cmpq $8, source_character_count
jb source_compare_amomaxud_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxud_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxud_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxud_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxud_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxud_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxud_failure
cmpb $117, 6(%rax)
jne source_compare_amomaxud_failure
cmpb $100, 7(%rax)
jne source_compare_amomaxud_failure
cmpq $8, source_character_count
je source_compare_amomaxud_success
cmpb $10, 8(%rax)
je source_compare_amomaxud_success
cmpb $32, 8(%rax)
je source_compare_amomaxud_success
cmpb $35, 8(%rax)
je source_compare_amomaxud_success
source_compare_amomaxud_failure:
movb $1, %al
ret
source_compare_amomaxud_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxudaq:
cmpq $10, source_character_count
jb source_compare_amomaxudaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxudaq_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxudaq_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxudaq_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxudaq_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxudaq_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxudaq_failure
cmpb $117, 6(%rax)
jne source_compare_amomaxudaq_failure
cmpb $100, 7(%rax)
jne source_compare_amomaxudaq_failure
cmpb $97, 8(%rax)
jne source_compare_amomaxudaq_failure
cmpb $113, 9(%rax)
jne source_compare_amomaxudaq_failure
cmpq $10, source_character_count
je source_compare_amomaxudaq_success
cmpb $10, 10(%rax)
je source_compare_amomaxudaq_success
cmpb $32, 10(%rax)
je source_compare_amomaxudaq_success
cmpb $35, 10(%rax)
je source_compare_amomaxudaq_success
source_compare_amomaxudaq_failure:
movb $1, %al
ret
source_compare_amomaxudaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxudaqrl:
cmpq $12, source_character_count
jb source_compare_amomaxudaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $117, 6(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $100, 7(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $97, 8(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $113, 9(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $114, 10(%rax)
jne source_compare_amomaxudaqrl_failure
cmpb $108, 11(%rax)
jne source_compare_amomaxudaqrl_failure
cmpq $12, source_character_count
je source_compare_amomaxudaqrl_success
cmpb $10, 12(%rax)
je source_compare_amomaxudaqrl_success
cmpb $32, 12(%rax)
je source_compare_amomaxudaqrl_success
cmpb $35, 12(%rax)
je source_compare_amomaxudaqrl_success
source_compare_amomaxudaqrl_failure:
movb $1, %al
ret
source_compare_amomaxudaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxudrl:
cmpq $10, source_character_count
jb source_compare_amomaxudrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxudrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxudrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxudrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxudrl_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxudrl_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxudrl_failure
cmpb $117, 6(%rax)
jne source_compare_amomaxudrl_failure
cmpb $100, 7(%rax)
jne source_compare_amomaxudrl_failure
cmpb $114, 8(%rax)
jne source_compare_amomaxudrl_failure
cmpb $108, 9(%rax)
jne source_compare_amomaxudrl_failure
cmpq $10, source_character_count
je source_compare_amomaxudrl_success
cmpb $10, 10(%rax)
je source_compare_amomaxudrl_success
cmpb $32, 10(%rax)
je source_compare_amomaxudrl_success
cmpb $35, 10(%rax)
je source_compare_amomaxudrl_success
source_compare_amomaxudrl_failure:
movb $1, %al
ret
source_compare_amomaxudrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxuw:
cmpq $8, source_character_count
jb source_compare_amomaxuw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxuw_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxuw_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxuw_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxuw_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxuw_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxuw_failure
cmpb $117, 6(%rax)
jne source_compare_amomaxuw_failure
cmpb $119, 7(%rax)
jne source_compare_amomaxuw_failure
cmpq $8, source_character_count
je source_compare_amomaxuw_success
cmpb $10, 8(%rax)
je source_compare_amomaxuw_success
cmpb $32, 8(%rax)
je source_compare_amomaxuw_success
cmpb $35, 8(%rax)
je source_compare_amomaxuw_success
source_compare_amomaxuw_failure:
movb $1, %al
ret
source_compare_amomaxuw_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxuwaq:
cmpq $10, source_character_count
jb source_compare_amomaxuwaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxuwaq_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxuwaq_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxuwaq_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxuwaq_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxuwaq_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxuwaq_failure
cmpb $117, 6(%rax)
jne source_compare_amomaxuwaq_failure
cmpb $119, 7(%rax)
jne source_compare_amomaxuwaq_failure
cmpb $97, 8(%rax)
jne source_compare_amomaxuwaq_failure
cmpb $113, 9(%rax)
jne source_compare_amomaxuwaq_failure
cmpq $10, source_character_count
je source_compare_amomaxuwaq_success
cmpb $10, 10(%rax)
je source_compare_amomaxuwaq_success
cmpb $32, 10(%rax)
je source_compare_amomaxuwaq_success
cmpb $35, 10(%rax)
je source_compare_amomaxuwaq_success
source_compare_amomaxuwaq_failure:
movb $1, %al
ret
source_compare_amomaxuwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxuwaqrl:
cmpq $12, source_character_count
jb source_compare_amomaxuwaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $117, 6(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $119, 7(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $97, 8(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $113, 9(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $114, 10(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpb $108, 11(%rax)
jne source_compare_amomaxuwaqrl_failure
cmpq $12, source_character_count
je source_compare_amomaxuwaqrl_success
cmpb $10, 12(%rax)
je source_compare_amomaxuwaqrl_success
cmpb $32, 12(%rax)
je source_compare_amomaxuwaqrl_success
cmpb $35, 12(%rax)
je source_compare_amomaxuwaqrl_success
source_compare_amomaxuwaqrl_failure:
movb $1, %al
ret
source_compare_amomaxuwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomaxuwrl:
cmpq $10, source_character_count
jb source_compare_amomaxuwrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomaxuwrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomaxuwrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomaxuwrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomaxuwrl_failure
cmpb $97, 4(%rax)
jne source_compare_amomaxuwrl_failure
cmpb $120, 5(%rax)
jne source_compare_amomaxuwrl_failure
cmpb $117, 6(%rax)
jne source_compare_amomaxuwrl_failure
cmpb $119, 7(%rax)
jne source_compare_amomaxuwrl_failure
cmpb $114, 8(%rax)
jne source_compare_amomaxuwrl_failure
cmpb $108, 9(%rax)
jne source_compare_amomaxuwrl_failure
cmpq $10, source_character_count
je source_compare_amomaxuwrl_success
cmpb $10, 10(%rax)
je source_compare_amomaxuwrl_success
cmpb $32, 10(%rax)
je source_compare_amomaxuwrl_success
cmpb $35, 10(%rax)
je source_compare_amomaxuwrl_success
source_compare_amomaxuwrl_failure:
movb $1, %al
ret
source_compare_amomaxuwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomind:
cmpq $7, source_character_count
jb source_compare_amomind_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomind_failure
cmpb $109, 1(%rax)
jne source_compare_amomind_failure
cmpb $111, 2(%rax)
jne source_compare_amomind_failure
cmpb $109, 3(%rax)
jne source_compare_amomind_failure
cmpb $105, 4(%rax)
jne source_compare_amomind_failure
cmpb $110, 5(%rax)
jne source_compare_amomind_failure
cmpb $100, 6(%rax)
jne source_compare_amomind_failure
cmpq $7, source_character_count
je source_compare_amomind_success
cmpb $10, 7(%rax)
je source_compare_amomind_success
cmpb $32, 7(%rax)
je source_compare_amomind_success
cmpb $35, 7(%rax)
je source_compare_amomind_success
source_compare_amomind_failure:
movb $1, %al
ret
source_compare_amomind_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomindaq:
cmpq $9, source_character_count
jb source_compare_amomindaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomindaq_failure
cmpb $109, 1(%rax)
jne source_compare_amomindaq_failure
cmpb $111, 2(%rax)
jne source_compare_amomindaq_failure
cmpb $109, 3(%rax)
jne source_compare_amomindaq_failure
cmpb $105, 4(%rax)
jne source_compare_amomindaq_failure
cmpb $110, 5(%rax)
jne source_compare_amomindaq_failure
cmpb $100, 6(%rax)
jne source_compare_amomindaq_failure
cmpb $97, 7(%rax)
jne source_compare_amomindaq_failure
cmpb $113, 8(%rax)
jne source_compare_amomindaq_failure
cmpq $9, source_character_count
je source_compare_amomindaq_success
cmpb $10, 9(%rax)
je source_compare_amomindaq_success
cmpb $32, 9(%rax)
je source_compare_amomindaq_success
cmpb $35, 9(%rax)
je source_compare_amomindaq_success
source_compare_amomindaq_failure:
movb $1, %al
ret
source_compare_amomindaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomindaqrl:
cmpq $11, source_character_count
jb source_compare_amomindaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomindaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomindaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomindaqrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomindaqrl_failure
cmpb $105, 4(%rax)
jne source_compare_amomindaqrl_failure
cmpb $110, 5(%rax)
jne source_compare_amomindaqrl_failure
cmpb $100, 6(%rax)
jne source_compare_amomindaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amomindaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amomindaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amomindaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amomindaqrl_failure
cmpq $11, source_character_count
je source_compare_amomindaqrl_success
cmpb $10, 11(%rax)
je source_compare_amomindaqrl_success
cmpb $32, 11(%rax)
je source_compare_amomindaqrl_success
cmpb $35, 11(%rax)
je source_compare_amomindaqrl_success
source_compare_amomindaqrl_failure:
movb $1, %al
ret
source_compare_amomindaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amomindrl:
cmpq $9, source_character_count
jb source_compare_amomindrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amomindrl_failure
cmpb $109, 1(%rax)
jne source_compare_amomindrl_failure
cmpb $111, 2(%rax)
jne source_compare_amomindrl_failure
cmpb $109, 3(%rax)
jne source_compare_amomindrl_failure
cmpb $105, 4(%rax)
jne source_compare_amomindrl_failure
cmpb $110, 5(%rax)
jne source_compare_amomindrl_failure
cmpb $100, 6(%rax)
jne source_compare_amomindrl_failure
cmpb $114, 7(%rax)
jne source_compare_amomindrl_failure
cmpb $108, 8(%rax)
jne source_compare_amomindrl_failure
cmpq $9, source_character_count
je source_compare_amomindrl_success
cmpb $10, 9(%rax)
je source_compare_amomindrl_success
cmpb $32, 9(%rax)
je source_compare_amomindrl_success
cmpb $35, 9(%rax)
je source_compare_amomindrl_success
source_compare_amomindrl_failure:
movb $1, %al
ret
source_compare_amomindrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominw:
cmpq $7, source_character_count
jb source_compare_amominw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominw_failure
cmpb $109, 1(%rax)
jne source_compare_amominw_failure
cmpb $111, 2(%rax)
jne source_compare_amominw_failure
cmpb $109, 3(%rax)
jne source_compare_amominw_failure
cmpb $105, 4(%rax)
jne source_compare_amominw_failure
cmpb $110, 5(%rax)
jne source_compare_amominw_failure
cmpb $119, 6(%rax)
jne source_compare_amominw_failure
cmpq $7, source_character_count
je source_compare_amominw_success
cmpb $10, 7(%rax)
je source_compare_amominw_success
cmpb $32, 7(%rax)
je source_compare_amominw_success
cmpb $35, 7(%rax)
je source_compare_amominw_success
source_compare_amominw_failure:
movb $1, %al
ret
source_compare_amominw_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominwaq:
cmpq $9, source_character_count
jb source_compare_amominwaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominwaq_failure
cmpb $109, 1(%rax)
jne source_compare_amominwaq_failure
cmpb $111, 2(%rax)
jne source_compare_amominwaq_failure
cmpb $109, 3(%rax)
jne source_compare_amominwaq_failure
cmpb $105, 4(%rax)
jne source_compare_amominwaq_failure
cmpb $110, 5(%rax)
jne source_compare_amominwaq_failure
cmpb $119, 6(%rax)
jne source_compare_amominwaq_failure
cmpb $97, 7(%rax)
jne source_compare_amominwaq_failure
cmpb $113, 8(%rax)
jne source_compare_amominwaq_failure
cmpq $9, source_character_count
je source_compare_amominwaq_success
cmpb $10, 9(%rax)
je source_compare_amominwaq_success
cmpb $32, 9(%rax)
je source_compare_amominwaq_success
cmpb $35, 9(%rax)
je source_compare_amominwaq_success
source_compare_amominwaq_failure:
movb $1, %al
ret
source_compare_amominwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominwaqrl:
cmpq $11, source_character_count
jb source_compare_amominwaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominwaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amominwaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amominwaqrl_failure
cmpb $109, 3(%rax)
jne source_compare_amominwaqrl_failure
cmpb $105, 4(%rax)
jne source_compare_amominwaqrl_failure
cmpb $110, 5(%rax)
jne source_compare_amominwaqrl_failure
cmpb $119, 6(%rax)
jne source_compare_amominwaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amominwaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amominwaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amominwaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amominwaqrl_failure
cmpq $11, source_character_count
je source_compare_amominwaqrl_success
cmpb $10, 11(%rax)
je source_compare_amominwaqrl_success
cmpb $32, 11(%rax)
je source_compare_amominwaqrl_success
cmpb $35, 11(%rax)
je source_compare_amominwaqrl_success
source_compare_amominwaqrl_failure:
movb $1, %al
ret
source_compare_amominwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominwrl:
cmpq $9, source_character_count
jb source_compare_amominwrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominwrl_failure
cmpb $109, 1(%rax)
jne source_compare_amominwrl_failure
cmpb $111, 2(%rax)
jne source_compare_amominwrl_failure
cmpb $109, 3(%rax)
jne source_compare_amominwrl_failure
cmpb $105, 4(%rax)
jne source_compare_amominwrl_failure
cmpb $110, 5(%rax)
jne source_compare_amominwrl_failure
cmpb $119, 6(%rax)
jne source_compare_amominwrl_failure
cmpb $114, 7(%rax)
jne source_compare_amominwrl_failure
cmpb $108, 8(%rax)
jne source_compare_amominwrl_failure
cmpq $9, source_character_count
je source_compare_amominwrl_success
cmpb $10, 9(%rax)
je source_compare_amominwrl_success
cmpb $32, 9(%rax)
je source_compare_amominwrl_success
cmpb $35, 9(%rax)
je source_compare_amominwrl_success
source_compare_amominwrl_failure:
movb $1, %al
ret
source_compare_amominwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominud:
cmpq $8, source_character_count
jb source_compare_amominud_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominud_failure
cmpb $109, 1(%rax)
jne source_compare_amominud_failure
cmpb $111, 2(%rax)
jne source_compare_amominud_failure
cmpb $109, 3(%rax)
jne source_compare_amominud_failure
cmpb $105, 4(%rax)
jne source_compare_amominud_failure
cmpb $110, 5(%rax)
jne source_compare_amominud_failure
cmpb $117, 6(%rax)
jne source_compare_amominud_failure
cmpb $100, 7(%rax)
jne source_compare_amominud_failure
cmpq $8, source_character_count
je source_compare_amominud_success
cmpb $10, 8(%rax)
je source_compare_amominud_success
cmpb $32, 8(%rax)
je source_compare_amominud_success
cmpb $35, 8(%rax)
je source_compare_amominud_success
source_compare_amominud_failure:
movb $1, %al
ret
source_compare_amominud_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominudaq:
cmpq $10, source_character_count
jb source_compare_amominudaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominudaq_failure
cmpb $109, 1(%rax)
jne source_compare_amominudaq_failure
cmpb $111, 2(%rax)
jne source_compare_amominudaq_failure
cmpb $109, 3(%rax)
jne source_compare_amominudaq_failure
cmpb $105, 4(%rax)
jne source_compare_amominudaq_failure
cmpb $110, 5(%rax)
jne source_compare_amominudaq_failure
cmpb $117, 6(%rax)
jne source_compare_amominudaq_failure
cmpb $100, 7(%rax)
jne source_compare_amominudaq_failure
cmpb $97, 8(%rax)
jne source_compare_amominudaq_failure
cmpb $113, 9(%rax)
jne source_compare_amominudaq_failure
cmpq $10, source_character_count
je source_compare_amominudaq_success
cmpb $10, 10(%rax)
je source_compare_amominudaq_success
cmpb $32, 10(%rax)
je source_compare_amominudaq_success
cmpb $35, 10(%rax)
je source_compare_amominudaq_success
source_compare_amominudaq_failure:
movb $1, %al
ret
source_compare_amominudaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominudaqrl:
cmpq $12, source_character_count
jb source_compare_amominudaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominudaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amominudaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amominudaqrl_failure
cmpb $109, 3(%rax)
jne source_compare_amominudaqrl_failure
cmpb $105, 4(%rax)
jne source_compare_amominudaqrl_failure
cmpb $110, 5(%rax)
jne source_compare_amominudaqrl_failure
cmpb $117, 6(%rax)
jne source_compare_amominudaqrl_failure
cmpb $100, 7(%rax)
jne source_compare_amominudaqrl_failure
cmpb $97, 8(%rax)
jne source_compare_amominudaqrl_failure
cmpb $113, 9(%rax)
jne source_compare_amominudaqrl_failure
cmpb $114, 10(%rax)
jne source_compare_amominudaqrl_failure
cmpb $108, 11(%rax)
jne source_compare_amominudaqrl_failure
cmpq $12, source_character_count
je source_compare_amominudaqrl_success
cmpb $10, 12(%rax)
je source_compare_amominudaqrl_success
cmpb $32, 12(%rax)
je source_compare_amominudaqrl_success
cmpb $35, 12(%rax)
je source_compare_amominudaqrl_success
source_compare_amominudaqrl_failure:
movb $1, %al
ret
source_compare_amominudaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominudrl:
cmpq $10, source_character_count
jb source_compare_amominudrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominudrl_failure
cmpb $109, 1(%rax)
jne source_compare_amominudrl_failure
cmpb $111, 2(%rax)
jne source_compare_amominudrl_failure
cmpb $109, 3(%rax)
jne source_compare_amominudrl_failure
cmpb $105, 4(%rax)
jne source_compare_amominudrl_failure
cmpb $110, 5(%rax)
jne source_compare_amominudrl_failure
cmpb $117, 6(%rax)
jne source_compare_amominudrl_failure
cmpb $100, 7(%rax)
jne source_compare_amominudrl_failure
cmpb $114, 8(%rax)
jne source_compare_amominudrl_failure
cmpb $108, 9(%rax)
jne source_compare_amominudrl_failure
cmpq $10, source_character_count
je source_compare_amominudrl_success
cmpb $10, 10(%rax)
je source_compare_amominudrl_success
cmpb $32, 10(%rax)
je source_compare_amominudrl_success
cmpb $35, 10(%rax)
je source_compare_amominudrl_success
source_compare_amominudrl_failure:
movb $1, %al
ret
source_compare_amominudrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominuw:
cmpq $8, source_character_count
jb source_compare_amominuw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominuw_failure
cmpb $109, 1(%rax)
jne source_compare_amominuw_failure
cmpb $111, 2(%rax)
jne source_compare_amominuw_failure
cmpb $109, 3(%rax)
jne source_compare_amominuw_failure
cmpb $105, 4(%rax)
jne source_compare_amominuw_failure
cmpb $110, 5(%rax)
jne source_compare_amominuw_failure
cmpb $117, 6(%rax)
jne source_compare_amominuw_failure
cmpb $119, 7(%rax)
jne source_compare_amominuw_failure
cmpq $8, source_character_count
je source_compare_amominuw_success
cmpb $10, 8(%rax)
je source_compare_amominuw_success
cmpb $32, 8(%rax)
je source_compare_amominuw_success
cmpb $35, 8(%rax)
je source_compare_amominuw_success
source_compare_amominuw_failure:
movb $1, %al
ret
source_compare_amominuw_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominuwaq:
cmpq $10, source_character_count
jb source_compare_amominuwaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominuwaq_failure
cmpb $109, 1(%rax)
jne source_compare_amominuwaq_failure
cmpb $111, 2(%rax)
jne source_compare_amominuwaq_failure
cmpb $109, 3(%rax)
jne source_compare_amominuwaq_failure
cmpb $105, 4(%rax)
jne source_compare_amominuwaq_failure
cmpb $110, 5(%rax)
jne source_compare_amominuwaq_failure
cmpb $117, 6(%rax)
jne source_compare_amominuwaq_failure
cmpb $119, 7(%rax)
jne source_compare_amominuwaq_failure
cmpb $97, 8(%rax)
jne source_compare_amominuwaq_failure
cmpb $113, 9(%rax)
jne source_compare_amominuwaq_failure
cmpq $10, source_character_count
je source_compare_amominuwaq_success
cmpb $10, 10(%rax)
je source_compare_amominuwaq_success
cmpb $32, 10(%rax)
je source_compare_amominuwaq_success
cmpb $35, 10(%rax)
je source_compare_amominuwaq_success
source_compare_amominuwaq_failure:
movb $1, %al
ret
source_compare_amominuwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominuwaqrl:
cmpq $12, source_character_count
jb source_compare_amominuwaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominuwaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $109, 3(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $105, 4(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $110, 5(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $117, 6(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $119, 7(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $97, 8(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $113, 9(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $114, 10(%rax)
jne source_compare_amominuwaqrl_failure
cmpb $108, 11(%rax)
jne source_compare_amominuwaqrl_failure
cmpq $12, source_character_count
je source_compare_amominuwaqrl_success
cmpb $10, 12(%rax)
je source_compare_amominuwaqrl_success
cmpb $32, 12(%rax)
je source_compare_amominuwaqrl_success
cmpb $35, 12(%rax)
je source_compare_amominuwaqrl_success
source_compare_amominuwaqrl_failure:
movb $1, %al
ret
source_compare_amominuwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amominuwrl:
cmpq $10, source_character_count
jb source_compare_amominuwrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amominuwrl_failure
cmpb $109, 1(%rax)
jne source_compare_amominuwrl_failure
cmpb $111, 2(%rax)
jne source_compare_amominuwrl_failure
cmpb $109, 3(%rax)
jne source_compare_amominuwrl_failure
cmpb $105, 4(%rax)
jne source_compare_amominuwrl_failure
cmpb $110, 5(%rax)
jne source_compare_amominuwrl_failure
cmpb $117, 6(%rax)
jne source_compare_amominuwrl_failure
cmpb $119, 7(%rax)
jne source_compare_amominuwrl_failure
cmpb $114, 8(%rax)
jne source_compare_amominuwrl_failure
cmpb $108, 9(%rax)
jne source_compare_amominuwrl_failure
cmpq $10, source_character_count
je source_compare_amominuwrl_success
cmpb $10, 10(%rax)
je source_compare_amominuwrl_success
cmpb $32, 10(%rax)
je source_compare_amominuwrl_success
cmpb $35, 10(%rax)
je source_compare_amominuwrl_success
source_compare_amominuwrl_failure:
movb $1, %al
ret
source_compare_amominuwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoord:
cmpq $6, source_character_count
jb source_compare_amoord_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoord_failure
cmpb $109, 1(%rax)
jne source_compare_amoord_failure
cmpb $111, 2(%rax)
jne source_compare_amoord_failure
cmpb $111, 3(%rax)
jne source_compare_amoord_failure
cmpb $114, 4(%rax)
jne source_compare_amoord_failure
cmpb $100, 5(%rax)
jne source_compare_amoord_failure
cmpq $6, source_character_count
je source_compare_amoord_success
cmpb $10, 6(%rax)
je source_compare_amoord_success
cmpb $32, 6(%rax)
je source_compare_amoord_success
cmpb $35, 6(%rax)
je source_compare_amoord_success
source_compare_amoord_failure:
movb $1, %al
ret
source_compare_amoord_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoordaq:
cmpq $8, source_character_count
jb source_compare_amoordaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoordaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoordaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoordaq_failure
cmpb $111, 3(%rax)
jne source_compare_amoordaq_failure
cmpb $114, 4(%rax)
jne source_compare_amoordaq_failure
cmpb $100, 5(%rax)
jne source_compare_amoordaq_failure
cmpb $97, 6(%rax)
jne source_compare_amoordaq_failure
cmpb $113, 7(%rax)
jne source_compare_amoordaq_failure
cmpq $8, source_character_count
je source_compare_amoordaq_success
cmpb $10, 8(%rax)
je source_compare_amoordaq_success
cmpb $32, 8(%rax)
je source_compare_amoordaq_success
cmpb $35, 8(%rax)
je source_compare_amoordaq_success
source_compare_amoordaq_failure:
movb $1, %al
ret
source_compare_amoordaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoordaqrl:
cmpq $10, source_character_count
jb source_compare_amoordaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoordaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoordaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoordaqrl_failure
cmpb $111, 3(%rax)
jne source_compare_amoordaqrl_failure
cmpb $114, 4(%rax)
jne source_compare_amoordaqrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoordaqrl_failure
cmpb $97, 6(%rax)
jne source_compare_amoordaqrl_failure
cmpb $113, 7(%rax)
jne source_compare_amoordaqrl_failure
cmpb $114, 8(%rax)
jne source_compare_amoordaqrl_failure
cmpb $108, 9(%rax)
jne source_compare_amoordaqrl_failure
cmpq $10, source_character_count
je source_compare_amoordaqrl_success
cmpb $10, 10(%rax)
je source_compare_amoordaqrl_success
cmpb $32, 10(%rax)
je source_compare_amoordaqrl_success
cmpb $35, 10(%rax)
je source_compare_amoordaqrl_success
source_compare_amoordaqrl_failure:
movb $1, %al
ret
source_compare_amoordaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoordrl:
cmpq $8, source_character_count
jb source_compare_amoordrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoordrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoordrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoordrl_failure
cmpb $111, 3(%rax)
jne source_compare_amoordrl_failure
cmpb $114, 4(%rax)
jne source_compare_amoordrl_failure
cmpb $100, 5(%rax)
jne source_compare_amoordrl_failure
cmpb $114, 6(%rax)
jne source_compare_amoordrl_failure
cmpb $108, 7(%rax)
jne source_compare_amoordrl_failure
cmpq $8, source_character_count
je source_compare_amoordrl_success
cmpb $10, 8(%rax)
je source_compare_amoordrl_success
cmpb $32, 8(%rax)
je source_compare_amoordrl_success
cmpb $35, 8(%rax)
je source_compare_amoordrl_success
source_compare_amoordrl_failure:
movb $1, %al
ret
source_compare_amoordrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoorw:
cmpq $6, source_character_count
jb source_compare_amoorw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoorw_failure
cmpb $109, 1(%rax)
jne source_compare_amoorw_failure
cmpb $111, 2(%rax)
jne source_compare_amoorw_failure
cmpb $111, 3(%rax)
jne source_compare_amoorw_failure
cmpb $114, 4(%rax)
jne source_compare_amoorw_failure
cmpb $119, 5(%rax)
jne source_compare_amoorw_failure
cmpq $6, source_character_count
je source_compare_amoorw_success
cmpb $10, 6(%rax)
je source_compare_amoorw_success
cmpb $32, 6(%rax)
je source_compare_amoorw_success
cmpb $35, 6(%rax)
je source_compare_amoorw_success
source_compare_amoorw_failure:
movb $1, %al
ret
source_compare_amoorw_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoorwaq:
cmpq $8, source_character_count
jb source_compare_amoorwaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoorwaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoorwaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoorwaq_failure
cmpb $111, 3(%rax)
jne source_compare_amoorwaq_failure
cmpb $114, 4(%rax)
jne source_compare_amoorwaq_failure
cmpb $119, 5(%rax)
jne source_compare_amoorwaq_failure
cmpb $97, 6(%rax)
jne source_compare_amoorwaq_failure
cmpb $113, 7(%rax)
jne source_compare_amoorwaq_failure
cmpq $8, source_character_count
je source_compare_amoorwaq_success
cmpb $10, 8(%rax)
je source_compare_amoorwaq_success
cmpb $32, 8(%rax)
je source_compare_amoorwaq_success
cmpb $35, 8(%rax)
je source_compare_amoorwaq_success
source_compare_amoorwaq_failure:
movb $1, %al
ret
source_compare_amoorwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoorwaqrl:
cmpq $10, source_character_count
jb source_compare_amoorwaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoorwaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoorwaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoorwaqrl_failure
cmpb $111, 3(%rax)
jne source_compare_amoorwaqrl_failure
cmpb $114, 4(%rax)
jne source_compare_amoorwaqrl_failure
cmpb $119, 5(%rax)
jne source_compare_amoorwaqrl_failure
cmpb $97, 6(%rax)
jne source_compare_amoorwaqrl_failure
cmpb $113, 7(%rax)
jne source_compare_amoorwaqrl_failure
cmpb $114, 8(%rax)
jne source_compare_amoorwaqrl_failure
cmpb $108, 9(%rax)
jne source_compare_amoorwaqrl_failure
cmpq $10, source_character_count
je source_compare_amoorwaqrl_success
cmpb $10, 10(%rax)
je source_compare_amoorwaqrl_success
cmpb $32, 10(%rax)
je source_compare_amoorwaqrl_success
cmpb $35, 10(%rax)
je source_compare_amoorwaqrl_success
source_compare_amoorwaqrl_failure:
movb $1, %al
ret
source_compare_amoorwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoorwrl:
cmpq $8, source_character_count
jb source_compare_amoorwrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoorwrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoorwrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoorwrl_failure
cmpb $111, 3(%rax)
jne source_compare_amoorwrl_failure
cmpb $114, 4(%rax)
jne source_compare_amoorwrl_failure
cmpb $119, 5(%rax)
jne source_compare_amoorwrl_failure
cmpb $114, 6(%rax)
jne source_compare_amoorwrl_failure
cmpb $108, 7(%rax)
jne source_compare_amoorwrl_failure
cmpq $8, source_character_count
je source_compare_amoorwrl_success
cmpb $10, 8(%rax)
je source_compare_amoorwrl_success
cmpb $32, 8(%rax)
je source_compare_amoorwrl_success
cmpb $35, 8(%rax)
je source_compare_amoorwrl_success
source_compare_amoorwrl_failure:
movb $1, %al
ret
source_compare_amoorwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoswapd:
cmpq $8, source_character_count
jb source_compare_amoswapd_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoswapd_failure
cmpb $109, 1(%rax)
jne source_compare_amoswapd_failure
cmpb $111, 2(%rax)
jne source_compare_amoswapd_failure
cmpb $115, 3(%rax)
jne source_compare_amoswapd_failure
cmpb $119, 4(%rax)
jne source_compare_amoswapd_failure
cmpb $97, 5(%rax)
jne source_compare_amoswapd_failure
cmpb $112, 6(%rax)
jne source_compare_amoswapd_failure
cmpb $100, 7(%rax)
jne source_compare_amoswapd_failure
cmpq $8, source_character_count
je source_compare_amoswapd_success
cmpb $10, 8(%rax)
je source_compare_amoswapd_success
cmpb $32, 8(%rax)
je source_compare_amoswapd_success
cmpb $35, 8(%rax)
je source_compare_amoswapd_success
source_compare_amoswapd_failure:
movb $1, %al
ret
source_compare_amoswapd_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoswapdaq:
cmpq $10, source_character_count
jb source_compare_amoswapdaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoswapdaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoswapdaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoswapdaq_failure
cmpb $115, 3(%rax)
jne source_compare_amoswapdaq_failure
cmpb $119, 4(%rax)
jne source_compare_amoswapdaq_failure
cmpb $97, 5(%rax)
jne source_compare_amoswapdaq_failure
cmpb $112, 6(%rax)
jne source_compare_amoswapdaq_failure
cmpb $100, 7(%rax)
jne source_compare_amoswapdaq_failure
cmpb $97, 8(%rax)
jne source_compare_amoswapdaq_failure
cmpb $113, 9(%rax)
jne source_compare_amoswapdaq_failure
cmpq $10, source_character_count
je source_compare_amoswapdaq_success
cmpb $10, 10(%rax)
je source_compare_amoswapdaq_success
cmpb $32, 10(%rax)
je source_compare_amoswapdaq_success
cmpb $35, 10(%rax)
je source_compare_amoswapdaq_success
source_compare_amoswapdaq_failure:
movb $1, %al
ret
source_compare_amoswapdaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoswapdaqrl:
cmpq $12, source_character_count
jb source_compare_amoswapdaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $115, 3(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $119, 4(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $97, 5(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $112, 6(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $100, 7(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $97, 8(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $113, 9(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $114, 10(%rax)
jne source_compare_amoswapdaqrl_failure
cmpb $108, 11(%rax)
jne source_compare_amoswapdaqrl_failure
cmpq $12, source_character_count
je source_compare_amoswapdaqrl_success
cmpb $10, 12(%rax)
je source_compare_amoswapdaqrl_success
cmpb $32, 12(%rax)
je source_compare_amoswapdaqrl_success
cmpb $35, 12(%rax)
je source_compare_amoswapdaqrl_success
source_compare_amoswapdaqrl_failure:
movb $1, %al
ret
source_compare_amoswapdaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoswapdrl:
cmpq $10, source_character_count
jb source_compare_amoswapdrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoswapdrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoswapdrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoswapdrl_failure
cmpb $115, 3(%rax)
jne source_compare_amoswapdrl_failure
cmpb $119, 4(%rax)
jne source_compare_amoswapdrl_failure
cmpb $97, 5(%rax)
jne source_compare_amoswapdrl_failure
cmpb $112, 6(%rax)
jne source_compare_amoswapdrl_failure
cmpb $100, 7(%rax)
jne source_compare_amoswapdrl_failure
cmpb $114, 8(%rax)
jne source_compare_amoswapdrl_failure
cmpb $108, 9(%rax)
jne source_compare_amoswapdrl_failure
cmpq $10, source_character_count
je source_compare_amoswapdrl_success
cmpb $10, 10(%rax)
je source_compare_amoswapdrl_success
cmpb $32, 10(%rax)
je source_compare_amoswapdrl_success
cmpb $35, 10(%rax)
je source_compare_amoswapdrl_success
source_compare_amoswapdrl_failure:
movb $1, %al
ret
source_compare_amoswapdrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoswapw:
cmpq $8, source_character_count
jb source_compare_amoswapw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoswapw_failure
cmpb $109, 1(%rax)
jne source_compare_amoswapw_failure
cmpb $111, 2(%rax)
jne source_compare_amoswapw_failure
cmpb $115, 3(%rax)
jne source_compare_amoswapw_failure
cmpb $119, 4(%rax)
jne source_compare_amoswapw_failure
cmpb $97, 5(%rax)
jne source_compare_amoswapw_failure
cmpb $112, 6(%rax)
jne source_compare_amoswapw_failure
cmpb $119, 7(%rax)
jne source_compare_amoswapw_failure
cmpq $8, source_character_count
je source_compare_amoswapw_success
cmpb $10, 8(%rax)
je source_compare_amoswapw_success
cmpb $32, 8(%rax)
je source_compare_amoswapw_success
cmpb $35, 8(%rax)
je source_compare_amoswapw_success
source_compare_amoswapw_failure:
movb $1, %al
ret
source_compare_amoswapw_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoswapwaq:
cmpq $10, source_character_count
jb source_compare_amoswapwaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoswapwaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoswapwaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoswapwaq_failure
cmpb $115, 3(%rax)
jne source_compare_amoswapwaq_failure
cmpb $119, 4(%rax)
jne source_compare_amoswapwaq_failure
cmpb $97, 5(%rax)
jne source_compare_amoswapwaq_failure
cmpb $112, 6(%rax)
jne source_compare_amoswapwaq_failure
cmpb $119, 7(%rax)
jne source_compare_amoswapwaq_failure
cmpb $97, 8(%rax)
jne source_compare_amoswapwaq_failure
cmpb $113, 9(%rax)
jne source_compare_amoswapwaq_failure
cmpq $10, source_character_count
je source_compare_amoswapwaq_success
cmpb $10, 10(%rax)
je source_compare_amoswapwaq_success
cmpb $32, 10(%rax)
je source_compare_amoswapwaq_success
cmpb $35, 10(%rax)
je source_compare_amoswapwaq_success
source_compare_amoswapwaq_failure:
movb $1, %al
ret
source_compare_amoswapwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoswapwaqrl:
cmpq $12, source_character_count
jb source_compare_amoswapwaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $115, 3(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $119, 4(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $97, 5(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $112, 6(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $119, 7(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $97, 8(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $113, 9(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $114, 10(%rax)
jne source_compare_amoswapwaqrl_failure
cmpb $108, 11(%rax)
jne source_compare_amoswapwaqrl_failure
cmpq $12, source_character_count
je source_compare_amoswapwaqrl_success
cmpb $10, 12(%rax)
je source_compare_amoswapwaqrl_success
cmpb $32, 12(%rax)
je source_compare_amoswapwaqrl_success
cmpb $35, 12(%rax)
je source_compare_amoswapwaqrl_success
source_compare_amoswapwaqrl_failure:
movb $1, %al
ret
source_compare_amoswapwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoswapwrl:
cmpq $10, source_character_count
jb source_compare_amoswapwrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoswapwrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoswapwrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoswapwrl_failure
cmpb $115, 3(%rax)
jne source_compare_amoswapwrl_failure
cmpb $119, 4(%rax)
jne source_compare_amoswapwrl_failure
cmpb $97, 5(%rax)
jne source_compare_amoswapwrl_failure
cmpb $112, 6(%rax)
jne source_compare_amoswapwrl_failure
cmpb $119, 7(%rax)
jne source_compare_amoswapwrl_failure
cmpb $114, 8(%rax)
jne source_compare_amoswapwrl_failure
cmpb $108, 9(%rax)
jne source_compare_amoswapwrl_failure
cmpq $10, source_character_count
je source_compare_amoswapwrl_success
cmpb $10, 10(%rax)
je source_compare_amoswapwrl_success
cmpb $32, 10(%rax)
je source_compare_amoswapwrl_success
cmpb $35, 10(%rax)
je source_compare_amoswapwrl_success
source_compare_amoswapwrl_failure:
movb $1, %al
ret
source_compare_amoswapwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoxord:
cmpq $7, source_character_count
jb source_compare_amoxord_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoxord_failure
cmpb $109, 1(%rax)
jne source_compare_amoxord_failure
cmpb $111, 2(%rax)
jne source_compare_amoxord_failure
cmpb $120, 3(%rax)
jne source_compare_amoxord_failure
cmpb $111, 4(%rax)
jne source_compare_amoxord_failure
cmpb $114, 5(%rax)
jne source_compare_amoxord_failure
cmpb $100, 6(%rax)
jne source_compare_amoxord_failure
cmpq $7, source_character_count
je source_compare_amoxord_success
cmpb $10, 7(%rax)
je source_compare_amoxord_success
cmpb $32, 7(%rax)
je source_compare_amoxord_success
cmpb $35, 7(%rax)
je source_compare_amoxord_success
source_compare_amoxord_failure:
movb $1, %al
ret
source_compare_amoxord_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoxordaq:
cmpq $9, source_character_count
jb source_compare_amoxordaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoxordaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoxordaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoxordaq_failure
cmpb $120, 3(%rax)
jne source_compare_amoxordaq_failure
cmpb $111, 4(%rax)
jne source_compare_amoxordaq_failure
cmpb $114, 5(%rax)
jne source_compare_amoxordaq_failure
cmpb $100, 6(%rax)
jne source_compare_amoxordaq_failure
cmpb $97, 7(%rax)
jne source_compare_amoxordaq_failure
cmpb $113, 8(%rax)
jne source_compare_amoxordaq_failure
cmpq $9, source_character_count
je source_compare_amoxordaq_success
cmpb $10, 9(%rax)
je source_compare_amoxordaq_success
cmpb $32, 9(%rax)
je source_compare_amoxordaq_success
cmpb $35, 9(%rax)
je source_compare_amoxordaq_success
source_compare_amoxordaq_failure:
movb $1, %al
ret
source_compare_amoxordaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoxordaqrl:
cmpq $11, source_character_count
jb source_compare_amoxordaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoxordaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoxordaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoxordaqrl_failure
cmpb $120, 3(%rax)
jne source_compare_amoxordaqrl_failure
cmpb $111, 4(%rax)
jne source_compare_amoxordaqrl_failure
cmpb $114, 5(%rax)
jne source_compare_amoxordaqrl_failure
cmpb $100, 6(%rax)
jne source_compare_amoxordaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amoxordaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amoxordaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amoxordaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amoxordaqrl_failure
cmpq $11, source_character_count
je source_compare_amoxordaqrl_success
cmpb $10, 11(%rax)
je source_compare_amoxordaqrl_success
cmpb $32, 11(%rax)
je source_compare_amoxordaqrl_success
cmpb $35, 11(%rax)
je source_compare_amoxordaqrl_success
source_compare_amoxordaqrl_failure:
movb $1, %al
ret
source_compare_amoxordaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoxordrl:
cmpq $9, source_character_count
jb source_compare_amoxordrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoxordrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoxordrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoxordrl_failure
cmpb $120, 3(%rax)
jne source_compare_amoxordrl_failure
cmpb $111, 4(%rax)
jne source_compare_amoxordrl_failure
cmpb $114, 5(%rax)
jne source_compare_amoxordrl_failure
cmpb $100, 6(%rax)
jne source_compare_amoxordrl_failure
cmpb $114, 7(%rax)
jne source_compare_amoxordrl_failure
cmpb $108, 8(%rax)
jne source_compare_amoxordrl_failure
cmpq $9, source_character_count
je source_compare_amoxordrl_success
cmpb $10, 9(%rax)
je source_compare_amoxordrl_success
cmpb $32, 9(%rax)
je source_compare_amoxordrl_success
cmpb $35, 9(%rax)
je source_compare_amoxordrl_success
source_compare_amoxordrl_failure:
movb $1, %al
ret
source_compare_amoxordrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoxorw:
cmpq $7, source_character_count
jb source_compare_amoxorw_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoxorw_failure
cmpb $109, 1(%rax)
jne source_compare_amoxorw_failure
cmpb $111, 2(%rax)
jne source_compare_amoxorw_failure
cmpb $120, 3(%rax)
jne source_compare_amoxorw_failure
cmpb $111, 4(%rax)
jne source_compare_amoxorw_failure
cmpb $114, 5(%rax)
jne source_compare_amoxorw_failure
cmpb $119, 6(%rax)
jne source_compare_amoxorw_failure
cmpq $7, source_character_count
je source_compare_amoxorw_success
cmpb $10, 7(%rax)
je source_compare_amoxorw_success
cmpb $32, 7(%rax)
je source_compare_amoxorw_success
cmpb $35, 7(%rax)
je source_compare_amoxorw_success
source_compare_amoxorw_failure:
movb $1, %al
ret
source_compare_amoxorw_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoxorwaq:
cmpq $9, source_character_count
jb source_compare_amoxorwaq_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoxorwaq_failure
cmpb $109, 1(%rax)
jne source_compare_amoxorwaq_failure
cmpb $111, 2(%rax)
jne source_compare_amoxorwaq_failure
cmpb $120, 3(%rax)
jne source_compare_amoxorwaq_failure
cmpb $111, 4(%rax)
jne source_compare_amoxorwaq_failure
cmpb $114, 5(%rax)
jne source_compare_amoxorwaq_failure
cmpb $119, 6(%rax)
jne source_compare_amoxorwaq_failure
cmpb $97, 7(%rax)
jne source_compare_amoxorwaq_failure
cmpb $113, 8(%rax)
jne source_compare_amoxorwaq_failure
cmpq $9, source_character_count
je source_compare_amoxorwaq_success
cmpb $10, 9(%rax)
je source_compare_amoxorwaq_success
cmpb $32, 9(%rax)
je source_compare_amoxorwaq_success
cmpb $35, 9(%rax)
je source_compare_amoxorwaq_success
source_compare_amoxorwaq_failure:
movb $1, %al
ret
source_compare_amoxorwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoxorwaqrl:
cmpq $11, source_character_count
jb source_compare_amoxorwaqrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $120, 3(%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $111, 4(%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $114, 5(%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $119, 6(%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $97, 7(%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $113, 8(%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $114, 9(%rax)
jne source_compare_amoxorwaqrl_failure
cmpb $108, 10(%rax)
jne source_compare_amoxorwaqrl_failure
cmpq $11, source_character_count
je source_compare_amoxorwaqrl_success
cmpb $10, 11(%rax)
je source_compare_amoxorwaqrl_success
cmpb $32, 11(%rax)
je source_compare_amoxorwaqrl_success
cmpb $35, 11(%rax)
je source_compare_amoxorwaqrl_success
source_compare_amoxorwaqrl_failure:
movb $1, %al
ret
source_compare_amoxorwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_amoxorwrl:
cmpq $9, source_character_count
jb source_compare_amoxorwrl_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_amoxorwrl_failure
cmpb $109, 1(%rax)
jne source_compare_amoxorwrl_failure
cmpb $111, 2(%rax)
jne source_compare_amoxorwrl_failure
cmpb $120, 3(%rax)
jne source_compare_amoxorwrl_failure
cmpb $111, 4(%rax)
jne source_compare_amoxorwrl_failure
cmpb $114, 5(%rax)
jne source_compare_amoxorwrl_failure
cmpb $119, 6(%rax)
jne source_compare_amoxorwrl_failure
cmpb $114, 7(%rax)
jne source_compare_amoxorwrl_failure
cmpb $108, 8(%rax)
jne source_compare_amoxorwrl_failure
cmpq $9, source_character_count
je source_compare_amoxorwrl_success
cmpb $10, 9(%rax)
je source_compare_amoxorwrl_success
cmpb $32, 9(%rax)
je source_compare_amoxorwrl_success
cmpb $35, 9(%rax)
je source_compare_amoxorwrl_success
source_compare_amoxorwrl_failure:
movb $1, %al
ret
source_compare_amoxorwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_and:
cmpq $3, source_character_count
jb source_compare_and_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_and_failure
cmpb $110, 1(%rax)
jne source_compare_and_failure
cmpb $100, 2(%rax)
jne source_compare_and_failure
cmpq $3, source_character_count
je source_compare_and_success
cmpb $10, 3(%rax)
je source_compare_and_success
cmpb $32, 3(%rax)
je source_compare_and_success
cmpb $35, 3(%rax)
je source_compare_and_success
source_compare_and_failure:
movb $1, %al
ret
source_compare_and_success:
xorb %al, %al
ret


# out
# al status
source_compare_andi:
cmpq $4, source_character_count
jb source_compare_andi_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_andi_failure
cmpb $110, 1(%rax)
jne source_compare_andi_failure
cmpb $100, 2(%rax)
jne source_compare_andi_failure
cmpb $105, 3(%rax)
jne source_compare_andi_failure
cmpq $4, source_character_count
je source_compare_andi_success
cmpb $10, 4(%rax)
je source_compare_andi_success
cmpb $32, 4(%rax)
je source_compare_andi_success
cmpb $35, 4(%rax)
je source_compare_andi_success
source_compare_andi_failure:
movb $1, %al
ret
source_compare_andi_success:
xorb %al, %al
ret


# out
# al status
source_compare_auipc:
cmpq $5, source_character_count
jb source_compare_auipc_failure
movq source_character_address, %rax
cmpb $97, (%rax)
jne source_compare_auipc_failure
cmpb $117, 1(%rax)
jne source_compare_auipc_failure
cmpb $105, 2(%rax)
jne source_compare_auipc_failure
cmpb $112, 3(%rax)
jne source_compare_auipc_failure
cmpb $99, 4(%rax)
jne source_compare_auipc_failure
cmpq $5, source_character_count
je source_compare_auipc_success
cmpb $10, 5(%rax)
je source_compare_auipc_success
cmpb $32, 5(%rax)
je source_compare_auipc_success
cmpb $35, 5(%rax)
je source_compare_auipc_success
source_compare_auipc_failure:
movb $1, %al
ret
source_compare_auipc_success:
xorb %al, %al
ret


# out
# al status
source_compare_beq:
cmpq $3, source_character_count
jb source_compare_beq_failure
movq source_character_address, %rax
cmpb $98, (%rax)
jne source_compare_beq_failure
cmpb $101, 1(%rax)
jne source_compare_beq_failure
cmpb $113, 2(%rax)
jne source_compare_beq_failure
cmpq $3, source_character_count
je source_compare_beq_success
cmpb $10, 3(%rax)
je source_compare_beq_success
cmpb $32, 3(%rax)
je source_compare_beq_success
cmpb $35, 3(%rax)
je source_compare_beq_success
source_compare_beq_failure:
movb $1, %al
ret
source_compare_beq_success:
xorb %al, %al
ret


# out
# al status
source_compare_bge:
cmpq $3, source_character_count
jb source_compare_bge_failure
movq source_character_address, %rax
cmpb $98, (%rax)
jne source_compare_bge_failure
cmpb $103, 1(%rax)
jne source_compare_bge_failure
cmpb $101, 2(%rax)
jne source_compare_bge_failure
cmpq $3, source_character_count
je source_compare_bge_success
cmpb $10, 3(%rax)
je source_compare_bge_success
cmpb $32, 3(%rax)
je source_compare_bge_success
cmpb $35, 3(%rax)
je source_compare_bge_success
source_compare_bge_failure:
movb $1, %al
ret
source_compare_bge_success:
xorb %al, %al
ret


# out
# al status
source_compare_bgeu:
cmpq $4, source_character_count
jb source_compare_bgeu_failure
movq source_character_address, %rax
cmpb $98, (%rax)
jne source_compare_bgeu_failure
cmpb $103, 1(%rax)
jne source_compare_bgeu_failure
cmpb $101, 2(%rax)
jne source_compare_bgeu_failure
cmpb $117, 3(%rax)
jne source_compare_bgeu_failure
cmpq $4, source_character_count
je source_compare_bgeu_success
cmpb $10, 4(%rax)
je source_compare_bgeu_success
cmpb $32, 4(%rax)
je source_compare_bgeu_success
cmpb $35, 4(%rax)
je source_compare_bgeu_success
source_compare_bgeu_failure:
movb $1, %al
ret
source_compare_bgeu_success:
xorb %al, %al
ret


# out
# al status
source_compare_blt:
cmpq $3, source_character_count
jb source_compare_blt_failure
movq source_character_address, %rax
cmpb $98, (%rax)
jne source_compare_blt_failure
cmpb $108, 1(%rax)
jne source_compare_blt_failure
cmpb $116, 2(%rax)
jne source_compare_blt_failure
cmpq $3, source_character_count
je source_compare_blt_success
cmpb $10, 3(%rax)
je source_compare_blt_success
cmpb $32, 3(%rax)
je source_compare_blt_success
cmpb $35, 3(%rax)
je source_compare_blt_success
source_compare_blt_failure:
movb $1, %al
ret
source_compare_blt_success:
xorb %al, %al
ret


# out
# al status
source_compare_bltu:
cmpq $4, source_character_count
jb source_compare_bltu_failure
movq source_character_address, %rax
cmpb $98, (%rax)
jne source_compare_bltu_failure
cmpb $108, 1(%rax)
jne source_compare_bltu_failure
cmpb $116, 2(%rax)
jne source_compare_bltu_failure
cmpb $117, 3(%rax)
jne source_compare_bltu_failure
cmpq $4, source_character_count
je source_compare_bltu_success
cmpb $10, 4(%rax)
je source_compare_bltu_success
cmpb $32, 4(%rax)
je source_compare_bltu_success
cmpb $35, 4(%rax)
je source_compare_bltu_success
source_compare_bltu_failure:
movb $1, %al
ret
source_compare_bltu_success:
xorb %al, %al
ret


# out
# al status
source_compare_bne:
cmpq $3, source_character_count
jb source_compare_bne_failure
movq source_character_address, %rax
cmpb $98, (%rax)
jne source_compare_bne_failure
cmpb $110, 1(%rax)
jne source_compare_bne_failure
cmpb $101, 2(%rax)
jne source_compare_bne_failure
cmpq $3, source_character_count
je source_compare_bne_success
cmpb $10, 3(%rax)
je source_compare_bne_success
cmpb $32, 3(%rax)
je source_compare_bne_success
cmpb $35, 3(%rax)
je source_compare_bne_success
source_compare_bne_failure:
movb $1, %al
ret
source_compare_bne_success:
xorb %al, %al
ret


# out
# al status
source_compare_byte:
cmpq $4, source_character_count
jb source_compare_byte_failure
movq source_character_address, %rax
cmpb $98, (%rax)
jne source_compare_byte_failure
cmpb $121, 1(%rax)
jne source_compare_byte_failure
cmpb $116, 2(%rax)
jne source_compare_byte_failure
cmpb $101, 3(%rax)
jne source_compare_byte_failure
cmpq $4, source_character_count
je source_compare_byte_success
cmpb $10, 4(%rax)
je source_compare_byte_success
cmpb $32, 4(%rax)
je source_compare_byte_success
cmpb $35, 4(%rax)
je source_compare_byte_success
source_compare_byte_failure:
movb $1, %al
ret
source_compare_byte_success:
xorb %al, %al
ret


# out
# al status
source_compare_call:
cmpq $4, source_character_count
jb source_compare_call_failure
movq source_character_address, %rax
cmpb $99, (%rax)
jne source_compare_call_failure
cmpb $97, 1(%rax)
jne source_compare_call_failure
cmpb $108, 2(%rax)
jne source_compare_call_failure
cmpb $108, 3(%rax)
jne source_compare_call_failure
cmpq $4, source_character_count
je source_compare_call_success
cmpb $10, 4(%rax)
je source_compare_call_success
cmpb $32, 4(%rax)
je source_compare_call_success
cmpb $35, 4(%rax)
je source_compare_call_success
source_compare_call_failure:
movb $1, %al
ret
source_compare_call_success:
xorb %al, %al
ret


# out
# al status
source_compare_constant:
cmpq $8, source_character_count
jb source_compare_constant_failure
movq source_character_address, %rax
cmpb $99, (%rax)
jne source_compare_constant_failure
cmpb $111, 1(%rax)
jne source_compare_constant_failure
cmpb $110, 2(%rax)
jne source_compare_constant_failure
cmpb $115, 3(%rax)
jne source_compare_constant_failure
cmpb $116, 4(%rax)
jne source_compare_constant_failure
cmpb $97, 5(%rax)
jne source_compare_constant_failure
cmpb $110, 6(%rax)
jne source_compare_constant_failure
cmpb $116, 7(%rax)
jne source_compare_constant_failure
cmpq $8, source_character_count
je source_compare_constant_success
cmpb $10, 8(%rax)
je source_compare_constant_success
cmpb $32, 8(%rax)
je source_compare_constant_success
cmpb $35, 8(%rax)
je source_compare_constant_success
source_compare_constant_failure:
movb $1, %al
ret
source_compare_constant_success:
xorb %al, %al
ret


# out
# al status
source_compare_csrrc:
cmpq $5, source_character_count
jb source_compare_csrrc_failure
movq source_character_address, %rax
cmpb $99, (%rax)
jne source_compare_csrrc_failure
cmpb $115, 1(%rax)
jne source_compare_csrrc_failure
cmpb $114, 2(%rax)
jne source_compare_csrrc_failure
cmpb $114, 3(%rax)
jne source_compare_csrrc_failure
cmpb $99, 4(%rax)
jne source_compare_csrrc_failure
cmpq $5, source_character_count
je source_compare_csrrc_success
cmpb $10, 5(%rax)
je source_compare_csrrc_success
cmpb $32, 5(%rax)
je source_compare_csrrc_success
cmpb $35, 5(%rax)
je source_compare_csrrc_success
source_compare_csrrc_failure:
movb $1, %al
ret
source_compare_csrrc_success:
xorb %al, %al
ret


# out
# al status
source_compare_csrrci:
cmpq $6, source_character_count
jb source_compare_csrrci_failure
movq source_character_address, %rax
cmpb $99, (%rax)
jne source_compare_csrrci_failure
cmpb $115, 1(%rax)
jne source_compare_csrrci_failure
cmpb $114, 2(%rax)
jne source_compare_csrrci_failure
cmpb $114, 3(%rax)
jne source_compare_csrrci_failure
cmpb $99, 4(%rax)
jne source_compare_csrrci_failure
cmpb $105, 5(%rax)
jne source_compare_csrrci_failure
cmpq $6, source_character_count
je source_compare_csrrci_success
cmpb $10, 6(%rax)
je source_compare_csrrci_success
cmpb $32, 6(%rax)
je source_compare_csrrci_success
cmpb $35, 6(%rax)
je source_compare_csrrci_success
source_compare_csrrci_failure:
movb $1, %al
ret
source_compare_csrrci_success:
xorb %al, %al
ret


# out
# al status
source_compare_csrrs:
cmpq $5, source_character_count
jb source_compare_csrrs_failure
movq source_character_address, %rax
cmpb $99, (%rax)
jne source_compare_csrrs_failure
cmpb $115, 1(%rax)
jne source_compare_csrrs_failure
cmpb $114, 2(%rax)
jne source_compare_csrrs_failure
cmpb $114, 3(%rax)
jne source_compare_csrrs_failure
cmpb $115, 4(%rax)
jne source_compare_csrrs_failure
cmpq $5, source_character_count
je source_compare_csrrs_success
cmpb $10, 5(%rax)
je source_compare_csrrs_success
cmpb $32, 5(%rax)
je source_compare_csrrs_success
cmpb $35, 5(%rax)
je source_compare_csrrs_success
source_compare_csrrs_failure:
movb $1, %al
ret
source_compare_csrrs_success:
xorb %al, %al
ret


# out
# al status
source_compare_csrrsi:
cmpq $6, source_character_count
jb source_compare_csrrsi_failure
movq source_character_address, %rax
cmpb $99, (%rax)
jne source_compare_csrrsi_failure
cmpb $115, 1(%rax)
jne source_compare_csrrsi_failure
cmpb $114, 2(%rax)
jne source_compare_csrrsi_failure
cmpb $114, 3(%rax)
jne source_compare_csrrsi_failure
cmpb $115, 4(%rax)
jne source_compare_csrrsi_failure
cmpb $105, 5(%rax)
jne source_compare_csrrsi_failure
cmpq $6, source_character_count
je source_compare_csrrsi_success
cmpb $10, 6(%rax)
je source_compare_csrrsi_success
cmpb $32, 6(%rax)
je source_compare_csrrsi_success
cmpb $35, 6(%rax)
je source_compare_csrrsi_success
source_compare_csrrsi_failure:
movb $1, %al
ret
source_compare_csrrsi_success:
xorb %al, %al
ret


# out
# al status
source_compare_csrrw:
cmpq $5, source_character_count
jb source_compare_csrrw_failure
movq source_character_address, %rax
cmpb $99, (%rax)
jne source_compare_csrrw_failure
cmpb $115, 1(%rax)
jne source_compare_csrrw_failure
cmpb $114, 2(%rax)
jne source_compare_csrrw_failure
cmpb $114, 3(%rax)
jne source_compare_csrrw_failure
cmpb $119, 4(%rax)
jne source_compare_csrrw_failure
cmpq $5, source_character_count
je source_compare_csrrw_success
cmpb $10, 5(%rax)
je source_compare_csrrw_success
cmpb $32, 5(%rax)
je source_compare_csrrw_success
cmpb $35, 5(%rax)
je source_compare_csrrw_success
source_compare_csrrw_failure:
movb $1, %al
ret
source_compare_csrrw_success:
xorb %al, %al
ret


# out
# al status
source_compare_csrrwi:
cmpq $6, source_character_count
jb source_compare_csrrwi_failure
movq source_character_address, %rax
cmpb $99, (%rax)
jne source_compare_csrrwi_failure
cmpb $115, 1(%rax)
jne source_compare_csrrwi_failure
cmpb $114, 2(%rax)
jne source_compare_csrrwi_failure
cmpb $114, 3(%rax)
jne source_compare_csrrwi_failure
cmpb $119, 4(%rax)
jne source_compare_csrrwi_failure
cmpb $105, 5(%rax)
jne source_compare_csrrwi_failure
cmpq $6, source_character_count
je source_compare_csrrwi_success
cmpb $10, 6(%rax)
je source_compare_csrrwi_success
cmpb $32, 6(%rax)
je source_compare_csrrwi_success
cmpb $35, 6(%rax)
je source_compare_csrrwi_success
source_compare_csrrwi_failure:
movb $1, %al
ret
source_compare_csrrwi_success:
xorb %al, %al
ret


# out
# al status
source_compare_div:
cmpq $3, source_character_count
jb source_compare_div_failure
movq source_character_address, %rax
cmpb $100, (%rax)
jne source_compare_div_failure
cmpb $105, 1(%rax)
jne source_compare_div_failure
cmpb $118, 2(%rax)
jne source_compare_div_failure
cmpq $3, source_character_count
je source_compare_div_success
cmpb $10, 3(%rax)
je source_compare_div_success
cmpb $32, 3(%rax)
je source_compare_div_success
cmpb $35, 3(%rax)
je source_compare_div_success
source_compare_div_failure:
movb $1, %al
ret
source_compare_div_success:
xorb %al, %al
ret


# out
# al status
source_compare_divu:
cmpq $4, source_character_count
jb source_compare_divu_failure
movq source_character_address, %rax
cmpb $100, (%rax)
jne source_compare_divu_failure
cmpb $105, 1(%rax)
jne source_compare_divu_failure
cmpb $118, 2(%rax)
jne source_compare_divu_failure
cmpb $117, 3(%rax)
jne source_compare_divu_failure
cmpq $4, source_character_count
je source_compare_divu_success
cmpb $10, 4(%rax)
je source_compare_divu_success
cmpb $32, 4(%rax)
je source_compare_divu_success
cmpb $35, 4(%rax)
je source_compare_divu_success
source_compare_divu_failure:
movb $1, %al
ret
source_compare_divu_success:
xorb %al, %al
ret


# out
# al status
source_compare_divuw:
cmpq $5, source_character_count
jb source_compare_divuw_failure
movq source_character_address, %rax
cmpb $100, (%rax)
jne source_compare_divuw_failure
cmpb $105, 1(%rax)
jne source_compare_divuw_failure
cmpb $118, 2(%rax)
jne source_compare_divuw_failure
cmpb $117, 3(%rax)
jne source_compare_divuw_failure
cmpb $119, 4(%rax)
jne source_compare_divuw_failure
cmpq $5, source_character_count
je source_compare_divuw_success
cmpb $10, 5(%rax)
je source_compare_divuw_success
cmpb $32, 5(%rax)
je source_compare_divuw_success
cmpb $35, 5(%rax)
je source_compare_divuw_success
source_compare_divuw_failure:
movb $1, %al
ret
source_compare_divuw_success:
xorb %al, %al
ret


# out
# al status
source_compare_divw:
cmpq $4, source_character_count
jb source_compare_divw_failure
movq source_character_address, %rax
cmpb $100, (%rax)
jne source_compare_divw_failure
cmpb $105, 1(%rax)
jne source_compare_divw_failure
cmpb $118, 2(%rax)
jne source_compare_divw_failure
cmpb $119, 3(%rax)
jne source_compare_divw_failure
cmpq $4, source_character_count
je source_compare_divw_success
cmpb $10, 4(%rax)
je source_compare_divw_success
cmpb $32, 4(%rax)
je source_compare_divw_success
cmpb $35, 4(%rax)
je source_compare_divw_success
source_compare_divw_failure:
movb $1, %al
ret
source_compare_divw_success:
xorb %al, %al
ret


# out
# al status
source_compare_doubleword:
cmpq $10, source_character_count
jb source_compare_doubleword_failure
movq source_character_address, %rax
cmpb $100, (%rax)
jne source_compare_doubleword_failure
cmpb $111, 1(%rax)
jne source_compare_doubleword_failure
cmpb $117, 2(%rax)
jne source_compare_doubleword_failure
cmpb $98, 3(%rax)
jne source_compare_doubleword_failure
cmpb $108, 4(%rax)
jne source_compare_doubleword_failure
cmpb $101, 5(%rax)
jne source_compare_doubleword_failure
cmpb $119, 6(%rax)
jne source_compare_doubleword_failure
cmpb $111, 7(%rax)
jne source_compare_doubleword_failure
cmpb $114, 8(%rax)
jne source_compare_doubleword_failure
cmpb $100, 9(%rax)
jne source_compare_doubleword_failure
cmpq $10, source_character_count
je source_compare_doubleword_success
cmpb $10, 10(%rax)
je source_compare_doubleword_success
cmpb $32, 10(%rax)
je source_compare_doubleword_success
cmpb $35, 10(%rax)
je source_compare_doubleword_success
source_compare_doubleword_failure:
movb $1, %al
ret
source_compare_doubleword_success:
xorb %al, %al
ret


# out
# al status
source_compare_ebreak:
cmpq $6, source_character_count
jb source_compare_ebreak_failure
movq source_character_address, %rax
cmpb $101, (%rax)
jne source_compare_ebreak_failure
cmpb $98, 1(%rax)
jne source_compare_ebreak_failure
cmpb $114, 2(%rax)
jne source_compare_ebreak_failure
cmpb $101, 3(%rax)
jne source_compare_ebreak_failure
cmpb $97, 4(%rax)
jne source_compare_ebreak_failure
cmpb $107, 5(%rax)
jne source_compare_ebreak_failure
cmpq $6, source_character_count
je source_compare_ebreak_success
cmpb $10, 6(%rax)
je source_compare_ebreak_success
cmpb $32, 6(%rax)
je source_compare_ebreak_success
cmpb $35, 6(%rax)
je source_compare_ebreak_success
source_compare_ebreak_failure:
movb $1, %al
ret
source_compare_ebreak_success:
xorb %al, %al
ret


# out
# al status
source_compare_ecall:
cmpq $5, source_character_count
jb source_compare_ecall_failure
movq source_character_address, %rax
cmpb $101, (%rax)
jne source_compare_ecall_failure
cmpb $99, 1(%rax)
jne source_compare_ecall_failure
cmpb $97, 2(%rax)
jne source_compare_ecall_failure
cmpb $108, 3(%rax)
jne source_compare_ecall_failure
cmpb $108, 4(%rax)
jne source_compare_ecall_failure
cmpq $5, source_character_count
je source_compare_ecall_success
cmpb $10, 5(%rax)
je source_compare_ecall_success
cmpb $32, 5(%rax)
je source_compare_ecall_success
cmpb $35, 5(%rax)
je source_compare_ecall_success
source_compare_ecall_failure:
movb $1, %al
ret
source_compare_ecall_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddd:
cmpq $5, source_character_count
jb source_compare_faddd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddd_failure
cmpb $97, 1(%rax)
jne source_compare_faddd_failure
cmpb $100, 2(%rax)
jne source_compare_faddd_failure
cmpb $100, 3(%rax)
jne source_compare_faddd_failure
cmpb $100, 4(%rax)
jne source_compare_faddd_failure
cmpq $5, source_character_count
je source_compare_faddd_success
cmpb $10, 5(%rax)
je source_compare_faddd_success
cmpb $32, 5(%rax)
je source_compare_faddd_success
cmpb $35, 5(%rax)
je source_compare_faddd_success
source_compare_faddd_failure:
movb $1, %al
ret
source_compare_faddd_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddddyn:
cmpq $8, source_character_count
jb source_compare_faddddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddddyn_failure
cmpb $97, 1(%rax)
jne source_compare_faddddyn_failure
cmpb $100, 2(%rax)
jne source_compare_faddddyn_failure
cmpb $100, 3(%rax)
jne source_compare_faddddyn_failure
cmpb $100, 4(%rax)
jne source_compare_faddddyn_failure
cmpb $100, 5(%rax)
jne source_compare_faddddyn_failure
cmpb $121, 6(%rax)
jne source_compare_faddddyn_failure
cmpb $110, 7(%rax)
jne source_compare_faddddyn_failure
cmpq $8, source_character_count
je source_compare_faddddyn_success
cmpb $10, 8(%rax)
je source_compare_faddddyn_success
cmpb $32, 8(%rax)
je source_compare_faddddyn_success
cmpb $35, 8(%rax)
je source_compare_faddddyn_success
source_compare_faddddyn_failure:
movb $1, %al
ret
source_compare_faddddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fadddrdn:
cmpq $8, source_character_count
jb source_compare_fadddrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fadddrdn_failure
cmpb $97, 1(%rax)
jne source_compare_fadddrdn_failure
cmpb $100, 2(%rax)
jne source_compare_fadddrdn_failure
cmpb $100, 3(%rax)
jne source_compare_fadddrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fadddrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fadddrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fadddrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fadddrdn_failure
cmpq $8, source_character_count
je source_compare_fadddrdn_success
cmpb $10, 8(%rax)
je source_compare_fadddrdn_success
cmpb $32, 8(%rax)
je source_compare_fadddrdn_success
cmpb $35, 8(%rax)
je source_compare_fadddrdn_success
source_compare_fadddrdn_failure:
movb $1, %al
ret
source_compare_fadddrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fadddrmm:
cmpq $8, source_character_count
jb source_compare_fadddrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fadddrmm_failure
cmpb $97, 1(%rax)
jne source_compare_fadddrmm_failure
cmpb $100, 2(%rax)
jne source_compare_fadddrmm_failure
cmpb $100, 3(%rax)
jne source_compare_fadddrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fadddrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fadddrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fadddrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fadddrmm_failure
cmpq $8, source_character_count
je source_compare_fadddrmm_success
cmpb $10, 8(%rax)
je source_compare_fadddrmm_success
cmpb $32, 8(%rax)
je source_compare_fadddrmm_success
cmpb $35, 8(%rax)
je source_compare_fadddrmm_success
source_compare_fadddrmm_failure:
movb $1, %al
ret
source_compare_fadddrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fadddrtz:
cmpq $8, source_character_count
jb source_compare_fadddrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fadddrtz_failure
cmpb $97, 1(%rax)
jne source_compare_fadddrtz_failure
cmpb $100, 2(%rax)
jne source_compare_fadddrtz_failure
cmpb $100, 3(%rax)
jne source_compare_fadddrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fadddrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fadddrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fadddrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fadddrtz_failure
cmpq $8, source_character_count
je source_compare_fadddrtz_success
cmpb $10, 8(%rax)
je source_compare_fadddrtz_success
cmpb $32, 8(%rax)
je source_compare_fadddrtz_success
cmpb $35, 8(%rax)
je source_compare_fadddrtz_success
source_compare_fadddrtz_failure:
movb $1, %al
ret
source_compare_fadddrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fadddrup:
cmpq $8, source_character_count
jb source_compare_fadddrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fadddrup_failure
cmpb $97, 1(%rax)
jne source_compare_fadddrup_failure
cmpb $100, 2(%rax)
jne source_compare_fadddrup_failure
cmpb $100, 3(%rax)
jne source_compare_fadddrup_failure
cmpb $100, 4(%rax)
jne source_compare_fadddrup_failure
cmpb $114, 5(%rax)
jne source_compare_fadddrup_failure
cmpb $117, 6(%rax)
jne source_compare_fadddrup_failure
cmpb $112, 7(%rax)
jne source_compare_fadddrup_failure
cmpq $8, source_character_count
je source_compare_fadddrup_success
cmpb $10, 8(%rax)
je source_compare_fadddrup_success
cmpb $32, 8(%rax)
je source_compare_fadddrup_success
cmpb $35, 8(%rax)
je source_compare_fadddrup_success
source_compare_fadddrup_failure:
movb $1, %al
ret
source_compare_fadddrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddq:
cmpq $5, source_character_count
jb source_compare_faddq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddq_failure
cmpb $97, 1(%rax)
jne source_compare_faddq_failure
cmpb $100, 2(%rax)
jne source_compare_faddq_failure
cmpb $100, 3(%rax)
jne source_compare_faddq_failure
cmpb $113, 4(%rax)
jne source_compare_faddq_failure
cmpq $5, source_character_count
je source_compare_faddq_success
cmpb $10, 5(%rax)
je source_compare_faddq_success
cmpb $32, 5(%rax)
je source_compare_faddq_success
cmpb $35, 5(%rax)
je source_compare_faddq_success
source_compare_faddq_failure:
movb $1, %al
ret
source_compare_faddq_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddqdyn:
cmpq $8, source_character_count
jb source_compare_faddqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddqdyn_failure
cmpb $97, 1(%rax)
jne source_compare_faddqdyn_failure
cmpb $100, 2(%rax)
jne source_compare_faddqdyn_failure
cmpb $100, 3(%rax)
jne source_compare_faddqdyn_failure
cmpb $113, 4(%rax)
jne source_compare_faddqdyn_failure
cmpb $100, 5(%rax)
jne source_compare_faddqdyn_failure
cmpb $121, 6(%rax)
jne source_compare_faddqdyn_failure
cmpb $110, 7(%rax)
jne source_compare_faddqdyn_failure
cmpq $8, source_character_count
je source_compare_faddqdyn_success
cmpb $10, 8(%rax)
je source_compare_faddqdyn_success
cmpb $32, 8(%rax)
je source_compare_faddqdyn_success
cmpb $35, 8(%rax)
je source_compare_faddqdyn_success
source_compare_faddqdyn_failure:
movb $1, %al
ret
source_compare_faddqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddqrdn:
cmpq $8, source_character_count
jb source_compare_faddqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddqrdn_failure
cmpb $97, 1(%rax)
jne source_compare_faddqrdn_failure
cmpb $100, 2(%rax)
jne source_compare_faddqrdn_failure
cmpb $100, 3(%rax)
jne source_compare_faddqrdn_failure
cmpb $113, 4(%rax)
jne source_compare_faddqrdn_failure
cmpb $114, 5(%rax)
jne source_compare_faddqrdn_failure
cmpb $100, 6(%rax)
jne source_compare_faddqrdn_failure
cmpb $110, 7(%rax)
jne source_compare_faddqrdn_failure
cmpq $8, source_character_count
je source_compare_faddqrdn_success
cmpb $10, 8(%rax)
je source_compare_faddqrdn_success
cmpb $32, 8(%rax)
je source_compare_faddqrdn_success
cmpb $35, 8(%rax)
je source_compare_faddqrdn_success
source_compare_faddqrdn_failure:
movb $1, %al
ret
source_compare_faddqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddqrmm:
cmpq $8, source_character_count
jb source_compare_faddqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddqrmm_failure
cmpb $97, 1(%rax)
jne source_compare_faddqrmm_failure
cmpb $100, 2(%rax)
jne source_compare_faddqrmm_failure
cmpb $100, 3(%rax)
jne source_compare_faddqrmm_failure
cmpb $113, 4(%rax)
jne source_compare_faddqrmm_failure
cmpb $114, 5(%rax)
jne source_compare_faddqrmm_failure
cmpb $109, 6(%rax)
jne source_compare_faddqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_faddqrmm_failure
cmpq $8, source_character_count
je source_compare_faddqrmm_success
cmpb $10, 8(%rax)
je source_compare_faddqrmm_success
cmpb $32, 8(%rax)
je source_compare_faddqrmm_success
cmpb $35, 8(%rax)
je source_compare_faddqrmm_success
source_compare_faddqrmm_failure:
movb $1, %al
ret
source_compare_faddqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddqrtz:
cmpq $8, source_character_count
jb source_compare_faddqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddqrtz_failure
cmpb $97, 1(%rax)
jne source_compare_faddqrtz_failure
cmpb $100, 2(%rax)
jne source_compare_faddqrtz_failure
cmpb $100, 3(%rax)
jne source_compare_faddqrtz_failure
cmpb $113, 4(%rax)
jne source_compare_faddqrtz_failure
cmpb $114, 5(%rax)
jne source_compare_faddqrtz_failure
cmpb $116, 6(%rax)
jne source_compare_faddqrtz_failure
cmpb $122, 7(%rax)
jne source_compare_faddqrtz_failure
cmpq $8, source_character_count
je source_compare_faddqrtz_success
cmpb $10, 8(%rax)
je source_compare_faddqrtz_success
cmpb $32, 8(%rax)
je source_compare_faddqrtz_success
cmpb $35, 8(%rax)
je source_compare_faddqrtz_success
source_compare_faddqrtz_failure:
movb $1, %al
ret
source_compare_faddqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddqrup:
cmpq $8, source_character_count
jb source_compare_faddqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddqrup_failure
cmpb $97, 1(%rax)
jne source_compare_faddqrup_failure
cmpb $100, 2(%rax)
jne source_compare_faddqrup_failure
cmpb $100, 3(%rax)
jne source_compare_faddqrup_failure
cmpb $113, 4(%rax)
jne source_compare_faddqrup_failure
cmpb $114, 5(%rax)
jne source_compare_faddqrup_failure
cmpb $117, 6(%rax)
jne source_compare_faddqrup_failure
cmpb $112, 7(%rax)
jne source_compare_faddqrup_failure
cmpq $8, source_character_count
je source_compare_faddqrup_success
cmpb $10, 8(%rax)
je source_compare_faddqrup_success
cmpb $32, 8(%rax)
je source_compare_faddqrup_success
cmpb $35, 8(%rax)
je source_compare_faddqrup_success
source_compare_faddqrup_failure:
movb $1, %al
ret
source_compare_faddqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fadds:
cmpq $5, source_character_count
jb source_compare_fadds_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fadds_failure
cmpb $97, 1(%rax)
jne source_compare_fadds_failure
cmpb $100, 2(%rax)
jne source_compare_fadds_failure
cmpb $100, 3(%rax)
jne source_compare_fadds_failure
cmpb $115, 4(%rax)
jne source_compare_fadds_failure
cmpq $5, source_character_count
je source_compare_fadds_success
cmpb $10, 5(%rax)
je source_compare_fadds_success
cmpb $32, 5(%rax)
je source_compare_fadds_success
cmpb $35, 5(%rax)
je source_compare_fadds_success
source_compare_fadds_failure:
movb $1, %al
ret
source_compare_fadds_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddsdyn:
cmpq $8, source_character_count
jb source_compare_faddsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddsdyn_failure
cmpb $97, 1(%rax)
jne source_compare_faddsdyn_failure
cmpb $100, 2(%rax)
jne source_compare_faddsdyn_failure
cmpb $100, 3(%rax)
jne source_compare_faddsdyn_failure
cmpb $115, 4(%rax)
jne source_compare_faddsdyn_failure
cmpb $100, 5(%rax)
jne source_compare_faddsdyn_failure
cmpb $121, 6(%rax)
jne source_compare_faddsdyn_failure
cmpb $110, 7(%rax)
jne source_compare_faddsdyn_failure
cmpq $8, source_character_count
je source_compare_faddsdyn_success
cmpb $10, 8(%rax)
je source_compare_faddsdyn_success
cmpb $32, 8(%rax)
je source_compare_faddsdyn_success
cmpb $35, 8(%rax)
je source_compare_faddsdyn_success
source_compare_faddsdyn_failure:
movb $1, %al
ret
source_compare_faddsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddsrdn:
cmpq $8, source_character_count
jb source_compare_faddsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddsrdn_failure
cmpb $97, 1(%rax)
jne source_compare_faddsrdn_failure
cmpb $100, 2(%rax)
jne source_compare_faddsrdn_failure
cmpb $100, 3(%rax)
jne source_compare_faddsrdn_failure
cmpb $115, 4(%rax)
jne source_compare_faddsrdn_failure
cmpb $114, 5(%rax)
jne source_compare_faddsrdn_failure
cmpb $100, 6(%rax)
jne source_compare_faddsrdn_failure
cmpb $110, 7(%rax)
jne source_compare_faddsrdn_failure
cmpq $8, source_character_count
je source_compare_faddsrdn_success
cmpb $10, 8(%rax)
je source_compare_faddsrdn_success
cmpb $32, 8(%rax)
je source_compare_faddsrdn_success
cmpb $35, 8(%rax)
je source_compare_faddsrdn_success
source_compare_faddsrdn_failure:
movb $1, %al
ret
source_compare_faddsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddsrmm:
cmpq $8, source_character_count
jb source_compare_faddsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddsrmm_failure
cmpb $97, 1(%rax)
jne source_compare_faddsrmm_failure
cmpb $100, 2(%rax)
jne source_compare_faddsrmm_failure
cmpb $100, 3(%rax)
jne source_compare_faddsrmm_failure
cmpb $115, 4(%rax)
jne source_compare_faddsrmm_failure
cmpb $114, 5(%rax)
jne source_compare_faddsrmm_failure
cmpb $109, 6(%rax)
jne source_compare_faddsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_faddsrmm_failure
cmpq $8, source_character_count
je source_compare_faddsrmm_success
cmpb $10, 8(%rax)
je source_compare_faddsrmm_success
cmpb $32, 8(%rax)
je source_compare_faddsrmm_success
cmpb $35, 8(%rax)
je source_compare_faddsrmm_success
source_compare_faddsrmm_failure:
movb $1, %al
ret
source_compare_faddsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddsrtz:
cmpq $8, source_character_count
jb source_compare_faddsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddsrtz_failure
cmpb $97, 1(%rax)
jne source_compare_faddsrtz_failure
cmpb $100, 2(%rax)
jne source_compare_faddsrtz_failure
cmpb $100, 3(%rax)
jne source_compare_faddsrtz_failure
cmpb $115, 4(%rax)
jne source_compare_faddsrtz_failure
cmpb $114, 5(%rax)
jne source_compare_faddsrtz_failure
cmpb $116, 6(%rax)
jne source_compare_faddsrtz_failure
cmpb $122, 7(%rax)
jne source_compare_faddsrtz_failure
cmpq $8, source_character_count
je source_compare_faddsrtz_success
cmpb $10, 8(%rax)
je source_compare_faddsrtz_success
cmpb $32, 8(%rax)
je source_compare_faddsrtz_success
cmpb $35, 8(%rax)
je source_compare_faddsrtz_success
source_compare_faddsrtz_failure:
movb $1, %al
ret
source_compare_faddsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_faddsrup:
cmpq $8, source_character_count
jb source_compare_faddsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_faddsrup_failure
cmpb $97, 1(%rax)
jne source_compare_faddsrup_failure
cmpb $100, 2(%rax)
jne source_compare_faddsrup_failure
cmpb $100, 3(%rax)
jne source_compare_faddsrup_failure
cmpb $115, 4(%rax)
jne source_compare_faddsrup_failure
cmpb $114, 5(%rax)
jne source_compare_faddsrup_failure
cmpb $117, 6(%rax)
jne source_compare_faddsrup_failure
cmpb $112, 7(%rax)
jne source_compare_faddsrup_failure
cmpq $8, source_character_count
je source_compare_faddsrup_success
cmpb $10, 8(%rax)
je source_compare_faddsrup_success
cmpb $32, 8(%rax)
je source_compare_faddsrup_success
cmpb $35, 8(%rax)
je source_compare_faddsrup_success
source_compare_faddsrup_failure:
movb $1, %al
ret
source_compare_faddsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fclassd:
cmpq $7, source_character_count
jb source_compare_fclassd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fclassd_failure
cmpb $99, 1(%rax)
jne source_compare_fclassd_failure
cmpb $108, 2(%rax)
jne source_compare_fclassd_failure
cmpb $97, 3(%rax)
jne source_compare_fclassd_failure
cmpb $115, 4(%rax)
jne source_compare_fclassd_failure
cmpb $115, 5(%rax)
jne source_compare_fclassd_failure
cmpb $100, 6(%rax)
jne source_compare_fclassd_failure
cmpq $7, source_character_count
je source_compare_fclassd_success
cmpb $10, 7(%rax)
je source_compare_fclassd_success
cmpb $32, 7(%rax)
je source_compare_fclassd_success
cmpb $35, 7(%rax)
je source_compare_fclassd_success
source_compare_fclassd_failure:
movb $1, %al
ret
source_compare_fclassd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fclassq:
cmpq $7, source_character_count
jb source_compare_fclassq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fclassq_failure
cmpb $99, 1(%rax)
jne source_compare_fclassq_failure
cmpb $108, 2(%rax)
jne source_compare_fclassq_failure
cmpb $97, 3(%rax)
jne source_compare_fclassq_failure
cmpb $115, 4(%rax)
jne source_compare_fclassq_failure
cmpb $115, 5(%rax)
jne source_compare_fclassq_failure
cmpb $113, 6(%rax)
jne source_compare_fclassq_failure
cmpq $7, source_character_count
je source_compare_fclassq_success
cmpb $10, 7(%rax)
je source_compare_fclassq_success
cmpb $32, 7(%rax)
je source_compare_fclassq_success
cmpb $35, 7(%rax)
je source_compare_fclassq_success
source_compare_fclassq_failure:
movb $1, %al
ret
source_compare_fclassq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fclasss:
cmpq $7, source_character_count
jb source_compare_fclasss_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fclasss_failure
cmpb $99, 1(%rax)
jne source_compare_fclasss_failure
cmpb $108, 2(%rax)
jne source_compare_fclasss_failure
cmpb $97, 3(%rax)
jne source_compare_fclasss_failure
cmpb $115, 4(%rax)
jne source_compare_fclasss_failure
cmpb $115, 5(%rax)
jne source_compare_fclasss_failure
cmpb $115, 6(%rax)
jne source_compare_fclasss_failure
cmpq $7, source_character_count
je source_compare_fclasss_success
cmpb $10, 7(%rax)
je source_compare_fclasss_success
cmpb $32, 7(%rax)
je source_compare_fclasss_success
cmpb $35, 7(%rax)
je source_compare_fclasss_success
source_compare_fclasss_failure:
movb $1, %al
ret
source_compare_fclasss_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdl:
cmpq $6, source_character_count
jb source_compare_fcvtdl_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdl_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdl_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdl_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdl_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdl_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdl_failure
cmpq $6, source_character_count
je source_compare_fcvtdl_success
cmpb $10, 6(%rax)
je source_compare_fcvtdl_success
cmpb $32, 6(%rax)
je source_compare_fcvtdl_success
cmpb $35, 6(%rax)
je source_compare_fcvtdl_success
source_compare_fcvtdl_failure:
movb $1, %al
ret
source_compare_fcvtdl_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdldyn:
cmpq $9, source_character_count
jb source_compare_fcvtdldyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdldyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdldyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdldyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdldyn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdldyn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdldyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtdldyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtdldyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtdldyn_failure
cmpq $9, source_character_count
je source_compare_fcvtdldyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtdldyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtdldyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtdldyn_success
source_compare_fcvtdldyn_failure:
movb $1, %al
ret
source_compare_fcvtdldyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdlrdn:
cmpq $9, source_character_count
jb source_compare_fcvtdlrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdlrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdlrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdlrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdlrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdlrdn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdlrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdlrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtdlrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtdlrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtdlrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtdlrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtdlrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtdlrdn_success
source_compare_fcvtdlrdn_failure:
movb $1, %al
ret
source_compare_fcvtdlrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdlrmm:
cmpq $9, source_character_count
jb source_compare_fcvtdlrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdlrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdlrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdlrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdlrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdlrmm_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdlrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdlrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtdlrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtdlrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtdlrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtdlrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtdlrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtdlrmm_success
source_compare_fcvtdlrmm_failure:
movb $1, %al
ret
source_compare_fcvtdlrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdlrtz:
cmpq $9, source_character_count
jb source_compare_fcvtdlrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdlrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdlrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdlrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdlrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdlrtz_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdlrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdlrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtdlrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtdlrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtdlrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtdlrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtdlrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtdlrtz_success
source_compare_fcvtdlrtz_failure:
movb $1, %al
ret
source_compare_fcvtdlrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdlrup:
cmpq $9, source_character_count
jb source_compare_fcvtdlrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdlrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdlrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdlrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdlrup_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdlrup_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdlrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdlrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtdlrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtdlrup_failure
cmpq $9, source_character_count
je source_compare_fcvtdlrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtdlrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtdlrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtdlrup_success
source_compare_fcvtdlrup_failure:
movb $1, %al
ret
source_compare_fcvtdlrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdlu:
cmpq $7, source_character_count
jb source_compare_fcvtdlu_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdlu_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdlu_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdlu_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdlu_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdlu_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdlu_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdlu_failure
cmpq $7, source_character_count
je source_compare_fcvtdlu_success
cmpb $10, 7(%rax)
je source_compare_fcvtdlu_success
cmpb $32, 7(%rax)
je source_compare_fcvtdlu_success
cmpb $35, 7(%rax)
je source_compare_fcvtdlu_success
source_compare_fcvtdlu_failure:
movb $1, %al
ret
source_compare_fcvtdlu_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdludyn:
cmpq $10, source_character_count
jb source_compare_fcvtdludyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdludyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdludyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdludyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdludyn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdludyn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdludyn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdludyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtdludyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtdludyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtdludyn_failure
cmpq $10, source_character_count
je source_compare_fcvtdludyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtdludyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtdludyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtdludyn_success
source_compare_fcvtdludyn_failure:
movb $1, %al
ret
source_compare_fcvtdludyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdlurdn:
cmpq $10, source_character_count
jb source_compare_fcvtdlurdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdlurdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdlurdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdlurdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdlurdn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdlurdn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdlurdn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdlurdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtdlurdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtdlurdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtdlurdn_failure
cmpq $10, source_character_count
je source_compare_fcvtdlurdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtdlurdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtdlurdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtdlurdn_success
source_compare_fcvtdlurdn_failure:
movb $1, %al
ret
source_compare_fcvtdlurdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdlurmm:
cmpq $10, source_character_count
jb source_compare_fcvtdlurmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdlurmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdlurmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdlurmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdlurmm_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdlurmm_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdlurmm_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdlurmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtdlurmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtdlurmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtdlurmm_failure
cmpq $10, source_character_count
je source_compare_fcvtdlurmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtdlurmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtdlurmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtdlurmm_success
source_compare_fcvtdlurmm_failure:
movb $1, %al
ret
source_compare_fcvtdlurmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdlurtz:
cmpq $10, source_character_count
jb source_compare_fcvtdlurtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdlurtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdlurtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdlurtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdlurtz_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdlurtz_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdlurtz_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdlurtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtdlurtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtdlurtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtdlurtz_failure
cmpq $10, source_character_count
je source_compare_fcvtdlurtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtdlurtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtdlurtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtdlurtz_success
source_compare_fcvtdlurtz_failure:
movb $1, %al
ret
source_compare_fcvtdlurtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdlurup:
cmpq $10, source_character_count
jb source_compare_fcvtdlurup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdlurup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdlurup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdlurup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdlurup_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdlurup_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtdlurup_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdlurup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtdlurup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtdlurup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtdlurup_failure
cmpq $10, source_character_count
je source_compare_fcvtdlurup_success
cmpb $10, 10(%rax)
je source_compare_fcvtdlurup_success
cmpb $32, 10(%rax)
je source_compare_fcvtdlurup_success
cmpb $35, 10(%rax)
je source_compare_fcvtdlurup_success
source_compare_fcvtdlurup_failure:
movb $1, %al
ret
source_compare_fcvtdlurup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdq:
cmpq $6, source_character_count
jb source_compare_fcvtdq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdq_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdq_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdq_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdq_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdq_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtdq_failure
cmpq $6, source_character_count
je source_compare_fcvtdq_success
cmpb $10, 6(%rax)
je source_compare_fcvtdq_success
cmpb $32, 6(%rax)
je source_compare_fcvtdq_success
cmpb $35, 6(%rax)
je source_compare_fcvtdq_success
source_compare_fcvtdq_failure:
movb $1, %al
ret
source_compare_fcvtdq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdqdyn:
cmpq $9, source_character_count
jb source_compare_fcvtdqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdqdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdqdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdqdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdqdyn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdqdyn_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtdqdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtdqdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtdqdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtdqdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtdqdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtdqdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtdqdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtdqdyn_success
source_compare_fcvtdqdyn_failure:
movb $1, %al
ret
source_compare_fcvtdqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdqrdn:
cmpq $9, source_character_count
jb source_compare_fcvtdqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdqrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdqrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdqrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdqrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdqrdn_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtdqrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdqrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtdqrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtdqrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtdqrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtdqrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtdqrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtdqrdn_success
source_compare_fcvtdqrdn_failure:
movb $1, %al
ret
source_compare_fcvtdqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdqrmm:
cmpq $9, source_character_count
jb source_compare_fcvtdqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdqrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdqrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdqrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdqrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdqrmm_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtdqrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtdqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtdqrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtdqrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtdqrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtdqrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtdqrmm_success
source_compare_fcvtdqrmm_failure:
movb $1, %al
ret
source_compare_fcvtdqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdqrtz:
cmpq $9, source_character_count
jb source_compare_fcvtdqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdqrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdqrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdqrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdqrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdqrtz_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtdqrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdqrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtdqrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtdqrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtdqrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtdqrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtdqrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtdqrtz_success
source_compare_fcvtdqrtz_failure:
movb $1, %al
ret
source_compare_fcvtdqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdqrup:
cmpq $9, source_character_count
jb source_compare_fcvtdqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdqrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdqrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdqrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdqrup_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdqrup_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtdqrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdqrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtdqrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtdqrup_failure
cmpq $9, source_character_count
je source_compare_fcvtdqrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtdqrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtdqrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtdqrup_success
source_compare_fcvtdqrup_failure:
movb $1, %al
ret
source_compare_fcvtdqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtds:
cmpq $6, source_character_count
jb source_compare_fcvtds_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtds_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtds_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtds_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtds_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtds_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtds_failure
cmpq $6, source_character_count
je source_compare_fcvtds_success
cmpb $10, 6(%rax)
je source_compare_fcvtds_success
cmpb $32, 6(%rax)
je source_compare_fcvtds_success
cmpb $35, 6(%rax)
je source_compare_fcvtds_success
source_compare_fcvtds_failure:
movb $1, %al
ret
source_compare_fcvtds_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdsdyn:
cmpq $9, source_character_count
jb source_compare_fcvtdsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdsdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdsdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdsdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdsdyn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdsdyn_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtdsdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtdsdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtdsdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtdsdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtdsdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtdsdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtdsdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtdsdyn_success
source_compare_fcvtdsdyn_failure:
movb $1, %al
ret
source_compare_fcvtdsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdsrdn:
cmpq $9, source_character_count
jb source_compare_fcvtdsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdsrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdsrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdsrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdsrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdsrdn_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtdsrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdsrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtdsrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtdsrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtdsrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtdsrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtdsrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtdsrdn_success
source_compare_fcvtdsrdn_failure:
movb $1, %al
ret
source_compare_fcvtdsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdsrmm:
cmpq $9, source_character_count
jb source_compare_fcvtdsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdsrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdsrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdsrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdsrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdsrmm_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtdsrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtdsrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtdsrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtdsrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtdsrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtdsrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtdsrmm_success
source_compare_fcvtdsrmm_failure:
movb $1, %al
ret
source_compare_fcvtdsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdsrtz:
cmpq $9, source_character_count
jb source_compare_fcvtdsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdsrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdsrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdsrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdsrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdsrtz_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtdsrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdsrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtdsrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtdsrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtdsrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtdsrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtdsrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtdsrtz_success
source_compare_fcvtdsrtz_failure:
movb $1, %al
ret
source_compare_fcvtdsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdsrup:
cmpq $9, source_character_count
jb source_compare_fcvtdsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdsrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdsrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdsrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdsrup_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdsrup_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtdsrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdsrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtdsrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtdsrup_failure
cmpq $9, source_character_count
je source_compare_fcvtdsrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtdsrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtdsrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtdsrup_success
source_compare_fcvtdsrup_failure:
movb $1, %al
ret
source_compare_fcvtdsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdw:
cmpq $6, source_character_count
jb source_compare_fcvtdw_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdw_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdw_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdw_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdw_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdw_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdw_failure
cmpq $9, source_character_count
je source_compare_fcvtdw_success
cmpb $10, 9(%rax)
je source_compare_fcvtdw_success
cmpb $32, 9(%rax)
je source_compare_fcvtdw_success
cmpb $35, 9(%rax)
je source_compare_fcvtdw_success
source_compare_fcvtdw_failure:
movb $1, %al
ret
source_compare_fcvtdw_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwdyn:
cmpq $9, source_character_count
jb source_compare_fcvtdwdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwdyn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwdyn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtdwdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtdwdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtdwdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtdwdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtdwdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtdwdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtdwdyn_success
source_compare_fcvtdwdyn_failure:
movb $1, %al
ret
source_compare_fcvtdwdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwrdn:
cmpq $9, source_character_count
jb source_compare_fcvtdwrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwrdn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdwrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtdwrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtdwrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtdwrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtdwrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtdwrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtdwrdn_success
source_compare_fcvtdwrdn_failure:
movb $1, %al
ret
source_compare_fcvtdwrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwrmm:
cmpq $9, source_character_count
jb source_compare_fcvtdwrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwrmm_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdwrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtdwrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtdwrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtdwrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtdwrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtdwrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtdwrmm_success
source_compare_fcvtdwrmm_failure:
movb $1, %al
ret
source_compare_fcvtdwrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwrtz:
cmpq $9, source_character_count
jb source_compare_fcvtdwrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwrtz_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdwrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtdwrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtdwrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtdwrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtdwrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtdwrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtdwrtz_success
source_compare_fcvtdwrtz_failure:
movb $1, %al
ret
source_compare_fcvtdwrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwrup:
cmpq $9, source_character_count
jb source_compare_fcvtdwrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwrup_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwrup_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtdwrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtdwrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtdwrup_failure
cmpq $9, source_character_count
je source_compare_fcvtdwrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtdwrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtdwrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtdwrup_success
source_compare_fcvtdwrup_failure:
movb $1, %al
ret
source_compare_fcvtdwrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwu:
cmpq $7, source_character_count
jb source_compare_fcvtdwu_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwu_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwu_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwu_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwu_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwu_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwu_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdwu_failure
cmpq $7, source_character_count
je source_compare_fcvtdwu_success
cmpb $10, 7(%rax)
je source_compare_fcvtdwu_success
cmpb $32, 7(%rax)
je source_compare_fcvtdwu_success
cmpb $35, 7(%rax)
je source_compare_fcvtdwu_success
source_compare_fcvtdwu_failure:
movb $1, %al
ret
source_compare_fcvtdwu_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwudyn:
cmpq $10, source_character_count
jb source_compare_fcvtdwudyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwudyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwudyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwudyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwudyn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwudyn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwudyn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdwudyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtdwudyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtdwudyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtdwudyn_failure
cmpq $10, source_character_count
je source_compare_fcvtdwudyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtdwudyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtdwudyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtdwudyn_success
source_compare_fcvtdwudyn_failure:
movb $1, %al
ret
source_compare_fcvtdwudyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwurdn:
cmpq $10, source_character_count
jb source_compare_fcvtdwurdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwurdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwurdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwurdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwurdn_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwurdn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwurdn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdwurdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtdwurdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtdwurdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtdwurdn_failure
cmpq $10, source_character_count
je source_compare_fcvtdwurdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtdwurdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtdwurdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtdwurdn_success
source_compare_fcvtdwurdn_failure:
movb $1, %al
ret
source_compare_fcvtdwurdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwurmm:
cmpq $10, source_character_count
jb source_compare_fcvtdwurmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwurmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwurmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwurmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwurmm_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwurmm_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwurmm_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdwurmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtdwurmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtdwurmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtdwurmm_failure
cmpq $10, source_character_count
je source_compare_fcvtdwurmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtdwurmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtdwurmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtdwurmm_success
source_compare_fcvtdwurmm_failure:
movb $1, %al
ret
source_compare_fcvtdwurmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwurtz:
cmpq $10, source_character_count
jb source_compare_fcvtdwurtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwurtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwurtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwurtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwurtz_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwurtz_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwurtz_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdwurtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtdwurtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtdwurtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtdwurtz_failure
cmpq $10, source_character_count
je source_compare_fcvtdwurtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtdwurtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtdwurtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtdwurtz_success
source_compare_fcvtdwurtz_failure:
movb $1, %al
ret
source_compare_fcvtdwurtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtdwurup:
cmpq $10, source_character_count
jb source_compare_fcvtdwurup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtdwurup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtdwurup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtdwurup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtdwurup_failure
cmpb $100, 4(%rax)
jne source_compare_fcvtdwurup_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtdwurup_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtdwurup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtdwurup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtdwurup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtdwurup_failure
cmpq $10, source_character_count
je source_compare_fcvtdwurup_success
cmpb $10, 10(%rax)
je source_compare_fcvtdwurup_success
cmpb $32, 10(%rax)
je source_compare_fcvtdwurup_success
cmpb $35, 10(%rax)
je source_compare_fcvtdwurup_success
source_compare_fcvtdwurup_failure:
movb $1, %al
ret
source_compare_fcvtdwurup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtld:
cmpq $6, source_character_count
jb source_compare_fcvtld_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtld_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtld_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtld_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtld_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtld_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtld_failure
cmpq $6, source_character_count
je source_compare_fcvtld_success
cmpb $10, 6(%rax)
je source_compare_fcvtld_success
cmpb $32, 6(%rax)
je source_compare_fcvtld_success
cmpb $35, 6(%rax)
je source_compare_fcvtld_success
source_compare_fcvtld_failure:
movb $1, %al
ret
source_compare_fcvtld_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlddyn:
cmpq $9, source_character_count
jb source_compare_fcvtlddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlddyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlddyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlddyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlddyn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtlddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtlddyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtlddyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtlddyn_failure
cmpq $9, source_character_count
je source_compare_fcvtlddyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtlddyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtlddyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtlddyn_success
source_compare_fcvtlddyn_failure:
movb $1, %al
ret
source_compare_fcvtlddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtldrdn:
cmpq $9, source_character_count
jb source_compare_fcvtldrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtldrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtldrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtldrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtldrdn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtldrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtldrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtldrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtldrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtldrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtldrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtldrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtldrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtldrdn_success
source_compare_fcvtldrdn_failure:
movb $1, %al
ret
source_compare_fcvtldrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtldrmm:
cmpq $9, source_character_count
jb source_compare_fcvtldrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtldrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtldrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtldrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtldrmm_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtldrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtldrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtldrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtldrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtldrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtldrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtldrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtldrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtldrmm_success
source_compare_fcvtldrmm_failure:
movb $1, %al
ret
source_compare_fcvtldrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtldrtz:
cmpq $9, source_character_count
jb source_compare_fcvtldrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtldrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtldrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtldrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtldrtz_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtldrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtldrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtldrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtldrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtldrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtldrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtldrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtldrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtldrtz_success
source_compare_fcvtldrtz_failure:
movb $1, %al
ret
source_compare_fcvtldrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtldrup:
cmpq $9, source_character_count
jb source_compare_fcvtldrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtldrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtldrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtldrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtldrup_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtldrup_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtldrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtldrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtldrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtldrup_failure
cmpq $9, source_character_count
je source_compare_fcvtldrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtldrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtldrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtldrup_success
source_compare_fcvtldrup_failure:
movb $1, %al
ret
source_compare_fcvtldrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlq:
cmpq $6, source_character_count
jb source_compare_fcvtlq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlq_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlq_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlq_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlq_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlq_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtlq_failure
cmpq $6, source_character_count
je source_compare_fcvtlq_success
cmpb $10, 6(%rax)
je source_compare_fcvtlq_success
cmpb $32, 6(%rax)
je source_compare_fcvtlq_success
cmpb $35, 6(%rax)
je source_compare_fcvtlq_success
source_compare_fcvtlq_failure:
movb $1, %al
ret
source_compare_fcvtlq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlqdyn:
cmpq $9, source_character_count
jb source_compare_fcvtlqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlqdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlqdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlqdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlqdyn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlqdyn_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtlqdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtlqdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtlqdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtlqdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtlqdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtlqdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtlqdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtlqdyn_success
source_compare_fcvtlqdyn_failure:
movb $1, %al
ret
source_compare_fcvtlqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlqrdn:
cmpq $9, source_character_count
jb source_compare_fcvtlqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlqrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlqrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlqrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlqrdn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlqrdn_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtlqrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtlqrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtlqrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtlqrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtlqrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtlqrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtlqrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtlqrdn_success
source_compare_fcvtlqrdn_failure:
movb $1, %al
ret
source_compare_fcvtlqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlqrmm:
cmpq $9, source_character_count
jb source_compare_fcvtlqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlqrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlqrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlqrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlqrmm_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlqrmm_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtlqrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtlqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtlqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtlqrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtlqrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtlqrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtlqrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtlqrmm_success
source_compare_fcvtlqrmm_failure:
movb $1, %al
ret
source_compare_fcvtlqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlqrtz:
cmpq $9, source_character_count
jb source_compare_fcvtlqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlqrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlqrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlqrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlqrtz_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlqrtz_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtlqrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtlqrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtlqrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtlqrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtlqrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtlqrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtlqrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtlqrtz_success
source_compare_fcvtlqrtz_failure:
movb $1, %al
ret
source_compare_fcvtlqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlqrup:
cmpq $9, source_character_count
jb source_compare_fcvtlqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlqrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlqrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlqrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlqrup_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlqrup_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtlqrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtlqrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtlqrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtlqrup_failure
cmpq $9, source_character_count
je source_compare_fcvtlqrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtlqrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtlqrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtlqrup_success
source_compare_fcvtlqrup_failure:
movb $1, %al
ret
source_compare_fcvtlqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtls:
cmpq $6, source_character_count
jb source_compare_fcvtls_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtls_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtls_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtls_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtls_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtls_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtls_failure
cmpq $6, source_character_count
je source_compare_fcvtls_success
cmpb $10, 6(%rax)
je source_compare_fcvtls_success
cmpb $32, 6(%rax)
je source_compare_fcvtls_success
cmpb $35, 6(%rax)
je source_compare_fcvtls_success
source_compare_fcvtls_failure:
movb $1, %al
ret
source_compare_fcvtls_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlsdyn:
cmpq $9, source_character_count
jb source_compare_fcvtlsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlsdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlsdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlsdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlsdyn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlsdyn_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtlsdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtlsdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtlsdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtlsdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtlsdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtlsdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtlsdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtlsdyn_success
source_compare_fcvtlsdyn_failure:
movb $1, %al
ret
source_compare_fcvtlsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlsrdn:
cmpq $9, source_character_count
jb source_compare_fcvtlsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlsrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlsrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlsrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlsrdn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlsrdn_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtlsrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtlsrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtlsrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtlsrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtlsrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtlsrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtlsrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtlsrdn_success
source_compare_fcvtlsrdn_failure:
movb $1, %al
ret
source_compare_fcvtlsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlsrmm:
cmpq $9, source_character_count
jb source_compare_fcvtlsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlsrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlsrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlsrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlsrmm_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlsrmm_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtlsrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtlsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtlsrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtlsrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtlsrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtlsrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtlsrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtlsrmm_success
source_compare_fcvtlsrmm_failure:
movb $1, %al
ret
source_compare_fcvtlsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlsrtz:
cmpq $9, source_character_count
jb source_compare_fcvtlsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlsrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlsrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlsrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlsrtz_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlsrtz_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtlsrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtlsrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtlsrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtlsrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtlsrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtlsrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtlsrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtlsrtz_success
source_compare_fcvtlsrtz_failure:
movb $1, %al
ret
source_compare_fcvtlsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlsrup:
cmpq $9, source_character_count
jb source_compare_fcvtlsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlsrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlsrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlsrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlsrup_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlsrup_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtlsrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtlsrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtlsrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtlsrup_failure
cmpq $9, source_character_count
je source_compare_fcvtlsrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtlsrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtlsrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtlsrup_success
source_compare_fcvtlsrup_failure:
movb $1, %al
ret
source_compare_fcvtlsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlud:
cmpq $7, source_character_count
jb source_compare_fcvtlud_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlud_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlud_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlud_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlud_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlud_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtlud_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtlud_failure
cmpq $7, source_character_count
je source_compare_fcvtlud_success
cmpb $10, 7(%rax)
je source_compare_fcvtlud_success
cmpb $32, 7(%rax)
je source_compare_fcvtlud_success
cmpb $35, 7(%rax)
je source_compare_fcvtlud_success
source_compare_fcvtlud_failure:
movb $1, %al
ret
source_compare_fcvtlud_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtluddyn:
cmpq $10, source_character_count
jb source_compare_fcvtluddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtluddyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtluddyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtluddyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtluddyn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtluddyn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtluddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtluddyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtluddyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtluddyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtluddyn_failure
cmpq $10, source_character_count
je source_compare_fcvtluddyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtluddyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtluddyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtluddyn_success
source_compare_fcvtluddyn_failure:
movb $1, %al
ret
source_compare_fcvtluddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtludrdn:
cmpq $10, source_character_count
jb source_compare_fcvtludrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtludrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtludrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtludrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtludrdn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtludrdn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtludrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtludrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtludrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtludrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtludrdn_failure
cmpq $10, source_character_count
je source_compare_fcvtludrdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtludrdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtludrdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtludrdn_success
source_compare_fcvtludrdn_failure:
movb $1, %al
ret
source_compare_fcvtludrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtludrmm:
cmpq $10, source_character_count
jb source_compare_fcvtludrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtludrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtludrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtludrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtludrmm_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtludrmm_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtludrmm_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtludrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtludrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtludrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtludrmm_failure
cmpq $10, source_character_count
je source_compare_fcvtludrmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtludrmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtludrmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtludrmm_success
source_compare_fcvtludrmm_failure:
movb $1, %al
ret
source_compare_fcvtludrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtludrtz:
cmpq $10, source_character_count
jb source_compare_fcvtludrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtludrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtludrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtludrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtludrtz_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtludrtz_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtludrtz_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtludrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtludrtz_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtludrtz_failure
cmpb $101, 9(%rax)
jne source_compare_fcvtludrtz_failure
cmpq $10, source_character_count
je source_compare_fcvtludrtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtludrtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtludrtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtludrtz_success
source_compare_fcvtludrtz_failure:
movb $1, %al
ret
source_compare_fcvtludrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtludrup:
cmpq $10, source_character_count
jb source_compare_fcvtludrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtludrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtludrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtludrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtludrup_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtludrup_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtludrup_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtludrup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtludrup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtludrup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtludrup_failure
cmpq $10, source_character_count
je source_compare_fcvtludrup_success
cmpb $10, 10(%rax)
je source_compare_fcvtludrup_success
cmpb $32, 10(%rax)
je source_compare_fcvtludrup_success
cmpb $35, 10(%rax)
je source_compare_fcvtludrup_success
source_compare_fcvtludrup_failure:
movb $1, %al
ret
source_compare_fcvtludrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtluq:
cmpq $7, source_character_count
jb source_compare_fcvtluq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtluq_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtluq_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtluq_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtluq_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtluq_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtluq_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtluq_failure
cmpq $7, source_character_count
je source_compare_fcvtluq_success
cmpb $10, 7(%rax)
je source_compare_fcvtluq_success
cmpb $32, 7(%rax)
je source_compare_fcvtluq_success
cmpb $35, 7(%rax)
je source_compare_fcvtluq_success
source_compare_fcvtluq_failure:
movb $1, %al
ret
source_compare_fcvtluq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtluqdyn:
cmpq $10, source_character_count
jb source_compare_fcvtluqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtluqdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtluqdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtluqdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtluqdyn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtluqdyn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtluqdyn_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtluqdyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtluqdyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtluqdyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtluqdyn_failure
cmpq $10, source_character_count
je source_compare_fcvtluqdyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtluqdyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtluqdyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtluqdyn_success
source_compare_fcvtluqdyn_failure:
movb $1, %al
ret
source_compare_fcvtluqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtluqrdn:
cmpq $10, source_character_count
jb source_compare_fcvtluqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtluqrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtluqrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtluqrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtluqrdn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtluqrdn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtluqrdn_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtluqrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtluqrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtluqrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtluqrdn_failure
cmpq $10, source_character_count
je source_compare_fcvtluqrdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtluqrdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtluqrdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtluqrdn_success
source_compare_fcvtluqrdn_failure:
movb $1, %al
ret
source_compare_fcvtluqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtluqrmm:
cmpq $10, source_character_count
jb source_compare_fcvtluqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtluqrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtluqrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtluqrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtluqrmm_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtluqrmm_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtluqrmm_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtluqrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtluqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtluqrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtluqrmm_failure
cmpq $10, source_character_count
je source_compare_fcvtluqrmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtluqrmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtluqrmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtluqrmm_success
source_compare_fcvtluqrmm_failure:
movb $1, %al
ret
source_compare_fcvtluqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtluqrtz:
cmpq $10, source_character_count
jb source_compare_fcvtluqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtluqrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtluqrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtluqrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtluqrtz_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtluqrtz_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtluqrtz_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtluqrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtluqrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtluqrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtluqrtz_failure
cmpq $10, source_character_count
je source_compare_fcvtluqrtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtluqrtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtluqrtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtluqrtz_success
source_compare_fcvtluqrtz_failure:
movb $1, %al
ret
source_compare_fcvtluqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtluqrup:
cmpq $10, source_character_count
jb source_compare_fcvtluqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtluqrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtluqrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtluqrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtluqrup_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtluqrup_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtluqrup_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtluqrup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtluqrup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtluqrup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtluqrup_failure
cmpq $10, source_character_count
je source_compare_fcvtluqrup_success
cmpb $10, 10(%rax)
je source_compare_fcvtluqrup_success
cmpb $32, 10(%rax)
je source_compare_fcvtluqrup_success
cmpb $35, 10(%rax)
je source_compare_fcvtluqrup_success
source_compare_fcvtluqrup_failure:
movb $1, %al
ret
source_compare_fcvtluqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlus:
cmpq $7, source_character_count
jb source_compare_fcvtlus_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlus_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlus_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlus_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlus_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlus_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtlus_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtlus_failure
cmpq $7, source_character_count
je source_compare_fcvtlus_success
cmpb $10, 7(%rax)
je source_compare_fcvtlus_success
cmpb $32, 7(%rax)
je source_compare_fcvtlus_success
cmpb $35, 7(%rax)
je source_compare_fcvtlus_success
source_compare_fcvtlus_failure:
movb $1, %al
ret
source_compare_fcvtlus_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlusdyn:
cmpq $10, source_character_count
jb source_compare_fcvtlusdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlusdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlusdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlusdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlusdyn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlusdyn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtlusdyn_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtlusdyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtlusdyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtlusdyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtlusdyn_failure
cmpq $10, source_character_count
je source_compare_fcvtlusdyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtlusdyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtlusdyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtlusdyn_success
source_compare_fcvtlusdyn_failure:
movb $1, %al
ret
source_compare_fcvtlusdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlusrdn:
cmpq $10, source_character_count
jb source_compare_fcvtlusrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlusrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlusrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlusrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlusrdn_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlusrdn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtlusrdn_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtlusrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtlusrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtlusrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtlusrdn_failure
cmpq $10, source_character_count
je source_compare_fcvtlusrdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtlusrdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtlusrdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtlusrdn_success
source_compare_fcvtlusrdn_failure:
movb $1, %al
ret
source_compare_fcvtlusrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlusrmm:
cmpq $10, source_character_count
jb source_compare_fcvtlusrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlusrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlusrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlusrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlusrmm_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlusrmm_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtlusrmm_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtlusrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtlusrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtlusrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtlusrmm_failure
cmpq $10, source_character_count
je source_compare_fcvtlusrmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtlusrmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtlusrmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtlusrmm_success
source_compare_fcvtlusrmm_failure:
movb $1, %al
ret
source_compare_fcvtlusrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlusrtz:
cmpq $10, source_character_count
jb source_compare_fcvtlusrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlusrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlusrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlusrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlusrtz_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlusrtz_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtlusrtz_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtlusrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtlusrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtlusrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtlusrtz_failure
cmpq $10, source_character_count
je source_compare_fcvtlusrtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtlusrtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtlusrtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtlusrtz_success
source_compare_fcvtlusrtz_failure:
movb $1, %al
ret
source_compare_fcvtlusrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtlusrup:
cmpq $10, source_character_count
jb source_compare_fcvtlusrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtlusrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtlusrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtlusrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtlusrup_failure
cmpb $108, 4(%rax)
jne source_compare_fcvtlusrup_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtlusrup_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtlusrup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtlusrup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtlusrup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtlusrup_failure
cmpq $10, source_character_count
je source_compare_fcvtlusrup_success
cmpb $10, 10(%rax)
je source_compare_fcvtlusrup_success
cmpb $32, 10(%rax)
je source_compare_fcvtlusrup_success
cmpb $35, 10(%rax)
je source_compare_fcvtlusrup_success
source_compare_fcvtlusrup_failure:
movb $1, %al
ret
source_compare_fcvtlusrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqd:
cmpq $6, source_character_count
jb source_compare_fcvtqd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqd_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqd_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqd_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqd_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqd_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtqd_failure
cmpq $6, source_character_count
je source_compare_fcvtqd_success
cmpb $10, 6(%rax)
je source_compare_fcvtqd_success
cmpb $32, 6(%rax)
je source_compare_fcvtqd_success
cmpb $35, 6(%rax)
je source_compare_fcvtqd_success
source_compare_fcvtqd_failure:
movb $1, %al
ret
source_compare_fcvtqd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqddyn:
cmpq $9, source_character_count
jb source_compare_fcvtqddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqddyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqddyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqddyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqddyn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtqddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtqddyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtqddyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtqddyn_failure
cmpq $9, source_character_count
je source_compare_fcvtqddyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtqddyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtqddyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtqddyn_success
source_compare_fcvtqddyn_failure:
movb $1, %al
ret
source_compare_fcvtqddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqdrdn:
cmpq $9, source_character_count
jb source_compare_fcvtqdrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqdrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqdrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqdrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqdrdn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqdrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtqdrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqdrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtqdrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtqdrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtqdrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtqdrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtqdrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtqdrdn_success
source_compare_fcvtqdrdn_failure:
movb $1, %al
ret
source_compare_fcvtqdrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqdrmm:
cmpq $9, source_character_count
jb source_compare_fcvtqdrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqdrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqdrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqdrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqdrmm_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqdrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtqdrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqdrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtqdrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtqdrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtqdrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtqdrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtqdrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtqdrmm_success
source_compare_fcvtqdrmm_failure:
movb $1, %al
ret
source_compare_fcvtqdrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqdrtz:
cmpq $9, source_character_count
jb source_compare_fcvtqdrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqdrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqdrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqdrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqdrtz_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqdrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtqdrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqdrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtqdrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtqdrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtqdrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtqdrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtqdrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtqdrtz_success
source_compare_fcvtqdrtz_failure:
movb $1, %al
ret
source_compare_fcvtqdrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqdrup:
cmpq $9, source_character_count
jb source_compare_fcvtqdrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqdrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqdrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqdrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqdrup_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqdrup_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtqdrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqdrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtqdrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtqdrup_failure
cmpq $9, source_character_count
je source_compare_fcvtqdrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtqdrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtqdrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtqdrup_success
source_compare_fcvtqdrup_failure:
movb $1, %al
ret
source_compare_fcvtqdrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtql:
cmpq $6, source_character_count
jb source_compare_fcvtql_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtql_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtql_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtql_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtql_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtql_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtql_failure
cmpq $6, source_character_count
je source_compare_fcvtql_success
cmpb $10, 6(%rax)
je source_compare_fcvtql_success
cmpb $32, 6(%rax)
je source_compare_fcvtql_success
cmpb $35, 6(%rax)
je source_compare_fcvtql_success
source_compare_fcvtql_failure:
movb $1, %al
ret
source_compare_fcvtql_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqldyn:
cmpq $9, source_character_count
jb source_compare_fcvtqldyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqldyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqldyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqldyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqldyn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqldyn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqldyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtqldyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtqldyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtqldyn_failure
cmpq $9, source_character_count
je source_compare_fcvtqldyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtqldyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtqldyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtqldyn_success
source_compare_fcvtqldyn_failure:
movb $1, %al
ret
source_compare_fcvtqldyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqlrdn:
cmpq $9, source_character_count
jb source_compare_fcvtqlrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqlrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqlrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqlrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqlrdn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqlrdn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqlrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqlrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtqlrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtqlrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtqlrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtqlrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtqlrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtqlrdn_success
source_compare_fcvtqlrdn_failure:
movb $1, %al
ret
source_compare_fcvtqlrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqlrmm:
cmpq $9, source_character_count
jb source_compare_fcvtqlrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqlrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqlrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqlrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqlrmm_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqlrmm_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqlrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqlrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtqlrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtqlrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtqlrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtqlrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtqlrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtqlrmm_success
source_compare_fcvtqlrmm_failure:
movb $1, %al
ret
source_compare_fcvtqlrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqlrtz:
cmpq $9, source_character_count
jb source_compare_fcvtqlrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqlrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqlrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqlrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqlrtz_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqlrtz_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqlrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqlrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtqlrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtqlrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtqlrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtqlrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtqlrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtqlrtz_success
source_compare_fcvtqlrtz_failure:
movb $1, %al
ret
source_compare_fcvtqlrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqlrup:
cmpq $9, source_character_count
jb source_compare_fcvtqlrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqlrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqlrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqlrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqlrup_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqlrup_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqlrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqlrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtqlrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtqlrup_failure
cmpq $9, source_character_count
je source_compare_fcvtqlrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtqlrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtqlrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtqlrup_success
source_compare_fcvtqlrup_failure:
movb $1, %al
ret
source_compare_fcvtqlrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqlu:
cmpq $7, source_character_count
jb source_compare_fcvtqlu_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqlu_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqlu_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqlu_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqlu_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqlu_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqlu_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqlu_failure
cmpq $7, source_character_count
je source_compare_fcvtqlu_success
cmpb $10, 7(%rax)
je source_compare_fcvtqlu_success
cmpb $32, 7(%rax)
je source_compare_fcvtqlu_success
cmpb $35, 7(%rax)
je source_compare_fcvtqlu_success
source_compare_fcvtqlu_failure:
movb $1, %al
ret
source_compare_fcvtqlu_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqludyn:
cmpq $10, source_character_count
jb source_compare_fcvtqludyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqludyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqludyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqludyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqludyn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqludyn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqludyn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqludyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtqludyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtqludyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtqludyn_failure
cmpq $10, source_character_count
je source_compare_fcvtqludyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtqludyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtqludyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtqludyn_success
source_compare_fcvtqludyn_failure:
movb $1, %al
ret
source_compare_fcvtqludyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqlurdn:
cmpq $10, source_character_count
jb source_compare_fcvtqlurdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqlurdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqlurdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqlurdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqlurdn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqlurdn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqlurdn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqlurdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtqlurdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtqlurdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtqlurdn_failure
cmpq $10, source_character_count
je source_compare_fcvtqlurdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtqlurdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtqlurdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtqlurdn_success
source_compare_fcvtqlurdn_failure:
movb $1, %al
ret
source_compare_fcvtqlurdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqlurmm:
cmpq $10, source_character_count
jb source_compare_fcvtqlurmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqlurmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqlurmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqlurmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqlurmm_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqlurmm_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqlurmm_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqlurmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtqlurmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtqlurmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtqlurmm_failure
cmpq $10, source_character_count
je source_compare_fcvtqlurmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtqlurmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtqlurmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtqlurmm_success
source_compare_fcvtqlurmm_failure:
movb $1, %al
ret
source_compare_fcvtqlurmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqlurtz:
cmpq $10, source_character_count
jb source_compare_fcvtqlurtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqlurtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqlurtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqlurtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqlurtz_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqlurtz_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqlurtz_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqlurtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtqlurtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtqlurtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtqlurtz_failure
cmpq $10, source_character_count
je source_compare_fcvtqlurtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtqlurtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtqlurtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtqlurtz_success
source_compare_fcvtqlurtz_failure:
movb $1, %al
ret
source_compare_fcvtqlurtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqlurup:
cmpq $10, source_character_count
jb source_compare_fcvtqlurup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqlurup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqlurup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqlurup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqlurup_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqlurup_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtqlurup_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqlurup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtqlurup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtqlurup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtqlurup_failure
cmpq $10, source_character_count
je source_compare_fcvtqlurup_success
cmpb $10, 10(%rax)
je source_compare_fcvtqlurup_success
cmpb $32, 10(%rax)
je source_compare_fcvtqlurup_success
cmpb $35, 10(%rax)
je source_compare_fcvtqlurup_success
source_compare_fcvtqlurup_failure:
movb $1, %al
ret
source_compare_fcvtqlurup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqs:
cmpq $6, source_character_count
jb source_compare_fcvtqs_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqs_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqs_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqs_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqs_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqs_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtqs_failure
cmpq $6, source_character_count
je source_compare_fcvtqs_success
cmpb $10, 6(%rax)
je source_compare_fcvtqs_success
cmpb $32, 6(%rax)
je source_compare_fcvtqs_success
cmpb $35, 6(%rax)
je source_compare_fcvtqs_success
source_compare_fcvtqs_failure:
movb $1, %al
ret
source_compare_fcvtqs_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqsdyn:
cmpq $9, source_character_count
jb source_compare_fcvtqsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqsdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqsdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqsdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqsdyn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqsdyn_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtqsdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtqsdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtqsdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtqsdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtqsdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtqsdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtqsdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtqsdyn_success
source_compare_fcvtqsdyn_failure:
movb $1, %al
ret
source_compare_fcvtqsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqsrdn:
cmpq $9, source_character_count
jb source_compare_fcvtqsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqsrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqsrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqsrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqsrdn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqsrdn_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtqsrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqsrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtqsrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtqsrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtqsrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtqsrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtqsrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtqsrdn_success
source_compare_fcvtqsrdn_failure:
movb $1, %al
ret
source_compare_fcvtqsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqsrmm:
cmpq $9, source_character_count
jb source_compare_fcvtqsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqsrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqsrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqsrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqsrmm_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqsrmm_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtqsrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtqsrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtqsrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtqsrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtqsrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtqsrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtqsrmm_success
source_compare_fcvtqsrmm_failure:
movb $1, %al
ret
source_compare_fcvtqsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqsrtz:
cmpq $9, source_character_count
jb source_compare_fcvtqsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqsrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqsrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqsrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqsrtz_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqsrtz_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtqsrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqsrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtqsrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtqsrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtqsrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtqsrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtqsrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtqsrtz_success
source_compare_fcvtqsrtz_failure:
movb $1, %al
ret
source_compare_fcvtqsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqsrup:
cmpq $9, source_character_count
jb source_compare_fcvtqsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqsrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqsrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqsrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqsrup_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqsrup_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtqsrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqsrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtqsrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtqsrup_failure
cmpq $9, source_character_count
je source_compare_fcvtqsrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtqsrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtqsrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtqsrup_success
source_compare_fcvtqsrup_failure:
movb $1, %al
ret
source_compare_fcvtqsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqw:
cmpq $6, source_character_count
jb source_compare_fcvtqw_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqw_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqw_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqw_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqw_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqw_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqw_failure
cmpq $6, source_character_count
je source_compare_fcvtqw_success
cmpb $10, 6(%rax)
je source_compare_fcvtqw_success
cmpb $32, 6(%rax)
je source_compare_fcvtqw_success
cmpb $35, 6(%rax)
je source_compare_fcvtqw_success
source_compare_fcvtqw_failure:
movb $1, %al
ret
source_compare_fcvtqw_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwdyn:
cmpq $9, source_character_count
jb source_compare_fcvtqwdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwdyn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwdyn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtqwdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtqwdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtqwdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtqwdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtqwdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtqwdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtqwdyn_success
source_compare_fcvtqwdyn_failure:
movb $1, %al
ret
source_compare_fcvtqwdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwrdn:
cmpq $9, source_character_count
jb source_compare_fcvtqwrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwrdn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwrdn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqwrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtqwrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtqwrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtqwrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtqwrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtqwrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtqwrdn_success
source_compare_fcvtqwrdn_failure:
movb $1, %al
ret
source_compare_fcvtqwrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwrmm:
cmpq $9, source_character_count
jb source_compare_fcvtqwrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwrmm_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwrmm_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqwrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtqwrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtqwrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtqwrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtqwrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtqwrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtqwrmm_success
source_compare_fcvtqwrmm_failure:
movb $1, %al
ret
source_compare_fcvtqwrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwrtz:
cmpq $9, source_character_count
jb source_compare_fcvtqwrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwrtz_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwrtz_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqwrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtqwrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtqwrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtqwrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtqwrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtqwrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtqwrtz_success
source_compare_fcvtqwrtz_failure:
movb $1, %al
ret
source_compare_fcvtqwrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwrup:
cmpq $9, source_character_count
jb source_compare_fcvtqwrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwrup_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwrup_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtqwrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtqwrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtqwrup_failure
cmpq $9, source_character_count
je source_compare_fcvtqwrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtqwrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtqwrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtqwrup_success
source_compare_fcvtqwrup_failure:
movb $1, %al
ret
source_compare_fcvtqwrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwu:
cmpq $7, source_character_count
jb source_compare_fcvtqwu_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwu_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwu_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwu_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwu_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwu_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwu_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqwu_failure
cmpq $7, source_character_count
je source_compare_fcvtqwu_success
cmpb $10, 7(%rax)
je source_compare_fcvtqwu_success
cmpb $32, 7(%rax)
je source_compare_fcvtqwu_success
cmpb $35, 7(%rax)
je source_compare_fcvtqwu_success
source_compare_fcvtqwu_failure:
movb $1, %al
ret
source_compare_fcvtqwu_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwudyn:
cmpq $10, source_character_count
jb source_compare_fcvtqwudyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwudyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwudyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwudyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwudyn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwudyn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwudyn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqwudyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtqwudyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtqwudyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtqwudyn_failure
cmpq $10, source_character_count
je source_compare_fcvtqwudyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtqwudyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtqwudyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtqwudyn_success
source_compare_fcvtqwudyn_failure:
movb $1, %al
ret
source_compare_fcvtqwudyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwurdn:
cmpq $10, source_character_count
jb source_compare_fcvtqwurdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwurdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwurdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwurdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwurdn_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwurdn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwurdn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqwurdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtqwurdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtqwurdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtqwurdn_failure
cmpq $10, source_character_count
je source_compare_fcvtqwurdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtqwurdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtqwurdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtqwurdn_success
source_compare_fcvtqwurdn_failure:
movb $1, %al
ret
source_compare_fcvtqwurdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwurmm:
cmpq $10, source_character_count
jb source_compare_fcvtqwurmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwurmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwurmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwurmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwurmm_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwurmm_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwurmm_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqwurmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtqwurmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtqwurmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtqwurmm_failure
cmpq $10, source_character_count
je source_compare_fcvtqwurmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtqwurmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtqwurmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtqwurmm_success
source_compare_fcvtqwurmm_failure:
movb $1, %al
ret
source_compare_fcvtqwurmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwurtz:
cmpq $10, source_character_count
jb source_compare_fcvtqwurtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwurtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwurtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwurtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwurtz_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwurtz_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwurtz_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqwurtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtqwurtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtqwurtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtqwurtz_failure
cmpq $10, source_character_count
je source_compare_fcvtqwurtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtqwurtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtqwurtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtqwurtz_success
source_compare_fcvtqwurtz_failure:
movb $1, %al
ret
source_compare_fcvtqwurtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtqwurup:
cmpq $10, source_character_count
jb source_compare_fcvtqwurup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtqwurup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtqwurup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtqwurup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtqwurup_failure
cmpb $113, 4(%rax)
jne source_compare_fcvtqwurup_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtqwurup_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtqwurup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtqwurup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtqwurup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtqwurup_failure
cmpq $10, source_character_count
je source_compare_fcvtqwurup_success
cmpb $10, 10(%rax)
je source_compare_fcvtqwurup_success
cmpb $32, 10(%rax)
je source_compare_fcvtqwurup_success
cmpb $35, 10(%rax)
je source_compare_fcvtqwurup_success
source_compare_fcvtqwurup_failure:
movb $1, %al
ret
source_compare_fcvtqwurup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsd:
cmpq $6, source_character_count
jb source_compare_fcvtsd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsd_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsd_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsd_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsd_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsd_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtsd_failure
cmpq $6, source_character_count
je source_compare_fcvtsd_success
cmpb $10, 6(%rax)
je source_compare_fcvtsd_success
cmpb $32, 6(%rax)
je source_compare_fcvtsd_success
cmpb $35, 6(%rax)
je source_compare_fcvtsd_success
source_compare_fcvtsd_failure:
movb $1, %al
ret
source_compare_fcvtsd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsddyn:
cmpq $9, source_character_count
jb source_compare_fcvtsddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsddyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsddyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsddyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsddyn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtsddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtsddyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtsddyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtsddyn_failure
cmpq $9, source_character_count
je source_compare_fcvtsddyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtsddyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtsddyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtsddyn_success
source_compare_fcvtsddyn_failure:
movb $1, %al
ret
source_compare_fcvtsddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsdrdn:
cmpq $9, source_character_count
jb source_compare_fcvtsdrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsdrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsdrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsdrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsdrdn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsdrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtsdrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtsdrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtsdrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtsdrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtsdrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtsdrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtsdrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtsdrdn_success
source_compare_fcvtsdrdn_failure:
movb $1, %al
ret
source_compare_fcvtsdrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsdrmm:
cmpq $9, source_character_count
jb source_compare_fcvtsdrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsdrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsdrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsdrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsdrmm_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsdrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtsdrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtsdrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtsdrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtsdrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtsdrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtsdrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtsdrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtsdrmm_success
source_compare_fcvtsdrmm_failure:
movb $1, %al
ret
source_compare_fcvtsdrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsdrtz:
cmpq $9, source_character_count
jb source_compare_fcvtsdrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsdrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsdrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsdrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsdrtz_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsdrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtsdrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtsdrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtsdrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtsdrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtsdrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtsdrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtsdrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtsdrtz_success
source_compare_fcvtsdrtz_failure:
movb $1, %al
ret
source_compare_fcvtsdrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsdrup:
cmpq $9, source_character_count
jb source_compare_fcvtsdrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsdrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsdrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsdrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsdrup_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsdrup_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtsdrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtsdrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtsdrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtsdrup_failure
cmpq $9, source_character_count
je source_compare_fcvtsdrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtsdrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtsdrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtsdrup_success
source_compare_fcvtsdrup_failure:
movb $1, %al
ret
source_compare_fcvtsdrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsl:
cmpq $6, source_character_count
jb source_compare_fcvtsl_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsl_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsl_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsl_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsl_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsl_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtsl_failure
cmpq $6, source_character_count
je source_compare_fcvtsl_success
cmpb $10, 6(%rax)
je source_compare_fcvtsl_success
cmpb $32, 6(%rax)
je source_compare_fcvtsl_success
cmpb $35, 6(%rax)
je source_compare_fcvtsl_success
source_compare_fcvtsl_failure:
movb $1, %al
ret
source_compare_fcvtsl_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsldyn:
cmpq $9, source_character_count
jb source_compare_fcvtsldyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsldyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsldyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsldyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsldyn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsldyn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtsldyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtsldyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtsldyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtsldyn_failure
cmpq $9, source_character_count
je source_compare_fcvtsldyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtsldyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtsldyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtsldyn_success
source_compare_fcvtsldyn_failure:
movb $1, %al
ret
source_compare_fcvtsldyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtslrdn:
cmpq $9, source_character_count
jb source_compare_fcvtslrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtslrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtslrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtslrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtslrdn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtslrdn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtslrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtslrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtslrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtslrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtslrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtslrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtslrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtslrdn_success
source_compare_fcvtslrdn_failure:
movb $1, %al
ret
source_compare_fcvtslrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtslrmm:
cmpq $9, source_character_count
jb source_compare_fcvtslrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtslrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtslrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtslrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtslrmm_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtslrmm_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtslrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtslrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtslrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtslrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtslrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtslrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtslrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtslrmm_success
source_compare_fcvtslrmm_failure:
movb $1, %al
ret
source_compare_fcvtslrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtslrtz:
cmpq $9, source_character_count
jb source_compare_fcvtslrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtslrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtslrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtslrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtslrtz_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtslrtz_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtslrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtslrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtslrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtslrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtslrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtslrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtslrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtslrtz_success
source_compare_fcvtslrtz_failure:
movb $1, %al
ret
source_compare_fcvtslrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtslrup:
cmpq $9, source_character_count
jb source_compare_fcvtslrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtslrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtslrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtslrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtslrup_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtslrup_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtslrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtslrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtslrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtslrup_failure
cmpq $9, source_character_count
je source_compare_fcvtslrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtslrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtslrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtslrup_success
source_compare_fcvtslrup_failure:
movb $1, %al
ret
source_compare_fcvtslrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtslu:
cmpq $7, source_character_count
jb source_compare_fcvtslu_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtslu_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtslu_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtslu_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtslu_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtslu_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtslu_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtslu_failure
cmpq $7, source_character_count
je source_compare_fcvtslu_success
cmpb $10, 7(%rax)
je source_compare_fcvtslu_success
cmpb $32, 7(%rax)
je source_compare_fcvtslu_success
cmpb $35, 7(%rax)
je source_compare_fcvtslu_success
source_compare_fcvtslu_failure:
movb $1, %al
ret
source_compare_fcvtslu_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsludyn:
cmpq $10, source_character_count
jb source_compare_fcvtsludyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsludyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsludyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsludyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsludyn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsludyn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtsludyn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtsludyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtsludyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtsludyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtsludyn_failure
cmpq $10, source_character_count
je source_compare_fcvtsludyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtsludyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtsludyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtsludyn_success
source_compare_fcvtsludyn_failure:
movb $1, %al
ret
source_compare_fcvtsludyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtslurdn:
cmpq $10, source_character_count
jb source_compare_fcvtslurdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtslurdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtslurdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtslurdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtslurdn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtslurdn_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtslurdn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtslurdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtslurdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtslurdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtslurdn_failure
cmpq $10, source_character_count
je source_compare_fcvtslurdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtslurdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtslurdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtslurdn_success
source_compare_fcvtslurdn_failure:
movb $1, %al
ret
source_compare_fcvtslurdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtslurmm:
cmpq $10, source_character_count
jb source_compare_fcvtslurmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtslurmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtslurmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtslurmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtslurmm_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtslurmm_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtslurmm_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtslurmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtslurmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtslurmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtslurmm_failure
cmpq $10, source_character_count
je source_compare_fcvtslurmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtslurmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtslurmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtslurmm_success
source_compare_fcvtslurmm_failure:
movb $1, %al
ret
source_compare_fcvtslurmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtslurtz:
cmpq $10, source_character_count
jb source_compare_fcvtslurtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtslurtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtslurtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtslurtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtslurtz_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtslurtz_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtslurtz_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtslurtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtslurtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtslurtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtslurtz_failure
cmpq $10, source_character_count
je source_compare_fcvtslurtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtslurtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtslurtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtslurtz_success
source_compare_fcvtslurtz_failure:
movb $1, %al
ret
source_compare_fcvtslurtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtslurup:
cmpq $10, source_character_count
jb source_compare_fcvtslurup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtslurup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtslurup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtslurup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtslurup_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtslurup_failure
cmpb $108, 5(%rax)
jne source_compare_fcvtslurup_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtslurup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtslurup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtslurup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtslurup_failure
cmpq $10, source_character_count
je source_compare_fcvtslurup_success
cmpb $10, 10(%rax)
je source_compare_fcvtslurup_success
cmpb $32, 10(%rax)
je source_compare_fcvtslurup_success
cmpb $35, 10(%rax)
je source_compare_fcvtslurup_success
source_compare_fcvtslurup_failure:
movb $1, %al
ret
source_compare_fcvtslurup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsq:
cmpq $6, source_character_count
jb source_compare_fcvtsq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsq_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsq_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsq_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsq_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsq_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtsq_failure
cmpq $6, source_character_count
je source_compare_fcvtsq_success
cmpb $10, 6(%rax)
je source_compare_fcvtsq_success
cmpb $32, 6(%rax)
je source_compare_fcvtsq_success
cmpb $35, 6(%rax)
je source_compare_fcvtsq_success
source_compare_fcvtsq_failure:
movb $1, %al
ret
source_compare_fcvtsq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsqdyn:
cmpq $9, source_character_count
jb source_compare_fcvtsqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsqdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsqdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsqdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsqdyn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsqdyn_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtsqdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtsqdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtsqdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtsqdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtsqdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtsqdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtsqdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtsqdyn_success
source_compare_fcvtsqdyn_failure:
movb $1, %al
ret
source_compare_fcvtsqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsqrdn:
cmpq $9, source_character_count
jb source_compare_fcvtsqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsqrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsqrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsqrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsqrdn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsqrdn_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtsqrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtsqrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtsqrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtsqrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtsqrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtsqrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtsqrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtsqrdn_success
source_compare_fcvtsqrdn_failure:
movb $1, %al
ret
source_compare_fcvtsqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsqrmm:
cmpq $9, source_character_count
jb source_compare_fcvtsqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsqrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsqrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsqrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsqrmm_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsqrmm_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtsqrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtsqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtsqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtsqrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtsqrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtsqrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtsqrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtsqrmm_success
source_compare_fcvtsqrmm_failure:
movb $1, %al
ret
source_compare_fcvtsqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsqrtz:
cmpq $9, source_character_count
jb source_compare_fcvtsqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsqrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsqrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsqrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsqrtz_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsqrtz_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtsqrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtsqrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtsqrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtsqrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtsqrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtsqrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtsqrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtsqrtz_success
source_compare_fcvtsqrtz_failure:
movb $1, %al
ret
source_compare_fcvtsqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsqrup:
cmpq $9, source_character_count
jb source_compare_fcvtsqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsqrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsqrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsqrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsqrup_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsqrup_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtsqrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtsqrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtsqrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtsqrup_failure
cmpq $9, source_character_count
je source_compare_fcvtsqrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtsqrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtsqrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtsqrup_success
source_compare_fcvtsqrup_failure:
movb $1, %al
ret
source_compare_fcvtsqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtsw:
cmpq $6, source_character_count
jb source_compare_fcvtsw_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtsw_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtsw_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtsw_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtsw_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtsw_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtsw_failure
cmpq $6, source_character_count
je source_compare_fcvtsw_success
cmpb $10, 6(%rax)
je source_compare_fcvtsw_success
cmpb $32, 6(%rax)
je source_compare_fcvtsw_success
cmpb $35, 6(%rax)
je source_compare_fcvtsw_success
source_compare_fcvtsw_failure:
movb $1, %al
ret
source_compare_fcvtsw_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswdyn:
cmpq $9, source_character_count
jb source_compare_fcvtswdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswdyn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswdyn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtswdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtswdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtswdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtswdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtswdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtswdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtswdyn_success
source_compare_fcvtswdyn_failure:
movb $1, %al
ret
source_compare_fcvtswdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswrdn:
cmpq $9, source_character_count
jb source_compare_fcvtswrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswrdn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswrdn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtswrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtswrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtswrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtswrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtswrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtswrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtswrdn_success
source_compare_fcvtswrdn_failure:
movb $1, %al
ret
source_compare_fcvtswrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswrmm:
cmpq $9, source_character_count
jb source_compare_fcvtswrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswrmm_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswrmm_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtswrmm_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtswrmm_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtswrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtswrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtswrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtswrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtswrmm_success
source_compare_fcvtswrmm_failure:
movb $1, %al
ret
source_compare_fcvtswrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswrtz:
cmpq $9, source_character_count
jb source_compare_fcvtswrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswrtz_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswrtz_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtswrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtswrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtswrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtswrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtswrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtswrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtswrtz_success
source_compare_fcvtswrtz_failure:
movb $1, %al
ret
source_compare_fcvtswrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswrup:
cmpq $9, source_character_count
jb source_compare_fcvtswrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswrup_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswrup_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtswrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtswrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtswrup_failure
cmpq $9, source_character_count
je source_compare_fcvtswrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtswrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtswrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtswrup_success
source_compare_fcvtswrup_failure:
movb $1, %al
ret
source_compare_fcvtswrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswu:
cmpq $7, source_character_count
jb source_compare_fcvtswu_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswu_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswu_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswu_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswu_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswu_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswu_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtswu_failure
cmpq $7, source_character_count
je source_compare_fcvtswu_success
cmpb $10, 7(%rax)
je source_compare_fcvtswu_success
cmpb $32, 7(%rax)
je source_compare_fcvtswu_success
cmpb $35, 7(%rax)
je source_compare_fcvtswu_success
source_compare_fcvtswu_failure:
movb $1, %al
ret
source_compare_fcvtswu_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswudyn:
cmpq $10, source_character_count
jb source_compare_fcvtswudyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswudyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswudyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswudyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswudyn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswudyn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswudyn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtswudyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtswudyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtswudyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtswudyn_failure
cmpq $10, source_character_count
je source_compare_fcvtswudyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtswudyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtswudyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtswudyn_success
source_compare_fcvtswudyn_failure:
movb $1, %al
ret
source_compare_fcvtswudyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswurdn:
cmpq $10, source_character_count
jb source_compare_fcvtswurdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswurdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswurdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswurdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswurdn_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswurdn_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswurdn_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtswurdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtswurdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtswurdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtswurdn_failure
cmpq $10, source_character_count
je source_compare_fcvtswurdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtswurdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtswurdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtswurdn_success
source_compare_fcvtswurdn_failure:
movb $1, %al
ret
source_compare_fcvtswurdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswurmm:
cmpq $10, source_character_count
jb source_compare_fcvtswurmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswurmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswurmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswurmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswurmm_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswurmm_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswurmm_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtswurmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtswurmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtswurmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtswurmm_failure
cmpq $10, source_character_count
je source_compare_fcvtswurmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtswurmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtswurmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtswurmm_success
source_compare_fcvtswurmm_failure:
movb $1, %al
ret
source_compare_fcvtswurmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswurtz:
cmpq $10, source_character_count
jb source_compare_fcvtswurtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswurtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswurtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswurtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswurtz_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswurtz_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswurtz_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtswurtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtswurtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtswurtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtswurtz_failure
cmpq $10, source_character_count
je source_compare_fcvtswurtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtswurtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtswurtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtswurtz_success
source_compare_fcvtswurtz_failure:
movb $1, %al
ret
source_compare_fcvtswurtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtswurup:
cmpq $10, source_character_count
jb source_compare_fcvtswurup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtswurup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtswurup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtswurup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtswurup_failure
cmpb $115, 4(%rax)
jne source_compare_fcvtswurup_failure
cmpb $119, 5(%rax)
jne source_compare_fcvtswurup_failure
cmpb $117, 6(%rax)
jne source_compare_fcvtswurup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtswurup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtswurup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtswurup_failure
cmpq $10, source_character_count
je source_compare_fcvtswurup_success
cmpb $10, 10(%rax)
je source_compare_fcvtswurup_success
cmpb $32, 10(%rax)
je source_compare_fcvtswurup_success
cmpb $35, 10(%rax)
je source_compare_fcvtswurup_success
source_compare_fcvtswurup_failure:
movb $1, %al
ret
source_compare_fcvtswurup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwd:
cmpq $6, source_character_count
jb source_compare_fcvtwd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwd_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwd_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwd_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwd_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwd_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtwd_failure
cmpq $6, source_character_count
je source_compare_fcvtwd_success
cmpb $10, 6(%rax)
je source_compare_fcvtwd_success
cmpb $32, 6(%rax)
je source_compare_fcvtwd_success
cmpb $35, 6(%rax)
je source_compare_fcvtwd_success
source_compare_fcvtwd_failure:
movb $1, %al
ret
source_compare_fcvtwd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwddyn:
cmpq $9, source_character_count
jb source_compare_fcvtwddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwddyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwddyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwddyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwddyn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtwddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtwddyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtwddyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtwddyn_failure
cmpq $9, source_character_count
je source_compare_fcvtwddyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtwddyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtwddyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtwddyn_success
source_compare_fcvtwddyn_failure:
movb $1, %al
ret
source_compare_fcvtwddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwdrdn:
cmpq $9, source_character_count
jb source_compare_fcvtwdrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwdrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwdrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwdrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwdrdn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwdrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtwdrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwdrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtwdrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtwdrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtwdrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtwdrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtwdrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtwdrdn_success
source_compare_fcvtwdrdn_failure:
movb $1, %al
ret
source_compare_fcvtwdrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwdrmm:
cmpq $9, source_character_count
jb source_compare_fcvtwdrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwdrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwdrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwdrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwdrmm_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwdrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtwdrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwdrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtwdrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtwdrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtwdrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtwdrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtwdrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtwdrmm_success
source_compare_fcvtwdrmm_failure:
movb $1, %al
ret
source_compare_fcvtwdrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwdrtz:
cmpq $9, source_character_count
jb source_compare_fcvtwdrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwdrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwdrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwdrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwdrtz_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwdrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtwdrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwdrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtwdrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtwdrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtwdrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtwdrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtwdrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtwdrtz_success
source_compare_fcvtwdrtz_failure:
movb $1, %al
ret
source_compare_fcvtwdrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwdrup:
cmpq $9, source_character_count
jb source_compare_fcvtwdrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwdrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwdrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwdrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwdrup_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwdrup_failure
cmpb $100, 5(%rax)
jne source_compare_fcvtwdrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwdrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtwdrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtwdrup_failure
cmpq $9, source_character_count
je source_compare_fcvtwdrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtwdrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtwdrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtwdrup_success
source_compare_fcvtwdrup_failure:
movb $1, %al
ret
source_compare_fcvtwdrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwq:
cmpq $6, source_character_count
jb source_compare_fcvtwq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwq_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwq_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwq_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwq_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwq_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtwq_failure
cmpq $6, source_character_count
je source_compare_fcvtwq_success
cmpb $10, 6(%rax)
je source_compare_fcvtwq_success
cmpb $32, 6(%rax)
je source_compare_fcvtwq_success
cmpb $35, 6(%rax)
je source_compare_fcvtwq_success
source_compare_fcvtwq_failure:
movb $1, %al
ret
source_compare_fcvtwq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwqdyn:
cmpq $9, source_character_count
jb source_compare_fcvtwqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwqdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwqdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwqdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwqdyn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwqdyn_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtwqdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtwqdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtwqdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtwqdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtwqdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtwqdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtwqdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtwqdyn_success
source_compare_fcvtwqdyn_failure:
movb $1, %al
ret
source_compare_fcvtwqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwqrdn:
cmpq $9, source_character_count
jb source_compare_fcvtwqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwqrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwqrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwqrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwqrdn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwqrdn_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtwqrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwqrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtwqrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtwqrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtwqrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtwqrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtwqrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtwqrdn_success
source_compare_fcvtwqrdn_failure:
movb $1, %al
ret
source_compare_fcvtwqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwqrmm:
cmpq $9, source_character_count
jb source_compare_fcvtwqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwqrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwqrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwqrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwqrmm_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwqrmm_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtwqrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtwqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtwqrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtwqrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtwqrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtwqrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtwqrmm_success
source_compare_fcvtwqrmm_failure:
movb $1, %al
ret
source_compare_fcvtwqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwqrtz:
cmpq $9, source_character_count
jb source_compare_fcvtwqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwqrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwqrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwqrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwqrtz_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwqrtz_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtwqrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwqrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtwqrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtwqrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtwqrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtwqrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtwqrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtwqrtz_success
source_compare_fcvtwqrtz_failure:
movb $1, %al
ret
source_compare_fcvtwqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwqrup:
cmpq $9, source_character_count
jb source_compare_fcvtwqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwqrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwqrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwqrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwqrup_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwqrup_failure
cmpb $113, 5(%rax)
jne source_compare_fcvtwqrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwqrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtwqrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtwqrup_failure
cmpq $9, source_character_count
je source_compare_fcvtwqrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtwqrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtwqrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtwqrup_success
source_compare_fcvtwqrup_failure:
movb $1, %al
ret
source_compare_fcvtwqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtws:
cmpq $6, source_character_count
jb source_compare_fcvtws_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtws_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtws_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtws_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtws_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtws_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtws_failure
cmpq $6, source_character_count
je source_compare_fcvtws_success
cmpb $10, 6(%rax)
je source_compare_fcvtws_success
cmpb $32, 6(%rax)
je source_compare_fcvtws_success
cmpb $35, 6(%rax)
je source_compare_fcvtws_success
source_compare_fcvtws_failure:
movb $1, %al
ret
source_compare_fcvtws_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwsdyn:
cmpq $9, source_character_count
jb source_compare_fcvtwsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwsdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwsdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwsdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwsdyn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwsdyn_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtwsdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtwsdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fcvtwsdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtwsdyn_failure
cmpq $9, source_character_count
je source_compare_fcvtwsdyn_success
cmpb $10, 9(%rax)
je source_compare_fcvtwsdyn_success
cmpb $32, 9(%rax)
je source_compare_fcvtwsdyn_success
cmpb $35, 9(%rax)
je source_compare_fcvtwsdyn_success
source_compare_fcvtwsdyn_failure:
movb $1, %al
ret
source_compare_fcvtwsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwsrdn:
cmpq $9, source_character_count
jb source_compare_fcvtwsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwsrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwsrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwsrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwsrdn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwsrdn_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtwsrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwsrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtwsrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fcvtwsrdn_failure
cmpq $9, source_character_count
je source_compare_fcvtwsrdn_success
cmpb $10, 9(%rax)
je source_compare_fcvtwsrdn_success
cmpb $32, 9(%rax)
je source_compare_fcvtwsrdn_success
cmpb $35, 9(%rax)
je source_compare_fcvtwsrdn_success
source_compare_fcvtwsrdn_failure:
movb $1, %al
ret
source_compare_fcvtwsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwsrmm:
cmpq $9, source_character_count
jb source_compare_fcvtwsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwsrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwsrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwsrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwsrmm_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwsrmm_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtwsrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fcvtwsrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtwsrmm_failure
cmpq $9, source_character_count
je source_compare_fcvtwsrmm_success
cmpb $10, 9(%rax)
je source_compare_fcvtwsrmm_success
cmpb $32, 9(%rax)
je source_compare_fcvtwsrmm_success
cmpb $35, 9(%rax)
je source_compare_fcvtwsrmm_success
source_compare_fcvtwsrmm_failure:
movb $1, %al
ret
source_compare_fcvtwsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwsrtz:
cmpq $9, source_character_count
jb source_compare_fcvtwsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwsrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwsrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwsrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwsrtz_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwsrtz_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtwsrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwsrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fcvtwsrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fcvtwsrtz_failure
cmpq $9, source_character_count
je source_compare_fcvtwsrtz_success
cmpb $10, 9(%rax)
je source_compare_fcvtwsrtz_success
cmpb $32, 9(%rax)
je source_compare_fcvtwsrtz_success
cmpb $35, 9(%rax)
je source_compare_fcvtwsrtz_success
source_compare_fcvtwsrtz_failure:
movb $1, %al
ret
source_compare_fcvtwsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwsrup:
cmpq $9, source_character_count
jb source_compare_fcvtwsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwsrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwsrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwsrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwsrup_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwsrup_failure
cmpb $115, 5(%rax)
jne source_compare_fcvtwsrup_failure
cmpb $114, 6(%rax)
jne source_compare_fcvtwsrup_failure
cmpb $117, 7(%rax)
jne source_compare_fcvtwsrup_failure
cmpb $112, 8(%rax)
jne source_compare_fcvtwsrup_failure
cmpq $9, source_character_count
je source_compare_fcvtwsrup_success
cmpb $10, 9(%rax)
je source_compare_fcvtwsrup_success
cmpb $32, 9(%rax)
je source_compare_fcvtwsrup_success
cmpb $35, 9(%rax)
je source_compare_fcvtwsrup_success
source_compare_fcvtwsrup_failure:
movb $1, %al
ret
source_compare_fcvtwsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwud:
cmpq $7, source_character_count
jb source_compare_fcvtwud_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwud_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwud_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwud_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwud_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwud_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwud_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtwud_failure
cmpq $7, source_character_count
je source_compare_fcvtwud_success
cmpb $10, 7(%rax)
je source_compare_fcvtwud_success
cmpb $32, 7(%rax)
je source_compare_fcvtwud_success
cmpb $35, 7(%rax)
je source_compare_fcvtwud_success
source_compare_fcvtwud_failure:
movb $1, %al
ret
source_compare_fcvtwud_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwuddyn:
cmpq $10, source_character_count
jb source_compare_fcvtwuddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwuddyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwuddyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwuddyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwuddyn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwuddyn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwuddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtwuddyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtwuddyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtwuddyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtwuddyn_failure
cmpq $10, source_character_count
je source_compare_fcvtwuddyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtwuddyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtwuddyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtwuddyn_success
source_compare_fcvtwuddyn_failure:
movb $1, %al
ret
source_compare_fcvtwuddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwudrdn:
cmpq $10, source_character_count
jb source_compare_fcvtwudrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwudrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwudrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwudrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwudrdn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwudrdn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwudrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtwudrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwudrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtwudrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtwudrdn_failure
cmpq $10, source_character_count
je source_compare_fcvtwudrdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtwudrdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtwudrdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtwudrdn_success
source_compare_fcvtwudrdn_failure:
movb $1, %al
ret
source_compare_fcvtwudrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwudrmm:
cmpq $10, source_character_count
jb source_compare_fcvtwudrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwudrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwudrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwudrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwudrmm_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwudrmm_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwudrmm_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtwudrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwudrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtwudrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtwudrmm_failure
cmpq $10, source_character_count
je source_compare_fcvtwudrmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtwudrmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtwudrmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtwudrmm_success
source_compare_fcvtwudrmm_failure:
movb $1, %al
ret
source_compare_fcvtwudrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwudrtz:
cmpq $10, source_character_count
jb source_compare_fcvtwudrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwudrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwudrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwudrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwudrtz_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwudrtz_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwudrtz_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtwudrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwudrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtwudrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtwudrtz_failure
cmpq $10, source_character_count
je source_compare_fcvtwudrtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtwudrtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtwudrtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtwudrtz_success
source_compare_fcvtwudrtz_failure:
movb $1, %al
ret
source_compare_fcvtwudrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwudrup:
cmpq $10, source_character_count
jb source_compare_fcvtwudrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwudrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwudrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwudrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwudrup_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwudrup_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwudrup_failure
cmpb $100, 6(%rax)
jne source_compare_fcvtwudrup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwudrup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtwudrup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtwudrup_failure
cmpq $10, source_character_count
je source_compare_fcvtwudrup_success
cmpb $10, 10(%rax)
je source_compare_fcvtwudrup_success
cmpb $32, 10(%rax)
je source_compare_fcvtwudrup_success
cmpb $35, 10(%rax)
je source_compare_fcvtwudrup_success
source_compare_fcvtwudrup_failure:
movb $1, %al
ret
source_compare_fcvtwudrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwuq:
cmpq $7, source_character_count
jb source_compare_fcvtwuq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwuq_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwuq_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwuq_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwuq_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwuq_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwuq_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtwuq_failure
cmpq $7, source_character_count
je source_compare_fcvtwuq_success
cmpb $10, 7(%rax)
je source_compare_fcvtwuq_success
cmpb $32, 7(%rax)
je source_compare_fcvtwuq_success
cmpb $35, 7(%rax)
je source_compare_fcvtwuq_success
source_compare_fcvtwuq_failure:
movb $1, %al
ret
source_compare_fcvtwuq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwuqdyn:
cmpq $10, source_character_count
jb source_compare_fcvtwuqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwuqdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwuqdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwuqdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwuqdyn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwuqdyn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwuqdyn_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtwuqdyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtwuqdyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtwuqdyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtwuqdyn_failure
cmpq $10, source_character_count
je source_compare_fcvtwuqdyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtwuqdyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtwuqdyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtwuqdyn_success
source_compare_fcvtwuqdyn_failure:
movb $1, %al
ret
source_compare_fcvtwuqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwuqrdn:
cmpq $10, source_character_count
jb source_compare_fcvtwuqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwuqrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwuqrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwuqrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwuqrdn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwuqrdn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwuqrdn_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtwuqrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwuqrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtwuqrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtwuqrdn_failure
cmpq $10, source_character_count
je source_compare_fcvtwuqrdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtwuqrdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtwuqrdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtwuqrdn_success
source_compare_fcvtwuqrdn_failure:
movb $1, %al
ret
source_compare_fcvtwuqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwuqrmm:
cmpq $10, source_character_count
jb source_compare_fcvtwuqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwuqrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwuqrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwuqrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwuqrmm_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwuqrmm_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwuqrmm_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtwuqrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwuqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtwuqrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtwuqrmm_failure
cmpq $10, source_character_count
je source_compare_fcvtwuqrmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtwuqrmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtwuqrmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtwuqrmm_success
source_compare_fcvtwuqrmm_failure:
movb $1, %al
ret
source_compare_fcvtwuqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwuqrtz:
cmpq $10, source_character_count
jb source_compare_fcvtwuqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwuqrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwuqrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwuqrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwuqrtz_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwuqrtz_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwuqrtz_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtwuqrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwuqrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtwuqrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtwuqrtz_failure
cmpq $10, source_character_count
je source_compare_fcvtwuqrtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtwuqrtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtwuqrtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtwuqrtz_success
source_compare_fcvtwuqrtz_failure:
movb $1, %al
ret
source_compare_fcvtwuqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwuqrup:
cmpq $10, source_character_count
jb source_compare_fcvtwuqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwuqrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwuqrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwuqrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwuqrup_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwuqrup_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwuqrup_failure
cmpb $113, 6(%rax)
jne source_compare_fcvtwuqrup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwuqrup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtwuqrup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtwuqrup_failure
cmpq $10, source_character_count
je source_compare_fcvtwuqrup_success
cmpb $10, 10(%rax)
je source_compare_fcvtwuqrup_success
cmpb $32, 10(%rax)
je source_compare_fcvtwuqrup_success
cmpb $35, 10(%rax)
je source_compare_fcvtwuqrup_success
source_compare_fcvtwuqrup_failure:
movb $1, %al
ret
source_compare_fcvtwuqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwus:
cmpq $7, source_character_count
jb source_compare_fcvtwus_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwus_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwus_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwus_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwus_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwus_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwus_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtwus_failure
cmpq $7, source_character_count
je source_compare_fcvtwus_success
cmpb $10, 7(%rax)
je source_compare_fcvtwus_success
cmpb $32, 7(%rax)
je source_compare_fcvtwus_success
cmpb $35, 7(%rax)
je source_compare_fcvtwus_success
source_compare_fcvtwus_failure:
movb $1, %al
ret
source_compare_fcvtwus_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwusdyn:
cmpq $10, source_character_count
jb source_compare_fcvtwusdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwusdyn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwusdyn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwusdyn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwusdyn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwusdyn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwusdyn_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtwusdyn_failure
cmpb $100, 7(%rax)
jne source_compare_fcvtwusdyn_failure
cmpb $121, 8(%rax)
jne source_compare_fcvtwusdyn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtwusdyn_failure
cmpq $10, source_character_count
je source_compare_fcvtwusdyn_success
cmpb $10, 10(%rax)
je source_compare_fcvtwusdyn_success
cmpb $32, 10(%rax)
je source_compare_fcvtwusdyn_success
cmpb $35, 10(%rax)
je source_compare_fcvtwusdyn_success
source_compare_fcvtwusdyn_failure:
movb $1, %al
ret
source_compare_fcvtwusdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwusrdn:
cmpq $10, source_character_count
jb source_compare_fcvtwusrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwusrdn_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwusrdn_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwusrdn_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwusrdn_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwusrdn_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwusrdn_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtwusrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwusrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fcvtwusrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fcvtwusrdn_failure
cmpq $10, source_character_count
je source_compare_fcvtwusrdn_success
cmpb $10, 10(%rax)
je source_compare_fcvtwusrdn_success
cmpb $32, 10(%rax)
je source_compare_fcvtwusrdn_success
cmpb $35, 10(%rax)
je source_compare_fcvtwusrdn_success
source_compare_fcvtwusrdn_failure:
movb $1, %al
ret
source_compare_fcvtwusrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwusrmm:
cmpq $10, source_character_count
jb source_compare_fcvtwusrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwusrmm_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwusrmm_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwusrmm_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwusrmm_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwusrmm_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwusrmm_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtwusrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwusrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fcvtwusrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fcvtwusrmm_failure
cmpq $10, source_character_count
je source_compare_fcvtwusrmm_success
cmpb $10, 10(%rax)
je source_compare_fcvtwusrmm_success
cmpb $32, 10(%rax)
je source_compare_fcvtwusrmm_success
cmpb $35, 10(%rax)
je source_compare_fcvtwusrmm_success
source_compare_fcvtwusrmm_failure:
movb $1, %al
ret
source_compare_fcvtwusrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwusrtz:
cmpq $10, source_character_count
jb source_compare_fcvtwusrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwusrtz_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwusrtz_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwusrtz_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwusrtz_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwusrtz_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwusrtz_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtwusrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwusrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fcvtwusrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fcvtwusrtz_failure
cmpq $10, source_character_count
je source_compare_fcvtwusrtz_success
cmpb $10, 10(%rax)
je source_compare_fcvtwusrtz_success
cmpb $32, 10(%rax)
je source_compare_fcvtwusrtz_success
cmpb $35, 10(%rax)
je source_compare_fcvtwusrtz_success
source_compare_fcvtwusrtz_failure:
movb $1, %al
ret
source_compare_fcvtwusrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fcvtwusrup:
cmpq $10, source_character_count
jb source_compare_fcvtwusrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fcvtwusrup_failure
cmpb $99, 1(%rax)
jne source_compare_fcvtwusrup_failure
cmpb $118, 2(%rax)
jne source_compare_fcvtwusrup_failure
cmpb $116, 3(%rax)
jne source_compare_fcvtwusrup_failure
cmpb $119, 4(%rax)
jne source_compare_fcvtwusrup_failure
cmpb $117, 5(%rax)
jne source_compare_fcvtwusrup_failure
cmpb $115, 6(%rax)
jne source_compare_fcvtwusrup_failure
cmpb $114, 7(%rax)
jne source_compare_fcvtwusrup_failure
cmpb $117, 8(%rax)
jne source_compare_fcvtwusrup_failure
cmpb $112, 9(%rax)
jne source_compare_fcvtwusrup_failure
cmpq $10, source_character_count
je source_compare_fcvtwusrup_success
cmpb $10, 10(%rax)
je source_compare_fcvtwusrup_success
cmpb $32, 10(%rax)
je source_compare_fcvtwusrup_success
cmpb $35, 10(%rax)
je source_compare_fcvtwusrup_success
source_compare_fcvtwusrup_failure:
movb $1, %al
ret
source_compare_fcvtwusrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivd:
cmpq $5, source_character_count
jb source_compare_fdivd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivd_failure
cmpb $100, 1(%rax)
jne source_compare_fdivd_failure
cmpb $105, 2(%rax)
jne source_compare_fdivd_failure
cmpb $118, 3(%rax)
jne source_compare_fdivd_failure
cmpb $100, 4(%rax)
jne source_compare_fdivd_failure
cmpq $5, source_character_count
je source_compare_fdivd_success
cmpb $10, 5(%rax)
je source_compare_fdivd_success
cmpb $32, 5(%rax)
je source_compare_fdivd_success
cmpb $35, 5(%rax)
je source_compare_fdivd_success
source_compare_fdivd_failure:
movb $1, %al
ret
source_compare_fdivd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivddyn:
cmpq $8, source_character_count
jb source_compare_fdivddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivddyn_failure
cmpb $100, 1(%rax)
jne source_compare_fdivddyn_failure
cmpb $105, 2(%rax)
jne source_compare_fdivddyn_failure
cmpb $118, 3(%rax)
jne source_compare_fdivddyn_failure
cmpb $100, 4(%rax)
jne source_compare_fdivddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fdivddyn_failure
cmpb $121, 6(%rax)
jne source_compare_fdivddyn_failure
cmpb $110, 7(%rax)
jne source_compare_fdivddyn_failure
cmpq $8, source_character_count
je source_compare_fdivddyn_success
cmpb $10, 8(%rax)
je source_compare_fdivddyn_success
cmpb $32, 8(%rax)
je source_compare_fdivddyn_success
cmpb $35, 8(%rax)
je source_compare_fdivddyn_success
source_compare_fdivddyn_failure:
movb $1, %al
ret
source_compare_fdivddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivdrdn:
cmpq $8, source_character_count
jb source_compare_fdivdrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivdrdn_failure
cmpb $100, 1(%rax)
jne source_compare_fdivdrdn_failure
cmpb $105, 2(%rax)
jne source_compare_fdivdrdn_failure
cmpb $118, 3(%rax)
jne source_compare_fdivdrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fdivdrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fdivdrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fdivdrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fdivdrdn_failure
cmpq $8, source_character_count
je source_compare_fdivdrdn_success
cmpb $10, 8(%rax)
je source_compare_fdivdrdn_success
cmpb $32, 8(%rax)
je source_compare_fdivdrdn_success
cmpb $35, 8(%rax)
je source_compare_fdivdrdn_success
source_compare_fdivdrdn_failure:
movb $1, %al
ret
source_compare_fdivdrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivdrmm:
cmpq $8, source_character_count
jb source_compare_fdivdrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivdrmm_failure
cmpb $100, 1(%rax)
jne source_compare_fdivdrmm_failure
cmpb $105, 2(%rax)
jne source_compare_fdivdrmm_failure
cmpb $118, 3(%rax)
jne source_compare_fdivdrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fdivdrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fdivdrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fdivdrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fdivdrmm_failure
cmpq $8, source_character_count
je source_compare_fdivdrmm_success
cmpb $10, 8(%rax)
je source_compare_fdivdrmm_success
cmpb $32, 8(%rax)
je source_compare_fdivdrmm_success
cmpb $35, 8(%rax)
je source_compare_fdivdrmm_success
source_compare_fdivdrmm_failure:
movb $1, %al
ret
source_compare_fdivdrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivdrtz:
cmpq $8, source_character_count
jb source_compare_fdivdrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivdrtz_failure
cmpb $100, 1(%rax)
jne source_compare_fdivdrtz_failure
cmpb $105, 2(%rax)
jne source_compare_fdivdrtz_failure
cmpb $118, 3(%rax)
jne source_compare_fdivdrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fdivdrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fdivdrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fdivdrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fdivdrtz_failure
cmpq $8, source_character_count
je source_compare_fdivdrtz_success
cmpb $10, 8(%rax)
je source_compare_fdivdrtz_success
cmpb $32, 8(%rax)
je source_compare_fdivdrtz_success
cmpb $35, 8(%rax)
je source_compare_fdivdrtz_success
source_compare_fdivdrtz_failure:
movb $1, %al
ret
source_compare_fdivdrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivdrup:
cmpq $8, source_character_count
jb source_compare_fdivdrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivdrup_failure
cmpb $100, 1(%rax)
jne source_compare_fdivdrup_failure
cmpb $105, 2(%rax)
jne source_compare_fdivdrup_failure
cmpb $118, 3(%rax)
jne source_compare_fdivdrup_failure
cmpb $100, 4(%rax)
jne source_compare_fdivdrup_failure
cmpb $114, 5(%rax)
jne source_compare_fdivdrup_failure
cmpb $117, 6(%rax)
jne source_compare_fdivdrup_failure
cmpb $112, 7(%rax)
jne source_compare_fdivdrup_failure
cmpq $8, source_character_count
je source_compare_fdivdrup_success
cmpb $10, 8(%rax)
je source_compare_fdivdrup_success
cmpb $32, 8(%rax)
je source_compare_fdivdrup_success
cmpb $35, 8(%rax)
je source_compare_fdivdrup_success
source_compare_fdivdrup_failure:
movb $1, %al
ret
source_compare_fdivdrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivq:
cmpq $5, source_character_count
jb source_compare_fdivq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivq_failure
cmpb $100, 1(%rax)
jne source_compare_fdivq_failure
cmpb $105, 2(%rax)
jne source_compare_fdivq_failure
cmpb $118, 3(%rax)
jne source_compare_fdivq_failure
cmpb $113, 4(%rax)
jne source_compare_fdivq_failure
cmpq $5, source_character_count
je source_compare_fdivq_success
cmpb $10, 5(%rax)
je source_compare_fdivq_success
cmpb $32, 5(%rax)
je source_compare_fdivq_success
cmpb $35, 5(%rax)
je source_compare_fdivq_success
source_compare_fdivq_failure:
movb $1, %al
ret
source_compare_fdivq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivqdyn:
cmpq $8, source_character_count
jb source_compare_fdivqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivqdyn_failure
cmpb $100, 1(%rax)
jne source_compare_fdivqdyn_failure
cmpb $105, 2(%rax)
jne source_compare_fdivqdyn_failure
cmpb $118, 3(%rax)
jne source_compare_fdivqdyn_failure
cmpb $113, 4(%rax)
jne source_compare_fdivqdyn_failure
cmpb $100, 5(%rax)
jne source_compare_fdivqdyn_failure
cmpb $121, 6(%rax)
jne source_compare_fdivqdyn_failure
cmpb $110, 7(%rax)
jne source_compare_fdivqdyn_failure
cmpq $8, source_character_count
je source_compare_fdivqdyn_success
cmpb $10, 8(%rax)
je source_compare_fdivqdyn_success
cmpb $32, 8(%rax)
je source_compare_fdivqdyn_success
cmpb $35, 8(%rax)
je source_compare_fdivqdyn_success
source_compare_fdivqdyn_failure:
movb $1, %al
ret
source_compare_fdivqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivqrdn:
cmpq $8, source_character_count
jb source_compare_fdivqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivqrdn_failure
cmpb $100, 1(%rax)
jne source_compare_fdivqrdn_failure
cmpb $105, 2(%rax)
jne source_compare_fdivqrdn_failure
cmpb $118, 3(%rax)
jne source_compare_fdivqrdn_failure
cmpb $113, 4(%rax)
jne source_compare_fdivqrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fdivqrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fdivqrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fdivqrdn_failure
cmpq $8, source_character_count
je source_compare_fdivqrdn_success
cmpb $10, 8(%rax)
je source_compare_fdivqrdn_success
cmpb $32, 8(%rax)
je source_compare_fdivqrdn_success
cmpb $35, 8(%rax)
je source_compare_fdivqrdn_success
source_compare_fdivqrdn_failure:
movb $1, %al
ret
source_compare_fdivqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivqrmm:
cmpq $8, source_character_count
jb source_compare_fdivqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivqrmm_failure
cmpb $100, 1(%rax)
jne source_compare_fdivqrmm_failure
cmpb $105, 2(%rax)
jne source_compare_fdivqrmm_failure
cmpb $118, 3(%rax)
jne source_compare_fdivqrmm_failure
cmpb $113, 4(%rax)
jne source_compare_fdivqrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fdivqrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fdivqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fdivqrmm_failure
cmpq $8, source_character_count
je source_compare_fdivqrmm_success
cmpb $10, 8(%rax)
je source_compare_fdivqrmm_success
cmpb $32, 8(%rax)
je source_compare_fdivqrmm_success
cmpb $35, 8(%rax)
je source_compare_fdivqrmm_success
source_compare_fdivqrmm_failure:
movb $1, %al
ret
source_compare_fdivqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivqrtz:
cmpq $8, source_character_count
jb source_compare_fdivqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivqrtz_failure
cmpb $100, 1(%rax)
jne source_compare_fdivqrtz_failure
cmpb $105, 2(%rax)
jne source_compare_fdivqrtz_failure
cmpb $118, 3(%rax)
jne source_compare_fdivqrtz_failure
cmpb $113, 4(%rax)
jne source_compare_fdivqrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fdivqrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fdivqrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fdivqrtz_failure
cmpq $8, source_character_count
je source_compare_fdivqrtz_success
cmpb $10, 8(%rax)
je source_compare_fdivqrtz_success
cmpb $32, 8(%rax)
je source_compare_fdivqrtz_success
cmpb $35, 8(%rax)
je source_compare_fdivqrtz_success
source_compare_fdivqrtz_failure:
movb $1, %al
ret
source_compare_fdivqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivqrup:
cmpq $8, source_character_count
jb source_compare_fdivqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivqrup_failure
cmpb $100, 1(%rax)
jne source_compare_fdivqrup_failure
cmpb $105, 2(%rax)
jne source_compare_fdivqrup_failure
cmpb $118, 3(%rax)
jne source_compare_fdivqrup_failure
cmpb $113, 4(%rax)
jne source_compare_fdivqrup_failure
cmpb $114, 5(%rax)
jne source_compare_fdivqrup_failure
cmpb $117, 6(%rax)
jne source_compare_fdivqrup_failure
cmpb $112, 7(%rax)
jne source_compare_fdivqrup_failure
cmpq $8, source_character_count
je source_compare_fdivqrup_success
cmpb $10, 8(%rax)
je source_compare_fdivqrup_success
cmpb $32, 8(%rax)
je source_compare_fdivqrup_success
cmpb $35, 8(%rax)
je source_compare_fdivqrup_success
source_compare_fdivqrup_failure:
movb $1, %al
ret
source_compare_fdivqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivs:
cmpq $5, source_character_count
jb source_compare_fdivs_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivs_failure
cmpb $100, 1(%rax)
jne source_compare_fdivs_failure
cmpb $105, 2(%rax)
jne source_compare_fdivs_failure
cmpb $118, 3(%rax)
jne source_compare_fdivs_failure
cmpb $115, 4(%rax)
jne source_compare_fdivs_failure
cmpq $5, source_character_count
je source_compare_fdivs_success
cmpb $10, 5(%rax)
je source_compare_fdivs_success
cmpb $32, 5(%rax)
je source_compare_fdivs_success
cmpb $35, 5(%rax)
je source_compare_fdivs_success
source_compare_fdivs_failure:
movb $1, %al
ret
source_compare_fdivs_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivsdyn:
cmpq $8, source_character_count
jb source_compare_fdivsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivsdyn_failure
cmpb $100, 1(%rax)
jne source_compare_fdivsdyn_failure
cmpb $105, 2(%rax)
jne source_compare_fdivsdyn_failure
cmpb $118, 3(%rax)
jne source_compare_fdivsdyn_failure
cmpb $115, 4(%rax)
jne source_compare_fdivsdyn_failure
cmpb $100, 5(%rax)
jne source_compare_fdivsdyn_failure
cmpb $121, 6(%rax)
jne source_compare_fdivsdyn_failure
cmpb $110, 7(%rax)
jne source_compare_fdivsdyn_failure
cmpq $8, source_character_count
je source_compare_fdivsdyn_success
cmpb $10, 8(%rax)
je source_compare_fdivsdyn_success
cmpb $32, 8(%rax)
je source_compare_fdivsdyn_success
cmpb $35, 8(%rax)
je source_compare_fdivsdyn_success
source_compare_fdivsdyn_failure:
movb $1, %al
ret
source_compare_fdivsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivsrdn:
cmpq $8, source_character_count
jb source_compare_fdivsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivsrdn_failure
cmpb $100, 1(%rax)
jne source_compare_fdivsrdn_failure
cmpb $105, 2(%rax)
jne source_compare_fdivsrdn_failure
cmpb $118, 3(%rax)
jne source_compare_fdivsrdn_failure
cmpb $115, 4(%rax)
jne source_compare_fdivsrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fdivsrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fdivsrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fdivsrdn_failure
cmpq $8, source_character_count
je source_compare_fdivsrdn_success
cmpb $10, 8(%rax)
je source_compare_fdivsrdn_success
cmpb $32, 8(%rax)
je source_compare_fdivsrdn_success
cmpb $35, 8(%rax)
je source_compare_fdivsrdn_success
source_compare_fdivsrdn_failure:
movb $1, %al
ret
source_compare_fdivsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivsrmm:
cmpq $8, source_character_count
jb source_compare_fdivsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivsrmm_failure
cmpb $100, 1(%rax)
jne source_compare_fdivsrmm_failure
cmpb $105, 2(%rax)
jne source_compare_fdivsrmm_failure
cmpb $118, 3(%rax)
jne source_compare_fdivsrmm_failure
cmpb $115, 4(%rax)
jne source_compare_fdivsrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fdivsrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fdivsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fdivsrmm_failure
cmpq $8, source_character_count
je source_compare_fdivsrmm_success
cmpb $10, 8(%rax)
je source_compare_fdivsrmm_success
cmpb $32, 8(%rax)
je source_compare_fdivsrmm_success
cmpb $35, 8(%rax)
je source_compare_fdivsrmm_success
source_compare_fdivsrmm_failure:
movb $1, %al
ret
source_compare_fdivsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivsrtz:
cmpq $8, source_character_count
jb source_compare_fdivsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivsrtz_failure
cmpb $100, 1(%rax)
jne source_compare_fdivsrtz_failure
cmpb $105, 2(%rax)
jne source_compare_fdivsrtz_failure
cmpb $118, 3(%rax)
jne source_compare_fdivsrtz_failure
cmpb $115, 4(%rax)
jne source_compare_fdivsrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fdivsrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fdivsrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fdivsrtz_failure
cmpq $8, source_character_count
je source_compare_fdivsrtz_success
cmpb $10, 8(%rax)
je source_compare_fdivsrtz_success
cmpb $32, 8(%rax)
je source_compare_fdivsrtz_success
cmpb $35, 8(%rax)
je source_compare_fdivsrtz_success
source_compare_fdivsrtz_failure:
movb $1, %al
ret
source_compare_fdivsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fdivsrup:
cmpq $8, source_character_count
jb source_compare_fdivsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fdivsrup_failure
cmpb $100, 1(%rax)
jne source_compare_fdivsrup_failure
cmpb $105, 2(%rax)
jne source_compare_fdivsrup_failure
cmpb $118, 3(%rax)
jne source_compare_fdivsrup_failure
cmpb $115, 4(%rax)
jne source_compare_fdivsrup_failure
cmpb $114, 5(%rax)
jne source_compare_fdivsrup_failure
cmpb $117, 6(%rax)
jne source_compare_fdivsrup_failure
cmpb $112, 7(%rax)
jne source_compare_fdivsrup_failure
cmpq $8, source_character_count
je source_compare_fdivsrup_success
cmpb $10, 8(%rax)
je source_compare_fdivsrup_success
cmpb $32, 8(%rax)
je source_compare_fdivsrup_success
cmpb $35, 8(%rax)
je source_compare_fdivsrup_success
source_compare_fdivsrup_failure:
movb $1, %al
ret
source_compare_fdivsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fence:
cmpq $5, source_character_count
jb source_compare_fence_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fence_failure
cmpb $101, 1(%rax)
jne source_compare_fence_failure
cmpb $110, 2(%rax)
jne source_compare_fence_failure
cmpb $99, 3(%rax)
jne source_compare_fence_failure
cmpb $101, 4(%rax)
jne source_compare_fence_failure
cmpq $5, source_character_count
je source_compare_fence_success
cmpb $10, 5(%rax)
je source_compare_fence_success
cmpb $32, 5(%rax)
je source_compare_fence_success
cmpb $35, 5(%rax)
je source_compare_fence_success
source_compare_fence_failure:
movb $1, %al
ret
source_compare_fence_success:
xorb %al, %al
ret


# out
# al status
source_compare_fencei:
cmpq $6, source_character_count
jb source_compare_fencei_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fencei_failure
cmpb $101, 1(%rax)
jne source_compare_fencei_failure
cmpb $110, 2(%rax)
jne source_compare_fencei_failure
cmpb $99, 3(%rax)
jne source_compare_fencei_failure
cmpb $101, 4(%rax)
jne source_compare_fencei_failure
cmpb $105, 5(%rax)
jne source_compare_fencei_failure
cmpq $6, source_character_count
je source_compare_fencei_success
cmpb $10, 6(%rax)
je source_compare_fencei_success
cmpb $32, 6(%rax)
je source_compare_fencei_success
cmpb $35, 6(%rax)
je source_compare_fencei_success
source_compare_fencei_failure:
movb $1, %al
ret
source_compare_fencei_success:
xorb %al, %al
ret


# out
# al status
source_compare_feqd:
cmpq $4, source_character_count
jb source_compare_feqd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_feqd_failure
cmpb $101, 1(%rax)
jne source_compare_feqd_failure
cmpb $113, 2(%rax)
jne source_compare_feqd_failure
cmpb $100, 3(%rax)
jne source_compare_feqd_failure
cmpq $4, source_character_count
je source_compare_feqd_success
cmpb $10, 4(%rax)
je source_compare_feqd_success
cmpb $32, 4(%rax)
je source_compare_feqd_success
cmpb $35, 4(%rax)
je source_compare_feqd_success
source_compare_feqd_failure:
movb $1, %al
ret
source_compare_feqd_success:
xorb %al, %al
ret


# out
# al status
source_compare_feqq:
cmpq $4, source_character_count
jb source_compare_feqq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_feqq_failure
cmpb $101, 1(%rax)
jne source_compare_feqq_failure
cmpb $113, 2(%rax)
jne source_compare_feqq_failure
cmpb $113, 3(%rax)
jne source_compare_feqq_failure
cmpq $4, source_character_count
je source_compare_feqq_success
cmpb $10, 4(%rax)
je source_compare_feqq_success
cmpb $32, 4(%rax)
je source_compare_feqq_success
cmpb $35, 4(%rax)
je source_compare_feqq_success
source_compare_feqq_failure:
movb $1, %al
ret
source_compare_feqq_success:
xorb %al, %al
ret


# out
# al status
source_compare_feqs:
cmpq $4, source_character_count
jb source_compare_feqs_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_feqs_failure
cmpb $101, 1(%rax)
jne source_compare_feqs_failure
cmpb $113, 2(%rax)
jne source_compare_feqs_failure
cmpb $115, 3(%rax)
jne source_compare_feqs_failure
cmpq $4, source_character_count
je source_compare_feqs_success
cmpb $10, 4(%rax)
je source_compare_feqs_success
cmpb $32, 4(%rax)
je source_compare_feqs_success
cmpb $35, 4(%rax)
je source_compare_feqs_success
source_compare_feqs_failure:
movb $1, %al
ret
source_compare_feqs_success:
xorb %al, %al
ret


# out
# al status
source_compare_fld:
cmpq $3, source_character_count
jb source_compare_fld_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fld_failure
cmpb $108, 1(%rax)
jne source_compare_fld_failure
cmpb $100, 2(%rax)
jne source_compare_fld_failure
cmpq $3, source_character_count
je source_compare_fld_success
cmpb $10, 3(%rax)
je source_compare_fld_success
cmpb $32, 3(%rax)
je source_compare_fld_success
cmpb $35, 3(%rax)
je source_compare_fld_success
source_compare_fld_failure:
movb $1, %al
ret
source_compare_fld_success:
xorb %al, %al
ret


# out
# al status
source_compare_fled:
cmpq $4, source_character_count
jb source_compare_fled_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fled_failure
cmpb $108, 1(%rax)
jne source_compare_fled_failure
cmpb $101, 2(%rax)
jne source_compare_fled_failure
cmpb $100, 3(%rax)
jne source_compare_fled_failure
cmpq $4, source_character_count
je source_compare_fled_success
cmpb $10, 4(%rax)
je source_compare_fled_success
cmpb $32, 4(%rax)
je source_compare_fled_success
cmpb $35, 4(%rax)
je source_compare_fled_success
source_compare_fled_failure:
movb $1, %al
ret
source_compare_fled_success:
xorb %al, %al
ret


# out
# al status
source_compare_fleq:
cmpq $4, source_character_count
jb source_compare_fleq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fleq_failure
cmpb $108, 1(%rax)
jne source_compare_fleq_failure
cmpb $101, 2(%rax)
jne source_compare_fleq_failure
cmpb $113, 3(%rax)
jne source_compare_fleq_failure
cmpq $4, source_character_count
je source_compare_fleq_success
cmpb $10, 4(%rax)
je source_compare_fleq_success
cmpb $32, 4(%rax)
je source_compare_fleq_success
cmpb $35, 4(%rax)
je source_compare_fleq_success
source_compare_fleq_failure:
movb $1, %al
ret
source_compare_fleq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fles:
cmpq $4, source_character_count
jb source_compare_fles_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fles_failure
cmpb $108, 1(%rax)
jne source_compare_fles_failure
cmpb $101, 2(%rax)
jne source_compare_fles_failure
cmpb $115, 3(%rax)
jne source_compare_fles_failure
cmpq $4, source_character_count
je source_compare_fles_success
cmpb $10, 4(%rax)
je source_compare_fles_success
cmpb $32, 4(%rax)
je source_compare_fles_success
cmpb $35, 4(%rax)
je source_compare_fles_success
source_compare_fles_failure:
movb $1, %al
ret
source_compare_fles_success:
xorb %al, %al
ret


# out
# al status
source_compare_flq:
cmpq $3, source_character_count
jb source_compare_flq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_flq_failure
cmpb $108, 1(%rax)
jne source_compare_flq_failure
cmpb $113, 2(%rax)
jne source_compare_flq_failure
cmpq $3, source_character_count
je source_compare_flq_success
cmpb $10, 3(%rax)
je source_compare_flq_success
cmpb $32, 3(%rax)
je source_compare_flq_success
cmpb $35, 3(%rax)
je source_compare_flq_success
source_compare_flq_failure:
movb $1, %al
ret
source_compare_flq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fltd:
cmpq $4, source_character_count
jb source_compare_fltd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fltd_failure
cmpb $108, 1(%rax)
jne source_compare_fltd_failure
cmpb $116, 2(%rax)
jne source_compare_fltd_failure
cmpb $100, 3(%rax)
jne source_compare_fltd_failure
cmpq $4, source_character_count
je source_compare_fltd_success
cmpb $10, 4(%rax)
je source_compare_fltd_success
cmpb $32, 4(%rax)
je source_compare_fltd_success
cmpb $35, 4(%rax)
je source_compare_fltd_success
source_compare_fltd_failure:
movb $1, %al
ret
source_compare_fltd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fltq:
cmpq $4, source_character_count
jb source_compare_fltq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fltq_failure
cmpb $108, 1(%rax)
jne source_compare_fltq_failure
cmpb $116, 2(%rax)
jne source_compare_fltq_failure
cmpb $113, 3(%rax)
jne source_compare_fltq_failure
cmpq $4, source_character_count
je source_compare_fltq_success
cmpb $10, 4(%rax)
je source_compare_fltq_success
cmpb $32, 4(%rax)
je source_compare_fltq_success
cmpb $35, 4(%rax)
je source_compare_fltq_success
source_compare_fltq_failure:
movb $1, %al
ret
source_compare_fltq_success:
xorb %al, %al
ret


# out
# al status
source_compare_flts:
cmpq $4, source_character_count
jb source_compare_flts_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_flts_failure
cmpb $108, 1(%rax)
jne source_compare_flts_failure
cmpb $116, 2(%rax)
jne source_compare_flts_failure
cmpb $115, 3(%rax)
jne source_compare_flts_failure
cmpq $4, source_character_count
je source_compare_flts_success
cmpb $10, 4(%rax)
je source_compare_flts_success
cmpb $32, 4(%rax)
je source_compare_flts_success
cmpb $35, 4(%rax)
je source_compare_flts_success
source_compare_flts_failure:
movb $1, %al
ret
source_compare_flts_success:
xorb %al, %al
ret


# out
# al status
source_compare_flw:
cmpq $3, source_character_count
jb source_compare_flw_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_flw_failure
cmpb $108, 1(%rax)
jne source_compare_flw_failure
cmpb $119, 2(%rax)
jne source_compare_flw_failure
cmpq $3, source_character_count
je source_compare_flw_success
cmpb $10, 3(%rax)
je source_compare_flw_success
cmpb $32, 3(%rax)
je source_compare_flw_success
cmpb $35, 3(%rax)
je source_compare_flw_success
source_compare_flw_failure:
movb $1, %al
ret
source_compare_flw_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddd:
cmpq $6, source_character_count
jb source_compare_fmaddd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddd_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddd_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddd_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddd_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddd_failure
cmpb $100, 5(%rax)
jne source_compare_fmaddd_failure
cmpq $6, source_character_count
je source_compare_fmaddd_success
cmpb $10, 6(%rax)
je source_compare_fmaddd_success
cmpb $32, 6(%rax)
je source_compare_fmaddd_success
cmpb $35, 6(%rax)
je source_compare_fmaddd_success
source_compare_fmaddd_failure:
movb $1, %al
ret
source_compare_fmaddd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddddyn:
cmpq $9, source_character_count
jb source_compare_fmaddddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddddyn_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddddyn_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddddyn_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddddyn_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fmaddddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fmaddddyn_failure
cmpb $121, 7(%rax)
jne source_compare_fmaddddyn_failure
cmpb $110, 8(%rax)
jne source_compare_fmaddddyn_failure
cmpq $9, source_character_count
je source_compare_fmaddddyn_success
cmpb $10, 9(%rax)
je source_compare_fmaddddyn_success
cmpb $32, 9(%rax)
je source_compare_fmaddddyn_success
cmpb $35, 9(%rax)
je source_compare_fmaddddyn_success
source_compare_fmaddddyn_failure:
movb $1, %al
ret
source_compare_fmaddddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmadddrdn:
cmpq $9, source_character_count
jb source_compare_fmadddrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmadddrdn_failure
cmpb $109, 1(%rax)
jne source_compare_fmadddrdn_failure
cmpb $97, 2(%rax)
jne source_compare_fmadddrdn_failure
cmpb $100, 3(%rax)
jne source_compare_fmadddrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fmadddrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fmadddrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fmadddrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fmadddrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fmadddrdn_failure
cmpq $9, source_character_count
je source_compare_fmadddrdn_success
cmpb $10, 9(%rax)
je source_compare_fmadddrdn_success
cmpb $32, 9(%rax)
je source_compare_fmadddrdn_success
cmpb $35, 9(%rax)
je source_compare_fmadddrdn_success
source_compare_fmadddrdn_failure:
movb $1, %al
ret
source_compare_fmadddrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmadddrmm:
cmpq $9, source_character_count
jb source_compare_fmadddrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmadddrmm_failure
cmpb $109, 1(%rax)
jne source_compare_fmadddrmm_failure
cmpb $97, 2(%rax)
jne source_compare_fmadddrmm_failure
cmpb $100, 3(%rax)
jne source_compare_fmadddrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fmadddrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fmadddrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fmadddrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fmadddrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fmadddrmm_failure
cmpq $9, source_character_count
je source_compare_fmadddrmm_success
cmpb $10, 9(%rax)
je source_compare_fmadddrmm_success
cmpb $32, 9(%rax)
je source_compare_fmadddrmm_success
cmpb $35, 9(%rax)
je source_compare_fmadddrmm_success
source_compare_fmadddrmm_failure:
movb $1, %al
ret
source_compare_fmadddrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmadddrtz:
cmpq $9, source_character_count
jb source_compare_fmadddrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmadddrtz_failure
cmpb $109, 1(%rax)
jne source_compare_fmadddrtz_failure
cmpb $97, 2(%rax)
jne source_compare_fmadddrtz_failure
cmpb $100, 3(%rax)
jne source_compare_fmadddrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fmadddrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fmadddrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fmadddrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fmadddrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fmadddrtz_failure
cmpq $9, source_character_count
je source_compare_fmadddrtz_success
cmpb $10, 9(%rax)
je source_compare_fmadddrtz_success
cmpb $32, 9(%rax)
je source_compare_fmadddrtz_success
cmpb $35, 9(%rax)
je source_compare_fmadddrtz_success
source_compare_fmadddrtz_failure:
movb $1, %al
ret
source_compare_fmadddrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmadddrup:
cmpq $9, source_character_count
jb source_compare_fmadddrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmadddrup_failure
cmpb $109, 1(%rax)
jne source_compare_fmadddrup_failure
cmpb $97, 2(%rax)
jne source_compare_fmadddrup_failure
cmpb $100, 3(%rax)
jne source_compare_fmadddrup_failure
cmpb $100, 4(%rax)
jne source_compare_fmadddrup_failure
cmpb $100, 5(%rax)
jne source_compare_fmadddrup_failure
cmpb $114, 6(%rax)
jne source_compare_fmadddrup_failure
cmpb $117, 7(%rax)
jne source_compare_fmadddrup_failure
cmpb $112, 8(%rax)
jne source_compare_fmadddrup_failure
cmpq $9, source_character_count
je source_compare_fmadddrup_success
cmpb $10, 9(%rax)
je source_compare_fmadddrup_success
cmpb $32, 9(%rax)
je source_compare_fmadddrup_success
cmpb $35, 9(%rax)
je source_compare_fmadddrup_success
source_compare_fmadddrup_failure:
movb $1, %al
ret
source_compare_fmadddrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddq:
cmpq $6, source_character_count
jb source_compare_fmaddq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddq_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddq_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddq_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddq_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddq_failure
cmpb $113, 5(%rax)
jne source_compare_fmaddq_failure
cmpq $6, source_character_count
je source_compare_fmaddq_success
cmpb $10, 6(%rax)
je source_compare_fmaddq_success
cmpb $32, 6(%rax)
je source_compare_fmaddq_success
cmpb $35, 6(%rax)
je source_compare_fmaddq_success
source_compare_fmaddq_failure:
movb $1, %al
ret
source_compare_fmaddq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddqdyn:
cmpq $9, source_character_count
jb source_compare_fmaddqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddqdyn_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddqdyn_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddqdyn_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddqdyn_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddqdyn_failure
cmpb $113, 5(%rax)
jne source_compare_fmaddqdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fmaddqdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fmaddqdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fmaddqdyn_failure
cmpq $9, source_character_count
je source_compare_fmaddqdyn_success
cmpb $10, 9(%rax)
je source_compare_fmaddqdyn_success
cmpb $32, 9(%rax)
je source_compare_fmaddqdyn_success
cmpb $35, 9(%rax)
je source_compare_fmaddqdyn_success
source_compare_fmaddqdyn_failure:
movb $1, %al
ret
source_compare_fmaddqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddqrdn:
cmpq $9, source_character_count
jb source_compare_fmaddqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddqrdn_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddqrdn_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddqrdn_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddqrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddqrdn_failure
cmpb $113, 5(%rax)
jne source_compare_fmaddqrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fmaddqrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fmaddqrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fmaddqrdn_failure
cmpq $9, source_character_count
je source_compare_fmaddqrdn_success
cmpb $10, 9(%rax)
je source_compare_fmaddqrdn_success
cmpb $32, 9(%rax)
je source_compare_fmaddqrdn_success
cmpb $35, 9(%rax)
je source_compare_fmaddqrdn_success
source_compare_fmaddqrdn_failure:
movb $1, %al
ret
source_compare_fmaddqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddqrmm:
cmpq $9, source_character_count
jb source_compare_fmaddqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddqrmm_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddqrmm_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddqrmm_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddqrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddqrmm_failure
cmpb $113, 5(%rax)
jne source_compare_fmaddqrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fmaddqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fmaddqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fmaddqrmm_failure
cmpq $9, source_character_count
je source_compare_fmaddqrmm_success
cmpb $10, 9(%rax)
je source_compare_fmaddqrmm_success
cmpb $32, 9(%rax)
je source_compare_fmaddqrmm_success
cmpb $35, 9(%rax)
je source_compare_fmaddqrmm_success
source_compare_fmaddqrmm_failure:
movb $1, %al
ret
source_compare_fmaddqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddqrtz:
cmpq $9, source_character_count
jb source_compare_fmaddqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddqrtz_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddqrtz_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddqrtz_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddqrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddqrtz_failure
cmpb $113, 5(%rax)
jne source_compare_fmaddqrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fmaddqrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fmaddqrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fmaddqrtz_failure
cmpq $9, source_character_count
je source_compare_fmaddqrtz_success
cmpb $10, 9(%rax)
je source_compare_fmaddqrtz_success
cmpb $32, 9(%rax)
je source_compare_fmaddqrtz_success
cmpb $35, 9(%rax)
je source_compare_fmaddqrtz_success
source_compare_fmaddqrtz_failure:
movb $1, %al
ret
source_compare_fmaddqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddqrup:
cmpq $9, source_character_count
jb source_compare_fmaddqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddqrup_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddqrup_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddqrup_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddqrup_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddqrup_failure
cmpb $113, 5(%rax)
jne source_compare_fmaddqrup_failure
cmpb $114, 6(%rax)
jne source_compare_fmaddqrup_failure
cmpb $117, 7(%rax)
jne source_compare_fmaddqrup_failure
cmpb $112, 8(%rax)
jne source_compare_fmaddqrup_failure
cmpq $9, source_character_count
je source_compare_fmaddqrup_success
cmpb $10, 9(%rax)
je source_compare_fmaddqrup_success
cmpb $32, 9(%rax)
je source_compare_fmaddqrup_success
cmpb $35, 9(%rax)
je source_compare_fmaddqrup_success
source_compare_fmaddqrup_failure:
movb $1, %al
ret
source_compare_fmaddqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmadds:
cmpq $6, source_character_count
jb source_compare_fmadds_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmadds_failure
cmpb $109, 1(%rax)
jne source_compare_fmadds_failure
cmpb $97, 2(%rax)
jne source_compare_fmadds_failure
cmpb $100, 3(%rax)
jne source_compare_fmadds_failure
cmpb $100, 4(%rax)
jne source_compare_fmadds_failure
cmpb $115, 5(%rax)
jne source_compare_fmadds_failure
cmpq $6, source_character_count
je source_compare_fmadds_success
cmpb $10, 6(%rax)
je source_compare_fmadds_success
cmpb $32, 6(%rax)
je source_compare_fmadds_success
cmpb $35, 6(%rax)
je source_compare_fmadds_success
source_compare_fmadds_failure:
movb $1, %al
ret
source_compare_fmadds_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddsdyn:
cmpq $9, source_character_count
jb source_compare_fmaddsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddsdyn_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddsdyn_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddsdyn_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddsdyn_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddsdyn_failure
cmpb $115, 5(%rax)
jne source_compare_fmaddsdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fmaddsdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fmaddsdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fmaddsdyn_failure
cmpq $9, source_character_count
je source_compare_fmaddsdyn_success
cmpb $10, 9(%rax)
je source_compare_fmaddsdyn_success
cmpb $32, 9(%rax)
je source_compare_fmaddsdyn_success
cmpb $35, 9(%rax)
je source_compare_fmaddsdyn_success
source_compare_fmaddsdyn_failure:
movb $1, %al
ret
source_compare_fmaddsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddsrdn:
cmpq $9, source_character_count
jb source_compare_fmaddsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddsrdn_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddsrdn_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddsrdn_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddsrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddsrdn_failure
cmpb $115, 5(%rax)
jne source_compare_fmaddsrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fmaddsrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fmaddsrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fmaddsrdn_failure
cmpq $9, source_character_count
je source_compare_fmaddsrdn_success
cmpb $10, 9(%rax)
je source_compare_fmaddsrdn_success
cmpb $32, 9(%rax)
je source_compare_fmaddsrdn_success
cmpb $35, 9(%rax)
je source_compare_fmaddsrdn_success
source_compare_fmaddsrdn_failure:
movb $1, %al
ret
source_compare_fmaddsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddsrmm:
cmpq $9, source_character_count
jb source_compare_fmaddsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddsrmm_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddsrmm_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddsrmm_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddsrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddsrmm_failure
cmpb $115, 5(%rax)
jne source_compare_fmaddsrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fmaddsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fmaddsrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fmaddsrmm_failure
cmpq $9, source_character_count
je source_compare_fmaddsrmm_success
cmpb $10, 9(%rax)
je source_compare_fmaddsrmm_success
cmpb $32, 9(%rax)
je source_compare_fmaddsrmm_success
cmpb $35, 9(%rax)
je source_compare_fmaddsrmm_success
source_compare_fmaddsrmm_failure:
movb $1, %al
ret
source_compare_fmaddsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddsrtz:
cmpq $9, source_character_count
jb source_compare_fmaddsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddsrtz_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddsrtz_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddsrtz_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddsrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddsrtz_failure
cmpb $115, 5(%rax)
jne source_compare_fmaddsrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fmaddsrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fmaddsrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fmaddsrtz_failure
cmpq $9, source_character_count
je source_compare_fmaddsrtz_success
cmpb $10, 9(%rax)
je source_compare_fmaddsrtz_success
cmpb $32, 9(%rax)
je source_compare_fmaddsrtz_success
cmpb $35, 9(%rax)
je source_compare_fmaddsrtz_success
source_compare_fmaddsrtz_failure:
movb $1, %al
ret
source_compare_fmaddsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaddsrup:
cmpq $9, source_character_count
jb source_compare_fmaddsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaddsrup_failure
cmpb $109, 1(%rax)
jne source_compare_fmaddsrup_failure
cmpb $97, 2(%rax)
jne source_compare_fmaddsrup_failure
cmpb $100, 3(%rax)
jne source_compare_fmaddsrup_failure
cmpb $100, 4(%rax)
jne source_compare_fmaddsrup_failure
cmpb $115, 5(%rax)
jne source_compare_fmaddsrup_failure
cmpb $114, 6(%rax)
jne source_compare_fmaddsrup_failure
cmpb $117, 7(%rax)
jne source_compare_fmaddsrup_failure
cmpb $112, 8(%rax)
jne source_compare_fmaddsrup_failure
cmpq $9, source_character_count
je source_compare_fmaddsrup_success
cmpb $10, 9(%rax)
je source_compare_fmaddsrup_success
cmpb $32, 9(%rax)
je source_compare_fmaddsrup_success
cmpb $35, 9(%rax)
je source_compare_fmaddsrup_success
source_compare_fmaddsrup_failure:
movb $1, %al
ret
source_compare_fmaddsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaxd:
cmpq $5, source_character_count
jb source_compare_fmaxd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaxd_failure
cmpb $109, 1(%rax)
jne source_compare_fmaxd_failure
cmpb $97, 2(%rax)
jne source_compare_fmaxd_failure
cmpb $120, 3(%rax)
jne source_compare_fmaxd_failure
cmpb $100, 4(%rax)
jne source_compare_fmaxd_failure
cmpq $5, source_character_count
je source_compare_fmaxd_success
cmpb $10, 5(%rax)
je source_compare_fmaxd_success
cmpb $32, 5(%rax)
je source_compare_fmaxd_success
cmpb $35, 5(%rax)
je source_compare_fmaxd_success
source_compare_fmaxd_failure:
movb $1, %al
ret
source_compare_fmaxd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaxq:
cmpq $5, source_character_count
jb source_compare_fmaxq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaxq_failure
cmpb $109, 1(%rax)
jne source_compare_fmaxq_failure
cmpb $97, 2(%rax)
jne source_compare_fmaxq_failure
cmpb $120, 3(%rax)
jne source_compare_fmaxq_failure
cmpb $113, 4(%rax)
jne source_compare_fmaxq_failure
cmpq $5, source_character_count
je source_compare_fmaxq_success
cmpb $10, 5(%rax)
je source_compare_fmaxq_success
cmpb $32, 5(%rax)
je source_compare_fmaxq_success
cmpb $35, 5(%rax)
je source_compare_fmaxq_success
source_compare_fmaxq_failure:
movb $1, %al
ret
source_compare_fmaxq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmaxs:
cmpq $5, source_character_count
jb source_compare_fmaxs_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmaxs_failure
cmpb $109, 1(%rax)
jne source_compare_fmaxs_failure
cmpb $97, 2(%rax)
jne source_compare_fmaxs_failure
cmpb $120, 3(%rax)
jne source_compare_fmaxs_failure
cmpb $115, 4(%rax)
jne source_compare_fmaxs_failure
cmpq $5, source_character_count
je source_compare_fmaxs_success
cmpb $10, 5(%rax)
je source_compare_fmaxs_success
cmpb $32, 5(%rax)
je source_compare_fmaxs_success
cmpb $35, 5(%rax)
je source_compare_fmaxs_success
source_compare_fmaxs_failure:
movb $1, %al
ret
source_compare_fmaxs_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmind:
cmpq $5, source_character_count
jb source_compare_fmind_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmind_failure
cmpb $109, 1(%rax)
jne source_compare_fmind_failure
cmpb $105, 2(%rax)
jne source_compare_fmind_failure
cmpb $110, 3(%rax)
jne source_compare_fmind_failure
cmpb $100, 4(%rax)
jne source_compare_fmind_failure
cmpq $5, source_character_count
je source_compare_fmind_success
cmpb $10, 5(%rax)
je source_compare_fmind_success
cmpb $32, 5(%rax)
je source_compare_fmind_success
cmpb $35, 5(%rax)
je source_compare_fmind_success
source_compare_fmind_failure:
movb $1, %al
ret
source_compare_fmind_success:
xorb %al, %al
ret


# out
# al status
source_compare_fminq:
cmpq $5, source_character_count
jb source_compare_fminq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fminq_failure
cmpb $109, 1(%rax)
jne source_compare_fminq_failure
cmpb $105, 2(%rax)
jne source_compare_fminq_failure
cmpb $110, 3(%rax)
jne source_compare_fminq_failure
cmpb $113, 4(%rax)
jne source_compare_fminq_failure
cmpq $5, source_character_count
je source_compare_fminq_success
cmpb $10, 5(%rax)
je source_compare_fminq_success
cmpb $32, 5(%rax)
je source_compare_fminq_success
cmpb $35, 5(%rax)
je source_compare_fminq_success
source_compare_fminq_failure:
movb $1, %al
ret
source_compare_fminq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmins:
cmpq $5, source_character_count
jb source_compare_fmins_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmins_failure
cmpb $109, 1(%rax)
jne source_compare_fmins_failure
cmpb $105, 2(%rax)
jne source_compare_fmins_failure
cmpb $110, 3(%rax)
jne source_compare_fmins_failure
cmpb $115, 4(%rax)
jne source_compare_fmins_failure
cmpq $5, source_character_count
je source_compare_fmins_success
cmpb $10, 5(%rax)
je source_compare_fmins_success
cmpb $32, 5(%rax)
je source_compare_fmins_success
cmpb $35, 5(%rax)
je source_compare_fmins_success
source_compare_fmins_failure:
movb $1, %al
ret
source_compare_fmins_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubd:
cmpq $6, source_character_count
jb source_compare_fmsubd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubd_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubd_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubd_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubd_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubd_failure
cmpb $100, 5(%rax)
jne source_compare_fmsubd_failure
cmpq $6, source_character_count
je source_compare_fmsubd_success
cmpb $10, 6(%rax)
je source_compare_fmsubd_success
cmpb $32, 6(%rax)
je source_compare_fmsubd_success
cmpb $35, 6(%rax)
je source_compare_fmsubd_success
source_compare_fmsubd_failure:
movb $1, %al
ret
source_compare_fmsubd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubddyn:
cmpq $9, source_character_count
jb source_compare_fmsubddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubddyn_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubddyn_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubddyn_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubddyn_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fmsubddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fmsubddyn_failure
cmpb $121, 7(%rax)
jne source_compare_fmsubddyn_failure
cmpb $110, 8(%rax)
jne source_compare_fmsubddyn_failure
cmpq $9, source_character_count
je source_compare_fmsubddyn_success
cmpb $10, 9(%rax)
je source_compare_fmsubddyn_success
cmpb $32, 9(%rax)
je source_compare_fmsubddyn_success
cmpb $35, 9(%rax)
je source_compare_fmsubddyn_success
source_compare_fmsubddyn_failure:
movb $1, %al
ret
source_compare_fmsubddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubdrdn:
cmpq $9, source_character_count
jb source_compare_fmsubdrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubdrdn_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubdrdn_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubdrdn_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubdrdn_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubdrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fmsubdrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubdrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fmsubdrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fmsubdrdn_failure
cmpq $9, source_character_count
je source_compare_fmsubdrdn_success
cmpb $10, 9(%rax)
je source_compare_fmsubdrdn_success
cmpb $32, 9(%rax)
je source_compare_fmsubdrdn_success
cmpb $35, 9(%rax)
je source_compare_fmsubdrdn_success
source_compare_fmsubdrdn_failure:
movb $1, %al
ret
source_compare_fmsubdrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubdrmm:
cmpq $9, source_character_count
jb source_compare_fmsubdrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubdrmm_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubdrmm_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubdrmm_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubdrmm_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubdrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fmsubdrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubdrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fmsubdrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fmsubdrmm_failure
cmpq $9, source_character_count
je source_compare_fmsubdrmm_success
cmpb $10, 9(%rax)
je source_compare_fmsubdrmm_success
cmpb $32, 9(%rax)
je source_compare_fmsubdrmm_success
cmpb $35, 9(%rax)
je source_compare_fmsubdrmm_success
source_compare_fmsubdrmm_failure:
movb $1, %al
ret
source_compare_fmsubdrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubdrtz:
cmpq $9, source_character_count
jb source_compare_fmsubdrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubdrtz_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubdrtz_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubdrtz_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubdrtz_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubdrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fmsubdrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubdrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fmsubdrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fmsubdrtz_failure
cmpq $9, source_character_count
je source_compare_fmsubdrtz_success
cmpb $10, 9(%rax)
je source_compare_fmsubdrtz_success
cmpb $32, 9(%rax)
je source_compare_fmsubdrtz_success
cmpb $35, 9(%rax)
je source_compare_fmsubdrtz_success
source_compare_fmsubdrtz_failure:
movb $1, %al
ret
source_compare_fmsubdrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubdrup:
cmpq $9, source_character_count
jb source_compare_fmsubdrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubdrup_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubdrup_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubdrup_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubdrup_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubdrup_failure
cmpb $100, 5(%rax)
jne source_compare_fmsubdrup_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubdrup_failure
cmpb $117, 7(%rax)
jne source_compare_fmsubdrup_failure
cmpb $112, 8(%rax)
jne source_compare_fmsubdrup_failure
cmpq $9, source_character_count
je source_compare_fmsubdrup_success
cmpb $10, 9(%rax)
je source_compare_fmsubdrup_success
cmpb $32, 9(%rax)
je source_compare_fmsubdrup_success
cmpb $35, 9(%rax)
je source_compare_fmsubdrup_success
source_compare_fmsubdrup_failure:
movb $1, %al
ret
source_compare_fmsubdrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubq:
cmpq $6, source_character_count
jb source_compare_fmsubq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubq_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubq_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubq_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubq_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubq_failure
cmpb $113, 5(%rax)
jne source_compare_fmsubq_failure
cmpq $6, source_character_count
je source_compare_fmsubq_success
cmpb $10, 6(%rax)
je source_compare_fmsubq_success
cmpb $32, 6(%rax)
je source_compare_fmsubq_success
cmpb $35, 6(%rax)
je source_compare_fmsubq_success
source_compare_fmsubq_failure:
movb $1, %al
ret
source_compare_fmsubq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubqdyn:
cmpq $9, source_character_count
jb source_compare_fmsubqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubqdyn_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubqdyn_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubqdyn_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubqdyn_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubqdyn_failure
cmpb $113, 5(%rax)
jne source_compare_fmsubqdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fmsubqdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fmsubqdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fmsubqdyn_failure
cmpq $9, source_character_count
je source_compare_fmsubqdyn_success
cmpb $10, 9(%rax)
je source_compare_fmsubqdyn_success
cmpb $32, 9(%rax)
je source_compare_fmsubqdyn_success
cmpb $35, 9(%rax)
je source_compare_fmsubqdyn_success
source_compare_fmsubqdyn_failure:
movb $1, %al
ret
source_compare_fmsubqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubqrdn:
cmpq $9, source_character_count
jb source_compare_fmsubqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubqrdn_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubqrdn_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubqrdn_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubqrdn_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubqrdn_failure
cmpb $113, 5(%rax)
jne source_compare_fmsubqrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubqrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fmsubqrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fmsubqrdn_failure
cmpq $9, source_character_count
je source_compare_fmsubqrdn_success
cmpb $10, 9(%rax)
je source_compare_fmsubqrdn_success
cmpb $32, 9(%rax)
je source_compare_fmsubqrdn_success
cmpb $35, 9(%rax)
je source_compare_fmsubqrdn_success
source_compare_fmsubqrdn_failure:
movb $1, %al
ret
source_compare_fmsubqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubqrmm:
cmpq $9, source_character_count
jb source_compare_fmsubqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubqrmm_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubqrmm_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubqrmm_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubqrmm_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubqrmm_failure
cmpb $113, 5(%rax)
jne source_compare_fmsubqrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fmsubqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fmsubqrmm_failure
cmpq $9, source_character_count
je source_compare_fmsubqrmm_success
cmpb $10, 9(%rax)
je source_compare_fmsubqrmm_success
cmpb $32, 9(%rax)
je source_compare_fmsubqrmm_success
cmpb $35, 9(%rax)
je source_compare_fmsubqrmm_success
source_compare_fmsubqrmm_failure:
movb $1, %al
ret
source_compare_fmsubqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubqrtz:
cmpq $9, source_character_count
jb source_compare_fmsubqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubqrtz_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubqrtz_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubqrtz_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubqrtz_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubqrtz_failure
cmpb $113, 5(%rax)
jne source_compare_fmsubqrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubqrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fmsubqrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fmsubqrtz_failure
cmpq $9, source_character_count
je source_compare_fmsubqrtz_success
cmpb $10, 9(%rax)
je source_compare_fmsubqrtz_success
cmpb $32, 9(%rax)
je source_compare_fmsubqrtz_success
cmpb $35, 9(%rax)
je source_compare_fmsubqrtz_success
source_compare_fmsubqrtz_failure:
movb $1, %al
ret
source_compare_fmsubqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubqrup:
cmpq $9, source_character_count
jb source_compare_fmsubqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubqrup_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubqrup_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubqrup_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubqrup_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubqrup_failure
cmpb $113, 5(%rax)
jne source_compare_fmsubqrup_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubqrup_failure
cmpb $117, 7(%rax)
jne source_compare_fmsubqrup_failure
cmpb $112, 8(%rax)
jne source_compare_fmsubqrup_failure
cmpq $9, source_character_count
je source_compare_fmsubqrup_success
cmpb $10, 9(%rax)
je source_compare_fmsubqrup_success
cmpb $32, 9(%rax)
je source_compare_fmsubqrup_success
cmpb $35, 9(%rax)
je source_compare_fmsubqrup_success
source_compare_fmsubqrup_failure:
movb $1, %al
ret
source_compare_fmsubqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubs:
cmpq $6, source_character_count
jb source_compare_fmsubs_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubs_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubs_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubs_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubs_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubs_failure
cmpb $115, 5(%rax)
jne source_compare_fmsubs_failure
cmpq $6, source_character_count
je source_compare_fmsubs_success
cmpb $10, 6(%rax)
je source_compare_fmsubs_success
cmpb $32, 6(%rax)
je source_compare_fmsubs_success
cmpb $35, 6(%rax)
je source_compare_fmsubs_success
source_compare_fmsubs_failure:
movb $1, %al
ret
source_compare_fmsubs_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubsdyn:
cmpq $9, source_character_count
jb source_compare_fmsubsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubsdyn_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubsdyn_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubsdyn_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubsdyn_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubsdyn_failure
cmpb $115, 5(%rax)
jne source_compare_fmsubsdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fmsubsdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fmsubsdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fmsubsdyn_failure
cmpq $9, source_character_count
je source_compare_fmsubsdyn_success
cmpb $10, 9(%rax)
je source_compare_fmsubsdyn_success
cmpb $32, 9(%rax)
je source_compare_fmsubsdyn_success
cmpb $35, 9(%rax)
je source_compare_fmsubsdyn_success
source_compare_fmsubsdyn_failure:
movb $1, %al
ret
source_compare_fmsubsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubsrdn:
cmpq $9, source_character_count
jb source_compare_fmsubsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubsrdn_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubsrdn_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubsrdn_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubsrdn_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubsrdn_failure
cmpb $115, 5(%rax)
jne source_compare_fmsubsrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubsrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fmsubsrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fmsubsrdn_failure
cmpq $9, source_character_count
je source_compare_fmsubsrdn_success
cmpb $10, 9(%rax)
je source_compare_fmsubsrdn_success
cmpb $32, 9(%rax)
je source_compare_fmsubsrdn_success
cmpb $35, 9(%rax)
je source_compare_fmsubsrdn_success
source_compare_fmsubsrdn_failure:
movb $1, %al
ret
source_compare_fmsubsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubsrmm:
cmpq $9, source_character_count
jb source_compare_fmsubsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubsrmm_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubsrmm_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubsrmm_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubsrmm_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubsrmm_failure
cmpb $115, 5(%rax)
jne source_compare_fmsubsrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fmsubsrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fmsubsrmm_failure
cmpq $9, source_character_count
je source_compare_fmsubsrmm_success
cmpb $10, 9(%rax)
je source_compare_fmsubsrmm_success
cmpb $32, 9(%rax)
je source_compare_fmsubsrmm_success
cmpb $35, 9(%rax)
je source_compare_fmsubsrmm_success
source_compare_fmsubsrmm_failure:
movb $1, %al
ret
source_compare_fmsubsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubsrtz:
cmpq $9, source_character_count
jb source_compare_fmsubsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubsrtz_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubsrtz_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubsrtz_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubsrtz_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubsrtz_failure
cmpb $115, 5(%rax)
jne source_compare_fmsubsrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubsrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fmsubsrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fmsubsrtz_failure
cmpq $9, source_character_count
je source_compare_fmsubsrtz_success
cmpb $10, 9(%rax)
je source_compare_fmsubsrtz_success
cmpb $32, 9(%rax)
je source_compare_fmsubsrtz_success
cmpb $35, 9(%rax)
je source_compare_fmsubsrtz_success
source_compare_fmsubsrtz_failure:
movb $1, %al
ret
source_compare_fmsubsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmsubsrup:
cmpq $9, source_character_count
jb source_compare_fmsubsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmsubsrup_failure
cmpb $109, 1(%rax)
jne source_compare_fmsubsrup_failure
cmpb $115, 2(%rax)
jne source_compare_fmsubsrup_failure
cmpb $117, 3(%rax)
jne source_compare_fmsubsrup_failure
cmpb $98, 4(%rax)
jne source_compare_fmsubsrup_failure
cmpb $115, 5(%rax)
jne source_compare_fmsubsrup_failure
cmpb $114, 6(%rax)
jne source_compare_fmsubsrup_failure
cmpb $117, 7(%rax)
jne source_compare_fmsubsrup_failure
cmpb $112, 8(%rax)
jne source_compare_fmsubsrup_failure
cmpq $9, source_character_count
je source_compare_fmsubsrup_success
cmpb $10, 9(%rax)
je source_compare_fmsubsrup_success
cmpb $32, 9(%rax)
je source_compare_fmsubsrup_success
cmpb $35, 9(%rax)
je source_compare_fmsubsrup_success
source_compare_fmsubsrup_failure:
movb $1, %al
ret
source_compare_fmsubsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmuld:
cmpq $5, source_character_count
jb source_compare_fmuld_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmuld_failure
cmpb $109, 1(%rax)
jne source_compare_fmuld_failure
cmpb $117, 2(%rax)
jne source_compare_fmuld_failure
cmpb $108, 3(%rax)
jne source_compare_fmuld_failure
cmpb $100, 4(%rax)
jne source_compare_fmuld_failure
cmpq $5, source_character_count
je source_compare_fmuld_success
cmpb $10, 5(%rax)
je source_compare_fmuld_success
cmpb $32, 5(%rax)
je source_compare_fmuld_success
cmpb $35, 5(%rax)
je source_compare_fmuld_success
source_compare_fmuld_failure:
movb $1, %al
ret
source_compare_fmuld_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulddyn:
cmpq $8, source_character_count
jb source_compare_fmulddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulddyn_failure
cmpb $109, 1(%rax)
jne source_compare_fmulddyn_failure
cmpb $117, 2(%rax)
jne source_compare_fmulddyn_failure
cmpb $108, 3(%rax)
jne source_compare_fmulddyn_failure
cmpb $100, 4(%rax)
jne source_compare_fmulddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fmulddyn_failure
cmpb $121, 6(%rax)
jne source_compare_fmulddyn_failure
cmpb $110, 7(%rax)
jne source_compare_fmulddyn_failure
cmpq $8, source_character_count
je source_compare_fmulddyn_success
cmpb $10, 8(%rax)
je source_compare_fmulddyn_success
cmpb $32, 8(%rax)
je source_compare_fmulddyn_success
cmpb $35, 8(%rax)
je source_compare_fmulddyn_success
source_compare_fmulddyn_failure:
movb $1, %al
ret
source_compare_fmulddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmuldrdn:
cmpq $8, source_character_count
jb source_compare_fmuldrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmuldrdn_failure
cmpb $109, 1(%rax)
jne source_compare_fmuldrdn_failure
cmpb $117, 2(%rax)
jne source_compare_fmuldrdn_failure
cmpb $108, 3(%rax)
jne source_compare_fmuldrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fmuldrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fmuldrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fmuldrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fmuldrdn_failure
cmpq $8, source_character_count
je source_compare_fmuldrdn_success
cmpb $10, 8(%rax)
je source_compare_fmuldrdn_success
cmpb $32, 8(%rax)
je source_compare_fmuldrdn_success
cmpb $35, 8(%rax)
je source_compare_fmuldrdn_success
source_compare_fmuldrdn_failure:
movb $1, %al
ret
source_compare_fmuldrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmuldrmm:
cmpq $8, source_character_count
jb source_compare_fmuldrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmuldrmm_failure
cmpb $109, 1(%rax)
jne source_compare_fmuldrmm_failure
cmpb $117, 2(%rax)
jne source_compare_fmuldrmm_failure
cmpb $108, 3(%rax)
jne source_compare_fmuldrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fmuldrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fmuldrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fmuldrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fmuldrmm_failure
cmpq $8, source_character_count
je source_compare_fmuldrmm_success
cmpb $10, 8(%rax)
je source_compare_fmuldrmm_success
cmpb $32, 8(%rax)
je source_compare_fmuldrmm_success
cmpb $35, 8(%rax)
je source_compare_fmuldrmm_success
source_compare_fmuldrmm_failure:
movb $1, %al
ret
source_compare_fmuldrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmuldrtz:
cmpq $8, source_character_count
jb source_compare_fmuldrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmuldrtz_failure
cmpb $109, 1(%rax)
jne source_compare_fmuldrtz_failure
cmpb $117, 2(%rax)
jne source_compare_fmuldrtz_failure
cmpb $108, 3(%rax)
jne source_compare_fmuldrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fmuldrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fmuldrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fmuldrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fmuldrtz_failure
cmpq $8, source_character_count
je source_compare_fmuldrtz_success
cmpb $10, 8(%rax)
je source_compare_fmuldrtz_success
cmpb $32, 8(%rax)
je source_compare_fmuldrtz_success
cmpb $35, 8(%rax)
je source_compare_fmuldrtz_success
source_compare_fmuldrtz_failure:
movb $1, %al
ret
source_compare_fmuldrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmuldrup:
cmpq $8, source_character_count
jb source_compare_fmuldrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmuldrup_failure
cmpb $109, 1(%rax)
jne source_compare_fmuldrup_failure
cmpb $117, 2(%rax)
jne source_compare_fmuldrup_failure
cmpb $108, 3(%rax)
jne source_compare_fmuldrup_failure
cmpb $100, 4(%rax)
jne source_compare_fmuldrup_failure
cmpb $114, 5(%rax)
jne source_compare_fmuldrup_failure
cmpb $117, 6(%rax)
jne source_compare_fmuldrup_failure
cmpb $112, 7(%rax)
jne source_compare_fmuldrup_failure
cmpq $8, source_character_count
je source_compare_fmuldrup_success
cmpb $10, 8(%rax)
je source_compare_fmuldrup_success
cmpb $32, 8(%rax)
je source_compare_fmuldrup_success
cmpb $35, 8(%rax)
je source_compare_fmuldrup_success
source_compare_fmuldrup_failure:
movb $1, %al
ret
source_compare_fmuldrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulq:
cmpq $5, source_character_count
jb source_compare_fmulq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulq_failure
cmpb $109, 1(%rax)
jne source_compare_fmulq_failure
cmpb $117, 2(%rax)
jne source_compare_fmulq_failure
cmpb $108, 3(%rax)
jne source_compare_fmulq_failure
cmpb $113, 4(%rax)
jne source_compare_fmulq_failure
cmpq $5, source_character_count
je source_compare_fmulq_success
cmpb $10, 5(%rax)
je source_compare_fmulq_success
cmpb $32, 5(%rax)
je source_compare_fmulq_success
cmpb $35, 5(%rax)
je source_compare_fmulq_success
source_compare_fmulq_failure:
movb $1, %al
ret
source_compare_fmulq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulqdyn:
cmpq $8, source_character_count
jb source_compare_fmulqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulqdyn_failure
cmpb $109, 1(%rax)
jne source_compare_fmulqdyn_failure
cmpb $117, 2(%rax)
jne source_compare_fmulqdyn_failure
cmpb $108, 3(%rax)
jne source_compare_fmulqdyn_failure
cmpb $113, 4(%rax)
jne source_compare_fmulqdyn_failure
cmpb $100, 5(%rax)
jne source_compare_fmulqdyn_failure
cmpb $121, 6(%rax)
jne source_compare_fmulqdyn_failure
cmpb $110, 7(%rax)
jne source_compare_fmulqdyn_failure
cmpq $8, source_character_count
je source_compare_fmulqdyn_success
cmpb $10, 8(%rax)
je source_compare_fmulqdyn_success
cmpb $32, 8(%rax)
je source_compare_fmulqdyn_success
cmpb $35, 8(%rax)
je source_compare_fmulqdyn_success
source_compare_fmulqdyn_failure:
movb $1, %al
ret
source_compare_fmulqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulqrdn:
cmpq $8, source_character_count
jb source_compare_fmulqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulqrdn_failure
cmpb $109, 1(%rax)
jne source_compare_fmulqrdn_failure
cmpb $117, 2(%rax)
jne source_compare_fmulqrdn_failure
cmpb $108, 3(%rax)
jne source_compare_fmulqrdn_failure
cmpb $113, 4(%rax)
jne source_compare_fmulqrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fmulqrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fmulqrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fmulqrdn_failure
cmpq $8, source_character_count
je source_compare_fmulqrdn_success
cmpb $10, 8(%rax)
je source_compare_fmulqrdn_success
cmpb $32, 8(%rax)
je source_compare_fmulqrdn_success
cmpb $35, 8(%rax)
je source_compare_fmulqrdn_success
source_compare_fmulqrdn_failure:
movb $1, %al
ret
source_compare_fmulqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulqrmm:
cmpq $8, source_character_count
jb source_compare_fmulqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulqrmm_failure
cmpb $109, 1(%rax)
jne source_compare_fmulqrmm_failure
cmpb $117, 2(%rax)
jne source_compare_fmulqrmm_failure
cmpb $108, 3(%rax)
jne source_compare_fmulqrmm_failure
cmpb $113, 4(%rax)
jne source_compare_fmulqrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fmulqrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fmulqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fmulqrmm_failure
cmpq $8, source_character_count
je source_compare_fmulqrmm_success
cmpb $10, 8(%rax)
je source_compare_fmulqrmm_success
cmpb $32, 8(%rax)
je source_compare_fmulqrmm_success
cmpb $35, 8(%rax)
je source_compare_fmulqrmm_success
source_compare_fmulqrmm_failure:
movb $1, %al
ret
source_compare_fmulqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulqrtz:
cmpq $8, source_character_count
jb source_compare_fmulqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulqrtz_failure
cmpb $109, 1(%rax)
jne source_compare_fmulqrtz_failure
cmpb $117, 2(%rax)
jne source_compare_fmulqrtz_failure
cmpb $108, 3(%rax)
jne source_compare_fmulqrtz_failure
cmpb $113, 4(%rax)
jne source_compare_fmulqrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fmulqrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fmulqrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fmulqrtz_failure
cmpq $8, source_character_count
je source_compare_fmulqrtz_success
cmpb $10, 8(%rax)
je source_compare_fmulqrtz_success
cmpb $32, 8(%rax)
je source_compare_fmulqrtz_success
cmpb $35, 8(%rax)
je source_compare_fmulqrtz_success
source_compare_fmulqrtz_failure:
movb $1, %al
ret
source_compare_fmulqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulqrup:
cmpq $8, source_character_count
jb source_compare_fmulqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulqrup_failure
cmpb $109, 1(%rax)
jne source_compare_fmulqrup_failure
cmpb $117, 2(%rax)
jne source_compare_fmulqrup_failure
cmpb $108, 3(%rax)
jne source_compare_fmulqrup_failure
cmpb $113, 4(%rax)
jne source_compare_fmulqrup_failure
cmpb $114, 5(%rax)
jne source_compare_fmulqrup_failure
cmpb $117, 6(%rax)
jne source_compare_fmulqrup_failure
cmpb $112, 7(%rax)
jne source_compare_fmulqrup_failure
cmpq $8, source_character_count
je source_compare_fmulqrup_success
cmpb $10, 8(%rax)
je source_compare_fmulqrup_success
cmpb $32, 8(%rax)
je source_compare_fmulqrup_success
cmpb $35, 8(%rax)
je source_compare_fmulqrup_success
source_compare_fmulqrup_failure:
movb $1, %al
ret
source_compare_fmulqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmuls:
cmpq $5, source_character_count
jb source_compare_fmuls_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmuls_failure
cmpb $109, 1(%rax)
jne source_compare_fmuls_failure
cmpb $117, 2(%rax)
jne source_compare_fmuls_failure
cmpb $108, 3(%rax)
jne source_compare_fmuls_failure
cmpb $115, 4(%rax)
jne source_compare_fmuls_failure
cmpq $5, source_character_count
je source_compare_fmuls_success
cmpb $10, 5(%rax)
je source_compare_fmuls_success
cmpb $32, 5(%rax)
je source_compare_fmuls_success
cmpb $35, 5(%rax)
je source_compare_fmuls_success
source_compare_fmuls_failure:
movb $1, %al
ret
source_compare_fmuls_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulsdyn:
cmpq $8, source_character_count
jb source_compare_fmulsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulsdyn_failure
cmpb $109, 1(%rax)
jne source_compare_fmulsdyn_failure
cmpb $117, 2(%rax)
jne source_compare_fmulsdyn_failure
cmpb $108, 3(%rax)
jne source_compare_fmulsdyn_failure
cmpb $115, 4(%rax)
jne source_compare_fmulsdyn_failure
cmpb $100, 5(%rax)
jne source_compare_fmulsdyn_failure
cmpb $121, 6(%rax)
jne source_compare_fmulsdyn_failure
cmpb $110, 7(%rax)
jne source_compare_fmulsdyn_failure
cmpq $8, source_character_count
je source_compare_fmulsdyn_success
cmpb $10, 8(%rax)
je source_compare_fmulsdyn_success
cmpb $32, 8(%rax)
je source_compare_fmulsdyn_success
cmpb $35, 8(%rax)
je source_compare_fmulsdyn_success
source_compare_fmulsdyn_failure:
movb $1, %al
ret
source_compare_fmulsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulsrdn:
cmpq $8, source_character_count
jb source_compare_fmulsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulsrdn_failure
cmpb $109, 1(%rax)
jne source_compare_fmulsrdn_failure
cmpb $117, 2(%rax)
jne source_compare_fmulsrdn_failure
cmpb $108, 3(%rax)
jne source_compare_fmulsrdn_failure
cmpb $115, 4(%rax)
jne source_compare_fmulsrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fmulsrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fmulsrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fmulsrdn_failure
cmpq $8, source_character_count
je source_compare_fmulsrdn_success
cmpb $10, 8(%rax)
je source_compare_fmulsrdn_success
cmpb $32, 8(%rax)
je source_compare_fmulsrdn_success
cmpb $35, 8(%rax)
je source_compare_fmulsrdn_success
source_compare_fmulsrdn_failure:
movb $1, %al
ret
source_compare_fmulsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulsrmm:
cmpq $8, source_character_count
jb source_compare_fmulsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulsrmm_failure
cmpb $109, 1(%rax)
jne source_compare_fmulsrmm_failure
cmpb $117, 2(%rax)
jne source_compare_fmulsrmm_failure
cmpb $108, 3(%rax)
jne source_compare_fmulsrmm_failure
cmpb $115, 4(%rax)
jne source_compare_fmulsrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fmulsrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fmulsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fmulsrmm_failure
cmpq $8, source_character_count
je source_compare_fmulsrmm_success
cmpb $10, 8(%rax)
je source_compare_fmulsrmm_success
cmpb $32, 8(%rax)
je source_compare_fmulsrmm_success
cmpb $35, 8(%rax)
je source_compare_fmulsrmm_success
source_compare_fmulsrmm_failure:
movb $1, %al
ret
source_compare_fmulsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulsrtz:
cmpq $8, source_character_count
jb source_compare_fmulsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulsrtz_failure
cmpb $109, 1(%rax)
jne source_compare_fmulsrtz_failure
cmpb $117, 2(%rax)
jne source_compare_fmulsrtz_failure
cmpb $108, 3(%rax)
jne source_compare_fmulsrtz_failure
cmpb $115, 4(%rax)
jne source_compare_fmulsrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fmulsrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fmulsrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fmulsrtz_failure
cmpq $8, source_character_count
je source_compare_fmulsrtz_success
cmpb $10, 8(%rax)
je source_compare_fmulsrtz_success
cmpb $32, 8(%rax)
je source_compare_fmulsrtz_success
cmpb $35, 8(%rax)
je source_compare_fmulsrtz_success
source_compare_fmulsrtz_failure:
movb $1, %al
ret
source_compare_fmulsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmulsrup:
cmpq $8, source_character_count
jb source_compare_fmulsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmulsrup_failure
cmpb $109, 1(%rax)
jne source_compare_fmulsrup_failure
cmpb $117, 2(%rax)
jne source_compare_fmulsrup_failure
cmpb $108, 3(%rax)
jne source_compare_fmulsrup_failure
cmpb $115, 4(%rax)
jne source_compare_fmulsrup_failure
cmpb $114, 5(%rax)
jne source_compare_fmulsrup_failure
cmpb $117, 6(%rax)
jne source_compare_fmulsrup_failure
cmpb $112, 7(%rax)
jne source_compare_fmulsrup_failure
cmpq $8, source_character_count
je source_compare_fmulsrup_success
cmpb $10, 8(%rax)
je source_compare_fmulsrup_success
cmpb $32, 8(%rax)
je source_compare_fmulsrup_success
cmpb $35, 8(%rax)
je source_compare_fmulsrup_success
source_compare_fmulsrup_failure:
movb $1, %al
ret
source_compare_fmulsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmvdx:
cmpq $5, source_character_count
jb source_compare_fmvdx_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmvdx_failure
cmpb $109, 1(%rax)
jne source_compare_fmvdx_failure
cmpb $118, 2(%rax)
jne source_compare_fmvdx_failure
cmpb $100, 3(%rax)
jne source_compare_fmvdx_failure
cmpb $120, 4(%rax)
jne source_compare_fmvdx_failure
cmpq $5, source_character_count
je source_compare_fmvdx_success
cmpb $10, 5(%rax)
je source_compare_fmvdx_success
cmpb $32, 5(%rax)
je source_compare_fmvdx_success
cmpb $35, 5(%rax)
je source_compare_fmvdx_success
source_compare_fmvdx_failure:
movb $1, %al
ret
source_compare_fmvdx_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmvwx:
cmpq $5, source_character_count
jb source_compare_fmvwx_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmvwx_failure
cmpb $109, 1(%rax)
jne source_compare_fmvwx_failure
cmpb $118, 2(%rax)
jne source_compare_fmvwx_failure
cmpb $119, 3(%rax)
jne source_compare_fmvwx_failure
cmpb $120, 4(%rax)
jne source_compare_fmvwx_failure
cmpq $5, source_character_count
je source_compare_fmvwx_success
cmpb $10, 5(%rax)
je source_compare_fmvwx_success
cmpb $32, 5(%rax)
je source_compare_fmvwx_success
cmpb $35, 5(%rax)
je source_compare_fmvwx_success
source_compare_fmvwx_failure:
movb $1, %al
ret
source_compare_fmvwx_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmvxd:
cmpq $5, source_character_count
jb source_compare_fmvxd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmvxd_failure
cmpb $109, 1(%rax)
jne source_compare_fmvxd_failure
cmpb $118, 2(%rax)
jne source_compare_fmvxd_failure
cmpb $120, 3(%rax)
jne source_compare_fmvxd_failure
cmpb $100, 4(%rax)
jne source_compare_fmvxd_failure
cmpq $5, source_character_count
je source_compare_fmvxd_success
cmpb $10, 5(%rax)
je source_compare_fmvxd_success
cmpb $32, 5(%rax)
je source_compare_fmvxd_success
cmpb $35, 5(%rax)
je source_compare_fmvxd_success
source_compare_fmvxd_failure:
movb $1, %al
ret
source_compare_fmvxd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fmvxw:
cmpq $5, source_character_count
jb source_compare_fmvxw_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fmvxw_failure
cmpb $109, 1(%rax)
jne source_compare_fmvxw_failure
cmpb $118, 2(%rax)
jne source_compare_fmvxw_failure
cmpb $120, 3(%rax)
jne source_compare_fmvxw_failure
cmpb $119, 4(%rax)
jne source_compare_fmvxw_failure
cmpq $5, source_character_count
je source_compare_fmvxw_success
cmpb $10, 5(%rax)
je source_compare_fmvxw_success
cmpb $32, 5(%rax)
je source_compare_fmvxw_success
cmpb $35, 5(%rax)
je source_compare_fmvxw_success
source_compare_fmvxw_failure:
movb $1, %al
ret
source_compare_fmvxw_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddd:
cmpq $7, source_character_count
jb source_compare_fnmaddd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddd_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddd_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddd_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddd_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddd_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddd_failure
cmpb $100, 6(%rax)
jne source_compare_fnmaddd_failure
cmpq $7, source_character_count
je source_compare_fnmaddd_success
cmpb $10, 7(%rax)
je source_compare_fnmaddd_success
cmpb $32, 7(%rax)
je source_compare_fnmaddd_success
cmpb $35, 7(%rax)
je source_compare_fnmaddd_success
source_compare_fnmaddd_failure:
movb $1, %al
ret
source_compare_fnmaddd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddddyn:
cmpq $10, source_character_count
jb source_compare_fnmaddddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddddyn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddddyn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddddyn_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddddyn_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fnmaddddyn_failure
cmpb $100, 7(%rax)
jne source_compare_fnmaddddyn_failure
cmpb $121, 8(%rax)
jne source_compare_fnmaddddyn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmaddddyn_failure
cmpq $10, source_character_count
je source_compare_fnmaddddyn_success
cmpb $10, 10(%rax)
je source_compare_fnmaddddyn_success
cmpb $32, 10(%rax)
je source_compare_fnmaddddyn_success
cmpb $35, 10(%rax)
je source_compare_fnmaddddyn_success
source_compare_fnmaddddyn_failure:
movb $1, %al
ret
source_compare_fnmaddddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmadddrdn:
cmpq $10, source_character_count
jb source_compare_fnmadddrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmadddrdn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmadddrdn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmadddrdn_failure
cmpb $97, 3(%rax)
jne source_compare_fnmadddrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fnmadddrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fnmadddrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fnmadddrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fnmadddrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fnmadddrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmadddrdn_failure
cmpq $10, source_character_count
je source_compare_fnmadddrdn_success
cmpb $10, 10(%rax)
je source_compare_fnmadddrdn_success
cmpb $32, 10(%rax)
je source_compare_fnmadddrdn_success
cmpb $35, 10(%rax)
je source_compare_fnmadddrdn_success
source_compare_fnmadddrdn_failure:
movb $1, %al
ret
source_compare_fnmadddrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmadddrmm:
cmpq $10, source_character_count
jb source_compare_fnmadddrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmadddrmm_failure
cmpb $110, 1(%rax)
jne source_compare_fnmadddrmm_failure
cmpb $109, 2(%rax)
jne source_compare_fnmadddrmm_failure
cmpb $97, 3(%rax)
jne source_compare_fnmadddrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fnmadddrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fnmadddrmm_failure
cmpb $100, 6(%rax)
jne source_compare_fnmadddrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fnmadddrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fnmadddrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fnmadddrmm_failure
cmpq $10, source_character_count
je source_compare_fnmadddrmm_success
cmpb $10, 10(%rax)
je source_compare_fnmadddrmm_success
cmpb $32, 10(%rax)
je source_compare_fnmadddrmm_success
cmpb $35, 10(%rax)
je source_compare_fnmadddrmm_success
source_compare_fnmadddrmm_failure:
movb $1, %al
ret
source_compare_fnmadddrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmadddrtz:
cmpq $10, source_character_count
jb source_compare_fnmadddrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmadddrtz_failure
cmpb $110, 1(%rax)
jne source_compare_fnmadddrtz_failure
cmpb $109, 2(%rax)
jne source_compare_fnmadddrtz_failure
cmpb $97, 3(%rax)
jne source_compare_fnmadddrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fnmadddrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fnmadddrtz_failure
cmpb $100, 6(%rax)
jne source_compare_fnmadddrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fnmadddrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fnmadddrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fnmadddrtz_failure
cmpq $10, source_character_count
je source_compare_fnmadddrtz_success
cmpb $10, 10(%rax)
je source_compare_fnmadddrtz_success
cmpb $32, 10(%rax)
je source_compare_fnmadddrtz_success
cmpb $35, 10(%rax)
je source_compare_fnmadddrtz_success
source_compare_fnmadddrtz_failure:
movb $1, %al
ret
source_compare_fnmadddrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmadddrup:
cmpq $10, source_character_count
jb source_compare_fnmadddrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmadddrup_failure
cmpb $110, 1(%rax)
jne source_compare_fnmadddrup_failure
cmpb $109, 2(%rax)
jne source_compare_fnmadddrup_failure
cmpb $97, 3(%rax)
jne source_compare_fnmadddrup_failure
cmpb $100, 4(%rax)
jne source_compare_fnmadddrup_failure
cmpb $100, 5(%rax)
jne source_compare_fnmadddrup_failure
cmpb $100, 6(%rax)
jne source_compare_fnmadddrup_failure
cmpb $114, 7(%rax)
jne source_compare_fnmadddrup_failure
cmpb $117, 8(%rax)
jne source_compare_fnmadddrup_failure
cmpb $112, 9(%rax)
jne source_compare_fnmadddrup_failure
cmpq $10, source_character_count
je source_compare_fnmadddrup_success
cmpb $10, 10(%rax)
je source_compare_fnmadddrup_success
cmpb $32, 10(%rax)
je source_compare_fnmadddrup_success
cmpb $35, 10(%rax)
je source_compare_fnmadddrup_success
source_compare_fnmadddrup_failure:
movb $1, %al
ret
source_compare_fnmadddrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddq:
cmpq $7, source_character_count
jb source_compare_fnmaddq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddq_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddq_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddq_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddq_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddq_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddq_failure
cmpb $113, 6(%rax)
jne source_compare_fnmaddq_failure
cmpq $7, source_character_count
je source_compare_fnmaddq_success
cmpb $10, 7(%rax)
je source_compare_fnmaddq_success
cmpb $32, 7(%rax)
je source_compare_fnmaddq_success
cmpb $35, 7(%rax)
je source_compare_fnmaddq_success
source_compare_fnmaddq_failure:
movb $1, %al
ret
source_compare_fnmaddq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddqdyn:
cmpq $10, source_character_count
jb source_compare_fnmaddqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddqdyn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddqdyn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddqdyn_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddqdyn_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddqdyn_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddqdyn_failure
cmpb $113, 6(%rax)
jne source_compare_fnmaddqdyn_failure
cmpb $100, 7(%rax)
jne source_compare_fnmaddqdyn_failure
cmpb $121, 8(%rax)
jne source_compare_fnmaddqdyn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmaddqdyn_failure
cmpq $10, source_character_count
je source_compare_fnmaddqdyn_success
cmpb $10, 10(%rax)
je source_compare_fnmaddqdyn_success
cmpb $32, 10(%rax)
je source_compare_fnmaddqdyn_success
cmpb $35, 10(%rax)
je source_compare_fnmaddqdyn_success
source_compare_fnmaddqdyn_failure:
movb $1, %al
ret
source_compare_fnmaddqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddqrdn:
cmpq $10, source_character_count
jb source_compare_fnmaddqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddqrdn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddqrdn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddqrdn_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddqrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddqrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddqrdn_failure
cmpb $113, 6(%rax)
jne source_compare_fnmaddqrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fnmaddqrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fnmaddqrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmaddqrdn_failure
cmpq $10, source_character_count
je source_compare_fnmaddqrdn_success
cmpb $10, 10(%rax)
je source_compare_fnmaddqrdn_success
cmpb $32, 10(%rax)
je source_compare_fnmaddqrdn_success
cmpb $35, 10(%rax)
je source_compare_fnmaddqrdn_success
source_compare_fnmaddqrdn_failure:
movb $1, %al
ret
source_compare_fnmaddqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddqrmm:
cmpq $10, source_character_count
jb source_compare_fnmaddqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddqrmm_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddqrmm_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddqrmm_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddqrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddqrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddqrmm_failure
cmpb $113, 6(%rax)
jne source_compare_fnmaddqrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fnmaddqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fnmaddqrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fnmaddqrmm_failure
cmpq $10, source_character_count
je source_compare_fnmaddqrmm_success
cmpb $10, 10(%rax)
je source_compare_fnmaddqrmm_success
cmpb $32, 10(%rax)
je source_compare_fnmaddqrmm_success
cmpb $35, 10(%rax)
je source_compare_fnmaddqrmm_success
source_compare_fnmaddqrmm_failure:
movb $1, %al
ret
source_compare_fnmaddqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddqrtz:
cmpq $10, source_character_count
jb source_compare_fnmaddqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddqrtz_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddqrtz_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddqrtz_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddqrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddqrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddqrtz_failure
cmpb $113, 6(%rax)
jne source_compare_fnmaddqrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fnmaddqrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fnmaddqrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fnmaddqrtz_failure
cmpq $10, source_character_count
je source_compare_fnmaddqrtz_success
cmpb $10, 10(%rax)
je source_compare_fnmaddqrtz_success
cmpb $32, 10(%rax)
je source_compare_fnmaddqrtz_success
cmpb $35, 10(%rax)
je source_compare_fnmaddqrtz_success
source_compare_fnmaddqrtz_failure:
movb $1, %al
ret
source_compare_fnmaddqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddqrup:
cmpq $10, source_character_count
jb source_compare_fnmaddqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddqrup_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddqrup_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddqrup_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddqrup_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddqrup_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddqrup_failure
cmpb $113, 6(%rax)
jne source_compare_fnmaddqrup_failure
cmpb $114, 7(%rax)
jne source_compare_fnmaddqrup_failure
cmpb $117, 8(%rax)
jne source_compare_fnmaddqrup_failure
cmpb $112, 9(%rax)
jne source_compare_fnmaddqrup_failure
cmpq $10, source_character_count
je source_compare_fnmaddqrup_success
cmpb $10, 10(%rax)
je source_compare_fnmaddqrup_success
cmpb $32, 10(%rax)
je source_compare_fnmaddqrup_success
cmpb $35, 10(%rax)
je source_compare_fnmaddqrup_success
source_compare_fnmaddqrup_failure:
movb $1, %al
ret
source_compare_fnmaddqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmadds:
cmpq $7, source_character_count
jb source_compare_fnmadds_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmadds_failure
cmpb $110, 1(%rax)
jne source_compare_fnmadds_failure
cmpb $109, 2(%rax)
jne source_compare_fnmadds_failure
cmpb $97, 3(%rax)
jne source_compare_fnmadds_failure
cmpb $100, 4(%rax)
jne source_compare_fnmadds_failure
cmpb $100, 5(%rax)
jne source_compare_fnmadds_failure
cmpb $115, 6(%rax)
jne source_compare_fnmadds_failure
cmpq $7, source_character_count
je source_compare_fnmadds_success
cmpb $10, 7(%rax)
je source_compare_fnmadds_success
cmpb $32, 7(%rax)
je source_compare_fnmadds_success
cmpb $35, 7(%rax)
je source_compare_fnmadds_success
source_compare_fnmadds_failure:
movb $1, %al
ret
source_compare_fnmadds_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddsdyn:
cmpq $10, source_character_count
jb source_compare_fnmaddsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddsdyn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddsdyn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddsdyn_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddsdyn_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddsdyn_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddsdyn_failure
cmpb $115, 6(%rax)
jne source_compare_fnmaddsdyn_failure
cmpb $100, 7(%rax)
jne source_compare_fnmaddsdyn_failure
cmpb $121, 8(%rax)
jne source_compare_fnmaddsdyn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmaddsdyn_failure
cmpq $10, source_character_count
je source_compare_fnmaddsdyn_success
cmpb $10, 10(%rax)
je source_compare_fnmaddsdyn_success
cmpb $32, 10(%rax)
je source_compare_fnmaddsdyn_success
cmpb $35, 10(%rax)
je source_compare_fnmaddsdyn_success
source_compare_fnmaddsdyn_failure:
movb $1, %al
ret
source_compare_fnmaddsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddsrdn:
cmpq $10, source_character_count
jb source_compare_fnmaddsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddsrdn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddsrdn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddsrdn_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddsrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddsrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddsrdn_failure
cmpb $115, 6(%rax)
jne source_compare_fnmaddsrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fnmaddsrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fnmaddsrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmaddsrdn_failure
cmpq $10, source_character_count
je source_compare_fnmaddsrdn_success
cmpb $10, 10(%rax)
je source_compare_fnmaddsrdn_success
cmpb $32, 10(%rax)
je source_compare_fnmaddsrdn_success
cmpb $35, 10(%rax)
je source_compare_fnmaddsrdn_success
source_compare_fnmaddsrdn_failure:
movb $1, %al
ret
source_compare_fnmaddsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddsrmm:
cmpq $10, source_character_count
jb source_compare_fnmaddsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddsrmm_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddsrmm_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddsrmm_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddsrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddsrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddsrmm_failure
cmpb $115, 6(%rax)
jne source_compare_fnmaddsrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fnmaddsrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fnmaddsrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fnmaddsrmm_failure
cmpq $10, source_character_count
je source_compare_fnmaddsrmm_success
cmpb $10, 10(%rax)
je source_compare_fnmaddsrmm_success
cmpb $32, 10(%rax)
je source_compare_fnmaddsrmm_success
cmpb $35, 10(%rax)
je source_compare_fnmaddsrmm_success
source_compare_fnmaddsrmm_failure:
movb $1, %al
ret
source_compare_fnmaddsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddsrtz:
cmpq $10, source_character_count
jb source_compare_fnmaddsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddsrtz_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddsrtz_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddsrtz_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddsrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddsrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddsrtz_failure
cmpb $115, 6(%rax)
jne source_compare_fnmaddsrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fnmaddsrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fnmaddsrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fnmaddsrtz_failure
cmpq $10, source_character_count
je source_compare_fnmaddsrtz_success
cmpb $10, 10(%rax)
je source_compare_fnmaddsrtz_success
cmpb $32, 10(%rax)
je source_compare_fnmaddsrtz_success
cmpb $35, 10(%rax)
je source_compare_fnmaddsrtz_success
source_compare_fnmaddsrtz_failure:
movb $1, %al
ret
source_compare_fnmaddsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmaddsrup:
cmpq $10, source_character_count
jb source_compare_fnmaddsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmaddsrup_failure
cmpb $110, 1(%rax)
jne source_compare_fnmaddsrup_failure
cmpb $109, 2(%rax)
jne source_compare_fnmaddsrup_failure
cmpb $97, 3(%rax)
jne source_compare_fnmaddsrup_failure
cmpb $100, 4(%rax)
jne source_compare_fnmaddsrup_failure
cmpb $100, 5(%rax)
jne source_compare_fnmaddsrup_failure
cmpb $115, 6(%rax)
jne source_compare_fnmaddsrup_failure
cmpb $114, 7(%rax)
jne source_compare_fnmaddsrup_failure
cmpb $117, 8(%rax)
jne source_compare_fnmaddsrup_failure
cmpb $112, 9(%rax)
jne source_compare_fnmaddsrup_failure
cmpq $10, source_character_count
je source_compare_fnmaddsrup_success
cmpb $10, 10(%rax)
je source_compare_fnmaddsrup_success
cmpb $32, 10(%rax)
je source_compare_fnmaddsrup_success
cmpb $35, 10(%rax)
je source_compare_fnmaddsrup_success
source_compare_fnmaddsrup_failure:
movb $1, %al
ret
source_compare_fnmaddsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubd:
cmpq $7, source_character_count
jb source_compare_fnmsubd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubd_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubd_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubd_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubd_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubd_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubd_failure
cmpb $100, 6(%rax)
jne source_compare_fnmsubd_failure
cmpq $7, source_character_count
je source_compare_fnmsubd_success
cmpb $10, 7(%rax)
je source_compare_fnmsubd_success
cmpb $32, 7(%rax)
je source_compare_fnmsubd_success
cmpb $35, 7(%rax)
je source_compare_fnmsubd_success
source_compare_fnmsubd_failure:
movb $1, %al
ret
source_compare_fnmsubd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubddyn:
cmpq $10, source_character_count
jb source_compare_fnmsubddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubddyn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubddyn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubddyn_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubddyn_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubddyn_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fnmsubddyn_failure
cmpb $100, 7(%rax)
jne source_compare_fnmsubddyn_failure
cmpb $121, 8(%rax)
jne source_compare_fnmsubddyn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmsubddyn_failure
cmpq $10, source_character_count
je source_compare_fnmsubddyn_success
cmpb $10, 10(%rax)
je source_compare_fnmsubddyn_success
cmpb $32, 10(%rax)
je source_compare_fnmsubddyn_success
cmpb $35, 10(%rax)
je source_compare_fnmsubddyn_success
source_compare_fnmsubddyn_failure:
movb $1, %al
ret
source_compare_fnmsubddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubdrdn:
cmpq $10, source_character_count
jb source_compare_fnmsubdrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubdrdn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubdrdn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubdrdn_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubdrdn_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubdrdn_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubdrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fnmsubdrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubdrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fnmsubdrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmsubdrdn_failure
cmpq $10, source_character_count
je source_compare_fnmsubdrdn_success
cmpb $10, 10(%rax)
je source_compare_fnmsubdrdn_success
cmpb $32, 10(%rax)
je source_compare_fnmsubdrdn_success
cmpb $35, 10(%rax)
je source_compare_fnmsubdrdn_success
source_compare_fnmsubdrdn_failure:
movb $1, %al
ret
source_compare_fnmsubdrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubdrmm:
cmpq $10, source_character_count
jb source_compare_fnmsubdrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubdrmm_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubdrmm_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubdrmm_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubdrmm_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubdrmm_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubdrmm_failure
cmpb $100, 6(%rax)
jne source_compare_fnmsubdrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubdrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fnmsubdrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fnmsubdrmm_failure
cmpq $10, source_character_count
je source_compare_fnmsubdrmm_success
cmpb $10, 10(%rax)
je source_compare_fnmsubdrmm_success
cmpb $32, 10(%rax)
je source_compare_fnmsubdrmm_success
cmpb $35, 10(%rax)
je source_compare_fnmsubdrmm_success
source_compare_fnmsubdrmm_failure:
movb $1, %al
ret
source_compare_fnmsubdrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubdrtz:
cmpq $10, source_character_count
jb source_compare_fnmsubdrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubdrtz_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubdrtz_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubdrtz_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubdrtz_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubdrtz_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubdrtz_failure
cmpb $100, 6(%rax)
jne source_compare_fnmsubdrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubdrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fnmsubdrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fnmsubdrtz_failure
cmpq $10, source_character_count
je source_compare_fnmsubdrtz_success
cmpb $10, 10(%rax)
je source_compare_fnmsubdrtz_success
cmpb $32, 10(%rax)
je source_compare_fnmsubdrtz_success
cmpb $35, 10(%rax)
je source_compare_fnmsubdrtz_success
source_compare_fnmsubdrtz_failure:
movb $1, %al
ret
source_compare_fnmsubdrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubdrup:
cmpq $10, source_character_count
jb source_compare_fnmsubdrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubdrup_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubdrup_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubdrup_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubdrup_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubdrup_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubdrup_failure
cmpb $100, 6(%rax)
jne source_compare_fnmsubdrup_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubdrup_failure
cmpb $117, 8(%rax)
jne source_compare_fnmsubdrup_failure
cmpb $112, 9(%rax)
jne source_compare_fnmsubdrup_failure
cmpq $10, source_character_count
je source_compare_fnmsubdrup_success
cmpb $10, 10(%rax)
je source_compare_fnmsubdrup_success
cmpb $32, 10(%rax)
je source_compare_fnmsubdrup_success
cmpb $35, 10(%rax)
je source_compare_fnmsubdrup_success
source_compare_fnmsubdrup_failure:
movb $1, %al
ret
source_compare_fnmsubdrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubq:
cmpq $7, source_character_count
jb source_compare_fnmsubq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubq_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubq_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubq_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubq_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubq_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubq_failure
cmpb $113, 6(%rax)
jne source_compare_fnmsubq_failure
cmpq $7, source_character_count
je source_compare_fnmsubq_success
cmpb $10, 7(%rax)
je source_compare_fnmsubq_success
cmpb $32, 7(%rax)
je source_compare_fnmsubq_success
cmpb $35, 7(%rax)
je source_compare_fnmsubq_success
source_compare_fnmsubq_failure:
movb $1, %al
ret
source_compare_fnmsubq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubqdyn:
cmpq $10, source_character_count
jb source_compare_fnmsubqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubqdyn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubqdyn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubqdyn_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubqdyn_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubqdyn_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubqdyn_failure
cmpb $113, 6(%rax)
jne source_compare_fnmsubqdyn_failure
cmpb $100, 7(%rax)
jne source_compare_fnmsubqdyn_failure
cmpb $121, 8(%rax)
jne source_compare_fnmsubqdyn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmsubqdyn_failure
cmpq $10, source_character_count
je source_compare_fnmsubqdyn_success
cmpb $10, 10(%rax)
je source_compare_fnmsubqdyn_success
cmpb $32, 10(%rax)
je source_compare_fnmsubqdyn_success
cmpb $35, 10(%rax)
je source_compare_fnmsubqdyn_success
source_compare_fnmsubqdyn_failure:
movb $1, %al
ret
source_compare_fnmsubqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubqrdn:
cmpq $10, source_character_count
jb source_compare_fnmsubqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubqrdn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubqrdn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubqrdn_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubqrdn_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubqrdn_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubqrdn_failure
cmpb $113, 6(%rax)
jne source_compare_fnmsubqrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubqrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fnmsubqrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmsubqrdn_failure
cmpq $10, source_character_count
je source_compare_fnmsubqrdn_success
cmpb $10, 10(%rax)
je source_compare_fnmsubqrdn_success
cmpb $32, 10(%rax)
je source_compare_fnmsubqrdn_success
cmpb $35, 10(%rax)
je source_compare_fnmsubqrdn_success
source_compare_fnmsubqrdn_failure:
movb $1, %al
ret
source_compare_fnmsubqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubqrmm:
cmpq $10, source_character_count
jb source_compare_fnmsubqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubqrmm_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubqrmm_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubqrmm_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubqrmm_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubqrmm_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubqrmm_failure
cmpb $113, 6(%rax)
jne source_compare_fnmsubqrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fnmsubqrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fnmsubqrmm_failure
cmpq $10, source_character_count
je source_compare_fnmsubqrmm_success
cmpb $10, 10(%rax)
je source_compare_fnmsubqrmm_success
cmpb $32, 10(%rax)
je source_compare_fnmsubqrmm_success
cmpb $35, 10(%rax)
je source_compare_fnmsubqrmm_success
source_compare_fnmsubqrmm_failure:
movb $1, %al
ret
source_compare_fnmsubqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubqrtz:
cmpq $10, source_character_count
jb source_compare_fnmsubqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubqrtz_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubqrtz_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubqrtz_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubqrtz_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubqrtz_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubqrtz_failure
cmpb $113, 6(%rax)
jne source_compare_fnmsubqrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubqrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fnmsubqrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fnmsubqrtz_failure
cmpq $10, source_character_count
je source_compare_fnmsubqrtz_success
cmpb $10, 10(%rax)
je source_compare_fnmsubqrtz_success
cmpb $32, 10(%rax)
je source_compare_fnmsubqrtz_success
cmpb $35, 10(%rax)
je source_compare_fnmsubqrtz_success
source_compare_fnmsubqrtz_failure:
movb $1, %al
ret
source_compare_fnmsubqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubqrup:
cmpq $10, source_character_count
jb source_compare_fnmsubqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubqrup_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubqrup_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubqrup_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubqrup_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubqrup_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubqrup_failure
cmpb $113, 6(%rax)
jne source_compare_fnmsubqrup_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubqrup_failure
cmpb $117, 8(%rax)
jne source_compare_fnmsubqrup_failure
cmpb $112, 9(%rax)
jne source_compare_fnmsubqrup_failure
cmpq $10, source_character_count
je source_compare_fnmsubqrup_success
cmpb $10, 10(%rax)
je source_compare_fnmsubqrup_success
cmpb $32, 10(%rax)
je source_compare_fnmsubqrup_success
cmpb $35, 10(%rax)
je source_compare_fnmsubqrup_success
source_compare_fnmsubqrup_failure:
movb $1, %al
ret
source_compare_fnmsubqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubs:
cmpq $7, source_character_count
jb source_compare_fnmsubs_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubs_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubs_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubs_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubs_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubs_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubs_failure
cmpb $115, 6(%rax)
jne source_compare_fnmsubs_failure
cmpq $7, source_character_count
je source_compare_fnmsubs_success
cmpb $10, 7(%rax)
je source_compare_fnmsubs_success
cmpb $32, 7(%rax)
je source_compare_fnmsubs_success
cmpb $35, 7(%rax)
je source_compare_fnmsubs_success
source_compare_fnmsubs_failure:
movb $1, %al
ret
source_compare_fnmsubs_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubsdyn:
cmpq $10, source_character_count
jb source_compare_fnmsubsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubsdyn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubsdyn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubsdyn_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubsdyn_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubsdyn_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubsdyn_failure
cmpb $115, 6(%rax)
jne source_compare_fnmsubsdyn_failure
cmpb $100, 7(%rax)
jne source_compare_fnmsubsdyn_failure
cmpb $121, 8(%rax)
jne source_compare_fnmsubsdyn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmsubsdyn_failure
cmpq $10, source_character_count
je source_compare_fnmsubsdyn_success
cmpb $10, 10(%rax)
je source_compare_fnmsubsdyn_success
cmpb $32, 10(%rax)
je source_compare_fnmsubsdyn_success
cmpb $35, 10(%rax)
je source_compare_fnmsubsdyn_success
source_compare_fnmsubsdyn_failure:
movb $1, %al
ret
source_compare_fnmsubsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubsrdn:
cmpq $10, source_character_count
jb source_compare_fnmsubsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubsrdn_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubsrdn_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubsrdn_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubsrdn_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubsrdn_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubsrdn_failure
cmpb $115, 6(%rax)
jne source_compare_fnmsubsrdn_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubsrdn_failure
cmpb $100, 8(%rax)
jne source_compare_fnmsubsrdn_failure
cmpb $110, 9(%rax)
jne source_compare_fnmsubsrdn_failure
cmpq $10, source_character_count
je source_compare_fnmsubsrdn_success
cmpb $10, 10(%rax)
je source_compare_fnmsubsrdn_success
cmpb $32, 10(%rax)
je source_compare_fnmsubsrdn_success
cmpb $35, 10(%rax)
je source_compare_fnmsubsrdn_success
source_compare_fnmsubsrdn_failure:
movb $1, %al
ret
source_compare_fnmsubsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubsrmm:
cmpq $10, source_character_count
jb source_compare_fnmsubsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubsrmm_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubsrmm_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubsrmm_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubsrmm_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubsrmm_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubsrmm_failure
cmpb $115, 6(%rax)
jne source_compare_fnmsubsrmm_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubsrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fnmsubsrmm_failure
cmpb $109, 9(%rax)
jne source_compare_fnmsubsrmm_failure
cmpq $10, source_character_count
je source_compare_fnmsubsrmm_success
cmpb $10, 10(%rax)
je source_compare_fnmsubsrmm_success
cmpb $32, 10(%rax)
je source_compare_fnmsubsrmm_success
cmpb $35, 10(%rax)
je source_compare_fnmsubsrmm_success
source_compare_fnmsubsrmm_failure:
movb $1, %al
ret
source_compare_fnmsubsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubsrtz:
cmpq $10, source_character_count
jb source_compare_fnmsubsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubsrtz_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubsrtz_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubsrtz_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubsrtz_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubsrtz_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubsrtz_failure
cmpb $115, 6(%rax)
jne source_compare_fnmsubsrtz_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubsrtz_failure
cmpb $116, 8(%rax)
jne source_compare_fnmsubsrtz_failure
cmpb $122, 9(%rax)
jne source_compare_fnmsubsrtz_failure
cmpq $10, source_character_count
je source_compare_fnmsubsrtz_success
cmpb $10, 10(%rax)
je source_compare_fnmsubsrtz_success
cmpb $32, 10(%rax)
je source_compare_fnmsubsrtz_success
cmpb $35, 10(%rax)
je source_compare_fnmsubsrtz_success
source_compare_fnmsubsrtz_failure:
movb $1, %al
ret
source_compare_fnmsubsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fnmsubsrup:
cmpq $10, source_character_count
jb source_compare_fnmsubsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fnmsubsrup_failure
cmpb $110, 1(%rax)
jne source_compare_fnmsubsrup_failure
cmpb $109, 2(%rax)
jne source_compare_fnmsubsrup_failure
cmpb $115, 3(%rax)
jne source_compare_fnmsubsrup_failure
cmpb $117, 4(%rax)
jne source_compare_fnmsubsrup_failure
cmpb $98, 5(%rax)
jne source_compare_fnmsubsrup_failure
cmpb $115, 6(%rax)
jne source_compare_fnmsubsrup_failure
cmpb $114, 7(%rax)
jne source_compare_fnmsubsrup_failure
cmpb $117, 8(%rax)
jne source_compare_fnmsubsrup_failure
cmpb $112, 9(%rax)
jne source_compare_fnmsubsrup_failure
cmpq $10, source_character_count
je source_compare_fnmsubsrup_success
cmpb $10, 10(%rax)
je source_compare_fnmsubsrup_success
cmpb $32, 10(%rax)
je source_compare_fnmsubsrup_success
cmpb $35, 10(%rax)
je source_compare_fnmsubsrup_success
source_compare_fnmsubsrup_failure:
movb $1, %al
ret
source_compare_fnmsubsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsd:
cmpq $3, source_character_count
jb source_compare_fsd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsd_failure
cmpb $115, 1(%rax)
jne source_compare_fsd_failure
cmpb $100, 2(%rax)
jne source_compare_fsd_failure
cmpq $3, source_character_count
je source_compare_fsd_success
cmpb $10, 3(%rax)
je source_compare_fsd_success
cmpb $32, 3(%rax)
je source_compare_fsd_success
cmpb $35, 3(%rax)
je source_compare_fsd_success
source_compare_fsd_failure:
movb $1, %al
ret
source_compare_fsd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsgnjd:
cmpq $6, source_character_count
jb source_compare_fsgnjd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsgnjd_failure
cmpb $115, 1(%rax)
jne source_compare_fsgnjd_failure
cmpb $103, 2(%rax)
jne source_compare_fsgnjd_failure
cmpb $110, 3(%rax)
jne source_compare_fsgnjd_failure
cmpb $106, 4(%rax)
jne source_compare_fsgnjd_failure
cmpb $100, 5(%rax)
jne source_compare_fsgnjd_failure
cmpq $6, source_character_count
je source_compare_fsgnjd_success
cmpb $10, 6(%rax)
je source_compare_fsgnjd_success
cmpb $32, 6(%rax)
je source_compare_fsgnjd_success
cmpb $35, 6(%rax)
je source_compare_fsgnjd_success
source_compare_fsgnjd_failure:
movb $1, %al
ret
source_compare_fsgnjd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsgnjnd:
cmpq $7, source_character_count
jb source_compare_fsgnjnd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsgnjnd_failure
cmpb $115, 1(%rax)
jne source_compare_fsgnjnd_failure
cmpb $103, 2(%rax)
jne source_compare_fsgnjnd_failure
cmpb $110, 3(%rax)
jne source_compare_fsgnjnd_failure
cmpb $106, 4(%rax)
jne source_compare_fsgnjnd_failure
cmpb $110, 5(%rax)
jne source_compare_fsgnjnd_failure
cmpb $100, 6(%rax)
jne source_compare_fsgnjnd_failure
cmpq $7, source_character_count
je source_compare_fsgnjnd_success
cmpb $10, 7(%rax)
je source_compare_fsgnjnd_success
cmpb $32, 7(%rax)
je source_compare_fsgnjnd_success
cmpb $35, 7(%rax)
je source_compare_fsgnjnd_success
source_compare_fsgnjnd_failure:
movb $1, %al
ret
source_compare_fsgnjnd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsgnjnq:
cmpq $7, source_character_count
jb source_compare_fsgnjnq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsgnjnq_failure
cmpb $115, 1(%rax)
jne source_compare_fsgnjnq_failure
cmpb $103, 2(%rax)
jne source_compare_fsgnjnq_failure
cmpb $110, 3(%rax)
jne source_compare_fsgnjnq_failure
cmpb $106, 4(%rax)
jne source_compare_fsgnjnq_failure
cmpb $110, 5(%rax)
jne source_compare_fsgnjnq_failure
cmpb $113, 6(%rax)
jne source_compare_fsgnjnq_failure
cmpq $7, source_character_count
je source_compare_fsgnjnq_success
cmpb $10, 7(%rax)
je source_compare_fsgnjnq_success
cmpb $32, 7(%rax)
je source_compare_fsgnjnq_success
cmpb $35, 7(%rax)
je source_compare_fsgnjnq_success
source_compare_fsgnjnq_failure:
movb $1, %al
ret
source_compare_fsgnjnq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsgnjns:
cmpq $7, source_character_count
jb source_compare_fsgnjns_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsgnjns_failure
cmpb $115, 1(%rax)
jne source_compare_fsgnjns_failure
cmpb $103, 2(%rax)
jne source_compare_fsgnjns_failure
cmpb $110, 3(%rax)
jne source_compare_fsgnjns_failure
cmpb $106, 4(%rax)
jne source_compare_fsgnjns_failure
cmpb $110, 5(%rax)
jne source_compare_fsgnjns_failure
cmpb $115, 6(%rax)
jne source_compare_fsgnjns_failure
cmpq $7, source_character_count
je source_compare_fsgnjns_success
cmpb $10, 7(%rax)
je source_compare_fsgnjns_success
cmpb $32, 7(%rax)
je source_compare_fsgnjns_success
cmpb $35, 7(%rax)
je source_compare_fsgnjns_success
source_compare_fsgnjns_failure:
movb $1, %al
ret
source_compare_fsgnjns_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsgnjq:
cmpq $6, source_character_count
jb source_compare_fsgnjq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsgnjq_failure
cmpb $115, 1(%rax)
jne source_compare_fsgnjq_failure
cmpb $103, 2(%rax)
jne source_compare_fsgnjq_failure
cmpb $110, 3(%rax)
jne source_compare_fsgnjq_failure
cmpb $106, 4(%rax)
jne source_compare_fsgnjq_failure
cmpb $113, 5(%rax)
jne source_compare_fsgnjq_failure
cmpq $6, source_character_count
je source_compare_fsgnjq_success
cmpb $10, 6(%rax)
je source_compare_fsgnjq_success
cmpb $32, 6(%rax)
je source_compare_fsgnjq_success
cmpb $35, 6(%rax)
je source_compare_fsgnjq_success
source_compare_fsgnjq_failure:
movb $1, %al
ret
source_compare_fsgnjq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsgnjs:
cmpq $6, source_character_count
jb source_compare_fsgnjs_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsgnjs_failure
cmpb $115, 1(%rax)
jne source_compare_fsgnjs_failure
cmpb $103, 2(%rax)
jne source_compare_fsgnjs_failure
cmpb $110, 3(%rax)
jne source_compare_fsgnjs_failure
cmpb $106, 4(%rax)
jne source_compare_fsgnjs_failure
cmpb $115, 5(%rax)
jne source_compare_fsgnjs_failure
cmpq $6, source_character_count
je source_compare_fsgnjs_success
cmpb $10, 6(%rax)
je source_compare_fsgnjs_success
cmpb $32, 6(%rax)
je source_compare_fsgnjs_success
cmpb $35, 6(%rax)
je source_compare_fsgnjs_success
source_compare_fsgnjs_failure:
movb $1, %al
ret
source_compare_fsgnjs_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsgnjxd:
cmpq $7, source_character_count
jb source_compare_fsgnjxd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsgnjxd_failure
cmpb $115, 1(%rax)
jne source_compare_fsgnjxd_failure
cmpb $103, 2(%rax)
jne source_compare_fsgnjxd_failure
cmpb $110, 3(%rax)
jne source_compare_fsgnjxd_failure
cmpb $106, 4(%rax)
jne source_compare_fsgnjxd_failure
cmpb $120, 5(%rax)
jne source_compare_fsgnjxd_failure
cmpb $100, 6(%rax)
jne source_compare_fsgnjxd_failure
cmpq $7, source_character_count
je source_compare_fsgnjxd_success
cmpb $10, 7(%rax)
je source_compare_fsgnjxd_success
cmpb $32, 7(%rax)
je source_compare_fsgnjxd_success
cmpb $35, 7(%rax)
je source_compare_fsgnjxd_success
source_compare_fsgnjxd_failure:
movb $1, %al
ret
source_compare_fsgnjxd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsgnjxq:
cmpq $7, source_character_count
jb source_compare_fsgnjxq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsgnjxq_failure
cmpb $115, 1(%rax)
jne source_compare_fsgnjxq_failure
cmpb $103, 2(%rax)
jne source_compare_fsgnjxq_failure
cmpb $110, 3(%rax)
jne source_compare_fsgnjxq_failure
cmpb $106, 4(%rax)
jne source_compare_fsgnjxq_failure
cmpb $120, 5(%rax)
jne source_compare_fsgnjxq_failure
cmpb $113, 6(%rax)
jne source_compare_fsgnjxq_failure
cmpq $7, source_character_count
je source_compare_fsgnjxq_success
cmpb $10, 7(%rax)
je source_compare_fsgnjxq_success
cmpb $32, 7(%rax)
je source_compare_fsgnjxq_success
cmpb $35, 7(%rax)
je source_compare_fsgnjxq_success
source_compare_fsgnjxq_failure:
movb $1, %al
ret
source_compare_fsgnjxq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsgnjxs:
cmpq $7, source_character_count
jb source_compare_fsgnjxs_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsgnjxs_failure
cmpb $115, 1(%rax)
jne source_compare_fsgnjxs_failure
cmpb $103, 2(%rax)
jne source_compare_fsgnjxs_failure
cmpb $110, 3(%rax)
jne source_compare_fsgnjxs_failure
cmpb $106, 4(%rax)
jne source_compare_fsgnjxs_failure
cmpb $120, 5(%rax)
jne source_compare_fsgnjxs_failure
cmpb $115, 6(%rax)
jne source_compare_fsgnjxs_failure
cmpq $7, source_character_count
je source_compare_fsgnjxs_success
cmpb $10, 7(%rax)
je source_compare_fsgnjxs_success
cmpb $32, 7(%rax)
je source_compare_fsgnjxs_success
cmpb $35, 7(%rax)
je source_compare_fsgnjxs_success
source_compare_fsgnjxs_failure:
movb $1, %al
ret
source_compare_fsgnjxs_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsq:
cmpq $3, source_character_count
jb source_compare_fsq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsq_failure
cmpb $115, 1(%rax)
jne source_compare_fsq_failure
cmpb $113, 2(%rax)
jne source_compare_fsq_failure
cmpq $3, source_character_count
je source_compare_fsq_success
cmpb $10, 3(%rax)
je source_compare_fsq_success
cmpb $32, 3(%rax)
je source_compare_fsq_success
cmpb $35, 3(%rax)
je source_compare_fsq_success
source_compare_fsq_failure:
movb $1, %al
ret
source_compare_fsq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtd:
cmpq $6, source_character_count
jb source_compare_fsqrtd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtd_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtd_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtd_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtd_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtd_failure
cmpb $100, 5(%rax)
jne source_compare_fsqrtd_failure
cmpq $6, source_character_count
je source_compare_fsqrtd_success
cmpb $10, 6(%rax)
je source_compare_fsqrtd_success
cmpb $32, 6(%rax)
je source_compare_fsqrtd_success
cmpb $35, 6(%rax)
je source_compare_fsqrtd_success
source_compare_fsqrtd_failure:
movb $1, %al
ret
source_compare_fsqrtd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtddyn:
cmpq $9, source_character_count
jb source_compare_fsqrtddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtddyn_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtddyn_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtddyn_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtddyn_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fsqrtddyn_failure
cmpb $100, 6(%rax)
jne source_compare_fsqrtddyn_failure
cmpb $121, 7(%rax)
jne source_compare_fsqrtddyn_failure
cmpb $110, 8(%rax)
jne source_compare_fsqrtddyn_failure
cmpq $9, source_character_count
je source_compare_fsqrtddyn_success
cmpb $10, 9(%rax)
je source_compare_fsqrtddyn_success
cmpb $32, 9(%rax)
je source_compare_fsqrtddyn_success
cmpb $35, 9(%rax)
je source_compare_fsqrtddyn_success
source_compare_fsqrtddyn_failure:
movb $1, %al
ret
source_compare_fsqrtddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtdrdn:
cmpq $9, source_character_count
jb source_compare_fsqrtdrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtdrdn_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtdrdn_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtdrdn_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtdrdn_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtdrdn_failure
cmpb $100, 5(%rax)
jne source_compare_fsqrtdrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtdrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fsqrtdrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fsqrtdrdn_failure
cmpq $9, source_character_count
je source_compare_fsqrtdrdn_success
cmpb $10, 9(%rax)
je source_compare_fsqrtdrdn_success
cmpb $32, 9(%rax)
je source_compare_fsqrtdrdn_success
cmpb $35, 9(%rax)
je source_compare_fsqrtdrdn_success
source_compare_fsqrtdrdn_failure:
movb $1, %al
ret
source_compare_fsqrtdrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtdrmm:
cmpq $9, source_character_count
jb source_compare_fsqrtdrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtdrmm_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtdrmm_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtdrmm_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtdrmm_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtdrmm_failure
cmpb $100, 5(%rax)
jne source_compare_fsqrtdrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtdrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fsqrtdrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fsqrtdrmm_failure
cmpq $9, source_character_count
je source_compare_fsqrtdrmm_success
cmpb $10, 9(%rax)
je source_compare_fsqrtdrmm_success
cmpb $32, 9(%rax)
je source_compare_fsqrtdrmm_success
cmpb $35, 9(%rax)
je source_compare_fsqrtdrmm_success
source_compare_fsqrtdrmm_failure:
movb $1, %al
ret
source_compare_fsqrtdrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtdrtz:
cmpq $9, source_character_count
jb source_compare_fsqrtdrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtdrtz_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtdrtz_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtdrtz_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtdrtz_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtdrtz_failure
cmpb $100, 5(%rax)
jne source_compare_fsqrtdrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtdrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fsqrtdrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fsqrtdrtz_failure
cmpq $9, source_character_count
je source_compare_fsqrtdrtz_success
cmpb $10, 9(%rax)
je source_compare_fsqrtdrtz_success
cmpb $32, 9(%rax)
je source_compare_fsqrtdrtz_success
cmpb $35, 9(%rax)
je source_compare_fsqrtdrtz_success
source_compare_fsqrtdrtz_failure:
movb $1, %al
ret
source_compare_fsqrtdrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtdrup:
cmpq $9, source_character_count
jb source_compare_fsqrtdrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtdrup_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtdrup_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtdrup_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtdrup_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtdrup_failure
cmpb $100, 5(%rax)
jne source_compare_fsqrtdrup_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtdrup_failure
cmpb $117, 7(%rax)
jne source_compare_fsqrtdrup_failure
cmpb $112, 8(%rax)
jne source_compare_fsqrtdrup_failure
cmpq $9, source_character_count
je source_compare_fsqrtdrup_success
cmpb $10, 9(%rax)
je source_compare_fsqrtdrup_success
cmpb $32, 9(%rax)
je source_compare_fsqrtdrup_success
cmpb $35, 9(%rax)
je source_compare_fsqrtdrup_success
source_compare_fsqrtdrup_failure:
movb $1, %al
ret
source_compare_fsqrtdrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtq:
cmpq $6, source_character_count
jb source_compare_fsqrtq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtq_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtq_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtq_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtq_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtq_failure
cmpb $113, 5(%rax)
jne source_compare_fsqrtq_failure
cmpq $6, source_character_count
je source_compare_fsqrtq_success
cmpb $10, 6(%rax)
je source_compare_fsqrtq_success
cmpb $32, 6(%rax)
je source_compare_fsqrtq_success
cmpb $35, 6(%rax)
je source_compare_fsqrtq_success
source_compare_fsqrtq_failure:
movb $1, %al
ret
source_compare_fsqrtq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtqdyn:
cmpq $9, source_character_count
jb source_compare_fsqrtqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtqdyn_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtqdyn_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtqdyn_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtqdyn_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtqdyn_failure
cmpb $113, 5(%rax)
jne source_compare_fsqrtqdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fsqrtqdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fsqrtqdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fsqrtqdyn_failure
cmpq $9, source_character_count
je source_compare_fsqrtqdyn_success
cmpb $10, 9(%rax)
je source_compare_fsqrtqdyn_success
cmpb $32, 9(%rax)
je source_compare_fsqrtqdyn_success
cmpb $35, 9(%rax)
je source_compare_fsqrtqdyn_success
source_compare_fsqrtqdyn_failure:
movb $1, %al
ret
source_compare_fsqrtqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtqrdn:
cmpq $9, source_character_count
jb source_compare_fsqrtqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtqrdn_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtqrdn_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtqrdn_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtqrdn_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtqrdn_failure
cmpb $113, 5(%rax)
jne source_compare_fsqrtqrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtqrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fsqrtqrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fsqrtqrdn_failure
cmpq $9, source_character_count
je source_compare_fsqrtqrdn_success
cmpb $10, 9(%rax)
je source_compare_fsqrtqrdn_success
cmpb $32, 9(%rax)
je source_compare_fsqrtqrdn_success
cmpb $35, 9(%rax)
je source_compare_fsqrtqrdn_success
source_compare_fsqrtqrdn_failure:
movb $1, %al
ret
source_compare_fsqrtqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtqrmm:
cmpq $9, source_character_count
jb source_compare_fsqrtqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtqrmm_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtqrmm_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtqrmm_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtqrmm_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtqrmm_failure
cmpb $113, 5(%rax)
jne source_compare_fsqrtqrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fsqrtqrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fsqrtqrmm_failure
cmpq $9, source_character_count
je source_compare_fsqrtqrmm_success
cmpb $10, 9(%rax)
je source_compare_fsqrtqrmm_success
cmpb $32, 9(%rax)
je source_compare_fsqrtqrmm_success
cmpb $35, 9(%rax)
je source_compare_fsqrtqrmm_success
source_compare_fsqrtqrmm_failure:
movb $1, %al
ret
source_compare_fsqrtqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtqrtz:
cmpq $9, source_character_count
jb source_compare_fsqrtqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtqrtz_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtqrtz_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtqrtz_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtqrtz_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtqrtz_failure
cmpb $113, 5(%rax)
jne source_compare_fsqrtqrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtqrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fsqrtqrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fsqrtqrtz_failure
cmpq $9, source_character_count
je source_compare_fsqrtqrtz_success
cmpb $10, 9(%rax)
je source_compare_fsqrtqrtz_success
cmpb $32, 9(%rax)
je source_compare_fsqrtqrtz_success
cmpb $35, 9(%rax)
je source_compare_fsqrtqrtz_success
source_compare_fsqrtqrtz_failure:
movb $1, %al
ret
source_compare_fsqrtqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtqrup:
cmpq $9, source_character_count
jb source_compare_fsqrtqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtqrup_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtqrup_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtqrup_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtqrup_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtqrup_failure
cmpb $113, 5(%rax)
jne source_compare_fsqrtqrup_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtqrup_failure
cmpb $117, 7(%rax)
jne source_compare_fsqrtqrup_failure
cmpb $112, 8(%rax)
jne source_compare_fsqrtqrup_failure
cmpq $9, source_character_count
je source_compare_fsqrtqrup_success
cmpb $10, 9(%rax)
je source_compare_fsqrtqrup_success
cmpb $32, 9(%rax)
je source_compare_fsqrtqrup_success
cmpb $35, 9(%rax)
je source_compare_fsqrtqrup_success
source_compare_fsqrtqrup_failure:
movb $1, %al
ret
source_compare_fsqrtqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrts:
cmpq $6, source_character_count
jb source_compare_fsqrts_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrts_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrts_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrts_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrts_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrts_failure
cmpb $115, 5(%rax)
jne source_compare_fsqrts_failure
cmpq $6, source_character_count
je source_compare_fsqrts_success
cmpb $10, 6(%rax)
je source_compare_fsqrts_success
cmpb $32, 6(%rax)
je source_compare_fsqrts_success
cmpb $35, 6(%rax)
je source_compare_fsqrts_success
source_compare_fsqrts_failure:
movb $1, %al
ret
source_compare_fsqrts_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtsdyn:
cmpq $9, source_character_count
jb source_compare_fsqrtsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtsdyn_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtsdyn_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtsdyn_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtsdyn_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtsdyn_failure
cmpb $115, 5(%rax)
jne source_compare_fsqrtsdyn_failure
cmpb $100, 6(%rax)
jne source_compare_fsqrtsdyn_failure
cmpb $121, 7(%rax)
jne source_compare_fsqrtsdyn_failure
cmpb $110, 8(%rax)
jne source_compare_fsqrtsdyn_failure
cmpq $9, source_character_count
je source_compare_fsqrtsdyn_success
cmpb $10, 9(%rax)
je source_compare_fsqrtsdyn_success
cmpb $32, 9(%rax)
je source_compare_fsqrtsdyn_success
cmpb $35, 9(%rax)
je source_compare_fsqrtsdyn_success
source_compare_fsqrtsdyn_failure:
movb $1, %al
ret
source_compare_fsqrtsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtsrdn:
cmpq $9, source_character_count
jb source_compare_fsqrtsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtsrdn_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtsrdn_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtsrdn_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtsrdn_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtsrdn_failure
cmpb $115, 5(%rax)
jne source_compare_fsqrtsrdn_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtsrdn_failure
cmpb $100, 7(%rax)
jne source_compare_fsqrtsrdn_failure
cmpb $110, 8(%rax)
jne source_compare_fsqrtsrdn_failure
cmpq $9, source_character_count
je source_compare_fsqrtsrdn_success
cmpb $10, 9(%rax)
je source_compare_fsqrtsrdn_success
cmpb $32, 9(%rax)
je source_compare_fsqrtsrdn_success
cmpb $35, 9(%rax)
je source_compare_fsqrtsrdn_success
source_compare_fsqrtsrdn_failure:
movb $1, %al
ret
source_compare_fsqrtsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtsrmm:
cmpq $9, source_character_count
jb source_compare_fsqrtsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtsrmm_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtsrmm_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtsrmm_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtsrmm_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtsrmm_failure
cmpb $115, 5(%rax)
jne source_compare_fsqrtsrmm_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fsqrtsrmm_failure
cmpb $109, 8(%rax)
jne source_compare_fsqrtsrmm_failure
cmpq $9, source_character_count
je source_compare_fsqrtsrmm_success
cmpb $10, 9(%rax)
je source_compare_fsqrtsrmm_success
cmpb $32, 9(%rax)
je source_compare_fsqrtsrmm_success
cmpb $35, 9(%rax)
je source_compare_fsqrtsrmm_success
source_compare_fsqrtsrmm_failure:
movb $1, %al
ret
source_compare_fsqrtsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtsrtz:
cmpq $9, source_character_count
jb source_compare_fsqrtsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtsrtz_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtsrtz_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtsrtz_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtsrtz_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtsrtz_failure
cmpb $115, 5(%rax)
jne source_compare_fsqrtsrtz_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtsrtz_failure
cmpb $116, 7(%rax)
jne source_compare_fsqrtsrtz_failure
cmpb $122, 8(%rax)
jne source_compare_fsqrtsrtz_failure
cmpq $9, source_character_count
je source_compare_fsqrtsrtz_success
cmpb $10, 9(%rax)
je source_compare_fsqrtsrtz_success
cmpb $32, 9(%rax)
je source_compare_fsqrtsrtz_success
cmpb $35, 9(%rax)
je source_compare_fsqrtsrtz_success
source_compare_fsqrtsrtz_failure:
movb $1, %al
ret
source_compare_fsqrtsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsqrtsrup:
cmpq $9, source_character_count
jb source_compare_fsqrtsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsqrtsrup_failure
cmpb $115, 1(%rax)
jne source_compare_fsqrtsrup_failure
cmpb $113, 2(%rax)
jne source_compare_fsqrtsrup_failure
cmpb $114, 3(%rax)
jne source_compare_fsqrtsrup_failure
cmpb $116, 4(%rax)
jne source_compare_fsqrtsrup_failure
cmpb $115, 5(%rax)
jne source_compare_fsqrtsrup_failure
cmpb $114, 6(%rax)
jne source_compare_fsqrtsrup_failure
cmpb $117, 7(%rax)
jne source_compare_fsqrtsrup_failure
cmpb $112, 8(%rax)
jne source_compare_fsqrtsrup_failure
cmpq $9, source_character_count
je source_compare_fsqrtsrup_success
cmpb $10, 9(%rax)
je source_compare_fsqrtsrup_success
cmpb $32, 9(%rax)
je source_compare_fsqrtsrup_success
cmpb $35, 9(%rax)
je source_compare_fsqrtsrup_success
source_compare_fsqrtsrup_failure:
movb $1, %al
ret
source_compare_fsqrtsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubd:
cmpq $5, source_character_count
jb source_compare_fsubd_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubd_failure
cmpb $115, 1(%rax)
jne source_compare_fsubd_failure
cmpb $117, 2(%rax)
jne source_compare_fsubd_failure
cmpb $98, 3(%rax)
jne source_compare_fsubd_failure
cmpb $100, 4(%rax)
jne source_compare_fsubd_failure
cmpq $5, source_character_count
je source_compare_fsubd_success
cmpb $10, 5(%rax)
je source_compare_fsubd_success
cmpb $32, 5(%rax)
je source_compare_fsubd_success
cmpb $35, 5(%rax)
je source_compare_fsubd_success
source_compare_fsubd_failure:
movb $1, %al
ret
source_compare_fsubd_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubddyn:
cmpq $8, source_character_count
jb source_compare_fsubddyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubddyn_failure
cmpb $115, 1(%rax)
jne source_compare_fsubddyn_failure
cmpb $117, 2(%rax)
jne source_compare_fsubddyn_failure
cmpb $98, 3(%rax)
jne source_compare_fsubddyn_failure
cmpb $100, 4(%rax)
jne source_compare_fsubddyn_failure
cmpb $100, 5(%rax)
jne source_compare_fsubddyn_failure
cmpb $121, 6(%rax)
jne source_compare_fsubddyn_failure
cmpb $110, 7(%rax)
jne source_compare_fsubddyn_failure
cmpq $8, source_character_count
je source_compare_fsubddyn_success
cmpb $10, 8(%rax)
je source_compare_fsubddyn_success
cmpb $32, 8(%rax)
je source_compare_fsubddyn_success
cmpb $35, 8(%rax)
je source_compare_fsubddyn_success
source_compare_fsubddyn_failure:
movb $1, %al
ret
source_compare_fsubddyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubdrdn:
cmpq $8, source_character_count
jb source_compare_fsubdrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubdrdn_failure
cmpb $115, 1(%rax)
jne source_compare_fsubdrdn_failure
cmpb $117, 2(%rax)
jne source_compare_fsubdrdn_failure
cmpb $98, 3(%rax)
jne source_compare_fsubdrdn_failure
cmpb $100, 4(%rax)
jne source_compare_fsubdrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fsubdrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fsubdrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fsubdrdn_failure
cmpq $8, source_character_count
je source_compare_fsubdrdn_success
cmpb $10, 8(%rax)
je source_compare_fsubdrdn_success
cmpb $32, 8(%rax)
je source_compare_fsubdrdn_success
cmpb $35, 8(%rax)
je source_compare_fsubdrdn_success
source_compare_fsubdrdn_failure:
movb $1, %al
ret
source_compare_fsubdrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubdrmm:
cmpq $8, source_character_count
jb source_compare_fsubdrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubdrmm_failure
cmpb $115, 1(%rax)
jne source_compare_fsubdrmm_failure
cmpb $117, 2(%rax)
jne source_compare_fsubdrmm_failure
cmpb $98, 3(%rax)
jne source_compare_fsubdrmm_failure
cmpb $100, 4(%rax)
jne source_compare_fsubdrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fsubdrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fsubdrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fsubdrmm_failure
cmpq $8, source_character_count
je source_compare_fsubdrmm_success
cmpb $10, 8(%rax)
je source_compare_fsubdrmm_success
cmpb $32, 8(%rax)
je source_compare_fsubdrmm_success
cmpb $35, 8(%rax)
je source_compare_fsubdrmm_success
source_compare_fsubdrmm_failure:
movb $1, %al
ret
source_compare_fsubdrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubdrtz:
cmpq $8, source_character_count
jb source_compare_fsubdrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubdrtz_failure
cmpb $115, 1(%rax)
jne source_compare_fsubdrtz_failure
cmpb $117, 2(%rax)
jne source_compare_fsubdrtz_failure
cmpb $98, 3(%rax)
jne source_compare_fsubdrtz_failure
cmpb $100, 4(%rax)
jne source_compare_fsubdrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fsubdrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fsubdrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fsubdrtz_failure
cmpq $8, source_character_count
je source_compare_fsubdrtz_success
cmpb $10, 8(%rax)
je source_compare_fsubdrtz_success
cmpb $32, 8(%rax)
je source_compare_fsubdrtz_success
cmpb $35, 8(%rax)
je source_compare_fsubdrtz_success
source_compare_fsubdrtz_failure:
movb $1, %al
ret
source_compare_fsubdrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubdrup:
cmpq $8, source_character_count
jb source_compare_fsubdrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubdrup_failure
cmpb $115, 1(%rax)
jne source_compare_fsubdrup_failure
cmpb $117, 2(%rax)
jne source_compare_fsubdrup_failure
cmpb $98, 3(%rax)
jne source_compare_fsubdrup_failure
cmpb $100, 4(%rax)
jne source_compare_fsubdrup_failure
cmpb $114, 5(%rax)
jne source_compare_fsubdrup_failure
cmpb $117, 6(%rax)
jne source_compare_fsubdrup_failure
cmpb $112, 7(%rax)
jne source_compare_fsubdrup_failure
cmpq $8, source_character_count
je source_compare_fsubdrup_success
cmpb $10, 8(%rax)
je source_compare_fsubdrup_success
cmpb $32, 8(%rax)
je source_compare_fsubdrup_success
cmpb $35, 8(%rax)
je source_compare_fsubdrup_success
source_compare_fsubdrup_failure:
movb $1, %al
ret
source_compare_fsubdrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubq:
cmpq $5, source_character_count
jb source_compare_fsubq_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubq_failure
cmpb $115, 1(%rax)
jne source_compare_fsubq_failure
cmpb $117, 2(%rax)
jne source_compare_fsubq_failure
cmpb $98, 3(%rax)
jne source_compare_fsubq_failure
cmpb $113, 4(%rax)
jne source_compare_fsubq_failure
cmpq $5, source_character_count
je source_compare_fsubq_success
cmpb $10, 5(%rax)
je source_compare_fsubq_success
cmpb $32, 5(%rax)
je source_compare_fsubq_success
cmpb $35, 5(%rax)
je source_compare_fsubq_success
source_compare_fsubq_failure:
movb $1, %al
ret
source_compare_fsubq_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubqdyn:
cmpq $8, source_character_count
jb source_compare_fsubqdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubqdyn_failure
cmpb $115, 1(%rax)
jne source_compare_fsubqdyn_failure
cmpb $117, 2(%rax)
jne source_compare_fsubqdyn_failure
cmpb $98, 3(%rax)
jne source_compare_fsubqdyn_failure
cmpb $113, 4(%rax)
jne source_compare_fsubqdyn_failure
cmpb $100, 5(%rax)
jne source_compare_fsubqdyn_failure
cmpb $121, 6(%rax)
jne source_compare_fsubqdyn_failure
cmpb $110, 7(%rax)
jne source_compare_fsubqdyn_failure
cmpq $8, source_character_count
je source_compare_fsubqdyn_success
cmpb $10, 8(%rax)
je source_compare_fsubqdyn_success
cmpb $32, 8(%rax)
je source_compare_fsubqdyn_success
cmpb $35, 8(%rax)
je source_compare_fsubqdyn_success
source_compare_fsubqdyn_failure:
movb $1, %al
ret
source_compare_fsubqdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubqrdn:
cmpq $8, source_character_count
jb source_compare_fsubqrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubqrdn_failure
cmpb $115, 1(%rax)
jne source_compare_fsubqrdn_failure
cmpb $117, 2(%rax)
jne source_compare_fsubqrdn_failure
cmpb $98, 3(%rax)
jne source_compare_fsubqrdn_failure
cmpb $113, 4(%rax)
jne source_compare_fsubqrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fsubqrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fsubqrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fsubqrdn_failure
cmpq $8, source_character_count
je source_compare_fsubqrdn_success
cmpb $10, 8(%rax)
je source_compare_fsubqrdn_success
cmpb $32, 8(%rax)
je source_compare_fsubqrdn_success
cmpb $35, 8(%rax)
je source_compare_fsubqrdn_success
source_compare_fsubqrdn_failure:
movb $1, %al
ret
source_compare_fsubqrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubqrmm:
cmpq $8, source_character_count
jb source_compare_fsubqrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubqrmm_failure
cmpb $115, 1(%rax)
jne source_compare_fsubqrmm_failure
cmpb $117, 2(%rax)
jne source_compare_fsubqrmm_failure
cmpb $98, 3(%rax)
jne source_compare_fsubqrmm_failure
cmpb $113, 4(%rax)
jne source_compare_fsubqrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fsubqrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fsubqrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fsubqrmm_failure
cmpq $8, source_character_count
je source_compare_fsubqrmm_success
cmpb $10, 8(%rax)
je source_compare_fsubqrmm_success
cmpb $32, 8(%rax)
je source_compare_fsubqrmm_success
cmpb $35, 8(%rax)
je source_compare_fsubqrmm_success
source_compare_fsubqrmm_failure:
movb $1, %al
ret
source_compare_fsubqrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubqrtz:
cmpq $8, source_character_count
jb source_compare_fsubqrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubqrtz_failure
cmpb $115, 1(%rax)
jne source_compare_fsubqrtz_failure
cmpb $117, 2(%rax)
jne source_compare_fsubqrtz_failure
cmpb $98, 3(%rax)
jne source_compare_fsubqrtz_failure
cmpb $113, 4(%rax)
jne source_compare_fsubqrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fsubqrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fsubqrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fsubqrtz_failure
cmpq $8, source_character_count
je source_compare_fsubqrtz_success
cmpb $10, 8(%rax)
je source_compare_fsubqrtz_success
cmpb $32, 8(%rax)
je source_compare_fsubqrtz_success
cmpb $35, 8(%rax)
je source_compare_fsubqrtz_success
source_compare_fsubqrtz_failure:
movb $1, %al
ret
source_compare_fsubqrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubqrup:
cmpq $8, source_character_count
jb source_compare_fsubqrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubqrup_failure
cmpb $115, 1(%rax)
jne source_compare_fsubqrup_failure
cmpb $117, 2(%rax)
jne source_compare_fsubqrup_failure
cmpb $98, 3(%rax)
jne source_compare_fsubqrup_failure
cmpb $113, 4(%rax)
jne source_compare_fsubqrup_failure
cmpb $114, 5(%rax)
jne source_compare_fsubqrup_failure
cmpb $117, 6(%rax)
jne source_compare_fsubqrup_failure
cmpb $112, 7(%rax)
jne source_compare_fsubqrup_failure
cmpq $8, source_character_count
je source_compare_fsubqrup_success
cmpb $10, 8(%rax)
je source_compare_fsubqrup_success
cmpb $32, 8(%rax)
je source_compare_fsubqrup_success
cmpb $35, 8(%rax)
je source_compare_fsubqrup_success
source_compare_fsubqrup_failure:
movb $1, %al
ret
source_compare_fsubqrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubs:
cmpq $5, source_character_count
jb source_compare_fsubs_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubs_failure
cmpb $115, 1(%rax)
jne source_compare_fsubs_failure
cmpb $117, 2(%rax)
jne source_compare_fsubs_failure
cmpb $98, 3(%rax)
jne source_compare_fsubs_failure
cmpb $115, 4(%rax)
jne source_compare_fsubs_failure
cmpq $5, source_character_count
je source_compare_fsubs_success
cmpb $10, 5(%rax)
je source_compare_fsubs_success
cmpb $32, 5(%rax)
je source_compare_fsubs_success
cmpb $35, 5(%rax)
je source_compare_fsubs_success
source_compare_fsubs_failure:
movb $1, %al
ret
source_compare_fsubs_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubsdyn:
cmpq $8, source_character_count
jb source_compare_fsubsdyn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubsdyn_failure
cmpb $115, 1(%rax)
jne source_compare_fsubsdyn_failure
cmpb $117, 2(%rax)
jne source_compare_fsubsdyn_failure
cmpb $98, 3(%rax)
jne source_compare_fsubsdyn_failure
cmpb $115, 4(%rax)
jne source_compare_fsubsdyn_failure
cmpb $100, 5(%rax)
jne source_compare_fsubsdyn_failure
cmpb $121, 6(%rax)
jne source_compare_fsubsdyn_failure
cmpb $110, 7(%rax)
jne source_compare_fsubsdyn_failure
cmpq $8, source_character_count
je source_compare_fsubsdyn_success
cmpb $10, 8(%rax)
je source_compare_fsubsdyn_success
cmpb $32, 8(%rax)
je source_compare_fsubsdyn_success
cmpb $35, 8(%rax)
je source_compare_fsubsdyn_success
source_compare_fsubsdyn_failure:
movb $1, %al
ret
source_compare_fsubsdyn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubsrdn:
cmpq $8, source_character_count
jb source_compare_fsubsrdn_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubsrdn_failure
cmpb $115, 1(%rax)
jne source_compare_fsubsrdn_failure
cmpb $117, 2(%rax)
jne source_compare_fsubsrdn_failure
cmpb $98, 3(%rax)
jne source_compare_fsubsrdn_failure
cmpb $115, 4(%rax)
jne source_compare_fsubsrdn_failure
cmpb $114, 5(%rax)
jne source_compare_fsubsrdn_failure
cmpb $100, 6(%rax)
jne source_compare_fsubsrdn_failure
cmpb $110, 7(%rax)
jne source_compare_fsubsrdn_failure
cmpq $8, source_character_count
je source_compare_fsubsrdn_success
cmpb $10, 8(%rax)
je source_compare_fsubsrdn_success
cmpb $32, 8(%rax)
je source_compare_fsubsrdn_success
cmpb $35, 8(%rax)
je source_compare_fsubsrdn_success
source_compare_fsubsrdn_failure:
movb $1, %al
ret
source_compare_fsubsrdn_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubsrmm:
cmpq $8, source_character_count
jb source_compare_fsubsrmm_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubsrmm_failure
cmpb $115, 1(%rax)
jne source_compare_fsubsrmm_failure
cmpb $117, 2(%rax)
jne source_compare_fsubsrmm_failure
cmpb $98, 3(%rax)
jne source_compare_fsubsrmm_failure
cmpb $115, 4(%rax)
jne source_compare_fsubsrmm_failure
cmpb $114, 5(%rax)
jne source_compare_fsubsrmm_failure
cmpb $109, 6(%rax)
jne source_compare_fsubsrmm_failure
cmpb $109, 7(%rax)
jne source_compare_fsubsrmm_failure
cmpq $8, source_character_count
je source_compare_fsubsrmm_success
cmpb $10, 8(%rax)
je source_compare_fsubsrmm_success
cmpb $32, 8(%rax)
je source_compare_fsubsrmm_success
cmpb $35, 8(%rax)
je source_compare_fsubsrmm_success
source_compare_fsubsrmm_failure:
movb $1, %al
ret
source_compare_fsubsrmm_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubsrtz:
cmpq $8, source_character_count
jb source_compare_fsubsrtz_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubsrtz_failure
cmpb $115, 1(%rax)
jne source_compare_fsubsrtz_failure
cmpb $117, 2(%rax)
jne source_compare_fsubsrtz_failure
cmpb $98, 3(%rax)
jne source_compare_fsubsrtz_failure
cmpb $115, 4(%rax)
jne source_compare_fsubsrtz_failure
cmpb $114, 5(%rax)
jne source_compare_fsubsrtz_failure
cmpb $116, 6(%rax)
jne source_compare_fsubsrtz_failure
cmpb $122, 7(%rax)
jne source_compare_fsubsrtz_failure
cmpq $8, source_character_count
je source_compare_fsubsrtz_success
cmpb $10, 8(%rax)
je source_compare_fsubsrtz_success
cmpb $32, 8(%rax)
je source_compare_fsubsrtz_success
cmpb $35, 8(%rax)
je source_compare_fsubsrtz_success
source_compare_fsubsrtz_failure:
movb $1, %al
ret
source_compare_fsubsrtz_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsubsrup:
cmpq $8, source_character_count
jb source_compare_fsubsrup_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsubsrup_failure
cmpb $115, 1(%rax)
jne source_compare_fsubsrup_failure
cmpb $117, 2(%rax)
jne source_compare_fsubsrup_failure
cmpb $98, 3(%rax)
jne source_compare_fsubsrup_failure
cmpb $115, 4(%rax)
jne source_compare_fsubsrup_failure
cmpb $114, 5(%rax)
jne source_compare_fsubsrup_failure
cmpb $117, 6(%rax)
jne source_compare_fsubsrup_failure
cmpb $112, 7(%rax)
jne source_compare_fsubsrup_failure
cmpq $8, source_character_count
je source_compare_fsubsrup_success
cmpb $10, 8(%rax)
je source_compare_fsubsrup_success
cmpb $32, 8(%rax)
je source_compare_fsubsrup_success
cmpb $35, 8(%rax)
je source_compare_fsubsrup_success
source_compare_fsubsrup_failure:
movb $1, %al
ret
source_compare_fsubsrup_success:
xorb %al, %al
ret


# out
# al status
source_compare_fsw:
cmpq $3, source_character_count
jb source_compare_fsw_failure
movq source_character_address, %rax
cmpb $102, (%rax)
jne source_compare_fsw_failure
cmpb $115, 1(%rax)
jne source_compare_fsw_failure
cmpb $119, 2(%rax)
jne source_compare_fsw_failure
cmpq $3, source_character_count
je source_compare_fsw_success
cmpb $10, 3(%rax)
je source_compare_fsw_success
cmpb $32, 3(%rax)
je source_compare_fsw_success
cmpb $35, 3(%rax)
je source_compare_fsw_success
source_compare_fsw_failure:
movb $1, %al
ret
source_compare_fsw_success:
xorb %al, %al
ret


# out
# al status
source_compare_halfword:
cmpq $8, source_character_count
jb source_compare_halfword_failure
movq source_character_address, %rax
cmpb $104, (%rax)
jne source_compare_halfword_failure
cmpb $97, 1(%rax)
jne source_compare_halfword_failure
cmpb $108, 2(%rax)
jne source_compare_halfword_failure
cmpb $102, 3(%rax)
jne source_compare_halfword_failure
cmpb $119, 4(%rax)
jne source_compare_halfword_failure
cmpb $111, 5(%rax)
jne source_compare_halfword_failure
cmpb $114, 6(%rax)
jne source_compare_halfword_failure
cmpb $100, 7(%rax)
jne source_compare_halfword_failure
cmpq $8, source_character_count
je source_compare_halfword_success
cmpb $10, 8(%rax)
je source_compare_halfword_success
cmpb $32, 8(%rax)
je source_compare_halfword_success
cmpb $35, 8(%rax)
je source_compare_halfword_success
source_compare_halfword_failure:
movb $1, %al
ret
source_compare_halfword_success:
xorb %al, %al
ret


# out
# al status
source_compare_include:
cmpq $7, source_character_count
jb source_compare_include_failure
movq source_character_address, %rax
cmpb $105, (%rax)
jne source_compare_include_failure
cmpb $110, 1(%rax)
jne source_compare_include_failure
cmpb $99, 2(%rax)
jne source_compare_include_failure
cmpb $108, 3(%rax)
jne source_compare_include_failure
cmpb $117, 4(%rax)
jne source_compare_include_failure
cmpb $100, 5(%rax)
jne source_compare_include_failure
cmpb $101, 6(%rax)
jne source_compare_include_failure
cmpq $7, source_character_count
je source_compare_include_success
cmpb $10, 7(%rax)
je source_compare_include_success
cmpb $32, 7(%rax)
je source_compare_include_success
cmpb $35, 7(%rax)
je source_compare_include_success
source_compare_include_failure:
movb $1, %al
ret
source_compare_include_success:
xorb %al, %al
ret


# out
# al status
source_compare_jal:
cmpq $3, source_character_count
jb source_compare_jal_failure
movq source_character_address, %rax
cmpb $106, (%rax)
jne source_compare_jal_failure
cmpb $97, 1(%rax)
jne source_compare_jal_failure
cmpb $108, 2(%rax)
jne source_compare_jal_failure
cmpq $3, source_character_count
je source_compare_jal_success
cmpb $10, 3(%rax)
je source_compare_jal_success
cmpb $32, 3(%rax)
je source_compare_jal_success
cmpb $35, 3(%rax)
je source_compare_jal_success
source_compare_jal_failure:
movb $1, %al
ret
source_compare_jal_success:
xorb %al, %al
ret


# out
# al status
source_compare_jalr:
cmpq $4, source_character_count
jb source_compare_jalr_failure
movq source_character_address, %rax
cmpb $106, (%rax)
jne source_compare_jalr_failure
cmpb $97, 1(%rax)
jne source_compare_jalr_failure
cmpb $108, 2(%rax)
jne source_compare_jalr_failure
cmpb $114, 3(%rax)
jne source_compare_jalr_failure
cmpq $4, source_character_count
je source_compare_jalr_success
cmpb $10, 4(%rax)
je source_compare_jalr_success
cmpb $32, 4(%rax)
je source_compare_jalr_success
cmpb $35, 4(%rax)
je source_compare_jalr_success
source_compare_jalr_failure:
movb $1, %al
ret
source_compare_jalr_success:
xorb %al, %al
ret


# out
# al status
source_compare_label:
cmpq $5, source_character_count
jb source_compare_label_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_label_failure
cmpb $97, 1(%rax)
jne source_compare_label_failure
cmpb $98, 2(%rax)
jne source_compare_label_failure
cmpb $101, 3(%rax)
jne source_compare_label_failure
cmpb $108, 4(%rax)
jne source_compare_label_failure
cmpq $5, source_character_count
je source_compare_label_success
cmpb $10, 5(%rax)
je source_compare_label_success
cmpb $32, 5(%rax)
je source_compare_label_success
cmpb $35, 5(%rax)
je source_compare_label_success
source_compare_label_failure:
movb $1, %al
ret
source_compare_label_success:
xorb %al, %al
ret


# out
# al status
source_compare_lb:
cmpq $2, source_character_count
jb source_compare_lb_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lb_failure
cmpb $98, 1(%rax)
jne source_compare_lb_failure
cmpq $2, source_character_count
je source_compare_lb_success
cmpb $10, 2(%rax)
je source_compare_lb_success
cmpb $32, 2(%rax)
je source_compare_lb_success
cmpb $35, 2(%rax)
je source_compare_lb_success
source_compare_lb_failure:
movb $1, %al
ret
source_compare_lb_success:
xorb %al, %al
ret


# out
# al status
source_compare_lbu:
cmpq $3, source_character_count
jb source_compare_lbu_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lbu_failure
cmpb $98, 1(%rax)
jne source_compare_lbu_failure
cmpb $117, 2(%rax)
jne source_compare_lbu_failure
cmpq $3, source_character_count
je source_compare_lbu_success
cmpb $10, 3(%rax)
je source_compare_lbu_success
cmpb $32, 3(%rax)
je source_compare_lbu_success
cmpb $35, 3(%rax)
je source_compare_lbu_success
source_compare_lbu_failure:
movb $1, %al
ret
source_compare_lbu_success:
xorb %al, %al
ret


# out
# al status
source_compare_lc:
cmpq $2, source_character_count
jb source_compare_lc_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lc_failure
cmpb $99, 1(%rax)
jne source_compare_lc_failure
cmpq $2, source_character_count
je source_compare_lc_success
cmpb $10, 2(%rax)
je source_compare_lc_success
cmpb $32, 2(%rax)
je source_compare_lc_success
cmpb $35, 2(%rax)
je source_compare_lc_success
source_compare_lc_failure:
movb $1, %al
ret
source_compare_lc_success:
xorb %al, %al
ret


# out
# al status
source_compare_ld:
cmpq $2, source_character_count
jb source_compare_ld_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_ld_failure
cmpb $100, 1(%rax)
jne source_compare_ld_failure
cmpq $2, source_character_count
je source_compare_ld_success
cmpb $10, 2(%rax)
je source_compare_ld_success
cmpb $32, 2(%rax)
je source_compare_ld_success
cmpb $35, 2(%rax)
je source_compare_ld_success
source_compare_ld_failure:
movb $1, %al
ret
source_compare_ld_success:
xorb %al, %al
ret


# out
# al status
source_compare_lh:
cmpq $2, source_character_count
jb source_compare_lh_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lh_failure
cmpb $104, 1(%rax)
jne source_compare_lh_failure
cmpq $2, source_character_count
je source_compare_lh_success
cmpb $10, 2(%rax)
je source_compare_lh_success
cmpb $32, 2(%rax)
je source_compare_lh_success
cmpb $35, 2(%rax)
je source_compare_lh_success
source_compare_lh_failure:
movb $1, %al
ret
source_compare_lh_success:
xorb %al, %al
ret


# out
# al status
source_compare_lhu:
cmpq $3, source_character_count
jb source_compare_lhu_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lhu_failure
cmpb $104, 1(%rax)
jne source_compare_lhu_failure
cmpb $117, 2(%rax)
jne source_compare_lhu_failure
cmpq $3, source_character_count
je source_compare_lhu_success
cmpb $10, 3(%rax)
je source_compare_lhu_success
cmpb $32, 3(%rax)
je source_compare_lhu_success
cmpb $35, 3(%rax)
je source_compare_lhu_success
source_compare_lhu_failure:
movb $1, %al
ret
source_compare_lhu_success:
xorb %al, %al
ret


# out
# al status
source_compare_ll:
cmpq $2, source_character_count
jb source_compare_ll_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_ll_failure
cmpb $108, 1(%rax)
jne source_compare_ll_failure
cmpq $2, source_character_count
je source_compare_ll_success
cmpb $10, 2(%rax)
je source_compare_ll_success
cmpb $32, 2(%rax)
je source_compare_ll_success
cmpb $35, 2(%rax)
je source_compare_ll_success
source_compare_ll_failure:
movb $1, %al
ret
source_compare_ll_success:
xorb %al, %al
ret


# out
# al status
source_compare_lrd:
cmpq $3, source_character_count
jb source_compare_lrd_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lrd_failure
cmpb $114, 1(%rax)
jne source_compare_lrd_failure
cmpb $100, 2(%rax)
jne source_compare_lrd_failure
cmpq $3, source_character_count
je source_compare_lrd_success
cmpb $10, 3(%rax)
je source_compare_lrd_success
cmpb $32, 3(%rax)
je source_compare_lrd_success
cmpb $35, 3(%rax)
je source_compare_lrd_success
source_compare_lrd_failure:
movb $1, %al
ret
source_compare_lrd_success:
xorb %al, %al
ret


# out
# al status
source_compare_lrdaq:
cmpq $5, source_character_count
jb source_compare_lrdaq_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lrdaq_failure
cmpb $114, 1(%rax)
jne source_compare_lrdaq_failure
cmpb $100, 2(%rax)
jne source_compare_lrdaq_failure
cmpb $97, 3(%rax)
jne source_compare_lrdaq_failure
cmpb $113, 4(%rax)
jne source_compare_lrdaq_failure
cmpq $5, source_character_count
je source_compare_lrdaq_success
cmpb $10, 5(%rax)
je source_compare_lrdaq_success
cmpb $32, 5(%rax)
je source_compare_lrdaq_success
cmpb $35, 5(%rax)
je source_compare_lrdaq_success
source_compare_lrdaq_failure:
movb $1, %al
ret
source_compare_lrdaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_lrdaqrl:
cmpq $7, source_character_count
jb source_compare_lrdaqrl_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lrdaqrl_failure
cmpb $114, 1(%rax)
jne source_compare_lrdaqrl_failure
cmpb $100, 2(%rax)
jne source_compare_lrdaqrl_failure
cmpb $97, 3(%rax)
jne source_compare_lrdaqrl_failure
cmpb $113, 4(%rax)
jne source_compare_lrdaqrl_failure
cmpb $114, 5(%rax)
jne source_compare_lrdaqrl_failure
cmpb $108, 6(%rax)
jne source_compare_lrdaqrl_failure
cmpq $7, source_character_count
je source_compare_lrdaqrl_success
cmpb $10, 7(%rax)
je source_compare_lrdaqrl_success
cmpb $32, 7(%rax)
je source_compare_lrdaqrl_success
cmpb $35, 7(%rax)
je source_compare_lrdaqrl_success
source_compare_lrdaqrl_failure:
movb $1, %al
ret
source_compare_lrdaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_lrdrl:
cmpq $5, source_character_count
jb source_compare_lrdrl_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lrdrl_failure
cmpb $114, 1(%rax)
jne source_compare_lrdrl_failure
cmpb $100, 2(%rax)
jne source_compare_lrdrl_failure
cmpb $114, 3(%rax)
jne source_compare_lrdrl_failure
cmpb $108, 4(%rax)
jne source_compare_lrdrl_failure
cmpq $5, source_character_count
je source_compare_lrdrl_success
cmpb $10, 5(%rax)
je source_compare_lrdrl_success
cmpb $32, 5(%rax)
je source_compare_lrdrl_success
cmpb $35, 5(%rax)
je source_compare_lrdrl_success
source_compare_lrdrl_failure:
movb $1, %al
ret
source_compare_lrdrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_lrw:
cmpq $3, source_character_count
jb source_compare_lrw_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lrw_failure
cmpb $114, 1(%rax)
jne source_compare_lrw_failure
cmpb $119, 2(%rax)
jne source_compare_lrw_failure
cmpq $3, source_character_count
je source_compare_lrw_success
cmpb $10, 3(%rax)
je source_compare_lrw_success
cmpb $32, 3(%rax)
je source_compare_lrw_success
cmpb $35, 3(%rax)
je source_compare_lrw_success
source_compare_lrw_failure:
movb $1, %al
ret
source_compare_lrw_success:
xorb %al, %al
ret


# out
# al status
source_compare_lrwaq:
cmpq $5, source_character_count
jb source_compare_lrwaq_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lrwaq_failure
cmpb $114, 1(%rax)
jne source_compare_lrwaq_failure
cmpb $119, 2(%rax)
jne source_compare_lrwaq_failure
cmpb $97, 3(%rax)
jne source_compare_lrwaq_failure
cmpb $113, 4(%rax)
jne source_compare_lrwaq_failure
cmpq $5, source_character_count
je source_compare_lrwaq_success
cmpb $10, 5(%rax)
je source_compare_lrwaq_success
cmpb $32, 5(%rax)
je source_compare_lrwaq_success
cmpb $35, 5(%rax)
je source_compare_lrwaq_success
source_compare_lrwaq_failure:
movb $1, %al
ret
source_compare_lrwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_lrwaqrl:
cmpq $7, source_character_count
jb source_compare_lrwaqrl_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lrwaqrl_failure
cmpb $114, 1(%rax)
jne source_compare_lrwaqrl_failure
cmpb $119, 2(%rax)
jne source_compare_lrwaqrl_failure
cmpb $97, 3(%rax)
jne source_compare_lrwaqrl_failure
cmpb $113, 4(%rax)
jne source_compare_lrwaqrl_failure
cmpb $114, 5(%rax)
jne source_compare_lrwaqrl_failure
cmpb $108, 6(%rax)
jne source_compare_lrwaqrl_failure
cmpq $7, source_character_count
je source_compare_lrwaqrl_success
cmpb $10, 7(%rax)
je source_compare_lrwaqrl_success
cmpb $32, 7(%rax)
je source_compare_lrwaqrl_success
cmpb $35, 7(%rax)
je source_compare_lrwaqrl_success
source_compare_lrwaqrl_failure:
movb $1, %al
ret
source_compare_lrwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_lrwrl:
cmpq $5, source_character_count
jb source_compare_lrwrl_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lrwrl_failure
cmpb $114, 1(%rax)
jne source_compare_lrwrl_failure
cmpb $119, 2(%rax)
jne source_compare_lrwrl_failure
cmpb $114, 3(%rax)
jne source_compare_lrwrl_failure
cmpb $108, 4(%rax)
jne source_compare_lrwrl_failure
cmpq $5, source_character_count
je source_compare_lrwrl_success
cmpb $10, 5(%rax)
je source_compare_lrwrl_success
cmpb $32, 5(%rax)
je source_compare_lrwrl_success
cmpb $35, 5(%rax)
je source_compare_lrwrl_success
source_compare_lrwrl_failure:
movb $1, %al
ret
source_compare_lrwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_lui:
cmpq $3, source_character_count
jb source_compare_lui_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lui_failure
cmpb $117, 1(%rax)
jne source_compare_lui_failure
cmpb $105, 2(%rax)
jne source_compare_lui_failure
cmpq $3, source_character_count
je source_compare_lui_success
cmpb $10, 3(%rax)
je source_compare_lui_success
cmpb $32, 3(%rax)
je source_compare_lui_success
cmpb $35, 3(%rax)
je source_compare_lui_success
source_compare_lui_failure:
movb $1, %al
ret
source_compare_lui_success:
xorb %al, %al
ret


# out
# al status
source_compare_lw:
cmpq $2, source_character_count
jb source_compare_lw_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lw_failure
cmpb $119, 1(%rax)
jne source_compare_lw_failure
cmpq $2, source_character_count
je source_compare_lw_success
cmpb $10, 2(%rax)
je source_compare_lw_success
cmpb $32, 2(%rax)
je source_compare_lw_success
cmpb $35, 2(%rax)
je source_compare_lw_success
source_compare_lw_failure:
movb $1, %al
ret
source_compare_lw_success:
xorb %al, %al
ret


# out
# al status
source_compare_lwu:
cmpq $3, source_character_count
jb source_compare_lwu_failure
movq source_character_address, %rax
cmpb $108, (%rax)
jne source_compare_lwu_failure
cmpb $119, 1(%rax)
jne source_compare_lwu_failure
cmpb $117, 2(%rax)
jne source_compare_lwu_failure
cmpq $3, source_character_count
je source_compare_lwu_success
cmpb $10, 3(%rax)
je source_compare_lwu_success
cmpb $32, 3(%rax)
je source_compare_lwu_success
cmpb $35, 3(%rax)
je source_compare_lwu_success
source_compare_lwu_failure:
movb $1, %al
ret
source_compare_lwu_success:
xorb %al, %al
ret


# out
# al status
source_compare_mret:
cmpq $4, source_character_count
jb source_compare_mret_failure
movq source_character_address, %rax
cmpb $109, (%rax)
jne source_compare_mret_failure
cmpb $114, 1(%rax)
jne source_compare_mret_failure
cmpb $101, 2(%rax)
jne source_compare_mret_failure
cmpb $116, 3(%rax)
jne source_compare_mret_failure
cmpq $4, source_character_count
je source_compare_mret_success
cmpb $10, 4(%rax)
je source_compare_mret_success
cmpb $32, 4(%rax)
je source_compare_mret_success
cmpb $35, 4(%rax)
je source_compare_mret_success
source_compare_mret_failure:
movb $1, %al
ret
source_compare_mret_success:
xorb %al, %al
ret


# out
# al status
source_compare_mul:
cmpq $3, source_character_count
jb source_compare_mul_failure
movq source_character_address, %rax
cmpb $109, (%rax)
jne source_compare_mul_failure
cmpb $117, 1(%rax)
jne source_compare_mul_failure
cmpb $108, 2(%rax)
jne source_compare_mul_failure
cmpq $3, source_character_count
je source_compare_mul_success
cmpb $10, 3(%rax)
je source_compare_mul_success
cmpb $32, 3(%rax)
je source_compare_mul_success
cmpb $35, 3(%rax)
je source_compare_mul_success
source_compare_mul_failure:
movb $1, %al
ret
source_compare_mul_success:
xorb %al, %al
ret


# out
# al status
source_compare_mulh:
cmpq $4, source_character_count
jb source_compare_mulh_failure
movq source_character_address, %rax
cmpb $109, (%rax)
jne source_compare_mulh_failure
cmpb $117, 1(%rax)
jne source_compare_mulh_failure
cmpb $108, 2(%rax)
jne source_compare_mulh_failure
cmpb $104, 3(%rax)
jne source_compare_mulh_failure
cmpq $4, source_character_count
je source_compare_mulh_success
cmpb $10, 4(%rax)
je source_compare_mulh_success
cmpb $32, 4(%rax)
je source_compare_mulh_success
cmpb $35, 4(%rax)
je source_compare_mulh_success
source_compare_mulh_failure:
movb $1, %al
ret
source_compare_mulh_success:
xorb %al, %al
ret


# out
# al status
source_compare_mulhsu:
cmpq $6, source_character_count
jb source_compare_mulhsu_failure
movq source_character_address, %rax
cmpb $109, (%rax)
jne source_compare_mulhsu_failure
cmpb $117, 1(%rax)
jne source_compare_mulhsu_failure
cmpb $108, 2(%rax)
jne source_compare_mulhsu_failure
cmpb $104, 3(%rax)
jne source_compare_mulhsu_failure
cmpb $115, 4(%rax)
jne source_compare_mulhsu_failure
cmpb $117, 5(%rax)
jne source_compare_mulhsu_failure
cmpq $6, source_character_count
je source_compare_mulhsu_success
cmpb $10, 6(%rax)
je source_compare_mulhsu_success
cmpb $32, 6(%rax)
je source_compare_mulhsu_success
cmpb $35, 6(%rax)
je source_compare_mulhsu_success
source_compare_mulhsu_failure:
movb $1, %al
ret
source_compare_mulhsu_success:
xorb %al, %al
ret


# out
# al status
source_compare_mulhu:
cmpq $5, source_character_count
jb source_compare_mulhu_failure
movq source_character_address, %rax
cmpb $109, (%rax)
jne source_compare_mulhu_failure
cmpb $117, 1(%rax)
jne source_compare_mulhu_failure
cmpb $108, 2(%rax)
jne source_compare_mulhu_failure
cmpb $104, 3(%rax)
jne source_compare_mulhu_failure
cmpb $117, 4(%rax)
jne source_compare_mulhu_failure
cmpq $5, source_character_count
je source_compare_mulhu_success
cmpb $10, 5(%rax)
je source_compare_mulhu_success
cmpb $32, 5(%rax)
je source_compare_mulhu_success
cmpb $35, 5(%rax)
je source_compare_mulhu_success
source_compare_mulhu_failure:
movb $1, %al
ret
source_compare_mulhu_success:
xorb %al, %al
ret


# out
# al status
source_compare_mulw:
cmpq $4, source_character_count
jb source_compare_mulw_failure
movq source_character_address, %rax
cmpb $109, (%rax)
jne source_compare_mulw_failure
cmpb $117, 1(%rax)
jne source_compare_mulw_failure
cmpb $108, 2(%rax)
jne source_compare_mulw_failure
cmpb $119, 3(%rax)
jne source_compare_mulw_failure
cmpq $4, source_character_count
je source_compare_mulw_success
cmpb $10, 4(%rax)
je source_compare_mulw_success
cmpb $32, 4(%rax)
je source_compare_mulw_success
cmpb $35, 4(%rax)
je source_compare_mulw_success
source_compare_mulw_failure:
movb $1, %al
ret
source_compare_mulw_success:
xorb %al, %al
ret


# out
# al status
source_compare_or:
cmpq $2, source_character_count
jb source_compare_or_failure
movq source_character_address, %rax
cmpb $111, (%rax)
jne source_compare_or_failure
cmpb $114, 1(%rax)
jne source_compare_or_failure
cmpq $2, source_character_count
je source_compare_or_success
cmpb $10, 2(%rax)
je source_compare_or_success
cmpb $32, 2(%rax)
je source_compare_or_success
cmpb $35, 2(%rax)
je source_compare_or_success
source_compare_or_failure:
movb $1, %al
ret
source_compare_or_success:
xorb %al, %al
ret


# out
# al status
source_compare_ori:
cmpq $3, source_character_count
jb source_compare_ori_failure
movq source_character_address, %rax
cmpb $111, (%rax)
jne source_compare_ori_failure
cmpb $114, 1(%rax)
jne source_compare_ori_failure
cmpb $105, 2(%rax)
jne source_compare_ori_failure
cmpq $3, source_character_count
je source_compare_ori_success
cmpb $10, 3(%rax)
je source_compare_ori_success
cmpb $32, 3(%rax)
je source_compare_ori_success
cmpb $35, 3(%rax)
je source_compare_ori_success
source_compare_ori_failure:
movb $1, %al
ret
source_compare_ori_success:
xorb %al, %al
ret


# out
# al status
source_compare_rem:
cmpq $3, source_character_count
jb source_compare_rem_failure
movq source_character_address, %rax
cmpb $114, (%rax)
jne source_compare_rem_failure
cmpb $101, 1(%rax)
jne source_compare_rem_failure
cmpb $109, 2(%rax)
jne source_compare_rem_failure
cmpq $3, source_character_count
je source_compare_rem_success
cmpb $10, 3(%rax)
je source_compare_rem_success
cmpb $32, 3(%rax)
je source_compare_rem_success
cmpb $35, 3(%rax)
je source_compare_rem_success
source_compare_rem_failure:
movb $1, %al
ret
source_compare_rem_success:
xorb %al, %al
ret


# out
# al status
source_compare_remu:
cmpq $4, source_character_count
jb source_compare_remu_failure
movq source_character_address, %rax
cmpb $114, (%rax)
jne source_compare_remu_failure
cmpb $101, 1(%rax)
jne source_compare_remu_failure
cmpb $109, 2(%rax)
jne source_compare_remu_failure
cmpb $117, 3(%rax)
jne source_compare_remu_failure
cmpq $4, source_character_count
je source_compare_remu_success
cmpb $10, 4(%rax)
je source_compare_remu_success
cmpb $32, 4(%rax)
je source_compare_remu_success
cmpb $35, 4(%rax)
je source_compare_remu_success
source_compare_remu_failure:
movb $1, %al
ret
source_compare_remu_success:
xorb %al, %al
ret


# out
# al status
source_compare_remuw:
cmpq $5, source_character_count
jb source_compare_remuw_failure
movq source_character_address, %rax
cmpb $114, (%rax)
jne source_compare_remuw_failure
cmpb $101, 1(%rax)
jne source_compare_remuw_failure
cmpb $109, 2(%rax)
jne source_compare_remuw_failure
cmpb $117, 3(%rax)
jne source_compare_remuw_failure
cmpb $119, 4(%rax)
jne source_compare_remuw_failure
cmpq $5, source_character_count
je source_compare_remuw_success
cmpb $10, 5(%rax)
je source_compare_remuw_success
cmpb $32, 5(%rax)
je source_compare_remuw_success
cmpb $35, 5(%rax)
je source_compare_remuw_success
source_compare_remuw_failure:
movb $1, %al
ret
source_compare_remuw_success:
xorb %al, %al
ret


# out
# al status
source_compare_remw:
cmpq $4, source_character_count
jb source_compare_remw_failure
movq source_character_address, %rax
cmpb $114, (%rax)
jne source_compare_remw_failure
cmpb $101, 1(%rax)
jne source_compare_remw_failure
cmpb $109, 2(%rax)
jne source_compare_remw_failure
cmpb $119, 3(%rax)
jne source_compare_remw_failure
cmpq $4, source_character_count
je source_compare_remw_success
cmpb $10, 4(%rax)
je source_compare_remw_success
cmpb $32, 4(%rax)
je source_compare_remw_success
cmpb $35, 4(%rax)
je source_compare_remw_success
source_compare_remw_failure:
movb $1, %al
ret
source_compare_remw_success:
xorb %al, %al
ret


# out
# al status
source_compare_sb:
cmpq $2, source_character_count
jb source_compare_sb_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sb_failure
cmpb $98, 1(%rax)
jne source_compare_sb_failure
cmpq $2, source_character_count
je source_compare_sb_success
cmpb $10, 2(%rax)
je source_compare_sb_success
cmpb $32, 2(%rax)
je source_compare_sb_success
cmpb $35, 2(%rax)
je source_compare_sb_success
source_compare_sb_failure:
movb $1, %al
ret
source_compare_sb_success:
xorb %al, %al
ret


# out
# al status
source_compare_scd:
cmpq $3, source_character_count
jb source_compare_scd_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_scd_failure
cmpb $99, 1(%rax)
jne source_compare_scd_failure
cmpb $100, 2(%rax)
jne source_compare_scd_failure
cmpq $3, source_character_count
je source_compare_scd_success
cmpb $10, 3(%rax)
je source_compare_scd_success
cmpb $32, 3(%rax)
je source_compare_scd_success
cmpb $35, 3(%rax)
je source_compare_scd_success
source_compare_scd_failure:
movb $1, %al
ret
source_compare_scd_success:
xorb %al, %al
ret


# out
# al status
source_compare_scdaq:
cmpq $5, source_character_count
jb source_compare_scdaq_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_scdaq_failure
cmpb $99, 1(%rax)
jne source_compare_scdaq_failure
cmpb $100, 2(%rax)
jne source_compare_scdaq_failure
cmpb $97, 3(%rax)
jne source_compare_scdaq_failure
cmpb $113, 4(%rax)
jne source_compare_scdaq_failure
cmpq $5, source_character_count
je source_compare_scdaq_success
cmpb $10, 5(%rax)
je source_compare_scdaq_success
cmpb $32, 5(%rax)
je source_compare_scdaq_success
cmpb $35, 5(%rax)
je source_compare_scdaq_success
source_compare_scdaq_failure:
movb $1, %al
ret
source_compare_scdaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_scdaqrl:
cmpq $7, source_character_count
jb source_compare_scdaqrl_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_scdaqrl_failure
cmpb $99, 1(%rax)
jne source_compare_scdaqrl_failure
cmpb $100, 2(%rax)
jne source_compare_scdaqrl_failure
cmpb $97, 3(%rax)
jne source_compare_scdaqrl_failure
cmpb $113, 4(%rax)
jne source_compare_scdaqrl_failure
cmpb $114, 5(%rax)
jne source_compare_scdaqrl_failure
cmpb $108, 6(%rax)
jne source_compare_scdaqrl_failure
cmpq $7, source_character_count
je source_compare_scdaqrl_success
cmpb $10, 7(%rax)
je source_compare_scdaqrl_success
cmpb $32, 7(%rax)
je source_compare_scdaqrl_success
cmpb $35, 7(%rax)
je source_compare_scdaqrl_success
source_compare_scdaqrl_failure:
movb $1, %al
ret
source_compare_scdaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_scdrl:
cmpq $5, source_character_count
jb source_compare_scdrl_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_scdrl_failure
cmpb $99, 1(%rax)
jne source_compare_scdrl_failure
cmpb $100, 2(%rax)
jne source_compare_scdrl_failure
cmpb $114, 3(%rax)
jne source_compare_scdrl_failure
cmpb $108, 4(%rax)
jne source_compare_scdrl_failure
cmpq $5, source_character_count
je source_compare_scdrl_success
cmpb $10, 5(%rax)
je source_compare_scdrl_success
cmpb $32, 5(%rax)
je source_compare_scdrl_success
cmpb $35, 5(%rax)
je source_compare_scdrl_success
source_compare_scdrl_failure:
movb $1, %al
ret
source_compare_scdrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_scw:
cmpq $3, source_character_count
jb source_compare_scw_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_scw_failure
cmpb $99, 1(%rax)
jne source_compare_scw_failure
cmpb $119, 2(%rax)
jne source_compare_scw_failure
cmpq $3, source_character_count
je source_compare_scw_success
cmpb $10, 3(%rax)
je source_compare_scw_success
cmpb $32, 3(%rax)
je source_compare_scw_success
cmpb $35, 3(%rax)
je source_compare_scw_success
source_compare_scw_failure:
movb $1, %al
ret
source_compare_scw_success:
xorb %al, %al
ret


# out
# al status
source_compare_scwaq:
cmpq $5, source_character_count
jb source_compare_scwaq_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_scwaq_failure
cmpb $99, 1(%rax)
jne source_compare_scwaq_failure
cmpb $119, 2(%rax)
jne source_compare_scwaq_failure
cmpb $97, 3(%rax)
jne source_compare_scwaq_failure
cmpb $113, 4(%rax)
jne source_compare_scwaq_failure
cmpq $5, source_character_count
je source_compare_scwaq_success
cmpb $10, 5(%rax)
je source_compare_scwaq_success
cmpb $32, 5(%rax)
je source_compare_scwaq_success
cmpb $35, 5(%rax)
je source_compare_scwaq_success
source_compare_scwaq_failure:
movb $1, %al
ret
source_compare_scwaq_success:
xorb %al, %al
ret


# out
# al status
source_compare_scwaqrl:
cmpq $7, source_character_count
jb source_compare_scwaqrl_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_scwaqrl_failure
cmpb $99, 1(%rax)
jne source_compare_scwaqrl_failure
cmpb $119, 2(%rax)
jne source_compare_scwaqrl_failure
cmpb $97, 3(%rax)
jne source_compare_scwaqrl_failure
cmpb $113, 4(%rax)
jne source_compare_scwaqrl_failure
cmpb $114, 5(%rax)
jne source_compare_scwaqrl_failure
cmpb $108, 6(%rax)
jne source_compare_scwaqrl_failure
cmpq $7, source_character_count
je source_compare_scwaqrl_success
cmpb $10, 7(%rax)
je source_compare_scwaqrl_success
cmpb $32, 7(%rax)
je source_compare_scwaqrl_success
cmpb $35, 7(%rax)
je source_compare_scwaqrl_success
source_compare_scwaqrl_failure:
movb $1, %al
ret
source_compare_scwaqrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_scwrl:
cmpq $5, source_character_count
jb source_compare_scwrl_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_scwrl_failure
cmpb $99, 1(%rax)
jne source_compare_scwrl_failure
cmpb $119, 2(%rax)
jne source_compare_scwrl_failure
cmpb $114, 3(%rax)
jne source_compare_scwrl_failure
cmpb $108, 4(%rax)
jne source_compare_scwrl_failure
cmpq $5, source_character_count
je source_compare_scwrl_success
cmpb $10, 5(%rax)
je source_compare_scwrl_success
cmpb $32, 5(%rax)
je source_compare_scwrl_success
cmpb $35, 5(%rax)
je source_compare_scwrl_success
source_compare_scwrl_failure:
movb $1, %al
ret
source_compare_scwrl_success:
xorb %al, %al
ret


# out
# al status
source_compare_sd:
cmpq $2, source_character_count
jb source_compare_sd_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sd_failure
cmpb $100, 1(%rax)
jne source_compare_sd_failure
cmpq $2, source_character_count
je source_compare_sd_success
cmpb $10, 2(%rax)
je source_compare_sd_success
cmpb $32, 2(%rax)
je source_compare_sd_success
cmpb $35, 2(%rax)
je source_compare_sd_success
source_compare_sd_failure:
movb $1, %al
ret
source_compare_sd_success:
xorb %al, %al
ret


# out
# al status
source_compare_sfencevma:
cmpq $9, source_character_count
jb source_compare_sfencevma_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sfencevma_failure
cmpb $102, 1(%rax)
jne source_compare_sfencevma_failure
cmpb $101, 2(%rax)
jne source_compare_sfencevma_failure
cmpb $110, 3(%rax)
jne source_compare_sfencevma_failure
cmpb $99, 4(%rax)
jne source_compare_sfencevma_failure
cmpb $101, 5(%rax)
jne source_compare_sfencevma_failure
cmpb $118, 6(%rax)
jne source_compare_sfencevma_failure
cmpb $109, 7(%rax)
jne source_compare_sfencevma_failure
cmpb $97, 8(%rax)
jne source_compare_sfencevma_failure
cmpq $9, source_character_count
je source_compare_sfencevma_success
cmpb $10, 9(%rax)
je source_compare_sfencevma_success
cmpb $32, 9(%rax)
je source_compare_sfencevma_success
cmpb $35, 9(%rax)
je source_compare_sfencevma_success
source_compare_sfencevma_failure:
movb $1, %al
ret
source_compare_sfencevma_success:
xorb %al, %al
ret


# out
# al status
source_compare_sh:
cmpq $2, source_character_count
jb source_compare_sh_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sh_failure
cmpb $104, 1(%rax)
jne source_compare_sh_failure
cmpq $2, source_character_count
je source_compare_sh_success
cmpb $10, 2(%rax)
je source_compare_sh_success
cmpb $32, 2(%rax)
je source_compare_sh_success
cmpb $35, 2(%rax)
je source_compare_sh_success
source_compare_sh_failure:
movb $1, %al
ret
source_compare_sh_success:
xorb %al, %al
ret


# out
# al status
source_compare_sll:
cmpq $3, source_character_count
jb source_compare_sll_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sll_failure
cmpb $108, 1(%rax)
jne source_compare_sll_failure
cmpb $108, 2(%rax)
jne source_compare_sll_failure
cmpq $3, source_character_count
je source_compare_sll_success
cmpb $10, 3(%rax)
je source_compare_sll_success
cmpb $32, 3(%rax)
je source_compare_sll_success
cmpb $35, 3(%rax)
je source_compare_sll_success
source_compare_sll_failure:
movb $1, %al
ret
source_compare_sll_success:
xorb %al, %al
ret


# out
# al status
source_compare_slli:
cmpq $4, source_character_count
jb source_compare_slli_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_slli_failure
cmpb $108, 1(%rax)
jne source_compare_slli_failure
cmpb $108, 2(%rax)
jne source_compare_slli_failure
cmpb $105, 3(%rax)
jne source_compare_slli_failure
cmpq $4, source_character_count
je source_compare_slli_success
cmpb $10, 4(%rax)
je source_compare_slli_success
cmpb $32, 4(%rax)
je source_compare_slli_success
cmpb $35, 4(%rax)
je source_compare_slli_success
source_compare_slli_failure:
movb $1, %al
ret
source_compare_slli_success:
xorb %al, %al
ret


# out
# al status
source_compare_slliw:
cmpq $5, source_character_count
jb source_compare_slliw_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_slliw_failure
cmpb $108, 1(%rax)
jne source_compare_slliw_failure
cmpb $108, 2(%rax)
jne source_compare_slliw_failure
cmpb $105, 3(%rax)
jne source_compare_slliw_failure
cmpb $119, 4(%rax)
jne source_compare_slliw_failure
cmpq $5, source_character_count
je source_compare_slliw_success
cmpb $10, 5(%rax)
je source_compare_slliw_success
cmpb $32, 5(%rax)
je source_compare_slliw_success
cmpb $35, 5(%rax)
je source_compare_slliw_success
source_compare_slliw_failure:
movb $1, %al
ret
source_compare_slliw_success:
xorb %al, %al
ret


# out
# al status
source_compare_sllw:
cmpq $4, source_character_count
jb source_compare_sllw_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sllw_failure
cmpb $108, 1(%rax)
jne source_compare_sllw_failure
cmpb $108, 2(%rax)
jne source_compare_sllw_failure
cmpb $119, 3(%rax)
jne source_compare_sllw_failure
cmpq $4, source_character_count
je source_compare_sllw_success
cmpb $10, 4(%rax)
je source_compare_sllw_success
cmpb $32, 4(%rax)
je source_compare_sllw_success
cmpb $35, 4(%rax)
je source_compare_sllw_success
source_compare_sllw_failure:
movb $1, %al
ret
source_compare_sllw_success:
xorb %al, %al
ret


# out
# al status
source_compare_slt:
cmpq $3, source_character_count
jb source_compare_slt_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_slt_failure
cmpb $108, 1(%rax)
jne source_compare_slt_failure
cmpb $116, 2(%rax)
jne source_compare_slt_failure
cmpq $3, source_character_count
je source_compare_slt_success
cmpb $10, 3(%rax)
je source_compare_slt_success
cmpb $32, 3(%rax)
je source_compare_slt_success
cmpb $35, 3(%rax)
je source_compare_slt_success
source_compare_slt_failure:
movb $1, %al
ret
source_compare_slt_success:
xorb %al, %al
ret


# out
# al status
source_compare_slti:
cmpq $4, source_character_count
jb source_compare_slti_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_slti_failure
cmpb $108, 1(%rax)
jne source_compare_slti_failure
cmpb $116, 2(%rax)
jne source_compare_slti_failure
cmpb $105, 3(%rax)
jne source_compare_slti_failure
cmpq $4, source_character_count
je source_compare_slti_success
cmpb $10, 4(%rax)
je source_compare_slti_success
cmpb $32, 4(%rax)
je source_compare_slti_success
cmpb $35, 4(%rax)
je source_compare_slti_success
source_compare_slti_failure:
movb $1, %al
ret
source_compare_slti_success:
xorb %al, %al
ret


# out
# al status
source_compare_sltiu:
cmpq $5, source_character_count
jb source_compare_sltiu_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sltiu_failure
cmpb $108, 1(%rax)
jne source_compare_sltiu_failure
cmpb $116, 2(%rax)
jne source_compare_sltiu_failure
cmpb $105, 3(%rax)
jne source_compare_sltiu_failure
cmpb $117, 4(%rax)
jne source_compare_sltiu_failure
cmpq $5, source_character_count
je source_compare_sltiu_success
cmpb $10, 5(%rax)
je source_compare_sltiu_success
cmpb $32, 5(%rax)
je source_compare_sltiu_success
cmpb $35, 5(%rax)
je source_compare_sltiu_success
source_compare_sltiu_failure:
movb $1, %al
ret
source_compare_sltiu_success:
xorb %al, %al
ret


# out
# al status
source_compare_sltu:
cmpq $4, source_character_count
jb source_compare_sltu_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sltu_failure
cmpb $108, 1(%rax)
jne source_compare_sltu_failure
cmpb $116, 2(%rax)
jne source_compare_sltu_failure
cmpb $117, 3(%rax)
jne source_compare_sltu_failure
cmpq $4, source_character_count
je source_compare_sltu_success
cmpb $10, 4(%rax)
je source_compare_sltu_success
cmpb $32, 4(%rax)
je source_compare_sltu_success
cmpb $35, 4(%rax)
je source_compare_sltu_success
source_compare_sltu_failure:
movb $1, %al
ret
source_compare_sltu_success:
xorb %al, %al
ret


# out
# al status
source_compare_sra:
cmpq $3, source_character_count
jb source_compare_sra_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sra_failure
cmpb $114, 1(%rax)
jne source_compare_sra_failure
cmpb $97, 2(%rax)
jne source_compare_sra_failure
cmpq $3, source_character_count
je source_compare_sra_success
cmpb $10, 3(%rax)
je source_compare_sra_success
cmpb $32, 3(%rax)
je source_compare_sra_success
cmpb $35, 3(%rax)
je source_compare_sra_success
source_compare_sra_failure:
movb $1, %al
ret
source_compare_sra_success:
xorb %al, %al
ret


# out
# al status
source_compare_srai:
cmpq $4, source_character_count
jb source_compare_srai_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_srai_failure
cmpb $114, 1(%rax)
jne source_compare_srai_failure
cmpb $97, 2(%rax)
jne source_compare_srai_failure
cmpb $105, 3(%rax)
jne source_compare_srai_failure
cmpq $4, source_character_count
je source_compare_srai_success
cmpb $10, 4(%rax)
je source_compare_srai_success
cmpb $32, 4(%rax)
je source_compare_srai_success
cmpb $35, 4(%rax)
je source_compare_srai_success
source_compare_srai_failure:
movb $1, %al
ret
source_compare_srai_success:
xorb %al, %al
ret


# out
# al status
source_compare_sraiw:
cmpq $5, source_character_count
jb source_compare_sraiw_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sraiw_failure
cmpb $114, 1(%rax)
jne source_compare_sraiw_failure
cmpb $97, 2(%rax)
jne source_compare_sraiw_failure
cmpb $105, 3(%rax)
jne source_compare_sraiw_failure
cmpb $119, 4(%rax)
jne source_compare_sraiw_failure
cmpq $5, source_character_count
je source_compare_sraiw_success
cmpb $10, 5(%rax)
je source_compare_sraiw_success
cmpb $32, 5(%rax)
je source_compare_sraiw_success
cmpb $35, 5(%rax)
je source_compare_sraiw_success
source_compare_sraiw_failure:
movb $1, %al
ret
source_compare_sraiw_success:
xorb %al, %al
ret


# out
# al status
source_compare_sraw:
cmpq $4, source_character_count
jb source_compare_sraw_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sraw_failure
cmpb $114, 1(%rax)
jne source_compare_sraw_failure
cmpb $97, 2(%rax)
jne source_compare_sraw_failure
cmpb $119, 3(%rax)
jne source_compare_sraw_failure
cmpq $4, source_character_count
je source_compare_sraw_success
cmpb $10, 4(%rax)
je source_compare_sraw_success
cmpb $32, 4(%rax)
je source_compare_sraw_success
cmpb $35, 4(%rax)
je source_compare_sraw_success
source_compare_sraw_failure:
movb $1, %al
ret
source_compare_sraw_success:
xorb %al, %al
ret


# out
# al status
source_compare_sret:
cmpq $4, source_character_count
jb source_compare_sret_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sret_failure
cmpb $114, 1(%rax)
jne source_compare_sret_failure
cmpb $101, 2(%rax)
jne source_compare_sret_failure
cmpb $116, 3(%rax)
jne source_compare_sret_failure
cmpq $4, source_character_count
je source_compare_sret_success
cmpb $10, 4(%rax)
je source_compare_sret_success
cmpb $32, 4(%rax)
je source_compare_sret_success
cmpb $35, 4(%rax)
je source_compare_sret_success
source_compare_sret_failure:
movb $1, %al
ret
source_compare_sret_success:
xorb %al, %al
ret


# out
# al status
source_compare_srl:
cmpq $3, source_character_count
jb source_compare_srl_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_srl_failure
cmpb $114, 1(%rax)
jne source_compare_srl_failure
cmpb $108, 2(%rax)
jne source_compare_srl_failure
cmpq $3, source_character_count
je source_compare_srl_success
cmpb $10, 3(%rax)
je source_compare_srl_success
cmpb $32, 3(%rax)
je source_compare_srl_success
cmpb $35, 3(%rax)
je source_compare_srl_success
source_compare_srl_failure:
movb $1, %al
ret
source_compare_srl_success:
xorb %al, %al
ret


# out
# al status
source_compare_srli:
cmpq $4, source_character_count
jb source_compare_srli_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_srli_failure
cmpb $114, 1(%rax)
jne source_compare_srli_failure
cmpb $108, 2(%rax)
jne source_compare_srli_failure
cmpb $105, 3(%rax)
jne source_compare_srli_failure
cmpq $4, source_character_count
je source_compare_srli_success
cmpb $10, 4(%rax)
je source_compare_srli_success
cmpb $32, 4(%rax)
je source_compare_srli_success
cmpb $35, 4(%rax)
je source_compare_srli_success
source_compare_srli_failure:
movb $1, %al
ret
source_compare_srli_success:
xorb %al, %al
ret


# out
# al status
source_compare_srliw:
cmpq $5, source_character_count
jb source_compare_srliw_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_srliw_failure
cmpb $114, 1(%rax)
jne source_compare_srliw_failure
cmpb $108, 2(%rax)
jne source_compare_srliw_failure
cmpb $105, 3(%rax)
jne source_compare_srliw_failure
cmpb $119, 4(%rax)
jne source_compare_srliw_failure
cmpq $5, source_character_count
je source_compare_srliw_success
cmpb $10, 5(%rax)
je source_compare_srliw_success
cmpb $32, 5(%rax)
je source_compare_srliw_success
cmpb $35, 5(%rax)
je source_compare_srliw_success
source_compare_srliw_failure:
movb $1, %al
ret
source_compare_srliw_success:
xorb %al, %al
ret


# out
# al status
source_compare_srlw:
cmpq $4, source_character_count
jb source_compare_srlw_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_srlw_failure
cmpb $114, 1(%rax)
jne source_compare_srlw_failure
cmpb $108, 2(%rax)
jne source_compare_srlw_failure
cmpb $119, 3(%rax)
jne source_compare_srlw_failure
cmpq $4, source_character_count
je source_compare_srlw_success
cmpb $10, 4(%rax)
je source_compare_srlw_success
cmpb $32, 4(%rax)
je source_compare_srlw_success
cmpb $35, 4(%rax)
je source_compare_srlw_success
source_compare_srlw_failure:
movb $1, %al
ret
source_compare_srlw_success:
xorb %al, %al
ret


# out
# al status
source_compare_string:
cmpq $6, source_character_count
jb source_compare_string_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_string_failure
cmpb $116, 1(%rax)
jne source_compare_string_failure
cmpb $114, 2(%rax)
jne source_compare_string_failure
cmpb $105, 3(%rax)
jne source_compare_string_failure
cmpb $110, 4(%rax)
jne source_compare_string_failure
cmpb $103, 5(%rax)
jne source_compare_string_failure
cmpq $6, source_character_count
je source_compare_string_success
cmpb $10, 6(%rax)
je source_compare_string_success
cmpb $32, 6(%rax)
je source_compare_string_success
cmpb $35, 6(%rax)
je source_compare_string_success
source_compare_string_failure:
movb $1, %al
ret
source_compare_string_success:
xorb %al, %al
ret


# out
# al status
source_compare_sub:
cmpq $3, source_character_count
jb source_compare_sub_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sub_failure
cmpb $117, 1(%rax)
jne source_compare_sub_failure
cmpb $98, 2(%rax)
jne source_compare_sub_failure
cmpq $3, source_character_count
je source_compare_sub_success
cmpb $10, 3(%rax)
je source_compare_sub_success
cmpb $32, 3(%rax)
je source_compare_sub_success
cmpb $35, 3(%rax)
je source_compare_sub_success
source_compare_sub_failure:
movb $1, %al
ret
source_compare_sub_success:
xorb %al, %al
ret


# out
# al status
source_compare_subw:
cmpq $4, source_character_count
jb source_compare_subw_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_subw_failure
cmpb $117, 1(%rax)
jne source_compare_subw_failure
cmpb $98, 2(%rax)
jne source_compare_subw_failure
cmpb $119, 3(%rax)
jne source_compare_subw_failure
cmpq $4, source_character_count
je source_compare_subw_success
cmpb $10, 4(%rax)
je source_compare_subw_success
cmpb $32, 4(%rax)
je source_compare_subw_success
cmpb $35, 4(%rax)
je source_compare_subw_success
source_compare_subw_failure:
movb $1, %al
ret
source_compare_subw_success:
xorb %al, %al
ret


# out
# al status
source_compare_sw:
cmpq $2, source_character_count
jb source_compare_sw_failure
movq source_character_address, %rax
cmpb $115, (%rax)
jne source_compare_sw_failure
cmpb $119, 1(%rax)
jne source_compare_sw_failure
cmpq $2, source_character_count
je source_compare_sw_success
cmpb $10, 2(%rax)
je source_compare_sw_success
cmpb $32, 2(%rax)
je source_compare_sw_success
cmpb $35, 2(%rax)
je source_compare_sw_success
source_compare_sw_failure:
movb $1, %al
ret
source_compare_sw_success:
xorb %al, %al
ret


# out
# al status
source_compare_uret:
cmpq $4, source_character_count
jb source_compare_uret_failure
movq source_character_address, %rax
cmpb $117, (%rax)
jne source_compare_uret_failure
cmpb $114, 1(%rax)
jne source_compare_uret_failure
cmpb $101, 2(%rax)
jne source_compare_uret_failure
cmpb $116, 3(%rax)
jne source_compare_uret_failure
cmpq $4, source_character_count
je source_compare_uret_success
cmpb $10, 4(%rax)
je source_compare_uret_success
cmpb $32, 4(%rax)
je source_compare_uret_success
cmpb $35, 4(%rax)
je source_compare_uret_success
source_compare_uret_failure:
movb $1, %al
ret
source_compare_uret_success:
xorb %al, %al
ret


# out
# al status
source_compare_wfi:
cmpq $3, source_character_count
jb source_compare_wfi_failure
movq source_character_address, %rax
cmpb $119, (%rax)
jne source_compare_wfi_failure
cmpb $102, 1(%rax)
jne source_compare_wfi_failure
cmpb $105, 2(%rax)
jne source_compare_wfi_failure
cmpq $3, source_character_count
je source_compare_wfi_success
cmpb $10, 3(%rax)
je source_compare_wfi_success
cmpb $32, 3(%rax)
je source_compare_wfi_success
cmpb $35, 3(%rax)
je source_compare_wfi_success
source_compare_wfi_failure:
movb $1, %al
ret
source_compare_wfi_success:
xorb %al, %al
ret


# out
# al status
source_compare_word:
cmpq $4, source_character_count
jb source_compare_word_failure
movq source_character_address, %rax
cmpb $119, (%rax)
jne source_compare_word_failure
cmpb $111, 1(%rax)
jne source_compare_word_failure
cmpb $114, 2(%rax)
jne source_compare_word_failure
cmpb $100, 3(%rax)
jne source_compare_word_failure
cmpq $4, source_character_count
je source_compare_word_success
cmpb $10, 4(%rax)
je source_compare_word_success
cmpb $32, 4(%rax)
je source_compare_word_success
cmpb $35, 4(%rax)
je source_compare_word_success
source_compare_word_failure:
movb $1, %al
ret
source_compare_word_success:
xorb %al, %al
ret


# out
# al status
source_compare_xor:
cmpq $3, source_character_count
jb source_compare_xor_failure
movq source_character_address, %rax
cmpb $120, (%rax)
jne source_compare_xor_failure
cmpb $111, 1(%rax)
jne source_compare_xor_failure
cmpb $114, 2(%rax)
jne source_compare_xor_failure
cmpq $3, source_character_count
je source_compare_xor_success
cmpb $10, 3(%rax)
je source_compare_xor_success
cmpb $32, 3(%rax)
je source_compare_xor_success
cmpb $35, 3(%rax)
je source_compare_xor_success
source_compare_xor_failure:
movb $1, %al
ret
source_compare_xor_success:
xorb %al, %al
ret


# out
# al status
source_compare_xori:
cmpq $4, source_character_count
jb source_compare_xori_failure
movq source_character_address, %rax
cmpb $120, (%rax)
jne source_compare_xori_failure
cmpb $111, 1(%rax)
jne source_compare_xori_failure
cmpb $114, 2(%rax)
jne source_compare_xori_failure
cmpb $105, 3(%rax)
jne source_compare_xori_failure
cmpq $4, source_character_count
je source_compare_xori_success
cmpb $10, 4(%rax)
je source_compare_xori_success
cmpb $32, 4(%rax)
je source_compare_xori_success
cmpb $35, 4(%rax)
je source_compare_xori_success
source_compare_xori_failure:
movb $1, %al
ret
source_compare_xori_success:
xorb %al, %al
ret


# out
# al status
source_compare_zero:
cmpq $4, source_character_count
jb source_compare_zero_failure
movq source_character_address, %rax
cmpb $122, (%rax)
jne source_compare_zero_failure
cmpb $101, 1(%rax)
jne source_compare_zero_failure
cmpb $114, 2(%rax)
jne source_compare_zero_failure
cmpb $111, 3(%rax)
jne source_compare_zero_failure
cmpq $4, source_character_count
je source_compare_zero_success
cmpb $10, 4(%rax)
je source_compare_zero_success
cmpb $32, 4(%rax)
je source_compare_zero_success
cmpb $35, 4(%rax)
je source_compare_zero_success
source_compare_zero_failure:
movb $1, %al
ret
source_compare_zero_success:
xorb %al, %al
ret


.section .data

.align 2
source_list_size:
.word 0
source_count:
.word 0

.align 8
source_address:
.quad 0
source_character_address:
.quad 0
source_character_count:
.quad 0
source_line_index:
.quad 0
source_list:
.zero 135168 # 256 sources
