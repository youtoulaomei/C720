// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2018/3/16 17:04:51
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
`define LVDS_00 {VERSION}
`define LVDS_01 {YEAR,MONTH,DAY}
`define LVDS_02 {test_reg}

`define LVDS_04 {fill[31:4],adc_en[3:0]}
`define LVDS_05 {fill[31:0]}
`define LVDS_06 {fill[31:0]}
`define LVDS_07 {fill[31:0]}
`define LVDS_09 {his_fifo_overflow}
`define LVDS_0A {sign_mod}


`define LVDS_10 {fill[31:5],st_clr[0],fill[3:1],dly_inc[0]}
`define LVDS_11 {fill[31:9],dly_value[9*0+:9]}
`define LVDS_12 {fill[31:5],st_clr[1],fill[3:1],dly_inc[1]}
`define LVDS_13 {fill[31:9],dly_value[9*1+:9]}
//`define LVDS_14 {fill[31:5],st_clr[2],fill[3:1],dly_inc[2]}
//`define LVDS_15 {fill[31:9],dly_value[9*2+:9]}
//`define LVDS_16 {fill[31:5],st_clr[3],fill[3:1],dly_inc[3]}
//`define LVDS_17 {fill[31:9],dly_value[9*3+:9]}

`define LVDS_18 {fill[31:1],pns_rcvd_r2[0]}
`define LVDS_19 {fill[31:1],pns_rcvd_r2[1]}
//`define LVDS_1A {fill[31:1],pns_rcvd_r2[2]}
//`define LVDS_1B {fill[31:1],pns_rcvd_r2[3]}

`define LVDS_20 {fill[31:25],idelay_value_r2[1*9+:9],fill[15:9],idelay_value_r2[0*9+:9]}
`define LVDS_21 {fill[31:25],idelay_value_r2[3*9+:9],fill[15:9],idelay_value_r2[2*9+:9]}
`define LVDS_22 {fill[31:25],idelay_value_r2[5*9+:9],fill[15:9],idelay_value_r2[4*9+:9]}
`define LVDS_23 {fill[31:25],idelay_value_r2[7*9+:9],fill[15:9],idelay_value_r2[6*9+:9]}

`define LVDS_24 {fill[31:25],idelay_value_r2[9*9+:9],fill[15:9],idelay_value_r2[8*9+:9]}
`define LVDS_25 {fill[31:25],idelay_value_r2[11*9+:9],fill[15:9],idelay_value_r2[10*9+:9]}
`define LVDS_26 {fill[31:25],idelay_value_r2[13*9+:9],fill[15:9],idelay_value_r2[12*9+:9]}
`define LVDS_27 {fill[31:25],idelay_value_r2[15*9+:9],fill[15:9],idelay_value_r2[14*9+:9]}

// `define LVDS_28 {fill[31:25],idelay_value_r2[17*9+:9],fill[15:9],idelay_value_r2[16*9+:9]}
// `define LVDS_29 {fill[31:25],idelay_value_r2[19*9+:9],fill[15:9],idelay_value_r2[18*9+:9]}
// `define LVDS_2A {fill[31:25],idelay_value_r2[21*9+:9],fill[15:9],idelay_value_r2[20*9+:9]}
// `define LVDS_2B {fill[31:25],idelay_value_r2[23*9+:9],fill[15:9],idelay_value_r2[22*9+:9]}

// `define LVDS_2C {fill[31:25],idelay_value_r2[25*9+:9],fill[15:9],idelay_value_r2[24*9+:9]}
// `define LVDS_2D {fill[31:25],idelay_value_r2[27*9+:9],fill[15:9],idelay_value_r2[26*9+:9]}
// `define LVDS_2E {fill[31:25],idelay_value_r2[29*9+:9],fill[15:9],idelay_value_r2[28*9+:9]}
// `define LVDS_2F {fill[31:25],idelay_value_r2[31*9+:9],fill[15:9],idelay_value_r2[30*9+:9]}

`define LVDS_30 {test_0pattern}
`define LVDS_31 {test_1pattern}
`define LVDS_32 {test_2pattern}

`define LVDS_40 {io_cfg}

