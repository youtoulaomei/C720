// *********************************************************************************/
// Project Name :
// Author       : dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/11/2 9:59:25
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Sichuan shenrong digital equipment Co., Ltd.. 
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
module pcie_rchn_arbiter#(
parameter                           RCHN_NUM   = 3,
parameter                           RCHN_NUM_W = clog2b(RCHN_NUM),
parameter                           RTAG_NUM   = 32,
parameter                           RDATA_WIDTH= 512,
parameter                           U_DLY = 1
)
(
input                               clk,               
input                               rst_n,             
input       [9:0]                   rdma_tlp_size,
input                               rdma_stop,
//
input                               tag_release,            
//cib         
input       [32*RCHN_NUM-1:0]       rchn_dma_addr,          
input       [RCHN_NUM-1:0]          rchn_dma_en,            
input       [24*RCHN_NUM-1:0]       rchn_dma_len,   
input       [64*RCHN_NUM-1:0]       rchn_dma_rev, 
input       [32*RCHN_NUM-1:0]       rchn_dma_addr_h,          
//fib fifo
output reg                          rib_wen,
output wire [191:0]                 rib_din,
input                               rib_prog_full,
//buf
input                               wr_clk,    
input                               rmem_wr,   
input       [7:0]                   rmem_waddr,
input       [511:0]                 rmem_wdata,
//user
input       [RCHN_NUM-1:0]          rfifo_prog_full,
output reg  [RCHN_NUM-1:0]          rfifo_wr,
output reg  [RDATA_WIDTH-1:0]       rfifo_wr_data,

output wire [1:0]                   t_rchn_cur_st
);
// Parameter Define 
localparam                          RCHN_ABT    = 2'd0;
localparam                          RCHN_RECORD = 2'd1;
localparam                          RCHN_DONE   = 2'd2;

localparam                          BUF_IDLE    = 2'd0;
localparam                          BUF_ABT     = 2'd1;
localparam                          BUF_RDY     = 2'd2;

localparam                          D_IDLE      = 2'd0;
localparam                          D_FRM       = 2'd1;
localparam                          D_WAIT      = 2'd2;

localparam                          ADDR_128PAYLOAD = (RTAG_NUM*128)/64; 
localparam                          ADDR_256PAYLOAD = (RTAG_NUM*256)/64; 
localparam                          ADDR_512PAYLOAD = (RTAG_NUM*512)/64; 
// Register Define 
//
reg     [1:0]                       rchn_cur_st;
reg     [1:0]                       rchn_nex_st;
//
reg     [4:0]                       rib_tag;
reg     [RCHN_NUM-1:0]              rchn_dma_en_dly;
//
reg     [RCHN_NUM_W-1:0]            rchn_cnt;
reg     [RCHN_NUM_W-1:0]            data_user;
//
reg     [24*RCHN_NUM-1:0]           rchn_dma_pcnt;
reg     [32*RCHN_NUM-1:0]           rchn_dma_paddr;
reg     [64*RCHN_NUM-1:0]           rchn_dma_prev;
reg     [32*RCHN_NUM-1:0]           rchn_dma_daddr;
reg     [32*RCHN_NUM-1:0]           rchn_dma_daddr_h;
//
reg                                 tag_idle;
//reg     [4:0]                       rib_tag_r;
reg     [2:0]                       tag_release_r;
reg                                 buf_wr_index;
reg                                 buf_rd_index;
reg     [1:0]                       data_state;
reg     [1:0]                       data_nextstate;
reg                                 buf_rdone;
reg                                 buf_rdone_num;
reg                                 buf_abt;
reg                                 buf_abt_num;
reg                                 buf_rdy;
reg                                 buf_rdy_num;
reg                                 rmem_rd;
reg                                 rmem_rd_r;
reg     [7:0]                       rmem_raddr;
reg                                 rchn_done;
reg     [1:0]                       buf_wr_index_r;

