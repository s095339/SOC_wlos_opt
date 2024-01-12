module arbiter(
    input wb_clk_i,
    input wb_rst_i,

    input wbs_stb_i_cpu,
    input wbs_cyc_i_cpu,
    input wbs_we_i_cpu,
    input [3:0] wbs_sel_i_cpu,
    input [31:0] wbs_dat_i_cpu,
    input [31:0] wbs_adr_i_cpu,
    output wbs_ack_o_cpu,
    output [31:0] wbs_dat_o_cpu,

    input wbs_stb_i_dma,
    input wbs_cyc_i_dma,
    input wbs_we_i_dma,
    input [3:0] wbs_sel_i_dma,
    input [31:0] wbs_dat_i_dma,
    input [31:0] wbs_adr_i_dma,
    output wbs_ack_o_dma,
    output [31:0] wbs_dat_o_dma,

    output wbs_stb_o_ram,
    output wbs_cyc_o_ram,
    output wbs_we_o_ram,
    output [3:0] wbs_sel_o_ram,
    output [31:0] wbs_dat_o_ram,
    output [31:0] wbs_adr_o_ram,
    input wbs_ack_i_ram,
    input [31:0] wbs_dat_i_ram
);
endmodule