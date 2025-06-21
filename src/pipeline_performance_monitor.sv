module pipeline_performance_monitor (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic        branch_mispredict,
    output logic [31:0] total_cycles,
    output logic [31:0] stall_cycles,
    output logic [31:0] branch_mispredicts
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            total_cycles <= 32'b0;
        end else begin
            total_cycles <= total_cycles + 1;
        end
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            stall_cycles <= 32'b0;
        end else if (stall) begin
            stall_cycles <= stall_cycles + 1;
        end
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            branch_mispredicts <= 32'b0;
        end else if (branch_mispredict) begin
            branch_mispredicts <= branch_mispredicts + 1;
        end
    end

endmodule
