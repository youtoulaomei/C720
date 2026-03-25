// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Fri Jan 30 17:23:43 2026
// Host        : DESKTOP-MG0NR2O running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub e:/BHD-C720/05_noise_code/netlist/add_noise_top_stub.v
// Design      : add_noise_top
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module add_noise_top(clk_sys, clk_cib, rst_sys, cpu_cs, cpu_we, cpu_rd, 
  cpu_addr, cpu_wdata, cpu_rdata, data_in, data_in_vld, data_out, data_out_vld)
/* synthesis syn_black_box black_box_pad_pin="clk_sys,clk_cib,rst_sys,cpu_cs,cpu_we,cpu_rd,cpu_addr[7:0],cpu_wdata[31:0],cpu_rdata[31:0],data_in[31:0],data_in_vld[1:0],data_out[31:0],data_out_vld[1:0]" */;
  input clk_sys;
  input clk_cib;
  input rst_sys;
  input cpu_cs;
  input cpu_we;
  input cpu_rd;
  input [7:0]cpu_addr;
  input [31:0]cpu_wdata;
  output [31:0]cpu_rdata;
  input [31:0]data_in;
  input [1:0]data_in_vld;
  output [31:0]data_out;
  output [1:0]data_out_vld;
endmodule
