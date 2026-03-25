// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/03/13 10:08:46
// File Name    : mefc_cib.v
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
`define MEFC_00 {VERSION}
`define MEFC_01 {YEAR,MONTH,DAY}
`define MEFC_02 {test_reg}
`define MEFC_04 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,ers_start}
`define MEFC_05 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,wb_start}
`define MEFC_06 {fill31,fill30,fill29,fill28,fill27,fill26,wb_start_addr}
`define MEFC_07 {fill31,fill30,fill29,fill28,fill27,fill26,wb_word_len}
`define MEFC_08 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,rd_start}
`define MEFC_09 {fill31,fill30,fill29,fill28,fill27,fill26,rd_start_addr}
`define MEFC_0A {fill31,fill30,fill29,fill28,fill27,fill26,rd_word_len}
`define MEFC_0B {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,ers_sector_en}
`define MEFC_0C {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,ers_sector_addr}
`define MEFC_10 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,cur_st_free}
`define MEFC_11 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,alm_ers_reg_done,alm_rd_reg_done,alm_wb_reg_done}
`define MEFC_12 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,alm_his_ers_fail,alm_his_wb_fail}
`define MEFC_13 {fill31,fill30,fill29,fill28,fill27,fill26,cur_all_data_wcnt}
`define MEFC_18 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,alm_his_rfifo_full,alm_his_wfifo_empty}
`define MEFC_20 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,bit_order,fill3,fill2,fill1,r_sts_reg_en}
`define MEFC_30 {cnt_indata}


module mefc_cib #(
parameter                           U_DLY = 1,
parameter                           CPU_ADDR_W = 8,
parameter                           VERSION =32'h0000_0001,
parameter                           YEAR = 16'h2018,
parameter                           MONTH = 8'h03,
parameter                           DAY = 8'h13
)
(
input                               clk,
input                               rst,
//cpu bus
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [CPU_ADDR_W - 1:0]  cpu_addr,
input           [31:0]              cpu_wdata,
output  reg     [31:0]              cpu_rdata,
//others config
output  reg                         wb_start,
output  reg     [25:0]              wb_start_addr,
output  reg     [25:0]              wb_word_len,                    //base on word

output  reg                         rd_start,
output  reg     [25:0]              rd_start_addr,
output  reg     [25:0]              rd_word_len,                    //base on word

output  reg                         ers_start,
output  reg                         ers_sector_en,
output  reg     [9:0]               ers_sector_addr,

input                               st_free,
input                               wb_fail,
input                               ers_fail,
input                               wb_reg_done,
input                               rd_reg_done,
input                               ers_reg_done,
output  reg                         r_sts_reg_en,
input            [25:0]             all_data_wcnt,
output  reg                         bit_order,
input                               indata_cnt_ind, 

input                               wfifo_empty,
input                               rfifo_full
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
reg                cpu_we_dly;
reg                cpu_rd_dly;
reg  [31:0]        test_reg;

// Wire Define 
wire                                cpu_read_en;
wire                                cur_st_free;
wire     [25:0]                     cur_all_data_wcnt;
wire                                alm_his_wb_fail;
wire                                alm_his_ers_fail;
wire                                alm_his_wfifo_empty;
wire                                alm_his_rfifo_full;
wire                                alm_rd_reg_done;
wire                                alm_wb_reg_done;
wire                                alm_ers_reg_done;
wire     [31:0]                     cnt_indata;

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cpu_we_dly <= 1'b1;
            cpu_rd_dly <= 1'b1;
        end
    else
        begin
            cpu_we_dly <= #U_DLY cpu_we;
            cpu_rd_dly <= #U_DLY cpu_rd;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            `MEFC_02 <= 32'h0000_0000;
            `MEFC_04 <= 32'h0000_0000;
            `MEFC_05 <= 32'h0000_0000;
            `MEFC_06 <= 32'h0000_0000;
            `MEFC_07 <= 32'h0000_0000;
            `MEFC_08 <= 32'h0000_0000;
            `MEFC_09 <= 32'h0000_0000;
            `MEFC_0A <= 32'h0000_0000;
            `MEFC_0B <= 32'h0000_0000;
            `MEFC_0C <= 32'h0000_0000;
            `MEFC_20 <= 32'h0000_0011;
        end
    else
        begin
            if({cpu_we_dly,cpu_we} == 2'b10 && cpu_cs == 1'b0)
                 begin
                    case(cpu_addr)
                        8'h02:`MEFC_02 <= #U_DLY ~cpu_wdata;        
                        8'h04:`MEFC_04 <= #U_DLY cpu_wdata;      
                        8'h05:`MEFC_05 <= #U_DLY cpu_wdata;      
                        8'h06:`MEFC_06 <= #U_DLY cpu_wdata;      
                        8'h07:`MEFC_07 <= #U_DLY cpu_wdata;      
                        8'h08:`MEFC_08 <= #U_DLY cpu_wdata;      
                        8'h09:`MEFC_09 <= #U_DLY cpu_wdata;      
                        8'h0A:`MEFC_0A <= #U_DLY cpu_wdata;      
                        8'h0B:`MEFC_0B <= #U_DLY cpu_wdata;      
                        8'h0C:`MEFC_0C <= #U_DLY cpu_wdata;      
                        8'h20:`MEFC_20 <= #U_DLY cpu_wdata;      
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
            if({cpu_rd_dly,cpu_rd} == 2'b10 && cpu_cs == 1'b0)
                 begin
                    case(cpu_addr)
                        8'h00:cpu_rdata <= #U_DLY `MEFC_00;     
                        8'h01:cpu_rdata <= #U_DLY `MEFC_01;  
                        8'h02:cpu_rdata <= #U_DLY `MEFC_02;                          
                        8'h04:cpu_rdata <= #U_DLY `MEFC_04;                          
                        8'h05:cpu_rdata <= #U_DLY `MEFC_05;                          
                        8'h06:cpu_rdata <= #U_DLY `MEFC_06;                          
                        8'h07:cpu_rdata <= #U_DLY `MEFC_07;                          
                        8'h08:cpu_rdata <= #U_DLY `MEFC_08;                          
                        8'h09:cpu_rdata <= #U_DLY `MEFC_09;                          
                        8'h0A:cpu_rdata <= #U_DLY `MEFC_0A;                          
                        8'h0B:cpu_rdata <= #U_DLY `MEFC_0B;                          
                        8'h0C:cpu_rdata <= #U_DLY `MEFC_0C;                          
                        8'h10:cpu_rdata <= #U_DLY `MEFC_10;                          
                        8'h11:cpu_rdata <= #U_DLY `MEFC_11;                          
                        8'h12:cpu_rdata <= #U_DLY `MEFC_12;                          
                        8'h13:cpu_rdata <= #U_DLY `MEFC_13;                          
                        8'h18:cpu_rdata <= #U_DLY `MEFC_18;                          
                        8'h20:cpu_rdata <= #U_DLY `MEFC_20;                          
                        8'h30:cpu_rdata <= #U_DLY `MEFC_30;                          
                        default:cpu_rdata <= #U_DLY 'd0;
                    endcase
                end
            else;
        end
