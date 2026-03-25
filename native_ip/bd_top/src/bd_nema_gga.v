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
module bd_nema_gga # (
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst,
//
input  [19:0]                       tmo_sec,

//
input                               rx_vld,
input [7:0]                         rx_data,
//
output reg [15:0]                   gga_wd_word0,
output reg [23:0]                   gga_wd_word1,
output reg [7:0]                    gga_wd_dir,
output reg [19:0]                   gga_jd_word0,
output reg [23:0]                   gga_jd_word1,
output reg [7:0]                    gga_jd_dir,
output reg [23:0]                   gga_high_word0,
output reg [7:0]                    gga_high_word1,
output reg [7:0]                    gga_high_word_minus,
output reg [15:0]                   gga_id,
output reg                          gga_pps_overtime,
output reg [3:0]                    gga_state,
output reg [7:0]                    gga_satellite,
output reg                          gga_vld

);
// Parameter Define 
localparam                          IDLE  = 2'd0;
localparam                          SAMP  = 2'd1;
localparam                          COMMA = 2'd2;
localparam                          END   = 2'd3;
// Register Define 
reg     [1:0]                       state;
reg     [1:0]                       nextstate;
reg     [2:0]                       gngga_cnt;
reg     [3:0]                       samp_cnt;
reg                                 wd_point;
reg                                 jd_point;
reg                                 high_point;
reg                                 load;
reg     [15:0]                      gga_wd_word0_r;
reg     [23:0]                      gga_wd_word1_r;
reg     [7:0]                       gga_wd_dir_r;
reg     [19:0]                      gga_jd_word0_r;
reg     [23:0]                      gga_jd_word1_r;
reg     [7:0]                       gga_jd_dir_r;
reg     [23:0]                      gga_high_word0_r;
reg     [7:0]                       gga_high_word1_r;
reg     [7:0]                       gga_high_word_minus_r;
reg     [15:0]                      id_r;
reg     [1:0]                       bd_pps_cnt;
reg     [3:0]                       gga_state_r;
reg     [7:0]                       gga_satellite_r;
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

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        state <= #U_DLY IDLE;        
    else if(gga_pps_overtime==1'b1)
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
assign gngga[3] = (rx_vld==1'b1 && rx_data==8'h47) ? 1'b1:1'b0; //G
assign gngga[4] = (rx_vld==1'b1 && rx_data==8'h47) ? 1'b1:1'b0; //G
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
    	   ||  (gngga_cnt=='d3 && rx_vld==1'b1 && rx_data!=8'h47)//G
    	   ||  (gngga_cnt=='d4 && rx_vld==1'b1 && rx_data!=8'h47)//G
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
       gga_id <= #U_DLY 'b0; 
    else if(load==1'b1)
       gga_id <= #U_DLY id_r;
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
        gga_pps_overtime <= #U_DLY 1'b0; 
    else if(state==SAMP && bd_pps_cnt=='d3)
    	gga_pps_overtime <= #U_DLY 1'b1; 
    else 
    	gga_pps_overtime <= #U_DLY 1'b0; 
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
        load <= #U_DLY 1'b0;       
    else if(state==END)
        load <= #U_DLY 1'b1;
    else
        load <= #U_DLY 1'b0;
end




always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_wd_word0_r <= #U_DLY 'b0;      
    else if(state==IDLE)
        gga_wd_word0_r <= #U_DLY 'b0;     
    else if(state==SAMP && samp_cnt=='d1 && wd_point==1'b0)
        begin
            if(rx_vld==1'b1 && rx_data!=8'h2e)
            gga_wd_word0_r <= #U_DLY {gga_wd_word0_r[12:0],rx_data[3:0]};
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_wd_word1_r <= #U_DLY 'b0;  
    else if(state==IDLE)
        gga_wd_word1_r <= #U_DLY 'b0;         
    else if(state==SAMP && samp_cnt=='d1 && wd_point==1'b1)
        begin
            if(rx_vld==1'b1 && rx_data!=8'h2e && rx_data!=8'h2c)
            gga_wd_word1_r <= #U_DLY {gga_wd_word1_r[19:0],rx_data[3:0]};
        end   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        wd_point <= #U_DLY 1'b0;        
    else if(state==SAMP && samp_cnt=='d1)
        begin
            if(rx_comma==1'b1)
                wd_point <= #U_DLY 1'b0;
            else if(rx_point==1'b1)
                wd_point <= #U_DLY 1'b1;
        end   
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_wd_dir_r <= #U_DLY 'b0;        
    else if(state==SAMP && samp_cnt=='d2)  
        begin
            if(rx_vld==1'b1 && rx_data==8'h4e)//N
                gga_wd_dir_r <= #U_DLY 8'h4e;
            else if(rx_vld==1'b1 && rx_vld==8'h53)//S
                gga_wd_dir_r <= #U_DLY 8'h53;
        end 
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_jd_word0_r <= #U_DLY 'b0;    
    else if(state==IDLE)
        gga_jd_word0_r <= #U_DLY 'b0;            
    else if(state==SAMP && samp_cnt=='d3 && jd_point==1'b0)
        begin
            if(rx_vld==1'b1 && rx_data!=8'h2e)
            gga_jd_word0_r <= #U_DLY {gga_jd_word0_r[15:0],rx_data[3:0]};
        end
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_jd_word1_r <= #U_DLY 'b0;       
    else if(state==IDLE)
        gga_jd_word1_r <= #U_DLY 'b0;             
    else if(state==SAMP && samp_cnt=='d3 && jd_point==1'b1)
        begin
            if(rx_vld==1'b1 && rx_data!=8'h2e && rx_data!=8'h2c)
            gga_jd_word1_r <= #U_DLY {gga_jd_word1_r[19:0],rx_data[3:0]};
        end   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        jd_point <= #U_DLY 1'b0;        
    else if(state==SAMP && samp_cnt=='d3)
        begin
            if(rx_comma==1'b1)
                jd_point <= #U_DLY 1'b0;
            else if(rx_point==1'b1)
                jd_point <= #U_DLY 1'b1;
        end   
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_jd_dir_r <= #U_DLY 'b0;        
    else if(state==SAMP && samp_cnt=='d4)  
        begin
            if(rx_vld==1'b1 && rx_data==8'h45)//E
                gga_jd_dir_r <= #U_DLY 8'h45;
            else if(rx_vld==1'b1 && rx_vld==8'h57)//W
                gga_jd_dir_r <= #U_DLY 8'h57;
        end 
end



always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_high_word0_r <= #U_DLY 'b0;     
    else if(state==IDLE)
        gga_high_word0_r <= #U_DLY 'b0;         
    else if(state==SAMP && samp_cnt=='d8 && high_point==1'b0)
       begin
           if(rx_vld==1'b1 && rx_data!=8'h2e)
               gga_high_word0_r <= #U_DLY {gga_high_word0_r[19:0],rx_data[3:0]};
       end   

end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_high_word1_r <= #U_DLY 'b0;   
    else if(state==IDLE)
        gga_high_word1_r <= #U_DLY 'b0;           
    else if(state==SAMP && samp_cnt=='d8 && high_point==1'b1)
       begin
           if(rx_vld==1'b1 && rx_data!=8'h2e && rx_data!=8'h2c)
               gga_high_word1_r <= #U_DLY {gga_high_word1_r[3:0],rx_data[3:0]};
       end   
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        high_point <= #U_DLY 1'b0;         
    else if(state==SAMP && samp_cnt=='d8)
        begin
            if(rx_comma==1'b1)
                high_point <= #U_DLY 1'b0;
            else if(rx_point==1'b1)
                high_point <= #U_DLY 1'b1;
        end  

end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_high_word_minus_r <= #U_DLY 'b0;        
    else if(state==SAMP && samp_cnt=='d8)
        begin
            if(rx_vld==1'b1 && rx_data==8'h2d)
                gga_high_word_minus_r <= #U_DLY 8'h2d; 
        end   
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_state_r <= #U_DLY 'b0;        
    else if(state==SAMP && samp_cnt=='d5)
        begin
            if(rx_vld==1'b1 && rx_data!=",")
                gga_state_r <= #U_DLY rx_data[3:0]; 
        end   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        gga_satellite_r <= #U_DLY 'b0;     
    else if(state==IDLE)
        gga_satellite_r <= #U_DLY 'b0;         
    else if(state==SAMP && samp_cnt=='d6)
        begin
            if(rx_vld==1'b1 && rx_data!=",")
                gga_satellite_r <= #U_DLY {gga_satellite_r[3:0],rx_data[3:0]}; 
        end   
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            gga_wd_word0 <= #U_DLY 'b0;
            gga_wd_word1 <= #U_DLY 'b0;
            gga_wd_dir <= #U_DLY 'b0;
            gga_jd_word0 <= #U_DLY 'b0;
            gga_jd_word1 <= #U_DLY 'b0;
            gga_jd_dir <= #U_DLY 'b0;
            gga_high_word0 <= #U_DLY 'b0;
            gga_high_word1 <= #U_DLY 'b0;
            gga_high_word_minus <= #U_DLY 'b0;
            gga_state <= #U_DLY 'b0;
            gga_satellite <= #U_DLY 'b0;
        end        
    else if(load==1'b1)
        begin
            gga_wd_word0 <= #U_DLY gga_wd_word0_r;
            gga_wd_word1 <= #U_DLY gga_wd_word1_r;
            gga_wd_dir <= #U_DLY gga_wd_dir_r;
            gga_jd_word0 <= #U_DLY gga_jd_word0_r;
            gga_jd_word1 <= #U_DLY gga_jd_word1_r;
            gga_jd_dir <= #U_DLY gga_jd_dir_r;
            gga_high_word0 <= #U_DLY gga_high_word0_r;
            gga_high_word1 <= #U_DLY gga_high_word1_r;
            gga_high_word_minus <= #U_DLY gga_high_word_minus_r;
            gga_state <= #U_DLY gga_state_r;
            gga_satellite <= #U_DLY gga_satellite_r;
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
            gga_vld <= #U_DLY 1'b0;
            tmo_cnt <= #U_DLY 'd0;
        end       
    else   
        begin
            if(load==1'b1)
                gga_vld <= #U_DLY 1'b1;
            else if(tmo_cnt>=tmo_sec-'d1)
                gga_vld <= #U_DLY 1'b0;

            if(load==1'b1)
                tmo_cnt <= #U_DLY 'b0;
            else if((s_flg==1'b1) && (tmo_cnt>=tmo_sec-'d1))
                tmo_cnt <= #U_DLY tmo_sec;
            else if((s_flg==1'b1) && (tmo_cnt<tmo_sec-'d1))
                tmo_cnt <= #U_DLY tmo_cnt + 'b1;
        end 
end


endmodule
