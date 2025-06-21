module pc_logic_pipelined(
    input logic clk,
    input logic rst,
    input logic stall,
    input logic branch_taken,
    input logic[63:0] branch_target,
    input logic prediction_incorrect,
    input logic[63:0] corrected_pc,
    output logic[63:0] pc
);

logic[63:0] pc_next;

always_comb begin
    if(prediction_incorrect) begin
        pc_next = corrected_pc;
    end
    else if(stall) begin
        pc_next = pc;
    end
    else if(branch_taken) begin
        pc_next = branch_target;
    end
    else begin
        pc_next = pc + 64'd4;
    end
end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        pc <= 64'b0;
    end
    else begin
        pc <= pc_next;
    end
end

endmodule
