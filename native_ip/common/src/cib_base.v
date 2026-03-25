// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/11/16 10:15:08
// File Name    : cib_base.v
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
`define BASE_00 {logic_id[63:32]}
`define BASE_01 {logic_id[31:0]}
`define BASE_02 {compile_year,compile_month,compile_day}
`define BASE_03 {compile_hour,compile_min,version}
`define BASE_04 {test_reg}
`define BASE_05 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,soft_rst}
`define BASE_06 {cur_dna_data[31:0]}
`define BASE_07 {cur_dna_data[63:32]}
`define BASE_08 {fill31,fill30,fill29,fill28,cur_device_vccint,fill15,fill14,fill13,fill12,cur_device_temp}
`define BASE_09 {fill31,fill30,fill29,fill28,cur_device_vccbram,fill15,fill14,fill13,fill12,cur_device_vccaux}
`define BASE_0A {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,his_xadc_alm,fill3,fill2,fill1,his_ecc_error}
`define BASE_10 {cur_rsd_0alm}
`define BASE_11 {cur_rsd_1alm}
`define BASE_20 {his_rsd_0alm}
`define BASE_21 {his_rsd_1alm}
`define BASE_30 {reserevd_0cfg}
`define BASE_31 {reserevd_1cfg}
`define BASE_32 {reserevd_2cfg}
`define BASE_33 {reserevd_3cfg}
`define BASE_40 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,cur_Authorize_succ,cur_admin_accredit}
`define BASE_41 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,key_en,key_fetch}
`define BASE_42 {cur_key_refer}
`define BASE_43 {user_key}
`define BASE_44 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,fill1,multiboot_en}
`define BASE_45 {fill31,fill30,fill29,fill28,fill27,fill26,fill25,fill24,fill23,fill22,fill21,fill20,fill19,fill18,fill17,fill16,fill15,fill14,fill13,fill12,fill11,fill10,fill9,fill8,fill7,fill6,fill5,fill4,fill3,fill2,multiboot_sel}
`define BASE_46 {cur_icap_rdata}

