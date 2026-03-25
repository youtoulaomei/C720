// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2019/8/29 13:56:33
// File Name    : bcode_rx_phy.v
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
module bcode_rx_phy #(
parameter                           U_DLY = 1
)
(
input                               clk,                      //100M
input                               rst,
//io
input                               bcode_rx,                 //io
//
output  reg                         rx_vld,
output  reg     [1:0]               rx_ind,                   //11:crl_code; 01:"0"; 10:"1"; 00:err

output  reg                         millsec10_pulse,           //start of 10 millseconds,has 30ns offset because of the delay of bcode_rx
//for debug
input                               rx_en,
input           [19:0]              ctl_neg_cnt_low,
input           [19:0]              ctl_neg_cnt_high,
input           [19:0]              zero_neg_cnt_low,
input           [19:0]              zero_neg_cnt_high,
input           [19:0]              one_neg_cnt_low,
input           [19:0]              one_neg_cnt_high,
input           [19:0]              ms9_5_cnt,                  //9.5ms
input                               stat_restart,
output  reg     [19:0]              rx_pos_cnt_max,
output  reg     [19:0]              rx_pos_cnt_min,
output  reg     [19:0]              rx_pulse_cnt_max,
output  reg     [19:0]              rx_pulse_cnt_min,
output  reg                         rx_loss_signal,
output  reg                         bcode_chok
);
// Parameter Define 

// Register Define 
reg                                 judge_one;
reg                                 judge_zero;
reg                                 rx_vld_pre;
(* IOB="true" *)reg                 bcode_rx_1dly;
reg                                 bcode_rx_2dly;
reg                                 bcode_rx_3dly;
reg                                 judge_ctl;
reg     [19:0]                      rx_cnt;
reg     [23:0]                      rx_level_cnt;
// Wire Define  


