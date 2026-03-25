// *********************************************************************************/
// Project Name :
// Author       : yinchao
// Email        : 
// Creat Time   : 2021/1/7 14:11:25
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
module assembly#(
parameter                           U_DLY = 1,
parameter                           DATAI_WIDTH  = 32,
parameter                           DATAO_WIDTH  = 32,
parameter                           SPLIT_WIDTH = 16
)
(
input                                clk,
input                                rst_n,
input                                vld_in,
input        [DATAI_WIDTH-1:0]       data_in,
input                                select,
output reg   [DATAO_WIDTH-1:0]       data_out,
output reg                           vld_out
);
// Parameter Define 
localparam                           VLD_FLAG = DATAO_WIDTH/SPLIT_WIDTH-1;
// Register Define 
reg     [2:0]                       select_r;
reg     [VLD_FLAG-1:0]              vld_flag;

// Wire Define 

always @(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
    begin
        data_out  <= #U_DLY 'b0;
        vld_out   <= #U_DLY 1'b0;
        vld_flag  <= #U_DLY 'b0;
        select_r  <= #U_DLY 3'b0;
    end
    else
    begin
        select_r <= #U_DLY {select_r[1:0],select};

        if( vld_in == 1'b1)
        begin
            if(select_r[2] == 1'b1)
                data_out <= #U_DLY {data_in[DATAI_WIDTH-1:DATAI_WIDTH-SPLIT_WIDTH],data_out[DATAO_WIDTH-1:SPLIT_WIDTH]};
            else
                data_out <= #U_DLY {data_in[SPLIT_WIDTH-1:0],data_out[DATAO_WIDTH-1:SPLIT_WIDTH]};
        end
        else;

        if(((vld_flag[0] == 1'b1)&&( vld_in == 1'b1))||(select_r[1]!=select_r[2]))
           vld_flag <= #U_DLY 'b0;
        else if( vld_in == 1'b1)
        begin
            if(VLD_FLAG == 1)
                vld_flag <= #U_DLY 1'b1;
            else
                vld_flag <= #U_DLY {1'b1,vld_flag[VLD_FLAG-1:1]};
        end           
        else;

        if((vld_flag[0] == 1'b1)&&( vld_in == 1'b1))
            vld_out <= #U_DLY 1'b1;
        else
            vld_out <= #U_DLY 1'b0;
    end
end

endmodule
