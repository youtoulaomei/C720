// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2015/9/21 16:20:19
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
module datas_check_8bit # (
parameter                           U_DLY = 1
)
(
input                               clk       ,
input                               rst_n     ,
input                               pbc_start ,
input [7:0]                         data_8bit ,
input                               valid     ,
input                               keep      ,
output                              error     
);
// Parameter Define 

// Register Define 
reg [7:0]                           data_8bit_inc;

// Wire Define 

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      data_8bit_inc <= #U_DLY 8'b0;
    else if(pbc_start== 1'b1 )
      data_8bit_inc <= #U_DLY data_8bit + 8'b1;   
    else if( valid == 1'b1 )
      data_8bit_inc <= #U_DLY data_8bit_inc + 8'b1; 
end


assign error = (pbc_start == 1'b1) ? 1'b0 :
               ((keep == 1'b1)&& (valid ==1'b1) && (data_8bit != data_8bit_inc)) ? 1'b1 : 1'b0;


endmodule
