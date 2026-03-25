// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/12/6 13:41:05
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Boyulihua digital equipment Co., Ltd.. 
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
module pcie_rchn_couple #(
parameter                           U_DLY = 1,
parameter                           RDATA_WIDTH=512,
parameter                           RBURST_LEN=2048
)
(
input                               sys_clk,
input                               sys_rst_n,

input                               rd_clk,
input                               rd_rst_n,

input                               rchn_st,                                            
output reg [31:0]                   rchn_cnt,   
output reg [31:0]                   rchn_cnt_h,                                         
output reg                          rchn_terr,                                            

output                              rfifo_empty,
output                              rfifo_prog_full,
input                               rfifo_wr,
input [RDATA_WIDTH-1:0]             rfifo_wr_data,

input                               rchn_data_rdy, 
output reg                          rchn_data_vld,         
output reg                          rchn_sof,
output reg                          rchn_eof,
output reg  [RDATA_WIDTH-1:0]       rchn_data,
output wire [RDATA_WIDTH/8-1:0]     rchn_keep,
output wire [15-1:0]                rchn_length,

output reg                          rfifo_overflow,
output reg                          rfifo_underflow


);
// Parameter Define 
localparam                          IDLE  =2'd0;
localparam                          FRM   =2'd1;
localparam                          DONE  =2'd2;

localparam                          RDATA_WIDTH_BYTE = RDATA_WIDTH/8;
localparam  [8:0]                   PROG_EMPTY_LEVEL = RBURST_LEN/RDATA_WIDTH_BYTE;

// Register Define 
reg     [1:0]                       ru_state;
reg     [1:0]                       ru_nextstate;
reg     [8:0]                       rfifo_cnt;
reg     [2:0]                       rchn_st_r;
reg                                 rchn_first;
reg     [RDATA_WIDTH-1:0]           rchn_data_r;
reg     [RDATA_WIDTH/32-1:0]        rchn_terr_l;
reg     [3:0]                       rfifo_underflow_r;
// Wire Define 
wire                                rfifo_rd;
wire    [RDATA_WIDTH-1:0]           rfifo_rd_data;
wire                                rfifo_prog_empty;
wire                                rfifo_full;


asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (RDATA_WIDTH                ),
    .DATA_DEEPTH                (512                        ),
    .ADDR_WIDTH                 (9                          )
)u_rfifo
(
    .wr_clk                     (sys_clk                    ),
    .wr_rst_n                   (sys_rst_n                  ),
    .rd_clk                     (rd_clk                     ),
    .rd_rst_n                   (rd_rst_n                   ),
    .din                        (rfifo_wr_data              ),
    .wr_en                      (rfifo_wr                   ),
    .rd_en                      (rfifo_rd                   ),
    .dout                       (rfifo_rd_data              ),
    .full                       (rfifo_full                 ),
    .prog_full                  (rfifo_prog_full            ),
    .empty                      (rfifo_empty                ),
    .prog_empty                 (rfifo_prog_empty           ),
    .prog_full_thresh           (9'd255                     ),
    .prog_empty_thresh          (PROG_EMPTY_LEVEL           ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )
);


//state-machine
always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)     
        ru_state <= #U_DLY IDLE;        
    else    
        ru_state <= #U_DLY ru_nextstate;
end

