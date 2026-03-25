// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2018/12/5 11:49:23
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Shenrong Co., Ltd.. 
// All Rights Reserved
//
// *********************************************************************************/
// Modification History:
// 1. initial
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
`timescale 1 ns / 1 ns
module pcie_ritem_glb # (
parameter                           U_DLY          = 1,
parameter                           RCHN_NUM        = 4,
parameter                           RCHN_NUM_W      = clog2b(RCHN_NUM)
)
(   
input                               clk,
input                               rst,
input                               ritem_rst,
//
input                               rg_wr_det,
input           [31:0]              ritem_wdata0,
input           [31:0]              ritem_wdata1,
input           [31:0]              ritem_wdata2,
input           [31:0]              ritem_wdata3,
input           [31:0]              ritem_wdata4,

input           [RCHN_NUM-1:0]       ritem_arb_req,
output  reg     [RCHN_NUM-1:0]       arb_ritem_ack,
output  reg     [RCHN_NUM*160-1:0]   arb_ritem_data,


input                               rchn_dma_done,
input           [31:0]              rchn_dma_daddr,
input           [63:0]              rchn_dma_drev,
input           [RCHN_NUM_W-1:0]    rchn_dma_chn,
input           [31:0]              rchn_dma_daddr_h,

input                               oritem_rd_det,
output  reg     [31:0]              oritem_rdata0,
output  reg     [31:0]              oritem_rdata1,
output  reg     [31:0]              oritem_rdata2,
output  reg     [31:0]              oritem_rdata3,
output  reg     [31:0]              oritem_rdata4,

output                              rg_fifo_full,
output                              rg_fifo_empty,
output                              rg_fifo_prog_empty,
output  reg                         rg_fifo_overflow,

output          [RCHN_NUM-1:0]      ritem_fifo_full,
output          [RCHN_NUM-1:0]      ritem_fifo_prog_full,
output          [RCHN_NUM-1:0]      ritem_fifo_empty,
output          [RCHN_NUM-1:0]      ritem_fifo_prog_empty,
output                              ritem_fifo_overflow,
output                              oritem_fifo_full,
output                              oritem_fifo_empty,
output                              oritem_fifo_prog_empty,
output  reg                         oritem_fifo_overflow,
output  reg                         oritem_fifo_underflow,
output          [7:0]               oritem_fifo_rcnt,
output          [7:0]               oritem_fifo_wcnt,
output reg      [31:0]              rg_fifo_rd_en_cnt,
output reg      [31:0]              ritem_fifo_wr_en_cnt,
output reg      [31:0]              ritem_fifo_rd_en_cnt
);


// Parameter Define 


// Register Define 
reg     [RCHN_NUM-1:0]              ritem_fifo_rd_en;
reg     [RCHN_NUM-1:0]              ritem_rdone;
reg     [159:0]                     oritem_fifo_din;
reg     [RCHN_NUM-1:0]              ritem_fifo_overflow_a;
reg                                 oritem_fifo_wr;
reg     [RCHN_NUM-1:0]              ritem_fifo_wr_en;
reg     [159:0]                     ritem_fifo_din;
reg                                 rg_fifo_rd_en;





// Wire Define 
wire    [159:0]                     rg_fifo_din;
wire                                rg_fifo_wr_en;
wire    [159:0]                     rg_fifo_dout;
wire    [RCHN_NUM_W-1:0]            rg_fifo_chnindex;
wire    [RCHN_NUM*160-1:0]          ritem_fifo_dout;
wire    [159:0]                     oritem_fifo_dout;
wire                                oritem_fifo_rd_en;
wire                                oritem_fifo_wr_en;
//-----------------------------------------------------------------------------
//item gfifo
//-----------------------------------------------------------------------------
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (160                        ),
    .DATA_DEEPTH                (32                         ),
    .ADDR_WIDTH                 (5                          )
)u_rg_fifo
(
    .wr_clk                     (clk                        ),
    .wr_rst_n                   (~(rst | ritem_rst)         ),
    .rd_clk                     (clk                        ),
    .rd_rst_n                   (~(rst | ritem_rst)         ),
    .din                        (rg_fifo_din                ),
    .wr_en                      (rg_fifo_wr_en              ),
    .rd_en                      (rg_fifo_rd_en              ),
    .dout                       (rg_fifo_dout               ),
    .full                       (rg_fifo_full               ),
    .prog_full                  (                           ),
    .empty                      (rg_fifo_empty              ),
    .prog_empty                 (rg_fifo_prog_empty         ),
    .prog_full_thresh           (5'd28                      ),
    .prog_empty_thresh          (5'd4                       ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )
);
assign rg_fifo_din   = {ritem_wdata4,ritem_wdata3,ritem_wdata2,ritem_wdata1,ritem_wdata0};
assign rg_fifo_wr_en = (rg_wr_det==1'b1)&&(rg_fifo_full==1'b0) ? 1'b1:1'b0;
assign rg_fifo_chnindex = rg_fifo_dout[56+:RCHN_NUM_W];

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)    
        rg_fifo_rd_en <= #U_DLY 1'b0;                 
    else if(rg_fifo_rd_en==1'b1)
        rg_fifo_rd_en <= #U_DLY 1'b0;                 
    else if(rg_fifo_empty==1'b0 && ritem_fifo_full[rg_fifo_chnindex]==1'b0)
        rg_fifo_rd_en <= #U_DLY 1'b1;                 
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)    
        rg_fifo_overflow <= #U_DLY 1'b0;        
    else if(rg_wr_det==1'b1 && rg_fifo_full==1'b1)
        rg_fifo_overflow <= #U_DLY 1'b1;
    else
        rg_fifo_overflow <= #U_DLY 1'b0;    
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        rg_fifo_rd_en_cnt <= #U_DLY 'd0;
    else if(ritem_rst==1'b1)
        rg_fifo_rd_en_cnt <= #U_DLY 'd0;
    else if(rg_fifo_rd_en==1'b1)
        rg_fifo_rd_en_cnt <= #U_DLY rg_fifo_rd_en_cnt + 'd1;
end




//-----------------------------------------------------------------------------
//item fifo
//-----------------------------------------------------------------------------
generate
genvar i;
for(i=0;i<RCHN_NUM;i=i+1)
begin
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (160                        ),
    .DATA_DEEPTH                (256                        ),
    .ADDR_WIDTH                 (8                          )
)u_item_fifo
(
    .wr_clk                     (clk                        ),
    .wr_rst_n                   (~(rst | ritem_rst)         ),
    .rd_clk                     (clk                        ),
    .rd_rst_n                   (~(rst | ritem_rst)         ),
    .din                        (ritem_fifo_din             ),
    .wr_en                      (ritem_fifo_wr_en[i]        ),
    .rd_en                      (ritem_fifo_rd_en[i]        ),
    .dout                       (ritem_fifo_dout[160*i+:160]),
    .full                       (ritem_fifo_full[i]         ),
    .prog_full                  (ritem_fifo_prog_full[i]    ),
    .empty                      (ritem_fifo_empty[i]        ),
    .prog_empty                 (ritem_fifo_prog_empty[i]   ),
    .prog_full_thresh           (8'd64                      ),
    .prog_empty_thresh          (8'd60                      ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )

);

end
endgenerate


always @ (posedge clk or posedge rst)begin:RITEM_FIFO_WR
integer i;
    if(rst == 1'b1)     
        begin
            ritem_fifo_wr_en <= #U_DLY 'b0;
            ritem_fifo_din <= #U_DLY 'b0;
        end       
    else 
        begin
            for(i=0;i<RCHN_NUM;i=i+1)
                begin
                    if(rg_fifo_rd_en==1'b1 && rg_fifo_chnindex==i)
                        ritem_fifo_wr_en[i] <= #U_DLY 1'b1;
                    else
                        ritem_fifo_wr_en[i] <= #U_DLY 1'b0;

                    ritem_fifo_din <= #U_DLY rg_fifo_dout;
                end
        end   
end
//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------   
always @ (posedge clk or posedge rst)begin:RITEM_PRO
integer i;
    if(rst == 1'b1)     
        begin
            ritem_fifo_rd_en <= #U_DLY 'b0;
            ritem_rdone <= #U_DLY 'b0;
            arb_ritem_data <= #U_DLY 'b0;
            arb_ritem_ack <= #U_DLY 'b0;
            ritem_fifo_overflow_a <= #U_DLY 'b0;  
        end        
    else    
        begin
        	  for(i=0;i<RCHN_NUM;i=i+1)
        	      begin
                    if(ritem_fifo_rd_en[i]==1'b1)
                        ritem_fifo_rd_en[i] <= #U_DLY 1'b0;
                    else if(ritem_arb_req[i]==1'b1 && ritem_fifo_empty[i]==1'b0 && ritem_rdone[i]==1'b0 && arb_ritem_ack[i]==1'b0)
                        ritem_fifo_rd_en[i] <= #U_DLY 1'b1;
                    
                    ritem_rdone[i] <= #U_DLY ritem_fifo_rd_en[i];
                    
                    if(ritem_fifo_rd_en[i]==1'b1)
                        arb_ritem_data[160*i+:160] <= #U_DLY ritem_fifo_dout[160*i+:160];
                    
                    arb_ritem_ack[i] <= #U_DLY ritem_rdone[i];
                    
                    if(ritem_fifo_wr_en[i]==1'b1 && ritem_fifo_full[i]==1'b1)
                        ritem_fifo_overflow_a[i] <= #U_DLY 1'b1;
                    else
                        ritem_fifo_overflow_a[i] <= #U_DLY 1'b0;
                end                
        end

end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        ritem_fifo_wr_en_cnt <= #U_DLY 'd0;        
    else if(ritem_rst==1'b1)
        ritem_fifo_wr_en_cnt <= #U_DLY 'd0;
    else if(ritem_fifo_wr_en[0]==1'b1)
        ritem_fifo_wr_en_cnt <= #U_DLY ritem_fifo_wr_en_cnt + 'd1;
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        ritem_fifo_rd_en_cnt <= #U_DLY 'd0;        
    else if(ritem_rst==1'b1)   
        ritem_fifo_rd_en_cnt <= #U_DLY 'd0;
    else if(ritem_fifo_rd_en[0]==1'b1)
        ritem_fifo_rd_en_cnt <= #U_DLY ritem_fifo_rd_en_cnt + 'd1;
end

assign ritem_fifo_overflow = |ritem_fifo_overflow_a;
//-----------------------------------------------------------------------------
//oitem fifo
//-----------------------------------------------------------------------------  
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (160                        ),
    .DATA_DEEPTH                (256                        ),
    .ADDR_WIDTH                 (8                          )
)u_oitem_fifo
(
    .wr_clk                     (clk                        ),
    .wr_rst_n                   (~(rst | ritem_rst)         ),
    .rd_clk                     (clk                        ),
    .rd_rst_n                   (~(rst | ritem_rst)         ),
    .din                        (oritem_fifo_din            ),
    .wr_en                      (oritem_fifo_wr_en          ),
    .rd_en                      (oritem_fifo_rd_en          ),
    .dout                       (oritem_fifo_dout           ),
    .full                       (oritem_fifo_full           ),
    .prog_full                  (                           ),
    .empty                      (oritem_fifo_empty          ),
    .prog_empty                 (oritem_fifo_prog_empty     ),
    .prog_full_thresh           (8'd240                     ),
    .prog_empty_thresh          (8'd60                      ),
    .rd_data_count              (oritem_fifo_rcnt           ),    
    .wr_data_count              (oritem_fifo_wcnt           )     
);

assign oritem_fifo_rd_en = (oritem_rd_det==1'b1) && (oritem_fifo_empty==1'b0) ? 1'b1 : 1'b0;
assign oritem_fifo_wr_en = (oritem_fifo_wr==1'b1) && (oritem_fifo_full==1'b0) ? 1'b1: 1'b0;

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1) 
        begin
            oritem_fifo_wr <= #U_DLY 1'b0;
            oritem_fifo_din <= #U_DLY 'b0;
            oritem_rdata0 <= #U_DLY 'b0;
            oritem_rdata1 <= #U_DLY 'b0;
            oritem_rdata2 <= #U_DLY 'b0;
            oritem_rdata3 <= #U_DLY 'b0;
            oritem_rdata4 <= #U_DLY 'b0;
        end    
    else    
        begin
            if(rchn_dma_done==1'b1)
                oritem_fifo_wr <= #U_DLY 1'b1;
            else
                oritem_fifo_wr <= #U_DLY 1'b0;
            
            if(rchn_dma_done==1'b1)
                oritem_fifo_din <= #U_DLY {rchn_dma_daddr_h,
                                           rchn_dma_drev,
                                           {{(8-RCHN_NUM_W){1'b0}},rchn_dma_chn,24'b0},
                                           rchn_dma_daddr};

            //if(oritem_fifo_rd_en==1'b1)
                oritem_rdata0 <= #U_DLY oritem_fifo_dout[31:0];

            //if(oritem_fifo_rd_en==1'b1)
                oritem_rdata1 <= #U_DLY oritem_fifo_dout[63:32];
            
            //if(oritem_fifo_rd_en==1'b1)
                oritem_rdata2 <= #U_DLY oritem_fifo_dout[95:64];
            
            //if(oritem_fifo_rd_en==1'b1)
                oritem_rdata3 <= #U_DLY oritem_fifo_dout[127:96];
                
                oritem_rdata4 <= #U_DLY oritem_fifo_dout[159:128];

        end

end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            oritem_fifo_overflow <= #U_DLY 1'b0; 
            oritem_fifo_underflow <= #U_DLY 1'b0;
        end       
    else    
        begin
            if(oritem_fifo_wr==1'b1 && oritem_fifo_full==1'b1)
                oritem_fifo_overflow <= #U_DLY 1'b1;
            else
                oritem_fifo_overflow <= #U_DLY 1'b0;
            
            if(oritem_rd_det==1'b1 && oritem_fifo_empty==1'b1)
                oritem_fifo_underflow <= #U_DLY 1'b1;
            else
                oritem_fifo_underflow <= #U_DLY 1'b0;
        end
end



function integer clog2b;
input integer value;
integer tmp;
begin
    tmp = value;
    if(tmp<=1)
        clog2b = 1;
    else
    begin
        tmp = tmp-1;
        for (clog2b=0; tmp>0; clog2b=clog2b+1)
            tmp = tmp>>1;
    end
end
endfunction

endmodule




