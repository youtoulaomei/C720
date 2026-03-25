// *********************************************************************************/
// Project Name :
// Author       : Zhang Yu
// Creat Time   : 2019/11/19 10:38:27
// File Name    : jesd_tx_top.v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2019, BoYuLiHua Technology Co., Ltd.. 
// All Rights Reserved
//
// *********************************************************************************/
// Modification History:
// 1. initial
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
`timescale 1 ns / 1 ps
`define JESD_TX_AUTHORIZE_EN
`define QPLL_EN
//`define KINTEX_ULTRASCALE
module jesd_tx_top#(
parameter                        U_DLY = 1
) 
(
// system signals
input                            clk_100m,
input                            soft_rst,
input                            hard_rst,
input                            timing_1s,
input       [31:0]               authorize_code,
// jesd signals
input                            refclk_p,
input                            refclk_n,
input                            glblclk_p,
input                            glblclk_n,
input                            tx_sysref,
input                            tx_sync,
output      [  3:0]              txp,
output      [  3:0]              txn,
// data input
output                           tx_core_clk,
input                            c0_dvld_in,
input       [ 31:0]              c0_data_in,
input                            c1_dvld_in,
input       [ 31:0]              c1_data_in,
input                            c2_dvld_in,
input       [ 31:0]              c2_data_in,
input                            c3_dvld_in,
input       [ 31:0]              c3_data_in,
// local bus signals
input                            cpu_clk,  // 100m
input                            cpu_cs,
input                            cpu_we,
input                            cpu_rd,
input       [  7:0]              cpu_addr,
input       [ 31:0]              cpu_wdata,
output      [ 31:0]              cpu_rdata
);
// Parameter Define 

// Register Define 
reg         [  9:0]              tx_sync_cnt;
reg                              tx_sync_chk;
reg         [ 31:0]              c0_tx_tdata;
reg         [ 31:0]              c1_tx_tdata;
reg         [ 31:0]              c2_tx_tdata;
reg         [ 31:0]              c3_tx_tdata;
reg         [  2:0]              timing_1s_dly;
reg         [ 31:0]              timing_1s_cnt;
reg         [ 31:0]              glbl_freq_cnt;
reg         [2:0]                tx_sysref_dly;
reg         [  9:0]              tx_sysref_cnt;
reg         [  9:0]              sysref_cnt;
reg         [3:0]                dds_en_1dly;
reg         [3:0]                dds_en_2dly;
reg                              dds_config_1dly;
reg                              dds_config_2dly;
reg                              dds_config_3dly;
reg         [31:0]               dds_config_0_data_1dly; 
reg         [31:0]               dds_config_0_data_2dly; 
reg         [31:0]               dds_config_1_data_1dly; 
reg         [31:0]               dds_config_1_data_2dly; 
reg         [31:0]               dds_config_2_data_1dly; 
reg         [31:0]               dds_config_2_data_2dly; 
reg         [31:0]               dds_config_3_data_1dly; 
reg         [31:0]               dds_config_3_data_2dly; 
reg                              dds_cfg;
// Wire Define 
wire                             tx_tready;
wire        [127:0]              tx_tdata;
wire        [ 11:0]              s_axi_awaddr;
wire                             s_axi_awvalid;
wire                             s_axi_awready;
wire        [ 31:0]              s_axi_wdata;
wire                             s_axi_wvalid;
wire                             s_axi_wready;
wire        [ 11:0]              s_axi_araddr;
wire                             s_axi_arvalid;
wire                             s_axi_arready;
wire        [ 31:0]              s_axi_rdata;
wire                             s_axi_rvalid;

wire        [  7:0]              c0_0_byte;
wire        [  7:0]              c0_1_byte;
wire        [  7:0]              c0_2_byte;
wire        [  7:0]              c0_3_byte;

wire        [  7:0]              c1_0_byte;
wire        [  7:0]              c1_1_byte;
wire        [  7:0]              c1_2_byte;
wire        [  7:0]              c1_3_byte;

wire        [  7:0]              c2_0_byte;
wire        [  7:0]              c2_1_byte;
wire        [  7:0]              c2_2_byte;
wire        [  7:0]              c2_3_byte;

wire        [  7:0]              c3_0_byte;
wire        [  7:0]              c3_1_byte;
wire        [  7:0]              c3_2_byte;
wire        [  7:0]              c3_3_byte;