always @(posedge clk)
begin
    bcode_rx_1dly <= #U_DLY bcode_rx;
    bcode_rx_2dly <= #U_DLY bcode_rx_1dly;
    bcode_rx_3dly <= #U_DLY bcode_rx_2dly;
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        rx_cnt <= 20'hf_ffff;
    else
        begin
            if({bcode_rx_3dly,bcode_rx_2dly} == 2'b01 || rx_en == 1'b0)
                rx_cnt <= #U_DLY 'd0;
            else if(rx_cnt != 20'hf_ffff)
                rx_cnt <= #U_DLY rx_cnt + 'd1;
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            judge_ctl <= 1'b0;
            judge_one <= 1'b0;
            judge_zero <= 1'b0;
        end
    else
        begin
            if({bcode_rx_3dly,bcode_rx_2dly} == 2'b10 && rx_cnt >= ctl_neg_cnt_low && rx_cnt <= ctl_neg_cnt_high)
                judge_ctl <= #U_DLY 1'b1;
            else if(rx_vld == 1'b1 || {bcode_rx_3dly,bcode_rx_2dly} == 2'b01)
                judge_ctl <= #U_DLY 1'b0;
            else;

            if({bcode_rx_3dly,bcode_rx_2dly} == 2'b10 && rx_cnt >= one_neg_cnt_low && rx_cnt <= one_neg_cnt_high)
                judge_one <= #U_DLY 1'b1;
            else if(rx_vld == 1'b1 || {bcode_rx_3dly,bcode_rx_2dly} == 2'b01)
                judge_one <= #U_DLY 1'b0;
            else;

            if({bcode_rx_3dly,bcode_rx_2dly} == 2'b10 && rx_cnt >= zero_neg_cnt_low && rx_cnt <= zero_neg_cnt_high)
                judge_zero <= #U_DLY 1'b1;
            else if(rx_vld == 1'b1 || {bcode_rx_3dly,bcode_rx_2dly} == 2'b01)
                judge_zero <= #U_DLY 1'b0;
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rx_vld_pre <= 1'b0;
            rx_vld <= 1'b0;
            rx_ind <= 2'b00;
        end
    else 
        begin
            if(rx_vld_pre == 1'b1)
                rx_vld_pre <= #U_DLY 1'b0;
            else if(rx_cnt == ms9_5_cnt)                         //9.5ms,send the received data
                rx_vld_pre <= #U_DLY 1'b1;
            else;

            rx_vld <= #U_DLY rx_vld_pre;
        
            if(rx_vld_pre == 1'b1)
                begin
                    case({judge_ctl,judge_one,judge_zero})       //11----->crl_code; 01------>"0"; 10------->"1"; 00------>err
                        3'b100:rx_ind <= #U_DLY 2'b11;
                        3'b010:rx_ind <= #U_DLY 2'b10;
                        3'b001:rx_ind <= #U_DLY 2'b01;
                        default:rx_ind <= #U_DLY 2'b00;
                    endcase
                end
            else;
        end
end
//for debug
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rx_pos_cnt_max <= 20'h0;
            rx_pos_cnt_min <= 20'hf_ffff;
            rx_pulse_cnt_max <= 20'd0;
            rx_pulse_cnt_min <= 20'hf_ffff;
            rx_level_cnt <= 24'h0;
            rx_loss_signal <= 1'b0;
            bcode_chok <= #U_DLY 1'b0;
        end
    else
        begin
            if(stat_restart == 1'b1)
                rx_pos_cnt_max <= #U_DLY 'd0;
            else if({bcode_rx_3dly,bcode_rx_2dly} == 2'b01)
                begin
                    if(rx_pos_cnt_max <= rx_cnt)
                        rx_pos_cnt_max <= #U_DLY rx_cnt;
                    else;
                end
            else;

            if(stat_restart == 1'b1)
                rx_pos_cnt_min <= #U_DLY 20'hf_ffff;
            else if({bcode_rx_3dly,bcode_rx_2dly} == 2'b01)
                begin
                    if(rx_pos_cnt_min >= rx_cnt)
                        rx_pos_cnt_min <= #U_DLY rx_cnt;
                    else;
                end
            else;

            if(stat_restart == 1'b1)
                rx_pulse_cnt_max <= #U_DLY 'd0;
            else if({bcode_rx_3dly,bcode_rx_2dly} == 2'b10)
                begin
                    if(rx_pulse_cnt_max <= rx_cnt)
                        rx_pulse_cnt_max <= #U_DLY rx_cnt;
                    else;
                end
            else;

            if(stat_restart == 1'b1)
                rx_pulse_cnt_min <= #U_DLY 20'hf_ffff;
            else if({bcode_rx_3dly,bcode_rx_2dly} == 2'b10)
                begin
                    if(rx_pulse_cnt_min >= rx_cnt)
                        rx_pulse_cnt_min <= #U_DLY rx_cnt;
                    else;
                end
            else;

            if(bcode_rx_3dly ^ bcode_rx_2dly == 1'b1)
                rx_level_cnt <= #U_DLY 'd0;
            else if(rx_level_cnt != 24'hff_ffff)
                rx_level_cnt <= #U_DLY rx_level_cnt + 'd1;
            else;

            if(rx_level_cnt == 24'hff_ffff)
                rx_loss_signal <= #U_DLY 1'b1;
            else
                rx_loss_signal <= #U_DLY 1'b0;
            
            if(rx_loss_signal==1'b1)
                bcode_chok <= #U_DLY 1'b0;
            else if(bcode_rx_3dly ^ bcode_rx_2dly == 1'b1)
                bcode_chok <= #U_DLY 1'b1;
        end
end
//start of 10 millseconds,has about 30 ns offset
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        millsec10_pulse <= 1'b0;
    else if({bcode_rx_3dly,bcode_rx_2dly} == 2'b01)
        millsec10_pulse <= #U_DLY 1'b1;
    else
        millsec10_pulse <= #U_DLY 1'b0;
end

endmodule

