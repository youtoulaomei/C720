// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/11/15 17:13:38
// File Name    : cpu_process.v
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
module cpu_process #(
parameter                           U_DLY = 1,
parameter                           CPU_ADDR_W = 14,
parameter                           CPU_DATA_W = 32,
parameter                           CPU_BOUNDARY = {14'h0fff,14'h0000}
)
(
//top cpu bus
input                               cpu_cs,
input                               cpu_rd,
input                               cpu_we,
input           [CPU_ADDR_W - 1:0]  cpu_addr,
input           [CPU_DATA_W - 1:0]  cpu_wdata,
//cpu allocation
input   wire                        cpu_u_clk,
input   wire                        cpu_u_rst,
output  reg                         cpu_u_cs,
output  reg                         cpu_u_we,   
output  reg                         cpu_u_rd/* synthesis syn_keep=1 */, 
output  reg     [CPU_ADDR_W - 1:0]  cpu_u_addr/* synthesis syn_maxfan=10 */,
output  reg     [CPU_DATA_W - 1:0]  cpu_u_wdata/* synthesis syn_maxfan=10 */
);
// Parameter Define 

// Register Define 
reg                                 cpu_cs_dly;
reg                                 cpu_rd_dly;
reg                                 cpu_we_dly;
reg     [CPU_ADDR_W - 1:0]          cpu_addr_dly;
reg     [CPU_DATA_W - 1:0]          cpu_wdata_dly;
// Wire Define 

assign cpu_cs_curchip = (cpu_addr >= CPU_BOUNDARY[0+:CPU_ADDR_W] && cpu_addr <= CPU_BOUNDARY[CPU_ADDR_W+:CPU_ADDR_W]) ? cpu_cs : 1'b1;
always @(posedge cpu_u_clk or posedge cpu_u_rst)
begin
    if(cpu_u_rst == 1'b1)
        begin
            cpu_cs_dly <= 1'b1;
            cpu_u_cs <= 1'b1;
        end
    else
        begin
            cpu_cs_dly <= #U_DLY cpu_cs_curchip;
            cpu_u_cs <= #U_DLY cpu_cs_dly;
        end
end

always @(posedge cpu_u_clk or posedge cpu_u_rst)
begin
    if(cpu_u_rst == 1'b1)
        begin
            cpu_rd_dly <= 1'b1;
            cpu_u_rd <= 1'b1;
        end
    else
        begin
            cpu_rd_dly <= #U_DLY cpu_rd;
            cpu_u_rd <= #U_DLY cpu_rd_dly;
        end
end

always @(posedge cpu_u_clk or posedge cpu_u_rst)
begin
    if(cpu_u_rst == 1'b1)
        begin
            cpu_we_dly <= 1'b1;
            cpu_u_we <= 1'b1;
        end
    else
        begin
            cpu_we_dly <= #U_DLY cpu_we;
            cpu_u_we <= #U_DLY cpu_we_dly;
        end
end

always @(posedge cpu_u_clk or posedge cpu_u_rst)
begin
    if(cpu_u_rst == 1'b1)
        begin
            cpu_addr_dly <= 'd0;
            cpu_u_addr <= 'd0;
            cpu_wdata_dly <= 'd0;
            cpu_u_wdata <= 'd0;
        end
    else
        begin
            cpu_addr_dly <= #U_DLY cpu_addr;
            cpu_u_addr <= #U_DLY cpu_addr_dly;
            cpu_wdata_dly <= #U_DLY cpu_wdata;
            cpu_u_wdata <= #U_DLY cpu_wdata_dly;
        end
end


endmodule

