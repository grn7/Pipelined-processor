`include "definitions.sv"

module alu (
    input  logic [63:0] a,
    input  logic [63:0] b,
    input  logic [2:0]  alu_control,
    input  logic [1:0]  forward_a,      // Not used - forwarding handled externally
    input  logic [1:0]  forward_b,      // Not used - forwarding handled externally
    input  logic [63:0] mem_result,     // Not used - forwarding handled externally
    input  logic [63:0] wb_result,      // Not used - forwarding handled externally
    output logic [63:0] result,
    output logic        zero
);

    // ALU operation - simplified without internal forwarding
    always_comb begin
        case (alu_control)
            `ALU_ADD: result = a + b;
            `ALU_SUB: result = a - b;
            `ALU_AND: result = a & b;
            `ALU_OR:  result = a | b;
            default:  result = 64'b0;
        endcase
    end

    // Zero flag
    assign zero = (result == 64'b0);

endmodule
