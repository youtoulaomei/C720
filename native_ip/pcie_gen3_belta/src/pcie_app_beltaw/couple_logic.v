// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2017/10/18 9:31:49
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
module couple_logic # (
parameter                           WCHN_NUM_W  =5,
parameter                           WDATA_WIDTH =1024,
parameter                           BUILTIN_NUM =0,
parameter                           BURST_LEN   =2048,
parameter                           U_DLY = 1
)
(
input                               wr_clk,
input                               wr_rst_n,
input                               rd_clk,
input                               rd_rst_n,
input                               built_in,
input                               ds_rx_data_vld,
input  [511:0]                      ds_rx_data,

output reg                          wchn_data_rdy, 
input                               wchn_data_vld, 
input                               wchn_sof,      
input                               wchn_eof,      
input  [WDATA_WIDTH-1:0]            wchn_data,   
input                               wchn_end,
input  [WDATA_WIDTH/8-1:0]          wchn_keep,     
input  [15-1:0]                     wchn_length,   
input  [WCHN_NUM_W-1:0]             wchn_chn,

output reg                          wchn_eflg,
input                               wchn_eflg_clr,
input                               wchn_ren,
output                              wchn_dvld,
output [512+15+WCHN_NUM_W:0]        wchn_dout,
output reg                          cfifo_overflow,
output                              cfifo_empty

);
// Parameter Define 
localparam [7:0] PROG_EMPTY_THRESH = BURST_LEN/64;

// Register Define 
reg     [2:0]                       built_in_r;
reg                                 wvld;
reg     [511:0]                     wdata;
reg     [1:0]                       cfifo_overflow_r;
reg                                 wend;
reg     [WCHN_NUM_W-1:0]            wchn;
reg     [2:0]                       wchn_eflg_clr_r;
reg     [15-1:0]                    wchn_len;

// Wire Define
wire                                txdma_fifo_prog_empty;
wire                                txdma_fifo_prog_full;
wire    [528+WCHN_NUM_W-1:0]        txdma_fifo_rd_data;
wire                                txdma_fifo_rd;
wire    [528+WCHN_NUM_W-1:0]        txdma_fifo_wr_data;
wire                                txdma_fifo_wr;
wire                                txdma_fifo_full;



