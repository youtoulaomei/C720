// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2019/8/29 16:38:58
// File Name    : bcode_rx_stm.v
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
module bcode_rx_stm #(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst,
//seconds frame header
input                               rx_sfh,
//
input                               rx_vld,
input           [1:0]               rx_ind,                   //11:crl_code; 01:"0"; 10:"1"; 00:err

input                               millsec10_pulse,          //start of 10 millseconds,has 30ns offset because of the delay of bacode_rx
//
output  reg                         bcode_time_vld,
output  reg     [11:0]              bcode_year,
output  reg     [8:0]               bcode_day,
output  reg     [4:0]               bcode_hour,
output  reg     [5:0]               bcode_min,
output  reg     [5:0]               bcode_sec,    
output  reg     [9:0]               bcode_msec,
output  reg     [9:0]               bcode_microsec,
output  reg     [9:0]               bcode_nanosec,

output  wire    [1:0]               rx_sfh_dly,

output  reg     [16:0]              str_sec,
output  reg                         str_sec_vld,
output  reg     [8:0]               ctl_0func,
output  reg     [8:0]               ctl_1func,
//debug
output  reg                         vld_time_out,
output  reg                         rec_p_err,
output  reg     [2:0]               l1_state,
output  reg     [3:0]               l2_state,
input                               sec_framehead_en,
input           [9:0]               cfg_nanosec_offset,

input                               authorize_succ 
);
// Parameter Define 
localparam                          HUNT = 3'b001; 
localparam                          PRE_HUNT = 3'b010; 
localparam                          SYNC = 3'b100; 

localparam                          L2_IDLE = 4'b0000; 
localparam                          L2_PR = 4'b0001; 
localparam                          L2_SECONDS = 4'b0010; 
localparam                          L2_MINUTES = 4'b0011; 
localparam                          L2_HOURS = 4'b0100; 
localparam                          L2_DAYS_LOW = 4'b0101; 
localparam                          L2_DAYS_HIGH = 4'b0110; 
localparam                          L2_YEARS = 4'b0111; 
localparam                          L2_CTL_FUNC_LOW = 4'b1000; 
localparam                          L2_CTL_FUNC_HIGH = 4'b1001; 
localparam                          L2_SBS_LOW = 4'b1010; 
localparam                          L2_SBS_HIGH = 4'b1011; 
// Register Define 
reg     [19:0]                      vld_time_cnt;
reg     [2:0]                       l1_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [2:0]                       l1_next_st;
reg     [2:0]                       l1_cur_st_dly;
reg     [3:0]                       l2_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [3:0]                       l2_next_st;
reg     [3:0]                       rec_data_cnt;
reg     [3:0]                       seconds_one_place;
reg     [2:0]                       seconds_ten_place;
reg     [5:0]                       bin_sec;
reg     [3:0]                       minutes_one_place;
reg     [2:0]                       minutes_ten_place;
reg     [5:0]                       bin_min;
reg     [4:0]                       bin_hour;
reg     [3:0]                       hours_one_place;
reg     [1:0]                       hours_ten_place;
reg     [3:0]                       days_one_place;
reg     [3:0]                       days_ten_place;
reg     [1:0]                       days_hun_place;
reg     [8:0]                       bin_day;
reg                                 years_ten_ind;
reg     [3:0]                       years_one_place;
reg     [3:0]                       years_ten_place;
reg     [11:0]                      bin_year;
reg     [8:0]                       ctl_func0_word;
reg     [8:0]                       ctl_func1_word;
reg                                 ctl_func_vld;
reg     [16:0]                      str_bin_sec;
reg                                 str_bin_vld;
(* IOB="true" *)reg                 rx_sfh_1dly;
reg                                 rx_sfh_2dly;
reg                                 rx_sfh_3dly;
// Wire Define 


