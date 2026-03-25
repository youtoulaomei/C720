// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2015/9/21 10:49:28
// File Name    : rtc_nanosec.v
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
module rtc_nanosec #(
parameter                           U_DLY = 1,
parameter                           CLK_PERIOD = 10
)
(
input                               rst,
input                               clk,

input                               rtc_mode,
//config interface
input                               cfg_en,
input           [11:0]              cfg_year,
input           [8:0]               cfg_day,
input           [4:0]               cfg_hour,
input           [5:0]               cfg_min,
input           [5:0]               cfg_sec,
input           [9:0]               cfg_msec,
input           [9:0]               cfg_microsec,
input           [9:0]               cfg_nanosec,
//bcode interface
input                               bcode_en,
input           [11:0]              bcode_year,
input           [8:0]               bcode_day,
input           [4:0]               bcode_hour,
input           [5:0]               bcode_min,
input           [5:0]               bcode_sec,
input           [9:0]               bcode_msec,
input           [9:0]               bcode_microsec,
input           [9:0]               bcode_nanosec,

input           [1:0]               rx_sfh_dly,
//RTC time
output  reg     [11:0]              rtc_year,
output  reg     [8:0]               rtc_day,
output  reg     [4:0]               rtc_hour,
output  reg     [5:0]               rtc_min,
output  reg     [5:0]               rtc_sec,
output  reg     [9:0]               rtc_msec,
output  reg     [9:0]               rtc_microsec,
output  reg     [9:0]               rtc_nanosec,
output  reg                         rtc_timing_1s,
//straight binary seconds
input           [16:0]              str_sec,
input                               str_sec_vld,
output  reg     [16:0]              rtc_str_sec,
//for bcode tx
output  reg                         nanosec_carry,
output  reg                         microsec_carry,
output  reg                         msec_carry
);
// Parameter Define 

