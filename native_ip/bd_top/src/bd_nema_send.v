// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/12/21 17:04:17
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Boyulihua digital equipment Co., Ltd.. 
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
module bd_nema_send # (
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst,

input                               send,
input [7:0]                         send_data,
output reg                          send_done,


output reg                          tx_vld,
output reg [7:0]                    tx_data,
input                               tx_busy

);
// Parameter Define 
localparam                          IDLE     = 2'd0;
localparam                          SEND_CHK = 2'd1;
localparam                          SEND_PRO = 2'd2;
localparam                          SEND_DONE= 2'd3;

// Register Define 
reg     [1:0]                       ut_state;
reg     [1:0]                       ut_nextstate;

// Wire Define 

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        ut_state <= #U_DLY IDLE;        
    else    
        ut_state <= #U_DLY ut_nextstate;
end

always @ (*)begin
    case(ut_state)
        IDLE:
        begin
            if(send==1'b1 && tx_busy==1'b0)
                ut_nextstate=SEND_CHK;
            else 
                ut_nextstate=IDLE;
        end

        SEND_CHK:
        begin
            if(tx_busy==1'b1)
                ut_nextstate=SEND_PRO;
            else
                ut_nextstate=SEND_CHK;
        end

        SEND_PRO:
        begin
            if(tx_busy==1'b0)
                ut_nextstate=SEND_DONE;
            else
                ut_nextstate=SEND_PRO;
        end

        SEND_DONE:
        begin
            if(send==1'b0)
                ut_nextstate=IDLE;
            else
                ut_nextstate=SEND_DONE;
        end

        default:ut_nextstate=IDLE;
    endcase
end




always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        tx_vld <= #U_DLY 1'b0;
    else if(ut_state==SEND_CHK && ut_nextstate!=SEND_CHK)
        tx_vld <= #U_DLY 1'b0;
    else if(ut_state==IDLE && send==1'b1)
        tx_vld <= #U_DLY 1'b1;
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        tx_data <= #U_DLY 'b0;        
    else if(ut_state==IDLE && send==1'b1)  
        tx_data <= #U_DLY send_data;  
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        send_done <= #U_DLY 1'b0;      
    else if(ut_state==SEND_PRO && ut_nextstate==SEND_DONE)
        send_done <= #U_DLY 1'b1;
    else
        send_done <= #U_DLY 1'b0;   
end

endmodule

