// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/3/13 10:36:24
// File Name    : mefc_top.v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2018,BoYuLiHua Technology Co., Ltd.. 
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
//`define AUTHORIZE_ENABLE
module mefc_top #(
parameter                           U_DLY = 1,
parameter                           ADDR_W = 26,
parameter                           DATA_W = 16,
parameter                           CPU_ADDR_W = 8
)
(
input                               clk,                 //clock 100M
input                               hard_rst,
input                               rst,
//authorization 
input           [31:0]              authorize_code,
//Io
output          [ADDR_W - 1:0]      io_addr,
output                              io_ce,
output                              io_oe,
output                              io_we,
inout           [DATA_W - 1:0]      io_dq,
input                               io_ry_byn,
//interface with up-stream
output          [DATA_W - 1:0]      read_data,
output                              read_vld,

input           [DATA_W - 1:0]      write_data,
input                               write_vld,
output                              write_rdy,
//cpu
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [CPU_ADDR_W - 1:0]  cpu_addr,
input           [31:0]              cpu_wdata,
output  wire    [31:0]              cpu_rdata
);
// Parameter Define 
localparam                           VERSION =32'h0000_0001;
localparam                           YEAR = 16'h2020;
localparam                           MONTH = 8'h10;
localparam                           DAY = 8'h10;
// Register Define 

// Wire Define 
wire    [DATA_W - 1:0]              rdata;
wire    [DATA_W - 1:0]              wdata;
wire    [ADDR_W - 1:0]              op_addr;
wire    [DATA_W - 1:0]              op_wdata;
wire    [DATA_W - 1:0]              op_rdata;
wire    [ADDR_W - 1:0]              wb_start_addr;
wire    [ADDR_W - 1:0]              wb_word_len;
wire    [ADDR_W - 1:0]              rd_start_addr;
wire    [ADDR_W - 1:0]              rd_word_len;
wire    [ADDR_W - 17:0]             ers_sector_addr;
wire    [ADDR_W - 1:0]              all_data_wcnt; 


data_pro #(
    .U_DLY                      (U_DLY                      ),
    .DATA_W                     (DATA_W                     )
)
u_data_pro(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//interface with cmd_pro module
    .rdata                      (rdata                      ),
    .rvld                       (rvld                       ),

    .wdata                      (wdata                      ),
    .wdata_ren                  (wdata_ren                  ),
    .wdata_rdy                  (wdata_rdy                  ),
//interface with upstream 
    .read_data                  (read_data                  ),
    .read_vld                   (read_vld                   ),

    .write_data                 (write_data                 ),
    .write_vld                  (write_vld                  ),
    .write_rdy                  (write_rdy                  ),
//cfg
    .wfifo_empty                (wfifo_empty                ),
//    .rfifo_full                 (rfifo_full                 ),
    .inbuf_en                   (inbuf_en                   ),
    .indata_cnt_ind             (indata_cnt_ind             )
);

