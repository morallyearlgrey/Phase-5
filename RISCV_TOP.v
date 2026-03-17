module RISCV_TOP (
    input iClk,
    input iRstN
  );

  // Internal Wires
  reg [31:0] wPC;
  initial
    wPC = 32'h0;
  wire [31:0] wNextPC, wInstr, wImm;
  wire [6:0] wOpcode, wFunct7;
  wire [2:0] wFunct3;
  wire [4:0] wRd, wRs1, wRs2;
  wire [31:0] wRs1Data, wRs2Data, wAluDataA, wAluDataB, wAluResult, wMemReadData, wWriteData, wMemToRegData;
  wire [3:0] wAluCtrl;
  wire wAluZero;

  // PC+4: return address for JAL/JALR
  wire [31:0] wPcPlus4;
  assign wPcPlus4 = wPC + 32'd4;

  // Control Signals
  wire wLui, wPcSrc, wMemRd, wMemWr, wMemtoReg, wAluSrc1, wAluSrc2, wRegWrite, wBranch, wJump;
  wire [2:0] wAluOp;

  // --- Program Counter ---
  always @(posedge iClk or negedge iRstN)
  begin
    if (~iRstN)
    begin
      wPC <= 32'h0;
    end
    else
    begin
      wPC <= wNextPC;
    end
  end

  // --- Instruction Memory ---
  INSTRUCTION_MEMORY instr_mem (
                       .iRdAddr(wPC),
                       .oInstr(wInstr)
                     );

  // --- Decoder ---
  DECODER decoder (
            .iInstr(wInstr),
            .oOpcode(wOpcode),
            .oRd(wRd),
            .oFunct3(wFunct3),
            .oRs1(wRs1),
            .oRs2(wRs2),
            .oFunct7(wFunct7),
            .oImm(wImm)
          );

  // --- Control Unit ---
  CONTROL control (
            .iOpcode(wOpcode),
            .oLui(wLui),
            .oPcSrc(wPcSrc),
            .oMemRd(wMemRd),
            .oMemWr(wMemWr),
            .oAluOp(wAluOp),
            .oMemtoReg(wMemtoReg),
            .oAluSrc1(wAluSrc1),
            .oAluSrc2(wAluSrc2),
            .oRegWrite(wRegWrite),
            .oBranch(wBranch),
            .oJump(wJump)
          );

  // --- Register File ---
  REGISTER register (
             .iClk(iClk),
             .iRstN(iRstN),
             .iWriteEn(wRegWrite),
             .iRdAddr(wRd),
             .iRs1Addr(wRs1),
             .iRs2Addr(wRs2),
             .iWriteData(wFinalWriteData),
             .oRs1Data(wRs1Data),
             .oRs2Data(wRs2Data)
           );

  // --- ALU Source Muxes ---
  MUX_2_1 #(32) alu_src1_mux (
            .iData0(wRs1Data),
            .iData1(wPC),
            .iSel(wAluSrc1),
            .oData(wAluDataA)
          );

  MUX_2_1 #(32) alu_src2_mux (
            .iData0(wRs2Data),
            .iData1(wImm),
            .iSel(wAluSrc2),
            .oData(wAluDataB)
          );

  // --- ALU Control ---
  ALU_CONTROL alu_control (
                .iAluOp(wAluOp),
                .iFunct3(wFunct3),
                .iFunct7(wFunct7),
                .oAluCtrl(wAluCtrl)
              );

  // --- ALU ---
  ALU alu (
        .iDataA(wAluDataA),
        .iDataB(wAluDataB),
        .iAluCtrl(wAluCtrl),
        .oData(wAluResult),
        .oZero(wAluZero)
      );

  // --- Data Memory ---
  DATA_MEMORY data_memory (
                .iClk(iClk),
                .iRstN(iRstN),
                .iAddress(wAluResult),
                .iWriteData(wRs2Data),
                .iFunct3(wFunct3),
                .iMemWrite(wMemWr),
                .iMemRead(wMemRd),
                .oReadData(wMemReadData)
              );

  // --- Writeback Muxes ---
  MUX_2_1 #(32) mem_to_reg_mux (
            .iData0(wAluResult),
            .iData1(wMemReadData),
            .iSel(wMemtoReg),
            .oData(wMemToRegData)
          );

  MUX_2_1 #(32) lui_mux (
            .iData0(wMemToRegData),
            .iData1(wImm),
            .iSel(wLui),
            .oData(wWriteData)
          );

  wire [31:0] wFinalWriteData;
  MUX_2_1 #(32) jump_wb_mux (
            .iData0(wWriteData),
            .iData1(wPcPlus4),
            .iSel(wJump),
            .oData(wFinalWriteData)
          );

  // --- Branch and Jump Unit ---
  BRANCH_JUMP branch_jump (
                .iBranch(wBranch),
                .iJump(wJump),
                .iZero(wAluZero),
                .iOffset(wImm),
                .iPc(wPC),
                .iRs1(wRs1Data),
                .iPcSrc(wPcSrc),
                .oPc(wNextPC)
              );

endmodule
