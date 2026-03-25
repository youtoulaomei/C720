// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2016/2/17 13:41:47
// File Name    : timestamp_7s.v
// Module Name  : 
// Called By    :
// Abstract     : For 7 series FPGA compile time
//
// CopyRight(c) 2016, Zhimingda digital equipment Co., Ltd.. 
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
module timestamp_7s #(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst,
//output
output  wire    [15:0]              year,
output  reg     [7:0]               month,
output  reg     [7:0]               day,
output  reg     [7:0]               hour,
output  reg     [7:0]               minute
);
// Parameter Define 

// Register Define 
reg             [7:0]               year_l;
// Wire Define 
wire            [31:0]              ts_w;

USR_ACCESSE2 u_USR_ACCESSE2 (
    .CFGCLK                     (                           ),
    .DATA                       (ts_w                       ),
    .DATAVALID                  (                           )
   );
//year
assign year = {8'h20,year_l};

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        year_l <= 8'h00;
    else
        begin
            if(ts_w[22:17] >= 6'd60)
                begin
                    year_l[7:4] <= #U_DLY 4'h6;
                    year_l[3:0] <= #U_DLY ts_w[22:17] - 6'd60;
                end
            else if(ts_w[22:17] >= 6'd50)
                begin
                    year_l[7:4] <= #U_DLY 4'h5;
                    year_l[3:0] <= #U_DLY ts_w[22:17] - 6'd50;
                end
            else if(ts_w[22:17] >= 6'd40)
                begin
                    year_l[7:4] <= #U_DLY 4'h4;
                    year_l[3:0] <= #U_DLY ts_w[22:17] - 6'd40;
                end
            else if(ts_w[22:17] >= 6'd30)
                begin
                    year_l[7:4] <= #U_DLY 4'h3;
                    year_l[3:0] <= #U_DLY ts_w[22:17] - 6'd30;
                end
            else if(ts_w[22:17] >= 6'd20)
                begin
                    year_l[7:4] <= #U_DLY 4'h2;
                    year_l[3:0] <= #U_DLY ts_w[22:17] - 6'd20;
                end
            else if(ts_w[22:17] >= 6'd10)
                begin
                    year_l[7:4] <= #U_DLY 4'h1;
                    year_l[3:0] <= #U_DLY ts_w[22:17] - 6'd10;
                end
            else
                begin
                    year_l[7:4] <= #U_DLY 4'h0;
                    year_l[3:0] <= #U_DLY ts_w[20:17];
                end
        end
end
//month
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        month <= 8'd0;
    else
        begin
            if(ts_w[26:23] >= 4'd10)
                begin
                    month[7:4] <= #U_DLY 4'h1;
                    month[3:0] <= #U_DLY ts_w[26:23] - 4'd10;
                end
            else
                begin
                    month[7:4] <= #U_DLY 4'h0;
                    month[3:0] <= #U_DLY ts_w[26:23];
                end
        end
end
//day
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        day <= 8'd0;
    else
        begin
            if(ts_w[31:27] >= 5'd30)
                begin
                    day[7:4] <= #U_DLY 4'h3;
                    day[3:0] <= #U_DLY ts_w[31:27] - 5'd30;
                end
            else if(ts_w[31:27] >= 5'd20)
                begin
                    day[7:4] <= #U_DLY 4'h2;
                    day[3:0] <= #U_DLY ts_w[31:27] - 5'd20;
                end
            else if(ts_w[31:27] >= 5'd10)
                begin
                    day[7:4] <= #U_DLY 4'h1;
                    day[3:0] <= #U_DLY ts_w[31:27] - 5'd10;
                end
            else
                begin
                    day[7:4] <= #U_DLY 4'h0;
                    day[3:0] <= #U_DLY ts_w[30:27];
                end
        end
end
//hour
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        hour <= 8'd0;
    else
        begin
            if(ts_w[16:12] >= 5'd20)
                begin
                    hour[7:4] <= #U_DLY 4'h2;
                    hour[3:0] <= #U_DLY ts_w[16:12] - 5'd20;
                end
            else if(ts_w[16:12] >= 5'd10)
                begin
                    hour[7:4] <= #U_DLY 4'h1;
                    hour[3:0] <= #U_DLY ts_w[16:12] - 5'd10;
                end
            else
                begin
                    hour[7:4] <= #U_DLY 4'h0;
                    hour[3:0] <= #U_DLY ts_w[15:12];
                end
        end
end
//minute
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        minute <= 8'd0;
    else
        begin
            if(ts_w[11:6] >= 6'd50)
                begin
                    minute[7:4] <= #U_DLY 4'd5;
                    minute[3:0] <= #U_DLY ts_w[11:6] - 6'd50;
                end
            else if(ts_w[11:6] >= 6'd40)
                begin
                    minute[7:4] <= #U_DLY 4'd4;
                    minute[3:0] <= #U_DLY ts_w[11:6] - 6'd40;
                end     
            else if(ts_w[11:6] >= 6'd30)
                begin
                    minute[7:4] <= #U_DLY 4'd3;
                    minute[3:0] <= #U_DLY ts_w[11:6] - 6'd30;
                end    
            else if(ts_w[11:6] >= 6'd20)
                begin
                    minute[7:4] <= #U_DLY 4'd2;
                    minute[3:0] <= #U_DLY ts_w[11:6] - 6'd20;
                end
            else if(ts_w[11:6] >= 6'd10)
                begin
                    minute[7:4] <= #U_DLY 4'd1;
                    minute[3:0] <= #U_DLY ts_w[11:6] - 6'd10;
                end 
            else
                begin
                    minute[7:4] <= #U_DLY 4'd0;
                    minute[3:0] <= #U_DLY ts_w[9:6];
                end 
        end
end

endmodule

