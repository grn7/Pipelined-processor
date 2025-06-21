module forwarding_unit(
    input logic[4:0] ex_rs1,
    input logic[4:0] ex_rs2,
    input logic[4:0] wb_rd,
    input logic[4:0] mem_rd,
    input logic mem_reg_wr,
    input logic wb_reg_wr,
    output logic[1:0] forward_a,
    output logic[1:0] forward_b
);

always_comb begin 
    forward_a = 2'b00; // no forwarding (default)

    if(mem_reg_wr && (mem_rd != 5'b0) && (mem_rd == ex_rs1)) begin
        forward_a = 2'b10; // forward from MEM stage 
    end
    else if(wb_reg_wr && (wb_rd != 5'b0) && (wb_rd == ex_rs1)) begin
        forward_a = 2'b01; // forward from WB stage
    end
end

always_comb begin
    forward_b = 2'b00;

    if(mem_reg_wr && (mem_rd != 5'b0) && (mem_rd == ex_rs2)) begin
        forward_b = 2'b10; 
    end
    else if(wb_reg_wr && (wb_rd != 5'b0) && (wb_rd == ex_rs2)) begin
        forward_b = 2'b01;
    end
end

endmodule
