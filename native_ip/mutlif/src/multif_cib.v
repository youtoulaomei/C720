// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2019/3/8 13:34:13
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Shenrong Co., Ltd.. 
// All Rights Reserved
//
// *********************************************************************************/
// Modification History:
// 1. initial
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
`define MUF_01 {test}   
`define MUF_02 {frame_byte_len}
`define MUF_10 {fill[31:3],vld_indication,fifo_prog_empty,his_fifo_overflow}      
`define MUF_11 {fill[31:24],band}
`define MUF_12 {fifo_empty}
//`define MUF_13 {fifo_empty[55:32]}
//`define MUF_14 {fifo_empty[75:64]}
//`define MUF_15 {fifo_empty[127:96]}
//`define MUF_16 {fifo_empty[135:128]}

`define MUF_20 {chn_ctrl[31:0]}
`define MUF_21 {chn_ctrl[63:32]}
`define MUF_22 {chn_ctrl[95:64]}
`define MUF_23 {chn_ctrl[127:96]}
`define MUF_24 {chn_ctrl[135:128]}

`define MUF_30 {indata_vld_r2}
//`define MUF_31 {indata_vld_r2[55:32]}
//`define MUF_32 {indata_vld_r2[75:64]}
//`define MUF_33 {indata_vld_r2[127:96]}
//`define MUF_34 {indata_vld_r2[135:128]}


