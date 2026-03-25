// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2019/9/2 10:54:17
// File Name    : bocde_tx_timepro.v
// Module Name  : 
// Called By    :
// Abstract     :
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
module bocde_tx_timepro #(
parameter                           U_DLY = 1
)
(
//clock
input                               clk,
input                               rst,
//
output  reg                         bcd_time_vld,
output  wire    [7:0]               bcd_year,
output  wire    [9:0]               bcd_day,
output  reg     [5:0]               bcd_hour,
output  reg     [6:0]               bcd_min,
output  reg     [6:0]               bcd_sec,
output  reg     [16:0]              bin_str_sec,
//interface with RTC
input           [11:0]              rtc_year,
input           [8:0]               rtc_day,
input           [4:0]               rtc_hour,
input           [5:0]               rtc_min,
input           [5:0]               rtc_sec,
input           [16:0]              rtc_str_sec,

input                               nanosec_carry,
input                               microsec_carry,
input                               msec_carry,
//debug
input                               tx_en,
//
input                               authorize_succ
);
// Parameter Define 

// Register Define 
reg                                 bin_time_vld;
reg                                 bin_time_vld_pre;
reg     [3:0]                       bcd_sec_one_place;
reg     [2:0]                       bcd_sec_ten_place;
reg     [3:0]                       bcd_min_one_place;
reg     [2:0]                       bcd_min_ten_place;
reg     [3:0]                       bcd_hour_one_place;
reg     [1:0]                       bcd_hour_ten_place;
reg     [3:0]                       bcd_day_one_place_1pre;
reg     [3:0]                       bcd_day_one_place_2pre;
reg     [3:0]                       bcd_day_one_place_3pre;
reg     [3:0]                       bcd_day_one_place_4pre;
reg     [3:0]                       bcd_day_ten_place_1pre;
reg     [3:0]                       bcd_day_ten_place_2pre;
reg     [3:0]                       bcd_day_ten_place_3pre;
reg     [3:0]                       bcd_day_ten_place_4pre;
reg     [3:0]                       bcd_day_one_place;
reg     [3:0]                       bcd_day_ten_place;
reg     [1:0]                       bcd_day_hun_place;
reg     [11:0]                      bcd_years_pre;
reg     [7:0]                       bcd_year_one_place;
reg     [7:0]                       bcd_year_ten_place;

