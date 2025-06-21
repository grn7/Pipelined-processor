`timescale 1ps/1ps

// Testbench for Pipelined CPU - Tests Fibonacci sequence calculation
// Verifies correct operation of the 5-stage pipeline with hazard handling
module pipelined_cpu_tb;
    // Clock and reset signals
    logic clk;                // System clock
    logic rst;                // System reset
    logic [63:0] debug_out;   // Debug output from CPU (register 31)
    
    // Instantiate the Pipelined CPU under test
    pipelined_cpu cpu (
        .clk(clk),           // Connect clock
        .rst(rst),           // Connect reset
        .debug_out(debug_out) // Connect debug output
    );
    
    // Clock generation - 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5000 clk = ~clk;  // Toggle every 5000ps = 5ns
    end
    
    // Variables for tracking Fibonacci computation progress
    int prev_fib_count = 0;    // Previous count of computed Fibonacci numbers
    int current_fib_count = 0; // Current count of computed Fibonacci numbers
    int cycle_count = 0;       // Total number of clock cycles
    
    // Monitor instruction execution and pipeline behavior
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count++;
            
            // Track Fibonacci number computation progress
            // Register 5 contains the count of computed Fibonacci numbers
            current_fib_count = cpu.rf_inst.registers[5];
            
            // Check if a new Fibonacci number was computed
            if (current_fib_count > prev_fib_count && current_fib_count >= 3) begin
                $display("--- After %0d cycles: computed %0d fib numbers ---", 
                         cycle_count, current_fib_count);
                $display("");
                prev_fib_count = current_fib_count;
            end
            
            // Debug pipeline stages for first 20 cycles
            if (cycle_count <= 20) begin
                $display("CYCLE %0d:", cycle_count);
                $display("  IF: PC=%h, Instr=%h, Pred=%b", 
                         cpu.if_pc, cpu.if_instruction, cpu.branch_prediction);
                $display("  ID: PC=%h, Instr=%h, rs1=%d, rs2=%d, rd=%d, Pred=%b", 
                         cpu.id_pc, cpu.id_instruction, cpu.id_rs1, cpu.id_rs2, cpu.id_rd, cpu.id_prediction);
                $display("  EX: PC=%h, ALUOp=%b, rs1=%d, rs2=%d, rd=%d, result=%h, Pred=%b, Taken=%b, Incorrect=%b", 
                         cpu.ex_pc, cpu.ex_alu_control, cpu.ex_rs1, cpu.ex_rs2, cpu.ex_rd, 
                         cpu.ex_alu_result, cpu.ex_prediction, cpu.ex_branch_taken, cpu.ex_prediction_incorrect);
                $display("  MEM: ALURes=%h, MemWrite=%b, MemRead=%b, rd=%d", 
                         cpu.mem_alu_result, cpu.mem_mem_write, cpu.mem_mem_read, cpu.mem_rd);
                $display("  WB: rd=%d, data=%h, RegWrite=%b", 
                         cpu.wb_rd, cpu.wb_write_data, cpu.wb_reg_write);
                $display("  Hazard: stall=%b", cpu.hazard_stall);
                $display("");
            end
        end
    end
    
    // Main test sequence
    initial begin
        // Variables for Fibonacci verification
        integer expected_fib[0:9];  // Expected Fibonacci values
        integer i;                  // Loop counter
        integer mem_addr;           // Memory address for checking
        integer mem_value;          // Memory value read
        integer correct_count;      // Count of correct values
        
        // Setup waveform dump for debugging
        $dumpfile("pipelined_fibo.vcd");
        $dumpvars(0, pipelined_cpu_tb);
        
        $display("=== RISC-V Pipelined Fibonacci Test ===");
        $display("Testing pipelined processor with Fibonacci sequence calculation");
        $display("=========================================================");
        $display("");
        
        // Reset the CPU for 5 clock cycles
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        
        $display("Reset released, starting Fibonacci calculation...");
        $display("");
        
        // Initialize tracking variables
        prev_fib_count = 0;
        cycle_count = 0;
        
        // Run for 120 cycles (more than single-cycle due to pipeline startup)
        repeat(120) begin
            @(posedge clk);
        end
        
        // Display final results
        $display("=== FINAL RESULTS ===");
        $display("Debug output (Register 31): %0d", debug_out);
        $display("Register 1 (Fib n-1): %0d", cpu.rf_inst.registers[1]);
        $display("Register 2 (Fib n):   %0d", cpu.rf_inst.registers[2]);
        $display("Register 3 (Fib n+1): %0d", cpu.rf_inst.registers[3]);
        $display("Register 5 (index):   %0d", cpu.rf_inst.registers[5]);
        
        // Initialize expected Fibonacci sequence for verification
        expected_fib[1] = 1;   // Fib(1) = 1
        expected_fib[2] = 1;   // Fib(2) = 1
        expected_fib[3] = 2;   // Fib(3) = 2
        expected_fib[4] = 3;   // Fib(4) = 3
        expected_fib[5] = 5;   // Fib(5) = 5
        expected_fib[6] = 8;   // Fib(6) = 8
        expected_fib[7] = 13;  // Fib(7) = 13
        expected_fib[8] = 21;  // Fib(8) = 21
        expected_fib[9] = 34;  // Fib(9) = 34
        
        // Check memory values against expected Fibonacci sequence
        $display("");
        $display("=== FIBONACCI SEQUENCE IN MEMORY ===");
        correct_count = 0;
        for (i = 1; i <= 9; i = i + 1) begin
            mem_addr = i + 1; // Offset: Fib(1) at addr 2, Fib(2) at addr 3, etc.
            mem_value = cpu.data_mem_inst.memory_array[mem_addr];
            if (mem_value == expected_fib[i]) begin
                $display(" Fib(%0d) = %0d [CORRECT]", i, mem_value);
                correct_count = correct_count + 1;
            end else begin
                $display(" Fib(%0d) = %0d [ERROR - expected %0d]", i, mem_value, expected_fib[i]);
            end
        end
        
        // Final verification summary
        $display("");
        if (correct_count == 9) begin
            $display("Verification: %0d/9 correct values", correct_count);
            $display("SUCCESS: Fibonacci calculation is CORRECT!");
        end else begin
            $display("Verification: %0d/9 correct values", correct_count);
            $display("FAILURE: Fibonacci calculation has errors");
        end
        
        // Display pipeline statistics
        $display("");
        $display("=== PIPELINE STATISTICS ===");
        $display("Total cycles: %0d", cycle_count);
        
        $finish;
    end

endmodule
