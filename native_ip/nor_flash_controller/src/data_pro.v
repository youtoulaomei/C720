// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/3/9 9:34:32
// File Name    : data_pro.v
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
module data_pro #(
parameter                           U_DLY = 1,
parameter                           DATA_W = 16
)
(
input                               clk,
input                               rst,
//interface with cmd_pro module
input           [DATA_W - 1:0]      rdata,
input                               rvld,

output  wire    [DATA_W - 1:0]      wdata,
input                               wdata_ren,
output  reg                         wdata_rdy,
//interface with upstream 
output  reg     [DATA_W - 1:0]      read_data,
output  reg                         read_vld,

input           [DATA_W - 1:0]      write_data,
input                               write_vld,
output  reg                         write_rdy,
//cfg
output  reg                         wfifo_empty,
//output  reg                         rfifo_full,
input                               inbuf_en,
output  reg                         indata_cnt_ind
);
// Parameter Define 
localparam                           WFIFO_ADDR_W = 9;              //512 words,1024 Bytes
// Register Define 
reg     [DATA_W - 1:0]              wdata_fifo[2**WFIFO_ADDR_W-1:0]/* synthesis syn_ramstyle="block_ram" */;
reg     [DATA_W - 1:0]              wfifo_rdata_pre;
reg     [DATA_W - 1:0]              wfifo_rdata;
reg     [WFIFO_ADDR_W - 1:0]        wfifo_waddr;
reg     [WFIFO_ADDR_W - 1:0]        wfifo_raddr;
// Wire Define 
wire    [WFIFO_ADDR_W - 1:0]        wfifo_wl;

//**************************************************************************//
//write data  process
//**************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        indata_cnt_ind <= 1'b0;
    else
        begin
            if((write_vld & write_rdy) == 1'b1)
                indata_cnt_ind <= #U_DLY 1'b1;
            else
                indata_cnt_ind <= #U_DLY 1'b0;
        end
end

always @(posedge clk)
begin
    if((write_vld & write_rdy) == 1'b1)
        wdata_fifo[wfifo_waddr] <= #U_DLY write_data;
    else;
end

always @(posedge clk)
begin
    wfifo_rdata_pre <= #U_DLY wdata_fifo[wfifo_raddr];
    wfifo_rdata <= #U_DLY wfifo_rdata_pre;
end
//##########################################################################//
assign wdata = wfifo_rdata;
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wfifo_waddr <= 'd0;
            wfifo_raddr <= 'd0;
        end
    else
        begin
            if(write_vld == 1'b1 && write_rdy == 1'b1)
                wfifo_waddr <= #U_DLY wfifo_waddr + 'd1;
            else;

            if(wdata_ren == 1'b1)
                wfifo_raddr <= #U_DLY wfifo_raddr + 'd1;
            else;
        end
end

assign wfifo_wl = wfifo_waddr - wfifo_raddr;
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        write_rdy <= 1'b0;
    else
        begin
            if(wfifo_wl >= (2**WFIFO_ADDR_W - 3))
                write_rdy <= #U_DLY 1'b0;
            else
                write_rdy <= #U_DLY inbuf_en;
        end
end 

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        wfifo_empty <= 1'b1;
    else
        begin
            if(wfifo_waddr == wfifo_raddr)
                wfifo_empty <= #U_DLY 1'b1;
            else
                wfifo_empty <= #U_DLY 1'b0;
        end
end
//**************************************************************************//
//yangyong added 20200217
//**************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        wdata_rdy <= 1'b0;
    else 
        begin
            if(wfifo_wl >= (2**(WFIFO_ADDR_W - 1) - 3))                          //almost 512Bytes
                wdata_rdy <= #U_DLY 1'b1;
            else
                wdata_rdy <= #U_DLY 1'b0;
        end
end 
//**************************************************************************//
//read data  process
//**************************************************************************//           
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            read_data <= 'd0;
            read_vld <= 1'b0;
        end
    else
        begin
            read_data <= #U_DLY rdata;
            read_vld <= #U_DLY rvld;
        end
end

endmodule

