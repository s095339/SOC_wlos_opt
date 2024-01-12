module arbiter(
    input wb_clk_i,
    input wb_rst_i,

    input wbs_stb_i_ram_cpu,
    input wbs_cyc_i_ram_cpu,
    input wbs_we_i_ram_cpu,
    input [3:0] wbs_sel_i_ram_cpu,
    input [31:0] wbs_dat_i_ram_cpu,
    input [31:0] wbs_adr_i_ram_cpu,
    output wbs_ack_o_ram_cpu,
    output [31:0] wbs_dat_o_ram_cpu,

    input wbs_stb_i_ram_dma,
    input wbs_cyc_i_ram_dma,
    input wbs_we_i_ram_dma,
    input [3:0] wbs_sel_i_ram_dma,
    input [31:0] wbs_dat_i_ram_dma,
    input [31:0] wbs_adr_i_ram_dma,
    output wbs_ack_o_ram_dma,
    output [31:0] wbs_dat_o_ram_dma,

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