// *********************************************************************************/
// Project Name :
// Author       : dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/11/30 11:01:19
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, boyulihua Co., Ltd.. 
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
module pcie_msi_engine_gen3 # (
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst_n,

//input                               int_release,
input                               wdma_int_dis,
input                               rdma_int_dis, 

input                               wchn_dma_done,
input                               rchn_dma_done,
input                               cfg_interrupt_msi_enable,
input                               cfg_interrupt_msi_sent,
input                               cfg_interrupt_msi_fail,
output  reg     [31:0]              cfg_interrupt_msi_int
//Debug Interface

);
// Parameter Define 

// Register Define 
reg [2:0]                           wchn_dma_done_r;
reg [2:0]                           rchn_dma_done_r;

//reg                                 int_lock;
reg                                 wdma_int_ind;
reg                                 rdma_int_ind;

// Wire Define 

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            cfg_interrupt_msi_int <= 32'd0;
            wchn_dma_done_r <= 'b0;
            rchn_dma_done_r <= 'b0;
            //int_lock <= 1'b0;
            wdma_int_ind <= 1'b0;
            rdma_int_ind <= 1'b0;
        end
    else    
        begin
            if(cfg_interrupt_msi_enable == 1'b1)
                begin
                    if(cfg_interrupt_msi_fail == 1'b1 || cfg_interrupt_msi_sent == 1'b1)
                        cfg_interrupt_msi_int <= #U_DLY 32'h0000_0000;
                    //else if((wdma_int_ind != {WCHN_NUM{1'b0}} || rdma_int_ind != {RCHN_NUM{1'b0}} || send_dma_wint_ind == 1'b1) && cfg_interrupt_msi_int == 32'h0000_0000 && int_lock == 1'b0)
                    else if((wdma_int_ind != 1'b0 || rdma_int_ind != 1'b0 ) && cfg_interrupt_msi_int == 32'h0000_0000 )
                        cfg_interrupt_msi_int <= #U_DLY 32'h0000_0001;
                end

            //if(cfg_interrupt_msi_int != 32'd0 && cfg_interrupt_msi_sent == 1'b1 && cfg_interrupt_msi_enable == 1'b1)
            //    int_lock <= #U_DLY 1'b1;
            //else if(int_release == 1'b1 || wdma_int_dis != 1'b0 || rdma_int_dis != 1'b0)
            //    int_lock <= #U_DLY 1'b0;
              
            if((cfg_interrupt_msi_int != 32'd0 && cfg_interrupt_msi_sent == 1'b1 && cfg_interrupt_msi_enable == 1'b1) || (wdma_int_dis == 1'b1))
                wdma_int_ind <= #U_DLY 1'b0;
            else if({wchn_dma_done_r[2],wchn_dma_done_r[1]} == 2'b01)
                wdma_int_ind <= #U_DLY 1'b1;
       

            if((cfg_interrupt_msi_int != 32'd0 && cfg_interrupt_msi_sent == 1'b1 && cfg_interrupt_msi_enable == 1'b1) || (rdma_int_dis == 1'b1) )
                rdma_int_ind <= #U_DLY 1'b0;
            else if({rchn_dma_done_r[2],rchn_dma_done_r[1]} == 2'b01)
                rdma_int_ind <= #U_DLY 1'b1;
  

            wchn_dma_done_r <= #U_DLY {wchn_dma_done_r[1:0],wchn_dma_done};
            rchn_dma_done_r <= #U_DLY {rchn_dma_done_r[1:0],rchn_dma_done};
        end
end


endmodule
