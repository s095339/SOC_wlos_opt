module rx_fifo
#(
    parameter DEPTH = 8
)
(
    input clk,
    input rst_n,
    // rx_fifo to ctrl
    output [8-1:0]  rx_ctrl_data,
    output reg      read_valid,
    output          rx_ctrl_fullbusy,
    input           ctrl_rx_finish,
    // rx to rx_fifo
    output  reg     rx_finish,
    input [8-1:0]   din,
    input           rx_busy,
    input           wr_en,
    //fifo interrupt
    output  reg     fifo_interrupt
);


    // rx_fifo to ctrl
    reg [1:0] state, next_state;
    parameter STAT_IDLE = 2'd0;
    parameter STAT_FIRSTINPUT = 2'd1;
    parameter STAT_RUN = 2'd2;

    // rx to rx_fifo

    //synchronized fifo
    reg [6:0] wr_ptr, rd_ptr;
    wire wr_en, rd_en;
    reg [8-1:0] fifo[0:DEPTH-1];
    wire empty, full;

    //rx_fifo interrupt
    parameter interrupt_ref = 5;
    reg [1:0] intr_state, next_intr_state;
    parameter INTR_IDLE = 2'd0;
    parameter INTR_WORK = 2'd1;
    parameter INTR_IRQ = 2'd2;
    parameter INTR_CNTIRQ = 2'd3;
    
    reg [20:0] intr_cnt, intr_cnt_next;
    parameter cnt_limit = 21'd100000;

    
    
//*************************************//
// rx_fifo to ctrl                     //
//*************************************//
assign rx_ctrl_fullbusy = full & rx_busy;

always@(posedge clk or negedge rst_n)
    if(~rst_n)
        state <= STAT_IDLE;
    else
        state <= next_state;

always@*
    case(state)
        STAT_IDLE:
            next_state = STAT_FIRSTINPUT;
        STAT_FIRSTINPUT:
            if(wr_en)
                next_state = STAT_RUN;
            else
                next_state = STAT_FIRSTINPUT; 
        STAT_RUN:
            if(ctrl_rx_finish & ~empty)
                next_state = STAT_RUN;
            else if(ctrl_rx_finish & empty)
                next_state = STAT_FIRSTINPUT;
            else
                next_state = STAT_RUN;
        default:
            next_state = STAT_IDLE;
    endcase

always@(posedge clk or negedge rst_n)
    if(~rst_n)
        read_valid <= 1'b0;
    else
        case(state)
            STAT_FIRSTINPUT:
                read_valid <= wr_en;
            STAT_RUN:
                read_valid <= ctrl_rx_finish & ~empty;
            default:
                read_valid <= 1'b0;
        endcase

//*************************************//
// rx to rx_fifo                       //
//*************************************//

always@(posedge clk or negedge rst_n)
    if(~rst_n)
        rx_finish <= 1'b0;
    else
        rx_finish <= wr_en;

//*************************************//
// Synchronized FiFo                   //
//*************************************//

assign rd_en = read_valid;
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

assign rx_ctrl_data = fifo[rd_ptr];
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

//*************************************//
// rx_fifo interrupt                   //
//*************************************//


always@(posedge clk or negedge rst_n)
    if(~rst_n)
        intr_state <= 2'd0;
    else
        intr_state <= next_intr_state;

always@*
    case(intr_state)
        INTR_IDLE:
            if(wr_en)
                next_intr_state = INTR_WORK;
            else
                next_intr_state = INTR_IDLE;
        INTR_IRQ:
            next_intr_state = INTR_WORK;
        INTR_WORK:
            if(wr_en && wr_ptr>rd_ptr)
                if(wr_ptr - rd_ptr >= interrupt_ref)
                    next_intr_state = INTR_IRQ;
                else
                    next_intr_state = INTR_WORK;
            else if (wr_en && wr_ptr < rd_ptr)
                if(wr_ptr + (DEPTH-rd_ptr) >= interrupt_ref)
                    next_intr_state = INTR_IRQ;
                else
                    next_intr_state = INTR_WORK;
            else if(intr_cnt >= cnt_limit)
                next_intr_state = INTR_CNTIRQ;
            else
                next_intr_state = INTR_WORK;
        INTR_CNTIRQ:
            next_intr_state = INTR_IDLE;
        default:
            next_intr_state = INTR_IDLE;
    endcase
always@*
    case(intr_state)
        INTR_IRQ:
            fifo_interrupt = 1'b1;
        INTR_CNTIRQ:
            fifo_interrupt = 1'b1;
        default:
            fifo_interrupt = 1'b0;
    endcase

// interrupt counter
always@(posedge clk or negedge rst_n)
    if(~rst_n)
        intr_cnt <= 21'd0;
    else
        intr_cnt <= intr_cnt_next;
always@*
    case(intr_state)
        INTR_WORK:
            if(wr_en)
                intr_cnt_next = 21'd0;
            else
                intr_cnt_next = intr_cnt + 21'd1;
        default:
            intr_cnt_next = 21'd0;
    endcase

endmodule