// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/12/14 9:26:26
// File Name    : bd_top.v
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
module bd_top # (
parameter                           U_DLY     = 1,
parameter                           NEMA_ZDA  = "true",
parameter                           NEMA_GGA  = "true",
parameter                           NEMA_RMC  = "true",
parameter                           BAUD_PARA = 12'd1302,
parameter                           US_CNT    = 100 //1000ns = US_CNT*10ns (100MHZ) 
)
(
input                               clk,
input                               rst,
input                               hard_rst,

input                               bd_pps,
output                              bd_rstn,
output                              bd_pwd,
input                               bd_rx_pad,
output                              bd_tx_pad,

input                               cpu_cs,
input                               cpu_wr,
input                               cpu_rd,
input        [7:0]                  cpu_addr,
input        [31:0]                 cpu_wr_data,
output       [31:0]                 cpu_rd_data,

output       [11:0]                 rtc_year,
output       [3:0]                  rtc_month,
output       [4:0]                  rtc_day,
output       [4:0]                  rtc_hour,
output       [5:0]                  rtc_min,
output       [5:0]                  rtc_sec,
output       [9:0]                  rtc_msec,
output       [9:0]                  rtc_microsec,
output       [9:0]                  rtc_nanosec,
output                              rtc_timing_1s,

output       [31:0]                 sfh_pulse_cnt,
output       [31:0]                 sfh_pulse_freq,
output                              bd_utc_chok

);
// Parameter Define
//parameter       BAUD_PARA  = 12'd1302    ; // 100M == 9600 * 8 * BAUD_PARA 
//parameter       BAUD_PARA  = 12'd651    ; // 50M == 9600 * 8 * BAUD_PARA
// Register Define 
reg                                 cfg_en;
reg     [11:0]                      cfg_year;
reg     [3:0]                       cfg_month;
reg     [4:0]                       cfg_day;
reg     [4:0]                       cfg_hour;
reg     [5:0]                       cfg_min;
reg     [5:0]                       cfg_sec;
reg     [9:0]                       cfg_msec;
reg     [9:0]                       cfg_microsec;
reg     [9:0]                       cfg_nanosec;
reg                                 pps_cfg;
reg     [2:0]                       bd_pps_r;
reg     [1:0]                       soft_cfg_r;

// Wire Define
wire                                rx_vld;
wire    [7:0]                       rx_data;
wire                                baud_en;
wire                                bd_soft_rst;
wire    [15:0]                      rmc_wd_word0;
wire    [23:0]                      rmc_wd_word1;
wire    [7:0]                       rmc_wd_dir;
wire    [19:0]                      rmc_jd_word0;
wire    [23:0]                      rmc_jd_word1;
wire    [7:0]                       rmc_jd_dir;
wire    [11:0]                      rmc_utc_year;
wire    [3:0]                       rmc_utc_mon;
wire    [4:0]                       rmc_utc_day;
wire    [4:0]                       rmc_utc_hour;
wire    [5:0]                       rmc_utc_min;
wire    [5:0]                       rmc_utc_sec;
wire                                rmc_utc_vld;
wire    [7:0]                       rmc_position;
wire    [7:0]                       rmc_gspeed0;
wire    [7:0]                       rmc_gspeed1;
wire    [7:0]                       rmc_ghead0;
wire    [7:0]                       rmc_ghead1;
wire    [15:0]                      rmc_id;
wire                                rmc_pps_overtime;
wire                                send;
wire    [7:0]                       send_data;
wire                                send_done;
wire                                tx_vld;
wire    [7:0]                       tx_data;
wire                                tx_busy;
wire    [3:0]                       gga_state;
wire    [7:0]                       gga_satellite;
wire                                gga_vld;
wire                                east;
wire                                west;
wire    [3:0]                       zone_cnt;
wire    [19:0]                      tmo_sec;
wire    [2:0]                       rtc_mode;
wire                                soft_cfg;
wire    [11:0]                      soft_utc_year;
wire    [3:0]                       soft_utc_mon;
wire    [4:0]                       soft_utc_day;
wire    [4:0]                       soft_utc_hour;
wire    [5:0]                       soft_utc_min;
wire    [5:0]                       soft_utc_sec;
wire    [9:0]                       soft_utc_ms;
wire    [9:0]                       soft_utc_us;
wire    [9:0]                       soft_utc_ns;
wire    [9:0]                       u_ms;
wire    [9:0]                       u_us;
wire    [9:0]                       u_ns;
wire                                zda_utc_chok;
wire                                rmc_utc_chok;

