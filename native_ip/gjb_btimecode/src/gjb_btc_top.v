// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2019/8/30 15:46:44
// File Name    : gjb_btc_top.v
// Module Name  : 
// Called By    :
// Abstract     : GJB 2991A-2008 B time code
//
// CopyRight(c) 2019, BoYuLiHua Co., Ltd.. 
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
//`define SIM_ENABLE
//`define AUTHORIZE_ENABLE
module gjb_btc_top #(
parameter                           U_DLY = 1,
parameter                           CPU_ADDR_W = 8
)
(
input                               clk,                      //100M
input                               rst,
input                               hard_rst,
//authorization 
input           [31:0]              authorize_code,
//io
input                               btc_rx,                   //io
output                              btc_tx,

input                               btc_1pps,                 //second frame header,1pps
//localbus
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [CPU_ADDR_W - 1:0]  cpu_addr,
input           [31:0]              cpu_wdata,
output wire     [31:0]              cpu_rdata,
//rtc time
output wire     [11:0]              rtc_year,
output wire     [8:0]               rtc_day,
output wire     [4:0]               rtc_hour,
output wire     [5:0]               rtc_min,
output wire     [5:0]               rtc_sec,
output wire     [9:0]               rtc_msec,
output wire     [9:0]               rtc_microsec,
output wire     [9:0]               rtc_nanosec,
output wire                         rtc_timing_1s,
//
output wire     [31:0]              sfh_pulse_cnt,
output wire     [31:0]              sfh_pulse_freq,
output wire                         bcode_chok
);
// Parameter Define 

// Register Define 

// Wire Define 
wire    [1:0]                       rx_ind;
wire    [11:0]                      bcode_year;
wire    [8:0]                       bcode_day;
wire    [4:0]                       bcode_hour;
wire    [5:0]                       bcode_min;
wire    [5:0]                       bcode_sec;
wire    [16:0]                      str_sec;
wire    [16:0]                      rtc_str_sec;
wire    [7:0]                       bcd_year;
wire    [9:0]                       bcd_day;
wire    [5:0]                       bcd_hour;
wire    [6:0]                       bcd_min;
wire    [6:0]                       bcd_sec;
wire    [16:0]                      bin_str_sec;
wire    [19:0]                      ctl_neg_cnt_low;
wire    [19:0]                      ctl_neg_cnt_high;
wire    [19:0]                      zero_neg_cnt_low;
wire    [19:0]                      zero_neg_cnt_high;
wire    [19:0]                      one_neg_cnt_low;
wire    [19:0]                      one_neg_cnt_high;
wire    [19:0]                      ms9_5_cnt;
wire    [19:0]                      rx_pos_cnt_max;
wire    [19:0]                      rx_pos_cnt_min;
wire    [19:0]                      rx_pulse_cnt_max;
wire    [19:0]                      rx_pulse_cnt_min;
wire    [8:0]                       ctl_0func;
wire    [8:0]                       ctl_1func;
wire    [2:0]                       l1_state;
wire    [3:0]                       l2_state;
wire    [9:0]                       cfg_nanosec_offset;
wire    [19:0]                      zero_neg_cnt;
wire    [19:0]                      one_neg_cnt;
wire    [19:0]                      ctl_neg_cnt;
wire    [8:0]                       ctl_0_func;
wire    [8:0]                       ctl_1_func;
wire    [9:0]                       bcode_msec;
wire    [9:0]                       bcode_microsec;
wire    [9:0]                       bcode_nanosec;
wire    [9:0]                       cfg_microsec;
wire    [9:0]                       cfg_msec;
wire    [5:0]                       cfg_sec;
wire    [5:0]                       cfg_min;
wire    [4:0]                       cfg_hour;
wire    [8:0]                       cfg_day;
wire    [11:0]                      cfg_year;
wire    [1:0]                       rx_sfh_dly;

