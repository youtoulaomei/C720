// *********************************************************************************/
// Project Name :
// Author       : Zhang Yu
// Creat Time   : 2019/8/26 14:31:48
// File Name    : jesd_cib.v
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

/* base registers */
`define JESD_00_REG {VERSION}
`define JESD_01_REG {YEAR,MONTH,DAY}
`define JESD_02_REG {jesd_reset}
`define JESD_03_REG {test_data}

`define JESD_05_REG {fill[31:2],xn_sel}
`define JESD_06_REG {fill[31:4],PositionConstraint}
/* registers for local bus address axi bus */
`define JESD_10_REG {lb2axi_addr}
`define JESD_11_REG {lb2axi_data}
`define JESD_12_REG {lb2axi_enb}
`define JESD_13_REG {axi2lb_data}
`define JESD_14_REG {fill[31:2],axi_rd_busy,axi_wr_busy}

/* registers for parameters or controller */
`define JESD_20_REG {fill[31:4],dds_en}
`define JESD_21_REG {fill[31:1],dds_config}
`define JESD_22_REG {dds_config_0_data}
`define JESD_23_REG {dds_config_1_data}
`define JESD_24_REG {dds_config_2_data}
`define JESD_25_REG {dds_config_3_data}
`define JESD_26_REG {fill[31:1],dds_rst}

/* registers for debug */
`define JESD_80_REG {fill[31:3],his_qpll_unlock,his_pll_unlock,his_tx_loss_sync}
`define JESD_90_REG {fill[31:10],cur_sysref_cnt}
`define JESD_91_REG {cur_glbl_freq_cnt}

module jesd_tx_cib#(
parameter                        U_DLY = 1,
parameter                        VERSION =32'h0000_0002,
parameter                        YEAR = 16'h2019,
parameter                        MONTH = 8'h11,
parameter                        DAY = 8'h11
)
(
// system signals
input                            clk,
input                            rst,
output                           cfg_rst,
// local bus        
input       [  7:0]              cpu_addr,
input                            cpu_cs,
input                            cpu_we,
input                            cpu_rd,
input       [ 31:0]              cpu_wdata,
output reg  [ 31:0]              cpu_rdata,
// local bus <--> aix
output reg  [ 11:0]              s_axi_awaddr,
output reg                       s_axi_awvalid,
input                            s_axi_awready,
output reg  [ 31:0]              s_axi_wdata,
output reg                       s_axi_wvalid,
input                            s_axi_wready,
output reg  [ 11:0]              s_axi_araddr,
output reg                       s_axi_arvalid,
input                            s_axi_arready,
input       [ 31:0]              s_axi_rdata,
input                            s_axi_rvalid,
// debug signals
input                            tx_loss_sync,
input                            pll_unlock,
input                            qpll_unlock,
input       [ 31:0]              glbl_freq_cnt,
input       [  9:0]              sysref_cnt,
output reg  [1:0]                xn_sel,
output reg  [3:0]                PositionConstraint,
output reg  [3:0]                dds_en,
output reg                       dds_config,
output reg  [31:0]               dds_config_0_data,
output reg  [31:0]               dds_config_1_data,
output reg  [31:0]               dds_config_2_data,
output reg  [31:0]               dds_config_3_data,
output reg                       dds_rst
);
// Parameter Define 

// Register Define 
reg         [ 31:0]              fill = 32'd0;
reg         [ 31:0]              test_data;
reg         [ 31:0]              jesd_reset;
reg         [ 31:0]              lb2axi_addr;
reg         [ 31:0]              lb2axi_data;
reg         [ 31:0]              lb2axi_enb;
reg                              axi_wr_busy;
reg                              axi_rd_busy;
reg         [ 31:0]              axi2lb_data;
reg         [  2:0]              cpu_we_dly;
reg         [  2:0]              cpu_rd_dly;
reg         [  1:0]              cpu_cs_dly;
reg                              axi_wr_flag;
reg                              axi_rd_flag;
// Wire Define 
wire                             cpu_rden;
wire                             cpu_wren;
wire                             cpu_read_en;
wire                             his_tx_loss_sync;
wire                             his_pll_unlock;
wire                             his_qpll_unlock;
wire        [ 31:0]              cur_glbl_freq_cnt;
wire        [  9:0]              cur_sysref_cnt;
/////////////////////////////////////////////////////////////////////////////////////
assign  cfg_rst = jesd_reset[0];

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
    begin
        cpu_we_dly <= #U_DLY 3'b0;
        cpu_rd_dly <= #U_DLY 3'b0;
        cpu_cs_dly <= #U_DLY 2'b0;
    end
    else
    begin
        cpu_we_dly <= #U_DLY {cpu_we_dly[1:0],cpu_we};
        cpu_rd_dly <= #U_DLY {cpu_rd_dly[1:0],cpu_rd};
        cpu_cs_dly <= #U_DLY {cpu_cs_dly[  0],cpu_cs};
    end
end

assign cpu_rden = {cpu_rd_dly[2:1],cpu_cs_dly[1]} == 3'b100;
assign cpu_wren = {cpu_we_dly[2:1],cpu_cs_dly[1]} == 3'b100;

// read
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        cpu_rdata <= 32'd0;
    else if (cpu_rden == 1'b1)
    begin
        case(cpu_addr)
            8'h00:   cpu_rdata <= #U_DLY `JESD_00_REG; 
            8'h01:   cpu_rdata <= #U_DLY `JESD_01_REG;
            8'h02:   cpu_rdata <= #U_DLY `JESD_02_REG;
            8'h03:   cpu_rdata <= #U_DLY `JESD_03_REG;
            8'h05:   cpu_rdata <= #U_DLY `JESD_05_REG;
            8'h06:   cpu_rdata <= #U_DLY `JESD_06_REG;
            8'h10:   cpu_rdata <= #U_DLY `JESD_10_REG; 
            8'h11:   cpu_rdata <= #U_DLY `JESD_11_REG;
            8'h12:   cpu_rdata <= #U_DLY `JESD_12_REG;
            8'h13:   cpu_rdata <= #U_DLY `JESD_13_REG;
            8'h14:   cpu_rdata <= #U_DLY `JESD_14_REG; 
            8'h20:   cpu_rdata <= #U_DLY `JESD_20_REG; 
            8'h21:   cpu_rdata <= #U_DLY `JESD_21_REG; 
            8'h22:   cpu_rdata <= #U_DLY `JESD_22_REG; 
            8'h23:   cpu_rdata <= #U_DLY `JESD_23_REG; 
            8'h24:   cpu_rdata <= #U_DLY `JESD_24_REG; 
            8'h25:   cpu_rdata <= #U_DLY `JESD_25_REG; 
            8'h26:   cpu_rdata <= #U_DLY `JESD_26_REG; 
            8'h80:   cpu_rdata <= #U_DLY `JESD_80_REG;
            8'h90:   cpu_rdata <= #U_DLY `JESD_90_REG;
            8'h91:   cpu_rdata <= #U_DLY `JESD_91_REG;
            default: cpu_rdata <= #U_DLY  32'd0;
        endcase
    end
    else;
