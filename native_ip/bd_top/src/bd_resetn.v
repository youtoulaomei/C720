// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/12/18 9:47:13
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
module bd_resetn # (
parameter                           U_DLY  = 1,
parameter                           US_CNT = 50
)
(
input                               clk,
input                               rst,
input                               bd_soft_rst,
output reg                          bd_rstn,
output reg                          bd_pwd

);
// Parameter Define 
localparam                          IDLE     = 2'd0;
localparam                          WAIT_50MS = 2'd1;
localparam                          RST_1MS  = 2'd2;
localparam                          RST_DONE = 2'd3;

// Register Define 
reg     [7:0]                       us_cnt;
reg     [9:0]                       ms_cnt;
reg                                 us_flg;
reg                                 ms_flg;
reg     [1:0]                       rst_state;
reg     [1:0]                       rst_nextstate;
reg     [5:0]                       cnt_50ms;
reg                                 wait_done;
reg                                 cnt_2ms;
reg                                 rst_done;
reg     [1:0]                       bd_soft_rst_r;
reg                                 bd_soft_rst_det;

// Wire Define 
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        rst_state <= #U_DLY IDLE;        
    else    
        rst_state <= #U_DLY rst_nextstate;
end

always @ (*)begin
    case(rst_state)
        IDLE:
        begin
            rst_nextstate=WAIT_50MS;
        end

        WAIT_50MS:
        begin
            if(wait_done==1'b1)
                rst_nextstate=RST_1MS;
            else
                rst_nextstate=WAIT_50MS;
        end

        RST_1MS:
        begin
            if(rst_done==1'b1)
                rst_nextstate=RST_DONE;
            else
                rst_nextstate=RST_1MS;
        end

        RST_DONE:
        begin
            if(bd_soft_rst_det==1'b1)
                rst_nextstate=RST_1MS;
            else
                rst_nextstate=RST_DONE;
        end
        
        default:rst_nextstate=RST_DONE;
    endcase
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        us_cnt <= #U_DLY 'b0;        
    else if(us_flg==1'b1)
        us_cnt <= #U_DLY 'b0;
    else
        us_cnt <= #U_DLY us_cnt + 'b1;     
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)          
        us_flg <= #U_DLY 1'b0;        
    else if(us_cnt==US_CNT-1)
        us_flg <= #U_DLY 1'b1;
    else
        us_flg <= #U_DLY 1'b0;
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)      
        ms_cnt <= #U_DLY 'b0;       
    else if(us_flg==1'b1 && ms_cnt=='d999)
        ms_cnt <= #U_DLY 'b0;
    else if(us_flg==1'b1)
        ms_cnt <= #U_DLY ms_cnt + 'b1;
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)      
        ms_flg <= #U_DLY 1'b0;        
    else if(us_flg==1'b1 && ms_cnt=='d999)
        ms_flg <= #U_DLY 1'b1;
    else
        ms_flg <= #U_DLY 1'b0;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        cnt_50ms <= #U_DLY 'b0;        
    else if(wait_done==1'b1)
        cnt_50ms <= #U_DLY 'b0;
    else if(rst_state==WAIT_50MS && ms_flg==1'b1)
        cnt_50ms <= #U_DLY cnt_50ms + 'b1;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        wait_done <= #U_DLY 1'b0;        
    else if(cnt_50ms=='d50 && ms_flg==1'b1)
        wait_done <= #U_DLY 1'b1;
    else
        wait_done <= #U_DLY 1'b0;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        cnt_2ms <= #U_DLY 'b0;       
    else if(rst_done==1'b1)
        cnt_2ms <= #U_DLY 'b0;
    else if(rst_state==RST_1MS && ms_flg==1'b1)
        cnt_2ms <= #U_DLY cnt_2ms + 'b1;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        rst_done <= #U_DLY 1'b0;        
    else if(cnt_2ms=='d1 && ms_flg==1'b1)
        rst_done <= #U_DLY 1'b1;
    else
        rst_done <= #U_DLY 1'b0;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        bd_rstn <= #U_DLY 1'b1;    
    else if(rst_state==RST_1MS)
        bd_rstn <= #U_DLY 1'b0;
    else
        bd_rstn <= #U_DLY 1'b1;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        bd_soft_rst_r <= #U_DLY 'b0;        
    else    
        bd_soft_rst_r <= #U_DLY {bd_soft_rst_r[0],bd_soft_rst};
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        bd_soft_rst_det <= #U_DLY 1'b0;       
    else if(bd_soft_rst_r[0]==1'b1 && bd_soft_rst_r[1]==1'b0)
        bd_soft_rst_det <= #U_DLY 1'b1;
    else
        bd_soft_rst_det <= #U_DLY 1'b0;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        bd_pwd <= #U_DLY 1'b0;        
    else
        bd_pwd <= #U_DLY 1'b1;   
end



endmodule
