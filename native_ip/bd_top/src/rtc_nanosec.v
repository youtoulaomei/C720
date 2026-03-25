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

output reg                          rtc_timing_1s,
//config interface
input                               cfg_en,
input           [11:0]              cfg_year,
input           [3:0]               cfg_month,
input           [4:0]               cfg_day,
input           [4:0]               cfg_hour,
input           [5:0]               cfg_min,
input           [5:0]               cfg_sec,
input           [9:0]               cfg_msec,
input           [9:0]               cfg_microsec,
input           [9:0]               cfg_nanosec,
//RTC time
output  reg     [11:0]              rtc_year,
output  reg     [3:0]               rtc_month,
output  reg     [4:0]               rtc_day,
output  reg     [4:0]               rtc_hour,
output  reg     [5:0]               rtc_min,
output  reg     [5:0]               rtc_sec,
output  reg     [9:0]               rtc_msec,
output  reg     [9:0]               rtc_microsec,
output  reg     [9:0]               rtc_nanosec
);
// Parameter Define 

// Register Define 
reg                                 nanosec_carry;
reg                                 microsec_carry;
reg                                 msec_carry;
reg                                 sec_carry;
reg                                 min_carry;
reg                                 hour_carry;
reg                                 day_carry;
reg                                 month_carry;
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
            else if(rtc_nanosec + CLK_PERIOD > 10'd999)
                rtc_nanosec <= #U_DLY rtc_nanosec + CLK_PERIOD - 10'd1000;
            else
                rtc_nanosec <= #U_DLY rtc_nanosec + CLK_PERIOD;

            if(nanosec_carry == 1'b1 || cfg_updata == 1'b1)
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
            else if(nanosec_carry == 1'b1)
                begin
                    if(rtc_microsec >= 10'd999)
                    //if(rtc_microsec >= 10'd99)
                        rtc_microsec <= #U_DLY 10'd0;
                    else
                        rtc_microsec <= #U_DLY rtc_microsec + 10'd1;
                 end
            else;
            
            if(cfg_updata == 1'b1)
                begin
                    if(cfg_microsec==10'd999)
                    //if(cfg_microsec==10'd99)
                        microsec_carry <= #U_DLY 1'b1;
                    else
                        microsec_carry <= #U_DLY 1'b0;
                end
            else if(nanosec_carry == 1'b1)
                begin
                    if(rtc_microsec >= 10'd999)
                    //if(rtc_microsec >= 10'd99)
                        microsec_carry <= #U_DLY 1'b0;
                    else if(rtc_microsec == 10'd998)
                    //else if(rtc_microsec == 10'd98)
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
            else if({microsec_carry,nanosec_carry} == 2'b11)
                begin
                    if(rtc_msec >= 10'd999)
                    //if(rtc_msec >= 10'd99)
                        rtc_msec <= #U_DLY 10'd0;
                    else
                        rtc_msec <= #U_DLY rtc_msec + 10'd1;
                end
            else;
            
            if(cfg_updata == 1'b1)
                begin
                    if(cfg_msec==10'd999)
                    //if(cfg_msec==10'd99)
                        msec_carry <= #U_DLY 1'b1;
                    else
                        msec_carry <= #U_DLY 1'b0;
                end
            else if({microsec_carry,nanosec_carry} == 2'b11) 
                begin
                    if(rtc_msec >= 10'd999)
                    //if(rtc_msec >= 10'd99)
                        msec_carry <= #U_DLY 1'b0;
                    else if(rtc_msec == 10'd998)
                    //else if(rtc_msec == 10'd98)
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
            else if({msec_carry,microsec_carry,nanosec_carry} == 3'b111)
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
            else if({msec_carry,microsec_carry,nanosec_carry} == 3'b111)
                begin
                    if(rtc_sec >= 6'd59)
                        sec_carry <= #U_DLY 1'b0;
                    else if(rtc_sec == 6'd58)
                        sec_carry <= #U_DLY 1'b1;
                    else;
                end
            else;

            if({msec_carry,microsec_carry,nanosec_carry} == 3'b111)
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
            else if({sec_carry,msec_carry,microsec_carry,nanosec_carry} == 4'hf)
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
            else if({sec_carry,msec_carry,microsec_carry,nanosec_carry} == 4'hf)
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
            else if({min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 5'h1f)
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
            else if({min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 5'h1f)
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
//day
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rtc_day <= 5'd1;
            day_carry <= 1'b0;
        end
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_day <= #U_DLY cfg_day;
            else if(rtc_day == 5'd0)
                rtc_day <= #U_DLY 5'd1;
            else if({hour_carry,min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 6'h3f)
                begin
                    case(rtc_month)
                        4'd1,4'd3,4'd5,4'd7,4'd8,4'd10,4'd12:begin
                            if(rtc_day >= 5'd31)
                                rtc_day <= #U_DLY 5'd1;
                            else
                                rtc_day <= #U_DLY rtc_day + 5'd1;end
                        4'd2:begin
                            if(rtc_year[1:0] == 2'b00)
                                begin
                                    if(rtc_day >= 5'd29)
                                        rtc_day <= #U_DLY 5'd1;
                                    else
                                        rtc_day <= #U_DLY rtc_day + 5'd1;
                                end
                            else
                                begin
                                    if(rtc_day >= 5'd28)
                                        rtc_day <= #U_DLY 5'd1;
                                    else
                                        rtc_day <= #U_DLY rtc_day + 5'd1;
                                end
                            end
                        default:begin
                            if(rtc_day >= 5'd30)
                                rtc_day <= #U_DLY 5'd1;
                            else
                                rtc_day <= #U_DLY rtc_day + 5'd1;end
                    endcase
                end
            else;

            if(cfg_updata == 1'b1)
                begin
                    case(cfg_month)
                        4'd1,4'd3,4'd5,4'd7,4'd8,4'd10,4'd12:begin
                            if(cfg_day == 5'd31)
                                day_carry <= #U_DLY 1'b1;
                            else 
                                day_carry <= #U_DLY 1'b0;
                            end
                        4'd2:begin
                            if(cfg_year[1:0] == 2'b00)
                                begin
                                    if(cfg_day == 5'd29)
                                        day_carry <= #U_DLY 1'b1;
                                    else 
                                        day_carry <= #U_DLY 1'b0;
                                end
                            else
                                begin
                                    if(cfg_day == 5'd28)
                                        day_carry <= #U_DLY 1'b1;
                                    else 
                                        day_carry <= #U_DLY 1'b0;
                                end
                            end
                        4'd4,4'd6,4'd9,4'd11:begin
                            if(cfg_day == 5'd30)
                                day_carry <= #U_DLY 1'b1;
                            else 
                                day_carry <= #U_DLY 1'b0;end
                        default:begin
                            if(cfg_day == 5'd30)
                                day_carry <= #U_DLY 1'b1;
                            else 
                                day_carry <= #U_DLY 1'b0;end
                    endcase
                end
            else if({hour_carry,min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 6'h3f)
                begin
                    case(rtc_month)
                        4'd1,4'd3,4'd5,4'd7,4'd8,4'd10,4'd12:begin
                            if(rtc_day >= 5'd31)
                                day_carry <= #U_DLY 1'b0;
                            else if(rtc_day == 5'd30)
                                day_carry <= #U_DLY 1'b1;end
                        4'd2:begin
                            if(rtc_year[1:0] == 2'b00)
                                begin
                                    if(rtc_day >= 5'd29)
                                        day_carry <= #U_DLY 1'b0;
                                    else if(rtc_day == 5'd28)
                                        day_carry <= #U_DLY 1'b1;
                                    else;
                                end
                            else
                                begin
                                    if(rtc_day >= 5'd28)
                                        day_carry <= #U_DLY 1'b0;
                                    else if(rtc_day == 5'd27)
                                        day_carry <= #U_DLY 1'b1;
                                    else;
                                end
                            end
                        4'd4,4'd6,4'd9,4'd11:begin
                            if(rtc_day >= 5'd30)
                                day_carry <= #U_DLY 1'b0;
                            else if(rtc_day == 5'd29)
                                day_carry <= #U_DLY 1'b1;end
                        default:begin
                            if(rtc_day >= 5'd30)
                                day_carry <= #U_DLY 1'b0;
                            else if(rtc_day == 5'd29)
                                day_carry <= #U_DLY 1'b1;end
                    endcase
                end
            else;
        end
end
//month
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rtc_month <= 4'd1;
            month_carry <= 1'b0;
        end
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_month <= #U_DLY cfg_month;
            else if(rtc_month == 4'd0)
                rtc_month <= #U_DLY 4'd1;
            else if({day_carry,hour_carry,min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 7'h7f)
                begin
                    if(rtc_month >= 4'd12)
                        rtc_month <= #U_DLY 4'd1;
                    else 
                        rtc_month <= #U_DLY rtc_month + 4'd1;
                end
            else;

            if(cfg_updata == 1'b1)
                begin
                    if(cfg_month==4'd12)
                        month_carry <= #U_DLY 1'b1;
                    else
                        month_carry <= #U_DLY 1'b0;
                end            
            else if({day_carry,hour_carry,min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 7'h7f)
                begin
                    if(rtc_month >= 4'd12)
                        month_carry <= #U_DLY 1'b0;
                    else if(rtc_month == 4'd11)
                        month_carry <= #U_DLY 1'b1;
                end
            else;
        end
end
//year
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        rtc_year <= 12'h7DF;          //2015
    else
        begin
            if(cfg_updata == 1'b1)
                rtc_year <= #U_DLY cfg_year; 
            else if({month_carry,day_carry,hour_carry,min_carry,sec_carry,msec_carry,microsec_carry,nanosec_carry} == 8'hff)
                rtc_year <= #U_DLY rtc_year + 12'd1;
            else;
        end
end





endmodule

