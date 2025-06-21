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
    
    // Word address (divide byte address by 8)
    wire [31:0] word_addr = addr[31:3];

    // Initialize memory
    integer i;
    initial begin
        // Initialize all memory to zero
        for (i = 0; i < mem_size; i = i + 1) begin
            memory_array[i] = 64'b0;
        end
        
        // Load ROM data from file
        $readmemh(rom_file, memory_array, 0, rom_size-1);
        
        $display("Data memory initialized:");
        for (i = 0; i < rom_size; i = i + 1) begin
            $display("  ROM[%0d] = %0d", i, memory_array[i]);
        end
    end

    // Write operation - allow writes to word addresses >= 2
    always_ff @(posedge clk) begin
        if (wr_enable && word_addr < mem_size) begin
            if (word_addr >= rom_size) begin  // Allow writes to word addr 2 and above
                memory_array[word_addr] <= wr_data;
                // Removed $display to fix synthesis warnings
            end else begin
                // Removed $display to fix synthesis warnings
            end
        end
    end

    // Read operation
    assign rd_data = (word_addr < mem_size) ? memory_array[word_addr] : 64'b0;

endmodule
