// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/6/1 14:20:57
// File Name    : frame_adapter.v
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
module frame_adapter #(
parameter                           U_DLY = 1,
parameter                           DDR_TYPE = 4'h4,

parameter                           USER_NUM_W = 3,
parameter                           DATA_W = 512,                                    //bit
parameter                           FRAME_LEN_W = 14,                                //base on byte,the max value are 16K bytes
parameter                           RESERVED_INFO_W = 8,

parameter                           DDR_ADDR_W = 26,
parameter                           DDR_BURST_MAX = 64,                              //time slot,one slot value are DATA_W bits

parameter                           CPU_ADDR_W = 4
)
(
input                               ui_clk,
input                               clk_100m,
input                               rst,
//frame input
input                               f_in_clk,
input           [DATA_W - 1:0]      f_in_data,
input                               f_in_vld,
output                              f_in_rdy,
input                               f_in_sof,
input                               f_in_eof,
input           [FRAME_LEN_W - 1:0] f_in_len,                                        //base on byte
input           [RESERVED_INFO_W - 1:0]f_in_rsvd_info,                               //reserved infomation
//frame output
input                               f_out_clk,
output          [DATA_W - 1:0]      f_out_data,
output                              f_out_vld,
input                               f_out_rdy,
output                              f_out_sof,
output                              f_out_eof,
output          [FRAME_LEN_W - 1:0] f_out_len,                                        //base on byte
output          [RESERVED_INFO_W - 1:0]f_out_rsvd_info,                               //reserved infomation
//others
input           [USER_NUM_W - 1:0]  user_id,
//interface with DDR_Arbiter
output          [DDR_ADDR_W - 1:0]  w_user_addr,
output          [2:0]               w_user_cmd,                                      //001:read; 000:write                                   
output                              w_user_en,
input                               w_user_done,
output          [DATA_W - 1:0]      w_user_wdata,
output          [DATA_W/8 -1:0]     w_user_mask,

output          [DDR_ADDR_W - 1:0]  r_user_addr,
output          [2:0]               r_user_cmd,                                      //001:read; 000:write                                   
output                              r_user_en,
input                               r_user_done,
input           [DATA_W - 1:0]      r_user_rdata,
input                               r_user_rvld,
//localbus
input                               hard_rst,
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [CPU_ADDR_W-1:0]    cpu_addr,
input           [31:0]              cpu_wdata,
output          [31:0]              cpu_rdata,
//others
output                              frame_ififo_afull,
output                              frame_ififo_aempty,
input                               ddr_init_done,
output wire                         ui_clk_rst,
output wire                         ddr_cntrl_rst,
input                               authorize_succ
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

parameter                           DDR_FRAME_ADDR_LOW_W = FRAME_LEN_W - clogb2(DATA_W/8);
parameter                           DDR_FRAME_ADDR_HGIH_W = DDR_ADDR_W - USER_NUM_W - DDR_FRAME_ADDR_LOW_W;
parameter                           RST_DLY_PERIOD = 4;
// Register Define 
reg     [RST_DLY_PERIOD-1:0]        ddr_clk_rst;
reg     [RST_DLY_PERIOD-1:0]        f_in_rst;
reg     [RST_DLY_PERIOD-1:0]        f_out_rst;
reg     [RST_DLY_PERIOD-1:0]        clk_100m_rst;

// Wire Define 
wire    [DDR_FRAME_ADDR_HGIH_W - 1:0]frame_ififo_waddr;
wire    [(FRAME_LEN_W+RESERVED_INFO_W+DDR_FRAME_ADDR_LOW_W) - 1:0] frame_ififo_wdata;
wire    [DDR_FRAME_ADDR_HGIH_W - 1:0]frame_ififo_raddr;
wire    [(FRAME_LEN_W+RESERVED_INFO_W+DDR_FRAME_ADDR_LOW_W) - 1:0] frame_ififo_rdata;
wire    [DDR_FRAME_ADDR_HGIH_W - 1:0] frame_ififo_waterline;
wire    [31:0]                      frame_waterline;
wire    [31:0]                      frame_ififo_lwup_cfg;
wire    [31:0]                      frame_ififo_lwdown_cfg;
wire                                reset_main;
wire                                controller_rst;
wire    [31:0]                      cmd_data_checkcnt;

frame_wside_adp #(
    .U_DLY                      (U_DLY                      ),
    .USER_NUM_W                 (USER_NUM_W                 ),
    .DATA_W                     (DATA_W                     ),
    .FRAME_LEN_W                (FRAME_LEN_W                ),
    .RESERVED_INFO_W            (RESERVED_INFO_W            ),

    .DDR_ADDR_W                 (DDR_ADDR_W                 ),
    .DDR_BURST_MAX              (DDR_BURST_MAX              ),
    .DDR_FRAME_ADDR_LOW_W       (DDR_FRAME_ADDR_LOW_W       ),

    .DDR_FRAME_ADDR_HGIH_W      (DDR_FRAME_ADDR_HGIH_W      )
)
u_frame_wside_adp(
    .clk                        (ui_clk                     ),
    .rst                        (ddr_clk_rst[RST_DLY_PERIOD-1]),
//frame_interface
    .f_in_clk                   (f_in_clk                   ),
    .f_in_rst                   (f_in_rst[RST_DLY_PERIOD-1] ),
    .f_in_data                  (f_in_data                  ),
    .f_in_vld                   (f_in_vld                   ),
    .f_in_rdy                   (f_in_rdy                   ),
    .f_in_sof                   (f_in_sof                   ),
    .f_in_eof                   (f_in_eof                   ),
    .f_in_len                   (f_in_len                   ),
    .f_in_rsvd_info             (f_in_rsvd_info             ),
//interface with DDR_Arbiter
    .w_user_addr                (w_user_addr                ),
    .w_user_cmd                 (w_user_cmd                 ),
    .w_user_en                  (w_user_en                  ),
    .w_user_done                (w_user_done                ),

    .w_user_wdata               (w_user_wdata               ),
    .w_user_mask                (w_user_mask                ),
//interface with frame_info_fifo
    .frame_ififo_waddr          (frame_ififo_waddr          ),
    .frame_ififo_full           (frame_ififo_full           ),
    .frame_ififo_wen            (frame_ififo_wen            ),
    .frame_ififo_wdata          (frame_ififo_wdata          ),
//others
    .user_id                    (user_id                    ),
    .ddr_init_done              (ddr_init_done              ),
//cib
    .frag_ififo_full            (frag_i_full                ),
    .frag_ififo_empty           (frag_i_empty               ),
    .data_i_slotcnt_ind         (data_i_slotcnt_ind         ),
    .data_i_framecnt_ind        (data_i_framecnt_ind        ),
    .sof_eof_err                (sof_eof_err                ),
    .vld_err                    (vld_err                    ),
    .fin_vld                    (fin_vld                    )
);

