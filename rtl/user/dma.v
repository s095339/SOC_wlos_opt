`timescale 1ns / 1ps
// Engineer: Chen
// 
// Create Date: 01/12/2024 03:34:47 PM
// Module Name: dma
//////////////////////////////////////////////////////////////////////////////////


module dma(
    input clk,
    input rst,
    // CPU <====> DMA
    input cpu2d_stb_i,
    input cpu2d_cyc_i,
    input cpu2d_we_i,
    input wire [3:0] cpu2d_sel_i,
    input wire [31:0] cpu2d_dat_i,
    input wire [31:0] cpu2d_adr_i,

    output d2cpu_ack_o,
    output wire [31:0] d2cpu_dat_o,

    // DMA <====> SDRAM
    output reg d2srm_stb_o,
    output reg d2srm_cyc_o,
    output reg d2srm_we_o,
    output reg [3:0] d2srm_sel_o,
    output reg [31:0] d2srm_dat_o,
    output reg [31:0] d2srm_adr_o,

    input srm2d_ack_i,
    input wire [31:0] srm2d_dat_i
    );
//----------- signal instantiation -----------//
// FIFO
reg [31:0] x_data_in;
reg x_rd;
reg x_wr;
wire [31:0] x_data_out;
wire x_empty;
wire x_full;
// Prepare
reg [95:0] cpu2d_data;
reg [1:0] cpu_access_cnt;
wire [31:0] srm_start_adr;
wire [31:0] srm_data_length;
wire [31:0] srm_save_adr;
wire dma_start;
// Dma
parameter IDLE  = 2'd0;
parameter READ  = 2'd1;
parameter WRITE = 2'd2;
reg [1:0] state;
reg [1:0] next_state;
// reg srm_wr;
wire srm_rd;
assign srm_rd = 1'd1;
reg [31:0] srm_adr_cnt;
reg [31:0] srm_adr_cnt_tmp;
wire x_data_end;
//----------- signal instantiation -----------//
// X Y FIFO
fifo 
#(
	.DATA_WIDTH	(32),
    .DATA_DEPTH	(4)
)
X_FIFO(
	.clk(clk),
	.rst(rst),
	.data_in(x_data_in),
	.rd_en(x_rd),
	.wr_en(x_wr),

	.data_out(x_data_out),
	.empty(x_empty),
	.full(x_full)
);
// fifo 
// #(
// 	.DATA_WIDTH	(32),
//     .DATA_DEPTH	(4)
// )
// Y_FIFO(
// 	.clk(clk),
// 	.rst(rst),
// 	.data_in(y_data_in),
// 	.rd_en(y_rd),
// 	.wr_en(y_wr),

//     .data_out_valid(y_out_valid),
// 	.data_out(y_data_out),
// 	.empty(y_empty),
// 	.full(y_full)
// );
// always @(*) begin
//     if(!x_full)begin
//         srm_rd = 1'd1;
//         srm_wr = 1'd0;
//     end
//     else if (x_full&&(!y_empty)) begin
//         srm_rd = 1'd0;
//         srm_wr = 1'd1;
//     end
//     else begin
//         srm_rd = 1'd0;
//         srm_wr = 1'd0;
//     end
// end
// Prepare
always @(posedge clk or negedge rst) begin
    if(!rst)begin
        // d2cpu_ack_o <= 1'd0;
        cpu2d_data <= 96'd0;
        cpu_access_cnt <= 2'd0;
    end
    else if(cpu2d_stb_i)begin
        // d2cpu_ack_o <= 1'd1;
        cpu2d_data <= {cpu2d_data[63:0], cpu2d_dat_i};
        cpu_access_cnt <= cpu_access_cnt + 1'd1;
    end
    else begin
        // d2cpu_ack_o <= 1'd0;
        cpu2d_data <= cpu2d_data;
        cpu_access_cnt <= cpu_access_cnt;
    end
end
assign d2cpu_ack_o = cpu2d_stb_i;
assign {srm_start_adr, srm_data_length, srm_save_adr} = cpu2d_data;
assign d2cpu_dat_o = 32'd0;
assign dma_start = (cpu_access_cnt==2'd3) ? 1'b1 : 1'b0;

//----------- DMA -----------//
// FSM
always @(*) begin
    case (state)
        IDLE: begin
            if(dma_start&&srm_rd)begin
                next_state = READ;
            end
            // else if(dma_start&&srm_wr)begin
            //     next_state = WRITE;
            // end
            else begin
                next_state = IDLE;
            end
        end
        READ: begin
            if(srm2d_ack_i&&(~srm_rd)&&x_data_end)begin
                next_state = IDLE;
            end
            // else if (srm2d_ack_i&&srm_wr) begin
            //     next_state = WRITE;
            // end
            else begin
                next_state = READ;
            end
        end
        // WRITE: begin
        //     if(srm2d_ack_i&&srm_rd)begin
        //         next_state = READ;
        //     end
        //     else if (srm2d_ack_i&&srm_wr) begin
        //         next_state = WRITE;
        //     end
        //     else begin
        //         next_state = IDLE;
        //     end
        // end
        default: next_state = IDLE;
    endcase
end
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= 2'd0;
    end
    else begin
        state <= next_state;
    end
end
// Access SDRAM
always @(*) begin
    case (state)
        READ: begin
            d2srm_stb_o = 1'd1;
            d2srm_cyc_o = 1'd1;
            d2srm_we_o = 1'd0;
            d2srm_sel_o = 4'b1111;
            d2srm_dat_o = 32'd0;
            d2srm_adr_o = srm_start_adr + srm_adr_cnt;
            srm_adr_cnt_tmp = srm_adr_cnt;
            x_wr = 1'd0;
            x_data_in = 32'd0;
            if(srm2d_ack_i)begin
                srm_adr_cnt_tmp = srm_adr_cnt + 3'd4;
                x_wr = srm2d_ack_i;
                x_data_in = srm2d_dat_i;
            end
        end
        // WRITE: begin
            
        // end
        default: begin
            d2srm_stb_o = 1'd0;
            d2srm_cyc_o = 1'd0;
            d2srm_we_o = 1'd0;
            d2srm_sel_o = 4'b0000;
            d2srm_dat_o = 32'd0;
            d2srm_adr_o = 32'd0;
            srm_adr_cnt_tmp = srm_adr_cnt;
            x_wr = 1'd0;
            x_data_in = 32'd0;
        end
    endcase
end
always @(posedge clk or negedge rst) begin
    if(!rst)begin
        srm_adr_cnt <= 32'd0;
    end
    else begin
        srm_adr_cnt <= srm_adr_cnt_tmp;
    end
end
assign x_data_end = (srm_adr_cnt==srm_data_length) ? 1'b1 : 1'b0;
//----------- DMA -----------//

endmodule
