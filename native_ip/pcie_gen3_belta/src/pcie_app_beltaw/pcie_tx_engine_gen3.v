// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/11/30 14:37:12
// File Name    : pcie_tx_engine_gen3.v
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
module pcie_tx_engine_gen3 # (
parameter                           U_DLY      = 1,
parameter                           WCHN_NUM   = 8,
parameter                           RCHN_NUM   = 8,
parameter                           WCHN_NUM_W = clog2b(WCHN_NUM),
parameter                           RCHN_NUM_W = clog2b(RCHN_NUM)

)
(
input                               clk,
input                               rst_n,

input       [9:0]                   wdma_tlp_size,

output  reg                         wchn_dma_done,
output  reg                         wchn_dma_end,
output  reg [WCHN_NUM_W-1:0]        wchn_dma_chn,
output  reg [23:0]                  wchn_dma_count,
output  reg [31:0]                  wchn_dma_daddr,
output  reg [63:0]                  wchn_dma_drev,
output  reg [31:0]                  wchn_dma_daddr_h,

output  reg                         rchn_dma_done,    
output  reg [RCHN_NUM_W-1:0]        rchn_dma_chn,
output  reg [31:0]                  rchn_dma_daddr,
output  reg [63:0]                  rchn_dma_drev,
output  reg [31:0]                  rchn_dma_daddr_h,


//
output  reg                         s_axis_rq_tlast,
(* max_fanout=10 *)output  reg [255:0]                 s_axis_rq_tdata,
output      [59:0]                  s_axis_rq_tuser,
output  reg [7:0]                   s_axis_rq_tkeep,
input                               s_axis_rq_tready,
output  reg                         s_axis_rq_tvalid,


input                               wib_empty,   
(* max_fanout=20 *)output reg       wib_ren,
input       [255:0]                 wib_dout,

input                               rib_empty,     
output reg                          rib_ren,
input       [191:0]                 rib_dout,

input                               wdb_empty, 
(* max_fanout=20 *)output reg       wdb_ren,             
input       [512-1:0]               wdb_dout,
output reg                          wdb_underflow,
output reg                          txfifo_abnormal_rst,
output reg                          trabt_err

);
// Parameter Define 

// Register Define 
//reg                                 mwr_end;    
//reg                                 mrd_end;    
reg                                 mwr_st;
reg                                 mrd_st;
reg     [3:0]                       wdb_underflow_r;
reg                                 fifo_abnormal;
reg     [9:0]                       fifo_abnormal_uscnt;
reg                                 fifo_abnormal_usflg;
reg     [9:0]                       fifo_abnormal_mscnt;
reg                                 fifo_abnormal_msflg;
reg     [9:0]                       fifo_abnormal_scnt;
reg                                 fifo_abnormal_sflg;
reg                                 fifo_abnormal_cnt;
reg     [3:0]                       fifo_abnormal_rst_r;
reg                                 wdb_ren_r;
reg                                 wdb_empty_r;
reg     [3:0]                       cnt;
reg     [3:0]                       wchn_dma_done_cnt;
reg     [3:0]                       rchn_dma_done_cnt;
reg                                 l_flg;
reg     [127:0]                     dout_1_x;
reg     [127:0]                     dout_2_x;
//(* max_fanout=20 *)
reg     [127:0]                     dout_1;
reg     [127:0]                     dout_2;
reg     [127:0]                     dout_3;
reg     [1:0]                       d_flg;
reg     [9:0]                       wdma_tlp_size_r1;
reg     [9:0]                       wdma_tlp_size_r2;
reg                                 last_flg;
reg     [1:0]                       wib_ren_r;
reg     [255:0]                     wib_dout_r;
reg     [1:0]                       mrd_st_xr;

// Wire Define 
wire    [7:0]                       rdma_tlp_size_dw;
wire    [31:0]                      rd_dma_addr;
wire    [31:0]                      rd_dma_addr_h;
wire    [31:0]                      mwr_header_dw0;
wire    [31:0]                      mwr_header_dw1;
wire    [31:0]                      mwr_header_dw2;
wire    [31:0]                      mwr_header_dw3;
wire    [31:0]                      mrd_header_dw0;
wire    [31:0]                      mrd_header_dw1;
wire    [31:0]                      mrd_header_dw2;
wire    [31:0]                      mrd_header_dw3;
wire    [127:0]                     dout_0_x;

