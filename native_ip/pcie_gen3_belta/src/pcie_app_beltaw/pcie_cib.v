// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/11/6 13:47:24
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
`define DMA_00 {fill[31:17],rdma_int_dis,fill[15:1],wdma_int_dis}  //0x0+0x400
`define DMA_01 {test}                                              //0x4+0x400
`define DMA_02 {fill[31:1],soft_rst}                               //0x8+0x400
`define DMA_05 {fill[31:17],rdma_stop,fill[15:1],wdma_stop}        //0x14+0x400 

`define DMA_0F {fill[31:11],cfg_current_speed_r2,fill[7:4],cfg_negotiated_width_r2}  //0x3c+0x400 
`define DMA_10 {fill[31:11],cfg_max_read_req_r2,fill[7:3],cfg_max_payload_r2}        //0x40+0x400 

`define DMA_12 {fill[31:25],rib_empty_r[1],fill[23:21],wdb_empty_r[1],fill[19:17],wib_empty_r[1],his_cfifo_overflow,fill[7:4],trabt_err_r[2],his_wdb_underflow,his_wib_overflow,his_wdb_overflow} //0x48 +0x400
`define DMA_13 {wchn_dvld_r2,rfifo_empty_r2,cfifo_empty_r2,fill[7:6],t_rchn_cur_st,fill[3:2],t_wchn_cur_st} //0x4C +0x400
`define DMA_14 {fill[31:18],his_rfifo_overflow,his_rfifo_underflow,fill[15:14],his_wchnindex_err,his_oritem_fifo_underflow,his_oritem_fifo_overflow,his_ritem_fifo_overflow,his_rg_fifo_overflow,his_owitem_fifo_underflow,his_owitem_fifo_overflow,his_witem_fifo_overflow,his_txfifo_abnormal,his_rc_fail,his_rc_err,his_err_type,his_err_len,his_err_bar} //0x50+0x400
`define DMA_18 {fill[31:1],witem_rst}
`define DMA_19 {fill[31:1],ritem_rst}
`define DMA_20 {wchn_ena[31:0]}
`define DMA_21 {wchn_ena[63:32]}
`define DMA_22 {wchn_ena[95:64]}

`define DMA_28 {band[31:0]}    //0xA0+0x400
`define DMA_29 {rx_band[31:0]}    //0xA4+0x400

//`define DMA_30 {fill[31:1],int_release}//0xc0+0x400

`define DMA_40 {built_in}                                //0x100 +0x400
`define DMA_41 {ds_static_pattern[31:0]}                 //0x104 +0x400
`define DMA_42 {ds_static_pattern[63:32]}                //0x108 +0x400
`define DMA_43 {fill[31:22],ds_tbucket_width[21:0]}  //0x10c +0x400
`define DMA_44 {ds_len_mode_count[31:0]}             //0x110 +0x400
`define DMA_45 {fill[31:1],check_st}                     //0x114 +0x400
`define DMA_46 {fill[31:3],ds_data_mode[2:0]}         //0x118 + 0x400
`define DMA_47 {fill[31:5],ds_tx_len_start,fill[3:1],ds_tx_con_start} //0x11c +0x400
`define DMA_48 {fill[31:22],ds_tbucket_deepth[21:0]}  //0x120 +0x400

`define DMA_80 {wchn_dma_en_cnt}          //0x200 +0x400
`define DMA_81 {wchn_dma_done_cnt}        //0x204 +0x400
`define DMA_82 {fill[31:2],rchn_st,wchn_st}       //0x208 +0x400
`define DMA_83 {rchn_cnt_r2}              //0x20C +0x400
`define DMA_84 {rchn_terr_r2[RCHN_NUM-1:0]}  //0x210 +0x400
`define DMA_85 {rchn_cnt_hr2}             //0x214 +0x400
`define DMA_86 {rchn_dma_done_cnt}        //0x218 +0x400
`define DMA_87 {fill[31:20],wt_time}      //0x21c +0x400
`define DMA_88 {witem_fifo_wcnt,witem_fifo_rcnt,owitem_fifo_wcnt,owitem_fifo_rcnt} //0x220 +0x400
`define DMA_89 {fill[31:16],oritem_fifo_wcnt,oritem_fifo_rcnt} //0x224 +0x400
`define DMA_8A {wchn_curr_index} //0x228 +0x400
`define DMA_8B {wchn_dma_en}  //0x22c +0x400
`define DMA_8C {rchn_dma_en}  //0x230 +0x400
`define DMA_8D {ritem_fifo_empty}
`define DMA_8E {rchn_dma_en_cnt}
`define DMA_8F {rg_fifo_rd_en_cnt}
`define DMA_90 {ritem_fifo_wr_en_cnt}
`define DMA_91 {ritem_fifo_rd_en_cnt}


`define DMA_A0 {witem_wdata0}             //0x280 +0x400
`define DMA_A1 {witem_wdata1}             //0x284 +0x400
`define DMA_A2 {witem_wdata2}             //0x288 +0x400 
`define DMA_A3 {witem_wdata3}             //0x28c +0x400
`define DMA_A4 {witem_wdata4}             //0x28c +0x400
`define DMA_A7 {fill[31:7],witem_fifo_prog_empty,witem_fifo_full,witem_fifo_empty,fill[3:1],witem_wr_det}  //0x29c +0x400

`define DMA_A8 {owitem_rdata0}            //0x2a0 +0x400
`define DMA_A9 {owitem_rdata1}            //0x2a4 +0x400
`define DMA_AA {owitem_rdata2}            //0x2a8 +0x400 
`define DMA_AB {owitem_rdata3}            //0x2ac +0x400
`define DMA_AC {owitem_rdata4}            //0x2ac +0x400
`define DMA_AF {fill[31:7],owitem_fifo_prog_empty,owitem_fifo_full,owitem_fifo_empty,fill[3:1],owitem_rd_det} //0x2bc +0x400


`define DMA_B0 {ritem_wdata0}             //0x2c0 +0x400 
`define DMA_B1 {ritem_wdata1}             //0x2c4 +0x400 
`define DMA_B2 {ritem_wdata2}             //0x2c8 +0x400 
`define DMA_B3 {ritem_wdata3}             //0x2cc +0x400
`define DMA_B4 {ritem_wdata4}             //0x2cc +0x400
`define DMA_B6 {ritem_fifo_prog_full[RCHN_NUM-1:0]}
`define DMA_B7 {fill[31:7],rg_fifo_prog_empty,rg_fifo_full,rg_fifo_empty,fill[3:1],rg_wr_det} //0x2dc +0x400

`define DMA_B8 {oritem_rdata0}            //0x2e0 +0x400
`define DMA_B9 {oritem_rdata1}            //0x2e4 +0x400
`define DMA_BA {oritem_rdata2}            //0x2e8 +0x400
`define DMA_BB {oritem_rdata3}            //0x2ec +0x400
`define DMA_BC {oritem_rdata4}            //0x2ec +0x400
`define DMA_BF {fill[31:7],oritem_fifo_prog_empty,oritem_fifo_full,oritem_fifo_empty,fill[3:1],oritem_rd_det}//0x2fc +0x400



