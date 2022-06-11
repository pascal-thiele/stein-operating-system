; source byte layout
; 0 path
; 512 address
; 520 size
; 528

.code


; out
; rax source address
source_allocate:
xor eax, eax
movzx rbx, source_list_size
cmp bx, 256
je source_allocate_return
mov eax, 528
mul rbx
lea rcx, source_list
add rax, rcx
add bx, 1
mov source_list_size, bx
source_allocate_return:
ret


source_iterator:
lea rax, source_list
mov source_address, rax
mov bx, source_list_size
mov source_count, bx
mov rcx, [rax+512]
mov rdx, [rax+520]
mov source_character_address, rcx
mov source_character_count, rdx
mov source_line_index, 1
ret


; out
; al status
source_iterator_increment:
add source_count, -1
jz source_iterator_increment_failure
mov rax, source_address
add rax, 528
mov source_address, rax
mov rbx, [rax+512]
mov rcx, [rax+520]
mov source_character_address, rbx
mov source_character_count, rcx
mov source_line_index, 1
xor al, al
ret
source_iterator_increment_failure:
mov al, 1
ret


source_to_terminal:
mov rax, source_address
xor bx, bx
mov rcx, rax
source_to_terminal_compare_path:
cmp byte ptr[rcx], 0
je source_to_terminal_append_path
add rcx, 1
add bx, 1
cmp bx, 512
jne source_to_terminal_compare_path
source_to_terminal_append_path:
call terminal_append_string
mov al, 58
call terminal_append_character
mov al, 32
call terminal_append_character
mov rax, source_line_index
call terminal_append_integer
mov al, 58
call terminal_append_character
mov al, 32
call terminal_append_character
ret


; out
; al status
source_jump_line:
mov rax, source_character_address
mov rbx, source_character_count
source_jump_line_loop:
add rbx, -1
jz source_jump_line_failure
mov cl, [rax]
add rax, 1
cmp cl, 10
jne source_jump_line_loop

mov source_character_address, rax
mov source_character_count, rbx
add source_line_index, 1
xor al, al
ret

source_jump_line_failure:
mov al, 1
ret


; A token is terminated by space, a new line or a hashtag.

; out
; rax token address
; rbx token size
source_token:
mov rax, source_character_address
xor ebx, ebx
mov rcx, rax
mov rdx, source_character_count
source_token_loop:
cmp byte ptr[rcx], 10
je source_token_return
cmp byte ptr[rcx], 32
je source_token_return
cmp byte ptr[rcx], 35
je source_token_return
add rbx, 1
add rcx, 1
add rdx, -1
jnz source_token_loop
source_token_return:
ret


; out
; al status
source_seek_token:
mov rax, source_character_address
mov rbx, source_character_count
source_seek_token_loop:
cmp byte ptr[rax], 32
jne source_seek_token_end
add rax, 1
add rbx, -1
jnz source_seek_token_loop
mov al, 1
ret

source_seek_token_end:
cmp byte ptr[rax], 10
je source_seek_token_failure
cmp byte ptr[rax], 35
je source_seek_token_failure
mov source_character_address, rax
mov source_character_count, rbx
xor al, al
ret

source_seek_token_failure:
mov al, 1
ret


; out
; al status
source_jump_token:
mov rax, source_character_address
mov rbx, source_character_count
source_jump_token_loop:
cmp byte ptr[rax], 10
je source_jump_token_end
cmp byte ptr[rax], 32
je source_jump_token_end
cmp byte ptr[rax], 35
je source_jump_token_end
add rax, 1
add rbx, -1
jnz source_jump_token_loop
mov al, 1
ret

source_jump_token_end:
mov source_character_address, rax
mov source_character_count, rbx
xor al, al
ret


; in
; rax extended token address
; out
; al status
source_extend_token:
mov qword ptr[rax], 0
mov qword ptr[rax+8], 0
mov qword ptr[rax+16], 0
mov qword ptr[rax+24], 0
mov qword ptr[rax+32], 0
mov qword ptr[rax+40], 0
mov qword ptr[rax+48], 0
mov qword ptr[rax+56], 0
mov qword ptr[rax+64], 0
mov qword ptr[rax+72], 0
mov qword ptr[rax+80], 0
mov qword ptr[rax+88], 0
mov qword ptr[rax+96], 0
mov qword ptr[rax+104], 0
mov qword ptr[rax+112], 0
mov qword ptr[rax+120], 0
mov qword ptr[rax+128], 0
mov qword ptr[rax+136], 0
mov qword ptr[rax+144], 0
mov qword ptr[rax+152], 0
mov qword ptr[rax+160], 0
mov qword ptr[rax+168], 0
mov qword ptr[rax+176], 0
mov qword ptr[rax+184], 0
mov qword ptr[rax+192], 0
mov qword ptr[rax+200], 0
mov qword ptr[rax+208], 0
mov qword ptr[rax+216], 0
mov qword ptr[rax+224], 0
mov qword ptr[rax+232], 0
mov qword ptr[rax+240], 0
mov qword ptr[rax+248], 0
mov rbx, source_character_address
mov rcx, source_character_count
mov dx, 256
source_extend_token_loop:
mov sil, [rbx]
cmp sil, 10
je source_extend_token_end
cmp sil, 32
je source_extend_token_end
cmp sil, 35
je source_extend_token_end
mov [rax], sil
add rcx, -1
jz source_extend_token_end
add rax, 1
add rbx, 1
add dx, -1
jnz source_extend_token_loop
mov al, 1
ret
source_extend_token_end:
xor al, al
ret


; The first and last character of a quote are quotation marks and the entire quote is terminated by space, a new line or a hashtag.

; out
; rax quote address
; rbx quote size
source_quote:
mov rax, source_character_address
cmp byte ptr[rax], 34
jne source_quote_failure
mov ebx, 1
mov rcx, rax
mov rdx, source_character_count
source_quote_loop:
add rdx, -1
jz source_quote_failure
add rcx, 1
cmp byte ptr[rcx], 10
je source_quote_failure
cmp byte ptr[rcx], 35
je source_quote_failure
add rbx, 1
cmp byte ptr[rcx], 34
jne source_quote_loop

add rdx, -1
jz source_quote_return
cmp byte ptr[rcx+1], 10
je source_quote_return
cmp byte ptr[rcx+1], 32
je source_quote_return
cmp byte ptr[rcx+1], 35
je source_quote_return
source_quote_failure:
xor eax, eax
xor ebx, ebx
source_quote_return:
ret


; out
; al status
source_jump_quote:
mov rax, source_character_address
cmp byte ptr[rax], 34
jne source_jump_quote_failure
mov rbx, source_character_count
source_jump_quote_loop:
add rbx, -1
jz source_jump_quote_failure
add rax, 1
cmp byte ptr[rax], 10
je source_jump_quote_failure
cmp byte ptr[rax], 35
je source_jump_quote_failure
cmp byte ptr[rax], 34
jne source_jump_quote_loop

add rbx, -1
jz source_jump_quote_failure
add rax, 1
cmp byte ptr[rax], 10
je source_jump_quote_end
cmp byte ptr[rax], 32
je source_jump_quote_end
cmp byte ptr[rax], 35
je source_jump_quote_end
source_jump_quote_failure:
mov al, 1
ret

source_jump_quote_end:
mov source_character_address, rax
mov source_character_count, rbx
xor al, al
ret


; in
; rax extended quote address
; out
; al status
source_extend_quote:
mov qword ptr[rax], 0
mov qword ptr[rax+8], 0
mov qword ptr[rax+16], 0
mov qword ptr[rax+24], 0
mov qword ptr[rax+32], 0
mov qword ptr[rax+40], 0
mov qword ptr[rax+48], 0
mov qword ptr[rax+56], 0
mov qword ptr[rax+64], 0
mov qword ptr[rax+72], 0
mov qword ptr[rax+80], 0
mov qword ptr[rax+88], 0
mov qword ptr[rax+96], 0
mov qword ptr[rax+104], 0
mov qword ptr[rax+112], 0
mov qword ptr[rax+120], 0
mov qword ptr[rax+128], 0
mov qword ptr[rax+136], 0
mov qword ptr[rax+144], 0
mov qword ptr[rax+152], 0
mov qword ptr[rax+160], 0
mov qword ptr[rax+168], 0
mov qword ptr[rax+176], 0
mov qword ptr[rax+184], 0
mov qword ptr[rax+192], 0
mov qword ptr[rax+200], 0
mov qword ptr[rax+208], 0
mov qword ptr[rax+216], 0
mov qword ptr[rax+224], 0
mov qword ptr[rax+232], 0
mov qword ptr[rax+240], 0
mov qword ptr[rax+248], 0
mov qword ptr[rax+256], 0
mov qword ptr[rax+264], 0
mov qword ptr[rax+272], 0
mov qword ptr[rax+280], 0
mov qword ptr[rax+288], 0
mov qword ptr[rax+296], 0
mov qword ptr[rax+304], 0
mov qword ptr[rax+312], 0
mov qword ptr[rax+320], 0
mov qword ptr[rax+328], 0
mov qword ptr[rax+336], 0
mov qword ptr[rax+344], 0
mov qword ptr[rax+352], 0
mov qword ptr[rax+360], 0
mov qword ptr[rax+368], 0
mov qword ptr[rax+376], 0
mov qword ptr[rax+384], 0
mov qword ptr[rax+392], 0
mov qword ptr[rax+400], 0
mov qword ptr[rax+408], 0
mov qword ptr[rax+416], 0
mov qword ptr[rax+424], 0
mov qword ptr[rax+432], 0
mov qword ptr[rax+440], 0
mov qword ptr[rax+448], 0
mov qword ptr[rax+456], 0
mov qword ptr[rax+464], 0
mov qword ptr[rax+472], 0
mov qword ptr[rax+480], 0
mov qword ptr[rax+488], 0
mov qword ptr[rax+496], 0
mov qword ptr[rax+504], 0

mov rbx, source_character_address
cmp byte ptr[rbx], 34
jne source_extend_quote_failure
mov rcx, source_character_count
mov dx, 512
source_extend_quote_loop:
add rcx, -1
jz source_extend_quote_failure
add rbx, 1
mov sil, [rbx]
cmp sil, 10
je source_extend_quote_failure
cmp sil, 34
je source_extend_quote_end
cmp sil, 35
je source_extend_quote_failure
mov [rax], sil
add rax, 1
add dx, -1
jnz source_extend_quote_loop
source_extend_quote_failure:
mov al, 1
ret

source_extend_quote_end:
add rcx, -1
jz source_extend_quote_success
add rbx, 1
cmp byte ptr[rbx], 10
je source_extend_quote_success
cmp byte ptr[rbx], 32
je source_extend_quote_success
cmp byte ptr[rbx], 35
je source_extend_quote_success
mov al, 1
ret

source_extend_quote_success:
xor al, al
ret


; out
; al status
; rbx integer
source_integer:
mov rcx, source_character_address
movzx rbx, byte ptr[rcx]
cmp bl, 45
je source_integer_negative
cmp bl, 48
jb source_integer_failure
cmp bl, 58
jae source_integer_failure
add bl, -48
mov rsi, source_character_count
add rsi, -1
jz source_integer_positive_success
xor edx, edx
mov edi, 10
source_integer_positive_digit:
add rcx, 1
movzx r8, byte ptr[rcx]
cmp r8b, 10
je source_integer_positive_success
cmp r8b, 32
je source_integer_positive_success
cmp r8b, 35
je source_integer_positive_success
cmp r8b, 48
jb source_integer_failure
cmp r8b, 58
jae source_integer_failure
add r8b, -48
; check for integer overflow
mov rax, 18446744073709551615
sub rax, r8
div rdi
cmp rax, rbx
jb source_integer_failure
; add digit
mov rax, rbx
mul rdi
add rax, r8
mov rbx, rax
add rsi, -1
jnz source_integer_positive_digit
source_integer_positive_success:
xor al, al
ret

source_integer_negative:
mov rsi, source_character_count
add rsi, -1
jz source_integer_failure
add rcx, 1
movzx rbx, byte ptr[rcx]
cmp bl, 48
jb source_integer_failure
cmp bl, 58
jae source_integer_failure
add bl, -48
add rsi, -1
jz source_integer_negative_success
xor edx, edx
mov edi, 10
source_integer_negative_digit:
add rcx, 1
movzx r8, byte ptr[rcx]
cmp r8b, 10
je source_integer_negative_success
cmp r8b, 32
je source_integer_negative_success
cmp r8b, 35
je source_integer_negative_success
cmp r8b, 48
jb source_integer_failure
cmp r8b, 58
jae source_integer_failure
add r8b, -48
; check for integer overflow
mov rax, 9223372036854775808
sub rax, r8
div rdi
cmp rax, rbx
jb source_integer_failure
; add digit
mov rax, rbx
mul rdi
add rax, r8
mov rbx, rax
add rsi, -1
jnz source_integer_negative_digit
source_integer_negative_success:
neg rbx
xor al, al
ret

source_integer_failure:
mov al, 1
ret


; out
; al status
; rbx signed integer
source_signed_integer:
mov rcx, source_character_address
movzx rbx, byte ptr[rcx]
cmp bl, 45
je source_signed_integer_negative
cmp bl, 48
jb source_signed_integer_failure
cmp bl, 58
jae source_signed_integer_failure
add bl, -48
mov rsi, source_character_count
add rsi, -1
jz source_signed_integer_positive_success
xor edx, edx
mov edi, 10
source_signed_integer_positive_digit:
add rcx, 1
movzx r8, byte ptr[rcx]
cmp r8b, 10
je source_signed_integer_positive_success
cmp r8b, 32
je source_signed_integer_positive_success
cmp r8b, 35
je source_signed_integer_positive_success
cmp r8b, 48
jb source_signed_integer_failure
cmp r8b, 58
jae source_signed_integer_failure
add r8b, -48
; check for integer overflow
mov rax, 9223372036854775807
sub rax, r8
div rdi
cmp rax, rbx
jb source_signed_integer_failure
; add digit
mov rax, rbx
mul rdi
add rax, r8
mov rbx, rax
add rsi, -1
jnz source_signed_integer_positive_digit
source_signed_integer_positive_success:
xor al, al
ret

source_signed_integer_negative:
mov rsi, source_character_count
add rsi, -1
jz source_signed_integer_failure
add rcx, 1
movzx rbx, byte ptr[rcx]
cmp bl, 48
jb source_signed_integer_failure
cmp bl, 58
jae source_signed_integer_failure
add bl, -48
add rsi, -1
jz source_signed_integer_negative_success
xor edx, edx
mov edi, 10
source_signed_integer_negative_digit:
add rcx, 1
movzx r8, byte ptr[rcx]
cmp r8b, 10
je source_signed_integer_negative_success
cmp r8b, 32
je source_signed_integer_negative_success
cmp r8b, 35
je source_signed_integer_negative_success
cmp r8b, 48
jb source_signed_integer_failure
cmp r8b, 58
jae source_signed_integer_failure
add r8b, -48
; check for integer overflow
mov rax, 9223372036854775808
sub rax, r8
div rdi
cmp rax, rbx
jb source_signed_integer_failure
; add digit
mov rax, rbx
mul rdi
add rax, r8
mov rbx, rax
add rsi, -1
jnz source_signed_integer_negative_digit
source_signed_integer_negative_success:
neg rbx
xor al, al
ret

source_signed_integer_failure:
mov al, 1
ret


; out
; al status
; rbx unsigned integer
source_unsigned_integer:
mov rcx, source_character_address
movzx rbx, byte ptr[rcx]
cmp bl, 48
jb source_unsigned_integer_failure
cmp bl, 58
jae source_unsigned_integer_failure
add bl, -48
mov rsi, source_character_count
add rsi, -1
jz source_unsigned_integer_success
xor edx, edx
mov edi, 10
source_unsigned_integer_digit:
add rcx, 1
movzx r8, byte ptr[rcx]
cmp r8b, 10
je source_unsigned_integer_success
cmp r8b, 32
je source_unsigned_integer_success
cmp r8b, 35
je source_unsigned_integer_success
cmp r8b, 48
jb source_unsigned_integer_failure
cmp r8b, 58
jae source_unsigned_integer_failure
add r8b, -48
; check for integer overflow
mov rax, 18446744073709551615
sub rax, r8
div rdi
cmp rax, rbx
jb source_unsigned_integer_failure
; add digit
mov rax, rbx
mul rdi
add rax, r8
mov rbx, rax
add rsi, -1
jnz source_unsigned_integer_digit
source_unsigned_integer_success:
xor al, al
ret
source_unsigned_integer_failure:
mov al, 1
ret


; out
; al status
; bl input flag
; cl output flag
; dl read flag
; sil write flag
source_fence_mask:
mov rax, source_character_address
cmp byte ptr[rax], 105
jne source_fence_mask_first_flag_output
mov bl, 1
xor cl, cl
xor dl, dl
xor sil, sil
jmp source_fence_mask_second_flag
source_fence_mask_first_flag_output:
cmp byte ptr[rax], 111
jne source_fence_mask_first_flag_read
xor bl, bl
mov cl, 1
xor dl, dl
xor sil, sil
jmp source_fence_mask_second_flag
source_fence_mask_first_flag_read:
cmp byte ptr[rax], 114
jne source_fence_mask_first_flag_write
xor bl, bl
xor cl, cl
mov dl, 1
xor sil, sil
jmp source_fence_mask_second_flag
source_fence_mask_first_flag_write:
cmp byte ptr[rax], 119
jne source_fence_mask_failure
xor bl, bl
xor cl, cl
xor dl, dl
mov sil, 1

source_fence_mask_second_flag:
cmp source_character_count, 1
je source_fence_mask_success
cmp byte ptr[rax+1], 10
je source_fence_mask_success
cmp byte ptr[rax+1], 32
je source_fence_mask_success
cmp byte ptr[rax+1], 35
je source_fence_mask_success
cmp byte ptr[rax+1], 105
jne source_fence_mask_second_flag_output
xor bl, 1
jz source_fence_mask_failure
jmp source_fence_mask_third_flag
source_fence_mask_second_flag_output:
cmp byte ptr[rax+1], 111
jne source_fence_mask_second_flag_read
xor cl, 1
jz source_fence_mask_failure
jmp source_fence_mask_third_flag
source_fence_mask_second_flag_read:
cmp byte ptr[rax+1], 114
jne source_fence_mask_second_flag_write
xor dl, 1
jz source_fence_mask_failure
jmp source_fence_mask_third_flag
source_fence_mask_second_flag_write:
cmp byte ptr[rax+1], 119
jne source_fence_mask_failure
xor sil, 1
jz source_fence_mask_failure

source_fence_mask_third_flag:
cmp source_character_count, 2
je source_fence_mask_success
cmp byte ptr[rax+2], 10
je source_fence_mask_success
cmp byte ptr[rax+2], 32
je source_fence_mask_success
cmp byte ptr[rax+2], 35
je source_fence_mask_success
cmp byte ptr[rax+2], 105
jne source_fence_mask_third_flag_output
xor bl, 1
jz source_fence_mask_failure
jmp source_fence_mask_fourth_flag
source_fence_mask_third_flag_output:
cmp byte ptr[rax+2], 111
jne source_fence_mask_third_flag_read
xor cl, 1
jz source_fence_mask_failure
jmp source_fence_mask_fourth_flag
source_fence_mask_third_flag_read:
cmp byte ptr[rax+2], 114
jne source_fence_mask_third_flag_write
xor dl, 1
jz source_fence_mask_failure
jmp source_fence_mask_fourth_flag
source_fence_mask_third_flag_write:
cmp byte ptr[rax+2], 119
jne source_fence_mask_failure
xor sil, 1
jz source_fence_mask_failure

source_fence_mask_fourth_flag:
cmp source_character_count, 3
je source_fence_mask_success
cmp byte ptr[rax+3], 10
je source_fence_mask_success
cmp byte ptr[rax+3], 32
je source_fence_mask_success
cmp byte ptr[rax+3], 35
je source_fence_mask_success
cmp byte ptr[rax+3], 105
jne source_fence_mask_fourth_flag_output
xor bl, 1
jz source_fence_mask_failure
jmp source_fence_mask_end
source_fence_mask_fourth_flag_output:
cmp byte ptr[rax+3], 111
jne source_fence_mask_fourth_flag_read
xor cl, 1
jz source_fence_mask_failure
jmp source_fence_mask_end
source_fence_mask_fourth_flag_read:
cmp byte ptr[rax+3], 114
jne source_fence_mask_fourth_flag_write
xor dl, 1
jz source_fence_mask_failure
jmp source_fence_mask_end
source_fence_mask_fourth_flag_write:
cmp byte ptr[rax+3], 119
jne source_fence_mask_failure
xor sil, 1
jz source_fence_mask_failure

source_fence_mask_end:
cmp source_character_count, 4
je source_fence_mask_success
cmp byte ptr[rax+4], 10
je source_fence_mask_success
cmp byte ptr[rax+4], 32
je source_fence_mask_success
cmp byte ptr[rax+4], 35
je source_fence_mask_success
source_fence_mask_failure:
mov al, 1
ret

source_fence_mask_success:
xor al, al
ret


; out
; al status
source_compare_add:
cmp source_character_count, 3
jb source_compare_add_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_add_failure
cmp byte ptr[rax+1], 100
jne source_compare_add_failure
cmp byte ptr[rax+2], 100
jne source_compare_add_failure
cmp source_character_count, 3
je source_compare_add_success
cmp byte ptr[rax+3], 10
je source_compare_add_success
cmp byte ptr[rax+3], 32
je source_compare_add_success
cmp byte ptr[rax+3], 35
je source_compare_add_success
source_compare_add_failure:
mov al, 1
ret
source_compare_add_success:
xor al, al
ret


; out
; al status
source_compare_addi:
cmp source_character_count, 4
jb source_compare_addi_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_addi_failure
cmp byte ptr[rax+1], 100
jne source_compare_addi_failure
cmp byte ptr[rax+2], 100
jne source_compare_addi_failure
cmp byte ptr[rax+3], 105
jne source_compare_addi_failure
cmp source_character_count, 4
je source_compare_addi_success
cmp byte ptr[rax+4], 10
je source_compare_addi_success
cmp byte ptr[rax+4], 32
je source_compare_addi_success
cmp byte ptr[rax+4], 35
je source_compare_addi_success
source_compare_addi_failure:
mov al, 1
ret
source_compare_addi_success:
xor al, al
ret


; out
; al status
source_compare_addiw:
cmp source_character_count, 5
jb source_compare_addiw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_addiw_failure
cmp byte ptr[rax+1], 100
jne source_compare_addiw_failure
cmp byte ptr[rax+2], 100
jne source_compare_addiw_failure
cmp byte ptr[rax+3], 105
jne source_compare_addiw_failure
cmp byte ptr[rax+4], 119
jne source_compare_addiw_failure
cmp source_character_count, 5
je source_compare_addiw_success
cmp byte ptr[rax+5], 10
je source_compare_addiw_success
cmp byte ptr[rax+5], 32
je source_compare_addiw_success
cmp byte ptr[rax+5], 35
je source_compare_addiw_success
source_compare_addiw_failure:
mov al, 1
ret
source_compare_addiw_success:
xor al, al
ret


; out
; al status
source_compare_addw:
cmp source_character_count, 4
jb source_compare_addw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_addw_failure
cmp byte ptr[rax+1], 100
jne source_compare_addw_failure
cmp byte ptr[rax+2], 100
jne source_compare_addw_failure
cmp byte ptr[rax+3], 119
jne source_compare_addw_failure
cmp source_character_count, 4
je source_compare_addw_success
cmp byte ptr[rax+4], 10
je source_compare_addw_success
cmp byte ptr[rax+4], 32
je source_compare_addw_success
cmp byte ptr[rax+4], 35
je source_compare_addw_success
source_compare_addw_failure:
mov al, 1
ret
source_compare_addw_success:
xor al, al
ret


; out
; al status
source_compare_align:
cmp source_character_count, 5
jb source_compare_align_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_align_failure
cmp byte ptr[rax+1], 108
jne source_compare_align_failure
cmp byte ptr[rax+2], 105
jne source_compare_align_failure
cmp byte ptr[rax+3], 103
jne source_compare_align_failure
cmp byte ptr[rax+4], 110
jne source_compare_align_failure
cmp source_character_count, 5
je source_compare_align_success
cmp byte ptr[rax+5], 10
je source_compare_align_success
cmp byte ptr[rax+5], 32
je source_compare_align_success
cmp byte ptr[rax+5], 35
je source_compare_align_success
source_compare_align_failure:
mov al, 1
ret
source_compare_align_success:
xor al, al
ret


; out
; al status
source_compare_amoaddd:
cmp source_character_count, 7
jb source_compare_amoaddd_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoaddd_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoaddd_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoaddd_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoaddd_failure
cmp byte ptr[rax+4], 100
jne source_compare_amoaddd_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoaddd_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoaddd_failure
cmp source_character_count, 7
je source_compare_amoaddd_success
cmp byte ptr[rax+7], 10
je source_compare_amoaddd_success
cmp byte ptr[rax+7], 32
je source_compare_amoaddd_success
cmp byte ptr[rax+7], 35
je source_compare_amoaddd_success
source_compare_amoaddd_failure:
mov al, 1
ret
source_compare_amoaddd_success:
xor al, al
ret


; out
; al status
source_compare_amoadddaq:
cmp source_character_count, 9
jb source_compare_amoadddaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoadddaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoadddaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoadddaq_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoadddaq_failure
cmp byte ptr[rax+4], 100
jne source_compare_amoadddaq_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoadddaq_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoadddaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoadddaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoadddaq_failure
cmp source_character_count, 9
je source_compare_amoadddaq_success
cmp byte ptr[rax+9], 10
je source_compare_amoadddaq_success
cmp byte ptr[rax+9], 32
je source_compare_amoadddaq_success
cmp byte ptr[rax+9], 35
je source_compare_amoadddaq_success
source_compare_amoadddaq_failure:
mov al, 1
ret
source_compare_amoadddaq_success:
xor al, al
ret


; out
; al status
source_compare_amoadddaqrl:
cmp source_character_count, 11
jb source_compare_amoadddaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+4], 100
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amoadddaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amoadddaqrl_failure
cmp source_character_count, 11
je source_compare_amoadddaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amoadddaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amoadddaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amoadddaqrl_success
source_compare_amoadddaqrl_failure:
mov al, 1
ret
source_compare_amoadddaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoadddrl:
cmp source_character_count, 9
jb source_compare_amoadddrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoadddrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoadddrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoadddrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoadddrl_failure
cmp byte ptr[rax+4], 100
jne source_compare_amoadddrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoadddrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoadddrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amoadddrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amoadddrl_failure
cmp source_character_count, 9
je source_compare_amoadddrl_success
cmp byte ptr[rax+9], 10
je source_compare_amoadddrl_success
cmp byte ptr[rax+9], 32
je source_compare_amoadddrl_success
cmp byte ptr[rax+9], 35
je source_compare_amoadddrl_success
source_compare_amoadddrl_failure:
mov al, 1
ret
source_compare_amoadddrl_success:
xor al, al
ret


; out
; al status
source_compare_amoaddw:
cmp source_character_count, 7
jb source_compare_amoaddw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoaddw_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoaddw_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoaddw_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoaddw_failure
cmp byte ptr[rax+4], 100
jne source_compare_amoaddw_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoaddw_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoaddw_failure
cmp source_character_count, 7
je source_compare_amoaddw_success
cmp byte ptr[rax+7], 10
je source_compare_amoaddw_success
cmp byte ptr[rax+7], 32
je source_compare_amoaddw_success
cmp byte ptr[rax+7], 35
je source_compare_amoaddw_success
source_compare_amoaddw_failure:
mov al, 1
ret
source_compare_amoaddw_success:
xor al, al
ret


; out
; al status
source_compare_amoaddwaq:
cmp source_character_count, 9
jb source_compare_amoaddwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoaddwaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoaddwaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoaddwaq_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoaddwaq_failure
cmp byte ptr[rax+4], 100
jne source_compare_amoaddwaq_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoaddwaq_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoaddwaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoaddwaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoaddwaq_failure
cmp source_character_count, 9
je source_compare_amoaddwaq_success
cmp byte ptr[rax+9], 10
je source_compare_amoaddwaq_success
cmp byte ptr[rax+9], 32
je source_compare_amoaddwaq_success
cmp byte ptr[rax+9], 35
je source_compare_amoaddwaq_success
source_compare_amoaddwaq_failure:
mov al, 1
ret
source_compare_amoaddwaq_success:
xor al, al
ret


; out
; al status
source_compare_amoaddwaqrl:
cmp source_character_count, 11
jb source_compare_amoaddwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+4], 100
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amoaddwaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amoaddwaqrl_failure
cmp source_character_count, 11
je source_compare_amoaddwaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amoaddwaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amoaddwaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amoaddwaqrl_success
source_compare_amoaddwaqrl_failure:
mov al, 1
ret
source_compare_amoaddwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoaddwrl:
cmp source_character_count, 9
jb source_compare_amoaddwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoaddwrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoaddwrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoaddwrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoaddwrl_failure
cmp byte ptr[rax+4], 100
jne source_compare_amoaddwrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoaddwrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoaddwrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amoaddwrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amoaddwrl_failure
cmp source_character_count, 9
je source_compare_amoaddwrl_success
cmp byte ptr[rax+9], 10
je source_compare_amoaddwrl_success
cmp byte ptr[rax+9], 32
je source_compare_amoaddwrl_success
cmp byte ptr[rax+9], 35
je source_compare_amoaddwrl_success
source_compare_amoaddwrl_failure:
mov al, 1
ret
source_compare_amoaddwrl_success:
xor al, al
ret


; out
; al status
source_compare_amoandd:
cmp source_character_count, 7
jb source_compare_amoandd_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoandd_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoandd_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoandd_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoandd_failure
cmp byte ptr[rax+4], 110
jne source_compare_amoandd_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoandd_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoandd_failure
cmp source_character_count, 7
je source_compare_amoandd_success
cmp byte ptr[rax+7], 10
je source_compare_amoandd_success
cmp byte ptr[rax+7], 32
je source_compare_amoandd_success
cmp byte ptr[rax+7], 35
je source_compare_amoandd_success
source_compare_amoandd_failure:
mov al, 1
ret
source_compare_amoandd_success:
xor al, al
ret


; out
; al status
source_compare_amoanddaq:
cmp source_character_count, 9
jb source_compare_amoanddaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoanddaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoanddaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoanddaq_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoanddaq_failure
cmp byte ptr[rax+4], 110
jne source_compare_amoanddaq_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoanddaq_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoanddaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoanddaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoanddaq_failure
cmp source_character_count, 9
je source_compare_amoanddaq_success
cmp byte ptr[rax+9], 10
je source_compare_amoanddaq_success
cmp byte ptr[rax+9], 32
je source_compare_amoanddaq_success
cmp byte ptr[rax+9], 35
je source_compare_amoanddaq_success
source_compare_amoanddaq_failure:
mov al, 1
ret
source_compare_amoanddaq_success:
xor al, al
ret


; out
; al status
source_compare_amoanddaqrl:
cmp source_character_count, 11
jb source_compare_amoanddaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+4], 110
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amoanddaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amoanddaqrl_failure
cmp source_character_count, 11
je source_compare_amoanddaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amoanddaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amoanddaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amoanddaqrl_success
source_compare_amoanddaqrl_failure:
mov al, 1
ret
source_compare_amoanddaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoanddrl:
cmp source_character_count, 9
jb source_compare_amoanddrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoanddrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoanddrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoanddrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoanddrl_failure
cmp byte ptr[rax+4], 110
jne source_compare_amoanddrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoanddrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoanddrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amoanddrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amoanddrl_failure
cmp source_character_count, 9
je source_compare_amoanddrl_success
cmp byte ptr[rax+9], 10
je source_compare_amoanddrl_success
cmp byte ptr[rax+9], 32
je source_compare_amoanddrl_success
cmp byte ptr[rax+9], 35
je source_compare_amoanddrl_success
source_compare_amoanddrl_failure:
mov al, 1
ret
source_compare_amoanddrl_success:
xor al, al
ret


; out
; al status
source_compare_amoandw:
cmp source_character_count, 7
jb source_compare_amoandw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoandw_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoandw_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoandw_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoandw_failure
cmp byte ptr[rax+4], 110
jne source_compare_amoandw_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoandw_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoandw_failure
cmp source_character_count, 7
je source_compare_amoandw_success
cmp byte ptr[rax+7], 10
je source_compare_amoandw_success
cmp byte ptr[rax+7], 32
je source_compare_amoandw_success
cmp byte ptr[rax+7], 35
je source_compare_amoandw_success
source_compare_amoandw_failure:
mov al, 1
ret
source_compare_amoandw_success:
xor al, al
ret


; out
; al status
source_compare_amoandwaq:
cmp source_character_count, 9
jb source_compare_amoandwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoandwaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoandwaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoandwaq_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoandwaq_failure
cmp byte ptr[rax+4], 110
jne source_compare_amoandwaq_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoandwaq_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoandwaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoandwaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoandwaq_failure
cmp source_character_count, 9
je source_compare_amoandwaq_success
cmp byte ptr[rax+9], 10
je source_compare_amoandwaq_success
cmp byte ptr[rax+9], 32
je source_compare_amoandwaq_success
cmp byte ptr[rax+9], 35
je source_compare_amoandwaq_success
source_compare_amoandwaq_failure:
mov al, 1
ret
source_compare_amoandwaq_success:
xor al, al
ret


; out
; al status
source_compare_amoandwaqrl:
cmp source_character_count, 11
jb source_compare_amoandwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+4], 110
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amoandwaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amoandwaqrl_failure
cmp source_character_count, 11
je source_compare_amoandwaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amoandwaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amoandwaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amoandwaqrl_success
source_compare_amoandwaqrl_failure:
mov al, 1
ret
source_compare_amoandwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoandwrl:
cmp source_character_count, 9
jb source_compare_amoandwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoandwrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoandwrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoandwrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_amoandwrl_failure
cmp byte ptr[rax+4], 110
jne source_compare_amoandwrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoandwrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoandwrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amoandwrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amoandwrl_failure
cmp source_character_count, 9
je source_compare_amoandwrl_success
cmp byte ptr[rax+9], 10
je source_compare_amoandwrl_success
cmp byte ptr[rax+9], 32
je source_compare_amoandwrl_success
cmp byte ptr[rax+9], 35
je source_compare_amoandwrl_success
source_compare_amoandwrl_failure:
mov al, 1
ret
source_compare_amoandwrl_success:
xor al, al
ret


; out
; al status
source_compare_amomaxd:
cmp source_character_count, 7
jb source_compare_amomaxd_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxd_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxd_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxd_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxd_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxd_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxd_failure
cmp byte ptr[rax+6], 100
jne source_compare_amomaxd_failure
cmp source_character_count, 7
je source_compare_amomaxd_success
cmp byte ptr[rax+7], 10
je source_compare_amomaxd_success
cmp byte ptr[rax+7], 32
je source_compare_amomaxd_success
cmp byte ptr[rax+7], 35
je source_compare_amomaxd_success
source_compare_amomaxd_failure:
mov al, 1
ret
source_compare_amomaxd_success:
xor al, al
ret


; out
; al status
source_compare_amomaxdaq:
cmp source_character_count, 9
jb source_compare_amomaxdaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxdaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxdaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxdaq_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxdaq_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxdaq_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxdaq_failure
cmp byte ptr[rax+6], 100
jne source_compare_amomaxdaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amomaxdaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amomaxdaq_failure
cmp source_character_count, 9
je source_compare_amomaxdaq_success
cmp byte ptr[rax+9], 10
je source_compare_amomaxdaq_success
cmp byte ptr[rax+9], 32
je source_compare_amomaxdaq_success
cmp byte ptr[rax+9], 35
je source_compare_amomaxdaq_success
source_compare_amomaxdaq_failure:
mov al, 1
ret
source_compare_amomaxdaq_success:
xor al, al
ret


; out
; al status
source_compare_amomaxdaqrl:
cmp source_character_count, 11
jb source_compare_amomaxdaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amomaxdaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amomaxdaqrl_failure
cmp source_character_count, 11
je source_compare_amomaxdaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amomaxdaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amomaxdaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amomaxdaqrl_success
source_compare_amomaxdaqrl_failure:
mov al, 1
ret
source_compare_amomaxdaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amomaxdrl:
cmp source_character_count, 9
jb source_compare_amomaxdrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxdrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxdrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxdrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxdrl_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxdrl_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxdrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amomaxdrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amomaxdrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amomaxdrl_failure
cmp source_character_count, 9
je source_compare_amomaxdrl_success
cmp byte ptr[rax+9], 10
je source_compare_amomaxdrl_success
cmp byte ptr[rax+9], 32
je source_compare_amomaxdrl_success
cmp byte ptr[rax+9], 35
je source_compare_amomaxdrl_success
source_compare_amomaxdrl_failure:
mov al, 1
ret
source_compare_amomaxdrl_success:
xor al, al
ret


; out
; al status
source_compare_amomaxw:
cmp source_character_count, 7
jb source_compare_amomaxw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxw_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxw_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxw_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxw_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxw_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxw_failure
cmp byte ptr[rax+6], 119
jne source_compare_amomaxw_failure
cmp source_character_count, 7
je source_compare_amomaxw_success
cmp byte ptr[rax+7], 10
je source_compare_amomaxw_success
cmp byte ptr[rax+7], 32
je source_compare_amomaxw_success
cmp byte ptr[rax+7], 35
je source_compare_amomaxw_success
source_compare_amomaxw_failure:
mov al, 1
ret
source_compare_amomaxw_success:
xor al, al
ret


; out
; al status
source_compare_amomaxwaq:
cmp source_character_count, 9
jb source_compare_amomaxwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxwaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxwaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxwaq_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxwaq_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxwaq_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxwaq_failure
cmp byte ptr[rax+6], 119
jne source_compare_amomaxwaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amomaxwaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amomaxwaq_failure
cmp source_character_count, 9
je source_compare_amomaxwaq_success
cmp byte ptr[rax+9], 10
je source_compare_amomaxwaq_success
cmp byte ptr[rax+9], 32
je source_compare_amomaxwaq_success
cmp byte ptr[rax+9], 35
je source_compare_amomaxwaq_success
source_compare_amomaxwaq_failure:
mov al, 1
ret
source_compare_amomaxwaq_success:
xor al, al
ret


; out
; al status
source_compare_amomaxwaqrl:
cmp source_character_count, 11
jb source_compare_amomaxwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amomaxwaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amomaxwaqrl_failure
cmp source_character_count, 11
je source_compare_amomaxwaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amomaxwaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amomaxwaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amomaxwaqrl_success
source_compare_amomaxwaqrl_failure:
mov al, 1
ret
source_compare_amomaxwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amomaxwrl:
cmp source_character_count, 9
jb source_compare_amomaxwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxwrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxwrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxwrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxwrl_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxwrl_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxwrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amomaxwrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amomaxwrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amomaxwrl_failure
cmp source_character_count, 9
je source_compare_amomaxwrl_success
cmp byte ptr[rax+9], 10
je source_compare_amomaxwrl_success
cmp byte ptr[rax+9], 32
je source_compare_amomaxwrl_success
cmp byte ptr[rax+9], 35
je source_compare_amomaxwrl_success
source_compare_amomaxwrl_failure:
mov al, 1
ret
source_compare_amomaxwrl_success:
xor al, al
ret


; out
; al status
source_compare_amomaxud:
cmp source_character_count, 8
jb source_compare_amomaxud_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxud_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxud_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxud_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxud_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxud_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxud_failure
cmp byte ptr[rax+6], 117
jne source_compare_amomaxud_failure
cmp byte ptr[rax+7], 100
jne source_compare_amomaxud_failure
cmp source_character_count, 8
je source_compare_amomaxud_success
cmp byte ptr[rax+8], 10
je source_compare_amomaxud_success
cmp byte ptr[rax+8], 32
je source_compare_amomaxud_success
cmp byte ptr[rax+8], 35
je source_compare_amomaxud_success
source_compare_amomaxud_failure:
mov al, 1
ret
source_compare_amomaxud_success:
xor al, al
ret


; out
; al status
source_compare_amomaxudaq:
cmp source_character_count, 10
jb source_compare_amomaxudaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxudaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxudaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxudaq_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxudaq_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxudaq_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxudaq_failure
cmp byte ptr[rax+6], 117
jne source_compare_amomaxudaq_failure
cmp byte ptr[rax+7], 100
jne source_compare_amomaxudaq_failure
cmp byte ptr[rax+8], 97
jne source_compare_amomaxudaq_failure
cmp byte ptr[rax+9], 113
jne source_compare_amomaxudaq_failure
cmp source_character_count, 10
je source_compare_amomaxudaq_success
cmp byte ptr[rax+10], 10
je source_compare_amomaxudaq_success
cmp byte ptr[rax+10], 32
je source_compare_amomaxudaq_success
cmp byte ptr[rax+10], 35
je source_compare_amomaxudaq_success
source_compare_amomaxudaq_failure:
mov al, 1
ret
source_compare_amomaxudaq_success:
xor al, al
ret


; out
; al status
source_compare_amomaxudaqrl:
cmp source_character_count, 12
jb source_compare_amomaxudaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+6], 117
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+7], 100
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+8], 97
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+9], 113
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+10], 114
jne source_compare_amomaxudaqrl_failure
cmp byte ptr[rax+11], 108
jne source_compare_amomaxudaqrl_failure
cmp source_character_count, 12
je source_compare_amomaxudaqrl_success
cmp byte ptr[rax+12], 10
je source_compare_amomaxudaqrl_success
cmp byte ptr[rax+12], 32
je source_compare_amomaxudaqrl_success
cmp byte ptr[rax+12], 35
je source_compare_amomaxudaqrl_success
source_compare_amomaxudaqrl_failure:
mov al, 1
ret
source_compare_amomaxudaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amomaxudrl:
cmp source_character_count, 10
jb source_compare_amomaxudrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxudrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxudrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxudrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxudrl_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxudrl_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxudrl_failure
cmp byte ptr[rax+6], 117
jne source_compare_amomaxudrl_failure
cmp byte ptr[rax+7], 100
jne source_compare_amomaxudrl_failure
cmp byte ptr[rax+8], 114
jne source_compare_amomaxudrl_failure
cmp byte ptr[rax+9], 108
jne source_compare_amomaxudrl_failure
cmp source_character_count, 10
je source_compare_amomaxudrl_success
cmp byte ptr[rax+10], 10
je source_compare_amomaxudrl_success
cmp byte ptr[rax+10], 32
je source_compare_amomaxudrl_success
cmp byte ptr[rax+10], 35
je source_compare_amomaxudrl_success
source_compare_amomaxudrl_failure:
mov al, 1
ret
source_compare_amomaxudrl_success:
xor al, al
ret


; out
; al status
source_compare_amomaxuw:
cmp source_character_count, 8
jb source_compare_amomaxuw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxuw_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxuw_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxuw_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxuw_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxuw_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxuw_failure
cmp byte ptr[rax+6], 117
jne source_compare_amomaxuw_failure
cmp byte ptr[rax+7], 119
jne source_compare_amomaxuw_failure
cmp source_character_count, 8
je source_compare_amomaxuw_success
cmp byte ptr[rax+8], 10
je source_compare_amomaxuw_success
cmp byte ptr[rax+8], 32
je source_compare_amomaxuw_success
cmp byte ptr[rax+8], 35
je source_compare_amomaxuw_success
source_compare_amomaxuw_failure:
mov al, 1
ret
source_compare_amomaxuw_success:
xor al, al
ret


; out
; al status
source_compare_amomaxuwaq:
cmp source_character_count, 10
jb source_compare_amomaxuwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxuwaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxuwaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxuwaq_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxuwaq_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxuwaq_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxuwaq_failure
cmp byte ptr[rax+6], 117
jne source_compare_amomaxuwaq_failure
cmp byte ptr[rax+7], 119
jne source_compare_amomaxuwaq_failure
cmp byte ptr[rax+8], 97
jne source_compare_amomaxuwaq_failure
cmp byte ptr[rax+9], 113
jne source_compare_amomaxuwaq_failure
cmp source_character_count, 10
je source_compare_amomaxuwaq_success
cmp byte ptr[rax+10], 10
je source_compare_amomaxuwaq_success
cmp byte ptr[rax+10], 32
je source_compare_amomaxuwaq_success
cmp byte ptr[rax+10], 35
je source_compare_amomaxuwaq_success
source_compare_amomaxuwaq_failure:
mov al, 1
ret
source_compare_amomaxuwaq_success:
xor al, al
ret


; out
; al status
source_compare_amomaxuwaqrl:
cmp source_character_count, 12
jb source_compare_amomaxuwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+6], 117
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+7], 119
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+8], 97
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+9], 113
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+10], 114
jne source_compare_amomaxuwaqrl_failure
cmp byte ptr[rax+11], 108
jne source_compare_amomaxuwaqrl_failure
cmp source_character_count, 12
je source_compare_amomaxuwaqrl_success
cmp byte ptr[rax+12], 10
je source_compare_amomaxuwaqrl_success
cmp byte ptr[rax+12], 32
je source_compare_amomaxuwaqrl_success
cmp byte ptr[rax+12], 35
je source_compare_amomaxuwaqrl_success
source_compare_amomaxuwaqrl_failure:
mov al, 1
ret
source_compare_amomaxuwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amomaxuwrl:
cmp source_character_count, 10
jb source_compare_amomaxuwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomaxuwrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomaxuwrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomaxuwrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomaxuwrl_failure
cmp byte ptr[rax+4], 97
jne source_compare_amomaxuwrl_failure
cmp byte ptr[rax+5], 120
jne source_compare_amomaxuwrl_failure
cmp byte ptr[rax+6], 117
jne source_compare_amomaxuwrl_failure
cmp byte ptr[rax+7], 119
jne source_compare_amomaxuwrl_failure
cmp byte ptr[rax+8], 114
jne source_compare_amomaxuwrl_failure
cmp byte ptr[rax+9], 108
jne source_compare_amomaxuwrl_failure
cmp source_character_count, 10
je source_compare_amomaxuwrl_success
cmp byte ptr[rax+10], 10
je source_compare_amomaxuwrl_success
cmp byte ptr[rax+10], 32
je source_compare_amomaxuwrl_success
cmp byte ptr[rax+10], 35
je source_compare_amomaxuwrl_success
source_compare_amomaxuwrl_failure:
mov al, 1
ret
source_compare_amomaxuwrl_success:
xor al, al
ret


; out
; al status
source_compare_amomind:
cmp source_character_count, 7
jb source_compare_amomind_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomind_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomind_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomind_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomind_failure
cmp byte ptr[rax+4], 105
jne source_compare_amomind_failure
cmp byte ptr[rax+5], 110
jne source_compare_amomind_failure
cmp byte ptr[rax+6], 100
jne source_compare_amomind_failure
cmp source_character_count, 7
je source_compare_amomind_success
cmp byte ptr[rax+7], 10
je source_compare_amomind_success
cmp byte ptr[rax+7], 32
je source_compare_amomind_success
cmp byte ptr[rax+7], 35
je source_compare_amomind_success
source_compare_amomind_failure:
mov al, 1
ret
source_compare_amomind_success:
xor al, al
ret


; out
; al status
source_compare_amomindaq:
cmp source_character_count, 9
jb source_compare_amomindaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomindaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomindaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomindaq_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomindaq_failure
cmp byte ptr[rax+4], 105
jne source_compare_amomindaq_failure
cmp byte ptr[rax+5], 110
jne source_compare_amomindaq_failure
cmp byte ptr[rax+6], 100
jne source_compare_amomindaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amomindaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amomindaq_failure
cmp source_character_count, 9
je source_compare_amomindaq_success
cmp byte ptr[rax+9], 10
je source_compare_amomindaq_success
cmp byte ptr[rax+9], 32
je source_compare_amomindaq_success
cmp byte ptr[rax+9], 35
je source_compare_amomindaq_success
source_compare_amomindaq_failure:
mov al, 1
ret
source_compare_amomindaq_success:
xor al, al
ret


; out
; al status
source_compare_amomindaqrl:
cmp source_character_count, 11
jb source_compare_amomindaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+4], 105
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+5], 110
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amomindaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amomindaqrl_failure
cmp source_character_count, 11
je source_compare_amomindaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amomindaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amomindaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amomindaqrl_success
source_compare_amomindaqrl_failure:
mov al, 1
ret
source_compare_amomindaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amomindrl:
cmp source_character_count, 9
jb source_compare_amomindrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amomindrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amomindrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amomindrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amomindrl_failure
cmp byte ptr[rax+4], 105
jne source_compare_amomindrl_failure
cmp byte ptr[rax+5], 110
jne source_compare_amomindrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amomindrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amomindrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amomindrl_failure
cmp source_character_count, 9
je source_compare_amomindrl_success
cmp byte ptr[rax+9], 10
je source_compare_amomindrl_success
cmp byte ptr[rax+9], 32
je source_compare_amomindrl_success
cmp byte ptr[rax+9], 35
je source_compare_amomindrl_success
source_compare_amomindrl_failure:
mov al, 1
ret
source_compare_amomindrl_success:
xor al, al
ret


; out
; al status
source_compare_amominw:
cmp source_character_count, 7
jb source_compare_amominw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominw_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominw_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominw_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominw_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominw_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominw_failure
cmp byte ptr[rax+6], 119
jne source_compare_amominw_failure
cmp source_character_count, 7
je source_compare_amominw_success
cmp byte ptr[rax+7], 10
je source_compare_amominw_success
cmp byte ptr[rax+7], 32
je source_compare_amominw_success
cmp byte ptr[rax+7], 35
je source_compare_amominw_success
source_compare_amominw_failure:
mov al, 1
ret
source_compare_amominw_success:
xor al, al
ret


; out
; al status
source_compare_amominwaq:
cmp source_character_count, 9
jb source_compare_amominwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominwaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominwaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominwaq_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominwaq_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominwaq_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominwaq_failure
cmp byte ptr[rax+6], 119
jne source_compare_amominwaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amominwaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amominwaq_failure
cmp source_character_count, 9
je source_compare_amominwaq_success
cmp byte ptr[rax+9], 10
je source_compare_amominwaq_success
cmp byte ptr[rax+9], 32
je source_compare_amominwaq_success
cmp byte ptr[rax+9], 35
je source_compare_amominwaq_success
source_compare_amominwaq_failure:
mov al, 1
ret
source_compare_amominwaq_success:
xor al, al
ret


; out
; al status
source_compare_amominwaqrl:
cmp source_character_count, 11
jb source_compare_amominwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amominwaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amominwaqrl_failure
cmp source_character_count, 11
je source_compare_amominwaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amominwaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amominwaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amominwaqrl_success
source_compare_amominwaqrl_failure:
mov al, 1
ret
source_compare_amominwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amominwrl:
cmp source_character_count, 9
jb source_compare_amominwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominwrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominwrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominwrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominwrl_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominwrl_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominwrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amominwrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amominwrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amominwrl_failure
cmp source_character_count, 9
je source_compare_amominwrl_success
cmp byte ptr[rax+9], 10
je source_compare_amominwrl_success
cmp byte ptr[rax+9], 32
je source_compare_amominwrl_success
cmp byte ptr[rax+9], 35
je source_compare_amominwrl_success
source_compare_amominwrl_failure:
mov al, 1
ret
source_compare_amominwrl_success:
xor al, al
ret


; out
; al status
source_compare_amominud:
cmp source_character_count, 8
jb source_compare_amominud_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominud_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominud_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominud_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominud_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominud_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominud_failure
cmp byte ptr[rax+6], 117
jne source_compare_amominud_failure
cmp byte ptr[rax+7], 100
jne source_compare_amominud_failure
cmp source_character_count, 8
je source_compare_amominud_success
cmp byte ptr[rax+8], 10
je source_compare_amominud_success
cmp byte ptr[rax+8], 32
je source_compare_amominud_success
cmp byte ptr[rax+8], 35
je source_compare_amominud_success
source_compare_amominud_failure:
mov al, 1
ret
source_compare_amominud_success:
xor al, al
ret


; out
; al status
source_compare_amominudaq:
cmp source_character_count, 10
jb source_compare_amominudaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominudaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominudaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominudaq_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominudaq_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominudaq_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominudaq_failure
cmp byte ptr[rax+6], 117
jne source_compare_amominudaq_failure
cmp byte ptr[rax+7], 100
jne source_compare_amominudaq_failure
cmp byte ptr[rax+8], 97
jne source_compare_amominudaq_failure
cmp byte ptr[rax+9], 113
jne source_compare_amominudaq_failure
cmp source_character_count, 10
je source_compare_amominudaq_success
cmp byte ptr[rax+10], 10
je source_compare_amominudaq_success
cmp byte ptr[rax+10], 32
je source_compare_amominudaq_success
cmp byte ptr[rax+10], 35
je source_compare_amominudaq_success
source_compare_amominudaq_failure:
mov al, 1
ret
source_compare_amominudaq_success:
xor al, al
ret


; out
; al status
source_compare_amominudaqrl:
cmp source_character_count, 12
jb source_compare_amominudaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+6], 117
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+7], 100
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+8], 97
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+9], 113
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+10], 114
jne source_compare_amominudaqrl_failure
cmp byte ptr[rax+11], 108
jne source_compare_amominudaqrl_failure
cmp source_character_count, 12
je source_compare_amominudaqrl_success
cmp byte ptr[rax+12], 10
je source_compare_amominudaqrl_success
cmp byte ptr[rax+12], 32
je source_compare_amominudaqrl_success
cmp byte ptr[rax+12], 35
je source_compare_amominudaqrl_success
source_compare_amominudaqrl_failure:
mov al, 1
ret
source_compare_amominudaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amominudrl:
cmp source_character_count, 10
jb source_compare_amominudrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominudrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominudrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominudrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominudrl_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominudrl_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominudrl_failure
cmp byte ptr[rax+6], 117
jne source_compare_amominudrl_failure
cmp byte ptr[rax+7], 100
jne source_compare_amominudrl_failure
cmp byte ptr[rax+8], 114
jne source_compare_amominudrl_failure
cmp byte ptr[rax+9], 108
jne source_compare_amominudrl_failure
cmp source_character_count, 10
je source_compare_amominudrl_success
cmp byte ptr[rax+10], 10
je source_compare_amominudrl_success
cmp byte ptr[rax+10], 32
je source_compare_amominudrl_success
cmp byte ptr[rax+10], 35
je source_compare_amominudrl_success
source_compare_amominudrl_failure:
mov al, 1
ret
source_compare_amominudrl_success:
xor al, al
ret


; out
; al status
source_compare_amominuw:
cmp source_character_count, 8
jb source_compare_amominuw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominuw_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominuw_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominuw_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominuw_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominuw_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominuw_failure
cmp byte ptr[rax+6], 117
jne source_compare_amominuw_failure
cmp byte ptr[rax+7], 119
jne source_compare_amominuw_failure
cmp source_character_count, 8
je source_compare_amominuw_success
cmp byte ptr[rax+8], 10
je source_compare_amominuw_success
cmp byte ptr[rax+8], 32
je source_compare_amominuw_success
cmp byte ptr[rax+8], 35
je source_compare_amominuw_success
source_compare_amominuw_failure:
mov al, 1
ret
source_compare_amominuw_success:
xor al, al
ret


; out
; al status
source_compare_amominuwaq:
cmp source_character_count, 10
jb source_compare_amominuwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominuwaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominuwaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominuwaq_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominuwaq_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominuwaq_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominuwaq_failure
cmp byte ptr[rax+6], 117
jne source_compare_amominuwaq_failure
cmp byte ptr[rax+7], 119
jne source_compare_amominuwaq_failure
cmp byte ptr[rax+8], 97
jne source_compare_amominuwaq_failure
cmp byte ptr[rax+9], 113
jne source_compare_amominuwaq_failure
cmp source_character_count, 10
je source_compare_amominuwaq_success
cmp byte ptr[rax+10], 10
je source_compare_amominuwaq_success
cmp byte ptr[rax+10], 32
je source_compare_amominuwaq_success
cmp byte ptr[rax+10], 35
je source_compare_amominuwaq_success
source_compare_amominuwaq_failure:
mov al, 1
ret
source_compare_amominuwaq_success:
xor al, al
ret


; out
; al status
source_compare_amominuwaqrl:
cmp source_character_count, 12
jb source_compare_amominuwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+6], 117
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+7], 119
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+8], 97
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+9], 113
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+10], 114
jne source_compare_amominuwaqrl_failure
cmp byte ptr[rax+11], 108
jne source_compare_amominuwaqrl_failure
cmp source_character_count, 12
je source_compare_amominuwaqrl_success
cmp byte ptr[rax+12], 10
je source_compare_amominuwaqrl_success
cmp byte ptr[rax+12], 32
je source_compare_amominuwaqrl_success
cmp byte ptr[rax+12], 35
je source_compare_amominuwaqrl_success
source_compare_amominuwaqrl_failure:
mov al, 1
ret
source_compare_amominuwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amominuwrl:
cmp source_character_count, 10
jb source_compare_amominuwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amominuwrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amominuwrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amominuwrl_failure
cmp byte ptr[rax+3], 109
jne source_compare_amominuwrl_failure
cmp byte ptr[rax+4], 105
jne source_compare_amominuwrl_failure
cmp byte ptr[rax+5], 110
jne source_compare_amominuwrl_failure
cmp byte ptr[rax+6], 117
jne source_compare_amominuwrl_failure
cmp byte ptr[rax+7], 119
jne source_compare_amominuwrl_failure
cmp byte ptr[rax+8], 114
jne source_compare_amominuwrl_failure
cmp byte ptr[rax+9], 108
jne source_compare_amominuwrl_failure
cmp source_character_count, 10
je source_compare_amominuwrl_success
cmp byte ptr[rax+10], 10
je source_compare_amominuwrl_success
cmp byte ptr[rax+10], 32
je source_compare_amominuwrl_success
cmp byte ptr[rax+10], 35
je source_compare_amominuwrl_success
source_compare_amominuwrl_failure:
mov al, 1
ret
source_compare_amominuwrl_success:
xor al, al
ret


; out
; al status
source_compare_amoord:
cmp source_character_count, 6
jb source_compare_amoord_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoord_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoord_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoord_failure
cmp byte ptr[rax+3], 111
jne source_compare_amoord_failure
cmp byte ptr[rax+4], 114
jne source_compare_amoord_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoord_failure
cmp source_character_count, 6
je source_compare_amoord_success
cmp byte ptr[rax+6], 10
je source_compare_amoord_success
cmp byte ptr[rax+6], 32
je source_compare_amoord_success
cmp byte ptr[rax+6], 35
je source_compare_amoord_success
source_compare_amoord_failure:
mov al, 1
ret
source_compare_amoord_success:
xor al, al
ret


; out
; al status
source_compare_amoordaq:
cmp source_character_count, 8
jb source_compare_amoordaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoordaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoordaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoordaq_failure
cmp byte ptr[rax+3], 111
jne source_compare_amoordaq_failure
cmp byte ptr[rax+4], 114
jne source_compare_amoordaq_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoordaq_failure
cmp byte ptr[rax+6], 97
jne source_compare_amoordaq_failure
cmp byte ptr[rax+7], 113
jne source_compare_amoordaq_failure
cmp source_character_count, 8
je source_compare_amoordaq_success
cmp byte ptr[rax+8], 10
je source_compare_amoordaq_success
cmp byte ptr[rax+8], 32
je source_compare_amoordaq_success
cmp byte ptr[rax+8], 35
je source_compare_amoordaq_success
source_compare_amoordaq_failure:
mov al, 1
ret
source_compare_amoordaq_success:
xor al, al
ret


; out
; al status
source_compare_amoordaqrl:
cmp source_character_count, 10
jb source_compare_amoordaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoordaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoordaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoordaqrl_failure
cmp byte ptr[rax+3], 111
jne source_compare_amoordaqrl_failure
cmp byte ptr[rax+4], 114
jne source_compare_amoordaqrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoordaqrl_failure
cmp byte ptr[rax+6], 97
jne source_compare_amoordaqrl_failure
cmp byte ptr[rax+7], 113
jne source_compare_amoordaqrl_failure
cmp byte ptr[rax+8], 114
jne source_compare_amoordaqrl_failure
cmp byte ptr[rax+9], 108
jne source_compare_amoordaqrl_failure
cmp source_character_count, 10
je source_compare_amoordaqrl_success
cmp byte ptr[rax+10], 10
je source_compare_amoordaqrl_success
cmp byte ptr[rax+10], 32
je source_compare_amoordaqrl_success
cmp byte ptr[rax+10], 35
je source_compare_amoordaqrl_success
source_compare_amoordaqrl_failure:
mov al, 1
ret
source_compare_amoordaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoordrl:
cmp source_character_count, 8
jb source_compare_amoordrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoordrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoordrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoordrl_failure
cmp byte ptr[rax+3], 111
jne source_compare_amoordrl_failure
cmp byte ptr[rax+4], 114
jne source_compare_amoordrl_failure
cmp byte ptr[rax+5], 100
jne source_compare_amoordrl_failure
cmp byte ptr[rax+6], 114
jne source_compare_amoordrl_failure
cmp byte ptr[rax+7], 108
jne source_compare_amoordrl_failure
cmp source_character_count, 8
je source_compare_amoordrl_success
cmp byte ptr[rax+8], 10
je source_compare_amoordrl_success
cmp byte ptr[rax+8], 32
je source_compare_amoordrl_success
cmp byte ptr[rax+8], 35
je source_compare_amoordrl_success
source_compare_amoordrl_failure:
mov al, 1
ret
source_compare_amoordrl_success:
xor al, al
ret


; out
; al status
source_compare_amoorw:
cmp source_character_count, 6
jb source_compare_amoorw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoorw_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoorw_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoorw_failure
cmp byte ptr[rax+3], 111
jne source_compare_amoorw_failure
cmp byte ptr[rax+4], 114
jne source_compare_amoorw_failure
cmp byte ptr[rax+5], 119
jne source_compare_amoorw_failure
cmp source_character_count, 6
je source_compare_amoorw_success
cmp byte ptr[rax+6], 10
je source_compare_amoorw_success
cmp byte ptr[rax+6], 32
je source_compare_amoorw_success
cmp byte ptr[rax+6], 35
je source_compare_amoorw_success
source_compare_amoorw_failure:
mov al, 1
ret
source_compare_amoorw_success:
xor al, al
ret


; out
; al status
source_compare_amoorwaq:
cmp source_character_count, 8
jb source_compare_amoorwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoorwaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoorwaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoorwaq_failure
cmp byte ptr[rax+3], 111
jne source_compare_amoorwaq_failure
cmp byte ptr[rax+4], 114
jne source_compare_amoorwaq_failure
cmp byte ptr[rax+5], 119
jne source_compare_amoorwaq_failure
cmp byte ptr[rax+6], 97
jne source_compare_amoorwaq_failure
cmp byte ptr[rax+7], 113
jne source_compare_amoorwaq_failure
cmp source_character_count, 8
je source_compare_amoorwaq_success
cmp byte ptr[rax+8], 10
je source_compare_amoorwaq_success
cmp byte ptr[rax+8], 32
je source_compare_amoorwaq_success
cmp byte ptr[rax+8], 35
je source_compare_amoorwaq_success
source_compare_amoorwaq_failure:
mov al, 1
ret
source_compare_amoorwaq_success:
xor al, al
ret


; out
; al status
source_compare_amoorwaqrl:
cmp source_character_count, 10
jb source_compare_amoorwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoorwaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoorwaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoorwaqrl_failure
cmp byte ptr[rax+3], 111
jne source_compare_amoorwaqrl_failure
cmp byte ptr[rax+4], 114
jne source_compare_amoorwaqrl_failure
cmp byte ptr[rax+5], 119
jne source_compare_amoorwaqrl_failure
cmp byte ptr[rax+6], 97
jne source_compare_amoorwaqrl_failure
cmp byte ptr[rax+7], 113
jne source_compare_amoorwaqrl_failure
cmp byte ptr[rax+8], 114
jne source_compare_amoorwaqrl_failure
cmp byte ptr[rax+9], 108
jne source_compare_amoorwaqrl_failure
cmp source_character_count, 10
je source_compare_amoorwaqrl_success
cmp byte ptr[rax+10], 10
je source_compare_amoorwaqrl_success
cmp byte ptr[rax+10], 32
je source_compare_amoorwaqrl_success
cmp byte ptr[rax+10], 35
je source_compare_amoorwaqrl_success
source_compare_amoorwaqrl_failure:
mov al, 1
ret
source_compare_amoorwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoorwrl:
cmp source_character_count, 8
jb source_compare_amoorwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoorwrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoorwrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoorwrl_failure
cmp byte ptr[rax+3], 111
jne source_compare_amoorwrl_failure
cmp byte ptr[rax+4], 114
jne source_compare_amoorwrl_failure
cmp byte ptr[rax+5], 119
jne source_compare_amoorwrl_failure
cmp byte ptr[rax+6], 114
jne source_compare_amoorwrl_failure
cmp byte ptr[rax+7], 108
jne source_compare_amoorwrl_failure
cmp source_character_count, 8
je source_compare_amoorwrl_success
cmp byte ptr[rax+8], 10
je source_compare_amoorwrl_success
cmp byte ptr[rax+8], 32
je source_compare_amoorwrl_success
cmp byte ptr[rax+8], 35
je source_compare_amoorwrl_success
source_compare_amoorwrl_failure:
mov al, 1
ret
source_compare_amoorwrl_success:
xor al, al
ret


; out
; al status
source_compare_amoswapd:
cmp source_character_count, 8
jb source_compare_amoswapd_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoswapd_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoswapd_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoswapd_failure
cmp byte ptr[rax+3], 115
jne source_compare_amoswapd_failure
cmp byte ptr[rax+4], 119
jne source_compare_amoswapd_failure
cmp byte ptr[rax+5], 97
jne source_compare_amoswapd_failure
cmp byte ptr[rax+6], 112
jne source_compare_amoswapd_failure
cmp byte ptr[rax+7], 100
jne source_compare_amoswapd_failure
cmp source_character_count, 8
je source_compare_amoswapd_success
cmp byte ptr[rax+8], 10
je source_compare_amoswapd_success
cmp byte ptr[rax+8], 32
je source_compare_amoswapd_success
cmp byte ptr[rax+8], 35
je source_compare_amoswapd_success
source_compare_amoswapd_failure:
mov al, 1
ret
source_compare_amoswapd_success:
xor al, al
ret


; out
; al status
source_compare_amoswapdaq:
cmp source_character_count, 10
jb source_compare_amoswapdaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoswapdaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoswapdaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoswapdaq_failure
cmp byte ptr[rax+3], 115
jne source_compare_amoswapdaq_failure
cmp byte ptr[rax+4], 119
jne source_compare_amoswapdaq_failure
cmp byte ptr[rax+5], 97
jne source_compare_amoswapdaq_failure
cmp byte ptr[rax+6], 112
jne source_compare_amoswapdaq_failure
cmp byte ptr[rax+7], 100
jne source_compare_amoswapdaq_failure
cmp byte ptr[rax+8], 97
jne source_compare_amoswapdaq_failure
cmp byte ptr[rax+9], 113
jne source_compare_amoswapdaq_failure
cmp source_character_count, 10
je source_compare_amoswapdaq_success
cmp byte ptr[rax+10], 10
je source_compare_amoswapdaq_success
cmp byte ptr[rax+10], 32
je source_compare_amoswapdaq_success
cmp byte ptr[rax+10], 35
je source_compare_amoswapdaq_success
source_compare_amoswapdaq_failure:
mov al, 1
ret
source_compare_amoswapdaq_success:
xor al, al
ret


; out
; al status
source_compare_amoswapdaqrl:
cmp source_character_count, 12
jb source_compare_amoswapdaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+3], 115
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+4], 119
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+5], 97
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+6], 112
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+7], 100
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+8], 97
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+9], 113
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+10], 114
jne source_compare_amoswapdaqrl_failure
cmp byte ptr[rax+11], 108
jne source_compare_amoswapdaqrl_failure
cmp source_character_count, 12
je source_compare_amoswapdaqrl_success
cmp byte ptr[rax+12], 10
je source_compare_amoswapdaqrl_success
cmp byte ptr[rax+12], 32
je source_compare_amoswapdaqrl_success
cmp byte ptr[rax+12], 35
je source_compare_amoswapdaqrl_success
source_compare_amoswapdaqrl_failure:
mov al, 1
ret
source_compare_amoswapdaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoswapdrl:
cmp source_character_count, 10
jb source_compare_amoswapdrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoswapdrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoswapdrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoswapdrl_failure
cmp byte ptr[rax+3], 115
jne source_compare_amoswapdrl_failure
cmp byte ptr[rax+4], 119
jne source_compare_amoswapdrl_failure
cmp byte ptr[rax+5], 97
jne source_compare_amoswapdrl_failure
cmp byte ptr[rax+6], 112
jne source_compare_amoswapdrl_failure
cmp byte ptr[rax+7], 100
jne source_compare_amoswapdrl_failure
cmp byte ptr[rax+8], 114
jne source_compare_amoswapdrl_failure
cmp byte ptr[rax+9], 108
jne source_compare_amoswapdrl_failure
cmp source_character_count, 10
je source_compare_amoswapdrl_success
cmp byte ptr[rax+10], 10
je source_compare_amoswapdrl_success
cmp byte ptr[rax+10], 32
je source_compare_amoswapdrl_success
cmp byte ptr[rax+10], 35
je source_compare_amoswapdrl_success
source_compare_amoswapdrl_failure:
mov al, 1
ret
source_compare_amoswapdrl_success:
xor al, al
ret


; out
; al status
source_compare_amoswapw:
cmp source_character_count, 8
jb source_compare_amoswapw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoswapw_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoswapw_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoswapw_failure
cmp byte ptr[rax+3], 115
jne source_compare_amoswapw_failure
cmp byte ptr[rax+4], 119
jne source_compare_amoswapw_failure
cmp byte ptr[rax+5], 97
jne source_compare_amoswapw_failure
cmp byte ptr[rax+6], 112
jne source_compare_amoswapw_failure
cmp byte ptr[rax+7], 119
jne source_compare_amoswapw_failure
cmp source_character_count, 8
je source_compare_amoswapw_success
cmp byte ptr[rax+8], 10
je source_compare_amoswapw_success
cmp byte ptr[rax+8], 32
je source_compare_amoswapw_success
cmp byte ptr[rax+8], 35
je source_compare_amoswapw_success
source_compare_amoswapw_failure:
mov al, 1
ret
source_compare_amoswapw_success:
xor al, al
ret


; out
; al status
source_compare_amoswapwaq:
cmp source_character_count, 10
jb source_compare_amoswapwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoswapwaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoswapwaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoswapwaq_failure
cmp byte ptr[rax+3], 115
jne source_compare_amoswapwaq_failure
cmp byte ptr[rax+4], 119
jne source_compare_amoswapwaq_failure
cmp byte ptr[rax+5], 97
jne source_compare_amoswapwaq_failure
cmp byte ptr[rax+6], 112
jne source_compare_amoswapwaq_failure
cmp byte ptr[rax+7], 119
jne source_compare_amoswapwaq_failure
cmp byte ptr[rax+8], 97
jne source_compare_amoswapwaq_failure
cmp byte ptr[rax+9], 113
jne source_compare_amoswapwaq_failure
cmp source_character_count, 10
je source_compare_amoswapwaq_success
cmp byte ptr[rax+10], 10
je source_compare_amoswapwaq_success
cmp byte ptr[rax+10], 32
je source_compare_amoswapwaq_success
cmp byte ptr[rax+10], 35
je source_compare_amoswapwaq_success
source_compare_amoswapwaq_failure:
mov al, 1
ret
source_compare_amoswapwaq_success:
xor al, al
ret


; out
; al status
source_compare_amoswapwaqrl:
cmp source_character_count, 12
jb source_compare_amoswapwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+3], 115
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+4], 119
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+5], 97
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+6], 112
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+7], 119
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+8], 97
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+9], 113
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+10], 114
jne source_compare_amoswapwaqrl_failure
cmp byte ptr[rax+11], 108
jne source_compare_amoswapwaqrl_failure
cmp source_character_count, 12
je source_compare_amoswapwaqrl_success
cmp byte ptr[rax+12], 10
je source_compare_amoswapwaqrl_success
cmp byte ptr[rax+12], 32
je source_compare_amoswapwaqrl_success
cmp byte ptr[rax+12], 35
je source_compare_amoswapwaqrl_success
source_compare_amoswapwaqrl_failure:
mov al, 1
ret
source_compare_amoswapwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoswapwrl:
cmp source_character_count, 10
jb source_compare_amoswapwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoswapwrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoswapwrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoswapwrl_failure
cmp byte ptr[rax+3], 115
jne source_compare_amoswapwrl_failure
cmp byte ptr[rax+4], 119
jne source_compare_amoswapwrl_failure
cmp byte ptr[rax+5], 97
jne source_compare_amoswapwrl_failure
cmp byte ptr[rax+6], 112
jne source_compare_amoswapwrl_failure
cmp byte ptr[rax+7], 119
jne source_compare_amoswapwrl_failure
cmp byte ptr[rax+8], 114
jne source_compare_amoswapwrl_failure
cmp byte ptr[rax+9], 108
jne source_compare_amoswapwrl_failure
cmp source_character_count, 10
je source_compare_amoswapwrl_success
cmp byte ptr[rax+10], 10
je source_compare_amoswapwrl_success
cmp byte ptr[rax+10], 32
je source_compare_amoswapwrl_success
cmp byte ptr[rax+10], 35
je source_compare_amoswapwrl_success
source_compare_amoswapwrl_failure:
mov al, 1
ret
source_compare_amoswapwrl_success:
xor al, al
ret


; out
; al status
source_compare_amoxord:
cmp source_character_count, 7
jb source_compare_amoxord_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoxord_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoxord_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoxord_failure
cmp byte ptr[rax+3], 120
jne source_compare_amoxord_failure
cmp byte ptr[rax+4], 111
jne source_compare_amoxord_failure
cmp byte ptr[rax+5], 114
jne source_compare_amoxord_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoxord_failure
cmp source_character_count, 7
je source_compare_amoxord_success
cmp byte ptr[rax+7], 10
je source_compare_amoxord_success
cmp byte ptr[rax+7], 32
je source_compare_amoxord_success
cmp byte ptr[rax+7], 35
je source_compare_amoxord_success
source_compare_amoxord_failure:
mov al, 1
ret
source_compare_amoxord_success:
xor al, al
ret


; out
; al status
source_compare_amoxordaq:
cmp source_character_count, 9
jb source_compare_amoxordaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoxordaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoxordaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoxordaq_failure
cmp byte ptr[rax+3], 120
jne source_compare_amoxordaq_failure
cmp byte ptr[rax+4], 111
jne source_compare_amoxordaq_failure
cmp byte ptr[rax+5], 114
jne source_compare_amoxordaq_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoxordaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoxordaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoxordaq_failure
cmp source_character_count, 9
je source_compare_amoxordaq_success
cmp byte ptr[rax+9], 10
je source_compare_amoxordaq_success
cmp byte ptr[rax+9], 32
je source_compare_amoxordaq_success
cmp byte ptr[rax+9], 35
je source_compare_amoxordaq_success
source_compare_amoxordaq_failure:
mov al, 1
ret
source_compare_amoxordaq_success:
xor al, al
ret


; out
; al status
source_compare_amoxordaqrl:
cmp source_character_count, 11
jb source_compare_amoxordaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+3], 120
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+4], 111
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+5], 114
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amoxordaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amoxordaqrl_failure
cmp source_character_count, 11
je source_compare_amoxordaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amoxordaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amoxordaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amoxordaqrl_success
source_compare_amoxordaqrl_failure:
mov al, 1
ret
source_compare_amoxordaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoxordrl:
cmp source_character_count, 9
jb source_compare_amoxordrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoxordrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoxordrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoxordrl_failure
cmp byte ptr[rax+3], 120
jne source_compare_amoxordrl_failure
cmp byte ptr[rax+4], 111
jne source_compare_amoxordrl_failure
cmp byte ptr[rax+5], 114
jne source_compare_amoxordrl_failure
cmp byte ptr[rax+6], 100
jne source_compare_amoxordrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amoxordrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amoxordrl_failure
cmp source_character_count, 9
je source_compare_amoxordrl_success
cmp byte ptr[rax+9], 10
je source_compare_amoxordrl_success
cmp byte ptr[rax+9], 32
je source_compare_amoxordrl_success
cmp byte ptr[rax+9], 35
je source_compare_amoxordrl_success
source_compare_amoxordrl_failure:
mov al, 1
ret
source_compare_amoxordrl_success:
xor al, al
ret


; out
; al status
source_compare_amoxorw:
cmp source_character_count, 7
jb source_compare_amoxorw_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoxorw_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoxorw_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoxorw_failure
cmp byte ptr[rax+3], 120
jne source_compare_amoxorw_failure
cmp byte ptr[rax+4], 111
jne source_compare_amoxorw_failure
cmp byte ptr[rax+5], 114
jne source_compare_amoxorw_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoxorw_failure
cmp source_character_count, 7
je source_compare_amoxorw_success
cmp byte ptr[rax+7], 10
je source_compare_amoxorw_success
cmp byte ptr[rax+7], 32
je source_compare_amoxorw_success
cmp byte ptr[rax+7], 35
je source_compare_amoxorw_success
source_compare_amoxorw_failure:
mov al, 1
ret
source_compare_amoxorw_success:
xor al, al
ret


; out
; al status
source_compare_amoxorwaq:
cmp source_character_count, 9
jb source_compare_amoxorwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoxorwaq_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoxorwaq_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoxorwaq_failure
cmp byte ptr[rax+3], 120
jne source_compare_amoxorwaq_failure
cmp byte ptr[rax+4], 111
jne source_compare_amoxorwaq_failure
cmp byte ptr[rax+5], 114
jne source_compare_amoxorwaq_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoxorwaq_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoxorwaq_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoxorwaq_failure
cmp source_character_count, 9
je source_compare_amoxorwaq_success
cmp byte ptr[rax+9], 10
je source_compare_amoxorwaq_success
cmp byte ptr[rax+9], 32
je source_compare_amoxorwaq_success
cmp byte ptr[rax+9], 35
je source_compare_amoxorwaq_success
source_compare_amoxorwaq_failure:
mov al, 1
ret
source_compare_amoxorwaq_success:
xor al, al
ret


; out
; al status
source_compare_amoxorwaqrl:
cmp source_character_count, 11
jb source_compare_amoxorwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+3], 120
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+4], 111
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+5], 114
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+7], 97
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+8], 113
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+9], 114
jne source_compare_amoxorwaqrl_failure
cmp byte ptr[rax+10], 108
jne source_compare_amoxorwaqrl_failure
cmp source_character_count, 11
je source_compare_amoxorwaqrl_success
cmp byte ptr[rax+11], 10
je source_compare_amoxorwaqrl_success
cmp byte ptr[rax+11], 32
je source_compare_amoxorwaqrl_success
cmp byte ptr[rax+11], 35
je source_compare_amoxorwaqrl_success
source_compare_amoxorwaqrl_failure:
mov al, 1
ret
source_compare_amoxorwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_amoxorwrl:
cmp source_character_count, 9
jb source_compare_amoxorwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_amoxorwrl_failure
cmp byte ptr[rax+1], 109
jne source_compare_amoxorwrl_failure
cmp byte ptr[rax+2], 111
jne source_compare_amoxorwrl_failure
cmp byte ptr[rax+3], 120
jne source_compare_amoxorwrl_failure
cmp byte ptr[rax+4], 111
jne source_compare_amoxorwrl_failure
cmp byte ptr[rax+5], 114
jne source_compare_amoxorwrl_failure
cmp byte ptr[rax+6], 119
jne source_compare_amoxorwrl_failure
cmp byte ptr[rax+7], 114
jne source_compare_amoxorwrl_failure
cmp byte ptr[rax+8], 108
jne source_compare_amoxorwrl_failure
cmp source_character_count, 9
je source_compare_amoxorwrl_success
cmp byte ptr[rax+9], 10
je source_compare_amoxorwrl_success
cmp byte ptr[rax+9], 32
je source_compare_amoxorwrl_success
cmp byte ptr[rax+9], 35
je source_compare_amoxorwrl_success
source_compare_amoxorwrl_failure:
mov al, 1
ret
source_compare_amoxorwrl_success:
xor al, al
ret


; out
; al status
source_compare_and:
cmp source_character_count, 3
jb source_compare_and_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_and_failure
cmp byte ptr[rax+1], 110
jne source_compare_and_failure
cmp byte ptr[rax+2], 100
jne source_compare_and_failure
cmp source_character_count, 3
je source_compare_and_success
cmp byte ptr[rax+3], 10
je source_compare_and_success
cmp byte ptr[rax+3], 32
je source_compare_and_success
cmp byte ptr[rax+3], 35
je source_compare_and_success
source_compare_and_failure:
mov al, 1
ret
source_compare_and_success:
xor al, al
ret


; out
; al status
source_compare_andi:
cmp source_character_count, 4
jb source_compare_andi_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_andi_failure
cmp byte ptr[rax+1], 110
jne source_compare_andi_failure
cmp byte ptr[rax+2], 100
jne source_compare_andi_failure
cmp byte ptr[rax+3], 105
jne source_compare_andi_failure
cmp source_character_count, 4
je source_compare_andi_success
cmp byte ptr[rax+4], 10
je source_compare_andi_success
cmp byte ptr[rax+4], 32
je source_compare_andi_success
cmp byte ptr[rax+4], 35
je source_compare_andi_success
source_compare_andi_failure:
mov al, 1
ret
source_compare_andi_success:
xor al, al
ret


; out
; al status
source_compare_auipc:
cmp source_character_count, 5
jb source_compare_auipc_failure
mov rax, source_character_address
cmp byte ptr[rax], 97
jne source_compare_auipc_failure
cmp byte ptr[rax+1], 117
jne source_compare_auipc_failure
cmp byte ptr[rax+2], 105
jne source_compare_auipc_failure
cmp byte ptr[rax+3], 112
jne source_compare_auipc_failure
cmp byte ptr[rax+4], 99
jne source_compare_auipc_failure
cmp source_character_count, 5
je source_compare_auipc_success
cmp byte ptr[rax+5], 10
je source_compare_auipc_success
cmp byte ptr[rax+5], 32
je source_compare_auipc_success
cmp byte ptr[rax+5], 35
je source_compare_auipc_success
source_compare_auipc_failure:
mov al, 1
ret
source_compare_auipc_success:
xor al, al
ret


; out
; al status
source_compare_beq:
cmp source_character_count, 3
jb source_compare_beq_failure
mov rax, source_character_address
cmp byte ptr[rax], 98
jne source_compare_beq_failure
cmp byte ptr[rax+1], 101
jne source_compare_beq_failure
cmp byte ptr[rax+2], 113
jne source_compare_beq_failure
cmp source_character_count, 3
je source_compare_beq_success
cmp byte ptr[rax+3], 10
je source_compare_beq_success
cmp byte ptr[rax+3], 32
je source_compare_beq_success
cmp byte ptr[rax+3], 35
je source_compare_beq_success
source_compare_beq_failure:
mov al, 1
ret
source_compare_beq_success:
xor al, al
ret


; out
; al status
source_compare_bge:
cmp source_character_count, 3
jb source_compare_bge_failure
mov rax, source_character_address
cmp byte ptr[rax], 98
jne source_compare_bge_failure
cmp byte ptr[rax+1], 103
jne source_compare_bge_failure
cmp byte ptr[rax+2], 101
jne source_compare_bge_failure
cmp source_character_count, 3
je source_compare_bge_success
cmp byte ptr[rax+3], 10
je source_compare_bge_success
cmp byte ptr[rax+3], 32
je source_compare_bge_success
cmp byte ptr[rax+3], 35
je source_compare_bge_success
source_compare_bge_failure:
mov al, 1
ret
source_compare_bge_success:
xor al, al
ret


; out
; al status
source_compare_bgeu:
cmp source_character_count, 4
jb source_compare_bgeu_failure
mov rax, source_character_address
cmp byte ptr[rax], 98
jne source_compare_bgeu_failure
cmp byte ptr[rax+1], 103
jne source_compare_bgeu_failure
cmp byte ptr[rax+2], 101
jne source_compare_bgeu_failure
cmp byte ptr[rax+3], 117
jne source_compare_bgeu_failure
cmp source_character_count, 4
je source_compare_bgeu_success
cmp byte ptr[rax+4], 10
je source_compare_bgeu_success
cmp byte ptr[rax+4], 32
je source_compare_bgeu_success
cmp byte ptr[rax+4], 35
je source_compare_bgeu_success
source_compare_bgeu_failure:
mov al, 1
ret
source_compare_bgeu_success:
xor al, al
ret


; out
; al status
source_compare_blt:
cmp source_character_count, 3
jb source_compare_blt_failure
mov rax, source_character_address
cmp byte ptr[rax], 98
jne source_compare_blt_failure
cmp byte ptr[rax+1], 108
jne source_compare_blt_failure
cmp byte ptr[rax+2], 116
jne source_compare_blt_failure
cmp source_character_count, 3
je source_compare_blt_success
cmp byte ptr[rax+3], 10
je source_compare_blt_success
cmp byte ptr[rax+3], 32
je source_compare_blt_success
cmp byte ptr[rax+3], 35
je source_compare_blt_success
source_compare_blt_failure:
mov al, 1
ret
source_compare_blt_success:
xor al, al
ret


; out
; al status
source_compare_bltu:
cmp source_character_count, 4
jb source_compare_bltu_failure
mov rax, source_character_address
cmp byte ptr[rax], 98
jne source_compare_bltu_failure
cmp byte ptr[rax+1], 108
jne source_compare_bltu_failure
cmp byte ptr[rax+2], 116
jne source_compare_bltu_failure
cmp byte ptr[rax+3], 117
jne source_compare_bltu_failure
cmp source_character_count, 4
je source_compare_bltu_success
cmp byte ptr[rax+4], 10
je source_compare_bltu_success
cmp byte ptr[rax+4], 32
je source_compare_bltu_success
cmp byte ptr[rax+4], 35
je source_compare_bltu_success
source_compare_bltu_failure:
mov al, 1
ret
source_compare_bltu_success:
xor al, al
ret


; out
; al status
source_compare_bne:
cmp source_character_count, 3
jb source_compare_bne_failure
mov rax, source_character_address
cmp byte ptr[rax], 98
jne source_compare_bne_failure
cmp byte ptr[rax+1], 110
jne source_compare_bne_failure
cmp byte ptr[rax+2], 101
jne source_compare_bne_failure
cmp source_character_count, 3
je source_compare_bne_success
cmp byte ptr[rax+3], 10
je source_compare_bne_success
cmp byte ptr[rax+3], 32
je source_compare_bne_success
cmp byte ptr[rax+3], 35
je source_compare_bne_success
source_compare_bne_failure:
mov al, 1
ret
source_compare_bne_success:
xor al, al
ret


; out
; al status
source_compare_byte:
cmp source_character_count, 4
jb source_compare_byte_failure
mov rax, source_character_address
cmp byte ptr[rax], 98
jne source_compare_byte_failure
cmp byte ptr[rax+1], 121
jne source_compare_byte_failure
cmp byte ptr[rax+2], 116
jne source_compare_byte_failure
cmp byte ptr[rax+3], 101
jne source_compare_byte_failure
cmp source_character_count, 4
je source_compare_byte_success
cmp byte ptr[rax+4], 10
je source_compare_byte_success
cmp byte ptr[rax+4], 32
je source_compare_byte_success
cmp byte ptr[rax+4], 35
je source_compare_byte_success
source_compare_byte_failure:
mov al, 1
ret
source_compare_byte_success:
xor al, al
ret


; out
; al status
source_compare_call:
cmp source_character_count, 4
jb source_compare_call_failure
mov rax, source_character_address
cmp byte ptr[rax], 99
jne source_compare_call_failure
cmp byte ptr[rax+1], 97
jne source_compare_call_failure
cmp byte ptr[rax+2], 108
jne source_compare_call_failure
cmp byte ptr[rax+3], 108
jne source_compare_call_failure
cmp source_character_count, 4
je source_compare_call_success
cmp byte ptr[rax+4], 10
je source_compare_call_success
cmp byte ptr[rax+4], 32
je source_compare_call_success
cmp byte ptr[rax+4], 35
je source_compare_call_success
source_compare_call_failure:
mov al, 1
ret
source_compare_call_success:
xor al, al
ret


; out
; al status
source_compare_constant:
cmp source_character_count, 8
jb source_compare_constant_failure
mov rax, source_character_address
cmp byte ptr[rax], 99
jne source_compare_constant_failure
cmp byte ptr[rax+1], 111
jne source_compare_constant_failure
cmp byte ptr[rax+2], 110
jne source_compare_constant_failure
cmp byte ptr[rax+3], 115
jne source_compare_constant_failure
cmp byte ptr[rax+4], 116
jne source_compare_constant_failure
cmp byte ptr[rax+5], 97
jne source_compare_constant_failure
cmp byte ptr[rax+6], 110
jne source_compare_constant_failure
cmp byte ptr[rax+7], 116
jne source_compare_constant_failure
cmp source_character_count, 8
je source_compare_constant_success
cmp byte ptr[rax+8], 10
je source_compare_constant_success
cmp byte ptr[rax+8], 32
je source_compare_constant_success
cmp byte ptr[rax+8], 35
je source_compare_constant_success
source_compare_constant_failure:
mov al, 1
ret
source_compare_constant_success:
xor al, al
ret


; out
; al status
source_compare_csrrc:
cmp source_character_count, 5
jb source_compare_csrrc_failure
mov rax, source_character_address
cmp byte ptr[rax], 99
jne source_compare_csrrc_failure
cmp byte ptr[rax+1], 115
jne source_compare_csrrc_failure
cmp byte ptr[rax+2], 114
jne source_compare_csrrc_failure
cmp byte ptr[rax+3], 114
jne source_compare_csrrc_failure
cmp byte ptr[rax+4], 99
jne source_compare_csrrc_failure
cmp source_character_count, 5
je source_compare_csrrc_success
cmp byte ptr[rax+5], 10
je source_compare_csrrc_success
cmp byte ptr[rax+5], 32
je source_compare_csrrc_success
cmp byte ptr[rax+5], 35
je source_compare_csrrc_success
source_compare_csrrc_failure:
mov al, 1
ret
source_compare_csrrc_success:
xor al, al
ret


; out
; al status
source_compare_csrrci:
cmp source_character_count, 6
jb source_compare_csrrci_failure
mov rax, source_character_address
cmp byte ptr[rax], 99
jne source_compare_csrrci_failure
cmp byte ptr[rax+1], 115
jne source_compare_csrrci_failure
cmp byte ptr[rax+2], 114
jne source_compare_csrrci_failure
cmp byte ptr[rax+3], 114
jne source_compare_csrrci_failure
cmp byte ptr[rax+4], 99
jne source_compare_csrrci_failure
cmp byte ptr[rax+5], 105
jne source_compare_csrrci_failure
cmp source_character_count, 6
je source_compare_csrrci_success
cmp byte ptr[rax+6], 10
je source_compare_csrrci_success
cmp byte ptr[rax+6], 32
je source_compare_csrrci_success
cmp byte ptr[rax+6], 35
je source_compare_csrrci_success
source_compare_csrrci_failure:
mov al, 1
ret
source_compare_csrrci_success:
xor al, al
ret


; out
; al status
source_compare_csrrs:
cmp source_character_count, 5
jb source_compare_csrrs_failure
mov rax, source_character_address
cmp byte ptr[rax], 99
jne source_compare_csrrs_failure
cmp byte ptr[rax+1], 115
jne source_compare_csrrs_failure
cmp byte ptr[rax+2], 114
jne source_compare_csrrs_failure
cmp byte ptr[rax+3], 114
jne source_compare_csrrs_failure
cmp byte ptr[rax+4], 115
jne source_compare_csrrs_failure
cmp source_character_count, 5
je source_compare_csrrs_success
cmp byte ptr[rax+5], 10
je source_compare_csrrs_success
cmp byte ptr[rax+5], 32
je source_compare_csrrs_success
cmp byte ptr[rax+5], 35
je source_compare_csrrs_success
source_compare_csrrs_failure:
mov al, 1
ret
source_compare_csrrs_success:
xor al, al
ret


; out
; al status
source_compare_csrrsi:
cmp source_character_count, 6
jb source_compare_csrrsi_failure
mov rax, source_character_address
cmp byte ptr[rax], 99
jne source_compare_csrrsi_failure
cmp byte ptr[rax+1], 115
jne source_compare_csrrsi_failure
cmp byte ptr[rax+2], 114
jne source_compare_csrrsi_failure
cmp byte ptr[rax+3], 114
jne source_compare_csrrsi_failure
cmp byte ptr[rax+4], 115
jne source_compare_csrrsi_failure
cmp byte ptr[rax+5], 105
jne source_compare_csrrsi_failure
cmp source_character_count, 6
je source_compare_csrrsi_success
cmp byte ptr[rax+6], 10
je source_compare_csrrsi_success
cmp byte ptr[rax+6], 32
je source_compare_csrrsi_success
cmp byte ptr[rax+6], 35
je source_compare_csrrsi_success
source_compare_csrrsi_failure:
mov al, 1
ret
source_compare_csrrsi_success:
xor al, al
ret


; out
; al status
source_compare_csrrw:
cmp source_character_count, 5
jb source_compare_csrrw_failure
mov rax, source_character_address
cmp byte ptr[rax], 99
jne source_compare_csrrw_failure
cmp byte ptr[rax+1], 115
jne source_compare_csrrw_failure
cmp byte ptr[rax+2], 114
jne source_compare_csrrw_failure
cmp byte ptr[rax+3], 114
jne source_compare_csrrw_failure
cmp byte ptr[rax+4], 119
jne source_compare_csrrw_failure
cmp source_character_count, 5
je source_compare_csrrw_success
cmp byte ptr[rax+5], 10
je source_compare_csrrw_success
cmp byte ptr[rax+5], 32
je source_compare_csrrw_success
cmp byte ptr[rax+5], 35
je source_compare_csrrw_success
source_compare_csrrw_failure:
mov al, 1
ret
source_compare_csrrw_success:
xor al, al
ret


; out
; al status
source_compare_csrrwi:
cmp source_character_count, 6
jb source_compare_csrrwi_failure
mov rax, source_character_address
cmp byte ptr[rax], 99
jne source_compare_csrrwi_failure
cmp byte ptr[rax+1], 115
jne source_compare_csrrwi_failure
cmp byte ptr[rax+2], 114
jne source_compare_csrrwi_failure
cmp byte ptr[rax+3], 114
jne source_compare_csrrwi_failure
cmp byte ptr[rax+4], 119
jne source_compare_csrrwi_failure
cmp byte ptr[rax+5], 105
jne source_compare_csrrwi_failure
cmp source_character_count, 6
je source_compare_csrrwi_success
cmp byte ptr[rax+6], 10
je source_compare_csrrwi_success
cmp byte ptr[rax+6], 32
je source_compare_csrrwi_success
cmp byte ptr[rax+6], 35
je source_compare_csrrwi_success
source_compare_csrrwi_failure:
mov al, 1
ret
source_compare_csrrwi_success:
xor al, al
ret


; out
; al status
source_compare_div:
cmp source_character_count, 3
jb source_compare_div_failure
mov rax, source_character_address
cmp byte ptr[rax], 100
jne source_compare_div_failure
cmp byte ptr[rax+1], 105
jne source_compare_div_failure
cmp byte ptr[rax+2], 118
jne source_compare_div_failure
cmp source_character_count, 3
je source_compare_div_success
cmp byte ptr[rax+3], 10
je source_compare_div_success
cmp byte ptr[rax+3], 32
je source_compare_div_success
cmp byte ptr[rax+3], 35
je source_compare_div_success
source_compare_div_failure:
mov al, 1
ret
source_compare_div_success:
xor al, al
ret


; out
; al status
source_compare_divu:
cmp source_character_count, 4
jb source_compare_divu_failure
mov rax, source_character_address
cmp byte ptr[rax], 100
jne source_compare_divu_failure
cmp byte ptr[rax+1], 105
jne source_compare_divu_failure
cmp byte ptr[rax+2], 118
jne source_compare_divu_failure
cmp byte ptr[rax+3], 117
jne source_compare_divu_failure
cmp source_character_count, 4
je source_compare_divu_success
cmp byte ptr[rax+4], 10
je source_compare_divu_success
cmp byte ptr[rax+4], 32
je source_compare_divu_success
cmp byte ptr[rax+4], 35
je source_compare_divu_success
source_compare_divu_failure:
mov al, 1
ret
source_compare_divu_success:
xor al, al
ret


; out
; al status
source_compare_divuw:
cmp source_character_count, 5
jb source_compare_divuw_failure
mov rax, source_character_address
cmp byte ptr[rax], 100
jne source_compare_divuw_failure
cmp byte ptr[rax+1], 105
jne source_compare_divuw_failure
cmp byte ptr[rax+2], 118
jne source_compare_divuw_failure
cmp byte ptr[rax+3], 117
jne source_compare_divuw_failure
cmp byte ptr[rax+4], 119
jne source_compare_divuw_failure
cmp source_character_count, 5
je source_compare_divuw_success
cmp byte ptr[rax+5], 10
je source_compare_divuw_success
cmp byte ptr[rax+5], 32
je source_compare_divuw_success
cmp byte ptr[rax+5], 35
je source_compare_divuw_success
source_compare_divuw_failure:
mov al, 1
ret
source_compare_divuw_success:
xor al, al
ret


; out
; al status
source_compare_divw:
cmp source_character_count, 4
jb source_compare_divw_failure
mov rax, source_character_address
cmp byte ptr[rax], 100
jne source_compare_divw_failure
cmp byte ptr[rax+1], 105
jne source_compare_divw_failure
cmp byte ptr[rax+2], 118
jne source_compare_divw_failure
cmp byte ptr[rax+3], 119
jne source_compare_divw_failure
cmp source_character_count, 4
je source_compare_divw_success
cmp byte ptr[rax+4], 10
je source_compare_divw_success
cmp byte ptr[rax+4], 32
je source_compare_divw_success
cmp byte ptr[rax+4], 35
je source_compare_divw_success
source_compare_divw_failure:
mov al, 1
ret
source_compare_divw_success:
xor al, al
ret


; out
; al status
source_compare_doubleword:
cmp source_character_count, 10
jb source_compare_doubleword_failure
mov rax, source_character_address
cmp byte ptr[rax], 100
jne source_compare_doubleword_failure
cmp byte ptr[rax+1], 111
jne source_compare_doubleword_failure
cmp byte ptr[rax+2], 117
jne source_compare_doubleword_failure
cmp byte ptr[rax+3], 98
jne source_compare_doubleword_failure
cmp byte ptr[rax+4], 108
jne source_compare_doubleword_failure
cmp byte ptr[rax+5], 101
jne source_compare_doubleword_failure
cmp byte ptr[rax+6], 119
jne source_compare_doubleword_failure
cmp byte ptr[rax+7], 111
jne source_compare_doubleword_failure
cmp byte ptr[rax+8], 114
jne source_compare_doubleword_failure
cmp byte ptr[rax+9], 100
jne source_compare_doubleword_failure
cmp source_character_count, 10
je source_compare_doubleword_success
cmp byte ptr[rax+10], 10
je source_compare_doubleword_success
cmp byte ptr[rax+10], 32
je source_compare_doubleword_success
cmp byte ptr[rax+10], 35
je source_compare_doubleword_success
source_compare_doubleword_failure:
mov al, 1
ret
source_compare_doubleword_success:
xor al, al
ret


; out
; al status
source_compare_ebreak:
cmp source_character_count, 6
jb source_compare_ebreak_failure
mov rax, source_character_address
cmp byte ptr[rax], 101
jne source_compare_ebreak_failure
cmp byte ptr[rax+1], 98
jne source_compare_ebreak_failure
cmp byte ptr[rax+2], 114
jne source_compare_ebreak_failure
cmp byte ptr[rax+3], 101
jne source_compare_ebreak_failure
cmp byte ptr[rax+4], 97
jne source_compare_ebreak_failure
cmp byte ptr[rax+5], 107
jne source_compare_ebreak_failure
cmp source_character_count, 6
je source_compare_ebreak_success
cmp byte ptr[rax+6], 10
je source_compare_ebreak_success
cmp byte ptr[rax+6], 32
je source_compare_ebreak_success
cmp byte ptr[rax+6], 35
je source_compare_ebreak_success
source_compare_ebreak_failure:
mov al, 1
ret
source_compare_ebreak_success:
xor al, al
ret


; out
; al status
source_compare_ecall:
cmp source_character_count, 5
jb source_compare_ecall_failure
mov rax, source_character_address
cmp byte ptr[rax], 101
jne source_compare_ecall_failure
cmp byte ptr[rax+1], 99
jne source_compare_ecall_failure
cmp byte ptr[rax+2], 97
jne source_compare_ecall_failure
cmp byte ptr[rax+3], 108
jne source_compare_ecall_failure
cmp byte ptr[rax+4], 108
jne source_compare_ecall_failure
cmp source_character_count, 5
je source_compare_ecall_success
cmp byte ptr[rax+5], 10
je source_compare_ecall_success
cmp byte ptr[rax+5], 32
je source_compare_ecall_success
cmp byte ptr[rax+5], 35
je source_compare_ecall_success
source_compare_ecall_failure:
mov al, 1
ret
source_compare_ecall_success:
xor al, al
ret


; out
; al status
source_compare_faddd:
cmp source_character_count, 5
jb source_compare_faddd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddd_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddd_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddd_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddd_failure
cmp byte ptr[rax+4], 100
jne source_compare_faddd_failure
cmp source_character_count, 5
je source_compare_faddd_success
cmp byte ptr[rax+5], 10
je source_compare_faddd_success
cmp byte ptr[rax+5], 32
je source_compare_faddd_success
cmp byte ptr[rax+5], 35
je source_compare_faddd_success
source_compare_faddd_failure:
mov al, 1
ret
source_compare_faddd_success:
xor al, al
ret


; out
; al status
source_compare_faddddyn:
cmp source_character_count, 8
jb source_compare_faddddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddddyn_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddddyn_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddddyn_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddddyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_faddddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_faddddyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_faddddyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_faddddyn_failure
cmp source_character_count, 8
je source_compare_faddddyn_success
cmp byte ptr[rax+8], 10
je source_compare_faddddyn_success
cmp byte ptr[rax+8], 32
je source_compare_faddddyn_success
cmp byte ptr[rax+8], 35
je source_compare_faddddyn_success
source_compare_faddddyn_failure:
mov al, 1
ret
source_compare_faddddyn_success:
xor al, al
ret


; out
; al status
source_compare_fadddrdn:
cmp source_character_count, 8
jb source_compare_fadddrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fadddrdn_failure
cmp byte ptr[rax+1], 97
jne source_compare_fadddrdn_failure
cmp byte ptr[rax+2], 100
jne source_compare_fadddrdn_failure
cmp byte ptr[rax+3], 100
jne source_compare_fadddrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fadddrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fadddrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fadddrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fadddrdn_failure
cmp source_character_count, 8
je source_compare_fadddrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fadddrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fadddrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fadddrdn_success
source_compare_fadddrdn_failure:
mov al, 1
ret
source_compare_fadddrdn_success:
xor al, al
ret


; out
; al status
source_compare_fadddrmm:
cmp source_character_count, 8
jb source_compare_fadddrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fadddrmm_failure
cmp byte ptr[rax+1], 97
jne source_compare_fadddrmm_failure
cmp byte ptr[rax+2], 100
jne source_compare_fadddrmm_failure
cmp byte ptr[rax+3], 100
jne source_compare_fadddrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fadddrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fadddrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fadddrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fadddrmm_failure
cmp source_character_count, 8
je source_compare_fadddrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fadddrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fadddrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fadddrmm_success
source_compare_fadddrmm_failure:
mov al, 1
ret
source_compare_fadddrmm_success:
xor al, al
ret


; out
; al status
source_compare_fadddrtz:
cmp source_character_count, 8
jb source_compare_fadddrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fadddrtz_failure
cmp byte ptr[rax+1], 97
jne source_compare_fadddrtz_failure
cmp byte ptr[rax+2], 100
jne source_compare_fadddrtz_failure
cmp byte ptr[rax+3], 100
jne source_compare_fadddrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fadddrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fadddrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fadddrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fadddrtz_failure
cmp source_character_count, 8
je source_compare_fadddrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fadddrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fadddrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fadddrtz_success
source_compare_fadddrtz_failure:
mov al, 1
ret
source_compare_fadddrtz_success:
xor al, al
ret


; out
; al status
source_compare_fadddrup:
cmp source_character_count, 8
jb source_compare_fadddrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fadddrup_failure
cmp byte ptr[rax+1], 97
jne source_compare_fadddrup_failure
cmp byte ptr[rax+2], 100
jne source_compare_fadddrup_failure
cmp byte ptr[rax+3], 100
jne source_compare_fadddrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fadddrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fadddrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fadddrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fadddrup_failure
cmp source_character_count, 8
je source_compare_fadddrup_success
cmp byte ptr[rax+8], 10
je source_compare_fadddrup_success
cmp byte ptr[rax+8], 32
je source_compare_fadddrup_success
cmp byte ptr[rax+8], 35
je source_compare_fadddrup_success
source_compare_fadddrup_failure:
mov al, 1
ret
source_compare_fadddrup_success:
xor al, al
ret


; out
; al status
source_compare_faddq:
cmp source_character_count, 5
jb source_compare_faddq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddq_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddq_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddq_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddq_failure
cmp byte ptr[rax+4], 113
jne source_compare_faddq_failure
cmp source_character_count, 5
je source_compare_faddq_success
cmp byte ptr[rax+5], 10
je source_compare_faddq_success
cmp byte ptr[rax+5], 32
je source_compare_faddq_success
cmp byte ptr[rax+5], 35
je source_compare_faddq_success
source_compare_faddq_failure:
mov al, 1
ret
source_compare_faddq_success:
xor al, al
ret


; out
; al status
source_compare_faddqdyn:
cmp source_character_count, 8
jb source_compare_faddqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddqdyn_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddqdyn_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddqdyn_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddqdyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_faddqdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_faddqdyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_faddqdyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_faddqdyn_failure
cmp source_character_count, 8
je source_compare_faddqdyn_success
cmp byte ptr[rax+8], 10
je source_compare_faddqdyn_success
cmp byte ptr[rax+8], 32
je source_compare_faddqdyn_success
cmp byte ptr[rax+8], 35
je source_compare_faddqdyn_success
source_compare_faddqdyn_failure:
mov al, 1
ret
source_compare_faddqdyn_success:
xor al, al
ret


; out
; al status
source_compare_faddqrdn:
cmp source_character_count, 8
jb source_compare_faddqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddqrdn_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddqrdn_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddqrdn_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddqrdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_faddqrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_faddqrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_faddqrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_faddqrdn_failure
cmp source_character_count, 8
je source_compare_faddqrdn_success
cmp byte ptr[rax+8], 10
je source_compare_faddqrdn_success
cmp byte ptr[rax+8], 32
je source_compare_faddqrdn_success
cmp byte ptr[rax+8], 35
je source_compare_faddqrdn_success
source_compare_faddqrdn_failure:
mov al, 1
ret
source_compare_faddqrdn_success:
xor al, al
ret


; out
; al status
source_compare_faddqrmm:
cmp source_character_count, 8
jb source_compare_faddqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddqrmm_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddqrmm_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddqrmm_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddqrmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_faddqrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_faddqrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_faddqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_faddqrmm_failure
cmp source_character_count, 8
je source_compare_faddqrmm_success
cmp byte ptr[rax+8], 10
je source_compare_faddqrmm_success
cmp byte ptr[rax+8], 32
je source_compare_faddqrmm_success
cmp byte ptr[rax+8], 35
je source_compare_faddqrmm_success
source_compare_faddqrmm_failure:
mov al, 1
ret
source_compare_faddqrmm_success:
xor al, al
ret


; out
; al status
source_compare_faddqrtz:
cmp source_character_count, 8
jb source_compare_faddqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddqrtz_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddqrtz_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddqrtz_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddqrtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_faddqrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_faddqrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_faddqrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_faddqrtz_failure
cmp source_character_count, 8
je source_compare_faddqrtz_success
cmp byte ptr[rax+8], 10
je source_compare_faddqrtz_success
cmp byte ptr[rax+8], 32
je source_compare_faddqrtz_success
cmp byte ptr[rax+8], 35
je source_compare_faddqrtz_success
source_compare_faddqrtz_failure:
mov al, 1
ret
source_compare_faddqrtz_success:
xor al, al
ret


; out
; al status
source_compare_faddqrup:
cmp source_character_count, 8
jb source_compare_faddqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddqrup_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddqrup_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddqrup_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddqrup_failure
cmp byte ptr[rax+4], 113
jne source_compare_faddqrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_faddqrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_faddqrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_faddqrup_failure
cmp source_character_count, 8
je source_compare_faddqrup_success
cmp byte ptr[rax+8], 10
je source_compare_faddqrup_success
cmp byte ptr[rax+8], 32
je source_compare_faddqrup_success
cmp byte ptr[rax+8], 35
je source_compare_faddqrup_success
source_compare_faddqrup_failure:
mov al, 1
ret
source_compare_faddqrup_success:
xor al, al
ret


; out
; al status
source_compare_fadds:
cmp source_character_count, 5
jb source_compare_fadds_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fadds_failure
cmp byte ptr[rax+1], 97
jne source_compare_fadds_failure
cmp byte ptr[rax+2], 100
jne source_compare_fadds_failure
cmp byte ptr[rax+3], 100
jne source_compare_fadds_failure
cmp byte ptr[rax+4], 115
jne source_compare_fadds_failure
cmp source_character_count, 5
je source_compare_fadds_success
cmp byte ptr[rax+5], 10
je source_compare_fadds_success
cmp byte ptr[rax+5], 32
je source_compare_fadds_success
cmp byte ptr[rax+5], 35
je source_compare_fadds_success
source_compare_fadds_failure:
mov al, 1
ret
source_compare_fadds_success:
xor al, al
ret


; out
; al status
source_compare_faddsdyn:
cmp source_character_count, 8
jb source_compare_faddsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddsdyn_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddsdyn_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddsdyn_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddsdyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_faddsdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_faddsdyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_faddsdyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_faddsdyn_failure
cmp source_character_count, 8
je source_compare_faddsdyn_success
cmp byte ptr[rax+8], 10
je source_compare_faddsdyn_success
cmp byte ptr[rax+8], 32
je source_compare_faddsdyn_success
cmp byte ptr[rax+8], 35
je source_compare_faddsdyn_success
source_compare_faddsdyn_failure:
mov al, 1
ret
source_compare_faddsdyn_success:
xor al, al
ret


; out
; al status
source_compare_faddsrdn:
cmp source_character_count, 8
jb source_compare_faddsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddsrdn_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddsrdn_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddsrdn_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddsrdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_faddsrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_faddsrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_faddsrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_faddsrdn_failure
cmp source_character_count, 8
je source_compare_faddsrdn_success
cmp byte ptr[rax+8], 10
je source_compare_faddsrdn_success
cmp byte ptr[rax+8], 32
je source_compare_faddsrdn_success
cmp byte ptr[rax+8], 35
je source_compare_faddsrdn_success
source_compare_faddsrdn_failure:
mov al, 1
ret
source_compare_faddsrdn_success:
xor al, al
ret


; out
; al status
source_compare_faddsrmm:
cmp source_character_count, 8
jb source_compare_faddsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddsrmm_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddsrmm_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddsrmm_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddsrmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_faddsrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_faddsrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_faddsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_faddsrmm_failure
cmp source_character_count, 8
je source_compare_faddsrmm_success
cmp byte ptr[rax+8], 10
je source_compare_faddsrmm_success
cmp byte ptr[rax+8], 32
je source_compare_faddsrmm_success
cmp byte ptr[rax+8], 35
je source_compare_faddsrmm_success
source_compare_faddsrmm_failure:
mov al, 1
ret
source_compare_faddsrmm_success:
xor al, al
ret


; out
; al status
source_compare_faddsrtz:
cmp source_character_count, 8
jb source_compare_faddsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddsrtz_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddsrtz_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddsrtz_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddsrtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_faddsrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_faddsrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_faddsrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_faddsrtz_failure
cmp source_character_count, 8
je source_compare_faddsrtz_success
cmp byte ptr[rax+8], 10
je source_compare_faddsrtz_success
cmp byte ptr[rax+8], 32
je source_compare_faddsrtz_success
cmp byte ptr[rax+8], 35
je source_compare_faddsrtz_success
source_compare_faddsrtz_failure:
mov al, 1
ret
source_compare_faddsrtz_success:
xor al, al
ret


; out
; al status
source_compare_faddsrup:
cmp source_character_count, 8
jb source_compare_faddsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_faddsrup_failure
cmp byte ptr[rax+1], 97
jne source_compare_faddsrup_failure
cmp byte ptr[rax+2], 100
jne source_compare_faddsrup_failure
cmp byte ptr[rax+3], 100
jne source_compare_faddsrup_failure
cmp byte ptr[rax+4], 115
jne source_compare_faddsrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_faddsrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_faddsrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_faddsrup_failure
cmp source_character_count, 8
je source_compare_faddsrup_success
cmp byte ptr[rax+8], 10
je source_compare_faddsrup_success
cmp byte ptr[rax+8], 32
je source_compare_faddsrup_success
cmp byte ptr[rax+8], 35
je source_compare_faddsrup_success
source_compare_faddsrup_failure:
mov al, 1
ret
source_compare_faddsrup_success:
xor al, al
ret


; out
; al status
source_compare_fclassd:
cmp source_character_count, 7
jb source_compare_fclassd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fclassd_failure
cmp byte ptr[rax+1], 99
jne source_compare_fclassd_failure
cmp byte ptr[rax+2], 108
jne source_compare_fclassd_failure
cmp byte ptr[rax+3], 97
jne source_compare_fclassd_failure
cmp byte ptr[rax+4], 115
jne source_compare_fclassd_failure
cmp byte ptr[rax+5], 115
jne source_compare_fclassd_failure
cmp byte ptr[rax+6], 100
jne source_compare_fclassd_failure
cmp source_character_count, 7
je source_compare_fclassd_success
cmp byte ptr[rax+7], 10
je source_compare_fclassd_success
cmp byte ptr[rax+7], 32
je source_compare_fclassd_success
cmp byte ptr[rax+7], 35
je source_compare_fclassd_success
source_compare_fclassd_failure:
mov al, 1
ret
source_compare_fclassd_success:
xor al, al
ret


; out
; al status
source_compare_fclassq:
cmp source_character_count, 7
jb source_compare_fclassq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fclassq_failure
cmp byte ptr[rax+1], 99
jne source_compare_fclassq_failure
cmp byte ptr[rax+2], 108
jne source_compare_fclassq_failure
cmp byte ptr[rax+3], 97
jne source_compare_fclassq_failure
cmp byte ptr[rax+4], 115
jne source_compare_fclassq_failure
cmp byte ptr[rax+5], 115
jne source_compare_fclassq_failure
cmp byte ptr[rax+6], 113
jne source_compare_fclassq_failure
cmp source_character_count, 7
je source_compare_fclassq_success
cmp byte ptr[rax+7], 10
je source_compare_fclassq_success
cmp byte ptr[rax+7], 32
je source_compare_fclassq_success
cmp byte ptr[rax+7], 35
je source_compare_fclassq_success
source_compare_fclassq_failure:
mov al, 1
ret
source_compare_fclassq_success:
xor al, al
ret


; out
; al status
source_compare_fclasss:
cmp source_character_count, 7
jb source_compare_fclasss_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fclasss_failure
cmp byte ptr[rax+1], 99
jne source_compare_fclasss_failure
cmp byte ptr[rax+2], 108
jne source_compare_fclasss_failure
cmp byte ptr[rax+3], 97
jne source_compare_fclasss_failure
cmp byte ptr[rax+4], 115
jne source_compare_fclasss_failure
cmp byte ptr[rax+5], 115
jne source_compare_fclasss_failure
cmp byte ptr[rax+6], 115
jne source_compare_fclasss_failure
cmp source_character_count, 7
je source_compare_fclasss_success
cmp byte ptr[rax+7], 10
je source_compare_fclasss_success
cmp byte ptr[rax+7], 32
je source_compare_fclasss_success
cmp byte ptr[rax+7], 35
je source_compare_fclasss_success
source_compare_fclasss_failure:
mov al, 1
ret
source_compare_fclasss_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdl:
cmp source_character_count, 6
jb source_compare_fcvtdl_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdl_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdl_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdl_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdl_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdl_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdl_failure
cmp source_character_count, 6
je source_compare_fcvtdl_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtdl_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtdl_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtdl_success
source_compare_fcvtdl_failure:
mov al, 1
ret
source_compare_fcvtdl_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdldyn:
cmp source_character_count, 9
jb source_compare_fcvtdldyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdldyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdldyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdldyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdldyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdldyn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdldyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtdldyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtdldyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtdldyn_failure
cmp source_character_count, 9
je source_compare_fcvtdldyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdldyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdldyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdldyn_success
source_compare_fcvtdldyn_failure:
mov al, 1
ret
source_compare_fcvtdldyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdlrdn:
cmp source_character_count, 9
jb source_compare_fcvtdlrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdlrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdlrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdlrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdlrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdlrdn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdlrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdlrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtdlrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtdlrdn_failure
cmp source_character_count, 9
je source_compare_fcvtdlrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdlrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdlrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdlrdn_success
source_compare_fcvtdlrdn_failure:
mov al, 1
ret
source_compare_fcvtdlrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdlrmm:
cmp source_character_count, 9
jb source_compare_fcvtdlrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdlrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdlrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdlrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdlrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdlrmm_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdlrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdlrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtdlrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtdlrmm_failure
cmp source_character_count, 9
je source_compare_fcvtdlrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdlrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdlrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdlrmm_success
source_compare_fcvtdlrmm_failure:
mov al, 1
ret
source_compare_fcvtdlrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdlrtz:
cmp source_character_count, 9
jb source_compare_fcvtdlrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdlrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdlrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdlrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdlrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdlrtz_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdlrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdlrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtdlrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtdlrtz_failure
cmp source_character_count, 9
je source_compare_fcvtdlrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdlrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdlrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdlrtz_success
source_compare_fcvtdlrtz_failure:
mov al, 1
ret
source_compare_fcvtdlrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdlrup:
cmp source_character_count, 9
jb source_compare_fcvtdlrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdlrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdlrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdlrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdlrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdlrup_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdlrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdlrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtdlrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtdlrup_failure
cmp source_character_count, 9
je source_compare_fcvtdlrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdlrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdlrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdlrup_success
source_compare_fcvtdlrup_failure:
mov al, 1
ret
source_compare_fcvtdlrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdlu:
cmp source_character_count, 7
jb source_compare_fcvtdlu_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdlu_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdlu_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdlu_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdlu_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdlu_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdlu_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdlu_failure
cmp source_character_count, 7
je source_compare_fcvtdlu_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtdlu_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtdlu_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtdlu_success
source_compare_fcvtdlu_failure:
mov al, 1
ret
source_compare_fcvtdlu_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdludyn:
cmp source_character_count, 10
jb source_compare_fcvtdludyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdludyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdludyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdludyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdludyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdludyn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdludyn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdludyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtdludyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtdludyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtdludyn_failure
cmp source_character_count, 10
je source_compare_fcvtdludyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdludyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdludyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdludyn_success
source_compare_fcvtdludyn_failure:
mov al, 1
ret
source_compare_fcvtdludyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdlurdn:
cmp source_character_count, 10
jb source_compare_fcvtdlurdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdlurdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdlurdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdlurdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdlurdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdlurdn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdlurdn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdlurdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtdlurdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtdlurdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtdlurdn_failure
cmp source_character_count, 10
je source_compare_fcvtdlurdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdlurdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdlurdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdlurdn_success
source_compare_fcvtdlurdn_failure:
mov al, 1
ret
source_compare_fcvtdlurdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdlurmm:
cmp source_character_count, 10
jb source_compare_fcvtdlurmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdlurmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdlurmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdlurmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdlurmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdlurmm_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdlurmm_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdlurmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtdlurmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtdlurmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtdlurmm_failure
cmp source_character_count, 10
je source_compare_fcvtdlurmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdlurmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdlurmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdlurmm_success
source_compare_fcvtdlurmm_failure:
mov al, 1
ret
source_compare_fcvtdlurmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdlurtz:
cmp source_character_count, 10
jb source_compare_fcvtdlurtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdlurtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdlurtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdlurtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdlurtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdlurtz_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdlurtz_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdlurtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtdlurtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtdlurtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtdlurtz_failure
cmp source_character_count, 10
je source_compare_fcvtdlurtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdlurtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdlurtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdlurtz_success
source_compare_fcvtdlurtz_failure:
mov al, 1
ret
source_compare_fcvtdlurtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdlurup:
cmp source_character_count, 10
jb source_compare_fcvtdlurup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdlurup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdlurup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdlurup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdlurup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdlurup_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtdlurup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdlurup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtdlurup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtdlurup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtdlurup_failure
cmp source_character_count, 10
je source_compare_fcvtdlurup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdlurup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdlurup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdlurup_success
source_compare_fcvtdlurup_failure:
mov al, 1
ret
source_compare_fcvtdlurup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdq:
cmp source_character_count, 6
jb source_compare_fcvtdq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdq_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdq_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdq_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdq_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdq_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtdq_failure
cmp source_character_count, 6
je source_compare_fcvtdq_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtdq_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtdq_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtdq_success
source_compare_fcvtdq_failure:
mov al, 1
ret
source_compare_fcvtdq_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdqdyn:
cmp source_character_count, 9
jb source_compare_fcvtdqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdqdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdqdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdqdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdqdyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdqdyn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtdqdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtdqdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtdqdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtdqdyn_failure
cmp source_character_count, 9
je source_compare_fcvtdqdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdqdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdqdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdqdyn_success
source_compare_fcvtdqdyn_failure:
mov al, 1
ret
source_compare_fcvtdqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdqrdn:
cmp source_character_count, 9
jb source_compare_fcvtdqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdqrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdqrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdqrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdqrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdqrdn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtdqrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdqrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtdqrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtdqrdn_failure
cmp source_character_count, 9
je source_compare_fcvtdqrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdqrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdqrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdqrdn_success
source_compare_fcvtdqrdn_failure:
mov al, 1
ret
source_compare_fcvtdqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdqrmm:
cmp source_character_count, 9
jb source_compare_fcvtdqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdqrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdqrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdqrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdqrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdqrmm_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtdqrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtdqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtdqrmm_failure
cmp source_character_count, 9
je source_compare_fcvtdqrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdqrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdqrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdqrmm_success
source_compare_fcvtdqrmm_failure:
mov al, 1
ret
source_compare_fcvtdqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdqrtz:
cmp source_character_count, 9
jb source_compare_fcvtdqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdqrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdqrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdqrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdqrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdqrtz_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtdqrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdqrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtdqrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtdqrtz_failure
cmp source_character_count, 9
je source_compare_fcvtdqrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdqrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdqrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdqrtz_success
source_compare_fcvtdqrtz_failure:
mov al, 1
ret
source_compare_fcvtdqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdqrup:
cmp source_character_count, 9
jb source_compare_fcvtdqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdqrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdqrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdqrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdqrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdqrup_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtdqrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdqrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtdqrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtdqrup_failure
cmp source_character_count, 9
je source_compare_fcvtdqrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdqrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdqrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdqrup_success
source_compare_fcvtdqrup_failure:
mov al, 1
ret
source_compare_fcvtdqrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtds:
cmp source_character_count, 6
jb source_compare_fcvtds_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtds_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtds_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtds_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtds_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtds_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtds_failure
cmp source_character_count, 6
je source_compare_fcvtds_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtds_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtds_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtds_success
source_compare_fcvtds_failure:
mov al, 1
ret
source_compare_fcvtds_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdsdyn:
cmp source_character_count, 9
jb source_compare_fcvtdsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdsdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdsdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdsdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdsdyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdsdyn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtdsdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtdsdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtdsdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtdsdyn_failure
cmp source_character_count, 9
je source_compare_fcvtdsdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdsdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdsdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdsdyn_success
source_compare_fcvtdsdyn_failure:
mov al, 1
ret
source_compare_fcvtdsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdsrdn:
cmp source_character_count, 9
jb source_compare_fcvtdsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdsrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdsrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdsrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdsrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdsrdn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtdsrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdsrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtdsrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtdsrdn_failure
cmp source_character_count, 9
je source_compare_fcvtdsrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdsrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdsrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdsrdn_success
source_compare_fcvtdsrdn_failure:
mov al, 1
ret
source_compare_fcvtdsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdsrmm:
cmp source_character_count, 9
jb source_compare_fcvtdsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdsrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdsrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdsrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdsrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdsrmm_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtdsrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtdsrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtdsrmm_failure
cmp source_character_count, 9
je source_compare_fcvtdsrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdsrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdsrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdsrmm_success
source_compare_fcvtdsrmm_failure:
mov al, 1
ret
source_compare_fcvtdsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdsrtz:
cmp source_character_count, 9
jb source_compare_fcvtdsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdsrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdsrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdsrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdsrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdsrtz_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtdsrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdsrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtdsrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtdsrtz_failure
cmp source_character_count, 9
je source_compare_fcvtdsrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdsrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdsrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdsrtz_success
source_compare_fcvtdsrtz_failure:
mov al, 1
ret
source_compare_fcvtdsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdsrup:
cmp source_character_count, 9
jb source_compare_fcvtdsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdsrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdsrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdsrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdsrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdsrup_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtdsrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdsrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtdsrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtdsrup_failure
cmp source_character_count, 9
je source_compare_fcvtdsrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdsrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdsrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdsrup_success
source_compare_fcvtdsrup_failure:
mov al, 1
ret
source_compare_fcvtdsrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdw:
cmp source_character_count, 6
jb source_compare_fcvtdw_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdw_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdw_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdw_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdw_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdw_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdw_failure
cmp source_character_count, 6
je source_compare_fcvtdw_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtdw_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtdw_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtdw_success
source_compare_fcvtdw_failure:
mov al, 1
ret
source_compare_fcvtdw_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwdyn:
cmp source_character_count, 9
jb source_compare_fcvtdwdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwdyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwdyn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtdwdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtdwdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtdwdyn_failure
cmp source_character_count, 9
je source_compare_fcvtdwdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdwdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdwdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdwdyn_success
source_compare_fcvtdwdyn_failure:
mov al, 1
ret
source_compare_fcvtdwdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwrdn:
cmp source_character_count, 9
jb source_compare_fcvtdwrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwrdn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdwrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtdwrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtdwrdn_failure
cmp source_character_count, 9
je source_compare_fcvtdwrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdwrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdwrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdwrdn_success
source_compare_fcvtdwrdn_failure:
mov al, 1
ret
source_compare_fcvtdwrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwrmm:
cmp source_character_count, 9
jb source_compare_fcvtdwrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwrmm_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdwrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtdwrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtdwrmm_failure
cmp source_character_count, 9
je source_compare_fcvtdwrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdwrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdwrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdwrmm_success
source_compare_fcvtdwrmm_failure:
mov al, 1
ret
source_compare_fcvtdwrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwrtz:
cmp source_character_count, 9
jb source_compare_fcvtdwrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwrtz_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdwrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtdwrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtdwrtz_failure
cmp source_character_count, 9
je source_compare_fcvtdwrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdwrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdwrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdwrtz_success
source_compare_fcvtdwrtz_failure:
mov al, 1
ret
source_compare_fcvtdwrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwrup:
cmp source_character_count, 9
jb source_compare_fcvtdwrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwrup_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtdwrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtdwrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtdwrup_failure
cmp source_character_count, 9
je source_compare_fcvtdwrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtdwrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtdwrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtdwrup_success
source_compare_fcvtdwrup_failure:
mov al, 1
ret
source_compare_fcvtdwrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwu:
cmp source_character_count, 7
jb source_compare_fcvtdwu_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwu_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwu_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwu_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwu_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwu_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwu_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdwu_failure
cmp source_character_count, 7
je source_compare_fcvtdwu_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtdwu_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtdwu_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtdwu_success
source_compare_fcvtdwu_failure:
mov al, 1
ret
source_compare_fcvtdwu_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwudyn:
cmp source_character_count, 10
jb source_compare_fcvtdwudyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwudyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwudyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwudyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwudyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwudyn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwudyn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdwudyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtdwudyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtdwudyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtdwudyn_failure
cmp source_character_count, 10
je source_compare_fcvtdwudyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdwudyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdwudyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdwudyn_success
source_compare_fcvtdwudyn_failure:
mov al, 1
ret
source_compare_fcvtdwudyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwurdn:
cmp source_character_count, 10
jb source_compare_fcvtdwurdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwurdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwurdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwurdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwurdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwurdn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwurdn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdwurdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtdwurdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtdwurdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtdwurdn_failure
cmp source_character_count, 10
je source_compare_fcvtdwurdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdwurdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdwurdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdwurdn_success
source_compare_fcvtdwurdn_failure:
mov al, 1
ret
source_compare_fcvtdwurdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwurmm:
cmp source_character_count, 10
jb source_compare_fcvtdwurmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwurmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwurmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwurmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwurmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwurmm_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwurmm_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdwurmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtdwurmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtdwurmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtdwurmm_failure
cmp source_character_count, 10
je source_compare_fcvtdwurmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdwurmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdwurmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdwurmm_success
source_compare_fcvtdwurmm_failure:
mov al, 1
ret
source_compare_fcvtdwurmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwurtz:
cmp source_character_count, 10
jb source_compare_fcvtdwurtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwurtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwurtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwurtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwurtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwurtz_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwurtz_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdwurtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtdwurtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtdwurtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtdwurtz_failure
cmp source_character_count, 10
je source_compare_fcvtdwurtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdwurtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdwurtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdwurtz_success
source_compare_fcvtdwurtz_failure:
mov al, 1
ret
source_compare_fcvtdwurtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtdwurup:
cmp source_character_count, 10
jb source_compare_fcvtdwurup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtdwurup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtdwurup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtdwurup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtdwurup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fcvtdwurup_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtdwurup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtdwurup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtdwurup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtdwurup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtdwurup_failure
cmp source_character_count, 10
je source_compare_fcvtdwurup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtdwurup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtdwurup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtdwurup_success
source_compare_fcvtdwurup_failure:
mov al, 1
ret
source_compare_fcvtdwurup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtld:
cmp source_character_count, 6
jb source_compare_fcvtld_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtld_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtld_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtld_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtld_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtld_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtld_failure
cmp source_character_count, 6
je source_compare_fcvtld_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtld_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtld_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtld_success
source_compare_fcvtld_failure:
mov al, 1
ret
source_compare_fcvtld_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlddyn:
cmp source_character_count, 9
jb source_compare_fcvtlddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlddyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlddyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlddyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlddyn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtlddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtlddyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtlddyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtlddyn_failure
cmp source_character_count, 9
je source_compare_fcvtlddyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlddyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlddyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlddyn_success
source_compare_fcvtlddyn_failure:
mov al, 1
ret
source_compare_fcvtlddyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtldrdn:
cmp source_character_count, 9
jb source_compare_fcvtldrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtldrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtldrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtldrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtldrdn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtldrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtldrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtldrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtldrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtldrdn_failure
cmp source_character_count, 9
je source_compare_fcvtldrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtldrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtldrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtldrdn_success
source_compare_fcvtldrdn_failure:
mov al, 1
ret
source_compare_fcvtldrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtldrmm:
cmp source_character_count, 9
jb source_compare_fcvtldrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtldrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtldrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtldrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtldrmm_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtldrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtldrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtldrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtldrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtldrmm_failure
cmp source_character_count, 9
je source_compare_fcvtldrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtldrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtldrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtldrmm_success
source_compare_fcvtldrmm_failure:
mov al, 1
ret
source_compare_fcvtldrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtldrtz:
cmp source_character_count, 9
jb source_compare_fcvtldrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtldrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtldrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtldrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtldrtz_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtldrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtldrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtldrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtldrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtldrtz_failure
cmp source_character_count, 9
je source_compare_fcvtldrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtldrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtldrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtldrtz_success
source_compare_fcvtldrtz_failure:
mov al, 1
ret
source_compare_fcvtldrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtldrup:
cmp source_character_count, 9
jb source_compare_fcvtldrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtldrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtldrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtldrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtldrup_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtldrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtldrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtldrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtldrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtldrup_failure
cmp source_character_count, 9
je source_compare_fcvtldrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtldrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtldrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtldrup_success
source_compare_fcvtldrup_failure:
mov al, 1
ret
source_compare_fcvtldrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlq:
cmp source_character_count, 6
jb source_compare_fcvtlq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlq_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlq_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlq_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlq_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlq_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtlq_failure
cmp source_character_count, 6
je source_compare_fcvtlq_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtlq_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtlq_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtlq_success
source_compare_fcvtlq_failure:
mov al, 1
ret
source_compare_fcvtlq_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlqdyn:
cmp source_character_count, 9
jb source_compare_fcvtlqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlqdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlqdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlqdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlqdyn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlqdyn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtlqdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtlqdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtlqdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtlqdyn_failure
cmp source_character_count, 9
je source_compare_fcvtlqdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlqdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlqdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlqdyn_success
source_compare_fcvtlqdyn_failure:
mov al, 1
ret
source_compare_fcvtlqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlqrdn:
cmp source_character_count, 9
jb source_compare_fcvtlqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlqrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlqrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlqrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlqrdn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlqrdn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtlqrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtlqrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtlqrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtlqrdn_failure
cmp source_character_count, 9
je source_compare_fcvtlqrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlqrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlqrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlqrdn_success
source_compare_fcvtlqrdn_failure:
mov al, 1
ret
source_compare_fcvtlqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlqrmm:
cmp source_character_count, 9
jb source_compare_fcvtlqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlqrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlqrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlqrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlqrmm_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlqrmm_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtlqrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtlqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtlqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtlqrmm_failure
cmp source_character_count, 9
je source_compare_fcvtlqrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlqrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlqrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlqrmm_success
source_compare_fcvtlqrmm_failure:
mov al, 1
ret
source_compare_fcvtlqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlqrtz:
cmp source_character_count, 9
jb source_compare_fcvtlqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlqrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlqrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlqrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlqrtz_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlqrtz_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtlqrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtlqrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtlqrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtlqrtz_failure
cmp source_character_count, 9
je source_compare_fcvtlqrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlqrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlqrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlqrtz_success
source_compare_fcvtlqrtz_failure:
mov al, 1
ret
source_compare_fcvtlqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlqrup:
cmp source_character_count, 9
jb source_compare_fcvtlqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlqrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlqrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlqrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlqrup_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlqrup_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtlqrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtlqrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtlqrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtlqrup_failure
cmp source_character_count, 9
je source_compare_fcvtlqrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlqrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlqrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlqrup_success
source_compare_fcvtlqrup_failure:
mov al, 1
ret
source_compare_fcvtlqrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtls:
cmp source_character_count, 6
jb source_compare_fcvtls_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtls_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtls_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtls_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtls_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtls_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtls_failure
cmp source_character_count, 6
je source_compare_fcvtls_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtls_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtls_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtls_success
source_compare_fcvtls_failure:
mov al, 1
ret
source_compare_fcvtls_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlsdyn:
cmp source_character_count, 9
jb source_compare_fcvtlsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlsdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlsdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlsdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlsdyn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlsdyn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtlsdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtlsdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtlsdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtlsdyn_failure
cmp source_character_count, 9
je source_compare_fcvtlsdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlsdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlsdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlsdyn_success
source_compare_fcvtlsdyn_failure:
mov al, 1
ret
source_compare_fcvtlsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlsrdn:
cmp source_character_count, 9
jb source_compare_fcvtlsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlsrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlsrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlsrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlsrdn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlsrdn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtlsrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtlsrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtlsrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtlsrdn_failure
cmp source_character_count, 9
je source_compare_fcvtlsrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlsrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlsrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlsrdn_success
source_compare_fcvtlsrdn_failure:
mov al, 1
ret
source_compare_fcvtlsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlsrmm:
cmp source_character_count, 9
jb source_compare_fcvtlsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlsrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlsrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlsrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlsrmm_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlsrmm_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtlsrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtlsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtlsrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtlsrmm_failure
cmp source_character_count, 9
je source_compare_fcvtlsrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlsrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlsrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlsrmm_success
source_compare_fcvtlsrmm_failure:
mov al, 1
ret
source_compare_fcvtlsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlsrtz:
cmp source_character_count, 9
jb source_compare_fcvtlsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlsrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlsrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlsrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlsrtz_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlsrtz_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtlsrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtlsrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtlsrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtlsrtz_failure
cmp source_character_count, 9
je source_compare_fcvtlsrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlsrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlsrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlsrtz_success
source_compare_fcvtlsrtz_failure:
mov al, 1
ret
source_compare_fcvtlsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlsrup:
cmp source_character_count, 9
jb source_compare_fcvtlsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlsrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlsrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlsrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlsrup_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlsrup_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtlsrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtlsrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtlsrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtlsrup_failure
cmp source_character_count, 9
je source_compare_fcvtlsrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtlsrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtlsrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtlsrup_success
source_compare_fcvtlsrup_failure:
mov al, 1
ret
source_compare_fcvtlsrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlud:
cmp source_character_count, 7
jb source_compare_fcvtlud_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlud_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlud_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlud_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlud_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlud_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtlud_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtlud_failure
cmp source_character_count, 7
je source_compare_fcvtlud_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtlud_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtlud_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtlud_success
source_compare_fcvtlud_failure:
mov al, 1
ret
source_compare_fcvtlud_success:
xor al, al
ret


; out
; al status
source_compare_fcvtluddyn:
cmp source_character_count, 10
jb source_compare_fcvtluddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtluddyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtluddyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtluddyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtluddyn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtluddyn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtluddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtluddyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtluddyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtluddyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtluddyn_failure
cmp source_character_count, 10
je source_compare_fcvtluddyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtluddyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtluddyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtluddyn_success
source_compare_fcvtluddyn_failure:
mov al, 1
ret
source_compare_fcvtluddyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtludrdn:
cmp source_character_count, 10
jb source_compare_fcvtludrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtludrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtludrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtludrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtludrdn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtludrdn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtludrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtludrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtludrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtludrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtludrdn_failure
cmp source_character_count, 10
je source_compare_fcvtludrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtludrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtludrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtludrdn_success
source_compare_fcvtludrdn_failure:
mov al, 1
ret
source_compare_fcvtludrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtludrmm:
cmp source_character_count, 10
jb source_compare_fcvtludrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtludrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtludrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtludrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtludrmm_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtludrmm_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtludrmm_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtludrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtludrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtludrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtludrmm_failure
cmp source_character_count, 10
je source_compare_fcvtludrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtludrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtludrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtludrmm_success
source_compare_fcvtludrmm_failure:
mov al, 1
ret
source_compare_fcvtludrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtludrtz:
cmp source_character_count, 10
jb source_compare_fcvtludrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtludrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtludrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtludrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtludrtz_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtludrtz_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtludrtz_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtludrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtludrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtludrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtludrtz_failure
cmp source_character_count, 10
je source_compare_fcvtludrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtludrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtludrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtludrtz_success
source_compare_fcvtludrtz_failure:
mov al, 1
ret
source_compare_fcvtludrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtludrup:
cmp source_character_count, 10
jb source_compare_fcvtludrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtludrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtludrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtludrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtludrup_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtludrup_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtludrup_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtludrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtludrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtludrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtludrup_failure
cmp source_character_count, 10
je source_compare_fcvtludrup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtludrup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtludrup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtludrup_success
source_compare_fcvtludrup_failure:
mov al, 1
ret
source_compare_fcvtludrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtluq:
cmp source_character_count, 7
jb source_compare_fcvtluq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtluq_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtluq_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtluq_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtluq_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtluq_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtluq_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtluq_failure
cmp source_character_count, 7
je source_compare_fcvtluq_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtluq_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtluq_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtluq_success
source_compare_fcvtluq_failure:
mov al, 1
ret
source_compare_fcvtluq_success:
xor al, al
ret


; out
; al status
source_compare_fcvtluqdyn:
cmp source_character_count, 10
jb source_compare_fcvtluqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtluqdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtluqdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtluqdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtluqdyn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtluqdyn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtluqdyn_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtluqdyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtluqdyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtluqdyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtluqdyn_failure
cmp source_character_count, 10
je source_compare_fcvtluqdyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtluqdyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtluqdyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtluqdyn_success
source_compare_fcvtluqdyn_failure:
mov al, 1
ret
source_compare_fcvtluqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtluqrdn:
cmp source_character_count, 10
jb source_compare_fcvtluqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtluqrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtluqrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtluqrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtluqrdn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtluqrdn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtluqrdn_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtluqrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtluqrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtluqrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtluqrdn_failure
cmp source_character_count, 10
je source_compare_fcvtluqrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtluqrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtluqrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtluqrdn_success
source_compare_fcvtluqrdn_failure:
mov al, 1
ret
source_compare_fcvtluqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtluqrmm:
cmp source_character_count, 10
jb source_compare_fcvtluqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtluqrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtluqrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtluqrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtluqrmm_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtluqrmm_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtluqrmm_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtluqrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtluqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtluqrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtluqrmm_failure
cmp source_character_count, 10
je source_compare_fcvtluqrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtluqrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtluqrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtluqrmm_success
source_compare_fcvtluqrmm_failure:
mov al, 1
ret
source_compare_fcvtluqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtluqrtz:
cmp source_character_count, 10
jb source_compare_fcvtluqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtluqrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtluqrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtluqrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtluqrtz_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtluqrtz_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtluqrtz_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtluqrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtluqrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtluqrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtluqrtz_failure
cmp source_character_count, 10
je source_compare_fcvtluqrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtluqrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtluqrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtluqrtz_success
source_compare_fcvtluqrtz_failure:
mov al, 1
ret
source_compare_fcvtluqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtluqrup:
cmp source_character_count, 10
jb source_compare_fcvtluqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtluqrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtluqrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtluqrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtluqrup_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtluqrup_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtluqrup_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtluqrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtluqrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtluqrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtluqrup_failure
cmp source_character_count, 10
je source_compare_fcvtluqrup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtluqrup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtluqrup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtluqrup_success
source_compare_fcvtluqrup_failure:
mov al, 1
ret
source_compare_fcvtluqrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlus:
cmp source_character_count, 7
jb source_compare_fcvtlus_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlus_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlus_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlus_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlus_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlus_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtlus_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtlus_failure
cmp source_character_count, 7
je source_compare_fcvtlus_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtlus_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtlus_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtlus_success
source_compare_fcvtlus_failure:
mov al, 1
ret
source_compare_fcvtlus_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlusdyn:
cmp source_character_count, 10
jb source_compare_fcvtlusdyn_failure
cmp byte ptr[rax], 102
jne source_compare_fcvtlusdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlusdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlusdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlusdyn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlusdyn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtlusdyn_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtlusdyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtlusdyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtlusdyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtlusdyn_failure
cmp source_character_count, 10
je source_compare_fcvtlusdyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtlusdyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtlusdyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtlusdyn_success
source_compare_fcvtlusdyn_failure:
mov al, 1
ret
source_compare_fcvtlusdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlusrdn:
cmp source_character_count, 10
jb source_compare_fcvtlusrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlusrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlusrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlusrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlusrdn_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlusrdn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtlusrdn_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtlusrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtlusrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtlusrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtlusrdn_failure
cmp source_character_count, 10
je source_compare_fcvtlusrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtlusrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtlusrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtlusrdn_success
source_compare_fcvtlusrdn_failure:
mov al, 1
ret
source_compare_fcvtlusrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlusrmm:
cmp source_character_count, 10
jb source_compare_fcvtlusrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlusrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlusrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlusrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlusrmm_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlusrmm_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtlusrmm_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtlusrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtlusrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtlusrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtlusrmm_failure
cmp source_character_count, 10
je source_compare_fcvtlusrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtlusrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtlusrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtlusrmm_success
source_compare_fcvtlusrmm_failure:
mov al, 1
ret
source_compare_fcvtlusrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlusrtz:
cmp source_character_count, 10
jb source_compare_fcvtlusrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlusrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlusrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlusrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlusrtz_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlusrtz_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtlusrtz_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtlusrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtlusrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtlusrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtlusrtz_failure
cmp source_character_count, 10
je source_compare_fcvtlusrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtlusrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtlusrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtlusrtz_success
source_compare_fcvtlusrtz_failure:
mov al, 1
ret
source_compare_fcvtlusrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtlusrup:
cmp source_character_count, 10
jb source_compare_fcvtlusrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtlusrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtlusrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtlusrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtlusrup_failure
cmp byte ptr[rax+4], 108
jne source_compare_fcvtlusrup_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtlusrup_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtlusrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtlusrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtlusrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtlusrup_failure
cmp source_character_count, 10
je source_compare_fcvtlusrup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtlusrup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtlusrup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtlusrup_success
source_compare_fcvtlusrup_failure:
mov al, 1
ret
source_compare_fcvtlusrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqd:
cmp source_character_count, 6
jb source_compare_fcvtqd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqd_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqd_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqd_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqd_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqd_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtqd_failure
cmp source_character_count, 6
je source_compare_fcvtqd_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtqd_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtqd_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtqd_success
source_compare_fcvtqd_failure:
mov al, 1
ret
source_compare_fcvtqd_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqddyn:
cmp source_character_count, 9
jb source_compare_fcvtqddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqddyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqddyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqddyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqddyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtqddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtqddyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtqddyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtqddyn_failure
cmp source_character_count, 9
je source_compare_fcvtqddyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqddyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqddyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqddyn_success
source_compare_fcvtqddyn_failure:
mov al, 1
ret
source_compare_fcvtqddyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqdrdn:
cmp source_character_count, 9
jb source_compare_fcvtqdrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqdrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqdrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqdrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqdrdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqdrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtqdrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqdrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtqdrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtqdrdn_failure
cmp source_character_count, 9
je source_compare_fcvtqdrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqdrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqdrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqdrdn_success
source_compare_fcvtqdrdn_failure:
mov al, 1
ret
source_compare_fcvtqdrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqdrmm:
cmp source_character_count, 9
jb source_compare_fcvtqdrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqdrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqdrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqdrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqdrmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqdrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtqdrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqdrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtqdrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtqdrmm_failure
cmp source_character_count, 9
je source_compare_fcvtqdrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqdrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqdrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqdrmm_success
source_compare_fcvtqdrmm_failure:
mov al, 1
ret
source_compare_fcvtqdrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqdrtz:
cmp source_character_count, 9
jb source_compare_fcvtqdrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqdrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqdrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqdrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqdrtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqdrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtqdrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqdrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtqdrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtqdrtz_failure
cmp source_character_count, 9
je source_compare_fcvtqdrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqdrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqdrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqdrtz_success
source_compare_fcvtqdrtz_failure:
mov al, 1
ret
source_compare_fcvtqdrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqdrup:
cmp source_character_count, 9
jb source_compare_fcvtqdrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqdrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqdrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqdrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqdrup_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqdrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtqdrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqdrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtqdrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtqdrup_failure
cmp source_character_count, 9
je source_compare_fcvtqdrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqdrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqdrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqdrup_success
source_compare_fcvtqdrup_failure:
mov al, 1
ret
source_compare_fcvtqdrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtql:
cmp source_character_count, 6
jb source_compare_fcvtql_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtql_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtql_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtql_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtql_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtql_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtql_failure
cmp source_character_count, 6
je source_compare_fcvtql_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtql_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtql_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtql_success
source_compare_fcvtql_failure:
mov al, 1
ret
source_compare_fcvtql_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqldyn:
cmp source_character_count, 9
jb source_compare_fcvtqldyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqldyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqldyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqldyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqldyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqldyn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqldyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtqldyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtqldyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtqldyn_failure
cmp source_character_count, 9
je source_compare_fcvtqldyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqldyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqldyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqldyn_success
source_compare_fcvtqldyn_failure:
mov al, 1
ret
source_compare_fcvtqldyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqlrdn:
cmp source_character_count, 9
jb source_compare_fcvtqlrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqlrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqlrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqlrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqlrdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqlrdn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqlrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqlrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtqlrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtqlrdn_failure
cmp source_character_count, 9
je source_compare_fcvtqlrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqlrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqlrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqlrdn_success
source_compare_fcvtqlrdn_failure:
mov al, 1
ret
source_compare_fcvtqlrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqlrmm:
cmp source_character_count, 9
jb source_compare_fcvtqlrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqlrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqlrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqlrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqlrmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqlrmm_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqlrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqlrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtqlrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtqlrmm_failure
cmp source_character_count, 9
je source_compare_fcvtqlrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqlrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqlrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqlrmm_success
source_compare_fcvtqlrmm_failure:
mov al, 1
ret
source_compare_fcvtqlrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqlrtz:
cmp source_character_count, 9
jb source_compare_fcvtqlrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqlrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqlrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqlrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqlrtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqlrtz_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqlrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqlrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtqlrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtqlrtz_failure
cmp source_character_count, 9
je source_compare_fcvtqlrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqlrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqlrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqlrtz_success
source_compare_fcvtqlrtz_failure:
mov al, 1
ret
source_compare_fcvtqlrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqlrup:
cmp source_character_count, 9
jb source_compare_fcvtqlrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqlrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqlrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqlrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqlrup_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqlrup_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqlrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqlrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtqlrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtqlrup_failure
cmp source_character_count, 9
je source_compare_fcvtqlrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqlrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqlrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqlrup_success
source_compare_fcvtqlrup_failure:
mov al, 1
ret
source_compare_fcvtqlrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqlu:
cmp source_character_count, 7
jb source_compare_fcvtqlu_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqlu_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqlu_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqlu_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqlu_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqlu_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqlu_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqlu_failure
cmp source_character_count, 7
je source_compare_fcvtqlu_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtqlu_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtqlu_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtqlu_success
source_compare_fcvtqlu_failure:
mov al, 1
ret
source_compare_fcvtqlu_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqludyn:
cmp source_character_count, 10
jb source_compare_fcvtqludyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqludyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqludyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqludyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqludyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqludyn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqludyn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqludyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtqludyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtqludyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtqludyn_failure
cmp source_character_count, 10
je source_compare_fcvtqludyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqludyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqludyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqludyn_success
source_compare_fcvtqludyn_failure:
mov al, 1
ret
source_compare_fcvtqludyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqlurdn:
cmp source_character_count, 10
jb source_compare_fcvtqlurdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqlurdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqlurdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqlurdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqlurdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqlurdn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqlurdn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqlurdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtqlurdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtqlurdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtqlurdn_failure
cmp source_character_count, 10
je source_compare_fcvtqlurdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqlurdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqlurdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqlurdn_success
source_compare_fcvtqlurdn_failure:
mov al, 1
ret
source_compare_fcvtqlurdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqlurmm:
cmp source_character_count, 10
jb source_compare_fcvtqlurmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqlurmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqlurmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqlurmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqlurmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqlurmm_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqlurmm_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqlurmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtqlurmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtqlurmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtqlurmm_failure
cmp source_character_count, 10
je source_compare_fcvtqlurmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqlurmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqlurmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqlurmm_success
source_compare_fcvtqlurmm_failure:
mov al, 1
ret
source_compare_fcvtqlurmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqlurtz:
cmp source_character_count, 10
jb source_compare_fcvtqlurtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqlurtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqlurtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqlurtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqlurtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqlurtz_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqlurtz_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqlurtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtqlurtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtqlurtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtqlurtz_failure
cmp source_character_count, 10
je source_compare_fcvtqlurtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqlurtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqlurtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqlurtz_success
source_compare_fcvtqlurtz_failure:
mov al, 1
ret
source_compare_fcvtqlurtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqlurup:
cmp source_character_count, 10
jb source_compare_fcvtqlurup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqlurup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqlurup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqlurup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqlurup_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqlurup_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtqlurup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqlurup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtqlurup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtqlurup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtqlurup_failure
cmp source_character_count, 10
je source_compare_fcvtqlurup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqlurup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqlurup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqlurup_success
source_compare_fcvtqlurup_failure:
mov al, 1
ret
source_compare_fcvtqlurup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqs:
cmp source_character_count, 6
jb source_compare_fcvtqs_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqs_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqs_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqs_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqs_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqs_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtqs_failure
cmp source_character_count, 6
je source_compare_fcvtqs_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtqs_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtqs_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtqs_success
source_compare_fcvtqs_failure:
mov al, 1
ret
source_compare_fcvtqs_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqsdyn:
cmp source_character_count, 9
jb source_compare_fcvtqsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqsdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqsdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqsdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqsdyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqsdyn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtqsdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtqsdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtqsdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtqsdyn_failure
cmp source_character_count, 9
je source_compare_fcvtqsdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqsdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqsdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqsdyn_success
source_compare_fcvtqsdyn_failure:
mov al, 1
ret
source_compare_fcvtqsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqsrdn:
cmp source_character_count, 9
jb source_compare_fcvtqsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqsrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqsrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqsrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqsrdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqsrdn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtqsrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqsrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtqsrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtqsrdn_failure
cmp source_character_count, 9
je source_compare_fcvtqsrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqsrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqsrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqsrdn_success
source_compare_fcvtqsrdn_failure:
mov al, 1
ret
source_compare_fcvtqsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqsrmm:
cmp source_character_count, 9
jb source_compare_fcvtqsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqsrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqsrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqsrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqsrmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqsrmm_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtqsrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtqsrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtqsrmm_failure
cmp source_character_count, 9
je source_compare_fcvtqsrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqsrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqsrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqsrmm_success
source_compare_fcvtqsrmm_failure:
mov al, 1
ret
source_compare_fcvtqsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqsrtz:
cmp source_character_count, 9
jb source_compare_fcvtqsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqsrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqsrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqsrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqsrtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqsrtz_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtqsrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqsrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtqsrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtqsrtz_failure
cmp source_character_count, 9
je source_compare_fcvtqsrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqsrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqsrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqsrtz_success
source_compare_fcvtqsrtz_failure:
mov al, 1
ret
source_compare_fcvtqsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqsrup:
cmp source_character_count, 9
jb source_compare_fcvtqsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqsrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqsrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqsrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqsrup_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqsrup_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtqsrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqsrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtqsrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtqsrup_failure
cmp source_character_count, 9
je source_compare_fcvtqsrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqsrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqsrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqsrup_success
source_compare_fcvtqsrup_failure:
mov al, 1
ret
source_compare_fcvtqsrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqw:
cmp source_character_count, 6
jb source_compare_fcvtqw_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqw_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqw_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqw_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqw_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqw_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqw_failure
cmp source_character_count, 6
je source_compare_fcvtqw_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtqw_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtqw_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtqw_success
source_compare_fcvtqw_failure:
mov al, 1
ret
source_compare_fcvtqw_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwdyn:
cmp source_character_count, 9
jb source_compare_fcvtqwdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwdyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwdyn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtqwdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtqwdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtqwdyn_failure
cmp source_character_count, 9
je source_compare_fcvtqwdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqwdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqwdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqwdyn_success
source_compare_fcvtqwdyn_failure:
mov al, 1
ret
source_compare_fcvtqwdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwrdn:
cmp source_character_count, 9
jb source_compare_fcvtqwrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwrdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwrdn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqwrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtqwrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtqwrdn_failure
cmp source_character_count, 9
je source_compare_fcvtqwrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqwrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqwrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqwrdn_success
source_compare_fcvtqwrdn_failure:
mov al, 1
ret
source_compare_fcvtqwrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwrmm:
cmp source_character_count, 9
jb source_compare_fcvtqwrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwrmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwrmm_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqwrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtqwrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtqwrmm_failure
cmp source_character_count, 9
je source_compare_fcvtqwrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqwrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqwrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqwrmm_success
source_compare_fcvtqwrmm_failure:
mov al, 1
ret
source_compare_fcvtqwrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwrtz:
cmp source_character_count, 9
jb source_compare_fcvtqwrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwrtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwrtz_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqwrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtqwrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtqwrtz_failure
cmp source_character_count, 9
je source_compare_fcvtqwrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqwrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqwrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqwrtz_success
source_compare_fcvtqwrtz_failure:
mov al, 1
ret
source_compare_fcvtqwrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwrup:
cmp source_character_count, 9
jb source_compare_fcvtqwrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwrup_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwrup_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtqwrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtqwrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtqwrup_failure
cmp source_character_count, 9
je source_compare_fcvtqwrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtqwrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtqwrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtqwrup_success
source_compare_fcvtqwrup_failure:
mov al, 1
ret
source_compare_fcvtqwrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwu:
cmp source_character_count, 7
jb source_compare_fcvtqwu_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwu_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwu_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwu_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwu_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwu_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwu_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqwu_failure
cmp source_character_count, 7
je source_compare_fcvtqwu_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtqwu_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtqwu_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtqwu_success
source_compare_fcvtqwu_failure:
mov al, 1
ret
source_compare_fcvtqwu_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwudyn:
cmp source_character_count, 10
jb source_compare_fcvtqwudyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwudyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwudyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwudyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwudyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwudyn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwudyn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqwudyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtqwudyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtqwudyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtqwudyn_failure
cmp source_character_count, 10
je source_compare_fcvtqwudyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqwudyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqwudyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqwudyn_success
source_compare_fcvtqwudyn_failure:
mov al, 1
ret
source_compare_fcvtqwudyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwurdn:
cmp source_character_count, 10
jb source_compare_fcvtqwurdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwurdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwurdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwurdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwurdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwurdn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwurdn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqwurdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtqwurdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtqwurdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtqwurdn_failure
cmp source_character_count, 10
je source_compare_fcvtqwurdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqwurdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqwurdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqwurdn_success
source_compare_fcvtqwurdn_failure:
mov al, 1
ret
source_compare_fcvtqwurdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwurmm:
cmp source_character_count, 10
jb source_compare_fcvtqwurmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwurmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwurmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwurmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwurmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwurmm_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwurmm_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqwurmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtqwurmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtqwurmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtqwurmm_failure
cmp source_character_count, 10
je source_compare_fcvtqwurmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqwurmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqwurmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqwurmm_success
source_compare_fcvtqwurmm_failure:
mov al, 1
ret
source_compare_fcvtqwurmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwurtz:
cmp source_character_count, 10
jb source_compare_fcvtqwurtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwurtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwurtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwurtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwurtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwurtz_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwurtz_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqwurtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtqwurtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtqwurtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtqwurtz_failure
cmp source_character_count, 10
je source_compare_fcvtqwurtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqwurtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqwurtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqwurtz_success
source_compare_fcvtqwurtz_failure:
mov al, 1
ret
source_compare_fcvtqwurtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtqwurup:
cmp source_character_count, 10
jb source_compare_fcvtqwurup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtqwurup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtqwurup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtqwurup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtqwurup_failure
cmp byte ptr[rax+4], 113
jne source_compare_fcvtqwurup_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtqwurup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtqwurup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtqwurup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtqwurup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtqwurup_failure
cmp source_character_count, 10
je source_compare_fcvtqwurup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtqwurup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtqwurup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtqwurup_success
source_compare_fcvtqwurup_failure:
mov al, 1
ret
source_compare_fcvtqwurup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsd:
cmp source_character_count, 6
jb source_compare_fcvtsd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsd_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsd_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsd_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsd_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsd_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtsd_failure
cmp source_character_count, 6
je source_compare_fcvtsd_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtsd_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtsd_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtsd_success
source_compare_fcvtsd_failure:
mov al, 1
ret
source_compare_fcvtsd_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsddyn:
cmp source_character_count, 9
jb source_compare_fcvtsddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsddyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsddyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsddyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsddyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtsddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtsddyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtsddyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtsddyn_failure
cmp source_character_count, 9
je source_compare_fcvtsddyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsddyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsddyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsddyn_success
source_compare_fcvtsddyn_failure:
mov al, 1
ret
source_compare_fcvtsddyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsdrdn:
cmp source_character_count, 9
jb source_compare_fcvtsdrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsdrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsdrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsdrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsdrdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsdrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtsdrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtsdrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtsdrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtsdrdn_failure
cmp source_character_count, 9
je source_compare_fcvtsdrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsdrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsdrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsdrdn_success
source_compare_fcvtsdrdn_failure:
mov al, 1
ret
source_compare_fcvtsdrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsdrmm:
cmp source_character_count, 9
jb source_compare_fcvtsdrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsdrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsdrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsdrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsdrmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsdrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtsdrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtsdrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtsdrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtsdrmm_failure
cmp source_character_count, 9
je source_compare_fcvtsdrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsdrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsdrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsdrmm_success
source_compare_fcvtsdrmm_failure:
mov al, 1
ret
source_compare_fcvtsdrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsdrtz:
cmp source_character_count, 9
jb source_compare_fcvtsdrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsdrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsdrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsdrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsdrtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsdrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtsdrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtsdrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtsdrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtsdrtz_failure
cmp source_character_count, 9
je source_compare_fcvtsdrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsdrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsdrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsdrtz_success
source_compare_fcvtsdrtz_failure:
mov al, 1
ret
source_compare_fcvtsdrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsdrup:
cmp source_character_count, 9
jb source_compare_fcvtsdrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsdrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsdrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsdrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsdrup_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsdrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtsdrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtsdrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtsdrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtsdrup_failure
cmp source_character_count, 9
je source_compare_fcvtsdrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsdrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsdrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsdrup_success
source_compare_fcvtsdrup_failure:
mov al, 1
ret
source_compare_fcvtsdrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsl:
cmp source_character_count, 6
jb source_compare_fcvtsl_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsl_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsl_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsl_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsl_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsl_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtsl_failure
cmp source_character_count, 6
je source_compare_fcvtsl_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtsl_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtsl_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtsl_success
source_compare_fcvtsl_failure:
mov al, 1
ret
source_compare_fcvtsl_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsldyn:
cmp source_character_count, 9
jb source_compare_fcvtsldyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsldyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsldyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsldyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsldyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsldyn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtsldyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtsldyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtsldyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtsldyn_failure
cmp source_character_count, 9
je source_compare_fcvtsldyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsldyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsldyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsldyn_success
source_compare_fcvtsldyn_failure:
mov al, 1
ret
source_compare_fcvtsldyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtslrdn:
cmp source_character_count, 9
jb source_compare_fcvtslrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtslrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtslrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtslrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtslrdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtslrdn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtslrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtslrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtslrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtslrdn_failure
cmp source_character_count, 9
je source_compare_fcvtslrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtslrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtslrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtslrdn_success
source_compare_fcvtslrdn_failure:
mov al, 1
ret
source_compare_fcvtslrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtslrmm:
cmp source_character_count, 9
jb source_compare_fcvtslrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtslrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtslrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtslrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtslrmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtslrmm_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtslrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtslrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtslrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtslrmm_failure
cmp source_character_count, 9
je source_compare_fcvtslrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtslrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtslrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtslrmm_success
source_compare_fcvtslrmm_failure:
mov al, 1
ret
source_compare_fcvtslrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtslrtz:
cmp source_character_count, 9
jb source_compare_fcvtslrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtslrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtslrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtslrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtslrtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtslrtz_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtslrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtslrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtslrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtslrtz_failure
cmp source_character_count, 9
je source_compare_fcvtslrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtslrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtslrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtslrtz_success
source_compare_fcvtslrtz_failure:
mov al, 1
ret
source_compare_fcvtslrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtslrup:
cmp source_character_count, 9
jb source_compare_fcvtslrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtslrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtslrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtslrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtslrup_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtslrup_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtslrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtslrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtslrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtslrup_failure
cmp source_character_count, 9
je source_compare_fcvtslrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtslrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtslrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtslrup_success
source_compare_fcvtslrup_failure:
mov al, 1
ret
source_compare_fcvtslrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtslu:
cmp source_character_count, 7
jb source_compare_fcvtslu_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtslu_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtslu_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtslu_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtslu_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtslu_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtslu_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtslu_failure
cmp source_character_count, 7
je source_compare_fcvtslu_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtslu_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtslu_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtslu_success
source_compare_fcvtslu_failure:
mov al, 1
ret
source_compare_fcvtslu_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsludyn:
cmp source_character_count, 10
jb source_compare_fcvtsludyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsludyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsludyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsludyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsludyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsludyn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtsludyn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtsludyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtsludyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtsludyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtsludyn_failure
cmp source_character_count, 10
je source_compare_fcvtsludyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtsludyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtsludyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtsludyn_success
source_compare_fcvtsludyn_failure:
mov al, 1
ret
source_compare_fcvtsludyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtslurdn:
cmp source_character_count, 10
jb source_compare_fcvtslurdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtslurdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtslurdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtslurdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtslurdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtslurdn_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtslurdn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtslurdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtslurdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtslurdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtslurdn_failure
cmp source_character_count, 10
je source_compare_fcvtslurdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtslurdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtslurdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtslurdn_success
source_compare_fcvtslurdn_failure:
mov al, 1
ret
source_compare_fcvtslurdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtslurmm:
cmp source_character_count, 10
jb source_compare_fcvtslurmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtslurmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtslurmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtslurmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtslurmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtslurmm_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtslurmm_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtslurmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtslurmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtslurmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtslurmm_failure
cmp source_character_count, 10
je source_compare_fcvtslurmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtslurmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtslurmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtslurmm_success
source_compare_fcvtslurmm_failure:
mov al, 1
ret
source_compare_fcvtslurmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtslurtz:
cmp source_character_count, 10
jb source_compare_fcvtslurtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtslurtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtslurtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtslurtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtslurtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtslurtz_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtslurtz_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtslurtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtslurtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtslurtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtslurtz_failure
cmp source_character_count, 10
je source_compare_fcvtslurtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtslurtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtslurtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtslurtz_success
source_compare_fcvtslurtz_failure:
mov al, 1
ret
source_compare_fcvtslurtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtslurup:
cmp source_character_count, 10
jb source_compare_fcvtslurup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtslurup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtslurup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtslurup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtslurup_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtslurup_failure
cmp byte ptr[rax+5], 108
jne source_compare_fcvtslurup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtslurup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtslurup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtslurup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtslurup_failure
cmp source_character_count, 10
je source_compare_fcvtslurup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtslurup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtslurup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtslurup_success
source_compare_fcvtslurup_failure:
mov al, 1
ret
source_compare_fcvtslurup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsq:
cmp source_character_count, 6
jb source_compare_fcvtsq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsq_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsq_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsq_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsq_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsq_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtsq_failure
cmp source_character_count, 6
je source_compare_fcvtsq_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtsq_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtsq_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtsq_success
source_compare_fcvtsq_failure:
mov al, 1
ret
source_compare_fcvtsq_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsqdyn:
cmp source_character_count, 9
jb source_compare_fcvtsqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsqdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsqdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsqdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsqdyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsqdyn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtsqdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtsqdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtsqdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtsqdyn_failure
cmp source_character_count, 9
je source_compare_fcvtsqdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsqdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsqdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsqdyn_success
source_compare_fcvtsqdyn_failure:
mov al, 1
ret
source_compare_fcvtsqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsqrdn:
cmp source_character_count, 9
jb source_compare_fcvtsqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsqrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsqrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsqrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsqrdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsqrdn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtsqrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtsqrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtsqrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtsqrdn_failure
cmp source_character_count, 9
je source_compare_fcvtsqrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsqrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsqrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsqrdn_success
source_compare_fcvtsqrdn_failure:
mov al, 1
ret
source_compare_fcvtsqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsqrmm:
cmp source_character_count, 9
jb source_compare_fcvtsqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsqrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsqrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsqrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsqrmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsqrmm_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtsqrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtsqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtsqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtsqrmm_failure
cmp source_character_count, 9
je source_compare_fcvtsqrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsqrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsqrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsqrmm_success
source_compare_fcvtsqrmm_failure:
mov al, 1
ret
source_compare_fcvtsqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsqrtz:
cmp source_character_count, 9
jb source_compare_fcvtsqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsqrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsqrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsqrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsqrtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsqrtz_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtsqrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtsqrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtsqrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtsqrtz_failure
cmp source_character_count, 9
je source_compare_fcvtsqrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsqrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsqrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsqrtz_success
source_compare_fcvtsqrtz_failure:
mov al, 1
ret
source_compare_fcvtsqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsqrup:
cmp source_character_count, 9
jb source_compare_fcvtsqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsqrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsqrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsqrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsqrup_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsqrup_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtsqrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtsqrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtsqrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtsqrup_failure
cmp source_character_count, 9
je source_compare_fcvtsqrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtsqrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtsqrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtsqrup_success
source_compare_fcvtsqrup_failure:
mov al, 1
ret
source_compare_fcvtsqrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtsw:
cmp source_character_count, 6
jb source_compare_fcvtsw_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtsw_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtsw_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtsw_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtsw_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtsw_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtsw_failure
cmp source_character_count, 6
je source_compare_fcvtsw_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtsw_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtsw_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtsw_success
source_compare_fcvtsw_failure:
mov al, 1
ret
source_compare_fcvtsw_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswdyn:
cmp source_character_count, 9
jb source_compare_fcvtswdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswdyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswdyn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtswdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtswdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtswdyn_failure
cmp source_character_count, 9
je source_compare_fcvtswdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtswdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtswdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtswdyn_success
source_compare_fcvtswdyn_failure:
mov al, 1
ret
source_compare_fcvtswdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswrdn:
cmp source_character_count, 9
jb source_compare_fcvtswrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswrdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswrdn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtswrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtswrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtswrdn_failure
cmp source_character_count, 9
je source_compare_fcvtswrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtswrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtswrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtswrdn_success
source_compare_fcvtswrdn_failure:
mov al, 1
ret
source_compare_fcvtswrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswrmm:
cmp source_character_count, 9
jb source_compare_fcvtswrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswrmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswrmm_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtswrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtswrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtswrmm_failure
cmp source_character_count, 9
je source_compare_fcvtswrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtswrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtswrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtswrmm_success
source_compare_fcvtswrmm_failure:
mov al, 1
ret
source_compare_fcvtswrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswrtz:
cmp source_character_count, 9
jb source_compare_fcvtswrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswrtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswrtz_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtswrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtswrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtswrtz_failure
cmp source_character_count, 9
je source_compare_fcvtswrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtswrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtswrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtswrtz_success
source_compare_fcvtswrtz_failure:
mov al, 1
ret
source_compare_fcvtswrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswrup:
cmp source_character_count, 9
jb source_compare_fcvtswrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswrup_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswrup_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtswrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtswrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtswrup_failure
cmp source_character_count, 9
je source_compare_fcvtswrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtswrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtswrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtswrup_success
source_compare_fcvtswrup_failure:
mov al, 1
ret
source_compare_fcvtswrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswu:
cmp source_character_count, 7
jb source_compare_fcvtswu_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswu_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswu_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswu_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswu_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswu_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswu_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtswu_failure
cmp source_character_count, 7
je source_compare_fcvtswu_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtswu_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtswu_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtswu_success
source_compare_fcvtswu_failure:
mov al, 1
ret
source_compare_fcvtswu_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswudyn:
cmp source_character_count, 10
jb source_compare_fcvtswudyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswudyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswudyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswudyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswudyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswudyn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswudyn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtswudyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtswudyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtswudyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtswudyn_failure
cmp source_character_count, 10
je source_compare_fcvtswudyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtswudyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtswudyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtswudyn_success
source_compare_fcvtswudyn_failure:
mov al, 1
ret
source_compare_fcvtswudyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswurdn:
cmp source_character_count, 10
jb source_compare_fcvtswurdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswurdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswurdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswurdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswurdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswurdn_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswurdn_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtswurdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtswurdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtswurdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtswurdn_failure
cmp source_character_count, 10
je source_compare_fcvtswurdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtswurdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtswurdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtswurdn_success
source_compare_fcvtswurdn_failure:
mov al, 1
ret
source_compare_fcvtswurdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswurmm:
cmp source_character_count, 10
jb source_compare_fcvtswurmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswurmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswurmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswurmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswurmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswurmm_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswurmm_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtswurmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtswurmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtswurmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtswurmm_failure
cmp source_character_count, 10
je source_compare_fcvtswurmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtswurmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtswurmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtswurmm_success
source_compare_fcvtswurmm_failure:
mov al, 1
ret
source_compare_fcvtswurmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswurtz:
cmp source_character_count, 10
jb source_compare_fcvtswurtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswurtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswurtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswurtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswurtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswurtz_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswurtz_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtswurtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtswurtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtswurtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtswurtz_failure
cmp source_character_count, 10
je source_compare_fcvtswurtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtswurtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtswurtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtswurtz_success
source_compare_fcvtswurtz_failure:
mov al, 1
ret
source_compare_fcvtswurtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtswurup:
cmp source_character_count, 10
jb source_compare_fcvtswurup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtswurup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtswurup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtswurup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtswurup_failure
cmp byte ptr[rax+4], 115
jne source_compare_fcvtswurup_failure
cmp byte ptr[rax+5], 119
jne source_compare_fcvtswurup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fcvtswurup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtswurup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtswurup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtswurup_failure
cmp source_character_count, 10
je source_compare_fcvtswurup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtswurup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtswurup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtswurup_success
source_compare_fcvtswurup_failure:
mov al, 1
ret
source_compare_fcvtswurup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwd:
cmp source_character_count, 6
jb source_compare_fcvtwd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwd_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwd_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwd_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwd_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwd_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtwd_failure
cmp source_character_count, 6
je source_compare_fcvtwd_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtwd_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtwd_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtwd_success
source_compare_fcvtwd_failure:
mov rax, 1
ret
source_compare_fcvtwd_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwddyn:
cmp source_character_count, 9
jb source_compare_fcvtwddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwddyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwddyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwddyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwddyn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtwddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtwddyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtwddyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtwddyn_failure
cmp source_character_count, 9
je source_compare_fcvtwddyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwddyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwddyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwddyn_success
source_compare_fcvtwddyn_failure:
mov al, 1
ret
source_compare_fcvtwddyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwdrdn:
cmp source_character_count, 9
jb source_compare_fcvtwdrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwdrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwdrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwdrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwdrdn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwdrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtwdrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwdrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtwdrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtwdrdn_failure
cmp source_character_count, 9
je source_compare_fcvtwdrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwdrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwdrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwdrdn_success
source_compare_fcvtwdrdn_failure:
mov al, 1
ret
source_compare_fcvtwdrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwdrmm:
cmp source_character_count, 9
jb source_compare_fcvtwdrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwdrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwdrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwdrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwdrmm_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwdrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtwdrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwdrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtwdrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtwdrmm_failure
cmp source_character_count, 9
je source_compare_fcvtwdrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwdrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwdrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwdrmm_success
source_compare_fcvtwdrmm_failure:
mov al, 1
ret
source_compare_fcvtwdrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwdrtz:
cmp source_character_count, 9
jb source_compare_fcvtwdrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwdrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwdrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwdrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwdrtz_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwdrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtwdrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwdrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtwdrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtwdrtz_failure
cmp source_character_count, 9
je source_compare_fcvtwdrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwdrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwdrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwdrtz_success
source_compare_fcvtwdrtz_failure:
mov al, 1
ret
source_compare_fcvtwdrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwdrup:
cmp source_character_count, 9
jb source_compare_fcvtwdrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwdrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwdrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwdrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwdrup_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwdrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fcvtwdrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwdrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtwdrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtwdrup_failure
cmp source_character_count, 9
je source_compare_fcvtwdrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwdrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwdrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwdrup_success
source_compare_fcvtwdrup_failure:
mov al, 1
ret
source_compare_fcvtwdrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwq:
cmp source_character_count, 6
jb source_compare_fcvtwq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwq_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwq_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwq_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwq_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwq_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtwq_failure
cmp source_character_count, 6
je source_compare_fcvtwq_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtwq_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtwq_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtwq_success
source_compare_fcvtwq_failure:
mov al, 1
ret
source_compare_fcvtwq_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwqdyn:
cmp source_character_count, 9
jb source_compare_fcvtwqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwqdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwqdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwqdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwqdyn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwqdyn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtwqdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtwqdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtwqdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtwqdyn_failure
cmp source_character_count, 9
je source_compare_fcvtwqdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwqdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwqdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwqdyn_success
source_compare_fcvtwqdyn_failure:
mov al, 1
ret
source_compare_fcvtwqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwqrdn:
cmp source_character_count, 9
jb source_compare_fcvtwqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwqrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwqrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwqrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwqrdn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwqrdn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtwqrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwqrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtwqrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtwqrdn_failure
cmp source_character_count, 9
je source_compare_fcvtwqrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwqrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwqrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwqrdn_success
source_compare_fcvtwqrdn_failure:
mov al, 1
ret
source_compare_fcvtwqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwqrmm:
cmp source_character_count, 9
jb source_compare_fcvtwqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwqrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwqrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwqrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwqrmm_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwqrmm_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtwqrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtwqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtwqrmm_failure
cmp source_character_count, 9
je source_compare_fcvtwqrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwqrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwqrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwqrmm_success
source_compare_fcvtwqrmm_failure:
mov al, 1
ret
source_compare_fcvtwqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwqrtz:
cmp source_character_count, 9
jb source_compare_fcvtwqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwqrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwqrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwqrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwqrtz_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwqrtz_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtwqrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwqrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtwqrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtwqrtz_failure
cmp source_character_count, 9
je source_compare_fcvtwqrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwqrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwqrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwqrtz_success
source_compare_fcvtwqrtz_failure:
mov al, 1
ret
source_compare_fcvtwqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwqrup:
cmp source_character_count, 9
jb source_compare_fcvtwqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwqrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwqrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwqrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwqrup_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwqrup_failure
cmp byte ptr[rax+5], 113
jne source_compare_fcvtwqrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwqrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtwqrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtwqrup_failure
cmp source_character_count, 9
je source_compare_fcvtwqrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwqrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwqrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwqrup_success
source_compare_fcvtwqrup_failure:
mov al, 1
ret
source_compare_fcvtwqrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtws:
cmp source_character_count, 6
jb source_compare_fcvtws_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtws_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtws_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtws_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtws_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtws_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtws_failure
cmp source_character_count, 6
je source_compare_fcvtws_success
cmp byte ptr[rax+6], 10
je source_compare_fcvtws_success
cmp byte ptr[rax+6], 32
je source_compare_fcvtws_success
cmp byte ptr[rax+6], 35
je source_compare_fcvtws_success
source_compare_fcvtws_failure:
mov al, 1
ret
source_compare_fcvtws_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwsdyn:
cmp source_character_count, 9
jb source_compare_fcvtwsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwsdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwsdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwsdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwsdyn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwsdyn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtwsdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtwsdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fcvtwsdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtwsdyn_failure
cmp source_character_count, 9
je source_compare_fcvtwsdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwsdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwsdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwsdyn_success
source_compare_fcvtwsdyn_failure:
mov al, 1
ret
source_compare_fcvtwsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwsrdn:
cmp source_character_count, 9
jb source_compare_fcvtwsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwsrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwsrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwsrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwsrdn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwsrdn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtwsrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwsrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtwsrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fcvtwsrdn_failure
cmp source_character_count, 9
je source_compare_fcvtwsrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwsrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwsrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwsrdn_success
source_compare_fcvtwsrdn_failure:
mov al, 1
ret
source_compare_fcvtwsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwsrmm:
cmp source_character_count, 9
jb source_compare_fcvtwsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwsrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwsrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwsrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwsrmm_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwsrmm_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtwsrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fcvtwsrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtwsrmm_failure
cmp source_character_count, 9
je source_compare_fcvtwsrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwsrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwsrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwsrmm_success
source_compare_fcvtwsrmm_failure:
mov al, 1
ret
source_compare_fcvtwsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwsrtz:
cmp source_character_count, 9
jb source_compare_fcvtwsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwsrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwsrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwsrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwsrtz_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwsrtz_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtwsrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwsrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fcvtwsrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fcvtwsrtz_failure
cmp source_character_count, 9
je source_compare_fcvtwsrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwsrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwsrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwsrtz_success
source_compare_fcvtwsrtz_failure:
mov al, 1
ret
source_compare_fcvtwsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwsrup:
cmp source_character_count, 9
jb source_compare_fcvtwsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwsrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwsrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwsrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwsrup_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwsrup_failure
cmp byte ptr[rax+5], 115
jne source_compare_fcvtwsrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fcvtwsrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fcvtwsrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fcvtwsrup_failure
cmp source_character_count, 9
je source_compare_fcvtwsrup_success
cmp byte ptr[rax+9], 10
je source_compare_fcvtwsrup_success
cmp byte ptr[rax+9], 32
je source_compare_fcvtwsrup_success
cmp byte ptr[rax+9], 35
je source_compare_fcvtwsrup_success
source_compare_fcvtwsrup_failure:
mov al, 1
ret
source_compare_fcvtwsrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwud:
cmp source_character_count, 7
jb source_compare_fcvtwud_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwud_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwud_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwud_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwud_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwud_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwud_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtwud_failure
cmp source_character_count, 7
je source_compare_fcvtwud_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtwud_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtwud_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtwud_success
source_compare_fcvtwud_failure:
mov al, 1
ret
source_compare_fcvtwud_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwuddyn:
cmp source_character_count, 10
jb source_compare_fcvtwuddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwuddyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwuddyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwuddyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwuddyn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwuddyn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwuddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtwuddyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtwuddyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtwuddyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtwuddyn_failure
cmp source_character_count, 10
je source_compare_fcvtwuddyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwuddyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwuddyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwuddyn_success
source_compare_fcvtwuddyn_failure:
mov al, 1
ret
source_compare_fcvtwuddyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwudrdn:
cmp source_character_count, 10
jb source_compare_fcvtwudrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwudrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwudrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwudrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwudrdn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwudrdn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwudrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtwudrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwudrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtwudrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtwudrdn_failure
cmp source_character_count, 10
je source_compare_fcvtwudrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwudrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwudrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwudrdn_success
source_compare_fcvtwudrdn_failure:
mov al, 1
ret
source_compare_fcvtwudrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwudrmm:
cmp source_character_count, 10
jb source_compare_fcvtwudrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwudrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwudrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwudrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwudrmm_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwudrmm_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwudrmm_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtwudrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwudrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtwudrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtwudrmm_failure
cmp source_character_count, 10
je source_compare_fcvtwudrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwudrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwudrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwudrmm_success
source_compare_fcvtwudrmm_failure:
mov al, 1
ret
source_compare_fcvtwudrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwudrtz:
cmp source_character_count, 10
jb source_compare_fcvtwudrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwudrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwudrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwudrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwudrtz_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwudrtz_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwudrtz_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtwudrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwudrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtwudrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtwudrtz_failure
cmp source_character_count, 10
je source_compare_fcvtwudrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwudrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwudrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwudrtz_success
source_compare_fcvtwudrtz_failure:
mov al, 1
ret
source_compare_fcvtwudrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwudrup:
cmp source_character_count, 10
jb source_compare_fcvtwudrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwudrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwudrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwudrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwudrup_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwudrup_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwudrup_failure
cmp byte ptr[rax+6], 100
jne source_compare_fcvtwudrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwudrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtwudrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtwudrup_failure
cmp source_character_count, 10
je source_compare_fcvtwudrup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwudrup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwudrup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwudrup_success
source_compare_fcvtwudrup_failure:
mov al, 1
ret
source_compare_fcvtwudrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwuq:
cmp source_character_count, 7
jb source_compare_fcvtwuq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwuq_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwuq_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwuq_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwuq_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwuq_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwuq_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtwuq_failure
cmp source_character_count, 7
je source_compare_fcvtwuq_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtwuq_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtwuq_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtwuq_success
source_compare_fcvtwuq_failure:
mov al, 1
ret
source_compare_fcvtwuq_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwuqdyn:
cmp source_character_count, 10
jb source_compare_fcvtwuqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwuqdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwuqdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwuqdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwuqdyn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwuqdyn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwuqdyn_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtwuqdyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtwuqdyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtwuqdyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtwuqdyn_failure
cmp source_character_count, 10
je source_compare_fcvtwuqdyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwuqdyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwuqdyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwuqdyn_success
source_compare_fcvtwuqdyn_failure:
mov al, 1
ret
source_compare_fcvtwuqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwuqrdn:
cmp source_character_count, 10
jb source_compare_fcvtwuqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwuqrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwuqrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwuqrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwuqrdn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwuqrdn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwuqrdn_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtwuqrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwuqrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtwuqrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtwuqrdn_failure
cmp source_character_count, 10
je source_compare_fcvtwuqrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwuqrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwuqrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwuqrdn_success
source_compare_fcvtwuqrdn_failure:
mov al, 1
ret
source_compare_fcvtwuqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwuqrmm:
cmp source_character_count, 10
jb source_compare_fcvtwuqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwuqrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwuqrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwuqrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwuqrmm_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwuqrmm_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwuqrmm_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtwuqrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwuqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtwuqrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtwuqrmm_failure
cmp source_character_count, 10
je source_compare_fcvtwuqrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwuqrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwuqrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwuqrmm_success
source_compare_fcvtwuqrmm_failure:
mov al, 1
ret
source_compare_fcvtwuqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwuqrtz:
cmp source_character_count, 10
jb source_compare_fcvtwuqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwuqrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwuqrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwuqrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwuqrtz_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwuqrtz_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwuqrtz_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtwuqrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwuqrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtwuqrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtwuqrtz_failure
cmp source_character_count, 10
je source_compare_fcvtwuqrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwuqrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwuqrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwuqrtz_success
source_compare_fcvtwuqrtz_failure:
mov al, 1
ret
source_compare_fcvtwuqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwuqrup:
cmp source_character_count, 10
jb source_compare_fcvtwuqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwuqrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwuqrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwuqrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwuqrup_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwuqrup_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwuqrup_failure
cmp byte ptr[rax+6], 113
jne source_compare_fcvtwuqrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwuqrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtwuqrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtwuqrup_failure
cmp source_character_count, 10
je source_compare_fcvtwuqrup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwuqrup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwuqrup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwuqrup_success
source_compare_fcvtwuqrup_failure:
mov al, 1
ret
source_compare_fcvtwuqrup_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwus:
cmp source_character_count, 7
jb source_compare_fcvtwus_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwus_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwus_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwus_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwus_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwus_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwus_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtwus_failure
cmp source_character_count, 7
je source_compare_fcvtwus_success
cmp byte ptr[rax+7], 10
je source_compare_fcvtwus_success
cmp byte ptr[rax+7], 32
je source_compare_fcvtwus_success
cmp byte ptr[rax+7], 35
je source_compare_fcvtwus_success
source_compare_fcvtwus_failure:
mov al, 1
ret
source_compare_fcvtwus_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwusdyn:
cmp source_character_count, 10
jb source_compare_fcvtwusdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwusdyn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwusdyn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwusdyn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwusdyn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwusdyn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwusdyn_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtwusdyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fcvtwusdyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fcvtwusdyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtwusdyn_failure
cmp source_character_count, 10
je source_compare_fcvtwusdyn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwusdyn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwusdyn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwusdyn_success
source_compare_fcvtwusdyn_failure:
mov al, 1
ret
source_compare_fcvtwusdyn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwusrdn:
cmp source_character_count, 10
jb source_compare_fcvtwusrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwusrdn_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwusrdn_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwusrdn_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwusrdn_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwusrdn_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwusrdn_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtwusrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwusrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fcvtwusrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fcvtwusrdn_failure
cmp source_character_count, 10
je source_compare_fcvtwusrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwusrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwusrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwusrdn_success
source_compare_fcvtwusrdn_failure:
mov al, 1
ret
source_compare_fcvtwusrdn_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwusrmm:
cmp source_character_count, 10
jb source_compare_fcvtwusrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwusrmm_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwusrmm_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwusrmm_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwusrmm_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwusrmm_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwusrmm_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtwusrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwusrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fcvtwusrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fcvtwusrmm_failure
cmp source_character_count, 10
je source_compare_fcvtwusrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwusrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwusrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwusrmm_success
source_compare_fcvtwusrmm_failure:
mov al, 1
ret
source_compare_fcvtwusrmm_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwusrtz:
cmp source_character_count, 10
jb source_compare_fcvtwusrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwusrtz_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwusrtz_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwusrtz_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwusrtz_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwusrtz_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwusrtz_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtwusrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwusrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fcvtwusrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fcvtwusrtz_failure
cmp source_character_count, 10
je source_compare_fcvtwusrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwusrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwusrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwusrtz_success
source_compare_fcvtwusrtz_failure:
mov al, 1
ret
source_compare_fcvtwusrtz_success:
xor al, al
ret


; out
; al status
source_compare_fcvtwusrup:
cmp source_character_count, 10
jb source_compare_fcvtwusrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fcvtwusrup_failure
cmp byte ptr[rax+1], 99
jne source_compare_fcvtwusrup_failure
cmp byte ptr[rax+2], 118
jne source_compare_fcvtwusrup_failure
cmp byte ptr[rax+3], 116
jne source_compare_fcvtwusrup_failure
cmp byte ptr[rax+4], 119
jne source_compare_fcvtwusrup_failure
cmp byte ptr[rax+5], 117
jne source_compare_fcvtwusrup_failure
cmp byte ptr[rax+6], 115
jne source_compare_fcvtwusrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fcvtwusrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fcvtwusrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fcvtwusrup_failure
cmp source_character_count, 10
je source_compare_fcvtwusrup_success
cmp byte ptr[rax+10], 10
je source_compare_fcvtwusrup_success
cmp byte ptr[rax+10], 32
je source_compare_fcvtwusrup_success
cmp byte ptr[rax+10], 35
je source_compare_fcvtwusrup_success
source_compare_fcvtwusrup_failure:
mov al, 1
ret
source_compare_fcvtwusrup_success:
xor al, al
ret


; out
; al status
source_compare_fdivd:
cmp source_character_count, 5
jb source_compare_fdivd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivd_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivd_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivd_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivd_failure
cmp byte ptr[rax+4], 100
jne source_compare_fdivd_failure
cmp source_character_count, 5
je source_compare_fdivd_success
cmp byte ptr[rax+5], 10
je source_compare_fdivd_success
cmp byte ptr[rax+5], 32
je source_compare_fdivd_success
cmp byte ptr[rax+5], 35
je source_compare_fdivd_success
source_compare_fdivd_failure:
mov al, 1
ret
source_compare_fdivd_success:
xor al, al
ret


; out
; al status
source_compare_fdivddyn:
cmp source_character_count, 8
jb source_compare_fdivddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivddyn_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivddyn_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivddyn_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivddyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fdivddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fdivddyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_fdivddyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fdivddyn_failure
cmp source_character_count, 8
je source_compare_fdivddyn_success
cmp byte ptr[rax+8], 10
je source_compare_fdivddyn_success
cmp byte ptr[rax+8], 32
je source_compare_fdivddyn_success
cmp byte ptr[rax+8], 35
je source_compare_fdivddyn_success
source_compare_fdivddyn_failure:
mov al, 1
ret
source_compare_fdivddyn_success:
xor al, al
ret


; out
; al status
source_compare_fdivdrdn:
cmp source_character_count, 8
jb source_compare_fdivdrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivdrdn_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivdrdn_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivdrdn_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivdrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fdivdrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivdrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fdivdrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fdivdrdn_failure
cmp source_character_count, 8
je source_compare_fdivdrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fdivdrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fdivdrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fdivdrdn_success
source_compare_fdivdrdn_failure:
mov al, 1
ret
source_compare_fdivdrdn_success:
xor al, al
ret


; out
; al status
source_compare_fdivdrmm:
cmp source_character_count, 8
jb source_compare_fdivdrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivdrmm_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivdrmm_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivdrmm_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivdrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fdivdrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivdrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fdivdrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fdivdrmm_failure
cmp source_character_address, 8
je source_compare_fdivdrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fdivdrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fdivdrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fdivdrmm_success
source_compare_fdivdrmm_failure:
mov al, 1
ret
source_compare_fdivdrmm_success:
xor al, al
ret


; out
; al status
source_compare_fdivdrtz:
cmp source_character_count, 8
jb source_compare_fdivdrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivdrtz_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivdrtz_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivdrtz_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivdrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fdivdrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivdrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fdivdrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fdivdrtz_failure
cmp source_character_count, 8
je source_compare_fdivdrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fdivdrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fdivdrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fdivdrtz_success
source_compare_fdivdrtz_failure:
mov al, 1
ret
source_compare_fdivdrtz_success:
xor al, al
ret


; out
; al status
source_compare_fdivdrup:
cmp source_character_count, 8
jb source_compare_fdivdrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivdrup_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivdrup_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivdrup_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivdrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fdivdrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivdrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fdivdrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fdivdrup_failure
cmp source_character_count, 8
je source_compare_fdivdrup_success
cmp byte ptr[rax+8], 10
je source_compare_fdivdrup_success
cmp byte ptr[rax+8], 32
je source_compare_fdivdrup_success
cmp byte ptr[rax+8], 35
je source_compare_fdivdrup_success
source_compare_fdivdrup_failure:
mov al, 1
ret
source_compare_fdivdrup_success:
xor al, al
ret


; out
; al status
source_compare_fdivq:
cmp source_character_count, 5
jb source_compare_fdivq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivq_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivq_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivq_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivq_failure
cmp byte ptr[rax+4], 113
jne source_compare_fdivq_failure
cmp source_character_count, 5
je source_compare_fdivq_success
cmp byte ptr[rax+5], 10
je source_compare_fdivq_success
cmp byte ptr[rax+5], 32
je source_compare_fdivq_success
cmp byte ptr[rax+5], 35
je source_compare_fdivq_success
source_compare_fdivq_failure:
mov al, 1
ret
source_compare_fdivq_success:
xor al, al
ret


; out
; al status
source_compare_fdivqdyn:
cmp source_character_count, 8
jb source_compare_fdivqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivqdyn_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivqdyn_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivqdyn_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivqdyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fdivqdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fdivqdyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_fdivqdyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fdivqdyn_failure
cmp source_character_count, 8
je source_compare_fdivqdyn_success
cmp byte ptr[rax+8], 10
je source_compare_fdivqdyn_success
cmp byte ptr[rax+8], 32
je source_compare_fdivqdyn_success
cmp byte ptr[rax+8], 35
je source_compare_fdivqdyn_success
source_compare_fdivqdyn_failure:
mov al, 1
ret
source_compare_fdivqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fdivqrdn:
cmp source_character_count, 8
jb source_compare_fdivqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivqrdn_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivqrdn_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivqrdn_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivqrdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fdivqrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivqrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fdivqrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fdivqrdn_failure
cmp source_character_count, 8
je source_compare_fdivqrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fdivqrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fdivqrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fdivqrdn_success
source_compare_fdivqrdn_failure:
mov al, 1
ret
source_compare_fdivqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fdivqrmm:
cmp source_character_count, 8
jb source_compare_fdivqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivqrmm_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivqrmm_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivqrmm_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivqrmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_fdivqrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivqrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fdivqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fdivqrmm_failure
cmp source_character_count, 8
je source_compare_fdivqrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fdivqrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fdivqrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fdivqrmm_success
source_compare_fdivqrmm_failure:
mov al, 1
ret
source_compare_fdivqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fdivqrtz:
cmp source_character_count, 8
jb source_compare_fdivqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivqrtz_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivqrtz_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivqrtz_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivqrtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_fdivqrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivqrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fdivqrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fdivqrtz_failure
cmp source_character_count, 8
je source_compare_fdivqrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fdivqrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fdivqrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fdivqrtz_success
source_compare_fdivqrtz_failure:
mov al, 1
ret
source_compare_fdivqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fdivqrup:
cmp source_character_count, 8
jb source_compare_fdivqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivqrup_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivqrup_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivqrup_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivqrup_failure
cmp byte ptr[rax+4], 113
jne source_compare_fdivqrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivqrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fdivqrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fdivqrup_failure
cmp source_character_count, 8
je source_compare_fdivqrup_success
cmp byte ptr[rax+8], 10
je source_compare_fdivqrup_success
cmp byte ptr[rax+8], 32
je source_compare_fdivqrup_success
cmp byte ptr[rax+8], 35
je source_compare_fdivqrup_success
source_compare_fdivqrup_failure:
mov al, 1
ret
source_compare_fdivqrup_success:
xor al, al
ret


; out
; al status
source_compare_fdivs:
cmp source_character_count, 5
jb source_compare_fdivs_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivs_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivs_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivs_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivs_failure
cmp byte ptr[rax+4], 115
jne source_compare_fdivs_failure
cmp source_character_count, 5
je source_compare_fdivs_success
cmp byte ptr[rax+5], 10
je source_compare_fdivs_success
cmp byte ptr[rax+5], 32
je source_compare_fdivs_success
cmp byte ptr[rax+5], 35
je source_compare_fdivs_success
source_compare_fdivs_failure:
mov al, 1
ret
source_compare_fdivs_success:
xor al, al
ret


; out
; al status
source_compare_fdivsdyn:
cmp source_character_count, 8
jb source_compare_fdivsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivsdyn_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivsdyn_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivsdyn_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivsdyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fdivsdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fdivsdyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_fdivsdyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fdivsdyn_failure
cmp source_character_count, 8
je source_compare_fdivsdyn_success
cmp byte ptr[rax+8], 10
je source_compare_fdivsdyn_success
cmp byte ptr[rax+8], 32
je source_compare_fdivsdyn_success
cmp byte ptr[rax+8], 35
je source_compare_fdivsdyn_success
source_compare_fdivsdyn_failure:
mov al, 1
ret
source_compare_fdivsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fdivsrdn:
cmp source_character_count, 8
jb source_compare_fdivsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivsrdn_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivsrdn_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivsrdn_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivsrdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fdivsrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivsrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fdivsrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fdivsrdn_failure
cmp source_character_count, 8
je source_compare_fdivsrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fdivsrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fdivsrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fdivsrdn_success
source_compare_fdivsrdn_failure:
mov al, 1
ret
source_compare_fdivsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fdivsrmm:
cmp source_character_count, 8
jb source_compare_fdivsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivsrmm_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivsrmm_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivsrmm_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivsrmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_fdivsrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivsrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fdivsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fdivsrmm_failure
cmp source_character_count, 8
je source_compare_fdivsrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fdivsrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fdivsrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fdivsrmm_success
source_compare_fdivsrmm_failure:
mov al, 1
ret
source_compare_fdivsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fdivsrtz:
cmp source_character_count, 8
jb source_compare_fdivsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivsrtz_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivsrtz_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivsrtz_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivsrtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_fdivsrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivsrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fdivsrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fdivsrtz_failure
cmp source_character_count, 8
je source_compare_fdivsrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fdivsrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fdivsrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fdivsrtz_success
source_compare_fdivsrtz_failure:
mov al, 1
ret
source_compare_fdivsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fdivsrup:
cmp source_character_count, 8
jb source_compare_fdivsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fdivsrup_failure
cmp byte ptr[rax+1], 100
jne source_compare_fdivsrup_failure
cmp byte ptr[rax+2], 105
jne source_compare_fdivsrup_failure
cmp byte ptr[rax+3], 118
jne source_compare_fdivsrup_failure
cmp byte ptr[rax+4], 115
jne source_compare_fdivsrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fdivsrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fdivsrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fdivsrup_failure
cmp source_character_count, 8
je source_compare_fdivsrup_success
cmp byte ptr[rax+8], 10
je source_compare_fdivsrup_success
cmp byte ptr[rax+8], 32
je source_compare_fdivsrup_success
cmp byte ptr[rax+8], 35
je source_compare_fdivsrup_success
source_compare_fdivsrup_failure:
mov al, 1
ret
source_compare_fdivsrup_success:
xor al, al
ret


; out
; al status
source_compare_fence:
cmp source_character_count, 5
jb source_compare_fence_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fence_failure
cmp byte ptr[rax+1], 101
jne source_compare_fence_failure
cmp byte ptr[rax+2], 110
jne source_compare_fence_failure
cmp byte ptr[rax+3], 99
jne source_compare_fence_failure
cmp byte ptr[rax+4], 101
jne source_compare_fence_failure
cmp source_character_count, 5
je source_compare_fence_success
cmp byte ptr[rax+5], 10
je source_compare_fence_success
cmp byte ptr[rax+5], 32
je source_compare_fence_success
cmp byte ptr[rax+5], 35
je source_compare_fence_success
source_compare_fence_failure:
mov al, 1
ret
source_compare_fence_success:
xor al, al
ret


; out
; al status
source_compare_fencei:
cmp source_character_count, 6
jb source_compare_fencei_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fencei_failure
cmp byte ptr[rax+1], 101
jne source_compare_fencei_failure
cmp byte ptr[rax+2], 110
jne source_compare_fencei_failure
cmp byte ptr[rax+3], 99
jne source_compare_fencei_failure
cmp byte ptr[rax+4], 101
jne source_compare_fencei_failure
cmp byte ptr[rax+5], 105
jne source_compare_fencei_failure
cmp source_character_count, 6
je source_compare_fencei_success
cmp byte ptr[rax+6], 10
je source_compare_fencei_success
cmp byte ptr[rax+6], 32
je source_compare_fencei_success
cmp byte ptr[rax+6], 35
je source_compare_fencei_success
source_compare_fencei_failure:
mov al, 1
ret
source_compare_fencei_success:
xor al, al
ret


; out
; al status
source_compare_feqd:
cmp source_character_count, 4
jb source_compare_feqd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_feqd_failure
cmp byte ptr[rax+1], 101
jne source_compare_feqd_failure
cmp byte ptr[rax+2], 113
jne source_compare_feqd_failure
cmp byte ptr[rax+3], 100
jne source_compare_feqd_failure
cmp source_character_count, 4
je source_compare_feqd_success
cmp byte ptr[rax+4], 10
je source_compare_feqd_success
cmp byte ptr[rax+4], 32
je source_compare_feqd_success
cmp byte ptr[rax+4], 35
je source_compare_feqd_success
source_compare_feqd_failure:
mov al, 1
ret
source_compare_feqd_success:
xor al, al
ret


; out
; al status
source_compare_feqq:
cmp source_character_count, 4
jb source_compare_feqq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_feqq_failure
cmp byte ptr[rax+1], 101
jne source_compare_feqq_failure
cmp byte ptr[rax+2], 113
jne source_compare_feqq_failure
cmp byte ptr[rax+3], 113
jne source_compare_feqq_failure
cmp source_character_count, 4
je source_compare_feqq_success
cmp byte ptr[rax+4], 10
je source_compare_feqq_success
cmp byte ptr[rax+4], 32
je source_compare_feqq_success
cmp byte ptr[rax+4], 35
je source_compare_feqq_success
source_compare_feqq_failure:
mov al, 1
ret
source_compare_feqq_success:
xor al, al
ret


; out
; al status
source_compare_feqs:
cmp source_character_count, 4
jb source_compare_feqs_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_feqs_failure
cmp byte ptr[rax+1], 101
jne source_compare_feqs_failure
cmp byte ptr[rax+2], 113
jne source_compare_feqs_failure
cmp byte ptr[rax+3], 115
jne source_compare_feqs_failure
cmp source_character_count, 4
je source_compare_feqs_success
cmp byte ptr[rax+4], 10
je source_compare_feqs_success
cmp byte ptr[rax+4], 32
je source_compare_feqs_success
cmp byte ptr[rax+4], 35
je source_compare_feqs_success
source_compare_feqs_failure:
mov al, 1
ret
source_compare_feqs_success:
xor al, al
ret


; out
; al status
source_compare_fld:
cmp source_character_count, 3
jb source_compare_fld_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fld_failure
cmp byte ptr[rax+1], 108
jne source_compare_fld_failure
cmp byte ptr[rax+2], 100
jne source_compare_fld_failure
cmp source_character_count, 3
je source_compare_fld_success
cmp byte ptr[rax+3], 10
je source_compare_fld_success
cmp byte ptr[rax+3], 32
je source_compare_fld_success
cmp byte ptr[rax+3], 35
je source_compare_fld_success
source_compare_fld_failure:
mov al, 1
ret
source_compare_fld_success:
xor al, al
ret


; out
; al status
source_compare_fled:
cmp source_character_count, 4
jb source_compare_fled_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fled_failure
cmp byte ptr[rax+1], 108
jne source_compare_fled_failure
cmp byte ptr[rax+2], 101
jne source_compare_fled_failure
cmp byte ptr[rax+3], 100
jne source_compare_fled_failure
cmp source_character_count, 4
je source_compare_fled_success
cmp byte ptr[rax+4], 10
je source_compare_fled_success
cmp byte ptr[rax+4], 32
je source_compare_fled_success
cmp byte ptr[rax+4], 35
je source_compare_fled_success
source_compare_fled_failure:
mov al, 1
ret
source_compare_fled_success:
xor al, al
ret


; out
; al status
source_compare_fleq:
cmp source_character_count, 4
jb source_compare_fleq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fleq_failure
cmp byte ptr[rax+1], 108
jne source_compare_fleq_failure
cmp byte ptr[rax+2], 101
jne source_compare_fleq_failure
cmp byte ptr[rax+3], 113
jne source_compare_fleq_failure
cmp source_character_count, 4
je source_compare_fleq_success
cmp byte ptr[rax+4], 10
je source_compare_fleq_success
cmp byte ptr[rax+4], 32
je source_compare_fleq_success
cmp byte ptr[rax+4], 35
je source_compare_fleq_success
source_compare_fleq_failure:
mov al, 1
ret
source_compare_fleq_success:
xor al, al
ret


; out
; al status
source_compare_fles:
cmp source_character_count, 4
jb source_compare_fles_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fles_failure
cmp byte ptr[rax+1], 108
jne source_compare_fles_failure
cmp byte ptr[rax+2], 101
jne source_compare_fles_failure
cmp byte ptr[rax+3], 115
jne source_compare_fles_failure
cmp source_character_count, 4
je source_compare_fles_success
cmp byte ptr[rax+4], 10
je source_compare_fles_success
cmp byte ptr[rax+4], 32
je source_compare_fles_success
cmp byte ptr[rax+4], 35
je source_compare_fles_success
source_compare_fles_failure:
mov al, 1
ret
source_compare_fles_success:
xor al, al
ret


; out
; al status
source_compare_flq:
cmp source_character_count, 3
jb source_compare_flq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_flq_failure
cmp byte ptr[rax+1], 108
jne source_compare_flq_failure
cmp byte ptr[rax+2], 113
jne source_compare_flq_failure
cmp source_character_count, 3
je source_compare_flq_success
cmp byte ptr[rax+3], 10
je source_compare_flq_success
cmp byte ptr[rax+3], 32
je source_compare_flq_success
cmp byte ptr[rax+3], 35
je source_compare_flq_success
source_compare_flq_failure:
mov al, 1
ret
source_compare_flq_success:
xor al, al
ret


; out
; al status
source_compare_fltd:
cmp source_character_count, 4
jb source_compare_fltd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fltd_failure
cmp byte ptr[rax+1], 108
jne source_compare_fltd_failure
cmp byte ptr[rax+2], 116
jne source_compare_fltd_failure
cmp byte ptr[rax+3], 100
jne source_compare_fltd_failure
cmp source_character_count, 4
je source_compare_fltd_success
cmp byte ptr[rax+4], 10
je source_compare_fltd_success
cmp byte ptr[rax+4], 32
je source_compare_fltd_success
cmp byte ptr[rax+4], 35
je source_compare_fltd_success
source_compare_fltd_failure:
mov al, 1
ret
source_compare_fltd_success:
xor al, al
ret


; out
; al status
source_compare_fltq:
cmp source_character_count, 4
jb source_compare_fltq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fltq_failure
cmp byte ptr[rax+1], 108
jne source_compare_fltq_failure
cmp byte ptr[rax+2], 116
jne source_compare_fltq_failure
cmp byte ptr[rax+3], 113
jne source_compare_fltq_failure
cmp source_character_count, 4
je source_compare_fltq_success
cmp byte ptr[rax+4], 10
je source_compare_fltq_success
cmp byte ptr[rax+4], 32
je source_compare_fltq_success
cmp byte ptr[rax+4], 35
je source_compare_fltq_success
source_compare_fltq_failure:
mov al, 1
ret
source_compare_fltq_success:
xor al, al
ret


; out
; al status
source_compare_flts:
cmp source_character_count, 4
jb source_compare_flts_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_flts_failure
cmp byte ptr[rax+1], 108
jne source_compare_flts_failure
cmp byte ptr[rax+2], 116
jne source_compare_flts_failure
cmp byte ptr[rax+3], 115
jne source_compare_flts_failure
cmp source_character_count, 4
je source_compare_flts_success
cmp byte ptr[rax+4], 10
je source_compare_flts_success
cmp byte ptr[rax+4], 32
je source_compare_flts_success
cmp byte ptr[rax+4], 35
je source_compare_flts_success
source_compare_flts_failure:
mov al, 1
ret
source_compare_flts_success:
xor al, al
ret


; out
; al status
source_compare_flw:
cmp source_character_count, 3
jb source_compare_flw_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_flw_failure
cmp byte ptr[rax+1], 108
jne source_compare_flw_failure
cmp byte ptr[rax+2], 119
jne source_compare_flw_failure
cmp source_character_count, 3
je source_compare_flw_success
cmp byte ptr[rax+3], 10
je source_compare_flw_success
cmp byte ptr[rax+3], 32
je source_compare_flw_success
cmp byte ptr[rax+3], 35
je source_compare_flw_success
source_compare_flw_failure:
mov al, 1
ret
source_compare_flw_success:
xor al, al
ret


; out
; al status
source_compare_fmaddd:
cmp source_character_count, 6
jb source_compare_fmaddd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddd_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddd_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddd_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddd_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddd_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmaddd_failure
cmp source_character_count, 6
je source_compare_fmaddd_success
cmp byte ptr[rax+6], 10
je source_compare_fmaddd_success
cmp byte ptr[rax+6], 32
je source_compare_fmaddd_success
cmp byte ptr[rax+6], 35
je source_compare_fmaddd_success
source_compare_fmaddd_failure:
mov al, 1
ret
source_compare_fmaddd_success:
xor al, al
ret


; out
; al status
source_compare_fmaddddyn:
cmp source_character_count, 9
jb source_compare_fmaddddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddddyn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddddyn_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddddyn_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddddyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmaddddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fmaddddyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fmaddddyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmaddddyn_failure
cmp source_character_count, 9
je source_compare_fmaddddyn_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddddyn_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddddyn_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddddyn_success
source_compare_fmaddddyn_failure:
mov al, 1
ret
source_compare_fmaddddyn_success:
xor al, al
ret


; out
; al status
source_compare_fmadddrdn:
cmp source_character_count, 9
jb source_compare_fmadddrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmadddrdn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmadddrdn_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmadddrdn_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmadddrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmadddrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmadddrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmadddrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fmadddrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmadddrdn_failure
cmp source_character_count, 9
je source_compare_fmadddrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fmadddrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fmadddrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fmadddrdn_success
source_compare_fmadddrdn_failure:
mov al, 1
ret
source_compare_fmadddrdn_success:
xor al, al
ret


; out
; al status
source_compare_fmadddrmm:
cmp source_character_count, 9
jb source_compare_fmadddrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmadddrmm_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmadddrmm_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmadddrmm_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmadddrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmadddrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmadddrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmadddrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fmadddrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fmadddrmm_failure
cmp source_character_count, 9
je source_compare_fmadddrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fmadddrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fmadddrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fmadddrmm_success
source_compare_fmadddrmm_failure:
mov al, 1
ret
source_compare_fmadddrmm_success:
xor al, al
ret


; out
; al status
source_compare_fmadddrtz:
cmp source_character_count, 9
jb source_compare_fmadddrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmadddrtz_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmadddrtz_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmadddrtz_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmadddrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmadddrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmadddrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmadddrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fmadddrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fmadddrtz_failure
cmp source_character_count, 9
je source_compare_fmadddrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fmadddrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fmadddrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fmadddrtz_success
source_compare_fmadddrtz_failure:
mov al, 1
ret
source_compare_fmadddrtz_success:
xor al, al
ret


; out
; al status
source_compare_fmadddrup:
cmp source_character_count, 9
jb source_compare_fmadddrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmadddrup_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmadddrup_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmadddrup_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmadddrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmadddrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmadddrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmadddrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fmadddrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fmadddrup_failure
cmp source_character_count, 9
je source_compare_fmadddrup_success
cmp byte ptr[rax+9], 10
je source_compare_fmadddrup_success
cmp byte ptr[rax+9], 32
je source_compare_fmadddrup_success
cmp byte ptr[rax+9], 35
je source_compare_fmadddrup_success
source_compare_fmadddrup_failure:
mov al, 1
ret
source_compare_fmadddrup_success:
xor al, al
ret


; out
; al status
source_compare_fmaddq:
cmp source_character_count, 6
jb source_compare_fmaddq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddq_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddq_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddq_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddq_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddq_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmaddq_failure
cmp source_character_count, 6
je source_compare_fmaddq_success
cmp byte ptr[rax+6], 10
je source_compare_fmaddq_success
cmp byte ptr[rax+6], 32
je source_compare_fmaddq_success
cmp byte ptr[rax+6], 35
je source_compare_fmaddq_success
source_compare_fmaddq_failure:
mov al, 1
ret
source_compare_fmaddq_success:
xor al, al
ret


; out
; al status
source_compare_fmaddqdyn:
cmp source_character_count, 9
jb source_compare_fmaddqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddqdyn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddqdyn_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddqdyn_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddqdyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddqdyn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmaddqdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fmaddqdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fmaddqdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmaddqdyn_failure
cmp source_character_count, 9
je source_compare_fmaddqdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddqdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddqdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddqdyn_success
source_compare_fmaddqdyn_failure:
mov al, 1
ret
source_compare_fmaddqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fmaddqrdn:
cmp source_character_count, 9
jb source_compare_fmaddqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddqrdn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddqrdn_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddqrdn_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddqrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddqrdn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmaddqrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmaddqrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fmaddqrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmaddqrdn_failure
cmp source_character_count, 9
je source_compare_fmaddqrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddqrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddqrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddqrdn_success
source_compare_fmaddqrdn_failure:
mov al, 1
ret
source_compare_fmaddqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fmaddqrmm:
cmp source_character_count, 9
jb source_compare_fmaddqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddqrmm_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddqrmm_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddqrmm_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddqrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddqrmm_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmaddqrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmaddqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fmaddqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fmaddqrmm_failure
cmp source_character_count, 9
je source_compare_fmaddqrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddqrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddqrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddqrmm_success
source_compare_fmaddqrmm_failure:
mov al, 1
ret
source_compare_fmaddqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fmaddqrtz:
cmp source_character_count, 9
jb source_compare_fmaddqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddqrtz_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddqrtz_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddqrtz_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddqrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddqrtz_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmaddqrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmaddqrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fmaddqrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fmaddqrtz_failure
cmp source_character_count, 9
je source_compare_fmaddqrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddqrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddqrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddqrtz_success
source_compare_fmaddqrtz_failure:
mov al, 1
ret
source_compare_fmaddqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fmaddqrup:
cmp source_character_count, 9
jb source_compare_fmaddqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddqrup_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddqrup_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddqrup_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddqrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddqrup_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmaddqrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmaddqrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fmaddqrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fmaddqrup_failure
cmp source_character_count, 9
je source_compare_fmaddqrup_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddqrup_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddqrup_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddqrup_success
source_compare_fmaddqrup_failure:
mov al, 1
ret
source_compare_fmaddqrup_success:
xor al, al
ret


; out
; al status
source_compare_fmadds:
cmp source_character_count, 6
jb source_compare_fmadds_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmadds_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmadds_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmadds_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmadds_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmadds_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmadds_failure
cmp source_character_count, 6
je source_compare_fmadds_success
cmp byte ptr[rax+6], 10
je source_compare_fmadds_success
cmp byte ptr[rax+6], 32
je source_compare_fmadds_success
cmp byte ptr[rax+6], 35
je source_compare_fmadds_success
source_compare_fmadds_failure:
mov al, 1
ret
source_compare_fmadds_success:
xor al, al
ret


; out
; al status
source_compare_fmaddsdyn:
cmp source_character_count, 9
jb source_compare_fmaddsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddsdyn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddsdyn_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddsdyn_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddsdyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddsdyn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmaddsdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fmaddsdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fmaddsdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmaddsdyn_failure
cmp source_character_count, 9
je source_compare_fmaddsdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddsdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddsdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddsdyn_success
source_compare_fmaddsdyn_failure:
mov al, 1
ret
source_compare_fmaddsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fmaddsrdn:
cmp source_character_count, 9
jb source_compare_fmaddsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddsrdn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddsrdn_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddsrdn_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddsrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddsrdn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmaddsrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmaddsrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fmaddsrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmaddsrdn_failure
cmp source_character_count, 9
je source_compare_fmaddsrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddsrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddsrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddsrdn_success
source_compare_fmaddsrdn_failure:
mov al, 1
ret
source_compare_fmaddsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fmaddsrmm:
cmp source_character_count, 9
jb source_compare_fmaddsrmm_failure
cmp byte ptr[rax], 102
jne source_compare_fmaddsrmm_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddsrmm_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddsrmm_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddsrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddsrmm_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmaddsrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmaddsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fmaddsrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fmaddsrmm_failure
cmp source_character_count, 9
je source_compare_fmaddsrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddsrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddsrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddsrmm_success
source_compare_fmaddsrmm_failure:
mov al, 1
ret
source_compare_fmaddsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fmaddsrtz:
cmp source_character_count, 9
jb source_compare_fmaddsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddsrtz_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddsrtz_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddsrtz_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddsrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddsrtz_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmaddsrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmaddsrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fmaddsrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fmaddsrtz_failure
cmp source_character_count, 9
je source_compare_fmaddsrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddsrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddsrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddsrtz_success
source_compare_fmaddsrtz_failure:
mov al, 1
ret
source_compare_fmaddsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fmaddsrup:
cmp source_character_count, 9
jb source_compare_fmaddsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaddsrup_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaddsrup_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaddsrup_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmaddsrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaddsrup_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmaddsrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmaddsrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fmaddsrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fmaddsrup_failure
cmp source_character_count, 9
je source_compare_fmaddsrup_success
cmp byte ptr[rax+9], 10
je source_compare_fmaddsrup_success
cmp byte ptr[rax+9], 32
je source_compare_fmaddsrup_success
cmp byte ptr[rax+9], 35
je source_compare_fmaddsrup_success
source_compare_fmaddsrup_failure:
mov al, 1
ret
source_compare_fmaddsrup_success:
xor al, al
ret


; out
; al status
source_compare_fmaxd:
cmp source_character_count, 5
jb source_compare_fmaxd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaxd_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaxd_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaxd_failure
cmp byte ptr[rax+3], 120
jne source_compare_fmaxd_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmaxd_failure
cmp source_character_count, 5
je source_compare_fmaxd_success
cmp byte ptr[rax+5], 10
je source_compare_fmaxd_success
cmp byte ptr[rax+5], 32
je source_compare_fmaxd_success
cmp byte ptr[rax+5], 35
je source_compare_fmaxd_success
source_compare_fmaxd_failure:
mov al, 1
ret
source_compare_fmaxd_success:
xor al, al
ret


; out
; al status
source_compare_fmaxq:
cmp source_character_count, 5
jb source_compare_fmaxq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaxq_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaxq_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaxq_failure
cmp byte ptr[rax+3], 120
jne source_compare_fmaxq_failure
cmp byte ptr[rax+4], 113
jne source_compare_fmaxq_failure
cmp source_character_count, 5
je source_compare_fmaxq_success
cmp byte ptr[rax+5], 10
je source_compare_fmaxq_success
cmp byte ptr[rax+5], 32
je source_compare_fmaxq_success
cmp byte ptr[rax+5], 35
je source_compare_fmaxq_success
source_compare_fmaxq_failure:
mov al, 1
ret
source_compare_fmaxq_success:
xor al, al
ret


; out
; al status
source_compare_fmaxs:
cmp source_character_count, 5
jb source_compare_fmaxs_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmaxs_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmaxs_failure
cmp byte ptr[rax+2], 97
jne source_compare_fmaxs_failure
cmp byte ptr[rax+3], 120
jne source_compare_fmaxs_failure
cmp byte ptr[rax+4], 115
jne source_compare_fmaxs_failure
cmp source_character_count, 5
je source_compare_fmaxs_success
cmp byte ptr[rax+5], 10
je source_compare_fmaxs_success
cmp byte ptr[rax+5], 32
je source_compare_fmaxs_success
cmp byte ptr[rax+5], 35
je source_compare_fmaxs_success
source_compare_fmaxs_failure:
mov al, 1
ret
source_compare_fmaxs_success:
xor al, al
ret


; out
; al status
source_compare_fmind:
cmp source_character_count, 5
jb source_compare_fmind_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmind_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmind_failure
cmp byte ptr[rax+2], 105
jne source_compare_fmind_failure
cmp byte ptr[rax+3], 110
jne source_compare_fmind_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmind_failure
cmp source_character_count, 5
je source_compare_fmind_success
cmp byte ptr[rax+5], 10
je source_compare_fmind_success
cmp byte ptr[rax+5], 32
je source_compare_fmind_success
cmp byte ptr[rax+5], 35
je source_compare_fmind_success
source_compare_fmind_failure:
mov al, 1
ret
source_compare_fmind_success:
xor al, al
ret


; out
; al status
source_compare_fminq:
cmp source_character_count, 5
jb source_compare_fminq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fminq_failure
cmp byte ptr[rax+1], 109
jne source_compare_fminq_failure
cmp byte ptr[rax+2], 105
jne source_compare_fminq_failure
cmp byte ptr[rax+3], 110
jne source_compare_fminq_failure
cmp byte ptr[rax+4], 113
jne source_compare_fminq_failure
cmp source_character_count, 5
je source_compare_fminq_success
cmp byte ptr[rax+5], 10
je source_compare_fminq_success
cmp byte ptr[rax+5], 32
je source_compare_fminq_success
cmp byte ptr[rax+5], 35
je source_compare_fminq_success
source_compare_fminq_failure:
mov al, 1
ret
source_compare_fminq_success:
xor al, al
ret


; out
; al status
source_compare_fmins:
cmp source_character_count, 5
jb source_compare_fmins_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmins_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmins_failure
cmp byte ptr[rax+2], 105
jne source_compare_fmins_failure
cmp byte ptr[rax+3], 110
jne source_compare_fmins_failure
cmp byte ptr[rax+4], 115
jne source_compare_fmins_failure
cmp source_character_count, 5
je source_compare_fmins_success
cmp byte ptr[rax+5], 10
je source_compare_fmins_success
cmp byte ptr[rax+5], 32
je source_compare_fmins_success
cmp byte ptr[rax+5], 35
je source_compare_fmins_success
source_compare_fmins_failure:
mov al, 1
ret
source_compare_fmins_success:
xor al, al
ret


; out
; al status
source_compare_fmsubd:
cmp source_character_count, 6
jb source_compare_fmsubd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubd_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubd_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubd_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubd_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubd_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmsubd_failure
cmp source_character_count, 6
je source_compare_fmsubd_success
cmp byte ptr[rax+6], 10
je source_compare_fmsubd_success
cmp byte ptr[rax+6], 32
je source_compare_fmsubd_success
cmp byte ptr[rax+6], 35
je source_compare_fmsubd_success
source_compare_fmsubd_failure:
mov al, 1
ret
source_compare_fmsubd_success:
xor al, al
ret


; out
; al status
source_compare_fmsubddyn:
cmp source_character_count, 9
jb source_compare_fmsubddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubddyn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubddyn_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubddyn_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubddyn_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmsubddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fmsubddyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fmsubddyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmsubddyn_failure
cmp source_character_count, 9
je source_compare_fmsubddyn_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubddyn_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubddyn_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubddyn_success
source_compare_fmsubddyn_failure:
mov al, 1
ret
source_compare_fmsubddyn_success:
xor al, al
ret


; out
; al status
source_compare_fmsubdrdn:
cmp source_character_count, 9
jb source_compare_fmsubdrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubdrdn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubdrdn_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubdrdn_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubdrdn_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubdrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmsubdrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubdrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fmsubdrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmsubdrdn_failure
cmp source_character_count, 9
je source_compare_fmsubdrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubdrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubdrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubdrdn_success
source_compare_fmsubdrdn_failure:
mov al, 1
ret
source_compare_fmsubdrdn_success:
xor al, al
ret


; out
; al status
source_compare_fmsubdrmm:
cmp source_character_count, 9
jb source_compare_fmsubdrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubdrmm_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubdrmm_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubdrmm_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubdrmm_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubdrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmsubdrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubdrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fmsubdrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fmsubdrmm_failure
cmp source_character_count, 9
je source_compare_fmsubdrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubdrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubdrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubdrmm_success
source_compare_fmsubdrmm_failure:
mov al, 1
ret
source_compare_fmsubdrmm_success:
xor al, al
ret


; out
; al status
source_compare_fmsubdrtz:
cmp source_character_count, 9
jb source_compare_fmsubdrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubdrtz_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubdrtz_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubdrtz_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubdrtz_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubdrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmsubdrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubdrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fmsubdrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fmsubdrtz_failure
cmp source_character_count, 9
je source_compare_fmsubdrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubdrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubdrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubdrtz_success
source_compare_fmsubdrtz_failure:
mov al, 1
ret
source_compare_fmsubdrtz_success:
xor al, al
ret


; out
; al status
source_compare_fmsubdrup:
cmp source_character_count, 9
jb source_compare_fmsubdrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubdrup_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubdrup_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubdrup_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubdrup_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubdrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmsubdrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubdrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fmsubdrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fmsubdrup_failure
cmp source_character_count, 9
je source_compare_fmsubdrup_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubdrup_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubdrup_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubdrup_success
source_compare_fmsubdrup_failure:
mov al, 1
ret
source_compare_fmsubdrup_success:
xor al, al
ret


; out
; al status
source_compare_fmsubq:
cmp source_character_count, 6
jb source_compare_fmsubq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubq_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubq_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubq_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubq_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubq_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmsubq_failure
cmp source_character_count, 6
je source_compare_fmsubq_success
cmp byte ptr[rax+6], 10
je source_compare_fmsubq_success
cmp byte ptr[rax+6], 32
je source_compare_fmsubq_success
cmp byte ptr[rax+6], 35
je source_compare_fmsubq_success
source_compare_fmsubq_failure:
mov al, 1
ret
source_compare_fmsubq_success:
xor al, al
ret


; out
; al status
source_compare_fmsubqdyn:
cmp source_character_count, 9
jb source_compare_fmsubqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubqdyn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubqdyn_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubqdyn_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubqdyn_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubqdyn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmsubqdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fmsubqdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fmsubqdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmsubqdyn_failure
cmp source_character_count, 9
je source_compare_fmsubqdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubqdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubqdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubqdyn_success
source_compare_fmsubqdyn_failure:
mov al, 1
ret
source_compare_fmsubqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fmsubqrdn:
cmp source_character_count, 9
jb source_compare_fmsubqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubqrdn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubqrdn_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubqrdn_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubqrdn_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubqrdn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmsubqrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubqrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fmsubqrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmsubqrdn_failure
cmp source_character_count, 9
je source_compare_fmsubqrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubqrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubqrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubqrdn_success
source_compare_fmsubqrdn_failure:
mov al, 1
ret
source_compare_fmsubqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fmsubqrmm:
cmp source_character_count, 9
jb source_compare_fmsubqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubqrmm_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubqrmm_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubqrmm_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubqrmm_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubqrmm_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmsubqrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fmsubqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fmsubqrmm_failure
cmp source_character_count, 9
je source_compare_fmsubqrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubqrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubqrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubqrmm_success
source_compare_fmsubqrmm_failure:
mov al, 1
ret
source_compare_fmsubqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fmsubqrtz:
cmp source_character_count, 9
jb source_compare_fmsubqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubqrtz_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubqrtz_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubqrtz_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubqrtz_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubqrtz_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmsubqrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubqrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fmsubqrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fmsubqrtz_failure
cmp source_character_count, 9
je source_compare_fmsubqrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubqrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubqrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubqrtz_success
source_compare_fmsubqrtz_failure:
mov al, 1
ret
source_compare_fmsubqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fmsubqrup:
cmp source_character_count, 9
jb source_compare_fmsubqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubqrup_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubqrup_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubqrup_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubqrup_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubqrup_failure
cmp byte ptr[rax+5], 113
jne source_compare_fmsubqrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubqrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fmsubqrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fmsubqrup_failure
cmp source_character_count, 9
je source_compare_fmsubqrup_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubqrup_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubqrup_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubqrup_success
source_compare_fmsubqrup_failure:
mov al, 1
ret
source_compare_fmsubqrup_success:
xor al, al
ret


; out
; al status
source_compare_fmsubs:
cmp source_character_count, 6
jb source_compare_fmsubs_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubs_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubs_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubs_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubs_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubs_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmsubs_failure
cmp source_character_count, 6
je source_compare_fmsubs_success
cmp byte ptr[rax+6], 10
je source_compare_fmsubs_success
cmp byte ptr[rax+6], 32
je source_compare_fmsubs_success
cmp byte ptr[rax+6], 35
je source_compare_fmsubs_success
source_compare_fmsubs_failure:
mov al, 1
ret
source_compare_fmsubs_success:
xor al, al
ret


; out
; al status
source_compare_fmsubsdyn:
cmp source_character_count, 9
jb source_compare_fmsubsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubsdyn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubsdyn_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubsdyn_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubsdyn_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubsdyn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmsubsdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fmsubsdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fmsubsdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmsubsdyn_failure
cmp source_character_count, 9
je source_compare_fmsubsdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubsdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubsdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubsdyn_success
source_compare_fmsubsdyn_failure:
mov al, 1
ret
source_compare_fmsubsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fmsubsrdn:
cmp source_character_count, 9
jb source_compare_fmsubsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubsrdn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubsrdn_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubsrdn_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubsrdn_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubsrdn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmsubsrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubsrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fmsubsrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fmsubsrdn_failure
cmp source_character_count, 9
je source_compare_fmsubsrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubsrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubsrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubsrdn_success
source_compare_fmsubsrdn_failure:
mov al, 1
ret
source_compare_fmsubsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fmsubsrmm:
cmp source_character_count, 9
jb source_compare_fmsubsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubsrmm_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubsrmm_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubsrmm_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubsrmm_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubsrmm_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmsubsrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fmsubsrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fmsubsrmm_failure
cmp source_character_count, 9
je source_compare_fmsubsrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubsrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubsrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubsrmm_success
source_compare_fmsubsrmm_failure:
mov al, 1
ret
source_compare_fmsubsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fmsubsrtz:
cmp source_character_count, 9
jb source_compare_fmsubsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubsrtz_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubsrtz_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubsrtz_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubsrtz_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubsrtz_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmsubsrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubsrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fmsubsrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fmsubsrtz_failure
cmp source_character_count, 9
je source_compare_fmsubsrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubsrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubsrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubsrtz_success
source_compare_fmsubsrtz_failure:
mov al, 1
ret
source_compare_fmsubsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fmsubsrup:
cmp source_character_count, 9
jb source_compare_fmsubsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmsubsrup_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmsubsrup_failure
cmp byte ptr[rax+2], 115
jne source_compare_fmsubsrup_failure
cmp byte ptr[rax+3], 117
jne source_compare_fmsubsrup_failure
cmp byte ptr[rax+4], 98
jne source_compare_fmsubsrup_failure
cmp byte ptr[rax+5], 115
jne source_compare_fmsubsrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fmsubsrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fmsubsrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fmsubsrup_failure
cmp source_character_count, 9
je source_compare_fmsubsrup_success
cmp byte ptr[rax+9], 10
je source_compare_fmsubsrup_success
cmp byte ptr[rax+9], 32
je source_compare_fmsubsrup_success
cmp byte ptr[rax+9], 35
je source_compare_fmsubsrup_success
source_compare_fmsubsrup_failure:
mov al, 1
ret
source_compare_fmsubsrup_success:
xor al, al
ret


; out
; al status
source_compare_fmuld:
cmp source_character_count, 5
jb source_compare_fmuld_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmuld_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmuld_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmuld_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmuld_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmuld_failure
cmp source_character_count, 5
je source_compare_fmuld_success
cmp byte ptr[rax+5], 10
je source_compare_fmuld_success
cmp byte ptr[rax+5], 32
je source_compare_fmuld_success
cmp byte ptr[rax+5], 35
je source_compare_fmuld_success
source_compare_fmuld_failure:
mov al, 1
ret
source_compare_fmuld_success:
xor al, al
ret


; out
; al status
source_compare_fmulddyn:
cmp source_character_count, 8
jb source_compare_fmulddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulddyn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulddyn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulddyn_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulddyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmulddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmulddyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_fmulddyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fmulddyn_failure
cmp source_character_count, 8
je source_compare_fmulddyn_success
cmp byte ptr[rax+8], 10
je source_compare_fmulddyn_success
cmp byte ptr[rax+8], 32
je source_compare_fmulddyn_success
cmp byte ptr[rax+8], 35
je source_compare_fmulddyn_success
source_compare_fmulddyn_failure:
mov al, 1
ret
source_compare_fmulddyn_success:
xor al, al
ret


; out
; al status
source_compare_fmuldrdn:
cmp source_character_count, 8
jb source_compare_fmuldrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmuldrdn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmuldrdn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmuldrdn_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmuldrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmuldrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmuldrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fmuldrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fmuldrdn_failure
cmp source_character_count, 8
je source_compare_fmuldrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fmuldrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fmuldrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fmuldrdn_success
source_compare_fmuldrdn_failure:
mov al, 1
ret
source_compare_fmuldrdn_success:
xor al, al
ret


; out
; al status
source_compare_fmuldrmm:
cmp source_character_count, 8
jb source_compare_fmuldrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmuldrmm_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmuldrmm_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmuldrmm_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmuldrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmuldrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmuldrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fmuldrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fmuldrmm_failure
cmp source_character_count, 8
je source_compare_fmuldrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fmuldrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fmuldrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fmuldrmm_success
source_compare_fmuldrmm_failure:
mov al, 1
ret
source_compare_fmuldrmm_success:
xor al, al
ret


; out
; al status
source_compare_fmuldrtz:
cmp source_character_count, 8
jb source_compare_fmuldrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmuldrtz_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmuldrtz_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmuldrtz_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmuldrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmuldrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmuldrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fmuldrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fmuldrtz_failure
cmp source_character_count, 8
je source_compare_fmuldrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fmuldrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fmuldrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fmuldrtz_success
source_compare_fmuldrtz_failure:
mov al, 1
ret
source_compare_fmuldrtz_success:
xor al, al
ret


; out
; al status
source_compare_fmuldrup:
cmp source_character_count, 8
jb source_compare_fmuldrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmuldrup_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmuldrup_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmuldrup_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmuldrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmuldrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmuldrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fmuldrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fmuldrup_failure
cmp source_character_count, 8
je source_compare_fmuldrup_success
cmp byte ptr[rax+8], 10
je source_compare_fmuldrup_success
cmp byte ptr[rax+8], 32
je source_compare_fmuldrup_success
cmp byte ptr[rax+8], 35
je source_compare_fmuldrup_success
source_compare_fmuldrup_failure:
mov al, 1
ret
source_compare_fmuldrup_success:
xor al, al
ret


; out
; al status
source_compare_fmulq:
cmp source_character_count, 5
jb source_compare_fmulq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulq_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulq_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulq_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulq_failure
cmp byte ptr[rax+4], 113
jne source_compare_fmulq_failure
cmp source_character_count, 5
je source_compare_fmulq_success
cmp byte ptr[rax+5], 10
je source_compare_fmulq_success
cmp byte ptr[rax+5], 32
je source_compare_fmulq_success
cmp byte ptr[rax+5], 35
je source_compare_fmulq_success
source_compare_fmulq_failure:
mov al, 1
ret
source_compare_fmulq_success:
xor al, al
ret


; out
; al status
source_compare_fmulqdyn:
cmp source_character_count, 8
jb source_compare_fmulqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulqdyn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulqdyn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulqdyn_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulqdyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fmulqdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmulqdyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_fmulqdyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fmulqdyn_failure
cmp source_character_count, 8
je source_compare_fmulqdyn_success
cmp byte ptr[rax+8], 10
je source_compare_fmulqdyn_success
cmp byte ptr[rax+8], 32
je source_compare_fmulqdyn_success
cmp byte ptr[rax+8], 35
je source_compare_fmulqdyn_success
source_compare_fmulqdyn_failure:
mov al, 1
ret
source_compare_fmulqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fmulqrdn:
cmp source_character_count, 8
jb source_compare_fmulqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulqrdn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulqrdn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulqrdn_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulqrdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fmulqrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmulqrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fmulqrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fmulqrdn_failure
cmp source_character_count, 8
je source_compare_fmulqrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fmulqrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fmulqrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fmulqrdn_success
source_compare_fmulqrdn_failure:
mov al, 1
ret
source_compare_fmulqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fmulqrmm:
cmp source_character_count, 8
jb source_compare_fmulqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulqrmm_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulqrmm_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulqrmm_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulqrmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_fmulqrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmulqrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fmulqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fmulqrmm_failure
cmp source_character_count, 8
je source_compare_fmulqrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fmulqrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fmulqrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fmulqrmm_success
source_compare_fmulqrmm_failure:
mov al, 1
ret
source_compare_fmulqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fmulqrtz:
cmp source_character_count, 8
jb source_compare_fmulqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulqrtz_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulqrtz_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulqrtz_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulqrtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_fmulqrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmulqrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fmulqrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fmulqrtz_failure
cmp source_character_count, 8
je source_compare_fmulqrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fmulqrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fmulqrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fmulqrtz_success
source_compare_fmulqrtz_failure:
mov al, 1
ret
source_compare_fmulqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fmulqrup:
cmp source_character_count, 8
jb source_compare_fmulqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulqrup_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulqrup_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulqrup_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulqrup_failure
cmp byte ptr[rax+4], 113
jne source_compare_fmulqrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmulqrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fmulqrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fmulqrup_failure
cmp source_character_count, 8
je source_compare_fmulqrup_success
cmp byte ptr[rax+8], 10
je source_compare_fmulqrup_success
cmp byte ptr[rax+8], 32
je source_compare_fmulqrup_success
cmp byte ptr[rax+8], 35
je source_compare_fmulqrup_success
source_compare_fmulqrup_failure:
mov al, 1
ret
source_compare_fmulqrup_success:
xor al, al
ret


; out
; al status
source_compare_fmuls:
cmp source_character_count, 5
jb source_compare_fmuls_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmuls_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmuls_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmuls_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmuls_failure
cmp byte ptr[rax+4], 115
jne source_compare_fmuls_failure
cmp source_character_count, 5
je source_compare_fmuls_success
cmp byte ptr[rax+5], 10
je source_compare_fmuls_success
cmp byte ptr[rax+5], 32
je source_compare_fmuls_success
cmp byte ptr[rax+5], 35
je source_compare_fmuls_success
source_compare_fmuls_failure:
mov al, 1
ret
source_compare_fmuls_success:
xor al, al
ret


; out
; al status
source_compare_fmulsdyn:
cmp source_character_count, 8
jb source_compare_fmulsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulsdyn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulsdyn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulsdyn_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulsdyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fmulsdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fmulsdyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_fmulsdyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fmulsdyn_failure
cmp source_character_count, 8
je source_compare_fmulsdyn_success
cmp byte ptr[rax+8], 10
je source_compare_fmulsdyn_success
cmp byte ptr[rax+8], 32
je source_compare_fmulsdyn_success
cmp byte ptr[rax+8], 35
je source_compare_fmulsdyn_success
source_compare_fmulsdyn_failure:
mov al, 1
ret
source_compare_fmulsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fmulsrdn:
cmp source_character_count, 8
jb source_compare_fmulsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulsrdn_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulsrdn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulsrdn_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulsrdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fmulsrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmulsrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fmulsrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fmulsrdn_failure
cmp source_character_count, 8
je source_compare_fmulsrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fmulsrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fmulsrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fmulsrdn_success
source_compare_fmulsrdn_failure:
mov al, 1
ret
source_compare_fmulsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fmulsrmm:
cmp source_character_count, 8
jb source_compare_fmulsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulsrmm_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulsrmm_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulsrmm_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulsrmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_fmulsrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmulsrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fmulsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fmulsrmm_failure
cmp source_character_count, 8
je source_compare_fmulsrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fmulsrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fmulsrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fmulsrmm_success
source_compare_fmulsrmm_failure:
mov al, 1
ret
source_compare_fmulsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fmulsrtz:
cmp source_character_count, 8
jb source_compare_fmulsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulsrtz_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulsrtz_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulsrtz_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulsrtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_fmulsrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmulsrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fmulsrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fmulsrtz_failure
cmp source_character_count, 8
je source_compare_fmulsrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fmulsrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fmulsrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fmulsrtz_success
source_compare_fmulsrtz_failure:
mov al, 1
ret
source_compare_fmulsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fmulsrup:
cmp source_character_count, 8
jb source_compare_fmulsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmulsrup_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmulsrup_failure
cmp byte ptr[rax+2], 117
jne source_compare_fmulsrup_failure
cmp byte ptr[rax+3], 108
jne source_compare_fmulsrup_failure
cmp byte ptr[rax+4], 115
jne source_compare_fmulsrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fmulsrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fmulsrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fmulsrup_failure
cmp source_character_count, 8
je source_compare_fmulsrup_success
cmp byte ptr[rax+8], 10
je source_compare_fmulsrup_success
cmp byte ptr[rax+8], 32
je source_compare_fmulsrup_success
cmp byte ptr[rax+8], 35
je source_compare_fmulsrup_success
source_compare_fmulsrup_failure:
mov al, 1
ret
source_compare_fmulsrup_success:
xor al, al
ret


; out
; al status
source_compare_fmvdx:
cmp source_character_count, 5
jb source_compare_fmvdx_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmvdx_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmvdx_failure
cmp byte ptr[rax+2], 118
jne source_compare_fmvdx_failure
cmp byte ptr[rax+3], 100
jne source_compare_fmvdx_failure
cmp byte ptr[rax+4], 120
jne source_compare_fmvdx_failure
cmp source_character_count, 5
je source_compare_fmvdx_success
cmp byte ptr[rax+5], 10
je source_compare_fmvdx_success
cmp byte ptr[rax+5], 32
je source_compare_fmvdx_success
cmp byte ptr[rax+5], 35
je source_compare_fmvdx_success
source_compare_fmvdx_failure:
mov al, 1
ret
source_compare_fmvdx_success:
xor al, al
ret


; out
; al status
source_compare_fmvwx:
cmp source_character_count, 5
jb source_compare_fmvwx_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmvwx_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmvwx_failure
cmp byte ptr[rax+2], 118
jne source_compare_fmvwx_failure
cmp byte ptr[rax+3], 119
jne source_compare_fmvwx_failure
cmp byte ptr[rax+4], 120
jne source_compare_fmvwx_failure
cmp source_character_count, 5
je source_compare_fmvwx_success
cmp byte ptr[rax+5], 10
je source_compare_fmvwx_success
cmp byte ptr[rax+5], 32
je source_compare_fmvwx_success
cmp byte ptr[rax+5], 35
je source_compare_fmvwx_success
source_compare_fmvwx_failure:
mov al, 1
ret
source_compare_fmvwx_success:
xor al, al
ret


; out
; al status
source_compare_fmvxd:
cmp source_character_count, 5
jb source_compare_fmvxd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmvxd_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmvxd_failure
cmp byte ptr[rax+2], 118
jne source_compare_fmvxd_failure
cmp byte ptr[rax+3], 120
jne source_compare_fmvxd_failure
cmp byte ptr[rax+4], 100
jne source_compare_fmvxd_failure
cmp source_character_count, 5
je source_compare_fmvxd_success
cmp byte ptr[rax+5], 10
je source_compare_fmvxd_success
cmp byte ptr[rax+5], 32
je source_compare_fmvxd_success
cmp byte ptr[rax+5], 35
je source_compare_fmvxd_success
source_compare_fmvxd_failure:
mov al, 1
ret
source_compare_fmvxd_success:
xor al, al
ret


; out
; al status
source_compare_fmvxw:
cmp source_character_count, 5
jb source_compare_fmvxw_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fmvxw_failure
cmp byte ptr[rax+1], 109
jne source_compare_fmvxw_failure
cmp byte ptr[rax+2], 118
jne source_compare_fmvxw_failure
cmp byte ptr[rax+3], 120
jne source_compare_fmvxw_failure
cmp byte ptr[rax+4], 119
jne source_compare_fmvxw_failure
cmp source_character_count, 5
je source_compare_fmvxw_success
cmp byte ptr[rax+5], 10
je source_compare_fmvxw_success
cmp byte ptr[rax+5], 32
je source_compare_fmvxw_success
cmp byte ptr[rax+5], 35
je source_compare_fmvxw_success
source_compare_fmvxw_failure:
mov al, 1
ret
source_compare_fmvxw_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddd:
cmp source_character_count, 7
jb source_compare_fnmaddd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddd_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddd_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddd_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddd_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddd_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddd_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmaddd_failure
cmp source_character_count, 7
je source_compare_fnmaddd_success
cmp byte ptr[rax+7], 10
je source_compare_fnmaddd_success
cmp byte ptr[rax+7], 32
je source_compare_fnmaddd_success
cmp byte ptr[rax+7], 35
je source_compare_fnmaddd_success
source_compare_fnmaddd_failure:
mov al, 1
ret
source_compare_fnmaddd_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddddyn:
cmp source_character_count, 10
jb source_compare_fnmaddddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddddyn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddddyn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddddyn_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddddyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmaddddyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fnmaddddyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fnmaddddyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmaddddyn_failure
cmp source_character_count, 10
je source_compare_fnmaddddyn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddddyn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddddyn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddddyn_success
source_compare_fnmaddddyn_failure:
mov al, 1
ret
source_compare_fnmaddddyn_success:
xor al, al
ret


; out
; al status
source_compare_fnmadddrdn:
cmp source_character_count, 10
jb source_compare_fnmadddrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmadddrdn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmadddrdn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmadddrdn_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmadddrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmadddrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmadddrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmadddrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmadddrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fnmadddrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmadddrdn_failure
cmp source_character_count, 10
je source_compare_fnmadddrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmadddrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmadddrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmadddrdn_success
source_compare_fnmadddrdn_failure:
mov al, 1
ret
source_compare_fnmadddrdn_success:
xor al, al
ret


; out
; al status
source_compare_fnmadddrmm:
cmp source_character_count, 10
jb source_compare_fnmadddrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmadddrmm_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmadddrmm_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmadddrmm_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmadddrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmadddrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmadddrmm_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmadddrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmadddrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fnmadddrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fnmadddrmm_failure
cmp source_character_count, 10
je source_compare_fnmadddrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fnmadddrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fnmadddrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fnmadddrmm_success
source_compare_fnmadddrmm_failure:
mov al, 1
ret
source_compare_fnmadddrmm_success:
xor al, al
ret


; out
; al status
source_compare_fnmadddrtz:
cmp source_character_count, 10
jb source_compare_fnmadddrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmadddrtz_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmadddrtz_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmadddrtz_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmadddrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmadddrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmadddrtz_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmadddrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmadddrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fnmadddrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fnmadddrtz_failure
cmp source_character_count, 10
je source_compare_fnmadddrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fnmadddrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fnmadddrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fnmadddrtz_success
source_compare_fnmadddrtz_failure:
mov al, 1
ret
source_compare_fnmadddrtz_success:
xor al, al
ret


; out
; al status
source_compare_fnmadddrup:
cmp source_character_count, 10
jb source_compare_fnmadddrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmadddrup_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmadddrup_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmadddrup_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmadddrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmadddrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmadddrup_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmadddrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmadddrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fnmadddrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fnmadddrup_failure
cmp source_character_count, 10
je source_compare_fnmadddrup_success
cmp byte ptr[rax+10], 10
je source_compare_fnmadddrup_success
cmp byte ptr[rax+10], 32
je source_compare_fnmadddrup_success
cmp byte ptr[rax+10], 35
je source_compare_fnmadddrup_success
source_compare_fnmadddrup_failure:
mov al, 1
ret
source_compare_fnmadddrup_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddq:
cmp source_character_count, 7
jb source_compare_fnmaddq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddq_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddq_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddq_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddq_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddq_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddq_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmaddq_failure
cmp source_character_count, 7
je source_compare_fnmaddq_success
cmp byte ptr[rax+7], 10
je source_compare_fnmaddq_success
cmp byte ptr[rax+7], 32
je source_compare_fnmaddq_success
cmp byte ptr[rax+7], 35
je source_compare_fnmaddq_success
source_compare_fnmaddq_failure:
mov al, 1
ret
source_compare_fnmaddq_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddqdyn:
cmp source_character_count, 10
jb source_compare_fnmaddqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddqdyn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddqdyn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddqdyn_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddqdyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddqdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddqdyn_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmaddqdyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fnmaddqdyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fnmaddqdyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmaddqdyn_failure
cmp source_character_count, 10
je source_compare_fnmaddqdyn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddqdyn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddqdyn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddqdyn_success
source_compare_fnmaddqdyn_failure:
mov al, 1
ret
source_compare_fnmaddqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddqrdn:
cmp source_character_count, 10
jb source_compare_fnmaddqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddqrdn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddqrdn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddqrdn_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddqrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddqrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddqrdn_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmaddqrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmaddqrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fnmaddqrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmaddqrdn_failure
cmp source_character_count, 10
je source_compare_fnmaddqrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddqrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddqrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddqrdn_success
source_compare_fnmaddqrdn_failure:
mov al, 1
ret
source_compare_fnmaddqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddqrmm:
cmp source_character_count, 10
jb source_compare_fnmaddqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddqrmm_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddqrmm_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddqrmm_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddqrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddqrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddqrmm_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmaddqrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmaddqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fnmaddqrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fnmaddqrmm_failure
cmp source_character_count, 10
je source_compare_fnmaddqrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddqrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddqrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddqrmm_success
source_compare_fnmaddqrmm_failure:
mov al, 1
ret
source_compare_fnmaddqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddqrtz:
cmp source_character_count, 10
jb source_compare_fnmaddqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddqrtz_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddqrtz_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddqrtz_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddqrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddqrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddqrtz_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmaddqrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmaddqrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fnmaddqrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fnmaddqrtz_failure
cmp source_character_count, 10
je source_compare_fnmaddqrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddqrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddqrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddqrtz_success
source_compare_fnmaddqrtz_failure:
mov al, 1
ret
source_compare_fnmaddqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddqrup:
cmp source_character_count, 10
jb source_compare_fnmaddqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddqrup_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddqrup_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddqrup_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddqrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddqrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddqrup_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmaddqrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmaddqrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fnmaddqrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fnmaddqrup_failure
cmp source_character_count, 10
je source_compare_fnmaddqrup_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddqrup_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddqrup_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddqrup_success
source_compare_fnmaddqrup_failure:
mov al, 1
ret
source_compare_fnmaddqrup_success:
xor al, al
ret


; out
; al status
source_compare_fnmadds:
cmp source_character_count, 7
jb source_compare_fnmadds_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmadds_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmadds_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmadds_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmadds_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmadds_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmadds_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmadds_failure
cmp source_character_count, 7
je source_compare_fnmadds_success
cmp byte ptr[rax+7], 10
je source_compare_fnmadds_success
cmp byte ptr[rax+7], 32
je source_compare_fnmadds_success
cmp byte ptr[rax+7], 35
je source_compare_fnmadds_success
source_compare_fnmadds_failure:
mov al, 1
ret
source_compare_fnmadds_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddsdyn:
cmp source_character_count, 10
jb source_compare_fnmaddsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddsdyn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddsdyn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddsdyn_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddsdyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddsdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddsdyn_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmaddsdyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fnmaddsdyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fnmaddsdyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmaddsdyn_failure
cmp source_character_count, 10
je source_compare_fnmaddsdyn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddsdyn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddsdyn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddsdyn_success
source_compare_fnmaddsdyn_failure:
mov al, 1
ret
source_compare_fnmaddsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddsrdn:
cmp source_character_count, 10
jb source_compare_fnmaddsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddsrdn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddsrdn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddsrdn_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddsrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddsrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddsrdn_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmaddsrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmaddsrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fnmaddsrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmaddsrdn_failure
cmp source_character_count, 10
je source_compare_fnmaddsrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddsrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddsrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddsrdn_success
source_compare_fnmaddsrdn_failure:
mov al, 1
ret
source_compare_fnmaddsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddsrmm:
cmp source_character_count, 10
jb source_compare_fnmaddsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddsrmm_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddsrmm_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddsrmm_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddsrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddsrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddsrmm_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmaddsrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmaddsrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fnmaddsrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fnmaddsrmm_failure
cmp source_character_count, 10
je source_compare_fnmaddsrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddsrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddsrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddsrmm_success
source_compare_fnmaddsrmm_failure:
mov al, 1
ret
source_compare_fnmaddsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddsrtz:
cmp source_character_count, 10
jb source_compare_fnmaddsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddsrtz_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddsrtz_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddsrtz_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddsrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddsrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddsrtz_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmaddsrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmaddsrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fnmaddsrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fnmaddsrtz_failure
cmp source_character_count, 10
je source_compare_fnmaddsrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddsrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddsrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddsrtz_success
source_compare_fnmaddsrtz_failure:
mov al, 1
ret
source_compare_fnmaddsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fnmaddsrup:
cmp source_character_count, 10
jb source_compare_fnmaddsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmaddsrup_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmaddsrup_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmaddsrup_failure
cmp byte ptr[rax+3], 97
jne source_compare_fnmaddsrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fnmaddsrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fnmaddsrup_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmaddsrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmaddsrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fnmaddsrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fnmaddsrup_failure
cmp source_character_count, 10
je source_compare_fnmaddsrup_success
cmp byte ptr[rax+10], 10
je source_compare_fnmaddsrup_success
cmp byte ptr[rax+10], 32
je source_compare_fnmaddsrup_success
cmp byte ptr[rax+10], 35
je source_compare_fnmaddsrup_success
source_compare_fnmaddsrup_failure:
mov al, 1
ret
source_compare_fnmaddsrup_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubd:
cmp source_character_count, 7
jb source_compare_fnmsubd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubd_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubd_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubd_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubd_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubd_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubd_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmsubd_failure
cmp source_character_count, 7
je source_compare_fnmsubd_success
cmp byte ptr[rax+7], 10
je source_compare_fnmsubd_success
cmp byte ptr[rax+7], 32
je source_compare_fnmsubd_success
cmp byte ptr[rax+7], 35
je source_compare_fnmsubd_success
source_compare_fnmsubd_failure:
mov al, 1
ret
source_compare_fnmsubd_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubddyn:
cmp source_character_count, 10
jb source_compare_fnmsubddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubddyn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubddyn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubddyn_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubddyn_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubddyn_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmsubddyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fnmsubddyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fnmsubddyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmsubddyn_failure
cmp source_character_count, 10
je source_compare_fnmsubddyn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubddyn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubddyn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubddyn_success
source_compare_fnmsubddyn_failure:
mov al, 1
ret
source_compare_fnmsubddyn_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubdrdn:
cmp source_character_count, 10
jb source_compare_fnmsubdrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubdrdn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubdrdn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubdrdn_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubdrdn_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubdrdn_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubdrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmsubdrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubdrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fnmsubdrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmsubdrdn_failure
cmp source_character_count, 10
je source_compare_fnmsubdrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubdrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubdrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubdrdn_success
source_compare_fnmsubdrdn_failure:
mov al, 1
ret
source_compare_fnmsubdrdn_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubdrmm:
cmp source_character_count, 10
jb source_compare_fnmsubdrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubdrmm_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubdrmm_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubdrmm_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubdrmm_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubdrmm_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubdrmm_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmsubdrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubdrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fnmsubdrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fnmsubdrmm_failure
cmp source_character_count, 10
je source_compare_fnmsubdrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubdrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubdrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubdrmm_success
source_compare_fnmsubdrmm_failure:
mov al, 1
ret
source_compare_fnmsubdrmm_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubdrtz:
cmp source_character_count, 10
jb source_compare_fnmsubdrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubdrtz_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubdrtz_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubdrtz_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubdrtz_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubdrtz_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubdrtz_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmsubdrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubdrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fnmsubdrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fnmsubdrtz_failure
cmp source_character_count, 10
je source_compare_fnmsubdrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubdrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubdrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubdrtz_success
source_compare_fnmsubdrtz_failure:
mov al, 1
ret
source_compare_fnmsubdrtz_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubdrup:
cmp source_character_count, 10
jb source_compare_fnmsubdrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubdrup_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubdrup_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubdrup_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubdrup_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubdrup_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubdrup_failure
cmp byte ptr[rax+6], 100
jne source_compare_fnmsubdrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubdrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fnmsubdrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fnmsubdrup_failure
cmp source_character_count, 10
je source_compare_fnmsubdrup_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubdrup_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubdrup_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubdrup_success
source_compare_fnmsubdrup_failure:
mov al, 1
ret
source_compare_fnmsubdrup_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubq:
cmp source_character_count, 7
jb source_compare_fnmsubq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubq_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubq_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubq_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubq_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubq_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubq_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmsubq_failure
cmp source_character_count, 7
je source_compare_fnmsubq_success
cmp byte ptr[rax+7], 10
je source_compare_fnmsubq_success
cmp byte ptr[rax+7], 32
je source_compare_fnmsubq_success
cmp byte ptr[rax+7], 35
je source_compare_fnmsubq_success
source_compare_fnmsubq_failure:
mov al, 1
ret
source_compare_fnmsubq_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubqdyn:
cmp source_character_count, 10
jb source_compare_fnmsubqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubqdyn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubqdyn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubqdyn_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubqdyn_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubqdyn_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubqdyn_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmsubqdyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fnmsubqdyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fnmsubqdyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmsubqdyn_failure
cmp source_character_count, 10
je source_compare_fnmsubqdyn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubqdyn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubqdyn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubqdyn_success
source_compare_fnmsubqdyn_failure:
mov al, 1
ret
source_compare_fnmsubqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubqrdn:
cmp source_character_count, 10
jb source_compare_fnmsubqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubqrdn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubqrdn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubqrdn_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubqrdn_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubqrdn_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubqrdn_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmsubqrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubqrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fnmsubqrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmsubqrdn_failure
cmp source_character_count, 10
je source_compare_fnmsubqrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubqrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubqrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubqrdn_success
source_compare_fnmsubqrdn_failure:
mov al, 1
ret
source_compare_fnmsubqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubqrmm:
cmp source_character_count, 10
jb source_compare_fnmsubqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubqrmm_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubqrmm_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubqrmm_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubqrmm_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubqrmm_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubqrmm_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmsubqrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fnmsubqrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fnmsubqrmm_failure
cmp source_character_count, 10
je source_compare_fnmsubqrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubqrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubqrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubqrmm_success
source_compare_fnmsubqrmm_failure:
mov al, 1
ret
source_compare_fnmsubqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubqrtz:
cmp source_character_count, 10
jb source_compare_fnmsubqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubqrtz_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubqrtz_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubqrtz_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubqrtz_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubqrtz_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubqrtz_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmsubqrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubqrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fnmsubqrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fnmsubqrtz_failure
cmp source_character_count, 10
je source_compare_fnmsubqrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubqrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubqrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubqrtz_success
source_compare_fnmsubqrtz_failure:
mov al, 1
ret
source_compare_fnmsubqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubqrup:
cmp source_character_count, 10
jb source_compare_fnmsubqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubqrup_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubqrup_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubqrup_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubqrup_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubqrup_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubqrup_failure
cmp byte ptr[rax+6], 113
jne source_compare_fnmsubqrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubqrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fnmsubqrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fnmsubqrup_failure
cmp source_character_count, 10
je source_compare_fnmsubqrup_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubqrup_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubqrup_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubqrup_success
source_compare_fnmsubqrup_failure:
mov al, 1
ret
source_compare_fnmsubqrup_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubs:
cmp source_character_count, 7
jb source_compare_fnmsubs_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubs_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubs_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubs_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubs_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubs_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubs_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmsubs_failure
cmp source_character_count, 7
je source_compare_fnmsubs_success
cmp byte ptr[rax+7], 10
je source_compare_fnmsubs_success
cmp byte ptr[rax+7], 32
je source_compare_fnmsubs_success
cmp byte ptr[rax+7], 35
je source_compare_fnmsubs_success
source_compare_fnmsubs_failure:
mov al, 1
ret
source_compare_fnmsubs_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubsdyn:
cmp source_character_count, 10
jb source_compare_fnmsubsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubsdyn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubsdyn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubsdyn_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubsdyn_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubsdyn_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubsdyn_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmsubsdyn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fnmsubsdyn_failure
cmp byte ptr[rax+8], 121
jne source_compare_fnmsubsdyn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmsubsdyn_failure
cmp source_character_count, 10
je source_compare_fnmsubsdyn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubsdyn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubsdyn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubsdyn_success
source_compare_fnmsubsdyn_failure:
mov al, 1
ret
source_compare_fnmsubsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubsrdn:
cmp source_character_count, 10
jb source_compare_fnmsubsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubsrdn_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubsrdn_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubsrdn_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubsrdn_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubsrdn_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubsrdn_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmsubsrdn_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubsrdn_failure
cmp byte ptr[rax+8], 100
jne source_compare_fnmsubsrdn_failure
cmp byte ptr[rax+9], 110
jne source_compare_fnmsubsrdn_failure
cmp source_character_count, 10
je source_compare_fnmsubsrdn_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubsrdn_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubsrdn_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubsrdn_success
source_compare_fnmsubsrdn_failure:
mov al, 1
ret
source_compare_fnmsubsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubsrmm:
cmp source_character_count, 10
jb source_compare_fnmsubsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubsrmm_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubsrmm_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubsrmm_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubsrmm_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubsrmm_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubsrmm_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmsubsrmm_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubsrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fnmsubsrmm_failure
cmp byte ptr[rax+9], 109
jne source_compare_fnmsubsrmm_failure
cmp source_character_count, 10
je source_compare_fnmsubsrmm_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubsrmm_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubsrmm_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubsrmm_success
source_compare_fnmsubsrmm_failure:
mov al, 1
ret
source_compare_fnmsubsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubsrtz:
cmp source_character_count, 10
jb source_compare_fnmsubsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubsrtz_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubsrtz_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubsrtz_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubsrtz_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubsrtz_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubsrtz_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmsubsrtz_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubsrtz_failure
cmp byte ptr[rax+8], 116
jne source_compare_fnmsubsrtz_failure
cmp byte ptr[rax+9], 122
jne source_compare_fnmsubsrtz_failure
cmp source_character_count, 10
je source_compare_fnmsubsrtz_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubsrtz_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubsrtz_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubsrtz_success
source_compare_fnmsubsrtz_failure:
mov al, 1
ret
source_compare_fnmsubsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fnmsubsrup:
cmp source_character_count, 10
jb source_compare_fnmsubsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fnmsubsrup_failure
cmp byte ptr[rax+1], 110
jne source_compare_fnmsubsrup_failure
cmp byte ptr[rax+2], 109
jne source_compare_fnmsubsrup_failure
cmp byte ptr[rax+3], 115
jne source_compare_fnmsubsrup_failure
cmp byte ptr[rax+4], 117
jne source_compare_fnmsubsrup_failure
cmp byte ptr[rax+5], 98
jne source_compare_fnmsubsrup_failure
cmp byte ptr[rax+6], 115
jne source_compare_fnmsubsrup_failure
cmp byte ptr[rax+7], 114
jne source_compare_fnmsubsrup_failure
cmp byte ptr[rax+8], 117
jne source_compare_fnmsubsrup_failure
cmp byte ptr[rax+9], 112
jne source_compare_fnmsubsrup_failure
cmp source_character_count, 10
je source_compare_fnmsubsrup_success
cmp byte ptr[rax+10], 10
je source_compare_fnmsubsrup_success
cmp byte ptr[rax+10], 32
je source_compare_fnmsubsrup_success
cmp byte ptr[rax+10], 35
je source_compare_fnmsubsrup_success
source_compare_fnmsubsrup_failure:
mov al, 1
ret
source_compare_fnmsubsrup_success:
xor al, al
ret


; out
; al status
source_compare_fsd:
cmp source_character_count, 3
jb source_compare_fsd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsd_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsd_failure
cmp byte ptr[rax+2], 100
jne source_compare_fsd_failure
cmp source_character_count, 3
je source_compare_fsd_success
cmp byte ptr[rax+3], 10
je source_compare_fsd_success
cmp byte ptr[rax+3], 32
je source_compare_fsd_success
cmp byte ptr[rax+3], 35
je source_compare_fsd_success
source_compare_fsd_failure:
mov al, 1
ret
source_compare_fsd_success:
xor al, al
ret


; out
; al status
source_compare_fsgnjd:
cmp source_character_count, 6
jb source_compare_fsgnjd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsgnjd_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsgnjd_failure
cmp byte ptr[rax+2], 103
jne source_compare_fsgnjd_failure
cmp byte ptr[rax+3], 110
jne source_compare_fsgnjd_failure
cmp byte ptr[rax+4], 106
jne source_compare_fsgnjd_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsgnjd_failure
cmp source_character_count, 6
je source_compare_fsgnjd_success
cmp byte ptr[rax+6], 10
je source_compare_fsgnjd_success
cmp byte ptr[rax+6], 32
je source_compare_fsgnjd_success
cmp byte ptr[rax+6], 35
je source_compare_fsgnjd_success
source_compare_fsgnjd_failure:
mov al, 1
ret
source_compare_fsgnjd_success:
xor al, al
ret


; out
; al status
source_compare_fsgnjnd:
cmp source_character_count, 7
jb source_compare_fsgnjnd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsgnjnd_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsgnjnd_failure
cmp byte ptr[rax+2], 103
jne source_compare_fsgnjnd_failure
cmp byte ptr[rax+3], 110
jne source_compare_fsgnjnd_failure
cmp byte ptr[rax+4], 106
jne source_compare_fsgnjnd_failure
cmp byte ptr[rax+5], 110
jne source_compare_fsgnjnd_failure
cmp byte ptr[rax+6], 100
jne source_compare_fsgnjnd_failure
cmp source_character_count, 7
je source_compare_fsgnjnd_success
cmp byte ptr[rax+7], 10
je source_compare_fsgnjnd_success
cmp byte ptr[rax+7], 32
je source_compare_fsgnjnd_success
cmp byte ptr[rax+7], 35
je source_compare_fsgnjnd_success
source_compare_fsgnjnd_failure:
mov al, 1
ret
source_compare_fsgnjnd_success:
xor al, al
ret


; out
; al status
source_compare_fsgnjnq:
cmp source_character_count, 7
jb source_compare_fsgnjnq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsgnjnq_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsgnjnq_failure
cmp byte ptr[rax+2], 103
jne source_compare_fsgnjnq_failure
cmp byte ptr[rax+3], 110
jne source_compare_fsgnjnq_failure
cmp byte ptr[rax+4], 106
jne source_compare_fsgnjnq_failure
cmp byte ptr[rax+5], 110
jne source_compare_fsgnjnq_failure
cmp byte ptr[rax+6], 113
jne source_compare_fsgnjnq_failure
cmp source_character_count, 7
je source_compare_fsgnjnq_success
cmp byte ptr[rax+7], 10
je source_compare_fsgnjnq_success
cmp byte ptr[rax+7], 32
je source_compare_fsgnjnq_success
cmp byte ptr[rax+7], 35
je source_compare_fsgnjnq_success
source_compare_fsgnjnq_failure:
mov al, 1
ret
source_compare_fsgnjnq_success:
xor al, al
ret


; out
; al status
source_compare_fsgnjns:
cmp source_character_count, 7
jb source_compare_fsgnjns_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsgnjns_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsgnjns_failure
cmp byte ptr[rax+2], 103
jne source_compare_fsgnjns_failure
cmp byte ptr[rax+3], 110
jne source_compare_fsgnjns_failure
cmp byte ptr[rax+4], 106
jne source_compare_fsgnjns_failure
cmp byte ptr[rax+5], 110
jne source_compare_fsgnjns_failure
cmp byte ptr[rax+6], 115
jne source_compare_fsgnjns_failure
cmp source_character_count, 7
je source_compare_fsgnjns_success
cmp byte ptr[rax+7], 10
je source_compare_fsgnjns_success
cmp byte ptr[rax+7], 32
je source_compare_fsgnjns_success
cmp byte ptr[rax+7], 35
je source_compare_fsgnjns_success
source_compare_fsgnjns_failure:
mov al, 1
ret
source_compare_fsgnjns_success:
xor al, al
ret


; out
; al status
source_compare_fsgnjq:
cmp source_character_count, 6
jb source_compare_fsgnjq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsgnjq_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsgnjq_failure
cmp byte ptr[rax+2], 103
jne source_compare_fsgnjq_failure
cmp byte ptr[rax+3], 110
jne source_compare_fsgnjq_failure
cmp byte ptr[rax+4], 106
jne source_compare_fsgnjq_failure
cmp byte ptr[rax+5], 113
jne source_compare_fsgnjq_failure
cmp source_character_count, 6
je source_compare_fsgnjq_success
cmp byte ptr[rax+6], 10
je source_compare_fsgnjq_success
cmp byte ptr[rax+6], 32
je source_compare_fsgnjq_success
cmp byte ptr[rax+6], 35
je source_compare_fsgnjq_success
source_compare_fsgnjq_failure:
mov al, 1
ret
source_compare_fsgnjq_success:
xor al, al
ret


; out
; al status
source_compare_fsgnjs:
cmp source_character_count, 6
jb source_compare_fsgnjs_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsgnjs_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsgnjs_failure
cmp byte ptr[rax+2], 103
jne source_compare_fsgnjs_failure
cmp byte ptr[rax+3], 110
jne source_compare_fsgnjs_failure
cmp byte ptr[rax+4], 106
jne source_compare_fsgnjs_failure
cmp byte ptr[rax+5], 115
jne source_compare_fsgnjs_failure
cmp source_character_count, 6
je source_compare_fsgnjs_success
cmp byte ptr[rax+6], 10
je source_compare_fsgnjs_success
cmp byte ptr[rax+6], 32
je source_compare_fsgnjs_success
cmp byte ptr[rax+6], 35
je source_compare_fsgnjs_success
source_compare_fsgnjs_failure:
mov al, 1
ret
source_compare_fsgnjs_success:
xor al, al
ret


; out
; al status
source_compare_fsgnjxd:
cmp source_character_count, 7
jb source_compare_fsgnjxd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsgnjxd_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsgnjxd_failure
cmp byte ptr[rax+2], 103
jne source_compare_fsgnjxd_failure
cmp byte ptr[rax+3], 110
jne source_compare_fsgnjxd_failure
cmp byte ptr[rax+4], 106
jne source_compare_fsgnjxd_failure
cmp byte ptr[rax+5], 120
jne source_compare_fsgnjxd_failure
cmp byte ptr[rax+6], 100
jne source_compare_fsgnjxd_failure
cmp source_character_count, 7
je source_compare_fsgnjxd_success
cmp byte ptr[rax+7], 10
je source_compare_fsgnjxd_success
cmp byte ptr[rax+7], 32
je source_compare_fsgnjxd_success
cmp byte ptr[rax+7], 35
je source_compare_fsgnjxd_success
source_compare_fsgnjxd_failure:
mov al, 1
ret
source_compare_fsgnjxd_success:
xor al, al
ret


; out
; al status
source_compare_fsgnjxq:
cmp source_character_count, 7
jb source_compare_fsgnjxq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsgnjxq_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsgnjxq_failure
cmp byte ptr[rax+2], 103
jne source_compare_fsgnjxq_failure
cmp byte ptr[rax+3], 110
jne source_compare_fsgnjxq_failure
cmp byte ptr[rax+4], 106
jne source_compare_fsgnjxq_failure
cmp byte ptr[rax+5], 120
jne source_compare_fsgnjxq_failure
cmp byte ptr[rax+6], 113
jne source_compare_fsgnjxq_failure
cmp source_character_count, 7
je source_compare_fsgnjxq_success
cmp byte ptr[rax+7], 10
je source_compare_fsgnjxq_success
cmp byte ptr[rax+7], 32
je source_compare_fsgnjxq_success
cmp byte ptr[rax+7], 35
je source_compare_fsgnjxq_success
source_compare_fsgnjxq_failure:
mov al, 1
ret
source_compare_fsgnjxq_success:
xor al, al
ret


; out
; al status
source_compare_fsgnjxs:
cmp source_character_count, 7
jb source_compare_fsgnjxs_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsgnjxs_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsgnjxs_failure
cmp byte ptr[rax+2], 103
jne source_compare_fsgnjxs_failure
cmp byte ptr[rax+3], 110
jne source_compare_fsgnjxs_failure
cmp byte ptr[rax+4], 106
jne source_compare_fsgnjxs_failure
cmp byte ptr[rax+5], 120
jne source_compare_fsgnjxs_failure
cmp byte ptr[rax+6], 115
jne source_compare_fsgnjxs_failure
cmp source_character_count, 7
je source_compare_fsgnjxs_success
cmp byte ptr[rax+7], 10
je source_compare_fsgnjxs_success
cmp byte ptr[rax+7], 32
je source_compare_fsgnjxs_success
cmp byte ptr[rax+7], 35
je source_compare_fsgnjxs_success
source_compare_fsgnjxs_failure:
mov al, 1
ret
source_compare_fsgnjxs_success:
xor al, al
ret


; out
; al status
source_compare_fsq:
cmp source_character_count, 3
jb source_compare_fsq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsq_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsq_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsq_failure
cmp source_character_count, 3
je source_compare_fsq_success
cmp byte ptr[rax+3], 10
je source_compare_fsq_success
cmp byte ptr[rax+3], 32
je source_compare_fsq_success
cmp byte ptr[rax+3], 35
je source_compare_fsq_success
source_compare_fsq_failure:
mov al, 1
ret
source_compare_fsq_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtd:
cmp source_character_count, 6
jb source_compare_fsqrtd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtd_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtd_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtd_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtd_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtd_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsqrtd_failure
cmp source_character_count, 6
je source_compare_fsqrtd_success
cmp byte ptr[rax+6], 10
je source_compare_fsqrtd_success
cmp byte ptr[rax+6], 32
je source_compare_fsqrtd_success
cmp byte ptr[rax+6], 35
je source_compare_fsqrtd_success
source_compare_fsqrtd_failure:
mov al, 1
ret
source_compare_fsqrtd_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtddyn:
cmp source_character_count, 9
jb source_compare_fsqrtddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtddyn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtddyn_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtddyn_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtddyn_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsqrtddyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fsqrtddyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fsqrtddyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fsqrtddyn_failure
cmp source_character_count, 9
je source_compare_fsqrtddyn_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtddyn_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtddyn_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtddyn_success
source_compare_fsqrtddyn_failure:
mov al, 1
ret
source_compare_fsqrtddyn_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtdrdn:
cmp source_character_count, 9
jb source_compare_fsqrtdrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtdrdn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtdrdn_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtdrdn_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtdrdn_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtdrdn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsqrtdrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtdrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fsqrtdrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fsqrtdrdn_failure
cmp source_character_count, 9
je source_compare_fsqrtdrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtdrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtdrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtdrdn_success
source_compare_fsqrtdrdn_failure:
mov al, 1
ret
source_compare_fsqrtdrdn_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtdrmm:
cmp source_character_count, 9
jb source_compare_fsqrtdrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtdrmm_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtdrmm_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtdrmm_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtdrmm_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtdrmm_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsqrtdrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtdrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fsqrtdrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fsqrtdrmm_failure
cmp source_character_count, 9
je source_compare_fsqrtdrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtdrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtdrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtdrmm_success
source_compare_fsqrtdrmm_failure:
mov al, 1
ret
source_compare_fsqrtdrmm_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtdrtz:
cmp source_character_count, 9
jb source_compare_fsqrtdrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtdrtz_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtdrtz_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtdrtz_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtdrtz_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtdrtz_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsqrtdrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtdrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fsqrtdrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fsqrtdrtz_failure
cmp source_character_count, 9
je source_compare_fsqrtdrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtdrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtdrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtdrtz_success
source_compare_fsqrtdrtz_failure:
mov al, 1
ret
source_compare_fsqrtdrtz_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtdrup:
cmp source_character_count, 9
jb source_compare_fsqrtdrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtdrup_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtdrup_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtdrup_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtdrup_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtdrup_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsqrtdrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtdrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fsqrtdrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fsqrtdrup_failure
cmp source_character_count, 9
je source_compare_fsqrtdrup_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtdrup_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtdrup_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtdrup_success
source_compare_fsqrtdrup_failure:
mov al, 1
ret
source_compare_fsqrtdrup_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtq:
cmp source_character_count, 6
jb source_compare_fsqrtq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtq_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtq_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtq_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtq_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtq_failure
cmp byte ptr[rax+5], 113
jne source_compare_fsqrtq_failure
cmp source_character_count, 6
je source_compare_fsqrtq_success
cmp byte ptr[rax+6], 10
je source_compare_fsqrtq_success
cmp byte ptr[rax+6], 32
je source_compare_fsqrtq_success
cmp byte ptr[rax+6], 35
je source_compare_fsqrtq_success
source_compare_fsqrtq_failure:
mov al, 1
ret
source_compare_fsqrtq_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtqdyn:
cmp source_character_count, 9
jb source_compare_fsqrtqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtqdyn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtqdyn_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtqdyn_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtqdyn_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtqdyn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fsqrtqdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fsqrtqdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fsqrtqdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fsqrtqdyn_failure
cmp source_character_count, 9
je source_compare_fsqrtqdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtqdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtqdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtqdyn_success
source_compare_fsqrtqdyn_failure:
mov al, 1
ret
source_compare_fsqrtqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtqrdn:
cmp source_character_count, 9
jb source_compare_fsqrtqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtqrdn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtqrdn_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtqrdn_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtqrdn_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtqrdn_failure
cmp byte ptr[rax+5], 113
jne source_compare_fsqrtqrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtqrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fsqrtqrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fsqrtqrdn_failure
cmp source_character_count, 9
je source_compare_fsqrtqrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtqrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtqrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtqrdn_success
source_compare_fsqrtqrdn_failure:
mov al, 1
ret
source_compare_fsqrtqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtqrmm:
cmp source_character_count, 9
jb source_compare_fsqrtqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtqrmm_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtqrmm_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtqrmm_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtqrmm_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtqrmm_failure
cmp byte ptr[rax+5], 113
jne source_compare_fsqrtqrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fsqrtqrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fsqrtqrmm_failure
cmp source_character_count, 9
je source_compare_fsqrtqrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtqrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtqrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtqrmm_success
source_compare_fsqrtqrmm_failure:
mov al, 1
ret
source_compare_fsqrtqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtqrtz:
cmp source_character_count, 9
jb source_compare_fsqrtqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtqrtz_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtqrtz_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtqrtz_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtqrtz_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtqrtz_failure
cmp byte ptr[rax+5], 113
jne source_compare_fsqrtqrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtqrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fsqrtqrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fsqrtqrtz_failure
cmp source_character_count, 9
je source_compare_fsqrtqrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtqrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtqrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtqrtz_success
source_compare_fsqrtqrtz_failure:
mov al, 1
ret
source_compare_fsqrtqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtqrup:
cmp source_character_count, 9
jb source_compare_fsqrtqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtqrup_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtqrup_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtqrup_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtqrup_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtqrup_failure
cmp byte ptr[rax+5], 113
jne source_compare_fsqrtqrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtqrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fsqrtqrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fsqrtqrup_failure
cmp source_character_count, 9
je source_compare_fsqrtqrup_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtqrup_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtqrup_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtqrup_success
source_compare_fsqrtqrup_failure:
mov al, 1
ret
source_compare_fsqrtqrup_success:
xor al, al
ret


; out
; al status
source_compare_fsqrts:
cmp source_character_count, 6
jb source_compare_fsqrts_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrts_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrts_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrts_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrts_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrts_failure
cmp byte ptr[rax+5], 115
jne source_compare_fsqrts_failure
cmp source_character_count, 6
je source_compare_fsqrts_success
cmp byte ptr[rax+6], 10
je source_compare_fsqrts_success
cmp byte ptr[rax+6], 32
je source_compare_fsqrts_success
cmp byte ptr[rax+6], 35
je source_compare_fsqrts_success
source_compare_fsqrts_failure:
mov al, 1
ret
source_compare_fsqrts_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtsdyn:
cmp source_character_count, 9
jb source_compare_fsqrtsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtsdyn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtsdyn_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtsdyn_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtsdyn_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtsdyn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fsqrtsdyn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fsqrtsdyn_failure
cmp byte ptr[rax+7], 121
jne source_compare_fsqrtsdyn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fsqrtsdyn_failure
cmp source_character_count, 9
je source_compare_fsqrtsdyn_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtsdyn_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtsdyn_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtsdyn_success
source_compare_fsqrtsdyn_failure:
mov al, 1
ret
source_compare_fsqrtsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtsrdn:
cmp source_character_count, 9
jb source_compare_fsqrtsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtsrdn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtsrdn_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtsrdn_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtsrdn_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtsrdn_failure
cmp byte ptr[rax+5], 115
jne source_compare_fsqrtsrdn_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtsrdn_failure
cmp byte ptr[rax+7], 100
jne source_compare_fsqrtsrdn_failure
cmp byte ptr[rax+8], 110
jne source_compare_fsqrtsrdn_failure
cmp source_character_count, 9
je source_compare_fsqrtsrdn_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtsrdn_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtsrdn_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtsrdn_success
source_compare_fsqrtsrdn_failure:
mov al, 1
ret
source_compare_fsqrtsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtsrmm:
cmp source_character_count, 9
jb source_compare_fsqrtsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtsrmm_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtsrmm_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtsrmm_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtsrmm_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtsrmm_failure
cmp byte ptr[rax+5], 115
jne source_compare_fsqrtsrmm_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fsqrtsrmm_failure
cmp byte ptr[rax+8], 109
jne source_compare_fsqrtsrmm_failure
cmp source_character_count, 9
je source_compare_fsqrtsrmm_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtsrmm_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtsrmm_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtsrmm_success
source_compare_fsqrtsrmm_failure:
mov al, 1
ret
source_compare_fsqrtsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtsrtz:
cmp source_character_count, 9
jb source_compare_fsqrtsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtsrtz_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtsrtz_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtsrtz_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtsrtz_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtsrtz_failure
cmp byte ptr[rax+5], 115
jne source_compare_fsqrtsrtz_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtsrtz_failure
cmp byte ptr[rax+7], 116
jne source_compare_fsqrtsrtz_failure
cmp byte ptr[rax+8], 122
jne source_compare_fsqrtsrtz_failure
cmp source_character_count, 9
je source_compare_fsqrtsrtz_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtsrtz_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtsrtz_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtsrtz_success
source_compare_fsqrtsrtz_failure:
mov al, 1
ret
source_compare_fsqrtsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fsqrtsrup:
cmp source_character_count, 9
jb source_compare_fsqrtsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsqrtsrup_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsqrtsrup_failure
cmp byte ptr[rax+2], 113
jne source_compare_fsqrtsrup_failure
cmp byte ptr[rax+3], 114
jne source_compare_fsqrtsrup_failure
cmp byte ptr[rax+4], 116
jne source_compare_fsqrtsrup_failure
cmp byte ptr[rax+5], 115
jne source_compare_fsqrtsrup_failure
cmp byte ptr[rax+6], 114
jne source_compare_fsqrtsrup_failure
cmp byte ptr[rax+7], 117
jne source_compare_fsqrtsrup_failure
cmp byte ptr[rax+8], 112
jne source_compare_fsqrtsrup_failure
cmp source_character_count, 9
je source_compare_fsqrtsrup_success
cmp byte ptr[rax+9], 10
je source_compare_fsqrtsrup_success
cmp byte ptr[rax+9], 32
je source_compare_fsqrtsrup_success
cmp byte ptr[rax+9], 35
je source_compare_fsqrtsrup_success
source_compare_fsqrtsrup_failure:
mov al, 1
ret
source_compare_fsqrtsrup_success:
xor al, al
ret


; out
; al status
source_compare_fsubd:
cmp source_character_count, 5
jb source_compare_fsubd_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubd_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubd_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubd_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubd_failure
cmp byte ptr[rax+4], 100
jne source_compare_fsubd_failure
cmp source_character_count, 5
je source_compare_fsubd_success
cmp byte ptr[rax+5], 10
je source_compare_fsubd_success
cmp byte ptr[rax+5], 32
je source_compare_fsubd_success
cmp byte ptr[rax+5], 35
je source_compare_fsubd_success
source_compare_fsubd_failure:
mov al, 1
ret
source_compare_fsubd_success:
xor al, al
ret


; out
; al status
source_compare_fsubddyn:
cmp source_character_count, 8
jb source_compare_fsubddyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubddyn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubddyn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubddyn_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubddyn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fsubddyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsubddyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_fsubddyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fsubddyn_failure
cmp source_character_count, 8
je source_compare_fsubddyn_success
cmp byte ptr[rax+8], 10
je source_compare_fsubddyn_success
cmp byte ptr[rax+8], 32
je source_compare_fsubddyn_success
cmp byte ptr[rax+8], 35
je source_compare_fsubddyn_success
source_compare_fsubddyn_failure:
mov al, 1
ret
source_compare_fsubddyn_success:
xor al, al
ret


; out
; al status
source_compare_fsubdrdn:
cmp source_character_count, 8
jb source_compare_fsubdrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubdrdn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubdrdn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubdrdn_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubdrdn_failure
cmp byte ptr[rax+4], 100
jne source_compare_fsubdrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubdrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fsubdrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fsubdrdn_failure
cmp source_character_count, 8
je source_compare_fsubdrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fsubdrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fsubdrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fsubdrdn_success
source_compare_fsubdrdn_failure:
mov al, 1
ret
source_compare_fsubdrdn_success:
xor al, al
ret


; out
; al status
source_compare_fsubdrmm:
cmp source_character_count, 8
jb source_compare_fsubdrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubdrmm_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubdrmm_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubdrmm_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubdrmm_failure
cmp byte ptr[rax+4], 100
jne source_compare_fsubdrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubdrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fsubdrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fsubdrmm_failure
cmp source_character_count, 8
je source_compare_fsubdrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fsubdrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fsubdrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fsubdrmm_success
source_compare_fsubdrmm_failure:
mov al, 1
ret
source_compare_fsubdrmm_success:
xor al, al
ret


; out
; al status
source_compare_fsubdrtz:
cmp source_character_count, 8
jb source_compare_fsubdrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubdrtz_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubdrtz_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubdrtz_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubdrtz_failure
cmp byte ptr[rax+4], 100
jne source_compare_fsubdrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubdrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fsubdrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fsubdrtz_failure
cmp source_character_count, 8
je source_compare_fsubdrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fsubdrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fsubdrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fsubdrtz_success
source_compare_fsubdrtz_failure:
mov al, 1
ret
source_compare_fsubdrtz_success:
xor al, al
ret


; out
; al status
source_compare_fsubdrup:
cmp source_character_count, 8
jb source_compare_fsubdrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubdrup_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubdrup_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubdrup_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubdrup_failure
cmp byte ptr[rax+4], 100
jne source_compare_fsubdrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubdrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fsubdrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fsubdrup_failure
cmp source_character_count, 8
je source_compare_fsubdrup_success
cmp byte ptr[rax+8], 10
je source_compare_fsubdrup_success
cmp byte ptr[rax+8], 32
je source_compare_fsubdrup_success
cmp byte ptr[rax+8], 35
je source_compare_fsubdrup_success
source_compare_fsubdrup_failure:
mov al, 1
ret
source_compare_fsubdrup_success:
xor al, al
ret


; out
; al status
source_compare_fsubq:
cmp source_character_count, 5
jb source_compare_fsubq_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubq_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubq_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubq_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubq_failure
cmp byte ptr[rax+4], 113
jne source_compare_fsubq_failure
cmp source_character_count, 5
je source_compare_fsubq_success
cmp byte ptr[rax+5], 10
je source_compare_fsubq_success
cmp byte ptr[rax+5], 32
je source_compare_fsubq_success
cmp byte ptr[rax+5], 35
je source_compare_fsubq_success
source_compare_fsubq_failure:
mov al, 1
ret
source_compare_fsubq_success:
xor al, al
ret


; out
; al status
source_compare_fsubqdyn:
cmp source_character_count, 8
jb source_compare_fsubqdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubqdyn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubqdyn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubqdyn_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubqdyn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fsubqdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsubqdyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_fsubqdyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fsubqdyn_failure
cmp source_character_count, 8
jb source_compare_fsubqdyn_success
cmp byte ptr[rax+8], 10
je source_compare_fsubqdyn_success
cmp byte ptr[rax+8], 32
je source_compare_fsubqdyn_success
cmp byte ptr[rax+8], 35
je source_compare_fsubqdyn_success
source_compare_fsubqdyn_failure:
mov al, 1
ret
source_compare_fsubqdyn_success:
xor al, al
ret


; out
; al status
source_compare_fsubqrdn:
cmp source_character_count, 8
jb source_compare_fsubqrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubqrdn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubqrdn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubqrdn_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubqrdn_failure
cmp byte ptr[rax+4], 113
jne source_compare_fsubqrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubqrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fsubqrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fsubqrdn_failure
cmp source_character_count, 8
je source_compare_fsubqrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fsubqrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fsubqrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fsubqrdn_success
source_compare_fsubqrdn_failure:
mov al, 1
ret
source_compare_fsubqrdn_success:
xor al, al
ret


; out
; al status
source_compare_fsubqrmm:
cmp source_character_count, 8
jb source_compare_fsubqrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubqrmm_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubqrmm_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubqrmm_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubqrmm_failure
cmp byte ptr[rax+4], 113
jne source_compare_fsubqrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubqrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fsubqrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fsubqrmm_failure
cmp source_character_count, 8
je source_compare_fsubqrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fsubqrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fsubqrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fsubqrmm_success
source_compare_fsubqrmm_failure:
mov al, 1
ret
source_compare_fsubqrmm_success:
xor al, al
ret


; out
; al status
source_compare_fsubqrtz:
cmp source_character_count, 8
jb source_compare_fsubqrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubqrtz_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubqrtz_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubqrtz_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubqrtz_failure
cmp byte ptr[rax+4], 113
jne source_compare_fsubqrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubqrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fsubqrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fsubqrtz_failure
cmp source_character_count, 8
je source_compare_fsubqrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fsubqrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fsubqrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fsubqrtz_success
source_compare_fsubqrtz_failure:
mov al, 1
ret
source_compare_fsubqrtz_success:
xor al, al
ret


; out
; al status
source_compare_fsubqrup:
cmp source_character_count, 8
jb source_compare_fsubqrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubqrup_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubqrup_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubqrup_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubqrup_failure
cmp byte ptr[rax+4], 113
jne source_compare_fsubqrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubqrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fsubqrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fsubqrup_failure
cmp source_character_count, 8
je source_compare_fsubqrup_success
cmp byte ptr[rax+8], 10
je source_compare_fsubqrup_success
cmp byte ptr[rax+8], 32
je source_compare_fsubqrup_success
cmp byte ptr[rax+8], 35
je source_compare_fsubqrup_success
source_compare_fsubqrup_failure:
mov al, 1
ret
source_compare_fsubqrup_success:
xor al, al
ret


; out
; al status
source_compare_fsubs:
cmp source_character_count, 5
jb source_compare_fsubs_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubs_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubs_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubs_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubs_failure
cmp byte ptr[rax+4], 115
jne source_compare_fsubs_failure
cmp source_character_count, 5
je source_compare_fsubs_success
cmp byte ptr[rax+5], 10
je source_compare_fsubs_success
cmp byte ptr[rax+5], 32
je source_compare_fsubs_success
cmp byte ptr[rax+5], 35
je source_compare_fsubs_success
source_compare_fsubs_failure:
mov al, 1
ret
source_compare_fsubs_success:
xor al, al
ret


; out
; al status
source_compare_fsubsdyn:
cmp source_character_count, 8
jb source_compare_fsubsdyn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubsdyn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubsdyn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubsdyn_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubsdyn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fsubsdyn_failure
cmp byte ptr[rax+5], 100
jne source_compare_fsubsdyn_failure
cmp byte ptr[rax+6], 121
jne source_compare_fsubsdyn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fsubsdyn_failure
cmp source_character_count, 8
je source_compare_fsubsdyn_success
cmp byte ptr[rax+8], 10
je source_compare_fsubsdyn_success
cmp byte ptr[rax+8], 32
je source_compare_fsubsdyn_success
cmp byte ptr[rax+8], 35
je source_compare_fsubsdyn_success
source_compare_fsubsdyn_failure:
mov al, 1
ret
source_compare_fsubsdyn_success:
xor al, al
ret


; out
; al status
source_compare_fsubsrdn:
cmp source_character_count, 8
jb source_compare_fsubsrdn_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubsrdn_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubsrdn_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubsrdn_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubsrdn_failure
cmp byte ptr[rax+4], 115
jne source_compare_fsubsrdn_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubsrdn_failure
cmp byte ptr[rax+6], 100
jne source_compare_fsubsrdn_failure
cmp byte ptr[rax+7], 110
jne source_compare_fsubsrdn_failure
cmp source_character_count, 8
je source_compare_fsubsrdn_success
cmp byte ptr[rax+8], 10
je source_compare_fsubsrdn_success
cmp byte ptr[rax+8], 32
je source_compare_fsubsrdn_success
cmp byte ptr[rax+8], 35
je source_compare_fsubsrdn_success
source_compare_fsubsrdn_failure:
mov al, 1
ret
source_compare_fsubsrdn_success:
xor al, al
ret


; out
; al status
source_compare_fsubsrmm:
cmp source_character_count, 8
jb source_compare_fsubsrmm_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubsrmm_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubsrmm_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubsrmm_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubsrmm_failure
cmp byte ptr[rax+4], 115
jne source_compare_fsubsrmm_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubsrmm_failure
cmp byte ptr[rax+6], 109
jne source_compare_fsubsrmm_failure
cmp byte ptr[rax+7], 109
jne source_compare_fsubsrmm_failure
cmp source_character_count, 8
je source_compare_fsubsrmm_success
cmp byte ptr[rax+8], 10
je source_compare_fsubsrmm_success
cmp byte ptr[rax+8], 32
je source_compare_fsubsrmm_success
cmp byte ptr[rax+8], 35
je source_compare_fsubsrmm_success
source_compare_fsubsrmm_failure:
mov al, 1
ret
source_compare_fsubsrmm_success:
xor al, al
ret


; out
; al status
source_compare_fsubsrtz:
cmp source_character_count, 8
jb source_compare_fsubsrtz_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubsrtz_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubsrtz_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubsrtz_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubsrtz_failure
cmp byte ptr[rax+4], 115
jne source_compare_fsubsrtz_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubsrtz_failure
cmp byte ptr[rax+6], 116
jne source_compare_fsubsrtz_failure
cmp byte ptr[rax+7], 122
jne source_compare_fsubsrtz_failure
cmp source_character_count, 8
je source_compare_fsubsrtz_success
cmp byte ptr[rax+8], 10
je source_compare_fsubsrtz_success
cmp byte ptr[rax+8], 32
je source_compare_fsubsrtz_success
cmp byte ptr[rax+8], 35
je source_compare_fsubsrtz_success
source_compare_fsubsrtz_failure:
mov al, 1
ret
source_compare_fsubsrtz_success:
xor al, al
ret


; out
; al status
source_compare_fsubsrup:
cmp source_character_count, 8
jb source_compare_fsubsrup_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsubsrup_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsubsrup_failure
cmp byte ptr[rax+2], 117
jne source_compare_fsubsrup_failure
cmp byte ptr[rax+3], 98
jne source_compare_fsubsrup_failure
cmp byte ptr[rax+4], 115
jne source_compare_fsubsrup_failure
cmp byte ptr[rax+5], 114
jne source_compare_fsubsrup_failure
cmp byte ptr[rax+6], 117
jne source_compare_fsubsrup_failure
cmp byte ptr[rax+7], 112
jne source_compare_fsubsrup_failure
cmp source_character_count, 8
je source_compare_fsubsrup_success
cmp byte ptr[rax+8], 10
je source_compare_fsubsrup_success
cmp byte ptr[rax+8], 32
je source_compare_fsubsrup_success
cmp byte ptr[rax+8], 35
je source_compare_fsubsrup_success
source_compare_fsubsrup_failure:
mov al, 1
ret
source_compare_fsubsrup_success:
xor al, al
ret


; out
; al status
source_compare_fsw:
cmp source_character_count, 3
jb source_compare_fsw_failure
mov rax, source_character_address
cmp byte ptr[rax], 102
jne source_compare_fsw_failure
cmp byte ptr[rax+1], 115
jne source_compare_fsw_failure
cmp byte ptr[rax+2], 119
jne source_compare_fsw_failure
cmp source_character_count, 3
je source_compare_fsw_success
cmp byte ptr[rax+3], 10
je source_compare_fsw_success
cmp byte ptr[rax+3], 32
je source_compare_fsw_success
cmp byte ptr[rax+3], 35
je source_compare_fsw_success
source_compare_fsw_failure:
mov al, 1
ret
source_compare_fsw_success:
xor al, al
ret


; out
; al status
source_compare_halfword:
cmp source_character_count, 8
jb source_compare_halfword_failure
mov rax, source_character_address
cmp byte ptr[rax], 104
jne source_compare_halfword_failure
cmp byte ptr[rax+1], 97
jne source_compare_halfword_failure
cmp byte ptr[rax+2], 108
jne source_compare_halfword_failure
cmp byte ptr[rax+3], 102
jne source_compare_halfword_failure
cmp byte ptr[rax+4], 119
jne source_compare_halfword_failure
cmp byte ptr[rax+5], 111
jne source_compare_halfword_failure
cmp byte ptr[rax+6], 114
jne source_compare_halfword_failure
cmp byte ptr[rax+7], 100
jne source_compare_halfword_failure
cmp source_character_count, 8
je source_compare_halfword_success
cmp byte ptr[rax+8], 10
je source_compare_halfword_success
cmp byte ptr[rax+8], 32
je source_compare_halfword_success
cmp byte ptr[rax+8], 35
je source_compare_halfword_success
source_compare_halfword_failure:
mov al, 1
ret
source_compare_halfword_success:
xor al, al
ret


; out
; al status
source_compare_include:
cmp source_character_count, 7
jb source_compare_include_failure
mov rax, source_character_address
cmp byte ptr[rax], 105
jne source_compare_include_failure
cmp byte ptr[rax+1], 110
jne source_compare_include_failure
cmp byte ptr[rax+2], 99
jne source_compare_include_failure
cmp byte ptr[rax+3], 108
jne source_compare_include_failure
cmp byte ptr[rax+4], 117
jne source_compare_include_failure
cmp byte ptr[rax+5], 100
jne source_compare_include_failure
cmp byte ptr[rax+6], 101
jne source_compare_include_failure
cmp source_character_count, 7
je source_compare_include_success
cmp byte ptr[rax+7], 10
je source_compare_include_success
cmp byte ptr[rax+7], 32
je source_compare_include_success
cmp byte ptr[rax+7], 35
je source_compare_include_success
source_compare_include_failure:
mov al, 1
ret
source_compare_include_success:
xor al, al
ret


; out
; al status
source_compare_jal:
cmp source_character_count, 3
jb source_compare_jal_failure
mov rax, source_character_address
cmp byte ptr[rax], 106
jne source_compare_jal_failure
cmp byte ptr[rax+1], 97
jne source_compare_jal_failure
cmp byte ptr[rax+2], 108
jne source_compare_jal_failure
cmp source_character_count, 3
je source_compare_jal_success
cmp byte ptr[rax+3], 10
je source_compare_jal_success
cmp byte ptr[rax+3], 32
je source_compare_jal_success
cmp byte ptr[rax+3], 35
je source_compare_jal_success
source_compare_jal_failure:
mov al, 1
ret
source_compare_jal_success:
xor al, al
ret


; out
; al status
source_compare_jalr:
cmp source_character_count, 4
jb source_compare_jalr_failure
mov rax, source_character_address
cmp byte ptr[rax], 106
jne source_compare_jalr_failure
cmp byte ptr[rax+1], 97
jne source_compare_jalr_failure
cmp byte ptr[rax+2], 108
jne source_compare_jalr_failure
cmp byte ptr[rax+3], 114
jne source_compare_jalr_failure
cmp source_character_count, 4
je source_compare_jalr_success
cmp byte ptr[rax+4], 10
je source_compare_jalr_success
cmp byte ptr[rax+4], 32
je source_compare_jalr_success
cmp byte ptr[rax+4], 35
je source_compare_jalr_success
source_compare_jalr_failure:
mov al, 1
ret
source_compare_jalr_success:
xor al, al
ret


; out
; al status
source_compare_label:
cmp source_character_count, 5
jb source_compare_label_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_label_failure
cmp byte ptr[rax+1], 97
jne source_compare_label_failure
cmp byte ptr[rax+2], 98
jne source_compare_label_failure
cmp byte ptr[rax+3], 101
jne source_compare_label_failure
cmp byte ptr[rax+4], 108
jne source_compare_label_failure
cmp source_character_count, 5
je source_compare_label_success
cmp byte ptr[rax+5], 10
je source_compare_label_success
cmp byte ptr[rax+5], 32
je source_compare_label_success
cmp byte ptr[rax+5], 35
je source_compare_label_success
source_compare_label_failure:
mov al, 1
ret
source_compare_label_success:
xor al, al
ret


; out
; al status
source_compare_lb:
cmp source_character_count, 2
jb source_compare_lb_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lb_failure
cmp byte ptr[rax+1], 98
jne source_compare_lb_failure
cmp source_character_count, 2
je source_compare_lb_success
cmp byte ptr[rax+2], 10
je source_compare_lb_success
cmp byte ptr[rax+2], 32
je source_compare_lb_success
cmp byte ptr[rax+2], 35
je source_compare_lb_success
source_compare_lb_failure:
mov al, 1
ret
source_compare_lb_success:
xor al, al
ret


; out
; al status
source_compare_lbu:
cmp source_character_count, 3
jb source_compare_lbu_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lbu_failure
cmp byte ptr[rax+1], 98
jne source_compare_lbu_failure
cmp byte ptr[rax+2], 117
jne source_compare_lbu_failure
cmp source_character_count, 3
je source_compare_lbu_success
cmp byte ptr[rax+3], 10
je source_compare_lbu_success
cmp byte ptr[rax+3], 32
je source_compare_lbu_success
cmp byte ptr[rax+3], 35
je source_compare_lbu_success
source_compare_lbu_failure:
mov al, 1
ret
source_compare_lbu_success:
xor al, al
ret


; out
; al status
source_compare_lc:
cmp source_character_count, 2
jb source_compare_lc_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lc_failure
cmp byte ptr[rax+1], 99
jne source_compare_lc_failure
cmp source_character_count, 2
je source_compare_lc_success
cmp byte ptr[rax+2], 10
je source_compare_lc_success
cmp byte ptr[rax+2], 32
je source_compare_lc_success
cmp byte ptr[rax+2], 35
je source_compare_lc_success
source_compare_lc_failure:
mov al, 1
ret
source_compare_lc_success:
xor al, al
ret


; out
; al status
source_compare_ld:
cmp source_character_count, 2
jb source_compare_ld_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_ld_failure
cmp byte ptr[rax+1], 100
jne source_compare_ld_failure
cmp source_character_count, 2
je source_compare_ld_success
cmp byte ptr[rax+2], 10
je source_compare_ld_success
cmp byte ptr[rax+2], 32
je source_compare_ld_success
cmp byte ptr[rax+2], 35
je source_compare_ld_success
source_compare_ld_failure:
mov al, 1
ret
source_compare_ld_success:
xor al, al
ret


; out
; al status
source_compare_lh:
cmp source_character_count, 2
jb source_compare_lh_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lh_failure
cmp byte ptr[rax+1], 104
jne source_compare_lh_failure
cmp source_character_count, 2
je source_compare_lh_success
cmp byte ptr[rax+2], 10
je source_compare_lh_success
cmp byte ptr[rax+2], 32
je source_compare_lh_success
cmp byte ptr[rax+2], 35
je source_compare_lh_success
source_compare_lh_failure:
mov al, 1
ret
source_compare_lh_success:
xor al, al
ret


; out
; al status
source_compare_lhu:
cmp source_character_count, 3
jb source_compare_lhu_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lhu_failure
cmp byte ptr[rax+1], 104
jne source_compare_lhu_failure
cmp byte ptr[rax+2], 117
jne source_compare_lhu_failure
cmp source_character_count, 3
je source_compare_lhu_success
cmp byte ptr[rax+3], 10
je source_compare_lhu_success
cmp byte ptr[rax+3], 32
je source_compare_lhu_success
cmp byte ptr[rax+3], 35
je source_compare_lhu_success
source_compare_lhu_failure:
mov al, 1
ret
source_compare_lhu_success:
xor al, al
ret


; out
; al status
source_compare_ll:
cmp source_character_count, 2
jb source_compare_ll_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_ll_failure
cmp byte ptr[rax+1], 108
jne source_compare_ll_failure
cmp source_character_count, 2
je source_compare_ll_success
cmp byte ptr[rax+2], 10
je source_compare_ll_success
cmp byte ptr[rax+2], 32
je source_compare_ll_success
cmp byte ptr[rax+2], 35
je source_compare_ll_success
source_compare_ll_failure:
mov al, 1
ret
source_compare_ll_success:
xor al, al
ret


; out
; al status
source_compare_lrd:
cmp source_character_count, 3
jb source_compare_lrd_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lrd_failure
cmp byte ptr[rax+1], 114
jne source_compare_lrd_failure
cmp byte ptr[rax+2], 100
jne source_compare_lrd_failure
cmp source_character_count, 3
je source_compare_lrd_success
cmp byte ptr[rax+3], 10
je source_compare_lrd_success
cmp byte ptr[rax+3], 32
je source_compare_lrd_success
cmp byte ptr[rax+3], 35
je source_compare_lrd_success
source_compare_lrd_failure:
mov al, 1
ret
source_compare_lrd_success:
xor al, al
ret


; out
; al status
source_compare_lrdaq:
cmp source_character_count, 5
jb source_compare_lrdaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lrdaq_failure
cmp byte ptr[rax+1], 114
jne source_compare_lrdaq_failure
cmp byte ptr[rax+2], 100
jne source_compare_lrdaq_failure
cmp byte ptr[rax+3], 97
jne source_compare_lrdaq_failure
cmp byte ptr[rax+4], 113
jne source_compare_lrdaq_failure
cmp source_character_count, 5
je source_compare_lrdaq_success
cmp byte ptr[rax+5], 10
je source_compare_lrdaq_success
cmp byte ptr[rax+5], 32
je source_compare_lrdaq_success
cmp byte ptr[rax+5], 35
je source_compare_lrdaq_success
source_compare_lrdaq_failure:
mov al, 1
ret
source_compare_lrdaq_success:
xor al, al
ret


; out
; al status
source_compare_lrdaqrl:
cmp source_character_count, 7
jb source_compare_lrdaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lrdaqrl_failure
cmp byte ptr[rax+1], 114
jne source_compare_lrdaqrl_failure
cmp byte ptr[rax+2], 100
jne source_compare_lrdaqrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_lrdaqrl_failure
cmp byte ptr[rax+4], 113
jne source_compare_lrdaqrl_failure
cmp byte ptr[rax+5], 114
jne source_compare_lrdaqrl_failure
cmp byte ptr[rax+6], 108
jne source_compare_lrdaqrl_failure
cmp source_character_count, 7
je source_compare_lrdaqrl_success
cmp byte ptr[rax+7], 10
je source_compare_lrdaqrl_success
cmp byte ptr[rax+7], 32
je source_compare_lrdaqrl_success
cmp byte ptr[rax+7], 35
je source_compare_lrdaqrl_success
source_compare_lrdaqrl_failure:
mov al, 1
ret
source_compare_lrdaqrl_success:
xor al, al
ret


; out
; al status
source_compare_lrdrl:
cmp source_character_count, 5
jb source_compare_lrdrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lrdrl_failure
cmp byte ptr[rax+1], 114
jne source_compare_lrdrl_failure
cmp byte ptr[rax+2], 100
jne source_compare_lrdrl_failure
cmp byte ptr[rax+3], 114
jne source_compare_lrdrl_failure
cmp byte ptr[rax+4], 108
jne source_compare_lrdrl_failure
cmp source_character_count, 5
je source_compare_lrdrl_success
cmp byte ptr[rax+5], 10
je source_compare_lrdrl_success
cmp byte ptr[rax+5], 32
je source_compare_lrdrl_success
cmp byte ptr[rax+5], 35
je source_compare_lrdrl_success
source_compare_lrdrl_failure:
mov al, 1
ret
source_compare_lrdrl_success:
xor al, al
ret


; out
; al status
source_compare_lrw:
cmp source_character_count, 3
jb source_compare_lrw_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lrw_failure
cmp byte ptr[rax+1], 114
jne source_compare_lrw_failure
cmp byte ptr[rax+2], 119
jne source_compare_lrw_failure
cmp source_character_count, 3
jb source_compare_lrw_success
cmp byte ptr[rax+3], 10
je source_compare_lrw_success
cmp byte ptr[rax+3], 32
je source_compare_lrw_success
cmp byte ptr[rax+3], 35
je source_compare_lrw_success
source_compare_lrw_failure:
mov al, 1
ret
source_compare_lrw_success:
xor al, al
ret


; out
; al status
source_compare_lrwaq:
cmp source_character_count, 5
jb source_compare_lrwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lrwaq_failure
cmp byte ptr[rax+1], 114
jne source_compare_lrwaq_failure
cmp byte ptr[rax+2], 119
jne source_compare_lrwaq_failure
cmp byte ptr[rax+3], 97
jne source_compare_lrwaq_failure
cmp byte ptr[rax+4], 113
jne source_compare_lrwaq_failure
cmp source_character_count, 5
je source_compare_lrwaq_success
cmp byte ptr[rax+5], 10
je source_compare_lrwaq_success
cmp byte ptr[rax+5], 32
je source_compare_lrwaq_success
cmp byte ptr[rax+5], 35
je source_compare_lrwaq_success
source_compare_lrwaq_failure:
mov al, 1
ret
source_compare_lrwaq_success:
xor al, al
ret


; out
; al status
source_compare_lrwaqrl:
cmp source_character_count, 7
jb source_compare_lrwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lrwaqrl_failure
cmp byte ptr[rax+1], 114
jne source_compare_lrwaqrl_failure
cmp byte ptr[rax+2], 119
jne source_compare_lrwaqrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_lrwaqrl_failure
cmp byte ptr[rax+4], 113
jne source_compare_lrwaqrl_failure
cmp byte ptr[rax+5], 114
jne source_compare_lrwaqrl_failure
cmp byte ptr[rax+6], 108
jne source_compare_lrwaqrl_failure
cmp source_character_count, 7
je source_compare_lrwaqrl_success
cmp byte ptr[rax+7], 10
je source_compare_lrwaqrl_success
cmp byte ptr[rax+7], 32
je source_compare_lrwaqrl_success
cmp byte ptr[rax+7], 35
je source_compare_lrwaqrl_success
source_compare_lrwaqrl_failure:
mov al, 1
ret
source_compare_lrwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_lrwrl:
cmp source_character_count, 5
jb source_compare_lrwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lrwrl_failure
cmp byte ptr[rax+1], 114
jne source_compare_lrwrl_failure
cmp byte ptr[rax+2], 119
jne source_compare_lrwrl_failure
cmp byte ptr[rax+3], 114
jne source_compare_lrwrl_failure
cmp byte ptr[rax+4], 108
jne source_compare_lrwrl_failure
cmp source_character_count, 5
je source_compare_lrwrl_success
cmp byte ptr[rax+5], 10
je source_compare_lrwrl_success
cmp byte ptr[rax+5], 32
je source_compare_lrwrl_success
cmp byte ptr[rax+5], 35
je source_compare_lrwrl_success
source_compare_lrwrl_failure:
mov al, 1
ret
source_compare_lrwrl_success:
xor al, al
ret


; out
; al status
source_compare_lui:
cmp source_character_count, 3
jb source_compare_lui_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lui_failure
cmp byte ptr[rax+1], 117
jne source_compare_lui_failure
cmp byte ptr[rax+2], 105
jne source_compare_lui_failure
cmp source_character_count, 3
je source_compare_lui_success
cmp byte ptr[rax+3], 10
je source_compare_lui_success
cmp byte ptr[rax+3], 32
je source_compare_lui_success
cmp byte ptr[rax+3], 35
je source_compare_lui_success
source_compare_lui_failure:
mov al, 1
ret
source_compare_lui_success:
xor al, al
ret


; out
; al status
source_compare_lw:
cmp source_character_count, 2
jb source_compare_lw_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lw_failure
cmp byte ptr[rax+1], 119
jne source_compare_lw_failure
cmp source_character_count, 2
je source_compare_lw_success
cmp byte ptr[rax+2], 10
je source_compare_lw_success
cmp byte ptr[rax+2], 32
je source_compare_lw_success
cmp byte ptr[rax+2], 35
je source_compare_lw_success
source_compare_lw_failure:
mov al, 1
ret
source_compare_lw_success:
xor al, al
ret


; out
; al status
source_compare_lwu:
cmp source_character_count, 3
jb source_compare_lwu_failure
mov rax, source_character_address
cmp byte ptr[rax], 108
jne source_compare_lwu_failure
cmp byte ptr[rax+1], 119
jne source_compare_lwu_failure
cmp byte ptr[rax+2], 117
jne source_compare_lwu_failure
cmp source_character_count, 3
je source_compare_lwu_success
cmp byte ptr[rax+3], 10
je source_compare_lwu_success
cmp byte ptr[rax+3], 32
je source_compare_lwu_success
cmp byte ptr[rax+3], 35
je source_compare_lwu_success
source_compare_lwu_failure:
mov al, 1
ret
source_compare_lwu_success:
xor al, al
ret


; out
; al status
source_compare_mret:
cmp source_character_count, 4
jb source_compare_mret_failure
mov rax, source_character_address
cmp byte ptr[rax], 109
jne source_compare_mret_failure
cmp byte ptr[rax+1], 114
jne source_compare_mret_failure
cmp byte ptr[rax+2], 101
jne source_compare_mret_failure
cmp byte ptr[rax+3], 116
jne source_compare_mret_failure
cmp source_character_count, 4
je source_compare_mret_success
cmp byte ptr[rax+4], 10
je source_compare_mret_success
cmp byte ptr[rax+4], 32
je source_compare_mret_success
cmp byte ptr[rax+4], 35
je source_compare_mret_success
source_compare_mret_failure:
mov al, 1
ret
source_compare_mret_success:
xor al, al
ret


; out
; al status
source_compare_mul:
cmp source_character_count, 3
jb source_compare_mul_failure
mov rax, source_character_address
cmp byte ptr[rax], 109
jne source_compare_mul_failure
cmp byte ptr[rax+1], 117
jne source_compare_mul_failure
cmp byte ptr[rax+2], 108
jne source_compare_mul_failure
cmp source_character_count, 3
je source_compare_mul_success
cmp byte ptr[rax+3], 10
je source_compare_mul_success
cmp byte ptr[rax+3], 32
je source_compare_mul_success
cmp byte ptr[rax+3], 35
je source_compare_mul_success
source_compare_mul_failure:
mov al, 1
ret
source_compare_mul_success:
xor al, al
ret


; out
; al status
source_compare_mulh:
cmp source_character_count, 4
jb source_compare_mulh_failure
mov rax, source_character_address
cmp byte ptr[rax], 109
jne source_compare_mulh_failure
cmp byte ptr[rax+1], 117
jne source_compare_mulh_failure
cmp byte ptr[rax+2], 108
jne source_compare_mulh_failure
cmp byte ptr[rax+3], 104
jne source_compare_mulh_failure
cmp source_character_count, 4
je source_compare_mulh_success
cmp byte ptr[rax+4], 10
je source_compare_mulh_success
cmp byte ptr[rax+4], 32
je source_compare_mulh_success
cmp byte ptr[rax+4], 35
je source_compare_mulh_success
source_compare_mulh_failure:
mov al, 1
ret
source_compare_mulh_success:
xor al, al
ret


; out
; al status
source_compare_mulhsu:
cmp source_character_count, 6
jb source_compare_mulhsu_failure
mov rax, source_character_address
cmp byte ptr[rax], 109
jne source_compare_mulhsu_failure
cmp byte ptr[rax+1], 117
jne source_compare_mulhsu_failure
cmp byte ptr[rax+2], 108
jne source_compare_mulhsu_failure
cmp byte ptr[rax+3], 104
jne source_compare_mulhsu_failure
cmp byte ptr[rax+4], 115
jne source_compare_mulhsu_failure
cmp byte ptr[rax+5], 117
jne source_compare_mulhsu_failure
cmp source_character_count, 6
je source_compare_mulhsu_success
cmp byte ptr[rax+6], 10
je source_compare_mulhsu_success
cmp byte ptr[rax+6], 32
je source_compare_mulhsu_success
cmp byte ptr[rax+6], 35
je source_compare_mulhsu_success
source_compare_mulhsu_failure:
mov al, 1
ret
source_compare_mulhsu_success:
xor al, al
ret


; out
; al status
source_compare_mulhu:
cmp source_character_count, 5
jb source_compare_mulhu_failure
mov rax, source_character_address
cmp byte ptr[rax], 109
jne source_compare_mulhu_failure
cmp byte ptr[rax+1], 117
jne source_compare_mulhu_failure
cmp byte ptr[rax+2], 108
jne source_compare_mulhu_failure
cmp byte ptr[rax+3], 104
jne source_compare_mulhu_failure
cmp byte ptr[rax+4], 117
jne source_compare_mulhu_failure
cmp source_character_count, 5
je source_compare_mulhu_success
cmp byte ptr[rax+5], 10
je source_compare_mulhu_success
cmp byte ptr[rax+5], 32
je source_compare_mulhu_success
cmp byte ptr[rax+5], 35
je source_compare_mulhu_success
source_compare_mulhu_failure:
mov al, 1
ret
source_compare_mulhu_success:
xor al, al
ret


; out
; al status
source_compare_mulw:
cmp source_character_count, 4
jb source_compare_mulw_failure
mov rax, source_character_address
cmp byte ptr[rax], 109
jne source_compare_mulw_failure
cmp byte ptr[rax+1], 117
jne source_compare_mulw_failure
cmp byte ptr[rax+2], 108
jne source_compare_mulw_failure
cmp byte ptr[rax+3], 119
jne source_compare_mulw_failure
cmp source_character_count, 4
je source_compare_mulw_success
cmp byte ptr[rax+4], 10
je source_compare_mulw_success
cmp byte ptr[rax+4], 32
je source_compare_mulw_success
cmp byte ptr[rax+4], 35
je source_compare_mulw_success
source_compare_mulw_failure:
mov al, 1
ret
source_compare_mulw_success:
xor al, al
ret


; out
; al status
source_compare_or:
cmp source_character_count, 2
jb source_compare_or_failure
mov rax, source_character_address
cmp byte ptr[rax], 111
jne source_compare_or_failure
cmp byte ptr[rax+1], 114
jne source_compare_or_failure
cmp source_character_count, 2
je source_compare_or_success
cmp byte ptr[rax+2], 10
je source_compare_or_success
cmp byte ptr[rax+2], 32
je source_compare_or_success
cmp byte ptr[rax+2], 35
je source_compare_or_success
source_compare_or_failure:
mov al, 1
ret
source_compare_or_success:
xor al, al
ret


; out
; al status
source_compare_ori:
cmp source_character_count, 3
jb source_compare_ori_failure
mov rax, source_character_address
cmp byte ptr[rax], 111
jne source_compare_ori_failure
cmp byte ptr[rax+1], 114
jne source_compare_ori_failure
cmp byte ptr[rax+2], 105
jne source_compare_ori_failure
cmp source_character_count, 3
je source_compare_ori_success
cmp byte ptr[rax+3], 10
je source_compare_ori_success
cmp byte ptr[rax+3], 32
je source_compare_ori_success
cmp byte ptr[rax+3], 35
je source_compare_ori_success
source_compare_ori_failure:
mov al, 1
ret
source_compare_ori_success:
xor al, al
ret


; out
; al status
source_compare_rem:
cmp source_character_count, 3
jb source_compare_rem_failure
mov rax, source_character_address
cmp byte ptr[rax], 114
jne source_compare_rem_failure
cmp byte ptr[rax+1], 101
jne source_compare_rem_failure
cmp byte ptr[rax+2], 109
jne source_compare_rem_failure
cmp source_character_count, 3
je source_compare_rem_success
cmp byte ptr[rax+3], 10
je source_compare_rem_success
cmp byte ptr[rax+3], 32
je source_compare_rem_success
cmp byte ptr[rax+3], 35
je source_compare_rem_success
source_compare_rem_failure:
mov al, 1
ret
source_compare_rem_success:
xor al, al
ret


; out
; al status
source_compare_remu:
cmp source_character_count, 4
jb source_compare_remu_failure
mov rax, source_character_address
cmp byte ptr[rax], 114
jne source_compare_remu_failure
cmp byte ptr[rax+1], 101
jne source_compare_remu_failure
cmp byte ptr[rax+2], 109
jne source_compare_remu_failure
cmp byte ptr[rax+3], 117
jne source_compare_remu_failure
cmp source_character_count, 4
je source_compare_remu_success
cmp byte ptr[rax+4], 10
je source_compare_remu_success
cmp byte ptr[rax+4], 32
je source_compare_remu_success
cmp byte ptr[rax+4], 35
je source_compare_remu_success
source_compare_remu_failure:
mov al, 1
ret
source_compare_remu_success:
xor al, al
ret


; out
; al status
source_compare_remuw:
cmp source_character_count, 5
jb source_compare_remuw_failure
mov rax, source_character_address
cmp byte ptr[rax], 114
jne source_compare_remuw_failure
cmp byte ptr[rax+1], 101
jne source_compare_remuw_failure
cmp byte ptr[rax+2], 109
jne source_compare_remuw_failure
cmp byte ptr[rax+3], 117
jne source_compare_remuw_failure
cmp byte ptr[rax+4], 119
jne source_compare_remuw_failure
cmp source_character_count, 5
je source_compare_remuw_success
cmp byte ptr[rax+5], 10
je source_compare_remuw_success
cmp byte ptr[rax+5], 32
je source_compare_remuw_success
cmp byte ptr[rax+5], 35
je source_compare_remuw_success
source_compare_remuw_failure:
mov al, 1
ret
source_compare_remuw_success:
xor al, al
ret


; out
; al status
source_compare_remw:
cmp source_character_count, 4
jb source_compare_remw_failure
mov rax, source_character_address
cmp byte ptr[rax], 114
jne source_compare_remw_failure
cmp byte ptr[rax+1], 101
jne source_compare_remw_failure
cmp byte ptr[rax+2], 109
jne source_compare_remw_failure
cmp byte ptr[rax+3], 119
jne source_compare_remw_failure
cmp source_character_count, 4
je source_compare_remw_success
cmp byte ptr[rax+4], 10
je source_compare_remw_success
cmp byte ptr[rax+4], 32
je source_compare_remw_success
cmp byte ptr[rax+4], 35
je source_compare_remw_success
source_compare_remw_failure:
mov al, 1
ret
source_compare_remw_success:
xor al, al
ret


; out
; al status
source_compare_sb:
cmp source_character_count, 2
jb source_compare_sb_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sb_failure
cmp byte ptr[rax+1], 98
jne source_compare_sb_failure
cmp source_character_count, 2
je source_compare_sb_success
cmp byte ptr[rax+2], 10
je source_compare_sb_success
cmp byte ptr[rax+2], 32
je source_compare_sb_success
cmp byte ptr[rax+2], 35
je source_compare_sb_success
source_compare_sb_failure:
mov al, 1
ret
source_compare_sb_success:
xor al, al
ret


; out
; al status
source_compare_scd:
cmp source_character_count, 3
jb source_compare_scd_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_scd_failure
cmp byte ptr[rax+1], 99
jne source_compare_scd_failure
cmp byte ptr[rax+2], 100
jne source_compare_scd_failure
cmp source_character_count, 3
je source_compare_scd_success
cmp byte ptr[rax+3], 10
je source_compare_scd_success
cmp byte ptr[rax+3], 32
je source_compare_scd_success
cmp byte ptr[rax+3], 35
je source_compare_scd_success
source_compare_scd_failure:
mov al, 1
ret
source_compare_scd_success:
xor al, al
ret


; out
; al status
source_compare_scdaq:
cmp source_character_count, 5
jb source_compare_scdaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_scdaq_failure
cmp byte ptr[rax+1], 99
jne source_compare_scdaq_failure
cmp byte ptr[rax+2], 100
jne source_compare_scdaq_failure
cmp byte ptr[rax+3], 97
jne source_compare_scdaq_failure
cmp byte ptr[rax+4], 113
jne source_compare_scdaq_failure
cmp source_character_count, 5
je source_compare_scdaq_success
cmp byte ptr[rax+5], 10
je source_compare_scdaq_success
cmp byte ptr[rax+5], 32
je source_compare_scdaq_success
cmp byte ptr[rax+5], 35
je source_compare_scdaq_success
source_compare_scdaq_failure:
mov al, 1
ret
source_compare_scdaq_success:
xor al, al
ret


; out
; al status
source_compare_scdaqrl:
cmp source_character_count, 7
jb source_compare_scdaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_scdaqrl_failure
cmp byte ptr[rax+1], 99
jne source_compare_scdaqrl_failure
cmp byte ptr[rax+2], 100
jne source_compare_scdaqrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_scdaqrl_failure
cmp byte ptr[rax+4], 113
jne source_compare_scdaqrl_failure
cmp byte ptr[rax+5], 114
jne source_compare_scdaqrl_failure
cmp byte ptr[rax+6], 108
jne source_compare_scdaqrl_failure
cmp source_character_count, 7
je source_compare_scdaqrl_success
cmp byte ptr[rax+7], 10
je source_compare_scdaqrl_success
cmp byte ptr[rax+7], 32
je source_compare_scdaqrl_success
cmp byte ptr[rax+7], 35
je source_compare_scdaqrl_success
source_compare_scdaqrl_failure:
mov al, 1
ret
source_compare_scdaqrl_success:
xor al, al
ret


; out
; al status
source_compare_scdrl:
cmp source_character_count, 5
jb source_compare_scdrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_scdrl_failure
cmp byte ptr[rax+1], 99
jne source_compare_scdrl_failure
cmp byte ptr[rax+2], 100
jne source_compare_scdrl_failure
cmp byte ptr[rax+3], 114
jne source_compare_scdrl_failure
cmp byte ptr[rax+4], 108
jne source_compare_scdrl_failure
cmp source_character_count, 5
je source_compare_scdrl_success
cmp byte ptr[rax+5], 10
je source_compare_scdrl_success
cmp byte ptr[rax+5], 32
je source_compare_scdrl_success
cmp byte ptr[rax+5], 35
je source_compare_scdrl_success
source_compare_scdrl_failure:
mov al, 1
ret
source_compare_scdrl_success:
xor al, al
ret


; out
; al status
source_compare_scw:
cmp source_character_count, 3
jb source_compare_scw_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_scw_failure
cmp byte ptr[rax+1], 99
jne source_compare_scw_failure
cmp byte ptr[rax+2], 119
jne source_compare_scw_failure
cmp source_character_count, 3
je source_compare_scw_success
cmp byte ptr[rax+3], 10
je source_compare_scw_success
cmp byte ptr[rax+3], 32
je source_compare_scw_success
cmp byte ptr[rax+3], 35
je source_compare_scw_success
source_compare_scw_failure:
mov al, 1
ret
source_compare_scw_success:
xor al, al
ret


; out
; al status
source_compare_scwaq:
cmp source_character_count, 5
jb source_compare_scwaq_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_scwaq_failure
cmp byte ptr[rax+1], 99
jne source_compare_scwaq_failure
cmp byte ptr[rax+2], 119
jne source_compare_scwaq_failure
cmp byte ptr[rax+3], 97
jne source_compare_scwaq_failure
cmp byte ptr[rax+4], 113
jne source_compare_scwaq_failure
cmp source_character_count, 5
je source_compare_scwaq_success
cmp byte ptr[rax+5], 10
je source_compare_scwaq_success
cmp byte ptr[rax+5], 32
je source_compare_scwaq_success
cmp byte ptr[rax+5], 35
je source_compare_scwaq_success
source_compare_scwaq_failure:
mov al, 1
ret
source_compare_scwaq_success:
xor al, al
ret


; out
; al status
source_compare_scwaqrl:
cmp source_character_count, 7
jb source_compare_scwaqrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_scwaqrl_failure
cmp byte ptr[rax+1], 99
jne source_compare_scwaqrl_failure
cmp byte ptr[rax+2], 119
jne source_compare_scwaqrl_failure
cmp byte ptr[rax+3], 97
jne source_compare_scwaqrl_failure
cmp byte ptr[rax+4], 113
jne source_compare_scwaqrl_failure
cmp byte ptr[rax+5], 114
jne source_compare_scwaqrl_failure
cmp byte ptr[rax+6], 108
jne source_compare_scwaqrl_failure
cmp source_character_count, 7
je source_compare_scwaqrl_success
cmp byte ptr[rax+7], 10
je source_compare_scwaqrl_success
cmp byte ptr[rax+7], 32
je source_compare_scwaqrl_success
cmp byte ptr[rax+7], 35
je source_compare_scwaqrl_success
source_compare_scwaqrl_failure:
mov al, 1
ret
source_compare_scwaqrl_success:
xor al, al
ret


; out
; al status
source_compare_scwrl:
cmp source_character_count, 5
jb source_compare_scwrl_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_scwrl_failure
cmp byte ptr[rax+1], 99
jne source_compare_scwrl_failure
cmp byte ptr[rax+2], 119
jne source_compare_scwrl_failure
cmp byte ptr[rax+3], 114
jne source_compare_scwrl_failure
cmp byte ptr[rax+4], 108
jne source_compare_scwrl_failure
cmp source_character_count, 5
je source_compare_scwrl_success
cmp byte ptr[rax+5], 10
je source_compare_scwrl_success
cmp byte ptr[rax+5], 32
je source_compare_scwrl_success
cmp byte ptr[rax+5], 35
je source_compare_scwrl_success
source_compare_scwrl_failure:
mov al, 1
ret
source_compare_scwrl_success:
xor al, al
ret


; out
; al status
source_compare_sd:
cmp source_character_count, 2
jb source_compare_sd_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sd_failure
cmp byte ptr[rax+1], 100
jne source_compare_sd_failure
cmp source_character_count, 2
je source_compare_sd_success
cmp byte ptr[rax+2], 10
je source_compare_sd_success
cmp byte ptr[rax+2], 32
je source_compare_sd_success
cmp byte ptr[rax+2], 35
je source_compare_sd_success
source_compare_sd_failure:
mov al, 1
ret
source_compare_sd_success:
xor al, al
ret


; out
; al status
source_compare_sfencevma:
cmp source_character_count, 9
jb source_compare_sfencevma_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sfencevma_failure
cmp byte ptr[rax+1], 102
jne source_compare_sfencevma_failure
cmp byte ptr[rax+2], 101
jne source_compare_sfencevma_failure
cmp byte ptr[rax+3], 110
jne source_compare_sfencevma_failure
cmp byte ptr[rax+4], 99
jne source_compare_sfencevma_failure
cmp byte ptr[rax+5], 101
jne source_compare_sfencevma_failure
cmp byte ptr[rax+6], 118
jne source_compare_sfencevma_failure
cmp byte ptr[rax+7], 109
jne source_compare_sfencevma_failure
cmp byte ptr[rax+8], 97
jne source_compare_sfencevma_failure
cmp source_character_count, 9
je source_compare_sfencevma_success
cmp byte ptr[rax+9], 10
je source_compare_sfencevma_success
cmp byte ptr[rax+9], 32
je source_compare_sfencevma_success
cmp byte ptr[rax+9], 35
je source_compare_sfencevma_success
source_compare_sfencevma_failure:
mov al, 1
ret
source_compare_sfencevma_success:
xor al, al
ret


; out
; al status
source_compare_sh:
cmp source_character_count, 2
jb source_compare_sh_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sh_failure
cmp byte ptr[rax+1], 104
jne source_compare_sh_failure
cmp source_character_count, 2
je source_compare_sh_success
cmp byte ptr[rax+2], 10
je source_compare_sh_success
cmp byte ptr[rax+2], 32
je source_compare_sh_success
cmp byte ptr[rax+2], 35
je source_compare_sh_success
source_compare_sh_failure:
mov al, 1
ret
source_compare_sh_success:
xor al, al
ret


; out
; al status
source_compare_sll:
cmp source_character_count, 3
jb source_compare_sll_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sll_failure
cmp byte ptr[rax+1], 108
jne source_compare_sll_failure
cmp byte ptr[rax+2], 108
jne source_compare_sll_failure
cmp source_character_count, 3
je source_compare_sll_success
cmp byte ptr[rax+3], 10
je source_compare_sll_success
cmp byte ptr[rax+3], 32
je source_compare_sll_success
cmp byte ptr[rax+3], 35
je source_compare_sll_success
source_compare_sll_failure:
mov al, 1
ret
source_compare_sll_success:
xor al, al
ret


; out
; al status
source_compare_slli:
cmp source_character_count, 4
jb source_compare_slli_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_slli_failure
cmp byte ptr[rax+1], 108
jne source_compare_slli_failure
cmp byte ptr[rax+2], 108
jne source_compare_slli_failure
cmp byte ptr[rax+3], 105
jne source_compare_slli_failure
cmp source_character_count, 4
je source_compare_slli_success
cmp byte ptr[rax+4], 10
je source_compare_slli_success
cmp byte ptr[rax+4], 32
je source_compare_slli_success
cmp byte ptr[rax+4], 35
je source_compare_slli_success
source_compare_slli_failure:
mov al, 1
ret
source_compare_slli_success:
xor al, al
ret


; out
; al status
source_compare_slliw:
cmp source_character_count, 5
jb source_compare_slliw_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_slliw_failure
cmp byte ptr[rax+1], 108
jne source_compare_slliw_failure
cmp byte ptr[rax+2], 108
jne source_compare_slliw_failure
cmp byte ptr[rax+3], 105
jne source_compare_slliw_failure
cmp byte ptr[rax+4], 119
jne source_compare_slliw_failure
cmp source_character_count, 5
je source_compare_slliw_success
cmp byte ptr[rax+5], 10
je source_compare_slliw_success
cmp byte ptr[rax+5], 32
je source_compare_slliw_success
cmp byte ptr[rax+5], 35
je source_compare_slliw_success
source_compare_slliw_failure:
mov al, 1
ret
source_compare_slliw_success:
xor al, al
ret


; out
; al status
source_compare_sllw:
cmp source_character_count, 4
jb source_compare_sllw_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sllw_failure
cmp byte ptr[rax+1], 108
jne source_compare_sllw_failure
cmp byte ptr[rax+2], 108
jne source_compare_sllw_failure
cmp byte ptr[rax+3], 119
jne source_compare_sllw_failure
cmp source_character_count, 4
je source_compare_sllw_success
cmp byte ptr[rax+4], 10
je source_compare_sllw_success
cmp byte ptr[rax+4], 32
je source_compare_sllw_success
cmp byte ptr[rax+4], 35
je source_compare_sllw_success
source_compare_sllw_failure:
mov al, 1
ret
source_compare_sllw_success:
xor al, al
ret


; out
; al status
source_compare_slt:
cmp source_character_count, 3
jb source_compare_slt_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_slt_failure
cmp byte ptr[rax+1], 108
jne source_compare_slt_failure
cmp byte ptr[rax+2], 116
jne source_compare_slt_failure
cmp source_character_count, 3
je source_compare_slt_success
cmp byte ptr[rax+3], 10
je source_compare_slt_success
cmp byte ptr[rax+3], 32
je source_compare_slt_success
cmp byte ptr[rax+3], 35
je source_compare_slt_success
source_compare_slt_failure:
mov al, 1
ret
source_compare_slt_success:
xor al, al
ret


; out
; al status
source_compare_slti:
cmp source_character_count, 4
jb source_compare_slti_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_slti_failure
cmp byte ptr[rax+1], 108
jne source_compare_slti_failure
cmp byte ptr[rax+2], 116
jne source_compare_slti_failure
cmp byte ptr[rax+3], 105
jne source_compare_slti_failure
cmp source_character_count, 4
je source_compare_slti_success
cmp byte ptr[rax+4], 10
je source_compare_slti_success
cmp byte ptr[rax+4], 32
je source_compare_slti_success
cmp byte ptr[rax+4], 35
je source_compare_slti_success
source_compare_slti_failure:
mov al, 1
ret
source_compare_slti_success:
xor al, al
ret


; out
; al status
source_compare_sltiu:
cmp source_character_count, 5
jb source_compare_sltiu_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sltiu_failure
cmp byte ptr[rax+1], 108
jne source_compare_sltiu_failure
cmp byte ptr[rax+2], 116
jne source_compare_sltiu_failure
cmp byte ptr[rax+3], 105
jne source_compare_sltiu_failure
cmp byte ptr[rax+4], 117
jne source_compare_sltiu_failure
cmp source_character_count, 5
je source_compare_sltiu_success
cmp byte ptr[rax+5], 10
je source_compare_sltiu_success
cmp byte ptr[rax+5], 32
je source_compare_sltiu_success
cmp byte ptr[rax+5], 35
je source_compare_sltiu_success
source_compare_sltiu_failure:
mov al, 1
ret
source_compare_sltiu_success:
xor al, al
ret


; out
; al status
source_compare_sltu:
cmp source_character_count, 4
jb source_compare_sltu_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sltu_failure
cmp byte ptr[rax+1], 108
jne source_compare_sltu_failure
cmp byte ptr[rax+2], 116
jne source_compare_sltu_failure
cmp byte ptr[rax+3], 117
jne source_compare_sltu_failure
cmp source_character_count, 4
je source_compare_sltu_success
cmp byte ptr[rax+4], 10
je source_compare_sltu_success
cmp byte ptr[rax+4], 32
je source_compare_sltu_success
cmp byte ptr[rax+4], 35
je source_compare_sltu_success
source_compare_sltu_failure:
mov al, 1
ret
source_compare_sltu_success:
xor al, al
ret


; out
; al status
source_compare_sra:
cmp source_character_count, 3
jb source_compare_sra_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sra_failure
cmp byte ptr[rax+1], 114
jne source_compare_sra_failure
cmp byte ptr[rax+2], 97
jne source_compare_sra_failure
cmp source_character_count, 3
je source_compare_sra_success
cmp byte ptr[rax+3], 10
je source_compare_sra_success
cmp byte ptr[rax+3], 32
je source_compare_sra_success
cmp byte ptr[rax+3], 35
je source_compare_sra_success
source_compare_sra_failure:
mov al, 1
ret
source_compare_sra_success:
xor al, al
ret


; out
; al status
source_compare_srai:
cmp source_character_count, 4
jb source_compare_srai_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_srai_failure
cmp byte ptr[rax+1], 114
jne source_compare_srai_failure
cmp byte ptr[rax+2], 97
jne source_compare_srai_failure
cmp byte ptr[rax+3], 105
jne source_compare_srai_failure
cmp source_character_count, 4
je source_compare_srai_success
cmp byte ptr[rax+4], 10
je source_compare_srai_success
cmp byte ptr[rax+4], 32
je source_compare_srai_success
cmp byte ptr[rax+4], 35
je source_compare_srai_success
source_compare_srai_failure:
mov al, 1
ret
source_compare_srai_success:
xor al, al
ret


; out
; al status
source_compare_sraiw:
cmp source_character_count, 5
jb source_compare_sraiw_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sraiw_failure
cmp byte ptr[rax+1], 114
jne source_compare_sraiw_failure
cmp byte ptr[rax+2], 97
jne source_compare_sraiw_failure
cmp byte ptr[rax+3], 105
jne source_compare_sraiw_failure
cmp byte ptr[rax+4], 119
jne source_compare_sraiw_failure
cmp source_character_count, 5
je source_compare_sraiw_success
cmp byte ptr[rax+5], 10
je source_compare_sraiw_success
cmp byte ptr[rax+5], 32
je source_compare_sraiw_success
cmp byte ptr[rax+5], 35
je source_compare_sraiw_success
source_compare_sraiw_failure:
mov al, 1
ret
source_compare_sraiw_success:
xor al, al
ret


; out
; al status
source_compare_sraw:
cmp source_character_count, 4
jb source_compare_sraw_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sraw_failure
cmp byte ptr[rax+1], 114
jne source_compare_sraw_failure
cmp byte ptr[rax+2], 97
jne source_compare_sraw_failure
cmp byte ptr[rax+3], 119
jne source_compare_sraw_failure
cmp source_character_count, 4
je source_compare_sraw_success
cmp byte ptr[rax+4], 10
je source_compare_sraw_success
cmp byte ptr[rax+4], 32
je source_compare_sraw_success
cmp byte ptr[rax+4], 35
je source_compare_sraw_success
source_compare_sraw_failure:
mov al, 1
ret
source_compare_sraw_success:
xor al, al
ret


; out
; al status
source_compare_sret:
cmp source_character_count, 4
jb source_compare_sret_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sret_failure
cmp byte ptr[rax+1], 114
jne source_compare_sret_failure
cmp byte ptr[rax+2], 101
jne source_compare_sret_failure
cmp byte ptr[rax+3], 116
jne source_compare_sret_failure
cmp source_character_count, 4
je source_compare_sret_success
cmp byte ptr[rax+4], 10
je source_compare_sret_success
cmp byte ptr[rax+4], 32
je source_compare_sret_success
cmp byte ptr[rax+4], 35
je source_compare_sret_success
source_compare_sret_failure:
mov al, 1
ret
source_compare_sret_success:
xor al, al
ret


; out
; al status
source_compare_srl:
cmp source_character_count, 3
jb source_compare_srl_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_srl_failure
cmp byte ptr[rax+1], 114
jne source_compare_srl_failure
cmp byte ptr[rax+2], 108
jne source_compare_srl_failure
cmp source_character_count, 3
je source_compare_srl_success
cmp byte ptr[rax+3], 10
je source_compare_srl_success
cmp byte ptr[rax+3], 32
je source_compare_srl_success
cmp byte ptr[rax+3], 35
je source_compare_srl_success
source_compare_srl_failure:
mov al, 1
ret
source_compare_srl_success:
xor al, al
ret


; out
; al status
source_compare_srli:
cmp source_character_count, 4
jb source_compare_srli_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_srli_failure
cmp byte ptr[rax+1], 114
jne source_compare_srli_failure
cmp byte ptr[rax+2], 108
jne source_compare_srli_failure
cmp byte ptr[rax+3], 105
jne source_compare_srli_failure
cmp source_character_count, 4
je source_compare_srli_success
cmp byte ptr[rax+4], 10
je source_compare_srli_success
cmp byte ptr[rax+4], 32
je source_compare_srli_success
cmp byte ptr[rax+4], 35
je source_compare_srli_success
source_compare_srli_failure:
mov al, 1
ret
source_compare_srli_success:
xor al, al
ret


; out
; al status
source_compare_srliw:
cmp source_character_count, 5
jb source_compare_srliw_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_srliw_failure
cmp byte ptr[rax+1], 114
jne source_compare_srliw_failure
cmp byte ptr[rax+2], 108
jne source_compare_srliw_failure
cmp byte ptr[rax+3], 105
jne source_compare_srliw_failure
cmp byte ptr[rax+4], 119
jne source_compare_srliw_failure
cmp source_character_count, 5
je source_compare_srliw_success
cmp byte ptr[rax+5], 10
je source_compare_srliw_success
cmp byte ptr[rax+5], 32
je source_compare_srliw_success
cmp byte ptr[rax+5], 35
je source_compare_srliw_success
source_compare_srliw_failure:
mov al, 1
ret
source_compare_srliw_success:
xor al, al
ret


; out
; al status
source_compare_srlw:
cmp source_character_count, 4
jb source_compare_srlw_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_srlw_failure
cmp byte ptr[rax+1], 114
jne source_compare_srlw_failure
cmp byte ptr[rax+2], 108
jne source_compare_srlw_failure
cmp byte ptr[rax+3], 119
jne source_compare_srlw_failure
cmp source_character_count, 4
je source_compare_srlw_success
cmp byte ptr[rax+4], 10
je source_compare_srlw_success
cmp byte ptr[rax+4], 32
je source_compare_srlw_success
cmp byte ptr[rax+4], 35
je source_compare_srlw_success
source_compare_srlw_failure:
mov al, 1
ret
source_compare_srlw_success:
xor al, al
ret


; out
; al status
source_compare_string:
cmp source_character_count, 6
jb source_compare_string_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_string_failure
cmp byte ptr[rax+1], 116
jne source_compare_string_failure
cmp byte ptr[rax+2], 114
jne source_compare_string_failure
cmp byte ptr[rax+3], 105
jne source_compare_string_failure
cmp byte ptr[rax+4], 110
jne source_compare_string_failure
cmp byte ptr[rax+5], 103
jne source_compare_string_failure
cmp source_character_count, 6
je source_compare_string_success
cmp byte ptr[rax+6], 10
je source_compare_string_success
cmp byte ptr[rax+6], 32
je source_compare_string_success
cmp byte ptr[rax+6], 35
je source_compare_string_success
source_compare_string_failure:
mov al, 1
ret
source_compare_string_success:
xor al, al
ret


; out
; al status
source_compare_sub:
cmp source_character_count, 3
jb source_compare_sub_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sub_failure
cmp byte ptr[rax+1], 117
jne source_compare_sub_failure
cmp byte ptr[rax+2], 98
jne source_compare_sub_failure
cmp source_character_count, 3
je source_compare_sub_success
cmp byte ptr[rax+3], 10
je source_compare_sub_success
cmp byte ptr[rax+3], 32
je source_compare_sub_success
cmp byte ptr[rax+3], 35
je source_compare_sub_success
source_compare_sub_failure:
mov al, 1
ret
source_compare_sub_success:
xor al, al
ret


; out
; al status
source_compare_subw:
cmp source_character_count, 4
jb source_compare_subw_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_subw_failure
cmp byte ptr[rax+1], 117
jne source_compare_subw_failure
cmp byte ptr[rax+2], 98
jne source_compare_subw_failure
cmp byte ptr[rax+3], 119
jne source_compare_subw_failure
cmp source_character_count, 4
je source_compare_subw_success
cmp byte ptr[rax+4], 10
je source_compare_subw_success
cmp byte ptr[rax+4], 32
je source_compare_subw_success
cmp byte ptr[rax+4], 35
je source_compare_subw_success
source_compare_subw_failure:
mov al, 1
ret
source_compare_subw_success:
xor al, al
ret


; out
; al status
source_compare_sw:
cmp source_character_count, 2
jb source_compare_sw_failure
mov rax, source_character_address
cmp byte ptr[rax], 115
jne source_compare_sw_failure
cmp byte ptr[rax+1], 119
jne source_compare_sw_failure
cmp source_character_count, 2
je source_compare_sw_success
cmp byte ptr[rax+2], 10
je source_compare_sw_success
cmp byte ptr[rax+2], 32
je source_compare_sw_success
cmp byte ptr[rax+2], 35
je source_compare_sw_success
source_compare_sw_failure:
mov al, 1
ret
source_compare_sw_success:
xor al, al
ret


; out
; al status
source_compare_uret:
cmp source_character_count, 4
jb source_compare_uret_failure
mov rax, source_character_address
cmp byte ptr[rax], 117
jne source_compare_uret_failure
cmp byte ptr[rax+1], 114
jne source_compare_uret_failure
cmp byte ptr[rax+2], 101
jne source_compare_uret_failure
cmp byte ptr[rax+3], 116
jne source_compare_uret_failure
cmp source_character_count, 4
je source_compare_uret_success
cmp byte ptr[rax+4], 10
je source_compare_uret_success
cmp byte ptr[rax+4], 32
je source_compare_uret_success
cmp byte ptr[rax+4], 35
je source_compare_uret_success
source_compare_uret_failure:
mov al, 1
ret
source_compare_uret_success:
xor al, al
ret


; out
; al status
source_compare_wfi:
cmp source_character_count, 3
jb source_compare_wfi_failure
mov rax, source_character_address
cmp byte ptr[rax], 119
jne source_compare_wfi_failure
cmp byte ptr[rax+1], 102
jne source_compare_wfi_failure
cmp byte ptr[rax+2], 105
jne source_compare_wfi_failure
cmp source_character_count, 3
je source_compare_wfi_success
cmp byte ptr[rax+3], 10
je source_compare_wfi_success
cmp byte ptr[rax+3], 32
je source_compare_wfi_success
cmp byte ptr[rax+3], 35
je source_compare_wfi_success
source_compare_wfi_failure:
mov al, 1
ret
source_compare_wfi_success:
xor al, al
ret


; out
; al status
source_compare_word:
cmp source_character_count, 4
jb source_compare_word_failure
mov rax, source_character_address
cmp byte ptr[rax], 119
jne source_compare_word_failure
cmp byte ptr[rax+1], 111
jne source_compare_word_failure
cmp byte ptr[rax+2], 114
jne source_compare_word_failure
cmp byte ptr[rax+3], 100
jne source_compare_word_failure
cmp source_character_count, 4
je source_compare_word_success
cmp byte ptr[rax+4], 10
je source_compare_word_success
cmp byte ptr[rax+4], 32
je source_compare_word_success
cmp byte ptr[rax+4], 35
je source_compare_word_success
source_compare_word_failure:
mov al, 1
ret
source_compare_word_success:
xor al, al
ret


; out
; al status
source_compare_xor:
cmp source_character_count, 3
jb source_compare_xor_failure
mov rax, source_character_address
cmp byte ptr[rax], 120
jne source_compare_xor_failure
cmp byte ptr[rax+1], 111
jne source_compare_xor_failure
cmp byte ptr[rax+2], 114
jne source_compare_xor_failure
cmp source_character_count, 3
je source_compare_xor_success
cmp byte ptr[rax+3], 10
je source_compare_xor_success
cmp byte ptr[rax+3], 32
je source_compare_xor_success
cmp byte ptr[rax+3], 35
je source_compare_xor_success
source_compare_xor_failure:
mov al, 1
ret
source_compare_xor_success:
xor al, al
ret


; out
; al status
source_compare_xori:
cmp source_character_count, 4
jb source_compare_xori_failure
mov rax, source_character_address
cmp byte ptr[rax], 120
jne source_compare_xori_failure
cmp byte ptr[rax+1], 111
jne source_compare_xori_failure
cmp byte ptr[rax+2], 114
jne source_compare_xori_failure
cmp byte ptr[rax+3], 105
jne source_compare_xori_failure
cmp source_character_count, 4
je source_compare_xori_success
cmp byte ptr[rax+4], 10
je source_compare_xori_success
cmp byte ptr[rax+4], 32
je source_compare_xori_success
cmp byte ptr[rax+4], 35
je source_compare_xori_success
source_compare_xori_failure:
mov al, 1
ret
source_compare_xori_success:
xor al, al
ret


; out
; al status
source_compare_zero:
cmp source_character_count, 4
jb source_compare_zero_failure
mov rax, source_character_address
cmp byte ptr[rax], 122
jne source_compare_zero_failure
cmp byte ptr[rax+1], 101
jne source_compare_zero_failure
cmp byte ptr[rax+2], 114
jne source_compare_zero_failure
cmp byte ptr[rax+3], 111
jne source_compare_zero_failure
cmp source_character_count, 4
je source_compare_zero_success
cmp byte ptr[rax+4], 10
je source_compare_zero_success
cmp byte ptr[rax+4], 32
je source_compare_zero_success
cmp byte ptr[rax+4], 35
je source_compare_zero_success
source_compare_zero_failure:
mov al, 1
ret
source_compare_zero_success:
xor al, al
ret


.data

align 2
source_list_size word 0
source_count word 0

align 8
source_address qword 0
source_character_address qword 0
source_character_count qword 0
source_line_index qword 0
source_list byte 135168 dup(0) ; 256 sources
