// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/10/17 10:35:25
// File Name    : sgl_ch_ddr_frame_top.v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2018, BoYuLiHua Co., Ltd.. 
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
`define SGL_CH_AUTHORIZE_EN
//`define SGL_CH_MEM_DDR4
module sgl_ch_ddr_frame_top #(
parameter                           U_DLY = 1,
parameter                           USER_NUM = 9,                                    //max user number are 16
parameter                           DATA_W = 512,
parameter                           FRAME_LEN_W = 15,                                //base on byte,the max value are 16K bytes
parameter                           RESERVED_INFO_W = 8,                             //max user number are 16
`ifdef SGL_CH_MEM_DDR4                       
parameter                           DDR_IO_ADDR_W = 17,                              //8Gb DDR4
parameter                           DDR_ADDR_W = 26,
parameter                           DDR_IO_BANK_W = 2,
`else
parameter                           DDR_IO_ADDR_W = 15,                              //4Gb DDR3
parameter                           DDR_ADDR_W = 25,
parameter                           DDR_IO_BANK_W = 3,
`endif
parameter                           DDR_BURST_MAX = 64,                              //time slot,one slot value are DATA_W bits

parameter                           CPU_ADDR_W = 8
)
(
input                               clk_100m,
output wire                         ddr_clk,
input                               ddr_rst,
input                               hard_rst,
input           [31:0]              authorize_code,
output wire                         init_done,
`ifdef SGL_CH_MEM_DDR4
input                               c0_sys_clk_p,
input                               c0_sys_clk_n,
`else
input                               clk_200m,
input           [11:0]              device_temp_i,
`endif
// DDR PHY Interface
`ifdef SGL_CH_MEM_DDR4
output                              c0_ddr_act_n,  
output          [DDR_IO_ADDR_W-1:0] c0_ddr_addr,
output          [DDR_IO_BANK_W-1:0] c0_ddr_ba,
output                              c0_ddr_bg,
output          [0:0]               c0_ddr_cke,
output          [0:0]               c0_ddr_odt,
output                              c0_ddr_cs_n,
output          [0:0]               c0_ddr_ck_t,
output          [0:0]               c0_ddr_ck_c,
output                              c0_ddr_reset_n,
inout           [7:0]               c0_ddr_dm_dbi_n,
inout           [63:0]              c0_ddr_dq,
inout           [7:0]               c0_ddr_dqs_c,
inout           [7:0]               c0_ddr_dqs_t,
`else
inout           [63:0]              ddr3_dq,
inout           [7:0]               ddr3_dqs_n,
inout           [7:0]               ddr3_dqs_p,
output          [DDR_IO_ADDR_W-1:0] ddr3_addr,
output          [DDR_IO_BANK_W-1:0] ddr3_ba,
output                              ddr3_ras_n,
output                              ddr3_cas_n,
output                              ddr3_we_n,
output                              ddr3_reset_n,
output          [0:0]               ddr3_ck_p,
output          [0:0]               ddr3_ck_n,
output          [0:0]               ddr3_cke,
output          [0:0]               ddr3_cs_n,
output          [7:0]               ddr3_dm,
output          [0:0]               ddr3_odt,
`endif
//user interface
input           [USER_NUM-1:0]      f_in_clk,
input           [DATA_W*USER_NUM - 1:0]f_in_data,
input           [USER_NUM-1:0]      f_in_vld,
output          [USER_NUM-1:0]      f_in_rdy,
input           [USER_NUM-1:0]      f_in_sof,
input           [USER_NUM-1:0]      f_in_eof,
input           [FRAME_LEN_W*USER_NUM - 1:0]f_in_len,                                //base on byte
input           [RESERVED_INFO_W*USER_NUM - 1:0]f_in_rsvd_info,                      //reserved infomation
//frame output
input           [USER_NUM-1:0]      f_out_clk,
output          [DATA_W*USER_NUM - 1:0]f_out_data,
output          [USER_NUM-1:0]      f_out_vld,
input           [USER_NUM-1:0]      f_out_rdy,
output          [USER_NUM-1:0]      f_out_sof,
output          [USER_NUM-1:0]      f_out_eof,
output          [FRAME_LEN_W*USER_NUM - 1:0] f_out_len,                               //base on byte
output          [RESERVED_INFO_W*USER_NUM - 1:0]f_out_rsvd_info,                      //reserved infomation
//others
output  wire    [USER_NUM-1:0]      frame_ififo_afull,
output  wire    [USER_NUM-1:0]      frame_ififo_aempty,
//cpu interface
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [CPU_ADDR_W-1:0]    cpu_addr,
input           [31:0]              cpu_wdata,
output reg      [31:0]              cpu_rdata
)/* synthesis syn_maxfan=20 */;
// Parameter Define 
function integer clogb2;
input [31:0] value;
begin
value = value - 1;
for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1)
value = value >> 1;
end
endfunction

parameter USER_NUM_W = (USER_NUM > 1) ? clogb2(USER_NUM) : 1; 
`ifdef SGL_CH_MEM_DDR4
parameter DDR_TYPE = 4'h4;            //DDR4
`else
parameter DDR_TYPE = 4'h3;
`endif
// Register Define 

