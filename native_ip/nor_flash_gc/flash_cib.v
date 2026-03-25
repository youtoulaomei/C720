// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/12/5 10:08:46
// File Name    : uart_cib.v
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
`define FLASH_00 {VERSION}
`define FLASH_01 {YEAR,MONTH,DAY}
`define FLASH_02 {test_reg}
`define FLASH_10 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,istart_opt_flash,fill7,fill6,fill5,fill4,fill3,fill2,his_oexceed_max_time,his_oflag_wr_chk_err}
`define FLASH_30 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,istart_opt_flash,fill7,fill6,fill5,iwrite_done,fill3,iconfig_cmd}
`define FLASH_31 {fill31,fill30,fill29,fill28,fill27,iuser_adr} //write flash addr 
`define FLASH_32 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,ird_flash_num} //read flash byte num
`define FLASH_33 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fifo2_empty,fill2,fill1,oflash_rdy} //read flash byte num

module flash_cib #(
parameter                           U_DLY = 1,
parameter                           CPU_ADDR_W = 7 ,
parameter                           VERSION =32'h00_00_00_01,
parameter                           YEAR = 16'h20_23,
parameter                           MONTH = 8'h05,
parameter                           DAY = 8'h05
)
(
input                               clk,
input                               rst,
//cpu bus
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [7:0]               cpu_addr,
input           [31:0]              cpu_wdata,
output  reg     [31:0]              cpu_rdata,



//others config

input                               fifo2_empty,    // input wire [0 : 0] probe_in0
input                               oflash_rdy      ,    // input wire [0 : 0] probe_in0
input                               oexceed_max_time,    // input wire [0 : 0] probe_in1
input                               oflag_wr_chk_err,    // input wire [0 : 0] probe_in2
output  reg                         istart_opt_flash,  // output wire [0 : 0] probe_out0
output  reg     [2 : 0]             iconfig_cmd     ,  // output wire [2 : 0] probe_out1
output  reg                         iwrite_done     ,  // output wire [0 : 0] probe_out2
output  reg     [26 : 0]            iuser_adr       ,  // output wire [26 : 0] probe_out3
output  reg     [23 : 0]            ird_flash_num    // output wire [23 : 0] probe_out4

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
wire                                cur_send_busy;
wire  [15:0]                        cur_rdata_ram_wl;
wire                                cpu_read_en;
wire                                his_check_err;
wire                                his_stop_err;
wire                                his_rdata_ram_full;
wire                                his_rdata_overflow;
wire  [15:0]                        cur_min_pulse_cnt;
wire  [31:0]                        cnt_rx_signal_edge;
wire                                his_oexceed_max_time;
wire                                his_oflag_wr_chk_err;


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
            `FLASH_02 <= 32'h0000_0000;
            `FLASH_30 <= 32'h0000_0000;            
            `FLASH_31 <= 32'h0000_0000;            
            `FLASH_32 <= 32'h0000_0000;            
        end
    else
        begin
            if({cpu_we_dly,cpu_we} == 2'b10 && cpu_cs == 1'b0)
                 begin
                    case(cpu_addr)
                        7'h02:`FLASH_02 <= #U_DLY ~cpu_wdata;                          
                        7'h30:`FLASH_30 <= #U_DLY cpu_wdata;                         
                        7'h31:`FLASH_31 <= #U_DLY cpu_wdata;                         
                        7'h32:`FLASH_32 <= #U_DLY cpu_wdata;                         
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
                        7'h00:cpu_rdata <= #U_DLY `FLASH_00;     
                        7'h01:cpu_rdata <= #U_DLY `FLASH_01;  
                        7'h02:cpu_rdata <= #U_DLY `FLASH_02;                          
                        7'h10:cpu_rdata <= #U_DLY `FLASH_10;
                        7'h30:cpu_rdata <= #U_DLY `FLASH_30;
                        7'h31:cpu_rdata <= #U_DLY `FLASH_31;
                        7'h32:cpu_rdata <= #U_DLY `FLASH_32;
                        7'h33:cpu_rdata <= #U_DLY `FLASH_33;
                        default:cpu_rdata <= #U_DLY 'd0;
                    endcase
                end
            else;
        end
end

assign cpu_read_en = ({cpu_rd_dly,cpu_rd} == 2'b10 && cpu_cs == 1'b0) ? 1'b1 : 1'b0;



alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             (7'h10                      )
)
u_alm_his_oflag_wr_chk_err(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (oflag_wr_chk_err                  ),
    .alarm_history              (his_oflag_wr_chk_err              )
);
alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (CPU_ADDR_W                 ),
    .ALARM_HIS_ADDR             (7'h10                      )
)
u_alm_(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (oexceed_max_time                  ),
    .alarm_history              (his_oexceed_max_time              )
);

endmodule

