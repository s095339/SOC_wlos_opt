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
    input wire [31:0] srm2d_dat_i,

    // DMA <====> FIR
    // maseter out
    output reg dma2fir_valid,
    output reg [31:0] dma2fir_data,
    output wire dma2fir_last,

    input wire fir2dma_ready,
    // slave in
    output reg dma2fir_ready,

    input wire fir2dma_valid,
    input wire [31:0] fir2dma_data,
    input wire fir2dma_last,
    // irq
    output wire dma_irq
    );
//----------- signal instantiation -----------//
// FIFO
reg [31:0] x_data_in;
reg x_rd;
reg x_wr;
wire [31:0] x_data_out;
wire x_empty;
wire x_full;
wire x_last_data;

reg [31:0] y_data_in;
reg y_rd;
reg y_wr;
wire [31:0] y_data_out;
wire y_empty;
wire y_full;
wire y_last_data;
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
reg srm_wr;
reg srm_rd;
reg wrote_1;
reg wrote_1_tmp;
reg read_1;
reg read_1_tmp;
reg [31:0] srm_adr_cnt;
reg [31:0] srm_adr_cnt_tmp;
reg [31:0] save_adr_cnt;
reg [31:0] save_adr_cnt_tmp;
wire x_data_end;
reg y_data_last;
wire write_end;
reg write_end_delay;
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
	.full(x_full),
    .last_data(x_last_data)
);
fifo 
#(
	.DATA_WIDTH	(32),
    .DATA_DEPTH	(4)
)
Y_FIFO(
	.clk(clk),
	.rst(rst),
	.data_in(y_data_in),
	.rd_en(y_rd),
	.wr_en(y_wr),

	.data_out(y_data_out),
	.empty(y_empty),
	.full(y_full),
    .last_data(y_last_data)
);

always @(*) begin
    case ({x_full,y_empty})
        2'b00: begin
            srm_rd = 1'd1;
            srm_wr = 1'd0;
            if(x_data_end&&(!write_end))begin
                srm_rd = 1'd0;
                srm_wr = 1'd1;
            end
            else if (write_end) begin
                srm_rd = 1'd0;
                srm_wr = 1'd0;
            end
        end
        2'b01: begin
            srm_rd = 1'd1;
            srm_wr = 1'd0;
            if(x_data_end)begin
                srm_rd = 1'd0;
                srm_wr = 1'd0;
            end
        end
        2'b10: begin
            srm_rd = 1'd0;
            srm_wr = 1'd1;
            if (write_end) begin
                srm_rd = 1'd0;
                srm_wr = 1'd0;
            end
        end
        2'b11: begin
            srm_rd = 1'd0;
            srm_wr = 1'd0;
        end
        default: begin
            srm_rd = 1'd0;
            srm_wr = 1'd0;
        end
    endcase
