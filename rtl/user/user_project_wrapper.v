// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);
//system_ram==========================
// cpu to sdram arbiter
wire wbs_stb_i_ram_cpu;
wire wbs_cyc_i_ram_cpu;
wire wbs_we_i_ram_cpu;
wire [3:0] wbs_sel_i_ram_cpu;
wire [31:0] wbs_dat_i_ram_cpu;
wire [31:0] wbs_adr_i_ram_cpu;
wire wbs_ack_o_ram_cpu;
wire [31:0] wbs_dat_o_ram_cpu;
//dma to sdram arbiter
wire wbs_stb_i_ram_dma;
wire wbs_cyc_i_ram_dma;
wire wbs_we_i_ram_dma;
wire [3:0] wbs_sel_i_ram_dma;
wire [31:0] wbs_dat_i_ram_dma;
wire [31:0] wbs_adr_i_ram_dma;
wire wbs_ack_o_ram_dma;
wire [31:0] wbs_dat_o_ram_dma;
// sdram arbiter to sdram
wire wbs_stb_i_ram;
wire wbs_cyc_i_ram;
wire wbs_we_i_ram;
wire [3:0] wbs_sel_i_ram;
wire [31:0] wbs_dat_i_ram;
wire [31:0] wbs_adr_i_ram;
wire wbs_ack_o_ram;
wire [31:0] wbs_dat_o_ram;
//fir===================================
// 傳axilite的
wire wbs_stb_i_fir;
wire wbs_cyc_i_fir;
wire wbs_we_i_fir;
wire [3:0] wbs_sel_i_fir;
wire [31:0] wbs_dat_i_fir;
wire [31:0] wbs_adr_i_fir;
wire wbs_ack_o_fir;
wire [31:0] wbs_dat_o_fir;
// axilite
wire                     awready;
wire                     wready;
wire                     awvalid;
wire [11:0] awaddr;
wire                     wvalid;
wire [31:0] wdata;
//read(output)---
wire                     arready;
wire                     rready;
wire                     arvalid;
wire [11:0] araddr;
wire                     rvalid;
wire [31:0] rdata;

//axisin---
wire                     ss_tvalid;
wire [31:0] ss_tdata;
wire                     ss_tlast; 
wire                     ss_tready; 
//axisout---
wire                     sm_tready; 
wire                     sm_tvalid; 
wire [31:0] sm_tdata;
wire                     sm_tlast; 


//bram
// ram for tap
wire [3:0]               tap_WE;
wire                     tap_EN;
wire [31:0] tap_Di;
wire [11:0] tap_A;
wire [31:0] tap_Do;

