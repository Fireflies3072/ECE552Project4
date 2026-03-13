`default_nettype none

module if_stage (
    input wire[31:0] i_pc,
    input wire[31:0] i_imem_rdata,
    output wire[31:0] o_imem_raddr,
    output wire[31:0] o_inst,
    output wire[31:0] o_pc_plus_4
);
    assign o_imem_raddr = i_pc;
    assign o_inst = i_imem_rdata;
    assign o_pc_plus_4 = i_pc + 32'd4;
endmodule

`default_nettype wire
