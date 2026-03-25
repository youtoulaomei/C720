// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/12/12 15:08:45
// File Name    : i2c_master_top.v
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
`define AUTHORIZE_ENABLE
module i2c_master_top #(
parameter                           U_DLY = 1,
parameter                           CPU_ADDR_W = 8
)
(
input                               clk,
input                               rst,
input                               hard_rst,
//authorization 
input           [31:0]              authorize_code,
//i2c sda scl
inout                               sda,
output                              scl,
//cpu interface
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [CPU_ADDR_W - 1:0]  cpu_addr,
input           [31:0]              cpu_wdata,
output  wire    [31:0]              cpu_rdata
);
// Parameter Define 
localparam                          DATA_BIT_LEN = 8;
localparam                          VERSION =32'h00_00_00_01;
localparam                          YEAR = 16'h20_17;
localparam                          MONTH = 8'h12;
localparam                          DAY = 8'h16;
// Register Define 

// Wire Define 
wire    [31:0]                      cpu_rdata_phy;
wire    [23:0]                      i2c_scl_prd;
wire    [2:0]                       i2c_header_len;
wire    [5:0]                       i2c_op_len;
wire    [15:0]                      i2c_sta_hold;
wire    [15:0]                      i2c_sto_setup;
wire    [31:0]                      cpu_rdata_cib;

i2c_phy #(
    .U_DLY                      (U_DLY                      ),
    .CPU_ADDR_W                 (CPU_ADDR_W - 1             ),
    .DATA_BIT_LEN               (DATA_BIT_LEN               )
)
u_i2c_phy(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//i2c sda scl
    .sda                        (sda                        ),
    .scl                        (scl                        ),
//cpu interface
    .cpu_cs                     (cpu_cs_phy                 ),
    .cpu_we                     (cpu_we                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr[CPU_ADDR_W-2:0]   ),
    .cpu_wdata                  (cpu_wdata                  ),
    .cpu_rdata                  (cpu_rdata_phy              ),
//config
    .i2c_start                  (i2c_start                  ),
    .i2c_scl_prd                (i2c_scl_prd                ),
    .i2c_header_len             (i2c_header_len             ),
    .i2c_op_len                 (i2c_op_len                 ),
    .i2c_sta_hold               (i2c_sta_hold               ),
    .i2c_sto_setup              (i2c_sto_setup              ),
    .last_read_ack              (last_read_ack              ),
    .slave_no_ack               (slave_no_ack               ),
    .i2c_master_free            (i2c_master_free            ),
//others
`ifdef AUTHORIZE_ENABLE 
    .authorize_succ             (authorize_succ             )
`else
    .authorize_succ             (1'b1                       )
`endif
);


i2c_cib #(
    .U_DLY                      (U_DLY                      ),
    .CPU_ADDR_W                 (CPU_ADDR_W - 1             ),
    .VERSION                    (VERSION                    ),
    .YEAR                       (YEAR                       ),
    .MONTH                      (MONTH                      ),
    .DAY                        (DAY                        )
)
u_i2c_cib(
    .clk                        (clk                        ),
    .rst                        (hard_rst                   ),
//cpu bus
    .cpu_cs                     (cpu_cs_cib                 ),
    .cpu_we                     (cpu_we                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr[CPU_ADDR_W-2:0]   ),
    .cpu_wdata                  (cpu_wdata                  ),
    .cpu_rdata                  (cpu_rdata_cib              ),
//others config
    .i2c_start                  (i2c_start                  ),
    .i2c_scl_prd                (i2c_scl_prd                ),
    .i2c_header_len             (i2c_header_len             ),
    .i2c_op_len                 (i2c_op_len                 ),
    .i2c_sta_hold               (i2c_sta_hold               ),
    .i2c_sto_setup              (i2c_sto_setup              ),
    .last_read_ack              (last_read_ack              ),
    .slave_no_ack               (slave_no_ack               ),
    .i2c_master_free            (i2c_master_free            )
);

assign cpu_cs_cib = (cpu_addr[CPU_ADDR_W - 1] == 1'b0) ? cpu_cs : 1'b1;
assign cpu_cs_phy = (cpu_addr[CPU_ADDR_W - 1] == 1'b1) ? cpu_cs : 1'b1;
assign cpu_rdata = (cpu_addr[CPU_ADDR_W - 1] == 1'b1) ? cpu_rdata_phy : cpu_rdata_cib;

authorize_sub_module #(
    .U_DLY                      (U_DLY                      )
)
u_authorize_sub_module(
    .clk                        (clk                        ),
    .rst                        (hard_rst                   ),
    .key                        (32'h4C_4A_43_44            ),    
//
    .authorize_code             (authorize_code             ),
//
    .authorize_succ             (authorize_succ             )
);

endmodule


