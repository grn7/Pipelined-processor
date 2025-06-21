module hazard_detection_unit(
    input logic[4:0] id_rs1,
    input logic[4:0] id_rs2,
    input logic id_branch,
    input logic id_mem_rd,
    input logic id_mem_wr,

    input logic[4:0] ex_rd,
    input logic ex_mem_rd,
    input logic ex_reg_wr,

    input logic[4:0] mem_rd,
    input logic mem_mem_rd,
    input logic mem_reg_wr,

    output logic stall,
    output logic flush_id_ex
);

logic load_hazard_ex;
logic load_hazard_mem;
logic branch_load_hazard;
logic branch_load_hazard_mem;
logic double_load_hazard;
logic store_data_hazard;

always_comb begin
    load_hazard_ex = 1'b0;
    if(ex_mem_rd && (ex_rd != 5'b0) && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) begin
        load_hazard_ex = 1'b1;
    end
end

always_comb begin
    load_hazard_mem = 1'b0;
    if(mem_mem_rd && (mem_rd != 5'b0) && ((mem_rd == id_rs1) || (mem_rd == id_rs2)) && 
       !(ex_reg_wr && (ex_rd == id_rs1 || ex_rd == id_rs2))) begin
        load_hazard_mem = 1'b1;
    end
end

always_comb begin
    branch_load_hazard = 1'b0;
    if(id_branch && ex_mem_rd && ex_rd != 5'b0 && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) begin
        branch_load_hazard = 1'b1;
    end
end

always_comb begin
    branch_load_hazard_mem = 1'b0;
    if(id_branch && mem_mem_rd && mem_rd != 5'b0 && ((mem_rd == id_rs1) || (mem_rd == id_rs2))) begin
        branch_load_hazard_mem = 1'b1;
    end
end

always_comb begin
    double_load_hazard = 1'b0;

    if ((id_mem_rd || id_mem_wr)) begin
        if (ex_mem_rd && ex_rd != 5'b0 && (ex_rd == id_rs1)) begin
            double_load_hazard = 1'b1;
        end
        else if (mem_mem_rd && mem_rd != 5'b0 && (mem_rd == id_rs1)) begin
            double_load_hazard = 1'b1;
        end
    end
end

// Enhanced store data hazard detection
always_comb begin
    store_data_hazard = 1'b0;
    
    // If current instruction is a store and previous instruction writes to rs2
    if (id_mem_wr && ex_reg_wr && ex_rd != 5'b0 && ex_rd == id_rs2) begin
        store_data_hazard = 1'b1;
    end
end

always_comb begin
    stall = load_hazard_ex || load_hazard_mem || branch_load_hazard || 
            branch_load_hazard_mem || double_load_hazard || store_data_hazard;
end

assign flush_id_ex = stall;

endmodule
