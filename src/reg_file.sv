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
    output logic [63:0] debug_output
);

    // 32 64-bit registers
    logic [63:0] registers [0:31];

    // Initialize registers properly
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 64'b0;
        end
    end

    // Read operations (combinational) - ensure x0 is always 0
    assign rd_data1 = (rd_addr1 == 5'b0) ? 64'b0 : registers[rd_addr1];
    assign rd_data2 = (rd_addr2 == 5'b0) ? 64'b0 : registers[rd_addr2];

    // Write operation (sequential) - prevent writing 'x' values
    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 64'b0;
            end
        end else if (wr_enable && wr_addr != 5'b0) begin
            // Only write if data is not 'x'
            if (wr_data !== 64'bx) begin
                registers[wr_addr] <= wr_data;
                // Reduced debug output to prevent spam - removed $display
            end else begin
                // Removed $display to fix synthesis warnings
            end
        end
    end

    // Debug output
    assign debug_output = registers[31];

endmodule