always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            vld_time_cnt <= 'hf_ffff;
            vld_time_out <= 1'b0;
        end
    else
        begin
            if(rx_vld == 1'b1)
                vld_time_cnt <= #U_DLY 'd0;
            else if(vld_time_cnt != 'hf_ffff)
                vld_time_cnt <= #U_DLY vld_time_cnt + 'd1;
            else;

            if(vld_time_cnt == 'hf_fffe)                  //about 10.4ms 
                vld_time_out <= #U_DLY 1'b1;
            else
                vld_time_out <= #U_DLY 1'b0;
        end
end
//level 1 stm
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        l1_cur_st <= HUNT;
    else
        l1_cur_st <= l1_next_st;
end

always @(*)
begin
    if(authorize_succ == 1'b0)
        l1_next_st = HUNT;
    else
        begin
            case(l1_cur_st)
                HUNT:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)     //received P
                        l1_next_st = PRE_HUNT;
                    else
                        l1_next_st = HUNT;end
                PRE_HUNT:begin
                    if(vld_time_out == 1'b1)
                        l1_next_st = HUNT;
                    else if(rx_vld == 1'b1)
                        begin
                            if(rx_ind != 2'b11)               //received P
                                l1_next_st = HUNT;
                            else
                                l1_next_st = SYNC;
                        end
                    else
                        l1_next_st = PRE_HUNT;end
                SYNC:begin
                    if(vld_time_out == 1'b1 || rec_p_err == 1'b1)
                        l1_next_st = HUNT;
                    else if(rx_vld == 1'b1 && rx_ind == 2'b00)//received err
                        l1_next_st = HUNT;
                    else
                        l1_next_st = SYNC;end
                default:l1_next_st = HUNT;
            endcase
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        l1_cur_st_dly <= HUNT;
    else
        l1_cur_st_dly <= #U_DLY l1_cur_st;
end
//level 2 stm
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        l2_cur_st <= L2_IDLE;
    else
        l2_cur_st <= #U_DLY l2_next_st;
end

always @(*)
begin
    if(l1_cur_st == SYNC)
        begin
            case(l2_cur_st)
                L2_IDLE:begin
                    if(l1_cur_st_dly == PRE_HUNT)        //when l1 enter SYNC,l2 enter SECOND   
                        l2_next_st = L2_SECONDS;
                    else
                        l2_next_st = L2_IDLE;end
                L2_PR:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)//receive P
                        l2_next_st = L2_SECONDS;
                    else
                        l2_next_st = L2_PR;end
                L2_SECONDS:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_MINUTES;
                    else
                        l2_next_st = L2_SECONDS;end
                L2_MINUTES:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_HOURS;
                    else
                        l2_next_st = L2_MINUTES;end
                L2_HOURS:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_DAYS_LOW;
                    else
                        l2_next_st = L2_HOURS;end
                L2_DAYS_LOW:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_DAYS_HIGH;
                    else
                        l2_next_st = L2_DAYS_LOW;end
                L2_DAYS_HIGH:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_YEARS;
                    else
                        l2_next_st = L2_DAYS_HIGH;end
                L2_YEARS:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_CTL_FUNC_LOW;
                    else
                        l2_next_st = L2_YEARS;end                        
                L2_CTL_FUNC_LOW:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_CTL_FUNC_HIGH;
                    else
                        l2_next_st = L2_CTL_FUNC_LOW;end 
                L2_CTL_FUNC_HIGH:begin
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_SBS_LOW;
                    else
                        l2_next_st = L2_CTL_FUNC_HIGH;end
                L2_SBS_LOW:begin                                  //SBS:straight binary seconds
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_SBS_HIGH;
                    else
                        l2_next_st = L2_SBS_LOW;end
                L2_SBS_HIGH:begin  
                    if(rx_vld == 1'b1 && rx_ind == 2'b11)
                        l2_next_st = L2_PR;
                    else
                        l2_next_st = L2_SBS_HIGH;end
                default:l2_next_st = L2_IDLE;
            endcase
        end
    else
        l2_next_st = L2_IDLE;
end
//for restart sync
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rec_data_cnt <= 4'd0;
            rec_p_err <= 1'b0;
        end
    else
        begin
            if(rx_vld == 1'b1)
                begin
                   if(rx_ind == 2'b11)                             //received P
                       rec_data_cnt <= #U_DLY 'd0;
                   else
                       rec_data_cnt <= #U_DLY rec_data_cnt + 'd1;
                end
            else;

            if(rx_vld == 1'b1 && rx_ind == 2'b11)                  //received P
                begin
                    if((l2_cur_st != L2_PR && l2_cur_st != L2_IDLE && l2_cur_st != L2_SECONDS) && rec_data_cnt <= 'd8)   
                        rec_p_err <= #U_DLY 1'b1;
                    else if(l2_cur_st == L2_SECONDS && rec_data_cnt <= 'd7)          //seconds period has one slot is replaced by PR
                        rec_p_err <= #U_DLY 1'b1;
                    else
                        rec_p_err <= #U_DLY 1'b0;
                end
            else
                rec_p_err <= #U_DLY 1'b0;
        end
end
//**********************************************************************//
//seconds
//**********************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            seconds_one_place <= 4'd0;
            seconds_ten_place <= 3'd0;
        end
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_SECONDS && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd0 && rec_data_cnt <= 'd3)
                        begin
                            if(rx_ind == 2'b01)
                                seconds_one_place <= #U_DLY {1'b0,seconds_one_place[3:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                seconds_one_place <= #U_DLY {1'b1,seconds_one_place[3:1]};
                            else;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_SECONDS && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd5 && rec_data_cnt <= 'd7)
                        begin
                            if(rx_ind == 2'b01)
                                seconds_ten_place <= #U_DLY {1'b0,seconds_ten_place[2:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                seconds_ten_place <= #U_DLY {1'b1,seconds_ten_place[2:1]};
                            else;
                        end
                    else;
                end
            else;
        end
end
//8421 to bin
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        bin_sec <= 6'd0;
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_SECONDS && rx_vld == 1'b1 && rx_ind == 2'b11)
                begin
                    case(seconds_ten_place)
                        3'd0:bin_sec <= #U_DLY {2'd0,seconds_one_place};
                        3'd1:bin_sec <= #U_DLY {2'd0,seconds_one_place} + 6'd10;
                        3'd2:bin_sec <= #U_DLY {2'd0,seconds_one_place} + 6'd20;
                        3'd3:bin_sec <= #U_DLY {2'd0,seconds_one_place} + 6'd30;
                        3'd4:bin_sec <= #U_DLY {2'd0,seconds_one_place} + 6'd40;
                        3'd5:bin_sec <= #U_DLY {2'd0,seconds_one_place} + 6'd50;
                        3'd6:bin_sec <= #U_DLY {2'd0,seconds_one_place} + 6'd60;  //for leap second
                        default:bin_sec <= #U_DLY {2'd0,seconds_one_place};
                    endcase
                end
            else;
        end
end
//**********************************************************************//
//minutes
//**********************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            minutes_one_place <= 4'd0;
            minutes_ten_place <= 3'd0;
        end
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_MINUTES && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd0 && rec_data_cnt <= 'd3)
                        begin
                            if(rx_ind == 2'b01)
                                minutes_one_place <= #U_DLY {1'b0,minutes_one_place[3:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                minutes_one_place <= #U_DLY {1'b1,minutes_one_place[3:1]};
                            else;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_MINUTES && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd5 && rec_data_cnt <= 'd7)
                        begin
                            if(rx_ind == 2'b01)
                                minutes_ten_place <= #U_DLY {1'b0,minutes_ten_place[2:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                minutes_ten_place <= #U_DLY {1'b1,minutes_ten_place[2:1]};
                            else;
                        end
                    else;
                end
            else;
        end
end
//8421 to bin
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        bin_min <= 6'd0;
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_MINUTES && rx_vld == 1'b1 && rx_ind == 2'b11)
                begin
                    case(minutes_ten_place)
                        3'd0:bin_min <= #U_DLY {2'd0,minutes_one_place};
                        3'd1:bin_min <= #U_DLY {2'd0,minutes_one_place} + 6'd10;
                        3'd2:bin_min <= #U_DLY {2'd0,minutes_one_place} + 6'd20;
                        3'd3:bin_min <= #U_DLY {2'd0,minutes_one_place} + 6'd30;
                        3'd4:bin_min <= #U_DLY {2'd0,minutes_one_place} + 6'd40;
                        3'd5:bin_min <= #U_DLY {2'd0,minutes_one_place} + 6'd50;
                        default:bin_min <= #U_DLY {2'd0,minutes_one_place};
                    endcase
                end
            else;
        end
