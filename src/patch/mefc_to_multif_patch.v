// *********************************************************************************/
// Project Name :
// Author       : LanJing
// Email        : 390336267@qq.com
// Creat Time   : 2019/7/25 14:28:02
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2019, BoYuLiHua Co., Ltd.. 
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
module mefc_to_multif_patch #(
parameter                           U_DLY = 1,
parameter                           DATA_IN_WIDTH  = 16,
parameter                           DATA_OUT_WIDTH = 512     
)
(
input                               sys_clk,
input                               rst,
input         [DATA_IN_WIDTH-1:0]   mefc_in_data,
input                               mefc_in_vld,

output  reg   [DATA_OUT_WIDTH-1:0]  mefc_out_data,       
output  reg                         mefc_out_vld
);
// Parameter Define 

// Register Define 
reg           [DATA_OUT_WIDTH-1:0]  mefc_data_tmp;
reg           [4:0]                 data_cnt;
reg                                 mefc_in_vld_dly1;
reg                                 mefc_in_vld_dly2;
// Wire Define 

always @ (posedge sys_clk or posedge rst)
begin
    if(rst == 1'b1)
    begin    
        mefc_in_vld_dly1 <= #U_DLY 'b0;
        mefc_in_vld_dly2 <= #U_DLY 'b0;
    end
    else
    begin
        mefc_in_vld_dly1 <= #U_DLY mefc_in_vld;
        mefc_in_vld_dly2 <= #U_DLY mefc_in_vld_dly1;
    end
end

always @ (posedge sys_clk or posedge rst)
begin
    if(rst == 1'b1)     
       data_cnt <= #U_DLY 5'b0;
    else if(mefc_in_vld_dly2 == 1'b1)
       data_cnt <= #U_DLY data_cnt + 1'b1;
    else ;   
end

always @ (posedge sys_clk or posedge rst)
begin
    if(rst == 1'b1)
    begin 
       mefc_data_tmp <= #U_DLY 'b0;    
   end
   else if (mefc_in_vld==1'b1)  
       mefc_data_tmp <= #U_DLY {mefc_in_data,mefc_data_tmp[511:16]};
   else ;
end 

always @ (posedge sys_clk or posedge rst)
begin
    if(rst == 1'b1)
    begin       
        mefc_out_data <= #U_DLY 'b0;
        mefc_out_vld  <= #U_DLY 1'b0;
    end
    else if((&data_cnt)==1'b1)
   begin
        mefc_out_data <= #U_DLY mefc_data_tmp;
        mefc_out_vld  <= #U_DLY 1'b1;
    end
   else
        mefc_out_vld  <= #U_DLY 1'b0;
end

endmodule

