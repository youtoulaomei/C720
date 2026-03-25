// *********************************************************************************/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2016/10/13 13:36:26
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Zhimingda digital equipment Co., Ltd.. 
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
module bd_timer#(
parameter                           SIMULATION = "FALSE",
parameter                           U_DLY = 1,
parameter                           US_CNT =8'd100  //1000ns = US_CNT*10ns (100MHZ)
)
(
input                               rst,
input                               clk,
input                               gps_load,
input       [7:0]                   gps_year,
input       [4:0]                   gps_mon,
input       [4:0]                   gps_day,
input       [4:0]                   gps_hour,
input       [5:0]                   gps_min,
input       [5:0]                   gps_sec,
input                               gps_pps,
output  reg                         gps_sel,
output  reg [15:0]                  year,
output  reg [7:0]                   mon,
output  reg [7:0]                   day,
output  reg [7:0]                   hour,
output  reg [7:0]                   min,
output  reg [7:0]                   sec,
output  reg [11:0]                  ms,
output  reg [11:0]                  us,
output  reg                         vld 
);
// Parameter Define 
parameter                           NS_CARRY_THD = (SIMULATION == "TRUE") ? 8'd4 : US_CNT-1;
parameter                           US_CARRY_THD = (SIMULATION == "TRUE") ? 10'd4 :10'd999;
parameter                           MS_CARRY_THD = (SIMULATION == "TRUE") ? 10'd4 :10'd999;
parameter                           SEC_CARRY_THD = (SIMULATION == "TRUE") ? 6'd4 :6'd59;
parameter                           MIN_CARRY_THD = (SIMULATION == "TRUE") ? 6'd4 :6'd59;
parameter                           HOUR_CARRY_THD = (SIMULATION == "TRUE") ? 5'd4 :5'd23;
parameter                           DAY_CARRY_THD = (SIMULATION == "TRUE") ? 5'd4 :5'd30; 
parameter                           MON_CARRY_THD = (SIMULATION == "TRUE") ? 5'd4 :5'd11; 

// Register Define 
reg     [7:0]                       ns_cnt;
reg     [9:0]                       us_cnt;
reg     [9:0]                       ms_cnt;
reg     [5:0]                       sec_cnt;
reg     [5:0]                       min_cnt;
reg     [4:0]                       hour_cnt;
reg     [4:0]                       day_cnt;
reg     [11:0]                      year_cnt;
reg                                 ns_cry_pre;
reg                                 us_cry_pre;
reg                                 ms_cry_pre;
reg                                 sec_cry_pre;
reg                                 min_cry_pre;
reg                                 hour_cry_pre;
reg                                 day_cry_pre;
reg                                 ns_cry;
reg                                 us_cry;
reg                                 ms_cry;
reg                                 sec_cry;
reg                                 min_cry;
reg                                 hour_cry;
reg                                 day_cry;
reg     [3:0]                       cfg_vld_dly;
reg     [15:0]                      cfg_year_0dly;
reg     [15:0]                      cfg_year_1dly;
reg     [1:0]                       sync_cnt;
reg     [3:0]                       mon_cnt;
reg                                 mon_cry_pre;
reg                                 mon_cry;
reg     [2:0]                       gps_pps_dly;
reg                                 day_cry_pre_com;
reg     [1:0]                       vld_r;

// Wire Define 
wire                                pps_fast;


always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)     
        gps_pps_dly <= 3'd0;
    else    
        gps_pps_dly <= #U_DLY {gps_pps_dly[1:0],gps_pps}; 
end

