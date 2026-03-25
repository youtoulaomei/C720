// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2015/9/22 13:24:26
// File Name    : cib_counter_64b.v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Zhimingda digital equipment Co., Ltd.. 
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
module cib_counter_32b #(
parameter                           U_DLY        = 1,
parameter                           CYCLE_EN     = "NO",                                 //"YES" : cycle counter ; "NO" : no cycle counter
parameter                           CLEAR_EN     = "YES",                                //"YES" : read clear ; "NO" : read but no clear
parameter                           CLK_ASYNC    = "TRUE",                               //"TRUE" : clk_cpu and clk_src are async; "FALSE" : the same clock
parameter                           CPU_ADDR_W   = 11,
parameter                           COUNTER_ADDR = 11'b0
)
(
input                               rst,
input                               clk_cpu,
input                               clk_src,
//
input                               counter_en,
input           [CPU_ADDR_W - 1:0]  cpu_addr,
input                               cpu_read_en,
output reg      [31:0]              counter_value
);

// Parameter Define 
reg                                 clear_en;
reg             [15:0]              counter_1step;
reg             [15:0]              counter_2step;
reg                                 carry_1step;
// Wire Define 
wire                                clear_ind;

generate 
    if (CLK_ASYNC == "TRUE")
    begin: CLEAR_IND
        reg     [2:0]               clear_en_dly;

        always @(posedge clk_src or posedge rst)
        begin
            if(rst == 1'b1)
                clear_en_dly <= 3'd0;
            else
                clear_en_dly <= #U_DLY {clear_en_dly[1:0],clear_en};
        end

        assign clear_ind = clear_en_dly[2] ^ clear_en_dly[1];
    end
    else
    begin
        reg                         clear_en_dly;
        always @(posedge clk_src or posedge rst)
        begin
            if(rst == 1'b1)
                clear_en_dly <= 1'd0;
            else
                clear_en_dly <= #U_DLY clear_en;
        end

        assign clear_ind = clear_en_dly ^ clear_en;
    end
endgenerate

always @(posedge clk_src or posedge rst)
begin
    if(rst == 1'b1)
        begin
            counter_1step <= 16'd0;
            carry_1step <= 1'b0;
        end
    else
        begin
            case({CYCLE_EN,CLEAR_EN})
                {"YES","YES"}:begin
                    if(clear_ind == 1'b1)
                        begin
                            if(counter_en == 1'b1)
                                counter_1step <= #U_DLY 16'd1;
                            else
                                counter_1step <= #U_DLY 16'd0;
                        end
                    else if(counter_en == 1'b1)
                        counter_1step <= #U_DLY counter_1step + 16'd1;
                    else;end
                {"YES","NO"}:begin
                    if(counter_en == 1'b1)
                        counter_1step <= #U_DLY counter_1step + 16'd1;
                    else;end
                {"NO","YES"}:begin
                    if(clear_ind == 1'b1)
                        begin
                            if(counter_en == 1'b1)
                                counter_1step <= #U_DLY 16'd1;
                            else
                                counter_1step <= #U_DLY 16'd0;
                        end
                    else if(counter_en == 1'b1)
                        begin
                            if(counter_1step != 16'hffff)
                                counter_1step <= #U_DLY counter_1step + 16'd1;
                            else;
                        end
                    else;end
                {"NO","NO"}:begin
                    if(counter_en == 1'b1)
                        begin
                            if(counter_1step != 16'hffff)
                                counter_1step <= #U_DLY counter_1step + 16'd1;
                            else;
                        end
                    else;end
                default:begin                    
                    if(counter_en == 1'b1)
                        begin
                            if(counter_1step != 16'hffff)
                                counter_1step <= #U_DLY counter_1step + 16'd1;
                            else;
                        end
                    else;end
        endcase

        if((counter_1step >= 16'hffff && counter_en == 1'b1)|| (CLEAR_EN == "YES" && clear_ind == 1'b1))
            carry_1step <= #U_DLY 1'b0;
        else if(counter_1step == 16'hfffe && counter_en == 1'b1)
            carry_1step <= #U_DLY 1'b1;
        else;
    end
end    

always @(posedge clk_src or posedge rst)
begin
    if(rst == 1'b1)
        begin
            counter_2step <= 16'd0;
        end
    else
        begin
            case({CYCLE_EN,CLEAR_EN})
                {"YES","YES"}:begin
                    if(clear_ind == 1'b1)
                        begin
                            if({carry_1step,counter_en} == 2'b11)
                                counter_2step <= #U_DLY 16'd1;
                            else
                                counter_2step <= #U_DLY 16'd0;
                        end
                    else if({carry_1step,counter_en} == 2'b11)
                        counter_2step <= #U_DLY counter_2step + 16'd1;
                    else;end
                {"YES","NO"}:begin
                    if({carry_1step,counter_en} == 2'b11)
                        counter_2step <= #U_DLY counter_2step + 16'd1;
                    else;end
                {"NO","YES"}:begin
                    if(clear_ind == 1'b1)
                        begin
                            if({carry_1step,counter_en} == 2'b11)
                                counter_2step <= #U_DLY 16'd1;
                            else
                                counter_2step <= #U_DLY 16'd0;
                        end
                    else if({carry_1step,counter_en} == 2'b11)
                        begin
                            if(counter_2step != 16'hffff)
                                counter_2step <= #U_DLY counter_2step + 16'd1;
                            else;
                        end
                    else;end
                {"NO","NO"}:begin
                    if({carry_1step,counter_en} == 2'b11)
                        begin
                            if(counter_2step != 16'hffff)
                                counter_2step <= #U_DLY counter_2step + 16'd1;
                            else;
                        end
                    else;end
                default:begin                    
                    if({carry_1step,counter_en} == 2'b11)
                        begin
                            if(counter_2step != 16'hffff)
                                counter_2step <= #U_DLY counter_2step + 16'd1;
                            else;
                        end
                    else;end
        endcase
    end
end

always @(posedge clk_cpu or posedge rst)
begin
    if(rst == 1'b1)
        clear_en <= 1'b0;
    else if(cpu_read_en == 1'b1 && cpu_addr == COUNTER_ADDR)
        clear_en <= #U_DLY ~clear_en;
    else;
end
      
//always @(posedge clk_src or posedge rst)
//begin
//    if(rst == 1'b1)
//        counter_value <= 32'd0;
//    else if(clear_ind == 1'b1)
//        counter_value <= #U_DLY {counter_2step,counter_1step};
//    else;
//end  

always @(*)
begin
    counter_value = {counter_2step,counter_1step};
end

endmodule

