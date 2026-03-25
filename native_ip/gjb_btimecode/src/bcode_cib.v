// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/11/14 10:08:46
// File Name    : bcode_cib.v
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
`define BCODE_00 {VERSION}
`define BCODE_01 {YEAR,MONTH,DAY}
`define BCODE_02 {test_reg}
`define BCODE_03 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,rtc_mode,fill11,fill10,fill9,rtc_rst,fill7,fill6,fill5,sec_framehead_en,fill3,fill2,tx_en,rx_en}
`define BCODE_04 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,his_rec_p_err,his_vld_time_out,his_rx_loss_signal}
`define BCODE_06 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,ctl_neg_cnt_low}
`define BCODE_07 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,ctl_neg_cnt_high}
`define BCODE_08 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,zero_neg_cnt_low}
`define BCODE_09 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,zero_neg_cnt_high}
`define BCODE_0A {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,one_neg_cnt_low}
`define BCODE_0B {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,one_neg_cnt_high}
`define BCODE_0C {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,ms9_5_cnt}
`define BCODE_10 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,stat_restart}
`define BCODE_11 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,cur_rx_pos_cnt_max}
`define BCODE_12 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,cur_rx_pos_cnt_min}
`define BCODE_13 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,cur_rx_pulse_cnt_max}
`define BCODE_14 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,cur_rx_pulse_cnt_min}
`define BCODE_15 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,cur_l2_state,fill3,cur_l1_state}
`define BCODE_16 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,cfg_nanosec_offset}
`define BCODE_20 {fill31,fill30,fill29,cur_bcode_hour,fill23,fill22,fill21,cur_bcode_day,cur_bcode_year}
`define BCODE_21 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,cur_bcode_sec,fill7,fill6,cur_bcode_min}
`define BCODE_22 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,cur_str_sec}
`define BCODE_23 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,cur_ctl_1func,fill15,fill14,fill13,fill12,fill11,fill10,fill9,cur_ctl_0func}
`define BCODE_30 {fill31,fill30,fill29,cur_rtc_hour,fill23,fill22,fill21,cur_rtc_day,cur_rtc_year}
`define BCODE_31 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,cur_rtc_sec,fill7,fill6,cur_rtc_min}
`define BCODE_32 {fill31,fill30,fill29,fill28,fill27,fill26,cur_rtc_microsec,fill15,fill14,fill13,fill12,fill11,fill10,cur_rtc_msec}
`define BCODE_33 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,cur_rtc_str_sec}
`define BCODE_40 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,zero_neg_cnt}
`define BCODE_41 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,one_neg_cnt}
`define BCODE_42 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,ctl_neg_cnt}
`define BCODE_43 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,ctl_1_func,fill15,fill14,fill13,fill12,fill11,fill10,fill9,ctl_0_func}
`define BCODE_50 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,cfg_en}
`define BCODE_51 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,cfg_day,fill15,fill14,fill13,fill12,cfg_year}
`define BCODE_52 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,cfg_sec,fill15,fill14,cfg_min,fill7,fill6,fill5,cfg_hour}
`define BCODE_53 {fill31,fill30,fill29,fill28,fill27,fill26,cfg_microsec,fill15,fill14,fill13,fill12,fill11,fill10,cfg_msec}

`define BCODE_60 {sfh_pulse_freq}

