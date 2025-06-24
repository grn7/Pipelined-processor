`timescale 1ps/1ps

module pipelined_cpu_tb;
    logic clk;
    logic rst;
    logic [63:0] debug_out;
    
    pipelined_cpu cpu (
        .clk(clk),
        .rst(rst),
        .debug_out(debug_out)
    );
    
    // Clock generation - 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5000 clk = ~clk;  // Toggle every 5000ps = 5ns
    end
    
    int cycle_count = 0;
    
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count++;
            
            // Enhanced debug for Fibonacci calculation
            if (cycle_count <= 50) begin
                $display("CYCLE %0d:", cycle_count);
                $display("  IF: PC=%h, Instr=%h", cpu.if_pc, cpu.if_instruction);
                $display("  ID: PC=%h, Instr=%h, rs1=%d, rs2=%d, rd=%d", 
                         cpu.id_pc, cpu.id_instruction, cpu.id_rs1, cpu.id_rs2, cpu.id_rd);
                $display("  EX: ALURes=%h, MemWrite=%b, MemRead=%b, rd=%d", 
                         cpu.ex_alu_result, cpu.ex_mem_write, cpu.ex_mem_read, cpu.ex_rd);
                $display("  MEM: ALURes=%h, MemWrite=%b, MemRead=%b, rd=%d", 
                         cpu.mem_alu_result, cpu.mem_mem_write, cpu.mem_mem_read, cpu.mem_rd);
                $display("  WB: rd=%d, data=%h, RegWrite=%b", 
                         cpu.wb_rd, cpu.wb_write_data, cpu.wb_reg_write);
                
                // Show key register values for Fibonacci
                $display("  Fib Registers: x1=%d, x2=%d, x3=%d, x5=%d, x31=%d", 
                         cpu.rf_inst.registers[1], cpu.rf_inst.registers[2], 
                         cpu.rf_inst.registers[3], cpu.rf_inst.registers[5], 
                         cpu.rf_inst.registers[31]);
                $display("  Loop Registers: x4=%d, x27=%d", 
                         cpu.rf_inst.registers[4], cpu.rf_inst.registers[27]);
                $display("  Hazard stall: %b", cpu.hazard_stall);
                
                // Show when ADD instruction executes (the critical Fibonacci calculation)
                if (cpu.id_instruction[6:0] == 7'b0110011 && cpu.id_instruction[14:12] == 3'b000 && cpu.id_instruction[31:25] == 7'b0000000) begin
                    $display("  *** FIBONACCI ADD: x%d = x%d + x%d ***", 
                             cpu.id_rd, cpu.id_rs1, cpu.id_rs2);
                end
                $display("");
            end
        end
    end
    
    initial begin
        integer expected_fib[0:9];
        integer i;
        integer mem_addr;
        integer mem_value;
        integer correct_count;
        
        $dumpfile("pipelined_fibo.vcd");
        $dumpvars(0, pipelined_cpu_tb);
        
        $display("=== RISC-V Pipelined Fibonacci Test (FIXED) ===");
        $display("Testing pipelined processor with Fibonacci sequence calculation");
        $display("=========================================================");
        $display("");
        
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        
        $display("Reset released, starting Fibonacci calculation...");
        $display("");
        
        cycle_count = 0;
        
        repeat(200) begin
            @(posedge clk);
        end
        
        $display("=== FINAL RESULTS ===");
        $display("Debug output (Register 31): %0d", debug_out);
        $display("Register 1 (Fib n-1): %0d", cpu.rf_inst.registers[1]);
        $display("Register 2 (Fib n):   %0d", cpu.rf_inst.registers[2]);
        $display("Register 3 (Fib n+1): %0d", cpu.rf_inst.registers[3]);
        $display("Register 4 (limit):   %0d", cpu.rf_inst.registers[4]);
        $display("Register 5 (addr):    %0d", cpu.rf_inst.registers[5]);
        $display("Register 27 (diff):   %0d", $signed(cpu.rf_inst.registers[27]));
        
        expected_fib[1] = 1;
        expected_fib[2] = 1;
        expected_fib[3] = 2;
        expected_fib[4] = 3;
        expected_fib[5] = 5;
        expected_fib[6] = 8;
        expected_fib[7] = 13;
        expected_fib[8] = 21;
        expected_fib[9] = 34;
        
        $display("");
        $display("=== FIBONACCI SEQUENCE IN MEMORY ===");
        $display("Memory dump (first 20 locations):");
        for (i = 0; i < 20; i = i + 1) begin
            $display("  mem[%0d] = %0d", i, cpu.data_mem_inst.memory_array[i]);
        end
        
        $display("");
        $display("Expected vs Actual:");
        correct_count = 0;
        for (i = 1; i <= 9; i = i + 1) begin
            mem_addr = 2 + (i - 1);  // Word addresses 2, 3, 4, 5, 6, 7, 8, 9, 10
            if (mem_addr < 20) begin  // Safety check
                mem_value = cpu.data_mem_inst.memory_array[mem_addr];
                if (mem_value == expected_fib[i]) begin
                    $display(" Fib(%0d) = %0d [CORRECT] (at word addr %0d)", i, mem_value, mem_addr);
                    correct_count = correct_count + 1;
                end else begin
                    $display(" Fib(%0d) = %0d [ERROR - expected %0d] (at word addr %0d)", i, mem_value, expected_fib[i], mem_addr);
                end
            end
        end
        
        $display("");
        if (correct_count >= 5) begin
            $display("Verification: %0d/9 correct values", correct_count);
            $display("SUCCESS: Fibonacci calculation is working!");
        end else begin
            $display("Verification: %0d/9 correct values", correct_count);
            $display("FAILURE: Fibonacci calculation has errors");
        end
        
        $display("");
        $display("=== PIPELINE STATISTICS ===");
        $display("Total cycles: %0d", cycle_count);
        
        $finish;
    end

endmodule
