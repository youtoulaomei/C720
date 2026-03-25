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
module pcie_witem_glb # (
parameter                           U_DLY         = 1,
parameter                           WCHN_NUM      = 60,
parameter                           WCHN_NUM_W    = clog2b(WCHN_NUM)
)
(   
input                               clk,
input                               rst,
input                               witem_rst,
input                               rtc_us_flg,
//
input                               witem_wr_det,
input           [31:0]              witem_wdata0,
input           [31:0]              witem_wdata1,
input           [31:0]              witem_wdata2,
input           [31:0]              witem_wdata3,
input           [31:0]              witem_wdata4,

input           [WCHN_NUM-1:0]      witem_arb_req,
output  reg     [WCHN_NUM-1:0]      arb_witem_ack,
output  reg     [WCHN_NUM-1:0]      arb_witem_vld,
output  reg     [159:0]             arb_witem_data,


input                               wchn_dma_done,
input                               wchn_dma_end,
input           [31:0]              wchn_dma_daddr,
input           [31:0]              wchn_dma_daddr_h,
input           [23:0]              wchn_dma_count,
input           [WCHN_NUM_W-1:0]    wchn_dma_chn,
input           [63:0]              wchn_dma_drev,

input                               owitem_rd_det,
output  reg     [31:0]              owitem_rdata0,
output  reg     [31:0]              owitem_rdata1,
output  reg     [31:0]              owitem_rdata2,
output  reg     [31:0]              owitem_rdata3,
output  reg     [31:0]              owitem_rdata4,


output                              witem_fifo_full,
output                              witem_fifo_empty,
output                              witem_fifo_prog_empty,
output  reg                         witem_fifo_overflow,
output                              owitem_fifo_full,
output                              owitem_fifo_empty,
output                              owitem_fifo_prog_empty,
output  reg                         owitem_fifo_overflow,
output  reg                         owitem_fifo_underflow,
output  reg     [19:0]              wt_time,
output          [7:0]               witem_fifo_rcnt,
output          [7:0]               witem_fifo_wcnt,
output          [7:0]               owitem_fifo_rcnt,
output          [7:0]               owitem_fifo_wcnt

);


// Parameter Define 


// Register Define 
reg     [1:0]                       arb_state;
reg     [1:0]                       arb_nextstate;
reg                                 arb_req;
reg     [WCHN_NUM_W-1:0]            cur_num;
reg     [WCHN_NUM_W-1:0]            arb_num;
reg                                 arb_selected;
reg                                 frm_state;
reg                                 frm_nextstate;
reg                                 sel_ack;
reg                                 witem_fifo_rd_en;
reg     [WCHN_NUM_W-1:0]            frm_num;
reg     [159:0]                     owitem_fifo_din;
reg                                 owitem_fifo_wr;
reg     [2:0]                       rtc_us_flg_r;
reg     [19:0]                      t_time;


// Wire Define 
wire                                witem_fifo_wr_en;
wire    [159:0]                     witem_fifo_din;
wire    [159:0]                     witem_fifo_dout;
wire    [WCHN_NUM_W-1:0]            cur_num_x;
wire    [WCHN_NUM_W-1:0]            arb_num_x;
wire                                arb_selected_x;

wire    [159:0]                     owitem_fifo_dout;
wire                                owitem_fifo_rd_en;
wire                                owitem_fifo_wr_en;

