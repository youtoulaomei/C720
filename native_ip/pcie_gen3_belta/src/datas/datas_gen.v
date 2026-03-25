// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2015/9/9 11:19:07
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
module datas_gen # (
parameter                           U_DLY  = 1,
parameter                           DATA_W = 512
)
(
input                               clk,
input                               rst_n,

input                               tbucket_ready,

input  [2:0]                        ds_data_mode,
input  [63:0]                       ds_static_pattern,
input                               ds_tx_len_start,
input                               ds_tx_con_start,
input  [31:0]                       ds_len_mode_count,
input  [247:0]                      ds_prbs31_seed,

output wire[DATA_W-1:0]             tx_data,
output wire[DATA_W/8-1:0]           tx_keep,
output reg                          tx_last,
output reg                          tx_head,  
output reg                          tx_tail,
output reg                          tx_data_vld,
input                               prog_full,

output reg                          ds_send_done
);
// Parameter Define 
localparam                           IDLE       = 3'd0;
localparam                           SEND_DATA  = 3'd1;
localparam                           SEND_LEN   = 3'd2;
localparam                           SEND_END   = 3'd3;
// Register Define 
reg [2:0]                           gen_state                          ;
reg [2:0]                           gen_nextstate                      ;

reg  [2:0]                          ds_data_mode_syn_1                 ; 
reg  [63:0]                         ds_static_pattern_syn_1            ;
reg                                 ds_tx_len_start_syn_1              ;
reg                                 ds_tx_con_start_syn_1              ;
reg  [31:0]                         ds_len_mode_count_syn_1            ;
reg  [247:0]                        ds_prbs31_seed_syn_1               ;

reg  [2:0]                          ds_data_mode_syn_2                 ;
reg  [63:0]                         ds_static_pattern_syn_2            ;
reg                                 ds_tx_len_start_syn_2              ;
reg                                 ds_tx_con_start_syn_2              ;              
reg                                 ds_tx_con_start_syn_3              ; 
reg  [31:0]                         ds_len_mode_count_syn_2            ;
reg  [247:0]                        ds_prbs31_seed_syn_2               ;
                                                                       
reg                                 ds_tx_len_start_syn_3              ;
wire                                ds_tx_len_start_det                ;

reg  [127:0]                        tx_data_128_mode_w                 ;
reg  [31:0]                         tx_data_32_mode_w                  ;                                                                
reg                                 send_len_done                      ;
wire                                send_len_done_x                    ;
reg  [6:0]                          tx_byte                            ;
reg  [31:0]                         len_mode_count                     ;
wire [31:0]                         len_mode_count_x                   ;


wire                                tx_inc8_vld                        ;
wire                                tx_prbs31_vld                      ;
wire [7:0]                          tx_data_8_mode_w                   ;         
wire [DATA_W-1:0]                   tx_data_prbs31_mode_w              ;
reg  [DATA_W-1:0]                   tx_data_reg                        ;   

wire                                clr                                ;
reg                                 start_clr                          ;

wire  [30:0]                        seed_x [DATA_W/8-1:0]              ;
wire [(31*(DATA_W/8))-1:0]          seed_w                             ;
wire                                send_len_last_x                    ;    
reg                                 ds_tx_con_start_neg                ;

reg                                 ds_send_done_r1                    ;
reg                                 ds_send_done_r2                    ;

//------------------------------------------------------------------------------
// sync
//------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      begin
        ds_data_mode_syn_1 <= #U_DLY 3'b0;
        ds_data_mode_syn_2 <= #U_DLY 3'b0;
      end
    else    
      begin
        ds_data_mode_syn_1 <= #U_DLY ds_data_mode;
        ds_data_mode_syn_2 <= #U_DLY ds_data_mode_syn_1;
      end
end

