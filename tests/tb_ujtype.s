# Testbench: U-type and J-type instructions
# Tests: lui, auipc, jal, jalr (with correct assembler syntax)
.data
result: .word 0

.text
.globl main

main:
    # LUI: load upper immediate
    lui  t0, 0x12345     # t0 = 0x12345000
    lui  t1, 1           # t1 = 0x00001000
    lui  t2, 0xFFFFF     # t2 = 0xFFFFF000

    # AUIPC: add upper immediate to PC
    auipc t3, 0          # t3 = PC of this instruction
    auipc t4, 1          # t4 = PC + 0x1000

    # JAL: jump and link - ra = PC+4, jump to jal_target
    jal  ra, jal_target
    addi t5, x0, 99      # skipped

jal_target:
    addi t5, x0, 1       # t5 = 1 (reached via jal)

    # JALR: jump via register - syntax is jalr rd, offset(rs1)
    jalr x0, 4(ra)       # jump to ra+4 (skips next instruction)
    addi t6, x0, 99      # skipped

jalr_land:
    addi t6, x0, 2       # t6 = 2 (reached via jalr)

    ebreak