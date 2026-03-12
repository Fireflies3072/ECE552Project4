module control_unit (
    input  wire[6:0] i_opcode,
    input  wire[2:0] i_funct3,
    input  wire[6:0] i_funct7,
    output reg       o_reg_wen,  // 0: don't write register, 1: write register
    output reg       o_alu_src1, // 0: rs1, 1: pc
    output reg       o_alu_src2, // 0: rs2, 1: imm
    output reg[2:0]  o_alu_opsel, // ALU operation selection
    output reg       o_alu_sub,   // ALU subtraction
    output reg       o_alu_unsigned, // ALU unsigned comparison
    output reg       o_alu_arith, // ALU arithmetic right shift
    output reg[5:0]  o_imm_format,// Instruction format for imm gen
    output reg       o_mem_ren,  // 0: don't read memory, 1: read memory
    output reg       o_mem_wen,  // 0: don't write memory, 1: write memory
    output reg[1:0]  o_wb_mux,   // Write back: 0: ALU, 1: Mem, 2: PC+4, 3: Imm
    output reg       o_branch,   // 0: don't branch, 1: branch
    output reg       o_jump,     // 0: don't jump, 1: jump
    output reg       o_jalr,     // 0: don't jalr, 1: jalr
    output reg       o_halt      // 0: don't exit, 1: exit
);
    // ALU arithmetic operations
    localparam ALU_ADD_SUB = 3'b000;
    localparam ALU_SLL     = 3'b001;
    localparam ALU_SLT     = 3'b010;
    localparam ALU_SLTU    = 3'b011;
    localparam ALU_XOR     = 3'b100;
    localparam ALU_SRL_SRA = 3'b101;
    localparam ALU_OR      = 3'b110;
    localparam ALU_AND     = 3'b111;

    always @(*) begin
        // Initialize default output values
        o_reg_wen = 0;
        o_alu_src1 = 0;
        o_alu_src2 = 0;
        o_alu_opsel = 3'b000;
        o_alu_sub = 0;
        o_alu_unsigned = 0;
        o_alu_arith = 0;
        o_imm_format = 6'b000000;
        o_mem_ren = 0;
        o_mem_wen = 0;
        o_wb_mux = 2'd0;
        o_branch = 0;
        o_jump = 0;
        o_jalr = 0;
        o_halt = 0;

        case (i_opcode)
            7'b0110011: begin // R-type
                o_reg_wen = 1;
                o_alu_src2 = 0;
                o_wb_mux  = 2'd0;
                o_imm_format = 6'b000001;
                case (i_funct3)
                    3'b000: begin
                        o_alu_opsel = ALU_ADD_SUB;
                        o_alu_sub = i_funct7[5];
                    end
                    3'b001: o_alu_opsel = ALU_SLL;
                    3'b010: o_alu_opsel = ALU_SLT;
                    3'b011: begin
                        o_alu_opsel = ALU_SLTU;
                        o_alu_unsigned = 1;
                    end
                    3'b100: o_alu_opsel = ALU_XOR;
                    3'b101: begin
                        o_alu_opsel = ALU_SRL_SRA;
                        o_alu_arith = i_funct7[5];
                    end
                    3'b110: o_alu_opsel = ALU_OR;
                    3'b111: o_alu_opsel = ALU_AND;
                    default: o_alu_opsel = ALU_ADD_SUB;
                endcase
            end

            7'b0010011: begin // I-type (arithmetic, ex. addi, ...)
                o_reg_wen = 1;
                o_alu_src2 = 1;
                o_wb_mux  = 2'd0;
                o_imm_format = 6'b000010;
                case (i_funct3)
                    3'b000: o_alu_opsel = ALU_ADD_SUB; // addi
                    3'b001: o_alu_opsel = ALU_SLL; // slli
                    3'b010: o_alu_opsel = ALU_SLT; // slti
                    3'b011: begin
                        o_alu_opsel = ALU_SLTU; // sltiu
                        o_alu_unsigned = 1;
                    end
                    3'b100: o_alu_opsel = ALU_XOR; // xori
                    3'b101: begin
                        o_alu_opsel = ALU_SRL_SRA; // srai : srli
                        o_alu_arith = i_funct7[5];
                    end
                    3'b110: o_alu_opsel = ALU_OR; // ori
                    3'b111: o_alu_opsel = ALU_AND; // andi
                    default: o_alu_opsel = ALU_ADD_SUB;
                endcase
            end
            7'b0000011: begin // I-type (load, ex. lb, ...)
                o_reg_wen = 1;
                o_alu_src2 = 1;
                o_alu_opsel = ALU_ADD_SUB; // add address
                o_mem_ren = 1;
                o_wb_mux = 2'd1;
                o_imm_format = 6'b000010;
            end

            7'b0100011: begin // S-type (store, ex. sb, ...)
                o_alu_src2 = 1;
                o_alu_opsel = ALU_ADD_SUB; // add address
                o_mem_wen = 1;
                o_imm_format = 6'b000100;
            end

            7'b1100011: begin // B-type (branch, ex. beq, ...)
                o_branch = 1;
                o_alu_src2 = 0;
                o_imm_format = 6'b001000;
                case (i_funct3)
                    3'b000, 3'b001: o_alu_opsel = ALU_XOR; // beq, bne (use xor)
                    3'b100, 3'b101: o_alu_opsel = ALU_SLT; // blt, bge (use slt)
                    3'b110, 3'b111: begin
                        o_alu_opsel = ALU_SLTU; // bltu, bgeu (use sltu)
                        o_alu_unsigned = 1;
                    end
                    default: o_alu_opsel = ALU_ADD_SUB;
                endcase
            end

            7'b1101111: begin // J-type (jal)
                o_reg_wen = 1;
                o_jump = 1;
                o_wb_mux = 2'd2; // PC+4
                o_imm_format = 6'b100000;
            end

            7'b1100111: begin // I-type (jalr)
                o_reg_wen = 1;
                o_jalr = 1;
                o_alu_src2 = 1;
                o_alu_opsel = ALU_ADD_SUB; // rs1 + imm
                o_wb_mux = 2'd2; // PC+4
                o_imm_format = 6'b000010;
            end

            7'b0110111: begin // U-type (lui)
                o_reg_wen = 1;
                o_wb_mux = 2'd3; // imm
                o_imm_format = 6'b010000;
            end
            7'b0010111: begin // U-type (auipc)
                o_reg_wen = 1;
                o_alu_src1 = 1; // pc
                o_alu_src2 = 1; // imm
                o_alu_opsel = ALU_ADD_SUB;
                o_wb_mux = 2'd0; // ALU
                o_imm_format = 6'b010000;
            end

            7'b1110011: begin // System (ebreak)
                case (i_funct3)
                    3'b000: begin
                        case (i_funct7)
                            7'b0000000: o_halt = 1;
                            default: ;
                        endcase
                    end
                    default: ;
                endcase
            end

            default: ;
        endcase
    end
endmodule