`define BASE_70 {int_level}

module cib_base #(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst,

input           [63:0]              logic_id,
input           [15:0]              version,
//
input                               cpu_cs,
input                               cpu_rd,
input                               cpu_we,
input           [7:0]               cpu_addr,
input           [31:0]              cpu_wdata,
output  reg     [31:0]              cpu_rdata,
//
output  reg                         soft_rst,
input           [63:0]              dna_data,   
input                               authorize_succ,
input           [11:0]              device_temp,
input           [11:0]              device_vccint,
input           [11:0]              device_vccaux,
input           [11:0]              device_vccbram,
input                               ecc_error,
input           [3:0]               xadc_alm,
input           [15:0]              compile_year,
input           [7:0]               compile_month,
input           [7:0]               compile_day,
input           [7:0]               compile_hour,
input           [7:0]               compile_min,

input           [31:0]              reserved_cur_0alm,
input           [31:0]              reserved_cur_1alm,
input           [31:0]              reserved_his_0alm,
input           [31:0]              reserved_his_1alm,
output  reg     [31:0]              reserevd_0cfg,
output  reg     [31:0]              reserevd_1cfg,
output  reg     [31:0]              reserevd_2cfg,
output  reg     [31:0]              reserevd_3cfg,
//interrupt
input           [31:0]              int_signal,
output  reg     [31:0]              int_level,

output  reg                         key_fetch,
output  reg                         key_en,
input           [31:0]              key_refer,
output  reg     [31:0]              user_key,
input                               admin_accredit,
output  reg                         multiboot_en,
output  reg     [1:0]               multiboot_sel,
input           [31:0]              icap_rdata
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
wire    [63:0]                      cur_dna_data;
wire    [11:0]                      cur_device_temp;
wire    [11:0]                      cur_device_vccint;
wire    [11:0]                      cur_device_vccaux;
wire    [11:0]                      cur_device_vccbram;
wire                                his_ecc_error;
wire    [3:0]                       his_xadc_alm;
wire    [31:0]                      cur_rsd_0alm;
wire    [31:0]                      cur_rsd_1alm;
wire    [31:0]                      his_rsd_0alm;
wire    [31:0]                      his_rsd_1alm;
wire                                cur_Authorize_succ;
wire                                cur_admin_accredit;
wire    [31:0]                      cur_key_refer;
wire    [31:0]                      cur_icap_rdata;


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
            `BASE_04 <= 32'h0000_0000;
            `BASE_05 <= 32'h0000_0000;
            `BASE_30 <= 32'h0000_0000;
            `BASE_31 <= 32'h0000_0000;            
            `BASE_32 <= 32'h0000_0000;            
            `BASE_33 <= 32'h0000_0000;            
            `BASE_41 <= 32'h0000_0000;            
            `BASE_43 <= 32'h0000_0000;            
            `BASE_44 <= 32'h0000_0000;            
            `BASE_45 <= 32'h0000_0000;            
        end
    else
        begin
            if({cpu_we_dly,cpu_we} == 2'b10 && cpu_cs == 1'b0)
                 begin
                    case(cpu_addr)          
                        8'h04:`BASE_04 <= #U_DLY ~cpu_wdata;             
                        8'h05:`BASE_05 <= #U_DLY cpu_wdata; 
                        8'h30:`BASE_30 <= #U_DLY cpu_wdata; 
                        8'h31:`BASE_31 <= #U_DLY cpu_wdata;
                        8'h32:`BASE_32 <= #U_DLY cpu_wdata;
                        8'h33:`BASE_33 <= #U_DLY cpu_wdata;
                        8'h41:`BASE_41 <= #U_DLY cpu_wdata;
                        8'h43:`BASE_43 <= #U_DLY cpu_wdata;
                        8'h44:`BASE_44 <= #U_DLY cpu_wdata;
                        8'h45:`BASE_45 <= #U_DLY cpu_wdata;
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
                        8'h00:cpu_rdata <= #U_DLY `BASE_00;             
                        8'h01:cpu_rdata <= #U_DLY `BASE_01;             
                        8'h02:cpu_rdata <= #U_DLY `BASE_02;             
                        8'h03:cpu_rdata <= #U_DLY `BASE_03;             
                        8'h04:cpu_rdata <= #U_DLY `BASE_04;    
                        8'h05:cpu_rdata <= #U_DLY `BASE_05;    
                        8'h06:cpu_rdata <= #U_DLY `BASE_06;    
                        8'h07:cpu_rdata <= #U_DLY `BASE_07;    
                        8'h08:cpu_rdata <= #U_DLY `BASE_08;    
                        8'h09:cpu_rdata <= #U_DLY `BASE_09;    
                        8'h0A:cpu_rdata <= #U_DLY `BASE_0A;    
                        8'h10:cpu_rdata <= #U_DLY `BASE_10;    
                        8'h11:cpu_rdata <= #U_DLY `BASE_11;    
                        8'h20:cpu_rdata <= #U_DLY `BASE_20;    
                        8'h21:cpu_rdata <= #U_DLY `BASE_21;    
                        8'h30:cpu_rdata <= #U_DLY `BASE_30;    
                        8'h31:cpu_rdata <= #U_DLY `BASE_31;    
                        8'h32:cpu_rdata <= #U_DLY `BASE_32;    
                        8'h33:cpu_rdata <= #U_DLY `BASE_33;    
                        8'h40:cpu_rdata <= #U_DLY `BASE_40;    
                        8'h41:cpu_rdata <= #U_DLY `BASE_41;    
                        8'h42:cpu_rdata <= #U_DLY `BASE_42;    
                        8'h43:cpu_rdata <= #U_DLY `BASE_43;    
                        8'h44:cpu_rdata <= #U_DLY `BASE_44;    
                        8'h45:cpu_rdata <= #U_DLY `BASE_45;    
                        8'h46:cpu_rdata <= #U_DLY `BASE_46;    
                        8'h70:cpu_rdata <= #U_DLY `BASE_70;    
                        default:cpu_rdata <= #U_DLY 'd0;
                    endcase
                end
            else;
        end
end