`define LVDS_50 {bias_sign[0],fill[30:16],bias[0*16+:16]}
`define LVDS_51 {bias_sign[1],fill[30:16],bias[1*16+:16]}
`define LVDS_52 {bias_sign[2],fill[30:16],bias[2*16+:16]}
`define LVDS_53 {bias_sign[3],fill[30:16],bias[3*16+:16]}

module lvds_7k_cib #(
parameter                           U_DLY   = 1,
parameter                           VERSION = 32'h00_00_00_01,
parameter                           YEAR    = 16'h20_18,
parameter                           MONTH   = 8'h03,
parameter                           DAY     = 8'h17,
parameter                           LVDS_NUM= 2
)
(
input                               clk,                        
input                               rst,       

input                               cpu_cs,
input                               cpu_wr,
input                               cpu_rd,
input        [7:0]                  cpu_addr,
input        [31:0]                 cpu_wr_data,
output reg   [31:0]                 cpu_rd_data,

output reg   [LVDS_NUM-1:0]         st_clr,
output reg   [15:0]                 test_0pattern,
output reg   [15:0]                 test_1pattern,
output reg   [15:0]                 test_2pattern,
input        [LVDS_NUM-1:0]         pns_rcvd,
output reg                          io_cfg,
output reg   [LVDS_NUM*9-1:0]       dly_value,
output reg   [LVDS_NUM-1:0]         dly_inc,
output reg                          sign_mod,
input  [LVDS_NUM*8*9-1:0]           idelay_value,

output reg [3:0]                    adc_en,

output reg [3:0]                    bias_sign,
output reg [63:0]                   bias,

//output reg                          pll_ref_sel,
input      [LVDS_NUM-1:0]           fifo_overflow
);
// Parameter Define 

// Register Define 
reg                                 cpu_wr_dly;
reg                                 cpu_rd_dly;
reg     [7:0]                       cpu_raddr;
reg     [31:0]                      fill;
reg     [31:0]                      test_reg;
reg                                 cpu_rd_det;
reg     [LVDS_NUM*8*9-1:0]          idelay_value_r1;
reg     [LVDS_NUM*8*9-1:0]          idelay_value_r2;
reg     [LVDS_NUM-1:0]              fifo_overflow_r1;
reg     [LVDS_NUM-1:0]              fifo_overflow_r2;
reg     [LVDS_NUM-1:0]              his_fifo_overflow;
reg     [LVDS_NUM-1:0]              pns_rcvd_r1;
reg     [LVDS_NUM-1:0]              pns_rcvd_r2;


// Wire Define 

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cpu_wr_dly <= 1'b1;
            cpu_rd_dly <= 1'b1;
        end
    else
        begin
            cpu_wr_dly <= #U_DLY cpu_wr;
            cpu_rd_dly <= #U_DLY cpu_rd;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        cpu_raddr <= 'd0;
    else if({cpu_rd,cpu_rd_dly} == 2'b01 && cpu_cs == 1'b0)   //read
        cpu_raddr <= #U_DLY cpu_addr;
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        cpu_rd_det <= #U_DLY 1'b0;
    else if({cpu_rd,cpu_rd_dly} == 2'b10 && cpu_cs == 1'b0)   //read
        cpu_rd_det <= #U_DLY 1'b1;
    else
    	cpu_rd_det <= #U_DLY 1'b0;
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        cpu_rd_data <= #U_DLY 'b0;       
    else   
        case(cpu_raddr)
            8'h00:cpu_rd_data <= #U_DLY `LVDS_00;
            8'h01:cpu_rd_data <= #U_DLY `LVDS_01; 
            8'h02:cpu_rd_data <= #U_DLY `LVDS_02; 
             
            8'h04:cpu_rd_data <= #U_DLY `LVDS_04; 
            8'h05:cpu_rd_data <= #U_DLY `LVDS_05; 
            8'h06:cpu_rd_data <= #U_DLY `LVDS_06; 
            8'h07:cpu_rd_data <= #U_DLY `LVDS_07; 
            8'h09:cpu_rd_data <= #U_DLY `LVDS_09; 
            8'h0A:cpu_rd_data <= #U_DLY `LVDS_0A; 
            8'h10:cpu_rd_data <= #U_DLY `LVDS_10; 
            8'h11:cpu_rd_data <= #U_DLY `LVDS_11; 
            8'h12:cpu_rd_data <= #U_DLY `LVDS_12; 
            8'h13:cpu_rd_data <= #U_DLY `LVDS_13;
