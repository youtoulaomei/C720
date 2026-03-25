// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/11/15 16:46:53
// File Name    : cpu_alloc.v
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
module cpu_alloc_32users #(
parameter                           U_DLY = 1,
parameter                           CPU_USER = 32,
parameter                           CPU_ADDR_W = 13,
parameter                           CPU_DATA_W = 32,
parameter                           CPU_BOUNDARY = {{13'h1fff,13'h1f00},{13'h1eff,13'h1e00},{13'h1dff,13'h1d00},{13'h1cff,13'h1c00},{13'h1bff,13'h1b00},{13'h1aff,13'h1a00},{13'h19ff,13'h1900},{13'h18ff,13'h1800},{13'h17ff,13'h1700},{13'h16ff,13'h1600},{13'h15ff,13'h1500},{13'h14ff,13'h1400},{13'h13ff,13'h1300},{13'h12ff,13'h1200},{13'h11ff,13'h1100},{13'h10ff,13'h1000},{13'hfff,13'hf00},{13'heff,13'he00},{13'hdff,13'hd00},{13'hcff,13'hc00},{13'hbff,13'hb00},{13'haff,13'ha00},{13'h9ff,13'h900},{13'h8ff,13'h800},{13'h7ff,13'h700},{13'h6ff,13'h600},{13'h5ff,13'h500},{13'h4ff,13'h400},{13'h3ff,13'h300},{13'h2ff,13'h200},{13'h1ff,13'h100},{13'h0ff,13'h000}}
)
(
//top cpu bus
input                               cpu_clk,
input                               cpu_rst,
input                               cpu_cs,
input                               cpu_rd,
input                               cpu_we,
input           [CPU_ADDR_W - 1:0]  cpu_addr,
input           [CPU_DATA_W - 1:0]  cpu_wdata,
output  reg     [CPU_DATA_W - 1:0]  cpu_rdata,
//cpu allocation
input   wire    [CPU_USER - 1:0]    cpu_u_clk,
input   wire    [CPU_USER - 1:0]    cpu_u_rst,
output  wire    [CPU_USER - 1:0]    cpu_u_cs,
output  wire    [CPU_USER - 1:0]    cpu_u_we,   
output  wire    [CPU_USER - 1:0]    cpu_u_rd, 
output  wire    [CPU_ADDR_W * CPU_USER - 1:0] cpu_u_addr,
output  wire    [CPU_DATA_W * CPU_USER - 1:0] cpu_u_wdata,
input           [CPU_DATA_W * CPU_USER - 1:0] cpu_u_rdata
);
// Parameter Define 

// Register Define 
reg     [CPU_DATA_W - 1:0]          cpu_rdata_pre;
// Wire Define 

genvar i;
generate 
for(i = 0; i < CPU_USER; i = i+1)
begin
cpu_process #(
    .U_DLY                      (U_DLY                      ),
    .CPU_ADDR_W                 (CPU_ADDR_W                 ),
    .CPU_DATA_W                 (CPU_DATA_W                 ),
    .CPU_BOUNDARY               (CPU_BOUNDARY[CPU_ADDR_W*2*i+:CPU_ADDR_W*2])
)
u_cpu_process(
//top cpu bus
    .cpu_cs                     (cpu_cs                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_we                     (cpu_we                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wdata                  (cpu_wdata                  ),
//cpu allocation
    .cpu_u_clk                  (cpu_u_clk[i]               ),
    .cpu_u_rst                  (cpu_u_rst[i]               ),
    .cpu_u_cs                   (cpu_u_cs[i]                ),
    .cpu_u_we                   (cpu_u_we[i]                ),
    .cpu_u_rd                   (cpu_u_rd[i]                ),
    .cpu_u_addr                 (cpu_u_addr[CPU_ADDR_W*i+:CPU_ADDR_W]),
    .cpu_u_wdata                (cpu_u_wdata[CPU_DATA_W*i+:CPU_DATA_W])
);
end
endgenerate

always @(posedge cpu_clk or posedge cpu_rst)
begin:cpu_rdata_sel
    integer j;
    if(cpu_rst == 1'b1)
        begin
            cpu_rdata_pre <= 'd0;
            cpu_rdata <= 'd0;
        end
    else
        begin
            for(j=0; j<CPU_USER; j=j+1)
                begin
                    if(cpu_addr >= CPU_BOUNDARY[(CPU_ADDR_W*(j*2))+:CPU_ADDR_W] && cpu_addr <= CPU_BOUNDARY[(CPU_ADDR_W*(j*2+1))+:CPU_ADDR_W])
                        cpu_rdata_pre <= #U_DLY cpu_u_rdata[(CPU_DATA_W*j)+:CPU_DATA_W];
                    else;
                end

            cpu_rdata <= #U_DLY cpu_rdata_pre;
    end
end


endmodule

