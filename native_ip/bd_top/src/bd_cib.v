// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/12/14 10:20:17
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Boyulihua digital equipment Co., Ltd.. 
// All Rights Reserved
//
// *********************************************************************************/
// Modification History:
// 1. initial
// *********************************************************************************/
// *************************
// MODULE DEFINITION
// *************************
//
//
`define BD_03 {spulse_mode}                                         
`define BD_04 {bd_test}                                         
`define BD_05 {fill[31:1],bd_soft_rst}                           
`define BD_06 {fill[31:7],his_zda_overtime,his_gga_overtime,his_rmc_overtime,rmc_utc_vld,zda_utc_vld,gga_vld,pps_vld}                           

`define BD_07 {fill[31:8],send_data}                             
`define BD_08 {fill[31:1],send}                                  
`define BD_09 {fill[31:3],rtc_mode}        
`define BD_0A {fill[31:12],zone_cnt,fill[7:5],west,fill[3:1],east}
`define BD_0B {fill[31:20],tmo_sec}

`define BD_10 {fill[31:17],gga_vld,gga_id}                               
`define BD_11 {fill[31:16],gga_wd_word0}                         
`define BD_12 {fill[31:24],gga_wd_word1}                         
`define BD_13 {fill[31:8],gga_wd_dir}                            
`define BD_14 {fill[31:20],gga_jd_word0}                         
`define BD_15 {fill[31:24],gga_jd_word1}                         
`define BD_16 {fill[31:8],gga_jd_dir}                            
`define BD_17 {fill[31:24],gga_high_word0}                       
`define BD_18 {fill[31:8],gga_high_word1}                        
`define BD_19 {fill[31:8],gga_high_word_minus}                   
`define BD_1A {fill[31:12],gga_state,gga_satellite}              

