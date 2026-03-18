// Two types of hazards: EX hazard and MEM hazard


// EX hazard pseudo code:
  // can do the same thing for each forward A and forward B, but for simplicity, i just did for forward A
/*
    if(EX/MEM.RegWrite && EX/MEM.RegisterRd != 0 && EX/MEM.RegisterRd == ID/EX.RegisterRs1) 
        ForwardA = 10; // Forward from EX/MEM
    else if(MEM/WB.RegWrite && MEM/WB.RegisterRd != 0 && MEM/WB.RegisterRd == ID/EX.RegisterRs) 
        ForwardA = 01; // Forward from MEM/WB
    else 
        ForwardA = 00; // No hazard
*/

//  MEM hazard pseudo code:
/*
    if(MEM/WB.RegWrite && MEM/WB.RegisterRd != 0 && MEM/WB.RegisterRd == ID/EX.RegisterRt) 
        ForwardA = 10; // Forward from MEM/WB
    else 
        ForwardA = 00; // No hazard
*/

// MUX Control Values:
/*
        ForwardA = 00 -> Source: ID/EX -> First ALU operand comes from register file
        ForwardA = 01 -> Source: MEM/WB -> First ALU operand forwarded from data mem OR earlier ALU result
        ForwardA = 10 -> Source: EX/MEM -> First ALU operand forwarded from prior ALU result
        
        ForwardB = 00 -> Source: ID/EX -> Second ALU operand comes from register file (no hazard)
        ForwardB = 01 -> Source: MEM/WB -> Second ALU operand forwarded from data mem OR earlier ALU result
        ForwardB = 10 -> Source: EX/MEM -> Second ALU operand forwarded from prior ALU result

*/
module hazard_detect(
    input wire iEXMemRegWrite,
    input wire [4:0] iEXMemRegisterRd,
    input wire [4:0] iIDExRegisterRs1,
    input wire [4:0] iIDExRegisterRs2,
    input wire iMemWbRegWrite,
    input wire [4:0] iMemWbRegisterRd,
    output reg [1:0] oForwardA,
    output reg [1:0] oForwardB
);

    always @(*) begin

        // ------------- EX HAZARD DETECTION -------------

        // EX hazard detection for ForwardA
        if (iEXMemRegWrite && (iEXMemRegisterRd != 0) && (iEXMemRegisterRd == iIDExRegisterRs1)) begin
            oForwardA = 2'b10; // Forward from EX/MEM
        end else if (iMemWbRegWrite && (iMemWbRegisterRd != 0) && (iMemWbRegisterRd == iIDExRegisterRs1)) begin
            oForwardA = 2'b01; // Forward from MEM/WB
        end else begin
            oForwardA = 2'b00; // No hazard
        end

        // EX hazard detection for ForwardB
        if (iEXMemRegWrite && (iEXMemRegisterRd != 0) && (iEXMemRegisterRd == iIDExRegisterRs2)) begin
            oForwardB = 2'b10; // Forward from EX/MEM
        end else if (iMemWbRegWrite && (iMemWbRegisterRd != 0) && (iMemWbRegisterRd == iIDExRegisterRs2)) begin
            oForwardB = 2'b01; // Forward from MEM/WB
        end else begin
            oForwardB = 2'b00; // No hazard
        end

        // ------------- MEM HAZARD DETECTION -------------
        
        // MEM hazard detection for ForwardA
        if (iMemWbRegWrite && (iMemWbRegisterRd != 0) && 
            !(iEXMemRegWrite && (iEXMemRegisterRd != 0) && 
                (iEXMemRegisterRd == iIDExRegisterRs1))
            && (iMemWbRegisterRd == iIDExRegisterRs1)) begin
            oForwardA = 2'b01; // Forward from MEM/WB
        end else begin
            oForwardA = 2'b00; // No hazard
        end

        // MEM hazard detection for ForwardB
        if (iMemWbRegWrite && (iMemWbRegisterRd != 0) && 
            !(iEXMemRegWrite && (iEXMemRegisterRd != 0) && 
                (iEXMemRegisterRd == iIDExRegisterRs2)) && 
            (iMemWbRegisterRd == iIDExRegisterRs2)) begin
            oForwardB = 2'b01; // Forward from MEM/WB
        end else begin
            oForwardB = 2'b00; // No hazard
        end
    end
