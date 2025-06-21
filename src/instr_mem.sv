module instr_mem #(
    parameter integer mem_size = 17, 
    parameter string  mem_file = "programs/fibo_comp.mem"
) (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    // Instruction array
    reg [31:0] memory_array [0:mem_size-1];
    
    // Initialize with NOP instructions first
    integer i;
    initial begin
        // Initialize all to NOP
        for (i = 0; i < mem_size; i = i + 1) begin
            memory_array[i] = 32'h00000013;  // NOP (addi x0, x0, 0)
        end
        
        // Load instructions from file
        $display("Loading instruction memory from %s", mem_file);
        $readmemh(mem_file, memory_array);
        
        // Display loaded instructions
        $display("Loaded instructions:");
        for (i = 0; i < mem_size && i < 20; i = i + 1) begin
            if (memory_array[i] != 32'h00000013) begin
                $display("  [%0d]: 0x%h", i, memory_array[i]);
            end
        end
    end

    // Output instruction
    wire [31:0] word_addr = address[31:2];
    assign instruction = (word_addr < mem_size) ? memory_array[word_addr] : 32'h00000013;

endmodule
