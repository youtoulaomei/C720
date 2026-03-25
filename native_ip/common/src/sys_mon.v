// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/12/25 10:38:15
// File Name    : sys_mon.v
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
`include "./device_cfg.v"
module sys_mon #(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst,
//others
input                               timing_1ms,
//output
output  reg     [11:0]              device_temp,
output  reg     [11:0]              device_vccint,
output  reg     [11:0]              device_vccaux,
output  reg     [11:0]              device_vccbram,
output  wire    [3:0]               xadc_alm
);
// Parameter Define 
localparam                          IDLE = 5'b0_0001;
localparam                          TEMP = 5'b0_0010;
localparam                          VCCINT = 5'b0_0100;
localparam                          VCCAUX = 5'b0_1000;
localparam                          VCCBRAM = 5'b1_0000;
// Register Define 
reg     [6:0]                       xadc_addr;
reg                                 xadc_den;
reg     [2:0]                       ms1_level_dly;
reg     [2:0]                       ms8_cnt;
reg                                 ms8_ind;
reg     [4:0]                       xadc_cur_st_dly;
reg     [4:0]                       xadc_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [4:0]                       xadc_next_st;
// Wire Define 
wire    [15:0]                      xadc_alm_w;
wire    [15:0]                      xadc_do;

`ifdef SERIES_7
XADC #(
        .INIT_40(16'h8000), // config reg 0
        .INIT_41(16'h3e01), // config reg 1
        .INIT_42(16'h0400), // config reg 2
        // INIT_48 - INIT_4F: Sequence Registers
        .INIT_48(16'h0100), // Sequencer channel selection
        .INIT_49(16'h0000), // Sequencer channel selection
        .INIT_4A(16'h0000), // Sequencer Average selection
        .INIT_4B(16'h0000), // Sequencer Average selection
        .INIT_4C(16'h0000), // Sequencer Bipolar selection
        .INIT_4D(16'h0000), // Sequencer Bipolar selection
        .INIT_4E(16'h0000), // Sequencer Acq time selection
        .INIT_4F(16'h0000), // Sequencer Acq time selection
        // INIT_50 - INIT_58, INIT5C: Alarm Limit Registers
        .INIT_50(16'hbd90), // Temp alarm trigger                    //100
        .INIT_51(16'h57e4), // Vccint upper alarm limit              //1.03V
        .INIT_52(16'ha147), // Vccaux upper alarm limit              //1.89
        .INIT_53(16'hca33), // Temp alarm OT upper                   //125C
        .INIT_54(16'hb362), // Temp alarm reset                      //80           //.INIT_54(16'ha93a), // Temp alarm reset                      //60
        .INIT_55(16'h52c6), // Vccint lower alarm limit              //0.97V
        .INIT_56(16'h91f5), // Vccaux lower alarm limit              //1.71V
        .INIT_57(16'hae4e), // Temp alarm OT reset                   //69.8C
        .INIT_58(16'h57e4), // VBRAM upper alarm limit               //1.03V
        .INIT_5C(16'h52c6), //  VBRAM lower alarm limit              //0.97V
        // Simulation attributes: Set for proepr simulation behavior
        .SIM_DEVICE("7SERIES")  // Select target device (values)
)
u_XADC(
        // ALARMS: 8-bit (each) output: ALM, OT
    .ALM                        (xadc_alm_w[7:0]            ),
    .OT                         (                           ),
        // Dynamic Reconfiguration Port (DRP): 16-bit (each) output: Dynamic Reconfiguration Ports
    .DO                         (xadc_do                    ),
    .DRDY                       (xadc_drdy                  ),
        // STATUS: 1-bit (each) output: XADC status ports
    .BUSY                       (                           ),
    .CHANNEL                    (                           ),
    .EOC                        (                           ),
    .EOS                        (                           ),
    .JTAGBUSY                   (                           ),
    .JTAGLOCKED                 (                           ),
    .JTAGMODIFIED               (                           ),
    .MUXADDR                    (                           ),
        // Auxiliary Analog-Input Pairs: 16-bit (each) input: VAUXP[15:0], VAUXN[15:0]
    .VAUXN                      (16'b0                      ),
    .VAUXP                      (16'b0                      ),
        // CONTROL and CLOCK: 1-bit (each) input: Reset, conversion start and clock inputs
    .CONVST                     (1'b0                       ),
    .CONVSTCLK                  (1'b0                       ),
    .RESET                      (1'b0                       ),
        // Dedicated Analog Input Pair: 1-bit (each) input: VP/VN
    .VN                         (1'b0                       ),
    .VP                         (1'b0                       ),
        // Dynamic Reconfiguration Port (DRP): 7-bit (each) input: Dynamic Reconfiguration Ports
    .DADDR                      (xadc_addr                  ),
    .DCLK                       (clk                        ),
    .DEN                        (xadc_den                   ),
    .DI                         (16'd0                      ),
    .DWE                        (1'b0                       )
);
`endif
`ifdef KINTEX_ULTRASCALE
SYSMONE1 #(                            //for UltraScale
      .INIT_40(16'h9000),// averaging of 16 selected for external channels
      .INIT_41(16'h2EE0),// Continuous Seq Mode, Disable unused ALMs, Enable calibration
      .INIT_42(16'h4000),// Set DCLK divides
      .INIT_43(16'h2E00),// CONFIG3 
      .INIT_46(16'h0001),// CHSEL0 - enable USER0
      .INIT_47(16'h0000),// SEQAVG0 disabled 
      .INIT_48(16'h4701),// CHSEL1 - enable Temp VCCINT, VCCAUX, VCCBRAM, and calibration
      .INIT_49(16'h000F),// CHSEL2 - enable aux analog channels 0 - 3
      .INIT_4A(16'h0000),// SEQAVG1 disabled
      .INIT_4B(16'h0000),// SEQAVG2 disabled
      .INIT_4C(16'h0000),// SEQINMODE0 
      .INIT_4D(16'h0000),// SEQINMODE1
      .INIT_4E(16'h0000),// SEQACQ0
      .INIT_4F(16'h0000),// SEQACQ1
      .INIT_50(16'hB723),// Temp upper alarm trigger 85癈 -For On-Chip Reference
      .INIT_51(16'h5999),// Vccint upper alarm limit 1.05V
      .INIT_52(16'hA147),// Vccaux upper alarm limit 1.89V
      .INIT_53(16'hCB93),// OT upper alarm limit 125癈 - For On-Chip Reference
      .INIT_54(16'hAA5F),// Temp lower alarm reset 60癈 - For On-Chip Reference
      .INIT_55(16'h5111),// Vccint lower alarm limit 0.95V
      .INIT_56(16'h91EB),// Vccaux lower alarm limit 1.71V
      .INIT_57(16'hAF7B),// OT lower alarm reset 70癈 - For On-Chip Reference
      .INIT_58(16'h5999),// VCCBRAM upper alarm limit 1.05V
      .INIT_5C(16'h5111), // VUSER0 upper alarm limit 1.05V 
      .INIT_60(16'h5999), // VUSER1 upper alarm limit 1.05V 
      .INIT_61(16'h5999), // VUSER2 upper alarm limit 1.05V 
      .INIT_62(16'h5999), // VUSER3 upper alarm limit 1.05V 
      .INIT_63(16'h5999), // VCCBRAM lower alarm limit 1.05V 
      .INIT_64(16'h5999), // VCCSYSMON upper alarm limit 1.05V 
      .INIT_68(16'h5111), // VUSER0 lower alarm limit 0.95V 
      .INIT_69(16'h5111), // VUSER1 lower alarm limit 0.95V 
      .INIT_6A(16'h5111), // VUSER2 lower alarm limit 0.95V 
      .INIT_6B(16'h5111), // VUSER3 lower alarm limit 0.95V 
      .INIT_6C(16'h5111), // VCCBRAM lower alarm limit 0.95V 
      .INIT_78(16'h0000), // SEQINMODE2
      .INIT_79(16'h0000), // SEQACQ2
      .SYSMON_VUSER0_BANK(66),
      .SYSMON_VUSER0_MONITOR("VCCO")
   )
u_SYSMONE1 (
      // ALARMS outputs: ALM, OT
    .ALM                        (xadc_alm_w                 ),// 16-bit output: Output alarm for temp, Vccint, Vccaux and Vccbram
    .OT                         (/*not used*/               ),
      // Dynamic Reconfiguration Port (DRP) outputs: Dynamic Reconfiguration Ports
    .DO                         (xadc_do                    ),// 16-bit output: DRP output data bus
    .DRDY                       (xadc_drdy                  ),// 1-bit output: DRP data ready
      // I2C Interface outputs: Ports used with the I2C DRP interface
    .I2C_SCLK_TS                (/*not used*/               ),
    .I2C_SDA_TS                 (/*not used*/               ),
      // STATUS outputs: SYSMON status ports
    .BUSY                       (/*not used*/               ),
    .CHANNEL                    (/*not used*/               ),
    .EOC                        (/*not used*/               ),
    .EOS                        (/*not used*/               ),
    .JTAGBUSY                   (/*not used*/               ),
    .JTAGLOCKED                 (/*not used*/               ),
    .JTAGMODIFIED               (/*not used*/               ),
    .MUXADDR                    (/*not used*/               ),
      // Auxiliary Analog-Input Pairs inputs: VAUXP[15:0], VAUXN[15:0]
    .VAUXN                      (16'b0                      ),
    .VAUXP                      (16'b0                      ),
      // CONTROL and CLOCK inputs: Reset, conversion start and clock inputs
    .CONVST                     (1'b0                       ),
    .CONVSTCLK                  (1'b0                       ),
    .RESET                      (1'b0                       ),
      // Dedicated Analog Input Pair inputs: VP/VN
    .VN                         (1'b0                       ),
    .VP                         (1'b0                       ),
      // Dynamic Reconfiguration Port (DRP) inputs: Dynamic Reconfiguration Ports
    .DADDR                      ({1'b0,xadc_addr}           ),
    .DCLK                       (clk                        ),
    .DEN                        (xadc_den                   ),
    .DI                         (16'd0                      ),
    .DWE                        (1'b0                       ),
      // I2C Interface inputs: Ports used with the I2C DRP interface
    .I2C_SCLK                   (1'b0                       ),
    .I2C_SDA                    (1'b0                       )
);
`endif
assign xadc_alm = xadc_alm_w[3:0];

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            xadc_addr <= 7'd0;
            xadc_den <= 1'b0;
        end
    else
        begin
            if(xadc_cur_st_dly == IDLE && xadc_cur_st == TEMP)
                xadc_addr <= #U_DLY 7'h00;
            else if(xadc_cur_st_dly == TEMP && xadc_cur_st == VCCINT)
                xadc_addr <= #U_DLY 7'h01;
            else if(xadc_cur_st_dly == VCCINT && xadc_cur_st == VCCAUX)
                xadc_addr <= #U_DLY 7'h02;
            else if(xadc_cur_st_dly == VCCAUX && xadc_cur_st == VCCBRAM)
                xadc_addr <= #U_DLY 7'h06;
            else;

            if(xadc_den == 1'b1)
                xadc_den <= #U_DLY 1'b0;
            else if((xadc_cur_st_dly == IDLE && xadc_cur_st == TEMP) || (xadc_cur_st_dly == TEMP && xadc_cur_st == VCCINT)
                 || (xadc_cur_st_dly == VCCINT && xadc_cur_st == VCCAUX) || (xadc_cur_st_dly == VCCAUX && xadc_cur_st == VCCBRAM))
                xadc_den <= #U_DLY 1'b1;
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            ms1_level_dly <= 3'd0;
            ms8_cnt <= 3'd0;
            ms8_ind <= 1'b0;
            xadc_cur_st_dly <= 5'd0;
        end
    else
        begin
            ms1_level_dly <= #U_DLY {ms1_level_dly[1:0],timing_1ms};

            if(ms1_level_dly[2] ^ ms1_level_dly[1] == 1'b1)
                ms8_cnt <= #U_DLY ms8_cnt + 3'd1;
            else;

            if(ms8_cnt == 3'd7 && ms1_level_dly[2] ^ ms1_level_dly[1] == 1'b1)
                ms8_ind <= #U_DLY 1'b1;
            else
                ms8_ind <= #U_DLY 1'b0;

            xadc_cur_st_dly <= #U_DLY xadc_cur_st;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        xadc_cur_st <= IDLE;
    else
        xadc_cur_st <= #U_DLY xadc_next_st;
end

always @(*)
begin
    case(xadc_cur_st)
        IDLE:begin
            if(ms8_ind == 1'b1)
                xadc_next_st = TEMP;
            else
                xadc_next_st = IDLE;end
        TEMP:begin
            if(xadc_drdy == 1'b1)
                xadc_next_st = VCCINT;
            else
                xadc_next_st = TEMP;end
        VCCINT:begin
            if(xadc_drdy == 1'b1)
                xadc_next_st = VCCAUX;
            else
                xadc_next_st = VCCINT;end
        VCCAUX:begin
            if(xadc_drdy == 1'b1)
                xadc_next_st = VCCBRAM;
            else
                xadc_next_st = VCCAUX;end
        VCCBRAM:begin
            if(xadc_drdy == 1'b1)
                xadc_next_st = IDLE;
            else
                xadc_next_st = VCCBRAM;end
        default:xadc_next_st = IDLE;
    endcase
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            device_temp <= 12'd0;
            device_vccint <= 12'd0;
            device_vccaux <= 12'd0;
            device_vccbram <= 12'd0;
        end
    else
        begin
            if(xadc_cur_st == TEMP && xadc_drdy == 1'b1)
                device_temp <= #U_DLY xadc_do[15:4];
            else;

            if(xadc_cur_st == VCCINT && xadc_drdy == 1'b1)
                device_vccint <= #U_DLY xadc_do[15:4];
            else;

            if(xadc_cur_st == VCCAUX && xadc_drdy == 1'b1)
                device_vccaux <= #U_DLY xadc_do[15:4];
            else;

            if(xadc_cur_st == VCCBRAM && xadc_drdy == 1'b1)
                device_vccbram <= #U_DLY xadc_do[15:4];
            else;
        end
end

endmodule