//            8'h14:cpu_rd_data <= #U_DLY `LVDS_14; 
//            8'h15:cpu_rd_data <= #U_DLY `LVDS_15; 
//            8'h16:cpu_rd_data <= #U_DLY `LVDS_16; 
//            8'h17:cpu_rd_data <= #U_DLY `LVDS_17; 
            8'h18:cpu_rd_data <= #U_DLY `LVDS_18; 
            8'h19:cpu_rd_data <= #U_DLY `LVDS_19; 
//            8'h1A:cpu_rd_data <= #U_DLY `LVDS_1A; 
//            8'h1B:cpu_rd_data <= #U_DLY `LVDS_1B; 
            8'h20:cpu_rd_data <= #U_DLY `LVDS_20; 
            8'h21:cpu_rd_data <= #U_DLY `LVDS_21; 
            8'h22:cpu_rd_data <= #U_DLY `LVDS_22; 
            8'h23:cpu_rd_data <= #U_DLY `LVDS_23; 
            8'h24:cpu_rd_data <= #U_DLY `LVDS_24; 
            8'h25:cpu_rd_data <= #U_DLY `LVDS_25; 
            8'h26:cpu_rd_data <= #U_DLY `LVDS_26; 
            8'h27:cpu_rd_data <= #U_DLY `LVDS_27; 
//            8'h28:cpu_rd_data <= #U_DLY `LVDS_28; 
//            8'h29:cpu_rd_data <= #U_DLY `LVDS_29; 
//            8'h2A:cpu_rd_data <= #U_DLY `LVDS_2A;
//            8'h2B:cpu_rd_data <= #U_DLY `LVDS_2B;
//            8'h2C:cpu_rd_data <= #U_DLY `LVDS_2C; 
//            8'h2D:cpu_rd_data <= #U_DLY `LVDS_2D; 
//            8'h2E:cpu_rd_data <= #U_DLY `LVDS_2E;
//            8'h2F:cpu_rd_data <= #U_DLY `LVDS_2F;
            8'h30:cpu_rd_data <= #U_DLY `LVDS_30; 
            8'h31:cpu_rd_data <= #U_DLY `LVDS_31; 
            8'h32:cpu_rd_data <= #U_DLY `LVDS_32; 
            8'h40:cpu_rd_data <= #U_DLY `LVDS_40; 
			
			8'h50:cpu_rd_data <= #U_DLY `LVDS_50;
			8'h51:cpu_rd_data <= #U_DLY `LVDS_51;
			8'h52:cpu_rd_data <= #U_DLY `LVDS_52;
			8'h53:cpu_rd_data <= #U_DLY `LVDS_53;
            default:cpu_rd_data <= #U_DLY 'b0;       
        endcase 

end



always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            fill <= #U_DLY 32'd0;
            `LVDS_02 <= #U_DLY 32'hdead_beef;
            `LVDS_04 <= #U_DLY 32'd0; 
            `LVDS_05 <= #U_DLY 32'd0; 
            `LVDS_06 <= #U_DLY 32'd0; 
            `LVDS_07 <= #U_DLY 32'd0;
            `LVDS_0A <= #U_DLY 32'd0; 
            `LVDS_10 <= #U_DLY 32'd0;  
            `LVDS_11 <= #U_DLY 32'd16;  
            `LVDS_12 <= #U_DLY 32'd0;  
            `LVDS_13 <= #U_DLY 32'd16;  