// Wire Define 
wire    [DDR_ADDR_W-1:0]            ddr_user_addr;
wire    [2:0]                       ddr_user_cmd;
wire    [DATA_W-1:0]                ddr_user_wdata;
wire    [DATA_W/8-1:0]              ddr_user_mask;
wire    [DATA_W-1:0]                ddr_user_rdata;
wire    [DDR_ADDR_W*USER_NUM-1:0]   w_user_addr;
wire    [DDR_ADDR_W*USER_NUM-1:0]   r_user_addr;
wire    [3*USER_NUM-1:0]            w_user_cmd;
wire    [3*USER_NUM-1:0]            r_user_cmd;
wire    [USER_NUM-1:0]              w_user_en;
wire    [USER_NUM-1:0]              r_user_en;
wire    [USER_NUM-1:0]              w_user_done;
wire    [USER_NUM-1:0]              r_user_done;
wire    [DATA_W*USER_NUM-1:0]       w_user_wdata;
wire    [DATA_W/8*USER_NUM-1:0]     w_user_mask;
wire    [USER_NUM*2-1:0]            r_user_rvld;
wire    [DATA_W*USER_NUM*2-1:0]     r_user_rdata;
wire    [USER_NUM-1:0]              cpu_cs_sub;
wire    [32*USER_NUM-1:0]           cpu_rdata_sub;
wire                                ui_clk;
wire                                authorize_succ;
wire                                ui_clk_sync_rst;
wire    [USER_NUM-1:0]              ui_clk_rst; 
wire    [USER_NUM-1:0]              ddr_cntrl_rst;

