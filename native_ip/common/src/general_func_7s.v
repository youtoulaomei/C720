// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/12/4 9:46:30
// File Name    : general_func_7s.v
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
module general_func_7s #(
parameter                           U_DLY = 1
)
(
input                               clk,                 //100M clock
input                               rst,
output                              int_pin,

input           [63:0]              logic_id,
input           [15:0]              version,
//timing output
output  reg                         timing_1us,          //turn when time over
output  reg                         timing_1ms,
output  reg                         timing_1s,
//cpu interface
input                               cpu_cs,
input                               cpu_rd,
input                               cpu_we,
input           [7:0]               cpu_addr,
input           [31:0]              cpu_wdata,
output  wire    [31:0]              cpu_rdata,
//others
input                               hard_rst,
output  wire                        soft_rst,
output  wire    [11:0]              device_temp,
output  wire    [31:0]              authorize_code,
input                               icap_pulse,
input           [1:0]               icap_sel,
//reserved
input           [31:0]              int_i,                //rollback when occur

input           [31:0]              reserved_cur_0alm,
input           [31:0]              reserved_cur_1alm,
input           [31:0]              reserved_his_0alm,
input           [31:0]              reserved_his_1alm,
output          [31:0]              reserevd_0cfg,
output          [31:0]              reserevd_1cfg,
output          [31:0]              reserevd_2cfg,
output          [31:0]              reserevd_3cfg             
);
// Parameter Define 
localparam                           AUTHORIZE_OPEN = "OFF";

localparam                          DNA_IDLE = 3'b001;
localparam                          DNA_READ = 3'b010;
localparam                          DNA_SHIFT = 3'b100;
// Register Define 
reg     [6:0]                       cnt_1us;
reg     [9:0]                       cnt_1ms;
reg     [9:0]                       cnt_1s;
reg                                 timing_1ms_dly;
reg     [2:0]                       dna_st/* synthesis syn_encoding="safe,onehot" */;;
reg     [2:0]                       dna_next_st;
reg                                 dna_read;
reg                                 dna_shift;
reg     [5:0]                       dna_shift_cnt;
reg                                 dna_shift_done;
reg     [63:0]                      dna_data;
reg                                 dna_vld;
reg     [31:0]                      int_i_1dly;
reg     [31:0]                      int_i_2dly;
reg     [31:0]                      int_i_3dly;
reg     [31:0]                      int_signal;
reg                                 key_fetch_dly;
reg                                 key_en_dly;
reg     [31:0]                      key_refer;
reg     [31:0]                      key_golden;
reg     [31:0]                      key_check;
reg                                 admin_accredit;
reg                                 multiboot_en_dly;
reg     [1:0]                       icap_multiboot_sel;
reg     [2:0]                       icap_slot_cnt;
reg                                 icap_en;
reg     [31:0]                      icap_data;
// Wire Define 
wire    [15:0]                      compile_year;
wire    [7:0]                       compile_month;
wire    [7:0]                       compile_day;
wire    [7:0]                       compile_hour;
wire    [7:0]                       compile_min;
wire    [11:0]                      device_vccint;
wire    [11:0]                      device_vccaux;
wire    [11:0]                      device_vccbram;
wire    [3:0]                       xadc_alm;
wire    [31:0]                      int_level;
wire    [31:0]                      user_key;
wire    [1:0]                       multiboot_sel;
wire    [31:0]                      icap_rdata;

