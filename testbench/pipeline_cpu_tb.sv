`timescale 1ns / 1ps

module pipeline_cpu_tb;

    // Parameters
    parameter CLK_PERIOD = 10;

    // Signals
    reg clk;
    reg rst;
    wire [63:0] debug_out;

    // Instantiate the CPU with correct module name and ports
    pipelined_cpu dut (
        .clk(clk),
        .rst(rst),
        .debug_out(debug_out)
    );

    // Clock generation
    always begin
        clk = 0;
        #(CLK_PERIOD/2);
        clk = 1;
        #(CLK_PERIOD/2);
    end

    // Cycle counter
    integer cycle_count = 0;
    integer instruction_count = 0;  // Add instruction counter
    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            instruction_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            // Count instructions that complete (reach WB stage with RegWrite or MemWrite)
            if (dut.wb_reg_write || (dut.mem_mem_write && cycle_count > 5)) begin
                instruction_count <= instruction_count + 1;
            end
        end
    end

    // Enhanced pipeline status display with signed decimal values and instruction count
    always_ff @(posedge clk) begin
        if (!rst && cycle_count > 0 && cycle_count <= 200) begin
            $display("CYCLE %0d: (Instructions: %0d)", cycle_count, instruction_count);
            $display("  IF: PC=%016h, Instr=%08h", dut.if_pc, dut.if_instruction);
            $display("  ID: PC=%016h, Instr=%08h, rs1=%2d, rs2=%2d, rd=%2d", 
                     dut.id_pc, dut.id_instruction, dut.id_rs1, dut.id_rs2, dut.id_rd);
        
        // Enhanced EX stage display with signed decimal ALU results
        if (dut.ex_instruction[6:0] == 7'b0110011 && dut.ex_instruction[14:12] == 3'b000 && 
            dut.ex_instruction[31:25] == 7'b0000000 && dut.ex_rs1 == 5'd1 && dut.ex_rs2 == 5'd2 && dut.ex_rd == 5'd3) begin
            // This is the main Fibonacci ADD instruction
            $display("  EX: ALURes=%0d, MemWrite=%b, MemRead=%b, rd=%2d *** FIBONACCI: x1(%0d) + x2(%0d) = %0d ***", 
                     $signed(dut.ex_alu_result), dut.ex_mem_write, dut.ex_mem_read, dut.ex_rd,
                     $signed(dut.ex_forwarded_a), $signed(dut.ex_forwarded_b), $signed(dut.ex_alu_result));
        end else if (dut.ex_reg_write && dut.ex_rd != 5'b0 && 
                    dut.ex_instruction[6:0] == 7'b0110011 && dut.ex_instruction[14:12] == 3'b000 && 
                    dut.ex_instruction[31:25] == 7'b0000000) begin
            // Other ADD instructions
            $display("  EX: ALURes=%0d, MemWrite=%b, MemRead=%b, rd=%2d *** ADD: x%0d + x%0d = %0d ***", 
                     $signed(dut.ex_alu_result), dut.ex_mem_write, dut.ex_mem_read, dut.ex_rd,
                     $signed(dut.ex_forwarded_a), $signed(dut.ex_forwarded_b), $signed(dut.ex_alu_result));
        end else begin
            // Regular EX stage display with signed decimal
            $display("  EX: ALURes=%0d, MemWrite=%b, MemRead=%b, rd=%2d", 
                     $signed(dut.ex_alu_result), dut.ex_mem_write, dut.ex_mem_read, dut.ex_rd);
        end
        
        // MEM stage with signed decimal ALU result
        $display("  MEM: ALURes=%0d, MemWrite=%b, MemRead=%b, rd=%2d", 
                 $signed(dut.mem_alu_result), dut.mem_mem_write, dut.mem_mem_read, dut.mem_rd);
        
        // WB stage with signed decimal data and instruction completion indicator
        if (dut.wb_reg_write) begin
            $display("  WB: rd=%2d, data=%0d, RegWrite=%b *** INSTRUCTION COMPLETED ***", 
                     dut.wb_rd, $signed(dut.wb_write_data), dut.wb_reg_write);
        end else begin
            $display("  WB: rd=%2d, data=%0d, RegWrite=%b", 
                     dut.wb_rd, $signed(dut.wb_write_data), dut.wb_reg_write);
        end
        
        // Display key Fibonacci registers through register file
        $display("  Fib Registers: x1=%20d, x2=%20d, x3=%20d, x5=%20d, x31=%20d", 
                 $signed(dut.rf_inst.registers[1]), $signed(dut.rf_inst.registers[2]), $signed(dut.rf_inst.registers[3]), 
                 $signed(dut.rf_inst.registers[5]), $signed(dut.rf_inst.registers[31]));
        $display("  Loop Registers: x4=%20d, x27=%20d", 
                 $signed(dut.rf_inst.registers[4]), $signed(dut.rf_inst.registers[27]));
        $display("  Hazard stall: %b", dut.hazard_stall);
        
        // Special highlighting for Fibonacci ADD operations in ID stage
        if (dut.id_instruction[6:0] == 7'b0110011 && dut.id_instruction[14:12] == 3'b000 && 
            dut.id_instruction[31:25] == 7'b0000000 && dut.id_rs1 == 5'd1 && dut.id_rs2 == 5'd2 && dut.id_rd == 5'd3) begin
            $display("  *** FIBONACCI ADD: x%0d = x%0d + x%0d ***", dut.id_rd, dut.id_rs1, dut.id_rs2);
        end
        
        $display("");
    end
end

    // Additional real-time Fibonacci calculation monitor with signed values
    always_ff @(posedge clk) begin
        if (!rst && cycle_count > 0 && cycle_count <= 200) begin
            // Monitor when Fibonacci calculations actually complete (regardless of stalls)
            if (dut.ex_instruction[6:0] == 7'b0110011 && dut.ex_instruction[14:12] == 3'b000 && 
                dut.ex_instruction[31:25] == 7'b0000000 && dut.ex_rs1 == 5'd1 && dut.ex_rs2 == 5'd2 && 
                dut.ex_rd == 5'd3 && dut.ex_reg_write) begin
                $display(">>> CYCLE %0d: FIBONACCI RESULT COMPUTED: Fib(%0d) = %0d <<<", 
                         cycle_count, (cycle_count/17), $signed(dut.ex_alu_result));
            end
        end
    end

    // Test sequence
    initial begin
        $dumpfile("pipelined_fibo.vcd");
        $dumpvars(0, pipeline_cpu_tb);
        
        $display("=== RISC-V Pipelined Fibonacci Test (SIGNED DECIMAL DEBUG) ===");
        $display("Testing pipelined processor with signed decimal display");
        $display("==============================================================");
        $display("");

        // Initialize
        clk = 0;
        rst = 1;
        
        // Reset sequence
        #20;
        rst = 0;
        $display("Reset released, starting Fibonacci calculation...");
        $display("");

        // Run for enough cycles to complete Fibonacci calculation
        #2000;
        
        // Final results with signed decimal display and actual CPI calculation
        $display("=== FINAL RESULTS ===");
        $display("Debug output (Register 31): %0d", $signed(debug_out));
        $display("Register 1 (Fib n-1): %0d", $signed(dut.rf_inst.registers[1]));
        $display("Register 2 (Fib n):   %0d", $signed(dut.rf_inst.registers[2]));
        $display("Register 3 (Fib n+1): %0d", $signed(dut.rf_inst.registers[3]));
        $display("Register 4 (limit):   %0d", $signed(dut.rf_inst.registers[4]));
        $display("Register 5 (addr):    %0d", $signed(dut.rf_inst.registers[5]));
        $display("Register 27 (diff):   %0d", $signed(dut.rf_inst.registers[27]));
        $display("");

        // Memory dump with proper integer declaration
        $display("=== FIBONACCI SEQUENCE IN MEMORY ===");
        $display("Memory dump (first 20 locations):");
        begin : memory_dump
            integer i;
            for (i = 0; i < 20; i = i + 1) begin
                $display("  mem[%0d] = %0d", i, $signed(dut.data_mem_inst.memory_array[i]));
            end
        end
        $display("");

        // Verification
        $display("Expected vs Actual:");
        $display(" Fib(1) = 1 [%s] (at word addr 2)", (dut.data_mem_inst.memory_array[2] == 1) ? "CORRECT" : "ERROR");
        $display(" Fib(2) = 1 [%s] (at word addr 3)", (dut.data_mem_inst.memory_array[3] == 1) ? "CORRECT" : "ERROR");
        $display(" Fib(3) = 2 [%s] (at word addr 4)", (dut.data_mem_inst.memory_array[4] == 2) ? "CORRECT" : "ERROR");
        $display(" Fib(4) = 3 [%s] (at word addr 5)", (dut.data_mem_inst.memory_array[5] == 3) ? "CORRECT" : "ERROR");
        $display(" Fib(5) = 5 [%s] (at word addr 6)", (dut.data_mem_inst.memory_array[6] == 5) ? "CORRECT" : "ERROR");
        $display(" Fib(6) = 8 [%s] (at word addr 7)", (dut.data_mem_inst.memory_array[7] == 8) ? "CORRECT" : "ERROR");
        $display(" Fib(7) = 13 [%s] (at word addr 8)", (dut.data_mem_inst.memory_array[8] == 13) ? "CORRECT" : "ERROR");
        $display(" Fib(8) = 21 [%s] (at word addr 9)", (dut.data_mem_inst.memory_array[9] == 21) ? "CORRECT" : "ERROR");
        $display(" Fib(9) = 34 [%s] (at word addr 10)", (dut.data_mem_inst.memory_array[10] == 34) ? "CORRECT" : "ERROR");

        // Count correct values
        begin : verification
            integer correct_count;
            correct_count = 0;
            if (dut.data_mem_inst.memory_array[2] == 1) correct_count = correct_count + 1;
            if (dut.data_mem_inst.memory_array[3] == 1) correct_count = correct_count + 1;
            if (dut.data_mem_inst.memory_array[4] == 2) correct_count = correct_count + 1;
            if (dut.data_mem_inst.memory_array[5] == 3) correct_count = correct_count + 1;
            if (dut.data_mem_inst.memory_array[6] == 5) correct_count = correct_count + 1;
            if (dut.data_mem_inst.memory_array[7] == 8) correct_count = correct_count + 1;
            if (dut.data_mem_inst.memory_array[8] == 13) correct_count = correct_count + 1;
            if (dut.data_mem_inst.memory_array[9] == 21) correct_count = correct_count + 1;
            if (dut.data_mem_inst.memory_array[10] == 34) correct_count = correct_count + 1;
            
            $display("");
            $display("Verification: %0d/9 correct values", correct_count);
            if (correct_count == 9) begin
                $display("SUCCESS: Fibonacci calculation is working!");
            end else begin
                $display("ERROR: Some Fibonacci values are incorrect!");
            end
        end

        $display("");
        $display("=== PIPELINE PERFORMANCE STATISTICS ===");
        $display("Total cycles executed: %0d", cycle_count);
        $display("Total instructions completed: %0d", instruction_count);
        begin : cpi_calculation
            real cpi_value;
            if (instruction_count > 0) begin
                cpi_value = real'(cycle_count) / real'(instruction_count);
                $display("Cycles Per Instruction (CPI): %.3f", cpi_value);
                $display("Instructions Per Cycle (IPC): %.3f", real'(instruction_count) / real'(cycle_count));
            end else begin
                $display("ERROR: No instructions completed!");
            end
        end
        
        $finish;
    end

endmodule
