// *********************************************************************************/
// Project Name :
// Author       : Lanjing
// Email        : 390336267@qq.com
// Creat Time   : 2019/7/16 11:25:30
// File Name    : ddr_to_mefc_patch.v
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
module ddr_to_mefc_patch #(
parameter                           U_DLY = 1,
parameter                           DATA_IN_WIDTH  = 512,
parameter                           DATA_OUT_WIDTH = 16 

)
(
input                               clk,            
input                               rst,         
//ddr                
input        [DATA_IN_WIDTH-1:0]    ddr_out_data,  
input                               ddr_out_vld,   
output                              ddr_out_rdy,   
//mefc                
output       [DATA_OUT_WIDTH-1:0]   mefc_odata,  
output  reg                         mefc_ovld,   
input                               mefc_ordy  

);
// Parameter Define 

// Register Define 

reg     [4:0]                       shift_data_cnt;
reg     [DATA_IN_WIDTH-1:0]         mefc_out_data_tmp;
reg                                 first_rd_flag;
reg                                 mefc_out_rdy_flag;
reg                                 wait_data_vld_flag;
 
// Wire Define
//
//
// first_rd_flag
always @ ( posedge clk or posedge rst )
begin
    if( rst == 1'b1 )     
        first_rd_flag <= #U_DLY 1'b1;           
    else if( ddr_out_rdy == 1'b1 && ddr_out_vld == 1'b1 )
        first_rd_flag <= #U_DLY 1'b0;  
    else ;
end

// mefc_out_rdy_flag 
always @ ( posedge clk or posedge rst )
begin
    if( rst == 1'b1 )     
        mefc_out_rdy_flag <= #U_DLY 1'b0;           
    else if( ddr_out_rdy == 1'b1 && ddr_out_vld == 1'b1 ) 
        mefc_out_rdy_flag <= #U_DLY 1'b0;
    else if(( shift_data_cnt == 5'd30) && mefc_ordy == 1'b1 && mefc_ovld == 1'b1 )
        mefc_out_rdy_flag <= #U_DLY 1'b1; 
    else if( first_rd_flag == 1'b1 )
        mefc_out_rdy_flag <= #U_DLY 1'b1;       
    else ;       
end

// ddr_out_rdy
assign ddr_out_rdy = ( first_rd_flag == 1'b1 && mefc_out_rdy_flag == 1'b1 ) ? 1'b1 :
                      ( mefc_out_rdy_flag == 1'b1 && ( ( &shift_data_cnt ) == 1'b1 ) && mefc_ordy == 1'b1 && mefc_ovld == 1'b1 ) ? 1'b1 : 
                      ( wait_data_vld_flag == 1'b1 ) ? 1'b1 : 1'b0;


// wait_data_vld_flag
always @ ( posedge clk or posedge rst )
begin
    if( rst == 1'b1 )     
        wait_data_vld_flag <= #U_DLY 1'b0;           
    else if( ddr_out_rdy == 1'b1 && ddr_out_vld == 1'b1 )
        wait_data_vld_flag <= #U_DLY 1'b0;         
    else if( ddr_out_rdy == 1'b1 && ddr_out_vld == 1'b0 && first_rd_flag == 1'b0 )
        wait_data_vld_flag <= #U_DLY 1'b1;   
    else ;
end    

// shift_data_cnt
always @ ( posedge clk or posedge rst )
begin
    if( rst == 1'b1 )     
        shift_data_cnt <= #U_DLY 'd0;
    else if( ddr_out_rdy == 1'b1 && ddr_out_vld == 1'b1 )
        shift_data_cnt <= #U_DLY 'd0;
    else if( mefc_ordy == 1'b1 && mefc_ovld == 1'b1 )
        shift_data_cnt <= #U_DLY shift_data_cnt + 'd1;
    else ;       
end

// mefc_out_data_tmp
always @ ( posedge clk or posedge rst )
begin
    if( rst == 1'b1 )     
        mefc_out_data_tmp <= #U_DLY 'd0; 
    else if( ddr_out_vld == 1'b1 && ddr_out_rdy == 1'b1 )
        mefc_out_data_tmp <= #U_DLY ddr_out_data; 
    else if( mefc_ordy == 1'b1 && mefc_ovld == 1'b1 )
        mefc_out_data_tmp <= #U_DLY mefc_out_data_tmp >> DATA_OUT_WIDTH; 
    else ;
end

assign mefc_odata = mefc_out_data_tmp[15:0];
// mefc_ovld
always @ ( posedge clk or posedge rst )
begin
    if( rst == 1'b1 )     
        mefc_ovld <= #U_DLY 1'b0;
    else if( ddr_out_rdy == 1'b1 && ddr_out_vld == 1'b1 )
        mefc_ovld <= #U_DLY 1'b1;
    else if((( &shift_data_cnt ) == 1'b1 ) && mefc_ordy == 1'b1 && mefc_ovld == 1'b1 )
        mefc_ovld <= #U_DLY 1'b0;
    else ;    
end

endmodule

