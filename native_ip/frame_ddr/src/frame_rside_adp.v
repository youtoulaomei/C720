// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/5/16 14:43:43
// File Name    : frame_rside_adp.v
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
module frame_rside_adp #(
parameter                           U_DLY = 1,
parameter                           USER_NUM_W = 3,
parameter                           DATA_W = 512,                                    //bit
parameter                           FRAME_LEN_W = 14,                                //base on byte,the max value are 16K bytes
parameter                           RESERVED_INFO_W = 8,

parameter                           DDR_ADDR_W = 26,
parameter                           DDR_BURST_MAX = 64,                              //time slot,one slot value are DATA_W bits
parameter                           DDR_FRAME_ADDR_LOW_W = 8,

parameter                           DDR_FRAME_ADDR_HGIH_W = DDR_ADDR_W - USER_NUM_W - DDR_FRAME_ADDR_LOW_W
)
(
input                               clk,
input                               rst,
//frame_interface
input                               f_out_clk,
input                               f_out_rst,
output  wire    [DATA_W - 1:0]      f_out_data,
output  reg                         f_out_vld,
input                               f_out_rdy,
output  reg                         f_out_sof,
output  reg                         f_out_eof,
output  reg     [FRAME_LEN_W - 1:0] f_out_len,                                        //base on byte
output  reg     [RESERVED_INFO_W - 1:0]f_out_rsvd_info,                               //reserved infomation
//interface with DDR_Arbiter
output  wire    [DDR_ADDR_W - 1:0]  r_user_addr,
output  wire    [2:0]               r_user_cmd,                                      //001:read; 000:write                                   
output  reg                         r_user_en,
input                               r_user_done,

input           [DATA_W - 1:0]      r_user_rdata,
input                               r_user_rvld,
//interface with frame_info_fifo
input           [DDR_FRAME_ADDR_HGIH_W - 1:0]frame_ififo_raddr,
input                               frame_ififo_empty,
output  reg                         frame_ififo_ren,
input           [(FRAME_LEN_W+RESERVED_INFO_W+DDR_FRAME_ADDR_LOW_W) - 1:0] frame_ififo_rdata,   //{reserved_info,frame_len,user_addr_low(slot_length)}
//others
input           [USER_NUM_W - 1:0]  user_id,
input                               ddr_init_done,
//cib
output  reg                         frag_ififo_full,
output  reg                         frag_ififo_empty,
output  reg                         data_o_slotcnt_ind,
output  reg                         data_o_framecnt_ind,
output  reg                         data_trans_fifo_full,
output  reg                         pktinfo_fifo_full,
output  reg                         fout_rdy,
output  wire    [31:0]              cmd_data_checkcnt
);
// Parameter Define 
function integer clogb2;
input [31:0] value;
begin
value = value - 1;
for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1)
value = value >> 1;
end
endfunction