wire    [7:0]                       wdma_tlp_size_dw;
wire    [31:0]                      wr_dma_addr;
wire    [31:0]                      wr_dma_addr_h;
(* max_fanout=20 *)
wire                                abt_flg_x;
(* max_fanout=20 *)
wire                                mwr_st_x;
(* max_fanout=20 *)
wire                                mrd_st_x;
wire    [4:0]                       rdma_tag;
//wire                                last_flg_x;
wire    [3:0]                       tlp_size;         
         
assign tlp_size=wdma_tlp_size_r2[8:5];


assign s_axis_rq_tuser = {52'd0,4'hf,4'hf};      //{52'd0,last_be,first_be};


assign abt_flg_x = (s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b1 && s_axis_rq_tready==1'b1 && mrd_st==1'b0) ? 1'b1:
                   (s_axis_rq_tvalid==1'b0 && mrd_st_xr==2'b00) ? 1'b1 :1'b0;

//assign mwr_st_x = (abt_flg_x==1'b1) && (last_flg_==1'b1) && (wib_empty==1'b0 && wdb_empty==1'b0) ? 1'b1:
//                  (abt_flg_x==1'b1) && (last_flg_x==1'b0) && (rib_empty==1'b1) && (wib_empty==1'b0 && wdb_empty==1'b0) ? 1'b1:1'b0;
//
//assign mrd_st_x = (abt_flg_x==1'b1) && (last_flg_x==1'b0) && (rib_empty==1'b0) ? 1'b1: 
//                  (abt_flg_x==1'b1) && (last_flg_x==1'b1) && (rib_empty==1'b0) && (wib_empty==1'b1 || wdb_empty==1'b1) ? 1'b1:1'b0;


//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)                   
//        last_flg <= #U_DLY 1'b0;         
//    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tready==1'b1 && s_axis_rq_tlast==1'b1 && mrd_st==1'b1)
//        last_flg <= #U_DLY 1'b1;
//    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tready==1'b1 && s_axis_rq_tlast==1'b1 && mwr_st==1'b1)
//        last_flg <= #U_DLY 1'b0;       
//end

//assign last_flg_x = (s_axis_rq_tvalid==1'b1 && s_axis_rq_tready==1'b1 && s_axis_rq_tlast==1'b1 && mrd_st==1'b1) ? 1'b1: //RD
//                    (s_axis_rq_tvalid==1'b1 && s_axis_rq_tready==1'b1 && s_axis_rq_tlast==1'b1 && mwr_st==1'b1) ? 1'b0: last_flg; //WR