module bcode_cib #(
parameter                           U_DLY = 1,
parameter                           CPU_ADDR_W = 8,
parameter                           VERSION =32'h00_00_00_01,
parameter                           YEAR = 16'h20_19,
parameter                           MONTH = 8'h09,
parameter                           DAY = 8'h10
)
(
input                               clk,
input                               rst,
//cpu bus
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [CPU_ADDR_W - 1:0]  cpu_addr,
input           [31:0]              cpu_wdata,
output  reg     [31:0]              cpu_rdata,
//others config
output reg                          rx_en,
output reg                          tx_en,
output reg                          rtc_rst,
output reg                          rtc_mode,
output reg      [19:0]              ctl_neg_cnt_low,
output reg      [19:0]              ctl_neg_cnt_high,
output reg      [19:0]              zero_neg_cnt_low,
output reg      [19:0]              zero_neg_cnt_high,
output reg      [19:0]              one_neg_cnt_low,
output reg      [19:0]              one_neg_cnt_high,
output reg      [19:0]              ms9_5_cnt,                  //9.5ms
output reg                          stat_restart,
input           [19:0]              rx_pos_cnt_max,
input           [19:0]              rx_pos_cnt_min,
input           [19:0]              rx_pulse_cnt_max,
input           [19:0]              rx_pulse_cnt_min,
input                               rx_loss_signal,
input           [11:0]              bcode_year,
input           [8:0]               bcode_day,
input           [4:0]               bcode_hour,
input           [5:0]               bcode_min,
input           [5:0]               bcode_sec,
input           [16:0]              str_sec,
input           [8:0]               ctl_0func,
input           [8:0]               ctl_1func,
input                               vld_time_out,
input                               rec_p_err,
input           [2:0]               l1_state,
input           [3:0]               l2_state,
output reg                          sec_framehead_en,
output reg      [9:0]               cfg_nanosec_offset,
input           [11:0]              rtc_year,
input           [8:0]               rtc_day,
input           [4:0]               rtc_hour,
input           [5:0]               rtc_min,
input           [5:0]               rtc_sec,
input           [9:0]               rtc_msec,
input           [9:0]               rtc_microsec,
input           [16:0]              rtc_str_sec,
output  reg     [19:0]              zero_neg_cnt,
output  reg     [19:0]              one_neg_cnt,
output  reg     [19:0]              ctl_neg_cnt,
output  reg     [8:0]               ctl_0_func,
output  reg     [8:0]               ctl_1_func,
output  reg                         cfg_en,
output  reg     [11:0]              cfg_year,
output  reg     [8:0]               cfg_day,
output  reg     [4:0]               cfg_hour,
output  reg     [5:0]               cfg_min,
output  reg     [5:0]               cfg_sec,
output  reg     [9:0]               cfg_msec,
output  reg     [9:0]               cfg_microsec,

input           [1:0]               rx_sfh_dly,
output  reg     [31:0]              sfh_pulse_cnt,
output  reg     [31:0]              sfh_pulse_freq
);
// Parameter Define 

// Register Define 
reg                fill1;
reg                fill2;
reg                fill3;
reg                fill4;
reg                fill5;
reg                fill6;
reg                fill7;
reg                fill8;
reg                fill9;
reg                fill10;
reg                fill11;
reg                fill12;
reg                fill13;
reg                fill14;
reg                fill15;
reg                fill16;
reg                fill17;
reg                fill18;
reg                fill19;
reg                fill20;
reg                fill21;
reg                fill22;
reg                fill23;
reg                fill24;
reg                fill25;
reg                fill26;
reg                fill27;
reg                fill28;
reg                fill29;
reg                fill30;
reg                fill31;
reg                cpu_we_dly;
reg                cpu_rd_dly;
reg  [31:0]        test_reg;
reg                rtc_sec_low_dly;
// Wire Define 
wire                                cpu_read_en;
wire                                his_rx_loss_signal;
wire    [19:0]                      cur_rx_pos_cnt_max;
wire    [19:0]                      cur_rx_pos_cnt_min;
wire    [19:0]                      cur_rx_pulse_cnt_max;
wire    [19:0]                      cur_rx_pulse_cnt_min;
wire    [11:0]                      cur_bcode_year;
wire    [8:0]                       cur_bcode_day;
wire    [4:0]                       cur_bcode_hour;
wire    [5:0]                       cur_bcode_min;
wire    [5:0]                       cur_bcode_sec;
wire    [16:0]                      cur_str_sec;
wire    [8:0]                       cur_ctl_0func;
wire    [8:0]                       cur_ctl_1func;
wire                                his_vld_time_out;
wire                                his_rec_p_err;
wire    [2:0]                       cur_l1_state;
wire    [3:0]                       cur_l2_state;
wire    [11:0]                      cur_rtc_year;
wire    [8:0]                       cur_rtc_day;
wire    [4:0]                       cur_rtc_hour;
wire    [5:0]                       cur_rtc_min;
wire    [5:0]                       cur_rtc_sec;
wire    [9:0]                       cur_rtc_msec;
wire    [9:0]                       cur_rtc_microsec;
wire    [16:0]                      cur_rtc_str_sec;


