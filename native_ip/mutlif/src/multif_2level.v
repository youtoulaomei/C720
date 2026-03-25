// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2019/3/6 14:14:21
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Shenrong Co., Ltd.. 
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
module multif_2level#(
parameter                           U_DLY      = 1,
parameter                           USER_NUM   = 4,
parameter                           IN_DATA_W  = 64,
parameter                           INFO_W     = 6,
parameter                           FRAME_LEN  = 2048,
parameter                           FIFO_W     = 512
)
(
input                               clk_w,
input                               clk_r,
input                               rst,
input                               rtc_s_flg,

input  [USER_NUM-1:0]               in_data_sof,
input  [USER_NUM-1:0]               in_data_eof,
input  [USER_NUM-1:0]               in_data_end,
input  [USER_NUM-1:0]               in_data_vld,
input  [USER_NUM*IN_DATA_W-1:0]     in_data,
input  [USER_NUM*INFO_W-1:0]        in_data_info,
input  [USER_NUM*15-1:0]            in_data_len,
output [USER_NUM-1:0]               in_data_pfull,

input                               out_data_rdy,
output reg                          out_data_vld,
output reg                          out_data_sof,
output reg                          out_data_eof,
output reg [511:0]                  out_data,
output reg [INFO_W-1:0]             out_data_info,
output reg [15-1:0]                 out_data_len,
output reg                          out_data_end,

output reg                          fifo_overflow,
output reg                          fifo_prog_empty,
output wire [USER_NUM-1:0]          fifo_empty,
output reg [23:0]                   band
);
// Parameter Define 
localparam                          ICNT   = FIFO_W/IN_DATA_W;
localparam                          ICNT_W = clog2b(ICNT);    
localparam                          FIFO_BW= FIFO_W/8; 
localparam    [7:0]                 PROG_EMPTY_LEVEL = FRAME_LEN/FIFO_BW;
localparam                          USER_NUM_W = clog2b(USER_NUM);

// Register Define 
reg     [FIFO_W*USER_NUM-1:0]       in_data_reg;
reg     [USER_NUM-1:0]              in_data_wr;
reg     [INFO_W*USER_NUM-1:0]       in_data_information;
reg     [USER_NUM-1:0]              in_data_ereg;
reg     [1:0]                       arb_state;
reg     [1:0]                       arb_nextstate;
reg                                 arb_req;
reg     [USER_NUM_W-1:0]            cur_num;
reg     [USER_NUM_W-1:0]            arb_num;
reg                                 arb_selected;
reg                                 frm_state;
reg                                 frm_nextstate;
reg     [1:0]                       s_flg_r;
reg     [9:0]                       kbcnt;
reg     [23:0]                      band_cnt;
reg     [USER_NUM-1:0]              in_data_prog_empty_r1;
reg     [USER_NUM-1:0]              in_data_prog_empty_r2;
reg     [(USER_NUM*15)-1:0]         len_fifo_wdata;
reg     [USER_NUM-1:0]              len_fifo_wr;
reg     [USER_NUM-1:0]              len_fifo_empty_r1;
reg     [USER_NUM-1:0]              len_fifo_empty_r2;
reg     [USER_NUM-1:0]              len_fifo_rd;
reg     [USER_NUM-1:0]              chn_rdy;

//reg     [USER_NUM_W-1:0]            frm_num;

reg     [7:0]                       out_cnt;
reg     [4-1:0]                     fifo_overflow_cnt;
reg     [USER_NUM-1:0]              fifo_overflow_r;  

// Wire Define 
wire    [USER_NUM_W-1:0]            cur_num_x;
wire                                arb_selected_x;
wire    [USER_NUM_W-1:0]            arb_num_x;
wire    [USER_NUM*(FIFO_W+INFO_W)-1:0] in_data_dout;
wire    [USER_NUM-1:0]              in_data_full;
wire    [USER_NUM-1:0]              in_data_prog_empty;
wire    [USER_NUM-1:0]              in_data_rd;
wire                                sel_ack;
wire                                frm_rd;
wire    [USER_NUM*16-1:0]           len_fifo_rdata;
wire    [USER_NUM-1:0]              len_fifo_empty;
wire    [USER_NUM-1:0]              len_fifo_full;
wire    [USER_NUM-1:0]              in_data_wr_en;

//--------------------------------------------------------------
// IN LOGIC
//--------------------------------------------------------------
generate 

