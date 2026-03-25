// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/12/5 10:08:46
// File Name    : sub_cib.v
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
`define SUB_0 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,ctl_rst,soft_rst}
`define SUB_1 {ddr_type,fill27,fill26,cur_authorize_succ,cur_ddr_init_done,fill23,fill22,fill21,fill20,fill19,fill18,cur_frame_ififo_afull,cur_frame_ififo_aempty,fill15,fill14,cur_pktinfo_fifo_full,cur_data_trans_fifo_full,fill11,fill10,cur_frame_ififo_full,cur_frame_ififo_empty,fill7,fill6,cur_frag_o_full,cur_frag_i_full,fill3,fill2,cur_frag_o_empty,cur_frag_i_empty}
`define SUB_2 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,his_frame_ififo_afull,his_frame_ififo_aempty,fill15,fill14,his_pktinfo_fifo_full,his_dtrans_fifo_full,fill11,fill10,his_frame_ififo_full,his_frame_ififo_empty,fill7,fill6,his_frag_o_full,his_frag_i_full,fill3,fill2,his_frag_o_empty,his_frag_i_empty}
`define SUB_3 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,his_fout_rdy,his_fout_vld,fill19,fill18,his_fin_rdy,his_fin_vld,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,his_vld_err,his_sof_eof_err}
`define SUB_4 {cnt_data_i_slot}
`define SUB_5 {cnt_data_i_frame}
`define SUB_6 {cnt_data_o_slot}
`define SUB_7 {cnt_data_o_frame}
`define SUB_8 {cur_frame_waterline}
`define SUB_9 {frame_ififo_lwdown_cfg}
`define SUB_A {frame_ififo_lwup_cfg}
`define SUB_B {cur_cmd_data_checkcnt}

module sub_cib #(
parameter                           U_DLY = 1,
parameter                           CPU_ADDR_W = 4
)
(
input                               clk,
input                               rst,
input                               f_in_clk,
input                               f_out_clk,
//cpu bus
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [CPU_ADDR_W-1:0]    cpu_addr,
input           [31:0]              cpu_wdata,
output  reg     [31:0]              cpu_rdata,
//others
input           [3:0]               ddr_type,
output  reg                         soft_rst,
output  reg                         ctl_rst,
input                               frag_i_full,
input                               frag_i_empty,
input                               frag_o_full,
input                               frag_o_empty,
input                               frame_ififo_full,
input                               frame_ififo_empty,
output  reg     [31:0]              frame_ififo_lwup_cfg,
output  reg     [31:0]              frame_ififo_lwdown_cfg,
input                               frame_ififo_afull,
input                               frame_ififo_aempty,
input                               data_trans_fifo_full,
input                               pktinfo_fifo_full,

input                               data_i_slotcnt_ind,
input                               data_i_framecnt_ind,
input                               sof_eof_err,
input                               vld_err,
input                               data_o_slotcnt_ind,
input                               data_o_framecnt_ind,

input           [31:0]              frame_waterline,
input                               ddr_init_done,
input                               authorize_succ,
input                               fin_vld,
input                               fin_rdy,
input                               fout_vld,
input                               fout_rdy,
input           [31:0]              cmd_data_checkcnt
);
// Parameter Define 

