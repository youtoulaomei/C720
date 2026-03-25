// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2015/9/9 14:20:31
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
module datas_gen_inc8 # (
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst_n,
input                               clr,
input                               send_vld,
output reg [7:0]                    data
);
// Parameter Define 

// Register Define 

// Wire Define 
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      data <= #U_DLY 8'b0;
    else if( clr == 1'b1 )
      data <= #U_DLY 8'b0;   
    else if( send_vld == 1'b1 )
      data <= #U_DLY data + 8'b1;
end

endmodule
