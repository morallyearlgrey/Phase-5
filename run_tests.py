#!/usr/bin/env python3
"""
Assembler Test Runner
Usage: python3 run_tests.py [path/to/assembler] [test_dir]

Assembles each .s file, decodes the output, and checks:
  - ebreak is the last instruction (0x00100073)
  - No all-zero instructions in text (likely encoding failure)
  - Instruction count matches expected (if expected file exists)
  - Exact word-by-word match against expected (if .expected file exists)
  - data.txt has correct word count matching .data section

Place .s files in the test directory.
Add a <testname>.expected file with one hex word per line (0x...) for exact match tests.
"""

import subprocess
import sys
import os
import tempfile
import struct

ASSEMBLER = "./assembler"       # path to compiled assembler binary
TEST_DIR  = "./tests"           # directory containing .s test files

EBREAK = 0x00100073

# ── colour helpers ────────────────────────────────────────────────────────────
PASS  = "\033[92mPASS\033[0m"
FAIL  = "\033[91mFAIL\033[0m"
WARN  = "\033[93mWARN\033[0m"
BOLD  = "\033[1m"
RESET = "\033[0m"

# ── helpers ───────────────────────────────────────────────────────────────────

def read_hex_file(path):
    """Read a file of 0xNN hex bytes, return list of ints."""
    values = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                values.append(int(line, 16))
    return values

def bytes_to_words(byte_list):
    """Convert list of bytes (little-endian groups of 4) to 32-bit words."""
    words = []
    for i in range(0, len(byte_list) - 3, 4):
        w = byte_list[i] | (byte_list[i+1] << 8) | (byte_list[i+2] << 16) | (byte_list[i+3] << 24)
        words.append(w)
    return words

def count_data_words(asm_path):
    """Count .word directives in the .data section of an assembly file."""
    count = 0
    in_data = False
    with open(asm_path) as f:
        for line in f:
            stripped = line.strip()
            # strip comments
            if '#' in stripped:
                stripped = stripped[:stripped.index('#')].strip()
            if stripped == '.data':
                in_data = True
            elif stripped == '.text':
                in_data = False
            elif in_data and '.word' in stripped:
                count += 1
    return count

def decode_instr(w):
    """Return a short human-readable description of a RISC-V instruction word."""
    opcode = w & 0x7F
    rd     = (w >> 7)  & 0x1F
    funct3 = (w >> 12) & 0x7
    rs1    = (w >> 15) & 0x1F
    rs2    = (w >> 20) & 0x1F
    funct7 = (w >> 25) & 0x7F
    imm_i  = (w >> 20)          # sign extend later if needed
    names = {0:'zero',1:'ra',2:'sp',3:'gp',4:'tp',5:'t0',6:'t1',7:'t2',
             8:'s0',9:'s1',10:'a0',11:'a1',12:'a2',13:'a3',14:'a4',15:'a5',
             16:'a6',17:'a7',18:'s2',19:'s3',20:'s4',21:'s5',22:'s6',23:'s7',
             24:'s8',25:'s9',26:'s10',27:'s11',28:'t3',29:'t4',30:'t5',31:'t6'}
    rn = lambda x: names.get(x, f'x{x}')
    op_map = {0x33:'R-type', 0x13:'I-ALU', 0x03:'LOAD', 0x23:'STORE',
              0x63:'BRANCH', 0x37:'LUI', 0x17:'AUIPC', 0x6F:'JAL',
              0x67:'JALR', 0x73:'SYSTEM'}
    tag = op_map.get(opcode, f'op=0x{opcode:02x}')
    if opcode == 0x73:
        return f"{'ebreak' if w==EBREAK else 'ecall'}"
    if opcode == 0x33:
        ops = {(0,0):'add',(0,0x20):'sub',(1,0):'sll',(2,0):'slt',
               (3,0):'sltu',(4,0):'xor',(5,0):'srl',(5,0x20):'sra',
               (6,0):'or',(7,0):'and'}
        nm = ops.get((funct3,funct7), 'R?')
        return f"{nm} {rn(rd)},{rn(rs1)},{rn(rs2)}"
    if opcode == 0x37:
        return f"lui {rn(rd)},0x{(w>>12)&0xFFFFF:x}"
    if opcode == 0x17:
        return f"auipc {rn(rd)},0x{(w>>12)&0xFFFFF:x}"
    return f"[{tag}] rd={rn(rd)} rs1={rn(rs1)} rs2={rn(rs2)}"

# ── test runner ───────────────────────────────────────────────────────────────

