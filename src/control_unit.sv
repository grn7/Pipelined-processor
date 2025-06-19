`include "definitions.sv"
module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [2:0] alu_control,   
    output logic       reg_write,     
    output logic       mem_read,      
    output logic       mem_write,     
    output logic       mem_to_reg,    
    output logic       alu_src,       
    output logic       branch        
);
    always_comb begin
        // Default values
        alu_control = `ALU_ADD;
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;
        alu_src     = 1'b0;
        branch      = 1'b0;

        case (opcode)
            // I-Type (LD)
            `OP_I_TYPE: begin
                alu_control = `ALU_ADD;
                reg_write   = 1'b1;
                mem_read    = 1'b1;
                mem_write   = 1'b0;
                mem_to_reg  = 1'b1;
                alu_src     = 1'b1;
                branch      = 1'b0;
            end
            
            `OP_I_ALU: begin
                alu_control = `ALU_ADD;
                reg_write   = 1'b1;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                mem_to_reg  = 1'b0;
                alu_src     = 1'b1;  // Use immediate
                branch      = 1'b0;
            end

            // S-Type (SD)
            `OP_S_TYPE: begin
                alu_control = `ALU_ADD;  // Add rs1 + immediate for address
                reg_write   = 1'b0;
                mem_read    = 1'b0;
                mem_write   = 1'b1;
                mem_to_reg  = 1'b0;
                alu_src     = 1'b1;      // Use immediate for address calculation
                branch      = 1'b0;
            end

            // R-Type (ADD/SUB/AND/OR)
            `OP_R_TYPE: begin
                case (funct3)
                    `FUNC3_ADD_SUB: begin
                        if (funct7 == `FUNC7_SUB)
                            alu_control = `ALU_SUB;
                        else
                            alu_control = `ALU_ADD;
                    end
                    `FUNC3_AND: alu_control = `ALU_AND;
                    `FUNC3_OR:  alu_control = `ALU_OR;
                    default:    alu_control = `ALU_ADD;
                endcase
                
                reg_write   = 1'b1;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                mem_to_reg  = 1'b0;
                alu_src     = 1'b0;
                branch      = 1'b0;
            end

            // B-Type (BEQ)
            `OP_B_TYPE: begin
                alu_control = `ALU_SUB;  // Subtract to compare
                reg_write   = 1'b0;      // Don't write to register
                mem_read    = 1'b0;      // Don't access memory
                mem_write   = 1'b0;      // Don't access memory
                mem_to_reg  = 1'b0;      // Don't care
                alu_src     = 1'b0;      // Use register for comparison
                branch      = 1'b1;      // This is a branch instruction
            end

            default: begin
                // Only display warning if opcode is not all X's (uninitialized)
                if (opcode !== 7'bxxxxxxx) begin
                    $display("Warning: Unknown opcode: 0x%h", opcode);
                end
            end
        endcase
    end

endmodule