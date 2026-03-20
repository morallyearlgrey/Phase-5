# Testbench: All R-type instructions
# Tests: add, sub, sll, slt, sltu, xor, srl, sra, or, and
.data
result0: .word 0
result1: .word 0
result2: .word 0
result3: .word 0
result4: .word 0
result5: .word 0
result6: .word 0
result7: .word 0
result8: .word 0
result9: .word 0

.text
.globl main

main:
    # t0 = 20 (0x14), t1 = 3
    addi t0, x0, 20
    addi t1, x0, 3

    # Load base pointer
    lui  s0, 0
    addi s0, x0, 0

    add  t2, t0, t1      # 23
    sub  t3, t0, t1      # 17
    sll  t4, t0, t1      # 20 << 3 = 160
    slt  t5, t1, t0      # 3 < 20 = 1
    sltu t6, t1, t0      # 3 < 20 (unsigned) = 1
    xor  s1, t0, t1      # 20 ^ 3 = 23
    srl  s2, t0, t1      # 20 >> 3 = 2
    sra  s3, t0, t1      # 20 >>> 3 = 2 (positive)
    or   s4, t0, t1      # 20 | 3 = 23
    and  s5, t0, t1      # 20 & 3 = 0
    ebreak