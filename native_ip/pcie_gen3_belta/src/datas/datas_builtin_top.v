// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2015/9/9 9:54:55
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Zhimingda digital equipment Co., Ltd.. 
// All Rights Reserved
//
// *********************************************************************************/
// Modification History:
// 1. initial
// 2. modified for AD11 by dingliang
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
`timescale 1 ns / 1 ns
module datas_builtin_top # (
parameter                           U_DLY           = 1   ,
parameter                           DATA_W          = 512 ,
parameter                           CHNL_NUM        = 2'd0,
parameter                           TBUCKET_DEEPTH  = 22'd1500   
)
(
input                               clk,
input                               rst_n,
input                               chk_clk,
input                               chk_rst_n,
input                               rtc_us_flg,


//
input  [21:0]                       ds_tbucket_deepth,
input  [21:0]                       ds_tbucket_width,

input  [2:0]                        ds_data_mode,
input  [63:0]                       ds_static_pattern,
input                               ds_tx_len_start,
input                               ds_tx_con_start,
input  [31:0]                       ds_len_mode_count,

input                               check_st,
output [63:0]                       file_len,
output [15:0]                       err_num_8bit,
output [63:0]                       err_len_8bit,
output [15:0]                       err_num_prbs31,
output [63:0]                       err_len_prbs31,
output [15:0]                       err_num_128bit,         
output [63:0]                       err_len_128bit,         

output                              errcontext_8bit_wr,        
output [5:0]                        errcontext_8bit_wr_addr,   
output [15:0]                       errcontext_8bit_wr_data,   
output                              errcontext_prbs31_wr,      
output [5:0]                        errcontext_prbs31_wr_addr, 
output [15:0]                       errcontext_prbs31_wr_data, 
output                              errcontext_128bit_wr,       
output [5:0]                        errcontext_128bit_wr_addr,  
output [15:0]                       errcontext_128bit_wr_data, 

input                               full,
output [DATA_W-1:0]                 ds_rx_data,
output [DATA_W/8-1:0]               ds_rx_keep,
output                              ds_rx_data_vld,
output                              ds_rx_last,

input [DATA_W-1:0]                  ds_tx_tdata,
input [DATA_W/8-1:0]                ds_tx_tkeep,
input                               ds_tx_tvalid,
input                               ds_tx_tlast,
output                              ds_tx_tready,

output                              ds_send_done

);
// Parameter Define 

// Register Define 

// Wire Define 
wire [DATA_W-1:0]                   tx_data      ;
wire [DATA_W/8-1:0]                 tx_keep      ;
wire                                tx_last      ;
wire                                tx_head      ;
wire                                tx_tail      ;
wire                                tx_data_vld  ; 
wire                                prog_full    ;

wire [DATA_W-1:0]                   rx_data      ;
wire [DATA_W/8-1:0]                 rx_keep      ;
wire                                rx_last      ;
wire                                rx_data_vld  ;


//--------------------------------------------------------------------------------------
// u_datas
//--------------------------------------------------------------------------------------

datas #(                                                                
    .U_DLY                      (U_DLY                      ),
    .DATA_W                     (DATA_W                     ),
    .TBUCKET_DEEPTH             (TBUCKET_DEEPTH             )
)u_datas
(
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),
    .chk_clk                    (chk_clk                    ),
    .chk_rst_n                  (chk_rst_n                  ),    
    .rtc_us_flg                 (rtc_us_flg                 ),

    .seed0                      (31'h4A74                   ),
    .seed1                      (31'h732D                   ),
    .seed2                      (31'h54AC                   ),
    .seed3                      (31'h449E                   ),
    .seed4                      (31'h6CD8                   ),
    .seed5                      (31'h148F                   ),
    .seed6                      (31'h29E7                   ),
    .seed7                      (31'h754f                   ),
//
    .ds_tbucket_deepth          (ds_tbucket_deepth          ),
    .ds_tbucket_width           (ds_tbucket_width           ),

    .ds_data_mode               (ds_data_mode               ),
    .ds_static_pattern          (ds_static_pattern          ),
    .ds_tx_len_start            (ds_tx_len_start            ),
    .ds_tx_con_start            (ds_tx_con_start            ),
    .ds_len_mode_count          (ds_len_mode_count          ),

    .tx_data                    (tx_data                    ),
    .tx_keep                    (tx_keep                    ),
    .tx_last                    (tx_last                    ),
    .tx_head                    (tx_head                    ),
    .tx_tail                    (tx_tail                    ),
    .tx_data_vld                (tx_data_vld                ), 
    .prog_full                  (prog_full                  ),  
    .ds_send_done               (ds_send_done               ),     


    .check_st                   (check_st                   ),
    .file_len                   (file_len                   ),
    .err_num_8bit               (err_num_8bit               ),
    .err_len_8bit               (err_len_8bit               ),
    .err_num_prbs31             (err_num_prbs31             ),
    .err_len_prbs31             (err_len_prbs31             ),
    .err_num_128bit             (err_num_128bit             ),      
    .err_len_128bit             (err_len_128bit             ),    
    .errcontext_8bit_wr         (errcontext_8bit_wr         ),      
    .errcontext_8bit_wr_addr    (errcontext_8bit_wr_addr    ),     
    .errcontext_8bit_wr_data    (errcontext_8bit_wr_data    ), 
    .errcontext_prbs31_wr       (errcontext_prbs31_wr       ),      
    .errcontext_prbs31_wr_addr  (errcontext_prbs31_wr_addr  ),     
    .errcontext_prbs31_wr_data  (errcontext_prbs31_wr_data  ), 
    .errcontext_128bit_wr       (errcontext_128bit_wr       ),      
    .errcontext_128bit_wr_addr  (errcontext_128bit_wr_addr  ),     
    .errcontext_128bit_wr_data  (errcontext_128bit_wr_data  ),  

    .rx_data                    (rx_data                    ),
    .rx_keep                    (rx_keep                    ),
    .rx_last                    (rx_last                    ),
    .rx_data_vld                (rx_data_vld                )
);




//--------------------------------------------------------------------------------------
// u_datas_ui_aurora_wc
//--------------------------------------------------------------------------------------

datas_ui_aurora_wc # (
    .U_DLY                      (U_DLY                      ),
    .DATA_W                     (DATA_W                     ),
    .CHNL_NUM                   (CHNL_NUM                   )
)u_datas_ui_aurora_wc
(
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),

    .tx_data                    (tx_data                    ),
    .tx_keep                    (tx_keep                    ),
    .tx_last                    (tx_last                    ),
    .tx_head                    (tx_head                    ),
    .tx_tail                    (tx_tail                    ),
    .tx_data_vld                (tx_data_vld                ),
    .prog_full                  (prog_full                  ),
    
    .full                       (full                       ),
    .ds_rx_data                 (ds_rx_data                 ),
    .ds_rx_keep                 (ds_rx_keep                 ),
    .ds_rx_data_vld             (ds_rx_data_vld             ),    
    .ds_rx_last                 (ds_rx_last                 )
    
);

//--------------------------------------------------------------------------------------
// u_datas_ui_aurora_rc
//--------------------------------------------------------------------------------------
datas_ui_aurora_rc # (
    .U_DLY                      (U_DLY                      ),
    .DATA_W                     (DATA_W                     )
)u_datas_ui_aurora_rc
(
    .clk                        (chk_clk                    ),
    .rst_n                      (chk_rst_n                  ),

//    .ds_tx_arb_req              (ds_tx_arb_req              ),
//    .ds_arb_tx_ack              (ds_arb_tx_ack              ),
    .ds_tx_tdata                (ds_tx_tdata                ),
    .ds_tx_tkeep                (ds_tx_tkeep                ),
    .ds_tx_tvalid               (ds_tx_tvalid               ),
    .ds_tx_tlast                (ds_tx_tlast                ),
    .ds_tx_tready               (ds_tx_tready               ),

    .rx_data                    (rx_data                    ),
    .rx_keep                    (rx_keep                    ),
    .rx_last                    (rx_last                    ),
    .rx_data_vld                (rx_data_vld                )
);


endmodule
