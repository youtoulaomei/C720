// *********************************************************************************/
// Project Name :
// Author       : chendong 
// Email        : 
// Creat Time   : 2014/8/25 15:05:15
// File Name    : ddr_arbiter.v
// Module Name  : 
// Called By    :
// Abstract     : for 7Series DDR Controller
//
// CopyRight(c) 2014, shenrong sichuan
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
module ddr_arbiter#(
parameter                                   U_DLY = 1,
parameter                                   DDR_ADDR_W = 25,
parameter                                   DDR_DATA_W = 512,
parameter                                   USER_NUM = 1,
parameter                                   USER_BURST_MAX = 256,                                     //slot.
parameter                                   ABT_RULE = "polling",                                    //"polling" or "priority". when "priority",the channel 0 has the highest priority
parameter                                   DDR_MASK_W = DDR_DATA_W/8
)(
//syster signals
input                                       clk,
input                                       rst,
//interface with DDR_controller
output          [DDR_ADDR_W-1:0]            ddr_addr,
output          [2:0]                       ddr_cmd,
output reg                                  ddr_en,
input                                       ddr_rdy,

output          [DDR_DATA_W-1:0]            ddr_wdata,
output                                      ddr_wend,
output          [DDR_MASK_W-1:0]            ddr_mask,
output reg                                  ddr_wen,
input                                       ddr_wrdy,

input           [DDR_DATA_W-1:0]            ddr_rdata,
input                                       ddr_rrdy,

input                                       init_done,
//interface with users
input           [DDR_ADDR_W*USER_NUM-1:0]   user_addr,
input           [3*USER_NUM-1:0]            user_cmd,
input           [USER_NUM-1:0]              user_en,
output          [USER_NUM-1:0]              user_done,

input           [DDR_DATA_W*USER_NUM-1:0]   user_wdata,
input           [DDR_MASK_W*USER_NUM-1:0]   user_mask,

output  reg     [DDR_DATA_W*USER_NUM-1:0]   user_rdata,
output  reg     [USER_NUM-1:0]              user_rvld,
//for debug
output  reg                                 wdata_fifo_overflow,
output  reg                                 wdata_fifo_norder
); 
//define the clogb2 function
function integer clogb2;
input [31:0] value;
begin
value = value - 1;
for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1)
value = value >> 1;
end
endfunction
// Parameter Define
localparam                                  USER_NUM_W = clogb2(USER_NUM);
localparam                                  USER_BURST_W = clogb2(USER_BURST_MAX);
localparam                                  CMD_FIFO_DEPTH = 16;
localparam                                  CMD_FIFO_DEPTH_W = clogb2(CMD_FIFO_DEPTH);
localparam                                  WDATA_FIFO_DEPTH = 32;
localparam                                  WDATA_FIFO_DEPTH_W =  clogb2(WDATA_FIFO_DEPTH);
localparam                                  RCMD_FIFO_DEPTH = 128;
localparam                                  RCMD_FIFO_DEPTH_W = clogb2(RCMD_FIFO_DEPTH);
localparam                                  ABT = 2'b01;
localparam                                  EMPOWER = 2'b10;
// Register Define 
reg             [1:0]                       cur_st/* synthesis syn_encoding="safe,onehot" */;
reg             [1:0]                       next_st;
reg                                         empower_end;
reg             [USER_NUM_W-1:0]            cur_judge_chn;
reg             [USER_NUM_W-1:0]            cur_chn_1dly;
reg             [USER_NUM_W-1:0]            cur_chn_2dly;
reg             [USER_BURST_W-1:0]          burst_len;
reg                                         cmd_fifo_full;
reg                                         cmd_fifo_empty;
reg             [(DDR_ADDR_W + 3)-1:0]      cmd_mem[CMD_FIFO_DEPTH-1:0]/* synthesis syn_ramstyle="block_ram" */;
reg             [CMD_FIFO_DEPTH_W-1:0]      cmd_fifo_waddr;
reg             [CMD_FIFO_DEPTH_W-1:0]      cmd_fifo_raddr;
reg             [(DDR_ADDR_W + 3)-1:0]      cmd_fifo_rdata;
reg             [CMD_FIFO_DEPTH_W-1:0]      cmd_mem_raddr;
reg                                         cmd_fifo_ren_dly;
reg                                         cmd_fifo_wen_dly;
reg             [DDR_DATA_W+DDR_MASK_W-1:0] wdata_mem[WDATA_FIFO_DEPTH-1:0]/* synthesis syn_ramstyle="block_ram" */;
reg                                         write_cmd_ind;
reg                                         wdata_fifo_wen;
reg                                         wdata_fifo_ren_dly;
reg             [WDATA_FIFO_DEPTH_W-1:0]    wdata_fifo_waddr;
reg             [WDATA_FIFO_DEPTH_W-1:0]    wdata_fifo_raddr;
reg                                         wdata_fifo_empty;
reg                                         wdata_fifo_full;
reg             [WDATA_FIFO_DEPTH_W-1:0]    wdata_mem_raddr;
reg             [DDR_DATA_W+DDR_MASK_W-1:0] wdata_fifo_rdata;
reg             [WDATA_FIFO_DEPTH_W-1:0]    pre_data_num;
reg                                         rcmd_fifo_wen;
reg             [RCMD_FIFO_DEPTH_W-1:0]     rcmd_fifo_waddr;
reg             [RCMD_FIFO_DEPTH_W-1:0]     rcmd_fifo_raddr;
reg             [RCMD_FIFO_DEPTH_W-1:0]     rcmd_mem_raddr;
reg             [USER_NUM_W-1:0]            rcmd_mem[RCMD_FIFO_DEPTH-1:0]/* synthesis syn_ramstyle="block_ram" */;
reg             [USER_NUM_W-1:0]            rcmd_fifo_rdata;
reg             [DDR_DATA_W-1:0]            ddr_rdata_1dly;
reg             [DDR_DATA_W-1:0]            ddr_rdata_2dly;
reg             [1:0]                       ddr_rrdy_dly;