cmd_pro #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_W                     (ADDR_W                     ),
    .DATA_W                     (DATA_W                     )
)
u_cmd_pro(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//io
    .ry_byn                     (io_ry_byn                  ),
//interface with phy
    .op_req                     (op_req                     ),
    .op_ack                     (op_ack                     ),
    .op_rw                      (op_rw                      ),
    .op_addr                    (op_addr                    ),
    .op_wdata                   (op_wdata                   ),
    .op_rdata                   (op_rdata                   ),
    .op_rvld                    (op_rvld                    ),
//interface with up-stream module
    .rdata                      (rdata                      ),
    .rvld                       (rvld                       ),

    .wdata                      (wdata                      ),
    .wdata_ren                  (wdata_ren                  ),
    .wdata_rdy                  (wdata_rdy                  ),
//cfg or alarm
    .wb_start_addr              (wb_start_addr              ),
    .wb_word_len                (wb_word_len                ),
    .wb_start                   (wb_start                   ),

    .rd_start_addr              (rd_start_addr              ),
    .rd_word_len                (rd_word_len                ),
    .rd_start                   (rd_start                   ),

    .ers_start                  (ers_start                  ),
    .ers_sector_en              (ers_sector_en              ),
    .ers_sector_addr            (ers_sector_addr            ),

    .st_free                    (st_free                    ),
    .wb_fail                    (wb_fail                    ),
    .ers_fail                   (ers_fail                   ),
    .wb_reg_done                (wb_reg_done                ),
    .rd_reg_done                (rd_reg_done                ),
    .ers_reg_done               (ers_reg_done               ),
    .r_sts_reg_en               (r_sts_reg_en               ),
    .all_data_wcnt              (all_data_wcnt              ),
    .bit_order                  (bit_order                  ),
    //others
    .inbuf_en                   (inbuf_en                   ),
`ifdef AUTHORIZE_ENABLE 
    .authorize_succ             (authorize_succ             )
`else
    .authorize_succ             (1'b1                       )
`endif
);

mefc_phy #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_W                     (ADDR_W                     ),
    .DATA_W                     (DATA_W                     )
)
u_mefc_phy(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//interface with upstram module
    .op_req                     (op_req                     ),
    .op_ack                     (op_ack                     ),
    .op_rw                      (op_rw                      ),
    .op_addr                    (op_addr                    ),
    .op_wdata                   (op_wdata                   ),
    .op_rdata                   (op_rdata                   ),
    .op_rvld                    (op_rvld                    ),
//IO
    .io_addr                    (io_addr                    ),
    .io_ce                      (io_ce                      ),
    .io_oe                      (io_oe                      ),
    .io_we                      (io_we                      ),
    .io_dq                      (io_dq                      )
);

mefc_cib #(
    .U_DLY                      (U_DLY                      ),
    .CPU_ADDR_W                 (CPU_ADDR_W                 ),
    .VERSION                    (VERSION                    ),
    .YEAR                       (YEAR                       ),
    .MONTH                      (MONTH                      ),
    .DAY                        (DAY                        )
)
u_mefc_cib(
    .clk                        (clk                        ),
    .rst                        (hard_rst                   ),
//cpu bus
    .cpu_cs                     (cpu_cs                     ),
    .cpu_we                     (cpu_we                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wdata                  (cpu_wdata                  ),
    .cpu_rdata                  (cpu_rdata                  ),
//others config
    .wb_start                   (wb_start                   ),
    .wb_start_addr              (wb_start_addr              ),
    .wb_word_len                (wb_word_len                ),

    .rd_start                   (rd_start                   ),
    .rd_start_addr              (rd_start_addr              ),
    .rd_word_len                (rd_word_len                ),

    .ers_start                  (ers_start                  ),
    .ers_sector_en              (ers_sector_en              ),
    .ers_sector_addr            (ers_sector_addr            ),

    .st_free                    (st_free                    ),
    .wb_fail                    (wb_fail                    ),
    .ers_fail                   (ers_fail                   ),
    .wb_reg_done                (wb_reg_done                ),
    .rd_reg_done                (rd_reg_done                ),
    .ers_reg_done               (ers_reg_done               ),
    .r_sts_reg_en               (r_sts_reg_en               ),
    .all_data_wcnt              (all_data_wcnt              ),
    .bit_order                  (bit_order                  ),
    .indata_cnt_ind             (indata_cnt_ind             ),

    .wfifo_empty                (wfifo_empty                ),
//    .rfifo_full                 (rfifo_full                 )
    .rfifo_full                 (1'b0                       )
);

authorize_sub_module #(
    .U_DLY                      (U_DLY                      )
)
u_authorize_sub_module(
    .clk                        (clk                        ),
    .rst                        (hard_rst                   ),
    .key                        (32'h4C_4A_43_44            ),    
//
    .authorize_code             (authorize_code             ),
//
    .authorize_succ             (authorize_succ             )
);

endmodule