// Register Define 
reg                fill1;
reg                fill2;
reg                fill3;
reg                fill4;
reg                fill5;
reg                fill6;
reg                fill7;
reg                fill8;
reg                fill9;
reg                fill10;
reg                fill11;
reg                fill12;
reg                fill13;
reg                fill14;
reg                fill15;
reg                fill16;
reg                fill17;
reg                fill18;
reg                fill19;
reg                fill20;
reg                fill21;
reg                fill22;
reg                fill23;
reg                fill24;
reg                fill25;
reg                fill26;
reg                fill27;
reg                fill28;
reg                fill29;
reg                fill30;
reg                fill31;
reg  [2:0]         cpu_we_dly;
reg  [2:0]         cpu_rd_dly;
reg  [1:0]         cpu_cs_dly;
// Wire Define 
wire                                cur_frag_i_full;
wire                                cur_frag_i_empty;
wire                                cur_frag_o_full;
wire                                cur_frag_o_empty;
wire                                his_frag_i_full;
wire                                his_frag_i_empty;
wire                                his_frag_o_full;
wire                                his_frag_o_empty;
wire                                cur_frame_ififo_full;
wire                                cur_frame_ififo_empty;
wire                                his_frame_ififo_full;
wire                                his_frame_ififo_empty;
wire    [31:0]                      cnt_data_i_slot;
wire    [31:0]                      cnt_data_i_frame;
wire    [31:0]                      cnt_data_o_slot;
wire    [31:0]                      cnt_data_o_frame;
wire                                his_sof_eof_err;
wire    [31:0]                      cur_frame_waterline;
wire                                his_fin_vld;
wire                                his_fin_rdy;
wire                                his_fout_vld;
wire                                his_fout_rdy;
wire                                cur_ddr_init_done;
wire                                cur_authorize_succ;
wire                                cur_frame_ififo_afull;
wire                                cur_frame_ififo_aempty;
wire                                his_vld_err;
wire                                cur_data_trans_fifo_full;
wire                                cur_pktinfo_fifo_full;
wire                                his_dtrans_fifo_full;
wire                                his_pktinfo_fifo_full;
wire                                his_frame_ififo_aempty;
wire                                his_frame_ififo_afull;
wire   [31:0]                       cur_cmd_data_checkcnt;
wire                                cpu_read_en;


always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cpu_we_dly <= 3'd0;
            cpu_rd_dly <= 3'd0;
            cpu_cs_dly <= 2'd0;
        end
    else
        begin
            cpu_we_dly <= #U_DLY {cpu_we_dly[1:0],cpu_we};
            cpu_rd_dly <= #U_DLY {cpu_rd_dly[1:0],cpu_rd};
            cpu_cs_dly <= #U_DLY {cpu_cs_dly[0],cpu_cs};
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            `SUB_0 <= 32'h0000_0000;
            `SUB_9 <= 32'h0000_000F;
            `SUB_A <= 32'hFFFF_FFF0;
        end
    else
        begin
            if(cpu_we_dly[2:1] == 2'b10 && cpu_cs_dly[1] == 1'b0)
                 begin
                    case(cpu_addr)
                        'h0:`SUB_0 <= #U_DLY cpu_wdata;                         
                        'h9:`SUB_9 <= #U_DLY cpu_wdata;                         
                        'hA:`SUB_A <= #U_DLY cpu_wdata;                         
                        default:;
                    endcase
                end
            else           
                {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1} <= #U_DLY 'd0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        cpu_rdata <= 'd0;
    else
        begin
            if(cpu_rd_dly[2:1] == 2'b10 && cpu_cs_dly[1] == 1'b0)
                 begin
                    case(cpu_addr)
                        'h0:cpu_rdata <= #U_DLY `SUB_0;     
                        'h1:cpu_rdata <= #U_DLY `SUB_1;     
                        'h2:cpu_rdata <= #U_DLY `SUB_2;     
                        'h3:cpu_rdata <= #U_DLY `SUB_3;     
                        'h4:cpu_rdata <= #U_DLY `SUB_4;     
                        'h5:cpu_rdata <= #U_DLY `SUB_5;     
                        'h6:cpu_rdata <= #U_DLY `SUB_6;     
                        'h7:cpu_rdata <= #U_DLY `SUB_7;     
                        'h8:cpu_rdata <= #U_DLY `SUB_8;     
                        'h9:cpu_rdata <= #U_DLY `SUB_9;     
                        'hA:cpu_rdata <= #U_DLY `SUB_A;
                        'hB:cpu_rdata <= #U_DLY `SUB_B;
                        default:cpu_rdata <= #U_DLY 'd0;
                    endcase
                end
            else;
        end
end