always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
         begin
             cnt_1us <= 'd0;
             timing_1us <= 1'b0;
         end
    else
        begin
            if(cnt_1us >= 'd99)
                cnt_1us <= #U_DLY 'd0;
            else
                cnt_1us <= #U_DLY cnt_1us + 'd1;

            if(cnt_1us >= 'd99)
                timing_1us <= #U_DLY ~timing_1us;
            else;
        end
end

always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        begin
            cnt_1ms <= 'd0;
            timing_1ms <= 1'b0;
        end
    else
        begin
            if(cnt_1ms >= 'd999)
                begin
                    if(cnt_1us >= 'd99)
                        cnt_1ms <= #U_DLY 'd0;
                    else;
                end
            else
                begin
                    if(cnt_1us >= 'd99)
                        cnt_1ms <= #U_DLY cnt_1ms + 'd1;
                    else;
                end
            
            if(cnt_1ms >= 'd999 && cnt_1us >= 'd99)
                timing_1ms <= #U_DLY ~timing_1ms;
            else;
        end
end
                 
always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        begin
            cnt_1s <= 'd0;
            timing_1s <= 1'b0;
        end
    else
        begin
            if(cnt_1s >= 'd999)
                begin
                    if(cnt_1ms >= 'd999 && cnt_1us >= 'd99)
                        cnt_1s <= #U_DLY 'd0;
                    else;
                end
            else
                begin
                    if(cnt_1ms >= 'd999 && cnt_1us >= 'd99)
                        cnt_1s <= #U_DLY cnt_1s + 'd1;
                    else;
                end

            if(cnt_1s >= 'd999 && cnt_1ms >= 'd999 && cnt_1us >= 'd99)
                timing_1s <= #U_DLY ~timing_1s;
            else;
        end
end
//******************************************************************************//
//                               XADC                                           //
//******************************************************************************//
sys_mon #(
    .U_DLY                      (U_DLY                      )
)
u_sys_mon(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//others
    .timing_1ms                 (timing_1ms                 ),
//output
    .device_temp                (device_temp                ),
    .device_vccint              (device_vccint              ),
    .device_vccaux              (device_vccaux              ),
    .device_vccbram             (device_vccbram             ),
    .xadc_alm                   (xadc_alm                   )
);
//******************************************************************************//
//                               SEU                                            //
//******************************************************************************//
`ifdef SERIES_7
FRAME_ECCE2 #(
    .FARSRC                     ("EFAR"                     ),
    .FRAME_RBT_IN_FILENAME      ("None"                     )
   )
u_FRAME_ECCE2(
    .CRCERROR                   (                           ),
    .ECCERROR                   (ecc_error                  ),
    .ECCERRORSINGLE             (                           ),
    .FAR                        (                           ),
    .SYNBIT                     (                           ),
    .SYNDROME                   (                           ),
    .SYNDROMEVALID              (                           ),
    .SYNWORD                    (                           )
   );
`endif
`ifdef KINTEX_ULTRASCALE
//FRAME_ECCE3 #(
//    .FARSRC                     ("EFAR"                     ),
//    .FRAME_RBT_IN_FILENAME      ("None"                     )
//   )
//u_FRAME_ECCE3(
//    .CRCERROR                   (                           ),
//    .ECCERROR                   (ecc_error                  ),
//    .ECCERRORSINGLE             (                           ),
//    .FAR                        (                           ),
//    .SYNBIT                     (                           ),
//    .SYNDROME                   (                           ),
//    .SYNDROMEVALID              (                           )
//   );
assign ecc_error = 1'b0;
`endif
//******************************************************************************//
//                               FPGA ID                                        //
//******************************************************************************// 
always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        timing_1ms_dly <= 1'b0;
    else
        timing_1ms_dly <= #U_DLY timing_1ms;
end

always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        dna_st <= DNA_IDLE;
    else
        dna_st <= #U_DLY dna_next_st;
end

always @(*)
begin
    case(dna_st)
        DNA_IDLE:begin
            if(timing_1ms_dly ^ timing_1ms == 1'b1)
                dna_next_st = DNA_READ;
            else
                dna_next_st = DNA_IDLE;end
        DNA_READ:dna_next_st = DNA_SHIFT;
        DNA_SHIFT:begin
            if(dna_shift_done == 1'b1)
                dna_next_st = DNA_IDLE;
            else
                dna_next_st = DNA_SHIFT;end
        default:dna_next_st = DNA_IDLE;
    endcase
end

always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        begin
            dna_read <= 1'b0;
            dna_shift <= 1'b0;
        end
    else
        begin
            if(dna_st == DNA_READ)
                dna_read <= #U_DLY 1'b1;
            else
                dna_read <= #U_DLY 1'b0;

            if(dna_shift_done == 1'b1)
                dna_shift <= #U_DLY 1'b0;
            else if(dna_read == 1'b1)
                dna_shift <= #U_DLY 1'b1;
            else;
        end
end

`ifdef SERIES_7
always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        begin
            dna_shift_cnt <= 6'd0;
            dna_shift_done <= 1'b0;
            dna_data <= 64'd0;
            dna_vld <= 1'b0;
        end
    else
        begin
            if(dna_read == 1'b1)
                dna_shift_cnt <= #U_DLY 'd0;
            else if(dna_shift == 1'b1)
                dna_shift_cnt <= #U_DLY dna_shift_cnt + 'd1;
            else;

            if(dna_shift_done == 1'b1)
                dna_shift_done <= #U_DLY 1'b0;
            else if(dna_shift == 1'b1 && dna_shift_cnt == 'd55)   //7 series
                dna_shift_done <= #U_DLY 1'b1;
            else;

            if(dna_read == 1'b1)
                dna_data <= #U_DLY 'd0;
            else if(dna_shift == 1'b1)
                dna_data <= #U_DLY {dna_data[62:0],dna_dout};
            else;

            dna_vld <= #U_DLY dna_shift_done;
        end
end

DNA_PORT #(
    .SIM_DNA_VALUE              (57'd0                      )
          )
u_dna_port(
    .DOUT                       (dna_dout                   ),
    .CLK                        (clk                        ),
    .DIN                        (1'b0                       ),
    .READ                       (dna_read                   ),
    .SHIFT                      (dna_shift                  )
);
`endif

`ifdef KINTEX_ULTRASCALE
always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        begin
            dna_shift_cnt <= 6'd0;
            dna_shift_done <= 1'b0;
            dna_data <= 64'd0;
            dna_vld <= 1'b0;
        end
    else
        begin
            if(dna_read == 1'b1)
                dna_shift_cnt <= #U_DLY 'd0;
            else if(dna_shift == 1'b1)
                dna_shift_cnt <= #U_DLY dna_shift_cnt + 'd1;
            else;

            if(dna_shift_done == 1'b1)
                dna_shift_done <= #U_DLY 1'b0;
            else if(dna_shift == 1'b1 && dna_shift_cnt == 'd63)   //kentex ultrascale
                dna_shift_done <= #U_DLY 1'b1;
            else;

            if(dna_read == 1'b1)
                dna_data <= #U_DLY 'd0;
            else if(dna_shift == 1'b1)
                dna_data <= #U_DLY {dna_data[62:0],dna_dout};
            else;

            dna_vld <= #U_DLY dna_shift_done;
        end
end

DNA_PORTE2 #(
    .SIM_DNA_VALUE              (96'h000000000000000000000000)// Specifies a sample 96-bit DNA value for simulation
)
u_dna_port(
    .DOUT                       (dna_dout                   ),
    .CLK                        (clk                        ),
    .DIN                        (1'b0                       ),
    .READ                       (dna_read                   ),
    .SHIFT                      (dna_shift                  )
   );
`endif
//******************************************************************************//
//                               time stamp                                     //
//******************************************************************************// 
timestamp_7s #(
    .U_DLY                      (U_DLY                      )
)
u_timestamp_7s(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//output
    .year                       (compile_year               ),
    .month                      (compile_month              ),
    .day                        (compile_day                ),
    .hour                       (compile_hour               ),
    .minute                     (compile_min                )
);
//******************************************************************************//
//                               base_cib                                       //
//******************************************************************************// 
cib_base #(
    .U_DLY                      (U_DLY                      )
)
u_cib_base(
    .clk                        (clk                        ),
    .rst                        (hard_rst                   ),

    .logic_id                   (logic_id                   ),
    .version                    (version                    ),
//
    .cpu_cs                     (cpu_cs                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_we                     (cpu_we                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wdata                  (cpu_wdata                  ),
    .cpu_rdata                  (cpu_rdata                  ),
//
    .soft_rst                   (soft_rst_cib               ),
    .dna_data                   (dna_data                   ),
    .authorize_succ             (authorize_succ             ),
    .device_temp                (device_temp                ),
    .device_vccint              (device_vccint              ),
    .device_vccaux              (device_vccaux              ),
    .device_vccbram             (device_vccbram             ),
    .ecc_error                  (ecc_error                  ),
    .xadc_alm                   (xadc_alm                   ),
    .compile_year               (compile_year               ),
    .compile_month              (compile_month              ),
    .compile_day                (compile_day                ),
    .compile_hour               (compile_hour               ),
    .compile_min                (compile_min                ),

    .reserved_cur_0alm          (reserved_cur_0alm          ),
    .reserved_cur_1alm          (reserved_cur_1alm          ),
    .reserved_his_0alm          (reserved_his_0alm          ),
    .reserved_his_1alm          (reserved_his_1alm          ),
    .reserevd_0cfg              (reserevd_0cfg              ),
    .reserevd_1cfg              (reserevd_1cfg              ),
    .reserevd_2cfg              (reserevd_2cfg              ),
    .reserevd_3cfg              (reserevd_3cfg              ),

    .int_signal                 (int_signal                 ),
    .int_level                  (int_level                  ),

    .key_fetch                  (key_fetch                  ),
    .key_en                     (key_en                     ),
    .key_refer                  (key_refer                  ),
    .user_key                   (user_key                   ),
    .admin_accredit             (admin_accredit             ),
    .multiboot_en               (multiboot_en               ),
    .multiboot_sel              (multiboot_sel              ),
    .icap_rdata                 (icap_rdata                 )
);

assign soft_rst = soft_rst_cib;
//******************************************************************************//
//                               DNA authorize                                  //
//******************************************************************************// 
authorize #(
    .U_DLY                      (U_DLY                      )
)
u_authorize(
    .clk                        (clk                        ),
    .rst                        (hard_rst                   ),
//dna
    .dna_data                   (dna_data[56:0]             ),
    .dna_vld                    (dna_vld                    ),

    .key                        (32'h4C_4A_43_44            ),
//authorize success
    .admin_accredit             (1'b1             ),            //admin_accredit
    .authorize_code             (authorize_code             ),
    .authorize_succ             (authorize_succ             )
);
//******************************************************************************//
//                               Interrupt                                      //
//******************************************************************************// 
always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        begin
            int_i_1dly <= 'd0;
            int_i_2dly <= 'd0;
            int_i_3dly <= 'd0;
        end
    else
        begin
            int_i_1dly <= #U_DLY int_i;
            int_i_2dly <= #U_DLY int_i_1dly;
            int_i_3dly <= #U_DLY int_i_2dly;
        end
end

always @(posedge clk or posedge hard_rst)
begin:interrupt_gen
    integer i;
    if(hard_rst == 1'b1)
        begin
            int_signal <= 'd0;
        end
    else
        begin
            for(i=0; i<=31; i=i+1)
                begin
                    if(int_i_3dly[i] ^ int_i_2dly[i] == 1'b1)
                        int_signal[i] <= #U_DLY 1'b1;
                    else
                        int_signal[i] <= #U_DLY 1'b0;
                end
        end
end
     
assign int_pin = |int_level;
//******************************************************************************//
//                               Multiboot                                      //
//******************************************************************************// 
always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        begin
            key_fetch_dly <= 1'b0;
            key_en_dly <= 1'b0;
            key_refer <= 'd0;
            key_golden <= 'ha5a5_5a50;
            key_check <= 'hffff_ffff;
            admin_accredit <= 1'b0;
            multiboot_en_dly <= 1'b0;
        end
    else
        begin
            key_fetch_dly <= #U_DLY key_fetch;
            key_en_dly <= #U_DLY key_en;

            if({key_fetch_dly,key_fetch} == 2'b01)
                key_golden <= #U_DLY authorize_code;
            else;

            if({key_fetch_dly,key_fetch} == 2'b01)
                key_refer <= #U_DLY ~authorize_code;
            else;

            if({key_en_dly,key_en} == 2'b01)
                key_check <= #U_DLY user_key;
            else;

            if(key_golden == key_check)
                admin_accredit <= #U_DLY 1'b1;
            else;

            multiboot_en_dly <= #U_DLY multiboot_en;
        end
end

always @(posedge clk or posedge hard_rst)
begin
    if(hard_rst == 1'b1)
        begin
            icap_multiboot_sel <= 2'd0;
            icap_slot_cnt <= 'd7;
            icap_en <= 1'b1;
            icap_data <= 'd0;
        end
    else
        begin
            if(icap_pulse == 1'b1)
                icap_multiboot_sel <= #U_DLY icap_sel;
            else if({multiboot_en_dly,multiboot_en} == 2'b01 && admin_accredit == 1'b1)
                icap_multiboot_sel <= #U_DLY multiboot_sel;
            else;

            if(icap_pulse == 1'b1 || ({multiboot_en_dly,multiboot_en} == 2'b01 && admin_accredit == 1'b1))
                icap_slot_cnt <= #U_DLY 'd0;
            else if(icap_slot_cnt != 'd7)
                icap_slot_cnt <= #U_DLY icap_slot_cnt + 'd1;
            else;
`ifdef SERIES_7
            if(icap_pulse == 1'b1 || ({multiboot_en_dly,multiboot_en} == 2'b01 && admin_accredit == 1'b1))
                icap_en <= #U_DLY 1'b0;
            else if(icap_slot_cnt == 'd7)
                icap_en <= #U_DLY 1'b1;
            else;
`endif
`ifdef KINTEX_ULTRASCALE
            if((icap_pulse == 1'b1 || ({multiboot_en_dly,multiboot_en} == 2'b01 && admin_accredit == 1'b1)) && ku_availability == 1'b1)
                icap_en <= #U_DLY 1'b0;
            else if(icap_slot_cnt == 'd7)
                icap_en <= #U_DLY 1'b1;
            else;
`endif
            case(icap_slot_cnt)
                 'd0:icap_data <= #U_DLY 'hffff_ffff;
                 'd1:icap_data <= #U_DLY 'haa99_5566;
                 'd2:icap_data <= #U_DLY 'h2000_0000;
                 'd3:icap_data <= #U_DLY 'h3002_0001;
`ifdef SERIES_7
                 'd4:icap_data <= #U_DLY {8'b0,icap_multiboot_sel,22'd0};    //????????????????????????????????????
`endif
`ifdef KINTEX_ULTRASCALE
                 'd4:icap_data <= #U_DLY {7'b0,icap_multiboot_sel,23'd0};    //total 512Mb,each image have 128Mb
`endif
                 'd5:icap_data <= #U_DLY 'h3000_8001;
                 'd6:icap_data <= #U_DLY 'h0000_000f;
                 'd7:icap_data <= #U_DLY 'h2000_0000;
                 default:icap_data <= #U_DLY 'd0;
            endcase;                
        end
end    
`ifdef SERIES_7            
ICAPE2 #(
    .DEVICE_ID                  ('h3651093                  ),// Specifies the pre-programmed Device ID value to be used for simulation purposes
    .ICAP_WIDTH                 ("X32"                      ),// Specifies the input and output data width.
    .SIM_CFG_FILE_NAME          ("None"                     ) //Specifies the Raw Bitstream (RBT) file to be parsed by the simulation model.
   )
ICAPE2_inst(
    .O                          (icap_rdata                 ),// 32-bit output: Configuration data output bus
    .CLK                        (clk                        ),// 1-bit input: Clock Input
    .CSIB                       (icap_en                    ),// 1-bit input: Active-Low ICAP Enable
    .I                          (icap_data                  ),// 32-bit input: Configuration data input bus
    .RDWRB                      (icap_en                    ) // 1-bit input: Read/Write Select input
); 
`endif
`ifdef KINTEX_ULTRASCALE
ICAPE3 #(
    .DEVICE_ID                  (32'h03628093               ),// Specifies the pre-programmed Device ID value to be used for simulation purposes
    .ICAP_AUTO_SWITCH           ("DISABLE"                  ),// Enable switch ICAP using sync word
    .SIM_CFG_FILE_NAME          ("NONE"                     ) // Specifies the Raw Bitstream (RBT) file to be parsed by the simulation model
)
ICAPE3_inst(
    .AVAIL                      (ku_availability            ),// 1-bit output: Availability status of ICAP
    .O                          (icap_rdata                 ),// 32-bit output: Configuration data output bus
    .PRDONE                     (                           ),// 1-bit output: Indicates completion of Partial Reconfiguration
    .PRERROR                    (                           ),// 1-bit output: Indicates Error during Partial Reconfiguration
    .CLK                        (clk                        ),// 1-bit input: Clock input
    .CSIB                       (icap_en                    ),// 1-bit input: Active-Low ICAP enable
    .I                          (icap_data                  ),// 32-bit input: Configuration data input bus
    .RDWRB                      (icap_en                    ) // 1-bit input: Read/Write Select input
);
`endif

endmodule