`timescale 1 ns / 1 ns
module pcie_cib #(
parameter                           U_DLY          = 1,
parameter                           WCHN_NUM       = 60,            
parameter                           WCHN_NUM_W     = clog2b(WCHN_NUM),
parameter                           RCHN_NUM       = 4,            
parameter                           RCHN_NUM_W     = clog2b(RCHN_NUM),
parameter                           WPHY_NUM       = 4,
parameter                           WPHY_NUM_W     = clog2b(WPHY_NUM)

)
(
input                               clk,
input                               rst_n,
input                               cpu_cs,
input                               cpu_wr,
input                               cpu_rd,
input        [7:0]                  cpu_addr,
input        [31:0]                 cpu_wr_data,
output reg   [31:0]                 cpu_rd_data,

input        [32-1:0]               band,
input        [32-1:0]               rx_band,
output reg                          wdma_int_dis,//CIB_OUT
output reg                          rdma_int_dis,//CIB_OUT
//output reg                          int_release,//CIB_OUT
input                               rtc_us_flg,

//WDMA
output      [32*WCHN_NUM-1:0]       wchn_dma_addr,          
output      [32*WCHN_NUM-1:0]       wchn_dma_addr_h,          
output      [WCHN_NUM-1:0]          wchn_dma_en,           
output      [24*WCHN_NUM-1:0]       wchn_dma_len,
output      [64*WCHN_NUM-1:0]       wchn_dma_rev,
input                               wchn_len_done,
input       [WCHN_NUM_W-1:0]        wchn_len_chn,
output reg                          wdma_stop,

input                               wchn_dma_done, 
input                               wchn_dma_end,
input       [WCHN_NUM_W-1:0]        wchn_dma_chn,
input       [24-1:0]                wchn_dma_count, 
input       [32-1:0]                wchn_dma_daddr, 
input       [64-1:0]                wchn_dma_drev,
input       [32-1:0]                wchn_dma_daddr_h, 

//RDMA
output       [RCHN_NUM-1:0]         rchn_dma_en,//CIB_OUT
output       [32*RCHN_NUM-1:0]      rchn_dma_addr,//CIB_OUT
output       [32*RCHN_NUM-1:0]      rchn_dma_addr_h,//CIB_OUT
output       [24*RCHN_NUM-1:0]      rchn_dma_len,//CIB_OUT
output       [64*RCHN_NUM-1:0]      rchn_dma_rev,
output reg                          rdma_stop,//CIB_OUT

input                               rchn_dma_done, //CIB_IN
input        [RCHN_NUM_W-1:0]       rchn_dma_chn,
input        [32-1:0]               rchn_dma_daddr, 
input        [64-1:0]               rchn_dma_drev, 
input        [32-1:0]               rchn_dma_daddr_h, 


output reg   [9:0]                  wdma_tlp_size,//CIB_OUT
output reg   [9:0]                  rdma_tlp_size,//CIB_OUT

input        [3:0]                  cfg_negotiated_width,//CIB_IN
input        [2:0]                  cfg_current_speed,//CIB_IN
input        [2:0]                  cfg_max_payload,//CIB_IN
input        [2:0]                  cfg_max_read_req,//CIB_IN

output reg   [WPHY_NUM-1:0]         built_in,
output reg   [22-1:0]               ds_tbucket_width,  
output reg   [22-1:0]               ds_tbucket_deepth,
output reg   [3-1:0]                ds_data_mode,   
output reg   [63:0]                 ds_static_pattern,
output reg                          ds_tx_len_start, 
output reg                          ds_tx_con_start,
output reg   [32-1:0]               ds_len_mode_count,
output reg                          check_st,
output reg                          soft_rst,

input                               wdb_overflow,
input                               wib_overflow,
input                               wdb_underflow,
input        [8-1:0]                cfifo_overflow,
input        [8-1:0]                cfifo_empty,
input        [8-1:0]                wchn_dvld,
input        [1:0]                  t_wchn_cur_st,
input                               wchnindex_err,
input        [WCHN_NUM_W-1:0]       wchn_curr_index,
input                               wib_empty,
input                               wdb_empty,    
input                               rib_empty,

input                               err_type_l,
input                               err_bar_l,
input                               err_len_l,

input                               rc_is_err,
input                               rc_is_fail,

input        [RCHN_NUM-1:0]         rfifo_empty,
input                               txfifo_abnormal_rst,


output reg                          rchn_st,       
input        [31:0]                 rchn_cnt,     
input        [31:0]                 rchn_cnt_h, 
input        [RCHN_NUM-1:0]         rchn_terr,

input        [RCHN_NUM-1:0]         rfifo_overflow, 
input        [RCHN_NUM-1:0]         rfifo_underflow,
input        [1:0]                  t_rchn_cur_st,
input                               trabt_err  

     
);
// Parameter Define 

// Register Define 
reg     [3:0]                       cfg_negotiated_width_r1;
reg     [3:0]                       cfg_negotiated_width_r2;
reg     [2:0]                       cfg_current_speed_r1;
reg     [2:0]                       cfg_current_speed_r2;
reg     [2:0]                       cfg_max_payload_r1;
reg     [2:0]                       cfg_max_payload_r2;
reg     [2:0]                       cfg_max_read_req_r1;
reg     [2:0]                       cfg_max_read_req_r2;
reg     [7:0]                       cpu_raddr;
reg                                 cpu_rd_dly;
reg                                 cpu_wr_dly;
reg     [31:0]                      fill;
reg     [31:0]                      test;
reg                                 his_wdb_overflow;
reg                                 his_wib_overflow;
reg     [2:0]                       wdb_underflow_r;
reg                                 his_wdb_underflow;
reg     [4:0]                       wchn_dma_done_r;
reg     [WCHN_NUM_W-1:0]            wchn_dma_chn_r1;
reg     [WCHN_NUM_W-1:0]            wchn_dma_chn_r2;
reg                                 wchn_dma_end_r1;  
reg                                 wchn_dma_end_r2;  
reg     [31:0]                      wchn_dma_daddr_r1;
reg     [31:0]                      wchn_dma_daddr_r2;
reg     [31:0]                      wchn_dma_daddr_h_r1;
reg     [31:0]                      wchn_dma_daddr_h_r2;
reg     [23:0]                      wchn_dma_count_r1;
reg     [23:0]                      wchn_dma_count_r2;
reg     [63:0]                      wchn_dma_drev_r1;
reg     [63:0]                      wchn_dma_drev_r2;
reg                                 his_wchnindex_err;
reg     [31:0]                      rchn_dma_en_cnt;
reg     [95:0]                      wchn_ena;


reg                                 wchn_dma_done_det;
reg     [4:0]                       rchn_dma_done_r;
reg     [RCHN_NUM_W-1:0]            rchn_dma_chn_r1;
reg     [RCHN_NUM_W-1:0]            rchn_dma_chn_r2;
reg     [31:0]                      rchn_dma_daddr_r1;
reg     [31:0]                      rchn_dma_daddr_r2;
reg     [31:0]                      rchn_dma_daddr_h_r1;
reg     [31:0]                      rchn_dma_daddr_h_r2;
reg     [63:0]                      rchn_dma_drev_r1; 
reg     [63:0]                      rchn_dma_drev_r2; 
reg                                 rchn_dma_done_det;

reg     [8-1:0]                     cfifo_overflow_1dly; 
reg     [8-1:0]                     cfifo_overflow_2dly; 
reg     [8-1:0]                     his_cfifo_overflow;
reg                                 his_err_type;
reg                                 his_err_bar;
reg                                 his_err_len;
reg     [2:0]                       rc_is_err_r;
reg     [2:0]                       rc_is_fail_r;
reg                                 his_rc_err;
reg                                 his_rc_fail;
reg     [2:0]                       txfifo_abnormal_rst_r;
reg                                 his_txfifo_abnormal;
reg                                 witem_rst;
reg     [31:0]                      witem_wdata0;
reg     [31:0]                      witem_wdata1;
reg     [31:0]                      witem_wdata2;
reg     [31:0]                      witem_wdata3;
reg     [31:0]                      witem_wdata4;
reg                                 witem_wr_det;
reg                                 owitem_rd_det;
reg                                 his_witem_fifo_overflow;
reg                                 his_owitem_fifo_overflow;
reg                                 his_owitem_fifo_underflow;
reg                                 ritem_rst;
reg     [31:0]                      ritem_wdata0;
reg     [31:0]                      ritem_wdata1;
reg     [31:0]                      ritem_wdata2;
reg     [31:0]                      ritem_wdata3;
reg     [31:0]                      ritem_wdata4;
reg                                 rg_wr_det;
reg                                 oritem_rd_det;
reg                                 his_ritem_fifo_overflow;
reg                                 his_oritem_fifo_overflow;
reg                                 his_oritem_fifo_underflow;
reg                                 his_rg_fifo_overflow;

reg     [31:0]                      wchn_dma_en_cnt;
reg     [31:0]                      wchn_dma_done_cnt;
reg     [31:0]                      rchn_dma_done_cnt;

reg     [1:0]                       wib_empty_r;
reg     [1:0]                       wdb_empty_r;
reg     [1:0]                       rib_empty_r;

reg     [WPHY_NUM-1:0]              cfifo_empty_r1;
reg     [WPHY_NUM-1:0]              cfifo_empty_r2;
reg     [WPHY_NUM-1:0]              wchn_dvld_r1;
reg     [WPHY_NUM-1:0]              wchn_dvld_r2;

reg     [2:0]                       err_type_r;
reg     [2:0]                       err_bar_r;
reg     [2:0]                       err_len_r;

reg     [8-1:0]                     rfifo_empty_r1;
reg     [8-1:0]                     rfifo_empty_r2;

reg     [31:0]                      rchn_cnt_r1;
reg     [31:0]                      rchn_cnt_r2;
reg     [31:0]                      rchn_cnt_hr1;
reg     [31:0]                      rchn_cnt_hr2;
reg     [RCHN_NUM-1:0]              rchn_terr_r1;
reg     [RCHN_NUM-1:0]              rchn_terr_r2;
reg                                 rchn_st_r;
reg                                 wchn_st_r;

reg                                 his_rfifo_overflow;
reg                                 his_rfifo_underflow;

reg     [RCHN_NUM-1:0]              rfifo_underflow_1dly;
reg     [RCHN_NUM-1:0]              rfifo_underflow_2dly;
reg     [RCHN_NUM-1:0]              rfifo_underflow_det;

//reg     [8-1:0]                     cur_wdma_done;
//reg     [8-1:0]                     cur_wdma_end;
//reg     [8-1:0]                     cur_rdma_done;
reg                                 wchn_st;
reg     [2:0]                       trabt_err_r;
// Wire Define 
wire                                cpu_wr_det;
wire                                cpu_rd_det;
wire                                cpu_rd_st;
wire    [31:0]                      owitem_rdata0;
wire    [31:0]                      owitem_rdata1;
wire    [31:0]                      owitem_rdata2;
wire    [31:0]                      owitem_rdata3;
wire    [31:0]                      owitem_rdata4;
wire                                witem_fifo_full;
wire                                witem_fifo_empty;
wire                                witem_fifo_prog_empty;
wire                                witem_fifo_overflow;
wire                                owitem_fifo_full;
wire                                owitem_fifo_empty;
wire                                owitem_fifo_prog_empty;
wire                                owitem_fifo_overflow;
wire                                owitem_fifo_underflow;
wire    [RCHN_NUM-1:0]              ritem_fifo_full;       
wire    [RCHN_NUM-1:0]              ritem_fifo_prog_full;       
wire    [RCHN_NUM-1:0]              ritem_fifo_empty;      
wire    [RCHN_NUM-1:0]              ritem_fifo_prog_empty; 
wire                                ritem_fifo_overflow;   
wire                                oritem_fifo_full;      
wire                                oritem_fifo_empty;     
wire                                oritem_fifo_prog_empty;
wire                                oritem_fifo_overflow;  
wire                                oritem_fifo_underflow; 
wire    [31:0]                      oritem_rdata0;
wire    [31:0]                      oritem_rdata1;
wire    [31:0]                      oritem_rdata2;
wire    [31:0]                      oritem_rdata3;
wire    [31:0]                      oritem_rdata4;
wire    [RCHN_NUM-1:0]              ritem_arb_req;
wire    [RCHN_NUM-1:0]              arb_ritem_ack;
wire    [RCHN_NUM*160-1:0]          arb_ritem_data;
wire    [WCHN_NUM-1:0]              witem_arb_req;
wire    [WCHN_NUM-1:0]              arb_witem_ack;
wire    [WCHN_NUM-1:0]              arb_witem_vld;
wire    [159:0]                     arb_witem_data;
wire                                rg_fifo_full;
wire                                rg_fifo_empty;
wire                                rg_fifo_prog_empty;
wire                                rg_fifo_overflow;
wire    [19:0]                      wt_time;
wire    [7:0]                       witem_fifo_rcnt;
wire    [7:0]                       witem_fifo_wcnt;
wire    [7:0]                       owitem_fifo_rcnt;
wire    [7:0]                       owitem_fifo_wcnt;    
wire    [7:0]                       oritem_fifo_rcnt;
wire    [7:0]                       oritem_fifo_wcnt; 
wire    [31:0]                      rg_fifo_rd_en_cnt;
wire    [31:0]                      ritem_fifo_wr_en_cnt;
wire    [31:0]                      ritem_fifo_rd_en_cnt;



//-----------------------------------------------------------------------------------------------
//local bus logic
//-----------------------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
            cpu_wr_dly <= 1'b1;
            cpu_rd_dly <= 1'b1;
        end
    else
        begin
            cpu_wr_dly <= #U_DLY cpu_wr;
            cpu_rd_dly <= #U_DLY cpu_rd;
        end
end
assign cpu_wr_det = (cpu_wr==1'b0 && cpu_wr_dly==1'b1 && cpu_cs==1'b0)?1'b1:1'b0;
assign cpu_rd_det = (cpu_rd==1'b1 && cpu_rd_dly==1'b0 && cpu_cs==1'b0)?1'b1:1'b0;
assign cpu_rd_st =  (cpu_rd==1'b0 && cpu_rd_dly==1'b1 && cpu_cs==1'b0)?1'b1:1'b0;



always @(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        cpu_raddr <= 'd0;
    else if({cpu_rd,cpu_rd_dly} == 2'b01 && cpu_cs == 1'b0)   //read
        cpu_raddr <= #U_DLY cpu_addr;
end




always @(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        cpu_rd_data <= 'h1234_beef;
    else
    case(cpu_raddr)
    	8'h00:cpu_rd_data <= #U_DLY `DMA_00;
        8'h01:cpu_rd_data <= #U_DLY `DMA_01;
        8'h02:cpu_rd_data <= #U_DLY `DMA_02;
        8'h05:cpu_rd_data <= #U_DLY `DMA_05;
        8'h0F:cpu_rd_data <= #U_DLY `DMA_0F;
        8'h10:cpu_rd_data <= #U_DLY `DMA_10;
        8'h12:cpu_rd_data <= #U_DLY `DMA_12;
        8'h13:cpu_rd_data <= #U_DLY `DMA_13;
        8'h14:cpu_rd_data <= #U_DLY `DMA_14;
        8'h18:cpu_rd_data <= #U_DLY `DMA_18;
        8'h19:cpu_rd_data <= #U_DLY `DMA_19;
        8'h20:cpu_rd_data <= #U_DLY `DMA_20;
        8'h21:cpu_rd_data <= #U_DLY `DMA_21;
        8'h22:cpu_rd_data <= #U_DLY `DMA_22;
        8'h28:cpu_rd_data <= #U_DLY `DMA_28;
        8'h29:cpu_rd_data <= #U_DLY `DMA_29;
        //8'h30:cpu_rd_data <= #U_DLY `DMA_30;
        8'h40:cpu_rd_data <= #U_DLY `DMA_40;
        8'h41:cpu_rd_data <= #U_DLY `DMA_41;
        8'h42:cpu_rd_data <= #U_DLY `DMA_42;
        8'h43:cpu_rd_data <= #U_DLY `DMA_43;
        8'h44:cpu_rd_data <= #U_DLY `DMA_44;
        8'h45:cpu_rd_data <= #U_DLY `DMA_45;
        8'h46:cpu_rd_data <= #U_DLY `DMA_46;
        8'h47:cpu_rd_data <= #U_DLY `DMA_47;
        8'h48:cpu_rd_data <= #U_DLY `DMA_48;
        8'h80:cpu_rd_data <= #U_DLY `DMA_80;
        8'h81:cpu_rd_data <= #U_DLY `DMA_81;   			  
        8'h82:cpu_rd_data <= #U_DLY `DMA_82;
        8'h83:cpu_rd_data <= #U_DLY `DMA_83;
        8'h84:cpu_rd_data <= #U_DLY `DMA_84;
        8'h85:cpu_rd_data <= #U_DLY `DMA_85;
        8'h86:cpu_rd_data <= #U_DLY `DMA_86;       
        8'h87:cpu_rd_data <= #U_DLY `DMA_87;   
        8'h88:cpu_rd_data <= #U_DLY `DMA_88; 
        8'h89:cpu_rd_data <= #U_DLY `DMA_89; 
        8'h8A:cpu_rd_data <= #U_DLY `DMA_8A;   
        8'h8B:cpu_rd_data <= #U_DLY `DMA_8B; 
        8'h8C:cpu_rd_data <= #U_DLY `DMA_8C; 
        8'h8D:cpu_rd_data <= #U_DLY `DMA_8D; 
        8'h8E:cpu_rd_data <= #U_DLY `DMA_8E; 
        8'h8F:cpu_rd_data <= #U_DLY `DMA_8F; 
        8'h90:cpu_rd_data <= #U_DLY `DMA_90; 
        8'h91:cpu_rd_data <= #U_DLY `DMA_91; 
			  
        8'hA0:cpu_rd_data <= #U_DLY `DMA_A0;
        8'hA1:cpu_rd_data <= #U_DLY `DMA_A1;
        8'hA2:cpu_rd_data <= #U_DLY `DMA_A2;
        8'hA3:cpu_rd_data <= #U_DLY `DMA_A3;
        8'hA4:cpu_rd_data <= #U_DLY `DMA_A4;
        8'hA7:cpu_rd_data <= #U_DLY `DMA_A7;
        8'hA8:cpu_rd_data <= #U_DLY `DMA_A8;
        8'hA9:cpu_rd_data <= #U_DLY `DMA_A9;
        8'hAA:cpu_rd_data <= #U_DLY `DMA_AA;
        8'hAB:cpu_rd_data <= #U_DLY `DMA_AB;
        8'hAC:cpu_rd_data <= #U_DLY `DMA_AC;
        8'hAF:cpu_rd_data <= #U_DLY `DMA_AF;

        8'hB0:cpu_rd_data <= #U_DLY `DMA_B0;
        8'hB1:cpu_rd_data <= #U_DLY `DMA_B1;
        8'hB2:cpu_rd_data <= #U_DLY `DMA_B2;
        8'hB3:cpu_rd_data <= #U_DLY `DMA_B3;
        8'hB4:cpu_rd_data <= #U_DLY `DMA_B4;
        8'hB6:cpu_rd_data <= #U_DLY `DMA_B6;
        8'hB7:cpu_rd_data <= #U_DLY `DMA_B7;
        8'hB8:cpu_rd_data <= #U_DLY `DMA_B8;
        8'hB9:cpu_rd_data <= #U_DLY `DMA_B9;
        8'hBA:cpu_rd_data <= #U_DLY `DMA_BA;
        8'hBB:cpu_rd_data <= #U_DLY `DMA_BB;
        8'hBC:cpu_rd_data <= #U_DLY `DMA_BC;
        8'hBF:cpu_rd_data <= #U_DLY `DMA_BF;

        default:cpu_rd_data <= #U_DLY 32'h1234_beef;  	    	
    endcase
