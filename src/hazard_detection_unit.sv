module hazard_detection_unit (
    input  logic [4:0]  id_rs1,
    input  logic [4:0]  id_rs2,
    input  logic        id_branch,
    input  logic        id_mem_rd,
    input  logic        id_mem_wr,
    input  logic [4:0]  ex_rd,
    input  logic        ex_mem_rd,
    input  logic        ex_reg_wr,
    input  logic [4:0]  mem_rd,
    input  logic        mem_mem_rd,
    input  logic        mem_reg_wr,
    output logic        stall,
    output logic        flush_id_ex
);

    logic load_use_hazard;
    logic store_data_hazard;
    
    // Traditional load-use hazard detection
    assign load_use_hazard = ex_mem_rd && 
                            ((ex_rd == id_rs1) || (ex_rd == id_rs2)) &&
                            (ex_rd != 5'b0);
    
    // CRITICAL: Store data hazard detection
    // Detect when a store instruction needs data from an instruction in EX stage
    assign store_data_hazard = id_mem_wr &&                    // Current instruction is store
                              ex_reg_wr &&                     // Previous instruction writes register
                              (ex_rd == id_rs2) &&             // Store source = previous destination
                              (ex_rd != 5'b0) &&               // Not writing to x0
                              !ex_mem_rd;                      // Previous is not load (ALU result)
    
    // Stall for either hazard
    assign stall = load_use_hazard || store_data_hazard;
    assign flush_id_ex = 1'b0;  // We use stalling, not flushing

endmodule