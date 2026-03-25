// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2015/9/21 16:30:37
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
module datas_check_prbs31 #(
parameter                           U_DLY = 1
)
(
input                               clk       ,
input                               rst_n     ,
input                               pbc_start ,
input [7:0]                         prbs31    ,
input                               valid     ,  
input                               keep      ,
output                              error     
);
// Parameter Define 

// Register Define 

// Wire Define 
reg  [7:0]   chk_prbs31;
wire [7:0]   chk_prbs31_x;
reg  [30:0]  f_last_seeds; 
wire [30:0]  f_last_seeds_x;
reg  [2:0]   pbc_start_cnt;


 always @( posedge clk or negedge rst_n )       
  begin                                        
  	 if( rst_n == 1'b0 )                        
  	   f_last_seeds <= #U_DLY 31'b0;
  	 else           
       f_last_seeds <= #U_DLY f_last_seeds_x ;              
  end   
 
assign f_last_seeds_x = (valid && pbc_start_cnt <= 'd3) ? next_seeds({f_last_seeds[30:8],prbs31[7:0]}) : 
                        (valid && pbc_start_cnt >= 'd4) ? next_seeds({f_last_seeds[30:0]}) : f_last_seeds ;


assign  chk_prbs31_x = f_last_seeds_x[7:0];
 
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

                                               
always @( posedge clk or negedge rst_n )
begin
	 if( rst_n == 1'b0 )   
	   chk_prbs31  <=  #U_DLY 8'b0;
	 else 
	   chk_prbs31  <=  #U_DLY chk_prbs31_x;
end

always @( posedge clk or negedge rst_n )
begin
	 if( rst_n == 1'b0 ) 
	     pbc_start_cnt <= #U_DLY 'b0;
	 else if(pbc_start==1'b1)
	     pbc_start_cnt <= #U_DLY 'b0;
	 else if(pbc_start_cnt>='d4)
	     pbc_start_cnt <= #U_DLY 'd4;  
	 else if(valid==1'b1)
	     pbc_start_cnt <= #U_DLY pbc_start_cnt + 'b1;
	    
end


assign error = (valid == 1'b0) ? 1'b0:
               (pbc_start == 1'b1) ? 1'b0:
               (valid == 1'b1 && keep == 1'b1 && pbc_start_cnt >= 'd4) && (prbs31 != chk_prbs31) ? 1'b1:1'b0;  


endmodule
