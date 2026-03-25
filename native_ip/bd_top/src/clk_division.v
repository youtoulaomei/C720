// Project Name : SBC8280I_U2
// Author       : Liuzhengchun
// Email        : liuzhengchun@zmdde.com
// File Name    : clk_divison.v
// Module Name  : clk_divison
// Called By    :
// Abstract     : customized clock divison, support integer range 4095 downto 0, 50% hign
//
// CopyRight(c) 2012, zhimingda Co., Ltd..
// All Rights Reserved
//
// *********************************************************************************
// Modification History:
// 1. initial 2012-06-20
// *********************************************************************************/
//*************************
// MODULE DEFINITION
// ************************
 `timescale 1 ns / 1 ns
module clk_divison
(
    input                  rst_n          ,   //reset signal//
    input                  clk_i          ,   //pending clock input//
    input     [11:0]       clk_div_para   ,   //set pending detection signal "clock", division parameter//
    output    reg          baud_en            //modified by hunk ()
    //output reg             clk_o              //output clock after division//
);

localparam U_DLY = 1;
reg     [11:0]   clk_cnt       ;              //clk cycle count//
reg     [11:0]   clk_cnt_h     ;              //Hign level count//
reg     [11:0]   clk_cnt_l     ;              //Low  level count//
reg              clk_cnt_odd   ;              //If input div_para odd, for adjustment//
reg              clk_div_a     ;
reg              clk_div_b     ;

reg              clk_o   ;

reg				baud_en_2dly			;



always @(posedge clk_i or negedge rst_n)
begin
    if (rst_n == 1'b0) begin
        clk_o <= 1'b0;
        clk_cnt_odd <= 1'b0;
        clk_cnt_h <= 12'h0;
        clk_cnt_l <= 12'h0;
    end
    else if (clk_div_para == 12'h000)
             clk_o <= 1'b0;
    //else if (clk_div_para == 12'h001)
    //       clk_o <= clk_i;
    else begin
             clk_o       <= clk_div_a || clk_div_b;      //cnt_L > cnt_H, use"|", else "&"//
             clk_cnt_h   <= (clk_div_para >>1);
             clk_cnt_odd <= clk_div_para[0];             //if odd Num., low cnt_l + 1//
             clk_cnt_l   <= clk_cnt_h + clk_cnt_odd;
    end
end

// set clk_div_b half of clk_i cycle delay compared to clk_div_a, then clk_o equal to "clk_div_a | clk_div_b" //
// if set cnt_H bigger than cnt_L, clk_o should be "clk_div_a & clk_div_b"//
always @(posedge clk_i or negedge rst_n)
begin
    if (rst_n == 1'b0) begin
        clk_cnt    <= 12'h0;
        clk_div_a  <= 1'b0;
    end
    else if ((clk_div_a == 1'b1) && (clk_cnt >= clk_cnt_h)) begin
              clk_cnt    <= 12'h1;
              clk_div_a  <= 1'b0;
         end
         else if (clk_cnt >= clk_cnt_l) begin
                  clk_cnt   <= 12'h1;
                  clk_div_a <= 1'b1;
              end
         else
                  clk_cnt <= clk_cnt + 12'h1;
end

always @(negedge clk_i or negedge rst_n)
begin
    if (rst_n == 1'b0) begin
        clk_div_b <= 1'b0;
    end
    else if ((clk_div_a == 1'b1) && (clk_cnt_odd == 1'b1))
              clk_div_b <= 1'b1;
         else
              clk_div_b <= 1'b0;
end




always @(negedge clk_i or negedge rst_n)
begin
    if (rst_n == 1'b0)
        baud_en_2dly <= 1'b0;
    else
        baud_en_2dly <= clk_o;
end

always @(negedge clk_i or negedge rst_n)
begin
    if (rst_n == 1'b0)
        baud_en <= 1'b0;
    else if ((clk_o == 1'b1) && (baud_en_2dly == 1'b0))
    	baud_en <=  1'b1;
    else
       	baud_en <=  1'b0;
end












endmodule
