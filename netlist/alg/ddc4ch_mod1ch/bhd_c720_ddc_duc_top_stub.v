// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Tue Mar 10 14:53:19 2026
// Host        : DESKTOP-MG0NR2O running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub e:/BHD-C720/02_alg_code/netlist/one_duc/bhd_c720_ddc_duc_top_stub.v
// Design      : bhd_c720_ddc_duc_top
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module bhd_c720_ddc_duc_top(adc_clk, dac_clk, cib_clk, hard_rst, soft_rst, 
  cpu_cs, cpu_we, cpu_rd, cpu_addr, cpu_wdata, cpu_rdata, sample_rate, cur_time_cnt, rtc_stamp, 
  b_sample_rate, b_cur_time_cnt, b_stamp, adc_din_vld, adc_din, ddc_dout_vld, ddc_dout, 
  dac_din_vld, dac_din, dac_din_rdy, duc_dout_vld, duc_dout)
/* synthesis syn_black_box black_box_pad_pin="adc_clk,dac_clk,cib_clk,hard_rst,soft_rst,cpu_cs,cpu_we,cpu_rd,cpu_addr[7:0],cpu_wdata[31:0],cpu_rdata[31:0],sample_rate[31:0],cur_time_cnt[31:0],rtc_stamp[63:0],b_sample_rate[31:0],b_cur_time_cnt[31:0],b_stamp[63:0],adc_din_vld[1:0],adc_din[31:0],ddc_dout_vld[3:0],ddc_dout[127:0],dac_din_vld[7:0],dac_din[255:0],dac_din_rdy[7:0],duc_dout_vld[1:0],duc_dout[63:0]" */;
  input adc_clk;
  input dac_clk;
  input cib_clk;
  input hard_rst;
  input soft_rst;
  input cpu_cs;
  input cpu_we;
  input cpu_rd;
  input [7:0]cpu_addr;
  input [31:0]cpu_wdata;
  output [31:0]cpu_rdata;
  input [31:0]sample_rate;
  input [31:0]cur_time_cnt;
  input [63:0]rtc_stamp;
  output [31:0]b_sample_rate;
  output [31:0]b_cur_time_cnt;
  output [63:0]b_stamp;
  input [1:0]adc_din_vld;
  input [31:0]adc_din;
  output [3:0]ddc_dout_vld;
  output [127:0]ddc_dout;
  input [7:0]dac_din_vld;
  input [255:0]dac_din;
  output [7:0]dac_din_rdy;
  output [1:0]duc_dout_vld;
  output [63:0]duc_dout;
endmodule
