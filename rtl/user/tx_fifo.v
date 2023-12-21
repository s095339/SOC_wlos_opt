module tx_fifo
#(
    parameter DEPTH = 8
)
(
    input clk,
    input rst_n,
    // uart_ctrl to tx_fifo
    input [8-1:0]  din,
    input           tx_ctrl_start,
    output  reg     tx_start_clear_ctrl,
    output          tx_ctrl_busy,
    // tx_fifo to uart_tx
    output [8-1:0] tx_uart_data,
    output reg      tx_uart_start,
    input           tx_uart_clear_reg,
    input           tx_uart_busy
);


// synchronized fifo
reg [6:0] wr_ptr, rd_ptr;
wire wr_en, rd_en;
reg [8-1:0] fifo[0:DEPTH-1];
wire empty, full;

//*************************************//
// uart_ctrl to tx_fifo                //
//*************************************//
always@(posedge clk or negedge rst_n)
    if(~rst_n)
        tx_start_clear_ctrl <= 1'b0;
    else
        if(tx_ctrl_start & ~tx_start_clear_ctrl)
            tx_start_clear_ctrl <= 1'b1;
        else
            tx_start_clear_ctrl <= 1'b0;

assign tx_ctrl_busy = full;


//*************************************//
// tx_fifo to uart_tx                  //
//*************************************//
always@(posedge clk or negedge rst_n)
    if(~rst_n)
        tx_uart_start <= 1'b0;
    else
        tx_uart_start <= ~empty & ~tx_uart_clear_reg;



//*************************************//
// Synchronized FiFo                   //
//*************************************//
assign wr_en = tx_start_clear_ctrl;
assign rd_en = tx_uart_clear_reg;
always@(posedge clk or negedge rst_n) begin
    if(~rst_n)
        wr_ptr <= 0;
    else begin
        if(wr_en & ~full)begin
            fifo[wr_ptr] <= din;
            if(wr_ptr < DEPTH-1)
                wr_ptr <= wr_ptr + 1; 
            else
                wr_ptr <= 0;
        end
        else begin
            fifo[wr_ptr] <= fifo[wr_ptr];
            wr_ptr <= wr_ptr; 
        end
    end
end

assign tx_uart_data = fifo[rd_ptr];
always@(posedge clk or negedge rst_n)begin
    if(~rst_n)
        rd_ptr <= 0;
    else begin
        if(rd_en & ~empty)
            if(rd_ptr < DEPTH-1) 
                rd_ptr <= rd_ptr + 1;
            else
                rd_ptr <= 0;
        else
            rd_ptr <= rd_ptr;
    end
end

assign full  = (wr_ptr + 1  == rd_ptr)? 1'b1:1'b0;
assign empty = (wr_ptr == rd_ptr)? 1'b1:1'b0;

endmodule