end
// Prepare
always @(posedge clk or negedge rst) begin
    if(!rst)begin
        cpu2d_data <= 96'd0;
        cpu_access_cnt <= 2'd0;
    end
    else if(cpu2d_stb_i)begin
        cpu2d_data <= {cpu2d_data[63:0], cpu2d_dat_i};
        cpu_access_cnt <= cpu_access_cnt + 1'd1;
    end
    else begin
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
            else if(dma_start&&srm_wr)begin
                next_state = WRITE;
            end
            else begin
                next_state = IDLE;
            end
        end
        READ: begin
            if (read_1&&srm_wr) begin
                next_state = WRITE;
            end
            else if(read_1&&(~srm_rd))begin
                next_state = IDLE;
            end
            else begin
                next_state = READ;
            end
        end
        WRITE: begin
            if(wrote_1&&srm_rd)begin
                next_state = READ;
            end
            else if (wrote_1&&(~srm_wr)) begin
                next_state = IDLE;
            end
            else begin
                next_state = WRITE;
            end
        end
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
            d2srm_adr_o = srm_start_adr + (srm_adr_cnt<<2);
            srm_adr_cnt_tmp = srm_adr_cnt;
            save_adr_cnt_tmp = save_adr_cnt;
            x_wr = 1'd0;
            x_data_in = 32'd0;
            y_rd = 1'd0;
            read_1_tmp = 1'd0;
            wrote_1_tmp = 1'd0;
            if(srm2d_ack_i)begin
                srm_adr_cnt_tmp = srm_adr_cnt + 1'd1;
                x_wr = srm2d_ack_i;
                x_data_in = srm2d_dat_i;
                read_1_tmp = srm2d_ack_i;
            end
        end
        WRITE: begin
            d2srm_stb_o = 1'd1;
            d2srm_cyc_o = 1'd1;
            d2srm_we_o = 1'd1;
            d2srm_sel_o = 4'b1111;
            d2srm_dat_o = y_data_out;
            d2srm_adr_o = srm_save_adr + (save_adr_cnt<<2);
            srm_adr_cnt_tmp = srm_adr_cnt;
            save_adr_cnt_tmp = save_adr_cnt;
            x_wr = 1'd0;
            x_data_in = 32'd0;
            y_rd = 1'd0;
            read_1_tmp = 1'd0;
            wrote_1_tmp = 1'd0;
            if(srm2d_ack_i)begin
                y_rd = srm2d_ack_i;
                save_adr_cnt_tmp = save_adr_cnt + 1'd1;
                wrote_1_tmp = srm2d_ack_i;
            end
        end
        default: begin
            d2srm_stb_o = 1'd0;
            d2srm_cyc_o = 1'd0;
            d2srm_we_o = 1'd0;
            d2srm_sel_o = 4'b0000;
            d2srm_dat_o = 32'd0;
            d2srm_adr_o = 32'd0;
            srm_adr_cnt_tmp = srm_adr_cnt;
            save_adr_cnt_tmp = save_adr_cnt;
            x_wr = 1'd0;
            x_data_in = 32'd0;
            y_rd = 1'd0;
            read_1_tmp = 1'd0;
            wrote_1_tmp = 1'd0;
        end
    endcase
end
always @(posedge clk or negedge rst) begin
    if(!rst)begin
        srm_adr_cnt <= 32'd0;
        save_adr_cnt <= 32'd0;
        read_1 <= 1'd0;
        wrote_1 <= 1'd0;
    end
    else begin
        srm_adr_cnt <= srm_adr_cnt_tmp;
        save_adr_cnt <= save_adr_cnt_tmp;
        read_1 <= read_1_tmp;
        wrote_1 <= wrote_1_tmp;
    end
end
assign x_data_end = (srm_adr_cnt==srm_data_length) ? 1'b1 : 1'b0;
assign dma2fir_last = x_data_end&x_last_data;
// DMA to FIR
always @(*) begin
    case (x_empty)
        1'd0: begin
            dma2fir_valid = 1'd1;
            dma2fir_data = x_data_out;
            x_rd = 1'd0;
            if(fir2dma_ready)begin
                x_rd = fir2dma_ready;
            end
        end
        1'd1: begin
            dma2fir_valid = 1'd0;
            dma2fir_data = 32'd0;
            x_rd = 1'd0;
        end
        default: begin
            dma2fir_valid = 1'd0;
            dma2fir_data = 32'd0;
            x_rd = 1'd0;
        end
    endcase
end
// FIR to DMA
always @(*) begin
    case (y_full)
        1'd0: begin
            dma2fir_ready = 1'd1;
            y_data_in = 32'd0;
            y_wr = 1'd0;
            if(fir2dma_valid)begin
                y_data_in = fir2dma_data;
                y_wr = fir2dma_valid;
            end
        end
        1'd1: begin
            dma2fir_ready = 1'd0;
            y_data_in = 32'd0;
            y_wr = 1'd0;
        end
        default: begin
            dma2fir_ready = 1'd0;
            y_data_in = 32'd0;
            y_wr = 1'd0;
        end
    endcase
end
always @(posedge clk or negedge rst) begin
    if(!rst)begin
        y_data_last <= 1'd0;
    end
    else if(fir2dma_valid&&fir2dma_last)begin
        y_data_last <= 1'd1;
    end
    else begin
        y_data_last <= y_data_last;
    end
end
assign write_end = y_data_last&&y_empty;
always @(posedge clk or negedge rst) begin
    if(!rst)begin
        write_end_delay <= 1'd0;
    end
    else begin
        write_end_delay <= write_end;
    end
end
assign dma_irq = write_end&~write_end_delay;
//----------- DMA -----------//

endmodule
