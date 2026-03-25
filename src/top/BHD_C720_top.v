/*
 * @Author              : chengrun ch3ngrun@163.com
 * @Date                : 2026-01-14 09:55:49
 * @LastEditors         : chengrun ch3ngrun@163.com
 * @LastEditTime        : 2026-02-05 18:54:37
 * @FilePath            : \Logic_Pro\src\top\BHD_C720_top.v
 * @Description         : BHD-C720����ģ��
 * 
 * Copyright (c) 2026 by Xie Chengrun, All Rights Reserved. 
 */
`timescale 1 ns / 1 ns
`define ALG_EN
module bhd_c720_top#(
parameter                           U_DLY    = 1
)
(
/* -------------------------------------------------------------------------- */
/*                                  Card 9981                                 */
/* -------------------------------------------------------------------------- */
input                               sys_clk_p,
input                               sys_clk_n,
/* --------------------------------- PCIE X8 -------------------------------- */
output          [7:0]               pci_exp_txn,
output          [7:0]               pci_exp_txp,
input           [7:0]               pci_exp_rxn,
input           [7:0]               pci_exp_rxp,
input                               pcie_clk_p,
input                               pcie_clk_n,
input                               pcie_rst_n,
/* ---------------------------------- DDR3 ---------------------------------- */
inout           [63:0]              ddr3_dq,
inout           [7:0]               ddr3_dqs_n,
inout           [7:0]               ddr3_dqs_p,
output          [14:0]              ddr3_addr,
output          [2:0]               ddr3_ba,
output                              ddr3_ras_n,
output                              ddr3_cas_n,
output                              ddr3_we_n,
output                              ddr3_reset_n,
output          [0:0]               ddr3_ck_p,
output          [0:0]               ddr3_ck_n,
output          [0:0]               ddr3_cke,
output          [0:0]               ddr3_cs_n,
output          [7:0]               ddr3_dm,
output          [0:0]               ddr3_odt,

/* ----------------------- RX BP model ZD20E 4line SPI ---------------------- */
output                              rf_power_en,
output                              rx_zd20e_sck,
output                              rx_zd20e_cs,
inout                               rx_zd20e_mosi,
input                               rx_zd20e_miso,
input                               rx_zd20e_full_warm0,
input                               rx_zd20e_full_warm1,
/* ----------------------- TX TL model ZC18 4line SPI ----------------------- */
output                              tx_zc18_sck,
output                              tx_zc18_cs,
inout                               tx_zc18_mosi,
input                               tx_zc18_miso,

/* ------------------------------ IIC_FMC_Card ------------------------------ */
inout                               sda_fmc0,
output                              scl_fmc0,
inout                               sda_fmc1,
output                              scl_fmc1,
/* ----------------------------- IIC_MASTER_Card ---------------------------- */
inout                               sda_master,
output                              scl_master,

/* ---------------------------------- FLASH --------------------------------- */
output          [25:0]              flash_addr,
output                              flash_oe,
output                              flash_we,
inout           [15:0]              flash_dq,
output                              flash_ce,
input                               flash_ry_byn,
/* ------------------------------ b_code & gps ------------------------------ */
output                              bd_rstn,
input                               bd_pps,
input                               bd_rx,
output                              bd_tx,

output                              btc_tx,
input                               btc_rx,
input                               btc_1pps,
output                              btc_rx_en,
output                              btc_1pps_en,

/* ---------------------------------- other --------------------------------- */
// output                              v7_12v_en,
output                              da_chn0_en,
output                              da_chn1_en,


/* -------------------------------------------------------------------------- */
/*                                 FMC RX Card                                */
/* -------------------------------------------------------------------------- */
output                              fmc_ad_pll_pwr_ctrl,
output                              fmc_ad_pll_sel,
input                               fmc_ad_ext_trig,
/* --------------------------------- LVDS RX -------------------------------- */
input   [1:0]                       lvds_clk_p,
input   [1:0]                       lvds_clk_n,
input   [15:0]                      lvds_data_p,
input   [15:0]                      lvds_data_n,
/* -------------------------- PLL AD9516 4line SPI -------------------------- */
output                              pll_ad9516_sck,
output                              pll_ad9516_cs,
inout                               pll_ad9516_mosi,
input                               pll_ad9516_miso,
output                              pll_ad9516_reset_pin,
/* ------------------------ ADC A9467 chip1 3line SPI ----------------------- */
output                              adc_a9467_1_sck,
output                              adc_a9467_1_cs,
inout                               adc_a9467_1_mosi,
input                               adc_a9467_1_miso,
/* ------------------------ ADC A9467 chip2 3line SPI ----------------------- */
output                              adc_a9467_2_sck,
output                              adc_a9467_2_cs,
inout                               adc_a9467_2_mosi,
input                               adc_a9467_2_miso,

/* -------------------------------------------------------------------------- */
/*                                 FMC TX Card                                */
/* -------------------------------------------------------------------------- */

/* --------------------------------- JESD TX -------------------------------- */
input                               jesd_sync0_p,
input                               jesd_sync0_n,
input                               jesd_sync1_p,
input                               jesd_sync1_n,
input                               jesd_sys_ref_p,
input                               jesd_sys_ref_n,
input                               jesd_glblclkp,
input                               jesd_glblclkn,
input                               jesd_refclk_p,
input                               jesd_refclk_n,
output  [3:0]                       jesd_txp,
output  [3:0]                       jesd_txn,
/* -------------------------- PLL HMC7044 3line SPI ------------------------- */
output                              pll_hmc7044_sck,
output                              pll_hmc7044_cs,
inout                               pll_hmc7044_mosi,
input                               pll_hmc7044_miso,
output                              pll_hmc7044_reset_pin,
/* -------------------------- DAC AD9172 4line SPI -------------------------- */
output                              dac_ad9172_sck,
output                              dac_ad9172_cs,
inout                               dac_ad9172_mosi,
input                               dac_ad9172_miso,
output                              dac_ad9172_reset_pin
);
// Parameter Define 
localparam                          LOGIC_ID = 64'h441D_4337_3135;
localparam                          VERSION  = 16'h1000;
// Register Define 
reg     [2:0]                       pp1s_r;
reg     [2:0]                       bd_pps_r;
reg                                 pps_flg;
reg     [31:0]                      samp_cnt;
reg     [31:0]                      samp_rate;
reg     [63:0]                      stamp_1r;
reg     [63:0]                      stamp_2r;
reg     [2:0]                       bd_timing_1s_r;
reg     [2:0]                       btc_timing_1s_r;
reg     [31:0]                      reserevd_0cfg_1r;
reg     [31:0]                      reserevd_0cfg_2r;
reg     [31:0]                      reserevd_1cfg_1r;
reg     [31:0]                      reserevd_1cfg_2r;
reg     [31:0]                      reserevd_2cfg_1r;
reg     [31:0]                      reserevd_2cfg_2r;
reg     [31:0]                      reserevd_3cfg_1r;
reg     [31:0]                      reserevd_3cfg_2r;
reg     [7:0]                       cfg_rdy;

// Wire Define 
wire                                clk_100m;
wire                                clk_50m;
wire                                clk_150m;
wire                                clk_200m;
wire                                sys_locked;
wire                                locked_dac;
wire                                locked_ad;
wire                                hard_rst;
wire                                rst;
wire    [31:0]                      reserved_cur_1alm;
wire    [31:0]                      reserved_cur_0alm;
wire    [31:0]                      reserved_his_1alm;
wire    [31:0]                      reserved_his_0alm;
wire    [31:0]                      reserevd_0cfg;
wire    [31:0]                      reserevd_1cfg;
wire    [31:0]                      reserevd_2cfg;
wire    [31:0]                      reserevd_3cfg;

