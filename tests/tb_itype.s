# Testbench: I-type arithmetic instructions
# Tests: addi, slti, sltiu, xori, ori, andi, slli, srli, srai
.data
val: .word 20

.text
.globl main

main:
    addi t0, x0, 20      # t0 = 20
    addi t1, x0, -5      # t1 = -5 (sign extend)
    slti t2, t0, 25      # 20 < 25 = 1
    slti t3, t0, 10      # 20 < 10 = 0
    sltiu t4, t0, 25     # 20 < 25 unsigned = 1
    xori t5, t0, 15      # 20 ^ 15 = 27
    ori  t6, t0, 7       # 20 | 7 = 23
    andi s1, t0, 14      # 20 & 14 = 4
    slli s2, t0, 2       # 20 << 2 = 80
    srli s3, t0, 2       # 20 >> 2 = 5
    addi s4, x0, -8      # s4 = -8 (0xFFFFFFF8)
    srai s5, s4, 2       # -8 >>> 2 = -2 (arithmetic, sign preserved)
    srli s6, s4, 2       # -8 >> 2 = 0x3FFFFFFE (logical)
    ebreak