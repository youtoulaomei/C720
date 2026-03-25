// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : Dingliang@zmdde.com
// Creat Time   : 2015/9/19 10:35:35
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
module datas_check # (
parameter                           U_DLY  = 1,
parameter                           DATA_W = 256
)
(
input                               clk,
input                               rst_n,

input  [247:0]                      ds_prbs31_seed,

input                               check_st,

input [DATA_W-1:0]                  rx_data,
input [DATA_W/8-1:0]                rx_keep,
input                               rx_last,
input                               rx_data_vld,

output reg [15:0]                   err_num_8bit,
output reg [63:0]                   err_len_8bit,
output reg [15:0]                   err_num_prbs31,
output reg [63:0]                   err_len_prbs31,
output reg [15:0]                   err_num_128bit,
output reg [63:0]                   err_len_128bit,

output reg                          errcontext_8bit_wr,   
output reg [5:0]                    errcontext_8bit_wr_addr,   
output reg [15:0]                   errcontext_8bit_wr_data,   

output reg                          errcontext_prbs31_wr,      
output reg [5:0]                    errcontext_prbs31_wr_addr, 
output reg [15:0]                   errcontext_prbs31_wr_data, 

output reg                          errcontext_128bit_wr,      
output reg [5:0]                    errcontext_128bit_wr_addr, 
output reg [15:0]                   errcontext_128bit_wr_data, 

output reg [63:0]                   file_len
);
// Parameter Define 

// Register Define 

// Wire Define 
reg  [2:0]                          check_st_r                ;                    
reg                                 check_st_det              ;
reg                                 check_first               ;
wire                                pbc_start                 ;
                                                              
wire [DATA_W/8-1:0]                 err_flag_x_8bit           ;
wire                                err_flag_8bit_or          ;
wire                                fisrt_err_8bit            ;
reg                                 check_fisrt_err_8bit      ;
reg                                 fisrt_err_8bit_af         ;
reg  [767:0]                        errcontext_8bit_w         ;
wire [5:0]                          errcontext_8bit_wr_addr_x ;
wire [15:0]                         errcontext_8bit_t [0:47]  ;
                                                             
wire [DATA_W/8-1:0]                 err_flag_x_prbs31         ;
wire                                err_flag_prbs31_or        ;
wire                                fisrt_err_prbs31          ;
reg                                 check_fisrt_err_prbs31    ;
reg                                 fisrt_err_prbs31_af       ;
reg  [767:0]                        errcontext_prbs31_w       ;
wire [5:0]                          errcontext_prbs31_wr_addr_x;
wire [15:0]                         errcontext_prbs31_t [0:47];


reg                                 add                       ;
reg [5:0]                           addcnt                    ;

reg [DATA_W-1:0]                    rx_data_r1                ;