reg     [1:0]                       buf_state [0:1];
reg     [RCHN_NUM_W-1:0]            buf_user  [0:1];
reg     [RCHN_NUM_W-1:0]            curr_rd_user;     
reg     [511:0]                     rmem_rdata;
reg     [2:0]                       rdma_tlp_ind;
// Wire Define 


//state-machine
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        rchn_cur_st <= RCHN_ABT;
    else    
        rchn_cur_st <= #U_DLY rchn_nex_st;
end

always @(*)
begin
    case(rchn_cur_st)
        RCHN_ABT:
            begin
                if( rib_prog_full == 1'b0 &&
                    rfifo_prog_full[rchn_cnt]==1'b0 &&
                    buf_state[buf_wr_index] == BUF_IDLE &&
                    rchn_dma_en[rchn_cnt] == 1'b1 &&
                    rchn_dma_pcnt[24*rchn_cnt+:24] > 24'd0)

                    rchn_nex_st = RCHN_RECORD;
                else
                    rchn_nex_st = RCHN_ABT;
            end

        RCHN_RECORD:
            begin
                if(rib_tag==RTAG_NUM-1) 
                     rchn_nex_st = RCHN_DONE;
                 else
                     rchn_nex_st = RCHN_RECORD;
            end
        
        RCHN_DONE:
            begin
                if(tag_idle == 1'b1)
                   rchn_nex_st = RCHN_ABT;
                else
                	 rchn_nex_st = RCHN_DONE;   
            end
              
        default:rchn_nex_st = RCHN_ABT;
    endcase
end


integer k;
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            rchn_dma_en_dly <= {RCHN_NUM{1'b0}};
            rchn_cnt <= {RCHN_NUM_W{1'b0}};
            rchn_dma_pcnt <= {RCHN_NUM{24'd0}};
            rchn_dma_paddr <= {RCHN_NUM{32'd0}};
            rchn_dma_prev <= {RCHN_NUM{64'd0}}; 
            rchn_done <= #U_DLY 1'b0;
            rib_tag <= 5'd0;
            rchn_dma_daddr <= 'd0;
            rchn_dma_daddr_h <= 'd0;
        end
    else    
        begin
            rchn_dma_en_dly <= #U_DLY rchn_dma_en;

            if(rchn_nex_st==RCHN_ABT)
                begin
                    if(rchn_cnt < (RCHN_NUM-1))
                        rchn_cnt <= #U_DLY rchn_cnt + 'd1;
                    else
                        rchn_cnt <= #U_DLY {RCHN_NUM{1'b0}};
                end


            for(k = 0;k < RCHN_NUM;k = k+1)
                begin
                    if(rdma_stop == 1'b1)
                        rchn_dma_pcnt[24*k+:24] <= #U_DLY 24'd0;
                    else if({rchn_dma_en_dly[k],rchn_dma_en[k]} == 2'b01)
                        rchn_dma_pcnt[24*k+:24] <= #U_DLY rchn_dma_len[24*k+:24];
                    else if(rib_wen == 1'b1 && rchn_dma_pcnt[24*k+:24] > 24'd0 && k == rchn_cnt)
                        rchn_dma_pcnt[24*k+:24] <= #U_DLY rchn_dma_pcnt[24*k+:24] - 24'd1;
                    else;

                    if({rchn_dma_en_dly[k],rchn_dma_en[k]} == 2'b01)
                        rchn_dma_paddr[32*k+:32] <= #U_DLY rchn_dma_addr[32*k+:32];                   
                    else if(rib_wen == 1'b1 && k == rchn_cnt)
                        rchn_dma_paddr[32*k+:32] <= #U_DLY rchn_dma_paddr[32*k+:32] + rdma_tlp_size;
                    else;
                    	
                    if({rchn_dma_en_dly[k],rchn_dma_en[k]} == 2'b01)
                        rchn_dma_daddr[32*k+:32] <= #U_DLY rchn_dma_addr[32*k+:32];                       	
                    
                    if({rchn_dma_en_dly[k],rchn_dma_en[k]} == 2'b01)
                        rchn_dma_daddr_h[32*k+:32] <= #U_DLY rchn_dma_addr_h[32*k+:32];                       	
                    	
                    if({rchn_dma_en_dly[k],rchn_dma_en[k]} == 2'b01)
                        rchn_dma_prev[64*k+:64] <= #U_DLY rchn_dma_rev[64*k+:64];       
                    
                    if(rchn_cur_st==RCHN_DONE && rchn_nex_st==RCHN_ABT)    
                    	  rchn_done  <= #U_DLY 1'b0;   
                    else if(rib_wen == 1'b1 && rchn_dma_pcnt[24*rchn_cnt+:24]== 24'd2)
                    	  rchn_done  <= #U_DLY 1'b1;                
                end

            if(rchn_cur_st==RCHN_DONE)
            	  rib_tag <= #U_DLY 'b0;
            else if(rib_wen==1'b1)
                rib_tag <= #U_DLY rib_tag + 5'd1;
            
        end
end


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        tag_idle <= #U_DLY 1'b1; 
    else if(tag_release_r[1]==1'b1 && tag_release_r[2]==1'b0)
        tag_idle <= #U_DLY 1'b1;    
    else if(rchn_cur_st == RCHN_ABT && rchn_nex_st==RCHN_RECORD)
        tag_idle <= #U_DLY 1'b0;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rib_wen <= #U_DLY 1'b0;        
    //else if(rchn_cur_st == RCHN_RECORD && rib_tag <'d31)
    else if(rchn_cur_st == RCHN_RECORD && rib_tag <RTAG_NUM-1)
        rib_wen <= #U_DLY 1'b1;
    else
        rib_wen <= #U_DLY 1'b0;   
end

assign rib_din = {rchn_dma_daddr_h[32*rchn_cnt+:32],  //[191:160]  
                 rchn_dma_daddr[32*rchn_cnt+:32],  //[159:128]                
                 rchn_dma_prev[64*rchn_cnt+:64],   //[127:64]
                 rchn_done,                        //[63]
                 {8'b0,rib_tag},                   //[62:50]
                 {{(8-RCHN_NUM_W){1'b0}},rchn_cnt},//[49:42]
                 rdma_tlp_size,                    //[41:32]
                 rchn_dma_paddr[32*rchn_cnt+:32]}; //[31:0]

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        tag_release_r <= #U_DLY 'b0;      
    else    
        tag_release_r <= #U_DLY {tag_release_r[1:0],tag_release};
end
//----------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        data_user <= #U_DLY 'b0;        
    else if(rchn_cur_st == RCHN_ABT && rchn_nex_st==RCHN_RECORD)
        data_user <= #U_DLY  rchn_cnt;  
end

//ABT NUM
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        buf_abt <= #U_DLY 1'b0;        
    else if(rchn_cur_st == RCHN_ABT && rchn_nex_st==RCHN_RECORD)
        buf_abt <= #U_DLY 1'b1;
    else
    	  buf_abt <= #U_DLY 1'b0;  
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        buf_abt_num <= #U_DLY 1'b0;        
    else if(rchn_cur_st == RCHN_ABT && rchn_nex_st==RCHN_RECORD)
        buf_abt_num <= #U_DLY buf_wr_index;
end

//
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        buf_wr_index <= #U_DLY 1'b0;        
    else if(rchn_cur_st==RCHN_DONE && rchn_nex_st==RCHN_ABT)  
        buf_wr_index <= #U_DLY buf_wr_index + 1'b1;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        buf_rd_index <= #U_DLY 1'b0;        
    else if(data_state==D_WAIT)
        buf_rd_index <= #U_DLY buf_rd_index + 1'b1;   
end

//BUF_RDy
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        buf_rdy <= #U_DLY 1'b0;        
    else if(tag_release_r[1]==1'b1 && tag_release_r[2]==1'b0)  
        buf_rdy <= #U_DLY 1'b1;
    else
    	  buf_rdy <= #U_DLY 1'b0;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        buf_rdy_num <= #U_DLY 1'b0;        
    else if(tag_release_r[1]==1'b1 && tag_release_r[2]==1'b0)  
        buf_rdy_num <= #U_DLY buf_wr_index;
end

//BUF_RDONE
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        buf_rdone <= #U_DLY 1'b0;        
    else if(data_state==D_WAIT)
        buf_rdone <= #U_DLY 1'b1;  
    else
    	  buf_rdone <= #U_DLY 1'b0;   
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        buf_rdone_num <= #U_DLY 1'b0;        
    else if(data_state==D_WAIT)
        buf_rdone_num <= #U_DLY buf_rd_index;   
end
//


always @ (posedge clk or negedge rst_n)begin:BUF_STAT_PRO
integer i;
    for(i=0;i<=1;i=i+1)
    if(rst_n == 1'b0)     
        buf_state[i] <= #U_DLY BUF_IDLE;        
    else   
        begin
            if(buf_rdone==1'b1 && buf_rdone_num==i)
                buf_state[i] <= #U_DLY BUF_IDLE;
            else if(buf_abt==1'b1 && buf_abt_num==i)
                buf_state[i] <= #U_DLY BUF_ABT;
            else if(buf_rdy==1'b1 && buf_rdy_num==i)
                buf_state[i] <= #U_DLY BUF_RDY;
        end   
end

wire [1:0] buf_state_0;
wire [1:0] buf_state_1;
assign  buf_state_0 = buf_state[0];
assign  buf_state_1 = buf_state[1];

always @ (posedge clk or negedge rst_n)begin:BUF_USER_PRO
integer i;
    for(i=0;i<=1;i=i+1)
    if(rst_n == 1'b0)     
        buf_user[i] <= #U_DLY 'b0;        
    else 

        begin
            if(buf_abt==1'b1 && buf_abt_num==i)
                buf_user[i] <= #U_DLY data_user;
        end   
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        data_state <= #U_DLY D_IDLE;        
    else    
        data_state <= #U_DLY data_nextstate; 
end

always @ (*)begin
    case(data_state)
        D_IDLE:
        begin
            //if(buf_state[buf_rd_index]==BUF_RDY && rfifo_prog_full[curr_rd_user]==1'b0)
            if(buf_state[buf_rd_index]==BUF_RDY)
                data_nextstate = D_FRM;
            else
                data_nextstate = D_IDLE;
        end

        D_FRM:
        begin
            if( (rmem_rd==1'b1 && rmem_raddr==ADDR_128PAYLOAD-1 && rdma_tlp_ind==3'b000) //128
            	||(rmem_rd==1'b1 && rmem_raddr==ADDR_256PAYLOAD-1 && rdma_tlp_ind==3'b001) //256
            	||(rmem_rd==1'b1 && rmem_raddr==ADDR_512PAYLOAD-1 && rdma_tlp_ind==3'b010))//512
                data_nextstate=D_WAIT;
            else
                data_nextstate=D_FRM;
        end

        D_WAIT:
        begin
            data_nextstate=D_IDLE;
        end
        
        default:data_nextstate=D_IDLE;
    endcase
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        curr_rd_user <= #U_DLY 'b0;        
    else
        curr_rd_user <= #U_DLY buf_user[buf_rd_index];
end
//--------------------------------------------------------------------------------------------
// WFIFO 256bit 512bit LOGIC
//--------------------------------------------------------------------------------------------
generate
if(RDATA_WIDTH==512)
begin
    always @ (posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)    
        	rmem_rd <= #U_DLY 1'b0;
        else if((rmem_rd==1'b1 && rmem_raddr==ADDR_128PAYLOAD-1 && rdma_tlp_ind==3'b000) //128
        	  || (rmem_rd==1'b1 && rmem_raddr==ADDR_256PAYLOAD-1 && rdma_tlp_ind==3'b001) //256
        	  || (rmem_rd==1'b1 && rmem_raddr==ADDR_512PAYLOAD-1 && rdma_tlp_ind==3'b010))//512
        	rmem_rd <= #U_DLY 1'b0;    
        else if(data_state==D_IDLE && data_nextstate==D_FRM)	
        	rmem_rd <= #U_DLY 1'b1;   	
    end
    
    always @ (posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)    
        	rmem_rd_r <= #U_DLY 1'b0;
        else 
        	rmem_rd_r <= #U_DLY rmem_rd;    
    end
    
    always @ (posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)     
          rmem_raddr <= #U_DLY 'b0;
        else if((rmem_rd==1'b1 && rmem_raddr==ADDR_128PAYLOAD-1 && rdma_tlp_ind==3'b000) //128
        	  || (rmem_rd==1'b1 && rmem_raddr==ADDR_256PAYLOAD-1 && rdma_tlp_ind==3'b001) //256
        	  || (rmem_rd==1'b1 && rmem_raddr==ADDR_512PAYLOAD-1 && rdma_tlp_ind==3'b010))//512
        	rmem_raddr <= #U_DLY 'b0;    
        else if(rmem_rd==1'b1)	
        	rmem_raddr <= #U_DLY rmem_raddr + 'b1;   	
    end
    
    always @ (posedge clk or negedge rst_n)begin:RFIFO_WR_PRO
    integer i;
        if(rst_n == 1'b0)     
        	rfifo_wr <= #U_DLY 1'b0;
        else
        	for(i=0;i<RCHN_NUM;i=i+1) 
        	    begin
                  if(rmem_rd_r==1'b1 && curr_rd_user==i)
                  	  rfifo_wr[i] <= #U_DLY 1'b1;    
                  else 
                  	  rfifo_wr[i] <= #U_DLY 1'b0;
              end   	
    end
    
    always @ (posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)     
        	rfifo_wr_data <= #U_DLY 'b0;
        else 
        	rfifo_wr_data <= #U_DLY rmem_rdata;    
    end
end

else if(RDATA_WIDTH==256)
begin:D256_PRO
reg          rmem_rd_1r;
reg [255:0]  rmem_rdata_hr;
reg [7:0]    rmem_rd_rcnt;
    always @ (posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)    
        	rmem_rd <= #U_DLY 1'b0;
        else if(rmem_rd==1'b1)
        	rmem_rd <= #U_DLY 1'b0;
        else if( (rmem_rd_r==1'b1 && rmem_rd_rcnt<ADDR_128PAYLOAD-1 && rdma_tlp_ind==3'b000) //128
        	  || (rmem_rd_r==1'b1 && rmem_rd_rcnt<ADDR_256PAYLOAD-1 && rdma_tlp_ind==3'b001) //256
        	  || (rmem_rd_r==1'b1 && rmem_rd_rcnt<ADDR_512PAYLOAD-1 && rdma_tlp_ind==3'b010) //512
              || (data_state==D_IDLE && data_nextstate==D_FRM))
        	rmem_rd <= #U_DLY 1'b1;
    end
    
    always @ (posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0) 
            begin   
        	    rmem_rd_r <= #U_DLY 1'b0;
        	    rmem_rd_1r <= #U_DLY 1'b0;
                rmem_rd_rcnt <= #U_DLY 'd0;
            end
        else 
            begin
        	    rmem_rd_r <= #U_DLY rmem_rd;
        	    rmem_rd_1r <= #U_DLY rmem_rd_r;
              
                if( (rmem_rd_r==1'b1 && rmem_rd_rcnt==ADDR_128PAYLOAD-1 && rdma_tlp_ind==3'b000) //128
        	     || (rmem_rd_r==1'b1 && rmem_rd_rcnt==ADDR_256PAYLOAD-1 && rdma_tlp_ind==3'b001) //256
        	     || (rmem_rd_r==1'b1 && rmem_rd_rcnt==ADDR_512PAYLOAD-1 && rdma_tlp_ind==3'b010)) //512
                    rmem_rd_rcnt <= #U_DLY 'd0;
                else if(rmem_rd_r==1'b1)
                    rmem_rd_rcnt <= #U_DLY rmem_rd_rcnt + 'd1;
            end    
    end
    
    always @ (posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)     
          rmem_raddr <= #U_DLY 'b0;
        else if((rmem_rd==1'b1 && rmem_raddr==ADDR_128PAYLOAD-1 && rdma_tlp_ind==3'b000) //128
        	  || (rmem_rd==1'b1 && rmem_raddr==ADDR_256PAYLOAD-1 && rdma_tlp_ind==3'b001) //256
        	  || (rmem_rd==1'b1 && rmem_raddr==ADDR_512PAYLOAD-1 && rdma_tlp_ind==3'b010))//512
        	rmem_raddr <= #U_DLY 'b0;    
        else if(rmem_rd==1'b1)	
        	rmem_raddr <= #U_DLY rmem_raddr + 'b1;   	
    end
    
    always @ (posedge clk or negedge rst_n)begin:RFIFO_WR_PRO
    integer i;
        if(rst_n == 1'b0)     
        	rfifo_wr <= #U_DLY 1'b0;
        else
        	for(i=0;i<RCHN_NUM;i=i+1) 
        	    begin
                  if((rmem_rd_r==1'b1||rmem_rd_1r==1'b1) && (curr_rd_user==i))
                  	  rfifo_wr[i] <= #U_DLY 1'b1;    
                  else 
                  	  rfifo_wr[i] <= #U_DLY 1'b0;
              end   	
    end
    
    always @ (posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)     
            begin
        	    rfifo_wr_data <= #U_DLY 'b0;
                rmem_rdata_hr <= #U_DLY 'b0;
            end
        else 
            begin
                if(rmem_rd_r==1'b1)
        	        rfifo_wr_data <= #U_DLY rmem_rdata[255:0];
                else if(rmem_rd_1r==1'b1)    
        	        rfifo_wr_data <= #U_DLY rmem_rdata_hr;

                if(rmem_rd_r==1'b1)
                    rmem_rdata_hr <= #U_DLY rmem_rdata[511:256];
            end
    end

end
endgenerate

//--------------------------------------------------------------------------------------------
// WFIFO 256bit 512bit LOGIC
//--------------------------------------------------------------------------------------------


// Parameter Define 
localparam MEM_WIDTH   = 512; 
localparam MEM_DEEPTH  = 512;
localparam MEM_ADDR_W  = clog2b(MEM_DEEPTH);
wire [MEM_ADDR_W-1:0]   mem_waddr;
wire [MEM_ADDR_W-1:0]   mem_raddr; 
reg     [MEM_WIDTH-1:0]             mem [MEM_DEEPTH-1:0]/* synthesis syn_ramstyle="block_ram" */;

always @ (posedge wr_clk)
begin
    buf_wr_index_r <= #U_DLY {buf_wr_index_r[0],buf_wr_index};
end


assign mem_waddr = {buf_wr_index_r[1],rmem_waddr};
assign mem_raddr = {buf_rd_index,rmem_raddr};

`ifdef SIM
integer i;
initial
begin
    for( i=0;i<=MEM_DEEPTH-1;i=i+1)
      begin
         mem[i] = {(MEM_WIDTH){1'b0}};        
      end
end  
`endif


always @ (posedge wr_clk)
begin
    if(rmem_wr == 1'b1)     
        mem[mem_waddr] <= #U_DLY rmem_wdata;    
end

always @ (posedge clk)
begin                                        
    rmem_rdata  <= #U_DLY mem[mem_raddr]; 
end     


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
    	  rdma_tlp_ind <= #U_DLY 3'b000;
    else if(rdma_tlp_size==10'd256)
    	  rdma_tlp_ind <= #U_DLY 3'b001;
    else if(rdma_tlp_size==10'd512)
    	  rdma_tlp_ind <= #U_DLY 3'b010;    	  
    else
    	  rdma_tlp_ind <= #U_DLY 3'b000;    	  	  
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

assign t_rchn_cur_st = rchn_cur_st;





//(* syn_keep = "true", mark_debug = "true" *)reg       rchn_first;
(* syn_keep = "true", mark_debug = "true" *)reg [511:0] rmem_wdata_r;
(* syn_keep = "true", mark_debug = "true" *)reg [15:0]  rmem_terr_l;
(* syn_keep = "true", mark_debug = "true" *)reg         rmem_terr;
//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)                  
//        rchn_st_r <= #U_DLY 'b0;               
//    else 
//        rchn_st_r <= #U_DLY {rchn_st_r[1:0],rchn_st};   
//end


//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)     
//        rchn_first <= #U_DLY 1'b1;        
//    else if(rfifo_wr==1'b1) 
//        rchn_first <= #U_DLY 1'b0;  
//end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)         
        rmem_wdata_r <= #U_DLY 'b0;        
    else if(rfifo_wr[0]==1'b1)   
        rmem_wdata_r <= #U_DLY rfifo_wr_data;
end

always @ (posedge clk or negedge rst_n)begin:RMEM_TERR_L_PRO
integer i;
    if(rst_n == 1'b0)      
        rmem_terr_l <= #U_DLY 'b0;       
    //else if(rfifo_wr==1'b1 && rchn_first==1'b0)
    else if(rfifo_wr[0]==1'b1)
        begin
            for(i=0;i<16;i=i+1)
               if(rfifo_wr_data[i*32+:32]!=rmem_wdata_r[i*32+:32]+'d16)
                   rmem_terr_l[i] <= #U_DLY 1'b1;
               else
                   rmem_terr_l[i] <= #U_DLY 1'b0;
        end   
    else
        rmem_terr_l <= #U_DLY 'b0;   
end


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)    
        rmem_terr <= #U_DLY 1'b0; 
    else if(|rmem_terr_l==1'b1)
        rmem_terr <= #U_DLY 1'b1;     
    else 
        rmem_terr <= #U_DLY 1'b0;     
end

/*
(* syn_keep = "true", mark_debug = "true" *)reg       trig_err;
(* syn_keep = "true", mark_debug = "true" *)reg [4:0]      trig_err_r;
(* syn_keep = "true", mark_debug = "true" *)reg [13:0]      trig_err_cnt;
(* syn_keep = "true", mark_debug = "true" *)reg [3:0]      etcnt;
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            trig_err <= 'b0;
            trig_err_cnt <= #U_DLY 'd0;
            etcnt <= #U_DLY 'd0;
        end
    else
        begin 
            if(rchn_cur_st==RCHN_DONE)  
                trig_err_cnt <= #U_DLY trig_err_cnt + 'd1;
            else
                trig_err_cnt <= #U_DLY 'd0;

            if(trig_err==1'b1 && etcnt=='d8)
                trig_err <= #U_DLY 1'b0;
            else if(trig_err_cnt=='d1000)
                trig_err <= #U_DLY 1'b1;

            if(trig_err==1'b1 && etcnt=='d8)
                etcnt <= #U_DLY 'd0;
            else if(trig_err==1'b1)
                etcnt <= #U_DLY etcnt + 'd1;

        end   
end

always @ (posedge wr_clk or negedge rst_n)
begin
    if(rst_n==1'b0)
        trig_err_r <= #U_DLY 'd0;
    else
        trig_err_r <= #U_DLY {trig_err_r[3:0],trig_err};
end
*/
endmodule
