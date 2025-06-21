// Pipeline Performance Monitor - Tracks performance metrics for analysis
// Counts cycles, stalls, and branch mispredictions to evaluate pipeline efficiency
module pipeline_performance_monitor (
    input  logic        clk,               // Clock for counter updates
    input  logic        rst,               // Reset to clear all counters
    input  logic        stall,             // Pipeline stall signal
    input  logic        branch_mispredict, // Branch misprediction signal
    output logic [31:0] total_cycles,      // Total number of clock cycles
    output logic [31:0] stall_cycles,      // Number of cycles spent stalled
    output logic [31:0] branch_mispredicts // Number of branch mispredictions
);

    // Total cycle counter - increments every clock cycle
    // Provides baseline for calculating performance ratios
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            total_cycles <= 32'b0;  // Reset counter to zero
        end else begin
            total_cycles <= total_cycles + 1;  // Increment every cycle
        end
    end
    
    // Stall cycle counter - increments when pipeline is stalled
    // High stall count indicates frequent data hazards
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            stall_cycles <= 32'b0;  // Reset counter to zero
        end else if (stall) begin
            stall_cycles <= stall_cycles + 1;  // Increment when stalled
        end
        // No increment when not stalled
    end
    
    // Branch misprediction counter - increments when prediction is wrong
    // High mispredict count indicates poor branch prediction accuracy
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            branch_mispredicts <= 32'b0;  // Reset counter to zero
        end else if (branch_mispredict) begin
            branch_mispredicts <= branch_mispredicts + 1;  // Increment on mispredict
        end
        // No increment when prediction is correct
    end

    // Performance metrics can be calculated from these counters:
    // - Pipeline efficiency = (total_cycles - stall_cycles) / total_cycles
    // - Branch prediction accuracy = 1 - (branch_mispredicts / total_branches)
    // - Average CPI (Cycles Per Instruction) considering stalls and mispredicts

endmodule
