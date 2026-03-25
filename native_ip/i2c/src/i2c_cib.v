// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/12/12 10:08:46
// File Name    : i2c_cib.v
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
`define I2C_00 {VERSION}
`define I2C_01 {YEAR,MONTH,DAY}
`define I2C_02 {test_reg}
`define I2C_04 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,i2c_start}
`define I2C_05 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,i2c_scl_prd}
`define I2C_06 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,last_read_ack,fill15,fill14,fill13,fill12,fill11,fill10,i2c_op_len,fill3,i2c_header_len}
`define I2C_07 {i2c_sto_setup,i2c_sta_hold}
`define I2C_08 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,his_slave_no_ack}
`define I2C_09 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,cur_i2c_master_free}

module i2c_cib #(
parameter                           U_DLY = 1,
parameter                           CPU_ADDR_W = 7 ,
parameter                           VERSION =32'h00_00_00_01,
parameter                           YEAR = 16'h20_17,
parameter                           MONTH = 8'h12,
parameter                           DAY = 8'h12
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
output  reg                         i2c_start,
output  reg      [23:0]             i2c_scl_prd,          //min freq:10K
output  reg      [2:0]              i2c_header_len,
output  reg      [5:0]              i2c_op_len,
output  reg      [15:0]             i2c_sta_hold,         //start hold time.a high-to-low transition of SDA.
output  reg      [15:0]             i2c_sto_setup,
output  reg                         last_read_ack,
input                               slave_no_ack,
input                               i2c_master_free
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
wire                                his_slave_no_ack;
wire                                cpu_read_en;
wire                                cur_i2c_master_free;


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
            `I2C_02 <= 32'h0000_0000;
            `I2C_04 <= 32'h0000_0000;
            `I2C_05 <= 32'h0000_03E8;      //100K
            `I2C_06 <= 32'h0000_0022;
            `I2C_07 <= 32'h00ff_00ff;
        end
    else
        begin
            if({cpu_we_dly,cpu_we} == 2'b10 && cpu_cs == 1'b0)
                 begin
                    case(cpu_addr)
                        7'h02:`I2C_02 <= #U_DLY ~cpu_wdata;        
                        7'h04:`I2C_04 <= #U_DLY cpu_wdata;  
                        7'h05:`I2C_05 <= #U_DLY cpu_wdata;                         
                        7'h06:`I2C_06 <= #U_DLY cpu_wdata; 
                        7'h07:`I2C_07 <= #U_DLY cpu_wdata;     
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
                        7'h00:cpu_rdata <= #U_DLY `I2C_00;     
                        7'h01:cpu_rdata <= #U_DLY `I2C_01;  
                        7'h02:cpu_rdata <= #U_DLY `I2C_02;                          
                        7'h04:cpu_rdata <= #U_DLY `I2C_04;                          
                        7'h05:cpu_rdata <= #U_DLY `I2C_05; 
                        7'h06:cpu_rdata <= #U_DLY `I2C_06;  
                        7'h07:cpu_rdata <= #U_DLY `I2C_07;
                        7'h08:cpu_rdata <= #U_DLY `I2C_08;
                        7'h09:cpu_rdata <= #U_DLY `I2C_09;
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
u_cur_i2c_master_free(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
//    .cpu_read_en                (cpu_read_en                ),
    .alarm_in                   (i2c_master_free            ),
    .alarm_current              (cur_i2c_master_free        )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (7                          ),
    .ALARM_HIS_ADDR             (7'h08                      )
)
u_his_slave_no_ack(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (slave_no_ack               ),
    .alarm_history              (his_slave_no_ack           )
);

endmodule