//wire    [11:0]                      rtc_year;
//wire    [3:0]                       rtc_month;
//wire    [4:0]                       rtc_day;
//wire    [4:0]                       rtc_hour;
//wire    [5:0]                       rtc_min;
//wire    [5:0]                       rtc_sec;
//wire    [9:0]                       rtc_msec;
//wire    [9:0]                       rtc_microsec;
//wire    [9:0]                       rtc_nanosec;


wire   [11:0]                       zda_utc_year;
wire   [3:0]                        zda_utc_mon;
wire   [4:0]                        zda_utc_day;
wire   [4:0]                        zda_utc_hour;
wire   [5:0]                        zda_utc_min;
wire   [5:0]                        zda_utc_sec;

wire                                zda_utc_vld; 
wire   [15:0]                       zda_id;                      
wire                                zda_pps_overtime;  
wire    [7:0]                       zda_pps_status;
wire    [7:0]                       zda_time_type;




wire    [15:0]                      gga_wd_word0;
wire    [23:0]                      gga_wd_word1;
wire    [7:0]                       gga_wd_dir;
wire    [19:0]                      gga_jd_word0;
wire    [23:0]                      gga_jd_word1;
wire    [7:0]                       gga_jd_dir;
wire    [23:0]                      gga_high_word0;
wire    [7:0]                       gga_high_word1;
wire    [7:0]                       gga_high_word_minus;
wire    [15:0]                      gga_id;                
wire                                gga_pps_overtime; 


assign bd_utc_chok = rmc_utc_chok;
//-----------------------------------------------------------------------
// uart
//-----------------------------------------------------------------------

