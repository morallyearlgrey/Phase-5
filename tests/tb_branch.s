# Testbench: Branch instructions
# Tests: beq, bne, blt, bge, bltu, bgeu
# Each branch should be taken; result counter should reach 6
.data
result: .word 0

.text
.globl main

main:
    addi t0, x0, 0       # counter
    addi t1, x0, 5
    addi t2, x0, 10
    addi t3, x0, 5       # t3 == t1

    # beq: t1 == t3 -> taken
    beq  t1, t3, beq_ok
    addi t0, t0, 100     # should NOT execute
beq_ok:
    addi t0, t0, 1       # counter = 1

    # bne: t1 != t2 -> taken
    bne  t1, t2, bne_ok
    addi t0, t0, 100
bne_ok:
    addi t0, t0, 1       # counter = 2

    # blt: t1 < t2 -> taken
    blt  t1, t2, blt_ok
    addi t0, t0, 100
blt_ok:
    addi t0, t0, 1       # counter = 3

    # bge: t2 >= t1 -> taken
    bge  t2, t1, bge_ok
    addi t0, t0, 100
bge_ok:
    addi t0, t0, 1       # counter = 4

    # bltu: t1 < t2 unsigned -> taken
    bltu t1, t2, bltu_ok
    addi t0, t0, 100
bltu_ok:
    addi t0, t0, 1       # counter = 5

    # bgeu: t2 >= t1 unsigned -> taken
    bgeu t2, t1, bgeu_ok
    addi t0, t0, 100
bgeu_ok:
    addi t0, t0, 1       # counter = 6

    # bne: t1 == t3, so NOT taken -> falls through
    bne  t1, t3, skip_me
    addi t0, t0, 1       # counter = 7 (branch NOT taken, falls through)

skip_me:
    ebreak