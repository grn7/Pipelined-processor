module sign_extend (
    input  logic [31:0] instr,
    output logic [63:0] imm_out
);

    // Different immediate formats
    logic [63:0] imm_i, imm_s, imm_b;
    logic [6:0] opcode;
    
    assign opcode = instr[6:0];
    
    // I-type immediate (bits [31:20]) - for LD and ADDI
    assign imm_i = {{52{instr[31]}}, instr[31:20]};
    
    // S-type immediate (bits [31:25] + [11:7]) - for SD
    assign imm_s = {{52{instr[31]}}, instr[31:25], instr[11:7]};
    
    // B-type immediate (bits: [31], [7], [30:25], [11:8], then <<1) - for BEQ/BNE
    // Fixed B-type immediate calculation
    assign imm_b = {{51{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

    // Select appropriate immediate based on instruction type
    always_comb begin
        case (opcode)
            7'b0100011: imm_out = imm_s;  // S-type (Store)
            7'b1100011: imm_out = imm_b;  // B-type (Branch)  
            default:    imm_out = imm_i;  // I-type (Load, ADDI)
        endcase
    end

endmodule
