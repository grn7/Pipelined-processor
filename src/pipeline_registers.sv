`include "definitions.sv"

module if_id_reg (
    input logic clk,
    input logic rst,
    input logic flush,
    input logic stall,

    input logic[63:0] pc_in,
    input logic[31:0] instr_in,
    input logic prediction_in,

    output logic[63:0] pc_out,
    output logic[31:0] instr_out,
    output logic prediction_out 
);

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        pc_out <= 64'b0;
        instr_out <= 32'h00000013;  // NOP instruction
        prediction_out <= 1'b0;
    end
    else if(flush) begin
        pc_out <= 64'b0;
        instr_out <= 32'h00000013;  // NOP instruction
        prediction_out <= 1'b0; 
    end
    else if(!stall) begin
        pc_out <= pc_in;
        instr_out <= instr_in;
        prediction_out <= prediction_in;
    end
end

endmodule

module id_ex_reg (
    input logic clk,
    input logic rst,
    input logic flush,

    input logic[2:0] alu_control_in,
    input logic reg_wr_in,
    input logic mem_wr_in,
    input logic mem_rd_in,
    input logic mem_to_reg_in,
    input logic branch_in,
    input logic prediction_in,
    input logic alu_src_in,

    input logic[63:0] pc_in,
    input logic[4:0] rs1_addr_in,
    input logic[4:0] rs2_addr_in,
    input logic[4:0] rd_addr_in,
    input logic[63:0] rs1_data_in,
    input logic[63:0] rs2_data_in,
    input logic[63:0] imm_in,
    input logic[31:0] instr_in,

    output logic[2:0] alu_control_out,
    output logic reg_wr_out,
    output logic mem_rd_out,
    output logic mem_wr_out,
    output logic mem_to_reg_out,
    output logic branch_out,
    output logic prediction_out,
    output logic alu_src_out,
    
    output logic[63:0] pc_out,
    output logic[4:0] rs1_addr_out,
    output logic[4:0] rs2_addr_out,
    output logic[4:0] rd_addr_out,
    output logic[63:0] rs1_data_out,
    output logic[63:0] rs2_data_out,
    output logic[63:0] imm_out,
    output logic[31:0] instr_out
);

always_ff @(posedge clk or posedge rst) begin
    if(rst || flush) begin
        alu_control_out <= 3'b0;
        alu_src_out <= 1'b0;
        mem_rd_out <= 1'b0;
        mem_wr_out <= 1'b0;
        reg_wr_out <= 1'b0;
        branch_out <= 1'b0;
        prediction_out <= 1'b0;
        mem_to_reg_out <= 1'b0;

        pc_out <= 64'b0;
        rs1_addr_out <= 5'b0;
        rs2_addr_out <= 5'b0;
        rd_addr_out <= 5'b0;
        rs1_data_out <= 64'b0;
        rs2_data_out <= 64'b0;
        imm_out <= 64'b0;
        instr_out <= 32'h00000013;
    end
    else begin
        alu_control_out <= alu_control_in;
        alu_src_out <= alu_src_in;
        branch_out <= branch_in;
        prediction_out <= prediction_in;
        mem_rd_out <= mem_rd_in;
        mem_wr_out <= mem_wr_in;
        reg_wr_out <= reg_wr_in;
        mem_to_reg_out <= mem_to_reg_in;

        pc_out <= pc_in;
        rs1_addr_out <= rs1_addr_in;
        rs2_addr_out <= rs2_addr_in;
        rd_addr_out <= rd_addr_in;
        rs1_data_out <= rs1_data_in;
        rs2_data_out <= rs2_data_in;
        imm_out <= imm_in;
        instr_out <= instr_in;
    end
end

endmodule

module ex_mem_reg(
    input logic clk,
    input logic rst,

    input logic reg_wr_in,
    input logic mem_rd_in,
    input logic mem_wr_in,
    input logic mem_to_reg_in,

    input logic[63:0] alu_result_in,
    input logic[63:0] wr_data_in,
    input logic[4:0] rd_addr_in,
    input logic zero_in,

    output logic reg_wr_out,
    output logic mem_rd_out,
    output logic mem_wr_out,
    output logic mem_to_reg_out,

    output logic[63:0] alu_result_out,
    output logic[4:0] rd_addr_out,
    output logic[63:0] wr_data_out,
    output logic zero_out
);

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        reg_wr_out <= 1'b0;
        mem_rd_out <= 1'b0;
        mem_wr_out <= 1'b0;
        mem_to_reg_out <= 1'b0;

        alu_result_out <= 64'b0;
        wr_data_out <= 64'b0;
        rd_addr_out <= 5'b0;
        zero_out <= 1'b0;
    end
    else begin
        reg_wr_out <= reg_wr_in;
        mem_rd_out <= mem_rd_in;
        mem_wr_out <= mem_wr_in;
        mem_to_reg_out <= mem_to_reg_in;

        alu_result_out <= alu_result_in;
        wr_data_out <= wr_data_in;
        rd_addr_out <= rd_addr_in;
        zero_out <= zero_in;
    end
end

endmodule

module mem_wb_reg(
    input logic clk,
    input logic rst,

    input logic mem_to_reg_in,
    input logic reg_wr_in,

    input logic[63:0] alu_result_in,
    input logic[63:0] rd_data_in,
    input logic[4:0] rd_addr_in,

    output logic mem_to_reg_out,
    output logic reg_wr_out,

    output logic[63:0] alu_result_out,
    output logic[63:0] rd_data_out,
    output logic[4:0] rd_addr_out
);

always_ff@(posedge clk or posedge rst) begin
    if(rst) begin
        reg_wr_out <= 1'b0;
        mem_to_reg_out <= 1'b0;

        alu_result_out <= 64'b0;
        rd_data_out <= 64'b0;
        rd_addr_out <= 5'b0;
    end
    else begin
        reg_wr_out <= reg_wr_in;
        mem_to_reg_out <= mem_to_reg_in;

        alu_result_out <= alu_result_in;
        rd_data_out <= rd_data_in;
        rd_addr_out <= rd_addr_in;
    end
end

endmodule
