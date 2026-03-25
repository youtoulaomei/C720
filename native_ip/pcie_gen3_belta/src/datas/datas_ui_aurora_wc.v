// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2015/9/15 11:16:34
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Zhimingda digital equipment Co., Ltd.. 
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
module datas_ui_aurora_wc # (
parameter                           U_DLY    = 1,
parameter                           DATA_W   = 512,
parameter                           CHNL_NUM = 2'd0
)
(
input                               clk,
input                               rst_n,

input [DATA_W-1:0]                  tx_data,
input [DATA_W/8-1:0]                tx_keep,
input                               tx_last,
input                               tx_head,
input                               tx_tail,
input                               tx_data_vld,
output wire                         prog_full,

input                               full,
output reg [DATA_W-1:0]             ds_rx_data,
output reg [DATA_W/8-1:0]           ds_rx_keep,
output reg                          ds_rx_last,
output reg                          ds_rx_data_vld

);  

//assign prog_full = 1'b0;
assign prog_full = full;
always @ (posedge clk or negedge rst_n)                                         
begin                                                                           
    if(rst_n == 1'b0)                                                           
        ds_rx_data <= #U_DLY 'b0;                                               
    else                                                                        
        ds_rx_data <= #U_DLY tx_data;                                          
end     


always @ (posedge clk or negedge rst_n)                                         
begin                                                                           
    if(rst_n == 1'b0)                                                           
        ds_rx_keep <= #U_DLY 'b0;                                               
    else                                                                        
        ds_rx_keep <= #U_DLY tx_keep;                                          
end 


always @ (posedge clk or negedge rst_n)                                         
begin                                                                           
    if(rst_n == 1'b0)                                                           
        ds_rx_data_vld <= #U_DLY 'b0;                                               
    else                                                                        
        ds_rx_data_vld <= #U_DLY tx_data_vld;                                          
end 

always @ (posedge clk or negedge rst_n)                                         
begin                                                                           
    if(rst_n == 1'b0)                                                           
        ds_rx_last <= #U_DLY 'b0;                                               
    else                                                                        
        ds_rx_last <= #U_DLY tx_last;                                          
end 

endmodule