//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)     
//      begin
//        ds_header_ins_syn_1 <= #U_DLY 1'b0;
//        ds_header_ins_syn_2 <= #U_DLY 1'b0;
//      end
//    else    
//      begin
//        ds_header_ins_syn_1 <= #U_DLY ds_header_ins;
//        ds_header_ins_syn_2 <= #U_DLY ds_header_ins_syn_1;
//      end
//end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      begin
        ds_static_pattern_syn_1 <= #U_DLY 64'b0;
        ds_static_pattern_syn_2 <= #U_DLY 64'b0;
      end
    else    
      begin
        ds_static_pattern_syn_1 <= #U_DLY ds_static_pattern;
        ds_static_pattern_syn_2 <= #U_DLY ds_static_pattern_syn_1;
      end
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      begin
        ds_tx_con_start_syn_1 <= #U_DLY 1'b0;
        ds_tx_con_start_syn_2 <= #U_DLY 1'b0;           
        ds_tx_con_start_syn_3 <= #U_DLY 1'b0; 
      end
    else    
      begin
        ds_tx_con_start_syn_1 <= #U_DLY ds_tx_con_start;
        ds_tx_con_start_syn_2 <= #U_DLY ds_tx_con_start_syn_1;     
        ds_tx_con_start_syn_3 <= #U_DLY ds_tx_con_start_syn_2;
      end
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      begin
        ds_tx_len_start_syn_1 <= #U_DLY 1'b0;
        ds_tx_len_start_syn_2 <= #U_DLY 1'b0;
        ds_tx_len_start_syn_3 <= #U_DLY 1'b0;
      end
    else    
      begin
        ds_tx_len_start_syn_1 <= #U_DLY ds_tx_len_start;
        ds_tx_len_start_syn_2 <= #U_DLY ds_tx_len_start_syn_1;
        ds_tx_len_start_syn_3 <= #U_DLY ds_tx_len_start_syn_2;
      end
end

assign ds_tx_len_start_det = (ds_tx_len_start_syn_2 == 1'b1 && ds_tx_len_start_syn_3 == 1'b0) ? 1'b1: 1'b0;


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      begin
        ds_len_mode_count_syn_1 <= #U_DLY 'b0;
        ds_len_mode_count_syn_2 <= #U_DLY 'b0;
      end
    else    
      begin
        ds_len_mode_count_syn_1 <= #U_DLY ds_len_mode_count;
        ds_len_mode_count_syn_2 <= #U_DLY ds_len_mode_count_syn_1;
      end
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      begin
        ds_prbs31_seed_syn_1 <= #U_DLY 248'b0;
        ds_prbs31_seed_syn_2 <= #U_DLY 248'b0;
      end
    else    
      begin
        ds_prbs31_seed_syn_1 <= #U_DLY ds_prbs31_seed;
        ds_prbs31_seed_syn_2 <= #U_DLY ds_prbs31_seed_syn_1;
      end
end
                                  
