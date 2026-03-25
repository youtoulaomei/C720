// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2019/8/30 17:16:37
// File Name    : bcode_tx_phy.v
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
module bcode_tx_phy #(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst,
//
(* IOB="true" *)output  reg         bcode_tx,
//interface with tx_stm
input                               bcd_time_vld,
input           [7:0]               bcd_year,
input           [9:0]               bcd_day,
input           [5:0]               bcd_hour,
input           [6:0]               bcd_min,
input           [6:0]               bcd_sec,
input           [16:0]              bin_str_sec,

input           [8:0]               ctl_0_func,
input           [8:0]               ctl_1_func,
//interface with RTC
input                               nanosec_carry,
input                               microsec_carry,
input                               msec_carry,
//for debug
input                               tx_en,
input           [19:0]              zero_neg_cnt,        //2ms
input           [19:0]              one_neg_cnt,         //5ms
input           [19:0]              ctl_neg_cnt          //8ms
);
// Parameter Define 

// Register Define 
reg     [19:0]                      millsec_10_cnt;
reg     [6:0]                       send_bit_cnt;
reg                                 pos_edge_en;
reg                                 pos_edge_en_dly;
reg     [6:0]                       sec_shift;
reg     [6:0]                       min_shift;
reg     [5:0]                       hour_shift;
reg     [9:0]                       day_shift;
reg     [7:0]                       year_shift;
reg     [8:0]                       ctl_0_func_shift;
reg     [8:0]                       ctl_1_func_shift;
reg     [16:0]                      str_sec_shift;
reg     [1:0]                       send_symbol;
reg                                 neg_edge_en;
// Wire Define 
wire                                sec_start;

