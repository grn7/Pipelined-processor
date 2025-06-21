module branch_predictor (
    input  logic        clk,
    input  logic        rst,
    input  logic [63:0] pc,
    input  logic        branch_taken,     // Actual branch outcome from EX stage
    input  logic        branch_resolved,  // Signal indicating branch is resolved
    input  logic [63:0] branch_pc,        // PC of the branch being resolved
    output logic        prediction        // 1 if branch predicted taken, 0 otherwise
);

    // 2-bit saturating counters: 
    // 00 = Strongly Taken
    // 01 = Weakly Taken
    // 10 = Weakly Not Taken
    // 11 = Strongly Not Taken
    logic [1:0] branch_history [15:0];

    wire [3:0] index = pc[5:2];
    wire [3:0] resolved_index = branch_pc[5:2];

    // Predict taken if MSB of counter is 0 (i.e. states 00 or 01)
    assign prediction = (branch_history[index][1] == 1'b0);

    // Update logic: 2-bit saturating counter update
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize all counters to 01: Weakly Taken (better for loops)
            for (int i = 0; i < 16; i++) begin
                branch_history[i] <= 2'b01;
            end
        end else if (branch_resolved) begin
            case (branch_history[resolved_index])
                2'b00: branch_history[resolved_index] <= branch_taken ? 2'b00 : 2'b01;
                2'b01: branch_history[resolved_index] <= branch_taken ? 2'b00 : 2'b10;
                2'b10: branch_history[resolved_index] <= branch_taken ? 2'b01 : 2'b11;
                2'b11: branch_history[resolved_index] <= branch_taken ? 2'b10 : 2'b11;
            endcase
        end
    end

endmodule