assign cpu_read_en = ({cpu_rd_dly,cpu_rd} == 2'b10 && cpu_cs == 1'b0) ? 1'b1 : 1'b0;
//******************************************************************//
//*                        alarm current                           *//  
//******************************************************************//
alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (64                         )
)
u_cur_dna(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (dna_data                   ),
    .alarm_current              (cur_dna_data               )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_cur_Authorize(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (authorize_succ             ),
    .alarm_current              (cur_Authorize_succ         )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (12                         )
)
u_cur_temp(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (device_temp                ),
    .alarm_current              (cur_device_temp            )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (12                         )
)
u_cur_vccint(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (device_vccint              ),
    .alarm_current              (cur_device_vccint          )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (12                         )
)
u_cur_vccaux(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (device_vccaux              ),
    .alarm_current              (cur_device_vccaux          )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (12                         )
)
u_cur_vccbram(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (device_vccbram             ),
    .alarm_current              (cur_device_vccbram         )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (1                          )
)
u_cur_admin_accredit(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (admin_accredit             ),
    .alarm_current              (cur_admin_accredit         )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (32                         )
)
u_cur_key_refer(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (key_refer                  ),
    .alarm_current              (cur_key_refer              )
);

alarm_current #(
    .U_DLY                      (U_DLY                      ),
    .SAME_SOURCE                ("false"                    ),
    .DATA_WIDTH                 (32                         )
)
u_cur_icap_rdata(
    .cpu_clk                    (clk                        ),
    .rst                        (rst                        ),
    .alarm_in                   (icap_rdata                 ),
    .alarm_current              (cur_icap_rdata             )
);
//******************************************************************//
//*                        alarm history                           *//  
//******************************************************************//
alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (8                          ),
    .ALARM_HIS_ADDR             (8'h9                       )
)
u_his_ecc_error(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (ecc_error                  ),
    .alarm_history              (his_ecc_error              )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (8                          ),
    .ALARM_HIS_ADDR             (8'h9                       )
)
u_his_xadc_0alm(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (xadc_alm[0]                ),
    .alarm_history              (his_xadc_alm[0]            )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (8                          ),
    .ALARM_HIS_ADDR             (8'h9                       )
)
u_his_xadc_1alm(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (xadc_alm[1]                ),
    .alarm_history              (his_xadc_alm[1]            )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (8                          ),
    .ALARM_HIS_ADDR             (8'h9                       )
)
u_his_xadc_2alm(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (xadc_alm[2]                ),
    .alarm_history              (his_xadc_alm[2]            )
);

alarm_history #(
    .U_DLY                      (U_DLY                      ),
    .ADDR_WIDTH                 (8                          ),
    .ALARM_HIS_ADDR             (8'h9                       )
)
u_his_xadc_3alm(
    .rst                        (rst                        ),
    .src_clk                    (clk                        ),
    .cpu_clk                    (clk                        ),
    .cpu_read_en                (cpu_read_en                ),
    .cpu_addr                   (cpu_addr                   ),
    .alarm_in                   (xadc_alm[3]                ),
    .alarm_history              (his_xadc_alm[3]            )
);



//******************************************************************//
//*                        reserved process                        *//  
//******************************************************************//
genvar i;
generate 
for(i = 0; i < 32; i = i+1)
begin
    alarm_current #(
        .U_DLY                      (U_DLY                      ),
        .SAME_SOURCE                ("false"                    ),
        .DATA_WIDTH                 (1                          )
    )
    u_reserved_cur_0alm(
        .cpu_clk                    (clk                        ),
        .rst                        (rst                        ),
        //.cpu_read_en                (cpu_read_en                ),
        .alarm_in                   (reserved_cur_0alm[i]       ),
        .alarm_current              (cur_rsd_0alm[i]            )
    );

    alarm_current #(
        .U_DLY                      (U_DLY                      ),
        .SAME_SOURCE                ("false"                    ),
        .DATA_WIDTH                 (1                          )
    )
    u_reserved_cur_1alm(
        .cpu_clk                    (clk                        ),
        .rst                        (rst                        ),
        //.cpu_read_en                (cpu_read_en                ),
        .alarm_in                   (reserved_cur_1alm[i]       ),
        .alarm_current              (cur_rsd_1alm[i]            )
    );

end
endgenerate

genvar j;
generate 
for(j = 0; j < 32; j = j+1)
begin
    alarm_history #(
        .U_DLY                      (U_DLY                      ),
        .ADDR_WIDTH                 (8                          ),
        .ALARM_HIS_ADDR             (8'h20                      )
    )
    u_his_reserved_his_0alm(
        .rst                        (rst                        ),
        .src_clk                    (clk                        ),
        .cpu_clk                    (clk                        ),
        .cpu_read_en                (cpu_read_en                ),
        .cpu_addr                   (cpu_addr                   ),
        .alarm_in                   (reserved_his_0alm[j]       ),
        .alarm_history              (his_rsd_0alm[j]            )
    );

    alarm_history #(
        .U_DLY                      (U_DLY                      ),
        .ADDR_WIDTH                 (8                          ),
        .ALARM_HIS_ADDR             (8'h21                      )
    )
    u_his_reserved_his_1alm(
        .rst                        (rst                        ),
        .src_clk                    (clk                        ),
        .cpu_clk                    (clk                        ),
        .cpu_read_en                (cpu_read_en                ),
        .cpu_addr                   (cpu_addr                   ),
        .alarm_in                   (reserved_his_1alm[j]       ),
        .alarm_history              (his_rsd_1alm[j]            )
    );
end
endgenerate

always @(posedge clk or posedge rst)
begin:interupt_p
    integer i;
    if(rst == 1'b1)
        int_level <= 'd0;
    else
        begin
            for(i=0; i<=31; i=i+1)
                begin
                    if(int_signal[i] == 1'b1)
                        int_level[i] <= #U_DLY 1'b1;
                    else if({cpu_we_dly,cpu_we} == 2'b10 && cpu_cs == 1'b0 && cpu_addr == 8'h70)
                        begin
                            if(int_level[i] == 1'b1 && cpu_wdata[i] == 1'b1)
                                int_level[i] <= #U_DLY 1'b0;
                            else;
                        end
                    else;
                end
        end
end

endmodule

