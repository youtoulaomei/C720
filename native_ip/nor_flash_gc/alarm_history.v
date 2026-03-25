// *********************************************************************************
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2014/1/15 8:56:12
// File Name    : alarm_history.v
// Module Name  :
// Called By    : 
// Abstract     :
//
// CopyRight(c) 2012, Zhimingda digital equipment Co., Ltd.. 
// All Rights Reserved
//
// *********************************************************************************
// Modification History:
// 1. initial
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
`timescale 1 ns / 1 ns
module alarm_history #(
parameter                           U_DLY          = 1,
parameter                           ADDR_WIDTH     = 11,
parameter                           ALARM_HIS_ADDR = 11'h0
)
(
input                               rst,
input                               src_clk,
input                               cpu_clk,
input                               cpu_read_en,
input      [ADDR_WIDTH-1:0]         cpu_addr,
input                               alarm_in,
output wire                         alarm_history
//output reg                         alarm_history
);

reg        [3:0]                    alarm_in_dly;
reg        [1:0]                    alarm_dly;
reg                                 alarm_history_pre;
reg                                 alarm_ext;

always @(posedge src_clk, posedge rst)
begin
    if(rst == 1'b1)
        begin
            alarm_in_dly <= 4'd0;
            alarm_ext <= 1'b0;
        end
    else
        begin
            alarm_in_dly <= #U_DLY {alarm_in_dly[2:0],alarm_in};
            alarm_ext <= #U_DLY |{alarm_in_dly,alarm_in};
        end
end

always @(posedge cpu_clk, posedge rst)
begin
    if(rst == 1'b1)
        alarm_dly <= 2'b00;
    else
        alarm_dly <= #U_DLY {alarm_dly[0],alarm_ext};
end

always @(posedge cpu_clk, posedge rst)
begin
    if(rst == 1'b1)
        alarm_history_pre <= 1'b0;
    else
        begin
            if(cpu_read_en == 1'b1 && cpu_addr == ALARM_HIS_ADDR)
                alarm_history_pre <= #U_DLY alarm_dly[1];
            else if(alarm_dly[1] == 1'b1)
                alarm_history_pre <= #U_DLY 1'b1;
            else;
        end
end

//always @(posedge cpu_clk, posedge rst)
//begin
//    if(rst == 1'b1)
//        alarm_history <= 1'b0;
//    else
//        begin
//            if(cpu_read_en == 1'b1 && cpu_addr == ALARM_HIS_ADDR)
//                alarm_history <= #U_DLY alarm_history_pre;
//            else;
//        end
//end
assign alarm_history = alarm_history_pre;

endmodule