always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)     
        begin
            sync_cnt <= 2'd0;
            gps_sel <= 1'b0;
        end
    else    
        begin
            if(gps_load == 1'b1)
                sync_cnt <= #U_DLY 2'd0;
            else if(ms_cry == 1'b1 && sync_cnt < 2'd3)
                sync_cnt <= #U_DLY sync_cnt + 2'd1;
            else;

            if(gps_load == 1'b1)
                gps_sel <= #U_DLY 1'b1;
            else if(sync_cnt == 2'd3)
                gps_sel <= #U_DLY 1'b0;
            else;
            	
            vld_r  <= #U_DLY {vld_r[0],gps_load};
            vld    <= #U_DLY  vld_r[1];  
            	
        end
end

always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)     
        begin
            ns_cnt <= 'd0;
            us_cnt <= 10'd0;
            ms_cnt <= 10'd0;
            sec_cnt <= 6'd0;
            min_cnt <= 6'd0;
            hour_cnt <= 5'd0;
            day_cnt <= 5'd0;
            mon_cnt <= 4'd0;
            year_cnt <= 12'd0;
            ns_cry_pre <= 1'b0;
            us_cry_pre <= 1'b0;
            ms_cry_pre <= 1'b0;
            sec_cry_pre <= 1'b0;
            min_cry_pre <= 1'b0;
            hour_cry_pre <= 1'b0;
            day_cry_pre <= 1'b0;
            mon_cry_pre <= 1'b0;
            ns_cry <= 1'b0;
            us_cry <= 1'b0;
            ms_cry <= 1'b0;
            sec_cry <= 1'b0;
            min_cry <= 1'b0;
            hour_cry <= 1'b0;
            day_cry <= 1'b0;
            mon_cry <= 1'b0;
        end
    else    
        begin
            //ns counter
            if(gps_pps_dly[2:1] == 2'b01)
                ns_cnt <= #U_DLY 'd0;
            else if(ns_cnt < NS_CARRY_THD)
                ns_cnt <= #U_DLY ns_cnt + 'd1;
            else
                ns_cnt <= #U_DLY 'd0;

            if(gps_pps_dly[2:1] == 2'b01)
                ns_cry_pre <= #U_DLY 1'b0;
            else if(ns_cnt == (NS_CARRY_THD - 'd2))
                ns_cry_pre <= #U_DLY 1'b1;
            else
                ns_cry_pre <= #U_DLY 1'b0;

            if(gps_pps_dly[2:1] == 2'b01)
                ns_cry <= #U_DLY 1'b0;
            else
                ns_cry <= #U_DLY ns_cry_pre;
            
            //us counter
            if(gps_pps_dly[2:1] == 2'b01)
                us_cnt <= 10'd0;
            else if(ns_cry == 1'b1)
                begin
                    if(us_cnt < US_CARRY_THD) 
                        us_cnt <= #U_DLY us_cnt + 10'd1;
                    else
                        us_cnt <= #U_DLY 10'd0;
                end
            else;

            if(gps_pps_dly[2:1] == 2'b01)
                us_cry_pre <= #U_DLY 1'b0;   
            else if(us_cnt == US_CARRY_THD)
                us_cry_pre <= #U_DLY 1'b1;
            else
                us_cry_pre <= #U_DLY 1'b0;

            if(gps_pps_dly[2:1] == 2'b01)
                us_cry <= #U_DLY 1'b0;
            else if((ns_cry_pre & us_cry_pre) == 1'b1)
                us_cry <= #U_DLY 1'b1;
            else
                us_cry <= #U_DLY 1'b0;

            //ms counter
            if(gps_pps_dly[2:1] == 2'b01)
                ms_cnt <= #U_DLY 10'd0;
            else if(us_cry == 1'b1)
                begin
                    if(ms_cnt < MS_CARRY_THD) 
                        ms_cnt <= #U_DLY ms_cnt + 10'd1;
                    else
                        ms_cnt <= #U_DLY 10'd0;
                end
            else;

            if(gps_pps_dly[2:1] == 2'b01)
                ms_cry_pre <= #U_DLY 1'b0;   
            else if(ms_cnt == MS_CARRY_THD)
                ms_cry_pre <= #U_DLY 1'b1;
            else
                ms_cry_pre <= #U_DLY 1'b0;

            if(gps_pps_dly[2:1] == 2'b01)
                ms_cry <= #U_DLY 1'b0;
            else if((ns_cry_pre & us_cry_pre & ms_cry_pre) == 1'b1)
                ms_cry <= #U_DLY 1'b1;
            else
                ms_cry <= #U_DLY 1'b0;
            
            //second counter
            if(gps_load == 1'b1)
                sec_cnt <= gps_sec;     //Load Irig_B Second
            else if(ms_cry == 1'b1 || pps_fast == 1'b1)
                begin
                    if(sec_cnt < SEC_CARRY_THD) 
                        sec_cnt <= #U_DLY sec_cnt + 6'd1;
                    else
                        sec_cnt <= #U_DLY 6'd0;
                end
            else;

            if(gps_load == 1'b1)
                sec_cry_pre <= #U_DLY 1'b0;   
            else if(sec_cnt == SEC_CARRY_THD)
                sec_cry_pre <= #U_DLY 1'b1;
            else
                sec_cry_pre <= #U_DLY 1'b0;

            if(gps_load == 1'b1)
                sec_cry <= #U_DLY 1'b0;
            else if((ns_cry_pre & us_cry_pre & ms_cry_pre & sec_cry_pre) == 1'b1)
                sec_cry <= #U_DLY 1'b1;
            else
                sec_cry <= #U_DLY 1'b0;

            //minute counter
            if(gps_load == 1'b1)
                min_cnt <= gps_min;     //Load Irig_B Minute
            else if(sec_cry == 1'b1 || (pps_fast & sec_cry_pre) == 1'b1)
                begin
                    if(min_cnt < MIN_CARRY_THD) 
                        min_cnt <= #U_DLY min_cnt + 6'd1;
                    else
                        min_cnt <= #U_DLY 6'd0;
                end
            else;

            if(gps_load == 1'b1)
                min_cry_pre <= #U_DLY 1'b0;   
            else if(min_cnt == MIN_CARRY_THD)
                min_cry_pre <= #U_DLY 1'b1;
            else
                min_cry_pre <= #U_DLY 1'b0;

            if(gps_load == 1'b1)
                min_cry <= #U_DLY 1'b0;
            else if((ns_cry_pre & us_cry_pre & ms_cry_pre & sec_cry_pre & min_cry_pre) == 1'b1)
                min_cry <= #U_DLY 1'b1;
            else
                min_cry <= #U_DLY 1'b0;

            //hour counter
            if(gps_load == 1'b1)
                hour_cnt <= gps_hour;     //Load Irig_B Minute
            else if(min_cry == 1'b1 || (pps_fast & sec_cry_pre & min_cry_pre) == 1'b1)
                begin
                    if(hour_cnt < HOUR_CARRY_THD) 
                        hour_cnt <= #U_DLY hour_cnt + 5'd1;
                    else
                        hour_cnt <= #U_DLY 5'd0;
                end
            else;

            if(gps_load == 1'b1)
                hour_cry_pre <= #U_DLY 1'b0;   
            else if(hour_cnt >= HOUR_CARRY_THD)
                hour_cry_pre <= #U_DLY 1'b1;
            else
                hour_cry_pre <= #U_DLY 1'b0;

            if(gps_load == 1'b1)
                hour_cry <= #U_DLY 1'b0;
            else if((ns_cry_pre & us_cry_pre & ms_cry_pre & sec_cry_pre & min_cry_pre & hour_cry_pre) == 1'b1)
                hour_cry <= #U_DLY 1'b1;
            else
                hour_cry <= #U_DLY 1'b0;

            //day counter
            if(gps_load == 1'b1)
                day_cnt <= gps_day;     //Load Irig_B Minute
            else if(hour_cry == 1'b1 || (pps_fast & sec_cry_pre & min_cry_pre & hour_cry_pre) == 1'b1)
                begin
                    if(day_cry_pre_com == 1'b0)
                        day_cnt <= #U_DLY day_cnt + 5'd1;
                    else
                        day_cnt <= #U_DLY 5'd0;
                end
            else;

            if(gps_load == 1'b1)
                day_cry_pre <= #U_DLY 1'b0;   
            else
                day_cry_pre <= #U_DLY day_cry_pre_com;

            if(gps_load == 1'b1)
                day_cry <= #U_DLY 1'b0;
            else if((ns_cry_pre & us_cry_pre & ms_cry_pre & sec_cry_pre & min_cry_pre & hour_cry_pre & day_cry_pre) == 1'b1)
                day_cry <= #U_DLY 1'b1;
            else
                day_cry <= #U_DLY 1'b0;


            //mon counter
            if(gps_load == 1'b1)
                mon_cnt <= gps_mon;     //Load Irig_B Minute
            else if(day_cry == 1'b1 || (pps_fast & sec_cry_pre & min_cry_pre & hour_cry_pre & day_cry_pre ) == 1'b1)
                begin
                    if(mon_cnt < MON_CARRY_THD) 
                        mon_cnt <= #U_DLY mon_cnt + 5'd1;
                    else
                        mon_cnt <= #U_DLY 5'd0;
                end
            else;

            if(gps_load == 1'b1)
                mon_cry_pre <= #U_DLY 1'b0;   
            else if(mon_cnt == MON_CARRY_THD)
                mon_cry_pre <= #U_DLY 1'b1;
            else
                mon_cry_pre <= #U_DLY 1'b0;

            if(gps_load == 1'b1)
                mon_cry <= #U_DLY 1'b0;
            else if((ns_cry_pre & us_cry_pre & ms_cry_pre & sec_cry_pre & min_cry_pre & hour_cry_pre & day_cry_pre & mon_cry_pre) == 1'b1)
                mon_cry <= #U_DLY 1'b1;
            else
                mon_cry <= #U_DLY 1'b0;

            
            //year counter
            if(gps_load == 1'b1)
                begin
                    if(gps_year[7:0] <= 8'd99 && gps_year[7:0] >= 8'd0)
                        year_cnt <= #U_DLY 12'd2000 + gps_year;
                    else;
                end
            else if(mon_cry == 1'b1 || (pps_fast & sec_cry_pre & min_cry_pre & hour_cry_pre & day_cry_pre & mon_cry_pre ) == 1'b1)
                begin
                    if(year_cnt < 12'd2099)
                        year_cnt <= #U_DLY year_cnt + 12'd1;
                    else;
                end
            else;
        end
end

assign pps_fast = (gps_pps_dly[2:1] == 2'b01 && ms_cnt[9] == 1'b1) ? 1'b1 : 1'b0;

always @(*)
begin
    case(mon_cnt)
        4'd1,
        4'd3,
        4'd5,
        4'd7,
        4'd8,
        4'd10,
        4'd12:
            begin
                if(day_cnt < DAY_CARRY_THD)
                    day_cry_pre_com = 1'b1;
                else
                    day_cry_pre_com = 1'b0;
            end
        4'd4,
        4'd6,
        4'd9,
        4'd11:
            begin
                if(day_cnt < DAY_CARRY_THD -1)
                    day_cry_pre_com = 1'b1;
                else
                    day_cry_pre_com = 1'b0;
            end
        4'd2:
            begin
                if((year[1:0] == 2'b00 && day_cnt < DAY_CARRY_THD -2) ||
                    (year[1:0] != 2'b00 && day_cnt < DAY_CARRY_THD -3))
                    day_cry_pre_com = 1'b1;
                else
                    day_cry_pre_com = 1'b0;
            end
        default:day_cry_pre_com = 1'b0;
        endcase
end

always @ (posedge clk or posedge rst)
begin
    if(rst == 1'b1)     
        begin
            year <= 16'd0;
            mon <= 8'd0;
            day <= 8'd0;
            hour <= 8'd0;
            min <= 8'd0;
            sec <= 8'd0;
            ms <= 12'd0;
            us <= 12'd0;
        end
    else    
        begin
            year <= #U_DLY {4'd0,year_cnt};
            day <= #U_DLY {3'd0,day_cnt};
            mon <= #U_DLY {4'd0,mon_cnt};
            hour <= #U_DLY {3'd0,hour_cnt};
            min <= #U_DLY {2'd0,min_cnt};
            sec <= #U_DLY {2'd0,sec_cnt};
            ms <= #U_DLY {2'd0,ms_cnt};
            us <= #U_DLY {2'd0,us_cnt};
        end

end

endmodule

