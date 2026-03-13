`default_nettype none

module ex_stage (
    input  wire i_valid,
    input  wire[31:0] i_pc,
    input  wire[31:0] i_next_pc_seq,
    input  wire[31:0] i_imm,
    input  wire[31:0] i_rs1_data,
    input  wire[31:0] i_rs2_data,
    input  wire        i_alu_src1,
    input  wire        i_alu_src2,
    input  wire[2:0]  i_alu_opsel,
    input  wire        i_alu_sub,
    input  wire        i_alu_unsigned,
    input  wire        i_alu_arith,
    input  wire[2:0]  i_funct3,
    input  wire        i_branch,
    input  wire        i_jump,
    input  wire        i_jalr,

    output wire[31:0] o_alu_result,
    output wire[31:0] o_next_pc,
    output wire        o_control_redirect
);
    wire[31:0] ex_alu_op_a = i_alu_src1 ? i_pc : i_rs1_data;
    wire[31:0] ex_alu_op_b = i_alu_src2 ? i_imm : i_rs2_data;
    wire        ex_alu_eq;
    wire        ex_alu_slt;

    alu alu_inst (
        .i_opsel(i_alu_opsel),
        .i_sub(i_alu_sub),
        .i_unsigned(i_alu_unsigned),
        .i_arith(i_alu_arith),
        .i_op1(ex_alu_op_a),
        .i_op2(ex_alu_op_b),
        .o_result(o_alu_result),
        .o_eq(ex_alu_eq),
        .o_slt(ex_alu_slt)
    );

    reg ex_take_branch;
    always @(*) begin
        case (i_funct3)
            3'b000: ex_take_branch = ex_alu_eq;   // beq
            3'b001: ex_take_branch = !ex_alu_eq;  // bne
            3'b100: ex_take_branch = ex_alu_slt;  // blt, bltu
            3'b101: ex_take_branch = !ex_alu_slt; // bge, bgeu
            3'b110: ex_take_branch = ex_alu_slt;  // bltu
            3'b111: ex_take_branch = !ex_alu_slt; // bgeu
            default: ex_take_branch = 1'b0;
        endcase
    end

    wire[31:0] ex_branch_target = i_pc + i_imm;
    wire[31:0] ex_jalr_target = o_alu_result & ~32'h1;

    assign o_next_pc = i_jump ? ex_branch_target :
                       i_jalr ? ex_jalr_target :
                       ((i_branch && ex_take_branch) ? ex_branch_target : i_next_pc_seq);
    assign o_control_redirect = i_valid && (i_jump || i_jalr || (i_branch && ex_take_branch));
endmodule

`default_nettype wire