// Wire Define 

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            bin_time_vld_pre <= 1'b0;
            bin_time_vld <= 1'b0;
            bcd_time_vld <= 1'b0;
        end
    else 
        begin
            if({nanosec_carry,microsec_carry,msec_carry} == 3'b111)
                bin_time_vld_pre <= #U_DLY tx_en & authorize_succ;
            else
                bin_time_vld_pre <= #U_DLY 1'b0;

            bin_time_vld <= #U_DLY bin_time_vld_pre; 
            bcd_time_vld <= #U_DLY bin_time_vld;
        end
end
//for binary time
//bcd seconds
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            bin_str_sec <= 'd0;
            bcd_sec_one_place <= 'd0;
            bcd_sec_ten_place <= 'd0;
            bcd_sec <= 'd0;
        end
    else
        begin
            if(bin_time_vld_pre == 1'b1)
                bin_str_sec <= #U_DLY rtc_str_sec;
            else;

            if(bin_time_vld_pre == 1'b1)
                begin
                    if(rtc_sec <= 'd9)
                        begin
                            bcd_sec_one_place <= #U_DLY rtc_sec[3:0];
                            bcd_sec_ten_place <= #U_DLY 3'd0;
                        end
                    else if(rtc_sec >= 'd10 && rtc_sec <= 'd19)
                         begin
                            bcd_sec_one_place <= #U_DLY rtc_sec - 'd10;
                            bcd_sec_ten_place <= #U_DLY 3'd1;
                        end     
                    else if(rtc_sec >= 'd20 && rtc_sec <= 'd29)
                         begin
                            bcd_sec_one_place <= #U_DLY rtc_sec - 'd20;
                            bcd_sec_ten_place <= #U_DLY 3'd2;
                        end                          
                    else if(rtc_sec >= 'd30 && rtc_sec <= 'd39)
                         begin
                            bcd_sec_one_place <= #U_DLY rtc_sec - 'd30;
                            bcd_sec_ten_place <= #U_DLY 3'd3;
                        end                     
                    else if(rtc_sec >= 'd40 && rtc_sec <= 'd49)
                         begin
                            bcd_sec_one_place <= #U_DLY rtc_sec - 'd40;
                            bcd_sec_ten_place <= #U_DLY 3'd4;
                        end 
                    else if(rtc_sec >= 'd50 && rtc_sec <= 'd59)
                         begin
                            bcd_sec_one_place <= #U_DLY rtc_sec - 'd50;
                            bcd_sec_ten_place <= #U_DLY 3'd4;
                        end
                    else
                        begin        
                            bcd_sec_one_place <= #U_DLY 'd0;
                            bcd_sec_ten_place <= #U_DLY 3'd0;
                        end
                end
            else;

            bcd_sec <= #U_DLY {bcd_sec_ten_place,bcd_sec_one_place};
        end
end
//bcd minutes
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            bcd_min_one_place <= 'd0;
            bcd_min_ten_place <= 'd0;
            bcd_min <= 'd0;
        end
    else
        begin
            if(bin_time_vld_pre == 1'b1)
                begin
                    if(rtc_min <= 'd9)
                        begin
                            bcd_min_one_place <= #U_DLY rtc_min[3:0];
                            bcd_min_ten_place <= #U_DLY 3'd0;
                        end
                    else if(rtc_min >= 'd10 && rtc_min <= 'd19)
                        begin
                            bcd_min_one_place <= #U_DLY rtc_min - 'd10;
                            bcd_min_ten_place <= #U_DLY 3'd1;
                        end     
                    else if(rtc_min >= 'd20 && rtc_min <= 'd29)
                        begin
                            bcd_min_one_place <= #U_DLY rtc_min - 'd20;
                            bcd_min_ten_place <= #U_DLY 3'd2;
                        end                          
                    else if(rtc_min >= 'd30 && rtc_min <= 'd39)
                        begin
                            bcd_min_one_place <= #U_DLY rtc_min - 'd30;
                            bcd_min_ten_place <= #U_DLY 3'd3;
                        end                     
                    else if(rtc_min >= 'd40 && rtc_min <= 'd49)
                        begin
                            bcd_min_one_place <= #U_DLY rtc_min - 'd40;
                            bcd_min_ten_place <= #U_DLY 3'd4;
                        end 
                    else if(rtc_min >= 'd50 && rtc_min <= 'd59)
                        begin
                            bcd_min_one_place <= #U_DLY rtc_min - 'd50;
                            bcd_min_ten_place <= #U_DLY 3'd4;
                        end
                    else
                        begin        
                            bcd_min_one_place <= #U_DLY 'd0;
                            bcd_min_ten_place <= #U_DLY 3'd0;
                        end
                end
            else;

            bcd_min <= #U_DLY {bcd_min_ten_place,bcd_min_one_place};
        end
end
//bcd hours
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            bcd_hour_one_place <= 'd0;
            bcd_hour_ten_place <= 'd0;
            bcd_hour <= 'd0;
        end
    else
        begin
            if(bin_time_vld_pre == 1'b1)
                begin
                    if(rtc_hour <= 'd9)
                        begin
                            bcd_hour_one_place <= #U_DLY rtc_hour[3:0];
                            bcd_hour_ten_place <= #U_DLY 2'd0;
                        end
                    else if(rtc_hour >= 'd10 && rtc_hour <= 'd19)
                        begin
                            bcd_hour_one_place <= #U_DLY rtc_hour - 'd10;
                            bcd_hour_ten_place <= #U_DLY 2'd1;
                        end     
                    else if(rtc_hour >= 'd20 && rtc_hour <= 'd23)
                        begin
                            bcd_hour_one_place <= #U_DLY rtc_hour - 'd20;
                            bcd_hour_ten_place <= #U_DLY 3'd2;
                        end
                    else
                        begin
                            bcd_hour_one_place <= #U_DLY 4'd0;
                            bcd_hour_ten_place <= #U_DLY 2'd0;
                        end
                end
            else;

            bcd_hour <= #U_DLY {bcd_hour_ten_place,bcd_hour_one_place};
        end
end
//bcd days
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            bcd_day_one_place_1pre <= 'd0;
            bcd_day_one_place_2pre <= 'd0;
            bcd_day_one_place_3pre <= 'd0;
            bcd_day_one_place_4pre <= 'd0;
            bcd_day_ten_place_1pre <= 'd0;
            bcd_day_ten_place_2pre <= 'd0;
            bcd_day_ten_place_3pre <= 'd0;
            bcd_day_ten_place_4pre <= 'd0;
        end
    else
        begin
            if(bin_time_vld_pre == 1'b1)
                begin
                    if(rtc_day <= 'd9)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day[3:0];
                            bcd_day_ten_place_1pre <= #U_DLY 'd0;
                        end
                    else if(rtc_day >= 'd10 && rtc_day <= 'd19)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day - 'd10;
                            bcd_day_ten_place_1pre <= #U_DLY 'd1;
                        end
                    else if(rtc_day >= 'd20 && rtc_day <= 'd29)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day - 'd20;
                            bcd_day_ten_place_1pre <= #U_DLY 'd2;
                        end
                    else if(rtc_day >= 'd30 && rtc_day <= 'd39)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day - 'd30;
                            bcd_day_ten_place_1pre <= #U_DLY 'd3;
                        end
                    else if(rtc_day >= 'd40 && rtc_day <= 'd49)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day - 'd40;
                            bcd_day_ten_place_1pre <= #U_DLY 'd4;
                        end
                    else if(rtc_day >= 'd50 && rtc_day <= 'd59)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day - 'd50;
                            bcd_day_ten_place_1pre <= #U_DLY 'd5;
                        end
                    else if(rtc_day >= 'd60 && rtc_day <= 'd69)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day - 'd60;
                            bcd_day_ten_place_1pre <= #U_DLY 'd6;
                        end
                    else if(rtc_day >= 'd70 && rtc_day <= 'd79)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day - 'd70;
                            bcd_day_ten_place_1pre <= #U_DLY 'd7;
                        end
                    else if(rtc_day >= 'd80 && rtc_day <= 'd89)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day - 'd80;
                            bcd_day_ten_place_1pre <= #U_DLY 'd8;
                        end
                    else if(rtc_day >= 'd90 && rtc_day <= 'd99)
                        begin
                            bcd_day_one_place_1pre <= #U_DLY rtc_day - 'd90;
                            bcd_day_ten_place_1pre <= #U_DLY 'd9;
                        end
                    else;
                end
            else;

            if(bin_time_vld_pre == 1'b1)
                begin
                    if(rtc_day >= 'd100 && rtc_day <= 'd109)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd100; 
                            bcd_day_ten_place_2pre <= #U_DLY 'd0;
                        end
                    else if(rtc_day >= 'd110 && rtc_day <= 'd119)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd110;
                            bcd_day_ten_place_2pre <= #U_DLY 'd1;
                        end
                    else if(rtc_day >= 'd120 && rtc_day <= 'd129)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd120;
                            bcd_day_ten_place_2pre <= #U_DLY 'd2;
                        end
                    else if(rtc_day >= 'd130 && rtc_day <= 'd139)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd130;
                            bcd_day_ten_place_2pre <= #U_DLY 'd3;
                        end
                    else if(rtc_day >= 'd140 && rtc_day <= 'd149)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd140;
                            bcd_day_ten_place_2pre <= #U_DLY 'd4;
                        end
                    else if(rtc_day >= 'd150 && rtc_day <= 'd159)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd150;
                            bcd_day_ten_place_2pre <= #U_DLY 'd5;
                        end
                    else if(rtc_day >= 'd160 && rtc_day <= 'd169)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd160;
                            bcd_day_ten_place_2pre <= #U_DLY 'd6;
                        end                            
                    else if(rtc_day >= 'd170 && rtc_day <= 'd179)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd170;
                            bcd_day_ten_place_2pre <= #U_DLY 'd7;
                        end
                    else if(rtc_day >= 'd180 && rtc_day <= 'd189)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd180; 
                            bcd_day_ten_place_2pre <= #U_DLY 'd8;
                        end                            
                    else if(rtc_day >= 'd190 && rtc_day <= 'd199)
                        begin
                            bcd_day_one_place_2pre <= #U_DLY rtc_day - 'd190;
                            bcd_day_ten_place_2pre <= #U_DLY 'd9;
                        end                            
                    else;
                end
            else;

            if(bin_time_vld_pre == 1'b1)
                begin
                    if(rtc_day >= 'd200 && rtc_day <= 'd209)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd200; 
                            bcd_day_ten_place_3pre <= #U_DLY 'd0;
                        end                            
                    else if(rtc_day >= 'd210 && rtc_day <= 'd219)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd210; 
                            bcd_day_ten_place_3pre <= #U_DLY 'd1;
                        end                                
                    else if(rtc_day >= 'd220 && rtc_day <= 'd229)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd220;
                            bcd_day_ten_place_3pre <= #U_DLY 'd2;
                        end
                    else if(rtc_day >= 'd230 && rtc_day <= 'd239)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd230;
                            bcd_day_ten_place_3pre <= #U_DLY 'd3;
                        end
                    else if(rtc_day >= 'd240 && rtc_day <= 'd249)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd240;
                            bcd_day_ten_place_3pre <= #U_DLY 'd4;
                        end
                    else if(rtc_day >= 'd250 && rtc_day <= 'd259)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd250;
                            bcd_day_ten_place_3pre <= #U_DLY 'd5;
                        end
                    else if(rtc_day >= 'd260 && rtc_day <= 'd269)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd260;
                            bcd_day_ten_place_3pre <= #U_DLY 'd6;
                        end
                    else if(rtc_day >= 'd270 && rtc_day <= 'd279)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd270;
                            bcd_day_ten_place_3pre <= #U_DLY 'd7;
                        end
                    else if(rtc_day >= 'd280 && rtc_day <= 'd289)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd280;
                            bcd_day_ten_place_3pre <= #U_DLY 'd8;
                        end
                    else if(rtc_day >= 'd290 && rtc_day <= 'd299)
                        begin
                            bcd_day_one_place_3pre <= #U_DLY rtc_day - 'd290;
                            bcd_day_ten_place_3pre <= #U_DLY 'd9;
                        end
                    else;
                end
            else;

            if(bin_time_vld_pre == 1'b1)
                begin
                    if(rtc_day >= 'd300 && rtc_day <= 'd309)
                        begin
                            bcd_day_one_place_4pre <= #U_DLY rtc_day - 'd300;
                            bcd_day_ten_place_4pre <= #U_DLY 'd0;
                        end
                    else if(rtc_day >= 'd310 && rtc_day <= 'd319)
                        begin
                            bcd_day_one_place_4pre <= #U_DLY rtc_day - 'd310;
                            bcd_day_ten_place_4pre <= #U_DLY 'd1;
                        end 
                    else if(rtc_day >= 'd320 && rtc_day <= 'd329)
                        begin
                            bcd_day_one_place_4pre <= #U_DLY rtc_day - 'd320;
                            bcd_day_ten_place_4pre <= #U_DLY 'd2;
                        end
                    else if(rtc_day >= 'd330 && rtc_day <= 'd339)
                        begin
                            bcd_day_one_place_4pre <= #U_DLY rtc_day - 'd330;
                            bcd_day_ten_place_4pre <= #U_DLY 'd3;
                        end                            
                    else if(rtc_day >= 'd340 && rtc_day <= 'd349)
                        begin
                            bcd_day_one_place_4pre <= #U_DLY rtc_day - 'd340;
                            bcd_day_ten_place_4pre <= #U_DLY 'd4;
                        end                            
                    else if(rtc_day >= 'd350 && rtc_day <= 'd359)
                        begin
                            bcd_day_one_place_4pre <= #U_DLY rtc_day - 'd350;
                            bcd_day_ten_place_4pre <= #U_DLY 'd5;
                        end                            
                    else if(rtc_day >= 'd360 && rtc_day <= 'd369)
                        begin
                            bcd_day_one_place_4pre <= #U_DLY rtc_day - 'd360;
                            bcd_day_ten_place_4pre <= #U_DLY 'd6;
                        end   
                    else;
                end
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            bcd_day_one_place <= 'd0;
            bcd_day_ten_place <= 'd0;
            bcd_day_hun_place <= 'd0;
        end
    else
        begin
            if(bin_time_vld == 1'b1)
                begin
                    if(rtc_day <= 'd99)
                        bcd_day_one_place <= #U_DLY bcd_day_one_place_1pre;
                    else if(rtc_day >= 'd100 && rtc_day <= 'd199)
                        bcd_day_one_place <= #U_DLY bcd_day_one_place_2pre;
                    else if(rtc_day >= 'd200 && rtc_day <= 'd299)
                        bcd_day_one_place <= #U_DLY bcd_day_one_place_3pre;
                    else
                        bcd_day_one_place <= #U_DLY bcd_day_one_place_4pre;
                end
            else;

            if(bin_time_vld == 1'b1)
                begin
                    if(rtc_day <= 'd99)
                        bcd_day_ten_place <= #U_DLY bcd_day_ten_place_1pre;
                    else if(rtc_day >= 'd100 && rtc_day <= 'd199)
                        bcd_day_ten_place <= #U_DLY bcd_day_ten_place_2pre;
                    else if(rtc_day >= 'd200 && rtc_day <= 'd299)
                        bcd_day_ten_place <= #U_DLY bcd_day_ten_place_3pre;
                    else
                        bcd_day_ten_place <= #U_DLY bcd_day_ten_place_4pre;
                end
            else;

            if(bin_time_vld == 1'b1)
                begin
                    if(rtc_day <= 'd99)
                        bcd_day_hun_place <= #U_DLY 'd0;
                    else if(rtc_day >= 'd100 && rtc_day <= 'd199)
                        bcd_day_hun_place <= #U_DLY 'd1;
                    else if(rtc_day >= 'd200 && rtc_day <= 'd299)
                        bcd_day_hun_place <= #U_DLY 'd2;
                    else if(rtc_day >= 'd300 && rtc_day <= 'd399)
                        bcd_day_hun_place <= #U_DLY 'd3;
                    else;
                end
            else;
        end
end 
assign bcd_day = {bcd_day_hun_place,bcd_day_ten_place,bcd_day_one_place};
//bcd years
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            bcd_years_pre <= 'd0;
            bcd_year_one_place <= 'd0;
            bcd_year_ten_place <= 'd0;
        end
    else
        begin
            if(bin_time_vld_pre == 1'b1)
                bcd_years_pre <= #U_DLY rtc_year - 'd2000;
            else;

            if(bin_time_vld == 1'b1)
                begin
                    if(bcd_years_pre <= 'd9)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre[3:0];
                            bcd_year_ten_place <= #U_DLY 'd0;
                        end
                    else if(bcd_years_pre >= 'd10 && bcd_years_pre <= 'd19)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre - 'd10;
                            bcd_year_ten_place <= #U_DLY 'd1;
                        end
                    else if(bcd_years_pre >= 'd20 && bcd_years_pre <= 'd29)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre - 'd20;
                            bcd_year_ten_place <= #U_DLY 'd2;
                        end
                    else if(bcd_years_pre >= 'd30 && bcd_years_pre <= 'd39)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre - 'd30;
                            bcd_year_ten_place <= #U_DLY 'd3;
                        end
                    else if(bcd_years_pre >= 'd40 && bcd_years_pre <= 'd49)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre - 'd40;
                            bcd_year_ten_place <= #U_DLY 'd4;
                        end
                    else if(bcd_years_pre >= 'd50 && bcd_years_pre <= 'd59)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre - 'd50;
                            bcd_year_ten_place <= #U_DLY 'd5;
                        end
                    else if(bcd_years_pre >= 'd60 && bcd_years_pre <= 'd69)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre - 'd60;
                            bcd_year_ten_place <= #U_DLY 'd6;
                        end
                    else if(bcd_years_pre >= 'd70 && bcd_years_pre <= 'd79)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre - 'd70;
                            bcd_year_ten_place <= #U_DLY 'd7;
                        end
                    else if(bcd_years_pre >= 'd80 && bcd_years_pre <= 'd89)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre - 'd80;
                            bcd_year_ten_place <= #U_DLY 'd8;
                        end
                    else if(bcd_years_pre >= 'd90 && bcd_years_pre <= 'd99)
                        begin
                            bcd_year_one_place <= #U_DLY bcd_years_pre - 'd90;
                            bcd_year_ten_place <= #U_DLY 'd9;
                        end
                    else;
                end
        end
end
assign bcd_year = {bcd_year_ten_place,bcd_year_one_place};

endmodule