assign mwr_st_x = (abt_flg_x==1'b1) && (last_flg==1'b1) && (wib_empty==1'b0 && wdb_empty==1'b0) ? 1'b1:                               
                  (abt_flg_x==1'b1) && (last_flg==1'b0) && (rib_empty==1'b1) && (wib_empty==1'b0 && wdb_empty==1'b0) ? 1'b1:1'b0;    
                                                                                                                                       
assign mrd_st_x = (abt_flg_x==1'b1) && (last_flg==1'b0) && (rib_empty==1'b0) ? 1'b1:                                                 
                  (abt_flg_x==1'b1) && (last_flg==1'b1) && (rib_empty==1'b0) && (wib_empty==1'b1 || wdb_empty==1'b1) ? 1'b1:1'b0;    
                                                                                                                                       


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)                   
        last_flg <= #U_DLY 1'b0;         
    else if(mwr_st_x==1'b1)
        last_flg <= #U_DLY 1'b0;
    else if(mrd_st_xr[1]==1'b1)
        last_flg <= #U_DLY 1'b1;       
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        s_axis_rq_tvalid <= #U_DLY 1'b0;
    else if(mwr_st_x==1'b1 || mrd_st_xr[1]==1'b1)
        s_axis_rq_tvalid <= #U_DLY 1'b1;   
    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b1 && s_axis_rq_tready==1'b1)
        s_axis_rq_tvalid <= #U_DLY 1'b0;    
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)      
        mrd_st_xr <= #U_DLY 'b0;        
    else    
        mrd_st_xr <= #U_DLY {mrd_st_xr[0],mrd_st_x};
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        s_axis_rq_tdata <= #U_DLY 'b0;        
    else if(mrd_st_xr[1]==1'b1)
        s_axis_rq_tdata <= #U_DLY {128'b0,mrd_header_dw3,mrd_header_dw2,mrd_header_dw1,mrd_header_dw0};     
   else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tready==1'b0)
        s_axis_rq_tdata <= #U_DLY s_axis_rq_tdata;
    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b0 )
        begin
            if(d_flg[1]==1'b1)
                s_axis_rq_tdata <= #U_DLY  {dout_0_x,dout_3};
            else if(d_flg[0]==1'b1)
                begin  
                    if(l_flg==1'b1)
                        s_axis_rq_tdata <= #U_DLY  {dout_2,dout_1};
                    else
                        s_axis_rq_tdata <= #U_DLY  {dout_2_x,dout_1_x};
                end
        end
    else
        s_axis_rq_tdata <= #U_DLY {dout_0_x[127:0],mwr_header_dw3,mwr_header_dw2,mwr_header_dw1,mwr_header_dw0};

end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        begin
            d_flg <= #U_DLY 'b0;  
            l_flg <= #U_DLY 1'b0;
        end
    else 
    	begin
    	    if(d_flg[0]==1'b1 && s_axis_rq_tready==1'b1)
    	    	d_flg[0] <= #U_DLY 1'b0;   
    	    else if((mwr_st_x==1'b1) || (d_flg[1]==1'b1 && s_axis_rq_tready==1'b1 && cnt<tlp_size-'b1))    
    	        d_flg[0] <= #U_DLY 1'b1;      
          
            if(d_flg[1]==1'b1 && s_axis_rq_tready==1'b1)
  		        d_flg[1] <= #U_DLY 1'b0;   
    	    else if(d_flg[0]==1'b1 && s_axis_rq_tready==1'b1)
    	        d_flg[1] <= #U_DLY 1'b1;
            

            if(l_flg==1'b1 && s_axis_rq_tready==1'b1)
               l_flg <= #U_DLY 1'b0;  
            else if(d_flg[0]==1'b1 && s_axis_rq_tready==1'b0)
               l_flg <= #U_DLY 1'b1;            
    	end       
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        begin
        	  dout_1 <= #U_DLY 'b0;
        	  dout_2 <= #U_DLY 'b0;
        	  dout_3 <= #U_DLY 'b0;
              dout_1_x <= #U_DLY 'b0;
              dout_2_x <= #U_DLY 'b0;

        end
    else
        begin 
            if(wdb_ren==1'b1)
    	        begin
                    dout_1 <= #U_DLY wdb_dout[255:128];
                    dout_2 <= #U_DLY wdb_dout[383:256];
                    dout_3 <= #U_DLY wdb_dout[511:384];    	  	
    	        end

            dout_1_x <= #U_DLY wdb_dout[255:128];
            dout_2_x <= #U_DLY wdb_dout[383:256];
               
        end
end

assign dout_0_x = wdb_dout[127:0];


//------------------------------------------------------------------------
// wdb fifo read
//------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)  
    	  begin   
            wdma_tlp_size_r1 <= #U_DLY 'b0;
            wdma_tlp_size_r2 <= #U_DLY 'b0;
        end
    else 
    	  begin   
            wdma_tlp_size_r1 <= #U_DLY wdma_tlp_size;
            wdma_tlp_size_r2 <= #U_DLY wdma_tlp_size_r1;
        end    
end




//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)     
//        tlp_end_flg <= #U_DLY 1'b0;
//    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b1 && s_axis_rq_tready==1'b1)
//        tlp_end_flg <= #U_DLY 1'b0;   
//    else if(cnt>=tlp_size-'b1)
//        tlp_end_flg <= #U_DLY 1'b1;
//end



always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)       
        cnt <= #U_DLY 'b0;        
    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b1 && s_axis_rq_tready==1'b1)    
        cnt <= #U_DLY 'b0;      
    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b0 && s_axis_rq_tready==1'b1 && mwr_st==1'b1)
        cnt <= #U_DLY cnt +'b1;  
end


//assign wdb_ren = (mwr_st_x==1'b1) ? 1'b1 : 
//                 (tlp_end_flg==1'b0 && s_axis_rq_tready==1'b1 && d_flg[1]==1'b1) ? 1'b1 : 1'b0;                 
 

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)      
        wdb_ren <= #U_DLY 1'b0;            
    else if(mwr_st_x==1'b1)
        wdb_ren <= #U_DLY 1'b1;
    else if(s_axis_rq_tready==1'b1 && d_flg[1]==1'b1 && cnt<tlp_size-'b1)  
        wdb_ren <= #U_DLY 1'b1;
    else
        wdb_ren <= #U_DLY 1'b0;
end

//assign wdb_ren = (s_axis_rq_tready==1'b1 && d_flg[0]==1'b1) ? 1'b1 : 1'b0;         

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        s_axis_rq_tlast <= #U_DLY 'b0;                
    else if(mrd_st_xr[1]==1'b1)
        s_axis_rq_tlast <= #U_DLY 1'b1;                
    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b1 && s_axis_rq_tready==1'b1)  
        s_axis_rq_tlast <= #U_DLY 1'b0;        
    else if(s_axis_rq_tvalid==1'b1 && cnt>=tlp_size-'b1 && d_flg[1]==1'b1 && s_axis_rq_tready==1'b1)
        s_axis_rq_tlast <= #U_DLY 1'b1;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        s_axis_rq_tkeep <= #U_DLY 'b0;     
    else if(mwr_st_x==1'b1)
        s_axis_rq_tkeep <= #U_DLY 8'hff;
    else if(mrd_st_xr[1]==1'b1)
        s_axis_rq_tkeep <= #U_DLY 8'h0f;                        
    else if(s_axis_rq_tvalid==1'b1 && cnt>=tlp_size-'b1  && d_flg[1]==1'b1 && s_axis_rq_tready==1'b1 )   
        s_axis_rq_tkeep <= #U_DLY 8'h0f;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        mwr_st <= #U_DLY 1'b0;      
    else if(mwr_st_x==1'b1)   
        mwr_st <= #U_DLY 1'b1;          
    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b1 && s_axis_rq_tready==1'b1 && mwr_st==1'b1)
        mwr_st <= #U_DLY 1'b0;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        mrd_st <= #U_DLY 1'b0;    
    else if(mrd_st_xr[1]==1'b1)   
        mrd_st <= #U_DLY 1'b1;            
    else if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b1 && s_axis_rq_tready==1'b1 && mrd_st==1'b1)
        mrd_st <= #U_DLY 1'b0;

end

//------------------------------------------------------------------------
// wib fifo read
//------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        wib_ren_r <= #U_DLY 'b0;        
    else
        wib_ren_r <= #U_DLY {wib_ren_r[0],mwr_st_x};
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        wib_ren <= #U_DLY 1'b0;        
    else 
        wib_ren <= #U_DLY wib_ren_r[1];
end


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        wib_dout_r <= #U_DLY 'b0;        
    else 
        wib_dout_r <= #U_DLY wib_dout;
end

//------------------------------------------------------------------------
// rib fifo read
//------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rib_ren <= #U_DLY 1'b0;       
    else if(mrd_st_xr[1]==1'b1)
        rib_ren <= #U_DLY 1'b1;
    else
        rib_ren <= #U_DLY 1'b0;   
end

//assign rib_ren = mrd_st_x;
//------------------------------------------------------------------------
// Memory write header
//------------------------------------------------------------------------
assign wr_dma_addr_h = wib_dout_r[195:164];
assign wr_dma_addr = wib_dout_r[31:0];
assign wdma_tlp_size_dw = wdma_tlp_size[9:2];

assign mwr_header_dw0 = {wr_dma_addr};     //{Addr[31:2],AT}
assign mwr_header_dw1 = {wr_dma_addr_h};
assign mwr_header_dw2 = {16'b0,1'b0,4'b0001,{3'd0,wdma_tlp_size_dw}};  //{requester_id,posioned_req,req_type,dword_cnt}
assign mwr_header_dw3 = {1'b0,3'd0,3'b0,1'b0,5'd0,3'd0,8'd0,8'd0};       //{force_ecrc,attr,tc,req_id_en,5'd0,memssage_rout,Msg_code,tag};

//------------------------------------------------------------------------
// Memory read header
//------------------------------------------------------------------------

assign rd_dma_addr_h = rib_dout[191:160]; 
assign rd_dma_addr = rib_dout[31:0];
assign rdma_tlp_size_dw = rib_dout[41:34];
assign rdma_tag = rib_dout[54:50];


assign mrd_header_dw0 = {rd_dma_addr};
assign mrd_header_dw1 = {rd_dma_addr_h};
assign mrd_header_dw2 = {16'b0,1'b0,4'b0000,{3'd0,rdma_tlp_size_dw}};  //{requester_id,posioned_req,req_type,dword_cnt}
assign mrd_header_dw3 = {1'b0,3'd0,3'b0,1'b0,5'd0,3'd0,8'd0,{3'd0,rdma_tag}};       //{force_ecrc,attr,tc,req_id_en,5'd0,memssage_rout,Msg_code,tag};

//------------------------------------------------------------------------
// DMA count
//------------------------------------------------------------------------
//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)     
//        begin
//            mwr_end <= 1'b0;
//            mrd_end <= 1'b0;
//        end
//    else    
//        begin
//            if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b1 && s_axis_rq_tready==1'b1 && mwr_st==1'b1)
//                mwr_end <= #U_DLY 1'b1; 
//            else
//            	mwr_end <= #U_DLY 1'b0;
//          	  
//            if(s_axis_rq_tvalid==1'b1 && s_axis_rq_tlast==1'b1 && s_axis_rq_tready==1'b1 && mrd_st==1'b1)
//                mrd_end <= #U_DLY 1'b1; 
//            else
//            	mrd_end <= #U_DLY 1'b0;
//        end
//end

//assign wib_din = { {124-WCHN_NUM_W{1'b0}},wchn_cnt,wchn_rd_end,wchn_done,wtlp_real_cnt,wchn_dma_daddr,wchn_dma_plen[24*wchn_cnt+:24],wchn_dma_prev[64*wchn_cnt+:64],wchn_dma_paddr[32*wchn_cnt+:32]};
//wib_din[196+:WCHN_NUM_W]     wchn_cnt;
//wib_din[195:164]             wchn_dma_daddr_h;
//wib_din[163]                 wchn_rd_end;
//wib_din[162]                 wchn_done;
//wib_din[161:152]             wtlp_real_cnt;
//wib_din[151:120]             wchn_dma_daddr;
//wib_din[119:96]              wchn_dma_plen;
//wib_din[95:32]               wchn_dma_prev;
//wib_din[31:0]                wchn_dma_paddr;




always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
        	  wchn_dma_done  <= #U_DLY 1'b0;
              wchn_dma_done_cnt <= #U_DLY 'b0;
              wchn_dma_end   <= #U_DLY 1'b0;
              wchn_dma_chn   <= #U_DLY 'b0;
              wchn_dma_count <= #U_DLY 1'b0;
              wchn_dma_daddr <= #U_DLY 'b0;
              wchn_dma_daddr_h <= #U_DLY 'b0;
              wchn_dma_drev  <= #U_DLY 'b0;
        end	
    else 
        begin
            if(wchn_dma_done==1'b1 && wchn_dma_done_cnt>='d15)
                wchn_dma_done <= #U_DLY 1'b0;
            else if(wib_ren==1'b1 && (wib_dout_r[163]==1'b1 || wib_dout_r[162]==1'b1))
                wchn_dma_done <= #U_DLY 1'b1;

            if(wchn_dma_done==1'b1 && wchn_dma_done_cnt>='d15)
                wchn_dma_done_cnt <= #U_DLY 'd0;
            else if(wchn_dma_done==1'b1)
                wchn_dma_done_cnt <= #U_DLY wchn_dma_done_cnt + 'd1;

            if(wchn_dma_done==1'b1 && wchn_dma_done_cnt>='d15)
                wchn_dma_end <= #U_DLY 1'b0;
            else if(wib_ren==1'b1 && wib_dout_r[163]==1'b1)
                wchn_dma_end <= #U_DLY 1'b1;

            if(wib_ren==1'b1 && (wib_dout_r[163]==1'b1 || wib_dout_r[162]==1'b1) )
                wchn_dma_chn <= #U_DLY wib_dout_r[196+:WCHN_NUM_W];

            if(wib_ren==1'b1 && (wib_dout_r[163]==1'b1 || wib_dout_r[162]==1'b1))
                wchn_dma_count <= #U_DLY wib_dout_r[119:96];
             
            if(wib_ren==1'b1 && (wib_dout_r[163]==1'b1 || wib_dout_r[162]==1'b1))
                wchn_dma_daddr <= #U_DLY wib_dout_r[151:120];

            if(wib_ren==1'b1 && (wib_dout_r[163]==1'b1 || wib_dout_r[162]==1'b1))
                wchn_dma_daddr_h <= #U_DLY wib_dout_r[195:164];
             
            if(wib_ren==1'b1 && (wib_dout_r[163]==1'b1 || wib_dout_r[162]==1'b1))
                wchn_dma_drev <= #U_DLY wib_dout_r[95:32]; 
        end        
end

//-------------------------------------------------------------
// rib_din = {rchn_dma_daddr_h[32*rchn_cnt+:32],  //[191:160]  
//                 rchn_dma_daddr[32*rchn_cnt+:32],  //[159:128]                
//                 rchn_dma_prev[64*rchn_cnt+:64],   //[127:64]
//                 rchn_done,
//                 {8'b0,rib_tag},                   //[63:50]
//                 {{(8-RCHN_NUM_W){1'b0}},rchn_cnt},//[49:42]
//                 rdma_tlp_size,                    //[41:32]
//                 rchn_dma_paddr[32*rchn_cnt+:32]}; //[31:0]


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
        	  rchn_dma_done  <= #U_DLY 1'b0;
              rchn_dma_done_cnt <= #U_DLY 'b0;
              rchn_dma_chn   <= #U_DLY 'b0;
              rchn_dma_daddr <= #U_DLY 'b0;
              rchn_dma_drev  <= #U_DLY 'b0;
              rchn_dma_daddr_h <= #U_DLY 'b0;
        end	
    else 
        begin
            if(rchn_dma_done==1'b1 && rchn_dma_done_cnt>='d15)
                rchn_dma_done <= #U_DLY 1'b0;
            else if(rib_ren==1'b1 && rib_dout[63]==1'b1)
                rchn_dma_done <= #U_DLY 1'b1;
            
            if(rchn_dma_done==1'b1 && rchn_dma_done_cnt>='d15)
                rchn_dma_done_cnt <= #U_DLY 'd0;
            else if(rchn_dma_done==1'b1)
                rchn_dma_done_cnt <= #U_DLY rchn_dma_done_cnt + 'd1;
            
            if(rib_ren==1'b1)
                rchn_dma_chn <= #U_DLY rib_dout[42+:RCHN_NUM_W];
            
            if(rib_ren==1'b1)
                rchn_dma_daddr <= #U_DLY rib_dout[159:128];
            
            if(rib_ren==1'b1)
                rchn_dma_daddr_h <= #U_DLY rib_dout[191:160];

            if(rib_ren==1'b1)
                rchn_dma_drev <= #U_DLY rib_dout[127:64]; 
        end
end




always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        begin     
            wdb_underflow_r[0]  <= #U_DLY 1'b0;
            wdb_ren_r  <= #U_DLY 1'b0;
            wdb_empty_r <= #U_DLY 1'b0;
        end        
    else
        begin
            wdb_ren_r  <= #U_DLY wdb_ren; 
            wdb_empty_r <= #U_DLY wdb_empty;
            if(wdb_ren_r==1'b1 && wdb_empty_r==1'b1)
                wdb_underflow_r[0] <= #U_DLY 1'b1;
            else
                wdb_underflow_r[0] <= #U_DLY 1'b0; 
        end
end


//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)     
//        wdb_underflow_r[0]  <= #U_DLY 1'b0;        
//    else if(wdb_ren==1'b1 && wdb_empty==1'b1)
//        wdb_underflow_r[0] <= #U_DLY 1'b1;
//    else
//        wdb_underflow_r[0] <= #U_DLY 1'b0;   
//end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        wdb_underflow_r[3:1]  <= #U_DLY 'b0;        
    else
        wdb_underflow_r[3:1]  <= #U_DLY wdb_underflow_r[2:0];
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        wdb_underflow  <= #U_DLY 1'b0;        
    else if(|wdb_underflow_r==1'b1)
        wdb_underflow  <= #U_DLY 1'b1;
    else
    	  wdb_underflow  <= #U_DLY 1'b0;
end

//fifo abnormal operation
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        fifo_abnormal  <= #U_DLY 1'b0;   
    else if((wib_empty==1'b0 && wdb_empty==1'b1) || (wib_empty==1'b1 && wdb_empty==1'b0))
        fifo_abnormal  <= #U_DLY 1'b1;  
    else
        fifo_abnormal  <= #U_DLY 1'b0;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        fifo_abnormal_uscnt  <= #U_DLY 'b0; 
    else if(fifo_abnormal_uscnt=='d250) 
    	fifo_abnormal_uscnt  <= #U_DLY 'b0; 
    else if(fifo_abnormal==1'b1)
    	fifo_abnormal_uscnt  <= #U_DLY fifo_abnormal_uscnt + 'b1;
    else
    	fifo_abnormal_uscnt  <= #U_DLY 'b0;    
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        fifo_abnormal_usflg  <= #U_DLY 1'b0; 
    else if(fifo_abnormal_uscnt=='d250) 
    	fifo_abnormal_usflg  <= #U_DLY 1'b1; 
    else 
    	fifo_abnormal_usflg  <= #U_DLY 1'b0;    
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        fifo_abnormal_mscnt <= #U_DLY 'b0;
    else if(fifo_abnormal==1'b0)
        fifo_abnormal_mscnt <= #U_DLY 'b0; 
    else if(fifo_abnormal_mscnt=='d1000)
        fifo_abnormal_mscnt <= #U_DLY 'b0;          
    else if(fifo_abnormal==1'b1 && fifo_abnormal_usflg==1'b1)
    	fifo_abnormal_mscnt  <= #U_DLY fifo_abnormal_mscnt + 'b1;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)        
        fifo_abnormal_msflg <= #U_DLY 1'b0;       
    else if(fifo_abnormal_mscnt=='d1000)   
        fifo_abnormal_msflg <= #U_DLY 1'b1;
    else
        fifo_abnormal_msflg <= #U_DLY 1'b0;     
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)          
        fifo_abnormal_scnt <= #U_DLY 'b0;       
    else if(fifo_abnormal==1'b0)
        fifo_abnormal_scnt <= #U_DLY 'b0;
    else if(fifo_abnormal_scnt=='d1000)
        fifo_abnormal_scnt <= #U_DLY 'b0;
    else if(fifo_abnormal==1'b1 && fifo_abnormal_msflg==1'b1)
        fifo_abnormal_scnt <= #U_DLY fifo_abnormal_scnt + 'b1;   
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)         
        fifo_abnormal_sflg <= #U_DLY 1'b0;       
    else if(fifo_abnormal_scnt=='d1000)
        fifo_abnormal_sflg <= #U_DLY 1'b1;
    else
        fifo_abnormal_sflg <= #U_DLY 1'b0;     
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)          
        fifo_abnormal_cnt <= #U_DLY 'b0;       
    else if(fifo_abnormal==1'b0)
        fifo_abnormal_cnt <= #U_DLY 'b0;
    else if(txfifo_abnormal_rst==1'b1)
        fifo_abnormal_cnt <= #U_DLY 'b0;
    else if(fifo_abnormal==1'b1 && fifo_abnormal_sflg==1'b1)
        fifo_abnormal_cnt <= #U_DLY fifo_abnormal_cnt + 'b1;    
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)         
        fifo_abnormal_rst_r[0] <= #U_DLY 1'b0; 
    else if(txfifo_abnormal_rst==1'b1)
        fifo_abnormal_rst_r[0] <= #U_DLY 1'b0;     
    else if(fifo_abnormal==1'b1 && fifo_abnormal_cnt=='d1 && fifo_abnormal_sflg==1'b1)
        fifo_abnormal_rst_r[0] <= #U_DLY 1'b1;    
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)         
        {txfifo_abnormal_rst,fifo_abnormal_rst_r[3:1]} <= #U_DLY 'b0; 
    else
        {txfifo_abnormal_rst,fifo_abnormal_rst_r[3:1]} <= #U_DLY fifo_abnormal_rst_r[3:0];     
end


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)         
        trabt_err <= #U_DLY 1'b0; 
    else if(mwr_st==1'b1 && mrd_st==1'b1)
        trabt_err <= #U_DLY 1'b1;   
    else
        trabt_err <= #U_DLY 1'b0; 
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
