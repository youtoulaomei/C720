// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2018/3/16 9:22:17
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Boyulihua digital equipment Co., Ltd.. 
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
module lvds_7k_top #(
parameter                           U_DLY      = 1,
parameter                           LVDS_NUM   = 2,
parameter                           LVDS_WIDTH = 8
)
(
input  [LVDS_NUM-1:0]               lvds_clk_p,
input  [LVDS_NUM-1:0]               lvds_clk_n,

input  [LVDS_NUM*LVDS_WIDTH-1:0]    lvds_data_p,
input  [LVDS_NUM*LVDS_WIDTH-1:0]    lvds_data_n,

input                               rst,
input                               hard_rst,

input                               cpu_cs,
input                               cpu_wr,
input                               cpu_rd,
input        [7:0]                  cpu_addr,
input        [31:0]                 cpu_wr_data,
output       [31:0]                 cpu_rd_data,

input                               clk_200m,
input                               clk_100m,
output                              ad_clk,
output      [16*LVDS_NUM-1:0]       ad_data,
output      [LVDS_NUM-1:0]          ad_vld,

input                               sys_ms_flg

);
// Parameter Define 
localparam    FIXED_DELAY_PARAM0 =5'd7 ; 
localparam    FIXED_DELAY_PARAM1 =5'd7 ; 
localparam    FIXED_DELAY_PARAM2 =5'd7 ; 
localparam    FIXED_DELAY_PARAM3 =5'd7 ;

localparam    FIXED_DELAY_PARAM ={FIXED_DELAY_PARAM3,FIXED_DELAY_PARAM2,FIXED_DELAY_PARAM1,FIXED_DELAY_PARAM0}; 
// Register Define 

// Wire Define 
wire    [LVDS_NUM*9-1:0]            dly_value;
wire    [LVDS_NUM*LVDS_WIDTH*9-1:0] idelay_value;
wire    [LVDS_NUM-1:0]              lvds_clk;
wire    [LVDS_NUM*LVDS_WIDTH*2-1:0] lvds_odata;
wire    [LVDS_NUM-1:0]              fifo_overflow;
wire    [LVDS_NUM-1:0]              dly_inc;
wire                                sign_mod;


wire    [LVDS_NUM-1:0]              st_clr;
wire    [LVDS_NUM-1:0]              pns_rcvd;
wire    [15:0]                      test_0pattern;
wire    [15:0]                      test_1pattern;
wire    [15:0]                      test_2pattern;


wire    [LVDS_NUM-1:0]              lvds_clk_t;
wire                                io_cfg;
wire    [3:0]                       adc_en;

wire    [LVDS_NUM-1:0]              bias_sign;
wire    [LVDS_NUM*16-1:0]           bias;


//--------------------------------------------------------------------
//ad_clk
//--------------------------------------------------------------------

assign ad_clk = lvds_clk[0];

//--------------------------------------------------------------------
//u_lvds_7k_cib
//--------------------------------------------------------------------
lvds_7k_cib #(
    .U_DLY                      (U_DLY                      ),
    .VERSION                    (32'h1                      ),
    .YEAR                       (16'h2019                   ),
    .MONTH                      (8'h10                      ),
    .DAY                        (8'h28                      ),
    .LVDS_NUM                   (LVDS_NUM                   )
)u_lvds_7k_cib(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),

    .cpu_cs                     (cpu_cs                     ),
    .cpu_wr                     (cpu_wr                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wr_data                (cpu_wr_data                ),
    .cpu_rd_data                (cpu_rd_data                ),

    .st_clr                     (st_clr                     ),
    .test_0pattern              (test_0pattern              ),
    .test_1pattern              (test_1pattern              ),
    .test_2pattern              (test_2pattern              ),
    .pns_rcvd                   (pns_rcvd                   ),
    .io_cfg                     (io_cfg                     ),
    .dly_value                  (dly_value                  ),
    .dly_inc                    (dly_inc                    ),
    .sign_mod                   (sign_mod                   ),

    .adc_en                     (adc_en                     ),

    .idelay_value               (idelay_value               ),
    
	.bias_sign                  ({2'b0,bias_sign}           ),
	.bias                       ({32'b0,bias}               ),

    .fifo_overflow              (fifo_overflow              )
);



genvar i;
generate 
for(i=0;i<LVDS_NUM;i=i+1)
begin
//IBUFDS
IBUFDS #(
    .DIFF_TERM            ("TRUE"                     ),
    .IBUF_LOW_PWR         ("TRUE"                     ),
    .IOSTANDARD           ("DEFAULT"                  )
   ) 
IBUFDS_inst (
    .O                    (lvds_clk_t[i]              ),
    .I                    (lvds_clk_p[i]              ),
    .IB                   (lvds_clk_n[i]              )
);

BUFG BUFG_inst (
      .O                  (lvds_clk[i]                ), // 1-bit output: Clock output
      .I                  (lvds_clk_t[i]              )// 1-bit input: Clock input
   );

//clk_controller clk_controller_inst(
//    .clk_out1                   (lvds_clk[i]                ),
//    .reset                      (1'b0                       ),
//    .locked                     (                           ),
//    .clk_in1_p                  (lvds_clk_p[i]              ),
//    .clk_in1_n                  (lvds_clk_n[i]              )
//);

lvds_7k_pro # (
    .U_DLY                      (U_DLY                      ),
    .LVDS_WIDTH                 (LVDS_WIDTH                 ),
    .FIXED_DELAY_PARAM          (FIXED_DELAY_PARAM[5*i+:5]  )
)u_lvds_7k_pro
(
    .clk_200m                   (clk_200m                   ),
    .clk_100m                   (clk_100m                   ),
    .rst                        (hard_rst                   ),

    .lvds_data_p                (lvds_data_p[i*LVDS_WIDTH+:LVDS_WIDTH]),
    .lvds_data_n                (lvds_data_n[i*LVDS_WIDTH+:LVDS_WIDTH]),
    
    .st_clr                     (st_clr[i]                  ),
    .test_0pattern              (test_0pattern              ),
    .test_1pattern              (test_1pattern              ),
    .test_2pattern              (test_2pattern              ),
    .pns_rcvd                   (pns_rcvd[i]                ),
    .io_cfg                     (io_cfg                     ),
    .dly_value                  (dly_value[i*9+:9]          ),
    .dly_inc                    (dly_inc[i]                 ),
    .sign_mod                   (sign_mod                   ),

    .lvds_clk                   (lvds_clk[i]                ),
    .lvds_odata                 (lvds_odata[(i*2*LVDS_WIDTH)+:(2*LVDS_WIDTH)]),
    .idelay_value               (idelay_value[(i*9*LVDS_WIDTH)+:(9*LVDS_WIDTH)]),
    .sys_ms_flg                 (sys_ms_flg                 )

);

lvds_7k_dp #(
    .U_DLY                      (U_DLY                      )
)u_lvds_7k_dp
(
    .rst                        (rst                        ),
    .lvds_clk                   (lvds_clk[i]                ),
    .chnl_en                    (adc_en[i]                  ),    
    .lvds_odata                 (lvds_odata[(i*2*LVDS_WIDTH)+:(2*LVDS_WIDTH)]),
    .ad_clk                     (ad_clk                     ),
    .ad_vld                     (ad_vld[i]                  ),
    .ad_data                    (ad_data[i*16+:16]          ),
    .fifo_overflow              (fifo_overflow[i]           ),
    .bias_sign                  (bias_sign[i]               ),
	.bias                       (bias[i*16+:16]             )
);
end
endgenerate



endmodule
