// *********************************************************************************/
// Project Name :
// Author       : dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/11/2 16:08:44
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Sichuan shenrong digital equipment Co., Ltd.. 
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
module pcie_app_gen3_belta # (
parameter                           WCHN_NUM   = 32,
parameter                           RCHN_NUM   = 9,
parameter                           WDATA_WIDTH= 512,
parameter                           RDATA_WIDTH= 512,
parameter                           WCHN_NUM_W = clog2b(WCHN_NUM),
parameter                           RCHN_NUM_W = clog2b(RCHN_NUM),
parameter                           WPHY_NUM   = 1,
parameter                           WPHY_NUM_W = clog2b(WPHY_NUM),
parameter                           RTAG_NUM   = 16,//32/16
parameter                           RBURST_LEN = 2048,
parameter                           BURST_LEN  = 2048,
parameter                           U_DLY      = 1
)
(
input                               ref_clk,
input                               ref_reset_n,
input                               sys_clk,
input                               sys_rst_n,
output                              user_clk,
output                              user_rst_n,
input                               rtc_s_flg,
input                               rtc_us_flg,

output      [7:0]                   pci_exp_txn,
output      [7:0]                   pci_exp_txp,
input       [7:0]                   pci_exp_rxn,
input       [7:0]                   pci_exp_rxp,
output                              pcie_link,
//local bus
output                              r_wr_en,
output      [18:0]                  r_addr,         
output      [31:0]                  r_wr_data,     
output                              r_rd_en,         
input       [31:0]                  r_rd_data,

//CIB
input                               pcie_cs,     
input                               pcie_wr,     
input                               pcie_rd,     
input       [7:0]                   pcie_addr,   
input       [31:0]                  pcie_wr_data,
output      [31:0]                  pcie_rd_data,


//MDMA USER Interface
input       [RCHN_NUM-1:0]                  rchn_clk,
input       [RCHN_NUM-1:0]                  rchn_rst_n,
input       [RCHN_NUM-1:0]                  rchn_data_rdy, 
output      [RCHN_NUM-1:0]                  rchn_data_vld,         
output      [RCHN_NUM-1:0]                  rchn_sof,
output      [RCHN_NUM-1:0]                  rchn_eof,
output      [RCHN_NUM*RDATA_WIDTH-1:0]      rchn_data,
output      [(RCHN_NUM*RDATA_WIDTH)/8-1:0]  rchn_keep,
output      [RCHN_NUM*15-1:0]               rchn_length,


input       [WPHY_NUM-1:0]                   wchn_clk,
input       [WPHY_NUM-1:0]                   wchn_rst_n,          
output      [WPHY_NUM-1:0]                   wchn_data_rdy,
input       [WPHY_NUM-1:0]                   wchn_data_vld,
input       [WPHY_NUM-1:0]                   wchn_sof,
input       [WPHY_NUM-1:0]                   wchn_eof,
input       [WPHY_NUM*WDATA_WIDTH-1:0]       wchn_data,
input       [WPHY_NUM-1:0]                   wchn_end,
input       [(WPHY_NUM*WDATA_WIDTH)/8-1:0]   wchn_keep,
input       [WPHY_NUM*15-1:0]                wchn_length,
input       [WPHY_NUM*WCHN_NUM_W-1:0]        wchn_chn
) /* synthesis syn_maxfan = 20 */;
// Parameter Define 

