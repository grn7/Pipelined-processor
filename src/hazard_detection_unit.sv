module hazard_detection_unit(
    input logic[4:0] id_rs1, //source registers of instruction in ID stage
    input logic[4:0] id_rs2,
    input logic id_branch, //instruction in ID stage is a branch
    input logic id_mem_rd, //instruction in ID stage is a load
    input logic id_mem_wr, //instruction in ID stage is a store

    input logic[4:0] ex_rd, //destination register of instruction in EX stage
    input logic ex_mem_rd, //EX stage instruction is a load
    input logic ex_reg_wr, //EX stage instruction writes to register

    //MEM stage
    input logic[4:0] mem_rd,
    input logic mem_mem_rd,
    input logic mem_reg_wr,

    output logic stall, //freeze IF and ID stage
    output logic flush_id_ex //flush ID-EX pipeline register
);

//internal signals for hazard detection
logic load_hazard_ex; //load hazards in EX and MEM stage
logic load_hazard_mem;
logic branch_load_hazard; //branch depends on load (EX stage)
logic branch_load_hazard_mem; //MEM stage
logic double_load_hazard; //2 continuous loads,2nd one depends on first one

always_comb begin
    load_hazard_ex=1'b0;
    if(ex_mem_rd && (ex_rd!=5'b0) && ((ex_rd==id_rs1) || (ex_rd==id_rs2))) begin
        load_hazard_ex=1'b1;
    end
end

always_comb begin
    load_hazard_mem=1'b0;
    if(mem_mem_rd && (mem_rd!=5'b0) && ((mem_rd==id_rs1) || (mem_rd==id_rs2)) && !(ex_reg_wr && (ex_rd==id_rs1 || ex_rd==id_rs2))) begin //!ex_reg_wr to make sure EX stage doesn't provide data
        load_hazard_mem=1'b1;
    end
end

always_comb begin
    branch_load_hazard=1'b0;
    if(id_branch && ex_mem_rd && ex_rd!=5'b0 && ((ex_rd==id_rs1) || (ex_rd==id_rs2))) begin
        branch_load_hazard=1'b1;
    end
end

always_comb begin
    branch_load_hazard_mem=1'b0;
    if(id_branch && mem_mem_rd && mem_rd!=5'b0 && ((mem_rd==id_rs1) || (mem_rd==id_rs2))) begin
        branch_load_hazard_mem=1'b1;
    end
end

always_comb begin
    double_load_hazard = 1'b0;

    //ID stage instruction is load or store
    if ((id_mem_rd || id_mem_wr)) begin

        //dependency on load in EX stage
        if (ex_mem_rd && ex_rd != 5'b0 && (ex_rd == id_rs1)) begin
            double_load_hazard = 1'b1;
        end

        //dependency on load in MEM stage
        else if (mem_mem_rd && mem_rd != 5'b0 && (mem_rd == id_rs1)) begin
            double_load_hazard = 1'b1;
        end
    end
end

always_comb begin
    stall=load_hazard_ex || load_hazard_mem || branch_load_hazard || branch_load_hazard_mem || double_load_hazard;
end

assign flush_id_ex=stall;

endmodule