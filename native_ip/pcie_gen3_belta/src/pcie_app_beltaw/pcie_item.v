// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2018/12/13 13:07:38
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
//
//
//
//  item data
//
//  [127:64] reserved
//  [63:56]  reserved 
//  [55:32]  wlen
//  [31:0]   waddr
// *************************
// MODULE DEFINITION
// *************************
`timescale 1 ns / 1 ns
module pcie_item #(
parameter                           U_DLY      = 1,
parameter                           CHN_NUM    = 60,
parameter                           CHN_NUM_W  = clog2b(CHN_NUM),
parameter                           CHN_INDEX = 8
)
(
input                               clk,
input                               rst,
input                               item_rst,
input                               chn_ena,
input       [2:0]                   cfg_max_payload,

output reg                          item_arb_req,
input                               arb_item_ack,
input                               arb_witem_vld,
input       [159:0]                 arb_item_data,

output reg                          chn_dma_en, 
output reg  [31:0]                  chn_dma_addr,
output reg  [23:0]                  chn_dma_len,
output reg  [63:0]                  chn_dma_rev,
output reg  [31:0]                  chn_dma_addr_h,

input                               chn_dma_done,
input       [CHN_NUM_W-1:0]         chn_dma_chn

);
// Parameter Define 
localparam                          IDLE         = 2'd0;
localparam                          ITEM_REQ     = 2'd1;
localparam                          ITEM_PROCESS = 2'd2;

// Register Define 
reg     [1:0]                       item_state;
reg     [1:0]                       item_nextstate;
reg                                 chn_dma_done_det;

// Wire Define 

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        item_state <= #U_DLY IDLE;
    else if(item_rst==1'b1 || chn_ena==1'b0)    
        item_state <= #U_DLY IDLE;
    else    
        item_state <= #U_DLY item_nextstate;
end


always @ (*)begin
    case(item_state)
        IDLE:begin
            item_nextstate=ITEM_REQ;
        end

        ITEM_REQ:begin
            if(arb_witem_vld==1'b1)
                item_nextstate=ITEM_PROCESS;
            else
                item_nextstate=ITEM_REQ;
        end

        ITEM_PROCESS:begin
            if(chn_dma_done_det==1'b1)
                item_nextstate=IDLE;
            else
                item_nextstate=ITEM_PROCESS;
        end
        
        default:item_nextstate=IDLE;
    endcase
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        item_arb_req <= #U_DLY 1'b0;        
    else if(item_rst==1'b1 || chn_ena==1'b0)
        item_arb_req <= #U_DLY 1'b0;
    else if(arb_item_ack==1'b1)
        item_arb_req <= #U_DLY 1'b0;
    else if(item_state==IDLE && item_nextstate==ITEM_REQ)
        item_arb_req <= #U_DLY 1'b1;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        chn_dma_en <= #U_DLY 1'b0;       
    else if(item_rst==1'b1 || chn_ena==1'b0)
        chn_dma_en <= #U_DLY 1'b0;
    else if(chn_dma_done_det==1'b1)
        chn_dma_en <= #U_DLY 1'b0;
    else if(arb_witem_vld==1'b1)
        chn_dma_en <= #U_DLY 1'b1;
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        chn_dma_addr <= #U_DLY 'b0;        
    else if(arb_witem_vld==1'b1)   
        chn_dma_addr <= #U_DLY arb_item_data[0+:32];
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        chn_dma_len <= #U_DLY 'b0;         
    else if(arb_witem_vld==1'b1)
        case(cfg_max_payload)   
            3'b000:chn_dma_len <= #U_DLY arb_item_data[32+:24];       //TLP128BYTE
            3'b001:chn_dma_len <= #U_DLY {1'b0,arb_item_data[33+:23]};//TLP256BYTE
            3'b010:chn_dma_len <= #U_DLY {1'b0,arb_item_data[33+:23]};//TLP256BYTE
            default:chn_dma_len <= #U_DLY arb_item_data[32+:24];
        endcase
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        chn_dma_rev <= #U_DLY 'd0;        
    else if(arb_witem_vld==1'b1)  
        chn_dma_rev <= #U_DLY arb_item_data[64+:64]; 
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        chn_dma_addr_h <= #U_DLY 'd0;        
    else if(arb_witem_vld==1'b1)  
        chn_dma_addr_h <= #U_DLY arb_item_data[128+:32]; 
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            chn_dma_done_det <= #U_DLY 'b0;
        end       
    else 
        begin
            if(chn_dma_done==1'b1&& chn_dma_chn==CHN_INDEX)
                chn_dma_done_det <= #U_DLY 1'b1;
            else
                chn_dma_done_det <= #U_DLY 1'b0;
        end   
end


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