always @ (posedge clk or negedge rst_n)
begin
   if(rst_n== 1'b0 )
       ds_tx_con_start_neg <= #U_DLY 1'b0;
   else if(gen_state == SEND_END)  
       ds_tx_con_start_neg <= #U_DLY 1'b0;
   else if(ds_tx_con_start_syn_2 == 1'b0 && ds_tx_con_start_syn_3 == 1'b1)
       ds_tx_con_start_neg <= #U_DLY 1'b1;
end                                  
                                  
// state-machine
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      gen_state <= #U_DLY IDLE;
    else    
      gen_state <= #U_DLY gen_nextstate;    
end

always @(*)
begin
  case(gen_state)
    IDLE:
      begin
        if(ds_tx_con_start_syn_2 == 1'b1)
          gen_nextstate = SEND_DATA;
        else if( ds_tx_len_start_det == 1'b1 )
          gen_nextstate = SEND_LEN;
        else
          gen_nextstate = IDLE;
      end

    SEND_DATA:
      begin
        if(ds_tx_con_start_neg == 1'b1)
          begin
              if(prog_full==1'b0 && tbucket_ready == 1'b1)
                  gen_nextstate = SEND_END;
              else
                  gen_nextstate = SEND_DATA; 
          end
        else
          gen_nextstate = SEND_DATA;
      end

    SEND_LEN:
      begin
        if(send_len_done == 1'b1)
           gen_nextstate = SEND_END;
        else
          gen_nextstate = SEND_LEN;
      end
    
    SEND_END:
      begin
        gen_nextstate = IDLE;
      end

    default:
      gen_nextstate = IDLE;
  endcase
end

//------------------------------------------------------------------------------
// tx_data_vld
//------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0) 
        tx_data_vld <= #U_DLY 1'b0;
    else if((gen_state == SEND_DATA) || (gen_state == SEND_LEN && send_len_done_x == 1'b0) )
      begin
        if( tbucket_ready == 1'b1 )
          begin
            if( prog_full == 1'b0 )
              tx_data_vld <= #U_DLY 1'b1;
            else
              tx_data_vld <= #U_DLY 1'b0;
          end
        else
          tx_data_vld <= #U_DLY 1'b0;
      end   
    else
      tx_data_vld <= #U_DLY 1'b0;
end


//not used 
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      tx_last <= #U_DLY 1'b0;
    else if( gen_state == SEND_DATA && ds_tx_con_start_syn_2 == 1'b0)  
      tx_last <= #U_DLY 1'b1;
    else if( gen_state == SEND_LEN && send_len_done == 1'b1)
      tx_last <= #U_DLY 1'b1;
    else
      tx_last <= #U_DLY 1'b0;  
end     
            
//ok  
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0) 
        tx_head <= #U_DLY 1'b0;
    else if(tx_data_vld == 1'b1)
        tx_head <= #U_DLY 1'b0;        
    else if(gen_state == IDLE && gen_nextstate != IDLE)
        tx_head <= #U_DLY 1'b1;
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        tx_tail <= #U_DLY 1'b0; 
    else if(gen_state == IDLE )    
        tx_tail <= #U_DLY 1'b0;   
    else if(send_len_last_x == 1'b1)
        tx_tail <= #U_DLY 1'b1; 
    else if(ds_tx_con_start_neg == 1'b1)
        tx_tail <= #U_DLY 1'b1; 
end


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      send_len_done <= #U_DLY 1'b0;  
    else    
      send_len_done <= #U_DLY send_len_done_x;
end

assign send_len_done_x =  (gen_state == IDLE) ? 1'b0 :   
                           (gen_state == SEND_LEN) && (ds_len_mode_count_syn_2 == len_mode_count_x) ? 1'b1 : 1'b0;

assign send_len_last_x =   (gen_state == IDLE) ? 1'b0 :   
                          (gen_state == SEND_LEN) && ((ds_len_mode_count_syn_2 - len_mode_count_x) <= 'd64) ? 1'b1 : 1'b0;
//------------------------------------------------------------------------------
// tx_keep
//------------------------------------------------------------------------------

assign tx_keep = 64'hffff_ffff_ffff_ffff;


//------------------------------------------------------------------------------
// tx_byte
//------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)    
        tx_byte <= #U_DLY 'd0;
    else if( gen_state == SEND_DATA )
        tx_byte <= #U_DLY 'd64;   
    else if( gen_state == SEND_LEN)
        begin
            if(ds_len_mode_count_syn_2 - len_mode_count_x <= 'd64 )
                tx_byte <= #U_DLY  (ds_len_mode_count_syn_2 - len_mode_count_x);
            else
                tx_byte <= #U_DLY  'd64;              
        end
    else
        tx_byte <= #U_DLY  'd0;                  
end


//------------------------------------------------------------------------------
//len_mode_count 
//------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        len_mode_count <= #U_DLY 'b0;          
    else
        len_mode_count <= #U_DLY len_mode_count_x;
end

assign len_mode_count_x = (gen_state == IDLE) ? 'b0 :
                          (tx_data_vld == 1'b1) ?  len_mode_count + {25'b0,tx_byte} : len_mode_count ;     


//tx_data
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        tx_data_reg <= #U_DLY {(DATA_W){1'b0}};
    else
        tx_data_reg <= #U_DLY tx_data;
end

assign tx_data = (ds_data_mode_syn_2 == 3'd0) ? {ds_static_pattern_syn_2,ds_static_pattern_syn_2,ds_static_pattern_syn_2,ds_static_pattern_syn_2,
                                                 ds_static_pattern_syn_2,ds_static_pattern_syn_2,ds_static_pattern_syn_2,ds_static_pattern_syn_2}:
                 (ds_data_mode_syn_2 == 3'd1) ? {tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w, 
                                                 tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,
                                                 tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,
                                                 tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,
                                                 tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w, 
                                                 tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,
                                                 tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,
                                                 tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w,tx_data_8_mode_w} :
                 (ds_data_mode_syn_2 == 3'd2) ? tx_data_prbs31_mode_w:
                 (ds_data_mode_syn_2 == 3'd3) ? {384'b0,tx_data_128_mode_w}:
                 (ds_data_mode_syn_2 == 3'd4) ? {tx_data_32_mode_w+'d15,tx_data_32_mode_w+'d14,tx_data_32_mode_w+'d13,tx_data_32_mode_w+'d12,
                                                 tx_data_32_mode_w+'d11,tx_data_32_mode_w+'d10,tx_data_32_mode_w+'d9,tx_data_32_mode_w+'d8,
                                                 tx_data_32_mode_w+'d7,tx_data_32_mode_w+'d6,tx_data_32_mode_w+'d5,tx_data_32_mode_w+'d4,
                                                 tx_data_32_mode_w+'d3,tx_data_32_mode_w+'d2,tx_data_32_mode_w+'d1,tx_data_32_mode_w+'d0}:tx_data_reg;
                 
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)    
        tx_data_128_mode_w <= #U_DLY 'b0;
    else if(clr==1'b1)
        tx_data_128_mode_w <= #U_DLY 'b0;
    else if((tx_data_vld == 1'b1) && (ds_data_mode_syn_2 == 3'd3))
        tx_data_128_mode_w <= #U_DLY tx_data_128_mode_w + 'b1;
end     

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)    
        tx_data_32_mode_w <= #U_DLY 'b0;
    else if(clr==1'b1)
        tx_data_32_mode_w <= #U_DLY 'b0;
    else if((tx_data_vld == 1'b1) && (ds_data_mode_syn_2 == 3'd4))
        tx_data_32_mode_w <= #U_DLY tx_data_32_mode_w + 'd16;
end              

//CLR 
//assign clr = (start_clr == 1'b1 || ds_tx_len_start_det == 1'b1) ? 1'b1:1'b0; 
assign clr = 1'b0;

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      start_clr <= #U_DLY 1'b0;
    else if( gen_state ==IDLE && gen_nextstate != IDLE ) 
      start_clr <= #U_DLY 1'b1;
    else
      start_clr <= #U_DLY 1'b0;  

end


assign tx_inc8_vld   = (tx_data_vld == 1'b1) && (ds_data_mode_syn_2 == 3'd1) ? 1'b1 : 1'b0;
assign tx_prbs31_vld = (tx_data_vld == 1'b1) && (ds_data_mode_syn_2 == 3'd2) ? 1'b1 : 1'b0;


//-----------------------------------------------------------------------------------------
//inc8
//----------------------------------------------------------------------------------------- 
//generate
//genvar j;
//for(j = 0 ; j <DATA_W/8 ; j = j + 1)        
//begin: inst_inc8
//datas_gen_inc8 #
//(
//.U_DLY (U_DLY)
//) 
//u_datas_gen_inc8(         
//  .clk      (clk),
//  .rst_n    (rst_n),
//  .clr      (clr),
//  .send_vld (tx_inc8_vld),
//  .data     (tx_data_8_mode_w[(j*8+7):(j*8)])
//  );
//end
//endgenerate

datas_gen_inc8 #                             
(                                            
.U_DLY (U_DLY)                               
)                                            
u_datas_gen_inc8(                            
  .clk      (clk),                           
  .rst_n    (rst_n),                         
  .clr      (clr),                           
  .send_vld (tx_inc8_vld),                   
  .data     (tx_data_8_mode_w)
  );                                         
                                         


//-----------------------------------------------------------------------------------------
//prbs31
//-----------------------------------------------------------------------------------------
assign seed_w = {ds_prbs31_seed_syn_2[30:0],
                 ds_prbs31_seed_syn_2[61:31],
                 ds_prbs31_seed_syn_2[92:62],
                 ds_prbs31_seed_syn_2[123:93],
                 ds_prbs31_seed_syn_2[154:124],
                 ds_prbs31_seed_syn_2[185:155],
                 ds_prbs31_seed_syn_2[216:186],
                 ds_prbs31_seed_syn_2[247:217],
                 
                 (ds_prbs31_seed_syn_2[30:0]   +1),
                 (ds_prbs31_seed_syn_2[61:31]  +2),
                 (ds_prbs31_seed_syn_2[92:62]  +3),
                 (ds_prbs31_seed_syn_2[123:93] +4),
                 (ds_prbs31_seed_syn_2[154:124]+5),
                 (ds_prbs31_seed_syn_2[185:155]+6),
                 (ds_prbs31_seed_syn_2[216:186]+7),
                 (ds_prbs31_seed_syn_2[247:217]+8),
                 
                 (ds_prbs31_seed_syn_2[30:0]   +22),
                 (ds_prbs31_seed_syn_2[61:31]  +24),
                 (ds_prbs31_seed_syn_2[92:62]  +26),
                 (ds_prbs31_seed_syn_2[123:93] +28),
                 (ds_prbs31_seed_syn_2[154:124]+30),
                 (ds_prbs31_seed_syn_2[185:155]+32),
                 (ds_prbs31_seed_syn_2[216:186]+34),
                 (ds_prbs31_seed_syn_2[247:217]+36),                 

                 (ds_prbs31_seed_syn_2[30:0]   +42),
                 (ds_prbs31_seed_syn_2[61:31]  +44),
                 (ds_prbs31_seed_syn_2[92:62]  +46),
                 (ds_prbs31_seed_syn_2[123:93] +48),
                 (ds_prbs31_seed_syn_2[154:124]+40),
                 (ds_prbs31_seed_syn_2[185:155]+42),
                 (ds_prbs31_seed_syn_2[216:186]+44),
                 (ds_prbs31_seed_syn_2[247:217]+46),                       

                 (ds_prbs31_seed_syn_2[30:0]   +76),
                 (ds_prbs31_seed_syn_2[61:31]  +98),
                 (ds_prbs31_seed_syn_2[92:62]  +53),
                 (ds_prbs31_seed_syn_2[123:93] +65),
                 (ds_prbs31_seed_syn_2[154:124]+76),
                 (ds_prbs31_seed_syn_2[185:155]+78),
                 (ds_prbs31_seed_syn_2[216:186]+90),
                 (ds_prbs31_seed_syn_2[247:217]+12),           
                 
                 (ds_prbs31_seed_syn_2[30:0]   +43),
                 (ds_prbs31_seed_syn_2[61:31]  +64),
                 (ds_prbs31_seed_syn_2[92:62]  +87),
                 (ds_prbs31_seed_syn_2[123:93] +91),
                 (ds_prbs31_seed_syn_2[154:124]+45),
                 (ds_prbs31_seed_syn_2[185:155]+31),
                 (ds_prbs31_seed_syn_2[216:186]+16),
                 (ds_prbs31_seed_syn_2[247:217]+49),
                 
                 (ds_prbs31_seed_syn_2[30:0]   +69),
                 (ds_prbs31_seed_syn_2[61:31]  +35),
                 (ds_prbs31_seed_syn_2[92:62]  +89),
                 (ds_prbs31_seed_syn_2[123:93] +54),
                 (ds_prbs31_seed_syn_2[154:124]+64),
                 (ds_prbs31_seed_syn_2[185:155]+22),
                 (ds_prbs31_seed_syn_2[216:186]+87),
                 (ds_prbs31_seed_syn_2[247:217]+10),                 

                 (ds_prbs31_seed_syn_2[30:0]   +34),
                 (ds_prbs31_seed_syn_2[61:31]  +54),
                 (ds_prbs31_seed_syn_2[92:62]  +87),
                 (ds_prbs31_seed_syn_2[123:93] +19),
                 (ds_prbs31_seed_syn_2[154:124]+28),
                 (ds_prbs31_seed_syn_2[185:155]+30),
                 (ds_prbs31_seed_syn_2[216:186]+76),
                 (ds_prbs31_seed_syn_2[247:217]+44)                         
                 };

generate
genvar l;
for(l=0; l <DATA_W/8 ; l = l+1)
   begin
      assign seed_x[l] = seed_w[(l*31+30):(l*31)];
   end
endgenerate


generate
genvar k;
for(k = 0 ; k <DATA_W/8 ; k = k + 1)        
begin: inst_prbs
datas_gen_prbs31 #
(
.U_DLY (U_DLY)
) 
u_datas_gen_prbs31(         
  .clk      (clk),
  .rst_n    (rst_n),
  .clr      (clr),
  .seed     (seed_x[k]),
  .send_vld (tx_prbs31_vld),
  .data     (tx_data_prbs31_mode_w[(k*8+7):(k*8)])
  );
end
endgenerate





//
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)    
        ds_send_done_r1 <= #U_DLY 1'b0;
    else if(gen_state == SEND_END && gen_nextstate == IDLE)
        ds_send_done_r1 <= #U_DLY 1'b1;
    else 
        ds_send_done_r1 <= #U_DLY 1'b0;
end  

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)    
        ds_send_done_r2 <= #U_DLY 'b0;
    else 
        ds_send_done_r2 <= #U_DLY ds_send_done_r1;
end  

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)    
        ds_send_done <= #U_DLY 'b0;
    else if(ds_send_done_r1 == 1'b1 || ds_send_done_r2 == 1'b1)
        ds_send_done <= #U_DLY 1'b1;
    else
        ds_send_done <= #U_DLY 1'b0;
end 


endmodule
