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

`default_nettype wire
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
    parameter BITS = 32,
    parameter DELAYS=10
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

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

// wrie to ram

reg wbs_stb_i_ram;
reg wbs_cyc_i_ram;
reg wbs_we_i_ram;
reg [3:0] wbs_sel_i_ram;
reg [31:0] wbs_dat_i_ram;
reg [31:0] wbs_adr_i_ram;
wire wbs_ack_o_ram;
wire [31:0] wbs_dat_o_ram;
//reg to uart

reg wbs_stb_i_uart;
reg wbs_cyc_i_uart;
reg wbs_we_i_uart;
reg [3:0] wbs_sel_i_uart;
reg [31:0] wbs_dat_i_uart;
reg [31:0] wbs_adr_i_uart;
wire wbs_ack_o_uart;
wire [31:0] wbs_dat_o_uart;
// reg for test
wire [31:0]wbs_adr_i_test;
wire [31:0]wbs_dat_i_test;

reg  ready;
reg  [BITS-17:0] delayed_count;


wire [1:0] decode; // 00null, 01:uart  10:bram 11:sofrware debugger  

assign decode = (wbs_adr_i >= 32'h30000000 && wbs_adr_i <= 32'h3000000c)? 2'b01 :
                (wbs_adr_i >= 32'h38000000)? 2'b10 : 
                (wbs_adr_i == 32'h30000090)? 2'b11: 2'b00;

assign wbs_dat_o = (decode == 2'b01)? wbs_dat_o_uart : 
                   (decode == 2'b10)? wbs_dat_o_ram: 
                   (decode == 2'b11)? 32'h94876487:
                   32'd0;

assign wbs_ack_o = (decode == 2'b01)? wbs_ack_o_uart : 
                   (decode == 2'b10)? wbs_ack_o_ram: 
                   (decode == 2'b11)? 1'b1 :1'd0;                 

assign wbs_adr_i_test = (decode == 2'b11)? wbs_adr_i:32'd0;
assign wbs_dat_i_test = (decode == 2'b11)? wbs_dat_i:32'd0;
assign wbs_ack_o_ram = ready;

always@*
    case(decode)
        2'b01:begin
            wbs_stb_i_uart = wbs_stb_i;
            wbs_cyc_i_uart = wbs_cyc_i;
            wbs_we_i_uart = wbs_we_i;
            wbs_sel_i_uart = wbs_sel_i;
            wbs_dat_i_uart = wbs_dat_i;
            wbs_adr_i_uart = wbs_adr_i;
        end
        2'b10:begin
            wbs_stb_i_uart = 1'd0;
            wbs_cyc_i_uart = 1'd0;
            wbs_we_i_uart = 1'd0;
            wbs_sel_i_uart = 1'd0;
            wbs_dat_i_uart = 32'd0;
            wbs_adr_i_uart = 32'd0;
        end
        default: begin
            wbs_stb_i_uart = 1'd0;
            wbs_cyc_i_uart = 1'd0;
            wbs_we_i_uart = 1'd0;
            wbs_sel_i_uart = 1'd0;
            wbs_dat_i_uart = 32'd0;
            wbs_adr_i_uart = 32'd0;
        end

    endcase

always@*
    case(decode)
        2'b10:begin
            wbs_stb_i_ram = wbs_stb_i;
            wbs_cyc_i_ram = wbs_cyc_i;
            wbs_we_i_ram = wbs_we_i;
            wbs_sel_i_ram = wbs_sel_i;
            wbs_dat_i_ram = wbs_dat_i;
            wbs_adr_i_ram = wbs_adr_i;
        end
        2'b01:begin
            wbs_stb_i_ram = 1'd0;
            wbs_cyc_i_ram = 1'd0;
            wbs_we_i_ram = 1'd0;
            wbs_sel_i_ram = 1'd0;
            wbs_dat_i_ram = 32'd0;
            wbs_adr_i_ram = 32'd0;
        end
        default: begin
            wbs_stb_i_ram = 1'd0;
            wbs_cyc_i_ram = 1'd0;
            wbs_we_i_ram = 1'd0;
            wbs_sel_i_ram = 1'd0;
            wbs_dat_i_ram = 32'd0;
            wbs_adr_i_ram = 32'd0;
        end

    endcase

assign valid = wbs_cyc_i_ram && wbs_stb_i_ram ; 
assign wstrb = wbs_sel_i_ram & {4{wbs_we_i_ram}};

always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
        ready <= 1'b0;
        delayed_count <= 16'b0;
    end else begin
        ready <= 1'b0;
        if ( valid && !ready ) begin
            if ( delayed_count == DELAYS ) begin
                delayed_count <= 16'b0;
                ready <= 1'b1;
            end else begin
                delayed_count <= delayed_count + 1;
            end
        end
    end
end


bram user_bram (
        .CLK(wb_clk_i),
        .WE0({4{wstrb}}),
        .EN0(valid),
        .Di0(wbs_dat_i_ram),
        .Do0(wbs_dat_o_ram),
        .A0(wbs_adr_i_ram)
    );



uart uart (
`ifdef USE_POWER_PINS
	.vccd1(vccd1),	// User area 1 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
`endif
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wbs_stb_i(wbs_stb_i_uart),
    .wbs_cyc_i(wbs_cyc_i_uart),
    .wbs_we_i(wbs_we_i_uart),
    .wbs_sel_i(wbs_sel_i_uart),
    .wbs_dat_i(wbs_dat_i_uart),
    .wbs_adr_i(wbs_adr_i_uart),
    .wbs_ack_o(wbs_ack_o_uart),
    .wbs_dat_o(wbs_dat_o_uart),

    // IO ports
    .io_in  (io_in      ),
    .io_out (io_out     ),
    .io_oeb (io_oeb     ),

    // irq
    .user_irq (user_irq)
);

endmodule	// user_project_wrapper

`default_nettype wire