bcode_rx_phy #(
    .U_DLY                      (U_DLY                      )
)
u_bcode_rx_phy(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//io
    .bcode_rx                   (btc_rx                     ),
//
    .rx_vld                     (rx_vld                     ),
    .rx_ind                     (rx_ind                     ),

    .millsec10_pulse            (millsec10_pulse            ),
//for debug
    .rx_en                      (rx_en                      ),
    .ctl_neg_cnt_low            (ctl_neg_cnt_low            ),
    .ctl_neg_cnt_high           (ctl_neg_cnt_high           ),
    .zero_neg_cnt_low           (zero_neg_cnt_low           ),
    .zero_neg_cnt_high          (zero_neg_cnt_high          ),
    .one_neg_cnt_low            (one_neg_cnt_low            ),
    .one_neg_cnt_high           (one_neg_cnt_high           ),
    .ms9_5_cnt                  (ms9_5_cnt                  ),
    .stat_restart               (stat_restart               ),
    .rx_pos_cnt_max             (rx_pos_cnt_max             ),
    .rx_pos_cnt_min             (rx_pos_cnt_min             ),
    .rx_pulse_cnt_max           (rx_pulse_cnt_max           ),
    .rx_pulse_cnt_min           (rx_pulse_cnt_min           ),
    .rx_loss_signal             (rx_loss_signal             ),
    .bcode_chok                 (bcode_chok                 )
);

