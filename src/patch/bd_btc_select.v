// *********************************************************************************/
// Project Name :
// Author       : yinchao
// Email        : 
// Creat Time   : 2021/3/30 16:30:40
// File Name    : .v
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
module bd_btc_select #(
parameter                           U_DLY = 1
)
(
input                                            clk,
input                                            rst,
input                                            pp1s,
input                                            bd_pps,
input          [63:0]                            stamp,
input                                            timing_1s,
input          [1:0]                             pps_cfg,
input                                            bd_utc_chok,
input                                            bcode_chok,
output reg     [63:0]                            stamp_2r,
output reg     [31:0]                            samp_cnt,
output reg     [31:0]                            samp_rate
);
// Parameter Define 

// Register Define 
reg     [2:0]                       pp1s_r;
reg     [2:0]                       bd_pps_r;
reg                                 pps_flg;
reg     [63:0]                      stamp_1r;
reg     [2:0]                       timing_1s_r;
reg     [1:0]                       reserevd_2cfg_1r;
reg     [1:0]                       reserevd_2cfg_2r;
// Wire Define 

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            pp1s_r <= #U_DLY 'b0;
            bd_pps_r <= #U_DLY 'b0;
            pps_flg <= #U_DLY 1'b0;
            samp_cnt <= #U_DLY 'd0;
            samp_rate <= #U_DLY 'd0;
            stamp_1r <= #U_DLY 'd0;
            stamp_2r <= #U_DLY 'd0;
            timing_1s_r <= #U_DLY 'b0;
            reserevd_2cfg_1r <= #U_DLY 'b0;
            reserevd_2cfg_2r <= #U_DLY 'b0;
        end   
    else   
        begin
            pp1s_r <= #U_DLY {pp1s_r[1:0],pp1s};
            bd_pps_r <= #U_DLY {bd_pps_r[1:0],bd_pps};
            stamp_1r <= #U_DLY stamp;
            stamp_2r <= #U_DLY stamp_1r;
            timing_1s_r <= #U_DLY {timing_1s_r[1:0],timing_1s};
            reserevd_2cfg_1r <= #U_DLY pps_cfg;
            reserevd_2cfg_2r <= #U_DLY reserevd_2cfg_1r;
            
            if(reserevd_2cfg_2r[1] == 1'b1)
                begin
                    if(timing_1s_r[1] ^ timing_1s_r[2]==1'b1)
                        pps_flg <= #U_DLY 1'b1;
                    else
                        pps_flg <= #U_DLY 1'b0;
                end
            else
                begin
                    if(reserevd_2cfg_2r[0] == 1'b1)
                        begin
                            if(bd_utc_chok==1'b1)
                                begin
                                    if(bd_pps_r[1]==1'b1 && bd_pps_r[2]==1'b0)
                                        pps_flg <= #U_DLY 1'b1;
                                    else
                                        pps_flg <= #U_DLY 1'b0;
                                end
                            else if(timing_1s_r[1] ^ timing_1s_r[2]==1'b1)
                                pps_flg <= #U_DLY 1'b1;
                            else
                                pps_flg <= #U_DLY 1'b0;
                        end 
                    else
                        begin
                            if(bcode_chok==1'b1)
                                begin
                                    if(pp1s_r[1]==1'b1 && pp1s_r[2]==1'b0)
                                        pps_flg <= #U_DLY 1'b1;
                                    else
                                        pps_flg <= #U_DLY 1'b0;
                                end
                            else if(timing_1s_r[1] ^ timing_1s_r[2]==1'b1)
                                pps_flg <= #U_DLY 1'b1;
                            else
                                pps_flg <= #U_DLY 1'b0;
                        end 
            end
            
            if(pps_flg==1'b1)
                samp_cnt <= #U_DLY 'd0;
            else
                samp_cnt <= #U_DLY samp_cnt + 'd1;

            if(pps_flg==1'b1)
                samp_rate <= #U_DLY samp_cnt;
        end 
end

endmodule
