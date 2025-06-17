module forwarding_unit(
    input logic[4:0] ex_rs1,//source register addresses of instruction currently being executed(in EX stage)
    input logic[4:0] ex_rs2,
    input logic[4:0] wb_rd, //destination registers of instructions in MEM and WB stage
    input logic[4:0] mem_rd,
    input logic mem_reg_wr, //to check if it is writing to register
    input logic wb_reg_wr,
    output logic[1:0] forward_a,//forwarding control for ALU input 1 and 2
    output logic[1:0] forward_b
);

always_comb begin 
    forward_a=2'b0;//no forwarding(default)

    if(mem_reg_wr && (mem_rd!=5'b0) && (mem_rd==ex_rs1)) begin //give priority to forward from MEM stage if both MEM and WB have the value,as forwarding from MEM stage allows it to reach earlier
        forward_a=2'b10; //forward from MEM stage 
    end

    else if(wb_reg_wr && (wb_rd!=5'b0) && (wb_rd==ex_rs1)) begin
        forward_a=2'b1; //forward from WB stage
    end
end

always_comb begin
    forward_b=2'b0;

    if(mem_reg_wr && (mem_rd!=5'b0) && (mem_rd==ex_rs2)) begin
        forward_b=2'b10; 
    end

    else if(wb_reg_wr && (wb_rd!=5'b0) && (wb_rd==ex_rs2)) begin
        forward_b=2'b1;
    end
end

endmodule
