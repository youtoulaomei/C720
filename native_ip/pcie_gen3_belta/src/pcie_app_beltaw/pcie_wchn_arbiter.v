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
module pcie_wchn_arbiter#(
parameter                           WCHN_NUM   = 60,
parameter                           WCHN_NUM_W = clog2b(WCHN_NUM),
parameter                           WPHY_NUM   = 4,
parameter                           WPHY_NUM_W = clog2b(WPHY_NUM),
parameter                           BURST_LEN   = 2048,
parameter                           U_DLY = 1
)
(
input                               clk,               //PCIE User Clock.
input                               rst_n,             //PCIE User Reset(Active Low).
input       [9:0]                   wdma_tlp_size,
input                               wdma_stop,              //Finish DMA Operation of Channels

input      [WPHY_NUM-1:0]             wchn_eflg,
output reg [WPHY_NUM-1:0]             wchn_eflg_clr,
input      [WPHY_NUM-1:0]             wchn_dvld,              //Write Channels Data Valid.
output reg [WPHY_NUM-1:0]             wchn_ren,               //Write Channels Read Enable.
input [(528+WCHN_NUM_W)*WPHY_NUM-1:0] wchn_dout,              //Write Channels Data(256bits/chn). 


input       [32*WCHN_NUM-1:0]       wchn_dma_addr,          //Write Channels DMA Start Addr.
input       [32*WCHN_NUM-1:0]       wchn_dma_addr_h,        //Write Channels DMA Start Addr H.
input       [WCHN_NUM-1:0]          wchn_dma_en,            //Write Channels DMA Enable.
input       [24*WCHN_NUM-1:0]       wchn_dma_len,           //Write Channels DMA Length(Unit:128Bytes).        
input       [64*WCHN_NUM-1:0]       wchn_dma_rev,
output reg                          wchn_len_done,
output reg  [WCHN_NUM_W-1:0]        wchn_len_chn, 


input                               wdb_full,
input                               wdb_prog_full,
output reg                          wdb_wen,
output reg    [512-1:0]             wdb_din,

input                               wib_full,
input                               wib_prog_full,
output reg                          wib_wen,
output wire   [255:0]               wib_din,

output reg                          wdb_overflow,
output reg                          wib_overflow,
output wire [1:0]                   t_wchn_cur_st,
output reg                          wchnindex_err,
output reg  [WCHN_NUM_W-1:0]        wchn_curr_index
);
// Parameter Define 
localparam                          WCHN_ABT    = 2'd0;
localparam                          WCHN_READ   = 2'd1;
localparam                          WCHN_WAIT   = 2'd2;


// Register Define 
reg     [1:0]                       wchn_cur_st;
reg     [1:0]                       wchn_nex_st;
reg     [WCHN_NUM-1:0]              wchn_dma_en_dly;
reg     [WCHN_NUM_W-1:0]            wchn_cnt;
reg     [24*WCHN_NUM-1:0]           wchn_dma_pcnt;
reg     [32*WCHN_NUM-1:0]           wchn_dma_paddr;
reg     [32*WCHN_NUM-1:0]           wchn_dma_daddr;
reg     [32*WCHN_NUM-1:0]           wchn_dma_daddr_h;
reg     [64*WCHN_NUM-1:0]           wchn_dma_prev;
reg     [24*WCHN_NUM-1:0]           wchn_dma_plen;
reg                                 wchn_done;
reg     [WPHY_NUM_W-1:0]            wphy_cnt;
reg     [WCHN_NUM-1:0]              wchn_plen_rd;
reg     [14:0]                      wchn_plen_r;


reg     [9:0]                       wtlp_cnt;
reg                                 wchn_rd_end;
reg                                 wchn_rd_end_pro;
reg     [9:0]                       wtlp_byte_cnt;
reg     [9:0]                       wtlp_real_cnt;