bcode_rx_stm #(
    .U_DLY                      (U_DLY                      )
)
u_bcode_rx_stm(
    .clk                        (clk                        ),
    .rst                        (rst                        ),

    .rx_sfh                     (btc_1pps                   ),
//
    .rx_vld                     (rx_vld                     ),
    .rx_ind                     (rx_ind                     ),

    .millsec10_pulse            (millsec10_pulse            ),
//
    .bcode_time_vld             (bcode_time_vld             ),
    .bcode_year                 (bcode_year                 ),
    .bcode_day                  (bcode_day                  ),
    .bcode_hour                 (bcode_hour                 ),
    .bcode_min                  (bcode_min                  ),
    .bcode_sec                  (bcode_sec                  ),
    .bcode_msec                 (bcode_msec                 ),
    .bcode_microsec             (bcode_microsec             ),
    .bcode_nanosec              (bcode_nanosec              ),
    .rx_sfh_dly                 (rx_sfh_dly                 ),
    .str_sec                    (str_sec                    ),
    .str_sec_vld                (str_sec_vld                ),
    .ctl_0func                  (ctl_0func                  ),
    .ctl_1func                  (ctl_1func                  ),
//debug
    .vld_time_out               (vld_time_out               ),
    .rec_p_err                  (rec_p_err                  ),
    .l1_state                   (l1_state                   ),
    .l2_state                   (l2_state                   ),
    .sec_framehead_en           (sec_framehead_en           ),
    .cfg_nanosec_offset         (cfg_nanosec_offset         ),
`ifdef AUTHORIZE_ENABLE 
    .authorize_succ             (authorize_succ             )
`else
    .authorize_succ             (1'b1                       )
`endif
);

rtc_nanosec #(
    .U_DLY                      (U_DLY                      )
)
u_rtc_nanosec(
    .rst                        (hard_rst | rtc_rst         ),
    .clk                        (clk                        ),
    .rtc_mode                   (rtc_mode                   ),
//config interface
    .cfg_en                     (cfg_time_vld               ),
    .cfg_year                   (cfg_year                   ),
    .cfg_day                    (cfg_day                    ),
    .cfg_hour                   (cfg_hour                   ),
    .cfg_min                    (cfg_min                    ),
    .cfg_sec                    (cfg_sec                    ),
    .cfg_msec                   (cfg_msec                   ),
    .cfg_microsec               (cfg_microsec               ),
    .cfg_nanosec                (10'd0                      ),
//bcode interface
    .bcode_en                   (bcode_time_vld             ),
    .bcode_year                 (bcode_year                 ),
    .bcode_day                  (bcode_day                  ),
    .bcode_hour                 (bcode_hour                 ),
    .bcode_min                  (bcode_min                  ),
    .bcode_sec                  (bcode_sec                  ),
    .bcode_msec                 (bcode_msec                 ),
    .bcode_microsec             (bcode_microsec             ),
    .bcode_nanosec              (bcode_nanosec              ),
    .rx_sfh_dly                 (rx_sfh_dly                 ),
//RTC time
    .rtc_year                   (rtc_year                   ),
    .rtc_day                    (rtc_day                    ),
    .rtc_hour                   (rtc_hour                   ),
    .rtc_min                    (rtc_min                    ),
    .rtc_sec                    (rtc_sec                    ),
    .rtc_msec                   (rtc_msec                   ),
    .rtc_microsec               (rtc_microsec               ),
    .rtc_nanosec                (rtc_nanosec                ),
    .rtc_timing_1s              (rtc_timing_1s              ),
//straight binary seconds
    .str_sec                    (str_sec                    ),
    .str_sec_vld                (str_sec_vld                ),
    .rtc_str_sec                (rtc_str_sec                ),
//for bcode tx
    .nanosec_carry              (nanosec_carry              ),
    .microsec_carry             (microsec_carry             ),
    .msec_carry                 (msec_carry                 )
);

bocde_tx_timepro #(
    .U_DLY                      (U_DLY                      )
)
u_bocde_tx_timepro(
//clock
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//
    .bcd_time_vld               (bcd_time_vld               ),
    .bcd_year                   (bcd_year                   ),
    .bcd_day                    (bcd_day                    ),
    .bcd_hour                   (bcd_hour                   ),
    .bcd_min                    (bcd_min                    ),
    .bcd_sec                    (bcd_sec                    ),
    .bin_str_sec                (bin_str_sec                ),
//interface with RTC
`ifndef SIM_ENABLE
    .rtc_year                   (rtc_year                   ),
    .rtc_day                    (rtc_day                    ),
    .rtc_hour                   (rtc_hour                   ),
    .rtc_min                    (rtc_min                    ),
    .rtc_sec                    (rtc_sec                    ),
    .rtc_str_sec                (rtc_str_sec                ),
`else
    .rtc_year                   ('d2003                     ),
    .rtc_day                    ('d173                      ),
    .rtc_hour                   ('d21                       ),
    .rtc_min                    ('d18                       ),
    .rtc_sec                    ('d42                       ),
    .rtc_str_sec                ('d76722                    ),
`endif
    .nanosec_carry              (nanosec_carry              ),
    .microsec_carry             (microsec_carry             ),
    .msec_carry                 (msec_carry                 ),
//debug
    .tx_en                      (tx_en                      ),
//
`ifdef AUTHORIZE_ENABLE 
    .authorize_succ             (authorize_succ             )
`else
    .authorize_succ             (1'b1                       )
`endif
);

bcode_tx_phy #(
    .U_DLY                      (U_DLY                      )
)
u_bcode_tx_phy(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//
    .bcode_tx                   (btc_tx                     ),
//interface with tx_stm
    .bcd_time_vld               (bcd_time_vld               ),
    .bcd_year                   (bcd_year                   ),
    .bcd_day                    (bcd_day                    ),
    .bcd_hour                   (bcd_hour                   ),
    .bcd_min                    (bcd_min                    ),
    .bcd_sec                    (bcd_sec                    ),
    .bin_str_sec                (bin_str_sec                ),
`ifndef SIM_ENABLE
    .ctl_0_func                 (ctl_0_func                 ),
    .ctl_1_func                 (ctl_1_func                 ),
`else
    .ctl_0_func                 (9'h155                     ),
    .ctl_1_func                 (9'h0aa                     ),
`endif
//interface with RTC
    .nanosec_carry              (nanosec_carry              ),
    .microsec_carry             (microsec_carry             ),
    .msec_carry                 (msec_carry                 ),
//for debug
    .tx_en                      (tx_en                      ),
    .zero_neg_cnt               (zero_neg_cnt               ),
    .one_neg_cnt                (one_neg_cnt                ),
    .ctl_neg_cnt                (ctl_neg_cnt                )
);

bcode_cib #(
    .U_DLY                      (U_DLY                      )
)
u_bcode_cib(
    .clk                        (clk                        ),
    .rst                        (hard_rst                   ),
//cpu bus
    .cpu_cs                     (cpu_cs                     ),
    .cpu_we                     (cpu_we                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wdata                  (cpu_wdata                  ),
    .cpu_rdata                  (cpu_rdata                  ),
//others config
    .rx_en                      (rx_en                      ),
    .tx_en                      (tx_en                      ),
    .rtc_rst                    (rtc_rst                    ),
    .rtc_mode                   (rtc_mode                   ),
    .ctl_neg_cnt_low            (ctl_neg_cnt_low            ),
    .ctl_neg_cnt_high           (ctl_neg_cnt_high           ),
    .zero_neg_cnt_low           (zero_neg_cnt_low           ),
    .zero_neg_cnt_high          (zero_neg_cnt_high          ),
    .one_neg_cnt_low            (one_neg_cnt_low            ),
    .one_neg_cnt_high           (one_neg_cnt_high           ),
    .ms9_5_cnt                  (ms9_5_cnt                  ),
    .stat_restart               (stat_restart               ),
    .rx_pos_cnt_max             (rx_pos_cnt_max             ),
    .rx_pos_cnt_min             (rx_pos_cnt_min             ),
    .rx_pulse_cnt_max           (rx_pulse_cnt_max           ),
    .rx_pulse_cnt_min           (rx_pulse_cnt_min           ),
    .rx_loss_signal             (rx_loss_signal             ),
    .bcode_year                 (bcode_year                 ),
    .bcode_day                  (bcode_day                  ),
    .bcode_hour                 (bcode_hour                 ),
    .bcode_min                  (bcode_min                  ),
    .bcode_sec                  (bcode_sec                  ),
    .str_sec                    (str_sec                    ),
    .ctl_0func                  (ctl_0func                  ),
    .ctl_1func                  (ctl_1func                  ),
    .vld_time_out               (vld_time_out               ),
    .rec_p_err                  (rec_p_err                  ),
    .l1_state                   (l1_state                   ),
    .l2_state                   (l2_state                   ),
    .sec_framehead_en           (sec_framehead_en           ),
    .cfg_nanosec_offset         (cfg_nanosec_offset         ),
    .rtc_year                   (rtc_year                   ),
    .rtc_day                    (rtc_day                    ),
    .rtc_hour                   (rtc_hour                   ),
    .rtc_min                    (rtc_min                    ),
    .rtc_sec                    (rtc_sec                    ),
    .rtc_msec                   (rtc_msec                   ),
    .rtc_microsec               (rtc_microsec               ),
    .rtc_str_sec                (rtc_str_sec                ),
    .zero_neg_cnt               (zero_neg_cnt               ),
    .one_neg_cnt                (one_neg_cnt                ),
    .ctl_neg_cnt                (ctl_neg_cnt                ),
    .ctl_0_func                 (ctl_0_func                 ),
    .ctl_1_func                 (ctl_1_func                 ),
    .cfg_en                     (cfg_time_vld               ),
    .cfg_year                   (cfg_year                   ),
    .cfg_day                    (cfg_day                    ),
    .cfg_hour                   (cfg_hour                   ),
    .cfg_min                    (cfg_min                    ),
    .cfg_sec                    (cfg_sec                    ),
    .cfg_msec                   (cfg_msec                   ),
    .cfg_microsec               (cfg_microsec               ),
    .rx_sfh_dly                 (rx_sfh_dly                 ),
    .sfh_pulse_cnt              (sfh_pulse_cnt              ),
    .sfh_pulse_freq             (sfh_pulse_freq             )
);

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