uart_driver u_uart_driver
    (
    .rst_n                  (   ~rst                    ),
    .clk_uart               (   clk                     ),
    .baud_en                (   baud_en                 ), // Fixed Baud-Rate 115200
    .verify_en              (   1'b0                    ),
    .verify_select          (   1'b0                    ),
    .stop_bit_sel           (   1'b0                    ),
    .verify_filter          (   1'b0                    ),
    .data_width             (   4'h8                    ),
    .tx_data                (   tx_data                 ),
    .tx_start               (   tx_vld                  ),
    .rx_data                (   rx_data                 ),
    .rx_data_vld            (   rx_vld                  ),
    .tx_busy                (   tx_busy                 ),
    .rx_in                  (   bd_rx_pad               ),
    .tx_out                 (   bd_tx_pad               )
    );

clk_divison u_clk_division
    (
    .rst_n                  (   ~rst                    ),
    .clk_i                  (   clk                     ),
    .clk_div_para           (   BAUD_PARA               ),
    .baud_en                (   baud_en                 )
    );

//--------------------------------------------------------------------
// u_bd_resetn
//--------------------------------------------------------------------
bd_resetn # (
    .U_DLY                      (U_DLY                      ),
    .US_CNT                     (US_CNT                     )
)u_bd_resetn
(
    .clk                        (clk                        ),
//    .rst                        (rst                        ),
    .rst                        (hard_rst                   ),    
    .bd_soft_rst                (bd_soft_rst                ),
    .bd_rstn                    (bd_rstn                    ),
    .bd_pwd                     (bd_pwd                     )

);    

//--------------------------------------------------------------------
// u_bd_resetn
//--------------------------------------------------------------------
bd_nema_send # (
    .U_DLY                      (U_DLY                      )
)u_bd_nema_send
(
    .clk                        (clk                        ),
    .rst                        (rst                        ),

    .send                       (send                       ),
    .send_data                  (send_data                  ),
    .send_done                  (send_done                  ),


    .tx_vld                     (tx_vld                     ),
    .tx_data                    (tx_data                    ),
    .tx_busy                    (tx_busy                    )

);


//--------------------------------------------------------------------
// u_bd_cib
//--------------------------------------------------------------------
bd_cib # (
    .U_DLY                      (U_DLY                      )
)u_bd_cib
(
    .clk                        (clk                        ),
    .rst                        (hard_rst                   ),

    .cpu_cs                     (cpu_cs                     ),
    .cpu_wr                     (cpu_wr                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wr_data                (cpu_wr_data                ),
    .cpu_rd_data                (cpu_rd_data                ),
//
    .send                       (send                       ),
    .send_data                  (send_data                  ),
    .send_done                  (send_done                  ),

//
    .bd_pps                     (bd_pps                     ),  
    .sfh_pulse_cnt              (sfh_pulse_cnt              ),
    .sfh_pulse_freq             (sfh_pulse_freq             ),
//
    .bd_soft_rst                (bd_soft_rst                ),
//zda
    .zda_utc_year               (zda_utc_year               ),
    .zda_utc_mon                (zda_utc_mon                ),
    .zda_utc_day                (zda_utc_day                ),
    .zda_utc_hour               (zda_utc_hour               ),
    .zda_utc_min                (zda_utc_min                ),
    .zda_utc_sec                (zda_utc_sec                ),
    .zda_utc_vld                (zda_utc_vld                ),
    .zda_id                     (zda_id                     ),    
    .zda_pps_overtime           (zda_pps_overtime           ),
    .zda_pps_status             (zda_pps_status             ),
    .zda_time_type              (zda_time_type              ),

//gga
    .gga_wd_word0               (gga_wd_word0               ),
    .gga_wd_word1               (gga_wd_word1               ),
    .gga_wd_dir                 (gga_wd_dir                 ),
    .gga_jd_word0               (gga_jd_word0               ),
    .gga_jd_word1               (gga_jd_word1               ),
    .gga_jd_dir                 (gga_jd_dir                 ),
    .gga_high_word0             (gga_high_word0             ),
    .gga_high_word1             (gga_high_word1             ),
    .gga_high_word_minus        (gga_high_word_minus        ),
    .gga_id                     (gga_id                     ),
    .gga_pps_overtime           (gga_pps_overtime           ),     
    .gga_state                  (gga_state                  ),
    .gga_satellite              (gga_satellite              ),    
    .gga_vld                    (gga_vld                    ),

//rmc
    .rmc_wd_word0               (rmc_wd_word0               ),
    .rmc_wd_word1               (rmc_wd_word1               ),
    .rmc_wd_dir                 (rmc_wd_dir                 ),
    .rmc_jd_word0               (rmc_jd_word0               ),
    .rmc_jd_word1               (rmc_jd_word1               ),
    .rmc_jd_dir                 (rmc_jd_dir                 ),
    .rmc_position               (rmc_position               ),

    .rmc_utc_year               (rmc_utc_year               ),
    .rmc_utc_mon                (rmc_utc_mon                ),
    .rmc_utc_day                (rmc_utc_day                ),
    .rmc_utc_hour               (rmc_utc_hour               ),
    .rmc_utc_min                (rmc_utc_min                ),
    .rmc_utc_sec                (rmc_utc_sec                ),
    .rmc_utc_vld                (rmc_utc_vld                ),

    .rmc_gspeed0                (rmc_gspeed0                ),
    .rmc_gspeed1                (rmc_gspeed1                ),
    .rmc_ghead0                 (rmc_ghead0                 ),
    .rmc_ghead1                 (rmc_ghead1                 ),
    .rmc_id                     (rmc_id                     ),
    .rmc_pps_overtime           (rmc_pps_overtime           ),

    .soft_cfg                   (soft_cfg                   ),
    .soft_utc_year              (soft_utc_year              ),
    .soft_utc_mon               (soft_utc_mon               ),
    .soft_utc_day               (soft_utc_day               ),
    .soft_utc_hour              (soft_utc_hour              ),
    .soft_utc_min               (soft_utc_min               ),
    .soft_utc_sec               (soft_utc_sec               ),
    .soft_utc_ms                (soft_utc_ms                ),
    .soft_utc_us                (soft_utc_us                ),
    .soft_utc_ns                (soft_utc_ns                ),

    .u_ms                       (u_ms                       ),
    .u_us                       (u_us                       ),
    .u_ns                       (u_ns                       ),


    .east                       (east                       ),
    .west                       (west                       ),
    .zone_cnt                   (zone_cnt                   ),
    .tmo_sec                    (tmo_sec                    ),
    .rtc_mode                   (rtc_mode                   ),

    .rtc_year                   (rtc_year                   ),
    .rtc_month                  (rtc_month                  ),
    .rtc_day                    (rtc_day                    ),
    .rtc_hour                   (rtc_hour                   ),
    .rtc_min                    (rtc_min                    ),
    .rtc_sec                    (rtc_sec                    ),
    .rtc_msec                   (rtc_msec                   ),
    .rtc_microsec               (rtc_microsec               ),
    .rtc_nanosec                (rtc_nanosec                )
);

//--------------------------------------------------------------------
// u_bd_nema_zda
//--------------------------------------------------------------------
generate
if(NEMA_ZDA=="true")
begin
bd_nema_zda # (
    .U_DLY                      (U_DLY                      ),
    .US_CNT                     (US_CNT                     )
)u_bd_nema_zda
(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
    .east                       (east                       ),
    .west                       (west                       ),
    .zone_cnt                   (zone_cnt                   ),
    .tmo_sec                    (tmo_sec                    ),
    .rx_vld                     (rx_vld                     ),
    .rx_data                    (rx_data                    ),
    .zda_utc_year               (zda_utc_year               ),
    .zda_utc_mon                (zda_utc_mon                ),
    .zda_utc_day                (zda_utc_day                ),
    .zda_utc_hour               (zda_utc_hour               ),
    .zda_utc_min                (zda_utc_min                ),
    .zda_utc_sec                (zda_utc_sec                ),
    .zda_utc_vld                (zda_utc_vld                ),
    .zda_utc_chok               (zda_utc_chok               ),
    .zda_id                     (zda_id                     ),
    .zda_pps_overtime           (zda_pps_overtime           ),
    .zda_time_type              (zda_time_type              ),
    .zda_pps_status             (zda_pps_status             )


);
end
else
begin
    assign zda_utc_year ='b0;
    assign zda_utc_mon  ='b0;
    assign zda_utc_day  ='b0;
    assign zda_utc_hour ='b0;
    assign zda_utc_min  ='b0;
    assign zda_utc_sec  ='b0;
    assign zda_utc_vld  ='b0;    
    assign zda_utc_chok = 'b0;
    assign zda_id       ='b0;
    assign zda_pps_overtime='b0;
    assign zda_time_type = 'b0;
    assign zda_pps_status = 'b0;

end
endgenerate

        

//--------------------------------------------------------------------
// u_bd_nema_gga
//--------------------------------------------------------------------
generate
if(NEMA_GGA=="true")
    begin
        bd_nema_gga # (
            .U_DLY                      (U_DLY                      )
        )u_bd_nema_gga
        (
            .clk                        (clk                        ),
            .rst                        (rst                        ),
            .tmo_sec                    (tmo_sec                    ),
            .rx_vld                     (rx_vld                     ),
            .rx_data                    (rx_data                    ),
            .gga_wd_word0               (gga_wd_word0               ),
            .gga_wd_word1               (gga_wd_word1               ),
            .gga_wd_dir                 (gga_wd_dir                 ),
            .gga_jd_word0               (gga_jd_word0               ),
            .gga_jd_word1               (gga_jd_word1               ),
            .gga_jd_dir                 (gga_jd_dir                 ),
            .gga_high_word0             (gga_high_word0             ),
            .gga_high_word1             (gga_high_word1             ),
            .gga_high_word_minus        (gga_high_word_minus        ),
            .gga_id                     (gga_id                     ),
            .gga_pps_overtime           (gga_pps_overtime           ),
            .gga_state                  (gga_state                  ),
            .gga_satellite              (gga_satellite              ),
            .gga_vld                    (gga_vld                    )
        );
    end
else
    begin
        assign gga_wd_word0         ='b0;
        assign gga_wd_word1         ='b0;
        assign gga_wd_dir           ='b0;
        assign gga_jd_word0         ='b0;
        assign gga_jd_word1         ='b0;
        assign gga_jd_dir           ='b0;
        assign gga_high_word0       ='b0;
        assign gga_high_word1       ='b0;
        assign gga_high_word_minus  ='b0; 
        assign gga_id               ='b0;
        assign gga_pps_overtime     ='b0;
    end
endgenerate

//--------------------------------------------------------------------
// u_bd_nema_rmc
//--------------------------------------------------------------------
generate
if(NEMA_RMC=="true")
begin
bd_nema_rmc # (
    .U_DLY                      (U_DLY                      ),
    .US_CNT                     (US_CNT                     )
)u_bd_nema_rmc
(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//
    .east                       (east                       ),
    .west                       (west                       ),
    .zone_cnt                   (zone_cnt                   ),
    .tmo_sec                    (tmo_sec                    ),
    .rx_vld                     (rx_vld                     ),
    .rx_data                    (rx_data                    ),
//
    .rmc_wd_word0               (rmc_wd_word0               ),
    .rmc_wd_word1               (rmc_wd_word1               ),
    .rmc_wd_dir                 (rmc_wd_dir                 ),
    .rmc_jd_word0               (rmc_jd_word0               ),
    .rmc_jd_word1               (rmc_jd_word1               ),
    .rmc_jd_dir                 (rmc_jd_dir                 ),

    .rmc_utc_year               (rmc_utc_year               ),
    .rmc_utc_mon                (rmc_utc_mon                ),
    .rmc_utc_day                (rmc_utc_day                ),
    .rmc_utc_hour               (rmc_utc_hour               ),
    .rmc_utc_min                (rmc_utc_min                ),
    .rmc_utc_sec                (rmc_utc_sec                ),
    .rmc_utc_vld                (rmc_utc_vld                ),
    .rmc_utc_chok               (rmc_utc_chok               ),

    .rmc_position               (rmc_position               ),

    .rmc_gspeed0                (rmc_gspeed0                ),
    .rmc_gspeed1                (rmc_gspeed1                ),
    .rmc_ghead0                 (rmc_ghead0                 ),
    .rmc_ghead1                 (rmc_ghead1                 ),
    .rmc_id                     (rmc_id                     ),
    .rmc_pps_overtime           (rmc_pps_overtime           )
);
end
else
begin
    assign  rmc_wd_word0 ='b0;
    assign  rmc_wd_word1 ='b0;
    assign  rmc_wd_dir   ='b0;
    assign  rmc_jd_word0 ='b0;
    assign  rmc_jd_word1 ='b0;
    assign  rmc_jd_dir   ='b0;
    assign  rmc_utc_year ='b0;
    assign  rmc_utc_mon  ='b0;  
    assign  rmc_utc_day  ='b0;  
    assign  rmc_utc_hour ='b0; 
    assign  rmc_utc_min  ='b0;  
    assign  rmc_utc_sec  ='b0;  
    assign  rmc_utc_vld  ='b0;
    assign  rmc_utc_chok = 'b0;
    assign  rmc_position ='b0;    
    assign  rmc_gspeed0  ='b0;
    assign  rmc_gspeed1  ='b0;
    assign  rmc_ghead0   ='b0;
    assign  rmc_ghead1   ='b0;
    assign  rmc_id       ='b0;
    assign  rmc_pps_overtime = 'b0;

