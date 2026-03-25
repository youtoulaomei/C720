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
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
`timescale 1 ns / 1 ns
module datas #(
parameter                           U_DLY           = 1   ,
parameter                           DATA_W          = 512 ,
parameter                           TBUCKET_DEEPTH  = 22'd1500   
)
(
input                               clk,
input                               rst_n,
input                               chk_clk,  
input                               chk_rst_n,
input                               rtc_us_flg,


input [30:0]                        seed0,
input [30:0]                        seed1,
input [30:0]                        seed2,
input [30:0]                        seed3,
input [30:0]                        seed4,
input [30:0]                        seed5,
input [30:0]                        seed6,
input [30:0]                        seed7,
//
input  [21:0]                       ds_tbucket_deepth,
input  [21:0]                       ds_tbucket_width,

input  [2:0]                        ds_data_mode,
input  [63:0]                       ds_static_pattern,
input                               ds_tx_len_start,
input                               ds_tx_con_start,
input  [31:0]                       ds_len_mode_count,

output [DATA_W-1:0]                 tx_data,
output [DATA_W/8-1:0]               tx_keep,
output                              tx_last,
output                              tx_head,
output                              tx_tail,
output                              tx_data_vld,
//input                               full,
input                               prog_full, 
output                              ds_send_done,  


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



input [DATA_W-1:0]                  rx_data,
input [DATA_W/8-1:0]                rx_keep,
input                               rx_last,
input                               rx_data_vld

);
// Parameter Define 

// Register Define 

// Wire Define 

//u_datas_tokenbucket       
wire                                tbucket_ready;


datas_tokenbucket # (
    .U_DLY                      (U_DLY                      ),
    .DATA_W                     (DATA_W                     ),    
    .TBUCKET_DEEPTH             (TBUCKET_DEEPTH             )
)u_datas_tokenbucket
(
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),
    .rtc_us_flg                 (rtc_us_flg                 ),
    .ds_tbucket_deepth          (ds_tbucket_deepth          ),
    .ds_tbucket_width           (ds_tbucket_width           ),
    .send_vld                   (tx_data_vld                ),
    .tbucket_ready              (tbucket_ready              )

);


//u_datas_gen
datas_gen # (
    .U_DLY                      (U_DLY                      ),
    .DATA_W                     (DATA_W                     )
)u_datas_gen
(
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),
    
    .tbucket_ready              (tbucket_ready              ),
    
    .ds_data_mode               (ds_data_mode               ),

    .ds_static_pattern          (ds_static_pattern          ),
    .ds_tx_len_start            (ds_tx_len_start            ),
    .ds_tx_con_start            (ds_tx_con_start            ),
    .ds_len_mode_count          (ds_len_mode_count          ),
    .ds_prbs31_seed             ({seed0,seed1,seed2,seed3,seed4,seed5,seed6,seed7}),
    
    .tx_data                    (tx_data                    ),
    .tx_keep                    (tx_keep                    ),
    .tx_last                    (tx_last                    ),  
    .tx_head                    (tx_head                    ),       
    .tx_tail                    (tx_tail                    ),       
    .tx_data_vld                (tx_data_vld                ),
//    .full                       (full                       ),
    .prog_full                  (prog_full                  ),
    .ds_send_done               (ds_send_done               )
);

//u_datas_check
datas_check # (
    .U_DLY                      (U_DLY                      ),
    .DATA_W                     (DATA_W                     )
)u_datas_check
(
    .clk                        (chk_clk                    ),
    .rst_n                      (chk_rst_n                  ),

    .ds_prbs31_seed             ({seed0,seed1,seed2,seed3,seed4,seed5,seed6,seed7}),    
    .check_st                   (check_st                   ),

    .rx_data                    (rx_data                    ),
    .rx_keep                    (rx_keep                    ),
    .rx_last                    (rx_last                    ),
    .rx_data_vld                (rx_data_vld                ),

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
    
    .file_len                   (file_len                   )
);



endmodule