frame_rside_adp #(
    .U_DLY                      (U_DLY                      ),
    .USER_NUM_W                 (USER_NUM_W                 ),
    .DATA_W                     (DATA_W                     ),
    .FRAME_LEN_W                (FRAME_LEN_W                ),
    .RESERVED_INFO_W            (RESERVED_INFO_W            ),

    .DDR_ADDR_W                 (DDR_ADDR_W                 ),
    .DDR_BURST_MAX              (DDR_BURST_MAX              ),
    .DDR_FRAME_ADDR_LOW_W       (DDR_FRAME_ADDR_LOW_W       ),

    .DDR_FRAME_ADDR_HGIH_W      (DDR_FRAME_ADDR_HGIH_W      )
)
u_frame_rside_adp(
    .clk                        (ui_clk                     ),
    .rst                        (ddr_clk_rst[RST_DLY_PERIOD-1]),
//frame_interface
    .f_out_clk                  (f_out_clk                  ),
    .f_out_rst                  (f_out_rst[RST_DLY_PERIOD-1]),
    .f_out_data                 (f_out_data                 ),
    .f_out_vld                  (f_out_vld                  ),
    .f_out_rdy                  (f_out_rdy                  ),
    .f_out_sof                  (f_out_sof                  ),
    .f_out_eof                  (f_out_eof                  ),
    .f_out_len                  (f_out_len                  ),
    .f_out_rsvd_info            (f_out_rsvd_info            ),
//interface with DDR_Arbiter
    .r_user_addr                (r_user_addr                ),
    .r_user_cmd                 (r_user_cmd                 ),
    .r_user_en                  (r_user_en                  ),
    .r_user_done                (r_user_done                ),

    .r_user_rdata               (r_user_rdata               ),
    .r_user_rvld                (r_user_rvld                ),
//interface with frame_info_fifo
    .frame_ififo_raddr          (frame_ififo_raddr          ),
    .frame_ififo_empty          (frame_ififo_empty          ),
    .frame_ififo_ren            (frame_ififo_ren            ),
    .frame_ififo_rdata          (frame_ififo_rdata          ),
//others
    .user_id                    (user_id                    ),
    .ddr_init_done              (ddr_init_done              ),
//cib
    .frag_ififo_full            (frag_o_full                ),
    .frag_ififo_empty           (frag_o_empty               ),
    .data_o_slotcnt_ind         (data_o_slotcnt_ind         ),
    .data_o_framecnt_ind        (data_o_framecnt_ind        ),
    .data_trans_fifo_full       (data_trans_fifo_full       ),
    .pktinfo_fifo_full          (pktinfo_fifo_full          ),
    .fout_rdy                   (fout_rdy                   ),
    .cmd_data_checkcnt          (cmd_data_checkcnt          )

);