end
endgenerate


//--------------------------------------------------------------------
// RTC
//--------------------------------------------------------------------

rtc_nanosec #(
    .U_DLY                      (U_DLY                      ),
    .CLK_PERIOD                 (10                         )
)u_rtc_nanosec
(
    .rst                        (hard_rst | bd_soft_rst     ),
    .clk                        (clk                        ),
    .rtc_timing_1s              (rtc_timing_1s              ),
//config interface
    .cfg_en                     (cfg_en                     ),
    .cfg_year                   (cfg_year                   ),
    .cfg_month                  (cfg_month                  ),
    .cfg_day                    (cfg_day                    ),
    .cfg_hour                   (cfg_hour                   ),
    .cfg_min                    (cfg_min                    ),
    .cfg_sec                    (cfg_sec                    ),
    .cfg_msec                   (cfg_msec                   ),
    .cfg_microsec               (cfg_microsec               ),
    .cfg_nanosec                (cfg_nanosec                ),
//RTC time
    .rtc_year                   (rtc_year                   ),
    .rtc_month                  (rtc_month                  ),
    .rtc_day                    (rtc_day                    ),
    .rtc_hour                   (rtc_hour                   ),
    .rtc_min                    (rtc_min                    ),
    .rtc_sec                    (rtc_sec                    ),
    .rtc_msec                   (rtc_msec                   ),
    .rtc_microsec               (rtc_microsec               ),
    .rtc_nanosec                (rtc_nanosec                )
);


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            bd_pps_r <= #U_DLY 'b0; 
            pps_cfg <= #U_DLY 1'b0;
        end       
    else 
        begin
            bd_pps_r <= #U_DLY {bd_pps_r[1:0],bd_pps}; 

            if(bd_pps_r[1]==1'b1 && bd_pps_r[2]==1'b0)
                pps_cfg <= #U_DLY 1'b1;
            else
                pps_cfg <= #U_DLY 1'b0;
        end   