end
//**********************************************************************//
//hours
//**********************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            hours_one_place <= 4'd0;
            hours_ten_place <= 2'd0;
        end
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_HOURS && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd0 && rec_data_cnt <= 'd3)
                        begin
                            if(rx_ind == 2'b01)
                                hours_one_place <= #U_DLY {1'b0,hours_one_place[3:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                hours_one_place <= #U_DLY {1'b1,hours_one_place[3:1]};
                            else;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_HOURS && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd5 && rec_data_cnt <= 'd6)
                        begin
                            if(rx_ind == 2'b01)
                                hours_ten_place <= #U_DLY {1'b0,hours_ten_place[1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                hours_ten_place <= #U_DLY {1'b1,hours_ten_place[1]};
                            else;
                        end
                    else;
                end
            else;
        end
end           
//8421 to bin
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        bin_hour <= 5'd0;
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_HOURS && rx_vld == 1'b1 && rx_ind == 2'b11)
                begin
                    case(hours_ten_place)
                        2'd0:bin_hour <= #U_DLY {1'b0,hours_one_place};
                        2'd1:bin_hour <= #U_DLY {1'b0,hours_one_place} + 5'd10;
                        2'd2:bin_hour <= #U_DLY {1'b0,hours_one_place} + 5'd20;
                        default:bin_hour <= #U_DLY {1'b0,hours_one_place};
                    endcase
                end
            else;
        end
