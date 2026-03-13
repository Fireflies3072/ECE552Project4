`default_nettype none

module wb_stage (
    input wire i_valid,
    input wire i_reg_wen,
    input wire[4:0] i_rd_addr,
    input wire[1:0] i_wb_mux,
    input wire[31:0] i_alu_result,
    input wire[31:0] i_load_data,
    input wire[31:0] i_pc,
    input wire[31:0] i_imm,

    output wire[4:0] o_wb_rd_addr,
    output wire[31:0] o_wb_rd_data,
    output wire o_wb_reg_wen
);
    assign o_wb_rd_addr = i_rd_addr;
    assign o_wb_reg_wen = i_valid && i_reg_wen;
    assign o_wb_rd_data = (i_wb_mux == 2'd0) ? i_alu_result :
                          (i_wb_mux == 2'd1) ? i_load_data :
                          (i_wb_mux == 2'd2) ? (i_pc + 32'd4) :
                          (i_wb_mux == 2'd3) ? i_imm :
                          32'd0;
endmodule

`default_nettype wire