def run_test(asm_path, assembler_bin):
    name = os.path.splitext(os.path.basename(asm_path))[0]
    expected_path = os.path.splitext(asm_path)[0] + ".expected"

    results = []   # list of (bool, message)
    warnings = []

    with tempfile.TemporaryDirectory() as tmpdir:
        # Run assembler
        try:
            proc = subprocess.run(
                [assembler_bin, asm_path, tmpdir],
                capture_output=True, text=True, timeout=5
            )
        except FileNotFoundError:
            return False, [f"Assembler binary not found: {assembler_bin}"], []
        except subprocess.TimeoutExpired:
            return False, ["Assembler timed out (>5s)"], []

        if proc.returncode != 0:
            return False, [f"Assembler exited with code {proc.returncode}", proc.stderr.strip()], []

        instr_path = os.path.join(tmpdir, "instr.txt")
        data_path  = os.path.join(tmpdir, "data.txt")

        if not os.path.exists(instr_path):
            return False, ["instr.txt not created"], []

        # Parse instruction words
        try:
            instr_bytes = read_hex_file(instr_path)
        except Exception as e:
            return False, [f"Failed to read instr.txt: {e}"], []
        words = bytes_to_words(instr_bytes)

        if not words:
            return False, ["instr.txt is empty"], []

        # ── Check 1: Last instruction is ebreak ──────────────────────────────
        last = words[-1]
        if last == EBREAK:
            results.append((True, f"Last instr = ebreak (0x{EBREAK:08x})"))
        else:
            results.append((False, f"Last instr should be ebreak, got 0x{last:08x} [{decode_instr(last)}]"))

        # ── Check 2: No all-zero instructions (likely encoding failure) ───────
        zero_indices = [i for i, w in enumerate(words[:-1]) if w == 0x00000000]
        if zero_indices:
            warnings.append(f"Zero words at positions {zero_indices} (possible encoding failure)")
        else:
            results.append((True, f"No zero-encoded instructions ({len(words)} total)"))

        # ── Check 3: data.txt word count matches .data section ────────────────
        expected_data_words = count_data_words(asm_path)
        if os.path.exists(data_path):
            try:
                data_bytes = read_hex_file(data_path)
                data_words = bytes_to_words(data_bytes)
                actual_dw = len(data_words)
                if actual_dw == expected_data_words:
                    results.append((True, f"data.txt has {actual_dw} word(s) (matches .data section)"))
                else:
                    results.append((False,
                        f"data.txt has {actual_dw} word(s), expected {expected_data_words} from .data section"))
            except Exception as e:
                results.append((False, f"Failed to read data.txt: {e}"))
        elif expected_data_words > 0:
            results.append((False, f"data.txt not created (expected {expected_data_words} word(s))"))
        else:
            results.append((True, "No .data section, data.txt not required"))

        # ── Check 4: Exact match against .expected file ───────────────────────
        if os.path.exists(expected_path):
            try:
                expected_lines = []
                with open(expected_path) as ef:
                    for line in ef:
                        line = line.strip()
                        if line and not line.startswith('#'):
                            expected_lines.append(int(line, 16))
                mismatches = []
                for i, (got, exp) in enumerate(zip(words, expected_lines)):
                    if got != exp:
                        mismatches.append(
                            f"  [{i:2d}] got 0x{got:08x} [{decode_instr(got)}]"
                            f" | expected 0x{exp:08x} [{decode_instr(exp)}]"
                        )
                if len(words) != len(expected_lines):
                    mismatches.append(
                        f"  Word count: got {len(words)}, expected {len(expected_lines)}"
                    )
                if not mismatches:
                    results.append((True, f"Exact match against .expected ({len(expected_lines)} words)"))
                else:
                    results.append((False, f"Mismatch against .expected:\n" + "\n".join(mismatches)))
            except Exception as e:
                warnings.append(f"Could not read .expected file: {e}")
        else:
            warnings.append("No .expected file — skipping exact match check")
            # Print decoded instructions for manual inspection
            lines = ["  Decoded instructions:"]
            for i, w in enumerate(words):
                lines.append(f"    [{i:2d}] 0x{w:08x}  {decode_instr(w)}")
            warnings.append("\n".join(lines))

    passed = all(ok for ok, _ in results)
    return passed, results, warnings


def main():
    assembler_bin = sys.argv[1] if len(sys.argv) > 1 else ASSEMBLER
    test_dir      = sys.argv[2] if len(sys.argv) > 2 else TEST_DIR

    assembler_bin = os.path.abspath(assembler_bin)
    test_dir      = os.path.abspath(test_dir)

    if not os.path.isfile(assembler_bin):
        print(f"{FAIL} Assembler not found: {assembler_bin}")
        print("Build it first:  g++ -o assembler assembler.cpp -std=c++17")
        sys.exit(1)

    asm_files = sorted(f for f in os.listdir(test_dir) if f.endswith('.s'))
    if not asm_files:
        print(f"No .s files found in {test_dir}")
        sys.exit(1)

    total = 0
    passed_count = 0
    print(f"\n{BOLD}=== Assembler Test Suite ==={RESET}")
    print(f"  Assembler : {assembler_bin}")
    print(f"  Tests dir : {test_dir}")
    print()

    for fname in asm_files:
        asm_path = os.path.join(test_dir, fname)
        total += 1
        passed, results, warnings = run_test(asm_path, assembler_bin)

        status = PASS if passed else FAIL
        print(f"{BOLD}[{fname}]{RESET}  {status}")

        for ok, msg in results:
            icon = "  ✓" if ok else "  ✗"
            color = "\033[92m" if ok else "\033[91m"
            # Handle multi-line messages (e.g. mismatch details)
            lines = msg.split('\n')
            print(f"{color}{icon} {lines[0]}{RESET}")
            for extra in lines[1:]:
                print(f"      {extra}")

        for w in warnings:
            lines = w.split('\n')
            print(f"\033[93m  ⚠ {lines[0]}{RESET}")
            for extra in lines[1:]:
                print(f"    {extra}")

        if passed:
            passed_count += 1
        print()

    print(f"{BOLD}Results: {passed_count}/{total} test files passed{RESET}")
    print()
    sys.exit(0 if passed_count == total else 1)


if __name__ == "__main__":
    main()