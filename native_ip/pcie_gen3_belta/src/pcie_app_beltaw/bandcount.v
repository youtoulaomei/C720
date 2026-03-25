// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2017/10/18 11:21:22
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
module bandcount # (
parameter                           U_DLY  = 1,
parameter                           DATAW  = 512
)
(
input                               clk,
input                               rst_n,
input                               rtc_s_flg,
input                               valid,
output reg [31:0]                   band

);
// Parameter Define 
localparam                          MBYTE = DATAW/8;
// Register Define 
reg     [31:0]                      cnt;
reg     [1:0]                       s_flg_r;
//reg                                 us_flg;
//reg                                 ms_flg;
//reg                                 s_flg;
//reg     [7:0]                       us_cnt;
//reg     [9:0]                       ms_cnt;
//reg     [9:0]                       s_cnt;
reg     [9:0]                       kbcnt;

// Wire Define 


 
//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)     
//        us_cnt <= #U_DLY 'b0;        
//    else if(us_flg==1'b1)
//        us_cnt <= #U_DLY 'b0;
//    else
//        us_cnt <= #U_DLY us_cnt + 'b1;     
//end
//
//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)     
//        us_flg <= #U_DLY 1'b0;        
//    else if(us_cnt==US_CNT-1)
//        us_flg <= #U_DLY 1'b1;
//    else
//        us_flg <= #U_DLY 1'b0;
//end
//
//
//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)     
//        ms_cnt <= #U_DLY 'b0;       
//    else if(us_flg==1'b1 && ms_cnt=='d999)
//        ms_cnt <= #U_DLY 'b0;
//    else if(us_flg==1'b1)
//        ms_cnt <= #U_DLY ms_cnt + 'b1;
//end
//
//
//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)     
//        ms_flg <= #U_DLY 1'b0;        
//    else if(us_flg==1'b1 && ms_cnt=='d999)
//        ms_flg <= #U_DLY 1'b1;
//    else
//        ms_flg <= #U_DLY 1'b0;   
//end
//
//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)     
//        s_cnt <= #U_DLY 'b0;       
//    else if(ms_flg==1'b1 && s_cnt=='d999)
//        s_cnt <= #U_DLY 'b0;
//    else if(ms_flg==1'b1)
//        s_cnt <= #U_DLY s_cnt + 'b1;
//end
//
//always @ (posedge clk or negedge rst_n)begin
//    if(rst_n == 1'b0)     
//        s_flg <= #U_DLY 1'b0;        
//    else if(ms_flg==1'b1 && s_cnt=='d999)
//        s_flg <= #U_DLY 1'b1;
//    else
//        s_flg <= #U_DLY 1'b0;   
//end



always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        s_flg_r <= #U_DLY 2'b0;        
    else    
        s_flg_r <= #U_DLY {s_flg_r[0],rtc_s_flg};
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        band <= #U_DLY 'b0;        
    else if(s_flg_r[0] ^ s_flg_r[1])
        band <= #U_DLY cnt;   
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        kbcnt <= #U_DLY 'b0;
    else if(valid==1'b1 && kbcnt=='d1024-MBYTE)
        kbcnt <= #U_DLY 'b0;
    else if(valid==1'b1)
        kbcnt <= #U_DLY kbcnt + MBYTE;   
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        cnt <= #U_DLY 'b0;        
    else if(s_flg_r[0]^s_flg_r[1])
        cnt <= #U_DLY 'b0;
    else if(valid==1'b1 && kbcnt=='d1024-MBYTE)
        cnt <= #U_DLY cnt + 'd1;   
end


endmodule