wire                                timing_1us;
wire                                timing_1ms;
wire                                timing_1s;
wire                                soft_rst;
wire    [11:0]                      device_temp;
wire    [31:0]                      authorize_code;
wire    [2 * 16 - 1:0]              lvds_out_ad_data;
wire    [2 * 1  - 1:0]              lvds_out_ad_vld;
wire    [2 * 16 - 1:0]              ad_addNoise_data_out;
wire    [2 * 1  - 1:0]              ad_addNoise_data_out_vld;
wire    [2 * 16 - 1:0]              bpf_data_out;
wire    [2 * 1  - 1:0]              bpf_data_out_vld;
reg     [2:0]                      	bypass_en_r;
wire                                ad_clk_half;
wire                                ad_clk;
wire    [2 * 64 - 1:0]              ad_data_d;
wire    [2 * 1  - 1:0]              ad_vld_d;
wire    [2 * 32 - 1:0]              ad_data;
wire    [2 * 1  - 1:0]              ad_vld;
wire    [64*4-1:0]                  ddc_dout_d;
wire    [1*4-1:0]                   ddc_dout_vld_d;
wire    [2 * 1  - 1:0]              ad_wc_fifo_profull;
wire    [2 * 1  - 1:0]              ad_wc_fifo_empty;
wire    [2 * 1  - 1:0]              ad_wc_fifo_profull_d;
wire    [2 * 1  - 1:0]              ad_wc_fifo_empty_d;
wire    [4 * 1  - 1:0]              ddc_fifo_empty_d;
wire    [4 * 1  - 1:0]              ddc_fifo_profull_d;
(* syn_keep="true",mark_debug="true" *)wire    [2 * 1  - 1:0]              alg_jesd_wc_fifo_empty;
(* syn_keep="true",mark_debug="true" *)wire    [2 * 1  - 1:0]              alg_jesd_wc_fifo_profull;
wire                                check_err;
wire    [8 * 1  - 1 : 0]            duc_din_vld;
wire    [8 * 1  - 1 : 0]            duc_din_rdy;
wire    [8 * 1  - 1 : 0]            duc_din_rdy_x;
(* syn_keep="true",mark_debug="true" *)wire    [8 * 1  - 1 : 0]            duc_din_wc_fifo_profull;
(* syn_keep="true",mark_debug="true" *)wire    [8 * 1  - 1 : 0]            duc_din_wc_fifo_empty;
wire    [8 * 32  - 1 : 0]           duc_din;
wire                                da_sysref;
wire    [1:0]                       da_sync;
wire                                tx_core_clk;
wire    [2 * 1  - 1 : 0]            duc_dout_vld;
wire    [2 * 32 - 1 : 0]            duc_dout;

wire    [2 * 1  - 1 : 0]            duc_wc_data_vld;
wire    [4 * 32 - 1 : 0]            duc_wc_data;

wire    [8 * 32 - 1 : 0]            dac2alg_data;
wire    [8 * 1  - 1 : 0]            dac2alg_data_vld;


(* syn_keep="true",mark_debug="true" *)reg 								d_rf_power_en		    	;	
(* syn_keep="true",mark_debug="true" *)reg 								d_rx_zd20e_sck		 		;
(* syn_keep="true",mark_debug="true" *)reg 								d_rx_zd20e_cs				;	 
// (* syn_keep="true",mark_debug="true" *)reg 								d_rx_zd20e_mosi		 		;
(* syn_keep="true",mark_debug="true" *)reg 								d_rx_zd20e_miso		 		;
(* syn_keep="true",mark_debug="true" *)reg 								d_rx_zd20e_full_warm0  		;
(* syn_keep="true",mark_debug="true" *)reg 								d_rx_zd20e_full_warm1  		;
(* syn_keep="true",mark_debug="true" *)reg 								d_tx_zc18_sck				;	 
(* syn_keep="true",mark_debug="true" *)reg 								d_tx_zc18_cs				;	 
// (* syn_keep="true",mark_debug="true" *)reg 								d_tx_zc18_mosi		 		;
(* syn_keep="true",mark_debug="true" *)reg 								d_tx_zc18_miso		 		;


wire                                muf_o_rdy;
wire                                muf_o_vld;
wire                                muf_o_sof;
wire                                muf_o_eof;
wire    [511:0]                     muf_o_data;
wire    [7:0]                       muf_o_info;
wire    [14:0]                      muf_o_len;
wire                                muf_o_end;
wire                                ddr_clk;
wire                                ddr_init_done;
wire    [8 * 1   - 1 : 0]           fout_vld;
wire    [8 * 1   - 1 : 0]           fout_rdy;
wire    [8 * 512 - 1 : 0]           fout_data;
wire    [8 * 1   - 1 : 0]           fout_sof;
wire    [8 * 1   - 1 : 0]           fout_eof;
wire    [8 * 15  - 1 : 0]           fout_len;
wire    [8 * 8   - 1 : 0]           fout_info;
wire    [1 * 512 - 1 : 0]           wchn_data;
wire    [1 * 1   - 1 : 0]           wchn_data_vld;
wire    [1 * 1   - 1 : 0]           wchn_data_rdy;
wire    [1 * 1   - 1 : 0]           wchn_sof;
wire    [1 * 1   - 1 : 0]           wchn_eof;
wire    [1 * 15  - 1 : 0]           wchn_length;
wire    [1 * 8   - 1 : 0]           wchn_rsvd_info;
wire                                pcie_clk_gt;
wire                                user_rst_n;
wire                                user_clk;
wire    [8 * 1   - 1 : 0]           rchn_data_rdy;
wire    [8 * 1   - 1 : 0]           rchn_data_vld;
wire    [8 * 1   - 1 : 0]           rchn_sof;
wire    [8 * 1   - 1 : 0]           rchn_eof;
wire    [8 * 512 - 1 : 0]           rchn_data;
wire    [8 * 64  - 1 : 0]           rchn_keep;
wire    [8 * 15  - 1 : 0]           rchn_len;
wire                                bd_check_err;
wire                                btc_check_err;

(* syn_keep="true",mark_debug="true" *)wire                                flash_data_rdy1;
wire                                flash_data_rdy;
wire                                flash_data_vld;
wire                                flash_sof;
wire                                flash_eof;
wire    [511:0]                     flash_data;
wire    [63:0]                      flash_keep;
wire    [14:0]                      flash_len;
wire                                bd_utc_chok;
wire                                bcode_chok;
wire                                sys_ms_flg;
wire    [63:0]                      stamp;

wire    [11:0]                      bd_rtc_year;
wire    [3:0]                       bd_rtc_month;
wire    [4:0]                       bd_rtc_day;
wire    [4:0]                       bd_rtc_hour;
wire    [5:0]                       bd_rtc_min;
wire    [5:0]                       bd_rtc_sec;
wire    [9:0]                       bd_rtc_msec;
wire    [9:0]                       bd_rtc_microsec;
wire    [9:0]                       bd_rtc_nanosec;
wire                                bd_rtc_timing_1s;
wire    [11:0]                      btc_rtc_year;
wire    [8:0]                       btc_rtc_day;
wire    [4:0]                       btc_rtc_hour;
wire    [5:0]                       btc_rtc_min;
wire    [5:0]                       btc_rtc_sec;
wire    [9:0]                       btc_rtc_msec;
wire    [9:0]                       btc_rtc_microsec;
wire    [9:0]                       btc_rtc_nanosec;
wire                                btc_rtc_timing_1s;
wire    [11:0]                      new_rtc_year;
wire    [8:0]                       new_rtc_day;
wire    [4:0]                       new_rtc_hour;
wire    [5:0]                       new_rtc_min;
wire    [5:0]                       new_rtc_sec;
wire    [9:0]                       new_rtc_msec;
wire    [9:0]                       new_rtc_microsec;
wire    [9:0]                       new_rtc_nanosec;

wire                                pcie_link;
wire    [15:0]                      mefc_odata;
wire                                mefc_ovld;
wire                                mefc_ordy;
(* syn_keep="true",mark_debug="true" *)wire                                mefc_ordy1;
wire    [15:0]                      read_data;
wire                                read_vld;
wire    [32*4-1:0]                  ddc_dout;
wire    [1*4-1:0]                   ddc_dout_vld;
wire                                dac_clk;
wire                                dac_double_clk;
wire                                sys_rst;

wire    [31:0]                      cpu_u_clk;
wire    [31:0]                      cpu_u_rst;
wire    [31:0]                      cpu_u_cs;
wire    [31:0]                      cpu_u_we;
wire    [31:0]                      cpu_u_rd;
wire    [415:0]                     cpu_u_addr;
wire    [1023:0]                    cpu_u_wdata;
wire    [1023:0]                    cpu_u_rdata;

wire                                r_rd_en;
wire                                r_wr_en;
wire    [18:0]                      r_addr;
wire    [31:0]                      r_wr_data;
wire    [31:0]                      r_rd_data;

wire                                cs_base;
wire                                we_base;
wire                                rd_base;
wire    [12:0]                      addr_base;
wire    [31:0]                      wdata_base;
wire    [31:0]                      rdata_base;

wire                                pcie_cs;
wire                                pcie_rd;
wire                                pcie_we;
wire    [12:0]                      pcie_addr;
wire    [31:0]                      pcie_wdata;
wire    [31:0]                      pcie_rdata; 

wire                                ddr_cs;
wire                                ddr_rd;
wire                                ddr_we;
wire    [12:0]                      ddr_addr;
wire    [31:0]                      ddr_wdata;
wire    [31:0]                      ddr_rdata; 

wire                                muf_cs;
wire                                muf_rd;
wire                                muf_we;
wire    [12:0]                      muf_addr;
wire    [31:0]                      muf_wdata;
wire    [31:0]                      muf_rdata;

wire                                mefc_cs;
wire                                mefc_rd;
wire                                mefc_we;
wire    [12:0]                      mefc_addr;
wire    [31:0]                      mefc_wdata;
wire    [31:0]                      mefc_rdata;

wire                                fill_cs         [4:0];
wire                                fill_rd         [4:0];
wire                                fill_we         [4:0];
wire    [12:0]                      fill_addr       [4:0];
wire    [31:0]                      fill_wdata      [4:0];

