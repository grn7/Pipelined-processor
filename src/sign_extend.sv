`include "definitions.sv"

module sign_extend (
    input  logic [31:0] instr,
    output logic [63:0] imm_out
);

    // Different immediate formats
    logic [63:0] imm_i, imm_s, imm_b;
    
    // I-type immediate (bits [31:20]) - for LD and ADDI
    assign imm_i = {{52{instr[31]}}, instr[31:20]};
    
    // S-type immediate (bits [31:25] + [11:7]) - for SD
    assign imm_s = {{52{instr[31]}}, instr[31:25], instr[11:7]};
    
    // B-type immediate (bits: [31], [7], [30:25], [11:8], then <<1) - for BEQ
    assign imm_b = {{51{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

    // Select appropriate immediate based on instruction type
    assign imm_out = (instr[6:0] == `OP_S_TYPE) ? imm_s :
                     (instr[6:0] == `OP_B_TYPE) ? imm_b : imm_i;

endmodule