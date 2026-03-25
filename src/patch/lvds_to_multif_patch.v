// *********************************************************************************/
// Project Name :
// Author       :jiangxiaohan
// Email        : 
// Creat Time   : 2019/10/31 11:13:35
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
module lvds_to_multif_patch #(
parameter                           U_DLY = 1,
parameter                           DATA_IN_WIDTH  = 16,
parameter                           DATA_OUT_WIDTH = 32,
parameter                           DATA_OUT_NUM   = 4 
)
(
input                                            clk,
input                                            rst,
input         [DATA_IN_WIDTH*DATA_OUT_NUM-1:0]   ad_data,
input         [DATA_OUT_NUM-1:0]                 ad_vld,

output  reg   [DATA_OUT_WIDTH-1:0]               ad0_data_dly,
output  reg   [DATA_OUT_WIDTH-1:0]               ad1_data_dly,  
output  reg   [DATA_OUT_WIDTH-1:0]               ad2_data_dly,
output  reg   [DATA_OUT_WIDTH-1:0]               ad3_data_dly,  

output  reg                                      ad0_dvld_temp,
output  reg                                      ad1_dvld_temp,
output  reg                                      ad2_dvld_temp,
output  reg                                      ad3_dvld_temp

);
// Parameter Define 

// Register Define 
reg         ad0_data_cnt;
reg         ad1_data_cnt;
reg         ad2_data_cnt;
reg         ad3_data_cnt;
reg         ad0_dvld;
reg         ad1_dvld;
reg         ad2_dvld;
reg         ad3_dvld;
reg [15:0]  ad0_data;
reg [15:0]  ad1_data;
reg [15:0]  ad2_data;
reg [15:0]  ad3_data;

// Wire Define 

//-----------------------------------------------------------------------
//patch 16 to 32
//-----------------------------------------------------------------------
always @(*)
begin
    ad0_data = ad_data[15:0];
    ad1_data = ad_data[31:16];
    ad2_data = ad_data[47:32];
    ad3_data = ad_data[63:48];
    ad0_dvld = ad_vld[0];
    ad1_dvld = ad_vld[1];
    ad2_dvld = ad_vld[2];
    ad3_dvld = ad_vld[3];
end

always @(posedge clk or posedge rst)
begin
    if(rst==1'b1)
    begin
        ad0_data_cnt  <= 'h0;
        ad0_data_dly  <= 'h0;
        ad0_dvld_temp <= 'h0;

        ad1_data_cnt  <= 'h0;
        ad1_data_dly  <= 'h0;
        ad1_dvld_temp <= 'h0;

        ad2_data_cnt  <= 'h0;
        ad2_data_dly  <= 'h0;
        ad2_dvld_temp <= 'h0;

        ad3_data_cnt  <= 'h0;
        ad3_data_dly  <= 'h0;
        ad3_dvld_temp <= 'h0;
    end
    else
    begin
        //lvds_chn0
        if(ad0_dvld == 1'b1)
        begin
            ad0_data_cnt <= ad0_data_cnt + 1'b1;
            ad0_data_dly <= {ad0_data,ad0_data_dly[31:16]};
        end
        else;
          
        if(ad0_data_cnt==1'b1 && ad0_dvld==1'b1)
            ad0_dvld_temp <= 1'b1;
        else
            ad0_dvld_temp <= 1'b0;

         //lvds_chn1
        if(ad1_dvld == 1'b1)
        begin
            ad1_data_cnt <= ad1_data_cnt + 1'b1;
            ad1_data_dly <= {ad1_data,ad1_data_dly[31:16]};
        end
        else;
          
        if(ad1_data_cnt==1'b1 && ad1_dvld==1'b1)
            ad1_dvld_temp <= 1'b1;
        else
            ad1_dvld_temp <= 1'b0;

         //lvds_chn2
        if(ad2_dvld == 1'b1)
        begin
            ad2_data_cnt <= ad2_data_cnt + 1'b1;
            ad2_data_dly <= {ad2_data,ad2_data_dly[31:16]};
        end
        else;
          
        if(ad2_data_cnt==1'b1 && ad2_dvld==1'b1)
            ad2_dvld_temp <= 1'b1;
        else
            ad2_dvld_temp <= 1'b0;

         //lvds_chn3
        if(ad3_dvld == 1'b1)
        begin
            ad3_data_cnt <= ad3_data_cnt + 1'b1;
            ad3_data_dly <= {ad3_data,ad3_data_dly[31:16]};
        end
        else;
          
        if(ad3_data_cnt==1'b1 && ad3_dvld==1'b1)
            ad3_dvld_temp <= 1'b1;
        else
            ad3_dvld_temp <= 1'b0;

    end
end

endmodule

