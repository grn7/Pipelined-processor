`include "definitions.sv"

module alu (
    input  logic [63:0] a,
    input  logic [63:0] b,
    input  logic [2:0]  alu_control,
    input  logic [1:0]  forward_a,
    input  logic [1:0]  forward_b,
    input  logic [63:0] mem_result,
    input  logic [63:0] wb_result,
    output logic [63:0] result,
    output logic        zero
);

    // Define forwarding modes for readability
    localparam FWD_NONE = 2'b00;
    localparam FWD_WB   = 2'b01;
    localparam FWD_MEM  = 2'b10;

    logic [63:0] alu_a, alu_b;

    // Forwarding logic for both inputs
    always_comb begin
        // Operand A forwarding
        case (forward_a)
            FWD_NONE: alu_a = a;
            FWD_WB:   alu_a = wb_result;
            FWD_MEM:  alu_a = mem_result;
            default:  alu_a = 64'hAAAA_AAAAA_AAAA;  // Debug value
        endcase

        // Operand B forwarding
        case (forward_b)
            FWD_NONE: alu_b = b;
            FWD_WB:   alu_b = wb_result;
            FWD_MEM:  alu_b = mem_result;
            default:  alu_b = 64'hB0A_B0A_B0A;  // Debug value
        endcase
    end

    // ALU operation
    always_comb begin
        case (alu_control)
            `ALU_ADD: result = alu_a + alu_b;
            `ALU_SUB: result = alu_a - alu_b;
            `ALU_AND: result = alu_a & alu_b;
            `ALU_OR:  result = alu_a | alu_b;
            default:  result = 64'hBAD1234_BAD1234;  // Default invalid op
        endcase
    end

    // Zero flag
    assign zero = (result == 64'b0);

endmodule