if(ICNT<=1)
begin
    always @ (posedge clk_w or posedge rst)begin:IN_DATA_PRO
    integer i;
        if(rst == 1'b1)     
            begin
                in_data_reg <= #U_DLY 'd0;
                in_data_wr  <= #U_DLY 'b0;
            end
        else
            begin
                in_data_reg <= #U_DLY in_data;
                in_data_wr  <= #U_DLY in_data_vld;
            end
    end
end

else
	
begin
	
reg    [ICNT_W*USER_NUM-1:0]        in_data_cnt;
always @ (posedge clk_w or posedge rst)begin:IN_LOG_PRO
integer i;
    if(rst == 1'b1)     
        begin
            in_data_cnt <= #U_DLY 'b0;
            in_data_reg <= #U_DLY 'd0;
            in_data_wr  <= #U_DLY 'b0;
        end        
    else    
        for(i=0;i<USER_NUM;i=i+1)
        begin
            if(in_data_vld[i]==1'b1)
                in_data_cnt[ICNT_W*i+:ICNT_W] <= #U_DLY in_data_cnt[ICNT_W*i+:ICNT_W] + 'b1;

            if(in_data_vld[i]==1'b1)
                //in_data_reg[FIFO_W*i+:FIFO_W] <= #U_DLY {in_data_reg[(FIFO_W*i)+:(FIFO_W-IN_DATA_W)],in_data[IN_DATA_W*i+:IN_DATA_W]};
                in_data_reg[FIFO_W*i+:FIFO_W] <= #U_DLY {in_data[IN_DATA_W*i+:IN_DATA_W],in_data_reg[(FIFO_W*i+IN_DATA_W)+:(FIFO_W-IN_DATA_W)]};
            
            if(in_data_vld[i]==1'b1 && (&in_data_cnt[ICNT_W*i+:ICNT_W]==1'b1))
                in_data_wr[i] <= #U_DLY 1'b1;
            else
                in_data_wr[i] <= #U_DLY 1'b0;
        end
end

end
endgenerate

always @ (posedge clk_w or posedge rst)begin:INFO_LOG_PRO
integer i;
    if(rst == 1'b1)     
        begin
            in_data_information <= #U_DLY 'b0;
            in_data_ereg <= #U_DLY 'b0;
            len_fifo_wdata <= #U_DLY 'b0;
            len_fifo_wr <= #U_DLY 'b0;
        end        
    else
        begin    
        for(i=0;i<USER_NUM;i=i+1)
            begin
                if(in_data_sof[i]==1'b1)
                    in_data_information[INFO_W*i+:INFO_W] <= #U_DLY in_data_info[INFO_W*i+:INFO_W];

                if(in_data_eof[i]==1'b1 && in_data_end[i]==1'b1)
                    in_data_ereg[i] <= #U_DLY 1'b1;
                else
                    in_data_ereg[i] <= #U_DLY 1'b0;

                if(in_data_eof[i]==1'b1)
                    len_fifo_wdata[15*i+:15] <= #U_DLY in_data_len[15*i+:15];

                if(in_data_eof[i]==1'b1)
                    len_fifo_wr[i] <= #U_DLY 1'b1;
                else
                    len_fifo_wr[i] <= #U_DLY 1'b0;

            end
        end
end

genvar k;
for(k=0;k<USER_NUM;k=k+1)
begin
assign in_data_wr_en[k] = (in_data_wr[k]==1'b1) && (in_data_full[k]==1'b0) ? 1'b1:1'b0;
end
//----------------------------------------------------------------
//u_fifo
//----------------------------------------------------------------
genvar j;
generate 
for(j=0;j<USER_NUM;j=j+1)
begin
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (FIFO_W+INFO_W              ),
    .DATA_DEEPTH                (256                        ),
    .ADDR_WIDTH                 (8                          ),
    .RAM_STYLE                  ("BRAM"                    )
)u_indata_fifo
(
    .wr_clk                     (clk_w                      ),
    .wr_rst_n                   (~rst                       ),
    .rd_clk                     (clk_r                      ),
    .rd_rst_n                   (~rst                       ),
    .din                        ({in_data_information[INFO_W*j+:INFO_W],in_data_reg[FIFO_W*j+:FIFO_W]}),
    .wr_en                      (in_data_wr_en[j]           ),
    .rd_en                      (in_data_rd[j]              ),
    .dout                       (in_data_dout[(FIFO_W+INFO_W)*j+:(FIFO_W+INFO_W)]),
    .full                       (in_data_full[j]            ),
    .prog_full                  (in_data_pfull[j]           ),
    .empty                      (fifo_empty[j]              ),
    .prog_empty                 (in_data_prog_empty[j]      ),
    .prog_full_thresh           (8'd240                     ),
    .prog_empty_thresh          (PROG_EMPTY_LEVEL           ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )

);



asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (16                         ),
    .DATA_DEEPTH                (16                         ),
    .ADDR_WIDTH                 (4                          ),
    .RAM_STYLE                  ("BRAM"                     )
)u_len_fifo
(
    .wr_clk                     (clk_w                      ),
    .wr_rst_n                   (~rst                       ),
    .rd_clk                     (clk_r                      ),
    .rd_rst_n                   (~rst                       ),
    .din                        ({in_data_ereg[j],len_fifo_wdata[15*j+:15]}   ),
    .wr_en                      (len_fifo_wr[j]             ),
    .rd_en                      (len_fifo_rd[j]             ),
    .dout                       (len_fifo_rdata[16*j+:16]   ),
    .full                       (len_fifo_full[j]           ),
    .prog_full                  (                           ),
    .empty                      (len_fifo_empty[j]          ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (4'd12                      ),
    .prog_empty_thresh          (4'd2                       ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )
);


end
endgenerate

always @ (posedge clk_w or posedge rst)begin:OVERFLOW_LOG_PRO
integer i;
    if(rst == 1'b1)     
        begin
            fifo_overflow_r <= #U_DLY 'b0;
            fifo_overflow_cnt <= #U_DLY 'b0;
            fifo_overflow <= #U_DLY 1'b0;
        end        
    else    
        begin
            for(i=0;i<USER_NUM;i=i+1)
            begin
                if((in_data_full[i]==1'b1 && in_data_wr[i]==1'b1) || (len_fifo_wr[i]==1'b1 &&len_fifo_full[i]==1'b1))
                    fifo_overflow_r[i] <= #U_DLY 1'b1;
                else
                    fifo_overflow_r[i] <= #U_DLY 1'b0;
            end
                    
            if(fifo_overflow_cnt=='d15)    
                fifo_overflow_cnt <= #U_DLY 'd0;
            else if((|fifo_overflow_r==1'b1) || (fifo_overflow_cnt>'d0))
                fifo_overflow_cnt <= #U_DLY fifo_overflow_cnt +'d1;
            
            if(fifo_overflow_cnt=='d15)
                fifo_overflow <= #U_DLY 1'b0;
            else if(|fifo_overflow_r==1'b1)
                fifo_overflow <= #U_DLY 1'b1;
        end
end

always @ (posedge clk_r or posedge rst)begin
    if(rst == 1'b1)     
        fifo_prog_empty <= #U_DLY 1'b1;        
    else if(&in_data_prog_empty_r2==1'b0)   
        fifo_prog_empty <= #U_DLY 1'b0;
    else
        fifo_prog_empty <= #U_DLY 1'b1;
end

//-----------------------------------------------------------------------------
//arb_state
//-----------------------------------------------------------------------------   
localparam                           IDLE = 2'd0;
localparam                           ARB  = 2'd1;
localparam                           WAIT = 2'd2;

always @ (posedge clk_r or posedge rst)begin
    if(rst == 1'b1)     
        begin
            in_data_prog_empty_r1 <= #U_DLY {(USER_NUM){1'b1}};
            in_data_prog_empty_r2 <= #U_DLY {(USER_NUM){1'b1}};
            len_fifo_empty_r1 <= #U_DLY  {(USER_NUM){1'b1}};
            len_fifo_empty_r2 <= #U_DLY  {(USER_NUM){1'b1}};
        end       
    else    
        begin
            in_data_prog_empty_r1 <= #U_DLY in_data_prog_empty;
            in_data_prog_empty_r2 <= #U_DLY in_data_prog_empty_r1;
            len_fifo_empty_r1 <= #U_DLY len_fifo_empty;
            len_fifo_empty_r2 <= #U_DLY len_fifo_empty_r1;
        end       
end


always @ (posedge clk_r or posedge rst)
begin
    if(rst == 1'b1)     
        arb_state <= #U_DLY IDLE;
    else    
        arb_state <= #U_DLY arb_nextstate;
end


always @ ( * )
begin
    case(arb_state)
        IDLE:
            begin
                if(arb_req == 1'b1)
                    arb_nextstate = ARB;
                else
                    arb_nextstate = IDLE;
            end
        ARB:
            begin
                if(arb_selected == 1'b1)
                    begin
                        if(sel_ack == 1'b1)
                            arb_nextstate = WAIT;
                        else
                            arb_nextstate = ARB;
                    end
                else
                    arb_nextstate = ARB;
            end
            
        WAIT:
            begin
                    arb_nextstate = IDLE;
            end  
        default:arb_nextstate = IDLE;     
    endcase
end       


assign cur_num_x =((arb_state==ARB) && (arb_selected == 1'b0) && (cur_num==(USER_NUM-1))) ? {(USER_NUM_W){1'b0}} :
                    ((arb_state==WAIT)&& (cur_num==(USER_NUM-1))) ?  {(USER_NUM_W){1'b0}} :
                    ((arb_state==ARB) && (arb_selected == 1'b0))  ?  cur_num +  {{(USER_NUM_W-1){1'b0}},1'b1} :
                    (arb_state==WAIT) ?  cur_num +  {{(USER_NUM_W-1){1'b0}},1'b1} : cur_num ;

assign arb_selected_x = (sel_ack == 1'b1) ? 1'b0 :
                        ((arb_nextstate == ARB)&&(in_data_prog_empty_r2[cur_num_x] == 1'b0)) ? 1'b1 : arb_selected;

assign arb_num_x = (arb_nextstate == ARB)&&(in_data_prog_empty_r2[cur_num_x] == 1'b0) ? cur_num_x : arb_num;     

always @ (posedge clk_r or posedge rst)begin:CHNRDY_PRO
integer i;
    if(rst == 1'b1)     
        chn_rdy <= #U_DLY 'b0;
    else   
        begin
            for(i=0;i<USER_NUM;i=i+1)
            begin
                if(in_data_prog_empty_r2[i]==1'b0 && len_fifo_empty_r2[i]==1'b0)
                    chn_rdy[i] <= #U_DLY 1'b1;
                else
                    chn_rdy[i] <= #U_DLY 1'b0;
            end
        end 
end

always @ (posedge clk_r or posedge rst)
begin
    if(rst == 1'b1)     
        arb_req <= #U_DLY 1'b0;        
    else if(|chn_rdy==1'b1)
        arb_req <= #U_DLY 1'b1;
    else
        arb_req <= #U_DLY 1'b0;
end

always @ (posedge clk_r or posedge rst)
begin
    if(rst == 1'b1)      
        begin
            cur_num      <= #U_DLY {(USER_NUM_W){1'b0}};
            arb_num      <= #U_DLY {(USER_NUM_W){1'b0}}; 
            arb_selected <= #U_DLY 1'b0;
        end        
    else    
        begin
            cur_num      <= #U_DLY cur_num_x;
            arb_num      <= #U_DLY arb_num_x; 
            arb_selected <= #U_DLY arb_selected_x;
        end      
end


//-----------------------------------------------------------------------------
//frm_state
//-----------------------------------------------------------------------------   
localparam                           SEND_FRM  = 2'd1;

always @ (posedge clk_r or posedge rst)
begin
    if(rst == 1'b1)        
        frm_state <= #U_DLY IDLE;      
    else    
        frm_state <= #U_DLY frm_nextstate;
end

always @ ( * )
begin
    case(frm_state)
        IDLE:
            begin
                if(arb_selected == 1'b1)
                    frm_nextstate = SEND_FRM;
                else
                    frm_nextstate = IDLE;
            end

        SEND_FRM:
            begin
                if(out_data_vld == 1'b1 && out_data_eof==1'b1 && out_data_rdy==1'b1) 
                    frm_nextstate = IDLE;
                else
                    frm_nextstate = SEND_FRM;
            end

        default:
            frm_nextstate = IDLE;
    endcase
end



// logic
//always @ (posedge clk_r or posedge rst)
//begin
//    if(rst == 1'b1)        
//        sel_ack <= #U_DLY 1'b0;        
//    else if(frm_state==IDLE && frm_nextstate==SEND_FRM)
//        sel_ack <= #U_DLY 1'b1;
//    else
//        sel_ack <= #U_DLY 1'b0;   
//end
assign  sel_ack =(out_data_vld == 1'b1 && out_data_eof==1'b1 && out_data_rdy==1'b1)? 1'b1 : 1'b0;

always @ (posedge clk_r or posedge rst)begin:OUT_LOC_PRO
integer i;
    if(rst == 1'b1)     
        begin
            //frm_num       <= #U_DLY 'b0;
            out_cnt       <= #U_DLY 'd0;
            out_data_vld  <= #U_DLY 'd0;
            out_data_sof  <= #U_DLY 1'b0;
            out_data_eof  <= #U_DLY 1'b0;
            out_data_end  <= #U_DLY 1'b0;
            out_data_len <= #U_DLY 'b0;
            out_data_info <= #U_DLY 'b0;
            out_data      <= #U_DLY 'b0;
            len_fifo_rd <= #U_DLY 1'b0;
        end        
    else    
        begin
            //if(frm_state==IDLE && arb_selected==1'b1)
            //    frm_num <= #U_DLY arb_num;

            if(out_data_vld==1'b1 && out_data_eof==1'b1 && out_data_rdy==1'b1)
                out_data_vld <= #U_DLY 1'b0;
            else if(frm_state==IDLE && frm_nextstate==SEND_FRM)
                out_data_vld <= #U_DLY 1'b1;

            if(out_data_vld==1'b1 && out_data_sof==1'b1 && out_data_rdy==1'b1)
                out_data_sof <= #U_DLY 1'b0;
            else if(frm_state==IDLE && frm_nextstate==SEND_FRM)
                out_data_sof <= #U_DLY 1'b1;


            if(out_data_vld==1'b1 && out_data_eof==1'b1 && out_data_rdy==1'b1)
                out_data_eof <= #U_DLY 1'b0;
            else if(out_data_vld==1'b1 && out_data_rdy==1'b1 && out_cnt== PROG_EMPTY_LEVEL-2)
                out_data_eof <= #U_DLY 1'b1;

            if(frm_rd==1'b1)
                out_data <= #U_DLY  in_data_dout[(FIFO_W+INFO_W)*arb_num+:FIFO_W];

            if(frm_state==IDLE && frm_nextstate==SEND_FRM)
                out_data_info <= #U_DLY in_data_dout[((FIFO_W+INFO_W)*arb_num+FIFO_W)+:INFO_W];

            if(out_data_vld==1'b1 && out_data_eof==1'b1 && out_data_rdy==1'b1 && out_data_end==1'b1)
                out_data_end <= #U_DLY 1'b0;
            else if(frm_state==IDLE && frm_nextstate==SEND_FRM)
                out_data_end <= #U_DLY len_fifo_rdata[16*arb_num+15];
                
            if(out_data_vld==1'b1 && out_data_rdy==1'b1 && out_data_eof==1'b1)    
                out_cnt <= #U_DLY 'b0;
            else if(out_data_vld==1'b1 && out_data_rdy==1'b1)
                out_cnt <= #U_DLY out_cnt + 'b1;
            
            if(frm_state==IDLE && frm_nextstate==SEND_FRM) 
                out_data_len <= #U_DLY len_fifo_rdata[16*arb_num+:15];
            
            for(i=0;i<USER_NUM;i=i+1)
            begin 
                if(frm_state==IDLE && frm_nextstate==SEND_FRM && arb_num==i)
                    len_fifo_rd[i] <= #U_DLY 1'b1;
                else
                    len_fifo_rd[i] <= #U_DLY 1'b0;
            end
        end

end

assign frm_rd = (frm_state==IDLE) && (frm_nextstate==SEND_FRM) ? 1'b1 :
                    (out_data_vld==1'b1 &&  out_data_eof==1'b0 && out_data_rdy==1'b1) ? 1'b1 :1'b0;
genvar m;
generate
begin
for(m=0;m<USER_NUM;m=m+1)
assign in_data_rd[m] = (frm_rd==1'b1) && (m==arb_num) ? 1'b1:1'b0;
end
endgenerate


//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------
always @ (posedge clk_r or posedge rst)begin
    if(rst == 1'b1)  
        begin   
            s_flg_r  <= #U_DLY 2'b0;
            band     <= #U_DLY 'b0; 
            kbcnt    <= #U_DLY 'b0; 
            band_cnt <= #U_DLY 'b0; 

        end        
    else  
        begin  
            s_flg_r <= #U_DLY {s_flg_r[0],rtc_s_flg};
            
            if(out_data_vld==1'b1 && out_data_rdy==1'b1 && kbcnt>='d1024-FIFO_BW)
                kbcnt <= #U_DLY 'd0;
            else if(out_data_vld==1'b1 && out_data_rdy==1'b1)
                kbcnt <= #U_DLY kbcnt + FIFO_BW;   

            if(s_flg_r[0]^s_flg_r[1])
                band_cnt <= #U_DLY 'b0;
            else if(out_data_vld==1'b1 && out_data_rdy==1'b1 && kbcnt>='d1024-FIFO_BW)
                band_cnt <= #U_DLY band_cnt + 'd1;   
            
            if(s_flg_r[0] ^ s_flg_r[1])
                band <= #U_DLY band_cnt;   

        end
end



function integer clog2b;
input integer value;
integer tmp;
begin
    tmp = value;
    if(tmp<=1)
        clog2b = 1;
    else
    begin
        tmp = tmp-1;
        for (clog2b=0; tmp>0; clog2b=clog2b+1)
            tmp = tmp>>1;
    end
end
endfunction

endmodule