reg                                 wdb_wen_pre;
reg     [WCHN_NUM-1:0]              wchn_dma_pcnt_ok;
reg                                 burst_done;
reg     [15:0]                      burst_len;
reg     [WPHY_NUM-1:0]              wchn_eflg_r1;
reg     [WPHY_NUM-1:0]              wchn_eflg_r2;
reg     [WCHN_NUM-1:0]              wchn_dma_len_done;

// Wire Define 
wire    [WCHN_NUM_W-1:0]            wchn_index;


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        wchn_cur_st <= WCHN_ABT;
    else    
        wchn_cur_st <= #U_DLY wchn_nex_st;
end

always @(*)
begin
    case(wchn_cur_st)
        WCHN_ABT:
            begin
                if(wdb_prog_full == 1'b0 && 
                   wib_prog_full == 1'b0 && 
                   wchn_dma_pcnt_ok[wchn_index] ==1'b1 && 
                   (wchn_dvld[wphy_cnt] == 1'b1 || wchn_eflg_r2[wphy_cnt] == 1'b1))
                    wchn_nex_st = WCHN_READ;
                else
                    wchn_nex_st = WCHN_ABT;
            end
        WCHN_READ:
            begin
                if(burst_done == 1'b1 || wchn_rd_end_pro==1'b1 || wchn_dma_len_done[wchn_cnt]==1'b1)
                    wchn_nex_st = WCHN_WAIT;
                else
                    wchn_nex_st = WCHN_READ;
            end
        
        WCHN_WAIT:
            begin
                if(wchn_rd_end_pro==1'b1)
                    begin
                        if(wchn_eflg_r2[wphy_cnt] ==1'b0)
                            wchn_nex_st = WCHN_ABT;
                        else
                            wchn_nex_st = WCHN_WAIT;
                    end
                else
                    wchn_nex_st = WCHN_ABT;
            end
        
        default:wchn_nex_st = WCHN_ABT;
    endcase
end



always @ (posedge clk or negedge rst_n)
begin:PCNT_OK
integer k;
    if(rst_n == 1'b0)
        wchn_dma_pcnt_ok <= 'b0;
    else 
    for(k=0;k<WCHN_NUM;k=k+1)
        begin	
            if(wchn_dma_pcnt[24*k+:24] > 24'd0 )    
            	  wchn_dma_pcnt_ok[k] <= 1'b1;
            else
            	  wchn_dma_pcnt_ok[k] <= 1'b0;
        end
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
    	  begin
            wchn_eflg_r1 <= 'b0;
            wchn_eflg_r2 <= 'b0;
        end
    else 
    	  begin
            wchn_eflg_r1 <= wchn_eflg;
            wchn_eflg_r2 <= wchn_eflg_r1;
        end    	
end


always @ (posedge clk or negedge rst_n)begin:MAIN_LOGIC
integer i,j;
    if(rst_n == 1'b0)     
        begin
            wchn_dma_en_dly <= {WCHN_NUM{1'b0}};
            wchn_cnt <= {WCHN_NUM_W{1'b0}};
            wphy_cnt <= {WPHY_NUM_W{1'b0}};
            wchn_dma_pcnt <= {WCHN_NUM{24'd0}};
            wchn_dma_paddr <= {WCHN_NUM{32'd0}};
            wchn_dma_daddr <= {WCHN_NUM{32'd0}};
            wchn_dma_daddr_h <= {WCHN_NUM{32'd0}};
            wchn_dma_prev <= {WCHN_NUM{64'd0}}; 
            wtlp_cnt <= 'd0;
            wchn_ren <= {WPHY_NUM_W{1'b0}};
            wib_wen <= 1'b0;
            wdb_wen <= 1'b0;
            wdb_wen_pre <= 'd0;
            burst_len <= 'b0;
            burst_done<= 1'b0;
            wchn_rd_end <=1'b0;
            wchn_rd_end_pro <=1'b0;
            wchn_eflg_clr <= 'b0;
            wchn_dma_len_done <= 'b0;
            wtlp_real_cnt <='b0;
            wchn_done <= #U_DLY 1'b0;
            wchn_dma_plen <= #U_DLY 'd0;
            wchnindex_err <= #U_DLY 1'b0;
            wtlp_byte_cnt <= #U_DLY 'b0;
            wchn_plen_rd <= #U_DLY 'b0;
            wchn_plen_r <= #U_DLY 15'b0;
        end
    else    
        begin
            wchn_dma_en_dly <= #U_DLY wchn_dma_en;

            if(wchn_cur_st == WCHN_ABT && wchn_nex_st == WCHN_READ)
                wchn_cnt <= #U_DLY wchn_index;

            if(wchn_nex_st == WCHN_ABT)
                begin
                    if(wphy_cnt < (WPHY_NUM - 1))
                        wphy_cnt <= #U_DLY wphy_cnt + 'd1;
                    else
                        wphy_cnt <= #U_DLY {WPHY_NUM_W{1'b0}};
                end


            for(i = 0;i < WCHN_NUM;i = i+1)
                begin
                    if(wdma_stop == 1'b1 || (wchn_rd_end==1'b1 && i == wchn_cnt) )
                        wchn_dma_pcnt[24*i+:24] <= #U_DLY 24'd0;
                    else if({wchn_dma_en_dly[i],wchn_dma_en[i]} == 2'b01)
                        wchn_dma_pcnt[24*i+:24] <= #U_DLY wchn_dma_len[24*i+:24];
                    else if(wib_wen == 1'b1 && wchn_dma_pcnt[24*i+:24] > 24'd0 && i == wchn_cnt)
                        wchn_dma_pcnt[24*i+:24] <= #U_DLY wchn_dma_pcnt[24*i+:24] - 24'd1;
                    else;

                    if({wchn_dma_en_dly[i],wchn_dma_en[i]} == 2'b01)
                        wchn_dma_paddr[32*i+:32] <= #U_DLY wchn_dma_addr[32*i+:32];                   
                    else if(wib_wen == 1'b1 && i == wchn_cnt)
                        wchn_dma_paddr[32*i+:32] <= #U_DLY wchn_dma_paddr[32*i+:32] + wdma_tlp_size;
                    else;

                    if({wchn_dma_en_dly[i],wchn_dma_en[i]} == 2'b01)
                        wchn_dma_daddr[32*i+:32] <= #U_DLY wchn_dma_addr[32*i+:32];                   
                    
                    if({wchn_dma_en_dly[i],wchn_dma_en[i]} == 2'b01)
                        wchn_dma_daddr_h[32*i+:32] <= #U_DLY wchn_dma_addr_h[32*i+:32];                   
  
                    if({wchn_dma_en_dly[i],wchn_dma_en[i]} == 2'b01)
                        wchn_dma_prev[64*i+:64] <= #U_DLY wchn_dma_rev[64*i+:64];                   
                    
                    
                    if({wchn_dma_en_dly[i],wchn_dma_en[i]} == 2'b01)	
                        wchn_dma_len_done[i] <= 'b0;
                    else if(wib_wen== 1'b1 && wchn_dma_pcnt[24*i+:24]=='d1 && i == wchn_cnt)
                    	wchn_dma_len_done[i] <= 1'b1;    
                    	  
                    //if({wchn_dma_en_dly[i],wchn_dma_en[i]} == 2'b01)	
                    //    wchn_dma_plen[24*i+:24] <= 'b0;
                    //else if( (|wchn_ren)== 1'b1 && i == wchn_cnt)
                    ////else if(wchn_ren[i]== 1'b1)
                    //	wchn_dma_plen[24*i+:24] <= wchn_dma_plen[24*i+:24] + 512/8;                   	  
                    if({wchn_dma_en_dly[i],wchn_dma_en[i]} == 2'b01)	
                        wchn_dma_plen[24*i+:24] <= 'b0;
                    else if( wchn_plen_rd[i]== 1'b1)
                    	wchn_dma_plen[24*i+:24] <= wchn_dma_plen[24*i+:24] + wchn_plen_r;

                    if(wchn_cur_st == WCHN_ABT &&  wchn_nex_st == WCHN_READ)
                        wchn_plen_r <= #U_DLY  wchn_dout[((528+WCHN_NUM_W)*wphy_cnt+513)+:15];

                    if(wchn_cur_st == WCHN_ABT &&  wchn_nex_st == WCHN_READ && i == wchn_index)
                        wchn_plen_rd[i] <= #U_DLY 1'b1;
                    else
                        wchn_plen_rd[i] <= #U_DLY 1'b0;

                end
            
            if(wchn_cur_st==WCHN_ABT)
                wchn_done <= #U_DLY 1'b0;
            else if((wtlp_cnt >= wdma_tlp_size -'d64) && (wchn_dma_pcnt[wchn_cnt*24+:24]=='d1))
                wchn_done <= #U_DLY 1'b1;    

            for(j=0;j<WPHY_NUM;j=j+1)
            begin
                if(wchn_ren[j]==1'b1 && wchn_dout[(528+WCHN_NUM_W)*j+512]==1'b1) 
                    wchn_ren[j] <= #U_DLY 1'b0;
            else if((wtlp_cnt >= wdma_tlp_size -'d64) && (wchn_dma_pcnt[wchn_cnt*24+:24]=='d1 || burst_len>=BURST_LEN-wdma_tlp_size))
                    wchn_ren[j] <= #U_DLY 1'b0;
                else if(wchn_cur_st == WCHN_READ && wchn_rd_end==1'b0 && wchn_dma_len_done[wchn_cnt]==1'b0 && burst_done==1'b0 && j==wphy_cnt)
                    wchn_ren[j] <= #U_DLY 1'b1;
                else
                    wchn_ren[j] <= #U_DLY 1'b0;

                if(wchn_cur_st == WCHN_WAIT && wchn_nex_st == WCHN_ABT && j==wphy_cnt)
                    wchn_eflg_clr[j]           <= #U_DLY 'b0;
                else if( wchn_cur_st == WCHN_READ && wchn_nex_st == WCHN_WAIT && wchn_rd_end==1'b1 && j==wphy_cnt)
                    wchn_eflg_clr[j] <= #U_DLY 1'b1;
            end

            if(wchn_cur_st == WCHN_ABT)
                wtlp_cnt <= #U_DLY 'b0;
            else if(wchn_cur_st == WCHN_READ)
                begin
                    
                    if(wdb_wen_pre==1'b1 && wtlp_cnt >= wdma_tlp_size -'d64 )
                        wtlp_cnt <= #U_DLY 'b0;
                    else if(wdb_wen_pre==1'b1)
                        wtlp_cnt <= #U_DLY wtlp_cnt + 512/8;
                    else if(wchn_rd_end==1'b1)
                    	  wtlp_cnt <= #U_DLY 'b0;
                end
                
            if(wchn_rd_end==1'b1 && wtlp_cnt >= wdma_tlp_size -'d64) 
            	  wdb_wen_pre <= #U_DLY 1'b0;
            else if(wdb_wen_pre==1'b1 &&  wchn_dout[(528+WCHN_NUM_W)*wphy_cnt+512]==1'b1 && wtlp_cnt >= wdma_tlp_size -'d64)
                  wdb_wen_pre <= #U_DLY 1'b0;  
            else if((wtlp_cnt >= wdma_tlp_size -'d64) && (wchn_dma_pcnt[wchn_cnt*24+:24]=='d1 || burst_len>=BURST_LEN-wdma_tlp_size))	  
            	  wdb_wen_pre <= #U_DLY 1'b0;
            //else if(wdb_wen_pre==1'b1 &&  wchn_dout[(528+WCHN_NUM_W)*j+512]==1'b1 && wtlp_cnt < wdma_tlp_size -'d64)
            //	  wdb_wen_pre <= #U_DLY 1'b1;  
            else if(wchn_cur_st == WCHN_READ && wchn_rd_end==1'b0 && wchn_dma_len_done[wchn_cnt]==1'b0 && burst_done==1'b0)
                wdb_wen_pre <= #U_DLY 1'b1;           
            //else
            //    wdb_wen_pre <= #U_DLY 1'b0;

            wdb_wen <= #U_DLY wdb_wen_pre;


            //if(wchn_cur_st == WCHN_READ && wdb_wen_pre==1'b1 && wtlp_cnt >= wdma_tlp_size -'d64)
            if(wdb_wen_pre==1'b1 && wtlp_cnt >= wdma_tlp_size -'d64)
                wib_wen <= #U_DLY 1'b1;
            else
                wib_wen <= #U_DLY 1'b0;
            
                
            if(wchn_cur_st == WCHN_ABT)
                burst_len <= #U_DLY 'b0;
            else if(wchn_cur_st == WCHN_READ && wdb_wen_pre==1'b1 && wtlp_cnt >= wdma_tlp_size -'d64 )
                burst_len <= #U_DLY burst_len + wdma_tlp_size;
            	
            if((burst_len>=BURST_LEN-wdma_tlp_size) && (wdb_wen_pre==1'b1) && (wtlp_cnt >= wdma_tlp_size -'d64))
                burst_done <= #U_DLY 1'b1;
            else 
                burst_done <= #U_DLY 1'b0;     
            
            if(wchn_cur_st == WCHN_WAIT && wchn_nex_st == WCHN_ABT)
                wchn_rd_end <= #U_DLY 1'b0;  
            else if(wchn_ren[wphy_cnt]==1'b1 && wchn_dout[(528+WCHN_NUM_W)*wphy_cnt+512]==1'b1)
                wchn_rd_end <= #U_DLY 1'b1;      
                
            if(wchn_cur_st == WCHN_WAIT && wchn_nex_st == WCHN_ABT)
                wchn_rd_end_pro <= #U_DLY 1'b0;  
            else if(wchn_rd_end==1'b1 && wdb_wen==1'b1)
                wchn_rd_end_pro <= #U_DLY 1'b1;       

          

            if(wchn_cur_st == WCHN_ABT)
                wtlp_byte_cnt <= #U_DLY 'b0;
            else if(wchn_cur_st == WCHN_READ)
                begin
                    if(wchn_ren[wphy_cnt]==1'b1 && wtlp_byte_cnt >= wdma_tlp_size -'d64  )
                        wtlp_byte_cnt <= #U_DLY 'b0;
                    else if(wchn_ren[wphy_cnt]==1'b1)
                        wtlp_byte_cnt <= #U_DLY wtlp_byte_cnt + 512/8;
                end
            
            if(wchn_ren[wphy_cnt]==1'b1)    
                wtlp_real_cnt <= #U_DLY  wtlp_byte_cnt  + 512/8;
            
            if(wchn_cur_st == WCHN_ABT && wchn_nex_st == WCHN_READ && wchn_index > WCHN_NUM)    
                wchnindex_err <= #U_DLY 1'b1;
            else
            	  wchnindex_err <= #U_DLY 1'b0;     
        end
end

//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)
//        wib_din <= 'b0;
//    else 
//    	  wib_din <=  {{21-WCHN_NUM_W{1'b0}},wchn_cnt,wchn_rd_end,wtlp_byte_cnt,wchn_dma_paddr[32*wchn_cnt+:32]};
//end

//assign wib_din = {wchn_dma_prev[64*wchn_cnt+:64],{21-WCHN_NUM_W{1'b0}},wchn_cnt,wchn_rd_end,wtlp_real_cnt,wchn_dma_paddr[32*wchn_cnt+:32]};
assign wib_din = { {(60-WCHN_NUM_W){1'b0}},
                    wchn_cnt,
                    wchn_dma_daddr_h[32*wchn_cnt+:32],
                    wchn_rd_end,
                    wchn_done,
                    wtlp_real_cnt,
                    wchn_dma_daddr[32*wchn_cnt+:32],
                    wchn_dma_plen[24*wchn_cnt+:24],    
                    wchn_dma_prev[64*wchn_cnt+:64],    
                    wchn_dma_paddr[32*wchn_cnt+:32]};  

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        wdb_din <= 'b0;
    else 
    	wdb_din <= wchn_dout[(528+WCHN_NUM_W)*wphy_cnt+:512];
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            wchn_len_done <= #U_DLY 'b0;
            wchn_len_chn <= #U_DLY 'b0;
        end
    else
        begin 
            if(wchn_len_done==1'b1)
                wchn_len_done <= #U_DLY 1'b0;
            else if( ((wtlp_cnt >= wdma_tlp_size -'d64) && (wchn_dma_pcnt[wchn_cnt*24+:24]=='d1) && (wchn_rd_end==1'b0))
                  || ((wchn_ren[wphy_cnt]==1'b1) && (wchn_dout[(528+WCHN_NUM_W)*wphy_cnt+512]==1'b1)) )
    	        wchn_len_done <= #U_DLY 1'b1;

            if( ((wtlp_cnt >= wdma_tlp_size -'d64) && (wchn_dma_pcnt[wchn_cnt*24+:24]=='d1) && (wchn_rd_end==1'b0))
             || ((wchn_ren[wphy_cnt]==1'b1) && (wchn_dout[(528+WCHN_NUM_W)*wphy_cnt+512]==1'b1)) )
               wchn_len_chn <= #U_DLY wchn_cnt;
        end
end




always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        wdb_overflow <= 'b0;
    else if(wdb_wen==1'b1 && wdb_full==1'b1)
        wdb_overflow <= 1'b1;
    else
        wdb_overflow <= 1'b0;  
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        wib_overflow <= 'b0;
    else if(wib_wen==1'b1 && wib_full==1'b1)
        wib_overflow <= 1'b1;
    else
    	wib_overflow <= 1'b0;  
end

//
//assign wchn_index = wchn_dout[513+:WCHN_NUM_W];
assign wchn_index = wchn_dout[((528+WCHN_NUM_W)*wphy_cnt+528)+:WCHN_NUM_W];

//testoutput
assign t_wchn_cur_st = wchn_cur_st;

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
    	  wchn_curr_index <= 'b0;
    else
    	  wchn_curr_index <= wchn_index;  
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



/*
reg [7:0]  test_data_r1;
reg [7:0]  test_data_r2;
//(* syn_keep = "true", mark_debug = "true" *)
reg        test_err;
reg [1:0]  cnt;

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
    	  test_data_r1 <= #U_DLY 'b0;  
    else if(wdb_wen==1'b1)
    	  test_data_r1 <= #U_DLY wdb_din[7:0];  	  
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
    	  test_data_r2 <= #U_DLY 'b0;  
    else if(wdb_wen==1'b1)
    	  test_data_r2 <= #U_DLY test_data_r1;  	  
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
    	  cnt <= #U_DLY 'b0;  
     else if(cnt>='d2)
     	  cnt <= #U_DLY cnt;
    else if(wdb_wen==1'b1)
    	  cnt <= #U_DLY cnt + 'd1;  	  
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
    	  test_err <= #U_DLY 'b0;  
    else if(cnt>='d2)
    	  begin
    	  	  if(test_data_r1==8'h00 && test_data_r2==8'hff)
    	  	  	  test_err <= #U_DLY 1'b0;
    	  	  else if(test_data_r1==test_data_r2+'b1)
    	          test_err <= #U_DLY 1'b0;   	     
    	      else
    	      	  test_err <= #U_DLY 1'b1;
    	  end  	  
end
*/




















endmodule