localparam                          PKTINFO_ADDR_W = 9;                               //512bit depth,use 1 M36K
localparam                          PKTINFO_DEPTH = 2**PKTINFO_ADDR_W;
localparam                          FRAG_IFIFO_DEPTH = 16;                            //adapter fifo storage 16 frags
localparam                          FRAG_IFIFO_DEPTH_W = clogb2(FRAG_IFIFO_DEPTH);
localparam                          FRAG_RAM_ADDR_LOW_W = clogb2(DDR_BURST_MAX);
localparam                          DATA_TRANS_FIFO_ADDR_W = 9;                       //72bit width and 512 deepth will use one M36K block.so 512bit width will use 7.5 M36K(s)
localparam                          DATA_TRANS_FIFO_DEPTH = 2**DATA_TRANS_FIFO_ADDR_W;
// Register Define 
reg     [2:0]                       frame_ififo_ren_dly;
reg     [DDR_FRAME_ADDR_HGIH_W - 1:0]r_user_addr_high;
reg     [DDR_FRAME_ADDR_LOW_W:0]    cmd_slot_cnt;
reg     [FRAG_RAM_ADDR_LOW_W - 1:0] cmd_frag_slot_cnt;
reg                                 cmd_frag_ind;
reg     [DDR_FRAME_ADDR_LOW_W - 1:0]r_user_addr_low;
reg     [FRAG_RAM_ADDR_LOW_W -1:0]  frag_ram_waddr_low;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ram_waddr_high;
reg     [DATA_W - 1:0]              frag_data_ram[FRAG_IFIFO_DEPTH*DDR_BURST_MAX-1:0]/* synthesis syn_ramstyle="block_ram" */;
reg     [DATA_W - 1:0]              frag_ram_rdata_pre;
reg     [DATA_W - 1:0]              frag_ram_rdata;
reg     [FRAG_RAM_ADDR_LOW_W+FRAME_LEN_W+RESERVED_INFO_W+1:0]frag_ififo[FRAG_IFIFO_DEPTH-1:0]/* synthesis syn_ramstyle="block_ram" */;
reg     [FRAG_RAM_ADDR_LOW_W+FRAME_LEN_W+RESERVED_INFO_W+1:0]frag_ififo_rdata_pre;
reg     [FRAG_RAM_ADDR_LOW_W+FRAME_LEN_W+RESERVED_INFO_W+1:0]frag_ififo_rdata;
reg                                 frag_ififo_wen;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_waddr;
reg     [FRAG_RAM_ADDR_LOW_W+FRAME_LEN_W+RESERVED_INFO_W-1:0]frag_ififo_wdata_pre;
reg                                 frag_ififo_ren;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_raddr;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_raddr_latch;
reg     [1:0]                       frag_ififo_ren_dly;
reg                                 frag_r_eof;
reg     [FRAG_RAM_ADDR_LOW_W - 1:0] frag_r_last_addr;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_raddr_b2g;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_waddr_b2g_1dly;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_waddr_b2g_2dly;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_waddr_g2b;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_waddr_b2g;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_raddr_b2g_1dly;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_raddr_b2g_2dly;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_raddr_g2b;
reg                                 frag_ram_ren_pre;
reg     [FRAG_RAM_ADDR_LOW_W -1:0]  frag_ram_raddr_low;
reg                                 pktinfo_fifo_wen;
reg     [PKTINFO_ADDR_W - 1:0]      pktinfo_fifo_waddr;
reg     [(FRAME_LEN_W+RESERVED_INFO_W+DDR_FRAME_ADDR_LOW_W) - 1:0]pktinfo_fifo_wdata;
reg     [(FRAME_LEN_W+RESERVED_INFO_W+DDR_FRAME_ADDR_LOW_W) - 1:0]pktinfo_fifo[PKTINFO_DEPTH-1:0]/* synthesis syn_ramstyle="block_ram" */;
reg     [(FRAME_LEN_W+RESERVED_INFO_W+DDR_FRAME_ADDR_LOW_W) - 1:0]pktinfo_fifo_rdata_pre;
reg     [(FRAME_LEN_W+RESERVED_INFO_W+DDR_FRAME_ADDR_LOW_W) - 1:0]pktinfo_fifo_rdata;
reg                                 pktinfo_fifo_empty;
reg                                 pktinfo_fifo_ren;
reg     [PKTINFO_ADDR_W - 1:0]      pktinfo_fifo_raddr;
reg     [4:0]                       pktinfo_fifo_ren_dly;
reg     [DDR_FRAME_ADDR_LOW_W:0]    rdata_ren_cnt;
reg     [DDR_FRAME_ADDR_LOW_W:0]    rdata_slot_cnt;
reg     [DDR_FRAME_ADDR_LOW_W:0]    pktinfo_slot_cnt;
reg     [RESERVED_INFO_W - 1:0]     pktinfo_rsvd_info;
reg     [FRAME_LEN_W - 1:0]         pktinfo_len;
reg                                 first_frag_ind;
reg                                 last_frag_ind;
reg     [1:0]                       init_done_dly;
reg     [DATA_W-1:0]                data_trans_fifo[DATA_TRANS_FIFO_DEPTH-1:0]/* synthesis syn_ramstyle="block_ram" */;
reg     [DATA_TRANS_FIFO_ADDR_W-1:0]send_cmd_cnt;
reg     [DATA_TRANS_FIFO_ADDR_W-1:0]rvld_cnt;
reg     [DATA_TRANS_FIFO_ADDR_W-1:0]ddr_pro_data_cnt;
reg     [DATA_W-1:0]                data_trans_fifo_rdata_pre;
reg     [DATA_W-1:0]                data_trans_fifo_rdata;
reg     [DATA_TRANS_FIFO_ADDR_W-1:0]data_trans_fifo_waddr;
reg     [DATA_TRANS_FIFO_ADDR_W-1:0]data_trans_fifo_raddr;
reg                                 data_trans_fifo_ren;
reg                                 frag_ififo_afull;
reg                                 data_trans_fifo_empty;
reg                                 data_trans_fifo_ren_dly;
reg                                 data_trans_fifo_rvld;
reg                                 data_trans_fifo_afull;