end





//  Write Moudle
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
        	`DMA_00 <= 32'd0;
            `DMA_01 <= 32'hbeef_beef;
            `DMA_02 <= 32'd0;
            `DMA_05 <= 32'd0;
            `DMA_20 <= 32'd0;
            `DMA_21 <= 32'd0;            
            `DMA_22 <= 32'd0;            
        
            `DMA_40 <= 32'd0;
            `DMA_41 <= 32'h5A5A_5A5A;
            `DMA_42 <= 32'h5A5A_5A5A;
            `DMA_43 <= {10'b0,22'd6442}; //6143MBytes/s   
            `DMA_44 <= 32'd0;   
            `DMA_45 <= 32'd0;  
            `DMA_46 <= {29'b0,3'd1};   
            `DMA_47 <= 3'd0;   
            `DMA_48 <= {10'b0,22'd8512}; //8117MBytes/s  
            `DMA_82 <= 32'h0; 
            //MDMA
            `DMA_A0 <= 32'd0;
            `DMA_A1 <= 32'd0;
            `DMA_A2 <= 32'd0;
            `DMA_A3 <= 32'd0;
            `DMA_A4 <= 32'd0;

            `DMA_B0 <= 32'd0;
            `DMA_B1 <= 32'd0;
            `DMA_B2 <= 32'd0;
            `DMA_B3 <= 32'd0;
            `DMA_B4 <= 32'd0;
            fill <= 32'd0;
        end
    else    
        begin
            if({cpu_wr,cpu_wr_dly} == 2'b01 && cpu_cs == 1'b0)
                begin
                    case(cpu_addr)
                    	8'h00:  `DMA_00 <= #U_DLY cpu_wr_data;
                        8'h01:  `DMA_01 <= #U_DLY cpu_wr_data;
                        8'h02:  `DMA_02 <= #U_DLY cpu_wr_data;
                        8'h05:  `DMA_05 <= #U_DLY cpu_wr_data;
                        8'h20:  `DMA_20 <= #U_DLY cpu_wr_data;
                        8'h21:  `DMA_21 <= #U_DLY cpu_wr_data;
                        8'h22:  `DMA_22 <= #U_DLY cpu_wr_data;
                                     
                        
                        8'h40:  `DMA_40 <= #U_DLY cpu_wr_data;
                        8'h41:  `DMA_41 <= #U_DLY cpu_wr_data;
                        8'h42:  `DMA_42 <= #U_DLY cpu_wr_data;
                        8'h43:  `DMA_43 <= #U_DLY cpu_wr_data;
                        8'h44:  `DMA_44 <= #U_DLY cpu_wr_data;
                        8'h45:  `DMA_45 <= #U_DLY cpu_wr_data;
                        8'h46:  `DMA_46 <= #U_DLY cpu_wr_data;
                        8'h47:  `DMA_47 <= #U_DLY cpu_wr_data;
                        8'h48:  `DMA_48 <= #U_DLY cpu_wr_data;
                        8'h82:  `DMA_82 <= #U_DLY cpu_wr_data;                      
                     
                        8'hA0:  `DMA_A0 <= #U_DLY cpu_wr_data;
                        8'hA1:  `DMA_A1 <= #U_DLY cpu_wr_data;
                        8'hA2:  `DMA_A2 <= #U_DLY cpu_wr_data;
                        8'hA3:  `DMA_A3 <= #U_DLY cpu_wr_data;
                        8'hA4:  `DMA_A4 <= #U_DLY cpu_wr_data;
                        8'hB0:  `DMA_B0 <= #U_DLY cpu_wr_data;
                        8'hB1:  `DMA_B1 <= #U_DLY cpu_wr_data;
                        8'hB2:  `DMA_B2 <= #U_DLY cpu_wr_data;
                        8'hB3:  `DMA_B3 <= #U_DLY cpu_wr_data;
                        8'hB4:  `DMA_B4 <= #U_DLY cpu_wr_data;
                        default:;
                    endcase
                end
            else
                fill <= #U_DLY 32'd0;
        end