frame_info_fifo #(
    .U_DLY                      (U_DLY                      ),
    .DDR_FRAME_ADDR_HGIH_W      (DDR_FRAME_ADDR_HGIH_W      ),
    .FRAME_IFIFO_DATA_W         (FRAME_LEN_W+RESERVED_INFO_W+DDR_FRAME_ADDR_LOW_W)
)
u_frame_info_fifo(
    .clk                        (ui_clk                     ),
    .rst                        (ddr_clk_rst[RST_DLY_PERIOD-1]),
//with write side
    .frame_ififo_waddr          (frame_ififo_waddr          ),
    .frame_ififo_full           (frame_ififo_full           ),
    .frame_ififo_wen            (frame_ififo_wen            ),
    .frame_ififo_wdata          (frame_ififo_wdata          ),
//with read side
    .frame_ififo_raddr          (frame_ififo_raddr          ),
    .frame_ififo_empty          (frame_ififo_empty          ),
    .frame_ififo_ren            (frame_ififo_ren            ),
    .frame_ififo_rdata          (frame_ififo_rdata          ),
    .frame_ififo_waterline      (frame_ififo_waterline      ),

    .frame_ififo_lwup_cfg       (frame_ififo_lwup_cfg       ),
    .frame_ififo_lwdown_cfg     (frame_ififo_lwdown_cfg     ),
    .frame_ififo_afull          (frame_ififo_afull          ),
    .frame_ififo_aempty         (frame_ififo_aempty         ),
    .authorize_succ             (authorize_succ             )
);

sub_cib #(
    .U_DLY                      (U_DLY                      ),
    .CPU_ADDR_W                 (CPU_ADDR_W                 )
)
u_sub_cib(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),
    .f_in_clk                   (f_in_clk                   ),
    .f_out_clk                  (f_out_clk                  ),
//cpu bus
    .cpu_cs                     (cpu_cs                     ),
    .cpu_we                     (cpu_we                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wdata                  (cpu_wdata                  ),
    .cpu_rdata                  (cpu_rdata                  ),
//others
    .ddr_type                   (DDR_TYPE                   ),
    .soft_rst                   (soft_rst                   ),
    .ctl_rst                    (ctl_rst                    ),
    .frag_i_full                (frag_i_full                ),
    .frag_i_empty               (frag_i_empty               ),
    .frag_o_full                (frag_o_full                ),
    .frag_o_empty               (frag_o_empty               ),
    .frame_ififo_full           (frame_ififo_full           ),
    .frame_ififo_empty          (frame_ififo_empty          ),
    .frame_ififo_lwup_cfg       (frame_ififo_lwup_cfg       ),
    .frame_ififo_lwdown_cfg     (frame_ififo_lwdown_cfg     ),
    .frame_ififo_afull          (frame_ififo_afull          ),
    .frame_ififo_aempty         (frame_ififo_aempty         ),
    .data_trans_fifo_full       (data_trans_fifo_full       ),
    .pktinfo_fifo_full          (pktinfo_fifo_full          ),

    .data_i_slotcnt_ind         (data_i_slotcnt_ind         ),
    .data_i_framecnt_ind        (data_i_framecnt_ind        ),
    .sof_eof_err                (sof_eof_err                ),
    .vld_err                    (vld_err                    ),
    .data_o_slotcnt_ind         (data_o_slotcnt_ind         ),
    .data_o_framecnt_ind        (data_o_framecnt_ind        ),

    .frame_waterline            (frame_waterline            ),
    .ddr_init_done              (ddr_init_done              ),
    .authorize_succ             (authorize_succ             ),

    .fin_vld                    (fin_vld                    ),
    .fin_rdy                    (f_in_rdy                   ),
    .fout_vld                   (f_out_vld                  ),
    .fout_rdy                   (fout_rdy                   ),
    .cmd_data_checkcnt          (cmd_data_checkcnt          )
);

assign frame_waterline = {{(32-DDR_FRAME_ADDR_HGIH_W){1'b0}},frame_ififo_waterline};
//rst process
assign reset_main = rst | soft_rst | ~ddr_init_done;
assign controller_rst = hard_rst | ctl_rst;
assign ui_clk_rst = ddr_clk_rst[RST_DLY_PERIOD-1];
assign ddr_cntrl_rst = clk_100m_rst[RST_DLY_PERIOD-1];

always @(posedge ui_clk or posedge reset_main)
begin
    if(reset_main == 1'b1)
        ddr_clk_rst <= {RST_DLY_PERIOD{1'b1}};
    else
        ddr_clk_rst <= #U_DLY {ddr_clk_rst[(RST_DLY_PERIOD-2):0],1'b0};
end

always @(posedge f_in_clk or posedge reset_main)
begin
    if(reset_main == 1'b1)
        f_in_rst <= {RST_DLY_PERIOD{1'b1}};
    else
        f_in_rst <= #U_DLY {f_in_rst[(RST_DLY_PERIOD-2):0],1'b0};
end

always @(posedge f_out_clk or posedge reset_main)
begin
    if(reset_main == 1'b1)
        f_out_rst <= {RST_DLY_PERIOD{1'b1}};
    else
        f_out_rst <= #U_DLY {f_out_rst[(RST_DLY_PERIOD-2):0],1'b0};
end

always @(posedge clk_100m or posedge controller_rst)
begin
    if(controller_rst == 1'b1)
        clk_100m_rst <= {RST_DLY_PERIOD{1'b1}};
    else
        clk_100m_rst <= #U_DLY {clk_100m_rst[(RST_DLY_PERIOD-2):0],1'b0};
end


endmodule