assign ddr_clk = ui_clk;
genvar i;
generate
for(i = 0;i < USER_NUM;i = i+1)
begin
    frame_adapter #(
        .U_DLY                      (U_DLY                      ),
        .DDR_TYPE                   (DDR_TYPE                   ),
        .USER_NUM_W                 (USER_NUM_W                 ),
        .DATA_W                     (DATA_W                     ),
        .FRAME_LEN_W                (FRAME_LEN_W                ),
        .RESERVED_INFO_W            (RESERVED_INFO_W            ),
    
        .DDR_ADDR_W                 (DDR_ADDR_W                 ),
        .DDR_BURST_MAX              (DDR_BURST_MAX              ),
    
        .CPU_ADDR_W                 (4                          )
    )
    u_frame_adapter(
        .ui_clk                     (ui_clk                     ),
        .clk_100m                   (clk_100m                   ),        
        .rst                        (ddr_rst                    ),
    //frame input
        .f_in_clk                   (f_in_clk[i]                ),
        .f_in_data                  (f_in_data[DATA_W*i+:DATA_W]),
        .f_in_vld                   (f_in_vld[i]                ),
        .f_in_rdy                   (f_in_rdy[i]                ),
        .f_in_sof                   (f_in_sof[i]                ),
        .f_in_eof                   (f_in_eof[i]                ),
        .f_in_len                   (f_in_len[FRAME_LEN_W*i+:FRAME_LEN_W]),
        .f_in_rsvd_info             (f_in_rsvd_info[RESERVED_INFO_W*i+:RESERVED_INFO_W]),
    //frame output
        .f_out_clk                  (f_out_clk[i]               ),
        .f_out_data                 (f_out_data[DATA_W*i+:DATA_W]),
        .f_out_vld                  (f_out_vld[i]               ),
        .f_out_rdy                  (f_out_rdy[i]               ),
        .f_out_sof                  (f_out_sof[i]               ),
        .f_out_eof                  (f_out_eof[i]               ),
        .f_out_len                  (f_out_len[FRAME_LEN_W*i+:FRAME_LEN_W]),
        .f_out_rsvd_info            (f_out_rsvd_info[RESERVED_INFO_W*i+:RESERVED_INFO_W]),
    //others
        .user_id                    (i[USER_NUM_W-1:0]          ),
    //interface with DDR_Arbiter
        .w_user_addr                (w_user_addr[DDR_ADDR_W*i+:DDR_ADDR_W]),
        .w_user_cmd                 (w_user_cmd[3*i+:3]         ),
        .w_user_en                  (w_user_en[i]               ),
        .w_user_done                (w_user_done[i]             ),
        .w_user_wdata               (w_user_wdata[DATA_W*i+:DATA_W]),
        .w_user_mask                (w_user_mask[DATA_W/8*i+:DATA_W/8]),
    
        .r_user_addr                (r_user_addr[DDR_ADDR_W*i+:DDR_ADDR_W]),
        .r_user_cmd                 (r_user_cmd[3*i+:3]         ),
        .r_user_en                  (r_user_en[i]               ),
        .r_user_done                (r_user_done[i]             ),
        .r_user_rdata               (r_user_rdata[(DATA_W*USER_NUM+DATA_W*i)+:DATA_W]),
        .r_user_rvld                (r_user_rvld[USER_NUM+i]    ),
    //localbus
        .hard_rst                   (hard_rst                   ),
        .cpu_cs                     (cpu_cs_sub[i]              ),
        .cpu_we                     (cpu_we                     ),
        .cpu_rd                     (cpu_rd                     ),
        .cpu_addr                   (cpu_addr[3:0]              ),
        .cpu_wdata                  (cpu_wdata                  ),
        .cpu_rdata                  (cpu_rdata_sub[32*i+:32]    ),
    //others
        .frame_ififo_afull          (frame_ififo_afull[i]       ),
        .frame_ififo_aempty         (frame_ififo_aempty[i]      ),
        .ddr_init_done              (init_done                  ),
        .ui_clk_rst                 (ui_clk_rst[i]              ),
        .ddr_cntrl_rst              (ddr_cntrl_rst[i]           ),
`ifdef SGL_CH_AUTHORIZE_EN 
        .authorize_succ             (authorize_succ             )
`else
        .authorize_succ             (1'b1                       )
`endif
    );
    assign cpu_cs_sub[i] = (cpu_addr[CPU_ADDR_W-1:4] == i) ? cpu_cs : 1'b1;
end
endgenerate

always @(posedge clk_100m or posedge hard_rst)
begin:cpu_rata_reg
integer j;
    if(hard_rst == 1'b1)
        cpu_rdata <= 'd0;
    else
        begin
            for(j=0; j<USER_NUM; j=j+1)
                begin
                    if(cpu_cs_sub[j] == 1'b0)
                        cpu_rdata <= #U_DLY cpu_rdata_sub[32*j+:32];
                    else;
                end
        end
end

ddr_arbiter #(
    .U_DLY                      (U_DLY                      ),
    .DDR_ADDR_W                 (DDR_ADDR_W                 ),
    .DDR_DATA_W                 (DATA_W                     ),
    .USER_NUM                   (USER_NUM*2                 ),
    .USER_BURST_MAX             (DDR_BURST_MAX              ),
    .ABT_RULE                   ("polling"                  ),//"polling" or "priority". when "priority",the channel 0 has the highest priority
    .DDR_MASK_W                 (DATA_W/8                   )
)
u_ddr_arbiter(
//syster signals
    .clk                        (ui_clk                     ),
    .rst                        (ui_clk_rst[0]              ),
//interface with DDR_controller
    .ddr_addr                   (ddr_user_addr              ),
    .ddr_cmd                    (ddr_user_cmd               ),
    .ddr_en                     (ddr_user_en                ),
    .ddr_rdy                    (ddr_user_rdy               ),

    .ddr_wdata                  (ddr_user_wdata             ),
    .ddr_wend                   (ddr_user_wend              ),
    .ddr_mask                   (ddr_user_mask              ),
    .ddr_wen                    (ddr_user_wen               ),
    .ddr_wrdy                   (ddr_user_wrdy              ),

    .ddr_rdata                  (ddr_user_rdata             ),
    .ddr_rrdy                   (ddr_user_rrdy              ),

    .init_done                  (init_done                  ),
//interface with users
    .user_addr                  ({r_user_addr,w_user_addr}  ),
    .user_cmd                   ({r_user_cmd,w_user_cmd}    ),
    .user_en                    ({r_user_en,w_user_en}      ),
    .user_done                  ({r_user_done,w_user_done}  ),

    .user_wdata                 ({{DATA_W*USER_NUM{1'b0}},w_user_wdata}),
    .user_mask                  ({{DATA_W/8*USER_NUM{1'b0}},w_user_mask}),

    .user_rdata                 (r_user_rdata               ),
    .user_rvld                  (r_user_rvld                ),
//for debug
    .wdata_fifo_overflow        (/*not used*/               ),
    .wdata_fifo_norder          (/*not used*/               )
); 
`ifdef SGL_CH_MEM_DDR4
ddr4_ctrl u0_ddr4_controller(
    .sys_rst                    (ddr_cntrl_rst[0]           ),
    .c0_sys_clk_p               (c0_sys_clk_p               ),
    .c0_sys_clk_n               (c0_sys_clk_n               ),
    .c0_ddr4_act_n              (c0_ddr_act_n               ),
    .c0_ddr4_adr                (c0_ddr_addr                ),
    .c0_ddr4_ba                 (c0_ddr_ba                  ),
    .c0_ddr4_bg                 (c0_ddr_bg                  ),
    .c0_ddr4_cke                (c0_ddr_cke                 ),
    .c0_ddr4_odt                (c0_ddr_odt                 ),
    .c0_ddr4_cs_n               (c0_ddr_cs_n                ),
    .c0_ddr4_ck_t               (c0_ddr_ck_t                ),
    .c0_ddr4_ck_c               (c0_ddr_ck_c                ),
    .c0_ddr4_reset_n            (c0_ddr_reset_n             ),
    .c0_ddr4_dm_dbi_n           (c0_ddr_dm_dbi_n            ),
    .c0_ddr4_dq                 (c0_ddr_dq                  ),
    .c0_ddr4_dqs_c              (c0_ddr_dqs_c               ),
    .c0_ddr4_dqs_t              (c0_ddr_dqs_t               ),

    .c0_init_calib_complete     (init_done                  ),
    .c0_ddr4_ui_clk             (ui_clk                     ),
    .c0_ddr4_ui_clk_sync_rst    (ui_clk_sync_rst            ),
    .dbg_clk                    (/*not used*/               ),

    .c0_ddr4_app_addr           ({ddr_user_addr,3'd0}       ),
    .c0_ddr4_app_cmd            (ddr_user_cmd               ),
    .c0_ddr4_app_en             (ddr_user_en                ),
    .c0_ddr4_app_hi_pri         (1'b0                       ),
    .c0_ddr4_app_wdf_data       (ddr_user_wdata             ),
    .c0_ddr4_app_wdf_end        (ddr_user_wend              ),
    .c0_ddr4_app_wdf_mask       (ddr_user_mask              ),
    .c0_ddr4_app_wdf_wren       (ddr_user_wen               ),
    .c0_ddr4_app_rd_data        (ddr_user_rdata             ),
    .c0_ddr4_app_rd_data_end    (/*not used*/               ),
    .c0_ddr4_app_rd_data_valid  (ddr_user_rrdy              ),
    .c0_ddr4_app_rdy            (ddr_user_rdy               ),
    .c0_ddr4_app_wdf_rdy        (ddr_user_wrdy              ),
    .dbg_bus                    (/*not used*/               )
  );
`else
ddr3_mig u_ddr3_mig(
    .ddr3_dq                    (ddr3_dq                    ),
    .ddr3_dqs_n                 (ddr3_dqs_n                 ),
    .ddr3_dqs_p                 (ddr3_dqs_p                 ),
    .ddr3_addr                  (ddr3_addr                  ),
    .ddr3_ba                    (ddr3_ba                    ),
    .ddr3_ras_n                 (ddr3_ras_n                 ),
    .ddr3_cas_n                 (ddr3_cas_n                 ),
    .ddr3_we_n                  (ddr3_we_n                  ),
    .ddr3_reset_n               (ddr3_reset_n               ),
    .ddr3_ck_p                  (ddr3_ck_p                  ),
    .ddr3_ck_n                  (ddr3_ck_n                  ),
    .ddr3_cke                   (ddr3_cke                   ),
    .ddr3_cs_n                  (ddr3_cs_n                  ),
    .ddr3_dm                    (ddr3_dm                    ),
    .ddr3_odt                   (ddr3_odt                   ),
    .sys_clk_i                  (clk_200m                   ),
    .app_addr                   ({1'b0,ddr_user_addr,3'd0}  ),
    .app_cmd                    (ddr_user_cmd               ),
    .app_en                     (ddr_user_en                ),
    .app_wdf_data               (ddr_user_wdata             ),
    .app_wdf_end                (ddr_user_wend              ),
    .app_wdf_mask               (ddr_user_mask              ),
    .app_wdf_wren               (ddr_user_wen               ),
    .app_rd_data                (ddr_user_rdata             ),
    .app_rd_data_end            (/*not used*/               ),
    .app_rd_data_valid          (ddr_user_rrdy              ),
    .app_rdy                    (ddr_user_rdy               ),
    .app_wdf_rdy                (ddr_user_wrdy              ),
    .app_sr_req                 (1'b0                       ),
    .app_ref_req                (1'b0                       ),
    .app_zq_req                 (1'b0                       ),
    .app_sr_active              (/*not used*/               ),
    .app_ref_ack                (/*not used*/               ),
    .app_zq_ack                 (/*not used*/               ),
    .ui_clk                     (ui_clk                     ),
    .ui_clk_sync_rst            (ui_clk_sync_rst            ),
    .init_calib_complete        (init_done                  ),
    .device_temp_i              (device_temp_i              ),
    .device_temp                (/*not used*/               ),
    .sys_rst                    (ddr_cntrl_rst[0]           )
);
`endif
authorize_sub_module #(
    .U_DLY                      (U_DLY                      )
)
u_authorize_sub_module(
    .clk                        (clk_100m                   ),
    .rst                        (hard_rst                   ),
    .key                        (32'h4C_4A_43_44            ),
//
    .authorize_code             (authorize_code             ),
//
    .authorize_succ             (authorize_succ             )
);

endmodule
