// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/12/14 9:53:46
// File Name    : bd_nema_zda.v
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
`timescale 1 ns / 1 ns
module bd_nema_zda # (
parameter                           U_DLY = 1,
parameter                           US_CNT = 8'd100 //1000ns = US_CNT*10ns (100MHZ)      
)
(
input                               clk,
input                               rst,
//
input                               east,
input                               west,
input  [3:0]                        zone_cnt,
input  [19:0]                       tmo_sec,
input                               rx_vld,
input [7:0]                         rx_data,
//
output [11:0]                       zda_utc_year,
output [3:0]                        zda_utc_mon,
output [4:0]                        zda_utc_day,
output [4:0]                        zda_utc_hour,
output [5:0]                        zda_utc_min,
output [5:0]                        zda_utc_sec,
output reg                          zda_utc_vld,
output reg                          zda_utc_chok,

output reg [15:0]                   zda_id,  
output reg                          zda_pps_overtime,

output reg [7:0]                    zda_time_type,
output reg [7:0]                    zda_pps_status

);
// Parameter Define 
localparam                          IDLE  = 2'd0;
localparam                          SAMP  = 2'd1;
localparam                          COMMA = 2'd2;
localparam                          END   = 2'd3;
// Register Define 
//(* syn_keep = "true", mark_debug = "true" *)reg     [1:0]                       state;
reg     [1:0]                       state;
reg     [1:0]                       nextstate;
reg     [2:0]                       gngga_cnt;
reg     [3:0]                       samp_cnt;
reg                                 load;
reg     [1:0]                       load_r;
reg     [31:0]                      zda_utc_time_r;
reg     [7:0]                       zda_dd_r;
reg     [7:0]                       zda_mm_r;
reg     [15:0]                      zda_yy_r;
reg     [1:0]                       bd_pps_cnt;
reg                                 day_add_flg;
reg                                 day_sub_flg;
reg     [3:0]                       utc_time_cnt;

reg     [15:0]                      id_r; 
reg     [4:0]                       hour_dec;
reg     [5:0]                       min_dec;
reg     [5:0]                       sec_dec;
reg     [7:0]                       year_dec;
reg     [7:0]                       mm_dec;
reg     [4:0]                       dd_dec;
reg     [4:0]                       hour_dec_pro;
reg     [4:0]                       dd_dec_pro;
reg     [3:0]                       mm_dec_pro;
reg     [7:0]                       year_dec_pro;
reg     [6:0]                       us_cnt;
reg                                 us_flg;
reg     [9:0]                       ms_cnt;
reg                                 ms_flg;
reg     [9:0]                       s_cnt;
reg                                 s_flg;
reg     [19:0]                      tmo_cnt;
// Wire Define 
wire    [6:0]                       gngga;
wire                                rx_comma;
wire                                rx_point;
wire    [7:0]                       hour;
wire    [7:0]                       min; 
wire    [7:0]                       sec; 
wire    [7:0]                       year;
wire    [7:0]                       mm;  
wire    [7:0]                       dd;  
wire    [3:0]                       mm_dec_x;

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        state <= #U_DLY IDLE;        
    else if(zda_pps_overtime==1'b1)
        state <= #U_DLY IDLE;        
    else    
        state <= #U_DLY nextstate;
end

always @ (*)begin
    case(state)
        IDLE:begin
            if(gngga_cnt=='d6 && gngga[6]==1'b1)
                nextstate=SAMP;
            else
                nextstate=IDLE;
        end

        SAMP:begin
            if(rx_vld==1'b1 && rx_data==8'h2c)//,
                nextstate=COMMA;
            else if(rx_vld==1'b1 && rx_data==8'h2a)//*
                nextstate=END;
            else
                nextstate=SAMP;
        end

        COMMA:begin
            nextstate=SAMP;
        end        

        END:begin
            nextstate=IDLE;
        end

        default:nextstate=IDLE;
    endcase
end

//assign gngga[1] = (rx_vld==1'b1 && rx_data==8'h47) ? 1'b1:1'b0; //G
//assign gngga[2] = (rx_vld==1'b1 && rx_data==8'h4E) ? 1'b1:1'b0; //N
assign gngga[0] = (rx_vld==1'b1 && rx_data==8'h24) ? 1'b1:1'b0; //$
assign gngga[1] = (rx_vld==1'b1) ? 1'b1:1'b0; //G
assign gngga[2] = (rx_vld==1'b1) ? 1'b1:1'b0; //N
assign gngga[3] = (rx_vld==1'b1 && rx_data==8'h5A) ? 1'b1:1'b0; //Z
assign gngga[4] = (rx_vld==1'b1 && rx_data==8'h44) ? 1'b1:1'b0; //D
assign gngga[5] = (rx_vld==1'b1 && rx_data==8'h41) ? 1'b1:1'b0; //A
assign gngga[6] = (rx_vld==1'b1 && rx_data==8'h2c) ? 1'b1:1'b0; //;

assign rx_comma =  (rx_vld==1'b1 && rx_data==8'h2c) ? 1'b1 : 1'b0;
assign rx_point =  (rx_vld==1'b1 && rx_data==8'h2e) ? 1'b1 : 1'b0;


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gngga_cnt <= #U_DLY 'b0;  
    else if(state==IDLE && nextstate!=IDLE)
    	  gngga_cnt <= #U_DLY 'b0; 
    else if(((gngga_cnt=='d0 && rx_vld==1'b1 && rx_data!=8'h24)//$
//    	   ||  (gngga_cnt=='d1 && rx_vld==1'b1 && rx_data!=8'h47)//G
//    	   ||  (gngga_cnt=='d2 && rx_vld==1'b1 && rx_data!=8'h4E)//N
    	   ||  (gngga_cnt=='d3 && rx_vld==1'b1 && rx_data!=8'h5A)//Z
    	   ||  (gngga_cnt=='d4 && rx_vld==1'b1 && rx_data!=8'h44)//D
    	   ||  (gngga_cnt=='d5 && rx_vld==1'b1 && rx_data!=8'h41)//A
    	   ||  (gngga_cnt=='d6 && rx_vld==1'b1 && rx_data!=8'h2c)) && (state==IDLE))//;
    	  gngga_cnt <= #U_DLY 'b0;    	          
    else if(((gngga_cnt=='d0 && gngga[0]==1'b1)
    	   ||  (gngga_cnt=='d1 && gngga[1]==1'b1)
         ||  (gngga_cnt=='d2 && gngga[2]==1'b1)
         ||  (gngga_cnt=='d3 && gngga[3]==1'b1)
         ||  (gngga_cnt=='d4 && gngga[4]==1'b1)
         ||  (gngga_cnt=='d5 && gngga[5]==1'b1)
         ||  (gngga_cnt=='d6 && gngga[6]==1'b1)) && (state==IDLE))
        gngga_cnt <= #U_DLY gngga_cnt + 'b1;
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        id_r <= #U_DLY 'b0; 
    else if(gngga_cnt=='d1 && rx_vld==1'b1)
    	id_r[15:8] <= #U_DLY rx_data;
    else if(gngga_cnt=='d2 && rx_vld==1'b1) 
    	id_r[7:0]  <= #U_DLY rx_data;
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        zda_id <= #U_DLY 'b0; 
    else if(load==1'b1)
    	zda_id <= #U_DLY id_r;
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        bd_pps_cnt <= #U_DLY 'b0; 
    else if(state==SAMP && nextstate!=SAMP)
    	bd_pps_cnt <= #U_DLY 'b0; 
    else if(state==SAMP && s_flg==1'b1)
    	bd_pps_cnt <= #U_DLY bd_pps_cnt + 'b1;
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        zda_pps_overtime <= #U_DLY 1'b0; 
    else if(state==SAMP && bd_pps_cnt=='d3)
    	zda_pps_overtime <= #U_DLY 1'b1; 
    else 
    	zda_pps_overtime <= #U_DLY 1'b0; 
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        samp_cnt <= #U_DLY 'b0;        
    else if(state==IDLE)
        samp_cnt <= #U_DLY 'b0;
    else if(state==SAMP && nextstate!=SAMP)
        samp_cnt <= #U_DLY samp_cnt + 'b1;   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
    	  begin
            load <= #U_DLY 1'b0;
            load_r <= #U_DLY 'b0; 
        end      
    else
    	  begin 
    	      if(state==END)
                load <= #U_DLY 1'b1;
            else
                load <= #U_DLY 1'b0;
                
            load_r <= #U_DLY {load_r[0],load};   
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        zda_utc_time_r <= #U_DLY 'b0;       
    else if(state==SAMP && samp_cnt=='d0) 
        begin
            if(rx_vld==1'b1 && rx_data!=8'h2e && rx_data!=8'h2c && utc_time_cnt<4'd8 )
                zda_utc_time_r <= #U_DLY {zda_utc_time_r[27:0],rx_data[3:0]};
        end  
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        utc_time_cnt <= #U_DLY 'b0;      
    else if(state==SAMP && nextstate!=SAMP)
    	utc_time_cnt <= #U_DLY 'b0;    
    else if(state==SAMP && samp_cnt=='d0 && rx_vld==1'b1 && rx_data!=8'h2e && rx_data!=8'h2c) 
        utc_time_cnt <= #U_DLY utc_time_cnt + 'd1;
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        zda_dd_r <= #U_DLY 'b0;       
    else if(state==SAMP && samp_cnt=='d1)
        begin
            if(rx_vld==1'b1 && rx_data!=8'h2c)
            zda_dd_r <= #U_DLY {zda_dd_r[3:0],rx_data[3:0]};
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        zda_mm_r <= #U_DLY 'b0;       
    else if(state==SAMP && samp_cnt=='d2)
        begin
            if(rx_vld==1'b1 && rx_data!=8'h2c)
            zda_mm_r <= #U_DLY {zda_mm_r[3:0],rx_data[3:0]};
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        zda_yy_r <= #U_DLY 'b0;       
    else if(state==SAMP && samp_cnt=='d3)
        begin
            if(rx_vld==1'b1 && rx_data!=8'h2c)
            zda_yy_r <= #U_DLY {zda_yy_r[11:0],rx_data[3:0]};
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        zda_time_type <= #U_DLY 'b0;       
    else if(state==SAMP && samp_cnt=='d4)
        begin
            if(rx_vld==1'b1 && rx_data!=8'h2c)
                zda_time_type <= #U_DLY {rx_data[7:0]};
        end
end
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        zda_pps_status <= #U_DLY 'b0;       
    else if(state==SAMP && samp_cnt=='d5)
        begin
            if(rx_vld==1'b1 && (rx_data!=8'h2c && rx_data!=8'h2a) )
                zda_pps_status <= #U_DLY {rx_data[7:0]};
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        zda_utc_chok <= #U_DLY 1'b0;       
    else if(zda_pps_status==8'h41 && zda_time_type!=8'h0)
        zda_utc_chok <= #U_DLY 1'b1;
    else
        zda_utc_chok <= #U_DLY 1'b0;
end


//--------------------------------------------------------------------
// UTC LOGIC
//--------------------------------------------------------------------

assign hour = zda_utc_time_r[31:24];
assign min  = zda_utc_time_r[23:16];
assign sec  = zda_utc_time_r[15:8];
assign year = zda_yy_r[7:0]; 
assign mm   = zda_mm_r[7:0];
assign dd   = zda_dd_r[7:0];


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            hour_dec <= #U_DLY 'b0;
            min_dec  <= #U_DLY 'b0;
            sec_dec  <= #U_DLY 'b0;
            year_dec <= #U_DLY 'b0;
            mm_dec   <= #U_DLY 'b0;
            dd_dec   <= #U_DLY 'b0;  
            day_add_flg <= #U_DLY 1'b0;
            day_sub_flg <= #U_DLY 1'b0;
        end
    else if(load==1'b1)   
    	  begin
            if(east==1'b1) 
                 begin 
                     if((hour[7:4]*10 + hour[3:0] + zone_cnt) >='d24 )
                         begin
                             hour_dec <= #U_DLY hour[7:4]*10 + hour[3:0] + zone_cnt - 'd24;
                             day_add_flg <= #U_DLY 1'b1;
                         end
                     else
                         begin
                             hour_dec <= #U_DLY hour[7:4]*10 + hour[3:0] + zone_cnt;
                             day_add_flg <= #U_DLY 1'b0;
                         end 
                 end
            else if(west==1'b1)
                 begin
                     if((hour[7:4]*10 + hour[3:0])< zone_cnt )
                         begin
                             hour_dec <= #U_DLY 'd24 + zone_cnt- hour[7:4]*10 - hour[3:0];
                             day_sub_flg <= #U_DLY 1'b1;
                         end
                     else
                         begin
                             hour_dec <= #U_DLY hour[7:4]*10 + hour[3:0] - zone_cnt;
                             day_sub_flg <= #U_DLY 1'b0;
                         end
                 end
            else
                begin
                    hour_dec <= #U_DLY hour[7:4]*10 + hour[3:0];
                    day_add_flg <= #U_DLY 1'b0;
                    day_sub_flg <= #U_DLY 1'b0;
                end
                        
            min_dec  <= #U_DLY min[7:4]*10 + min[3:0];         
            sec_dec  <= #U_DLY sec[7:4]*10 + sec[3:0];         
            year_dec <= #U_DLY year[7:4]*10 + year[3:0];       
            mm_dec   <= #U_DLY mm[7:4]*10 + mm[3:0];           
            dd_dec   <= #U_DLY dd[7:4]*10 + dd[3:0];               	 	
    	  end
end

assign mm_dec_x[3:0]  = mm_dec[3:0];
//-------------------------------------------------
// 
//-------------------------------------------------
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
    	  begin
    	      hour_dec_pro <= #U_DLY 'b0;
    	      dd_dec_pro   <= #U_DLY 'b0; 
    	      mm_dec_pro   <= #U_DLY 'b0;  
    	      year_dec_pro <= #U_DLY 'b0;  
    	  end
    else
    	  begin 
              //hour
    	      if(load_r[0]==1'b1)
    	      	  hour_dec_pro <= #U_DLY hour_dec;
    	      //day 
    	      if(load_r[0]==1'b1 && day_add_flg==1'b1)
    	      	  begin
    	      		    case(mm_dec_x)
    	      		    	 'd1,'d3,'d5,'d7,'d8,'d10,'d12:begin
    	      		    	 	  if(dd_dec>='d31)
    	      		    	 	  	  dd_dec_pro <= #U_DLY 'd1;
    	      		    	 	  else
    	      		    	 	  	  dd_dec_pro <= #U_DLY dd_dec + 'd1;
    	      		    	    end
    	      		    	 	  	  
    	      		    	 'd4,'d6,'d9,'d11:begin
     	      		    	 	  if(dd_dec>='d30)
    	      		    	 	  	  dd_dec_pro<= #U_DLY 'd1;
    	      		    	 	  else
    	      		    	 	  	  dd_dec_pro<= #U_DLY dd_dec + 'd1;   	      		  		
    	      		    	    end
    	      		    	 
    	      		    	 'd2:begin
    	      		    	 	  if((year_dec[1:0] == 2'b00 && dd_dec>='d28)
    	      		    		   ||(year_dec[1:0] != 2'b00 && dd_dec>='d29))
    	      		    		  	  dd_dec_pro <= #U_DLY 'd1;
    	      		    		  else
    	      		    		  	  dd_dec_pro <= #U_DLY dd_dec + 'd1 ;
    	      		    	    end 	 
    	      		        default:dd_dec_pro <= #U_DLY dd_dec;
    	      		    endcase
    	      		end
    	      else if(load_r[0]==1'b1 && day_sub_flg==1'b1)
    	      	  begin
    	      		    case(mm_dec_x)
    	      		    	'd1,'d2,'d4,'d6,'d8,'d9,'d11:begin
    	      		    	 	  if(dd_dec=='d1)
    	      		    	 	  	  dd_dec_pro <= #U_DLY 'd31;
    	      		    	 	  else
    	      		    	 	  	  dd_dec_pro <= #U_DLY dd_dec - 'd1;
    	      		    	    end
    	      		    	 	  	  
    	      		    	 'd5,'d7,'d10,'d12:begin
     	      		    	 	  if(dd_dec=='d1)
    	      		    	 	  	  dd_dec_pro<= #U_DLY 'd30;
    	      		    	 	  else
    	      		    	 	  	  dd_dec_pro<= #U_DLY dd_dec - 'd1;   	      		  		
    	      		    	    end
    	      		    	 
    	      		    	 'd3:begin
    	      		    	 	  if(year_dec[1:0] == 2'b00 && dd_dec=='d1)
                                      dd_dec_pro <= #U_DLY 'd28;
    	      		    		  else if(year_dec[1:0] != 2'b00 && dd_dec=='d1)
    	      		    		  	  dd_dec_pro <= #U_DLY 'd29;
    	      		    		  else
    	      		    		  	  dd_dec_pro <= #U_DLY dd_dec - 'd1 ;
    	      		    	    end 	 
    	      		        default:dd_dec_pro <= #U_DLY dd_dec;
    	      		    endcase
    	      		end
    	      else
    	          dd_dec_pro <= #U_DLY dd_dec;

    	      //month	 	
    	      if(load_r[0]==1'b1 && day_add_flg==1'b1)
    	      	  begin
    	      		    case(mm_dec_x)
    	      		    	 'd1,'d3,'d5,'d7,'d8,'d10:begin
    	      		    	 	  if(dd_dec>='d31)
    	      		    	 	  	  mm_dec_pro <= #U_DLY mm_dec_x + 'b1;
    	      		    	 	  else
    	      		    	 	  	  mm_dec_pro <= #U_DLY mm_dec_x;
    	      		    	    end

                             'd4,'d6,'d9,'d11:begin
    	      		    	 	  if(dd_dec>='d30)
    	      		    	 	  	  mm_dec_pro <= #U_DLY mm_dec_x + 'b1;
    	      		    	 	  else
    	      		    	 	  	  mm_dec_pro <= #U_DLY mm_dec_x;
    	      		    	    end

    	      		    	 	  	  
    	      		    	 'd12:begin
     	      		    	 	  if(dd_dec>='d31)
    	      		    	 	  	  mm_dec_pro<= #U_DLY 'd1;
    	      		    	 	  else
    	      		    	 	  	  mm_dec_pro<= #U_DLY mm_dec_x;   	      		  		
    	      		    	    end
    	      		    	 
    	      		    	 'd2:begin
    	      		    	 	  if((year_dec[1:0] == 2'b00 && dd_dec>='d28)
    	      		    		   ||(year_dec[1:0] != 2'b00 && dd_dec>='d29))
    	      		    		  	  mm_dec_pro <= #U_DLY 'd3;
    	      		    		  else
    	      		    		  	  mm_dec_pro <= #U_DLY mm_dec_x;
    	      		    	    end 	 
    	      		        default:mm_dec_pro <= #U_DLY mm_dec_x;
    	      		    endcase
    	      		end
    	      else if(load_r[0]==1'b1 && day_sub_flg==1'b1)
    	      	  begin
    	      		    case(mm_dec_x)
    	      		    	    'd1:begin
    	      		    	 	        if(dd_dec=='d1)
    	      		    	 	  	        mm_dec_pro <= #U_DLY 'd12;
    	      		    	 	        else
    	      		    	 	  	        mm_dec_pro <= #U_DLY mm_dec_x;
    	      		    	        end
    	      		    	 	  	  
    	      		    	    'd2,'d3,'d4,'d5,'d6,'d7,'d8,'d9,'d10,'d11,'d12:begin
     	      		    	 	    if(dd_dec=='d1)
    	      		    	 	  	    mm_dec_pro<= #U_DLY mm_dec_x - 'd1;
    	      		    	 	    else
    	      		    	 	  	    mm_dec_pro<= #U_DLY mm_dec_x;   	      		  		
    	      		    	    end
    	      		    	 
    	      		        default:mm_dec_pro <= #U_DLY mm_dec_x;
    	      		    endcase
    	      		end
    	      else
    	          mm_dec_pro <= #U_DLY mm_dec_x;   

              //year              
	          if(load_r[0]==1'b1 && day_add_flg==1'b1)
                  begin    
                      case(mm_dec_x)
                        'd12:begin
   	      	  	  	         if(dd_dec>='d31) 
    	      	  	  	         year_dec_pro <= #U_DLY year_dec + 1'b1;
    	      	  	  	     else
    	      	  	  	         year_dec_pro <= #U_DLY year_dec;                        	
                         end

                         default: year_dec_pro<= #U_DLY year_dec;   
                      endcase
                  end
    	      else if(load_r[0]==1'b1 && day_sub_flg==1'b1)
                  begin
                      case(mm_dec_x)
                        'd1:begin
   	      	  	  	         if(dd_dec=='d1) 
    	      	  	  	         year_dec_pro <= #U_DLY year_dec - 1'b1;
    	      	  	  	     else
    	      	  	  	         year_dec_pro <= #U_DLY year_dec;                        	
                         end
                         default: year_dec_pro<= #U_DLY year_dec;  
                      endcase
                  end
              else
    	      	  year_dec_pro<= #U_DLY year_dec;    	                    
    	      	     	 	  
    	  end    
end
//-------------------------------------------------
// UTC output
//-------------------------------------------------

assign zda_utc_year[11:0] = year_dec_pro + 'd2000;
assign zda_utc_mon[3:0]   = mm_dec_pro[3:0];
assign zda_utc_day[4:0]   = dd_dec_pro[4:0];
assign zda_utc_hour[4:0]  = hour_dec_pro[4:0];
assign zda_utc_min[5:0]   = min_dec[5:0];
assign zda_utc_sec[5:0]   = sec_dec[5:0];

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
            zda_utc_vld <= #U_DLY 1'b0;
            tmo_cnt <= #U_DLY 'd0;
        end       
    else   
        begin
            if(load_r[1]==1'b1)
                zda_utc_vld <= #U_DLY 1'b1;
            else if(tmo_cnt>=tmo_sec-'d1)
                zda_utc_vld <= #U_DLY 1'b0;

            if(load_r[1]==1'b1)
                tmo_cnt <= #U_DLY 'b0;
            else if((s_flg==1'b1) && (tmo_cnt>=tmo_sec-'d1))
                tmo_cnt <= #U_DLY tmo_sec;
            else if((s_flg==1'b1) && (tmo_cnt<tmo_sec-'d1))
                tmo_cnt <= #U_DLY tmo_cnt + 'b1;
        end 
end









endmodule