wire    [6:0]                       spi_cs;
wire    [6:0]                       spi_rd;
wire    [6:0]                       spi_we;
wire    [13*7-1:0]                  spi_addr;
wire    [32*7-1:0]                  spi_wdata;
wire    [32*7-1:0]                  spi_rdata;

wire    [1 * 1  -1:0]               lvds_cs;
wire    [1 * 1  -1:0]               lvds_we;
wire    [1 * 1  -1:0]               lvds_rd;
wire    [1 * 13 -1:0]               lvds_addr;
wire    [1 * 32 -1:0]               lvds_wdata;
wire    [1 * 32 -1:0]               lvds_rdata;

wire    [1 * 1  -1:0]               jesd_cs;
wire    [1 * 1  -1:0]               jesd_we;
wire    [1 * 1  -1:0]               jesd_rd;
wire    [1 * 13 -1:0]               jesd_addr;
wire    [1 * 32 -1:0]               jesd_wdata; 
wire    [1 * 32 -1:0]               jesd_rdata;

wire    [3:0]                       i2c_cs;
wire    [3:0]                       i2c_rd;
wire    [3:0]                       i2c_we;
wire    [13*4-1:0]                  i2c_addr;
wire    [32*4-1:0]                  i2c_wdata;
wire    [32*3-1:0]                  i2c_rdata;

wire    [3:0]                       uart_cs;
wire    [3:0]                       uart_rd;
wire    [3:0]                       uart_we;
wire    [13*4-1:0]                  uart_addr;
wire    [32*4-1:0]                  uart_wdata;
wire    [32*1-1:0]                  uart_rdata;

wire    [1:0]                       alg_cs;
wire    [1:0]                       alg_rd;
wire    [1:0]                       alg_we;
wire    [13*2-1:0]                  alg_addr;
wire    [32*2-1:0]                  alg_wdata;
wire    [32*1-1:0]                  alg_rdata;

wire                                add_noise_cs;
wire                                add_noise_we;
wire                                add_noise_rd;
wire    [12:0]                      add_noise_addr;
wire    [31:0]                      add_noise_wdata;
wire    [31:0]                      add_noise_rdata;

wire                                btc_cs;
wire                                btc_rd;
wire                                btc_we;
wire    [12:0]                      btc_addr;
wire    [31:0]                      btc_wdata;
wire    [31:0]                      btc_rdata;

wire                                bd_cs;
wire                                bd_rd;
wire                                bd_we;
wire    [12:0]                      bd_addr;
wire    [31:0]                      bd_wdata;
wire    [31:0]                      bd_rdata;

wire                                lvds_wc_rst;
wire                                da_wc_fifo_rst;


//clock 
sys_clk_wiz u_sys_clk_wiz_inst(
    .clk_50m                    (clk_50m                    ),
    .clk_100m                   (clk_100m                   ),
    .clk_150m                   (clk_150m                   ),
    .clk_200m                   (clk_200m                   ),
    .locked                     (sys_locked                 ),
    .clk_in1_p                  (sys_clk_p                  ),//100m
    .clk_in1_n                  (sys_clk_n                  )
);
DAC_division u_DAC_division
(
	.clk_out1		(dac_double_clk),
	.reset			(~da_dual_sync),
	.locked			(locked_dac),
	.clk_in1		(dac_clk)
);	

// AD_division u_AD_division
// (
	// .clk_out1		(ad_clk_half),
	// .reset			(1'b0),
	// .locked			(locked_ad),
	// .clk_in1		(ad_clk)
// );	


