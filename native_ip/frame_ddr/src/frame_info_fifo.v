// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/6/1 14:35:53
// File Name    : frame_info_fifo.v
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
module frame_info_fifo #(
parameter                           U_DLY = 1,
parameter                           DDR_FRAME_ADDR_HGIH_W = 15,
parameter                           FRAME_IFIFO_DATA_W = 32
)
(
input                               clk,
input                               rst,
//with write side
output  reg     [DDR_FRAME_ADDR_HGIH_W - 1:0]frame_ififo_waddr,
output  reg                         frame_ififo_full,
input                               frame_ififo_wen,
input           [FRAME_IFIFO_DATA_W - 1:0]frame_ififo_wdata,   //{reserved_info,frame_len,user_addr_low(slot_length)}
//with read side
output  reg     [DDR_FRAME_ADDR_HGIH_W - 1:0]frame_ififo_raddr,
output  reg                         frame_ififo_empty,
input                               frame_ififo_ren,
output  reg     [FRAME_IFIFO_DATA_W - 1:0]frame_ififo_rdata,   //{reserved_info,frame_len,user_addr_low(slot_length)}
//for debug
output  reg     [DDR_FRAME_ADDR_HGIH_W - 1:0]frame_ififo_waterline,
input           [31:0]              frame_ififo_lwup_cfg,
input           [31:0]              frame_ififo_lwdown_cfg,
output  reg                         frame_ififo_afull,
output  reg                         frame_ififo_aempty,
input                               authorize_succ
);
// Parameter Define 

// Register Define 
reg     [FRAME_IFIFO_DATA_W - 1:0]  frame_ififo[2**DDR_FRAME_ADDR_HGIH_W - 1:0]/* synthesis syn_ramstyle="block_ram" */;
reg     [FRAME_IFIFO_DATA_W - 1:0]  frame_ififo_rdata_pre;
reg     [31:0]                      frame_ififo_lwup_cfg_1dly;
reg     [31:0]                      frame_ififo_lwup_cfg_2dly;
reg     [31:0]                      frame_ififo_lwdown_cfg_1dly;
reg     [31:0]                      frame_ififo_lwdown_cfg_2dly;
// Wire Define 
wire    [DDR_FRAME_ADDR_HGIH_W - 1:0]frame_ififo_wl;


assign frame_ififo_wl = frame_ififo_waddr - frame_ififo_raddr; 
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frame_ififo_waddr <= 'd0;
            frame_ififo_full <= 1'b0;
        end
    else
        begin
            if(frame_ififo_wen == 1'b1 && authorize_succ == 1'b1)
                frame_ififo_waddr <= #U_DLY frame_ififo_waddr + 'd1;
            else;

            if(frame_ififo_wl >= ({DDR_FRAME_ADDR_HGIH_W{1'b1}} - 'd2)) 
                frame_ififo_full <= #U_DLY 1'b1;
            else
                frame_ififo_full <= #U_DLY 1'b0;
        end
end
                
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frame_ififo_raddr <= 'd0;
            frame_ififo_empty <= 1'b1;
        end
    else
        begin
            if(frame_ififo_ren == 1'b1)
                frame_ififo_raddr <= #U_DLY frame_ififo_raddr + 'd1;
            else;
   
            if(frame_ififo_wl == 'd0)
                frame_ififo_empty <= #U_DLY 1'b1;
            else
                frame_ififo_empty <= #U_DLY 1'b0;
        end
end             
//*******************************************************************************//
always @(posedge clk)
begin
    if(frame_ififo_wen == 1'b1)
        frame_ififo[frame_ififo_waddr] <= #U_DLY frame_ififo_wdata;
    else;
end

always @(posedge clk)
begin
    frame_ififo_rdata_pre <= #U_DLY frame_ififo[frame_ififo_raddr];
end 

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        frame_ififo_rdata <= 'd0;
    else
        frame_ififo_rdata <= #U_DLY frame_ififo_rdata_pre;
end
//*******************************************************************************//
//for debug
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frame_ififo_waterline <= 'd0;
            frame_ififo_lwup_cfg_1dly <= 'd0;
            frame_ififo_lwup_cfg_2dly <= 'd0;
            frame_ififo_lwdown_cfg_1dly <= 'd0;
            frame_ififo_lwdown_cfg_2dly <= 'd0;
            frame_ififo_afull <= 1'b0;
            frame_ififo_aempty <= 1'b0;
        end
    else
        begin
            frame_ififo_waterline <= #U_DLY frame_ififo_wl;
            frame_ififo_lwup_cfg_1dly <= #U_DLY frame_ififo_lwup_cfg;
            frame_ififo_lwup_cfg_2dly <= #U_DLY frame_ififo_lwup_cfg_1dly;
            frame_ififo_lwdown_cfg_1dly <= #U_DLY frame_ififo_lwdown_cfg;
            frame_ififo_lwdown_cfg_2dly <= #U_DLY frame_ififo_lwdown_cfg_1dly;
     
            if(frame_ififo_waterline > frame_ififo_lwup_cfg_2dly[DDR_FRAME_ADDR_HGIH_W - 1:0])
                frame_ififo_afull <= #U_DLY 1'b1;
            else
                frame_ififo_afull <= #U_DLY 1'b0;

            if(frame_ififo_waterline < frame_ififo_lwdown_cfg_2dly[DDR_FRAME_ADDR_HGIH_W - 1:0])
                frame_ififo_aempty <= #U_DLY 1'b1;
            else
                frame_ififo_aempty <= #U_DLY 1'b0;
        end               
end


endmodule