wire        [31:0]               dds_data_0_tdata;
wire        [31:0]               dds_data_1_tdata;
wire        [31:0]               dds_data_2_tdata;
wire        [31:0]               dds_data_3_tdata;

wire        [3:0]                dds_en;
wire        [31:0]               dds_config_0_data;
wire        [31:0]               dds_config_1_data;
wire        [31:0]               dds_config_2_data;
wire        [31:0]               dds_config_3_data;
wire        [127:0]              dds_cfg_data;
wire        [127:0]              dds_data_tdata;
wire        [1:0]                xn_sel;
wire        [3:0]                PositionConstraint;
wire                             rst;
wire                             cpll_refclk;
wire                             tx_reset_gt;
wire                             txoutclk;
wire                             rxoutclk;
wire                             cfg_rst;
wire                             dds_config;
wire                             dds_rst;
wire                             pll_lock;
wire                             qpll_lock;
wire                             tx_reset_done;
 wire [31 : 0] 	gt0_txdata		;
 wire [3 : 0] 	gt0_txcharisk   ;
 wire [31 : 0] 	gt1_txdata      ;
 wire [3 : 0] 	gt1_txcharisk   ;
 wire [31 : 0] 	gt2_txdata      ;
 wire [3 : 0] 	gt2_txcharisk   ;
 wire [31 : 0] 	gt3_txdata      ;
 wire [3 : 0] 	gt3_txcharisk   ;

assign  rst = |{soft_rst,hard_rst,cfg_rst};

assign  c0_0_byte = c0_data_in[ 7: 0];
assign  c0_1_byte = c0_data_in[15: 8];
assign  c0_2_byte = c0_data_in[23:16];
assign  c0_3_byte = c0_data_in[31:24];

assign  c1_0_byte = c1_data_in[ 7: 0];
assign  c1_1_byte = c1_data_in[15: 8];
assign  c1_2_byte = c1_data_in[23:16];
assign  c1_3_byte = c1_data_in[31:24];

assign  c2_0_byte = c2_data_in[ 7: 0];
assign  c2_1_byte = c2_data_in[15: 8];
assign  c2_2_byte = c2_data_in[23:16];
assign  c2_3_byte = c2_data_in[31:24];

assign  c3_0_byte = c3_data_in[ 7: 0];
assign  c3_1_byte = c3_data_in[15: 8];
assign  c3_2_byte = c3_data_in[23:16];
assign  c3_3_byte = c3_data_in[31:24];