end

//-----------------------------------------------------------------------------------------------
//PCIE CFG INFO
//-----------------------------------------------------------------------------------------------

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
        begin
    	    cfg_negotiated_width_r1 <= #U_DLY 'b0;
            cfg_negotiated_width_r2 <= #U_DLY 'b0;
            cfg_current_speed_r1    <= #U_DLY 'b0;
            cfg_current_speed_r2    <= #U_DLY 'b0;
            cfg_max_payload_r1      <= #U_DLY 'b0;
            cfg_max_payload_r2      <= #U_DLY 'b0;         
            cfg_max_read_req_r1     <= #U_DLY 'b0;
            cfg_max_read_req_r2     <= #U_DLY 'b0;                
        end
    else
        begin
    	    cfg_negotiated_width_r1 <= #U_DLY cfg_negotiated_width;
            cfg_negotiated_width_r2 <= #U_DLY cfg_negotiated_width_r1;
            cfg_current_speed_r1    <= #U_DLY cfg_current_speed;
            cfg_current_speed_r2    <= #U_DLY cfg_current_speed_r1;
            cfg_max_payload_r1      <= #U_DLY cfg_max_payload;
            cfg_max_payload_r2      <= #U_DLY cfg_max_payload_r1;         
            cfg_max_read_req_r1     <= #U_DLY cfg_max_read_req;
            cfg_max_read_req_r2     <= #U_DLY cfg_max_read_req_r1;                
        end
