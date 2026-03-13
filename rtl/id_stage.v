`default_nettype none

module id_stage (
    input wire i_clk,
    input wire i_rst,
    input wire[31:0] i_inst,

    input wire[4:0] i_wb_rd_addr,
    input wire[31:0] i_wb_rd_data,
    input wire i_wb_reg_wen,

    output wire[4:0] o_rs1_addr,
    output wire[4:0] o_rs2_addr,
    output wire[4:0] o_rd_addr,
    output wire[2:0] o_funct3,

    output wire[31:0] o_imm,
    output wire[31:0] o_rs1_data,
    output wire[31:0] o_rs2_data,

    output wire[2:0]  o_alu_opsel,
    output wire[1:0]  o_wb_mux,
    output wire o_reg_wen,
    output wire o_alu_src1,
    output wire o_alu_src2,
    output wire o_alu_sub,
    output wire o_alu_unsigned,
    output wire o_alu_arith,
    output wire o_mem_ren,
    output wire o_mem_wen,
    output wire o_branch,
    output wire o_jump,
    output wire o_jalr,
    output wire o_halt,

    output wire o_uses_rs1,
    output wire o_uses_rs2
);
    wire[6:0] id_opcode = i_inst[6:0];
    wire[2:0] id_funct3 = i_inst[14:12];
    wire[6:0] id_funct7 = i_inst[31:25];

    assign o_rs1_addr = i_inst[19:15];
    assign o_rs2_addr = i_inst[24:20];
    assign o_rd_addr = i_inst[11:7];
    assign o_funct3 = id_funct3;

    wire[5:0] id_imm_format;

    control_unit ctrl (
        .i_opcode(id_opcode),
        .i_funct3(id_funct3),
        .i_funct7(id_funct7),
        .o_reg_wen(o_reg_wen),
        .o_alu_src1(o_alu_src1),
        .o_alu_src2(o_alu_src2),
        .o_alu_opsel(o_alu_opsel),
        .o_alu_sub(o_alu_sub),
        .o_alu_unsigned(o_alu_unsigned),
        .o_alu_arith(o_alu_arith),
        .o_imm_format(id_imm_format),
        .o_mem_ren(o_mem_ren),
        .o_mem_wen(o_mem_wen),
        .o_wb_mux(o_wb_mux),
        .o_branch(o_branch),
        .o_jump(o_jump),
        .o_jalr(o_jalr),
        .o_halt(o_halt)
    );

    imm imm_g (
        .i_inst(i_inst),
        .i_format(id_imm_format),
        .o_immediate(o_imm)
    );

    rf #(
        .BYPASS_EN(1)
    ) rf_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_raddr(o_rs1_addr),
        .o_rs1_rdata(o_rs1_data),
        .i_rs2_raddr(o_rs2_addr),
        .o_rs2_rdata(o_rs2_data),
        .i_rd_waddr(i_wb_rd_addr),
        .i_rd_wdata(i_wb_rd_data),
        .i_rd_wen(i_wb_reg_wen)
    );

    assign o_uses_rs1 = (id_opcode == 7'b0110011) | // R-type
                        (id_opcode == 7'b0010011) | // I-op
                        (id_opcode == 7'b0000011) | // load
                        (id_opcode == 7'b0100011) | // store
                        (id_opcode == 7'b1100011) | // branch
                        (id_opcode == 7'b1100111);  // jalr

    assign o_uses_rs2 = (id_opcode == 7'b0110011) | // R-type
                        (id_opcode == 7'b0100011) | // store
                        (id_opcode == 7'b1100011);  // branch
endmodule

`default_nettype wire