`define MUF_40 {fill[31:27],chn_mode[3*3+:3]   ,fill[23:19] ,chn_mode[2*3+:3]  ,fill[15:11]  ,chn_mode[1*3+:3]  ,fill[7:3], chn_mode[0*3+:3]}
`define MUF_41 {fill[31:27],chn_mode[7*3+:3]   ,fill[23:19] ,chn_mode[6*3+:3]  ,fill[15:11]  ,chn_mode[5*3+:3]  ,fill[7:3], chn_mode[4*3+:3]}
`define MUF_42 {fill[31:27],chn_mode[11*3+:3]  ,fill[23:19] ,chn_mode[10*3+:3] ,fill[15:11]  ,chn_mode[9*3+:3]  ,fill[7:3], chn_mode[8*3+:3]}
`define MUF_43 {fill[31:27],chn_mode[15*3+:3]  ,fill[23:19] ,chn_mode[14*3+:3] ,fill[15:11]  ,chn_mode[13*3+:3] ,fill[7:3], chn_mode[12*3+:3]}
`define MUF_44 {fill[31:27],chn_mode[19*3+:3]  ,fill[23:19] ,chn_mode[18*3+:3] ,fill[15:11]  ,chn_mode[17*3+:3] ,fill[7:3], chn_mode[16*3+:3]}
`define MUF_45 {fill[31:27],chn_mode[23*3+:3]  ,fill[23:19] ,chn_mode[22*3+:3] ,fill[15:11]  ,chn_mode[21*3+:3] ,fill[7:3], chn_mode[20*3+:3]}
`define MUF_46 {fill[31:27],chn_mode[27*3+:3]  ,fill[23:19] ,chn_mode[26*3+:3] ,fill[15:11]  ,chn_mode[25*3+:3] ,fill[7:3], chn_mode[24*3+:3]}
`define MUF_47 {fill[31:27],chn_mode[31*3+:3]  ,fill[23:19] ,chn_mode[30*3+:3] ,fill[15:11]  ,chn_mode[29*3+:3] ,fill[7:3], chn_mode[28*3+:3]}
`define MUF_48 {fill[31:27],chn_mode[35*3+:3]  ,fill[23:19] ,chn_mode[34*3+:3] ,fill[15:11]  ,chn_mode[33*3+:3] ,fill[7:3], chn_mode[32*3+:3]}
`define MUF_49 {fill[31:27],chn_mode[39*3+:3]  ,fill[23:19] ,chn_mode[38*3+:3] ,fill[15:11]  ,chn_mode[37*3+:3] ,fill[7:3], chn_mode[36*3+:3]}
`define MUF_4A {fill[31:27],chn_mode[43*3+:3]  ,fill[23:19] ,chn_mode[42*3+:3] ,fill[15:11]  ,chn_mode[41*3+:3] ,fill[7:3], chn_mode[40*3+:3]}
`define MUF_4B {fill[31:27],chn_mode[47*3+:3]  ,fill[23:19] ,chn_mode[46*3+:3] ,fill[15:11]  ,chn_mode[45*3+:3] ,fill[7:3], chn_mode[44*3+:3]}
`define MUF_4C {fill[31:27],chn_mode[51*3+:3]  ,fill[23:19] ,chn_mode[50*3+:3] ,fill[15:11]  ,chn_mode[49*3+:3] ,fill[7:3], chn_mode[48*3+:3]}
`define MUF_4D {fill[31:27],chn_mode[55*3+:3]  ,fill[23:19] ,chn_mode[54*3+:3] ,fill[15:11]  ,chn_mode[53*3+:3] ,fill[7:3], chn_mode[52*3+:3]}
`define MUF_4E {fill[31:27],chn_mode[59*3+:3]  ,fill[23:19] ,chn_mode[58*3+:3] ,fill[15:11]  ,chn_mode[57*3+:3] ,fill[7:3], chn_mode[56*3+:3]}
`define MUF_4F {fill[31:27],chn_mode[63*3+:3]  ,fill[23:19] ,chn_mode[62*3+:3] ,fill[15:11]  ,chn_mode[61*3+:3] ,fill[7:3], chn_mode[60*3+:3]}
`define MUF_50 {fill[31:27],chn_mode[67*3+:3]  ,fill[23:19] ,chn_mode[66*3+:3] ,fill[15:11]  ,chn_mode[65*3+:3] ,fill[7:3], chn_mode[64*3+:3]}
`define MUF_51 {fill[31:27],chn_mode[71*3+:3]  ,fill[23:19] ,chn_mode[70*3+:3] ,fill[15:11]  ,chn_mode[69*3+:3] ,fill[7:3], chn_mode[68*3+:3]}
`define MUF_52 {fill[31:27],chn_mode[75*3+:3]  ,fill[23:19] ,chn_mode[74*3+:3] ,fill[15:11]  ,chn_mode[73*3+:3] ,fill[7:3], chn_mode[72*3+:3]}
`define MUF_53 {fill[31:27],chn_mode[79*3+:3]  ,fill[23:19] ,chn_mode[78*3+:3] ,fill[15:11]  ,chn_mode[77*3+:3] ,fill[7:3], chn_mode[76*3+:3]}
`define MUF_54 {fill[31:27],chn_mode[83*3+:3]  ,fill[23:19] ,chn_mode[82*3+:3] ,fill[15:11]  ,chn_mode[81*3+:3] ,fill[7:3], chn_mode[80*3+:3]}
`define MUF_55 {fill[31:27],chn_mode[87*3+:3]  ,fill[23:19] ,chn_mode[86*3+:3] ,fill[15:11]  ,chn_mode[85*3+:3] ,fill[7:3], chn_mode[84*3+:3]}
`define MUF_56 {fill[31:27],chn_mode[91*3+:3]  ,fill[23:19] ,chn_mode[90*3+:3] ,fill[15:11]  ,chn_mode[89*3+:3] ,fill[7:3], chn_mode[88*3+:3]}
`define MUF_57 {fill[31:27],chn_mode[95*3+:3]  ,fill[23:19] ,chn_mode[94*3+:3] ,fill[15:11]  ,chn_mode[93*3+:3] ,fill[7:3], chn_mode[92*3+:3]}
`define MUF_58 {fill[31:27],chn_mode[99*3+:3]  ,fill[23:19] ,chn_mode[98*3+:3] ,fill[15:11]  ,chn_mode[97*3+:3] ,fill[7:3], chn_mode[96*3+:3]}
`define MUF_59 {fill[31:27],chn_mode[103*3+:3]  ,fill[23:19] ,chn_mode[102*3+:3] ,fill[15:11]  ,chn_mode[101*3+:3] ,fill[7:3], chn_mode[100*3+:3]}
`define MUF_5A {fill[31:27],chn_mode[107*3+:3]  ,fill[23:19] ,chn_mode[106*3+:3] ,fill[15:11]  ,chn_mode[105*3+:3] ,fill[7:3], chn_mode[104*3+:3]}
`define MUF_5B {fill[31:27],chn_mode[111*3+:3]  ,fill[23:19] ,chn_mode[110*3+:3] ,fill[15:11]  ,chn_mode[109*3+:3] ,fill[7:3], chn_mode[108*3+:3]}
`define MUF_5C {fill[31:27],chn_mode[115*3+:3]  ,fill[23:19] ,chn_mode[114*3+:3] ,fill[15:11]  ,chn_mode[113*3+:3] ,fill[7:3], chn_mode[112*3+:3]}
`define MUF_5D {fill[31:27],chn_mode[119*3+:3]  ,fill[23:19] ,chn_mode[118*3+:3] ,fill[15:11]  ,chn_mode[117*3+:3] ,fill[7:3], chn_mode[116*3+:3]}
`define MUF_5E {fill[31:27],chn_mode[123*3+:3]  ,fill[23:19] ,chn_mode[122*3+:3] ,fill[15:11]  ,chn_mode[121*3+:3] ,fill[7:3], chn_mode[120*3+:3]}
`define MUF_5F {fill[31:27],chn_mode[127*3+:3]  ,fill[23:19] ,chn_mode[126*3+:3] ,fill[15:11]  ,chn_mode[125*3+:3] ,fill[7:3], chn_mode[124*3+:3]}
`define MUF_60 {fill[31:27],chn_mode[131*3+:3]  ,fill[23:19] ,chn_mode[130*3+:3] ,fill[15:11]  ,chn_mode[129*3+:3] ,fill[7:3], chn_mode[128*3+:3]}
`define MUF_61 {fill[31:27],chn_mode[135*3+:3]  ,fill[23:19] ,chn_mode[134*3+:3] ,fill[15:11]  ,chn_mode[133*3+:3] ,fill[7:3], chn_mode[132*3+:3]}


