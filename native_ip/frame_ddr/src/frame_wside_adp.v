// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/12/29 11:18:27
// File Name    : frame_wside_adp.v
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
module frame_wside_adp #(
parameter                           U_DLY = 1,
parameter                           USER_NUM_W = 3,
parameter                           DATA_W = 512,                                    //bit
parameter                           FRAME_LEN_W = 14,                                //base on byte,the max value are 16K bytes
parameter                           RESERVED_INFO_W = 8,

parameter                           DDR_ADDR_W = 26,
parameter                           DDR_BURST_MAX = 64,                              //time slot,one slot value are DATA_W bits
parameter                           DDR_FRAME_ADDR_LOW_W = 8,

parameter                           DDR_FRAME_ADDR_HGIH_W = DDR_ADDR_W - USER_NUM_W - DDR_FRAME_ADDR_LOW_W,
parameter                           MASK_W = DATA_W/8
)
(
input                               clk,
input                               rst,
//frame_interface
input                               f_in_clk,
input                               f_in_rst,
input           [DATA_W - 1:0]      f_in_data,
input                               f_in_vld,
output  reg                         f_in_rdy,
input                               f_in_sof,
input                               f_in_eof,
input           [FRAME_LEN_W - 1:0] f_in_len,                                        //base on byte
input           [RESERVED_INFO_W - 1:0]f_in_rsvd_info,                               //reserved infomation
//interface with DDR_Arbiter
output  wire    [DDR_ADDR_W - 1:0]  w_user_addr,
output  wire    [2:0]               w_user_cmd,                                      //001:read; 000:write                                   
output  reg                         w_user_en,
input                               w_user_done,

output  wire    [DATA_W - 1:0]      w_user_wdata,
output  wire    [MASK_W - 1:0]      w_user_mask,
//interface with frame_info_fifo
input           [DDR_FRAME_ADDR_HGIH_W - 1:0]frame_ififo_waddr,
input                               frame_ififo_full,
output  reg                         frame_ififo_wen,
output  reg     [(FRAME_LEN_W+RESERVED_INFO_W+DDR_FRAME_ADDR_LOW_W) - 1:0] frame_ififo_wdata,   //{reserved_info,frame_len,user_addr_low(slot_length)}
//others
input           [USER_NUM_W - 1:0]  user_id,
input                               ddr_init_done,
//cib
output  reg                         frag_ififo_full,
output  reg                         frag_ififo_empty,
output  wire                        data_i_slotcnt_ind,
output  reg                         data_i_framecnt_ind,
output  reg                         sof_eof_err,
output  reg                         vld_err,
output  reg                         fin_vld
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

localparam                          FRAG_IFIFO_DEPTH = 8;                            //adapter fifo storage 8 frags
localparam                          FRAG_IFIFO_DEPTH_W = clogb2(FRAG_IFIFO_DEPTH);
localparam                          FRAG_RAM_ADDR_LOW_W = clogb2(DDR_BURST_MAX);
// Register Define 
reg                                 frag_ram_wen;
reg     [FRAG_RAM_ADDR_LOW_W - 1:0] frag_ram_waddr_low;
reg     [DATA_W - 1:0]              frag_ram_wdata;
reg     [6:0]                       frag_cnt;
reg                                 frag_ind;
reg     [1:0]                       frag_ind_dly;
reg                                 eof_ind;
reg                                 sof_ind;
reg     [FRAME_LEN_W - 1:0]         frame_byte_len;
reg     [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_waddr;
reg     [RESERVED_INFO_W - 1:0]     frame_rsvd_info_latch;
reg     [DATA_W - 1:0]              frag_data_ram[FRAG_IFIFO_DEPTH * DDR_BURST_MAX - 1:0]/* synthesis syn_ramstyle="block_ram" */;
reg     [DATA_W - 1:0]              frag_ram_rdata_pre;
reg     [DATA_W - 1:0]              frag_ram_rdata;
reg     [(1+1+RESERVED_INFO_W+FRAME_LEN_W+FRAG_RAM_ADDR_LOW_W) - 1:0] frag_ififo[FRAG_IFIFO_DEPTH - 1:0]/* synthesis syn_ramstyle="block_ram" */;
reg     [(1+1+RESERVED_INFO_W+FRAME_LEN_W+FRAG_RAM_ADDR_LOW_W) - 1:0] frag_ififo_rdata_pre;
reg     [(1+1+RESERVED_INFO_W+FRAME_LEN_W+FRAG_RAM_ADDR_LOW_W) - 1:0] frag_ififo_rdata;
reg     [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_waddr_gray;
reg     [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_raddr_gray_1dly;
reg     [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_raddr_gray_2dly;
reg     [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_raddr_g2b;
reg     [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_raddr_gray;
reg     [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_waddr_gray_1dly;
reg     [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_waddr_gray_2dly;
reg     [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_waddr_g2b;
reg                                 frag_ififo_ren;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_raddr;
reg     [FRAG_IFIFO_DEPTH_W-1:0]    frag_ififo_raddr_latch;
reg     [1:0]                       frag_ififo_ren_dly;
reg     [FRAG_RAM_ADDR_LOW_W - 1:0] frag_ififo_rdata_len;
reg     [RESERVED_INFO_W+FRAME_LEN_W-1:0]frag_ififo_rinfo_len_latch;
reg     [DDR_FRAME_ADDR_LOW_W - 1:0] w_user_addr_low;
reg     [DDR_FRAME_ADDR_HGIH_W - 1:0] w_user_addr_high;
reg     [FRAG_RAM_ADDR_LOW_W - 1:0] frag_ram_raddr_low;
reg                                 frag_ififo_rdata_eof;
reg                                 sof_wait_eof;
reg     [1:0]                       init_done_dly;
// Wire Define 
wire    [(1+1+RESERVED_INFO_W+FRAME_LEN_W+FRAG_RAM_ADDR_LOW_W) - 1:0] frag_ififo_wdata;
wire                                frag_ififo_wen;
wire    [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_wside_wl;
wire    [FRAG_IFIFO_DEPTH_W - 1:0]  frag_ififo_rside_wl;
wire    [FRAG_RAM_ADDR_LOW_W+FRAG_IFIFO_DEPTH_W-1:0]frag_ram_waddr;
wire    [FRAG_RAM_ADDR_LOW_W+FRAG_IFIFO_DEPTH_W-1:0]frag_ram_raddr;

always @(posedge f_in_clk or posedge f_in_rst)
begin
    if(f_in_rst == 1'b1)
        begin
            init_done_dly <= 2'd0;
            f_in_rdy <= 1'b0;
        end
    else
        begin
            init_done_dly <= #U_DLY {init_done_dly[0],ddr_init_done};

            if(frag_cnt >= (DDR_BURST_MAX - 1) || {f_in_vld,f_in_rdy,f_in_eof} == 3'b111 || {frag_ind_dly,frag_ind} != 'd0)
                f_in_rdy <= #U_DLY 1'b0;
            else if(frag_ififo_full == 1'b0 && init_done_dly[1] == 1'b1)
                f_in_rdy <= #U_DLY 1'b1;
            else;
        end
end

always @(posedge f_in_clk or posedge f_in_rst)
begin
    if(f_in_rst == 1'b1)
        begin
            frag_ram_wen <= 1'b0;
            frag_ram_waddr_low <= 'd0;
            frag_ram_wdata <= 'd0;
        end
    else
        begin
            frag_ram_wen <= #U_DLY f_in_vld & f_in_rdy & (f_in_sof | sof_wait_eof);

            if(frag_ind == 1'b1)
                frag_ram_waddr_low <= #U_DLY 'd0;
            else if(frag_ram_wen == 1'b1)
                frag_ram_waddr_low <= #U_DLY frag_ram_waddr_low + 'd1;
            else;

            frag_ram_wdata <= #U_DLY f_in_data;
        end
end

always @(posedge f_in_clk or posedge f_in_rst)
begin
    if(f_in_rst == 1'b1)
        begin
            frag_cnt <= 'd0;
            frag_ind <= 1'b0;
            frag_ind_dly <= 2'd0;
            eof_ind <= 1'b0;
            sof_ind <= 1'b0;
        end
    else
        begin
            if(frag_ind == 1'b1)
                frag_cnt <= #U_DLY 'd0;
            //else if({f_in_vld,f_in_rdy} == 2'b11)
            else if({f_in_vld,f_in_rdy} == 2'b11 && (f_in_sof == 1'b1 || sof_wait_eof == 1'b1))
                frag_cnt <= #U_DLY frag_cnt + 'd1;
            else;

            if(frag_ind == 1'b1)
                frag_ind <= #U_DLY 1'b0;
            else if(frag_cnt >= (DDR_BURST_MAX - 1) || {f_in_vld,f_in_rdy,f_in_eof} == 3'b111)
                frag_ind <= #U_DLY 1'b1;
            else;

            frag_ind_dly <= #U_DLY {frag_ind_dly[0],frag_ind};

            if({f_in_vld,f_in_rdy,f_in_eof} == 3'b111)
                eof_ind <= #U_DLY 1'b1;
            else if(frag_ind == 1'b1)
                eof_ind <= #U_DLY 1'b0;
            else;

            if({f_in_vld,f_in_rdy,f_in_sof} == 3'b111)
                sof_ind <= #U_DLY 1'b1;
            else if(frag_ind == 1'b1)
                sof_ind <= #U_DLY 1'b0; 
            else;    
        end
end

assign frag_ififo_wside_wl = frag_ififo_waddr - frag_ififo_raddr_g2b;
always @(posedge f_in_clk or posedge f_in_rst)
begin
    if(f_in_rst == 1'b1)
        begin
            frame_byte_len <= 'd0;
            frag_ififo_waddr <= 'd0;
            frag_ififo_full <= 1'b0;
            frame_rsvd_info_latch <= 'd0;
        end
    else
        begin
            if({f_in_vld,f_in_rdy,f_in_sof} == 3'b111)
                frame_byte_len <= #U_DLY f_in_len;
            else;

            if(frag_ififo_wen == 1'b1)
                frag_ififo_waddr <= #U_DLY frag_ififo_waddr + 'd1;
            else;

            if(frag_ififo_wside_wl >= (FRAG_IFIFO_DEPTH - 'd1))
                frag_ififo_full <= #U_DLY 1'b1;
            else
                frag_ififo_full <= #U_DLY 1'b0;

            if({f_in_vld,f_in_rdy,f_in_sof} == 3'b111)
                frame_rsvd_info_latch <= #U_DLY f_in_rsvd_info;
            else;
        end
end

assign frag_ififo_wen = frag_ind;
assign frag_ififo_wdata = {sof_ind,eof_ind,frame_rsvd_info_latch,frame_byte_len,frag_ram_waddr_low};
//*******************************************************************************//
//frag data ram
always @(posedge f_in_clk)
begin
    if(frag_ram_wen == 1'b1)
        frag_data_ram[frag_ram_waddr] <= #U_DLY frag_ram_wdata;
    else;
end
always @(posedge clk)
begin
    frag_ram_rdata_pre <= #U_DLY frag_data_ram[frag_ram_raddr];
end    

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        frag_ram_rdata <= 'd0;
    else
        frag_ram_rdata <= #U_DLY frag_ram_rdata_pre;
end
//frag info fifo
always @(posedge f_in_clk)
begin
    if(frag_ififo_wen == 1'b1)
        frag_ififo[frag_ififo_waddr] <= #U_DLY frag_ififo_wdata;
    else;
end

always @(posedge clk)
begin
    frag_ififo_rdata_pre <= #U_DLY frag_ififo[frag_ififo_raddr];
end  

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        frag_ififo_rdata <= 'd0;
    else
        frag_ififo_rdata <= #U_DLY frag_ififo_rdata_pre;
end
//*******************************************************************************//
//address gray translate
always @(posedge f_in_clk or posedge f_in_rst)
begin
    if(f_in_rst == 1'b1)
        begin
            frag_ififo_waddr_gray <= 'd0;
            frag_ififo_raddr_gray_1dly <= 'd0;
            frag_ififo_raddr_gray_2dly <= 'd0;
            frag_ififo_raddr_g2b <= 'd0;
        end
    else
        begin
            frag_ififo_waddr_gray <= #U_DLY gray_bin(1'b0,frag_ififo_waddr);
            frag_ififo_raddr_gray_1dly <= #U_DLY frag_ififo_raddr_gray;
            frag_ififo_raddr_gray_2dly <= #U_DLY frag_ififo_raddr_gray_1dly;
            frag_ififo_raddr_g2b <= #U_DLY gray_bin(1'b1,frag_ififo_raddr_gray_2dly);            
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frag_ififo_raddr_gray <= 'd0;
            frag_ififo_waddr_gray_1dly <= 'd0;
            frag_ififo_waddr_gray_2dly <= 'd0;
            frag_ififo_waddr_g2b <= 'd0;
        end
    else
        begin
            frag_ififo_raddr_gray <= #U_DLY gray_bin(1'b0,frag_ififo_raddr);
            frag_ififo_waddr_gray_1dly <= #U_DLY frag_ififo_waddr_gray;
            frag_ififo_waddr_gray_2dly <= #U_DLY frag_ififo_waddr_gray_1dly;
            frag_ififo_waddr_g2b <= #U_DLY gray_bin(1'b1,frag_ififo_waddr_gray_2dly);
        end
end

assign frag_ififo_rside_wl = frag_ififo_waddr_g2b - frag_ififo_raddr;
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frag_ififo_ren <= 1'b0;
            frag_ififo_raddr <= 'd0;
            frag_ififo_raddr_latch <= 'd0;
            frag_ififo_ren_dly <= 2'd0;
            frag_ififo_rdata_len <= 'd0;
            frag_ififo_rinfo_len_latch <= 'd0;
        end
    else
        begin
            if(frag_ififo_ren == 1'b1 || frag_ififo_ren_dly != 2'b00 || w_user_en == 1'b1 || frame_ififo_full == 1'b1)
                frag_ififo_ren <= #U_DLY 1'b0;
            else if(frag_ififo_rside_wl != 'd0)
                frag_ififo_ren <= #U_DLY 1'b1;
            else;

            if(frag_ififo_ren == 1'b1)
                frag_ififo_raddr <= #U_DLY frag_ififo_raddr + 'd1;
            else;

            if(frag_ififo_ren == 1'b1)
                frag_ififo_raddr_latch <= #U_DLY frag_ififo_raddr;
            else;

            frag_ififo_ren_dly <= #U_DLY {frag_ififo_ren_dly[0],frag_ififo_ren};
            
            if(frag_ififo_ren_dly[1] == 1'b1)
                frag_ififo_rdata_len <= #U_DLY frag_ififo_rdata[0+:FRAG_RAM_ADDR_LOW_W];
            else;

            if(frag_ififo_ren_dly[1] == 1'b1)
                frag_ififo_rinfo_len_latch <= #U_DLY frag_ififo_rdata[FRAG_RAM_ADDR_LOW_W+:(RESERVED_INFO_W+FRAME_LEN_W)];
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        frag_ififo_empty <= 1'b1;
    else
        begin
            if(frag_ififo_rside_wl == 'd0)
                frag_ififo_empty <= #U_DLY 1'b1;
            else
                frag_ififo_empty <= #U_DLY 1'b0;
        end
end
//***************************************************************************************//
assign w_user_cmd = 3'b000;
assign w_user_addr = {user_id,w_user_addr_high,w_user_addr_low};
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            w_user_en <= 1'b0;
            w_user_addr_low <= 'd0;
            w_user_addr_high <= 'd0;
        end
    else
        begin
            if(frag_ififo_ren_dly[1] == 1'b1)
                w_user_en <= #U_DLY 1'b1;
            else if(frag_ram_raddr_low >= frag_ififo_rdata_len && {w_user_en,w_user_done} == 2'b11)      
                w_user_en <= #U_DLY 1'b0;
            else;   

            if(frag_ififo_ren_dly[1] == 1'b1 && frag_ififo_rdata[1+RESERVED_INFO_W+FRAME_LEN_W+FRAG_RAM_ADDR_LOW_W] == 1'b1)//sof. 1 frame will be stored in one ddr domain
                w_user_addr_low <= #U_DLY 'd0;
            else if({w_user_en,w_user_done} == 2'b11)
                w_user_addr_low <= #U_DLY w_user_addr_low + 'd1;
            else;

            if(frag_ififo_ren_dly[1] == 1'b1 && frag_ififo_rdata[1+RESERVED_INFO_W+FRAME_LEN_W+FRAG_RAM_ADDR_LOW_W] == 1'b1)//sof
                w_user_addr_high <= #U_DLY frame_ififo_waddr;
            else;
        end
end    
//read data from frag ram
assign w_user_wdata = frag_ram_rdata[0+:DATA_W];
assign w_user_mask = {MASK_W{1'b0}};
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        frag_ram_raddr_low <= 'd0;
    else
        begin
            if(frag_ififo_ren_dly[1] == 1'b1)
                frag_ram_raddr_low <= #U_DLY 'd0;
            else if({w_user_en,w_user_done} == 2'b11)
                frag_ram_raddr_low <= #U_DLY frag_ram_raddr_low + 'd1;
            else;
        end
end

assign frag_ram_waddr = {frag_ififo_waddr,frag_ram_waddr_low};
assign frag_ram_raddr = {frag_ififo_raddr_latch,frag_ram_raddr_low};
//write infomation to frame ififo
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            frame_ififo_wen <= 1'b0;
            frame_ififo_wdata <= 'd0;
            frag_ififo_rdata_eof <= 1'b0;
        end
    else
        begin
            if(frame_ififo_wen == 1'b1)
                frame_ififo_wen <= #U_DLY 1'b0;
            else if(frag_ram_raddr_low >= frag_ififo_rdata_len && frag_ififo_rdata_eof == 1'b1 && {w_user_en,w_user_done} == 2'b11) //frame eof
                frame_ififo_wen <= #U_DLY 1'b1;
            else;

            if(frag_ram_raddr_low >= frag_ififo_rdata_len && frag_ififo_rdata_eof == 1'b1 && {w_user_en,w_user_done} == 2'b11)  //frame eof
                frame_ififo_wdata <= #U_DLY {frag_ififo_rinfo_len_latch,w_user_addr_low}; //{reserved_info,frame_length,user_addr_low(slot_length)}
            else;

            if(frag_ififo_ren_dly[1] == 1'b1)
                frag_ififo_rdata_eof <= #U_DLY frag_ififo_rdata[RESERVED_INFO_W+FRAME_LEN_W+FRAG_RAM_ADDR_LOW_W];
            else; 
        end
end

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
assign data_i_slotcnt_ind = frag_ram_wen;

always @(posedge f_in_clk or posedge f_in_rst)
begin
    if(f_in_rst == 1'b1)
        begin
            data_i_framecnt_ind <= 1'b0;
            sof_wait_eof <= 1'b0;
            sof_eof_err <= 1'b0;
            vld_err <= 1'b0;
            fin_vld <= 1'b0;
        end
    else
        begin
            if({f_in_vld,f_in_rdy,f_in_eof} == 3'b111)
                data_i_framecnt_ind <= #U_DLY 1'b1;
            else
                data_i_framecnt_ind <= #U_DLY 1'b0;

            if({f_in_vld,f_in_rdy} == 2'b11 && f_in_sof ^ f_in_eof == 1'b1)
                begin
                    if(f_in_sof == 1'b1)
                        sof_wait_eof <= #U_DLY 1'b1;
                    else if(f_in_eof == 1'b1)
                        sof_wait_eof <= #U_DLY 1'b0;
                    else;
                end
            else;

            if({f_in_vld,f_in_rdy} == 2'b11 && f_in_sof ^ f_in_eof == 1'b1)
                begin
                    if((sof_wait_eof == 1'b0 && f_in_eof == 1'b1) || (sof_wait_eof == 1'b1 && f_in_sof == 1'b1))
                        sof_eof_err <= #U_DLY 1'b1;
                    else
                        sof_eof_err <= #U_DLY 1'b0;
                end
            else
                sof_eof_err <= #U_DLY 1'b0;

            if({f_in_vld,f_in_rdy} == 2'b11 && sof_wait_eof == 1'b0 && f_in_sof == 1'b0)
                vld_err <= #U_DLY 1'b1;
            else
                vld_err <= #U_DLY 1'b0;
 
            fin_vld <= #U_DLY f_in_vld;
        end
end

endmodule