//---------------------------------------------------------------------------------------------------------------------------------------
//check first logic 
//---------------------------------------------------------------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      check_st_r <= #U_DLY 3'b0;
    else    
      check_st_r <= #U_DLY {check_st_r[1:0],check_st};
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      check_st_det <= #U_DLY 1'b0;
    else if(check_st_r[1] == 1'b1 && check_st_r[2] == 1'b0 )   
      check_st_det <= #U_DLY 1'b1;
    else
      check_st_det <= #U_DLY 1'b0; 
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      check_first <= #U_DLY 1'b0;
    else if( rx_data_vld == 1'b1 && check_first == 1'b1 )
      check_first <= #U_DLY 1'b0;
    else if( check_st_det == 1'b1 )  
      check_first <= #U_DLY 1'b1;
end

assign pbc_start = (check_first == 1'b1) && (rx_data_vld == 1'b1) ? 1'b1 : 1'b0;

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      rx_data_r1 <= #U_DLY {(DATA_W){1'b0}}; 
    else if(rx_data_vld==1'b1)   
      rx_data_r1 <= #U_DLY rx_data;
end
//---------------------------------------------------------------------------------------------------------------------------------------
//128bit check logic 
//---------------------------------------------------------------------------------------------------------------------------------------
reg [127:0]  data_128bit_inc;
reg          check_fisrt_err_128bit;
wire[15:0]   err_flag_x_128bit;
wire[15:0]   err_flag_x_128bit_high;
wire         err_flag_128bit_or;
wire         fisrt_err_128bit;
reg          fisrt_err_128bit_af;      
reg [767:0]  errcontext_128bit_w; 
wire [5:0]   errcontext_128bit_wr_addr_x;  
wire [15:0]  errcontext_128bit_t [0:47];

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      data_128bit_inc <= #U_DLY 128'b0;
    else if(pbc_start== 1'b1 )
      data_128bit_inc <= #U_DLY rx_data[127:0] + 128'b1;   
    else if( rx_data_vld == 1'b1 )
      data_128bit_inc <= #U_DLY data_128bit_inc + 128'b1; 
end

generate
genvar h;
for(h=0;h<16;h=h+1)
assign err_flag_x_128bit[h] = (pbc_start == 1'b1) ? 1'b0 :
                            ((rx_keep[h] == 1'b1)&& (rx_data_vld ==1'b1) && (rx_data[(h*8+7):(h*8)] != data_128bit_inc[(h*8+7):(h*8)])) ? 1'b1 : 1'b0;
endgenerate


generate
genvar a;
for(a=0;a<16;a=a+1)
assign err_flag_x_128bit_high[a] = (pbc_start == 1'b1) ? 1'b0 :
                            ((rx_keep[(a+16)] == 1'b1)&& (rx_data_vld ==1'b1) && (rx_data[((a+16)*8+7):((a+16)*8)] != 8'b0) ) ? 1'b1 : 1'b0;
endgenerate

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      check_fisrt_err_128bit <= #U_DLY 1'b0;
    else if( check_st_det == 1'b1 )   
      check_fisrt_err_128bit <= #U_DLY 1'b1;
    else if(err_flag_128bit_or == 1'b1 )
      check_fisrt_err_128bit <= #U_DLY 1'b0;
end

assign err_flag_128bit_or =  ( (|err_flag_x_128bit == 1'b1) || (|err_flag_x_128bit_high == 1'b1)) ? 1'b1:1'b0;

assign fisrt_err_128bit =  (err_flag_128bit_or == 1'b1) && (check_fisrt_err_128bit == 1'b1) ? 1'b1:1'b0;


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      err_num_128bit <= #U_DLY 16'd0;
    else if( check_st_det == 1'b1 )   
      err_num_128bit <= #U_DLY 16'd0;
    else if( err_num_128bit == 16'hffff)
      err_num_128bit <= #U_DLY 16'hffff;
    else if( err_flag_128bit_or == 1'b1 )
      err_num_128bit <= #U_DLY err_num_128bit + 16'd1;
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      errcontext_128bit_w[511:256] <= #U_DLY 'b0;   
    else if( fisrt_err_128bit == 1'b1 )
      errcontext_128bit_w[511:256] <= #U_DLY rx_data;   
end


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      errcontext_128bit_w[255:0] <= #U_DLY 'b0;    
    else if( fisrt_err_128bit == 1'b1 )    
      errcontext_128bit_w[255:0] <= #U_DLY rx_data_r1; 
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      errcontext_128bit_w[767:512] <= #U_DLY 'b0;
    else if( fisrt_err_128bit_af == 1'b1 && rx_data_vld == 1'b1 )
      errcontext_128bit_w[767:512] <= #U_DLY rx_data;
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      fisrt_err_128bit_af <= #U_DLY 1'b0;
    else if( fisrt_err_128bit_af == 1'b1 && rx_data_vld == 1'b1 )   
      fisrt_err_128bit_af <= #U_DLY 1'b0;
    else if( fisrt_err_128bit == 1'b1 )
      fisrt_err_128bit_af <= #U_DLY 1'b1;      
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      err_len_128bit <= #U_DLY 64'b0;
    else if( fisrt_err_128bit == 1'b1)  
      err_len_128bit <= #U_DLY file_len; 
end

generate
genvar i;
    begin    
        for(i=0;i<48;i=i+1)
            assign errcontext_128bit_t[i] = errcontext_128bit_w[(i*16+15):(i*16)]; 
    end
endgenerate

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0) 
        errcontext_128bit_wr_data <= #U_DLY 'b0; 
    else    
        errcontext_128bit_wr_data <= #U_DLY errcontext_128bit_t[errcontext_128bit_wr_addr_x]; 
end 

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        errcontext_128bit_wr_addr <= #U_DLY 'b0;
    else
        errcontext_128bit_wr_addr <= #U_DLY errcontext_128bit_wr_addr_x; 
end

assign errcontext_128bit_wr_addr_x = (check_st_det == 1'b1) ? 'b0 :
                                   (errcontext_128bit_wr == 1'b1) ? errcontext_128bit_wr_addr + 'b1 : errcontext_128bit_wr_addr;     

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        errcontext_128bit_wr <= #U_DLY 'b0;
    else if( errcontext_128bit_wr == 1'b1 &&  errcontext_128bit_wr_addr == 6'd47 )
        errcontext_128bit_wr <= #U_DLY 'b0;
    else if( fisrt_err_128bit_af == 1'b1 && rx_data_vld == 1'b1)  
        errcontext_128bit_wr <= #U_DLY 1'b1; 
end
 
//---------------------------------------------------------------------------------------------------------------------------------------
//8bit check logic 
//---------------------------------------------------------------------------------------------------------------------------------------
generate
genvar b;
for(b=0;b<DATA_W/8;b=b+1)
begin
datas_check_8bit # 
(
    .U_DLY                      (U_DLY                      )
)u_datas_check_8bit
(
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),
    .pbc_start                  (pbc_start                  ),
    .data_8bit                  (rx_data[(b*8+7):(b*8)]     ),
    .valid                      (rx_data_vld                ),
    .keep                       (rx_keep[b]                 ),
    .error                      (err_flag_x_8bit[b]         )
);
end
endgenerate

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      check_fisrt_err_8bit <= #U_DLY 1'b0;
    else if( check_st_det == 1'b1 )   
      check_fisrt_err_8bit <= #U_DLY 1'b1;
    else if(err_flag_8bit_or == 1'b1 )
      check_fisrt_err_8bit <= #U_DLY 1'b0;
end

assign err_flag_8bit_or =  (|err_flag_x_8bit == 1'b1) ? 1'b1:1'b0;

assign fisrt_err_8bit =  (err_flag_8bit_or == 1'b1) && (check_fisrt_err_8bit == 1'b1) ? 1'b1:1'b0;


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      err_num_8bit <= #U_DLY 16'd0;
    else if( check_st_det == 1'b1 )   
      err_num_8bit <= #U_DLY 16'd0;
    else if( err_num_8bit == 16'hffff)
      err_num_8bit <= #U_DLY 16'hffff;
    else if( err_flag_8bit_or == 1'b1 )
      err_num_8bit <= #U_DLY err_num_8bit + 16'd1;
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      errcontext_8bit_w[511:256] <= #U_DLY 'b0;   
    else if( fisrt_err_8bit == 1'b1 )
      errcontext_8bit_w[511:256] <= #U_DLY rx_data;   
end


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      errcontext_8bit_w[255:0] <= #U_DLY 'b0;    
    else if( fisrt_err_8bit == 1'b1 )    
      errcontext_8bit_w[255:0] <= #U_DLY rx_data_r1; 
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      errcontext_8bit_w[767:512] <= #U_DLY 'b0;
    else if( fisrt_err_8bit_af == 1'b1 && rx_data_vld == 1'b1 )
      errcontext_8bit_w[767:512] <= #U_DLY rx_data;
end



always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      fisrt_err_8bit_af <= #U_DLY 1'b0;
    else if( fisrt_err_8bit_af == 1'b1 && rx_data_vld == 1'b1 )   
      fisrt_err_8bit_af <= #U_DLY 1'b0;
    else if( fisrt_err_8bit == 1'b1 )
      fisrt_err_8bit_af <= #U_DLY 1'b1;      
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      err_len_8bit <= #U_DLY 64'b0;
    else if( fisrt_err_8bit == 1'b1)  
      err_len_8bit <= #U_DLY file_len; 
end

generate                                                                             
genvar c;                                                                            
    begin                                                                            
        for(c=0;c<48;c=c+1)                                                          
            assign errcontext_8bit_t[c] = errcontext_8bit_w[(c*16+15):(c*16)];   
    end                                                                              
endgenerate                                                                          
                                                                                     


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0) 
        errcontext_8bit_wr_data <= #U_DLY 'b0; 
    else    
        errcontext_8bit_wr_data <= #U_DLY errcontext_8bit_t[errcontext_8bit_wr_addr_x]; 
end 

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        errcontext_8bit_wr_addr <= #U_DLY 'b0;
    else
        errcontext_8bit_wr_addr <= #U_DLY errcontext_8bit_wr_addr_x; 
end

assign errcontext_8bit_wr_addr_x = (check_st_det == 1'b1) ? 'b0 :
                                   (errcontext_8bit_wr == 1'b1) ? errcontext_8bit_wr_addr + 'b1 : errcontext_8bit_wr_addr;     

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        errcontext_8bit_wr <= #U_DLY 'b0;
    else if( errcontext_8bit_wr == 1'b1 &&  errcontext_8bit_wr_addr == 6'd47 )
        errcontext_8bit_wr <= #U_DLY 'b0;
    else if( fisrt_err_8bit_af == 1'b1 && rx_data_vld == 1'b1)  
        errcontext_8bit_wr <= #U_DLY 1'b1; 
end




//---------------------------------------------------------------------------------------------------------------------------------------
//prbs31 logic 
//---------------------------------------------------------------------------------------------------------------------------------------

generate
genvar j;
for(j=0;j<DATA_W/8;j=j+1)
begin
    datas_check_prbs31 #(
        .U_DLY                      (U_DLY                      )
    )    
    u_datas_check_prbs31
    (
        .clk                        (clk                        ),
        .rst_n                      (rst_n                      ),
        .pbc_start                  (pbc_start                  ),
        .prbs31                     (rx_data[(j*8+7):(j*8)]     ),
        .valid                      (rx_data_vld                ),
        .keep                       (rx_keep[j]                 ),
        .error                      (err_flag_x_prbs31[j]       )
    );
end
endgenerate
 
/* 
wire    err_test; 
datas_check_prbs31 #(
    .U_DLY                      (U_DLY                      )
)    
u0_datas_check_prbs31
(
    .clk                        (clk                        ),
    .rst_n                      (rst_n                      ),
    .clr                        (check_st_det               ),
    .seed                       (31'h6767_6767                   ),
    .pbc_start                  (pbc_start                  ),
    .prbs31                     (rx_data[7:0]               ),
    .valid                      (rx_data_vld                ),
    .keep                       (rx_keep[0]                 ),
    .error                      (err_test      )
);
*/
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      check_fisrt_err_prbs31 <= #U_DLY 1'b0;
    else if( check_st_det == 1'b1 )   
      check_fisrt_err_prbs31 <= #U_DLY 1'b1;
    else if(err_flag_prbs31_or == 1'b1 )
      check_fisrt_err_prbs31 <= #U_DLY 1'b0;
end

assign err_flag_prbs31_or =  (|err_flag_x_prbs31 == 1'b1) ? 1'b1:1'b0;

assign fisrt_err_prbs31 =  (err_flag_prbs31_or == 1'b1) && (check_fisrt_err_prbs31 == 1'b1) ? 1'b1:1'b0;


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      err_num_prbs31 <= #U_DLY 16'd0;
    else if( check_st_det == 1'b1 )   
      err_num_prbs31 <= #U_DLY 16'd0;
    else if( err_num_prbs31 == 16'hffff )
      err_num_prbs31 <= #U_DLY 16'hffff;
    else if( err_flag_prbs31_or == 1'b1 )
      err_num_prbs31 <= #U_DLY err_num_prbs31 + 16'd1;
end


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      errcontext_prbs31_w[511:256] <= #U_DLY 'b0;   
    else if( fisrt_err_prbs31 == 1'b1 )
      errcontext_prbs31_w[511:256] <= #U_DLY rx_data;   
end


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      errcontext_prbs31_w[255:0] <= #U_DLY 'b0;    
    else if( fisrt_err_prbs31 == 1'b1 )    
      errcontext_prbs31_w[255:0] <= #U_DLY rx_data_r1; 
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      errcontext_prbs31_w[767:512] <= #U_DLY 'b0;
    else if( fisrt_err_prbs31_af == 1'b1 && rx_data_vld == 1'b1 )
      errcontext_prbs31_w[767:512] <= #U_DLY rx_data;
end



always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      fisrt_err_prbs31_af <= #U_DLY 1'b0;
    else if( fisrt_err_prbs31_af == 1'b1 && rx_data_vld == 1'b1 )   
      fisrt_err_prbs31_af <= #U_DLY 1'b0;
    else if( fisrt_err_prbs31 == 1'b1 )
      fisrt_err_prbs31_af <= #U_DLY 1'b1;      
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      err_len_prbs31 <= #U_DLY 64'b0;
    else if( fisrt_err_prbs31 == 1'b1)  
      err_len_prbs31 <= #U_DLY file_len; 
end

generate                                                                             
genvar d;                                                                            
    begin                                                                            
        for(d=0;d<48;d=d+1)                                                          
            assign errcontext_prbs31_t[d] = errcontext_prbs31_w[(d*16+15):(d*16)];   
    end                                                                              
endgenerate                                                                          

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0) 
        errcontext_prbs31_wr_data <= #U_DLY 'b0; 
    else    
        errcontext_prbs31_wr_data <= #U_DLY errcontext_prbs31_t[errcontext_prbs31_wr_addr_x]; 
end 

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        errcontext_prbs31_wr_addr <= #U_DLY 'b0;
    else
        errcontext_prbs31_wr_addr <= #U_DLY errcontext_prbs31_wr_addr_x; 
end

assign errcontext_prbs31_wr_addr_x = (check_st_det == 1'b1) ? 'b0 :
                                   (errcontext_prbs31_wr == 1'b1) ? errcontext_prbs31_wr_addr + 'b1 : errcontext_prbs31_wr_addr;     

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        errcontext_prbs31_wr <= #U_DLY 'b0;
    else if( errcontext_prbs31_wr == 1'b1 &&  errcontext_prbs31_wr_addr == 6'd47 )
        errcontext_prbs31_wr <= #U_DLY 'b0;
    else if( fisrt_err_prbs31_af == 1'b1 && rx_data_vld == 1'b1)  
        errcontext_prbs31_wr <= #U_DLY 1'b1; 
end

//---------------------------------------------------------------------------------------------------------------------------------------
//file length logic 
//---------------------------------------------------------------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        add <= #U_DLY 1'b0;
    else if(rx_data_vld==1'b1)
        add <= #U_DLY 1'b1;
    else
        add <= #U_DLY 1'b0;     
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        addcnt <= #U_DLY 'b0;
    else 
        case(rx_keep)                                                
        32'b0000_0000_0000_0000_0000_0000_0000_0001: addcnt<= #U_DLY 6'd1 ;
        32'b0000_0000_0000_0000_0000_0000_0000_0011: addcnt<= #U_DLY 6'd2 ;
        32'b0000_0000_0000_0000_0000_0000_0000_0111: addcnt<= #U_DLY 6'd3 ;
        32'b0000_0000_0000_0000_0000_0000_0000_1111: addcnt<= #U_DLY 6'd4 ;
        32'b0000_0000_0000_0000_0000_0000_0001_1111: addcnt<= #U_DLY 6'd5 ;
        32'b0000_0000_0000_0000_0000_0000_0011_1111: addcnt<= #U_DLY 6'd6 ;
        32'b0000_0000_0000_0000_0000_0000_0111_1111: addcnt<= #U_DLY 6'd7 ;
        32'b0000_0000_0000_0000_0000_0000_1111_1111: addcnt<= #U_DLY 6'd8 ;
        32'b0000_0000_0000_0000_0000_0001_1111_1111: addcnt<= #U_DLY 6'd9 ;
        32'b0000_0000_0000_0000_0000_0011_1111_1111: addcnt<= #U_DLY 6'd10;
        32'b0000_0000_0000_0000_0000_0111_1111_1111: addcnt<= #U_DLY 6'd11;
        32'b0000_0000_0000_0000_0000_1111_1111_1111: addcnt<= #U_DLY 6'd12;
        32'b0000_0000_0000_0000_0001_1111_1111_1111: addcnt<= #U_DLY 6'd13;
        32'b0000_0000_0000_0000_0011_1111_1111_1111: addcnt<= #U_DLY 6'd14;
        32'b0000_0000_0000_0000_0111_1111_1111_1111: addcnt<= #U_DLY 6'd15;
        32'b0000_0000_0000_0000_1111_1111_1111_1111: addcnt<= #U_DLY 6'd16;
        32'b0000_0000_0000_0001_1111_1111_1111_1111: addcnt<= #U_DLY 6'd17 ; 
        32'b0000_0000_0000_0011_1111_1111_1111_1111: addcnt<= #U_DLY 6'd18 ; 
        32'b0000_0000_0000_0111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd19 ; 
        32'b0000_0000_0000_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd20 ; 
        32'b0000_0000_0001_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd21 ; 
        32'b0000_0000_0011_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd22 ; 
        32'b0000_0000_0111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd23 ; 
        32'b0000_0000_1111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd24; 
        32'b0000_0001_1111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd25; 
        32'b0000_0011_1111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd26; 
        32'b0000_0111_1111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd27; 
        32'b0000_1111_1111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd28; 
        32'b0001_1111_1111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd29; 
        32'b0011_1111_1111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd30; 
        32'b0111_1111_1111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd31; 
        32'b1111_1111_1111_1111_1111_1111_1111_1111: addcnt<= #U_DLY 6'd32;         
        default: addcnt <=#U_DLY 'b0;
        endcase 
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
      file_len <= #U_DLY 'b0;
    else if( check_st_det == 1'b1 )   
      file_len <= #U_DLY 'b0;
    else if( add == 1'b1 )
      file_len <= #U_DLY file_len + addcnt;      
end




endmodule