// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2015/9/9 14:46:00
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
module datas_gen_prbs31 # (
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst_n,
input                               clr,
input [30:0]                        seed,
input                               send_vld,
output [7:0]                        data

);
// Parameter Define 

// Register Define 

// Wire Define 
reg  [30:0]  f_last_seeds;
 
 always @( posedge clk or negedge rst_n )       
   begin                                        
   	 if( rst_n == 1'b0 )                        
   	   f_last_seeds <= #U_DLY 31'b0;
     else if( clr == 1'b1 )
       f_last_seeds <= #U_DLY seed;   
   	 else if( send_vld == 1'b1 )           
       f_last_seeds <= #U_DLY next_seeds(f_last_seeds);              
   end                                          
 
function [30:0] next_seeds(input [30:0] f_last_seeds);    //G(X) = X31 + X28 + 1 ; 
integer i;
reg [31:0]  shif_prbs31;
begin 
    shif_prbs31 = {1'b0,f_last_seeds};
    for(i=0; i<=7; i=i+1)
    shif_prbs31 = {shif_prbs31[30:0],shif_prbs31[30]^shif_prbs31[27]};
    next_seeds =  shif_prbs31[30:0];
end
endfunction
 
assign  data =  f_last_seeds[7:0];


endmodule