assign sec_start = msec_carry & microsec_carry & nanosec_carry;
//10ms time define.the first Pr posedge is triggered by sec_start
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            millsec_10_cnt <= 20'd0;
            send_bit_cnt <= 7'd100;
            pos_edge_en <= 1'b0;
            pos_edge_en_dly <= 1'b0;
        end
    else
        begin
            if(sec_start == 1'b1 || tx_en == 1'b0)
                millsec_10_cnt <= #U_DLY 'd0; 
            else if(send_bit_cnt <= 'd99)
                begin
                    if(millsec_10_cnt >= 20'd999_999)
                        millsec_10_cnt <= #U_DLY 'd0;
                    else
                        millsec_10_cnt <= #U_DLY millsec_10_cnt + 'd1;
                end
            else;

            if(sec_start == 1'b1 || tx_en == 1'b0)
                send_bit_cnt <= #U_DLY 'd0;
            else if(millsec_10_cnt >= 20'd999_999)
                begin
                    if(send_bit_cnt <= 'd99)
                        send_bit_cnt <= #U_DLY send_bit_cnt + 'd1;
                    else;
                end
            else;

            if(send_bit_cnt <= 'd98 && millsec_10_cnt == 20'd999_998)
                pos_edge_en <= #U_DLY 1'b1;
            else
                pos_edge_en <= #U_DLY 1'b0;  

            pos_edge_en_dly <= #U_DLY pos_edge_en;
        end
end 
//timer shift
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            sec_shift <= 7'd0;
            min_shift <= 7'd0;
            hour_shift <= 6'd0;
            day_shift <= 10'd0;
            year_shift <= 8'd0;
            ctl_0_func_shift <= 9'd0;
            ctl_1_func_shift <= 9'd0;
            str_sec_shift <= 17'd0;
        end
    else 
        begin
            if(bcd_time_vld == 1'b1)
                sec_shift <= #U_DLY bcd_sec;
            else if(pos_edge_en == 1'b1 && ((send_bit_cnt >= 'd1 && send_bit_cnt <= 'd4) || (send_bit_cnt >= 'd6 && send_bit_cnt <= 'd8)))
                sec_shift <= #U_DLY sec_shift >> 1;
            else;

            if(bcd_time_vld == 1'b1)
                min_shift <= #U_DLY bcd_min;
            else if(pos_edge_en == 1'b1 && ((send_bit_cnt >= 'd10 && send_bit_cnt <= 'd13) || (send_bit_cnt >= 'd15 && send_bit_cnt <= 'd17)))
                min_shift <= #U_DLY min_shift >> 1;
            else;

            if(bcd_time_vld == 1'b1)
                hour_shift <= #U_DLY bcd_hour;
            else if(pos_edge_en == 1'b1 && ((send_bit_cnt >= 'd20 && send_bit_cnt <= 'd23) || (send_bit_cnt >= 'd25 && send_bit_cnt <= 'd27)))
                hour_shift <= #U_DLY hour_shift >> 1;
            else;

            if(bcd_time_vld == 1'b1)
                day_shift <= #U_DLY bcd_day;
            else if(pos_edge_en == 1'b1 && ((send_bit_cnt >= 'd30 && send_bit_cnt <= 'd33) || (send_bit_cnt >= 'd35 && send_bit_cnt <= 'd38) || (send_bit_cnt >= 'd40 && send_bit_cnt <= 'd41)))
                day_shift <= #U_DLY day_shift >> 1;
            else;

            if(bcd_time_vld == 1'b1)
                year_shift <= #U_DLY bcd_year;
            else if(pos_edge_en == 1'b1 && ((send_bit_cnt >= 'd50 && send_bit_cnt <= 'd53) || (send_bit_cnt >= 'd55 && send_bit_cnt <= 'd58)))
                year_shift <= #U_DLY year_shift >> 1;
            else;

            if(bcd_time_vld == 1'b1)
                ctl_0_func_shift <= #U_DLY ctl_0_func;
            else if(pos_edge_en == 1'b1 && send_bit_cnt >= 'd60 && send_bit_cnt <= 'd68)
                ctl_0_func_shift <= #U_DLY ctl_0_func_shift >> 1;
            else;

            if(bcd_time_vld == 1'b1)
                ctl_1_func_shift <= #U_DLY ctl_1_func;
            else if(pos_edge_en == 1'b1 && send_bit_cnt >= 'd70 && send_bit_cnt <= 'd78)
                ctl_1_func_shift <= #U_DLY ctl_1_func_shift >> 1;
            else;

            if(bcd_time_vld == 1'b1)
                str_sec_shift <= #U_DLY bin_str_sec;
            else if(pos_edge_en == 1'b1 && ((send_bit_cnt >= 'd80 && send_bit_cnt <= 'd88) || (send_bit_cnt >= 'd90 && send_bit_cnt <= 'd97)))
                str_sec_shift <= #U_DLY str_sec_shift >> 1;
            else;
        end
end
//send symbol select
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        send_symbol <= 2'd0;         //11: "P" ; 10: "1" ; 01: "0";
    else
        begin
            if(sec_start == 1'b1)                         //Pr
                send_symbol <= #U_DLY 2'b11;       
            else if(pos_edge_en_dly == 1'b1 && (send_bit_cnt == 'd9 || send_bit_cnt == 'd19 || send_bit_cnt == 'd29 || send_bit_cnt == 'd39 || send_bit_cnt == 'd49 || send_bit_cnt == 'd59 || send_bit_cnt == 'd69 || send_bit_cnt == 'd79 || send_bit_cnt == 'd89 || send_bit_cnt == 'd99))//P0-P9
                send_symbol <= #U_DLY 2'b11;       
            else if(pos_edge_en_dly == 1'b1 && ((send_bit_cnt >= 'd1 && send_bit_cnt <= 'd4) || (send_bit_cnt >= 'd6 && send_bit_cnt <= 'd8)))//seconds
                begin
                    if(sec_shift[0] == 1'b0)
                        send_symbol <= #U_DLY 2'b01;
                    else
                        send_symbol <= #U_DLY 2'b10;
                end
            else if(pos_edge_en_dly == 1'b1 && ((send_bit_cnt >= 'd10 && send_bit_cnt <= 'd13) || (send_bit_cnt >= 'd15 && send_bit_cnt <= 'd17)))//minutes
                begin
                    if(min_shift[0] == 1'b0)
                        send_symbol <= #U_DLY 2'b01;
                    else
                        send_symbol <= #U_DLY 2'b10;
                end
            else if(pos_edge_en_dly == 1'b1 && ((send_bit_cnt >= 'd20 && send_bit_cnt <= 'd23) || (send_bit_cnt >= 'd25 && send_bit_cnt <= 'd27)))//hours
                begin
                    if(hour_shift[0] == 1'b0)
                        send_symbol <= #U_DLY 2'b01;
                    else
                        send_symbol <= #U_DLY 2'b10;
                end
            else if(pos_edge_en_dly == 1'b1 && ((send_bit_cnt >= 'd30 && send_bit_cnt <= 'd33) || (send_bit_cnt >= 'd35 && send_bit_cnt <= 'd38) || (send_bit_cnt >= 'd40 && send_bit_cnt <= 'd41)))//days
                begin
                    if(day_shift[0] == 1'b0)
                        send_symbol <= #U_DLY 2'b01;
                    else
                        send_symbol <= #U_DLY 2'b10;
                end
            else if(pos_edge_en_dly == 1'b1 && ((send_bit_cnt >= 'd50 && send_bit_cnt <= 'd53) || (send_bit_cnt >= 'd55 && send_bit_cnt <= 'd58)))
                begin
                    if(year_shift[0] == 1'b0)
                        send_symbol <= #U_DLY 2'b01;
                    else
                        send_symbol <= #U_DLY 2'b10;
                end
            else if(pos_edge_en_dly == 1'b1 && send_bit_cnt >= 'd60 && send_bit_cnt <= 'd68)
                begin
                    if(ctl_0_func_shift[0] == 1'b0)
                        send_symbol <= #U_DLY 2'b01;
                    else
                        send_symbol <= #U_DLY 2'b10;
                end
            else if(pos_edge_en_dly == 1'b1 && send_bit_cnt >= 'd70 && send_bit_cnt <= 'd78)
                begin
                    if(ctl_1_func_shift[0] == 1'b0)
                        send_symbol <= #U_DLY 2'b01;
                    else
                        send_symbol <= #U_DLY 2'b10;
                end
            else if(pos_edge_en_dly == 1'b1 && ((send_bit_cnt >= 'd80 && send_bit_cnt <= 'd88) || (send_bit_cnt >= 'd90 && send_bit_cnt <= 'd97)))
                begin
                    if(str_sec_shift[0] == 1'b0)
                        send_symbol <= #U_DLY 2'b01;
                    else
                        send_symbol <= #U_DLY 2'b10;
                end
            else if(pos_edge_en_dly == 1'b1)
                send_symbol <= #U_DLY 2'b01;                              //all others not define data are send 0 
            else;
        end
end
//negedge enable
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        neg_edge_en <= 1'b0;
    else 
        begin
            if((send_symbol == 2'b11 && millsec_10_cnt == ctl_neg_cnt) || (send_symbol == 2'b01 && millsec_10_cnt == zero_neg_cnt) || (send_symbol == 2'b10 && millsec_10_cnt == one_neg_cnt)) 
                neg_edge_en <= #U_DLY 1'b1;
            else
                neg_edge_en <= #U_DLY 1'b0;
        end
end
//tx IO
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        bcode_tx <= 1'b0;
    else
        begin
            if(sec_start == 1'b1 || pos_edge_en == 1'b1)
                bcode_tx <= #U_DLY 1'b1;
            else if(neg_edge_en == 1'b1)
                bcode_tx <= #U_DLY 1'b0;
            else;
        end
end

endmodule

