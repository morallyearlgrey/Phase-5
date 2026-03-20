// THIS IS AI SLOP
`timescale 1ns/1ps

module tb_top;

  // 1. Declare Testbench Signals
  reg clk;
  reg rst_n;
  integer cycle_count;

  // 2. Instantiate your Top-Level Processor
  // IMPORTANT: Change "RISCV_TOP" to the actual name of your top module
  RISCV_TOP uut (
    .iClk(clk),
    .iRstN(rst_n)
    // Add any other top-level ports your design requires here
  );

  // 3. Clock Generation (10ns period / 100MHz)
  always #5 clk = ~clk;

  // 4. Main Simulation Block
  initial begin
    // Set up waveform dumping (creates a wave.vcd file you can open in GTKWave)
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_top);

    // Initialize signals
    clk = 0;
    rst_n = 0;
    cycle_count = 0;

    $display("--- SIMULATION START ---");

    // Hold reset for 2 clock cycles to ensure everything clears
    #20;
    rst_n = 1;

    // Wait for the simulation to hit the autograder's limit
    wait(cycle_count >= 1000);
    
    $display("\n========================================================");
    $display(" TIMEOUT: Simulation stopped after 1000 cycles.");
    $display(" This perfectly mimics the autograder 'infinite loop' error.");
    $display("========================================================\n");
    $finish;
  end

  // 5. Cycle Counter & Trace Monitor
  always @(posedge clk) begin
    if (rst_n) begin
      cycle_count = cycle_count + 1;
      
      // Print out the PC and Instruction every cycle to see where it gets stuck!
      // NOTE: Ensure uut.wPc and uut.wInstr match the signal names in your top module
    //   $display("Cycle: %4d | PC: %h | Instr: %h", cycle_count, uut.wPc, uut.wInstr);
    //   $display("This is the instruction: %h", uut.wInstr);
    end
  end

endmodule