assign cpu_read_en = (cpu_rd_dly[2:1] == 2'b10 && cpu_cs_dly[1] == 1'b0) ? 1'b1 : 1'b0;
//***********************************************************************************//
alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_i_full(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (frag_i_full                ),
    .alarm_current              (cur_frag_i_full            )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_i_empty(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (frag_i_empty               ),
    .alarm_current              (cur_frag_i_empty           )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_o_full(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (frag_o_full                ),
    .alarm_current              (cur_frag_o_full            )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_o_empty(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (frag_o_empty               ),
    .alarm_current              (cur_frag_o_empty           )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_frame_full(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (frame_ififo_full           ),
    .alarm_current              (cur_frame_ififo_full       )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_frame_afull(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (frame_ififo_afull          ),
    .alarm_current              (cur_frame_ififo_afull      )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_frame_empty(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (frame_ififo_empty          ),
    .alarm_current              (cur_frame_ififo_empty      )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_frame_aempty(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (frame_ififo_aempty         ),
    .alarm_current              (cur_frame_ififo_aempty     )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (32                         )
)
u_alarm_cur_frame_waterline(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (frame_waterline            ),
    .alarm_current              (cur_frame_waterline        )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_ddr_init(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (ddr_init_done              ),
    .alarm_current              (cur_ddr_init_done          )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_authorize(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (authorize_succ             ),
    .alarm_current              (cur_authorize_succ         )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_dtrans_fifo_full(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (data_trans_fifo_full       ),
    .alarm_current              (cur_data_trans_fifo_full   )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_alarm_cur_pktinfo_fifo_full(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (pktinfo_fifo_full          ),
    .alarm_current              (cur_pktinfo_fifo_full      )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (32                         )
)
u_alarm_cur_cd_checkcnt(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (cmd_data_checkcnt          ),
    .alarm_current              (cur_cmd_data_checkcnt      )
);
//***********************************************************************************//
alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_i_full(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (frag_i_full                ),
    .alarm_history              (his_frag_i_full            )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_i_empty(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (frag_i_empty               ),
    .alarm_history              (his_frag_i_empty           )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_o_full(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (frag_o_full                ),
    .alarm_history              (his_frag_o_full            )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_o_empty(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (frag_o_empty               ),
    .alarm_history              (his_frag_o_empty           )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_frame_full(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (frame_ififo_full           ),
    .alarm_history              (his_frame_ififo_full       )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_frame_empty(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (frame_ififo_empty          ),
    .alarm_history              (his_frame_ififo_empty      )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h3                        )
)
u_alm_his_sof_eof_err(
    .rst                        (rst                        ),
    .src_clk                    (f_in_clk                   ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (sof_eof_err                ),
    .alarm_history              (his_sof_eof_err            )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h3                        )
)
u_alm_his_vld_err(
    .rst                        (rst                        ),
    .src_clk                    (f_in_clk                   ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (vld_err                    ),
    .alarm_history              (his_vld_err                )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h3                        )
)
u_alm_his_fin_vld(
    .rst                        (rst                        ),
    .src_clk                    (f_in_clk                   ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (fin_vld                    ),
    .alarm_history              (his_fin_vld                )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h3                        )
)
u_alm_his_fin_rdy(
    .rst                        (rst                        ),
    .src_clk                    (f_in_clk                   ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (fin_rdy                    ),
    .alarm_history              (his_fin_rdy                )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h3                        )
)
u_alm_his_fout_vld(
    .rst                        (rst                        ),
    .src_clk                    (f_out_clk                  ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (fout_vld                   ),
    .alarm_history              (his_fout_vld               )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h3                        )
)
u_alm_his_fout_rdy(
    .rst                        (rst                        ),
    .src_clk                    (f_out_clk                  ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (fout_rdy                   ),
    .alarm_history              (his_fout_rdy               )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_dtrans_fifo_full(
    .rst                        (rst                        ),
    .src_clk                    (f_out_clk                  ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (data_trans_fifo_full       ),
    .alarm_history              (his_dtrans_fifo_full       )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_pktinfo_fifo_full(
    .rst                        (rst                        ),
    .src_clk                    (f_out_clk                  ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (pktinfo_fifo_full          ),
    .alarm_history              (his_pktinfo_fifo_full      )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_frame_ififo_aempty(
    .rst                        (rst                        ),
    .src_clk                    (f_out_clk                  ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (frame_ififo_aempty         ),
    .alarm_history              (his_frame_ififo_aempty     )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             ('h2                        )
)
u_alm_his_frame_ififo_afull(
    .rst                        (rst                        ),
    .src_clk                    (f_out_clk                  ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (frame_ififo_afull          ),
    .alarm_history              (his_frame_ififo_afull      )
);

//***********************************************************************************//
cib_counter_32b #(
    .U_DLY                      (U_DLY                      ),
    .CYCLE_EN                   ("YES"                      ),//"YES" : cycle counter ; "NO" : no cycle counter
    .CLEAR_EN                   ("YES"                      ),//"YES" : read clear ; "NO" : read but no clear
    .CLK_ASYNC                  ("TRUE"                     ),//"TRUE" : clk_cpu and clk_src are async; "FALSE" : the same clock
    .CPU_ADDR_W                 (CPU_ADDR_W                 ),
    .COUNTER_ADDR               ('h4                        )
)
u_counter_data_i_slot(
    .rst                        (rst                        ),
    .clk_cpu                    (clk                        ),
    .clk_src                    (f_in_clk                   ),
//
    .counter_en                 (data_i_slotcnt_ind         ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_read_en                (cpu_read_en                ),
    .counter_value              (cnt_data_i_slot            )
);

cib_counter_32b #(
    .U_DLY                      (U_DLY                      ),
    .CYCLE_EN                   ("YES"                      ),//"YES" : cycle counter ; "NO" : no cycle counter
    .CLEAR_EN                   ("YES"                      ),//"YES" : read clear ; "NO" : read but no clear
    .CLK_ASYNC                  ("TRUE"                     ),//"TRUE" : clk_cpu and clk_src are async; "FALSE" : the same clock
    .CPU_ADDR_W                 (CPU_ADDR_W                 ),
    .COUNTER_ADDR               ('h5                        )
)
u_counter_data_i_frame(
    .rst                        (rst                        ),
    .clk_cpu                    (clk                        ),
    .clk_src                    (f_in_clk                   ),
//
    .counter_en                 (data_i_framecnt_ind        ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_read_en                (cpu_read_en                ),
    .counter_value              (cnt_data_i_frame           )
);

cib_counter_32b #(
    .U_DLY                      (U_DLY                      ),
    .CYCLE_EN                   ("YES"                      ),//"YES" : cycle counter ; "NO" : no cycle counter
    .CLEAR_EN                   ("YES"                      ),//"YES" : read clear ; "NO" : read but no clear
    .CLK_ASYNC                  ("TRUE"                     ),//"TRUE" : clk_cpu and clk_src are async; "FALSE" : the same clock
    .CPU_ADDR_W                 (CPU_ADDR_W                 ),
    .COUNTER_ADDR               ('h6                        )
)
u_counter_data_o_slot(
    .rst                        (rst                        ),
    .clk_cpu                    (clk                        ),
    .clk_src                    (f_out_clk                  ),
//
    .counter_en                 (data_o_slotcnt_ind         ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_read_en                (cpu_read_en                ),
    .counter_value              (cnt_data_o_slot            )
);

cib_counter_32b #(
    .U_DLY                      (U_DLY                      ),
    .CYCLE_EN                   ("YES"                      ),//"YES" : cycle counter ; "NO" : no cycle counter
    .CLEAR_EN                   ("YES"                      ),//"YES" : read clear ; "NO" : read but no clear
    .CLK_ASYNC                  ("TRUE"                     ),//"TRUE" : clk_cpu and clk_src are async; "FALSE" : the same clock
    .CPU_ADDR_W                 (CPU_ADDR_W                 ),
    .COUNTER_ADDR               ('h7                        )
)
u_counter_data_o_frame(
    .rst                        (rst                        ),
    .clk_cpu                    (clk                        ),
    .clk_src                    (f_out_clk                  ),
//
    .counter_en                 (data_o_framecnt_ind        ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_read_en                (cpu_read_en                ),
    .counter_value              (cnt_data_o_frame           )
);

endmodule