assign hard_rst          = ~sys_locked;
assign rst               = hard_rst|soft_rst;
assign sys_rst           = rst;
assign reserved_cur_0alm = {10'b0,rx_zd20e_full_warm0,rx_zd20e_full_warm1,bd_check_err,btc_check_err,dac2alg_data_vld,duc_din_rdy_x,ddr_init_done ,pcie_link};
assign reserved_cur_1alm = {12'b0,locked_ad,bd_utc_chok,bcode_chok,locked_dac,fout_vld,fout_rdy};
assign reserved_his_0alm = {10'd0,rx_zd20e_full_warm0,rx_zd20e_full_warm1,alg_jesd_wc_fifo_empty,alg_jesd_wc_fifo_profull,duc_din_wc_fifo_empty ,duc_din_wc_fifo_profull};
assign reserved_his_1alm = 32'b0;

//device hard reset pin
assign pll_ad9516_reset_pin     =   1'b1;

assign fmc_ad_pll_pwr_ctrl      =   reserevd_0cfg[0];
assign fmc_ad_pll_sel           =   reserevd_0cfg[1];
assign pll_hmc7044_reset_pin    =   reserevd_0cfg[2];
assign dac_ad9172_reset_pin     =   ~reserevd_0cfg[3];
assign rf_power_en     			=   ~reserevd_0cfg[7];

//logic config
assign da_chn0_en               =  ~reserevd_3cfg[2];
assign da_chn1_en               =  ~reserevd_3cfg[3];
assign btc_rx_en                =   reserevd_3cfg[4];
assign btc_1pps_en              =   reserevd_3cfg[5];

// assign v7_12v_en                = 1'b1;


IBUFDS_GTE2 refclk_ibuf 
(
    .O                          (pcie_clk_gt                ), 
    .ODIV2                      (/*not used*/               ),
    .I                          (pcie_clk_p                 ), 
    .CEB                        (1'b0                       ), 
    .IB                         (pcie_clk_n                 )
);

pcie_app_gen3_belta   u_pcie_app_gen3_belta(
    .ref_clk                    (pcie_clk_gt                ),
    .ref_reset_n                (pcie_rst_n                 ),
    .sys_clk                    (clk_100m                   ),
    .sys_rst_n                  (~hard_rst                  ),
    .user_clk                   (user_clk                   ),
    .user_rst_n                 (user_rst_n                 ),
    .rtc_s_flg                  (timing_1s                  ),
    .rtc_us_flg                 (timing_1us                 ),

    .pci_exp_txn                (pci_exp_txn                ),
    .pci_exp_txp                (pci_exp_txp                ),
    .pci_exp_rxn                (pci_exp_rxn                ),
    .pci_exp_rxp                (pci_exp_rxp                ),
    .pcie_link                  (pcie_link                  ),
//local bus
    .r_wr_en                    (r_wr_en                    ),
    .r_addr                     (r_addr                     ),
    .r_wr_data                  (r_wr_data                  ),
    .r_rd_en                    (r_rd_en                    ),
    .r_rd_data                  (r_rd_data                  ),
//CIB
    .pcie_cs                    (pcie_cs                    ),
    .pcie_wr                    (pcie_we                    ),
    .pcie_rd                    (pcie_rd                    ),
    .pcie_addr                  (pcie_addr[7:0]             ),
    .pcie_wr_data               (pcie_wdata                 ),
    .pcie_rd_data               (pcie_rdata                 ),
//MDMA USER Interface
    .rchn_clk                   ({{(8){clk_100m}}   ,clk_100m       }),
    .rchn_rst_n                 ({{(8){~rst}}       ,~rst           }),
    .rchn_data_rdy              ({rchn_data_rdy     ,flash_data_rdy1 }),
    .rchn_data_vld              ({rchn_data_vld     ,flash_data_vld }),
    .rchn_sof                   ({rchn_sof          ,flash_sof      }),
    .rchn_eof                   ({rchn_eof          ,flash_eof      }),
    .rchn_data                  ({rchn_data         ,flash_data     }),
    .rchn_keep                  ({rchn_keep         ,flash_keep     }),
    .rchn_length                ({rchn_len          ,flash_len      }),

    .wchn_clk                   (clk_100m                   ),
    .wchn_rst_n                 (~rst                       ),
    .wchn_data_rdy              (wchn_data_rdy              ),
    .wchn_data_vld              (wchn_data_vld              ),
    .wchn_sof                   (wchn_sof                   ),
    .wchn_eof                   (wchn_eof                   ),
    .wchn_data                  (wchn_data                  ),
    .wchn_end                   (wchn_rsvd_info[4]          ),
    .wchn_keep                  (64'd0                      ),
    .wchn_length                (wchn_length[14:0]          ),
    .wchn_chn                   (wchn_rsvd_info[3:0]        )
);

cpu_alloc_32users u_cpu_alloc(
    .cpu_clk                    (user_clk                   ),
    .cpu_rst                    (~user_rst_n                ),
    .cpu_cs                     (1'b0                       ),
    .cpu_rd                     (r_rd_en                    ),
    .cpu_we                     (r_wr_en                    ),
    .cpu_addr                   (r_addr[14:2]               ),
    .cpu_wdata                  (r_wr_data                  ),
    .cpu_rdata                  (r_rd_data                  ),
    .cpu_u_clk                  (cpu_u_clk                  ),
    .cpu_u_rst                  (cpu_u_rst                  ),
    .cpu_u_cs                   (cpu_u_cs                   ),
    .cpu_u_we                   (cpu_u_we                   ),
    .cpu_u_rd                   (cpu_u_rd                   ),
    .cpu_u_addr                 (cpu_u_addr                 ),
    .cpu_u_wdata                (cpu_u_wdata                ),
    .cpu_u_rdata                (cpu_u_rdata                )
);   

//cpu allocation
//LOW
assign cpu_u_clk[15:0]           ={clk_100m         ,clk_100m       ,clk_100m       ,clk_100m   ,{(7){clk_100m}}  ,clk_100m   ,clk_100m   ,clk_100m ,clk_100m  ,clk_100m  }; 
assign cpu_u_rst[15:0]           ={hard_rst         ,hard_rst       ,hard_rst       ,hard_rst   ,{(7){hard_rst}}  ,hard_rst   ,hard_rst   ,hard_rst ,hard_rst  ,hard_rst  };   
assign                            {fill_cs[0]       ,lvds_cs        ,fill_cs[1]     ,jesd_cs    ,spi_cs           ,mefc_cs    ,muf_cs     ,ddr_cs   ,pcie_cs   ,cs_base   }=cpu_u_cs[15:0];    
assign                            {fill_rd[0]       ,lvds_we        ,fill_rd[1]     ,jesd_we    ,spi_we           ,mefc_we    ,muf_we     ,ddr_we   ,pcie_we   ,we_base   }=cpu_u_we[15:0];    
assign                            {fill_we[0]       ,lvds_rd        ,fill_we[1]     ,jesd_rd    ,spi_rd           ,mefc_rd    ,muf_rd     ,ddr_rd   ,pcie_rd   ,rd_base   }=cpu_u_rd[15:0];   
assign                            {fill_addr[0]     ,lvds_addr      ,fill_addr[1]   ,jesd_addr  ,spi_addr         ,mefc_addr  ,muf_addr   ,ddr_addr ,pcie_addr ,addr_base }=cpu_u_addr[16*13-1:0];  
assign                            {fill_wdata[0]    ,lvds_wdata     ,fill_wdata[1]  ,jesd_wdata ,spi_wdata        ,mefc_wdata ,muf_wdata  ,ddr_wdata,pcie_wdata,wdata_base}=cpu_u_wdata[16*32-1:0];  
assign cpu_u_rdata[16*32-1:0]    ={32'b0            ,lvds_rdata     ,32'b0          ,jesd_rdata ,spi_rdata        ,mefc_rdata ,muf_rdata  ,ddr_rdata,pcie_rdata,rdata_base}; 
//HIGH
assign cpu_u_clk[31:16]          ={{(2){clk_100m}}              ,clk_100m ,clk_100m ,clk_100m       ,clk_100m           ,{(2){clk_50m}}        ,{(4){clk_100m}}   ,{(4){clk_100m}}  }; 
assign cpu_u_rst[31:16]          ={{(2){hard_rst}}              ,hard_rst ,hard_rst ,hard_rst       ,hard_rst           ,{(2){hard_rst}}        ,{(4){hard_rst}}   ,{(4){hard_rst}}  };   
assign                            {{fill_cs[2],fill_cs[3]}      ,bd_cs    ,btc_cs   ,fill_cs[4]     ,add_noise_cs       ,alg_cs                 ,uart_cs           ,i2c_cs           }=cpu_u_cs[31:16];    
assign                            {{fill_rd[2],fill_rd[3]}      ,bd_we    ,btc_we   ,fill_rd[4]     ,add_noise_we       ,alg_we                 ,uart_we           ,i2c_we           }=cpu_u_we[31:16];    
assign                            {{fill_we[2],fill_we[3]}      ,bd_rd    ,btc_rd   ,fill_we[4]     ,add_noise_rd       ,alg_rd                 ,uart_rd           ,i2c_rd           }=cpu_u_rd[31:16];   
assign                            {{fill_addr[2],fill_addr[3]}  ,bd_addr  ,btc_addr ,fill_addr[4]   ,add_noise_addr     ,alg_addr               ,uart_addr         ,i2c_addr         }=cpu_u_addr[32*13-1:16*13];  
assign                            {{fill_wdata[2],fill_wdata[3]},bd_wdata ,btc_wdata,fill_wdata[4]  ,add_noise_wdata    ,alg_wdata              ,uart_wdata        ,i2c_wdata        }=cpu_u_wdata[32*32-1:16*32];  
assign cpu_u_rdata[32*32-1:16*32]={64'b0                        ,bd_rdata ,32'd0    ,32'b0          ,add_noise_rdata    ,{32'b0,alg_rdata[31:0]},{128'd0}          ,{32'b0,i2c_rdata}}; 


general_func_7s u_general_func_7s(
    .clk                        (clk_100m                   ),
    .rst                        (rst                        ),
    .int_i                      (32'd0                      ),
    .int_pin                    (                           ),
    .logic_id                   (LOGIC_ID                   ),
    .version                    (VERSION                    ),
    .timing_1us                 (timing_1us                 ),
    .timing_1ms                 (timing_1ms                 ),
    .timing_1s                  (timing_1s                  ),
    .cpu_cs                     (cs_base                    ),
    .cpu_rd                     (rd_base                    ),
    .cpu_we                     (we_base                    ),
    .cpu_addr                   (addr_base[7:0]             ),
    .cpu_wdata                  (wdata_base                 ),
    .cpu_rdata                  (rdata_base                 ),
    .hard_rst                   (hard_rst                   ),
    .soft_rst                   (soft_rst                   ),
    .device_temp                (device_temp                ),
    .authorize_code             (authorize_code             ),
    .icap_pulse                 (1'b0                       ),
    .icap_sel                   (2'b0                       ),
    .reserved_cur_0alm          (reserved_cur_0alm          ),
    .reserved_cur_1alm          (reserved_cur_1alm          ),
    .reserved_his_0alm          (reserved_his_0alm          ),
    .reserved_his_1alm          (reserved_his_1alm          ),
    .reserevd_0cfg              (reserevd_0cfg              ),
    .reserevd_1cfg              (reserevd_1cfg              ),
    .reserevd_2cfg              (reserevd_2cfg              ),
    .reserevd_3cfg              (reserevd_3cfg              )
);

spi_common u_spi_pllad9516_inst(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),

    .cpu_cs                     (spi_cs[0]                  ),
    .cpu_wr                     (spi_we[0]                  ),
    .cpu_rd                     (spi_rd[0]                  ),
    .cpu_addr                   (spi_addr[0*13+:8]          ),
    .cpu_wr_data                (spi_wdata[0*32+:32]        ),
    .cpu_rd_data                (spi_rdata[0*32+:32]        ),

    .sck                        (pll_ad9516_sck             ),
    .ss_n                       (pll_ad9516_cs              ),
    .mosi                       (pll_ad9516_mosi            ),
    .miso                       (pll_ad9516_miso            )
);

spi_common u_spi_adc_a9467_1_inst(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),

    .cpu_cs                     (spi_cs[1]                  ),
    .cpu_wr                     (spi_we[1]                  ),
    .cpu_rd                     (spi_rd[1]                  ),
    .cpu_addr                   (spi_addr[1*13+:8]          ),
    .cpu_wr_data                (spi_wdata[1*32+:32]        ),
    .cpu_rd_data                (spi_rdata[1*32+:32]        ),

    .sck                        (adc_a9467_1_sck            ),
    .ss_n                       (adc_a9467_1_cs             ),
    .mosi                       (adc_a9467_1_mosi           ),
    .miso                       (adc_a9467_1_miso           )
);

spi_common u_spi_adc_a9467_2_inst(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),

    .cpu_cs                     (spi_cs[2]                  ),
    .cpu_wr                     (spi_we[2]                  ),
    .cpu_rd                     (spi_rd[2]                  ),
    .cpu_addr                   (spi_addr[2*13+:8]          ),
    .cpu_wr_data                (spi_wdata[2*32+:32]        ),
    .cpu_rd_data                (spi_rdata[2*32+:32]        ),

    .sck                        (adc_a9467_2_sck            ),
    .ss_n                       (adc_a9467_2_cs             ),
    .mosi                       (adc_a9467_2_mosi           ),
    .miso                       (adc_a9467_2_miso           )
);

spi_common u_spi_pllhmc7044_inst(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),

    .cpu_cs                     (spi_cs[3]                  ),
    .cpu_wr                     (spi_we[3]                  ),
    .cpu_rd                     (spi_rd[3]                  ),
    .cpu_addr                   (spi_addr[3*13+:8]          ),
    .cpu_wr_data                (spi_wdata[3*32+:32]        ),
    .cpu_rd_data                (spi_rdata[3*32+:32]        ),

    .sck                        (pll_hmc7044_sck             ),
    .ss_n                       (pll_hmc7044_cs              ),
    .mosi                       (pll_hmc7044_mosi            ),
    .miso                       (pll_hmc7044_miso            )
);

spi_common u_spi_dac_ad9172_inst(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),

    .cpu_cs                     (spi_cs[4]                  ),
    .cpu_wr                     (spi_we[4]                  ),
    .cpu_rd                     (spi_rd[4]                  ),
    .cpu_addr                   (spi_addr[4*13+:8]          ),
    .cpu_wr_data                (spi_wdata[4*32+:32]        ),
    .cpu_rd_data                (spi_rdata[4*32+:32]        ),

    .sck                        (dac_ad9172_sck             ),
    .ss_n                       (dac_ad9172_cs              ),
    .mosi                       (dac_ad9172_mosi            ),
    .miso                       (dac_ad9172_miso            )
);

spi_common u_spi_rx_zd20e_inst(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),

    .cpu_cs                     (spi_cs[5]                  ),
    .cpu_wr                     (spi_we[5]                  ),
    .cpu_rd                     (spi_rd[5]                  ),
    .cpu_addr                   (spi_addr[5*13+:8]          ),
    .cpu_wr_data                (spi_wdata[5*32+:32]        ),
    .cpu_rd_data                (spi_rdata[5*32+:32]        ),

    .sck                        (rx_zd20e_sck               ),
    .ss_n                       (rx_zd20e_cs                ),
    .mosi                       (rx_zd20e_mosi              ),
    .miso                       (rx_zd20e_miso              )
);

spi_common u_spi_tx_zc18_inst(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),

    .cpu_cs                     (spi_cs[6]                  ),
    .cpu_wr                     (spi_we[6]                  ),
    .cpu_rd                     (spi_rd[6]                  ),
    .cpu_addr                   (spi_addr[6*13+:8]          ),
    .cpu_wr_data                (spi_wdata[6*32+:32]        ),
    .cpu_rd_data                (spi_rdata[6*32+:32]        ),

    .sck                        (tx_zc18_sck                ),
    .ss_n                       (tx_zc18_cs                 ),
    .mosi                       (tx_zc18_mosi               ),
    .miso                       (tx_zc18_miso               )
);

always@(posedge clk_100m or posedge rst)begin
	if(rst==1'b1)begin
	d_rf_power_en		    <= 'b0;
	d_rx_zd20e_sck		 	<= 'b0;
	d_rx_zd20e_cs			<= 'b0;
	// d_rx_zd20e_mosi		 	<= 'b0;
	d_rx_zd20e_miso		 	<= 'b0;
	d_rx_zd20e_full_warm0  	<= 'b0;
	d_rx_zd20e_full_warm1  	<= 'b0;
	d_tx_zc18_sck			<= 'b0;
	d_tx_zc18_cs			<= 'b0;
	// d_tx_zc18_mosi		 	<= 'b0;
	d_tx_zc18_miso		 	<= 'b0;
	end
	else begin
	d_rf_power_en		    <= rf_power_en		    ;
	d_rx_zd20e_sck		 	<= rx_zd20e_sck		 	;
	d_rx_zd20e_cs			<= rx_zd20e_cs			;
	// d_rx_zd20e_mosi		 	<= rx_zd20e_mosi		; 	
	d_rx_zd20e_miso		 	<= rx_zd20e_miso		; 	
	d_rx_zd20e_full_warm0  	<= rx_zd20e_full_warm0  ;	
	d_rx_zd20e_full_warm1  	<= rx_zd20e_full_warm1  ;	
	d_tx_zc18_sck			<= tx_zc18_sck			;
	d_tx_zc18_cs			<= tx_zc18_cs			;
	// d_tx_zc18_mosi		 	<= tx_zc18_mosi		 	;
	d_tx_zc18_miso		 	<= tx_zc18_miso		 	;
	end
end

i2c_master_top i2c_master_top_inst_master
(
    .clk                        (clk_100m                   ),
    .rst                        (rst                        ),
    .hard_rst                   (hard_rst                   ),

    .authorize_code             (authorize_code             ),

    .sda                        (sda_master                 ),
    .scl                        (scl_master                 ),

    .cpu_cs                     (i2c_cs[0]                  ),
    .cpu_we                     (i2c_we[0]                  ),
    .cpu_rd                     (i2c_rd[0]                  ),
    .cpu_addr                   (i2c_addr[0*13+:8]          ),
    .cpu_wdata                  (i2c_wdata[0*32+:32]        ),
    .cpu_rdata                  (i2c_rdata[0*32+:32]        )
);
i2c_master_top i2c_master_top_inst_fmc0
(
    .clk                        (clk_100m                   ),
    .rst                        (rst                        ),
    .hard_rst                   (hard_rst                   ),

    .authorize_code             (authorize_code             ),

    .sda                        (sda_fmc0                   ),
    .scl                        (scl_fmc0                   ),

    .cpu_cs                     (i2c_cs[1]                  ),
    .cpu_we                     (i2c_we[1]                  ),
    .cpu_rd                     (i2c_rd[1]                  ),
    .cpu_addr                   (i2c_addr[1*13+:8]          ),
    .cpu_wdata                  (i2c_wdata[1*32+:32]        ),
    .cpu_rdata                  (i2c_rdata[1*32+:32]        )
);
i2c_master_top i2c_master_top_inst_fmc1
(
    .clk                        (clk_100m                   ),
    .rst                        (rst                        ),
    .hard_rst                   (hard_rst                   ),

    .authorize_code             (authorize_code             ),

    .sda                        (sda_fmc1                   ),
    .scl                        (scl_fmc1                   ),

    .cpu_cs                     (i2c_cs[2]                  ),
    .cpu_we                     (i2c_we[2]                  ),
    .cpu_rd                     (i2c_rd[2]                  ),
    .cpu_addr                   (i2c_addr[2*13+:8]          ),
    .cpu_wdata                  (i2c_wdata[2*32+:32]        ),
    .cpu_rdata                  (i2c_rdata[2*32+:32]        )
);

/* --------------------------------- LVDS RX -------------------------------- */

lvds_7k_top u_lvds_7k_top_chip(

    .lvds_clk_p                (lvds_clk_p                  ),
    .lvds_clk_n                (lvds_clk_n                  ),

    .lvds_data_p               (lvds_data_p                 ),
    .lvds_data_n               (lvds_data_n                 ),

    .rst                       (sys_rst                     ),
    .hard_rst                  (hard_rst                    ),
    
    //config idelay value
    .cpu_cs                    (lvds_cs                     ),
    .cpu_wr                    (lvds_we                     ),
    .cpu_rd                    (lvds_rd                     ),
    .cpu_addr                  (lvds_addr[7:0]              ),//match width
    .cpu_wr_data               (lvds_wdata                  ),
    .cpu_rd_data               (lvds_rdata                  ),

    .clk_200m                  (clk_200m                    ),//for idelayctrl
    .clk_100m                  (clk_100m                    ),
    .ad_clk                    (ad_clk                      ),
    .ad_data                   (lvds_out_ad_data            ),
    .ad_vld                    (lvds_out_ad_vld             ),

    .sys_ms_flg                (timing_1ms                  )
);

always@(posedge ad_clk or posedge rst)begin
	if(rst == 1'b1)
		bypass_en_r <= #U_DLY 'b0;
	else
		bypass_en_r <= #U_DLY {bypass_en_r[1:0],reserevd_0cfg[6]};
end
	
bpf_top u_bpf_top(
.sys_clk		(ad_clk				),
.sys_rst        (sys_rst			),
.data_din       (lvds_out_ad_data	),//[31:0]	
.data_din_vld   (lvds_out_ad_vld	),//[1:0]	
.data_dout      (bpf_data_out		),//[31:0]	
.data_dout_vld  (bpf_data_out_vld	),//[1:0]	
.bypass_en      (bypass_en_r[2]		)
);

add_noise_top u_add_noise_top_inst(
    .clk_sys                   (ad_clk                      ),   //  input clk_sys;
    .clk_cib                   (clk_100m                    ),   //  input clk_cib;
    .rst_sys                   (sys_rst                     ),   //  input rst_sys;
    .cpu_cs                    (add_noise_cs                ),   //  input cpu_cs;
    .cpu_we                    (add_noise_we                ),   //  input cpu_we;
    .cpu_rd                    (add_noise_rd                ),   //  input cpu_rd;
    .cpu_addr                  (add_noise_addr[7:0]         ),   //  input [7:0]cpu_addr;
    .cpu_wdata                 (add_noise_wdata             ),   //  input [31:0]cpu_wdata;
    .cpu_rdata                 (add_noise_rdata             ),   //  output [31:0]cpu_rdata;
    .data_in                   (bpf_data_out            	),   //  input [31:0]data_in;
    .data_in_vld               (bpf_data_out_vld           	),   //  input [1:0]data_in_vld;
    .data_out                  (ad_addNoise_data_out        ),   //  output [31:0]data_out;
    .data_out_vld              (ad_addNoise_data_out_vld    )   //  output [1:0]data_out_vld;
);

genvar n;
generate 
    for(n=0;n<2;n=n+1) begin : AD_LVDS_WC
        bit_convert # (
            .U_DLY                      (1                              ),
            .WIDTH_INPUT                (16                             ),

            .WIDTH_OUTPUT               (64                             )
        ) u_lvds_wc_16to32 (
            .WC_in_clk                  (ad_clk                         ),
            .rst                        (sys_rst                       	),
            .WC_in_data                 (ad_addNoise_data_out[n*16+:16] ),
            .WC_in_vld                  (ad_addNoise_data_out_vld[n]    ),
            .WC_out_data                (ad_data_d[n*64+:64]              ),
            .WC_out_vld                 (ad_vld_d[n]                  	)
        );
    end
endgenerate


genvar k;
generate 
    for(k=0;k<4;k=k+1) begin : ddc_d_freq
        bit_convert # (
            .U_DLY                      (1                              ),
            .WIDTH_INPUT                (32                             ),
            .WIDTH_OUTPUT               (64                             )
        ) u_ddc_32to64 (
            .WC_in_clk                  (ad_clk                         ),
            .rst                        (sys_rst                       	),
            .WC_in_data                 (ddc_dout[k*32+:32] ),
            .WC_in_vld                  (ddc_dout_vld[k]    ),
            .WC_out_data                (ddc_dout_d[k*64+:64]            ),
            .WC_out_vld                 (ddc_dout_vld_d[k]          	)
        );
    end
endgenerate

/* --------------------------------- JESD TX -------------------------------- */
IBUFDS #(
    .DQS_BIAS("FALSE") 
)
IBUFDS_sysref_tx (
    .O                          (da_sysref                  ),
    .I                          (jesd_sys_ref_p             ),
    .IB                         (jesd_sys_ref_n             )
);

