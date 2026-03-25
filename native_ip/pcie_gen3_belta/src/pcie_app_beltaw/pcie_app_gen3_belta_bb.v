// *********************************************************************************/
// Project Name :
// Author       : dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/11/2 16:08:44
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Sichuan shenrong digital equipment Co., Ltd.. 
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
module pcie_app_gen3_belta # (
parameter                           WCHN_NUM   = 76,
parameter                           RCHN_NUM   = 9,
parameter                           WDATA_WIDTH= 512,
parameter                           RDATA_WIDTH= 512,
parameter                           WCHN_NUM_W = clog2b(WCHN_NUM),
parameter                           RCHN_NUM_W = clog2b(RCHN_NUM),
parameter                           WPHY_NUM   = 1,
parameter                           WPHY_NUM_W = clog2b(WPHY_NUM),
parameter                           RTAG_NUM   = 16,//32/16
parameter                           RBURST_LEN = 2048,
parameter                           BURST_LEN  = 2048,
parameter                           U_DLY      = 1
)
(
input                               ref_clk,
input                               ref_reset_n,
input                               sys_clk,
input                               sys_rst_n,
output                              user_clk,
output                              user_rst_n,
input                               rtc_s_flg,
input                               rtc_us_flg,

output      [7:0]                   pci_exp_txn,
output      [7:0]                   pci_exp_txp,
input       [7:0]                   pci_exp_rxn,
input       [7:0]                   pci_exp_rxp,
output                              pcie_link,
//local bus
output                              r_wr_en,
output      [18:0]                  r_addr,         
output      [31:0]                  r_wr_data,     
output                              r_rd_en,         
input       [31:0]                  r_rd_data,

//CIB
input                               pcie_cs,     
input                               pcie_wr,     
input                               pcie_rd,     
input       [7:0]                   pcie_addr,   
input       [31:0]                  pcie_wr_data,
output      [31:0]                  pcie_rd_data,


//MDMA USER Interface
input       [RCHN_NUM-1:0]                  rchn_clk,
input       [RCHN_NUM-1:0]                  rchn_rst_n,
input       [RCHN_NUM-1:0]                  rchn_data_rdy, 
output      [RCHN_NUM-1:0]                  rchn_data_vld,         
output      [RCHN_NUM-1:0]                  rchn_sof,
output      [RCHN_NUM-1:0]                  rchn_eof,
output      [RCHN_NUM*RDATA_WIDTH-1:0]      rchn_data,
output      [(RCHN_NUM*RDATA_WIDTH)/8-1:0]  rchn_keep,
output      [RCHN_NUM*15-1:0]               rchn_length,
  

input       [WPHY_NUM-1:0]                   wchn_clk,
input       [WPHY_NUM-1:0]                   wchn_rst_n,          
output      [WPHY_NUM-1:0]                   wchn_data_rdy,
input       [WPHY_NUM-1:0]                   wchn_data_vld,
input       [WPHY_NUM-1:0]                   wchn_sof,
input       [WPHY_NUM-1:0]                   wchn_eof,
input       [WPHY_NUM*WDATA_WIDTH-1:0]       wchn_data,
input       [WPHY_NUM-1:0]                   wchn_end,
input       [(WPHY_NUM*WDATA_WIDTH)/8-1:0]   wchn_keep,
input       [WPHY_NUM*15-1:0]                wchn_length,
input       [WPHY_NUM*WCHN_NUM_W-1:0]        wchn_chn
)/* synthesis syn_black_box */;
// Parameter Define 

// Register Define 

// Wire Define 

  

function integer clog2b;
input integer value;
begin
if(value<=1)
clog2b = 1;
else
begin
value = value-1;
for (clog2b=0; value>0; clog2b=clog2b+1)
value = value>>1;
end
end
endfunction


endmodule