`define MUF_80 {trig_len}

`define MUF_C1 {tout_en}
`define MUF_D0 {fill[31:26],tout_time[1*10+:10],fill[15:10],tout_time[0*10+:10]}
`define MUF_D1 {fill[31:26],tout_time[3*10+:10],fill[15:10],tout_time[2*10+:10]}
`define MUF_D2 {fill[31:26],tout_time[5*10+:10],fill[15:10],tout_time[4*10+:10]}

`define MUF_E0 {hin_len[15:0],fill[15:1],hin_en}

`timescale 1 ns / 1 ns
module multif_cib#(
parameter                           U_DLY    = 1,
parameter                           FRAME_LEN= 8192,
parameter                           USER_NUM = 25,
parameter                           NUM_1S   = 6,
parameter                           NUM_2S   = 3
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

output reg   [136-1:0]         chn_ctrl,
output reg   [136*3-1:0]       chn_mode,
(* max_fanout=10 *)
output reg   [18:0]                 trig_len,
output reg   [6*10-1:0]             tout_time,
output reg   [31:0]                 tout_en,
output reg                          hin_en,
output reg   [15:0]                 hin_len,


input        [USER_NUM-1:0]         indata_vld,
input        [NUM_1S-1:0]           fifo_overflow_1s,
input        [NUM_2S-1:0]           fifo_overflow_2s,
input                               fifo_overflow_2level,

input        [NUM_1S-1:0]           fifo_prog_empty_1s,
input        [NUM_2S-1:0]           fifo_prog_empty_2s, 
input                               fifo_prog_empty_2level,
input        [USER_NUM-1:0]         fifo_empty,
input        [23:0]                 band,
input        [USER_NUM-1:0]         infifo_overflow      
);
// Parameter Define 

// Register Define 
reg     [7:0]                       cpu_raddr;
reg                                 cpu_rd_dly;
reg                                 cpu_wr_dly;
reg     [31:0]                      test;
reg     [31:0]                      fill;
reg     [NUM_1S-1:0]                fifo_overflow_1s_r1;
reg     [NUM_1S-1:0]                fifo_overflow_1s_r2;
reg     [NUM_2S-1:0]                fifo_overflow_2s_r1;
reg     [NUM_2S-1:0]                fifo_overflow_2s_r2;
reg                                 fifo_overflow_2level_r1;
reg                                 fifo_overflow_2level_r2;
reg                                 his_fifo_overflow;
reg                                 fifo_prog_empty;
reg     [USER_NUM-1:0]              indata_vld_r1;
reg     [USER_NUM-1:0]              indata_vld_r2;
reg                                 vld_indication;
reg     [USER_NUM-1:0]              infifo_overflow_r1;
reg     [USER_NUM-1:0]              infifo_overflow_r2;

// Wire Define 
wire                                cpu_wr_det;
wire                                cpu_rd_det;
wire                                cpu_rd_st;
wire    [31:0]                      frame_byte_len;


//-----------------------------------------------------------------------------------------------
//local bus logic
//-----------------------------------------------------------------------------------------------
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
assign cpu_wr_det = (cpu_wr==1'b0 && cpu_wr_dly==1'b1 && cpu_cs==1'b0)?1'b1:1'b0;
assign cpu_rd_det = (cpu_rd==1'b1 && cpu_rd_dly==1'b0 && cpu_cs==1'b0)?1'b1:1'b0;
assign cpu_rd_st =  (cpu_rd==1'b0 && cpu_rd_dly==1'b1 && cpu_cs==1'b0)?1'b1:1'b0;



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
        cpu_rd_data <= 'h1234_beef;
    else
    case(cpu_raddr)
        8'h01:cpu_rd_data <= #U_DLY `MUF_01;
        8'h02:cpu_rd_data <= #U_DLY `MUF_02;
        8'h10:cpu_rd_data <= #U_DLY `MUF_10;
        8'h11:cpu_rd_data <= #U_DLY `MUF_11;
        8'h12:cpu_rd_data <= #U_DLY `MUF_12;
        //8'h13:cpu_rd_data <= #U_DLY `MUF_13;
        //8'h14:cpu_rd_data <= #U_DLY `MUF_14;
        //8'h15:cpu_rd_data <= #U_DLY `MUF_15;
        //8'h16:cpu_rd_data <= #U_DLY `MUF_16;
        8'h20:cpu_rd_data <= #U_DLY `MUF_20;
        8'h21:cpu_rd_data <= #U_DLY `MUF_21;
        8'h22:cpu_rd_data <= #U_DLY `MUF_22;
        8'h23:cpu_rd_data <= #U_DLY `MUF_23;
        8'h24:cpu_rd_data <= #U_DLY `MUF_24;
        8'h30:cpu_rd_data <= #U_DLY `MUF_30;
        //8'h31:cpu_rd_data <= #U_DLY `MUF_31;
        //8'h32:cpu_rd_data <= #U_DLY `MUF_32;
        //8'h33:cpu_rd_data <= #U_DLY `MUF_33;
        //8'h34:cpu_rd_data <= #U_DLY `MUF_34;
        8'h40:cpu_rd_data <= #U_DLY `MUF_40;
        8'h41:cpu_rd_data <= #U_DLY `MUF_41;
        8'h42:cpu_rd_data <= #U_DLY `MUF_42;
        8'h43:cpu_rd_data <= #U_DLY `MUF_43;
        8'h44:cpu_rd_data <= #U_DLY `MUF_44;
        8'h45:cpu_rd_data <= #U_DLY `MUF_45;
        8'h46:cpu_rd_data <= #U_DLY `MUF_46;
        8'h47:cpu_rd_data <= #U_DLY `MUF_47;
        8'h48:cpu_rd_data <= #U_DLY `MUF_48;
        8'h49:cpu_rd_data <= #U_DLY `MUF_49;
        8'h4A:cpu_rd_data <= #U_DLY `MUF_4A;
        8'h4B:cpu_rd_data <= #U_DLY `MUF_4B;
        8'h4C:cpu_rd_data <= #U_DLY `MUF_4C;
        8'h4D:cpu_rd_data <= #U_DLY `MUF_4D;
        8'h4E:cpu_rd_data <= #U_DLY `MUF_4E;
        8'h4F:cpu_rd_data <= #U_DLY `MUF_4F;
        8'h50:cpu_rd_data <= #U_DLY `MUF_50;
        8'h51:cpu_rd_data <= #U_DLY `MUF_51;
        8'h52:cpu_rd_data <= #U_DLY `MUF_52;
        8'h53:cpu_rd_data <= #U_DLY `MUF_53;
        8'h54:cpu_rd_data <= #U_DLY `MUF_54;
        8'h55:cpu_rd_data <= #U_DLY `MUF_55;
        8'h56:cpu_rd_data <= #U_DLY `MUF_56;
        8'h57:cpu_rd_data <= #U_DLY `MUF_57;
        8'h58:cpu_rd_data <= #U_DLY `MUF_58;
        8'h59:cpu_rd_data <= #U_DLY `MUF_59;
        8'h5A:cpu_rd_data <= #U_DLY `MUF_5A;
        8'h5B:cpu_rd_data <= #U_DLY `MUF_5B;
        8'h5C:cpu_rd_data <= #U_DLY `MUF_5C;
        8'h5D:cpu_rd_data <= #U_DLY `MUF_5D;
        8'h5E:cpu_rd_data <= #U_DLY `MUF_5E;
        8'h5F:cpu_rd_data <= #U_DLY `MUF_5F;
        8'h60:cpu_rd_data <= #U_DLY `MUF_60;
        8'h61:cpu_rd_data <= #U_DLY `MUF_61;

        8'h80:cpu_rd_data <= #U_DLY `MUF_80;
        8'hC1:cpu_rd_data <= #U_DLY `MUF_C1;
        8'hD0:cpu_rd_data <= #U_DLY `MUF_D0;
        8'hD1:cpu_rd_data <= #U_DLY `MUF_D1;
        8'hD2:cpu_rd_data <= #U_DLY `MUF_D2;
        8'hE0:cpu_rd_data <= #U_DLY `MUF_E0;
        default:cpu_rd_data <= #U_DLY 32'h1234_beef;  	    	
    endcase