IBUFDS #(
    .DQS_BIAS("FALSE") 
)
IBUFDS_sync0_tx (
    .O                          (da_sync[0]                 ),
    .I                          (jesd_sync0_p               ),
    .IB                         (jesd_sync0_n               )
);

IBUFDS #(
    .DQS_BIAS("FALSE") 
)
IBUFDS_sync1_tx (
    .O                          (da_sync[1]                 ),
    .I                          (jesd_sync1_p               ),
    .IB                         (jesd_sync1_n               )
);

wire da_dual_sync;
assign da_dual_sync = (da_sync[0] == 1'b1 && da_sync[1] == 1'b1) ? 1'b1 : 1'b0;

genvar alg_jesd_wc;
generate
    for (alg_jesd_wc = 0 ;alg_jesd_wc < 2 ;alg_jesd_wc = alg_jesd_wc + 1 ) begin : ALG2JESD_WC
        width_conversion_S2B # (
            .U_DLY                      (1                              ),
            .WIDTH_INPUT                (32                             ),
            .WIDTH_OUTPUT               (64                             ),
            .RAM_STYLE                  ("block"                        ),
            .FIFO_DEEPTH                (32                             ),
            .FIFO_PROG_FULL_THRESH      (16                             ),
            .FIFO_PROG_EMPTY_THRESH     (2                              )
        ) u_lvds_wc_16to32 (
            .WC_in_clk                  (dac_double_clk            		),
            .WC_out_clk                 (dac_clk                        ),
            .rst                        (hard_rst                       ),
            .WC_in_data                 (duc_dout[alg_jesd_wc*32+:32]   ),
            .WC_in_vld                  (duc_dout_vld[alg_jesd_wc]      ),
            .WC_in_rdy                  (/*not used*/                   ),
            .WC_out_data                (duc_wc_data[alg_jesd_wc*64+:64]),
            .WC_out_vld                 (duc_wc_data_vld[alg_jesd_wc]   ),
            .WC_out_rdy                 (1'b1                           ),
            .WC_fifo_empty              (alg_jesd_wc_fifo_empty[alg_jesd_wc]  ),
            .WC_fifo_prog_full          (alg_jesd_wc_fifo_profull[alg_jesd_wc])
        );
    end
endgenerate


jesd_tx_top u_jesd_tx_top(
    .clk_100m                   (clk_100m                   ),
    .soft_rst                   (sys_rst                    ),
    .hard_rst                   (hard_rst                   ),
    .timing_1s                  (timing_1s                  ),
    .authorize_code             (authorize_code             ),

    .refclk_p                   (jesd_refclk_p              ),
    .refclk_n                   (jesd_refclk_n              ),
    .glblclk_p                  (jesd_glblclkp              ),
    .glblclk_n                  (jesd_glblclkn              ),
    .tx_sysref                  (da_sysref                  ),
    .tx_sync                    (da_dual_sync               ),
    .txp                        (jesd_txp                   ),
    .txn                        (jesd_txn                   ),
// data input
    .tx_core_clk                (dac_clk                    ),//93.33333m
    .c0_dvld_in                 (duc_wc_data_vld[0]         ),
    .c0_data_in                 (duc_wc_data[32*0+:32]      ),
    .c1_dvld_in                 (duc_wc_data_vld[0]         ),
    .c1_data_in                 (duc_wc_data[32*1+:32]      ),
    .c2_dvld_in                 (duc_wc_data_vld[1]         ),
    .c2_data_in                 (duc_wc_data[32*2+:32]      ),
    .c3_dvld_in                 (duc_wc_data_vld[1]         ),
    .c3_data_in                 (duc_wc_data[32*3+:32]      ),
// local bus signals
    .cpu_clk                    (clk_100m                   ),//I
    .cpu_cs                     (jesd_cs                    ),//I
    .cpu_we                     (jesd_we                    ),
    .cpu_rd                     (jesd_rd                    ),//I
    .cpu_addr                   (jesd_addr[7:0]             ),//I
    .cpu_wdata                  (jesd_wdata                 ),//I
    .cpu_rdata                  (jesd_rdata                 ) //O
);


`ifdef ALG_EN
bhd_c720_ddc_duc_top u_bhd_c720_ddc_duc_top_inst(
    .adc_clk                    (ad_clk                     ),  //  input adc_clk;
    .dac_clk                    (dac_double_clk         	),  //  input dac_clk;
    .cib_clk                    (clk_50m                   ),  //  input cib_clk;
    .hard_rst                   (hard_rst                   ),  //  input hard_rst;
    .soft_rst                   (soft_rst                   ),  //  input soft_rst;
    .cpu_cs                     (alg_cs[0]                  ),  //  input cpu_cs;
    .cpu_we                     (alg_we[0]                  ),  //  input cpu_we;
    .cpu_rd                     (alg_rd[0]                  ),  //  input cpu_rd;
    .cpu_addr                   (alg_addr[7:0]              ),  //  input [7:0]cpu_addr;
    .cpu_wdata                  (alg_wdata[31:0]            ),  //  input [31:0]cpu_wdata;
    .cpu_rdata                  (alg_rdata[31:0]            ),  //  output [31:0]cpu_rdata;
    .sample_rate                (samp_rate                  ),  //  input [31:0]sample_rate;
    .cur_time_cnt               (samp_cnt                   ),  //  input [31:0]cur_time_cnt;
    .rtc_stamp                  (stamp_2r                   ),  //  input [63:0]rtc_stamp;
    .b_sample_rate              (                           ),  //  output [31:0]b_sample_rate;
    .b_cur_time_cnt             (                           ),  //  output [31:0]b_cur_time_cnt;
    .b_stamp                    (                           ),  //  output [63:0]b_stamp;
    .adc_din_vld                (ad_addNoise_data_out_vld   ),  //  input [1:0]adc_din_vld;
    .adc_din                    (ad_addNoise_data_out       ),  //  input [31:0]adc_din;
    .ddc_dout_vld               (ddc_dout_vld               ),  //  output [3:0]ddc_dout_vld;
    .ddc_dout                   (ddc_dout                   ),  //  output [127:0]ddc_dout;
    .dac_din_vld                (dac2alg_data_vld           ),  //  input [7:0]dac_din_vld;
    .dac_din                    (dac2alg_data               ),  //  input [255:0]dac_din;
    .dac_din_rdy                (duc_din_rdy                ),  //  output [7:0]dac_din_rdy;
    .duc_dout_vld               (duc_dout_vld               ),  //  output [1:0]duc_dout_vld;
    .duc_dout                   (duc_dout                   )   //  output [63:0]duc_dout;
);

`else
assign ddc_dout        = 128'b0;
assign ddc_dout_vld    = 4'b0;

assign duc_din_rdy     = 8'b11111111;
assign duc_dout         = dac2alg_data;
assign duc_dout_vld     = dac2alg_data_vld;
`endif

//================================data mult
wire    [6*8-1:0]      multif_indata_info;
genvar i;
generate 
    for(i=0;i<6;i=i+1)
    begin
        assign multif_indata_info[i*8+:8] = i;
    end
endgenerate

multif_top u_multif_top(
    .clk_adc_w                  (ad_clk                     ),
    .clk_h                      (clk_100m                   ),
    .clk_r                      (clk_100m                   ),
    .hard_rst                   (hard_rst                   ),
    .rst                        (rst                        ),
    .rtc_us_flg                 (timing_1us                 ),
    .rtc_s_flg                  (timing_1s                  ),
    .stamp                      (stamp_2r                   ),
    .samp_rate                  (samp_rate                  ),
    .sfh_pulse_cnt              (samp_cnt                   ),
    .sfh_pulse_freq             (samp_rate                  ),

    .cpu_cs                     (muf_cs                     ),
    .cpu_wr                     (muf_we                     ),
    .cpu_rd                     (muf_rd                     ),
    .cpu_addr                   (muf_addr[7:0]              ),
    .cpu_wr_data                (muf_wdata                  ),
    .cpu_rd_data                (muf_rdata                  ),

    .indata                     ({ddc_dout_d    , ad_data_d }   ),
    .indata_vld                 ({ddc_dout_vld_d, ad_vld_d  }   ),
    .indata_end                 ({6'd0                  }   ),
    .indata_info                (multif_indata_info         ),

    .out_data_rdy               (muf_o_rdy                  ),
    .out_data_vld               (muf_o_vld                  ),
    .out_data_sof               (muf_o_sof                  ),
    .out_data_eof               (muf_o_eof                  ),
    .out_data                   (muf_o_data                 ),
    .out_data_info              (muf_o_info                 ),
    .out_data_len               (muf_o_len                  ),
    .out_data_end               (muf_o_end                  )
);

sgl_ch_ddr_frame_top u_sgl_ch_ddr_frame_top(
    .clk_100m                   (clk_100m                   ),
    .ddr_clk                    (ddr_clk                    ),
    .ddr_rst                    (rst                        ),
    .hard_rst                   (hard_rst                   ),
    .authorize_code             (authorize_code             ),
    .init_done                  (ddr_init_done              ),
    .clk_200m                   (clk_200m                   ),
    .device_temp_i              (device_temp                ),
// DDR3 PHY Interface
    .ddr3_dq                    (ddr3_dq                    ),
    .ddr3_dqs_n                 (ddr3_dqs_n                 ),
    .ddr3_dqs_p                 (ddr3_dqs_p                 ),
    .ddr3_addr                  (ddr3_addr                  ),
    .ddr3_ba                    (ddr3_ba                    ),
    .ddr3_ras_n                 (ddr3_ras_n                 ),
    .ddr3_cas_n                 (ddr3_cas_n                 ),
    .ddr3_we_n                  (ddr3_we_n                  ),
    .ddr3_reset_n               (ddr3_reset_n               ),
    .ddr3_ck_p                  (ddr3_ck_p                  ),
    .ddr3_ck_n                  (ddr3_ck_n                  ),
    .ddr3_cke                   (ddr3_cke                   ),
    .ddr3_cs_n                  (ddr3_cs_n                  ),
    .ddr3_dm                    (ddr3_dm                    ),
    .ddr3_odt                   (ddr3_odt                   ),
//user interface
    .f_in_clk                   ({{(8){clk_100m}}       ,clk_100m                      }),
    .f_in_rdy                   ({rchn_data_rdy         ,muf_o_rdy                     }),
    .f_in_vld                   ({rchn_data_vld         ,muf_o_vld                     }),
    .f_in_sof                   ({rchn_sof              ,muf_o_sof                     }),
    .f_in_eof                   ({rchn_eof              ,muf_o_eof                     }),
    .f_in_data                  ({rchn_data             ,muf_o_data                    }),
    .f_in_len                   ({rchn_len              ,muf_o_len                	   }),
    .f_in_rsvd_info             ({64'h0                 ,3'h0,muf_o_end,muf_o_info[3:0]}),
//frame output                      
    .f_out_clk                  ({{(8){clk_50m}}       ,clk_100m                      }),
    .f_out_data                 ({fout_data             ,wchn_data                     }),
    .f_out_vld                  ({fout_vld              ,wchn_data_vld                 }),
    .f_out_rdy                  ({fout_rdy              ,wchn_data_rdy                 }),
    .f_out_sof                  ({fout_sof              ,wchn_sof                      }),
    .f_out_eof                  ({fout_eof              ,wchn_eof                      }),
    .f_out_len                  ({fout_len              ,wchn_length                   }),
    .f_out_rsvd_info            ({fout_info             ,wchn_rsvd_info[7:0]           }),
    .frame_ififo_afull          (/*not used*/               ),
    .frame_ififo_aempty         (/*not used*/               ),
//cpu interface
    .cpu_cs                     (ddr_cs                     ),
    .cpu_we                     (ddr_we                     ),
    .cpu_rd                     (ddr_rd                     ),
    .cpu_addr                   (ddr_addr[7:0]              ),
    .cpu_wdata                  (ddr_wdata                  ),
    .cpu_rdata                  (ddr_rdata                  )
); 

always @ (posedge dac_double_clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            reserevd_3cfg_1r <= #U_DLY 'b0;
            reserevd_3cfg_2r <= #U_DLY 'b0;
            cfg_rdy <= #U_DLY 8'b0;
        end
    else
        begin
            reserevd_3cfg_1r <= #U_DLY reserevd_3cfg[13:6];
            reserevd_3cfg_2r <= #U_DLY reserevd_3cfg_1r;
            cfg_rdy <= #U_DLY reserevd_3cfg_2r[7:0];
        end
end

assign duc_din_rdy_x[0]  = (cfg_rdy[0]==1'b1) ? 1'b1 : duc_din_rdy[0];
assign duc_din_rdy_x[1]  = (cfg_rdy[1]==1'b1) ? 1'b1 : duc_din_rdy[1];
assign duc_din_rdy_x[2]  = (cfg_rdy[2]==1'b1) ? 1'b1 : duc_din_rdy[2];
assign duc_din_rdy_x[3]  = (cfg_rdy[3]==1'b1) ? 1'b1 : duc_din_rdy[3];
assign duc_din_rdy_x[4]  = (cfg_rdy[4]==1'b1) ? 1'b1 : duc_din_rdy[4];
assign duc_din_rdy_x[5]  = (cfg_rdy[5]==1'b1) ? 1'b1 : duc_din_rdy[5];
assign duc_din_rdy_x[6]  = (cfg_rdy[6]==1'b1) ? 1'b1 : duc_din_rdy[6];
assign duc_din_rdy_x[7]  = (cfg_rdy[7]==1'b1) ? 1'b1 : duc_din_rdy[7];

genvar da_data_wc;
generate
    for (da_data_wc = 0 ;da_data_wc < 8 ;da_data_wc = da_data_wc + 1 ) begin : DA_JESD_WC
        width_conversion_B2S # (
            .U_DLY                      (1                                  ),
            .WIDTH_INPUT                (512                                ),
            .WIDTH_OUTPUT               (32                                 ),
            .RAM_STYLE                  ("block"                            ),
            .IN_FIFO_DEEPTH             (64                                 ),
            .IN_FIFO_PROG_FULL_THRESH   (32                                 ),
            .IN_FIFO_PROG_EMPTY_THRESH  (2                                  ),
            .OUT_FIFO_DEEPTH            (128                                ),
            .OUT_FIFO_PROG_FULL_THRESH  (64                                 ),
            .OUT_FIFO_PROG_EMPTY_THRESH (2                                  )
        ) u_wid_con_512to32_pcie2ddr (
            .WC_in_clk                  (clk_50m                           ),
           .WC_out_clk                 (dac_double_clk                     ),
            .rst                        (hard_rst                           ),
            .WC_in_data                 (fout_data[da_data_wc*512+:512]     ),
            .WC_in_vld                  (fout_vld[da_data_wc]               ),
            .WC_in_rdy                  (fout_rdy[da_data_wc]               ),
            .WC_out_data                (dac2alg_data[da_data_wc*32+:32]    ),
            .WC_out_vld                 (dac2alg_data_vld[da_data_wc]       ),
            .WC_out_rdy                 (duc_din_rdy_x[da_data_wc]          ),
            .WC_fifo_empty              (duc_din_wc_fifo_empty[da_data_wc]  ),
            .WC_fifo_prog_full          (duc_din_wc_fifo_profull[da_data_wc])
        );
    end
endgenerate

assign mefc_ordy1 = reserevd_0cfg[4] ? 1'b1 : mefc_ordy;
assign flash_data_rdy1 = reserevd_0cfg[5] ? 1'b1 : flash_data_rdy;

pcie_to_mefc_patch u_pcie_to_mefc_patch(
    .clk                        (clk_100m                   ),
    .rst                        (rst                        ),

    .ddr_out_data               (flash_data                 ),
    .ddr_out_vld                (flash_data_vld             ),
    .ddr_out_rdy                (flash_data_rdy             ),

    .mefc_odata                 (mefc_odata                 ),
    .mefc_ovld                  (mefc_ovld                  ),
    .mefc_ordy                  (mefc_ordy1                  )
);

mefc_top u_mefc_top
(
    .clk                        (clk_100m                   ),
    .hard_rst                   (hard_rst                   ),
    .rst                        (rst                        ),
//authorization 
    .authorize_code             (authorize_code             ),
//Io
    .io_addr                    (flash_addr                 ),
    .io_ce                      (flash_ce                   ),
    .io_oe                      (flash_oe                   ),
    .io_we                      (flash_we                   ),
    .io_dq                      (flash_dq                   ),
    .io_ry_byn                  (flash_ry_byn               ),
//interface with up-stream
    .read_data                  (read_data                  ),
    .read_vld                   (read_vld                   ),

    .write_data                 (mefc_odata                 ),
    .write_vld                  (mefc_ovld                  ),
    .write_rdy                  (mefc_ordy                  ),
//cpu
    .cpu_cs                     (mefc_cs                    ),
    .cpu_we                     (mefc_we                    ),
    .cpu_rd                     (mefc_rd                    ),
    .cpu_addr                   (mefc_addr[7:0]             ),
    .cpu_wdata                  (mefc_wdata                 ),
    .cpu_rdata                  (mefc_rdata                 )
);


//---------------------------------------------------------------
//time stamp
//---------------------------------------------------------------
bd_top u_bd_top(
    .clk                        (clk_100m                   ),
    .rst                        (rst                        ),
    .hard_rst                   (hard_rst                   ),

    .bd_pps                     (bd_pps                     ),
    .bd_rstn                    (bd_rstn                    ),
    .bd_pwd                     (                           ),
    .bd_rx_pad                  (bd_rx                      ),
    .bd_tx_pad                  (bd_tx                      ),
    .cpu_cs                     (bd_cs                      ),
    .cpu_wr                     (bd_we                      ),
    .cpu_rd                     (bd_rd                      ),
    .cpu_addr                   (bd_addr[7:0]               ),
    .cpu_wr_data                (bd_wdata                   ),
    .cpu_rd_data                (bd_rdata                   ),

    .rtc_year                   (bd_rtc_year                ),
    .rtc_month                  (bd_rtc_month               ),
    .rtc_day                    (bd_rtc_day                 ),
    .rtc_hour                   (bd_rtc_hour                ),
    .rtc_min                    (bd_rtc_min                 ),
    .rtc_sec                    (bd_rtc_sec                 ),
    .rtc_msec                   (bd_rtc_msec                ),
    .rtc_microsec               (bd_rtc_microsec            ),
    .rtc_nanosec                (bd_rtc_nanosec             ),
    .rtc_timing_1s              (bd_rtc_timing_1s           ),

    .sfh_pulse_cnt              (                           ),
    .sfh_pulse_freq             (                           ),
    .bd_utc_chok                (bd_utc_chok                )

);


gjb_btc_top u_gjb_btc_top(
    .clk                        (clk_100m                   ),
    .rst                        (rst                        ),
    .hard_rst                   (hard_rst                   ),
    .authorize_code             (authorize_code             ),
    .btc_rx                     (btc_rx                     ),
    .btc_tx                     (btc_tx                     ),
    .btc_1pps                   (btc_1pps                   ),

    .cpu_cs                     (btc_cs                     ),
    .cpu_we                     (btc_we                     ),
    .cpu_rd                     (btc_rd                     ),
    .cpu_addr                   (btc_addr[7:0]              ),
    .cpu_wdata                  (btc_wdata[31:0]            ),
    .cpu_rdata                  (btc_rdata[31:0]            ),

    .rtc_year                   (btc_rtc_year               ),
    .rtc_day                    (btc_rtc_day                ),
    .rtc_hour                   (btc_rtc_hour               ),
    .rtc_min                    (btc_rtc_min                ),
    .rtc_sec                    (btc_rtc_sec                ),
    .rtc_msec                   (btc_rtc_msec               ),
    .rtc_microsec               (btc_rtc_microsec           ),
    .rtc_nanosec                (btc_rtc_nanosec            ),
    .rtc_timing_1s              (btc_rtc_timing_1s          ),
    .sfh_pulse_cnt              (                           ),
    .sfh_pulse_freq             (                           ),
    .bcode_chok                 (bcode_chok                 )
);

check_pps bd_check_pps(
    .clk_100m                   (clk_100m                   ),
    .sys_rst                    (rst                        ),

    .pps                        (bd_pps                     ),
    .timing_1s                  (timing_1s                  ),

    .check_err                  (bd_check_err               )
);

check_pps btc_check_pps(
    .clk_100m                   (clk_100m                   ),
    .sys_rst                    (rst                        ),

    .pps                        (btc_1pps                   ),
    .timing_1s                  (timing_1s                  ),

    .check_err                  (btc_check_err              )
);

assign new_rtc_year     = reserevd_2cfg[0] ?  bd_rtc_year                : btc_rtc_year;
assign new_rtc_day      = reserevd_2cfg[0] ? {bd_rtc_month,  bd_rtc_day} : btc_rtc_day;
assign new_rtc_hour     = reserevd_2cfg[0] ?  bd_rtc_hour                : btc_rtc_hour;
assign new_rtc_min      = reserevd_2cfg[0] ?  bd_rtc_min                 : btc_rtc_min;
assign new_rtc_sec      = reserevd_2cfg[0] ?  bd_rtc_sec                 : btc_rtc_sec;
assign new_rtc_msec     = reserevd_2cfg[0] ?  bd_rtc_msec                : btc_rtc_msec;
assign new_rtc_microsec = reserevd_2cfg[0] ?  bd_rtc_microsec            : btc_rtc_microsec;
assign new_rtc_nanosec  = reserevd_2cfg[0] ?  bd_rtc_nanosec             : btc_rtc_nanosec;

assign stamp = {new_rtc_year[7:0],
                new_rtc_day,
                new_rtc_hour,
                new_rtc_min,
                new_rtc_sec,
                new_rtc_msec,
                new_rtc_microsec,
                new_rtc_nanosec};

always @ (posedge ad_clk or posedge hard_rst)begin
    if(hard_rst == 1'b1)
        begin
            pp1s_r <= #U_DLY 'b0;
            bd_pps_r <= #U_DLY 'b0;
            pps_flg <= #U_DLY 1'b0;
            samp_cnt <= #U_DLY 'd0;
            samp_rate <= #U_DLY 'd0;
            stamp_1r <= #U_DLY 'd0;
            stamp_2r <= #U_DLY 'd0;
            bd_timing_1s_r <= #U_DLY 'b0;
            btc_timing_1s_r <= #U_DLY 'b0;
            reserevd_2cfg_1r <= #U_DLY 'b0;
            reserevd_2cfg_2r <= #U_DLY 'b0;
        end
    else
        begin
            pp1s_r <= #U_DLY {pp1s_r[1:0],btc_1pps};
            bd_pps_r <= #U_DLY {bd_pps_r[1:0],bd_pps};
            stamp_1r <= #U_DLY stamp;
            stamp_2r <= #U_DLY stamp_1r;
            bd_timing_1s_r <= #U_DLY {bd_timing_1s_r[1:0],bd_rtc_timing_1s};
            btc_timing_1s_r <= #U_DLY {btc_timing_1s_r[1:0],btc_rtc_timing_1s};
            reserevd_2cfg_1r <= #U_DLY reserevd_2cfg;
            reserevd_2cfg_2r <= #U_DLY reserevd_2cfg_1r;
            
            if(reserevd_2cfg_2r[1] == 1'b1) 
                begin
                    if(reserevd_2cfg_2r[0] == 1'b1)
                        if(bd_timing_1s_r[1] ^ bd_timing_1s_r[2]==1'b1)
                            pps_flg <= #U_DLY 1'b1;
                        else
                            pps_flg <= #U_DLY 1'b0;
                    else
                        if(btc_timing_1s_r[1] ^ btc_timing_1s_r[2]==1'b1)
                            pps_flg <= #U_DLY 1'b1;
                        else
                            pps_flg <= #U_DLY 1'b0;
                end
            else
                begin
                    if(reserevd_2cfg_2r[0] == 1'b1)
                        begin
                            if(bd_utc_chok==1'b1)
                                begin
                                    if(bd_pps_r[1]==1'b1 && bd_pps_r[2]==1'b0)
                                        pps_flg <= #U_DLY 1'b1;
                                    else
                                        pps_flg <= #U_DLY 1'b0;
                                end
                            else if(bd_timing_1s_r[1] ^ bd_timing_1s_r[2]==1'b1)
                                pps_flg <= #U_DLY 1'b1;
                            else
                                pps_flg <= #U_DLY 1'b0;
                        end 
                    else
                        begin
                            if(bcode_chok==1'b1)
                                begin
                                    if(pp1s_r[1]==1'b1 && pp1s_r[2]==1'b0)
                                        pps_flg <= #U_DLY 1'b1;
                                    else
                                        pps_flg <= #U_DLY 1'b0;
                                end
                            else if(btc_timing_1s_r[1] ^ btc_timing_1s_r[2]==1'b1)
                                pps_flg <= #U_DLY 1'b1;
                            else
                                pps_flg <= #U_DLY 1'b0;
                        end 
            end
            if(pps_flg==1'b1)
                samp_cnt <= #U_DLY 'd0;
            else
                samp_cnt <= #U_DLY samp_cnt + 'd1;

            if(pps_flg==1'b1)
                samp_rate <= #U_DLY samp_cnt;
        end
end

endmodule

