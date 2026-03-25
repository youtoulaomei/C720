// *********************************************************************************/
// Project Name :
// Author       : chendong
// Email        : dongfang219@126.com
// Creat Time   : 2014/8/10 14:12:45
// File Name    : .v
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
module alarm_current #(
parameter                           U_DLY = 1,
parameter                           SAME_SOURCE = "false",//yangyong modified 20170310,no need the read address
parameter                           DATA_WIDTH = 8
)
(
input                               cpu_clk,
input                               rst,
//input                               cpu_read_en,
input           [DATA_WIDTH-1:0]    alarm_in,
//output  reg     [DATA_WIDTH-1:0]    alarm_current 
output  wire    [DATA_WIDTH-1:0]    alarm_current 
);
// Parameter Define 

// Register Define 
reg             [DATA_WIDTH-1:0]    alarm_1dly;
reg             [DATA_WIDTH-1:0]    alarm_2dly;

// Wire Define 

generate
    if(SAME_SOURCE == "false")
        begin
            always @(posedge cpu_clk, posedge rst)
            begin
                if(rst == 1'b1)
                    begin
                        alarm_1dly <= 'd0;
                        alarm_2dly <= 'd0;
                    end
                else
                    begin
                        alarm_1dly <= #U_DLY alarm_in;
                        alarm_2dly <= #U_DLY alarm_1dly;
                    end
            end
        end
    else
        begin
            always @(*)
            begin
                alarm_1dly = 'd0;
                alarm_2dly = alarm_in;
            end
        end
endgenerate

//always @ (posedge cpu_clk, posedge rst)
//begin
//    if(rst == 1'b1)     
//        alarm_current <= 'd0;
//    else    
//        begin
//            if(cpu_read_en == 1'b1)
//                alarm_current <= #U_DLY alarm_2dly;
//            else;
//        end
//end
assign alarm_current = alarm_2dly;
endmodule