always @ (posedge tx_core_clk or posedge rst)
begin
    if (rst == 1'b1)
        c0_tx_tdata <= #U_DLY 32'd0;
    else
        begin
            if(xn_sel == 2'b01)          //X2 I0I1
                begin
                    if(dds_en_2dly[0] == 1'b1)
                    begin
                        if(PositionConstraint == 4'd0)
                            c0_tx_tdata <= #U_DLY {dds_data_1_tdata[7:0],dds_data_1_tdata[15:8],dds_data_0_tdata[7:0],dds_data_0_tdata[15:8]};     //I0I1
                        else if(PositionConstraint == 4'd1)
                            c0_tx_tdata <= #U_DLY {dds_data_1_tdata[7:0],dds_data_1_tdata[15:8],dds_data_1_tdata[23:16],dds_data_1_tdata[31:24]};  //I0Q0
                        else if(PositionConstraint == 4'd2)
                            c0_tx_tdata <= #U_DLY {dds_data_0_tdata[7:0],dds_data_0_tdata[15:8],dds_data_1_tdata[7:0],dds_data_1_tdata[15:8]};     //I1I0
                        else if(PositionConstraint == 4'd3)
                            c0_tx_tdata <= #U_DLY {dds_data_1_tdata[23:16],dds_data_1_tdata[31:24],dds_data_1_tdata[7:0],dds_data_1_tdata[15:8]};  //Q0I0
                    end
                    else if(c0_dvld_in == 1'b1)
                    begin
                        if(PositionConstraint == 4'd0)
                            c0_tx_tdata <= #U_DLY {c1_0_byte,c1_1_byte,c0_0_byte,c0_1_byte};        //I0I1
                        else if(PositionConstraint == 4'd1)
                            c0_tx_tdata <= #U_DLY {c1_0_byte,c1_1_byte,c1_2_byte,c1_3_byte};        //I0Q0
                        else if(PositionConstraint == 4'd2)
                            c0_tx_tdata <= #U_DLY {c0_0_byte,c0_1_byte,c1_0_byte,c1_1_byte};        //I1I0
                        else if(PositionConstraint == 4'd3)
                            c0_tx_tdata <= #U_DLY {c1_2_byte,c1_3_byte,c1_0_byte,c1_1_byte};        //Q0I0
                    end
                    else
                        c0_tx_tdata <= #U_DLY 32'd0;
                end
            else if(xn_sel == 2'b10)     //X4 I0I2
                begin
                    if(dds_en_2dly[0] == 1'b1)
                        c0_tx_tdata <= #U_DLY {dds_data_2_tdata[7:0],dds_data_2_tdata[15:8],dds_data_0_tdata[7:0],dds_data_0_tdata[15:8]};
                    else if(c0_dvld_in == 1'b1)
                        c0_tx_tdata <= #U_DLY {c2_0_byte,c2_1_byte,c0_0_byte,c0_1_byte};//2301                     
                    else
                        c0_tx_tdata <= #U_DLY 32'd0;
                end
            else                        //X1 I0Q0
                begin
                    if(dds_en_2dly[0] == 1'b1)
                        c0_tx_tdata <= #U_DLY {dds_data_0_tdata[23:16],dds_data_0_tdata[31:24],dds_data_0_tdata[7:0],dds_data_0_tdata[15:8]};
                    else if(c0_dvld_in == 1'b1)
                        c0_tx_tdata <= #U_DLY {c0_2_byte,c0_3_byte,c0_0_byte,c0_1_byte};//2301 
                    else
                        c0_tx_tdata <= #U_DLY 32'd0;
                end                
        end
end

always @ (posedge tx_core_clk or posedge rst)
begin
    if (rst == 1'b1)
        c1_tx_tdata <= #U_DLY 32'd0;
    else
        begin
            if(xn_sel == 2'b01)          //X2 Q0Q1
                begin
                    if(dds_en_2dly[1] == 1'b1)
                    begin
                        if(PositionConstraint == 4'd0)
                            c1_tx_tdata <= #U_DLY {dds_data_1_tdata[23:16],dds_data_1_tdata[31:24],dds_data_0_tdata[23:16],dds_data_0_tdata[31:24]};    //Q0Q1
                        else if(PositionConstraint == 4'd1)
                            c1_tx_tdata <= #U_DLY {dds_data_0_tdata[7:0],dds_data_0_tdata[15:8],dds_data_0_tdata[23:16],dds_data_0_tdata[31:24]};       //I1Q1
                        else if(PositionConstraint == 4'd2)
                            c1_tx_tdata <= #U_DLY {dds_data_0_tdata[23:16],dds_data_0_tdata[31:24],dds_data_1_tdata[23:16],dds_data_1_tdata[31:24]};    //Q1Q0
                        else if(PositionConstraint == 4'd3)
                            c1_tx_tdata <= #U_DLY {dds_data_0_tdata[23:16],dds_data_0_tdata[31:24],dds_data_0_tdata[7:0],dds_data_0_tdata[15:8]};       //Q1I1
                    end
                    else if(c1_dvld_in == 1'b1)
                    begin
                        if(PositionConstraint == 4'd0)
                            c1_tx_tdata <= #U_DLY {c1_2_byte,c1_3_byte,c0_2_byte,c0_3_byte};        //Q0Q1
                        else if(PositionConstraint == 4'd1)
                            c1_tx_tdata <= #U_DLY {c0_0_byte,c0_1_byte,c0_2_byte,c0_3_byte};        //I1Q1
                        else if(PositionConstraint == 4'd2)
                            c1_tx_tdata <= #U_DLY {c0_2_byte,c0_3_byte,c1_2_byte,c1_3_byte};        //Q1Q0
                        else if(PositionConstraint == 4'd3)
                            c1_tx_tdata <= #U_DLY {c0_2_byte,c0_3_byte,c0_0_byte,c0_1_byte};        //Q1I1
                    end
                    else
                        c1_tx_tdata <= #U_DLY 32'd0;
                end
            else if(xn_sel == 2'b10)     //X4 I1I3
                begin
                    if(dds_en_2dly[1] == 1'b1)
                        c1_tx_tdata <= #U_DLY {dds_data_3_tdata[7:0],dds_data_3_tdata[15:8],dds_data_1_tdata[7:0],dds_data_1_tdata[15:8]};
                    else if(c1_dvld_in == 1'b1)
                        c1_tx_tdata <= #U_DLY {c3_0_byte,c3_1_byte,c1_0_byte,c1_1_byte};//2301                     
                    else
                        c1_tx_tdata <= #U_DLY 32'd0;                    
                end
            else                       //X1 I1Q1
                begin
                    if(dds_en_2dly[1] == 1'b1)
                        c1_tx_tdata <= #U_DLY {dds_data_1_tdata[23:16],dds_data_1_tdata[31:24],dds_data_1_tdata[7:0],dds_data_1_tdata[15:8]};
                    else if(c1_dvld_in == 1'b1)
                        c1_tx_tdata <= #U_DLY {c1_2_byte,c1_3_byte,c1_0_byte,c1_1_byte};//2301
                    else
                        c1_tx_tdata <= #U_DLY 32'd0;
                end 
        end
end

always @ (posedge tx_core_clk or posedge rst)
begin
    if (rst == 1'b1)
        c2_tx_tdata <= #U_DLY 32'd0;
    else 
        begin
            if(xn_sel == 2'b01)          //X2 I2I3
                begin
                    if(dds_en_2dly[2] == 1'b1)
                    begin
                        if(PositionConstraint == 4'd0)
                            c2_tx_tdata <= #U_DLY {dds_data_3_tdata[7:0],dds_data_3_tdata[15:8],dds_data_2_tdata[7:0],dds_data_2_tdata[15:8]};     //I2I3
                        else if(PositionConstraint == 4'd1)
                            c2_tx_tdata <= #U_DLY {dds_data_3_tdata[7:0],dds_data_3_tdata[15:8],dds_data_3_tdata[23:16],dds_data_3_tdata[31:24]};  //I2Q2
                        else if(PositionConstraint == 4'd2)
                            c2_tx_tdata <= #U_DLY {dds_data_2_tdata[7:0],dds_data_2_tdata[15:8],dds_data_3_tdata[7:0],dds_data_3_tdata[15:8]};     //I3I2
                        else if(PositionConstraint == 4'd3)
                            c2_tx_tdata <= #U_DLY {dds_data_3_tdata[23:16],dds_data_3_tdata[31:24],dds_data_3_tdata[7:0],dds_data_3_tdata[15:8]};  //Q2I2
                    end
                    else if(c2_dvld_in == 1'b1)
                    begin
                        if(PositionConstraint == 4'd0)
                            c2_tx_tdata <= #U_DLY {c3_0_byte,c3_1_byte,c2_0_byte,c2_1_byte};        //I2I3
                        else if(PositionConstraint == 4'd1)
                            c2_tx_tdata <= #U_DLY {c3_0_byte,c3_1_byte,c3_2_byte,c3_3_byte};        //I2Q2
                        else if(PositionConstraint == 4'd2)
                            c2_tx_tdata <= #U_DLY {c2_0_byte,c2_1_byte,c3_0_byte,c3_1_byte};        //I3I2
                        else if(PositionConstraint == 4'd3)
                            c2_tx_tdata <= #U_DLY {c3_2_byte,c3_3_byte,c3_0_byte,c3_1_byte};        //Q2I2
                    end
                    else
                        c2_tx_tdata <= #U_DLY 32'd0;
                end
            else if(xn_sel == 2'b10)     //X4 Q0Q2
                begin
                    if(dds_en_2dly[2] == 1'b1)
                        c2_tx_tdata <= #U_DLY {dds_data_2_tdata[23:16],dds_data_2_tdata[31:24],dds_data_0_tdata[23:16],dds_data_0_tdata[31:24]};
                    else if(c2_dvld_in == 1'b1)
                        c2_tx_tdata <= #U_DLY {c2_2_byte,c2_3_byte,c0_2_byte,c0_3_byte};//2301                     
                    else
                        c2_tx_tdata <= #U_DLY 32'd0;                    
                end
            else                       //X1 I2Q2
                begin
                    if(dds_en_2dly[2] == 1'b1)
                        c2_tx_tdata <= #U_DLY {dds_data_2_tdata[23:16],dds_data_2_tdata[31:24],dds_data_2_tdata[7:0],dds_data_2_tdata[15:8]};              
                    else if(c2_dvld_in == 1'b1)
                        c2_tx_tdata <= #U_DLY {c2_2_byte,c2_3_byte,c2_0_byte,c2_1_byte};//2301
                    else
                        c2_tx_tdata <= #U_DLY 32'd0;
                end
        end
end

always @ (posedge tx_core_clk or posedge rst)
begin
    if (rst == 1'b1)
        c3_tx_tdata <= #U_DLY 32'd0;
    else
        begin
            if(xn_sel == 2'b01)          //X2 Q2Q3
                begin
                    if(dds_en_2dly[3] == 1'b1)
                    begin
                        if(PositionConstraint == 4'd0)
                            c3_tx_tdata <= #U_DLY {dds_data_3_tdata[23:16],dds_data_3_tdata[31:24],dds_data_2_tdata[23:16],dds_data_2_tdata[31:24]};    //Q2Q3
                        else if(PositionConstraint == 4'd1)
                            c3_tx_tdata <= #U_DLY {dds_data_2_tdata[7:0],dds_data_2_tdata[15:8],dds_data_2_tdata[23:16],dds_data_2_tdata[31:24]};       //I3Q3
                        else if(PositionConstraint == 4'd2)
                            c3_tx_tdata <= #U_DLY {dds_data_2_tdata[23:16],dds_data_2_tdata[31:24],dds_data_3_tdata[23:16],dds_data_3_tdata[31:24]};    //Q3Q2
                        else if(PositionConstraint == 4'd3)
                            c3_tx_tdata <= #U_DLY {dds_data_2_tdata[23:16],dds_data_2_tdata[31:24],dds_data_2_tdata[7:0],dds_data_2_tdata[15:8]};       //Q3I3
                    end
                    else if(c3_dvld_in == 1'b1)
                    begin
                        if(PositionConstraint == 4'd0)
                            c3_tx_tdata <= #U_DLY {c3_2_byte,c3_3_byte,c2_2_byte,c2_3_byte};        //Q2Q3
                        else if(PositionConstraint == 4'd1)
                            c3_tx_tdata <= #U_DLY {c2_0_byte,c2_1_byte,c2_2_byte,c2_3_byte};        //I3Q3
                        else if(PositionConstraint == 4'd2)
                            c3_tx_tdata <= #U_DLY {c2_2_byte,c2_3_byte,c3_2_byte,c3_3_byte};        //Q3Q2
                        else if(PositionConstraint == 4'd3)
                            c3_tx_tdata <= #U_DLY {c2_2_byte,c2_3_byte,c2_0_byte,c2_1_byte};        //Q3I3
                    end
                    else
                        c3_tx_tdata <= #U_DLY 32'd0;
                end
            else if(xn_sel == 2'b10)     //X4 Q1Q3
                begin
                    if(dds_en_2dly[3] == 1'b1)
                        c3_tx_tdata <= #U_DLY {dds_data_3_tdata[23:16],dds_data_3_tdata[31:24],dds_data_1_tdata[23:16],dds_data_1_tdata[31:24]};
                    else if(c3_dvld_in == 1'b1)
                        c3_tx_tdata <= #U_DLY {c3_2_byte,c3_3_byte,c1_2_byte,c1_3_byte};//2301                     
                    else
                        c3_tx_tdata <= #U_DLY 32'd0;
                end
            else                        //X1 I3Q3
                begin
                    if(dds_en_2dly[3] == 1'b1)
                        c3_tx_tdata <= #U_DLY {dds_data_3_tdata[23:16],dds_data_3_tdata[31:24],dds_data_3_tdata[7:0],dds_data_3_tdata[15:8]};  
                    else if(c3_dvld_in == 1'b1)
                        c3_tx_tdata <= #U_DLY {c3_2_byte,c3_3_byte,c3_0_byte,c3_1_byte};//2301
                    else
                        c3_tx_tdata <= #U_DLY 32'd0;
                end
        end
end

assign  tx_tdata = {c3_tx_tdata,c2_tx_tdata,c1_tx_tdata,c0_tx_tdata};
//assign  tx_tdata = {c1_tx_tdata,c0_tx_tdata};

////////IBUFDS_GTE2 #(
//   .CLKCM_CFG("TRUE"),   // Refer to Transceiver User Guide
//   .CLKRCV_TRST("TRUE"), // Refer to Transceiver User Guide
//   .CLKSWING_CFG(2'b11)  // Refer to Transceiver User Guide
//)
//IBUFDS_GTE2_inst (
//   .O(cpll_refclk),         // 1-bit output: Refer to Transceiver User Guide
//   .ODIV2( ), // 1-bit output: Refer to Transceiver User Guide
//   .CEB(1'b1),     // 1-bit input: Refer to Transceiver User Guide
//   .I(refclk_p),         // 1-bit input: Refer to Transceiver User Guide
//   .IB(refclk_n)        // 1-bit input: Refer to Transceiver User Guide
//);

  IBUFDS_GTE2 ibufds_refclk0
  (
    .O               (cpll_refclk),
    .ODIV2           (),
    .CEB             (1'b0),
    .I               (refclk_p),
    .IB              (refclk_n)
  );


// assign tx_core_clk = cpll_refclk;
 assign txoutclk = cpll_refclk;
jesd204b_tx jesd204b_tx (
    .gt0_txdata                 (gt0_txdata                 ),  
    .gt0_txcharisk              (gt0_txcharisk              ),  
    .gt1_txdata                 (gt1_txdata                 ),  
    .gt1_txcharisk              (gt1_txcharisk              ),  
    .gt2_txdata                 (gt2_txdata                 ),  
    .gt2_txcharisk              (gt2_txcharisk              ),  
    .gt3_txdata                 (gt3_txdata                 ),  
    .gt3_txcharisk              (gt3_txcharisk              ), 
    .tx_reset_done              (tx_reset_done              ),  
    .gt_prbssel_out             (              				),  
    .tx_reset_gt                (tx_reset_gt                ),  
    .tx_core_clk                (tx_core_clk                ),  

    .s_axi_aclk                 (cpu_clk                    ), 
    .s_axi_aresetn              (~rst                       ), 
    .s_axi_awaddr               (s_axi_awaddr               ), 
    .s_axi_awvalid              (s_axi_awvalid              ), 
    .s_axi_awready              (s_axi_awready              ), 
    .s_axi_wdata                (s_axi_wdata                ), 
    .s_axi_wstrb                (4'hf                       ), 
    .s_axi_wvalid               (s_axi_wvalid               ), 
    .s_axi_wready               (s_axi_wready               ), 
    .s_axi_bresp                (/* not used */             ), 
    .s_axi_bvalid               (/* not used */             ), 
    .s_axi_bready               (1'b1                       ), 
    .s_axi_araddr               (s_axi_araddr               ), 
    .s_axi_arvalid              (s_axi_arvalid              ), 
    .s_axi_arready              (s_axi_arready              ), 
    .s_axi_rdata                (s_axi_rdata                ), 
    .s_axi_rresp                (/* not used */             ), 
    .s_axi_rvalid               (s_axi_rvalid               ), 
    .s_axi_rready               (1'b1                       ),  
    .tx_reset                   (rst                   		),  
    .tx_sysref                  (tx_sysref                  ),  
    .tx_start_of_frame          (           				),  
    .tx_start_of_multiframe     (     		 				),  
    .tx_aresetn                 (                  			),  
    .tx_tdata                   (tx_tdata                   ),  
    .tx_tready                  (tx_tready                  ),  
    .tx_sync                    (tx_sync                    ) 
);

jesd204_phy_0 jesd204_phy_0(  
    .tx_sys_reset               (rst               			),
    .rx_sys_reset               (rst               			),
    .tx_reset_gt                (tx_reset_gt                ),
    .rx_reset_gt                (tx_reset_gt                ),
    .tx_reset_done              (tx_reset_done              ),
    .rx_reset_done              (               			),
    .cpll_refclk                (cpll_refclk                ),
    .rxencommaalign             (1'b0      					),
    .tx_core_clk                (tx_core_clk                ),
    .txoutclk                   (                           ),
    .rx_core_clk                (tx_core_clk     	        ),
    .rxoutclk                   (rxoutclk                   ),
    .drpclk                     (clk_100m                   ),
    .gt_prbssel                 (3'b0                 		),
    .gt0_txcharisk              (gt0_txcharisk              ),
    .gt0_txdata                 (gt0_txdata                 ),
    .gt1_txcharisk              (gt1_txcharisk              ),
    .gt1_txdata                 (gt1_txdata                 ),
    .gt2_txcharisk              (gt2_txcharisk              ),
    .gt2_txdata                 (gt2_txdata                 ),
    .gt3_txcharisk              (gt3_txcharisk              ),
    .gt3_txdata                 (gt3_txdata                 ),
    .gt0_rxcharisk              (							),
    .gt0_rxdisperr              (							),
    .gt0_rxnotintable           (							),
    .gt0_rxdata                 (							),
    .gt1_rxcharisk              (							),
    .gt1_rxdisperr              (							),
    .gt1_rxnotintable           (							),
    .gt1_rxdata                 (							),
    .gt2_rxcharisk              (							),
    .gt2_rxdisperr              (							),
    .gt2_rxnotintable           (							),
    .gt2_rxdata                 (							),
    .gt3_rxcharisk              (							),
    .gt3_rxdisperr              (							),
    .gt3_rxnotintable           (							),
    .gt3_rxdata                 (							),
    .rxn_in                     (4'b0                       ),
    .rxp_in                     (4'b0                       ),
    .txn_out                    (txn                    	),
    .txp_out                    (txp                    	) 
);

  BUFG BUFG_inst (
     .O(tx_core_clk    ), // 1-bit output: Clock output
     .I(txoutclk       )  // 1-bit input: Clock input
  );
`ifndef QPLL_EN
assign qpll_lock = 1'b1;
`endif
jesd_tx_cib u_jesd_tx_cib(
// system signals
    .clk                        (cpu_clk                    ),
    .rst                        (hard_rst                   ),
    .cfg_rst                    (cfg_rst                    ),
// local bus        
    .cpu_addr                   (cpu_addr                   ),
    .cpu_cs                     (cpu_cs                     ),
    .cpu_we                     (cpu_we                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_wdata                  (cpu_wdata                  ),
    .cpu_rdata                  (cpu_rdata                  ),
// local bus <--> aix
    .s_axi_awaddr               (s_axi_awaddr               ),
    .s_axi_awvalid              (s_axi_awvalid              ),
    .s_axi_awready              (s_axi_awready              ),
    .s_axi_wdata                (s_axi_wdata                ),
    .s_axi_wvalid               (s_axi_wvalid               ),
    .s_axi_wready               (s_axi_wready               ),
    .s_axi_araddr               (s_axi_araddr               ),
    .s_axi_arvalid              (s_axi_arvalid              ),
    .s_axi_arready              (s_axi_arready              ),
    .s_axi_rdata                (s_axi_rdata                ),
    .s_axi_rvalid               (s_axi_rvalid               ),
// debug signals
    .tx_loss_sync               (~tx_sync_chk               ),
    .pll_unlock                 (~pll_lock                  ),
    .qpll_unlock                (~qpll_lock                 ),
    .glbl_freq_cnt              (glbl_freq_cnt              ),
    .sysref_cnt                 (sysref_cnt                 ),
    .xn_sel                     (xn_sel                     ),
    .PositionConstraint         (PositionConstraint         ),
    .dds_en                     (dds_en                     ),
    .dds_config                 (dds_config                 ),
    .dds_config_0_data          (dds_config_0_data          ),
    .dds_config_1_data          (dds_config_1_data          ),
    .dds_config_2_data          (dds_config_2_data          ),
    .dds_config_3_data          (dds_config_3_data          ),
    .dds_rst                    (dds_rst                    )
);

always @ (posedge tx_core_clk or posedge rst)
begin
    if(rst == 1'b1)
        tx_sync_cnt <= #U_DLY 10'h000;
    else if (tx_sync == 1'b1)
    begin
        if (tx_sync_cnt < 10'h3ff)
            tx_sync_cnt <= #U_DLY tx_sync_cnt + 1'b1;
        else;
    end
    else
        tx_sync_cnt <= #U_DLY 10'h000;
end

always @ (posedge tx_core_clk or posedge rst)
begin
    if(rst == 1'b1)
        tx_sync_chk <= #U_DLY 1'b0;
    else if (tx_sync_cnt == 10'h3ff)
        tx_sync_chk <= #U_DLY 1'b1;
    else
        tx_sync_chk <= #U_DLY 1'b0;
end
//yangyong 20191224 
always @ (posedge tx_core_clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            timing_1s_dly <= 3'd0;
            timing_1s_cnt <= 'd0;
            glbl_freq_cnt <= 'd0;
        end
    else
        begin
            timing_1s_dly <= #U_DLY {timing_1s_dly[1:0],timing_1s};

            if(timing_1s_dly[2] ^ timing_1s_dly[1] == 1'b1)
                timing_1s_cnt <= #U_DLY 'd0;
            else
                timing_1s_cnt <= #U_DLY timing_1s_cnt + 'd1;

            if(timing_1s_dly[2] ^ timing_1s_dly[1] == 1'b1)
                glbl_freq_cnt <= #U_DLY timing_1s_cnt;
            else;
        end
end
always @ (posedge tx_core_clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            tx_sysref_dly <= 1'b0;
            tx_sysref_cnt <= 'd0;
            sysref_cnt <= 'd0;
        end
    else
        begin
            tx_sysref_dly <= #U_DLY {tx_sysref_dly[1:0],tx_sysref};

            if({tx_sysref_dly[2],tx_sysref_dly[1]} == 2'b01)
                tx_sysref_cnt <= #U_DLY 'd1;
            else 
                tx_sysref_cnt <= #U_DLY tx_sysref_cnt + 'd1;

            if({tx_sysref_dly[2],tx_sysref_dly[1]} == 2'b01)
                sysref_cnt <= #U_DLY tx_sysref_cnt;
            else;
        end
end

authorize_sub_module #(
    .U_DLY                      (U_DLY                      )
)
u_authorize_sub_module(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),
    .key                        (32'h4C_4A_43_44            ),
//
    .authorize_code             (authorize_code             ),
//
    .authorize_succ             (                           )
);
//dds_gen
genvar i;
generate
for(i=0; i<4; i=i+1)
begin
    dds_compiler_0 u_tx_dds(
        .aclk                       (tx_core_clk                ),
        .aclken                     (dds_en_2dly[i]             ),
        .aresetn                    (~dds_rst && tx_sync        ),
        .s_axis_config_tvalid       (dds_cfg                    ),
        .s_axis_config_tdata        (dds_cfg_data[32*i+:32]     ),
        .m_axis_data_tvalid         (/*not used*/               ),
        .m_axis_data_tdata          (dds_data_tdata[32*i+:32]   )
    );
end
endgenerate

assign dds_data_0_tdata = dds_data_tdata[32*0+:32];
assign dds_data_1_tdata = dds_data_tdata[32*1+:32];
assign dds_data_2_tdata = dds_data_tdata[32*2+:32];
assign dds_data_3_tdata = dds_data_tdata[32*3+:32];

always @ (posedge tx_core_clk or posedge rst)
begin
    if(rst == 1'b1)
        dds_cfg <= 1'b0;
    else if({dds_config_3dly,dds_config_2dly} == 2'b01)
        dds_cfg <= #U_DLY 1'b1;
    else
        dds_cfg <= #U_DLY 1'b0;
end
//******************************************************************//
always @ (posedge tx_core_clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            dds_en_1dly <= 4'd0;
            dds_en_2dly <= 4'd0;

            dds_config_1dly <= 1'b0;
            dds_config_2dly <= 1'b0;
            dds_config_3dly <= 1'b0;
        end
    else
        begin
            dds_en_1dly <= #U_DLY dds_en;
            dds_en_2dly <= #U_DLY dds_en_1dly;

            dds_config_1dly <= #U_DLY dds_config;
            dds_config_2dly <= #U_DLY dds_config_1dly;
            dds_config_3dly <= #U_DLY dds_config_2dly;
        end
end

always @ (posedge tx_core_clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            dds_config_0_data_1dly <= 'd0;
            dds_config_0_data_2dly <= 'd0;
            dds_config_1_data_1dly <= 'd0;
            dds_config_1_data_2dly <= 'd0;
            dds_config_2_data_1dly <= 'd0;
            dds_config_2_data_2dly <= 'd0;
            dds_config_3_data_1dly <= 'd0;
            dds_config_3_data_2dly <= 'd0;
        end
    else
        begin
            dds_config_0_data_1dly <= #U_DLY dds_config_0_data;
            dds_config_0_data_2dly <= #U_DLY dds_config_0_data_1dly; 

            dds_config_1_data_1dly <= #U_DLY dds_config_1_data;
            dds_config_1_data_2dly <= #U_DLY dds_config_1_data_1dly;

            dds_config_2_data_1dly <= #U_DLY dds_config_2_data;
            dds_config_2_data_2dly <= #U_DLY dds_config_2_data_1dly;

            dds_config_3_data_1dly <= #U_DLY dds_config_3_data;
            dds_config_3_data_2dly <= #U_DLY dds_config_3_data_1dly;
        end
end

assign dds_cfg_data = {dds_config_3_data_2dly,dds_config_2_data_2dly,dds_config_1_data_2dly,dds_config_0_data_2dly}; 

endmodule


