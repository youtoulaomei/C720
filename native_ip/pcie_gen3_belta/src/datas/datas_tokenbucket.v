// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2015/9/9 10:18:19
// File Name    : .v
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
module datas_tokenbucket#(
parameter                           U_DLY          = 1,
parameter                           DATA_W         = 512,
parameter                           TBUCKET_DEEPTH = 22'd1500
)
(
input                               clk,
input                               rst_n,
input                               rtc_us_flg,
input [21:0]                        ds_tbucket_deepth,
input [21:0]                        ds_tbucket_width,
input                               send_vld,
//input [DATA_W/8-1:0]                send_bkeep,
output reg                          tbucket_ready
//output [3:0]                        tbucket_lcnt

);
// Parameter Define 

// Register Define 
reg     [21:0]                      ds_tbucket_deepth_r1;
reg     [21:0]                      ds_tbucket_deepth_r2;
reg     [21:0]                      ds_tbucket_width_r1;
reg     [21:0]                      ds_tbucket_width_r2;
//reg     [9:0]                       us_cnt;
reg                                 us_flag;
//reg     [9:0]                       ms_cnt; 
//reg                                 ms_flag;
reg     [22:0]                      token_sum;  
//reg     [4:0]                       send_byte;  
reg                                 send_vld_r;  
reg     [2:0]                       rtc_us_flg_r;

// Wire Define 
//wire    [9:0]                       us_cnt_x;
//wire    [9:0]                       ms_cnt_x;


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            ds_tbucket_deepth_r1 <= #U_DLY 'd0;
            ds_tbucket_deepth_r2 <= #U_DLY 'd0;
            ds_tbucket_width_r1  <= #U_DLY 'd0;
            ds_tbucket_width_r2  <= #U_DLY 'd0;
        end       
    else    
        begin
            ds_tbucket_deepth_r1 <= #U_DLY ds_tbucket_deepth;
            ds_tbucket_deepth_r2 <= #U_DLY ds_tbucket_deepth_r1;
            ds_tbucket_width_r1  <= #U_DLY ds_tbucket_width;
            ds_tbucket_width_r2  <= #U_DLY ds_tbucket_width_r1;
        end
end

 //assign us_cnt_x = (us_flag == 1'b1 ) ?  10'd0 : us_cnt + 10'd1;
                     
 always @( posedge clk or negedge rst_n )
   begin
    if( rst_n == 1'b0 )
      us_flag <= #U_DLY 1'b0;
    //else if( us_cnt_x == US_CNT - 1 )
    else if(rtc_us_flg_r[1] ^ rtc_us_flg_r[2])
      us_flag <= #U_DLY 1'b1;
    else
      us_flag <= #U_DLY 1'b0;
   end
 always @( posedge clk or negedge rst_n )
   begin
    if( rst_n == 1'b0 )
      rtc_us_flg_r <= #U_DLY 'b0;
    else 
      rtc_us_flg_r <= #U_DLY {rtc_us_flg_r[1:0],rtc_us_flg};
   end
   

// assign ms_cnt_x = (ms_flag == 1'b1 ) ? 10'd0 :
//                   (us_flag == 1'b1 ) ? ms_cnt + 10'd1 : ms_cnt;
                   
                   
// always @( posedge clk or negedge rst_n )  
//   begin
//    if( rst_n == 1'b0 )
//      ms_flag <= #U_DLY 1'b0;
//    else if( ms_cnt_x == 10'd1000 && ms_cnt != 10'd1000 )
//      ms_flag <= #U_DLY 1'b1;
//    else
//      ms_flag <= #U_DLY 1'b0;
//   end
   
// always @( posedge clk or negedge rst_n )
//   begin
//    if( rst_n == 1'b0 )
//      begin
//        us_cnt <= #U_DLY 10'd0;
//        ms_cnt <= #U_DLY 10'd0;
//      end
//     else
//      begin
//        us_cnt <= #U_DLY us_cnt_x;
//        ms_cnt <= #U_DLY ms_cnt_x;
//      end       
//    end  

always @( posedge clk or negedge rst_n )
    begin
      if( rst_n == 1'b0 ) 
        token_sum <= #U_DLY 23'b0;//{1'b0,TBUCKET_DEEPTH}; 
      else if( us_flag == 1'b1 )
        begin
          if( send_vld_r == 1'b1 )
            begin
                if( ((token_sum + ds_tbucket_width_r2) - {16'd0,7'd64}) >= {1'b0,ds_tbucket_deepth_r2} )
                token_sum <= #U_DLY {1'b0,ds_tbucket_deepth_r2};
              else
                token_sum <= #U_DLY ((token_sum + ds_tbucket_width_r2) - {16'd0,7'd64});
            end
          else
            begin
              if( (token_sum + ds_tbucket_width_r2) >=  {1'b0,ds_tbucket_deepth_r2} )
                token_sum <= #U_DLY {1'b0,ds_tbucket_deepth_r2};
              else 
                token_sum <= #U_DLY (token_sum + ds_tbucket_width_r2);
            end
        end
      else if( send_vld_r == 1'b1 )
          token_sum <= #U_DLY token_sum - {16'd0,7'd64};
    end
    
always @( posedge clk or negedge rst_n )  
  begin
     if(rst_n == 1'b0)
         send_vld_r <= #U_DLY 1'b0;
     else
         send_vld_r <= #U_DLY send_vld;
  end    
  
//always @( posedge clk or negedge rst_n )  
//  begin
//     if(rst_n == 1'b0)
//         send_byte <= #U_DLY 5'b0;
//     else
//         case(send_bkeep)
//               16'b0000_0000_0000_0001:send_byte <= #U_DLY 5'd1;
//               16'b0000_0000_0000_0011:send_byte <= #U_DLY 5'd2;
//               16'b0000_0000_0000_0111:send_byte <= #U_DLY 5'd3;
//               16'b0000_0000_0000_1111:send_byte <= #U_DLY 5'd4;
//               16'b0000_0000_0001_1111:send_byte <= #U_DLY 5'd5;
//               16'b0000_0000_0011_1111:send_byte <= #U_DLY 5'd6;
//               16'b0000_0000_0111_1111:send_byte <= #U_DLY 5'd7;
//               16'b0000_0000_1111_1111:send_byte <= #U_DLY 5'd8;
//               16'b0000_0001_1111_1111:send_byte <= #U_DLY 5'd9;
//               16'b0000_0011_1111_1111:send_byte <= #U_DLY 5'd10;
//               16'b0000_0111_1111_1111:send_byte <= #U_DLY 5'd11;
//               16'b0000_1111_1111_1111:send_byte <= #U_DLY 5'd12;
//               16'b0001_1111_1111_1111:send_byte <= #U_DLY 5'd13;
//               16'b0011_1111_1111_1111:send_byte <= #U_DLY 5'd14;
//               16'b0111_1111_1111_1111:send_byte <= #U_DLY 5'd15;
//               16'b1111_1111_1111_1111:send_byte <= #U_DLY 5'd16;      
//             default:send_byte <= #U_DLY 5'd0;
//         endcase
//  end     
    

always @( posedge clk or negedge rst_n )  
  begin
     if(rst_n == 1'b0)
         tbucket_ready <= #U_DLY 1'b0;
     else if(token_sum[22:8] >= 15'd1)
         tbucket_ready <= #U_DLY 1'b1;
     else
        tbucket_ready <= #U_DLY 1'b0;
      
   end
                       
//assign tbucket_lcnt  = token_sum[3:0];

endmodule