end

//===============================================================
//  WCHN DMA
//
//u_pcie_item_glb_w
//===============================================================
pcie_witem_glb # (
    .U_DLY                      (U_DLY                      ),
    .WCHN_NUM                   (WCHN_NUM                   ),
    .WCHN_NUM_W                 (WCHN_NUM_W                 )
)u_pcie_witem_glb
(   
    .clk                        (clk                        ),
    .rst                        (~rst_n                     ),
    .witem_rst                  (witem_rst                  ),
    .rtc_us_flg                 (rtc_us_flg                 ),
//
    .witem_wr_det               (witem_wr_det               ),
    .witem_wdata0               (witem_wdata0               ),
    .witem_wdata1               (witem_wdata1               ),
    .witem_wdata2               (witem_wdata2               ),
    .witem_wdata3               (witem_wdata3               ),
    .witem_wdata4               (witem_wdata4               ),

    .witem_arb_req              (witem_arb_req              ),
    .arb_witem_ack              (arb_witem_ack              ),
    .arb_witem_vld              (arb_witem_vld              ),
    .arb_witem_data             (arb_witem_data             ),

    .wchn_dma_done              (wchn_dma_done_det          ),
    .wchn_dma_end               (wchn_dma_end_r2            ),
    .wchn_dma_daddr             (wchn_dma_daddr_r2          ),
    .wchn_dma_daddr_h           (wchn_dma_daddr_h_r2        ),
    .wchn_dma_count             (wchn_dma_count_r2          ),
    .wchn_dma_chn               (wchn_dma_chn_r2            ),
    .wchn_dma_drev              (wchn_dma_drev_r2           ),

    .owitem_rd_det              (owitem_rd_det              ),
    .owitem_rdata0              (owitem_rdata0              ),
    .owitem_rdata1              (owitem_rdata1              ),
    .owitem_rdata2              (owitem_rdata2              ),
    .owitem_rdata3              (owitem_rdata3              ),
    .owitem_rdata4              (owitem_rdata4              ),

    .witem_fifo_full            (witem_fifo_full            ),
    .witem_fifo_empty           (witem_fifo_empty           ),
    .witem_fifo_prog_empty      (witem_fifo_prog_empty      ),
    .witem_fifo_overflow        (witem_fifo_overflow        ),
    .owitem_fifo_full           (owitem_fifo_full           ),
    .owitem_fifo_empty          (owitem_fifo_empty          ),
    .owitem_fifo_prog_empty     (owitem_fifo_prog_empty     ),
    .owitem_fifo_overflow       (owitem_fifo_overflow       ),
    .owitem_fifo_underflow      (owitem_fifo_underflow      ),
    .wt_time                    (wt_time                    ),
    .witem_fifo_rcnt            (witem_fifo_rcnt            ),
    .witem_fifo_wcnt            (witem_fifo_wcnt            ),
    .owitem_fifo_rcnt           (owitem_fifo_rcnt           ),
    .owitem_fifo_wcnt           (owitem_fifo_wcnt           )    
    
    
    
);