// ram for data RAM
wire [3:0]               data_WE;
wire                     data_EN;
wire [31:0] data_Di;
wire [11:0] data_A;
wire [31:0] data_Do;
//dma===================================
//cpu to dma
//傳start_addr length save_addr的
wire wbs_stb_i_dma;
wire wbs_cyc_i_dma;
wire wbs_we_i_dma;
wire [3:0] wbs_sel_i_dma;
wire [31:0] wbs_dat_i_dma;
wire [31:0] wbs_adr_i_dma;
wire wbs_ack_o_dma;
wire [31:0] wbs_dat_o_dma;
//decoder
wire [1:0] decode; // 00 cpu2ram 01 cpu2fir 10 cpu2dma
wire dma_irq;
assign user_irq = {2'b00, dma_irq};
//TODO 可能還會需要宣告一些訊號 axilite axistream之類的\
/*--------------------------------------*/
/* Decoder                              */
/*--------------------------------------*/
assign decode = (wbs_adr_i >= 32'h38000000 && wbs_adr_i < 32'h38400000)? 2'b00:
                (wbs_adr_i >= 32'h30000000 && wbs_adr_i < 32'h30000080)? 2'b01:
                (wbs_adr_i >= 32'h30000080 && wbs_adr_i < 32'h30000090)? 2'b10: 2'b11;

// cpu to ram(arbiter)
assign wbs_stb_i_ram_cpu = (decode == 2'b00)? wbs_stb_i : 1'd0;
assign wbs_cyc_i_ram_cpu = (decode == 2'b00)? wbs_cyc_i : 1'd0;
assign wbs_we_i_ram_cpu = (decode == 2'b00)? wbs_we_i : 4'd0;
assign wbs_sel_i_ram_cpu = (decode == 2'b00)? wbs_sel_i : 1'd0;
assign wbs_dat_i_ram_cpu = (decode == 2'b00)? wbs_dat_i : 32'd0;
assign wbs_adr_i_ram_cpu = (decode == 2'b00)? wbs_adr_i : 32'd0;
// cpu to fir
assign wbs_stb_i_fir = (decode == 2'b01)? wbs_stb_i : 1'd0;
assign wbs_cyc_i_fir = (decode == 2'b01)? wbs_cyc_i : 1'd0;
assign wbs_we_i_fir = (decode == 2'b01)? wbs_we_i : 4'd0;
assign wbs_sel_i_fir = (decode == 2'b01)? wbs_sel_i : 1'd0;
assign wbs_dat_i_fir = (decode == 2'b01)? wbs_dat_i : 32'd0;
assign wbs_adr_i_fir = (decode == 2'b01)? wbs_adr_i : 32'd0;
// cpu to dma
assign wbs_stb_i_dma = (decode == 2'b10)? wbs_stb_i : 1'd0;
assign wbs_cyc_i_dma = (decode == 2'b10)? wbs_cyc_i : 1'd0;
assign wbs_we_i_dma = (decode == 2'b10)? wbs_we_i : 4'd0;
assign wbs_sel_i_dma = (decode == 2'b10)? wbs_sel_i : 1'd0;
assign wbs_dat_i_dma = (decode == 2'b10)? wbs_dat_i : 32'd0;
assign wbs_adr_i_dma = (decode == 2'b10)? wbs_adr_i : 32'd0;

assign wbs_ack_o =  (decode == 2'b00)? wbs_ack_o_ram_cpu:
                    (decode == 2'b01)? wbs_ack_o_fir:
                    (decode == 2'b10)? wbs_ack_o_dma: 32'h0;
assign wbs_dat_o =  (decode == 2'b00)? wbs_dat_o_ram_cpu:
                    (decode == 2'b01)? wbs_dat_o_fir:
                    (decode == 2'b10)? wbs_dat_o_dma: 32'h0;


/*--------------------------------------*/
/* FIR                                  */
/*--------------------------------------*/
//TODO 把FIR 跟axilite那些寫進來
/*--------------------------------------*/
/* DMA                                  */
/*--------------------------------------*/
//TODO 把DMA寫進來

/*--------------------------------------*/
/* arbiter                              */
/*--------------------------------------*/

//assign wbs_stb_i_ram_dma = (decode == 2'b10)? wbs_stb_i : 1'd0;
//assign wbs_cyc_i_ram_dma = (decode == 2'b10)? wbs_cyc_i : 1'd0;
//assign wbs_we_i_ram_dma = (decode == 2'b10)? wbs_we_i : 4'd0;
//assign wbs_sel_i_ram_dma = (decode == 2'b10)? wbs_sel_i : 1'd0;
//assign wbs_dat_i_ram_dma = (decode == 2'b10)? wbs_dat_i : 32'd0;
//assign wbs_adr_i_ram_dma = (decode == 2'b10)? wbs_adr_i : 32'd0;

arbiter sdram_arbiter(
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    .wbs_stb_i_ram_cpu(wbs_stb_i_ram_cpu),
    .wbs_cyc_i_ram_cpu(wbs_cyc_i_ram_cpu),
    .wbs_we_i_ram_cpu(wbs_we_i_ram_cpu),
    .wbs_sel_i_ram_cpu(wbs_sel_i_ram_cpu),
    .wbs_dat_i_ram_cpu(wbs_dat_i_ram_cpu),
    .wbs_adr_i_ram_cpu(wbs_adr_i_ram_cpu),
    .wbs_ack_o_ram_cpu(wbs_ack_o_ram_cpu),
    .wbs_dat_o_ram_cpu(wbs_dat_o_ram_cpu),

    .wbs_stb_i_ram_dma(wbs_stb_i_ram_dma),
    .wbs_cyc_i_ram_dma(wbs_cyc_i_ram_dma),
    .wbs_we_i_ram_dma(wbs_we_i_ram_dma),
    .wbs_sel_i_ram_dma(wbs_sel_i_ram_dma),
    .wbs_dat_i_ram_dma(wbs_dat_i_ram_dma),
    .wbs_adr_i_ram_dma(wbs_adr_i_ram_dma),
    .wbs_ack_o_ram_dma(wbs_ack_o_ram_dma),
    .wbs_dat_o_ram_dma(wbs_dat_o_ram_dma),

    .wbs_stb_o_ram(wbs_stb_i_ram),
    .wbs_cyc_o_ram(wbs_cyc_i_ram),
    .wbs_we_o_ram(wbs_we_i_ram),
    .wbs_sel_o_ram(wbs_sel_i_ram),
    .wbs_dat_o_ram(wbs_dat_i_ram),
    .wbs_adr_o_ram(wbs_adr_i_ram),
    .wbs_ack_i_ram(wbs_ack_o_ram),
    .wbs_dat_i_ram(wbs_dat_o_ram)
);

/*--------------------------------------*/
/* System_ram                           */
/*--------------------------------------*/
//sdram
wire [2:0]temp;
system_ram mprj (
`ifdef USE_POWER_PINS
	.vccd1(vccd1),	// User area 1 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
`endif

    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wbs_cyc_i(wbs_cyc_i_ram),
    .wbs_stb_i(wbs_stb_i_ram),
    .wbs_we_i(wbs_we_i_ram),
    .wbs_sel_i(wbs_sel_i_ram),
    .wbs_adr_i(wbs_adr_i_ram),
    .wbs_dat_i(wbs_dat_i_ram),
    .wbs_ack_o(wbs_ack_o_ram),
    .wbs_dat_o(wbs_dat_o_ram),

    // Logic Analyzer

    .la_data_in(la_data_in),
    .la_data_out(la_data_out),
    .la_oenb (la_oenb),

    // IO Pads

    .io_in (io_in),
    .io_out(io_out),
    .io_oeb(io_oeb),

    // IRQ
    .irq(temp)
);
dma DMA(
    // CPU <====> DMA
    .clk(wb_clk_i),
    .rst(~wb_rst_i),
    .cpu2d_stb_i(wbs_stb_i_dma),
    .cpu2d_cyc_i(wbs_cyc_i_dma),
    .cpu2d_we_i(wbs_we_i_dma),
    .cpu2d_sel_i(wbs_sel_i_dma),
    .cpu2d_dat_i(wbs_dat_i_dma),
    .cpu2d_adr_i(wbs_adr_i_dma),

    .d2cpu_ack_o(wbs_ack_o_dma),
    .d2cpu_dat_o(wbs_dat_o_dma),
    // DMA <====> SDRAM
    .d2srm_stb_o(wbs_stb_i_ram_dma),
    .d2srm_cyc_o(wbs_cyc_i_ram_dma),
    .d2srm_we_o(wbs_we_i_ram_dma),
    .d2srm_sel_o(wbs_sel_i_ram_dma),
    .d2srm_dat_o(wbs_dat_i_ram_dma),
    .d2srm_adr_o(wbs_adr_i_ram_dma),

    .srm2d_ack_i(wbs_ack_o_ram_dma),
    .srm2d_dat_i(wbs_dat_o_ram_dma),
    // DMA <====> FIR
    .dma2fir_valid(ss_tvalid),
    .dma2fir_data(ss_tdata),
    .dma2fir_last(ss_tlast),
    .fir2dma_ready(ss_tready),
    .dma2fir_ready(sm_tready),
    .fir2dma_valid(sm_tvalid),
    .fir2dma_data(sm_tdata),
    .fir2dma_last(sm_tlast),
    .dma_irq(dma_irq)
);
fir FIR(
    //axilite ports
    //write(input)--
    .awready(awready),
    .wready(wready),
    .awvalid(awvalid),
    .awaddr(awaddr),
    .wvalid(wvalid),
    .wdata(wdata),
    //read(output)---
    .arready(arready),
    .rready(rready),
    .arvalid(arvalid),
    .araddr(araddr),
    .rvalid(rvalid),
    .rdata(rdata),
//axistream ports
    .ss_tvalid(ss_tvalid),
    .ss_tdata(ss_tdata),
    .ss_tlast(ss_tlast),
    .ss_tready(ss_tready),

    .sm_tvalid(sm_tvalid),
    .sm_tdata(sm_tdata),
    .sm_tlast(sm_tlast),
    .sm_tready(sm_tready),

    // ram for tap
    .tap_WE(tap_WE),
    .tap_EN(tap_EN),
    .tap_Di(tap_Di),
    .tap_A(tap_A),
    .tap_Do(tap_Do),

    // ram for data
    .data_WE(data_WE),
    .data_EN(data_EN),
    .data_Di(data_Di),
    .data_A(data_A),
    .data_Do(data_Do),

    .axis_clk(wb_clk_i),
    .axis_rst_n(~wb_rst_i)
);
bram11 tap_RAM (
    .clk(wb_clk_i),
    .we(|tap_WE & tap_EN),
    .re(~(|tap_WE) & tap_EN),
    .waddr(tap_A),
    .raddr(tap_A),
    .wdi(tap_Di),
    .rdo(tap_Do)
);

bram11 data_RAM(
    .clk(wb_clk_i),
    .we(|data_WE & data_EN),
    .re(~(|data_WE) & data_EN),
    .waddr(data_A),
    .raddr(data_A),
    .wdi(data_Di),
    .rdo(data_Do)
);
wb_axilite wb_lite(
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(~wb_rst_i),
    .wbs_stb_i(wbs_stb_i_fir),
    .wbs_cyc_i(wbs_cyc_i_fir),
    .wbs_we_i(wbs_we_i_fir),
    .wbs_sel_i(wbs_sel_i_fir),
    .wbs_dat_i(wbs_dat_i_fir),
    .wbs_adr_i(wbs_adr_i_fir),
    .wbs_ack_o(wbs_ack_o_fir),
    .wbs_dat_o(wbs_dat_o_fir),
    //axilite ports=================================
    //write(input)--
    .awready(awready),
    .wready(wready),
    .awvalid(awvalid),
    .awaddr(awaddr),
    .wvalid(wvalid),
    .wdata(wdata),
    //read(output)---
    .arready(arready),
    .rready(rready),
    .arvalid(arvalid),
    .araddr(araddr),
    .rvalid(rvalid),
    .rdata(rdata)
);
endmodule	// user_project_wrapper

`default_nettype wire