end


//  Write Moudle
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            `MUF_01 <= 32'hdead_beef;
            `MUF_20 <= 32'h0;
            `MUF_21 <= 32'h0;
            `MUF_22 <= 32'h0;
            `MUF_23 <= 32'h0;
            `MUF_24 <= 32'h0;
            `MUF_40 <= 32'h0;
            `MUF_41 <= 32'h0;
            `MUF_42 <= 32'h0;
            `MUF_43 <= 32'h0;
            `MUF_44 <= 32'h0;
            `MUF_45 <= 32'h0;
            `MUF_46 <= 32'h0;
            `MUF_47 <= 32'h0;
            `MUF_48 <= 32'h0;
            `MUF_49 <= 32'h0;
            `MUF_4A <= 32'h0;
            `MUF_4B <= 32'h0;
            `MUF_4C <= 32'h0;
            `MUF_4D <= 32'h0;
            `MUF_4E <= 32'h0;
            `MUF_4F <= 32'h0;
            `MUF_50 <= 32'h0;
            `MUF_51 <= 32'h0;
            `MUF_52 <= 32'h0;
            `MUF_53 <= 32'h0;
            `MUF_54 <= 32'h0;
            `MUF_55 <= 32'h0;
            `MUF_56 <= 32'h0;
            `MUF_57 <= 32'h0;
            `MUF_58 <= 32'h0;
            `MUF_59 <= 32'h0;
            `MUF_5A <= 32'h0;
            `MUF_5B <= 32'h0;
            `MUF_5C <= 32'h0;
            `MUF_5D <= 32'h0;
            `MUF_5E <= 32'h0;
            `MUF_5F <= 32'h0;
            `MUF_60 <= 32'h0;
            `MUF_61 <= 32'h0;
            `MUF_80 <= 32'h0;
            `MUF_C1 <= 32'hffff_ffff;
            `MUF_D0 <= 32'h03e8_03e8;
            `MUF_D1 <= 32'h03e8_03e8;
            `MUF_D2 <= 32'h0032_0032;
            `MUF_E0 <= 32'h0400_0001;

            fill <= 32'd0;
        end
    else    
        begin
            if({cpu_wr,cpu_wr_dly} == 2'b01 && cpu_cs == 1'b0)
                begin
                    case(cpu_addr)
                        8'h01:  `MUF_01 <= #U_DLY cpu_wr_data;
                        8'h20:  `MUF_20 <= #U_DLY cpu_wr_data;
                        8'h21:  `MUF_21 <= #U_DLY cpu_wr_data;
                        8'h22:  `MUF_22 <= #U_DLY cpu_wr_data;
                        8'h23:  `MUF_23 <= #U_DLY cpu_wr_data;
                        8'h24:  `MUF_24 <= #U_DLY cpu_wr_data;
                        8'h40:  `MUF_40 <= #U_DLY cpu_wr_data;
                        8'h41:  `MUF_41 <= #U_DLY cpu_wr_data;
                        8'h42:  `MUF_42 <= #U_DLY cpu_wr_data;
                        8'h43:  `MUF_43 <= #U_DLY cpu_wr_data;
                        8'h44:  `MUF_44 <= #U_DLY cpu_wr_data;
                        8'h45:  `MUF_45 <= #U_DLY cpu_wr_data;
                        8'h46:  `MUF_46 <= #U_DLY cpu_wr_data;
                        8'h47:  `MUF_47 <= #U_DLY cpu_wr_data;
                        8'h48:  `MUF_48 <= #U_DLY cpu_wr_data;
                        8'h49:  `MUF_49 <= #U_DLY cpu_wr_data;
                        8'h4A:  `MUF_4A <= #U_DLY cpu_wr_data;
                        8'h4B:  `MUF_4B <= #U_DLY cpu_wr_data;
                        8'h4C:  `MUF_4C <= #U_DLY cpu_wr_data;
                        8'h4D:  `MUF_4D <= #U_DLY cpu_wr_data;
                        8'h4E:  `MUF_4E <= #U_DLY cpu_wr_data;
                        8'h4F:  `MUF_4F <= #U_DLY cpu_wr_data;
                        8'h50:  `MUF_50 <= #U_DLY cpu_wr_data;
                        8'h51:  `MUF_51 <= #U_DLY cpu_wr_data;
                        8'h52:  `MUF_52 <= #U_DLY cpu_wr_data;
                        8'h53:  `MUF_53 <= #U_DLY cpu_wr_data;
                        8'h54:  `MUF_54 <= #U_DLY cpu_wr_data;
                        8'h55:  `MUF_55 <= #U_DLY cpu_wr_data;
                        8'h56:  `MUF_56 <= #U_DLY cpu_wr_data;
                        8'h57:  `MUF_57 <= #U_DLY cpu_wr_data;
                        8'h58:  `MUF_58 <= #U_DLY cpu_wr_data;
                        8'h59:  `MUF_59 <= #U_DLY cpu_wr_data;
                        8'h5A:  `MUF_5A <= #U_DLY cpu_wr_data;
                        8'h5B:  `MUF_5B <= #U_DLY cpu_wr_data;
                        8'h5C:  `MUF_5C <= #U_DLY cpu_wr_data;
                        8'h5D:  `MUF_5D <= #U_DLY cpu_wr_data;
                        8'h5E:  `MUF_5E <= #U_DLY cpu_wr_data;
                        8'h5F:  `MUF_5F <= #U_DLY cpu_wr_data;
                        8'h60:  `MUF_60 <= #U_DLY cpu_wr_data;
                        8'h61:  `MUF_61 <= #U_DLY cpu_wr_data;
                        8'h80:  `MUF_80 <= #U_DLY cpu_wr_data;
                        
                        8'hC1:  `MUF_C1 <= #U_DLY cpu_wr_data;
                        8'hD0:  `MUF_D0 <= #U_DLY cpu_wr_data;
                        8'hD1:  `MUF_D1 <= #U_DLY cpu_wr_data;
                        8'hD2:  `MUF_D2 <= #U_DLY cpu_wr_data;
                        8'hE0:  `MUF_E0 <= #U_DLY cpu_wr_data;
                        default:;
                    endcase
                end
            else
                fill <= #U_DLY 32'd0;
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)        
        begin
            fifo_overflow_1s_r1 <= #U_DLY 'b0;
            fifo_overflow_1s_r2 <= #U_DLY 'b0;
            fifo_overflow_2s_r1 <= #U_DLY 'b0;
            fifo_overflow_2s_r2 <= #U_DLY 'b0;
            fifo_overflow_2level_r1 <= #U_DLY 'b0;
            fifo_overflow_2level_r2 <= #U_DLY 'b0;  
            infifo_overflow_r1 <= #U_DLY 'b0;
            infifo_overflow_r2 <= #U_DLY 'b0;
            fifo_prog_empty <= #U_DLY 1'b1;   
        end       
    else    
        begin
            fifo_overflow_1s_r1 <= #U_DLY fifo_overflow_1s;
            fifo_overflow_1s_r2 <= #U_DLY fifo_overflow_1s_r1;
            fifo_overflow_2s_r1 <= #U_DLY fifo_overflow_2s;
            fifo_overflow_2s_r2 <= #U_DLY fifo_overflow_2s_r1;
            fifo_overflow_2level_r1 <= #U_DLY fifo_overflow_2level;
            fifo_overflow_2level_r2 <= #U_DLY fifo_overflow_2level_r1;      
            infifo_overflow_r1 <= #U_DLY infifo_overflow;
            infifo_overflow_r2 <= #U_DLY infifo_overflow_r1;
            
            if( ((&fifo_prog_empty_1s==1'b0) && (&fifo_prog_empty_2s==1'b0) && (fifo_prog_empty_2level==1'b0) ) ==1'b0 )    
                fifo_prog_empty  <= #U_DLY 1'b0;
            else
                fifo_prog_empty  <= #U_DLY 1'b1;
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            his_fifo_overflow <= #U_DLY 1'b0;
        end       
    else    
        begin
            if(cpu_rd_det==1'b1 && cpu_addr==8'h10)
                his_fifo_overflow <= #U_DLY (|fifo_overflow_2level_r2) || (|fifo_overflow_1s_r2) ||  (|fifo_overflow_2s_r2) || (|infifo_overflow_r2);
            else if( ((|fifo_overflow_2level_r2) || (|fifo_overflow_1s_r2) || (|fifo_overflow_2s_r2) || (|infifo_overflow_r2)) ==1'b1)
                his_fifo_overflow <= #U_DLY 1'b1;
        end
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin     
            indata_vld_r1 <= #U_DLY 'd0;
            indata_vld_r2 <= #U_DLY 'd0;
            vld_indication <= #U_DLY 1'b0;
        end        
    else  
        begin
            indata_vld_r1 <= #U_DLY indata_vld;
            indata_vld_r2 <= #U_DLY indata_vld_r1;

            if(|indata_vld_r2==1'b1)
                vld_indication <= #U_DLY 1'b1;
            else
                vld_indication <= #U_DLY 1'b0;
        end  
end

assign frame_byte_len=FRAME_LEN;

endmodule

