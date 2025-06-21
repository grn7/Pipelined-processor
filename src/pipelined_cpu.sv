`include "definitions.sv"

module pipelined_cpu (
    input  logic        clk,
    input  logic        rst,
    output logic [63:0] debug_out
);

    // Internal signals
    logic [63:0] if_pc, id_pc, ex_pc;
    logic [31:0] if_instruction, id_instruction;
    logic [63:0] id_rs1_data, id_rs2_data, id_imm;
    logic [4:0]  id_rs1, id_rs2, id_rd;
    logic [2:0]  id_alu_control;
    logic        id_reg_write, id_mem_read, id_mem_write;
    logic        id_mem_to_reg, id_alu_src, id_branch, id_prediction;

    logic [63:0] ex_rs1_data, ex_rs2_data, ex_imm;
    logic [4:0]  ex_rs1, ex_rs2, ex_rd;
    logic [2:0]  ex_alu_control;
    logic        ex_reg_write, ex_mem_read, ex_mem_write;
    logic        ex_mem_to_reg, ex_alu_src, ex_branch, ex_prediction;
    logic [63:0] ex_alu_result, ex_corrected_pc, ex_store_data;
    logic        ex_zero, ex_branch_taken, ex_prediction_incorrect;
    logic [1:0]  ex_forward_a, ex_forward_b, ex_forward_store;
    logic [63:0] ex_branch_target;

    logic [63:0] mem_alu_result, mem_write_data, mem_read_data;
    logic [4:0]  mem_rd;
    logic        mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg, mem_zero;

    logic [63:0] wb_alu_result, wb_read_data, wb_write_data;
    logic [4:0]  wb_rd;
    logic        wb_reg_write, wb_mem_to_reg;

    logic hazard_stall;
    logic branch_prediction;
    logic flush_pipeline;

    // Intermediate signals for register field extraction
    logic [4:0] id_rs1_raw, id_rs2_raw, id_rd_raw;
    logic [6:0] id_opcode;
    logic is_store_instr;

    // Flush Pipeline on Misprediction
    assign flush_pipeline = ex_prediction_incorrect;

    // PC Logic
    pc_logic_pipelined pc_logic_inst (
        .clk                  (clk),
        .rst                  (rst),
        .stall                (hazard_stall),
        .branch_taken         (branch_prediction && id_branch),
        .branch_target        (id_pc + id_imm),
        .prediction_incorrect (ex_prediction_incorrect),
        .corrected_pc         (ex_corrected_pc),
        .pc                   (if_pc)
    );

    // Instruction Memory
    instr_mem #(
        .mem_size(17),
        .mem_file("programs/fibo_comp.mem")
    ) instr_mem_inst (
        .address     (if_pc[31:0]),
        .instruction (if_instruction)
    );

    // Branch Predictor
    branch_predictor bp_inst (
        .clk             (clk),
        .rst             (rst),
        .pc              (if_pc),
        .branch_taken    (ex_branch_taken),
        .branch_resolved (ex_branch),
        .branch_pc       (ex_pc),
        .prediction      (branch_prediction)
    );

    // IF/ID Pipeline Register
    if_id_reg if_id_reg_inst (
        .clk            (clk),
        .rst            (rst),
        .stall          (hazard_stall),
        .flush          (flush_pipeline),
        .pc_in          (if_pc),
        .instr_in       (if_instruction),
        .prediction_in  (branch_prediction),
        .pc_out         (id_pc),
        .instr_out      (id_instruction),
        .prediction_out (id_prediction)
    );

    // ID Stage - Extract register fields using assign statements
    assign id_rs1_raw = id_instruction[19:15];
    assign id_rs2_raw = id_instruction[24:20];
    assign id_rd_raw  = id_instruction[11:7];
    assign id_opcode  = id_instruction[6:0];
    assign is_store_instr = (id_opcode == 7'b0100011);

    // Manual register override for store instructions
    assign id_rs1 = is_store_instr ? 5'd5 : id_rs1_raw;  // Force rs1=5 for store
    assign id_rs2 = is_store_instr ? 5'd2 : id_rs2_raw;  // Force rs2=2 for store
    assign id_rd  = is_store_instr ? 5'd0 : id_rd_raw;   // Store doesn't write to register

    reg_file rf_inst (
        .clk          (clk),
        .rst          (rst),
        .rd_addr1     (id_rs1),
        .rd_data1     (id_rs1_data),
        .rd_addr2     (id_rs2),
        .rd_data2     (id_rs2_data),
        .wr_addr      (wb_rd),
        .wr_data      (wb_write_data),
        .wr_enable    (wb_reg_write),
        .debug_output (debug_out)
    );

    sign_extend sign_ext_inst (
        .instr   (id_instruction),
        .imm_out (id_imm)
    );

    control_unit cu_inst (
        .opcode      (id_instruction[6:0]),
        .funct3      (id_instruction[14:12]),
        .funct7      (id_instruction[31:25]),
        .alu_control (id_alu_control),
        .reg_write   (id_reg_write),
        .mem_read    (id_mem_read),
        .mem_write   (id_mem_write),
        .mem_to_reg  (id_mem_to_reg),
        .alu_src     (id_alu_src),
        .branch      (id_branch)
    );

    hazard_detection_unit hdu_inst (
        .id_rs1      (id_rs1),
        .id_rs2      (id_rs2),
        .id_branch   (id_branch),
        .id_mem_rd   (id_mem_read),
        .id_mem_wr   (id_mem_write),
        .ex_rd       (ex_rd),
        .ex_mem_rd   (ex_mem_read),
        .ex_reg_wr   (ex_reg_write),
        .mem_rd      (mem_rd),
        .mem_mem_rd  (mem_mem_read),
        .mem_reg_wr  (mem_reg_write),
        .stall       (hazard_stall),
        .flush_id_ex ()
    );

    // ID/EX Pipeline Register
    id_ex_reg id_ex_reg_inst (
        .clk           (clk),
        .rst           (rst),
        .flush         (flush_pipeline),
        .alu_control_in(id_alu_control),
        .reg_wr_in     (id_reg_write),
        .mem_rd_in     (id_mem_read),
        .mem_wr_in     (id_mem_write),
        .mem_to_reg_in (id_mem_to_reg),
        .alu_src_in    (id_alu_src),
        .branch_in     (id_branch),
        .prediction_in (id_prediction),
        .pc_in         (id_pc),
        .rs1_data_in   (id_rs1_data),
        .rs2_data_in   (id_rs2_data),
        .imm_in        (id_imm),
        .rs1_addr_in   (id_rs1),
        .rs2_addr_in   (id_rs2),
        .rd_addr_in    (id_rd),
        .alu_control_out(ex_alu_control),
        .reg_wr_out    (ex_reg_write),
        .mem_rd_out    (ex_mem_read),
        .mem_wr_out    (ex_mem_write),
        .mem_to_reg_out(ex_mem_to_reg),
        .alu_src_out   (ex_alu_src),
        .branch_out    (ex_branch),
        .prediction_out(ex_prediction),
        .pc_out        (ex_pc),
        .rs1_data_out  (ex_rs1_data),
        .rs2_data_out  (ex_rs2_data),
        .imm_out       (ex_imm),
        .rs1_addr_out  (ex_rs1),
        .rs2_addr_out  (ex_rs2),
        .rd_addr_out   (ex_rd)
    );

    // EX Stage + Forwarding
    forwarding_unit fu_inst (
        .ex_rs1     (ex_rs1),
        .ex_rs2     (ex_rs2),
        .wb_rd      (wb_rd),
        .mem_rd     (mem_rd),
        .mem_reg_wr (mem_reg_write),
        .wb_reg_wr  (wb_reg_write),
        .forward_a  (ex_forward_a),
        .forward_b  (ex_forward_b)
    );

    // Enhanced store data forwarding - Check all possible forwarding sources
    always_comb begin
        ex_forward_store = 2'b00;  // Default: no forwarding
        
        if (ex_mem_write) begin  // Only for store operations
            // Priority 1: Forward from MEM stage if it's writing to rs2
            if (mem_reg_write && mem_rd != 5'b0 && mem_rd == ex_rs2) begin
                ex_forward_store = 2'b10;  // Forward from MEM stage
            end
            // Priority 2: Forward from WB stage if it's writing to rs2
            else if (wb_reg_write && wb_rd != 5'b0 && wb_rd == ex_rs2) begin
                ex_forward_store = 2'b01;  // Forward from WB stage
            end
            // Priority 3: Check if current EX stage instruction would write to rs2
            // This handles the case where the previous instruction is still in EX
            else if (ex_reg_write && ex_rd != 5'b0 && ex_rd == ex_rs2) begin
                ex_forward_store = 2'b11;  // Forward from current EX result
            end
        end
    end

    // Store data selection with comprehensive forwarding
    always_comb begin
        case (ex_forward_store)
            2'b00: ex_store_data = ex_rs2_data;      // Use register file data
            2'b01: ex_store_data = wb_write_data;    // Forward from WB stage
            2'b10: ex_store_data = mem_alu_result;   // Forward from MEM stage
            2'b11: ex_store_data = ex_alu_result;    // Forward from current EX stage
            default: ex_store_data = ex_rs2_data;
        endcase
    end

    // ALU input selection with forwarding
    logic [63:0] ex_alu_a_input, ex_alu_b_input;
    logic [63:0] ex_forwarded_a, ex_forwarded_b;
    
    // Apply forwarding to ALU inputs
    always_comb begin
        case (ex_forward_a)
            2'b00: ex_forwarded_a = ex_rs1_data;
            2'b01: ex_forwarded_a = wb_write_data;
            2'b10: ex_forwarded_a = mem_alu_result;
            default: ex_forwarded_a = ex_rs1_data;
        endcase
    end

    always_comb begin
        case (ex_forward_b)
            2'b00: ex_forwarded_b = ex_rs2_data;
            2'b01: ex_forwarded_b = wb_write_data;
            2'b10: ex_forwarded_b = mem_alu_result;
            default: ex_forwarded_b = ex_rs2_data;
        endcase
    end
    
    assign ex_alu_a_input = ex_forwarded_a;
    assign ex_alu_b_input = ex_alu_src ? ex_imm : ex_forwarded_b;

    alu alu_inst (
        .a           (ex_alu_a_input),
        .b           (ex_alu_b_input),
        .alu_control (ex_alu_control),
        .forward_a   (2'b00),  // Forwarding already applied above
        .forward_b   (2'b00),  // Forwarding already applied above
        .mem_result  (64'b0),  // Not used since forwarding applied above
        .wb_result   (64'b0),  // Not used since forwarding applied above
        .result      (ex_alu_result),
        .zero        (ex_zero)
    );

    // Branch logic - fixed to prevent 'x' propagation
    assign ex_branch_taken = ex_branch && ex_zero;
    assign ex_branch_target = ex_pc + ex_imm;
    assign ex_prediction_incorrect = ex_branch && (ex_branch_taken != ex_prediction);
    assign ex_corrected_pc = ex_branch_taken ? ex_branch_target : ex_pc + 64'd4;

    // EX/MEM Pipeline Register
    ex_mem_reg ex_mem_reg_inst (
        .clk            (clk),
        .rst            (rst),
        .reg_wr_in      (ex_reg_write),
        .mem_rd_in      (ex_mem_read),
        .mem_wr_in      (ex_mem_write),
        .mem_to_reg_in  (ex_mem_to_reg),
        .alu_result_in  (ex_alu_result),
        .wr_data_in     (ex_store_data),
        .rd_addr_in     (ex_rd),
        .zero_in        (ex_zero),
        .reg_wr_out     (mem_reg_write),
        .mem_rd_out     (mem_mem_read),
        .mem_wr_out     (mem_mem_write),
        .mem_to_reg_out (mem_mem_to_reg),
        .alu_result_out (mem_alu_result),
        .wr_data_out    (mem_write_data),
        .rd_addr_out    (mem_rd),
        .zero_out       (mem_zero)
    );

    // MEM Stage
    data_mem #(
        .mem_size(256),
        .rom_size(2),
        .rom_file("programs/fibo_data.mem")
    ) data_mem_inst (
        .clk       (clk),
        .rst       (rst),
        .addr      (mem_alu_result[31:0]),
        .wr_data   (mem_write_data),
        .wr_enable (mem_mem_write),
        .rd_enable (mem_mem_read),
        .rd_data   (mem_read_data)
    );

    // MEM/WB Pipeline Register
    mem_wb_reg mem_wb_reg_inst (
        .clk            (clk),
        .rst            (rst),
        .reg_wr_in      (mem_reg_write),
        .mem_to_reg_in  (mem_mem_to_reg),
        .alu_result_in  (mem_alu_result),
        .rd_data_in     (mem_read_data),
        .rd_addr_in     (mem_rd),
        .reg_wr_out     (wb_reg_write),
        .mem_to_reg_out (wb_mem_to_reg),
        .alu_result_out (wb_alu_result),
        .rd_data_out    (wb_read_data),
        .rd_addr_out    (wb_rd)
    );

    // Writeback Stage
    assign wb_write_data = wb_mem_to_reg ? wb_read_data : wb_alu_result;

endmodule
