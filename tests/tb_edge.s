# Testbench: Edge cases
# Tests: negative immediates, x0 writes (no-op), %hi/%lo with multiple labels,
#        forward/backward branch labels, ebreak encoding
.data
p: .word 0xFFFFFFFF
q: .word 100
r: .word 0
s: .word 0

.text
.globl main

main:
    # x0 is always 0, writes to it are ignored
    addi x0, x0, 999    # no-op, x0 stays 0
    add  x0, x0, x0     # no-op

    # Negative immediates (sign-extended 12-bit)
    addi t0, x0, -1     # t0 = 0xFFFFFFFF
    addi t1, x0, -128   # t1 = 0xFFFFFF80
    addi t2, x0, 2047   # t2 = 0x7FF (max positive 12-bit)
    addi t3, x0, -2048  # t3 = 0xFFFFF800 (min negative 12-bit)

    # %hi/%lo: multiple labels in data section
    lui  s0, %hi(p)
    addi s0, s0, %lo(p)
    lw   t4, 0(s0)      # t4 = 0xFFFFFFFF

    lui  s1, %hi(q)
    addi s1, s1, %lo(q)
    lw   t5, 0(s1)      # t5 = 100

    # Backward branch (target before branch instruction)
    addi t6, x0, 0
    addi s2, x0, 3

loop:
    addi t6, t6, 1
    addi s2, s2, -1
    bne  s2, x0, loop   # backward branch, loops 3 times -> t6 = 3

    # Store with negative offset
    lui  s3, %hi(r)
    addi s3, s3, %lo(r)
    addi s3, s3, 8      # point past r by 8 bytes
    sw   t6, -8(s3)     # store to r (offset = -8)

    # SW with zero offset
    lui  s4, %hi(s)
    addi s4, s4, %lo(s)
    sw   t5, 0(s4)      # store 100 to s

    ebreak