end

always @ (posedge clk or posedge hard_rst)begin
    if(hard_rst == 1'b1)     
        begin
            cfg_en <= #U_DLY 1'b0;
            cfg_year <= #U_DLY 'b0;
            cfg_month <= #U_DLY 'b0;
            cfg_day <= #U_DLY 'b0;
            cfg_hour <= #U_DLY 'b0;
            cfg_min <= #U_DLY 'b0;
            cfg_sec <= #U_DLY 'b0;
            cfg_msec <= #U_DLY 'b0;
            cfg_microsec <= #U_DLY 'b0;
            cfg_nanosec <= #U_DLY 'b0;
            soft_cfg_r <= #U_DLY 2'b0;
        end        
    else   
        begin
            soft_cfg_r <= #U_DLY {soft_cfg_r[1],soft_cfg};

            if(rtc_mode==3'd0 || rtc_mode==3'd1)
                begin 
                    if(zda_utc_chok==1'b1 || rmc_utc_chok==1'b1) 
                        cfg_en <= #U_DLY pps_cfg;
                    else
                        cfg_en <= #U_DLY 1'b0;
                end     
            else if(rtc_mode==3'd2 && soft_cfg_r[0]==1'b1 && soft_cfg_r[1]==1'b0)
                cfg_en <= #U_DLY 1'b1;
            else
                cfg_en <= #U_DLY 1'b0;

            if(rtc_mode==3'd0) //zda
                begin
                    if(zda_utc_chok==1'b1)
                        begin
                            cfg_year <= #U_DLY zda_utc_year;
                            cfg_month <= #U_DLY zda_utc_mon;
                            cfg_day <= #U_DLY zda_utc_day;
                            cfg_hour <= #U_DLY zda_utc_hour;
                            cfg_min <= #U_DLY zda_utc_min;
                            cfg_sec <= #U_DLY zda_utc_sec;
                            cfg_msec <= #U_DLY u_ms;
                            cfg_microsec <= #U_DLY u_us;
                            cfg_nanosec <= #U_DLY u_ns;
                        end
                    else if(rmc_utc_chok==1'b1)
                        begin
                            cfg_year <= #U_DLY rmc_utc_year;
                            cfg_month <= #U_DLY rmc_utc_mon;
                            cfg_day <= #U_DLY rmc_utc_day;
                            cfg_hour <= #U_DLY rmc_utc_hour;
                            cfg_min <= #U_DLY rmc_utc_min;
                            cfg_sec <= #U_DLY rmc_utc_sec;
                            cfg_msec <= #U_DLY u_ms;
                            cfg_microsec <= #U_DLY u_us;
                            cfg_nanosec <= #U_DLY u_ns;
                        end
                end
            else if(rtc_mode==3'd1)//rmc
                begin
                    if(rmc_utc_chok==1'b1)
                        begin
                            cfg_year <= #U_DLY rmc_utc_year;
                            cfg_month <= #U_DLY rmc_utc_mon;
                            cfg_day <= #U_DLY rmc_utc_day;
                            cfg_hour <= #U_DLY rmc_utc_hour;
                            cfg_min <= #U_DLY rmc_utc_min;
                            cfg_sec <= #U_DLY rmc_utc_sec;
                            cfg_msec <= #U_DLY u_ms;
                            cfg_microsec <= #U_DLY u_us;
                            cfg_nanosec <= #U_DLY u_ns;
                        end   
                   else if(zda_utc_chok==1'b1)
                        begin
                            cfg_year <= #U_DLY zda_utc_year;
                            cfg_month <= #U_DLY zda_utc_mon;
                            cfg_day <= #U_DLY zda_utc_day;
                            cfg_hour <= #U_DLY zda_utc_hour;
                            cfg_min <= #U_DLY zda_utc_min;
                            cfg_sec <= #U_DLY zda_utc_sec;
                            cfg_msec <= #U_DLY u_ms;
                            cfg_microsec <= #U_DLY u_us;
                            cfg_nanosec <= #U_DLY u_ns;
                        end
                end
            else if(rtc_mode==3'd2)//soft
                begin
                    if(soft_cfg==1'b1)
                         begin
                            cfg_year <= #U_DLY soft_utc_year;
                            cfg_month <= #U_DLY soft_utc_mon;
                            cfg_day <= #U_DLY soft_utc_day;
                            cfg_hour <= #U_DLY soft_utc_hour;
                            cfg_min <= #U_DLY soft_utc_min;
                            cfg_sec <= #U_DLY soft_utc_sec;
                            cfg_msec <= #U_DLY soft_utc_ms;
                            cfg_microsec <= #U_DLY soft_utc_us;
                            cfg_nanosec <= #U_DLY soft_utc_ns;
                        end   
                end
        end 
end
 






endmodule
