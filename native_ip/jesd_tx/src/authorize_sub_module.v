// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/5/22 15:15:53
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2017,BoYuLiHua Technology Co., Ltd.. 
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
module authorize_sub_module #(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst,

input           [31:0]              key,
//
input           [31:0]              authorize_code,
//
output  reg                         authorize_succ
);
// Parameter Define 

// Register Define 
reg     [31:0]                      authorize_code_pre;
reg     [31:0]                      authorize_code_dly;

// Wire Define 

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            authorize_code_dly <= 'd0;
            authorize_code_pre <= 'h0;
        end  
    else
        begin
            authorize_code_dly <= #U_DLY authorize_code ^ key;
            authorize_code_pre <= #U_DLY athr_code_gen(authorize_code_dly);
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        authorize_succ <= 1'b0;
    else
        begin
            if(authorize_code_pre == authorize_code_dly)
                authorize_succ <= #U_DLY 1'b1;
            else
                authorize_succ <= #U_DLY 1'b0;
        end
end 


function [31:0] athr_code_gen(input [31:0] f_last_seeds);    //G(X) = X31 + X25 + X22 + X6 + 1; (not the standard PRBS31[G(X) = X31 + X28 + 1])
integer i;
reg base_xor;
begin
    athr_code_gen = f_last_seeds;
    for(i=0; i<=31; i=i+1)
        begin
            base_xor = athr_code_gen[30]^athr_code_gen[24]^athr_code_gen[21]^athr_code_gen[5];
            athr_code_gen = {athr_code_gen[30:0],base_xor};
        end
end
endfunction


endmodule