`define BD_20 {fill[31:17],zda_utc_vld,zda_id}                               
`define BD_21 {4'b0,zda_utc_year,4'b0,zda_utc_mon,3'b0,zda_utc_day}         
`define BD_22 {11'b0,zda_utc_hour,2'b0,zda_utc_min,2'b0,zda_utc_sec} 
`define BD_28 {fill[31:16],zda_time_type,zda_pps_status}


`define BD_30 {fill[31:17],rmc_utc_vld,rmc_id}                    
`define BD_31 {fill[31:16],rmc_wd_word0}                          
`define BD_32 {fill[31:24],rmc_wd_word1}                          
`define BD_33 {fill[31:8],rmc_wd_dir}                             
`define BD_34 {fill[31:20],rmc_jd_word0}                          
`define BD_35 {fill[31:24],rmc_jd_word1}                          
`define BD_36 {fill[31:8],rmc_jd_dir}                             
`define BD_37 {fill[31:8],rmc_position}                           
`define BD_38 {rmc_ghead0,rmc_ghead1,rmc_gspeed0,rmc_gspeed1}            
`define BD_39 {4'b0,rmc_utc_year,4'b0,rmc_utc_mon,3'b0,rmc_utc_day}              
`define BD_3A {11'b0,rmc_utc_hour,2'b0,rmc_utc_min,2'b0,rmc_utc_sec}  

`define BD_40 {fill[31:1],soft_cfg}
`define BD_41 {fill[31:28],soft_utc_year,fill[15:12],soft_utc_mon,fill[7:5],soft_utc_day}              
`define BD_42 {fill[31:21],soft_utc_hour,fill[15:14],soft_utc_min,fill[7:6],soft_utc_sec}  
`define BD_43 {fill[31:10],soft_utc_ms[9:0]}
`define BD_44 {fill[31:10],soft_utc_us[9:0]}
`define BD_45 {fill[31:10],soft_utc_ns[9:0]}

`define BD_51 {4'b0,rtc_year,4'b0,rtc_month,3'b0,rtc_day}              
`define BD_52 {11'b0,rtc_hour,2'b0,rtc_min,2'b0,rtc_sec}  
`define BD_53 {rtc_msec[9:0]}
`define BD_54 {rtc_microsec[9:0]}
`define BD_55 {rtc_nanosec[9:0]}

`define BD_63 {u_ms[9:0]}
`define BD_64 {u_us[9:0]}
`define BD_65 {u_ns[9:0]}


`timescale 1 ns / 1 ns
module bd_cib # (
parameter                           U_DLY = 1
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

output reg                          send,
output reg   [7:0]                  send_data,
input                               send_done,
//
input                               bd_pps,
output  reg     [31:0]              sfh_pulse_cnt,
output  reg     [31:0]              sfh_pulse_freq,
//
output reg                          bd_soft_rst,
//zda
input   [11:0]                      zda_utc_year, 
input   [3:0]                       zda_utc_mon,  
input   [4:0]                       zda_utc_day,  
input   [4:0]                       zda_utc_hour, 
input   [5:0]                       zda_utc_min,  
input   [5:0]                       zda_utc_sec,  
input                               zda_utc_vld,
input   [15:0]                      zda_id,          
input                               zda_pps_overtime,
input    [7:0]                      zda_pps_status,
input    [7:0]                      zda_time_type,


//gga
input [15:0]                        gga_wd_word0,
input [23:0]                        gga_wd_word1,
input [7:0]                         gga_wd_dir,
input [19:0]                        gga_jd_word0,
input [23:0]                        gga_jd_word1,
input [7:0]                         gga_jd_dir,
input [23:0]                        gga_high_word0,
input [7:0]                         gga_high_word1,
input [7:0]                         gga_high_word_minus,
input [15:0]                        gga_id,
input                               gga_pps_overtime,
input [3:0]                         gga_state,
input [7:0]                         gga_satellite,
input                               gga_vld,
//rmc
input [15:0]                        rmc_wd_word0,
input [23:0]                        rmc_wd_word1,
input [7:0]                         rmc_wd_dir,
input [19:0]                        rmc_jd_word0,
input [23:0]                        rmc_jd_word1,
input [7:0]                         rmc_jd_dir,
input [7:0]                         rmc_position,    

input [11:0]                        rmc_utc_year, 
input [3:0]                         rmc_utc_mon,  
input [4:0]                         rmc_utc_day,  
input [4:0]                         rmc_utc_hour, 
input [5:0]                         rmc_utc_min,  
input [5:0]                         rmc_utc_sec,  
input                               rmc_utc_vld,


input [7:0]                         rmc_gspeed0,
input [7:0]                         rmc_gspeed1,
input [7:0]                         rmc_ghead0,
input [7:0]                         rmc_ghead1,
input [15:0]                        rmc_id,
input                               rmc_pps_overtime,

output reg                          soft_cfg,
output reg    [11:0]                soft_utc_year,
output reg    [3:0]                 soft_utc_mon,
output reg    [4:0]                 soft_utc_day,
output reg    [4:0]                 soft_utc_hour,
output reg    [5:0]                 soft_utc_min,
output reg    [5:0]                 soft_utc_sec,
output reg    [9:0]                 soft_utc_ms,
output reg    [9:0]                 soft_utc_us,
output reg    [9:0]                 soft_utc_ns,

output reg    [9:0]                 u_ms,
output reg    [9:0]                 u_us,
output reg    [9:0]                 u_ns,

output reg                          east,
output reg                          west,
output reg     [3:0]                zone_cnt,
output reg     [19:0]               tmo_sec,
output reg     [2:0]                rtc_mode,

input       [11:0]                  rtc_year,
input       [3:0]                   rtc_month,
input       [4:0]                   rtc_day,
input       [4:0]                   rtc_hour,
input       [5:0]                   rtc_min,
input       [5:0]                   rtc_sec,
input       [9:0]                   rtc_msec,
input       [9:0]                   rtc_microsec,
input       [9:0]                   rtc_nanosec

);
// Parameter Define 

// Register Define 
reg                                 cpu_wr_dly;
reg                                 cpu_rd_dly;
reg     [7:0]                       cpu_raddr;
reg     [31:0]                      fill;
reg     [31:0]                      bd_test;
reg     [2:0]                       bd_pps_r;
reg                                 his_zda_overtime;
reg                                 his_gga_overtime;
reg                                 his_rmc_overtime;
reg                                 cpu_rd_det;
reg     [6:0]                       us_cnt;
reg                                 us_flg;
reg     [9:0]                       ms_cnt;
reg                                 ms_flg;
reg     [9:0]                       s_cnt;
reg                                 s_flg;
reg     [19:0]                      tmo_cnt;
reg                                 pps_det;
reg                                 pps_vld;
reg                                 rtc_sec_low_dly;
reg                                 spulse_mode;


// Wire Define 

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
        cpu_rd_det <= #U_DLY 1'b0;
    else if({cpu_rd,cpu_rd_dly} == 2'b10 && cpu_cs == 1'b0)   //read
        cpu_rd_det <= #U_DLY 1'b1;
    else
    	cpu_rd_det <= #U_DLY 1'b0;
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        cpu_rd_data <= #U_DLY 'b0;       
    else   
        case(cpu_raddr)
            8'h03:cpu_rd_data <= #U_DLY `BD_03;
            8'h04:cpu_rd_data <= #U_DLY `BD_04;
            8'h05:cpu_rd_data <= #U_DLY `BD_05; 
            8'h06:cpu_rd_data <= #U_DLY `BD_06; 
            8'h07:cpu_rd_data <= #U_DLY `BD_07; 
            8'h08:cpu_rd_data <= #U_DLY `BD_08; 
            8'h09:cpu_rd_data <= #U_DLY `BD_09;
            8'h0A:cpu_rd_data <= #U_DLY `BD_0A;
            8'h0B:cpu_rd_data <= #U_DLY `BD_0B;
            
            8'h10:cpu_rd_data <= #U_DLY `BD_10;  
            8'h11:cpu_rd_data <= #U_DLY `BD_11; 
            8'h12:cpu_rd_data <= #U_DLY `BD_12; 
            8'h13:cpu_rd_data <= #U_DLY `BD_13; 
            8'h14:cpu_rd_data <= #U_DLY `BD_14; 
            8'h15:cpu_rd_data <= #U_DLY `BD_15; 
            8'h16:cpu_rd_data <= #U_DLY `BD_16; 
            8'h17:cpu_rd_data <= #U_DLY `BD_17; 
            8'h18:cpu_rd_data <= #U_DLY `BD_18; 
            8'h19:cpu_rd_data <= #U_DLY `BD_19; 
            8'h1A:cpu_rd_data <= #U_DLY `BD_1A; 
            
            8'h20:cpu_rd_data <= #U_DLY `BD_20; 
            8'h21:cpu_rd_data <= #U_DLY `BD_21; 
            8'h22:cpu_rd_data <= #U_DLY `BD_22; 
            8'h28:cpu_rd_data <= #U_DLY `BD_28; 

           
            8'h30:cpu_rd_data <= #U_DLY `BD_30; 
            8'h31:cpu_rd_data <= #U_DLY `BD_31; 
            8'h32:cpu_rd_data <= #U_DLY `BD_32; 
            8'h33:cpu_rd_data <= #U_DLY `BD_33; 
            8'h34:cpu_rd_data <= #U_DLY `BD_34; 
            8'h35:cpu_rd_data <= #U_DLY `BD_35; 
            8'h36:cpu_rd_data <= #U_DLY `BD_36; 
            8'h37:cpu_rd_data <= #U_DLY `BD_37; 
            8'h38:cpu_rd_data <= #U_DLY `BD_38; 
            8'h39:cpu_rd_data <= #U_DLY `BD_39; 
            8'h3A:cpu_rd_data <= #U_DLY `BD_3A;

            8'h40:cpu_rd_data <= #U_DLY `BD_40; 
            8'h41:cpu_rd_data <= #U_DLY `BD_41; 
            8'h42:cpu_rd_data <= #U_DLY `BD_42; 
            8'h43:cpu_rd_data <= #U_DLY `BD_43; 
            8'h44:cpu_rd_data <= #U_DLY `BD_44; 
            8'h45:cpu_rd_data <= #U_DLY `BD_45;

            8'h51:cpu_rd_data <= #U_DLY `BD_51; 
            8'h52:cpu_rd_data <= #U_DLY `BD_52; 
            8'h53:cpu_rd_data <= #U_DLY `BD_53; 
            8'h54:cpu_rd_data <= #U_DLY `BD_54; 
            8'h55:cpu_rd_data <= #U_DLY `BD_55;

            8'h63:cpu_rd_data <= #U_DLY `BD_63; 
            8'h64:cpu_rd_data <= #U_DLY `BD_64; 
            8'h65:cpu_rd_data <= #U_DLY `BD_65;

            default:cpu_rd_data <= #U_DLY 'b0;       
        endcase 

end



always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            fill <= #U_DLY 32'd0;
            `BD_03 <= #U_DLY 32'h1;
            `BD_04 <= #U_DLY 32'hdead_beef;
            `BD_05 <= #U_DLY 32'd0;
            `BD_07 <= #U_DLY 32'd0;
            `BD_09 <= #U_DLY 32'd0; //RTC MODE 0-zda 1-rmc 2-soft
            `BD_0A <= #U_DLY 32'h0000_0801;//EAST 8 time zone beijing time 
            `BD_0B <= #U_DLY 32'd60; //60 second disappear
            `BD_40 <= #U_DLY 32'd0;
            `BD_41 <= #U_DLY 32'd0;
            `BD_42 <= #U_DLY 32'd0;
            `BD_43 <= #U_DLY 32'd0;
            `BD_44 <= #U_DLY 32'd0;
            `BD_45 <= #U_DLY 32'd0;
            `BD_63 <= #U_DLY 32'd0;
            `BD_64 <= #U_DLY 32'd0;
            `BD_65 <= #U_DLY 32'd30;
        end        
    else 
        begin   
            if({cpu_wr,cpu_wr_dly} == 2'b01 && cpu_cs == 1'b0)
                begin
                    case(cpu_addr)
                        8'h03:`BD_03 <= #U_DLY cpu_wr_data;
                        8'h04:`BD_04 <= #U_DLY cpu_wr_data;
                        8'h05:`BD_05 <= #U_DLY cpu_wr_data;
                        8'h07:`BD_07 <= #U_DLY cpu_wr_data;
                        8'h09:`BD_09 <= #U_DLY cpu_wr_data;
                        8'h0A:`BD_0A <= #U_DLY cpu_wr_data;
                        8'h0B:`BD_0B <= #U_DLY cpu_wr_data;
                        8'h41:`BD_41 <= #U_DLY cpu_wr_data;
                        8'h42:`BD_42 <= #U_DLY cpu_wr_data;
                        8'h43:`BD_43 <= #U_DLY cpu_wr_data;
                        8'h44:`BD_44 <= #U_DLY cpu_wr_data;
                        8'h45:`BD_45 <= #U_DLY cpu_wr_data;
                        8'h63:`BD_63 <= #U_DLY cpu_wr_data;
                        8'h64:`BD_64 <= #U_DLY cpu_wr_data;
                        8'h65:`BD_65 <= #U_DLY cpu_wr_data;
                        default:;
                    endcase
                end
            else
                fill <= #U_DLY 32'd0;


          if({cpu_wr,cpu_wr_dly} == 2'b01 && cpu_cs == 1'b0 && cpu_addr==8'h40 && cpu_wr_data[0]==1'b1)
              soft_cfg <= #U_DLY 1'b1;
          else
              soft_cfg <= #U_DLY 1'b0;


        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        send <= #U_DLY 1'b0;       
    else if(send_done==1'b1)
        send <= #U_DLY 1'b0;
    else if({cpu_wr,cpu_wr_dly} == 2'b01 && cpu_cs == 1'b0 && cpu_addr==8'h8)
        send <= #U_DLY cpu_wr_data[0];   
end



always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1) 
    	  begin    
            his_zda_overtime <= #U_DLY 1'b0;
            his_gga_overtime <= #U_DLY 1'b0;
            his_rmc_overtime <= #U_DLY 1'b0;
        end
    else
    	  begin
    	  	  if(cpu_rd_det==1'b1 && cpu_raddr==8'h06)
    	  	  	  his_zda_overtime <= #U_DLY zda_pps_overtime;
    	  	  else if(zda_pps_overtime==1'b1)
    	  	      his_zda_overtime <= #U_DLY 1'b1;
    	  	  
    	  	  if(cpu_rd_det==1'b1 && cpu_raddr==8'h06)
    	  	      his_gga_overtime <= #U_DLY gga_pps_overtime;
    	  	  else if(gga_pps_overtime==1'b1)
    	  	   	  his_gga_overtime <= #U_DLY 1'b1; 	   
    	  	   	  
    	  	  if(cpu_rd_det==1'b1 && cpu_raddr==8'h06)
    	  	      his_rmc_overtime <= #U_DLY rmc_pps_overtime;
    	  	  else if(rmc_pps_overtime==1'b1)
    	  	   	  his_rmc_overtime <= #U_DLY 1'b1; 	  	      	  	   	   
    	  end
end

//-------------------------------------------------
// us ms sec
//-------------------------------------------------
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            us_cnt <= #U_DLY 'b0;
            us_flg <= #U_DLY 1'b0;
            ms_cnt <= #U_DLY 'b0;
            ms_flg <= #U_DLY 1'b0;
            s_cnt <= #U_DLY 'b0;
            s_flg <= #U_DLY 1'b0;
        end       
    else  
        begin
            if(us_flg==1'b1)
                us_cnt <= #U_DLY 'd0;
            else 
                us_cnt <= #U_DLY us_cnt + 'b1;

            if(us_cnt=='d98)
                us_flg <= #U_DLY 1'b1;
            else
                us_flg <= #U_DLY 1'b0;

            if(us_flg==1'b1 && ms_cnt=='d999)
                ms_cnt <= #U_DLY 'b0;
            else if(us_flg==1'b1)
                ms_cnt <= #U_DLY ms_cnt + 'b1;

            if(us_flg==1'b1 && ms_cnt=='d999)
                ms_flg <= #U_DLY 1'b1;
            else
                ms_flg <= #U_DLY 1'b0;

            if(ms_flg==1'b1 && s_cnt=='d999)
                s_cnt <= #U_DLY 'd0;
            else if(ms_flg==1'b1)
                s_cnt <= #U_DLY s_cnt + 'b1;

            if(ms_flg==1'b1 && s_cnt=='d999)
                s_flg <= #U_DLY 1'b1;
            else
                s_flg <= #U_DLY 1'b0;

        end  
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            pps_vld <= #U_DLY 1'b0;
            tmo_cnt <= #U_DLY 'd0;
        end       
    else   
        begin
            if(pps_det==1'b1)
                pps_vld <= #U_DLY 1'b1;
            else if(tmo_cnt>=tmo_sec-'d1)
                pps_vld <= #U_DLY 1'b0;

            if(pps_det==1'b1)
                tmo_cnt <= #U_DLY 'b0;
            else if((s_flg==1'b1) && (tmo_cnt>=tmo_sec-'d1))
                tmo_cnt <= #U_DLY tmo_sec;
            else if((s_flg==1'b1) && (tmo_cnt<tmo_sec-'d1))
                tmo_cnt <= #U_DLY tmo_cnt + 'b1;
        end 
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        bd_pps_r <= #U_DLY 'b0;
    else
    	bd_pps_r <= #U_DLY {bd_pps_r[1:0],bd_pps};
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        pps_det <= #U_DLY 1'b0;
    else if(bd_pps_r[1]==1'b1 && bd_pps_r[2]==1'b0)
    	pps_det <= #U_DLY 1'b1;
    else
    	pps_det <= #U_DLY 1'b0;
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            sfh_pulse_cnt <= 'd0;
            sfh_pulse_freq <= 'd0;
            rtc_sec_low_dly <= 1'b0;
        end
    else
        begin

            if((spulse_mode == 1'b1 && bd_pps_r[2:1] == 2'b01) || (spulse_mode == 1'b0 && rtc_sec_low_dly ^ rtc_sec[0] == 1'b1))
                sfh_pulse_cnt <= #U_DLY 'd0;
            else
                sfh_pulse_cnt <= #U_DLY sfh_pulse_cnt + 'd1;

            if((spulse_mode == 1'b1 && bd_pps_r[2:1] == 2'b01) || (spulse_mode == 1'b0 && rtc_sec_low_dly ^ rtc_sec[0] == 1'b1))
                sfh_pulse_freq <= #U_DLY sfh_pulse_cnt;
            else;
        end
end
endmodule