//-----------------------------------------------------------------------------
//witem fifo
//-----------------------------------------------------------------------------  
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (160                        ),
    .DATA_DEEPTH                (256                        ),
    .ADDR_WIDTH                 (8                          )
)u_witem_fifo
(
    .wr_clk                     (clk                        ),
    .wr_rst_n                   (~(rst | witem_rst)         ),
    .rd_clk                     (clk                        ),
    .rd_rst_n                   (~(rst | witem_rst)         ),
    .din                        (witem_fifo_din             ),
    .wr_en                      (witem_fifo_wr_en           ),
    .rd_en                      (witem_fifo_rd_en           ),
    .dout                       (witem_fifo_dout            ),
    .full                       (witem_fifo_full            ),
    .prog_full                  (                           ),
    .empty                      (witem_fifo_empty           ),
    .prog_empty                 (witem_fifo_prog_empty      ),
    .prog_full_thresh           (8'd240                     ),
    .prog_empty_thresh          (8'd60                      ),
    .rd_data_count              (witem_fifo_rcnt            ),
    .wr_data_count              (witem_fifo_wcnt            )
);

assign witem_fifo_din = {witem_wdata4,witem_wdata3,witem_wdata2,witem_wdata1,witem_wdata0};
assign witem_fifo_wr_en= (witem_wr_det==1'b1)&&(witem_fifo_full==1'b0) ? 1'b1:1'b0;

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        witem_fifo_overflow <= #U_DLY 1'b0;        
    else if(witem_wr_det==1'b1 && witem_fifo_full==1'b1)
        witem_fifo_overflow <= #U_DLY 1'b1;
    else
        witem_fifo_overflow <= #U_DLY 1'b0;    
end

//-----------------------------------------------------------------------------
//arb_state
//-----------------------------------------------------------------------------   
localparam                           IDLE = 2'd0;
localparam                           ARB  = 2'd1;
localparam                           WAIT = 2'd2;

always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)     
        arb_state <= #U_DLY IDLE;
    else if(witem_rst==1'b1)
        arb_state <= #U_DLY IDLE;    
    else    
        arb_state <= #U_DLY arb_nextstate;
end


always @ ( * )
begin
    case(arb_state)
        IDLE:
            begin
                if(arb_req == 1'b1 && witem_fifo_empty==1'b0)
                    arb_nextstate = ARB;
                else
                    arb_nextstate = IDLE;
            end
        ARB:
            begin
                if(arb_selected == 1'b1)
                    begin
                        if(sel_ack == 1'b1)
                            arb_nextstate = WAIT;
                        else
                            arb_nextstate = ARB;
                    end
                else
                    arb_nextstate = ARB;
            end
            
        WAIT:
            begin
                 arb_nextstate = IDLE;
            end  
        default:arb_nextstate = IDLE;     
     endcase
end       


assign cur_num_x =((arb_state==ARB) && (arb_selected == 1'b0) && (cur_num==(WCHN_NUM-1))) ? {(WCHN_NUM_W){1'b0}} :
                  ((arb_state==WAIT)&& (cur_num==(WCHN_NUM-1))) ?  {(WCHN_NUM_W){1'b0}} :
                  ((arb_state==ARB) && (arb_selected == 1'b0))  ?  cur_num +  {{(WCHN_NUM_W-1){1'b0}},1'b1} :
                  (arb_state==WAIT) ?  cur_num +  {{(WCHN_NUM_W-1){1'b0}},1'b1} : cur_num ;

assign arb_selected_x = (sel_ack == 1'b1) ? 1'b0 :
                      ((arb_nextstate == ARB)&&(witem_arb_req[cur_num_x] == 1'b1)) ? 1'b1 : arb_selected;

assign arb_num_x = (arb_nextstate == ARB)&&(witem_arb_req[cur_num_x] == 1'b1) ? cur_num_x : arb_num;     


always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)     
        arb_req <= #U_DLY 1'b0;        
    else 
        arb_req <= #U_DLY |witem_arb_req;   
end

always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)      
        begin
            cur_num      <= #U_DLY {(WCHN_NUM_W){1'b0}};
            arb_num      <= #U_DLY {(WCHN_NUM_W){1'b0}}; 
            arb_selected <= #U_DLY 1'b0;
        end        
    else    
        begin
            cur_num      <= #U_DLY cur_num_x;
            arb_num      <= #U_DLY arb_num_x; 
            arb_selected <= #U_DLY arb_selected_x;
        end      
end

always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)      
        begin
            rtc_us_flg_r    <= #U_DLY 'b0;
            t_time <= #U_DLY 'b0; 
            wt_time <= 'b0;
        end        
    else    
        begin
            rtc_us_flg_r      <= #U_DLY {rtc_us_flg_r[1:0],rtc_us_flg};
            
            if((arb_req==1'b1) && (witem_fifo_empty==1'b0))
          	    t_time <= #U_DLY 'b0; 
            else if((arb_req==1'b1) && (witem_fifo_empty==1'b1) && (rtc_us_flg_r[1]^rtc_us_flg_r[2]==1'b1))
            	  t_time <= #U_DLY t_time + 'b1; 
            	  
            if((arb_req==1'b1) && (witem_fifo_empty==1'b0))
            	wt_time <= #U_DLY t_time; 
        end      
end

//-----------------------------------------------------------------------------
//frm_state
//-----------------------------------------------------------------------------   
localparam                           SEND_FRM  = 2'd1;

always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)        
        frm_state <= #U_DLY IDLE;      
    else if(witem_rst==1'b1)
        frm_state <= #U_DLY IDLE;   
    else    
        frm_state <= #U_DLY frm_nextstate;
end

always @ ( * )
begin
    case(frm_state)
        IDLE:
            begin
                if(arb_selected == 1'b1)
                    frm_nextstate = SEND_FRM;
                else
                    frm_nextstate = IDLE;
            end

        SEND_FRM:
            begin
                if(witem_fifo_rd_en == 1'b1)
                    frm_nextstate = IDLE;
                else
                    frm_nextstate = SEND_FRM;
            end
         
        default:
            frm_nextstate = IDLE;
    endcase
end



// logic
always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)        
        sel_ack <= #U_DLY 1'b0;        
    else if(frm_state==IDLE && frm_nextstate==SEND_FRM)
        sel_ack <= #U_DLY 1'b1;
    else
        sel_ack <= #U_DLY 1'b0;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            witem_fifo_rd_en <= #U_DLY 1'b0;
            arb_witem_data <= #U_DLY 'b0;
            frm_num <= #U_DLY 'b0;
        end        
    else    
        begin
            if(witem_fifo_rd_en==1'b1)
                witem_fifo_rd_en <= #U_DLY 1'b0;
            else if(frm_state==SEND_FRM && witem_fifo_empty==1'b0)
                witem_fifo_rd_en <= #U_DLY 1'b1;


            if(witem_fifo_rd_en==1'b1)
                arb_witem_data <= #U_DLY witem_fifo_dout;

            if(frm_state==IDLE && arb_selected==1'b1)
                frm_num <= #U_DLY arb_num;
                  
        end

end

always @ (posedge clk or posedge rst)
begin:ACKPRO
integer i;
    if(rst == 1'b1)            
        begin
            arb_witem_vld <= #U_DLY 'b0;
            arb_witem_ack <= #U_DLY 'b0;
        end
    else    
        begin    
        for(i=0;i<WCHN_NUM;i=i+1)
            begin
               if(witem_fifo_rd_en==1'b1 && frm_num==i)
                   arb_witem_vld[i] <= #U_DLY 1'b1;
               else
                   arb_witem_vld[i] <= #U_DLY 1'b0;
            
               if((frm_state==IDLE) && (arb_selected==1'b1) && (arb_num==i))
                   arb_witem_ack[i] <= #U_DLY 1'b1;
               else
                   arb_witem_ack[i] <= #U_DLY 1'b0;
                    
            end
        end
end


//-----------------------------------------------------------------------------
//owitem fifo
//-----------------------------------------------------------------------------  
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (160                        ),
    .DATA_DEEPTH                (256                        ),
    .ADDR_WIDTH                 (8                          )
)u_owitem_fifo
(
    .wr_clk                     (clk                        ),
    .wr_rst_n                   (~(rst | witem_rst)         ),
    .rd_clk                     (clk                        ),
    .rd_rst_n                   (~(rst | witem_rst)         ),
    .din                        (owitem_fifo_din            ),
    .wr_en                      (owitem_fifo_wr_en          ),
    .rd_en                      (owitem_fifo_rd_en          ),
    .dout                       (owitem_fifo_dout           ),
    .full                       (owitem_fifo_full           ),
    .prog_full                  (                           ),
    .empty                      (owitem_fifo_empty          ),
    .prog_empty                 (owitem_fifo_prog_empty     ),
    .prog_full_thresh           (8'd240                     ),
    .prog_empty_thresh          (8'd60                      ),
    .rd_data_count              (owitem_fifo_rcnt           ),    
    .wr_data_count              (owitem_fifo_wcnt           )    
);

assign owitem_fifo_rd_en = (owitem_rd_det==1'b1) && (owitem_fifo_empty==1'b0) ? 1'b1 : 1'b0;
assign owitem_fifo_wr_en = (owitem_fifo_wr==1'b1) && (owitem_fifo_full==1'b0) ? 1'b1: 1'b0;

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1) 
        begin
            owitem_fifo_wr <= #U_DLY 1'b0;
            owitem_fifo_din <= #U_DLY 'b0;
            owitem_rdata0 <= #U_DLY 'b0;
            owitem_rdata1 <= #U_DLY 'b0;
            owitem_rdata2 <= #U_DLY 'b0;
            owitem_rdata3 <= #U_DLY 'b0;
            owitem_rdata4 <= #U_DLY 'b0;
        end    
    else    
        begin
            if(wchn_dma_done==1'b1)
                owitem_fifo_wr <= #U_DLY 1'b1;
            else
                owitem_fifo_wr <= #U_DLY 1'b0;
            
            if(wchn_dma_done==1'b1)
                owitem_fifo_din <= #U_DLY {wchn_dma_daddr_h,
                                           wchn_dma_drev,
                                           {wchn_dma_end,{(7-WCHN_NUM_W){1'b0}},wchn_dma_chn,wchn_dma_count},
                                           wchn_dma_daddr};
            owitem_rdata0 <= #U_DLY owitem_fifo_dout[31:0];
            owitem_rdata1 <= #U_DLY owitem_fifo_dout[63:32];
            owitem_rdata2 <= #U_DLY owitem_fifo_dout[95:64];
            owitem_rdata3 <= #U_DLY owitem_fifo_dout[127:96];
            owitem_rdata4 <= #U_DLY owitem_fifo_dout[159:128];

        end

end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            owitem_fifo_overflow <= #U_DLY 1'b0; 
            owitem_fifo_underflow <= #U_DLY 1'b0;
        end       
    else    
        begin
            if(owitem_fifo_wr==1'b1 && owitem_fifo_full==1'b1)
                owitem_fifo_overflow <= #U_DLY 1'b1;
            else
                owitem_fifo_overflow <= #U_DLY 1'b0;
            
            if(owitem_rd_det==1'b1 && owitem_fifo_empty==1'b1)
                owitem_fifo_underflow <= #U_DLY 1'b1;
            else
                owitem_fifo_underflow <= #U_DLY 1'b0;
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