//            `LVDS_14 <= #U_DLY 32'd0;  
//            `LVDS_15 <= #U_DLY 32'd16;  
//            `LVDS_16 <= #U_DLY 32'd0;   
//            `LVDS_17 <= #U_DLY 32'd16; 
            `LVDS_30 <= #U_DLY {16'b0,16'h878E};  
            `LVDS_31 <= #U_DLY {16'b0,16'hAE64};  
            `LVDS_32 <= #U_DLY {16'b0,16'h929D};  
            `LVDS_40 <= #U_DLY 32'd0;   
			`LVDS_50 <= #U_DLY 32'd0;  
			`LVDS_51 <= #U_DLY 32'd0;  
			`LVDS_52 <= #U_DLY 32'd0;  
			`LVDS_53 <= #U_DLY 32'd0;  
        end        
    else 
        begin   
            if({cpu_wr,cpu_wr_dly} == 2'b01 && cpu_cs == 1'b0)
                begin
                    case(cpu_addr)
                        8'h02:`LVDS_02 <= #U_DLY cpu_wr_data;
                        8'h04:`LVDS_04 <= #U_DLY cpu_wr_data;
                        8'h05:`LVDS_05 <= #U_DLY cpu_wr_data;
                        8'h06:`LVDS_06 <= #U_DLY cpu_wr_data;
                        8'h07:`LVDS_07 <= #U_DLY cpu_wr_data;
                        8'h0A:`LVDS_0A <= #U_DLY cpu_wr_data;
                        8'h10:`LVDS_10 <= #U_DLY cpu_wr_data;
                        8'h11:`LVDS_11 <= #U_DLY cpu_wr_data;
                        8'h12:`LVDS_12 <= #U_DLY cpu_wr_data;
                        8'h13:`LVDS_13 <= #U_DLY cpu_wr_data;
//                        8'h14:`LVDS_14 <= #U_DLY cpu_wr_data;
//                        8'h15:`LVDS_15 <= #U_DLY cpu_wr_data;
//                        8'h16:`LVDS_16 <= #U_DLY cpu_wr_data;
//                        8'h17:`LVDS_17 <= #U_DLY cpu_wr_data;
                        8'h30:`LVDS_30 <= #U_DLY cpu_wr_data;
                        8'h31:`LVDS_31 <= #U_DLY cpu_wr_data;
                        8'h32:`LVDS_32 <= #U_DLY cpu_wr_data;
                        8'h40:`LVDS_40 <= #U_DLY cpu_wr_data;
						8'h50:`LVDS_50 <= #U_DLY cpu_wr_data;
						8'h51:`LVDS_51 <= #U_DLY cpu_wr_data;
						8'h52:`LVDS_52 <= #U_DLY cpu_wr_data;
						8'h53:`LVDS_53 <= #U_DLY cpu_wr_data;
                        default:;
                    endcase
                end
            else
                begin
                    `LVDS_10 <= #U_DLY 32'd0;  
                    `LVDS_12 <= #U_DLY 32'd0; 
//                    `LVDS_14 <= #U_DLY 32'd0;  
//                    `LVDS_16 <= #U_DLY 32'd0;   
                    `LVDS_40 <= #U_DLY 32'd0;  
                    fill <= #U_DLY 32'd0;

                end
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            idelay_value_r1 <= #U_DLY 'b0;
            idelay_value_r2 <= #U_DLY 'b0;
        end       
    else    
        begin
            idelay_value_r1 <= #U_DLY idelay_value;
            idelay_value_r2 <= #U_DLY idelay_value_r1;
        end               
end



always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            fifo_overflow_r1 <= #U_DLY 'b0;
            fifo_overflow_r2 <= #U_DLY 'b0;
        end       
    else    
        begin
            fifo_overflow_r1 <= #U_DLY fifo_overflow;
            fifo_overflow_r2 <= #U_DLY fifo_overflow_r1;
        end               
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
            his_fifo_overflow <= #U_DLY 'b0;
    else    
        begin:HIS_FIFO_OVERFLOW_PRO
        	  integer i;
        	  for(i=0;i<2;i=i+1)
        	  begin
                if(cpu_rd_det==1'b1 && cpu_addr==8'h14)
                    his_fifo_overflow[i] <= #U_DLY fifo_overflow_r1[i] && ~fifo_overflow_r2[i];
                else if(fifo_overflow_r1[i]==1'b1 && fifo_overflow_r2[i]==1'b0)
                    his_fifo_overflow[i] <= #U_DLY 1'b1;
            end
        end    	  
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            pns_rcvd_r1 <= #U_DLY 'b0;
            pns_rcvd_r2 <= #U_DLY 'b0;
        end        
    else    
        begin
            pns_rcvd_r1 <= #U_DLY pns_rcvd;
            pns_rcvd_r2 <= #U_DLY pns_rcvd_r1;
        end        
end

endmodule
