as -o "riscv64 assembler.o" "riscv64 assembler.s" terminal.s include.s constant.s label.s source.s heap.s
ld -s -e entrance -o "stein riscv64 assembler" "riscv64 assembler.o"