always @ (*)begin
    case(ru_state)
        IDLE:
        begin
            if(rfifo_prog_empty==1'b0)
                ru_nextstate = FRM;
            else
                ru_nextstate = IDLE;
        end

        FRM:
        begin
            if(rchn_data_vld==1'b1 && rchn_eof==1'b1 && rchn_data_rdy==1'b1)
                ru_nextstate = DONE;
            else
                ru_nextstate = FRM;
        end

        DONE:
            ru_nextstate = IDLE;

        default:
            ru_nextstate=IDLE;
    endcase
end

always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)     
        rchn_data_vld <= #U_DLY 1'b0;
    else if(rchn_data_vld==1'b1 && rchn_eof==1'b1 && rchn_data_rdy==1'b1)
        rchn_data_vld <= #U_DLY 1'b0;    
    else if(ru_state==IDLE && ru_nextstate==FRM)
        rchn_data_vld <= #U_DLY 1'b1;   
end

always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)       
        rchn_data <= #U_DLY 'b0;      
    else if(rfifo_rd==1'b1)
        rchn_data <= #U_DLY rfifo_rd_data;    
end

always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)       
        rchn_sof <= #U_DLY 1'b0;         
    else if(rchn_data_vld==1'b1 && rchn_sof==1'b1 && rchn_data_rdy==1'b1)
        rchn_sof <= #U_DLY 1'b0;
    else if(ru_state==IDLE && ru_nextstate==FRM)   
        rchn_sof <= #U_DLY 1'b1;
end


always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)      
        rchn_eof <= #U_DLY 1'b0;       
    else if(rchn_data_vld==1'b1 && rchn_eof==1'b1 && rchn_data_rdy==1'b1)
        rchn_eof <= #U_DLY 1'b0;
    else if(rchn_data_vld==1'b1 && rchn_data_rdy==1'b1 && rfifo_cnt>=PROG_EMPTY_LEVEL-9'd2)
        rchn_eof <= #U_DLY 1'b1;   
end

always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)      
        rfifo_cnt <= #U_DLY 'b0;       
    else if(rchn_data_vld==1'b1 && rchn_eof==1'b1 && rchn_data_rdy==1'b1)
        rfifo_cnt <= #U_DLY 'b0;
    else if(rchn_data_vld==1'b1 && rchn_data_rdy==1'b1)
        rfifo_cnt <= #U_DLY rfifo_cnt + 'b1;   
end

assign rchn_keep={(RDATA_WIDTH_BYTE){1'b1}};
assign rchn_length=RBURST_LEN;

assign rfifo_rd = (ru_state==IDLE) && (ru_nextstate==FRM) ? 1'b1 :
                  (rchn_data_vld==1'b1 &&  rchn_eof==1'b0 && rchn_data_rdy==1'b1) ? 1'b1 :1'b0;





always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)                   
        rchn_st_r <= #U_DLY 1'b0;               
    else 
        rchn_st_r <= #U_DLY {rchn_st_r[1:0],rchn_st};   
end

always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)                  
        rchn_cnt <= #U_DLY 'b0;        
    else if(rchn_st_r[1]==1'b1 && rchn_st_r[2]==1'b0)
        rchn_cnt <= #U_DLY 'b0;
    else if(rchn_data_vld==1'b1 && rchn_data_rdy==1'b1)
        rchn_cnt <= #U_DLY rchn_cnt + RDATA_WIDTH_BYTE;   
end

always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)                  
        rchn_cnt_h <= #U_DLY 'b0;        
    else if(rchn_st_r[1]==1'b1 && rchn_st_r[2]==1'b0)
        rchn_cnt_h <= #U_DLY 'b0;
end

always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)      
        rchn_first <= #U_DLY 1'b0;        
    else if(rchn_st_r[1]==1'b1 && rchn_st_r[2]==1'b0)
        rchn_first <= #U_DLY 1'b1;
    else if(rchn_data_vld==1'b1 && rchn_data_rdy==1'b1) 
        rchn_first <= #U_DLY 1'b0;  
end

always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)       
        rchn_data_r <= #U_DLY 'b0;        
    else if(rchn_data_vld==1'b1 && rchn_data_rdy==1'b1)   
        rchn_data_r <= #U_DLY rchn_data;
end

always @ (posedge rd_clk or negedge rd_rst_n)begin:RCHN_TERR_L_PRO
integer i;
    if(rd_rst_n == 1'b0)      
        rchn_terr_l <= #U_DLY 'b0;       
    else if(rchn_data_vld==1'b1 && rchn_data_rdy==1'b1 && rchn_first==1'b0)
        begin
            for(i=0;i<RDATA_WIDTH/32;i=i+1)
               if(rchn_data[i*32+:32]!=rchn_data_r[i*32+:32]+RDATA_WIDTH/32)
                   rchn_terr_l[i] <= #U_DLY 1'b1;
               else
                   rchn_terr_l[i] <= #U_DLY 1'b0;
        end   
    else
        rchn_terr_l <= #U_DLY 'b0;   
end


always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)     
        rchn_terr <= #U_DLY 1'b0; 
    else if(rchn_st_r[1]==1'b1 && rchn_st_r[2]==1'b0)
        rchn_terr <= #U_DLY 1'b0;    
    else if(|rchn_terr_l==1'b1)
        rchn_terr <= #U_DLY 1'b1;     
end



always @ (posedge sys_clk or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)     
        rfifo_overflow <= #U_DLY 1'b0;        
    else if(rfifo_wr==1'b1 && rfifo_full==1'b1)  
        rfifo_overflow <= #U_DLY 1'b1;
    else
    	  rfifo_overflow <= #U_DLY 1'b0;
end


always @ (posedge rd_clk or negedge rd_rst_n)begin
    if(rd_rst_n == 1'b0)  
    	  begin
    	  	  rfifo_underflow_r <= #U_DLY 'b0;     
            rfifo_underflow <= #U_DLY 1'b0;
        end        
    else 
    	  begin    
    	      rfifo_underflow_r[3:1] <= #U_DLY rfifo_underflow_r[2:0];   
    	      rfifo_underflow        <= #U_DLY rfifo_underflow_r[3];  
    	      
            if(rfifo_underflow==1'b1)
            	  rfifo_underflow_r[0] <= #U_DLY 1'b0; 	
            else if(rfifo_rd==1'b1 && rfifo_empty==1'b1)  
                rfifo_underflow_r[0] <= #U_DLY 1'b1;
        end
end


//(* syn_keep = "true", mark_debug = "true" *)reg [31:0]  rc_wr_cnt;
//(* syn_keep = "true", mark_debug = "true" *)reg [31:0]  rc_wr_cnt_h;
//
//
//always @ (posedge sys_clk or negedge sys_rst_n)begin
//    if(sys_rst_n == 1'b0)                   
//        rc_wr_cnt <= #U_DLY 'b0;        
//    else if(rchn_st_r[1]==1'b1 && rchn_st_r[2]==1'b0)
//        rc_wr_cnt <= #U_DLY 'b0;
//    else if(rfifo_wr==1'b1)
//        rc_wr_cnt <= #U_DLY rc_wr_cnt + 'd64;   
//end
//
//always @ (posedge sys_clk or negedge sys_rst_n)begin
//    if(sys_rst_n == 1'b0)                     
//        rc_wr_cnt_h <= #U_DLY 'b0;        
//    else if(rchn_st_r[1]==1'b1 && rchn_st_r[2]==1'b0)
//        rc_wr_cnt_h <= #U_DLY 'b0;
//    else if(rfifo_wr==1'b1 && rc_wr_cnt==32'hffff_ffc0)
//        rc_wr_cnt_h <= #U_DLY rc_wr_cnt_h + 'd1;   
//end

endmodule