always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cpu_we_dly <= 1'b1;
            cpu_rd_dly <= 1'b1;
        end
    else
        begin
            cpu_we_dly <= #U_DLY cpu_we;
            cpu_rd_dly <= #U_DLY cpu_rd;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            `BCODE_02 <= 32'h0000_0000;
            `BCODE_03 <= 32'h0000_1000;
            `BCODE_06 <= 32'h000C_0000; //7.99984ms
            `BCODE_07 <= 32'h000C_4100; //8.00016ms
            `BCODE_08 <= 32'h0002_ed30; //1.99984ms
            `BCODE_09 <= 32'h0003_1d50; //2.00016ms            
            `BCODE_0A <= 32'h0007_9110; //4.99984ms            
            `BCODE_0B <= 32'h0007_b130; //5.00016ms            
            `BCODE_0C <= 32'h000E_7EF0; //9.50000ms            
            `BCODE_10 <= 32'h0000_0000;           
            `BCODE_16 <= 32'h0000_0005; //50ns           
            `BCODE_40 <= 32'h0003_0d40; //2ms           
            `BCODE_41 <= 32'h0007_A120; //5ms           
            `BCODE_42 <= 32'h000C_3500; //8ms           
            `BCODE_43 <= 32'h0000_0000;         
            `BCODE_50 <= 32'h0000_0000;         
            `BCODE_51 <= 32'h0000_0000;         
            `BCODE_52 <= 32'h0000_0000;         
            `BCODE_53 <= 32'h0000_0000;         
        end
    else
        begin
            if({cpu_we_dly,cpu_we} == 2'b10 && cpu_cs == 1'b0)
                 begin
                    case(cpu_addr)
                        7'h02:`BCODE_02 <= #U_DLY ~cpu_wdata;        
                        7'h03:`BCODE_03 <= #U_DLY cpu_wdata;        
                        7'h06:`BCODE_06 <= #U_DLY cpu_wdata;        
                        7'h07:`BCODE_07 <= #U_DLY cpu_wdata;
                        7'h08:`BCODE_08 <= #U_DLY cpu_wdata;        
                        7'h09:`BCODE_09 <= #U_DLY cpu_wdata;                        
                        7'h0A:`BCODE_0A <= #U_DLY cpu_wdata;                        
                        7'h0B:`BCODE_0B <= #U_DLY cpu_wdata;                        
                        7'h0C:`BCODE_0C <= #U_DLY cpu_wdata;                        
                        7'h10:`BCODE_10 <= #U_DLY cpu_wdata;                        
                        7'h16:`BCODE_16 <= #U_DLY cpu_wdata;                        
                        7'h40:`BCODE_40 <= #U_DLY cpu_wdata;                        
                        7'h41:`BCODE_41 <= #U_DLY cpu_wdata;                        
                        7'h42:`BCODE_42 <= #U_DLY cpu_wdata;                        
                        7'h43:`BCODE_43 <= #U_DLY cpu_wdata;  
                        7'h50:`BCODE_50 <= #U_DLY cpu_wdata; 
                        7'h51:`BCODE_51 <= #U_DLY cpu_wdata; 
                        7'h52:`BCODE_52 <= #U_DLY cpu_wdata; 
                        7'h53:`BCODE_53 <= #U_DLY cpu_wdata;                         
                        default:;
                    endcase
                end
            else           
                {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1} <= #U_DLY 'd0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        cpu_rdata <= 'd0;
    else
        begin
            if({cpu_rd_dly,cpu_rd} == 2'b10 && cpu_cs == 1'b0)
                 begin
                    case(cpu_addr)
                        7'h00:cpu_rdata <= #U_DLY `BCODE_00;     
                        7'h01:cpu_rdata <= #U_DLY `BCODE_01;  
                        7'h02:cpu_rdata <= #U_DLY `BCODE_02;                          
                        7'h03:cpu_rdata <= #U_DLY `BCODE_03;                          
                        7'h04:cpu_rdata <= #U_DLY `BCODE_04;                          
                        7'h06:cpu_rdata <= #U_DLY `BCODE_06;                          
                        7'h07:cpu_rdata <= #U_DLY `BCODE_07;  
                        7'h08:cpu_rdata <= #U_DLY `BCODE_08;                          
                        7'h09:cpu_rdata <= #U_DLY `BCODE_09;
                        7'h0A:cpu_rdata <= #U_DLY `BCODE_0A;
                        7'h0B:cpu_rdata <= #U_DLY `BCODE_0B;
                        7'h0C:cpu_rdata <= #U_DLY `BCODE_0C;
                        7'h10:cpu_rdata <= #U_DLY `BCODE_10;
                        7'h11:cpu_rdata <= #U_DLY `BCODE_11;
                        7'h12:cpu_rdata <= #U_DLY `BCODE_12;
                        7'h13:cpu_rdata <= #U_DLY `BCODE_13;
                        7'h14:cpu_rdata <= #U_DLY `BCODE_14;
                        7'h15:cpu_rdata <= #U_DLY `BCODE_15;
                        7'h16:cpu_rdata <= #U_DLY `BCODE_16;
                        7'h20:cpu_rdata <= #U_DLY `BCODE_20;
                        7'h21:cpu_rdata <= #U_DLY `BCODE_21;
                        7'h22:cpu_rdata <= #U_DLY `BCODE_22;
                        7'h23:cpu_rdata <= #U_DLY `BCODE_23;
                        7'h30:cpu_rdata <= #U_DLY `BCODE_30;
                        7'h31:cpu_rdata <= #U_DLY `BCODE_31;
                        7'h32:cpu_rdata <= #U_DLY `BCODE_32;
                        7'h33:cpu_rdata <= #U_DLY `BCODE_33;
                        7'h40:cpu_rdata <= #U_DLY `BCODE_40;
                        7'h41:cpu_rdata <= #U_DLY `BCODE_41;
                        7'h42:cpu_rdata <= #U_DLY `BCODE_42;
                        7'h43:cpu_rdata <= #U_DLY `BCODE_43;
                        7'h50:cpu_rdata <= #U_DLY `BCODE_50;
                        7'h51:cpu_rdata <= #U_DLY `BCODE_51;
                        7'h52:cpu_rdata <= #U_DLY `BCODE_52;
                        7'h53:cpu_rdata <= #U_DLY `BCODE_53;
                        7'h60:cpu_rdata <= #U_DLY `BCODE_60;
                        default:cpu_rdata <= #U_DLY 'd0;
                    endcase
                end
            else;
        end