end

assign cpu_read_en = ({cpu_rd_dly,cpu_rd} == 2'b10 && cpu_cs == 1'b0) ? 1'b1 : 1'b0;


alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_cur_st_free(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (st_free                    ),
    .alarm_current              (cur_st_free                )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (26                         )
)
u_cur_wb_datacnt(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (all_data_wcnt              ),
    .alarm_current              (cur_all_data_wcnt          )
);
//*************************************************************************//
alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             (8'h11                      )
)
u_his_wb_reg_done(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (wb_reg_done                ),
    .alarm_history              (alm_wb_reg_done            )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             (8'h11                      )
)
u_his_rd_reg_done(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (rd_reg_done                ),
    .alarm_history              (alm_rd_reg_done            )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             (8'h11                      )
)
u_his_ers_reg_done(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (ers_reg_done               ),
    .alarm_history              (alm_ers_reg_done           )
);
//**********************************************************************//
alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             (8'h12                      )
)
u_his_wb_fail(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (wb_fail                    ),
    .alarm_history              (alm_his_wb_fail            )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             (8'h12                      )
)
u_his_ers_fail(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (ers_fail                   ),
    .alarm_history              (alm_his_ers_fail           )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             (8'h18                      )
)
u_his_wfifo_empty(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (wfifo_empty                ),
    .alarm_history              (alm_his_wfifo_empty        )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             (8'h18                      )
)
u_his_rfifo_full(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (rfifo_full                 ),
    .alarm_history              (alm_his_rfifo_full         )
);
//***************************************************************//
cib_counter_32b #(
    .U_DLY                      (U_DLY                      ),
    .CYCLE_EN                   ("YES"                      ),//"YES" : cycle counter ; "NO" : no cycle counter
    .CLEAR_EN                   ("YES"                      ),//"YES" : read clear ; "NO" : read but no clear
    .CLK_ASYNC                  ("TRUE"                     ),//"TRUE" : clk_cpu and clk_src are async; "FALSE" : the same clock
    .CPU_ADDR_W                 (CPU_ADDR_W                 ),
    .COUNTER_ADDR               ('h30                       )
)
u_counter_indata_cnt(
    .rst                        (rst                        ),
    .clk_cpu                    (clk                        ),
    .clk_src                    (clk                        ),
//
    .counter_en                 (indata_cnt_ind             ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_read_en                (cpu_read_en                ),
    .counter_value              (cnt_indata                 )
);

endmodule

