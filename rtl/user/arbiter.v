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

//arbiter
wire wbs_stb_i;
wire wbs_cyc_i;
wire wbs_we_i;
wire [3:0] wbs_sel_i;
wire [31:0] wbs_dat_i;
wire [31:0] wbs_adr_i;
wire wbs_ack_o;
wire [31:0] wbs_dat_o;

wire dma_valid, cpu_valid;
wire arb1_switch; // 0: cpu 1:dma;
reg[2:0] arb1_state, arb1_next_state;
reg[2:0] arb1_cnt, arb1_cnt_next;
parameter ARB1_CPU = 3'd1;
parameter ARB1_DMA = 3'd2;
parameter ARB1_INIT = 3'd3;
parameter ARB1_ARB = 3'd0;

parameter cnt_limit = 3'd4;

//*-----------------------------*//
// arbiter 1                     //
//*-----------------------------*//
assign dma_valid = wbs_stb_i_ram_dma & wbs_cyc_i_ram_dma;
assign cpu_valid = wbs_stb_i_ram_cpu & wbs_cyc_i_ram_cpu;

//--- state ---//
always@(posedge wb_clk_i or posedge wb_rst_i)
    if(wb_rst_i)
        arb1_state <= ARB1_ARB;
    else
        arb1_state <= arb1_next_state;

always@*
    case(arb1_state)
        ARB1_ARB:
            if(dma_valid & ~cpu_valid)
                arb1_next_state = ARB1_DMA;
            else if(~dma_valid & cpu_valid)
                arb1_next_state = ARB1_CPU;
            else if(dma_valid & cpu_valid)
                arb1_next_state = (arb1_switch)?ARB1_DMA:ARB1_CPU;
            else
                arb1_next_state = ARB1_ARB;
        ARB1_CPU:
            if(wbs_ack_o & wbs_cyc_i_ram_cpu & wbs_stb_i_ram_cpu)
                arb1_next_state = ARB1_ARB;
            else if(~(wbs_cyc_i_ram_cpu & wbs_stb_i_ram_cpu))
                arb1_next_state = ARB1_ARB;
            else
                arb1_next_state = ARB1_CPU;
        ARB1_DMA:
            if(wbs_ack_o & wbs_cyc_i_ram_dma & wbs_stb_i_ram_dma )
                arb1_next_state = ARB1_ARB;
            else if(~(wbs_cyc_i_ram_dma & wbs_stb_i_ram_dma))
                arb1_next_state = ARB1_ARB;
            else
                arb1_next_state = ARB1_DMA;
        ARB1_INIT:
            arb1_next_state = ARB1_ARB;
        default:
            arb1_next_state = ARB1_ARB;
    endcase

//--- cnt ---//
assign arb1_switch = (arb1_cnt == cnt_limit)? 1'b0:1'b1;
always@(*)
    case(arb1_state)
        ARB1_ARB:
            if(arb1_next_state == ARB1_DMA && arb1_cnt < cnt_limit) 
                arb1_cnt_next = arb1_cnt + 3'd1;
            else if(arb1_next_state == ARB1_DMA && arb1_cnt == cnt_limit) 
                arb1_cnt_next = arb1_cnt;
            else if(arb1_next_state == ARB1_CPU && arb1_cnt == cnt_limit)
                arb1_cnt_next = 3'd0;
            else
                arb1_cnt_next = arb1_cnt;
        default:
            arb1_cnt_next = arb1_cnt;
    endcase

always@(posedge wb_clk_i or posedge wb_rst_i)
    if(wb_rst_i)
        arb1_cnt <= 3'd0;
    else
        arb1_cnt <= arb1_cnt_next;

//--- decode ---//
assign wbs_stb_i =  (arb1_next_state == ARB1_CPU || arb1_state == ARB1_CPU)?wbs_stb_i_ram_cpu:
                    (arb1_next_state == ARB1_DMA || arb1_state == ARB1_DMA )?wbs_stb_i_ram_dma:1'd0 ; 

assign wbs_cyc_i =  (arb1_next_state == ARB1_CPU || arb1_state == ARB1_CPU)?wbs_cyc_i_ram_cpu:
                    (arb1_next_state == ARB1_DMA || arb1_state == ARB1_DMA)?wbs_cyc_i_ram_dma:1'd0; 

assign wbs_we_i =   (arb1_next_state == ARB1_CPU || arb1_state == ARB1_CPU)?wbs_we_i_ram_cpu:
                    (arb1_next_state == ARB1_DMA || arb1_state == ARB1_DMA)?wbs_we_i_ram_dma:1'd0; 

assign wbs_sel_i =  (arb1_next_state == ARB1_CPU || arb1_state == ARB1_CPU)?wbs_sel_i_ram_cpu:
                    (arb1_next_state == ARB1_DMA || arb1_state == ARB1_DMA)?wbs_sel_i_ram_dma:4'd0; 

assign wbs_dat_i =  (arb1_next_state == ARB1_CPU || arb1_state == ARB1_CPU)?wbs_dat_i_ram_cpu:
                    (arb1_next_state == ARB1_DMA || arb1_state == ARB1_DMA)?wbs_dat_i_ram_dma:32'd0; 

assign wbs_adr_i =  (arb1_next_state == ARB1_CPU || arb1_state == ARB1_CPU)?wbs_adr_i_ram_cpu:
                    (arb1_next_state == ARB1_DMA || arb1_state == ARB1_DMA)?wbs_adr_i_ram_dma:32'd0; 

assign wbs_ack_o_ram_cpu =  (arb1_state == ARB1_CPU)?wbs_ack_o:1'b0;
assign wbs_ack_o_ram_dma =  (arb1_state == ARB1_DMA)?wbs_ack_o:1'b0;
assign wbs_dat_o_ram_cpu =  (arb1_state == ARB1_CPU)?wbs_dat_o:32'd0;
assign wbs_dat_o_ram_dma =  (arb1_state == ARB1_DMA)?wbs_dat_o:32'd0;


assign wbs_stb_o_ram = wbs_stb_i;
assign wbs_cyc_o_ram = wbs_cyc_i;
assign wbs_we_o_ram = wbs_we_i;
assign wbs_sel_o_ram = wbs_sel_i;
assign wbs_dat_o_ram = wbs_dat_i;
assign wbs_adr_o_ram = wbs_adr_i;

assign wbs_ack_o = wbs_ack_i_ram;
assign wbs_dat_o =  wbs_dat_i_ram;

endmodule