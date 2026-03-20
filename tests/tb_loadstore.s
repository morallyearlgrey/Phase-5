# Testbench: Load and Store instructions (S-type and I-type loads)
# Tests: lw, sw, lb, sb, lh, sh, lbu, lhu
# Also tests %hi/%lo addressing and label-prefixed .word
.data
val_a: .word 0x12345678
val_b: .word 0xDEADBEEF
buf0:  .word 0
buf1:  .word 0
buf2:  .word 0
buf3:  .word 0

.text
.globl main

main:
    # Load base pointer using %hi/%lo
    lui  s0, %hi(val_a)
    addi s0, s0, %lo(val_a)

    # lw: load full word
    lw   t0, 0(s0)         # t0 = 0x12345678

    # sw: store full word
    sw   t0, 8(s0)         # buf0 = 0x12345678

    # lb: load byte signed (byte 0 = 0x78 = 120, sign extended)
    lb   t1, 0(s0)         # t1 = 0x78 = 120

    # lbu: load byte unsigned
    lbu  t2, 1(s0)         # t2 = 0x56 = 86

    # lh: load halfword signed (bytes 0-1 = 0x5678)
    lh   t3, 0(s0)         # t3 = 0x5678 = 22136

    # lhu: load halfword unsigned
    lhu  t4, 0(s0)         # t4 = 0x5678 (same, positive)

    # sb: store byte
    addi t5, x0, 0x42      # t5 = 0x42
    sb   t5, 12(s0)        # buf1[0] = 0x42

    # sh: store halfword
    addi t6, x0, 0x1234    # won't fit signed 12-bit... use lui+addi
    lui  t6, 1
    addi t6, t6, 0x234     # t6 = 0x1234
    sh   t6, 16(s0)        # buf2[0:1] = 0x1234

    # Second data word load
    lw   s1, 4(s0)         # s1 = 0xDEADBEEF

    ebreak