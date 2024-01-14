`timescale 1ns / 1ps
// Engineer: chen
// 
// Create Date: 01/12/2024 03:34:47 PM
// Module Name: fifo
//////////////////////////////////////////////////////////////////////////////////


module fifo
#(
	parameter DATA_WIDTH = 'd32,
    parameter DATA_DEPTH = 'd4
)
(
	input clk,
	input rst,
	input wire [DATA_WIDTH-1:0] data_in,
	input rd_en,
	input wr_en,
	output empty,
	output full,
	output wire [DATA_WIDTH-1:0] data_out
);
// signal
reg [DATA_WIDTH - 1 : 0] fifo_buffer [DATA_DEPTH - 1 : 0];	
reg [$clog2(DATA_DEPTH) - 1 : 0] wr_addr;
reg [$clog2(DATA_DEPTH) - 1 : 0] rd_addr;
reg [$clog2(DATA_DEPTH) : 0] fifo_cnt;

// read 
always @ (posedge clk or negedge rst) begin
	if (!rst)begin
        rd_addr <= 0;
    end
	else if (!empty && rd_en)begin
		rd_addr <= rd_addr + 1'd1;
	end
	else begin
		rd_addr <= rd_addr;
	end
end
assign data_out = fifo_buffer[rd_addr];
// write
always @ (posedge clk or negedge rst) begin
	if (!rst)begin
        wr_addr <= 0;
        fifo_buffer[wr_addr] <= 0;
    end
	else if (!full && wr_en)begin
		wr_addr <= wr_addr + 1'd1;
		fifo_buffer[wr_addr] <= data_in;
	end
    else begin
        wr_addr <= wr_addr;
		fifo_buffer[wr_addr] <= fifo_buffer[wr_addr];
    end
end
// fifo counter
always @ (posedge clk or negedge rst) begin
	if (!rst)
		fifo_cnt <= 0;
	else begin
		case({wr_en,rd_en})
			2'b00:
                fifo_cnt <= fifo_cnt;
			2'b01:
				if(fifo_cnt != 0)
				    fifo_cnt <= fifo_cnt - 1'b1;
			2'b10:
				if(fifo_cnt != DATA_DEPTH)
					fifo_cnt <= fifo_cnt + 1'b1;
			2'b11:
                fifo_cnt <= fifo_cnt;
			default:
                fifo_cnt <= fifo_cnt;
		endcase
	end
end

assign full  = (fifo_cnt == DATA_DEPTH) ? 1'b1 : 1'b0;
assign empty = (fifo_cnt == 0)? 1'b1 : 1'b0;
 
endmodule