always @ (posedge wr_clk or negedge wr_rst_n)begin
    if(wr_rst_n == 1'b0)  
    	  begin   
            cfifo_overflow   <= #U_DLY 1'b0;
            cfifo_overflow_r <= #U_DLY 'b0;
        end
    else
    	  begin
    	  	  cfifo_overflow_r <= #U_DLY {cfifo_overflow_r[0],cfifo_overflow};
    	  	   
            if(cfifo_overflow_r[1]==1'b1)
            	cfifo_overflow <= #U_DLY 1'b0;        
            else if(wvld==1'b1 && txdma_fifo_full==1'b1)   
                cfifo_overflow <= #U_DLY 1'b1;      
        end
end

always @ (posedge wr_clk or negedge wr_rst_n)begin
    if(wr_rst_n == 1'b0)     
        built_in_r <= #U_DLY 'b0;        
    else    
        built_in_r <= #U_DLY {built_in_r[1:0],built_in};
end

generate
if(WDATA_WIDTH==1024)
    begin
        wire wflg0;
        reg  wflg1;
        wire weflg0;
        reg  weflg1;
        reg [511:0] wchn_data_hr;
    
        always @ (posedge wr_clk or negedge wr_rst_n)begin
           if(wr_rst_n == 1'b0)         
               wchn_data_rdy <= #U_DLY 1'b1;
           else if(txdma_fifo_prog_full==1'b1)
               wchn_data_rdy <= #U_DLY 1'b0;
           else if(wchn_data_vld==1'b1 && wchn_data_rdy==1'b1)
               wchn_data_rdy <= #U_DLY 1'b0;
           else
               wchn_data_rdy <= #U_DLY 1'b1;
        end
        
        assign wflg0=(wchn_data_vld==1'b1 && wchn_data_rdy==1'b1) ? 1'b1: 1'b0;

        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)     
                begin
                    wvld <= #U_DLY 1'b0;
                    wflg1 <= #U_DLY 1'b0;
                    wchn_data_hr <= #U_DLY 'b0;
                end        
            else if(built_in_r[2]==1'b1)   
            	begin
            	    if(ds_rx_data_vld==1'b1)
            		    wvld <= #U_DLY 1'b1;
            		else
            		    wvld <= #U_DLY 1'b0;
            	end  
            else
            	begin
                    wflg1 <= #U_DLY wflg0;

                    if(wflg0==1'b1 || wflg1==1'b1)
                        wvld <= #U_DLY 1'b1;
                    else
                        wvld <= #U_DLY 1'b0;
                    
                    if(wflg0==1'b1)    
                    wchn_data_hr <=  wchn_data[1023:512];
                    
            	end
        end
        
        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)     
                wdata <= #U_DLY 'b0;        
            else if(built_in_r[2]==1'b1)   
                wdata <= #U_DLY ds_rx_data;
            else 
                begin
                    if(wflg0==1'b1)
            	        wdata <= #U_DLY wchn_data[511:0];
                    else
                        wdata <= #U_DLY wchn_data_hr;
                end
        end
        
        assign weflg0=(wchn_data_vld==1'b1 && wchn_data_rdy==1'b1 && wchn_end==1'b1 && wchn_eof==1'b1) ? 1'b1: 1'b0;   

        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)       
                begin 
                    wend <= #U_DLY 1'b0; 
                    weflg1 <= #U_DLY 1'b0;
                end      
            else if(built_in_r[2]==1'b1) 
                wend <= #U_DLY 1'b0;
            else
                begin
                    weflg1 <= #U_DLY weflg0;

                    if(weflg1==1'b1)
                        wend <= #U_DLY 1'b1;
                    else
                        wend <= #U_DLY 1'b0;

                end  
        end
        
        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)        
                wchn <= #U_DLY 'b0;       
            else if(built_in_r[2]==1'b1) 
                wchn <= #U_DLY BUILTIN_NUM;
            else
                if(wchn_data_vld==1'b1 && wchn_data_rdy==1'b1 && wchn_sof==1'b1)
                    wchn <= #U_DLY wchn_chn;  
        end

        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)        
                wchn_len <= #U_DLY 'b0;       
            else if(built_in_r[2]==1'b1) 
                wchn_len <= #U_DLY BURST_LEN;
            else
                if(wchn_data_vld==1'b1 && wchn_data_rdy==1'b1 && wchn_sof==1'b1)
                    wchn_len <= #U_DLY wchn_length;  
        end

    end
else
    begin
        always @ (posedge wr_clk or negedge wr_rst_n)begin
           if(wr_rst_n == 1'b0)         
               wchn_data_rdy <= #U_DLY 1'b1;
           else if(txdma_fifo_prog_full==1'b1)
               wchn_data_rdy <= #U_DLY 1'b0;
           else
               wchn_data_rdy <= #U_DLY 1'b1;
        end
        
        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)     
                begin
                    wvld <= #U_DLY 1'b0;
                end        
            else if(built_in_r[2]==1'b1)   
            	begin
            	    if(ds_rx_data_vld==1'b1)
            		    wvld <= #U_DLY 1'b1;
            		else
            		    wvld <= #U_DLY 1'b0;
            	end  
            else
            	begin
                    if(wchn_data_vld==1'b1 && wchn_data_rdy==1'b1)
                        wvld <= #U_DLY 1'b1;
                    else
                        wvld <= #U_DLY 1'b0;
            	end
        end
        
        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)     
                wdata <= #U_DLY 'b0;        
            else if(built_in_r[2]==1'b1)   
                wdata <= #U_DLY ds_rx_data;
            else 
                begin
            	    wdata <= #U_DLY wchn_data[511:0];
                end
        end
        
    
        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)       
                begin 
                    wend <= #U_DLY 1'b0; 
                end      
            else if(built_in_r[2]==1'b1) 
                wend <= #U_DLY 1'b0;
            else
                begin
                    if(wchn_data_vld==1'b1 && wchn_data_rdy==1'b1 && wchn_end==1'b1 && wchn_eof==1'b1)
                        wend <= #U_DLY 1'b1;
                    else
                        wend <= #U_DLY 1'b0;
                end  
        end
        
        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)        
                wchn <= #U_DLY 'b0;       
            else if(built_in_r[2]==1'b1) 
                wchn <= #U_DLY BUILTIN_NUM;
            else
                if(wchn_data_vld==1'b1 && wchn_data_rdy==1'b1 && wchn_sof==1'b1)
                    wchn <= #U_DLY wchn_chn;  
        end

        always @ (posedge wr_clk or negedge wr_rst_n)begin
            if(wr_rst_n == 1'b0)        
                wchn_len <= #U_DLY 'b0;       
            else if(built_in_r[2]==1'b1) 
                wchn_len <= #U_DLY BURST_LEN;
            else
                if(wchn_data_vld==1'b1 && wchn_data_rdy==1'b1 && wchn_sof==1'b1)
                    wchn_len <= #U_DLY wchn_length;  
        end

    end

endgenerate


assign txdma_fifo_wr      =  wvld;
assign txdma_fifo_wr_data =  {wchn,wchn_len,wend,wdata};



always @ (posedge wr_clk or negedge wr_rst_n)begin
    if(wr_rst_n == 1'b0)         
        wchn_eflg <= #U_DLY 1'b0;
    //else if(wchn_eflg_clr_r[1]==1'b1 && wchn_eflg_clr_r[2]==1'b0)
    else if(wchn_eflg_clr_r[2]==1'b1)
        wchn_eflg <= #U_DLY 1'b0;    
    else if(wvld==1'b1 && wend==1'b1)
        wchn_eflg <= #U_DLY 1'b1;   
end

always @ (posedge wr_clk or negedge wr_rst_n)begin
    if(wr_rst_n == 1'b0)    
        wchn_eflg_clr_r <= #U_DLY 'b0;        
    else    
        wchn_eflg_clr_r <= #U_DLY {wchn_eflg_clr_r[1:0],wchn_eflg_clr};
end


asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (528+WCHN_NUM_W             ),
    .DATA_DEEPTH                (256                        ),
    .ADDR_WIDTH                 (8                          )
)u_txdma_fifo
(
    .wr_clk                     (wr_clk                     ),
    .wr_rst_n                   (wr_rst_n                   ),
    .rd_clk                     (rd_clk                     ),
    .rd_rst_n                   (rd_rst_n                   ),
    .din                        (txdma_fifo_wr_data         ),
    .wr_en                      (txdma_fifo_wr              ),
    .rd_en                      (txdma_fifo_rd              ),
    .dout                       (txdma_fifo_rd_data         ),
    .full                       (txdma_fifo_full            ),
    .prog_full                  (txdma_fifo_prog_full       ),
    .empty                      (cfifo_empty                ),
    .prog_empty                 (txdma_fifo_prog_empty      ),
    .prog_full_thresh           (8'd240                     ),
    .prog_empty_thresh          (PROG_EMPTY_THRESH          ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )
);


assign wchn_dout = txdma_fifo_rd_data;

assign txdma_fifo_rd = (wchn_ren==1'b1)  ? 1'b1 : 1'b0;

assign wchn_dvld = ~txdma_fifo_prog_empty;
//

reg [7:0]  test_data_r1;
reg [7:0]  test_data_r2;
//(* syn_keep = "true", mark_debug = "true" *)
reg        test_err;
reg [1:0]  cnt;

always @ (posedge wr_clk or negedge wr_rst_n)begin
    if(wr_rst_n == 1'b0)       
    	  test_data_r1 <= #U_DLY 'b0;  
    else if(txdma_fifo_wr==1'b1)
    	  test_data_r1 <= #U_DLY txdma_fifo_wr_data[7:0];  	  
end

always @ (posedge wr_clk or negedge wr_rst_n)begin
    if(wr_rst_n == 1'b0)        
    	  test_data_r2 <= #U_DLY 'b0;  
    else if(txdma_fifo_wr==1'b1)
    	  test_data_r2 <= #U_DLY test_data_r1;  	  
end

always @ (posedge wr_clk or negedge wr_rst_n)begin
    if(wr_rst_n == 1'b0)         
    	  cnt <= #U_DLY 'b0;  
     else if(cnt>='d2)
     	  cnt <= #U_DLY cnt;
    else if(txdma_fifo_wr==1'b1)
    	  cnt <= #U_DLY cnt + 'd1;  	  
end

always @ (posedge wr_clk or negedge wr_rst_n)begin
    if(wr_rst_n == 1'b0)         
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






endmodule
