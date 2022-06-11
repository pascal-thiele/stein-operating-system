:: kernel32.lib has to be provided externally.
ml64 /c /Fo "riscv64 assembler.obj" "riscv64 assembler.asm"
link /SUBSYSTEM:CONSOLE /ENTRY:start "/OUT:stein riscv64 assembler.exe" "riscv64 assembler.obj" kernel32.lib