localparam                          PCI_EXP_EP_OUI   = 24'h000A35;
localparam                          PCI_EXP_EP_DSN_1 = {{8'h1},PCI_EXP_EP_OUI};
localparam                          PCI_EXP_EP_DSN_2 = 32'h1;


// Register Define 
reg                                 cfg_power_state_change_ack;

// Wire Define 
//pcie3
wire                                user_reset;
wire                                user_lnk_up;
wire                                s_axis_rq_tlast;
wire    [255:0]                     s_axis_rq_tdata;
wire    [59:0]                      s_axis_rq_tuser;
wire    [7:0]                       s_axis_rq_tkeep;
wire    [3:0]                       s_axis_rq_tready;
wire                                s_axis_rq_tvalid;
wire    [255:0]                     m_axis_rc_tdata;
wire    [74:0]                      m_axis_rc_tuser;
wire                                m_axis_rc_tlast;
wire    [7:0]                       m_axis_rc_tkeep;
wire                                m_axis_rc_tvalid;
wire                                m_axis_rc_tready;
wire    [255:0]                     m_axis_cq_tdata;
wire    [84:0]                      m_axis_cq_tuser;
wire                                m_axis_cq_tlast;
wire    [7:0]                       m_axis_cq_tkeep;
wire                                m_axis_cq_tvalid;
wire                                m_axis_cq_tready;
wire    [255:0]                     s_axis_cc_tdata;
wire    [32:0]                      s_axis_cc_tuser;
wire                                s_axis_cc_tlast;
wire    [7:0]                       s_axis_cc_tkeep;
wire                                s_axis_cc_tvalid;
wire    [3:0]                       s_axis_cc_tready;
wire    [3:0]                       cfg_negotiated_width;
wire    [2:0]                       cfg_current_speed;
wire    [2:0]                       cfg_max_payload;
wire    [2:0]                       cfg_max_read_req;
wire                                cfg_power_state_change_interrupt;
wire                                err_type_l;
wire                                err_bar_l;
wire                                err_len_l;
wire    [1:0]                       cfg_interrupt_msi_enable;
wire                                cfg_interrupt_msi_sent;
wire                                cfg_interrupt_msi_fail;
wire    [31:0]                      cfg_interrupt_msi_int;
wire                                rmem_wr;
wire    [7:0]                       rmem_waddr;
wire    [511:0]                     rmem_wdata;
wire    [RCHN_NUM-1:0]              rfifo_empty;
wire    [RCHN_NUM-1:0]              rfifo_prog_full;
wire    [RCHN_NUM-1:0]              rfifo_wr;
wire    [RDATA_WIDTH-1:0]           rfifo_wr_data;
wire                                txfifo_abnormal_rst;
wire                                soft_rst;
wire                                sys_rst_n_x;
wire    [WPHY_NUM-1:0]              wchn_eflg;
wire    [WPHY_NUM-1:0]              wchn_eflg_clr;
wire    [WPHY_NUM-1:0]              cfifo_overflow;
wire    [WPHY_NUM-1:0]              cfifo_empty;
wire    [31:0]                      band;
wire    [31:0]                      rx_band;
wire                                wdma_int_dis;
wire                                rdma_int_dis;
//wire                                int_release;
wire    [WCHN_NUM-1:0]              wchn_dma_en;
wire    [32*WCHN_NUM-1:0]           wchn_dma_addr;
wire    [32*WCHN_NUM-1:0]           wchn_dma_addr_h;
wire    [24*WCHN_NUM-1:0]           wchn_dma_len;
wire    [64*WCHN_NUM-1:0]           wchn_dma_rev;
wire                                wchn_len_done;
wire    [WCHN_NUM_W-1:0]            wchn_len_chn;
wire                                wdma_stop;
wire                                wchn_dma_done;
wire                                wchn_dma_end;
wire    [WCHN_NUM_W-1:0]            wchn_dma_chn;
wire    [23:0]                      wchn_dma_count;
wire    [31:0]                      wchn_dma_daddr;
wire    [31:0]                      wchn_dma_daddr_h;
wire    [63:0]                      wchn_dma_drev;
wire    [RCHN_NUM-1:0]              rchn_dma_en;
wire    [32*RCHN_NUM-1:0]           rchn_dma_addr;
wire    [32*RCHN_NUM-1:0]           rchn_dma_addr_h;
wire    [24*RCHN_NUM-1:0]           rchn_dma_len;
wire    [64*RCHN_NUM-1:0]           rchn_dma_rev;
wire                                rdma_stop;
wire                                rchn_dma_done;
wire    [RCHN_NUM_W-1:0]            rchn_dma_chn;
wire    [31:0]                      rchn_dma_daddr;
wire    [31:0]                      rchn_dma_daddr_h;
wire    [63:0]                      rchn_dma_drev;
wire    [9:0]                       wdma_tlp_size;
wire    [9:0]                       rdma_tlp_size;
wire                                rchn_st;
wire    [32*RCHN_NUM-1:0]           rchn_cnt;
wire    [32*RCHN_NUM-1:0]           rchn_cnt_h;
wire    [RCHN_NUM-1:0]              rchn_terr;
wire    [RCHN_NUM-1:0]              rfifo_overflow;
wire    [RCHN_NUM-1:0]              rfifo_underflow;
wire    [1:0]                       t_rchn_cur_st;
wire                                trabt_err;
wire                                wchnindex_err;
wire    [WCHN_NUM_W-1:0]            wchn_curr_index;

wire                                rc_is_err;
wire                                rc_is_fail;

wire                                tag_release;
wire                                rib_wen;
wire    [191:0]                     rib_din;
wire                                rib_prog_full;
wire                                wdb_full;
wire                                wdb_prog_full;
wire                                wdb_wen;
wire    [512-1:0]                   wdb_din; 
wire                                wib_full;
wire                                wib_prog_full;
wire                                wib_wen;
wire    [255:0]                     wib_din;

wire                                wib_empty;
wire                                wib_ren;
wire    [255:0]                     wib_dout;
wire                                rib_empty;
wire                                rib_ren;
wire    [191:0]                     rib_dout;
wire                                wdb_empty;
wire                                wdb_ren;
wire    [512-1:0]                   wdb_dout;

wire    [WPHY_NUM-1:0]              wchn_ren;
wire    [WPHY_NUM-1:0]              wchn_dvld; 
wire    [WPHY_NUM*(528+WCHN_NUM_W)-1:0] wchn_dout;
//pcie output
wire    [WPHY_NUM-1:0]              built_in;
wire    [WPHY_NUM*512-1:0]          ds_rx_data;
wire    [WPHY_NUM-1:0]              ds_rx_data_vld;
wire                                wdb_overflow;
wire                                wib_overflow;
wire                                wdb_underflow;
wire    [1:0]                       t_wchn_cur_st;


wire    [22-1:0]                    ds_tbucket_width;
wire    [22-1:0]                    ds_tbucket_deepth;
wire    [3-1:0]                     ds_data_mode;
wire    [63:0]                      ds_static_pattern;
wire    [1-1:0]                     ds_tx_len_start;
wire    [1-1:0]                     ds_tx_con_start;
wire    [1*32-1:0]                  ds_len_mode_count;
wire    [1-1:0]                     check_st;

//cib


assign pcie_link = user_lnk_up;
assign user_rst_n =  ~user_reset;
assign sys_rst_n_x = (sys_rst_n) & (~soft_rst) &( ~user_reset);



//----------------------------------------------------------------
//u_couple_logic
//----------------------------------------------------------------
genvar i;
generate 
for(i=0;i<WPHY_NUM;i=i+1)
begin   
couple_logic # (
    .WCHN_NUM_W                 (WCHN_NUM_W                 ),
    .WDATA_WIDTH                (WDATA_WIDTH                ),
    .BUILTIN_NUM                (i                          ),
    .BURST_LEN                  (BURST_LEN                  ),
    .U_DLY                      (U_DLY                      )
)u_couple_logic
(
    .wr_clk                     (wchn_clk[i]                ),
    .wr_rst_n                   (sys_rst_n_x & wchn_rst_n[i]),
    
    .rd_clk                     (sys_clk                    ),
    .rd_rst_n                   (sys_rst_n_x & wchn_rst_n[i]),
    .built_in                   (built_in[i]                ),
    .ds_rx_data_vld             (ds_rx_data_vld[i]          ),
    .ds_rx_data                 (ds_rx_data[512*i+:512]     ),
    
    .wchn_data_rdy              (wchn_data_rdy[i]           ),
    .wchn_data_vld              (wchn_data_vld[i]           ),
    .wchn_sof                   (wchn_sof[i]                ),
    .wchn_eof                   (wchn_eof[i]                ),
    .wchn_data                  (wchn_data[WDATA_WIDTH*i+:WDATA_WIDTH]),
    .wchn_end                   (wchn_end[i]                ),
    .wchn_keep                  (wchn_keep[(WDATA_WIDTH/8)*i+:(WDATA_WIDTH/8)]),
    .wchn_length                (wchn_length[15*i+:15]      ),
    .wchn_chn                   (wchn_chn[WCHN_NUM_W*i+:WCHN_NUM_W]),
 
    .wchn_eflg                  (wchn_eflg[i]               ),
    .wchn_eflg_clr              (wchn_eflg_clr[i]           ),
    .wchn_ren                   (wchn_ren[i]                ),
    .wchn_dvld                  (wchn_dvld[i]               ),
    .wchn_dout                  (wchn_dout[(528+WCHN_NUM_W)*i+:(528+WCHN_NUM_W)]),
    .cfifo_overflow             (cfifo_overflow[i]             ),
    .cfifo_empty                (cfifo_empty[i]                )
);



datas_builtin_top # (
    .U_DLY                      (U_DLY                      ),
    .TBUCKET_DEEPTH             ('d8000                     )
)u_datas_builtin_top
(
    .clk                        (wchn_clk[i]                ),   
    .rst_n                      (sys_rst_n_x & wchn_rst_n[i]),   
    .chk_clk                    (wchn_clk[i]                ),   
    .chk_rst_n                  (sys_rst_n_x & wchn_rst_n[i]),   
    .rtc_us_flg                 (rtc_us_flg                 ),
//                                                                
    .ds_tbucket_deepth          (ds_tbucket_deepth          ),
    .ds_tbucket_width           (ds_tbucket_width           ),

    .ds_data_mode               (ds_data_mode               ),
    .ds_static_pattern          (ds_static_pattern          ),
    .ds_tx_len_start            (ds_tx_len_start            ),
    .ds_tx_con_start            (ds_tx_con_start            ),
    .ds_len_mode_count          (ds_len_mode_count          ),

    .check_st                   (check_st                   ),
    .file_len                   (                           ),
    .err_num_8bit               (                           ),
    .err_len_8bit               (                           ),
    .err_num_prbs31             (                           ),
    .err_len_prbs31             (                           ),
    .err_num_128bit             (                           ),
    .err_len_128bit             (                           ),
    .errcontext_8bit_wr         (                           ),
    .errcontext_8bit_wr_addr    (                           ),
    .errcontext_8bit_wr_data    (                           ),
    .errcontext_prbs31_wr       (                           ),
    .errcontext_prbs31_wr_addr  (                           ),
    .errcontext_prbs31_wr_data  (                           ),
    .errcontext_128bit_wr       (                           ),
    .errcontext_128bit_wr_addr  (                           ),
    .errcontext_128bit_wr_data  (                           ),

    .full                       (~wchn_data_rdy[i]          ),
    .ds_rx_data                 (ds_rx_data[512*i+:512]     ),
    .ds_rx_keep                 (                           ),
    .ds_rx_data_vld             (ds_rx_data_vld[i]          ),
    .ds_rx_last                 (                           ),

    .ds_tx_tdata                (512'b0                     ),
    .ds_tx_tkeep                (64'b0                      ),
    .ds_tx_tvalid               (1'b0                       ),
    .ds_tx_tlast                (1'b0                       ),
    .ds_tx_tready               (                           ),
    .ds_send_done               (                           )

);
end
endgenerate
 
bandcount # (
    .U_DLY                      (U_DLY                      ),
    .DATAW                      (WDATA_WIDTH                )
)u_bandcount(
    .clk                        (sys_clk                    ),
    .rst_n                      (sys_rst_n_x                ),
    .rtc_s_flg                  (rtc_s_flg                  ),
    .valid                      (wdb_wen                    ),
    .band                       (band                       )
);

bandcount # (
    .U_DLY                      (U_DLY                      ),
    .DATAW                      (RDATA_WIDTH                )
)u_bandcount_rx(
    .clk                        (sys_clk                    ),
    .rst_n                      (sys_rst_n_x                ),
    .rtc_s_flg                  (rtc_s_flg                  ),
    .valid                      (|rfifo_wr                  ),
    .band                       (rx_band                    )
);

//----------------------------------------------------------------
//u_pcie_rchn_couple
//----------------------------------------------------------------
genvar j;
generate 
for(j=0;j<RCHN_NUM;j=j+1)
begin
pcie_rchn_couple #(
    .U_DLY                      (U_DLY                      ),
    .RDATA_WIDTH                (RDATA_WIDTH                ),
    .RBURST_LEN                 (RBURST_LEN                 )
)u_pcie_rchn_couple
(
    .sys_clk                    (sys_clk                    ),
    .sys_rst_n                  (sys_rst_n_x & rchn_rst_n[j]),

    .rd_clk                     (rchn_clk[j]                ),
    .rd_rst_n                   (sys_rst_n_x & rchn_rst_n[j]),
    
    .rchn_st                    (rchn_st                    ),
    .rchn_cnt                   (rchn_cnt[32*j+:32]         ),
    .rchn_cnt_h                 (rchn_cnt_h[32*j+:32]       ),
    .rchn_terr                  (rchn_terr[j]               ),    
    
    
    .rfifo_empty                (rfifo_empty[j]             ),
    .rfifo_prog_full            (rfifo_prog_full[j]         ),
    .rfifo_wr                   (rfifo_wr[j]                ),
    .rfifo_wr_data              (rfifo_wr_data              ),

    .rchn_data_rdy              (rchn_data_rdy[j]           ),
    .rchn_data_vld              (rchn_data_vld[j]           ),
    .rchn_sof                   (rchn_sof[j]                ),
    .rchn_eof                   (rchn_eof[j]                ),
    .rchn_data                  (rchn_data[(RDATA_WIDTH)*j+:RDATA_WIDTH]      ),
    .rchn_keep                  (rchn_keep[(RDATA_WIDTH/8)*j +: (RDATA_WIDTH/8)]),
    .rchn_length                (rchn_length[15*j+:15]      ),
    
    .rfifo_overflow             (rfifo_overflow[j]          ),
    .rfifo_underflow            (rfifo_underflow[j]         )
   
    
);
end
endgenerate
//----------------------------------------------------------------
//u_pcie_cib
//----------------------------------------------------------------

pcie_cib #(
    .U_DLY                      (U_DLY                      ),
    .WCHN_NUM                   (WCHN_NUM                   ),
    .WCHN_NUM_W                 (WCHN_NUM_W                 ),
    .RCHN_NUM                   (RCHN_NUM                   ),
    .RCHN_NUM_W                 (RCHN_NUM_W                 ),
    .WPHY_NUM                   (WPHY_NUM                   ),
    .WPHY_NUM_W                 (WPHY_NUM_W                 )
)u_pcie_cib
(
    .clk                        (sys_clk                    ),
    .rst_n                      (~user_reset                ),

    .cpu_cs                     (pcie_cs                    ),
    .cpu_wr                     (pcie_wr                    ),
    .cpu_rd                     (pcie_rd                    ),
    .cpu_addr                   (pcie_addr                  ),
    .cpu_wr_data                (pcie_wr_data               ),
    .cpu_rd_data                (pcie_rd_data               ),

    .band                       (band                       ),
    .rx_band                    (rx_band                    ),
    .wdma_int_dis               (wdma_int_dis               ),
    .rdma_int_dis               (rdma_int_dis               ),
    .rtc_us_flg                 (rtc_us_flg                 ),
    //WDMA
    .wchn_dma_addr              (wchn_dma_addr              ),
    .wchn_dma_addr_h            (wchn_dma_addr_h            ),
    .wchn_dma_en                (wchn_dma_en                ),
    .wchn_dma_len               (wchn_dma_len               ),
    .wchn_dma_rev               (wchn_dma_rev               ),
    .wchn_len_done              (wchn_len_done              ),
    .wchn_len_chn               (wchn_len_chn               ),
    .wdma_stop                  (wdma_stop                  ),

    .wchn_dma_done              (wchn_dma_done              ),
    .wchn_dma_end               (wchn_dma_end               ),
    .wchn_dma_chn               (wchn_dma_chn               ),
    .wchn_dma_count             (wchn_dma_count             ),
    .wchn_dma_daddr             (wchn_dma_daddr             ),
    .wchn_dma_drev              (wchn_dma_drev              ),
    .wchn_dma_daddr_h           (wchn_dma_daddr_h           ),
   
    //RDMA
    .rchn_dma_en                (rchn_dma_en                ),
    .rchn_dma_addr              (rchn_dma_addr              ),
    .rchn_dma_len               (rchn_dma_len               ),
    .rchn_dma_rev               (rchn_dma_rev               ),
    .rdma_stop                  (rdma_stop                  ),
    .rchn_dma_addr_h            (rchn_dma_addr_h            ),

    .rchn_dma_done              (rchn_dma_done              ),
    .rchn_dma_chn               (rchn_dma_chn               ),
    .rchn_dma_daddr             (rchn_dma_daddr             ),
    .rchn_dma_drev              (rchn_dma_drev              ),
    .rchn_dma_daddr_h           (rchn_dma_daddr_h           ),

    .wdma_tlp_size              (wdma_tlp_size              ),
    .rdma_tlp_size              (rdma_tlp_size              ),

    .cfg_negotiated_width       (cfg_negotiated_width       ),
    .cfg_current_speed          (cfg_current_speed          ),
    .cfg_max_payload            (cfg_max_payload            ),
    .cfg_max_read_req           (cfg_max_read_req           ),


    .built_in                   (built_in                   ),
    .ds_tbucket_width           (ds_tbucket_width           ),
    .ds_tbucket_deepth          (ds_tbucket_deepth          ),
    .ds_data_mode               (ds_data_mode               ),
    .ds_static_pattern          (ds_static_pattern          ),
    .ds_tx_len_start            (ds_tx_len_start            ),
    .ds_tx_con_start            (ds_tx_con_start            ),
    .ds_len_mode_count          (ds_len_mode_count          ),
    .check_st                   (check_st                   ), 
    .soft_rst                   (soft_rst                   ),

    .wdb_overflow               (wdb_overflow               ),
    .wib_overflow               (wib_overflow               ),
    .wdb_underflow              (wdb_underflow              ),
    .cfifo_overflow             ({ {(8-WPHY_NUM){1'b0}},cfifo_overflow}             ),
    .cfifo_empty                ({ {(8-WPHY_NUM){1'b1}},cfifo_empty}                ),
    .wchn_dvld                  ({ {(8-WPHY_NUM){1'b0}},wchn_dvld}                  ),
    .t_wchn_cur_st              (t_wchn_cur_st              ), 
    .wchnindex_err              (wchnindex_err              ),
    .wchn_curr_index            (wchn_curr_index            ),
    .wib_empty                  (wib_empty                  ),
    .wdb_empty                  (wdb_empty                  ),
    .rib_empty                  (rib_empty                  ),

    .err_type_l                 (err_type_l                 ),
    .err_bar_l                  (err_bar_l                  ),
    .err_len_l                  (err_len_l                  ),
    .rc_is_err                  (rc_is_err                  ),
    .rc_is_fail                 (rc_is_fail                 ),
    
    .rfifo_empty                (rfifo_empty                ),
    .txfifo_abnormal_rst        (txfifo_abnormal_rst        ),
    
    .rchn_st                    (rchn_st                    ),
    .rchn_cnt                   (rchn_cnt[31:0]             ),
    .rchn_cnt_h                 (rchn_cnt_h[31:0]           ), 
    .rchn_terr                  (rchn_terr                  ),
    
    .rfifo_overflow             (rfifo_overflow             ),
    .rfifo_underflow            (rfifo_underflow            ),
    
    .t_rchn_cur_st              (t_rchn_cur_st              ),
    .trabt_err                  (trabt_err                  )

);

//----------------------------------------------------------------
// u_pcie_regif_gen3
//----------------------------------------------------------------
pcie_regif_gen3 #(
    .U_DLY                      (U_DLY                      )
)u_pcie_regif_gen3
(
    .clk                        (user_clk                   ),
    .rst_n                      (~user_reset                ),
    .m_axis_cq_tdata            (m_axis_cq_tdata            ),
    .m_axis_cq_tuser            (m_axis_cq_tuser            ),
    .m_axis_cq_tlast            (m_axis_cq_tlast            ),
    .m_axis_cq_tkeep            (m_axis_cq_tkeep            ),
    .m_axis_cq_tvalid           (m_axis_cq_tvalid           ),
    .m_axis_cq_tready           (m_axis_cq_tready           ),

    .s_axis_cc_tdata            (s_axis_cc_tdata            ),
    .s_axis_cc_tuser            (s_axis_cc_tuser            ),
    .s_axis_cc_tlast            (s_axis_cc_tlast            ),
    .s_axis_cc_tkeep            (s_axis_cc_tkeep            ),
    .s_axis_cc_tvalid           (s_axis_cc_tvalid           ),
    .s_axis_cc_tready           (s_axis_cc_tready[0]        ),

    .r_wr_en                    (r_wr_en                    ),
    .r_addr                     (r_addr                     ),
    .r_wr_data                  (r_wr_data                  ),
    .r_rd_en                    (r_rd_en                    ),
    .r_rd_data                  (r_rd_data                  ),

    .err_type_l                 (err_type_l                 ),
    .err_bar_l                  (err_bar_l                  ),
    .err_len_l                  (err_len_l                  )  
    
);                                                               
//----------------------------------------------------------------  
//u_pcie_rx_engine_gen3                                             
//----------------------------------------------------------------  
pcie_rx_engine_gen3 # (
    .U_DLY                      (U_DLY                      ),
    .RTAG_NUM                   (RTAG_NUM                   )
)u_pcie_rx_engine_gen3
(
    .clk                        (user_clk                   ),
    .rst_n                      (sys_rst_n_x                ),
    .cfg_max_payload            (cfg_max_payload            ),
    .rchn_st                    (rchn_st                    ),
//  Requester Completion Package
    .m_axis_rc_tdata            (m_axis_rc_tdata            ),
    .m_axis_rc_tuser            (m_axis_rc_tuser            ),
    .m_axis_rc_tlast            (m_axis_rc_tlast            ),
    .m_axis_rc_tkeep            (m_axis_rc_tkeep            ),
    .m_axis_rc_tvalid           (m_axis_rc_tvalid           ),
    .m_axis_rc_tready           (m_axis_rc_tready           ),
//
    .tag_release                (tag_release                ),
//  RX Buffer
    .rmem_wr                    (rmem_wr                    ),
    .rmem_waddr                 (rmem_waddr                 ),
    .rmem_wdata                 (rmem_wdata                 ),
//  Debug Interface
    .rc_is_err                  (rc_is_err                  ),
    .rc_is_fail                 (rc_is_fail                 )
    
);

//----------------------------------------------------------------
//u_pcie_rchn_arbiter
//----------------------------------------------------------------
pcie_rchn_arbiter#(
    .RCHN_NUM                   (RCHN_NUM                   ),
    .RCHN_NUM_W                 (RCHN_NUM_W                 ),
    .RTAG_NUM                   (RTAG_NUM                   ), 
    .RDATA_WIDTH                (RDATA_WIDTH                ),
    .U_DLY                      (U_DLY                      )
)u_pcie_rchn_arbiter
(
    .clk                        (sys_clk                    ),
    .rst_n                      (sys_rst_n_x                ),
    .rdma_tlp_size              (rdma_tlp_size              ),
    .rdma_stop                  (rdma_stop                  ),

    .tag_release                (tag_release                ),

    .rchn_dma_addr              (rchn_dma_addr[RCHN_NUM*32-1:0]     ),
    .rchn_dma_en                (rchn_dma_en[RCHN_NUM-1:0]          ),
    .rchn_dma_len               (rchn_dma_len[RCHN_NUM*24-1:0]      ),
    .rchn_dma_rev               (rchn_dma_rev[RCHN_NUM*64-1:0]      ),    
    .rchn_dma_addr_h            (rchn_dma_addr_h[RCHN_NUM*32-1:0]   ),

    .rib_wen                    (rib_wen                    ),
    .rib_din                    (rib_din                    ),
    .rib_prog_full              (rib_prog_full              ),

    .wr_clk                     (user_clk                   ), 
    .rmem_wr                    (rmem_wr                    ), 
    .rmem_waddr                 (rmem_waddr                 ), 
    .rmem_wdata                 (rmem_wdata                 ), 

    .rfifo_prog_full            (rfifo_prog_full            ),
    .rfifo_wr                   (rfifo_wr                   ),
    .rfifo_wr_data              (rfifo_wr_data              ),
    .t_rchn_cur_st              (t_rchn_cur_st              )
    


);



//----------------------------------------------------------------
//u_rib_fifo
//----------------------------------------------------------------
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (192                        ),
    .DATA_DEEPTH                (64                         ),
    .ADDR_WIDTH                 (6                          )
)u_rib_fifo
(
    .wr_clk                     (sys_clk                    ),
    .wr_rst_n                   (sys_rst_n_x                ),
    .rd_clk                     (user_clk                   ),
    .rd_rst_n                   (sys_rst_n_x                ),
    .din                        (rib_din                    ),
    .wr_en                      (rib_wen                    ),
    .rd_en                      (rib_ren                    ),
    .dout                       (rib_dout                   ),
    .full                       (                           ),
    .prog_full                  (rib_prog_full              ),
    .empty                      (rib_empty                  ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (6'd32                      ),
    .prog_empty_thresh          (6'd2                       ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )

);


//----------------------------------------------------------------
//u_pcie_wchn_arbiter
//----------------------------------------------------------------
pcie_wchn_arbiter#(
    .WCHN_NUM                   (WCHN_NUM                   ),
    .WCHN_NUM_W                 (WCHN_NUM_W                 ),
    .WPHY_NUM                   (WPHY_NUM                   ),
    .WPHY_NUM_W                 (WPHY_NUM_W                 ),
    .BURST_LEN                  (BURST_LEN                  ),
    .U_DLY                      (U_DLY                      )
)u_pcie_wchn_arbiter
(
    .clk                        (sys_clk                    ),
    .rst_n                      (sys_rst_n_x                ),
    .wdma_tlp_size              (wdma_tlp_size              ),
    .wdma_stop                  (wdma_stop                  ),

    .wchn_eflg                  (wchn_eflg                  ),
    .wchn_eflg_clr              (wchn_eflg_clr              ),
    .wchn_dvld                  (wchn_dvld                  ),
    .wchn_ren                   (wchn_ren                   ),
    .wchn_dout                  (wchn_dout                  ),

    .wchn_dma_addr              (wchn_dma_addr[WCHN_NUM*32-1:0]     ),
    .wchn_dma_addr_h            (wchn_dma_addr_h[WCHN_NUM*32-1:0]   ),
    .wchn_dma_en                (wchn_dma_en[WCHN_NUM-1:0]          ),
    .wchn_dma_len               (wchn_dma_len[WCHN_NUM*24-1:0]      ),
    .wchn_dma_rev               (wchn_dma_rev[WCHN_NUM*64-1:0]      ),
    .wchn_len_done              (wchn_len_done              ),
    .wchn_len_chn               (wchn_len_chn               ),

    
    //wchn_data_fifo
    .wdb_full                   (wdb_full                   ),
    .wdb_prog_full              (wdb_prog_full              ),
    .wdb_wen                    (wdb_wen                    ),
    .wdb_din                    (wdb_din                    ),
    //wchn_info_fifo
    .wib_full                   (wib_full                   ),   
    .wib_prog_full              (wib_prog_full              ), 
    .wib_wen                    (wib_wen                    ),
    .wib_din                    (wib_din                    ),
    
    .wdb_overflow               (wdb_overflow               ),
    .wib_overflow               (wib_overflow               ),
    .t_wchn_cur_st              (t_wchn_cur_st              ),
    .wchnindex_err              (wchnindex_err              ),
    .wchn_curr_index            (wchn_curr_index            )

);

//----------------------------------------------------------------
//u_wib_fifo
//----------------------------------------------------------------
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (256                        ),
    .DATA_DEEPTH                (128                        ),
    .ADDR_WIDTH                 (7                          )
)u_wib_fifo
(
    .wr_clk                     (sys_clk                    ),
    .wr_rst_n                   (sys_rst_n_x&(~txfifo_abnormal_rst)),
    .rd_clk                     (user_clk                   ),
    .rd_rst_n                   (sys_rst_n_x&(~txfifo_abnormal_rst)),
    .din                        (wib_din                    ),
    .wr_en                      (wib_wen                    ),
    .rd_en                      (wib_ren                    ),
    .dout                       (wib_dout                   ),
    .full                       (wib_full                   ),
    .prog_full                  (wib_prog_full              ),
    .empty                      (wib_empty                  ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (7'd64                      ),
    .prog_empty_thresh          (7'd4                       ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )
);

//----------------------------------------------------------------
//u_wdb_fifo
//----------------------------------------------------------------
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (512                        ),
    .DATA_DEEPTH                (512                        ),
    .ADDR_WIDTH                 (9                          )
)u_wdb_fifo
(
    .wr_clk                     (sys_clk                    ),
    .wr_rst_n                   ((sys_rst_n_x)&(~txfifo_abnormal_rst)),
    .rd_clk                     (user_clk                   ),
    .rd_rst_n                   ((sys_rst_n_x)&(~txfifo_abnormal_rst)),
    .din                        (wdb_din                    ),
    .wr_en                      (wdb_wen                    ),
    .rd_en                      (wdb_ren                    ),
    .dout                       (wdb_dout                   ),
    .full                       (wdb_full                   ),
    .prog_full                  (wdb_prog_full              ),
    .empty                      (wdb_empty                  ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (9'd128                     ),
    .prog_empty_thresh          (9'd4                       ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )

);

//----------------------------------------------------------------
//u_pcie_tx_engine_gen3
//----------------------------------------------------------------
pcie_tx_engine_gen3 # (
    .U_DLY                      (U_DLY                           ),
    .WCHN_NUM                   (WCHN_NUM                        ),
    .RCHN_NUM                   (RCHN_NUM                        )
)u_pcie_tx_engine_gen3
(
    .clk                        (user_clk                        ),
    .rst_n                      (sys_rst_n_x                     ),
    
    .wdma_tlp_size              (wdma_tlp_size                   ),  
 
    .wchn_dma_done              (wchn_dma_done                   ),
    .wchn_dma_end               (wchn_dma_end                    ),
    .wchn_dma_chn               (wchn_dma_chn                    ),
    .wchn_dma_count             (wchn_dma_count                  ),
    .wchn_dma_daddr             (wchn_dma_daddr                  ),
    .wchn_dma_drev              (wchn_dma_drev                   ),
    .wchn_dma_daddr_h           (wchn_dma_daddr_h                ),

    .rchn_dma_done              (rchn_dma_done                   ),
    .rchn_dma_chn               (rchn_dma_chn                    ),
    .rchn_dma_daddr             (rchn_dma_daddr                  ),
    .rchn_dma_drev              (rchn_dma_drev                   ),
    .rchn_dma_daddr_h           (rchn_dma_daddr_h                ),

    .s_axis_rq_tlast            (s_axis_rq_tlast                 ),
    .s_axis_rq_tdata            (s_axis_rq_tdata                 ),
    .s_axis_rq_tuser            (s_axis_rq_tuser                 ),
    .s_axis_rq_tkeep            (s_axis_rq_tkeep                 ),
    .s_axis_rq_tready           (s_axis_rq_tready[0]             ),
    .s_axis_rq_tvalid           (s_axis_rq_tvalid                ),

    .wib_empty                  (wib_empty                       ),
    .wib_ren                    (wib_ren                         ),
    .wib_dout                   (wib_dout                        ),

    .rib_empty                  (rib_empty                       ),
    .rib_ren                    (rib_ren                         ),
    .rib_dout                   (rib_dout                        ),

    .wdb_empty                  (wdb_empty                       ),
    .wdb_ren                    (wdb_ren                         ),
    .wdb_dout                   (wdb_dout                        ),
    .wdb_underflow              (wdb_underflow                   ),
    .txfifo_abnormal_rst        (txfifo_abnormal_rst             ),
    .trabt_err                  (trabt_err                       ) 

);

//----------------------------------------------------------------
//u_pcie_msi_engine_gen3
//----------------------------------------------------------------

pcie_msi_engine_gen3#(
    .U_DLY                      (U_DLY                      ) 
)
u_pcie_msi_engine_gen3(
    .clk                        (user_clk                   ),
    .rst_n                      (sys_rst_n_x                ),
    .wdma_int_dis               (wdma_int_dis               ),
    .rdma_int_dis               (rdma_int_dis               ),
//    .int_release                (int_release                ),
    .wchn_dma_done              (wchn_dma_done               ),
    .rchn_dma_done              (rchn_dma_done              ),
    .cfg_interrupt_msi_enable   (cfg_interrupt_msi_enable[0]),
    .cfg_interrupt_msi_sent     (cfg_interrupt_msi_sent     ),
    .cfg_interrupt_msi_fail     (cfg_interrupt_msi_fail     ),
    .cfg_interrupt_msi_int      (cfg_interrupt_msi_int      )

);



//----------------------------------------------------------------
//u_pcie3_7x_0
//----------------------------------------------------------------
pcie3_7x_0 u_pcie3_7x_0(
    .pci_exp_txn                (pci_exp_txn                ),
    .pci_exp_txp                (pci_exp_txp                ),
    .pci_exp_rxn                (pci_exp_rxn                ),
    .pci_exp_rxp                (pci_exp_rxp                ),
    .int_pclk_out_slave         (                           ),
    .int_pipe_rxusrclk_out      (                           ),
    .int_rxoutclk_out           (                           ),
    .int_dclk_out               (                           ),
    .int_userclk1_out           (                           ),
    .int_userclk2_out           (                           ),
    .int_oobclk_out             (                           ),
    .int_qplllock_out           (                           ),
    .int_qplloutclk_out         (                           ),
    .int_qplloutrefclk_out      (                           ),
    .int_pclk_sel_slave         (8'b0                       ), //input [7:0]
    .mmcm_lock                  (                           ),
    .user_clk                   (user_clk                   ),
    .user_reset                 (user_reset                 ),
    .user_lnk_up                (user_lnk_up                ),
    .user_app_rdy               (                           ),
    .s_axis_rq_tlast            (s_axis_rq_tlast            ),
    .s_axis_rq_tdata            (s_axis_rq_tdata            ),
    .s_axis_rq_tuser            (s_axis_rq_tuser            ),
    .s_axis_rq_tkeep            (s_axis_rq_tkeep            ),
    .s_axis_rq_tready           (s_axis_rq_tready           ),
    .s_axis_rq_tvalid           (s_axis_rq_tvalid           ),
    .m_axis_rc_tdata            (m_axis_rc_tdata            ),
    .m_axis_rc_tuser            (m_axis_rc_tuser            ),
    .m_axis_rc_tlast            (m_axis_rc_tlast            ),
    .m_axis_rc_tkeep            (m_axis_rc_tkeep            ),
    .m_axis_rc_tvalid           (m_axis_rc_tvalid           ),
    .m_axis_rc_tready           (m_axis_rc_tready           ),
    .m_axis_cq_tdata            (m_axis_cq_tdata            ),
    .m_axis_cq_tuser            (m_axis_cq_tuser            ),
    .m_axis_cq_tlast            (m_axis_cq_tlast            ),
    .m_axis_cq_tkeep            (m_axis_cq_tkeep            ),
    .m_axis_cq_tvalid           (m_axis_cq_tvalid           ),
    .m_axis_cq_tready           (m_axis_cq_tready           ),
    .s_axis_cc_tdata            (s_axis_cc_tdata            ),
    .s_axis_cc_tuser            (s_axis_cc_tuser            ),
    .s_axis_cc_tlast            (s_axis_cc_tlast            ),
    .s_axis_cc_tkeep            (s_axis_cc_tkeep            ),
    .s_axis_cc_tvalid           (s_axis_cc_tvalid           ),
    .s_axis_cc_tready           (s_axis_cc_tready           ),
    .pcie_rq_seq_num            (                           ),
    .pcie_rq_seq_num_vld        (                           ),
    .pcie_rq_tag                (                           ),
    .pcie_rq_tag_vld            (                           ),
    .pcie_tfc_nph_av            (                           ),
    .pcie_tfc_npd_av            (                           ),
    .pcie_cq_np_req             (1'b1                       ),
    .pcie_cq_np_req_count       (                           ),
    .cfg_phy_link_down          (                           ),
    .cfg_phy_link_status        (                           ),
    .cfg_negotiated_width       (cfg_negotiated_width       ),
    .cfg_current_speed          (cfg_current_speed          ),
    .cfg_max_payload            (cfg_max_payload            ),
    .cfg_max_read_req           (cfg_max_read_req           ),
    .cfg_function_status        (                           ),
    .cfg_function_power_state   (                           ),
    .cfg_vf_status              (                           ),
    .cfg_vf_power_state         (                           ),
    .cfg_link_power_state       (                           ),
    .cfg_mgmt_addr              (19'b0                      ),
    .cfg_mgmt_write             (1'b0                       ),
    .cfg_mgmt_write_data        (32'b0                      ),
    .cfg_mgmt_byte_enable       (4'b0                       ),
    .cfg_mgmt_read              (1'b0                       ),
    .cfg_mgmt_read_data         (                           ),
    .cfg_mgmt_read_write_done   (                           ),
    .cfg_mgmt_type1_cfg_reg_access(1'b0                     ),
    .cfg_err_cor_out            (                           ),
    .cfg_err_nonfatal_out       (                           ),
    .cfg_err_fatal_out          (                           ),
    .cfg_ltr_enable             (                           ),
    .cfg_ltssm_state            (                           ),
    .cfg_rcb_status             (                           ),
    .cfg_dpa_substate_change    (                           ),
    .cfg_obff_enable            (                           ),
    .cfg_pl_status_change       (                           ),
    .cfg_tph_requester_enable   (                           ),
    .cfg_tph_st_mode            (                           ),
    .cfg_vf_tph_requester_enable(                           ),
    .cfg_vf_tph_st_mode         (                           ),
    .cfg_msg_received           (                           ),
    .cfg_msg_received_data      (                           ),
    .cfg_msg_received_type      (                           ),
    .cfg_msg_transmit           (1'b0                       ),
    .cfg_msg_transmit_type      (3'b0                       ),
    .cfg_msg_transmit_data      (32'b0                      ),
    .cfg_msg_transmit_done      (                           ),
    .cfg_fc_ph                  (                           ),
    .cfg_fc_pd                  (                           ),
    .cfg_fc_nph                 (                           ),
    .cfg_fc_npd                 (                           ),
    .cfg_fc_cplh                (                           ),
    .cfg_fc_cpld                (                           ),
    .cfg_fc_sel                 (3'b0                       ),
    .cfg_per_func_status_control(3'b0                       ),
    .cfg_per_func_status_data   (                           ),
    .cfg_per_function_number    (3'b0                       ),
    .cfg_per_function_output_request(1'b0                   ),
    .cfg_per_function_update_done(                          ),
    .cfg_subsys_vend_id         (16'h10ee                   ),
    .cfg_dsn                    ({PCI_EXP_EP_DSN_2,PCI_EXP_EP_DSN_1}),
    .cfg_power_state_change_ack (cfg_power_state_change_ack ),
    .cfg_power_state_change_interrupt (cfg_power_state_change_interrupt),
    .cfg_err_cor_in             (1'b0                       ),
    .cfg_err_uncor_in           (1'b0                       ),
    .cfg_flr_in_process         (                           ),
    .cfg_flr_done               (2'b0                       ),
    .cfg_vf_flr_in_process      (                           ),
    .cfg_vf_flr_done            (6'b0                       ),
    .cfg_link_training_enable   (1'b1                       ),
//    .cfg_ext_read_received      (                           ),
//    .cfg_ext_write_received     (                           ),
//    .cfg_ext_register_number    (                           ),
//    .cfg_ext_function_number    (                           ),
//    .cfg_ext_write_data         (                           ),
//    .cfg_ext_write_byte_enable  (                           ),
//    .cfg_ext_read_data          (32'b0                      ),
//    .cfg_ext_read_data_valid    (1'b0                       ),
    .cfg_interrupt_int          (4'b0                       ),
    .cfg_interrupt_pending      (2'b0                       ),
    .cfg_interrupt_sent         (                           ),
    .cfg_interrupt_msi_enable   (cfg_interrupt_msi_enable   ),
    .cfg_interrupt_msi_vf_enable(                           ),
    .cfg_interrupt_msi_mmenable (                           ),
    .cfg_interrupt_msi_mask_update (                        ),
    .cfg_interrupt_msi_data     (                           ),
    .cfg_interrupt_msi_select   (4'b0                       ),
    .cfg_interrupt_msi_int      (cfg_interrupt_msi_int      ),//input
    .cfg_interrupt_msi_pending_status(64'b0                 ),
    .cfg_interrupt_msi_sent     (cfg_interrupt_msi_sent     ),//output
    .cfg_interrupt_msi_fail     (cfg_interrupt_msi_fail     ),//output
    .cfg_interrupt_msi_attr     (3'b0                       ),
    .cfg_interrupt_msi_tph_present(1'b0                     ),
    .cfg_interrupt_msi_tph_type (2'b0                       ),
    .cfg_interrupt_msi_tph_st_tag(9'b0                      ),
    .cfg_interrupt_msi_function_number(3'b0                 ),
    .cfg_hot_reset_out          (                           ),
    .cfg_config_space_enable    (1'b1                       ),
    .cfg_req_pm_transition_l23_ready(1'b0                   ),
    .cfg_hot_reset_in           (1'b0                       ),
    .cfg_ds_port_number         (8'b0                       ),
    .cfg_ds_bus_number          (8'b0                       ),
    .cfg_ds_device_number       (5'b0                       ),
    .cfg_ds_function_number     (3'b0                       ),
    .sys_clk                    (ref_clk                    ),
    .sys_reset                  (~ref_reset_n               )
);

always @ (posedge user_clk or posedge user_reset)
begin
    if(user_reset == 1'b1)     
        cfg_power_state_change_ack <= 1'b0;  
    else    
        begin
            if(cfg_power_state_change_interrupt == 1'b1)
                cfg_power_state_change_ack <= #U_DLY 1'b1;
            else
                cfg_power_state_change_ack <= #U_DLY 1'b0;
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
