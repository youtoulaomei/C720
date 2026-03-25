// *********************************************************************************/
// Project Name :
// Author       : Dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2018/3/16 10:47:25
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
`timescale 1 ns / 1 ns
module lvds_7k_pro # (
parameter                           U_DLY       = 1,
parameter                           LVDS_WIDTH  = 8,
parameter                           FIXED_DELAY_PARAM = 5'd0
)
(
input                               clk_200m,
input                               clk_100m,
input                               rst,

input  [LVDS_WIDTH-1:0]             lvds_data_p,
input  [LVDS_WIDTH-1:0]             lvds_data_n,   

input                               st_clr,
input  [15:0]                       test_0pattern,
input  [15:0]                       test_1pattern,
input  [15:0]                       test_2pattern,
output reg                          pns_rcvd,
input                               io_cfg,
input       [8:0]                   dly_value,
input                               dly_inc,
input                               sign_mod,

input                               lvds_clk,
//(* IOB="true" *)
output reg  [LVDS_WIDTH*2-1:0]      lvds_odata,
output reg  [LVDS_WIDTH*9-1:0]      idelay_value,
input                               sys_ms_flg

);
// Parameter Define 
localparam                          IDLE       =2'd0;
localparam                          IO_CFG     =2'd1;
localparam                          IO_CFG_DONE=2'd2;
// Register Define 
reg     [8:0]                       dly_value_0dly;
reg     [8:0]                       dly_value_1dly;
reg     [3:0]                       st_clr_r;
reg     [1:0]                       pns_cnt;
reg     [3:0]                       pns_rcvd_cnt;
reg     [2:0]                       au_ld_dly;
reg     [1:0]                       iodelay_state;
reg     [1:0]                       iodelay_nextstate;
reg     [10:0]                      io_indcnt;
reg                                 au_ld;
reg                                 iodelay_cfg_done;
reg     [2:0]                       sys_ms_flg_r;
reg     [10:0]                      idle_tcnt;
reg                                 idle_done;
reg     [3:0]                       io_cfg_r;
//reg     [LVDS_WIDTH-1:0]            idelay_ld/* synthesis syn_preserve = 1 */;
//reg     [LVDS_WIDTH-1:0]            idelay_ce/* synthesis syn_preserve = 1 */;
//reg     [LVDS_WIDTH-1:0]            idelay_inc/* synthesis syn_preserve = 1 */; 
reg     [LVDS_WIDTH-1:0]            idelay_ld;
reg     [LVDS_WIDTH-1:0]            idelay_ce;
reg     [LVDS_WIDTH-1:0]            idelay_inc; 
reg     [2:0]                       dly_inc_r;
reg     [15:0]                      test_0pattern_1r;
reg     [15:0]                      test_0pattern_2r;
reg     [15:0]                      test_1pattern_1r;
reg     [15:0]                      test_1pattern_2r;
reg     [15:0]                      test_2pattern_1r;
reg     [15:0]                      test_2pattern_2r;
reg     [2:0]                       sign_mod_r;


// Wire Define 
wire    [LVDS_WIDTH-1:0]            lvds_rx_line;
wire    [2*LVDS_WIDTH-1:0]          lvds_q;
wire    [LVDS_WIDTH-1:0]            lvds_rx_idly;
wire    [LVDS_WIDTH*5-1:0]          cntvalueout;
wire                                idelay_rdy;




//--------------------------------------------------------------------
//IDELAYCTRL_inst
//--------------------------------------------------------------------
(* IODELAY_GROUP = "IODELAY_ADC" *)
IDELAYCTRL/* #(
.SIM_DEVICE("ULTRASCALE")                               // Set the device version (7SERIES, ULTRASCALE)
 )*/IDELAYCTRL_inst(
.RDY                     (idelay_rdy                 ), // 1-bit output: Ready output
.REFCLK                  (clk_200m                   ), // 1-bit input: Reference clock input
.RST                     (rst                        )  // 1-bit input: Active high reset input. Asynchronous assert, synchronous deassert to                      // REFCLK.
);     



//--------------------------------------------------------------------
//IDELAY2
//--------------------------------------------------------------------
genvar i;
generate
for(i=0;i<LVDS_WIDTH;i=i+1)
begin
IBUFDS #(
    .DIFF_TERM                  ("TRUE"                     ),
    .IBUF_LOW_PWR               ("TRUE"                     ),
    .IOSTANDARD                 ("DEFAULT"                  )
   ) 
IBUFDS_inst (
    .O                          (lvds_rx_line[i]            ),
    .I                          (lvds_data_p[i]             ),
    .IB                         (lvds_data_n[i]             )
);

(* IODELAY_GROUP = "IODELAY_ADC" *)
IDELAYE2 #(
    .IDELAY_TYPE        ("VAR_LOAD"                ), //string:delay type:FIXED,VAR_LOAD,VARIABLE,VAR_LOAD_PIPE
    .DELAY_SRC          ("IDATAIN"                 ), //string:chain input select signal
    .IDELAY_VALUE       (FIXED_DELAY_PARAM         ), //FIXED mode delay value,ignored when other delay type
    .HIGH_PERFORMANCE_MODE ("TRUE"                 ), //power consumption 
    .SIGNAL_PATTERN     ("DATA"                    ), //input pattern:DATA OR CLOCK
    .REFCLK_FREQUENCY   ( 200                      ),  //reference clock frequency
    .CINVCTRL_SEL       ("FALSE"                   ), //enable pipeline 
    .PIPE_SEL           ("FALSE"                   )  //select pipeline mode
 ) IDELAYE2_inst (
    .C                  (clk_200m                 ),       // 1-bit input: clock input
    .REGRST             (rst                      ),       // 1-bit input: reset for register pipeline 
    .LD                 (idelay_ld[i]             ),       // 1-bit input: load delay vaule
    .CE                 (idelay_ce[i]             ),       // 1-bit input: enable incement/decrement function
    .INC                (idelay_inc[i]            ),       // 1-bit input: incement/decrement number of taps value
    .CINVCTRL           (1'b0                     ),       // 1-bit input: invert clock polarity
    .CNTVALUEIN         (dly_value_1dly[4:0]      ),       // 5-bit input: load delay value
    .IDATAIN            (lvds_rx_line[i]          ),       // 1-bit input: from IBUF
    .DATAIN             (1'b0                     ),       // 1-bit input: from fpga logic
    .LDPIPEEN           (1'b0                     ),       // 1-bit input: enable pipeline
    .DATAOUT            (lvds_rx_idly[i]          ),
    .CNTVALUEOUT        (cntvalueout[i*5+:5]      )        // 5-bit output: monitor load delay value
 );


IDDR #(
    .DDR_CLK_EDGE       ("SAME_EDGE_PIPELINED"   ),       // IDDRE1 mode (OPPOSITE_EDGE, SAME_EDGE, SAME_EDGE_PIPELINED)
    .INIT_Q1            (1'b0                   ),          // Optional inversion for CB
    .INIT_Q2            (1'b0                   ),          // Optional inversion for C
    .SRTYPE             ("ASYNC"                )           // RESET TYPE : AYSNC OR SYNC               
 )
 IDDR_inst (
    .Q1                 (lvds_q[2*i+1]          ),       // 1-bit output: Registered parallel output 1
    .Q2                 (lvds_q[2*i]            ),       // 1-bit output: Registered parallel output 2
    .C                  (lvds_clk               ),       // 1-bit input: High-speed clock
    .CE                 (1'b1                   ),       // 1-bit input: clock enable
    .D                  (lvds_rx_idly[i]        ),       // 1-bit input: Serial Data Input
    .R                  (1'b0                   ),        // 1-bit input: Active High Async Reset
    .S                  (1'b0                   )
 );
end
endgenerate

//--------------------------------------------------------------------
//lvds_odata
//--------------------------------------------------------------------
always @ (posedge lvds_clk or posedge rst)begin
    if(rst == 1'b1)
        begin     
            lvds_odata <= #U_DLY 'b0;
            sign_mod_r <= #U_DLY 'b0;
        end      
    else 
        begin
            if(sign_mod_r[2]==1'b1)   
                lvds_odata <= #U_DLY {~lvds_q[15],lvds_q[14:2],lvds_q[1],lvds_q[0]};
            else 
                lvds_odata <= #U_DLY {lvds_q[15],lvds_q[14:2],lvds_q[1],lvds_q[0]};
            
            sign_mod_r <= #U_DLY {sign_mod_r[1:0],sign_mod};
        end 
end

always @ (posedge lvds_clk or posedge rst)begin
    if(rst == 1'b1)    
        begin    
            st_clr_r <= #U_DLY 'b0;
            test_0pattern_1r <= #U_DLY 'b0;
            test_0pattern_2r <= #U_DLY 'b0;
            test_1pattern_1r <= #U_DLY 'b0;
            test_1pattern_2r <= #U_DLY 'b0;
            test_2pattern_1r <= #U_DLY 'b0;
            test_2pattern_2r <= #U_DLY 'b0;
        end        
    else 
        begin   
            st_clr_r <= #U_DLY {st_clr_r[2:0],st_clr};
            test_0pattern_1r <= #U_DLY test_0pattern;
            test_0pattern_2r <= #U_DLY test_0pattern_1r;
            test_1pattern_1r <= #U_DLY test_1pattern;
            test_1pattern_2r <= #U_DLY test_1pattern_1r;
            test_2pattern_1r <= #U_DLY test_2pattern;
            test_2pattern_2r <= #U_DLY test_2pattern_1r;
        end
end

always @ (posedge lvds_clk or posedge rst)begin
    if(rst == 1'b1) 
        pns_cnt <= #U_DLY 'b0;
    else if(st_clr_r[2]==1'b1 &&  st_clr_r[3] == 1'b0)
        pns_cnt <= #U_DLY 'b0;       
    //else if((lvds_odata==16'h87BE && pns_cnt=='d0)
    //     || (lvds_odata==16'hAE64 && pns_cnt=='d1)
    //     || (lvds_odata==16'h929D && pns_cnt=='d2))
    else if((lvds_odata==test_0pattern_2r && pns_cnt=='d0)
         || (lvds_odata==test_1pattern_2r && pns_cnt=='d1)
         || (lvds_odata==test_2pattern_2r && pns_cnt=='d2))
        pns_cnt <= #U_DLY pns_cnt + 'b1;
    else
        pns_cnt <= #U_DLY 'b0;    
end

always @ (posedge lvds_clk or posedge rst)begin
    if(rst == 1'b1)      
        pns_rcvd_cnt <= #U_DLY 'b0;        
    else if(st_clr_r[2]==1'b1 &&  st_clr_r[3] == 1'b0)
        pns_rcvd_cnt <= #U_DLY 'b0;
    else if(pns_rcvd_cnt>='d10)
        pns_rcvd_cnt <= #U_DLY pns_rcvd_cnt;    
    else if(pns_cnt=='d3)
        pns_rcvd_cnt <= #U_DLY pns_rcvd_cnt + 'b1;   
end

always @ (posedge lvds_clk or posedge rst)begin
    if(rst == 1'b1)         
        pns_rcvd <= #U_DLY 1'b0;        
    else if(st_clr_r[2]==1'b1 &&  st_clr_r[3] == 1'b0)   
        pns_rcvd <= #U_DLY 1'b0;
    else if(pns_rcvd_cnt>='d10)
        pns_rcvd <= #U_DLY 1'b1;   
end



always @ (posedge clk_200m or posedge rst) begin:DLY_LOAD_PRO
integer j;
    if(rst == 1'b1)     
        begin
            dly_value_0dly <= 'd0;
            dly_value_1dly <= 'd0;
            au_ld_dly <= #U_DLY 'b0;
            idelay_ld <= #U_DLY 'b0;
            idelay_ce <= #U_DLY 'b0;
            idelay_inc <= #U_DLY 'b0;
            dly_inc_r <= #U_DLY 'b0;
            idelay_value <= #U_DLY 'b0;
        end
    else    
        begin
            dly_value_0dly <= #U_DLY dly_value;
            dly_value_1dly <= #U_DLY dly_value_0dly;
            au_ld_dly <= #U_DLY {au_ld_dly[1:0],au_ld};
            dly_inc_r <= #U_DLY {dly_inc_r[1:0],dly_inc};

            for(j=0;j<LVDS_WIDTH;j=j+1)
            begin
                if(au_ld_dly[1]==1'b1 && au_ld_dly[2]==1'b0)
                    idelay_ld[j] <= #U_DLY 1'b1;
                else
                    idelay_ld[j] <= #U_DLY 1'b0;

                if(dly_inc_r[1]==1'b1 && dly_inc_r[2]==1'b0)
                    idelay_ce[j] <= #U_DLY 1'b1;
                else
                    idelay_ce[j] <= #U_DLY 1'b0;
                
                if(dly_inc_r[1]==1'b1 && dly_inc_r[2]==1'b0)
                    idelay_inc[j] <= #U_DLY 1'b1;
                else
                    idelay_inc[j] <= #U_DLY 1'b0;

                idelay_value[9*j+:9] <= #U_DLY {4'b0,cntvalueout[5*j+:5]};

            end


        end
end





always @ (posedge clk_100m or posedge rst)begin
    if(rst == 1'b1)     
        iodelay_state <= #U_DLY IDLE;
    else    
        iodelay_state <= #U_DLY iodelay_nextstate;
end

always @ (*)begin
    case(iodelay_state)
        IDLE:
        begin
           if(idle_done==1'b1)
                iodelay_nextstate=IO_CFG;
           else
                iodelay_nextstate=IDLE;
        end

        IO_CFG:
        begin
            if(iodelay_cfg_done==1'b1)
                iodelay_nextstate=IO_CFG_DONE;
            else
                iodelay_nextstate=IO_CFG;
        end

        IO_CFG_DONE:
            if(io_cfg_r[2]==1'b1 &&  io_cfg_r[3] == 1'b0)
                iodelay_nextstate=IDLE;
            else
                iodelay_nextstate=IO_CFG_DONE;
        default:
            iodelay_nextstate=IDLE;
    endcase
end


always @ (posedge clk_100m or posedge rst)begin
    if(rst == 1'b1)      
        begin
            io_indcnt <= #U_DLY 'd0;
            au_ld <= #U_DLY 1'b0;
            sys_ms_flg_r <= #U_DLY 'd0;
            iodelay_cfg_done <= #U_DLY 1'b0;
            idle_tcnt <= #U_DLY 'd0;
            idle_done <= #U_DLY 1'b0;
            io_cfg_r <= #U_DLY 'b0;
        end       
    else   
        begin
            if(iodelay_state==IO_CFG) 
                io_indcnt <= #U_DLY io_indcnt + 'd1;
            else
                io_indcnt <= #U_DLY 'd0;
  
             if(iodelay_cfg_done==1'b1)
                iodelay_cfg_done <= #U_DLY 1'b0;
            else if(io_indcnt=='d1000)
                iodelay_cfg_done <= #U_DLY 1'b1;


            if(io_indcnt>='d30 && io_indcnt<='d38)
                au_ld <= #U_DLY 1'b1;
            else
                au_ld <= #U_DLY 1'b0;
            
            sys_ms_flg_r <= #U_DLY {sys_ms_flg_r[1:0],sys_ms_flg};
            
            if(idle_done==1'b1)
                idle_tcnt <= #U_DLY 'd0;
            else if(iodelay_state==IDLE && sys_ms_flg_r[1]==1'b1 && sys_ms_flg_r[2]==1'b0)
                idle_tcnt<= #U_DLY idle_tcnt + 'd1;
            
            if(idle_tcnt=='d200)
                idle_done <= #U_DLY 1'b1;
            else
                idle_done <= #U_DLY 1'b0;

             io_cfg_r <= #U_DLY {io_cfg_r[2:0],io_cfg};
        end 

end







endmodule
