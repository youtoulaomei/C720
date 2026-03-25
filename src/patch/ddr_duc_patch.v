// *********************************************************************************/
// Project Name :
// Author       : denghongquan
// Email        : 573798697@qq.com
// Creat Time   : 2019/8/27 15:18:26
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c)  2019, Boyulihua digital equipment co., Ltd.. 
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
module ddr_duc_patch #(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               dac_clk,
input                               rst,

output                              fifo_empty,

input       [511:0]                 datain,
input                               datain_vld,
output reg                          dataout_rdy,//output


output      [31:0]                  dataout,
output                              dataout_vld,
input                               datain_rdy//input
);
// Register Define 
reg     [479:0]                     datain_r;
reg                                 fifo_wr;
reg     [31:0]                      fifo_wr_data;
reg     [3:0]                       fifo_wr_cnt;

// Wire Define                    
wire                                fifo_rd;
wire    [31:0]                      fifo_rd_data;
wire                                fifo_prog_full;
//wire                                fifo_empty;



always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        dataout_rdy <= #U_DLY 1'b0;  
    else if(dataout_rdy==1'b1 && datain_vld==1'b1)
        dataout_rdy <= #U_DLY 1'b0;  
    else if((fifo_prog_full==1'b0) && ((fifo_wr==1'b0 && fifo_wr_cnt=='d0) || (fifo_wr==1'b1 && fifo_wr_cnt=='d14)) )
        dataout_rdy <= #U_DLY 1'b1;  
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        datain_r <= #U_DLY 'b0;        
    else if(dataout_rdy==1'b1 && datain_vld==1'b1 )   
        datain_r <= #U_DLY datain[511:32];
    else
        datain_r <= #U_DLY datain_r>>32; 
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            fifo_wr <= #U_DLY 1'b0;
            fifo_wr_data <= #U_DLY 'b0;
            fifo_wr_cnt <= #U_DLY 'b0;
        end       
    else
        begin
            if(fifo_wr==1'b1 && fifo_wr_cnt=='d15 &&  (dataout_rdy==1'b0 || datain_vld==1'b0))
                fifo_wr <= #U_DLY 1'b0;
            else if(dataout_rdy==1'b1 && datain_vld==1'b1) 
                fifo_wr <= #U_DLY 1'b1;

            if(fifo_wr==1'b1)
                fifo_wr_cnt <= #U_DLY fifo_wr_cnt + 'd1;

            if(dataout_rdy==1'b1 && datain_vld==1'b1) 
                fifo_wr_data <= #U_DLY datain[31:0];
            else
                fifo_wr_data <= #U_DLY datain_r[31:0];
        end    

end

asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (32                         ),
    .DATA_DEEPTH                (64                        ),
    .ADDR_WIDTH                 (6                         ),
    .RAM_STYLE                  ("REG"                    )    
)u_patch_fifo
(
    .wr_clk                     (clk                        ),
    .wr_rst_n                   (~rst                       ),
    .rd_clk                     (dac_clk                       ),
    .rd_rst_n                   (~rst                       ),
    .din                        (fifo_wr_data               ),
    .wr_en                      (fifo_wr                    ),
    .rd_en                      (fifo_rd                    ),
    .dout                       (fifo_rd_data               ),
    .full                       (                           ),
    .prog_full                  (fifo_prog_full             ),
    .empty                      (fifo_empty                 ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (6'd32                    ),
    .prog_empty_thresh          (6'd2                      )
);
//fifo_generator_0 u_fifo_generator_0(
//    .wr_clk                     (clk                     ),
//    .wr_rst                     (rst                     ),
//    .rd_clk                     (clk                     ),
//    .rd_rst                     (rst                     ),
//    .din                        (fifo_wr_data                 ),
//    .wr_en                      (fifo_wr                      ),
//    .rd_en                      (fifo_rd                      ),
//    .dout                       (fifo_rd_data                 ),
//    .full                       (                             ),
//    .empty                      (fifo_empty                   ),
//    .prog_full                  (fifo_prog_full               ),
//    .prog_empty                 (                             )
//);

assign fifo_rd=(fifo_empty==1'b0) && (datain_rdy==1'b1) ? 1'b1 : 1'b0;

assign dataout_vld=(fifo_empty==1'b0) ? 1'b1:1'b0;

assign dataout=fifo_rd_data;



endmodule