// Wire Define 
wire    [FRAG_IFIFO_DEPTH_W+FRAG_RAM_ADDR_LOW_W-1:0]frag_ram_waddr;
wire    [FRAG_RAM_ADDR_LOW_W+FRAME_LEN_W+RESERVED_INFO_W+1:0]frag_ififo_wdata;
wire    [FRAG_IFIFO_DEPTH_W-1:0]    frag_ram_raddr_high;
wire    [FRAG_IFIFO_DEPTH_W+FRAG_RAM_ADDR_LOW_W-1:0]frag_ram_raddr;
wire    [FRAG_IFIFO_DEPTH_W-1:0]    frag_rside_wl;
wire    [FRAG_IFIFO_DEPTH_W-1:0]    frag_wside_wl;
wire    [PKTINFO_ADDR_W - 1:0]      pktinfo_fifo_wl;
wire                                frag_ram_ren;
wire    [FRAG_RAM_ADDR_LOW_W -1:0]  fram_ram_raddr_low_vldpre;
wire    [FRAG_RAM_ADDR_LOW_W -1:0]  fram_ram_raddr_low_eofpre;
wire    [DDR_FRAME_ADDR_LOW_W:0]    cmd_slot_cnt_pre;
wire    [DDR_FRAME_ADDR_LOW_W:0]    rdata_ren_cnt_pre;
wire    [DATA_TRANS_FIFO_ADDR_W-1:0]data_trans_fifo_wl;

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frame_ififo_ren <= 1'b0;
            frame_ififo_ren_dly <= 3'd0;
            r_user_addr_high <= 'd0;
        end
    else
        begin
            if(frame_ififo_ren == 1'b1 || frame_ififo_ren_dly != 'd0 || cmd_slot_cnt >= 'd1)
                frame_ififo_ren <=#U_DLY 1'b0;
            else if(frame_ififo_empty == 1'b0 && pktinfo_fifo_full == 1'b0 && frag_ififo_afull == 1'b0)
                frame_ififo_ren <= #U_DLY 1'b1;
            else;

            frame_ififo_ren_dly <= #U_DLY {frame_ififo_ren_dly[1:0],frame_ififo_ren};

            if(frame_ififo_ren == 1'b1)
                r_user_addr_high <= #U_DLY frame_ififo_raddr;
            else;
        end
end

assign cmd_slot_cnt_pre = {1'b0,frame_ififo_rdata[DDR_FRAME_ADDR_LOW_W - 1:0]} + 'd1;
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cmd_slot_cnt <= 'd0;
            cmd_frag_slot_cnt <= 'd0;
            cmd_frag_ind <= 1'b0;
        end
    else
        begin
            if(frame_ififo_ren_dly[1] == 1'b1)
                cmd_slot_cnt <= #U_DLY cmd_slot_cnt_pre;
            else if({r_user_en,r_user_done} == 2'b11 && cmd_slot_cnt != 'd0)
                cmd_slot_cnt <= #U_DLY cmd_slot_cnt - 'd1;
            else;

            if(frame_ififo_ren_dly[1] == 1'b1 || cmd_frag_ind == 1'b1)
                cmd_frag_slot_cnt <= #U_DLY 'd0;
            else if({r_user_en,r_user_done} == 2'b11)
                cmd_frag_slot_cnt <= #U_DLY cmd_frag_slot_cnt + 'd1;
            else;

            if(cmd_frag_ind == 1'b1)
                cmd_frag_ind <= #U_DLY 1'b0;
            else if(cmd_frag_slot_cnt == (DDR_BURST_MAX - 'd2) && {r_user_en,r_user_done} == 2'b11)
                cmd_frag_ind <= #U_DLY 1'b1;
            else;
        end
end

assign r_user_cmd = 3'b001;
assign r_user_addr = {user_id,r_user_addr_high,r_user_addr_low};

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            init_done_dly <= 2'd0;
            r_user_en <= 1'b0;
            r_user_addr_low <= 'd0;
        end
    else
        begin
            init_done_dly <= #U_DLY {init_done_dly[0],ddr_init_done};

            if(((cmd_slot_cnt == 'd1 && {r_user_en,r_user_done} == 2'b11) || cmd_frag_ind == 1'b1) || data_trans_fifo_afull == 1'b1)
                r_user_en <= #U_DLY 1'b0;
            else if(cmd_slot_cnt >= 'd1 && init_done_dly[1] == 1'b1)
                r_user_en <= #U_DLY 1'b1; 
            else;

            if(frame_ififo_ren_dly[2] == 1'b1)
                r_user_addr_low <= #U_DLY 'd0;
            else if({r_user_en,r_user_done} == 2'b11)         
                r_user_addr_low <= #U_DLY r_user_addr_low + 'd1;
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            send_cmd_cnt <= 'd0;
            rvld_cnt <= 'd0;
            ddr_pro_data_cnt <= 'd0;
        end
    else
        begin
            if({r_user_en,r_user_done} == 2'b11)
                send_cmd_cnt <= #U_DLY send_cmd_cnt + 'd1;
            else;

            if(r_user_rvld == 1'b1)
                rvld_cnt <= #U_DLY rvld_cnt + 'd1;
            else; 

            ddr_pro_data_cnt <= #U_DLY send_cmd_cnt - rvld_cnt;
        end
end

assign cmd_data_checkcnt = {{(32-DATA_TRANS_FIFO_ADDR_W){1'b0}},ddr_pro_data_cnt};
//***************************************************************************//
//data from DDR,first write to this fifo,because the rvld from the DDR may be
//not regular,this fifo can output regular data
//***************************************************************************//
always @(posedge clk)
begin
    if(r_user_rvld == 1'b1)
        data_trans_fifo[data_trans_fifo_waddr] <= #U_DLY r_user_rdata;
    else;
end

always @(posedge clk)
begin
    data_trans_fifo_rdata_pre <= #U_DLY data_trans_fifo[data_trans_fifo_raddr];
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        data_trans_fifo_rdata <= 'd0;
    else  
        data_trans_fifo_rdata <= #U_DLY data_trans_fifo_rdata_pre;
end
//***************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            data_trans_fifo_waddr <= 'd0;
            data_trans_fifo_raddr <= 'd0;
        end
    else
        begin
            if(r_user_rvld == 1'b1) 
                data_trans_fifo_waddr <= #U_DLY data_trans_fifo_waddr + 'd1;
            else;

            if(data_trans_fifo_ren == 1'b1)
                data_trans_fifo_raddr <= #U_DLY data_trans_fifo_raddr + 'd1;
            else;
        end
end

assign data_trans_fifo_wl = data_trans_fifo_waddr - data_trans_fifo_raddr;
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            data_trans_fifo_ren <= 1'b0;
            data_trans_fifo_empty <= 1'b1;
            data_trans_fifo_full <= 1'b0;
            data_trans_fifo_afull <= 1'b0;
        end
    else
        begin
            if(data_trans_fifo_empty == 1'b0 && frag_ififo_full == 1'b0)
                begin
                    if(data_trans_fifo_wl == 'd1 && {data_trans_fifo_ren,r_user_rvld} == 2'b10)
                        data_trans_fifo_ren <= #U_DLY 1'b0;
                    else if(rdata_ren_cnt > 'd1)
                        data_trans_fifo_ren <= #U_DLY 1'b1;
                    else if(rdata_ren_cnt == 'd1)
                        data_trans_fifo_ren <= #U_DLY ~data_trans_fifo_ren;
                    else
                        data_trans_fifo_ren <= #U_DLY 'd0;
                end
            else
                data_trans_fifo_ren <= #U_DLY 1'b0;

            if(r_user_rvld ^ data_trans_fifo_ren == 1'b1)
                begin
                    if(data_trans_fifo_wl == 'd1 && data_trans_fifo_ren == 1'b1)
                        data_trans_fifo_empty <= #U_DLY 1'b1;
                    else if(data_trans_fifo_wl == 'd0 && r_user_rvld == 1'b1)
                        data_trans_fifo_empty <= #U_DLY 1'b0;
                    else;
                end
            else;

            if(data_trans_fifo_wl >= (DATA_TRANS_FIFO_DEPTH - 2))
                data_trans_fifo_full <= #U_DLY 1'b1;
            else
                data_trans_fifo_full <= #U_DLY 1'b0;

            if(data_trans_fifo_wl >= 'd256)
                data_trans_fifo_afull <= #U_DLY 1'b1;
            else if(data_trans_fifo_wl <= 'd128) 
                data_trans_fifo_afull <= #U_DLY 1'b0;
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            data_trans_fifo_ren_dly <= 1'b0;
            data_trans_fifo_rvld <= 1'b0;
        end
    else
        begin
            data_trans_fifo_ren_dly <= #U_DLY data_trans_fifo_ren;
            data_trans_fifo_rvld <= #U_DLY data_trans_fifo_ren_dly;
        end
end
//***************************************************************************//
//  packet info FIFO                                                         //
//***************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            pktinfo_fifo_wen <= 1'b0;
            pktinfo_fifo_waddr <= 'd0;
            pktinfo_fifo_wdata <= 'd0;
        end
    else
        begin
            if(frame_ififo_ren_dly[1] == 1'b1)
                pktinfo_fifo_wen <= #U_DLY 1'b1;
            else
                pktinfo_fifo_wen <= #U_DLY 1'b0;

            if(pktinfo_fifo_wen == 1'b1)
                pktinfo_fifo_waddr <= #U_DLY pktinfo_fifo_waddr + 'd1;
            else;

            if(frame_ififo_ren_dly[1] == 1'b1)
                pktinfo_fifo_wdata <= #U_DLY frame_ififo_rdata;
            else;
        end
end
//***************************************************************************//
always @(posedge clk)
begin
    if(pktinfo_fifo_wen == 1'b1)
        pktinfo_fifo[pktinfo_fifo_waddr] <= #U_DLY pktinfo_fifo_wdata;
    else;
end
always @(posedge clk)
begin
    pktinfo_fifo_rdata_pre <= #U_DLY pktinfo_fifo[pktinfo_fifo_raddr];
end 
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        pktinfo_fifo_rdata <= 'd0;
    else
        pktinfo_fifo_rdata <= #U_DLY pktinfo_fifo_rdata_pre;
end
//***************************************************************************//
assign pktinfo_fifo_wl = pktinfo_fifo_waddr - pktinfo_fifo_raddr;
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            pktinfo_fifo_empty <= 1'b1;
            pktinfo_fifo_full <= 1'b0;
        end
    else
        begin
            if(pktinfo_fifo_wl == 'd0)
                pktinfo_fifo_empty <= #U_DLY 1'b1;
            else
                pktinfo_fifo_empty <= #U_DLY 1'b0;

            if(pktinfo_fifo_wl >= (PKTINFO_DEPTH - 'd2))
                pktinfo_fifo_full <= #U_DLY 1'b1;
            else
                pktinfo_fifo_full <= #U_DLY 1'b0;
        end
end

assign rdata_ren_cnt_pre = {1'b0,pktinfo_fifo_rdata[DDR_FRAME_ADDR_LOW_W - 1:0]} + 'd1;
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            pktinfo_fifo_ren <= 1'b0;
            pktinfo_fifo_ren_dly <= 5'd0;
            pktinfo_fifo_raddr <= 'd0;
            rdata_ren_cnt <= 'd0;           
        end
    else
        begin
            if(pktinfo_fifo_ren == 1'b1 || pktinfo_fifo_ren_dly != 'd0 || rdata_ren_cnt != 'd0)
                pktinfo_fifo_ren <= #U_DLY 1'b0;
            else if(pktinfo_fifo_empty == 1'b0 && frag_ififo_full == 1'b0)
                pktinfo_fifo_ren <= #U_DLY 1'b1;
            else;

            pktinfo_fifo_ren_dly <= #U_DLY {pktinfo_fifo_ren_dly[3:0],pktinfo_fifo_ren};

            if(pktinfo_fifo_ren == 1'b1)
                pktinfo_fifo_raddr <= #U_DLY pktinfo_fifo_raddr + 'd1;
            else;

            if(pktinfo_fifo_ren_dly[1] == 1'b1)
                rdata_ren_cnt <= #U_DLY rdata_ren_cnt_pre;           
            else if(data_trans_fifo_ren == 1'b1 && rdata_ren_cnt != 'd0)
                rdata_ren_cnt <= #U_DLY rdata_ren_cnt - 'd1;
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
           pktinfo_slot_cnt <= 'd0;
           pktinfo_rsvd_info <= 'd0;
           pktinfo_len <= 'd0;
           first_frag_ind <= 1'b0;
           last_frag_ind <= 1'b0;
        end
    else
        begin
            if(pktinfo_fifo_ren_dly[1] == 1'b1)
                pktinfo_slot_cnt <= #U_DLY rdata_ren_cnt_pre;
            else;
 
            if(pktinfo_fifo_ren_dly[1] == 1'b1)
                pktinfo_rsvd_info <= #U_DLY pktinfo_fifo_rdata[(FRAME_LEN_W+DDR_FRAME_ADDR_LOW_W)+:RESERVED_INFO_W];
            else;

            if(pktinfo_fifo_ren_dly[1] == 1'b1)
                pktinfo_len <= #U_DLY pktinfo_fifo_rdata[DDR_FRAME_ADDR_LOW_W+:FRAME_LEN_W];
            else;

            if(pktinfo_fifo_ren_dly[1] == 1'b1)
                first_frag_ind <= #U_DLY 1'b1;
            else if(frag_ififo_wen == 1'b1)
                first_frag_ind <= #U_DLY 1'b0;
            else;

            if(pktinfo_fifo_ren_dly[4] == 1'b1 || frag_ififo_wen == 1'b1)
                begin
                    if(rdata_slot_cnt <= DDR_BURST_MAX)
                        last_frag_ind <= #U_DLY 1'b1;
                    else
                        last_frag_ind <= #U_DLY 1'b0;
                end
            else;
        end
end
//***************************************************************************//
// frag process                                                              //
//***************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        rdata_slot_cnt <= 'd0;
    else
        begin
            if(pktinfo_fifo_ren_dly[3] == 1'b1)
                rdata_slot_cnt <= #U_DLY pktinfo_slot_cnt;
            else if(data_trans_fifo_rvld == 1'b1 && rdata_slot_cnt != 'd0)
                rdata_slot_cnt <= #U_DLY rdata_slot_cnt - 'd1;
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frag_ram_waddr_low <= 'd0;
            frag_ram_waddr_high <= 'd0;
        end
    else
        begin
            if(data_trans_fifo_rvld == 1'b1)
                frag_ram_waddr_low <= #U_DLY frag_ram_waddr_low + 'd1;
            else if(frag_ififo_wen == 1'b1)
                frag_ram_waddr_low <= #U_DLY 'd0;
            else;

            if(data_trans_fifo_rvld == 1'b1 && (frag_ram_waddr_low >= (DDR_BURST_MAX - 'd1) || rdata_slot_cnt == 'd1))     //frag_ififo_wen
                frag_ram_waddr_high <= #U_DLY frag_ram_waddr_high + 'd1;
            else;
        end
end

assign frag_ram_waddr = {frag_ram_waddr_high,frag_ram_waddr_low};
assign frag_ram_raddr_high = frag_ififo_raddr_latch;
assign frag_ram_raddr = {frag_ram_raddr_high,frag_ram_raddr_low};
//************************************************************************//
//frag data ram
always @(posedge clk)
begin
    if(data_trans_fifo_rvld == 1'b1)
        frag_data_ram[frag_ram_waddr] <= #U_DLY data_trans_fifo_rdata;
    else;
end

always @(posedge f_out_clk)
begin
    if(frag_ram_ren == 1'b1)
        begin
            frag_ram_rdata_pre <= #U_DLY frag_data_ram[frag_ram_raddr];
        end
    else;
end   

always @(posedge f_out_clk or posedge f_out_rst)
begin
    if(f_out_rst == 1'b1)
        frag_ram_rdata <= 'd0;
    else if(frag_ram_ren == 1'b1)
        frag_ram_rdata <= #U_DLY frag_ram_rdata_pre;
    else;
end
//frag info fifo
always @(posedge clk)
begin
    if(frag_ififo_wen == 1'b1)
        frag_ififo[frag_ififo_waddr] <= #U_DLY frag_ififo_wdata;
    else;
end

always @(posedge f_out_clk)
begin
    frag_ififo_rdata_pre <= #U_DLY frag_ififo[frag_ififo_raddr];
end  

always @(posedge f_out_clk or posedge f_out_rst)
begin
    if(f_out_rst == 1'b1)
        frag_ififo_rdata <= 'd0;
    else
        frag_ififo_rdata <= #U_DLY frag_ififo_rdata_pre;
end
//************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frag_ififo_wen <= 1'b0;
            frag_ififo_waddr <= 'd0;
            frag_ififo_wdata_pre <= 'd0;
        end
    else
        begin
            if(data_trans_fifo_rvld == 1'b1 && (frag_ram_waddr_low >= (DDR_BURST_MAX - 'd1) || rdata_slot_cnt == 'd1))//frag_ififo_wen
                frag_ififo_wen <= #U_DLY 1'b1;
            else if(frag_ififo_wen == 1'b1)
                frag_ififo_wen <= #U_DLY 1'b0;
            else;

            frag_ififo_waddr <= #U_DLY frag_ram_waddr_high;
 
            if(data_trans_fifo_rvld == 1'b1 && (frag_ram_waddr_low >= (DDR_BURST_MAX - 'd1) || rdata_slot_cnt == 'd1))//frag_ififo_wen
                frag_ififo_wdata_pre <= #U_DLY {pktinfo_rsvd_info,pktinfo_len,frag_ram_waddr_low};
            else;
        end
end
assign frag_ififo_wdata = {first_frag_ind,last_frag_ind,frag_ififo_wdata_pre};

always @(posedge f_out_clk or posedge f_out_rst)
begin
    if(f_out_rst == 1'b1)
        begin
            frag_ififo_ren <= 1'b0;
            frag_ififo_raddr <= 'd0;
            frag_ififo_raddr_latch <= 'd0;
        end
    else
        begin
            if(frag_ififo_ren == 1'b1 || frag_ififo_ren_dly != 'd0 || f_out_vld == 1'b1)
                frag_ififo_ren <= #U_DLY 1'b0;
            else if(frag_ififo_empty == 1'b0)
                frag_ififo_ren <= #U_DLY 1'b1;
            else;

            if(frag_ififo_ren == 1'b1)
                frag_ififo_raddr <= #U_DLY frag_ififo_raddr + 'd1;
            else;

            if(frag_ififo_ren == 1'b1)
                frag_ififo_raddr_latch <= #U_DLY frag_ififo_raddr;
            else;
        end
end

always @(posedge f_out_clk or posedge f_out_rst)
begin
    if(f_out_rst == 1'b1)
        begin
            frag_ififo_ren_dly <= 2'd0;
            frag_r_eof <= 1'b0;
            frag_r_last_addr <= 'd0;
        end
    else
        begin
            frag_ififo_ren_dly <= #U_DLY {frag_ififo_ren_dly[0],frag_ififo_ren};

            if(frag_ififo_ren_dly[1] == 1'b1)
                frag_r_eof <= #U_DLY frag_ififo_rdata[FRAG_RAM_ADDR_LOW_W+FRAME_LEN_W+RESERVED_INFO_W];
            else;

            if(frag_ififo_ren_dly[1] == 1'b1)
                frag_r_last_addr <= #U_DLY frag_ififo_rdata[(FRAG_RAM_ADDR_LOW_W-1):0];
            else;
        end
end
//***************************************************************************//
//frag fifo empty or full                                                    //
//***************************************************************************//
assign frag_rside_wl = frag_ififo_waddr_g2b - frag_ififo_raddr;
always @(posedge f_out_clk or posedge f_out_rst)
begin
    if(f_out_rst == 1'b1)
        begin
            frag_ififo_raddr_b2g <= 'd0;
            frag_ififo_waddr_b2g_1dly <= 'd0;
            frag_ififo_waddr_b2g_2dly <= 'd0;
            frag_ififo_waddr_g2b <= 'd0;
            frag_ififo_empty <= 1'b1;
        end
    else
        begin
            frag_ififo_raddr_b2g <= #U_DLY gray_bin(1'b0,frag_ififo_raddr);
            frag_ififo_waddr_b2g_1dly <= #U_DLY frag_ififo_waddr_b2g;
            frag_ififo_waddr_b2g_2dly <= #U_DLY frag_ififo_waddr_b2g_1dly;
            frag_ififo_waddr_g2b <= #U_DLY gray_bin(1'b1,frag_ififo_waddr_b2g_2dly);

            if(frag_rside_wl == 'd0)
                frag_ififo_empty <= #U_DLY 1'b1;
            else
                frag_ififo_empty <= #U_DLY 1'b0;
        end
end

assign frag_wside_wl = frag_ififo_waddr - frag_ififo_raddr_g2b;
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frag_ififo_waddr_b2g <= 'd0;
            frag_ififo_raddr_b2g_1dly <= 'd0;
            frag_ififo_raddr_b2g_2dly <= 'd0;
            frag_ififo_raddr_g2b <= 'd0;
            frag_ififo_afull <= 1'b0;
            frag_ififo_full <= 1'b0;
        end
    else
        begin
            frag_ififo_waddr_b2g <= #U_DLY gray_bin(1'b0,frag_ififo_waddr);
            frag_ififo_raddr_b2g_1dly <= #U_DLY frag_ififo_raddr_b2g;
            frag_ififo_raddr_b2g_2dly <= #U_DLY frag_ififo_raddr_b2g_1dly;
            frag_ififo_raddr_g2b <= #U_DLY gray_bin(1'b1,frag_ififo_raddr_b2g_2dly);

            if(frag_wside_wl >= (FRAG_IFIFO_DEPTH - 'd4))
                frag_ififo_afull <= #U_DLY 1'b1;
            else
                frag_ififo_afull <= #U_DLY 1'b0;

            if(frag_wside_wl >= (FRAG_IFIFO_DEPTH - 'd2))
                frag_ififo_full <= #U_DLY 1'b1;
            else
                frag_ififo_full <= #U_DLY 1'b0;
        end
end
//***************************************************************************//
// pre-fetch control                                                         //
//***************************************************************************//
assign frag_ram_ren = frag_ram_ren_pre | (f_out_vld & f_out_rdy);
always @(posedge f_out_clk or posedge f_out_rst)
begin
    if(f_out_rst == 1'b1)
        begin
            frag_ram_ren_pre <= 1'b0;
            frag_ram_raddr_low <= 'd0;
        end
    else
        begin
            if(frag_ififo_ren == 1'b1 || frag_ififo_ren_dly[0] == 1'b1)
                frag_ram_ren_pre <= #U_DLY 1'b1;
            else
                frag_ram_ren_pre <= #U_DLY 1'b0;

            if(frag_ififo_ren == 1'b1)
                frag_ram_raddr_low <= #U_DLY 'd0;
            else if(frag_ram_ren == 1'b1)
                frag_ram_raddr_low <= #U_DLY frag_ram_raddr_low + 'd1;
            else;
        end
end 
  
assign f_out_data = frag_ram_rdata;

assign fram_ram_raddr_low_vldpre = frag_ram_raddr_low - 'd2;
assign fram_ram_raddr_low_eofpre = frag_ram_raddr_low - 'd1;
always @(posedge f_out_clk or posedge f_out_rst)
begin
    if(f_out_rst == 1'b1)
        begin
            f_out_vld <= 1'b0;
            f_out_sof <= 1'b0;
            f_out_eof <= 1'b0;
            f_out_len <= 'd0;
            f_out_rsvd_info <= 'd0;
        end
    else
        begin
            if(frag_ififo_ren_dly[1] == 1'b1)
                f_out_vld <= #U_DLY 1'b1;
            else if(fram_ram_raddr_low_vldpre >= frag_r_last_addr && {f_out_vld,f_out_rdy} == 2'b11)
                f_out_vld <= #U_DLY 1'b0;
            else;

            if(frag_ififo_ren_dly[1] == 1'b1)
                f_out_sof <= #U_DLY frag_ififo_rdata[FRAG_RAM_ADDR_LOW_W+FRAME_LEN_W+RESERVED_INFO_W+1];
            else if({f_out_vld,f_out_rdy} == 2'b11)
                f_out_sof <= #U_DLY 1'b0;
            else;

            if(frag_ififo_ren_dly[1] == 1'b1 && frag_ififo_rdata[(FRAG_RAM_ADDR_LOW_W-1):0] == 'd0)
                f_out_eof <= #U_DLY 1'b1;
            else if({f_out_vld,f_out_rdy} == 2'b11)
                begin
                    if(fram_ram_raddr_low_eofpre == frag_r_last_addr)
                        f_out_eof <= #U_DLY frag_r_eof;
                    else
                        f_out_eof <= #U_DLY 1'b0;
                end
            else;

            if(frag_ififo_ren_dly[1] == 1'b1)
                f_out_len <= #U_DLY frag_ififo_rdata[FRAG_RAM_ADDR_LOW_W+:FRAME_LEN_W];
            else;

            if(frag_ififo_ren_dly[1] == 1'b1)
                f_out_rsvd_info <= #U_DLY frag_ififo_rdata[(FRAG_RAM_ADDR_LOW_W+FRAME_LEN_W)+:RESERVED_INFO_W];
            else;
        end
end
//************************************************************************************************//
function [FRAG_IFIFO_DEPTH_W-1:0] gray_bin(input integer code_op,             // 0 --->encode; 1 ---> decode
                                  input [FRAG_IFIFO_DEPTH_W-1:0] data_in);
integer i;
begin
     if(code_op == 0)
         gray_bin = (data_in >> 1) ^ data_in;
     else if(code_op == 1)
         begin
             gray_bin[FRAG_IFIFO_DEPTH_W-1] = data_in[FRAG_IFIFO_DEPTH_W-1];
             for(i=FRAG_IFIFO_DEPTH_W-2;i>=0;i=i-1)
                gray_bin[i] = gray_bin[i+1] ^ data_in[i];
        end
    else;
end
endfunction
//for debug
always @(posedge f_out_clk or posedge f_out_rst)
begin
    if(f_out_rst == 1'b1)
        begin
            data_o_slotcnt_ind <= 1'b0;
            data_o_framecnt_ind <= 1'b0;
            fout_rdy <= 1'b0;
        end
    else
        begin
            if({f_out_vld,f_out_rdy} == 2'b11)
                data_o_slotcnt_ind <= #U_DLY 1'b1;
            else
                data_o_slotcnt_ind <= #U_DLY 1'b0;

            if({f_out_vld,f_out_rdy,f_out_eof} == 3'b111)
                data_o_framecnt_ind <= #U_DLY 1'b1;
            else
                data_o_framecnt_ind <= #U_DLY 1'b0;

            fout_rdy <= #U_DLY f_out_rdy;
        end
end 

endmodule

