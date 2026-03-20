module IF_ID(
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,        // from hazard unit
    input  wire        flush,        // from branch/jump logic

    // Inputs from IF stage
    input  wire [31:0] i_PC,
    input  wire [31:0] i_instruction,

    // Outputs to ID stage
    output reg  [31:0] o_PC,
    output reg  [31:0] o_instruction
  );

  always @(posedge clk or posedge rst)
  begin
    if (!rst) begin
      o_PC <= 32'b0;
      o_instruction <= 32'h00000013;
    end 
    else if (flush) begin
      o_PC <= 32'b0;
      o_instruction <= 32'h00000013;
    end
    else if (!stall)
    begin
      o_PC          <= i_PC;
      o_instruction <= i_instruction;
    end
  end

endmodule
