// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2019/8/13 16:47:26
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Shenrong Co., Ltd.. 
// All Rights Reserved
//
// *********************************************************************************/
// Modification History:
// 1. initial
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
// (* syn_keep = "true", mark_debug = "true" *)
`timescale 1 ns / 1 ns
module multif_ctrl #
(
parameter                           U_DLY     = 1,
parameter  [63:0]                   HEADER_PATTERN=64'h7e7e7e7e_7e7e7e7e,
parameter                           IN_DATA_W = 64,
parameter                           INFO_W    = 8,
parameter                           TIME      = 100, //us
parameter                           FRAME_LEN = 8192, //2048,4096,8192,16384
parameter                           STP_W     = 32,
parameter                           MODE      = "START_STOP_TRIG" // 0-"START_STOP" 1-"TRIG" 2-"TIMEOUT" 3-"START_STOP_TRIG"

)
(
input                               clk_w,
input                               clk,
input                               rst,
input                               rtc_us,
input                               hin_en,
input       [15:0]                  hin_len,
input       [31:0]                  samp_rate,
input       [STP_W-1:0]             stamp,
input  [31:0]                       sfh_pulse_cnt,
input  [31:0]                       sfh_pulse_freq,

input                               chn_ctrl,
input       [2:0]                   chn_mode,
input       [18:0]                  trig_len,
// input       [9:0]                   tout_time,
input                               tout_en,

input                               indata_vld,
input                               indata_end,
input       [IN_DATA_W-1:0]         indata,
input       [INFO_W-1:0]            indata_info,

(* syn_keep = "true", mark_debug = "true" *)
output reg                          c_data_sof,
(* syn_keep = "true", mark_debug = "true" *)
output reg                          c_data_eof,
(* syn_keep = "true", mark_debug = "true" *)
output reg                          c_data_vld,
(* syn_keep = "true", mark_debug = "true" *)
output reg                          c_data_end,
(* syn_keep = "true", mark_debug = "true" *)
output reg  [15-1:0]                c_data_len,
(* syn_keep = "true", mark_debug = "true" *)
output reg  [IN_DATA_W-1:0]         c_data,
input                               c_pfull,
output reg                          infifo_overflow
);
// Parameter Define 
localparam                          IND_BYTE = IN_DATA_W/8;
localparam                          MOD_START_STOP = 3'd0;
localparam                          MOD_TRIG = 3'd1;

// Register Define 
reg     [2:0]                       rtc_us_r;
reg     [2:0]                       chn_ctrl_r;
reg                                 rtc_us_flg;
(* syn_keep = "true", mark_debug = "true" *)reg     [13:0]                      frame_cnt;
reg                                 chnl_ena;
reg                                 chnl_stop;
//reg     [19:0]                      tout_time_r1;
//reg     [19:0]                      tout_time_r2;
//(* max_fanout=20 *)reg     [19:0]   tout_time_reg;
//(* max_fanout=20 *)reg     [19:0]   tout_cnt;
reg                                 tou_flg;
reg                                 p_valid;
reg                                 p_valid_t;
reg                                 p_valid_tr;
reg                                 p_valid_r;
reg     [3:0]                       tout_en_r;
reg     [3:0]                       tout2_en_r;
reg                                 rtc_ms_flg;
reg     [9:0]                       rtc_ms_cnt;
reg                                 rtc_s_flg;
reg     [9:0]                       rtc_s_cnt;
reg     [15:0]                      s_kband;
reg     [10:0]                      s_byte_cnt;
reg                                 s_byte_k;
//reg     [STP_W-1:0]                 stamp_1r;
//(* syn_keep = "true", mark_debug = "true" *)reg     [STP_W-1:0]                 stamp_2r;
//(* syn_keep = "true", mark_debug = "true" *)
//reg     [STP_W-1:0]                 stamp_r;
reg                                 indata_vld_r;
reg     [IN_DATA_W-1:0]             indata_r;
reg                                 indata_end_r;
reg     [3:0]                       infifo_overflow_cnt;
reg                                 wr_en;
//reg     [IN_DATA_W+1-1:0]         din;
reg     [IN_DATA_W+1-1:0]           din;
reg                                 frame_end_flg;
reg     [2:0]                       hin_en_r;
reg                                 header_valid_t;
//(* syn_keep = "true", mark_debug = "true" *)
reg                                 header_valid;
reg     [15:0]                      hin_len_r2;
reg     [15:0]                      hin_len_r1;
reg     [31:0]                      sequence_num;
reg     [31:0]                      samp_rate_r1;
reg     [31:0]                      samp_rate_r2;
reg     [15:0]                      header_fcnt;
reg                                 header_flg;
//reg     [31:0]                      samp_rate_r;
//reg     [31:0]                      sfh_pulse_cnt_r;
//reg     [31:0]                      sfh_pulse_freq_r;
reg                                 c_data_eof_d;
reg                                 c_data_eof_p;
reg                                 eof_noread;
reg                                 eof_noread_r;
//reg     [31:0]                      sfh_pulse_cnt_1r;
//(* syn_keep = "true", mark_debug = "true" *)reg     [31:0]                      sfh_pulse_cnt_2r;
//reg     [31:0]                      sfh_pulse_freq_1r;
//(* syn_keep = "true", mark_debug = "true" *)reg     [31:0]                      sfh_pulse_freq_2r;
reg                                 last_frm;


reg    [2:0]                        chn_mode_r1;
reg    [2:0]                        chn_mode_r2;
reg    [2:0]                        chn_mode_reg;
reg    [18:0]                       trig_len_r1;
reg    [18:0]                       trig_len_r2;
reg    [18:0]                       trig_len_reg;
reg    [18:0]                       pack_cnt;
reg    [14:0]                       true_data_len;

// Wire Define 
wire                                empty;
wire                                rd_en;
//wire   [IN_DATA_W+161-1:0]          dout;
wire   [IN_DATA_W+1-1:0]          dout;
wire                                prog_full;
wire                                end_noread;
wire    [15:0]                      rtc_year;
wire    [7:0]                       rtc_month;
wire    [7:0]                       rtc_day;
wire    [7:0]                       rtc_hour;
wire    [7:0]                       rtc_min;
wire    [7:0]                       rtc_sec;
wire    [15:0]                      rtc_msec;
wire    [15:0]                      new_rtc_microsec;
wire    [15:0]                      new_rtc_nanosec;
//(* syn_keep = "true", mark_debug = "true" *)
//reg err_flg;
wire    [31:0]                      samp_rate_r;
wire    [STP_W-1:0]                 stamp_r;
wire    [31:0]                      sfh_pulse_cnt_r;
wire    [31:0]                      sfh_pulse_freq_r;

//always @ (posedge clk or posedge rst)begin
//    if(rst == 1'b1)     
//        err_flg <= #U_DLY 1'b0;      
//    else if(c_data_vld==1'b1 && header_valid==1'b1 && frame_cnt=='d0 )
//        begin
//            if(c_data!=HEADER_PATTERN[63:32])
//                err_flg <= #U_DLY 1'b1;
//            else      
//                err_flg <= #U_DLY 1'b0;
//        end   
//    else if(c_data_vld==1'b1 && header_valid==1'b1 && frame_cnt=='d1 )
//        begin
//            if(c_data!=HEADER_PATTERN[31:0] )
//                err_flg <= #U_DLY 1'b1;
//            else      
//                err_flg <= #U_DLY 1'b0;
//        end   
//    else
//        err_flg <= #U_DLY 1'b0;
//end

//always @ (posedge clk_w or posedge rst)begin
//    if(rst == 1'b1)     
//        begin
//            stamp_1r <= #U_DLY 'd0;
//            stamp_2r <= #U_DLY 'd0;
//            sfh_pulse_cnt_1r <= #U_DLY 'b0;
//            sfh_pulse_cnt_2r <= #U_DLY 'b0;
//            sfh_pulse_freq_1r <= #U_DLY 'b0;
//            sfh_pulse_freq_2r <= #U_DLY 'b0;
//        end       
//    else   
//        begin
//            stamp_1r <= #U_DLY stamp;
//            stamp_2r <= #U_DLY stamp_1r;
//            sfh_pulse_cnt_1r <= #U_DLY sfh_pulse_cnt;
//            sfh_pulse_cnt_2r <= #U_DLY sfh_pulse_cnt_1r;
//            sfh_pulse_freq_1r <= #U_DLY sfh_pulse_freq;
//            sfh_pulse_freq_2r <= #U_DLY sfh_pulse_freq_1r;
//        end 
//end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            rtc_us_r <= #U_DLY 'b0;
            chn_ctrl_r <= #U_DLY 'b0;
            rtc_us_flg <= #U_DLY 1'b0;
        end        
    else
        begin
            rtc_us_r <= #U_DLY {rtc_us_r[1:0],rtc_us};
            chn_ctrl_r <= #U_DLY {chn_ctrl_r[1:0],chn_ctrl};
            if((rtc_us_r[1]^rtc_us_r[2])==1'b1)
                rtc_us_flg <= #U_DLY 1'b1;
            else
                rtc_us_flg <= #U_DLY 1'b0;
        end    
end

always @ (posedge clk or posedge rst)begin
if(rst == 1'b1)         
    begin
        frame_cnt <= #U_DLY 'd0;
        c_data_end <= #U_DLY 1'b0;
        c_data_sof <= #U_DLY 1'b0;
        c_data_eof <= #U_DLY 1'b0;
        true_data_len <= #U_DLY 'd0;
        c_data_len <= #U_DLY 'd0;
        c_data_vld <= #U_DLY 1'b0;
    end       
else   
    begin
        if((indata_vld_r==1'b1 || p_valid==1'b1 || header_valid==1'b1) && (frame_cnt==(FRAME_LEN-IND_BYTE)) )
            frame_cnt <= #U_DLY 'd0;
        else if((chnl_ena==1'b1 && indata_vld_r==1'b1 && header_flg==1'b0) || (p_valid==1'b1) || (header_valid==1'b1))     
            frame_cnt <= #U_DLY frame_cnt + IND_BYTE;


        if((chnl_stop==1'b1) && (indata_vld_r==1'b1||p_valid==1'b1))
            c_data_end <= #U_DLY 1'b1;
        else if(chnl_stop==1'b0 && p_valid==1'b1)
            c_data_end <= #U_DLY 1'b1; 
        else if(indata_vld_r==1'b1 && indata_end_r==1'b1 && chnl_ena==1'b1)
            c_data_end <= #U_DLY 1'b1; 
        else if(indata_vld_r==1'b1 && chnl_ena==1'b1 && last_frm==1'b1)
            c_data_end <= #U_DLY 1'b1; 
        else if( (chn_mode_reg==MOD_TRIG) && (frame_cnt==(FRAME_LEN-IND_BYTE) ))
                begin 
                    if((indata_vld_r==1'b1 && pack_cnt==(trig_len_reg-1)) || (p_valid==1'b1) ) 
                        c_data_end <= #U_DLY 1'b1;
                end  
        else
            c_data_end <= #U_DLY 1'b0; 
        

        if( ((indata_vld_r==1'b1 && chnl_ena==1'b1)||(p_valid==1'b1) ||  (header_valid==1'b1))  && frame_cnt=='d0 )
            c_data_sof <= #U_DLY 1'b1;
        else
            c_data_sof <= #U_DLY 1'b0;

        if( ((indata_vld_r==1'b1 && chnl_ena==1'b1)|| (p_valid==1'b1) || (header_valid==1'b1) ) && (frame_cnt==(FRAME_LEN-IND_BYTE)))
            c_data_eof <= #U_DLY 1'b1;
        else
            c_data_eof <= #U_DLY 1'b0;


        if((indata_vld_r==1'b1 || p_valid==1'b1) && (frame_cnt==(FRAME_LEN-IND_BYTE)) )
            true_data_len <= #U_DLY 'd0;
        else if(indata_vld_r==1'b1 && chnl_ena==1'b1)
            true_data_len <= #U_DLY true_data_len + IND_BYTE;
        
        if((indata_vld_r==1'b1) && (true_data_len==(FRAME_LEN-IND_BYTE)) && chnl_ena==1'b1 )
            c_data_len <= #U_DLY {true_data_len+IND_BYTE};
        else if((indata_vld_r==1'b1 || p_valid==1'b1) && (frame_cnt==(FRAME_LEN-IND_BYTE)) )
            c_data_len <= #U_DLY {true_data_len};
        else if((header_valid==1'b1) &&  (frame_cnt==(FRAME_LEN-IND_BYTE)) )
            c_data_len <= #U_DLY FRAME_LEN;


        if((chnl_ena==1'b1 && indata_vld_r==1'b1) || (p_valid==1'b1) || (header_valid==1'b1)) 
            c_data_vld <= #U_DLY 1'b1;
        else
            c_data_vld <= #U_DLY 1'b0;
    end 
end


generate

if(IN_DATA_W==32)
begin
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)         
        c_data <= #U_DLY 'b0;
    else
        begin
            if(header_valid==1'b1)
                case(frame_cnt)
                    0*IND_BYTE: c_data <= #U_DLY HEADER_PATTERN[63:32];
                    1*IND_BYTE: c_data <= #U_DLY HEADER_PATTERN[31:0];
                    2*IND_BYTE: c_data <= #U_DLY sequence_num;
                    3*IND_BYTE: c_data <= #U_DLY samp_rate_r;
                    4*IND_BYTE: c_data <= #U_DLY sfh_pulse_freq_r;
                    5*IND_BYTE: c_data <= #U_DLY sfh_pulse_cnt_r;
                    6*IND_BYTE: c_data <= #U_DLY {rtc_day[7:0],rtc_month[7:0],rtc_year[15:0]};
                    7*IND_BYTE: c_data <= #U_DLY {8'b0,rtc_sec[7:0],rtc_min[7:0],rtc_hour[7:0]};
                    8*IND_BYTE: c_data <= #U_DLY {new_rtc_microsec[15:0],rtc_msec[15:0]};
                    9*IND_BYTE: c_data <= #U_DLY {16'h0,new_rtc_nanosec[15:0]};
                    10*IND_BYTE: c_data <= #U_DLY {{(3){8'h8B}},indata_info};
                    default: c_data <= #U_DLY {(IND_BYTE){8'h8B}};
                endcase
            else if(indata_vld_r==1'b1 && p_valid==1'b0)
                c_data <= #U_DLY indata_r;
            else if(p_valid==1'b1) 
                c_data <= #U_DLY {(IND_BYTE){8'h5A}};
        end
end
end

else if (IN_DATA_W==64)
begin
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)         
        c_data <= #U_DLY 'b0;
    else
        begin
            if(header_valid==1'b1)
                case(frame_cnt)
                    0*IND_BYTE: c_data <= #U_DLY HEADER_PATTERN[63:0];
                    1*IND_BYTE: c_data <= #U_DLY {samp_rate_r,sequence_num};
                    2*IND_BYTE: c_data <= #U_DLY {sfh_pulse_cnt_r,sfh_pulse_freq_r};
                    3*IND_BYTE: c_data <= #U_DLY {8'b0,rtc_sec[7:0],rtc_min[7:0],rtc_hour[7:0],rtc_day[7:0],rtc_month[7:0],rtc_year[15:0]};
                    4*IND_BYTE: c_data <= #U_DLY {16'h0,new_rtc_nanosec[15:0],new_rtc_microsec[15:0],rtc_msec[15:0]};
                    5*IND_BYTE: c_data <= #U_DLY {{(7){8'h8B}},indata_info};
                    default: c_data <= #U_DLY {(IND_BYTE){8'h8B}};
                endcase
            else if(indata_vld_r==1'b1 && p_valid==1'b0)
                c_data <= #U_DLY indata_r;
            else if(p_valid==1'b1) 
                c_data <= #U_DLY {(IND_BYTE){8'h5A}};
        end
end
end

else if (IN_DATA_W==128)
begin
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)         
        c_data <= #U_DLY 'b0;
    else
        begin
            if(header_valid==1'b1)
                case(frame_cnt)
                    0*IND_BYTE: c_data <= #U_DLY {{samp_rate_r,sequence_num},
                                                HEADER_PATTERN[63:0]};
                    1*IND_BYTE: c_data <= #U_DLY {{8'b0,rtc_sec[7:0],rtc_min[7:0],rtc_hour[7:0],rtc_day[7:0],rtc_month[7:0],rtc_year[15:0]},
                                                {sfh_pulse_cnt_r,sfh_pulse_freq_r}};
                    2*IND_BYTE: c_data <= #U_DLY {{{(7){8'h8B}},indata_info},
                                                {16'h0,new_rtc_nanosec[15:0],new_rtc_microsec[15:0],rtc_msec[15:0]}};
                    default: c_data <= #U_DLY {(IND_BYTE){8'h8B}};
                endcase
            else if(indata_vld_r==1'b1 && p_valid==1'b0)
                c_data <= #U_DLY indata_r;
            else if(p_valid==1'b1) 
                c_data <= #U_DLY {(IND_BYTE){8'h5A}};
        end
end
end
else if (IN_DATA_W==256)
begin
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)         
        c_data <= #U_DLY 'b0;
    else
        begin
            if(header_valid==1'b1)
                case(frame_cnt)
                    0*IND_BYTE: c_data <= #U_DLY {{8'b0,rtc_sec[7:0],rtc_min[7:0],rtc_hour[7:0],rtc_day[7:0],rtc_month[7:0],rtc_year[15:0]},
                                                {sfh_pulse_cnt_r,sfh_pulse_freq_r},
                                                {samp_rate_r,sequence_num},
                                                HEADER_PATTERN[63:0]};
                    1*IND_BYTE: c_data <= #U_DLY {{(8){8'h8B}},
                                                {(8){8'h8B}},
                                                {{(7){8'h8B}},indata_info},
                                                {16'h0,new_rtc_nanosec[15:0],new_rtc_microsec[15:0],rtc_msec[15:0]}};
                    default: c_data <= #U_DLY {(IND_BYTE){8'h8B}};
                endcase
            else if(indata_vld_r==1'b1 && p_valid==1'b0)
                c_data <= #U_DLY indata_r;
            else if(p_valid==1'b1) 
                c_data <= #U_DLY {(IND_BYTE){8'h5A}};
        end
end
end
else //512b
begin
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)         
        c_data <= #U_DLY 'b0;
    else
        begin
            if(header_valid==1'b1)
                case(frame_cnt)
                    0*IND_BYTE: c_data <= #U_DLY {{(8){8'h8B}},
                                                {(8){8'h8B}},
                                                {{(7){8'h8B}},indata_info},
                                                {16'h0,new_rtc_nanosec[15:0],new_rtc_microsec[15:0],rtc_msec[15:0]},
                                                {8'b0,rtc_sec[7:0],rtc_min[7:0],rtc_hour[7:0],rtc_day[7:0],rtc_month[7:0],rtc_year[15:0]},
                                                {sfh_pulse_cnt_r,sfh_pulse_freq_r},
                                                {samp_rate_r,sequence_num},
                                                HEADER_PATTERN[63:0]};
                    default: c_data <= #U_DLY {(IND_BYTE){8'h8B}};
                endcase
            else if(indata_vld_r==1'b1 && p_valid==1'b0)
                c_data <= #U_DLY indata_r;
            else if(p_valid==1'b1) 
                c_data <= #U_DLY {(IND_BYTE){8'h5A}};
        end
end
end

endgenerate

assign rtc_year[15:0]         = {8'h07,stamp_r[63:56]};
assign rtc_month[7:0]         = {4'b0,stamp_r[55:52]};
assign rtc_day[7:0]           = {3'b0,stamp_r[51:47]};
assign rtc_hour[7:0]          = {3'b0,stamp_r[46:42]};
assign rtc_min[7:0]           = {2'b0,stamp_r[41:36]};
assign rtc_sec[7:0]           = {2'b0,stamp_r[35:30]};
assign rtc_msec[15:0]         = {6'b0,stamp_r[29:20]};
assign new_rtc_microsec[15:0] = {6'b0,stamp_r[19:10]};
assign new_rtc_nanosec[15:0]  = {6'b0,stamp_r[9:0]};


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            hin_en_r <= #U_DLY 'b0;
            header_valid_t <= #U_DLY 1'b0;
            header_valid <= #U_DLY 1'b0;
            hin_len_r1 <= #U_DLY 'd0;
            hin_len_r2 <= #U_DLY 'd0;
            sequence_num <= #U_DLY 'd0;
            //samp_rate_r <= #U_DLY 'd0;
            //sfh_pulse_cnt_r <= #U_DLY 'b0;
            //stamp_r <= #U_DLY 'b0;
            //sfh_pulse_freq_r <= #U_DLY 'b0;
            header_flg <= #U_DLY 1'b0;
            header_fcnt <= #U_DLY 'd0;
            c_data_eof_d <= #U_DLY 1'b0;
            c_data_eof_p <= #U_DLY 1'b0;
            eof_noread <= #U_DLY 1'b0;
            eof_noread_r <= #U_DLY 1'b0;
            last_frm <= #U_DLY 1'b0;
        end       
    else
        begin
            hin_len_r1 <= #U_DLY hin_len;
            hin_len_r2 <= #U_DLY hin_len_r1;
            
            //if(empty==1'b0)
            //    samp_rate_r <= #U_DLY dout[(IN_DATA_W+65)+:32];

            //if(empty==1'b0)
            //    stamp_r <= #U_DLY dout[(IN_DATA_W+97)+:64];
            
            //if(empty==1'b0)
            //    sfh_pulse_cnt_r <= #U_DLY dout[(IN_DATA_W+1)+:32];

            //if(empty==1'b0)
            //    sfh_pulse_freq_r <= #U_DLY dout[(IN_DATA_W+33)+:32]; 

            hin_en_r <= #U_DLY {hin_en_r[1:0],hin_en};
            
            if(header_valid==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE)
                header_valid_t <= #U_DLY 1'b0;
            else if(chnl_ena==1'b1 && hin_en_r[2]==1'b1 && header_flg==1'b1 && empty==1'b0 && c_data_vld==1'b0)
                header_valid_t <= #U_DLY 1'b1;

            if(header_valid==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE)
                header_valid <= #U_DLY 'd0;
            else if(header_valid_t==1'b1)
                begin
                    if(c_pfull==1'b0)
                        header_valid <= #U_DLY 1'b1;
                    else
                        header_valid <= #U_DLY 1'b0;
                end
            else
                header_valid <= #U_DLY 1'b0;
            
            if(hin_en_r[2]==1'b0)
                header_flg <= #U_DLY 1'b0;
            else if(c_data_eof==1'b1 && header_flg==1'b1)
                header_flg <= #U_DLY 1'b0;
            else if(header_fcnt=='d0 && hin_en_r[2]==1'b1)
                header_flg <= #U_DLY 1'b1;
            
            if((c_data_eof_p==1'b1) || (c_data_eof_d==1'b1 && last_frm==1'b1))
                header_fcnt <= #U_DLY 'd0;
            else if(c_data_eof==1'b1)
                header_fcnt <= #U_DLY  header_fcnt + 'd1;
            
            if(indata_vld_r==1'b1 && chnl_ena==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE)
                c_data_eof_d <= #U_DLY 1'b1;
            else
                c_data_eof_d <= #U_DLY 1'b0;

            if( p_valid==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE)
                c_data_eof_p <= #U_DLY 1'b1;
            else
                c_data_eof_p <= #U_DLY 1'b0;

            
            if(eof_noread_r==1'b1)
                eof_noread <= #U_DLY 1'b0;
            else if( ((indata_vld_r==1'b1 && last_frm==1'b1)|| p_valid==1'b1) && (frame_cnt==FRAME_LEN-IND_BYTE)  )
                eof_noread <= #U_DLY 1'b1;

            eof_noread_r <= #U_DLY eof_noread;

            if(header_valid==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE )
                sequence_num <= #U_DLY sequence_num +'d1;

            if(header_fcnt==hin_len_r2 && hin_en_r[2]==1'b1)
                last_frm <= #U_DLY 1'b1;
            else
                last_frm <= #U_DLY 1'b0;

        end    
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            //tout_cnt <= #U_DLY 'b0;      
            tou_flg <= #U_DLY 1'b0;
            //tout_time_r1 <= #U_DLY 'd0;
            //tout_time_r2 <= #U_DLY 'd0;
            //tout_time_reg <= #U_DLY 'd0;
            //tout_en_r <= #U_DLY 'b0;
            tout2_en_r <= #U_DLY 'b0;
            rtc_ms_flg <= #U_DLY 1'b0;
            rtc_ms_cnt <= #U_DLY 'd0;
            rtc_s_flg <= #U_DLY 1'b0;
            rtc_s_cnt <= #U_DLY 'd0;
            s_kband <= #U_DLY 'd0;
            s_byte_cnt <= #U_DLY 'd0;   
            s_byte_k <= #U_DLY 1'b0;
        end       
    else    
        begin
            //tout_time_r1 <= #U_DLY tout_time;
            //tout_time_r2 <= #U_DLY tout_time_r1;
            //tout_en_r <= #U_DLY {tout_en_r[2:0],tout_en[0]};
            tout2_en_r <= #U_DLY {tout2_en_r[2:0],tout_en};

            //if(tout_time_r2<='d20)
            //    tout_time_reg <= #U_DLY 'd20;
            //else
            //    tout_time_reg <= #U_DLY tout_time_r2;

            //if(chnl_ena==1'b1 && tout_en_r[3]==1'b1)
            //    begin
            //        if(indata_vld_r==1'b1)
            //            tout_cnt <= #U_DLY 'd0;
            //        `ifdef MUF_SIM
            //        else if(p_valid==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE)
            //            tout_cnt <= #U_DLY 'd0;
            //        else if(tout_cnt>='d1000)
            //            tout_cnt <= #U_DLY tout_cnt;
            //        else if(indata_vld_r==1'b0 )
            //            tout_cnt <= #U_DLY tout_cnt+'d1;
            //        `else
            //          else if(p_valid==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE)
            //            tout_cnt <= #U_DLY 'd0;
            //        else if(rtc_us_flg==1'b1 && tout_cnt>=tout_time_reg-1)
            //            tout_cnt <= #U_DLY tout_cnt;
            //        else if(rtc_us_flg==1'b1 && indata_vld_r==1'b0 )
            //            tout_cnt <= #U_DLY tout_cnt+'d1;
            //       `endif
            //    end
            //else
            //    tout_cnt <= #U_DLY 'd0;



            //`ifdef MUF_SIM
            //if(p_valid==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE)
            //    tou_flg <= #U_DLY 1'b0;
            //else if((chnl_ena==1'b1 && tout_cnt>='d1000 && tout_en_r[3]==1'b1)
            //     || (chnl_ena==1'b1 && tout2_en_r[3]==1'b1 && rtc_ms_flg==1'b1 && s_kband<'d2048))
            //    tou_flg <= #U_DLY 1'b1;
            //`else
            //if(p_valid==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE)
            //    tou_flg <= #U_DLY 1'b0;
            //else if((chnl_ena==1'b1 && tout_cnt>=tout_time_reg-1 && tout_en_r[3]==1'b1)
            //    || (chnl_ena==1'b1 && tout2_en_r[3]==1'b1 && rtc_s_flg==1'b1 && s_kband<'d2048))
            //    tou_flg <= #U_DLY 1'b1;
            //`endif

            if(p_valid==1'b1 && frame_cnt==FRAME_LEN-IND_BYTE)
                tou_flg <= #U_DLY 1'b0;
            else if(chnl_ena==1'b1 && tout2_en_r[3]==1'b1 && rtc_s_flg==1'b1 && s_kband<'d2048)
                tou_flg <= #U_DLY 1'b1;

            
            if(chnl_ena==1'b1 && tout2_en_r[3]==1'b1)
                begin
                    if(rtc_us_flg==1'b1 && rtc_ms_cnt=='d999)
                        rtc_ms_flg <= #U_DLY 1'b1;
                    else
                        rtc_ms_flg <= #U_DLY 1'b0;
                    if(rtc_us_flg==1'b1 && rtc_ms_cnt=='d999)
                        rtc_ms_cnt <= #U_DLY 'd0;
                    else if(rtc_us_flg==1'b1)
                        rtc_ms_cnt <= #U_DLY rtc_ms_cnt + 'd1;

                    if(rtc_ms_flg==1'b1 && rtc_s_cnt=='d999)
                        rtc_s_flg <= #U_DLY 1'b1;
                    else
                        rtc_s_flg <= #U_DLY 1'b0;

                    if(rtc_ms_flg==1'b1 && rtc_s_cnt=='d999)
                        rtc_s_cnt <= #U_DLY 'd0;
                    else if(rtc_ms_flg==1'b1)
                        rtc_s_cnt <= #U_DLY rtc_s_cnt + 'd1;
                end
            else
                begin
                    rtc_ms_flg <= #U_DLY 1'b0;
                    rtc_ms_cnt <= #U_DLY 'd0;
                    rtc_s_flg <= #U_DLY 1'b0;
                    rtc_s_cnt <= #U_DLY 'd0;
                end



            if(chnl_ena==1'b1 && tout2_en_r[3]==1'b1)
                begin
                    if(rtc_s_flg==1'b1)
                        s_kband <= #U_DLY 'd0;
                    else if(s_byte_k==1'b1)
                        s_kband <= #U_DLY s_kband + 'd1;
                    
                    if(rtc_s_flg==1'b1)
                        s_byte_cnt <= #U_DLY 'd0;   
                    else if(indata_vld_r==1'b1 && s_byte_cnt>='d1024-IND_BYTE)
                        s_byte_cnt <= #U_DLY 'd0;   
                    else if(indata_vld_r==1'b1)
                        s_byte_cnt <= #U_DLY s_byte_cnt + IND_BYTE; 
                    
                    if(indata_vld_r==1'b1 && s_byte_cnt>='d1024-IND_BYTE)
                        s_byte_k <= #U_DLY 1'b1;
                    else
                        s_byte_k <= #U_DLY 1'b0;
                end
            else
                begin
                    s_kband <= #U_DLY 'd0;
                    s_byte_cnt <= #U_DLY 'd0;   
                    s_byte_k <= #U_DLY 1'b0;
                end
        end

end



always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)  
        begin
            chnl_ena <= #U_DLY 1'b0;
            chnl_stop <= #U_DLY 1'b0;
            chn_mode_r1 <= #U_DLY 'b0;
            chn_mode_r2 <= #U_DLY 'b0;
            chn_mode_reg <= #U_DLY 'b0;
            trig_len_r1 <= #U_DLY 'b0;
            trig_len_r2 <= #U_DLY 'b0;
            trig_len_reg <= #U_DLY 'b0;
            pack_cnt <= #U_DLY 'd0;
            p_valid <= #U_DLY 1'b0;
            p_valid_r <= #U_DLY 1'b0;
            p_valid_t <= #U_DLY 1'b0;
            p_valid_tr <= #U_DLY 1'b0;
            frame_end_flg <= #U_DLY 1'b0; 
        end       
    else   
        begin
            trig_len_r1 <= #U_DLY trig_len;
            trig_len_r2 <= #U_DLY trig_len_r1;
            
            if(chn_ctrl_r[1]==1'b1 && chn_ctrl_r[2]==1'b0)
                begin
                    if(trig_len_r2>='d1)
                        trig_len_reg <= #U_DLY trig_len_r2;
                    else
                        trig_len_reg <= #U_DLY 'd4;
                end

            chn_mode_r1 <= #U_DLY chn_mode;
            chn_mode_r2 <= #U_DLY chn_mode_r1;

            if(chn_ctrl_r[1]==1'b1 && chn_ctrl_r[2]==1'b0)
                chn_mode_reg <= #U_DLY chn_mode_r2;


            if((chnl_stop==1'b1) && (indata_vld_r==1'b1||p_valid==1'b1) && (frame_cnt==(FRAME_LEN-IND_BYTE)))
                chnl_ena <= #U_DLY 1'b0;
            //else if((chnl_ena==1'b1) && (pack_cnt==(trig_len_reg-1)) && (chn_mode_reg==MOD_TRIG) &&  (indata_vld_r==1'b1||p_valid==1'b1) && (frame_cnt==(FRAME_LEN-IND_BYTE)))    
            else if(frame_end_flg==1'b1)
                chnl_ena <= #U_DLY 1'b0;
            //else if(chn_ctrl_r[1]==1'b1 && chn_ctrl_r[2]==1'b0)
            else if((chn_ctrl_r[2]==1'b1 && chn_mode_reg==MOD_START_STOP)   
                    || (chn_ctrl_r[1]==1'b1 && chn_ctrl_r[2]==1'b0 && chn_mode_r2==MOD_TRIG))
                chnl_ena <= #U_DLY 1'b1;

            if((chnl_stop==1'b1) && (indata_vld_r==1'b1 || p_valid==1'b1) && (frame_cnt==(FRAME_LEN-IND_BYTE)))
                chnl_stop <= #U_DLY 1'b0;
            else if( ( tou_flg ==1'b1 && chn_mode_reg==MOD_TRIG)
                 //||  ((chnl_ena==1'b1) && (pack_cnt==(trig_len_reg-1)) && (chn_mode_reg==MOD_TRIG))
                    ||  ( (chn_ctrl_r[1]==1'b0 && chn_ctrl_r[2]==1'b1) && (chnl_ena==1'b1) && (chn_mode_reg==MOD_START_STOP)) )
                chnl_stop <= #U_DLY 1'b1;

            //if(frame_cnt==FRAME_LEN-IND_BYTE && chnl_stop==1'b1)
            if((chnl_ena==1'b1)  && (chn_mode_reg==MOD_TRIG) && (frame_cnt==(FRAME_LEN-IND_BYTE))  )
                begin 
                    if((indata_vld_r==1'b1 && pack_cnt==(trig_len_reg-1)) || (p_valid==1'b1) )    
                        frame_end_flg <= #U_DLY 1'b1;
                    else
                        frame_end_flg <= #U_DLY 1'b0;
                end
            else
                frame_end_flg <= #U_DLY 1'b0;

            //if(frame_cnt==FRAME_LEN-IND_BYTE && chnl_stop==1'b1)
            if(frame_end_flg==1'b1)
                pack_cnt <= #U_DLY 'd0;
            else if(chnl_ena==1'b1 && c_data_eof_d==1'b1 && chn_mode_reg==MOD_TRIG && p_valid_r==1'b0)
                pack_cnt <= #U_DLY pack_cnt + 'd1;

            if((p_valid==1'b1) && frame_cnt==(FRAME_LEN-IND_BYTE)) 
                p_valid_t <= #U_DLY 1'b0;
            else if(chnl_ena==1'b1 && ((tou_flg==1'b1) || (indata_vld_r==1'b1 && indata_end_r==1'b1) || (chnl_stop==1'b1)))
                p_valid_t <= #U_DLY 1'b1;

            if(c_data_eof_p==1'b1) 
                p_valid_tr <= #U_DLY 1'b0;
            else if(chnl_ena==1'b1 && ((tou_flg==1'b1) || (indata_vld_r==1'b1 && indata_end_r==1'b1) || (chnl_stop==1'b1)))
                p_valid_tr <= #U_DLY 1'b1;
            
            if((p_valid==1'b1) && frame_cnt==(FRAME_LEN-IND_BYTE)) 
                p_valid <= #U_DLY 1'b0;
            else if(p_valid_t==1'b1)
                begin 
                    if(c_pfull==1'b0)
                        p_valid <= #U_DLY 1'b1;
                    else
                        p_valid <= #U_DLY 1'b0;
                end
            else
                p_valid <= #U_DLY 1'b0;

            p_valid_r <= #U_DLY p_valid;
        end 
end


asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (IN_DATA_W+1                ),
    .DATA_DEEPTH                (1024                       ),
    .ADDR_WIDTH                 (10                         ),
    .RAM_STYLE                  ("BRAM"                     )
)u_in_fifo
(
    .wr_clk                     (clk_w                      ),
    .wr_rst_n                   (~rst                       ),
    .rd_clk                     (clk                        ),
    .rd_rst_n                   (~rst                       ),
    .din                        (din                        ),
    .wr_en                      (wr_en                      ),
    .rd_en                      (rd_en                      ),
    .dout                       (dout                       ),
    .full                       (full                       ),
    .prog_full                  (prog_full                  ),
    .empty                      (empty                      ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (10'd1000                   ),
    .prog_empty_thresh          (10'd3                      ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )
);

//assign rd_en = (chnl_ena==1'b0 && empty==1'b0 && c_data_vld==1'b0) ? 1'b1 :
assign rd_en = (chnl_ena==1'b0 && empty==1'b0 ) ? 1'b1 :
                (empty==1'b0) && (indata_end_r==1'b0) && (p_valid_tr==1'b0) && (header_flg==1'b0) && (eof_noread==1'b0) && (end_noread==1'b0) && (c_pfull==1'b0)? 1'b1 :1'b0;

assign end_noread = (indata_vld_r==1'b1 && true_data_len==FRAME_LEN-IND_BYTE && last_frm==1'b1) ? 1'b1 : 1'b0;

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            indata_vld_r <= #U_DLY 1'b0;
            indata_r <= #U_DLY 'b0;
            indata_end_r <= #U_DLY 1'b0;
        end       
    else    
        begin
            if(rd_en==1'b1 && chnl_ena==1'b1)
            //if(rd_en==1'b1)
                indata_vld_r <= #U_DLY 1'b1;
            else
                indata_vld_r <= #U_DLY 1'b0;

            if(rd_en==1'b1)
                indata_r <= #U_DLY dout[IN_DATA_W-1:0];
                
            if(rd_en==1'b1)
                indata_end_r <= #U_DLY dout[IN_DATA_W];  
            else            
                indata_end_r <= #U_DLY 1'b0;  
        end
end

always @ (posedge clk_w or posedge rst)begin
    if(rst == 1'b1)     
        begin
            infifo_overflow <= #U_DLY 1'b0;
            infifo_overflow_cnt <= #U_DLY 1'b0;
            wr_en <= #U_DLY 1'b0;
            din <= #U_DLY 'b0;
        end       
    else    
        begin
            if(infifo_overflow==1'b1 && infifo_overflow_cnt>='d15)
                infifo_overflow <= #U_DLY 1'b0;
            else if(indata_vld==1'b1 && prog_full==1'b1)
                infifo_overflow <= #U_DLY 1'b1;

            if(infifo_overflow==1'b1 && infifo_overflow_cnt>='d15)
                infifo_overflow_cnt <= #U_DLY 'd0;
            else if(infifo_overflow==1'b1)
                infifo_overflow_cnt <= #U_DLY infifo_overflow_cnt + 'd1;

            if(indata_vld==1'b1 && prog_full==1'b0)
                wr_en <= #U_DLY 1'b1;
            else
                wr_en <= #U_DLY 1'b0;

            //din <= #U_DLY {stamp_2r,samp_rate,sfh_pulse_freq_2r,sfh_pulse_cnt_2r,indata_end,indata};
            din <= #U_DLY {indata_end,indata};
        end
end

assign samp_rate_r = samp_rate;
assign stamp_r = stamp;
assign sfh_pulse_cnt_r = sfh_pulse_cnt;
assign sfh_pulse_freq_r = sfh_pulse_freq;



endmodule
