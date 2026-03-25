// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Mon Mar  9 15:10:35 2026
// Host        : DESKTOP-I2KN1QR running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               E:/liutian_learn/task/C720_task/eight/xilinx_ip/xilinx_ip/jesd204b_tx/jesd204b_tx_stub.v
// Design      : jesd204b_tx
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1761-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "jesd204_v7_2_4,Vivado 2018.3" *)
module jesd204b_tx(tx_reset, tx_core_clk, tx_sysref, tx_sync, 
  tx_aresetn, tx_start_of_frame, tx_start_of_multiframe, tx_tready, tx_tdata, tx_reset_gt, 
  tx_reset_done, gt0_txdata, gt0_txcharisk, gt1_txdata, gt1_txcharisk, gt2_txdata, 
  gt2_txcharisk, gt3_txdata, gt3_txcharisk, gt_prbssel_out, s_axi_aclk, s_axi_aresetn, 
  s_axi_awaddr, s_axi_awvalid, s_axi_awready, s_axi_wdata, s_axi_wstrb, s_axi_wvalid, 
  s_axi_wready, s_axi_bresp, s_axi_bvalid, s_axi_bready, s_axi_araddr, s_axi_arvalid, 
  s_axi_arready, s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready)
/* synthesis syn_black_box black_box_pad_pin="tx_reset,tx_core_clk,tx_sysref,tx_sync,tx_aresetn,tx_start_of_frame[3:0],tx_start_of_multiframe[3:0],tx_tready,tx_tdata[127:0],tx_reset_gt,tx_reset_done,gt0_txdata[31:0],gt0_txcharisk[3:0],gt1_txdata[31:0],gt1_txcharisk[3:0],gt2_txdata[31:0],gt2_txcharisk[3:0],gt3_txdata[31:0],gt3_txcharisk[3:0],gt_prbssel_out[2:0],s_axi_aclk,s_axi_aresetn,s_axi_awaddr[11:0],s_axi_awvalid,s_axi_awready,s_axi_wdata[31:0],s_axi_wstrb[3:0],s_axi_wvalid,s_axi_wready,s_axi_bresp[1:0],s_axi_bvalid,s_axi_bready,s_axi_araddr[11:0],s_axi_arvalid,s_axi_arready,s_axi_rdata[31:0],s_axi_rresp[1:0],s_axi_rvalid,s_axi_rready" */;
  input tx_reset;
  input tx_core_clk;
  input tx_sysref;
  input tx_sync;
  output tx_aresetn;
  output [3:0]tx_start_of_frame;
  output [3:0]tx_start_of_multiframe;
  output tx_tready;
  input [127:0]tx_tdata;
  output tx_reset_gt;
  input tx_reset_done;
  output [31:0]gt0_txdata;
  output [3:0]gt0_txcharisk;
  output [31:0]gt1_txdata;
  output [3:0]gt1_txcharisk;
  output [31:0]gt2_txdata;
  output [3:0]gt2_txcharisk;
  output [31:0]gt3_txdata;
  output [3:0]gt3_txcharisk;
  output [2:0]gt_prbssel_out;
  input s_axi_aclk;
  input s_axi_aresetn;
  input [11:0]s_axi_awaddr;
  input s_axi_awvalid;
  output s_axi_awready;
  input [31:0]s_axi_wdata;
  input [3:0]s_axi_wstrb;
  input s_axi_wvalid;
  output s_axi_wready;
  output [1:0]s_axi_bresp;
  output s_axi_bvalid;
  input s_axi_bready;
  input [11:0]s_axi_araddr;
  input s_axi_arvalid;
  output s_axi_arready;
  output [31:0]s_axi_rdata;
  output [1:0]s_axi_rresp;
  output s_axi_rvalid;
  input s_axi_rready;
endmodule
