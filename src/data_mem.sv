module data_mem #(
    parameter integer mem_size = 256,
    parameter integer rom_size = 2,
    parameter string  rom_file = "programs/fibo_data.mem"
) (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] addr,
    input  logic [63:0] wr_data,
    input  logic        wr_enable,
    input  logic        rd_enable,
    output logic [63:0] rd_data
);

    // Memory array
    reg [63:0] memory_array [0:mem_size-1];
    
    // Word address - use direct addressing
    wire [31:0] mem_addr = addr;

    // Initialize memory
    integer i;
    initial begin
        // Initialize all memory to zero
        for (i = 0; i < mem_size; i = i + 1) begin
            memory_array[i] = 64'b0;
        end
        
        // Load ROM data from file
        $display("Loading data memory from %s", rom_file);
        $readmemh(rom_file, memory_array, 0, rom_size-1);
        
        // Display loaded data
        $display("Loaded data memory:");
        for (i = 0; i < rom_size; i = i + 1) begin
            $display("  [%0d]: 0x%h (%0d)", i, memory_array[i], memory_array[i]);
        end
    end

    // Write operation
    always_ff @(posedge clk) begin
        if (wr_enable && mem_addr < mem_size) begin
            if (mem_addr >= rom_size) begin
                memory_array[mem_addr] <= wr_data;
                // Removed debug output to clean up testbench
            end else begin
                $display("WARNING: Attempted write to ROM region at address %0d", mem_addr);
            end
        end
    end

    // Read operation - always output data
    assign rd_data = (mem_addr < mem_size) ? memory_array[mem_addr] : 64'b0;

endmodule