end
//
assign cpu_read_en = ({cpu_rd_dly,cpu_rd} == 2'b10 && cpu_cs == 1'b0) ? 1'b1 : 1'b0;
//histrory alarm
alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h4                        )
)
u_alm_his_rx_loss_signal(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (rx_loss_signal             ),
    .alarm_history              (his_rx_loss_signal         )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h4                        )
)
u_alm_his_rx_vld_time_out(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (vld_time_out               ),
    .alarm_history              (his_vld_time_out           )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h4                        )
)
u_alm_his_rx_rec_p_err(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (rec_p_err                  ),
    .alarm_history              (his_rec_p_err              )
);
//current alarm
alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (20                         )
)
u_alarm_cur_rx_pos_cnt_max(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rx_pos_cnt_max             ),
    .alarm_current              (cur_rx_pos_cnt_max         )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (20                         )
)
u_alarm_cur_rx_pos_cnt_min(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rx_pos_cnt_min             ),
    .alarm_current              (cur_rx_pos_cnt_min         )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (20                         )
)
u_alarm_cur_rx_pulse_cnt_max(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rx_pulse_cnt_max           ),
    .alarm_current              (cur_rx_pulse_cnt_max       )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (20                         )
)
u_alarm_cur_rx_pulse_cnt_min(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rx_pulse_cnt_min           ),
    .alarm_current              (cur_rx_pulse_cnt_min       )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (12                         )
)
u_alarm_cur_bcode_year(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (bcode_year                 ),
    .alarm_current              (cur_bcode_year             )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (9                          )
)
u_alarm_cur_bcode_day(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (bcode_day                  ),
    .alarm_current              (cur_bcode_day              )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (5                          )
)
u_alarm_cur_bcode_hour(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (bcode_hour                 ),
    .alarm_current              (cur_bcode_hour             )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (6                          )
)
u_alarm_cur_bcode_min(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (bcode_min                  ),
    .alarm_current              (cur_bcode_min              )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (6                          )
)
u_alarm_cur_bcode_sec(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (bcode_sec                  ),
    .alarm_current              (cur_bcode_sec              )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (17                         )
)
u_alarm_cur_str_sec(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (str_sec                    ),
    .alarm_current              (cur_str_sec                )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (9                          )
)
u_alarm_cur_ctl_0func(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (ctl_0func                  ),
    .alarm_current              (cur_ctl_0func              )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (9                          )
)
u_alarm_cur_ctl_1func(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (ctl_1func                  ),
    .alarm_current              (cur_ctl_1func              )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (3                          )
)
u_alarm_cur_l1_state(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (l1_state                   ),
    .alarm_current              (cur_l1_state               )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (4                          )
)
u_alarm_cur_l2_state(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (l2_state                   ),
    .alarm_current              (cur_l2_state               )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (12                         )
)
u_alarm_cur_rtc_year(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rtc_year                   ),
    .alarm_current              (cur_rtc_year               )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (9                          )
)
u_alarm_cur_rtc_day(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rtc_day                    ),
    .alarm_current              (cur_rtc_day                )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (5                          )
)
u_alarm_cur_rtc_hour(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rtc_hour                   ),
    .alarm_current              (cur_rtc_hour               )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (6                          )
)
u_alarm_cur_rtc_min(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rtc_min                    ),
    .alarm_current              (cur_rtc_min                )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (6                          )
)
u_alarm_cur_rtc_sec(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rtc_sec                    ),
    .alarm_current              (cur_rtc_sec                )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (10                         )
)
u_alarm_cur_rtc_msec(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rtc_msec                   ),
    .alarm_current              (cur_rtc_msec               )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (10                         )
)
u_alarm_cur_rtc_microsec(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rtc_microsec               ),
    .alarm_current              (cur_rtc_microsec           )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (17                         )
)
u_alarm_cur_rtc_str_sec(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (rtc_str_sec                ),
    .alarm_current              (cur_rtc_str_sec            )
);


always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            sfh_pulse_cnt <= 'd0;
            sfh_pulse_freq <= 'd0;
            rtc_sec_low_dly <= 1'b0;
        end
    else
        begin
            rtc_sec_low_dly <= #U_DLY rtc_sec[0];

            if((rtc_mode == 1'b1 && rx_sfh_dly == 2'b01) || (rtc_mode == 1'b0 && rtc_sec_low_dly ^ rtc_sec[0] == 1'b1))
                sfh_pulse_cnt <= #U_DLY 'd0;
            else
                sfh_pulse_cnt <= #U_DLY sfh_pulse_cnt + 'd1;

            if((rtc_mode == 1'b1 && rx_sfh_dly == 2'b01) || (rtc_mode == 1'b0 && rtc_sec_low_dly ^ rtc_sec[0] == 1'b1))
                sfh_pulse_freq <= #U_DLY sfh_pulse_cnt;
            else;
        end
end

endmodule