wire                                        cmd_fifo_wen;
wire                                        cmd_fifo_ren;
wire                                        wdata_fifo_ren;
wire                                        write_op_done;
wire            [CMD_FIFO_DEPTH_W-1:0]      cmd_fifo_wl;
wire            [WDATA_FIFO_DEPTH_W-1:0]    wdata_fifo_wl;
//****************************************************************************//
//************************** channel aribiter ********************************//
//****************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        cur_st <= ABT;
    else if(init_done == 1'b0)
        cur_st <= #U_DLY ABT;
    else
        cur_st <= #U_DLY next_st;
end

always @(*)
begin
    next_st = ABT;
    case(cur_st)
        ABT:begin
            if(user_en[cur_judge_chn] == 1'b1)
                next_st = EMPOWER;
            else
                next_st = ABT;
        end
        EMPOWER:begin
            if(empower_end == 1'b1)
                next_st = ABT;
            else
                next_st = EMPOWER;
        end
        default:next_st = ABT;
    endcase
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cur_judge_chn <= 'd0;
            cur_chn_1dly <= 'd0;
            cur_chn_2dly <= 'd0;
        end
    else
        begin
            if(ABT_RULE == "polling")
                begin
                    if(empower_end == 1'b1 || (user_en[cur_judge_chn] == 1'b0 && cur_st == ABT))
                        begin
                            if(cur_judge_chn < (USER_NUM - 1))
                                cur_judge_chn <= #U_DLY cur_judge_chn + 'd1;
                            else
                                cur_judge_chn <= #U_DLY 'd0;
                        end
                    else;
                end
            else if(ABT_RULE == "priority")
                begin
                    if(empower_end == 1'b1)
                        cur_judge_chn <= #U_DLY 'd0;
                    else if(user_en[cur_judge_chn] == 1'b0 && cur_st == ABT)
                        begin
                            if(cur_judge_chn < (USER_NUM - 1))
                                cur_judge_chn <= #U_DLY cur_judge_chn + 'd1;
                            else
                                cur_judge_chn <= #U_DLY 'd0;
                        end
                    else;
                end
            else;
            
            cur_chn_1dly <= #U_DLY cur_judge_chn;
            cur_chn_2dly <= #U_DLY cur_chn_1dly;
        end
end

always @(*)
begin
    if((cur_st == EMPOWER && user_en[cur_judge_chn] == 1'b0) || burst_len >= (USER_BURST_MAX - 1))
        empower_end = 1'b1;
    else
        empower_end = 1'b0;
end
                        
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            //empower_end <= 1'b0;
            burst_len <= 'd0;
        end
    else
        begin
            //if(empower_end == 1'b1)
            //    empower_end <= #U_DLY 1'b0;
            //else if((cur_st == EMPOWER && user_en[cur_judge_chn] == 1'b0) || burst_len >= (USER_BURST_MAX - 1))
            //    empower_end <= #U_DLY 1'b1;   
            //else;

            if(empower_end == 1'b1)
                burst_len <= #U_DLY 'd0;
            else if(cur_st == EMPOWER && cmd_fifo_full == 1'b0 && burst_len < (USER_BURST_MAX - 1))
                burst_len <= #U_DLY burst_len + 'd1;
            else;
        end
end 
//****************************************************************************//
//************************** CMD fifo operate ********************************//
//****************************************************************************//
assign cmd_fifo_wen = (cur_st == EMPOWER) ? (user_en[cur_judge_chn] & ~cmd_fifo_full) : 1'b0;
assign cmd_fifo_ren = ddr_rdy & ~cmd_fifo_empty;
assign cmd_fifo_wl = cmd_fifo_waddr - cmd_fifo_raddr;

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cmd_fifo_waddr <= 'd0;
            cmd_fifo_raddr <= 'd0;
            cmd_fifo_full <= 1'b0;
            cmd_fifo_empty <= 1'b1;
        end
    else
        begin
            if(cmd_fifo_wen == 1'b1)
                cmd_fifo_waddr <= #U_DLY cmd_fifo_waddr + 'd1;
            else;

            if(cmd_fifo_ren == 1'b1)
                cmd_fifo_raddr <= #U_DLY cmd_fifo_raddr + 'd1;
            else;

            if(cmd_fifo_wl >= (CMD_FIFO_DEPTH-2))
                cmd_fifo_full <= #U_DLY 1'b1;
            else
                cmd_fifo_full <= #U_DLY 1'b0;

            if((cmd_fifo_wl == 'd1 && cmd_fifo_ren == 1'b1 && cmd_fifo_wen == 1'b0) || cmd_fifo_wl == 'd0)
                cmd_fifo_empty <= #U_DLY 1'b1;
            else
                cmd_fifo_empty <= #U_DLY 1'b0;

        end
end    

always @(posedge clk)
begin
    if(cmd_fifo_wen == 1'b1)
        cmd_mem[cmd_fifo_waddr] <= #U_DLY {user_addr[(cur_judge_chn*DDR_ADDR_W)+:DDR_ADDR_W],user_cmd[(cur_judge_chn*3)+:3]};
    else;
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cmd_fifo_ren_dly <= 1'b0;
            cmd_fifo_wen_dly <= 1'b0;
            cmd_mem_raddr <= 'd0;
            cmd_fifo_rdata <= 'd0;
            ddr_en <= 1'b0;
        end
    else
        begin
            if(cmd_fifo_ren == 1'b1)
                cmd_fifo_ren_dly <= #U_DLY 1'b1;
            else if(ddr_rdy == 1'b1)
                cmd_fifo_ren_dly <= #U_DLY 1'b0;
            else;

            cmd_fifo_wen_dly <= #U_DLY cmd_fifo_wen;

            if(cmd_fifo_ren == 1'b1)
                cmd_mem_raddr <= #U_DLY cmd_fifo_raddr;
            else;

            if({cmd_fifo_ren_dly,ddr_rdy} == 2'b11)
                cmd_fifo_rdata <= #U_DLY cmd_mem[cmd_mem_raddr];
            else;

            if({cmd_fifo_ren_dly,ddr_rdy} == 2'b11)
                ddr_en <= #U_DLY 1'b1;
            else if(ddr_rdy == 1'b1)
                ddr_en <= #U_DLY 1'b0;
            else;
        end
end    

assign ddr_addr = cmd_fifo_rdata[DDR_ADDR_W+2:3];
assign ddr_cmd = cmd_fifo_rdata[2:0];

genvar i;
generate
for(i=0; i<USER_NUM; i=i+1)
    assign user_done[i] = ((i == cur_judge_chn) && (cur_st == EMPOWER)) ? (~cmd_fifo_full) : 1'b0;
endgenerate
//****************************************************************************//
//************************** WRITE DATA FIFO *********************************//
//****************************************************************************//
assign wdata_fifo_ren = (pre_data_num != 4'd0) ? (~wdata_fifo_empty & ddr_wrdy) : 1'b0;
assign wdata_fifo_wl = wdata_fifo_waddr - wdata_fifo_raddr;

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            write_cmd_ind <= 1'b0;
            wdata_fifo_wen <= 1'b0;
            wdata_fifo_waddr <= 'd0;
            wdata_fifo_raddr <= 'd0;
            wdata_fifo_empty <= 1'b1;
            wdata_fifo_full <= 1'b0;
        end
    else
        begin
            write_cmd_ind <= #U_DLY user_cmd[cur_judge_chn*3];
            wdata_fifo_wen <= #U_DLY cmd_fifo_wen_dly & ~write_cmd_ind;

            if(wdata_fifo_wen == 1'b1)
                wdata_fifo_waddr <= #U_DLY wdata_fifo_waddr + 'd1;
            else;

            if(wdata_fifo_ren == 1'b1)
                wdata_fifo_raddr <= #U_DLY wdata_fifo_raddr + 'd1;
            else;

            if((wdata_fifo_wl == 'd1 && wdata_fifo_ren == 1'b1 && wdata_fifo_wen == 1'b1) || wdata_fifo_wl == 'd0)
                wdata_fifo_empty <= #U_DLY 1'b1;
            else
                wdata_fifo_empty <= #U_DLY 1'b0;

            if(wdata_fifo_wl >= (WDATA_FIFO_DEPTH-2))
                wdata_fifo_full <= #U_DLY 1'b1;
            else
                wdata_fifo_full <= #U_DLY 1'b0;
        end
end

always @(posedge clk)
begin
    if(wdata_fifo_wen == 1'b1)
        wdata_mem[wdata_fifo_waddr] <= #U_DLY {user_wdata[(cur_chn_2dly*DDR_DATA_W)+:DDR_DATA_W],user_mask[(cur_chn_2dly*DDR_MASK_W)+:DDR_MASK_W]};
    else;
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wdata_fifo_ren_dly <= 1'b0;
            wdata_mem_raddr <= 'd0;
            wdata_fifo_rdata <= 'd0;
            ddr_wen <= 1'b0;
        end
    else
        begin
            if(wdata_fifo_ren == 1'b1)
                wdata_fifo_ren_dly <= #U_DLY 1'b1;
            else if(ddr_wrdy == 1'b1)
                wdata_fifo_ren_dly <= #U_DLY 1'b0;
            else;

            if(wdata_fifo_ren == 1'b1)
                wdata_mem_raddr <= #U_DLY wdata_fifo_raddr;
            else;
            
            if({wdata_fifo_ren_dly,ddr_wrdy} == 2'b11)
                wdata_fifo_rdata <= #U_DLY wdata_mem[wdata_mem_raddr];
            else;

            if({wdata_fifo_ren_dly,ddr_wrdy} == 2'b11)
                ddr_wen <= #U_DLY 1'b1;
            else if(ddr_wrdy == 1'b1)
                ddr_wen <= #U_DLY 1'b0;
            else;
        end
end

assign ddr_wdata = wdata_fifo_rdata[DDR_DATA_W+DDR_MASK_W-1:DDR_MASK_W];
assign ddr_mask = wdata_fifo_rdata[DDR_MASK_W:0];
assign ddr_wend = ddr_wen;

assign write_op_done = ddr_en & ddr_rdy & ~ddr_cmd[0];

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        pre_data_num <= 'd0;
    else
        begin
            if({write_op_done,wdata_fifo_ren} == 2'b10)
                pre_data_num <= #U_DLY pre_data_num + 'd1;
            else if({write_op_done,wdata_fifo_ren} == 2'b01)
                pre_data_num <= #U_DLY pre_data_num - 'd1;
            else;
        end
end
//****************************************************************************//
//************************** READ CMD FIFO  **********************************//
//****************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rcmd_fifo_wen <= 1'b0;
            rcmd_fifo_waddr <= 'd0;
            rcmd_fifo_raddr <= 'd0;
        end
    else
        begin
            rcmd_fifo_wen <= cmd_fifo_wen & user_cmd[cur_judge_chn*3];

            if(rcmd_fifo_wen == 1'b1)
                rcmd_fifo_waddr <= #U_DLY rcmd_fifo_waddr + 'd1;
            else;

            if(ddr_rrdy == 1'b1)
                rcmd_fifo_raddr <= #U_DLY rcmd_fifo_raddr + 'd1;
            else;
        end
end

always @(posedge clk)
begin
    if(rcmd_fifo_wen == 1'b1)
        rcmd_mem[rcmd_fifo_waddr] <= #U_DLY cur_chn_1dly;
    else;
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rcmd_mem_raddr <= 7'd0;
            rcmd_fifo_rdata <= 'd0;
        end
    else
        begin
            rcmd_mem_raddr <= #U_DLY rcmd_fifo_raddr;
            rcmd_fifo_rdata <= #U_DLY rcmd_mem[rcmd_mem_raddr];
        end
end

always @(posedge clk or posedge rst)
begin:user_rdata_back
    integer i;
    if(rst == 1'b1)
        begin 
            ddr_rrdy_dly <= 2'd0;
            ddr_rdata_1dly <= 'd0;
            ddr_rdata_2dly <= 'd0;
            user_rvld <= 'd0;
            user_rdata <= 'd0;
        end
    else
        begin
            ddr_rrdy_dly <= #U_DLY {ddr_rrdy_dly[0],ddr_rrdy};
            ddr_rdata_1dly <= #U_DLY ddr_rdata;
            ddr_rdata_2dly <= #U_DLY ddr_rdata_1dly;

            for(i=0; i<=USER_NUM -1; i=i+1)
                begin
                    if(i == rcmd_fifo_rdata && ddr_rrdy_dly[1] == 1'b1)
                       begin
                           user_rvld[i] <= #U_DLY 1'b1;
                           user_rdata[(i*DDR_DATA_W)+:DDR_DATA_W] <= #U_DLY ddr_rdata_2dly;
                        end
                    else
                        user_rvld[i] <= #U_DLY 1'b0;
                end
        end
end
//****************************************************************************//
//************************** DEBUG INFO     **********************************//
//****************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wdata_fifo_overflow <= 1'b0;
            wdata_fifo_norder <= 1'b0;
        end
    else
        begin
            if(wdata_fifo_full == 1'b1 && wdata_fifo_wen == 1'b1 && wdata_fifo_ren == 1'b0)
                wdata_fifo_overflow <= #U_DLY 1'b1;
            else
                wdata_fifo_overflow <= #U_DLY 1'b0;

            if(wdata_fifo_empty == 1'b1 && pre_data_num != 'd0)
                wdata_fifo_norder <= #U_DLY 1'b1;
            else
                wdata_fifo_norder <= #U_DLY 1'b0;
        end
end


endmodule


