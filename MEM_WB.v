module MEM_WB(
    input  wire        clk,
    input  wire        rst,

    // Control signals from MEM
    input  wire        iMemToReg,
    input  wire        iRegWrite,

    // Data signals
    input  wire [31:0] i_mem_data,
    input  wire [31:0] i_ALU_result,
    input  wire [4:0]  i_rd_num,

    // Output to WB stage
    output reg         oMemToReg,
    output reg         oRegWrite,

    output reg [31:0]  o_mem_data,
    output reg [31:0]  o_ALU_result,
    output reg [4:0]   o_rd_num
);

always @(posedge clk) begin
    if (rst) begin
        oMemToReg    <= 1'b0;
        oRegWrite    <= 1'b0;

        o_mem_data   <= 32'b0;
        o_ALU_result <= 32'b0;
        o_rd_num     <= 5'b00000;
    end
    else begin
        oMemToReg    <= iMemToReg;
        oRegWrite    <= iRegWrite;

        o_mem_data   <= i_mem_data;
        o_ALU_result <= i_ALU_result;
        o_rd_num     <= i_rd_num;
    end
end

endmodule