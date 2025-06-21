`timescale 1ps/1ps

module pipeline_performance_monitor_tb;
    // Clock and reset
    logic        clk;
    logic        rst;
    
    // Inputs
    logic        stall;
    logic        branch_mispredict;
    
    // Outputs
    logic [31:0] total_cycles;
    logic [31:0] stall_cycles;
    logic [31:0] branch_mispredicts;
    
    // Instantiate the Unit Under Test (UUT)
    pipeline_performance_monitor uut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .branch_mispredict(branch_mispredict),
        .total_cycles(total_cycles),
        .stall_cycles(stall_cycles),
        .branch_mispredicts(branch_mispredicts)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence
    initial begin
        $display("Starting Pipeline Performance Monitor Testbench");
        
        // Initialize inputs
        rst = 1;
        stall = 0;
        branch_mispredict = 0;
        
        // Release reset
        #10 rst = 0;
        
        // Run for 5 cycles
        repeat(5) @(posedge clk);
        
        $display("After 5 cycles:");
        $display("Total cycles: %d", total_cycles);
        $display("Stall cycles: %d", stall_cycles);
        $display("Branch mispredicts: %d", branch_mispredicts);
        
        // Add some stalls
        stall = 1;
        repeat(3) @(posedge clk);
        stall = 0;
        
        $display("\nAfter adding 3 stalls:");
        $display("Total cycles: %d", total_cycles);
        $display("Stall cycles: %d", stall_cycles);
        $display("Branch mispredicts: %d", branch_mispredicts);
        
        // Add some branch mispredictions
        branch_mispredict = 1;
        @(posedge clk);
        branch_mispredict = 0;
        @(posedge clk);
        branch_mispredict = 1;
        @(posedge clk);
        branch_mispredict = 0;
        
        $display("\nAfter adding 2 branch mispredictions:");
        $display("Total cycles: %d", total_cycles);
        $display("Stall cycles: %d", stall_cycles);
        $display("Branch mispredicts: %d", branch_mispredicts);
        
        // Run for a few more cycles
        repeat(3) @(posedge clk);
        
        $display("\nFinal counts:");
        $display("Total cycles: %d", total_cycles);
        $display("Stall cycles: %d", stall_cycles);
        $display("Branch mispredicts: %d", branch_mispredicts);
        
        $finish;
    end

endmodule
