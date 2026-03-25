// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2019/3/8 13:30:35
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
`timescale 1 ns / 1 ns
module multif_top #(
parameter                           U_DLY      = 1,
parameter                           USER_NUM   = 6,
parameter                           IN_DATA_W  = 64,
parameter                           INFO_W     = 8,
parameter                           FRAME_LEN  = 2048,
parameter                           STP_W      = 64
)
(
input                               clk_adc_w,
input                               clk_h,
input                               clk_r,
input                               hard_rst,
input                               rst,
(* max_fanout=10 *)input                               rtc_us_flg,
(* max_fanout=10 *)input                               rtc_s_flg,
(* max_fanout=10 *)input  [STP_W-1:0]         stamp,
input  [32-1:0]                               samp_rate,
input  [31:0]                       sfh_pulse_cnt,
input  [31:0]                       sfh_pulse_freq,



input                               cpu_cs,
input                               cpu_wr,
input                               cpu_rd,
input  [7:0]                        cpu_addr,
input  [31:0]                       cpu_wr_data,
output [31:0]                       cpu_rd_data,


input  [USER_NUM-1:0]               indata_vld,
input  [USER_NUM-1:0]               indata_end,
input  [USER_NUM*IN_DATA_W-1:0]     indata,
input  [USER_NUM*INFO_W-1:0]        indata_info,

input                               out_data_rdy,
output                              out_data_vld,
output                              out_data_sof,
output                              out_data_eof,
output  [511:0]                     out_data,
output  [INFO_W-1:0]                out_data_info,
output  [15-1:0]                    out_data_len,
output                              out_data_end
);
// Parameter Define 
localparam                          NUM_1S = 3;
localparam                          NUM_2S = 3;

// Register Define 
reg     [STP_W-1:0]                 stamp_1r;
reg     [STP_W-1:0]                 stamp_2r;
reg     [31:0]                      sfh_pulse_cnt_1r;
//(* syn_keep = "true", mark_debug = "true" *)
reg     [31:0]                      sfh_pulse_cnt_2r;
reg     [31:0]                      sfh_pulse_freq_1r;
reg     [31:0]                      sfh_pulse_freq_2r;

// Wire Define 
wire    [USER_NUM-1:0]              chn_ctrl;
wire    [USER_NUM*3-1:0]            chn_mode;
wire    [18:0]                      trig_len;
wire    [USER_NUM*10-1:0]           tout_time;
wire    [31:0]                      tout_en;
wire    [USER_NUM-1:0]              infifo_overflow;
wire    [USER_NUM-1:0]              c_data_sof;
wire    [USER_NUM-1:0]              c_data_eof;
wire    [USER_NUM-1:0]              c_data_vld;
wire    [USER_NUM-1:0]              c_data_end;
wire    [(USER_NUM*15)-1:0]         c_data_len;
wire    [USER_NUM*IN_DATA_W-1:0]    c_data;
wire    [USER_NUM-1:0]              c_pfull;
wire                                hin_en;
wire    [15:0]                      hin_len;

//2s
wire    [NUM_2S-1:0]                out_pfull_2s;
wire    [NUM_2S-1:0]                out_data_vld_2s;
wire    [NUM_2S-1:0]                out_data_sof_2s;
wire    [NUM_2S-1:0]                out_data_eof_2s;
wire    [NUM_2S*256-1:0]            out_data_2s;
wire    [NUM_2S*INFO_W-1:0]         out_data_info_2s;
wire    [(NUM_2S*15)-1:0]           out_data_len_2s;
wire    [NUM_2S-1:0]                out_data_end_2s;
wire    [NUM_2S-1:0]                fifo_overflow_2s;
wire    [NUM_2S-1:0]                fifo_prog_empty_2s;
wire    [NUM_2S*4-1:0]              fifo_empty_2s;

//1s
wire    [NUM_1S-1:0]                out_pfull_1s;
wire    [NUM_1S-1:0]                out_data_vld_1s;
wire    [NUM_1S-1:0]                out_data_sof_1s;
wire    [NUM_1S-1:0]                out_data_eof_1s;
wire    [NUM_1S*256-1:0]            out_data_1s;
wire    [NUM_1S*INFO_W-1:0]         out_data_info_1s;
wire    [NUM_1S-1:0]                out_data_end_1s;
wire    [(NUM_1S*15)-1:0]           out_data_len_1s;
wire    [NUM_1S-1:0]                fifo_overflow_1s;
wire    [NUM_1S-1:0]                fifo_prog_empty_1s;
wire    [NUM_1S*2-1:0]              fifo_empty_1s;

wire    [23:0]                      band;
wire                                fifo_overflow_2level;
wire                                fifo_prog_empty_2level;


//--------------------------------------------------------
//u_multif_cib
//--------------------------------------------------------
multif_cib#(
    .U_DLY                      (U_DLY                      ),
    .FRAME_LEN                  (FRAME_LEN                  ),
    .USER_NUM                   (USER_NUM                   ),
    .NUM_1S                     (NUM_1S                     ),
    .NUM_2S                     (NUM_2S                     )
)u_multif_cib(
    .clk                        (clk_r                      ),
    .rst                        (hard_rst                   ),
    .cpu_cs                     (cpu_cs                     ),
    .cpu_wr                     (cpu_wr                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wr_data                (cpu_wr_data                ),
    .cpu_rd_data                (cpu_rd_data                ),

    .chn_ctrl                   (chn_ctrl                   ),
    .chn_mode                   (chn_mode                   ),
    .trig_len                   (trig_len                   ),
    .tout_time                  (tout_time                  ),
    .tout_en                    (tout_en                    ),
    .hin_en                     (hin_en                     ),
    .hin_len                    (hin_len                    ),

    .indata_vld                 ({indata_vld}               ),
    
    .fifo_overflow_1s           ({fifo_overflow_1s}         ),
    // .fifo_overflow_2s           (fifo_overflow_2s           ),
    .fifo_overflow_2s           (                           ),
    .fifo_overflow_2level       (fifo_overflow_2level       ),

    .fifo_prog_empty_1s         ({fifo_prog_empty_1s}       ),
    // .fifo_prog_empty_2s         (fifo_prog_empty_2s         ),
    .fifo_prog_empty_2s         (                           ),
    .fifo_prog_empty_2level     (fifo_prog_empty_2level     ),

    .fifo_empty                 ({fifo_empty_1s}            ),
    .band                       (band                       ),
    .infifo_overflow            (infifo_overflow            )

);

always @ (posedge clk_h or posedge rst)begin
    if(rst == 1'b1)
        begin
            stamp_1r <= #U_DLY 'd0;
            stamp_2r <= #U_DLY 'd0;
            sfh_pulse_cnt_1r <= #U_DLY 'b0;
            sfh_pulse_cnt_2r <= #U_DLY 'b0;
            sfh_pulse_freq_1r <= #U_DLY 'b0;
            sfh_pulse_freq_2r <= #U_DLY 'b0;
        end       
    else   
        begin
            stamp_1r <= #U_DLY stamp;
            stamp_2r <= #U_DLY stamp_1r;
            sfh_pulse_cnt_1r <= #U_DLY sfh_pulse_cnt;
            sfh_pulse_cnt_2r <= #U_DLY sfh_pulse_cnt_1r;
            sfh_pulse_freq_1r <= #U_DLY sfh_pulse_freq;
            sfh_pulse_freq_2r <= #U_DLY sfh_pulse_freq_1r;
        end 
end

//--------------------------------------------------------
//u_multif_ctrl
//--------------------------------------------------------
genvar i;
generate
for(i=0;i<USER_NUM;i=i+1)
begin
multif_ctrl # (
    .U_DLY                      (U_DLY                      ),
    .HEADER_PATTERN             (64'h7e7e7e7e_7e7e7e7e      ),
    .IN_DATA_W                  (IN_DATA_W                  ),
    .INFO_W                     (INFO_W                     ),
    .TIME                       (100                        ),
    .FRAME_LEN                  (FRAME_LEN                  ),
    .STP_W                      (STP_W                      )
)u_multif_ctrl_adc(
    .clk_w                      (clk_adc_w                  ),
    .clk                        (clk_h                      ),
    .rst                        (rst                        ),
    .rtc_us                     (rtc_us_flg                 ),
    .hin_en                     (hin_en                     ),
    .hin_len                    (hin_len                    ),
    .samp_rate                  (samp_rate[32-1:0]          ),
    .stamp                      (stamp_2r[STP_W-1:0]        ),
    .sfh_pulse_cnt              (sfh_pulse_cnt_2r           ),
    .sfh_pulse_freq             (sfh_pulse_freq_2r          ),

    .chn_ctrl                   (chn_ctrl[i]                ),
    .chn_mode                   (chn_mode[i*3+:3]           ),
    .trig_len                   (trig_len                   ),
    // .tout_time                  (tout_time[i*10+:10]        ),
    .tout_en                    (tout_en[0]                 ),

    .indata_vld                 (indata_vld[i]              ),
    .indata                     (indata[i*IN_DATA_W+:IN_DATA_W]),
    .indata_end                 (indata_end[i]              ),
    .indata_info                (indata_info[i*INFO_W+:INFO_W]),

    .c_data_sof                 (c_data_sof[i]                 ),
    .c_data_eof                 (c_data_eof[i]                 ),
    .c_data_vld                 (c_data_vld[i]                 ),
    .c_data_end                 (c_data_end[i]                 ),
    .c_data_len                 (c_data_len[15*i+:15]          ),
    .c_data                     (c_data[i*IN_DATA_W+:IN_DATA_W]),
    .c_pfull                    (c_pfull[i]                    ),
    .infifo_overflow            (infifo_overflow[i]            )
);
end
endgenerate
//--------------------------------------------------------
//1level
//--------------------------------------------------------
genvar j;
generate
for(j=0;j<NUM_1S;j=j+1)
begin
multif_1level#(
    .U_DLY                      (U_DLY                      ),
    .USER_NUM                   (2                          ),
    .IN_DATA_W                  (IN_DATA_W                  ),
    .INFO_W                     (INFO_W                     ),
    .FRAME_LEN                  (FRAME_LEN                  ),
    .FIFO_W                     (256                        ),
    .FIFO_DEEPTH                (512                        ),
    .FIFO_ADDR_W                (9                          ),
    .PROG_FULL_LEVEL            (9'd496                     )
)u_multif_1level_1s
(
    .clk_w                      (clk_h                      ),
    .clk_r                      (clk_h                      ),
    .rst                        (rst                        ),

    .in_data_sof                ({c_data_sof[(j*2+1)*1+:1],             c_data_sof[(j*2)*1+:1]}             ),
    .in_data_eof                ({c_data_eof[(j*2+1)*1+:1],             c_data_eof[(j*2)*1+:1]}             ),
    .in_data_end                ({c_data_end[(j*2+1)*1+:1],             c_data_end[(j*2)*1+:1]}             ),
    .in_data_vld                ({c_data_vld[(j*2+1)*1+:1],             c_data_vld[(j*2)*1+:1]}             ),
    .in_data                    ({c_data[(j*2+1)*IN_DATA_W+:IN_DATA_W], c_data[(j*2)*IN_DATA_W+:IN_DATA_W]} ),
    .in_data_info               ({indata_info[(j*2+1)*INFO_W+:INFO_W],  indata_info[(j*2)*INFO_W+:INFO_W]}  ),
    .in_data_len                ({c_data_len[((j*2+1)*15)+:15],         c_data_len[((j*2)*15)+:15]}         ),
    .in_data_pfull              ({c_pfull[(j*2+1)*1+:1],                c_pfull[(j*2)*1+:1]}                ),

    .out_pfull                  (out_pfull_1s[j]                    ),
    .out_data_vld               (out_data_vld_1s[j]                 ),
    .out_data_sof               (out_data_sof_1s[j]                 ),
    .out_data_eof               (out_data_eof_1s[j]                 ),
    .out_data                   (out_data_1s[j*256+:256]            ),
    .out_data_info              (out_data_info_1s[j*INFO_W+:INFO_W] ),
    .out_data_len               (out_data_len_1s[j*15+:15]          ),
    .out_data_end               (out_data_end_1s[j]                 ),

    .fifo_overflow              (fifo_overflow_1s[j]                ),
    .fifo_prog_empty            (fifo_prog_empty_1s[j]              ),
    .fifo_empty                 (fifo_empty_1s[j*2+:2]              )
);
end
endgenerate

//--------------------------------------------------------
//out level
//--------------------------------------------------------
multif_2level#(
    .U_DLY                      (U_DLY                      ),
    .USER_NUM                   (NUM_1S                     ),
    .IN_DATA_W                  (256                        ),
    .INFO_W                     (INFO_W                     ),
    .FRAME_LEN                  (FRAME_LEN                  ),
    .FIFO_W                     (512                        )
)u_multif_2level
(
    .clk_w                      (clk_h                      ),
    .clk_r                      (clk_r                      ),
    .rst                        (rst                        ),
    .rtc_s_flg                  (rtc_s_flg                  ),
    
    .in_data_sof                (out_data_sof_1s            ),
    .in_data_eof                (out_data_eof_1s            ),
    .in_data_end                (out_data_end_1s            ),
    .in_data_vld                (out_data_vld_1s            ),
    .in_data                    (out_data_1s                ),
    .in_data_info               (out_data_info_1s           ),
    .in_data_len                (out_data_len_1s            ),
    .in_data_pfull              (out_pfull_1s               ),

    .out_data_rdy               (out_data_rdy               ),
    .out_data_vld               (out_data_vld               ),
    .out_data_sof               (out_data_sof               ),
    .out_data_eof               (out_data_eof               ),
    .out_data                   (out_data                   ),
    .out_data_info              (out_data_info              ),
    .out_data_len               (out_data_len               ),
    .out_data_end               (out_data_end               ),
    
    .fifo_overflow              (fifo_overflow_2level       ),
    .fifo_prog_empty            (fifo_prog_empty_2level     ),
    .fifo_empty                 (                           ),
    .band                       (band                       )

);


function integer clog2b;
input integer value;
integer tmp;
begin
    tmp = value;
    if(tmp<=1)
        clog2b = 1;
    else
    begin
        tmp = tmp-1;
        for (clog2b=0; tmp>0; clog2b=clog2b+1)
            tmp = tmp>>1;
    end
end
endfunction

endmodule



