// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Mon Mar  9 13:23:33 2026
// Host        : DESKTOP-MG0NR2O running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub e:/BHD-C720/07_bpf_module/netlist/bpf_top_stub.v
// Design      : bpf_top
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module bpf_top(sys_clk, sys_rst, data_din, data_din_vld, 
  data_dout, data_dout_vld, bypass_en)
/* synthesis syn_black_box black_box_pad_pin="sys_clk,sys_rst,data_din[31:0],data_din_vld[1:0],data_dout[31:0],data_dout_vld[1:0],bypass_en" */;
  input sys_clk;
  input sys_rst;
  input [31:0]data_din;
  input [1:0]data_din_vld;
  output [31:0]data_dout;
  output [1:0]data_dout_vld;
  input bypass_en;
endmodule
