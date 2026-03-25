// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/12/8 13:59:27
// File Name    : authorize.v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2017,BoYuLiHua Technology Co., Ltd.. 
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
module authorize #(
parameter                           ADDR_W = 5,
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst,
//dna
input           [56:0]              dna_data,
input                               dna_vld,

input           [31:0]              key,
//authorize success
input                               admin_accredit,
output  reg     [31:0]              authorize_code,
output  reg                         authorize_succ
)/* synthesis syn_romstyle = "block_rom" */;
// Parameter Define 

// Register Define 
reg     [ADDR_W - 1:0]              addr;
reg     [56:0]                      idata_latch;
reg     [31:0]                      authorize_code_pre;
reg                                 step_0_result;
reg                                 step_1_result;
reg                                 authorize_succ_dly;
reg     [56:0]                      data_out;
// Wire Define 
always @(posedge clk)
begin
    case(addr)
        'd0: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd1: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd2: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd3: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd4: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd5: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd6: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd7: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd8: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd9: data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd10:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd11:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd12:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd13:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd14:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd15:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd16:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd17:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd18:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd19:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd20:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd21:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd22:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd23:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd24:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd25:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd26:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd27:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd28:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd29:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd30:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        'd31:data_out <= 57'h1FF_FFFF_FFFF_FFFF;
        default:;
    endcase
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            addr <= 'd0;
            idata_latch <= 'd0;
            step_0_result <= 1'b0;
            step_1_result <= 1'b0;
            authorize_succ <= 1'b0;
            authorize_succ_dly <= 1'b0;
        end
    else
        begin
            if(dna_vld == 1'b1)
                addr <= #U_DLY {ADDR_W{1'b1}};
            else if(addr != 'd0)
                addr <= #U_DLY addr - 'd1;
            else;

            if(dna_vld == 1'b1)
                idata_latch <= #U_DLY dna_data;
            else;

            if(idata_latch[31:0] == data_out[31:0])
                step_0_result <= #U_DLY 1'b1;
            else
                step_0_result <= #U_DLY 1'b0;

            if(idata_latch[56:32] == data_out[56:32])
                step_1_result <= #U_DLY 1'b1;
            else
                step_1_result <= #U_DLY 1'b0;

            if(admin_accredit == 1'b1)
                authorize_succ <= #U_DLY 1'b1;
            else if({step_1_result,step_0_result} == 2'b11)
                authorize_succ <= #U_DLY 1'b1;
            else;

            authorize_succ_dly <= #U_DLY authorize_succ;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        authorize_code_pre <= 'd0;  
    else
        begin
            if(authorize_succ == 1'b0)
                authorize_code_pre <= #U_DLY ~idata_latch[31:0];
            else
                authorize_code_pre <= #U_DLY athr_code_gen(authorize_code_pre);
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        authorize_code <= 'd0;
    else
        begin
            if(authorize_succ_dly == 1'b0)
                authorize_code <= #U_DLY 'hffff_ffff;
            else
                authorize_code <= #U_DLY authorize_code_pre ^ key;
        end
end

function [31:0] athr_code_gen(input [31:0] f_last_seeds);    //G(X) = X31 + X25 + X22 + X6 + 1; (not the standard PRBS31[G(X) = X31 + X28 + 1])
integer i;
reg base_xor;
begin
    athr_code_gen = f_last_seeds;
    for(i=0; i<=31; i=i+1)
        begin
            base_xor = athr_code_gen[30]^athr_code_gen[24]^athr_code_gen[21]^athr_code_gen[5];
            athr_code_gen = {athr_code_gen[30:0],base_xor};
        end
end
endfunction

endmodule

