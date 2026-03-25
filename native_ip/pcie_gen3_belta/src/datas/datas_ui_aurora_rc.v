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
module datas_ui_aurora_rc # (
parameter                           U_DLY  = 1,
parameter                           DATA_W = 512
)
(
input                               clk,
input                               rst_n,

//input                               ds_tx_arb_req,
//output reg                          ds_arb_tx_ack,
input  [DATA_W-1:0]                 ds_tx_tdata,
input  [DATA_W/8-1:0]               ds_tx_tkeep,
input                               ds_tx_tvalid,
input                               ds_tx_tlast,
output wire                         ds_tx_tready,

output reg  [DATA_W-1:0]            rx_data,          
output reg  [DATA_W/8-1:0]          rx_keep,          
output reg                          rx_last,          
output reg                          rx_data_vld       


);
// Parameter Define 
                                                         
// Register Define                                       


// Wire Define


assign ds_tx_tready = 1'b1;

//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)     
//        ds_tx_arb_req_r <= #U_DLY 2'b0;        
//    else 
//        ds_tx_arb_req_r <= #U_DLY {ds_tx_arb_req_r[0],ds_tx_arb_req};   
//end
//
//
//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)     
//        ds_arb_tx_ack <= #U_DLY 1'b0;        
//    else if(ds_tx_arb_req_r[0] == 1'b1 && ds_tx_arb_req_r[1] == 1'b0)
//        ds_arb_tx_ack <= #U_DLY 1'b1;
//    else
//        ds_arb_tx_ack <= #U_DLY 1'b0;   
//end
//assign ds_arb_tx_ack = (ds_tx_arb_req_r[1] == 1'b1 && ds_tx_arb_req_r[2] == 1'b0) ? 1'b1 :1'b0;


//assign header_hunt_x = (ds_tx_tlast==1'b1) && (ds_tx_tvalid==1'b1)? 1'b1 :
//                (ds_tx_tvalid==1'b1)? 1'b0 : header_hunt;
//
//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)     
//        header_hunt <= #U_DLY 1'b1;        
//    else    
//        header_hunt <= #U_DLY header_hunt_x;
//end
//
//assign header_flag = (header_hunt_x==1'b0)&&(header_hunt==1'b1)?1'b1:1'b0;


//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)     
//        end_flag <= #U_DLY 1'b0;
//    else if( ds_tx_tlast==1'b1 && ds_tx_tvalid==1'b1 && ds_tx_tready == 1'b1 )
//        end_flag <= #U_DLY 1'b0;
//    else if( ds_tx_tvalid == 1'b1 && header_flag == 1'b1 && ds_tx_tdata[5] == 1'b1 )
//        end_flag <= #U_DLY 1'b1;
//end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        rx_data <= #U_DLY {(DATA_W){1'b0}};       
    else if( ds_tx_tvalid == 1'b1 && ds_tx_tready == 1'b1 )
        rx_data <= #U_DLY ds_tx_tdata;
    else
        rx_data <= #U_DLY {(DATA_W){1'b0}}; 
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        rx_keep <= #U_DLY {(DATA_W/8){1'b0}};       
    else if( ds_tx_tvalid == 1'b1 && ds_tx_tready == 1'b1  )
        rx_keep <= #U_DLY ds_tx_tkeep;
    else
        rx_keep <= #U_DLY {(DATA_W/8){1'b0}}; 
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        rx_data_vld <= #U_DLY 1'b0;       
    else if( ds_tx_tvalid == 1'b1 && ds_tx_tready == 1'b1) 
        rx_data_vld <= #U_DLY ds_tx_tvalid;
    else
        rx_data_vld <= #U_DLY 1'b0; 
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        rx_last <= #U_DLY 1'b0;       
    else if( ds_tx_tvalid == 1'b1 && ds_tx_tready == 1'b1)
        rx_last <= #U_DLY ds_tx_tlast;
    else
        rx_last <= #U_DLY 1'b0; 
end

endmodule