// Register Define 
reg                                 sec_carry;
reg                                 min_carry;
reg                                 hour_carry;
reg                                 day_carry;
reg             [2:0]               cfg_en_dly;
reg                                 cfg_updata;
// Wire Define 

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cfg_en_dly <= 3'd0;
            cfg_updata <= 1'b0;
        end
    else
        begin
            cfg_en_dly <= #U_DLY {cfg_en_dly[1:0],cfg_en};

            if(cfg_updata == 1'b1)
                cfg_updata <= #U_DLY 1'b0;
            else if(cfg_en_dly[2:1] == 2'b01)
                cfg_updata <= #U_DLY 1'b1;
            else;
        end
end
//ns
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rtc_nanosec <= 10'd0;
            nanosec_carry <= 1'b0;
        end
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_nanosec <= #U_DLY cfg_nanosec;
            else if(bcode_en == 1'b1)
                rtc_nanosec <= #U_DLY bcode_nanosec;
            else if(rtc_nanosec + CLK_PERIOD > 10'd999)
                rtc_nanosec <= #U_DLY rtc_nanosec + CLK_PERIOD - 10'd1000;
            else
                rtc_nanosec <= #U_DLY rtc_nanosec + CLK_PERIOD;

            if(nanosec_carry == 1'b1 || cfg_updata == 1'b1 || bcode_en == 1'b1)
                nanosec_carry <= #U_DLY 1'b0;
            else if((rtc_nanosec + (CLK_PERIOD << 1)) > 10'd999)
                nanosec_carry <= #U_DLY 1'b1;
            else;
        end
end
//us
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rtc_microsec <= 10'd0;
            microsec_carry <= 1'b0;
        end
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_microsec <= #U_DLY cfg_microsec;
            else if(bcode_en == 1'b1)
                rtc_microsec <= #U_DLY bcode_microsec;
            else if(nanosec_carry == 1'b1)
                begin
                    if(rtc_microsec >= 10'd999)
                        rtc_microsec <= #U_DLY 10'd0;
                    else
                        rtc_microsec <= #U_DLY rtc_microsec + 10'd1;
                 end
            else;

            if(cfg_updata == 1'b1)
                begin
                    if(cfg_microsec==10'd999) 
                        microsec_carry <= #U_DLY 1'b1;
                    else
                        microsec_carry <= #U_DLY 1'b0;
                end
            else if(bcode_en == 1'b1)
                begin
                    if(bcode_microsec==10'd999) 
                        microsec_carry <= #U_DLY 1'b1;
                    else
                        microsec_carry <= #U_DLY 1'b0;
                end

            else if(nanosec_carry == 1'b1)
                begin
                    if(rtc_microsec >= 10'd999)
                        microsec_carry <= #U_DLY 1'b0;
                    else if(rtc_microsec == 10'd998)
                        microsec_carry <= #U_DLY 1'b1;
                    else;
                end
            else;
        end
end
//ms
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rtc_msec <= 10'd0;
            msec_carry <= 1'b0;
        end
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_msec <= #U_DLY cfg_msec;
            else if(bcode_en == 1'b1)
                rtc_msec <= #U_DLY bcode_msec;
            else if({microsec_carry,nanosec_carry} == 2'b11)
                begin
                    if(rtc_msec >= 10'd999)
                        rtc_msec <= #U_DLY 10'd0;
                    else
                        rtc_msec <= #U_DLY rtc_msec + 10'd1;
                end
            else;

            if(cfg_updata == 1'b1)
                begin
                    if(cfg_msec==10'd999)
                        msec_carry <= #U_DLY 1'b1;
                    else
                        msec_carry <= #U_DLY 1'b0;
                end
            else if(bcode_en == 1'b1)
                begin
                    if(bcode_msec==10'd999)
                        msec_carry <= #U_DLY 1'b1;
                    else
                        msec_carry <= #U_DLY 1'b0;
                end
            else if({microsec_carry,nanosec_carry} == 2'b11)
                begin
                    if(rtc_msec >= 10'd999)
                        msec_carry <= #U_DLY 1'b0;
                    else if(rtc_msec == 10'd998)
                        msec_carry <= #U_DLY 1'b1;
                    else;
                end
            else;
        end
end
//second
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rtc_sec <= 6'd0;
            sec_carry <= 1'b0;
            rtc_timing_1s <= #U_DLY 1'b0;
        end
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_sec <= #U_DLY cfg_sec;
            else if(bcode_en == 1'b1)
                rtc_sec <= #U_DLY bcode_sec;
            else if((rtc_mode == 1'b0 && {msec_carry,microsec_carry,nanosec_carry} == 3'b111) || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01))
                begin
                    if(rtc_sec >= 6'd59)
                        rtc_sec <= #U_DLY 6'd0;
                    else
                        rtc_sec <= #U_DLY rtc_sec + 6'd1;
                end
            else;

            if(cfg_updata == 1'b1)
                begin
                    if(cfg_sec==6'd59)
                        sec_carry <= #U_DLY 1'b1;
                    else
                        sec_carry <= #U_DLY 1'b0;
                end
            else if(bcode_en == 1'b1)
                begin
                    if(bcode_sec==6'd59)
                        sec_carry <= #U_DLY 1'b1;
                    else
                        sec_carry <= #U_DLY 1'b0;
                end
            else if((rtc_mode == 1'b0 && {msec_carry,microsec_carry,nanosec_carry} == 3'b111) || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01))
                begin
                    if(rtc_sec >= 6'd59)
                        sec_carry <= #U_DLY 1'b0;
                    else if(rtc_sec == 6'd58)
                        sec_carry <= #U_DLY 1'b1;
                    else;
                end
            else;

            if((rtc_mode == 1'b0 && {msec_carry,microsec_carry,nanosec_carry} == 3'b111) || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01))
                rtc_timing_1s <= #U_DLY ~rtc_timing_1s;

        end
end
//minute
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rtc_min <= 6'd0;
            min_carry <= 1'b0;
        end
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_min <= #U_DLY cfg_min;
            else if(bcode_en == 1'b1)
                rtc_min <= #U_DLY bcode_min;
            else if((rtc_mode == 1'b0 && {sec_carry,msec_carry,microsec_carry,nanosec_carry} == 4'hf) || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01 && sec_carry == 1'b1))
                begin
                    if(rtc_min >= 6'd59)
                        rtc_min <= #U_DLY 6'd0;
                    else
                        rtc_min <= #U_DLY rtc_min + 6'd1;
                end
            else;

            if(cfg_updata == 1'b1)
                begin
                    if(cfg_min==6'd59)
                        min_carry <= #U_DLY 1'b1;
                    else
                        min_carry <= #U_DLY 1'b0;
                end
            else if(bcode_en == 1'b1)
                begin
                    if(bcode_min==6'd59)
                        min_carry <= #U_DLY 1'b1;
                    else
                        min_carry <= #U_DLY 1'b0;
                end
            else if((rtc_mode == 1'b0 && {sec_carry,msec_carry,microsec_carry,nanosec_carry} == 4'hf) || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01 && sec_carry == 1'b1))
                begin
                    if(rtc_min >= 6'd59)
                        min_carry <= #U_DLY 1'b0;
                    else if(rtc_min == 6'd58)
                        min_carry <= #U_DLY 1'b1;
                    else;
                end
            else;
        end
end
//hour
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rtc_hour <= 5'd0;
            hour_carry <= 1'b0;
        end
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_hour <= #U_DLY cfg_hour;
            else if(bcode_en == 1'b1)
                rtc_hour <= #U_DLY bcode_hour;
            else if((rtc_mode == 1'b0 && {min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 5'h1f) || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01 && {min_carry,sec_carry} == 2'b11))
                begin
                    if(rtc_hour >= 5'd23)
                        rtc_hour <= #U_DLY 5'd0;
                    else 
                        rtc_hour <= #U_DLY rtc_hour + 5'd1;
                end
            else;

            if(cfg_updata == 1'b1)
                begin
                    if(cfg_hour==5'd23)
                        hour_carry <= #U_DLY 1'b1;
                    else
                        hour_carry <= #U_DLY 1'b0;
                end
            else if(bcode_en == 1'b1)
                begin
                    if(bcode_hour==5'd23)
                        hour_carry <= #U_DLY 1'b1;
                    else
                        hour_carry <= #U_DLY 1'b0;
                end
            else if((rtc_mode == 1'b0 && {min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 5'h1f) || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01 && {min_carry,sec_carry} == 2'b11))
                begin
                    if(rtc_hour >= 5'd23)
                        hour_carry <= #U_DLY 1'b0;
                    else if(rtc_hour == 5'd22)
                        hour_carry <= #U_DLY 1'b1;
                    else;
                end
            else;
        end
end
//day.modified 20190830 for B-code timer
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rtc_day <= 9'd1;
            day_carry <= 1'b0;
        end
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_day <= #U_DLY cfg_day;
            else if(bcode_en == 1'b1)
                rtc_day <= #U_DLY bcode_day;
            else if(rtc_day == 9'd0)
                rtc_day <= #U_DLY 9'd1;
            else if((rtc_mode == 1'b0 && {hour_carry,min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 6'h3f)
                || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01 && {hour_carry,min_carry,sec_carry} == 3'b111))
                begin
                    if(rtc_year[1:0] == 2'b00) 
                        if(rtc_day >= 9'd366)
                            rtc_day <= #U_DLY 9'd1;
                        else
                            rtc_day <= #U_DLY rtc_day + 9'd1;
                    else 
                        if(rtc_day >= 9'd365)
                            rtc_day <= #U_DLY 9'd1;
                        else
                            rtc_day <= #U_DLY rtc_day + 9'd1;
                end

            if(cfg_updata == 1'b1)
                begin
                    if(cfg_year[1:0]==2'b00)
                        if(cfg_day>=9'd366)
                            day_carry <= #U_DLY 1'b1;
                        else
                            day_carry <= #U_DLY 1'b0;
                    else
                        if(cfg_day>=9'd365)
                            day_carry <= #U_DLY 1'b1;
                        else
                            day_carry <= #U_DLY 1'b0;
                end
            else if(bcode_en == 1'b1)
                begin
                    if(bcode_year[1:0]==2'b00)
                        if(bcode_day>=9'd366)
                            day_carry <= #U_DLY 1'b1;
                        else
                            day_carry <= #U_DLY 1'b0;
                    else
                        if(bcode_day>=9'd365)
                            day_carry <= #U_DLY 1'b1;
                        else
                            day_carry <= #U_DLY 1'b0;
                end            
            else if((rtc_mode == 1'b0 && {hour_carry,min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 6'h3f)
                || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01 && {hour_carry,min_carry,sec_carry} == 3'b111))
                begin
                    if(rtc_year[1:0] == 2'b00)
                        if(rtc_day >= 9'd366)
                            day_carry <= #U_DLY 1'b0;
                        else if(rtc_day == 9'd365)
                            day_carry <= #U_DLY 1'b1;
                    else 
                        if(rtc_day >= 9'd365)
                           day_carry <= #U_DLY 1'b0;
                        else if(rtc_day == 9'd364)
                           day_carry <= #U_DLY 1'b1;
                end
        end
end    
//year
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        rtc_year <= 12'h7E3;          //2019
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_year <= #U_DLY cfg_year; 
            else if(bcode_en == 1'b1)
                rtc_year <= #U_DLY bcode_year;
            else if((rtc_mode == 1'b0 && {day_carry,hour_carry,min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 7'h7f)
                || (rtc_mode == 1'b1 && rx_sfh_dly == 2'b01 && {day_carry,hour_carry,min_carry,sec_carry} == 4'hf))
                rtc_year <= #U_DLY rtc_year + 12'd1;
            else;
        end
end
//straight binary seconds
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        rtc_str_sec <= 17'd1;
    else
        begin
            if(str_sec_vld == 1'b1)
                rtc_str_sec <= #U_DLY str_sec;
            else if({msec_carry,microsec_carry,nanosec_carry} == 3'h7)
                begin
                    if(rtc_str_sec >= 17'd86400)
                        rtc_str_sec <= #U_DLY 17'd1;
                    else
                        rtc_str_sec <= #U_DLY rtc_str_sec + 17'd1;
                end
            else;
        end
end


endmodule