//===============================================================
//pcie_witem
//===============================================================
generate 
genvar m;
for(m=0;m<WCHN_NUM;m=m+1)
begin
pcie_item #(
    .U_DLY                     (U_DLY                       ),
    .CHN_NUM                   (WCHN_NUM                    ),
    .CHN_NUM_W                 (WCHN_NUM_W                  ),
    .CHN_INDEX                 (m                           )
)u_pcie_item_wchn
(
    .clk                       (clk                         ),
    .rst                       (~rst_n                      ),
    .item_rst                  (witem_rst                   ),
    .chn_ena                   (wchn_ena[m]                 ),
    .cfg_max_payload           (cfg_max_payload_r2          ),

    .item_arb_req              (witem_arb_req[m]            ),
    .arb_item_ack              (arb_witem_ack[m]            ),
    .arb_witem_vld             (arb_witem_vld[m]            ),
    .arb_item_data             (arb_witem_data              ),

    .chn_dma_en                (wchn_dma_en[m]              ),
    .chn_dma_addr              (wchn_dma_addr[32*m+:32]     ),
    .chn_dma_len               (wchn_dma_len[24*m+:24]      ),
    .chn_dma_rev               (wchn_dma_rev[64*m+:64]      ),
    .chn_dma_addr_h            (wchn_dma_addr_h[32*m+:32]   ),

    .chn_dma_done              (wchn_len_done               ),
    .chn_dma_chn               (wchn_len_chn                )

);
end
endgenerate

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        begin
            witem_rst <= #U_DLY 1'b0;
            witem_wr_det   <= #U_DLY 1'b0;
            owitem_rd_det <= #U_DLY 1'b0;
            wchn_dma_done_r   <= #U_DLY 'b0;
            wchn_dma_chn_r1   <= #U_DLY 'b0;
            wchn_dma_chn_r2   <= #U_DLY 'b0;
            wchn_dma_done_det <= #U_DLY 'b0;
            wchn_dma_end_r1   <= #U_DLY 'b0;    
            wchn_dma_daddr_r1 <= #U_DLY 'b0;
            wchn_dma_daddr_h_r1 <= #U_DLY 'b0;
            wchn_dma_count_r1 <= #U_DLY 'b0;
            wchn_dma_end_r2   <= #U_DLY 'b0;
            wchn_dma_daddr_r2 <= #U_DLY 'b0;
            wchn_dma_daddr_h_r2 <= #U_DLY 'b0;
            wchn_dma_count_r2 <= #U_DLY 'b0;
            wchn_dma_drev_r1 <= #U_DLY 'b0;
            wchn_dma_drev_r2 <= #U_DLY 'b0;
        end
    else   
        begin
            if(cpu_wr_dly==1'b0 && cpu_cs==1'b0 && cpu_addr==8'h18 && cpu_wr_data[0]==1'b1)
                witem_rst <= #U_DLY 1'b1;
            else
                witem_rst <= #U_DLY 1'b0;
            
            if(cpu_wr_det==1'b1 && cpu_addr==8'ha7 && cpu_wr_data[0]==1'b1)
                witem_wr_det <= #U_DLY 1'b1;
            else
                witem_wr_det <= #U_DLY 1'b0;
            
            if(cpu_wr_det==1'b1 && cpu_addr==8'haf && cpu_wr_data[0]==1'b1)
                owitem_rd_det <= #U_DLY 1'b1;
            else
                owitem_rd_det <= #U_DLY 1'b0;

            wchn_dma_done_r <= #U_DLY {wchn_dma_done_r[3:0],wchn_dma_done};

            wchn_dma_chn_r1 <= #U_DLY wchn_dma_chn;
            wchn_dma_chn_r2 <= #U_DLY wchn_dma_chn_r1;

            wchn_dma_end_r1   <= #U_DLY wchn_dma_end; 
            wchn_dma_end_r2   <= #U_DLY wchn_dma_end_r1;   
            wchn_dma_daddr_r1 <= #U_DLY wchn_dma_daddr;
            wchn_dma_daddr_r2 <= #U_DLY wchn_dma_daddr_r1;
            wchn_dma_daddr_h_r1 <= #U_DLY wchn_dma_daddr_h;
            wchn_dma_daddr_h_r2 <= #U_DLY wchn_dma_daddr_h_r1;
            wchn_dma_count_r1 <= #U_DLY wchn_dma_count;
            wchn_dma_count_r2 <= #U_DLY wchn_dma_count_r1;
            wchn_dma_drev_r1 <= #U_DLY wchn_dma_drev;
            wchn_dma_drev_r2 <= #U_DLY wchn_dma_drev_r1;

            if(wchn_dma_done_r[3]==1'b1 && wchn_dma_done_r[4]==1'b0 )
                wchn_dma_done_det <= #U_DLY 1'b1;
            else
                wchn_dma_done_det <= #U_DLY 1'b0;

        end
end

//===============================================================
//  RCHN DMA
//
//u_pcie_ritem_glb
//===============================================================
pcie_ritem_glb # (
    .U_DLY                      (U_DLY                      ),
    .RCHN_NUM                   (RCHN_NUM                   ),
    .RCHN_NUM_W                 (RCHN_NUM_W                 )
)u_pcie_ritem_glb
(   
    .clk                        (clk                        ),
    .rst                        (~rst_n                     ),
    .ritem_rst                  (ritem_rst                  ),
//
    .rg_wr_det                  (rg_wr_det                  ),
    .ritem_wdata0               (ritem_wdata0               ),
    .ritem_wdata1               (ritem_wdata1               ),
    .ritem_wdata2               (ritem_wdata2               ),
    .ritem_wdata3               (ritem_wdata3               ),
    .ritem_wdata4               (ritem_wdata4               ),

    .ritem_arb_req              (ritem_arb_req              ),
    .arb_ritem_ack              (arb_ritem_ack              ),
    .arb_ritem_data             (arb_ritem_data             ),


    .rchn_dma_done              (rchn_dma_done_det          ),
    .rchn_dma_daddr             (rchn_dma_daddr_r2          ),
    .rchn_dma_drev              (rchn_dma_drev_r2           ),
    .rchn_dma_chn               (rchn_dma_chn_r2            ),
    .rchn_dma_daddr_h           (rchn_dma_daddr_h_r2        ),

    .oritem_rd_det              (oritem_rd_det              ),
    .oritem_rdata0              (oritem_rdata0              ),
    .oritem_rdata1              (oritem_rdata1              ),
    .oritem_rdata2              (oritem_rdata2              ),
    .oritem_rdata3              (oritem_rdata3              ),
    .oritem_rdata4              (oritem_rdata4              ),

    .rg_fifo_full               (rg_fifo_full               ),
    .rg_fifo_empty              (rg_fifo_empty              ),
    .rg_fifo_prog_empty         (rg_fifo_prog_empty         ),
    .rg_fifo_overflow           (rg_fifo_overflow           ),


    .ritem_fifo_full            (ritem_fifo_full            ),
    .ritem_fifo_prog_full       (ritem_fifo_prog_full       ),
    .ritem_fifo_empty           (ritem_fifo_empty           ),
    .ritem_fifo_prog_empty      (ritem_fifo_prog_empty      ),
    .ritem_fifo_overflow        (ritem_fifo_overflow        ),
    .oritem_fifo_full           (oritem_fifo_full           ),
    .oritem_fifo_empty          (oritem_fifo_empty          ),
    .oritem_fifo_prog_empty     (oritem_fifo_prog_empty     ),
    .oritem_fifo_overflow       (oritem_fifo_overflow       ),
    .oritem_fifo_underflow      (oritem_fifo_underflow      ),
    .oritem_fifo_rcnt           (oritem_fifo_rcnt           ),
    .oritem_fifo_wcnt           (oritem_fifo_wcnt           ),
    .rg_fifo_rd_en_cnt          (rg_fifo_rd_en_cnt          ),
    .ritem_fifo_wr_en_cnt       (ritem_fifo_wr_en_cnt       ),
    .ritem_fifo_rd_en_cnt       (ritem_fifo_rd_en_cnt       )
);



//===============================================================
//u_pcie_item_r
//===============================================================
generate 
genvar n;
for(n=0;n<RCHN_NUM;n=n+1)
begin
pcie_item #(
    .U_DLY                      (U_DLY                      ),
    .CHN_NUM                    (RCHN_NUM                   ),
    .CHN_NUM_W                  (RCHN_NUM_W                 ),
    .CHN_INDEX                  (n                          )
)u_pcie_item_rchn
(
    .clk                        (clk                        ),
    .rst                        (~rst_n                     ),
    .item_rst                   (ritem_rst                  ),
    .chn_ena                    (1'b1                       ),
    .cfg_max_payload            (cfg_max_payload_r2         ),

    .item_arb_req               (ritem_arb_req[n]           ),
    .arb_item_ack               (arb_ritem_ack[n]           ),
    .arb_witem_vld              (arb_ritem_ack[n]           ),
    .arb_item_data              (arb_ritem_data[160*n+:160] ),

    .chn_dma_en                 (rchn_dma_en[n]             ),
    .chn_dma_addr               (rchn_dma_addr[32*n+:32]    ),
    .chn_dma_len                (rchn_dma_len[24*n+:24]     ),
    .chn_dma_rev                (rchn_dma_rev[64*n+:64]     ),
    .chn_dma_addr_h             (rchn_dma_addr_h[32*n+:32]  ),

    .chn_dma_done               (rchn_dma_done_det          ),
    .chn_dma_chn                (rchn_dma_chn_r2            )

);

end
endgenerate
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        begin
            ritem_rst <= #U_DLY 1'b0;
            rg_wr_det   <= #U_DLY 1'b0;
            oritem_rd_det <= #U_DLY 1'b0;
            rchn_dma_done_r   <= #U_DLY 'b0;
            rchn_dma_chn_r1   <= #U_DLY 'b0;
            rchn_dma_chn_r2   <= #U_DLY 'b0;
            rchn_dma_done_det <= #U_DLY 'b0;
            rchn_dma_daddr_r1 <= #U_DLY 'b0;
            rchn_dma_daddr_r2 <= #U_DLY 'b0;
            rchn_dma_daddr_h_r1 <= #U_DLY 'b0;
            rchn_dma_daddr_h_r2 <= #U_DLY 'b0;
            rchn_dma_drev_r1  <= #U_DLY 'b0;
            rchn_dma_drev_r2  <= #U_DLY 'b0;
            
        end
    else   
        begin
            if(cpu_wr_dly==1'b0 && cpu_cs==1'b0 && cpu_addr==8'h19 && cpu_wr_data[0]==1'b1)
                ritem_rst <= #U_DLY 1'b1;
            else
                ritem_rst <= #U_DLY 1'b0;

            if(cpu_wr_det==1'b1 && cpu_addr==8'hb7 && cpu_wr_data[0]==1'b1)
                rg_wr_det <= #U_DLY 1'b1;
            else
                rg_wr_det <= #U_DLY 1'b0;
            
            if(cpu_wr_det==1'b1 && cpu_addr==8'hbf && cpu_wr_data[0]==1'b1)
                oritem_rd_det <= #U_DLY 1'b1;
            else
                oritem_rd_det <= #U_DLY 1'b0;

            rchn_dma_done_r <= #U_DLY {rchn_dma_done_r[3:0],rchn_dma_done};
            rchn_dma_chn_r1 <= #U_DLY rchn_dma_chn;
            rchn_dma_chn_r2 <= #U_DLY rchn_dma_chn_r1;

            if(rchn_dma_done_r[3]==1'b1 && rchn_dma_done_r[4]==1'b0)
                rchn_dma_done_det <= #U_DLY 1'b1;
            else
                rchn_dma_done_det <= #U_DLY 1'b0;

            rchn_dma_daddr_r1 <= #U_DLY rchn_dma_daddr;
            rchn_dma_daddr_r2 <= #U_DLY rchn_dma_daddr_r1;
            rchn_dma_daddr_h_r1 <= #U_DLY rchn_dma_daddr_h;
            rchn_dma_daddr_h_r2 <= #U_DLY rchn_dma_daddr_h_r1;
            rchn_dma_drev_r1  <= #U_DLY rchn_dma_drev;
            rchn_dma_drev_r2  <= #U_DLY rchn_dma_drev_r1;
        end
end
//===============================================================
//item fifo status 
//===============================================================
always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        begin
            his_witem_fifo_overflow <= #U_DLY 1'b0;
            his_owitem_fifo_overflow <= #U_DLY 1'b0;
            his_owitem_fifo_underflow <= #U_DLY 1'b0;
            his_ritem_fifo_overflow <= #U_DLY 1'b0;
            his_oritem_fifo_overflow <= #U_DLY 1'b0;
            his_oritem_fifo_underflow <= #U_DLY 1'b0;
            his_rg_fifo_overflow <= #U_DLY 1'b0;
           
        end
    else
        begin
            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_witem_fifo_overflow <= #U_DLY witem_fifo_overflow;
            else if(witem_fifo_overflow==1'b1)
                his_witem_fifo_overflow <= #U_DLY 1'b1;

            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_owitem_fifo_overflow <= #U_DLY owitem_fifo_overflow;
            else if(witem_fifo_overflow==1'b1)
                his_owitem_fifo_overflow <= #U_DLY 1'b1;

            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_owitem_fifo_underflow <= #U_DLY owitem_fifo_underflow;
            else if(owitem_fifo_underflow==1'b1)
                his_owitem_fifo_underflow <= #U_DLY 1'b1;

            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_ritem_fifo_overflow <= #U_DLY ritem_fifo_overflow;
            else if(ritem_fifo_overflow==1'b1)
                his_ritem_fifo_overflow <= #U_DLY 1'b1;

            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_oritem_fifo_overflow <= #U_DLY oritem_fifo_overflow;
            else if(oritem_fifo_overflow==1'b1)
                his_oritem_fifo_overflow <= #U_DLY 1'b1;

            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_oritem_fifo_underflow <= #U_DLY oritem_fifo_underflow;
            else if(oritem_fifo_underflow==1'b1)
                his_oritem_fifo_underflow <= #U_DLY 1'b1;


            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_rg_fifo_overflow <= #U_DLY rg_fifo_overflow;
            else if(rg_fifo_overflow==1'b1)
                his_rg_fifo_overflow <= #U_DLY 1'b1;


        end
end
//===============================================================
//
//===============================================================

always @ (posedge clk or negedge rst_n) begin:DMA_REF_PRO
    if(rst_n == 1'b0)     
        begin
            //int_release <= 1'b0;
            wdma_tlp_size <= 'd128;
            rdma_tlp_size <= 'd128;
        end
    else    
        begin
            case(cfg_max_payload_r2)
                3'b000:wdma_tlp_size <= #U_DLY 10'd128;  //128BYTE
                3'b001:wdma_tlp_size <= #U_DLY 10'd256;  //256BYTE
                3'b010:wdma_tlp_size <= #U_DLY 10'd256;  //512BYTE
                //3'b011:wdma_tlp_size <= #U_DLY 10'd1024;  //1024BYTE           
                default:wdma_tlp_size <= #U_DLY 10'd128;
            endcase

            case(cfg_max_payload_r2)
                3'b000:rdma_tlp_size <= #U_DLY 10'd128;  //128BYTE
                3'b001:rdma_tlp_size <= #U_DLY 10'd256;  //256BYTE
                3'b010:rdma_tlp_size <= #U_DLY 10'd256;  //512BYTE
                //3'b011:rdma_tlp_size <= #U_DLY 10'd1024;  //1024BYTE            
                default:rdma_tlp_size <= #U_DLY 10'd128;
            endcase

            //if(int_release == 1'b1)
            //    int_release <= #U_DLY 1'b0;
            //else if(cpu_wr_det == 1'b1 && cpu_addr == 8'h30)
            //    int_release <= #U_DLY cpu_wr_data[0];
            //else;

            
        end
end



always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        his_wdb_overflow <= #U_DLY 1'b0;        
    else if(cpu_rd_det==1'b1 && cpu_addr==8'h12) 
        his_wdb_overflow <= #U_DLY wdb_overflow;
    else if(wdb_overflow==1'b1)
        his_wdb_overflow <= #U_DLY 1'b1;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        his_wib_overflow <= #U_DLY 1'b0;        
    else if(cpu_rd_det==1'b1 && cpu_addr==8'h12) 
        his_wib_overflow <= #U_DLY wib_overflow;
    else if(wib_overflow==1'b1)
        his_wib_overflow <= #U_DLY 1'b1;
end


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        wdb_underflow_r <= #U_DLY 1'b0;        
    else    
        wdb_underflow_r <= #U_DLY {wdb_underflow_r[1:0],wdb_underflow};
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        his_wdb_underflow <= #U_DLY 1'b0;        
    else if(cpu_rd_det==1'b1 && cpu_addr==8'h12)   
        his_wdb_underflow <= #U_DLY wdb_underflow_r[2];
    else if(wdb_underflow_r[1]==1'b1 && wdb_underflow_r[2]==1'b0)
        his_wdb_underflow <= #U_DLY 1'b1;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)    
    	  begin 
            cfifo_overflow_1dly <= #U_DLY 'b0;
            cfifo_overflow_2dly <= #U_DLY 'b0;
        end        
    else    
    	  begin
            cfifo_overflow_1dly <= #U_DLY cfifo_overflow;
            cfifo_overflow_2dly <= #U_DLY cfifo_overflow_1dly;
        end
end

always @ (posedge clk or negedge rst_n)begin:CFIFO_OVERFLOW_PRO
	 integer i;
    if(rst_n == 1'b0)     
        his_cfifo_overflow <= #U_DLY 'b0;        
    else 
    for(i=0;i<8;i=i+1)
       begin
           if(cpu_rd_det==1'b1 && cpu_addr==8'h12)   
               his_cfifo_overflow[i] <= #U_DLY cfifo_overflow_2dly[i];
           else if(cfifo_overflow_1dly[i]==1'b1 && cfifo_overflow_2dly[i]==1'b0)
               his_cfifo_overflow[i] <= #U_DLY 1'b1;
       end
end

always @ (posedge clk or negedge rst_n)begin
	   if(rst_n==1'b0)
	       wchn_dma_en_cnt <= #U_DLY 'b0;
	   else if(wchn_st==1'b1 && wchn_st_r==1'b0)
	   	   wchn_dma_en_cnt <= #U_DLY 'b0;   
	   else if(witem_wr_det == 1'b1)
	   	   wchn_dma_en_cnt <= #U_DLY wchn_dma_en_cnt + 'b1;   
end

always @ (posedge clk or negedge rst_n)begin
	   if(rst_n==1'b0)
	       wchn_dma_done_cnt <= #U_DLY 'b0;
	   else if(wchn_st==1'b1 && wchn_st_r==1'b0)
	   	   wchn_dma_done_cnt <= #U_DLY 'b0;   	       
	   else if(wchn_dma_done_det == 1'b1)
	   	   wchn_dma_done_cnt <= #U_DLY wchn_dma_done_cnt + 'b1;   
end                

always @ (posedge clk or negedge rst_n)begin
	   if(rst_n==1'b0)
	       wchn_st_r <= #U_DLY 1'b0;
	   else 
	   	   wchn_st_r <= #U_DLY wchn_st;   
end 



always @ (posedge clk or negedge rst_n)begin
	   if(rst_n==1'b0)
	       rchn_st_r <= #U_DLY 1'b0;
	   else 
	   	   rchn_st_r <= #U_DLY rchn_st;   
end 

always @ (posedge clk or negedge rst_n)begin
	   if(rst_n==1'b0)
	       rchn_dma_done_cnt <= #U_DLY 'b0;
	   else if(rchn_st==1'b1 && rchn_st_r==1'b0)
	   	   rchn_dma_done_cnt <= #U_DLY 'b0;
	   else if(rchn_dma_done_r[3] == 1'b1 && rchn_dma_done_r[4] == 1'b0)
	   	   rchn_dma_done_cnt <= #U_DLY rchn_dma_done_cnt + 'b1;   
end   

always @ (posedge clk or negedge rst_n)begin
	   if(rst_n==1'b0)
	   	   begin
             wib_empty_r <= #U_DLY 'b0;
             wdb_empty_r <= #U_DLY 'b0; 	   	   	
	   	   	   rib_empty_r <= #U_DLY 'b0;
	   	   end	       
	   else 
	   	   begin
             wib_empty_r <= #U_DLY {wib_empty_r[0],wib_empty};
             wdb_empty_r <= #U_DLY {wdb_empty_r[0],wdb_empty}; 	   	   	
	   	   	 rib_empty_r <= #U_DLY {rib_empty_r[0],rib_empty};	   	   	   	   	
	   	   end   
end                

always @ (posedge clk or negedge rst_n)begin
	   if(rst_n==1'b0)
	   	   begin
             cfifo_empty_r1 <= #U_DLY 8'b1111_1111;
             cfifo_empty_r2 <= #U_DLY 8'b1111_1111; 	 
             wchn_dvld_r1 <= #U_DLY 'b0;    
             wchn_dvld_r2 <= #U_DLY 'b0;     
	   	   end	       
	   else 
	   	   begin
             cfifo_empty_r1 <= #U_DLY cfifo_empty;
             cfifo_empty_r2 <= #U_DLY cfifo_empty_r1; 	
             wchn_dvld_r1 <= #U_DLY wchn_dvld;    
             wchn_dvld_r2 <= #U_DLY wchn_dvld_r1;     
	   	   end   
end           


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            err_type_r <= #U_DLY 'b0; 
            err_bar_r  <= #U_DLY 'b0;
            err_len_r  <= #U_DLY 'b0;
        end
    else
        begin
            err_type_r <= #U_DLY {err_type_r[1:0],err_type_l}; 
            err_bar_r  <= #U_DLY {err_bar_r[1:0],err_bar_l};
            err_len_r  <= #U_DLY {err_len_r[1:0],err_len_l};
        end
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        begin     
            his_err_type <= #U_DLY 1'b0;
            his_err_bar  <= #U_DLY 1'b0;
            his_err_len  <= #U_DLY 1'b0; 
        end  
    else
        begin      
            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)   
                his_err_type <= #U_DLY err_type_r[2];
            else if(err_type_r[1]==1'b1 && err_type_r[2]==1'b0)
                his_err_type <= #U_DLY 1'b1;

            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)   
                his_err_bar <= #U_DLY err_bar_r[2];
            else if(err_bar_r[1]==1'b1 && err_bar_r[2]==1'b0)
                his_err_bar <= #U_DLY 1'b1;

            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)   
                his_err_len <= #U_DLY err_len_r[2];
            else if(err_len_r[1]==1'b1 && err_len_r[2]==1'b0)
                his_err_len <= #U_DLY 1'b1;

        end
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        begin
            rc_is_err_r  <= #U_DLY 'b0;
            rc_is_fail_r <= #U_DLY 'b0;
            txfifo_abnormal_rst_r <= #U_DLY 'b0;
        end       
    else    
        begin
            rc_is_err_r  <= #U_DLY {rc_is_err_r[1:0],rc_is_err};
            rc_is_fail_r <= #U_DLY {rc_is_fail_r[1:0],rc_is_fail};
            txfifo_abnormal_rst_r <= #U_DLY {txfifo_abnormal_rst_r[1:0],txfifo_abnormal_rst};
        end
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        begin
            his_rc_err <= #U_DLY 1'b0;
            his_rc_fail <= #U_DLY 1'b0;
            his_txfifo_abnormal <= #U_DLY 1'b0;
        end       
    else    
        begin
            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_rc_err <= #U_DLY rc_is_err_r[2];
            else if(rc_is_err_r[1]==1'b1 && rc_is_err_r[2]==1'b0)
                his_rc_err <= #U_DLY 1'b1;
            
            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_rc_fail <= #U_DLY rc_is_fail_r[2];
            else if(rc_is_fail_r[1]==1'b1 && rc_is_fail_r[2]==1'b0)
                his_rc_fail <= #U_DLY 1'b1;
            
            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_txfifo_abnormal <= #U_DLY txfifo_abnormal_rst_r[2];
            else if(txfifo_abnormal_rst_r[1]==1'b1 && txfifo_abnormal_rst_r[2]==1'b0)
                his_txfifo_abnormal <= #U_DLY 1'b1;
        end
end




always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0) 
    	  begin
    	  	  rfifo_empty_r1 <= #U_DLY 8'b1111_1111;
    	  	  rfifo_empty_r2 <= #U_DLY 8'b1111_1111;
    	  end    
    else
    	  begin
    	  	  rfifo_empty_r1 <= #U_DLY rfifo_empty;
    	  	  rfifo_empty_r2 <= #U_DLY rfifo_empty_r1;    	  	   	  	
    	  end  	
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0) 
    	  begin
    	  	  rchn_cnt_r1 <= #U_DLY 'b0;
    	  	  rchn_cnt_r2 <= #U_DLY 'b0;
    	  	  rchn_cnt_hr1 <= #U_DLY 'b0;
    	  	  rchn_cnt_hr2 <= #U_DLY 'b0;    	  	  
    	  	  rchn_terr_r1 <= #U_DLY 1'b0;
    	  	  rchn_terr_r2 <= #U_DLY 1'b0;
              rchn_dma_en_cnt <= #U_DLY 'b0;
    	  end    
    else
    	  begin
    	  	  rchn_cnt_r1 <= #U_DLY rchn_cnt;
    	  	  rchn_cnt_r2 <= #U_DLY rchn_cnt_r1;
    	  	  rchn_cnt_hr1 <= #U_DLY rchn_cnt_h;
    	  	  rchn_cnt_hr2 <= #U_DLY rchn_cnt_hr1;       	  	     	  	  
    	  	  rchn_terr_r1 <= #U_DLY rchn_terr;
    	  	  rchn_terr_r2 <= #U_DLY rchn_terr_r1;
              if(rchn_st==1'b1 && rchn_st_r==1'b0) 
                  rchn_dma_en_cnt <= #U_DLY 'd0;
              else if(rg_wr_det==1'b1)
                  rchn_dma_en_cnt <= #U_DLY rchn_dma_en_cnt + 'd1;

    	  end  	
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        begin
            his_rfifo_overflow <= #U_DLY 1'b0;
            his_rfifo_underflow <= #U_DLY 1'b0;
        end       
    else    
        begin
            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_rfifo_overflow <= #U_DLY |rfifo_overflow;
            else if(|rfifo_overflow==1'b1)
                his_rfifo_overflow <= #U_DLY 1'b1;
                
            if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                his_rfifo_underflow <= #U_DLY |rfifo_underflow_det ;
            else if(|rfifo_underflow_det==1'b1)
                his_rfifo_underflow <= #U_DLY 1'b1;                   
        end
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        begin
            rfifo_underflow_1dly <= #U_DLY 'b0;
            rfifo_underflow_2dly <= #U_DLY 'b0;
            rfifo_underflow_det  <= #U_DLY 'b0;
        end       
    else
        begin:HIS_RFIFO_UNDERFLOW
            integer i;
            rfifo_underflow_1dly <= #U_DLY rfifo_underflow;
            rfifo_underflow_2dly <= #U_DLY rfifo_underflow_1dly;
           
            for(i=0;i<RCHN_NUM;i=i+1)
        	  begin           
                  if(rfifo_underflow_1dly[i]==1'b1 && ~rfifo_underflow_2dly[i]==1'b0)
                      rfifo_underflow_det[i] <= #U_DLY 1'b1;
                  else
                      rfifo_underflow_det[i] <= #U_DLY 1'b0;
              end
        end       
end    	  


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        trabt_err_r <= #U_DLY 8'b0;
    else
        trabt_err_r <= #U_DLY {trabt_err_r[1:0],trabt_err}; 
end   


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)   
        his_wchnindex_err <= #U_DLY 1'b0;        
    else if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
        his_wchnindex_err <= #U_DLY wchnindex_err;
    else if(wchnindex_err==1'b1)
        his_wchnindex_err <= #U_DLY 1'b1;
end



//(* syn_keep = "true", mark_debug = "true" *)
//(* syn_keep = "true", mark_debug = "true" *)



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
