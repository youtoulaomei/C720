// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2018/3/16 13:46:00
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Boyulihua digital equipment Co., Ltd.. 
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
module lvds_7k_dp #(
parameter                           U_DLY = 1
)
(
input                               rst,
input                               lvds_clk,
input                               chnl_en,
input   [15:0]                      lvds_odata,

input                               ad_clk,
output  reg                         ad_vld,
output  reg [15:0]                  ad_data,
output  reg                         fifo_overflow,

input                               bias_sign,
input       [15:0]                  bias

);
// Parameter Define 

// Register Define 
reg     [1:0]                       chnl_en_dly;
reg     [15:0]                      lvds_odata_temp;
reg     [3:0]                       fifo_ofcnt;

// Wire Define 
wire    [15:0]                      dout;
wire                                rd_en;
wire                                u0_full;


always @ (posedge lvds_clk or posedge rst)
begin
    if(rst == 1'b1)
        chnl_en_dly <= 'd0;
    else
        chnl_en_dly <= #U_DLY {chnl_en_dly[0],chnl_en};
end

always @(posedge lvds_clk or posedge rst)
begin
    if(rst == 1'b1)
	    lvds_odata_temp <= 16'h0;
	else
	begin
	    if(bias_sign == 1'b1)
		    lvds_odata_temp <= #U_DLY lvds_odata + bias;
	    else
		    lvds_odata_temp <= #U_DLY lvds_odata - bias;
	end
end

always @(posedge lvds_clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
	        fifo_overflow <= #U_DLY 1'b0;
            fifo_ofcnt    <= #U_DLY 'b0;
        end
	else
	begin
        if(fifo_overflow==1'b1 && fifo_ofcnt>=4'd15)
	        fifo_overflow <= 1'b0;
	    else if(u0_full == 1'b1 && chnl_en_dly[1]==1'b1)
		    fifo_overflow <= #U_DLY 1'b1;

        if(fifo_overflow==1'b1 && fifo_ofcnt>=4'd15)
	        fifo_ofcnt <= 1'b0;
	    else if(fifo_overflow == 1'b1)
		    fifo_ofcnt <= #U_DLY fifo_ofcnt + 'd1;
	end
end

asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (16                         ),
    .DATA_DEEPTH                (16                         ),
    .ADDR_WIDTH                 (4                          )
)u0_fifo
(
    .wr_clk                     (lvds_clk                   ),
    .wr_rst_n                   (~rst                       ),
    .rd_clk                     (ad_clk                     ),
    .rd_rst_n                   (~rst                       ),
    .din                        (lvds_odata_temp            ),
    .wr_en                      (chnl_en_dly[1]             ),
    .rd_en                      (rd_en                      ),
    .dout                       (dout                       ),
    .full                       (u0_full                    ),
    .prog_full                  (                           ),
    .empty                      (empty                      ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (4'd13                      ),
    .prog_empty_thresh          (4'd2                       ),
    .rd_data_count              (                           ),
    .wr_data_count              (                           )
);

assign rd_en = ~empty;

always @ (posedge ad_clk or posedge rst)begin
    if(rst == 1'b1)     
        ad_vld <= #U_DLY 1'b0;        
    else if(rd_en==1'b1 && chnl_en_dly[1]==1'b1)
        ad_vld <= #U_DLY 1'b1;
    else
        ad_vld <= #U_DLY 1'b0;   
end

always @ (posedge ad_clk or posedge rst)begin
    if(rst == 1'b1)     
        ad_data <= #U_DLY 'b0;        
    else if(rd_en==1'b1)
        ad_data <= #U_DLY dout; 
    else  
        ad_data <= #U_DLY 'b0;        
end



endmodule