end
//**********************************************************************//
//days
//**********************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            days_one_place <= 4'd0;
            days_ten_place <= 4'd0;
            days_hun_place <= 2'd0;
        end
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_DAYS_LOW && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd0 && rec_data_cnt <= 'd3)
                        begin
                            if(rx_ind == 2'b01)
                                days_one_place <= #U_DLY {1'b0,days_one_place[3:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                days_one_place <= #U_DLY {1'b1,days_one_place[3:1]};
                            else;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_DAYS_LOW && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd5 && rec_data_cnt <= 'd8)
                        begin
                            if(rx_ind == 2'b01)
                                days_ten_place <= #U_DLY {1'b0,days_ten_place[3:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                days_ten_place <= #U_DLY {1'b1,days_ten_place[3:1]};
                            else;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_DAYS_HIGH && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd0 && rec_data_cnt <= 'd1)
                        begin
                            if(rx_ind == 2'b01)
                                days_hun_place <= #U_DLY {1'b0,days_hun_place[1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                days_hun_place <= #U_DLY {1'b1,days_hun_place[1]};
                            else;
                        end
                    else;
                end
            else;
        end
end 
//8421 to bin
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        bin_day <= 9'd0;
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_DAYS_HIGH && rx_vld == 1'b1 && rx_ind == 2'b11)
                begin
                    if(days_hun_place == 2'd0)
                        begin
                            case(days_ten_place)
                                4'd0:bin_day <= #U_DLY {5'd0,days_one_place};
                                4'd1:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd10;
                                4'd2:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd20;
                                4'd3:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd30;
                                4'd4:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd40;
                                4'd5:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd50;
                                4'd6:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd60;
                                4'd7:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd70;
                                4'd8:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd80;
                                4'd9:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd90;
                                default:bin_day <= #U_DLY {5'd0,days_one_place};
                            endcase
                        end
                    else if(days_hun_place == 2'd1)
                        begin
                            case(days_ten_place)
                                4'd0:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd100;
                                4'd1:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd10 + 9'd100;
                                4'd2:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd20 + 9'd100;
                                4'd3:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd30 + 9'd100;
                                4'd4:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd40 + 9'd100;
                                4'd5:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd50 + 9'd100;
                                4'd6:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd60 + 9'd100;
                                4'd7:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd70 + 9'd100;
                                4'd8:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd80 + 9'd100;
                                4'd9:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd90 + 9'd100;
                                default:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd100;
                            endcase
                        end
                    else if(days_hun_place == 2'd2)
                        begin
                            case(days_ten_place)
                                4'd0:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd200;
                                4'd1:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd10 + 9'd200;
                                4'd2:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd20 + 9'd200;
                                4'd3:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd30 + 9'd200;
                                4'd4:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd40 + 9'd200;
                                4'd5:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd50 + 9'd200;
                                4'd6:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd60 + 9'd200;
                                4'd7:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd70 + 9'd200;
                                4'd8:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd80 + 9'd200;
                                4'd9:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd90 + 9'd200;
                                default:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd200;
                            endcase
                        end
                    else if(days_hun_place == 2'd3)
                        begin
                            case(days_ten_place)
                                4'd0:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd300;
                                4'd1:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd10 + 9'd300;
                                4'd2:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd20 + 9'd300;
                                4'd3:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd30 + 9'd300;
                                4'd4:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd40 + 9'd300;
                                4'd5:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd50 + 9'd300;
                                4'd6:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd60 + 9'd300;
                                default:bin_day <= #U_DLY {5'd0,days_one_place} + 9'd300;
                            endcase
                        end
                    else;
                end
            else;
        end
end
//**********************************************************************//
//years
//**********************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            years_ten_ind <= 1'b0;
            years_one_place <= 4'd0;
            years_ten_place <= 4'd0;
        end
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_DAYS_HIGH && rx_vld == 1'b1)  //for GJB 2991A Btimecode
                begin
                    if(rec_data_cnt == 'd3)
                        begin
                            if(rx_ind == 2'b10)
                                years_ten_ind <= #U_DLY 1'b1;
                            else
                                years_ten_ind <= #U_DLY 1'b0;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_DAYS_HIGH && rx_vld == 1'b1 && years_ten_ind == 1'b0 && seconds_one_place[0] == 1'b0)  //for GJB 2991A Btimecode
                begin
                    if(rec_data_cnt >= 'd5 && rec_data_cnt <= 'd8)
                        begin
                            if(rx_ind == 2'b01)
                                years_one_place <= #U_DLY {1'b0,years_one_place[3:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                years_one_place <= #U_DLY {1'b1,years_one_place[3:1]};
                            else;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_DAYS_HIGH && rx_vld == 1'b1 && years_ten_ind == 1'b1 && seconds_one_place[0] == 1'b1) //for GJB 2991A Btimecode
                begin
                    if(rec_data_cnt >= 'd5 && rec_data_cnt <= 'd8)
                        begin
                            if(rx_ind == 2'b01)
                                years_ten_place <= #U_DLY {1'b0,years_ten_place[3:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                years_ten_place <= #U_DLY {1'b1,years_ten_place[3:1]};
                            else;
                        end
                    else;
                end
            else;
        end
end           
//8421 to bin
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        bin_year <= 12'h7E3;
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_YEARS && rx_vld == 1'b1 && rx_ind == 2'b11)
                begin
                    case(years_ten_place)
                        4'd0:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2000;
                        4'd1:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2010;
                        4'd2:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2020;
                        4'd3:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2030;
                        4'd4:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2040;
                        4'd5:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2050;
                        4'd6:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2060;
                        4'd7:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2070;
                        4'd8:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2080;
                        4'd9:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2090;
                        default:bin_year <= #U_DLY {8'd0,years_one_place} + 12'd2020;
                    endcase
                end
            else;
        end
end
//**********************************************************************//
//control functions
//**********************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            ctl_func0_word <= 9'd0;
            ctl_func1_word <= 9'd0;
            ctl_func_vld <= 1'b0;
        end
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_CTL_FUNC_LOW && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd0 && rec_data_cnt <= 'd8)
                        begin
                            if(rx_ind == 2'b01)
                                ctl_func0_word <= #U_DLY {1'b0,ctl_func0_word[8:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                ctl_func0_word <= #U_DLY {1'b1,ctl_func0_word[8:1]};
                            else;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_CTL_FUNC_HIGH && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd0 && rec_data_cnt <= 'd8)
                        begin
                            if(rx_ind == 2'b01)
                                ctl_func1_word <= #U_DLY {1'b0,ctl_func1_word[8:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                ctl_func1_word <= #U_DLY {1'b1,ctl_func1_word[8:1]};
                            else;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_CTL_FUNC_HIGH && rx_vld == 1'b1 && rx_ind == 2'b11) //receive P8
                ctl_func_vld <= #U_DLY 1'b1;
            else
                ctl_func_vld <= #U_DLY 1'b0;
        end
end 

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
           ctl_0func <= 9'd0;
           ctl_1func <= 9'd0;
        end
    else
        begin
            if(ctl_func_vld == 1'b1)
                begin
                    ctl_0func <= #U_DLY ctl_func0_word;
                    ctl_1func <= #U_DLY ctl_func1_word;
                end
            else;
        end
end
//**********************************************************************//
//straright binary seconds
//**********************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            str_bin_sec <= 17'd0;
            str_bin_vld <= 1'b0;
            str_sec <= 17'd0;
            str_sec_vld <= 1'b0;
        end
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_SBS_LOW && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd0 && rec_data_cnt <= 'd8)
                        begin
                            if(rx_ind == 2'b01)
                                str_bin_sec <= #U_DLY {1'b0,str_bin_sec[16:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                str_bin_sec <= #U_DLY {1'b1,str_bin_sec[16:1]};
                            else;
                        end
                    else;
                end
            else if(l1_cur_st == SYNC && l2_cur_st == L2_SBS_HIGH && rx_vld == 1'b1)
                begin
                    if(rec_data_cnt >= 'd0 && rec_data_cnt <= 'd7)
                        begin
                            if(rx_ind == 2'b01)
                                str_bin_sec <= #U_DLY {1'b0,str_bin_sec[16:1]};//01:"0"; 10:"1";
                            else if(rx_ind == 2'b10)
                                str_bin_sec <= #U_DLY {1'b1,str_bin_sec[16:1]};
                            else;
                        end
                    else;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_SBS_HIGH && rx_vld == 1'b1 && rx_ind == 2'b11) //receive P0
                str_bin_vld <= #U_DLY 1'b1;
            else
                str_bin_vld <= #U_DLY 1'b0;

            if(str_bin_vld == 1'b1)
                str_sec <= #U_DLY str_bin_sec;
            else;

            str_sec_vld <= #U_DLY str_bin_vld;
        end
end    
//**********************************************************************//
//bcode valid signal start at about 600ms in one second.start at the
//first bit of control functions
//**********************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            bcode_sec <= 6'd0;
            bcode_min <= 6'd0;
            bcode_hour <= 5'd0;
            bcode_day <= 9'd0;
            bcode_year <= 12'd0;
            bcode_time_vld <= 1'b0;
        end
    else
        begin
            if(l1_cur_st == SYNC && l2_cur_st == L2_YEARS && rx_vld == 1'b1 && rx_ind == 2'b11) //receive P6
                begin
                    if(sec_framehead_en == 1'b1)
                        bcode_sec <= #U_DLY bin_sec <= 58 ? bin_sec + 'd1 : bin_sec;                                      //for second frame-header,updata the next seconds time
                    else
                        bcode_sec <= #U_DLY bin_sec;
                end
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_YEARS && rx_vld == 1'b1 && rx_ind == 2'b11) //receive P6
                bcode_min <= #U_DLY bin_min;
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_YEARS && rx_vld == 1'b1 && rx_ind == 2'b11) //receive P6
                bcode_hour <= #U_DLY bin_hour;
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_YEARS && rx_vld == 1'b1 && rx_ind == 2'b11) //receive P6
                bcode_day <= #U_DLY bin_day;
            else;

            if(l1_cur_st == SYNC && l2_cur_st == L2_YEARS && rx_vld == 1'b1 && rx_ind == 2'b11) //receive P6
                bcode_year <= #U_DLY bin_year;
            else;

            if(sec_framehead_en == 1'b1)
                 begin
                     if({rx_sfh_3dly,rx_sfh_2dly} == 2'b01 && bin_sec != 'd59 && bin_sec != 'd60) //for simplly process,when current seconds is 59 senonds in one minute,not updata the real-timer,because
                          bcode_time_vld <= #U_DLY 1'b1;                                          //once add 1 seconds,the timer may add one year(60 are for leap second)
                     else
                          bcode_time_vld <= #U_DLY 1'b0;
                end
            else if(l1_cur_st == SYNC && l2_cur_st == L2_CTL_FUNC_LOW && rec_data_cnt == 'd0 && millsec10_pulse == 1'b1) //offset 40ns from the start of 600ms
                bcode_time_vld <= #U_DLY 1'b1;
            else
                bcode_time_vld <= #U_DLY 1'b0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            bcode_msec <= 'd0;
            bcode_microsec <= 'd0;
            bcode_nanosec <= 'd0;
        end
    else
        begin
            if(sec_framehead_en == 1'b1)
                begin
                    bcode_msec <= #U_DLY 'd0;
                    bcode_microsec <= #U_DLY 'd0;
                end
            else
                begin
                    bcode_msec <= #U_DLY 'd600;
                    bcode_microsec <= #U_DLY 'd0;
                end

            bcode_nanosec <= #U_DLY cfg_nanosec_offset;    //the deault value are 'd50 
         end
end
//frame header process
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rx_sfh_1dly <= 1'b0;
            rx_sfh_2dly <= 1'b0;
            rx_sfh_3dly <= 1'b0;
        end
    else
        begin
            rx_sfh_1dly <= #U_DLY rx_sfh;
            rx_sfh_2dly <= #U_DLY rx_sfh_1dly;
            rx_sfh_3dly <= #U_DLY rx_sfh_2dly;
        end
end

assign rx_sfh_dly = {rx_sfh_3dly,rx_sfh_2dly};
//for debug
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            l1_state <= HUNT;
            l2_state <= L2_IDLE;
        end
    else
        begin
            l1_state <= #U_DLY l1_cur_st;
            l2_state <= #U_DLY l2_cur_st;
        end
end
            
endmodule

