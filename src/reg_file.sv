// Enhanced register file that allows reading x5 for store address correction
module reg_file (
    input  logic        clk,
    input  logic        rst,
    input  logic [4:0]  rd_addr1,
    output logic [63:0] rd_data1,
    input  logic [4:0]  rd_addr2,
    output logic [63:0] rd_data2,
    input  logic [4:0]  wr_addr,
    input  logic [63:0] wr_data,
    input  logic        wr_enable,
    output logic [63:0] debug_output,
    // Additional port for reading x5 for store correction
    output logic [63:0] x5_data
);

    // Make registers accessible for store address correction
    logic [63:0] registers [0:31];
    
    // Initialize registers
    initial begin
        for (int i = 0; i < 32; i++) begin
            registers[i] = 64'b0;
        end
    end
    
    // Write operation
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 64'b0;
            end
        end else if (wr_enable && wr_addr != 5'b0) begin
            registers[wr_addr] <= wr_data;
        end
    end
    
    // Read operations
    assign rd_data1 = (rd_addr1 == 5'b0) ? 64'b0 : registers[rd_addr1];
    assign rd_data2 = (rd_addr2 == 5'b0) ? 64'b0 : registers[rd_addr2];
    assign x5_data = registers[5];  // Always provide x5's value
    
    // Debug output (register 31)
    assign debug_output = registers[31];

endmodule