end

// write
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
    begin
        `JESD_02_REG <= #U_DLY 32'd0;
        `JESD_03_REG <= #U_DLY 32'd0;
        `JESD_05_REG <= #U_DLY 32'd0;
        `JESD_06_REG <= #U_DLY 32'd0;
        `JESD_10_REG <= #U_DLY 32'd0;
        `JESD_11_REG <= #U_DLY 32'd0;
        `JESD_12_REG <= #U_DLY 32'd0;
        `JESD_20_REG <= #U_DLY 32'd0;
        `JESD_21_REG <= #U_DLY 32'd0;
        `JESD_22_REG <= #U_DLY 32'd0;
        `JESD_23_REG <= #U_DLY 32'd0;
        `JESD_24_REG <= #U_DLY 32'd0;
        `JESD_25_REG <= #U_DLY 32'd0;
        `JESD_26_REG <= #U_DLY 32'd0;
    end
    else if (cpu_wren == 1'b1)
    begin
        case(cpu_addr)
            8'h02:   `JESD_02_REG <= #U_DLY  cpu_wdata;
            8'h03:   `JESD_03_REG <= #U_DLY ~cpu_wdata;
            8'h05:   `JESD_05_REG <= #U_DLY  cpu_wdata;
            8'h06:   `JESD_06_REG <= #U_DLY  cpu_wdata;
            8'h10:   `JESD_10_REG <= #U_DLY  cpu_wdata;
            8'h11:   `JESD_11_REG <= #U_DLY  cpu_wdata;
            8'h12:   `JESD_12_REG <= #U_DLY  cpu_wdata;
            8'h20:   `JESD_20_REG <= #U_DLY  cpu_wdata;
            8'h21:   `JESD_21_REG <= #U_DLY  cpu_wdata;
            8'h22:   `JESD_22_REG <= #U_DLY  cpu_wdata;
            8'h23:   `JESD_23_REG <= #U_DLY  cpu_wdata;
            8'h24:   `JESD_24_REG <= #U_DLY  cpu_wdata;
            8'h25:   `JESD_25_REG <= #U_DLY  cpu_wdata;
            8'h26:   `JESD_26_REG <= #U_DLY  cpu_wdata;
            default: ;
        endcase
    end
    else;
end
/////////////////////////////////////////////////////////////////////////////////////
always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
    begin
        axi_wr_flag <= #U_DLY 1'b0;
        axi_rd_flag <= #U_DLY 1'b0;
    end
    else
    begin
        axi_wr_flag <= #U_DLY lb2axi_enb[0];
        axi_rd_flag <= #U_DLY lb2axi_enb[1];
    end
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        s_axi_awvalid <= #U_DLY 1'b0;
    else if (lb2axi_enb[0] == 1'b1 && axi_wr_flag == 1'b0)
        s_axi_awvalid <= #U_DLY 1'b1;
    else if (s_axi_awready == 1'b1)
        s_axi_awvalid <= #U_DLY 1'b0;
    else;
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        s_axi_awaddr <= #U_DLY 12'd0;
    else if (lb2axi_enb[0] == 1'b1 && axi_wr_flag == 1'b0)
        s_axi_awaddr <= #U_DLY lb2axi_addr[11:0];
    else;
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        s_axi_wvalid <= #U_DLY 1'b0;
    else if (lb2axi_enb[0] == 1'b1 && axi_wr_flag == 1'b0)
        s_axi_wvalid <= #U_DLY 1'b1;
    else if (s_axi_wready == 1'b1)
        s_axi_wvalid <= #U_DLY 1'b0;
    else;
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        s_axi_wdata <= #U_DLY 12'd0;
    else if (lb2axi_enb[0] == 1'b1 && axi_wr_flag == 1'b0)
        s_axi_wdata <= #U_DLY lb2axi_data;
    else;
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        s_axi_arvalid <= #U_DLY 1'b0;
    else if (lb2axi_enb[1] == 1'b1 && axi_rd_flag == 1'b0)
        s_axi_arvalid <= #U_DLY 1'b1;
    else if (s_axi_arready == 1'b1)
        s_axi_arvalid <= #U_DLY 1'b0;
    else;
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        s_axi_araddr <= #U_DLY 12'd0;
    else if (lb2axi_enb[1] == 1'b1 && axi_rd_flag == 1'b0)
        s_axi_araddr <= #U_DLY lb2axi_addr[11:0];
    else;
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        axi2lb_data <= #U_DLY 32'd0;
    else if (s_axi_rvalid == 1'b1)
        axi2lb_data <= #U_DLY s_axi_rdata;
    else;
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        axi_wr_busy <= #U_DLY 1'b0;
    else if (lb2axi_enb[0] == 1'b1 && axi_wr_flag == 1'b0)
        axi_wr_busy <= #U_DLY 1'b1;
    else if (s_axi_awvalid == 1'b0 && s_axi_wvalid == 1'b0)
        axi_wr_busy <= #U_DLY 1'b0;
    else;
end

always @ (posedge clk or posedge rst)
begin
    if (rst == 1'b1)
        axi_rd_busy <= #U_DLY 1'b0;
    else if (lb2axi_enb[1] == 1'b1 && axi_rd_flag == 1'b0)
        axi_rd_busy <= #U_DLY 1'b1;
    else if (s_axi_arvalid == 1'b0)
        axi_rd_busy <= #U_DLY 1'b0;
    else;
end
/////////////////////////////////////////////////////////////////////////////////////
//yangyong 20191224
assign cpu_read_en = cpu_rden;
alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (8                          ),
    .ALARM_HIS_ADDR             (8'h80                      )
)
u_his_tx_loss_sync(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (tx_loss_sync               ),
    .alarm_history              (his_tx_loss_sync           )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (8                          ),
    .ALARM_HIS_ADDR             (8'h80                      )
)
u_his_pll_unlock(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (pll_unlock                 ),
    .alarm_history              (his_pll_unlock             )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (8                          ),
    .ALARM_HIS_ADDR             (8'h80                      )
)
u_his_qpll_unlock(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (qpll_unlock                ),
    .alarm_history              (his_qpll_unlock            )
);
//alarm current
alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (32                         )
)
u_cur_glbl_freq_cnt(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (glbl_freq_cnt              ),
    .alarm_current              (cur_glbl_freq_cnt          )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (10                         )
)
u_cur_sysref_cnt(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (sysref_cnt                 ),
    .alarm_current              (cur_sysref_cnt             )
);

endmodule

