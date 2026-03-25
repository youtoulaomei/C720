/*******************************************************************************\
copyright @2023,fudan Company,ALL right reserved
Department: GKK
Author: chenjianwu
Project name:
Product ver:
Module name:
Module called:
called by:
Tools version:
Description:

Revision History:

       Date      by        ver.         prj.         SYED       description
--------------------------------------------------------------------------------
2022-10-25     chenjianwu  1.0                                  Initial
        
\*******************************************************************************/

`timescale 1ns / 1ps

// synthesis translate_off
//`define SIM_EN
// synthesis translate_on

module nor_bpi_port #
(
    parameter          CYCLE_ERASE      = 7'd102, //the number of the 10s cycle,    max time of the erase the whole flash time
    parameter          CYCLE_ERASE_K    = 8'd60,  //the number of the 167ms cycle,  max time of the erase flash 64k or 32k time 
    parameter          CYCLE_WR         = 7'd117  //the number of the 1.28us cycle, max time of the write the flash page time
)
(
    //reset and clock
    input              iglobal_rst        ,
    input              iglobal_clk        ,
    //configure the command
    input       [2 :0] iconfig_cmd        ,  //000:not configure, 001:erase the all flash, 010:erase the sector, 011:write the flash(one word), 
                                             //100:read the flash(one word), 101:read the flash id, 110:soft reset the flash, 111:Continuity check
    //the operate address
    input       [26:0] iuser_adr          ,
    //write data
    output reg         owr_flash_rd       ,
    input       [15:0] iwr_flash_dout     ,
    //read data
    input       [23:0] ird_flash_num      ,  //The maximum number of data read at a time is 2^16 = 65536-1 = 65535
    output reg         ord_flash_wr       ,
    output reg  [15:0] ord_flash_din      ,
    //read id
    output reg         ord_id_wr          ,
    //ready
    output reg         oflash_rdy         ,
    //configure the command
    input       [11:0] icmd_1adr          ,  //the first  command address
    input       [7 :0] icmd_1din          ,  //the first  command data
    input       [11:0] icmd_2adr          ,  //the second command address
    input       [7 :0] icmd_2din          ,  //the second command data
    input       [11:0] icmd_3adr          ,
    input       [7 :0] icmd_3din          ,
    input       [11:0] icmd_4adr          ,
    input       [7 :0] icmd_4din          ,
    input       [11:0] icmd_5adr          ,
    input       [7 :0] icmd_5din          ,
    input       [11:0] icmd_6adr          ,
    input       [7 :0] icmd_6din          ,
    input       [7 :0] icmd_rst           ,
    input       [26:0] ichk2_1adr         ,
    input       [15:0] ichk2_1din         ,
    input       [26:0] ichk2_2adr         ,
    input       [15:0] ichk2_2din         ,
    input       [26:0] ichk2_3adr         ,
    input       [15:0] ichk2_3din         ,
    //abnormal
    output reg         oexceed_max_time   ,
    output reg         oflag_wr_chk_err   ,
    //flash port
    output reg         oflash_ce_n        ,
    output reg         oflash_oe_n        ,
    output reg         oflash_we_n        ,
    input              flash_ry_by_i      ,
    inout       [15:0] ioflash_dq         ,
    output reg  [15:0] flash_dq_out,
    output reg  [26:0] oflash_adr         
);
/******************************************************************************\
                                    parameters
\******************************************************************************/
parameter   U_DLY               = 1'b1;
`ifdef SIM_EN
localparam   SIM_ON             = 1;
`else
localparam   SIM_ON             = 0;
`endif

localparam  FSM_IDLE            = 3'd0;
localparam  FSM_CMD             = 3'd1;
localparam  FSM_WAIT            = 3'd2;
localparam  FSM_DQ              = 3'd3;
localparam  FSM_RD              = 3'd4;
localparam  FSM_RST             = 3'd5;
localparam  FSM_CHK             = 3'd6;
localparam  FSM_WR_CHK          = 3'd7;

localparam  NUM_ERASE_CMD       = 3'd6;
localparam  NUM_WR_CMD          = 3'd4;
localparam  NUM_ID_CMD          = 3'd3;
localparam  NUM_CHK_CMD         = 3'd2;
localparam  NUM_RST_CMD         = 3'd1;
localparam  NUM_CHK_2CMD        = 3'd3;
localparam  NUM_CMD_BEAT        = 3'd7;
localparam  NUM_CMD_BEAT_LOW    = 3'd2;
localparam  NUM_CMD_BEAT_HIGH   = 3'd6;
localparam  NUM_RD_BEAT         = 4'd12;
localparam  NUM_RD_BEAT_LOW     = 4'd10;

localparam  NUM_WR_CHK_LOW      = 4'd3;
localparam  NUM_WR_CHK_HIGH     = 4'd13;

localparam  ERASE_W             = ( SIM_ON == 1 ) ? 12 : 29;  //if iglobal_clk is 20ns, 29bit all bit is 1, the time is 10.7s
localparam  ERASE_KW            = ( SIM_ON == 1 ) ? 12 : 23;  //if iglobal_clk is 20ns, 23bit all bit is 1, the time is 167ms
localparam  WR_WORD             = ( SIM_ON == 1 ) ? 4  : 6;   //if iglobal_clk is 20ns, 6bit  all bit is 1, the time is 1280ns
/******************************************************************************\
                                    variables
\******************************************************************************/
reg    [2 :0]             fsm_next;
reg    [2 :0]             fsm_next_1d;
reg    [2 :0]             fsm_curr;
reg    [2 :0]             cnt_cmd;
reg                       flag_erase_all;
reg                       flag_erase_k;
reg                       flag_wr;
reg                       flag_rd;
reg                       flag_id;
reg                       flag_rst;
reg                       flag_chk;
reg    [6 :0]             cnt_erase_all_cycle;
reg    [7 :0]             cnt_erase_k_cycle;
reg    [6 :0]             cnt_wr_cycle;
reg    [2 :0]             cnt_beat_we;
reg    [3 :0]             cnt_beat_oe;
reg                       flag_dq6_first;
reg                       flag_dq6_sec;
reg                       dq6_sec_value;
reg    [23:0]             cnt_rd_flash_data;
reg                       flash_dq_ctr;
reg    [26:0]             iuser_adr_buf;
reg    [23:0]             ird_flash_num_buf;
reg    [15:0]             iwr_flash_dout_buf;
reg                       flag_chk_sec;
reg    [3 :0]             cnt_wr_chk;


reg    [ERASE_W-1:0]      cnt_erase_all_wait;
reg    [ERASE_KW-1:0]     cnt_erase_64k_wait;
reg    [WR_WORD-1:0]      cnt_wr_flash_wait;
/******************************************************************************\
                                    main_proc
\******************************************************************************/
//reg    [15:0]             flash_dq_in;
//ila_port u_ila_port (
//  .clk    (iglobal_clk        ), // input wire clk
//  .probe0 (oflash_ce_n        ), // input wire [0:0]  probe0  
//  .probe1 (oflash_oe_n        ), // input wire [7:0]  probe1 
//  .probe2 (oflash_we_n        ), // input wire [0:0]  probe2 
//  .probe3 (flash_dq_out       ), // input wire [15:0]  probe3 
//  .probe4 (oflash_adr[23:0]   ), // input wire [23:0]  probe4
//  .probe5 (fsm_next           ), // input wire [2:0]  probe5  
//  .probe6 (ord_id_wr          ), // input wire [0:0]  probe6
//  .probe7 (flash_dq_in        ), // input wire [15:0]  probe7
//  .probe8 (ord_flash_wr       ) // input wire [0:0]  probe8
//);
////flash_dq_in
//always@(posedge iglobal_clk)
//begin
//    if (( fsm_next == FSM_DQ ) || ( fsm_next == FSM_RD ))
//        flash_dq_in <= #U_DLY ioflash_dq;
//    else
//        ;
//end


//state
always@(posedge iglobal_clk or posedge iglobal_rst)
begin
    if (iglobal_rst == 1'b1)
        fsm_next <= 3'd0;
    else
        fsm_next <= #U_DLY fsm_curr;
end
always@( * )
begin
    case (fsm_next)
      
    FSM_IDLE :
    begin
        if ( iconfig_cmd == 3'b100 )
            fsm_curr = FSM_RD;
        else if ( iconfig_cmd == 3'b110 )
            fsm_curr = FSM_RST;
        else if (( iconfig_cmd == 3'b001 ) || ( iconfig_cmd == 3'b010 ) || ( iconfig_cmd == 3'b011 ) || 
                 ( iconfig_cmd == 3'b101 ) || ( iconfig_cmd == 3'b111 ))
            fsm_curr = FSM_CMD;
        else
            fsm_curr = FSM_IDLE;
    end
    FSM_CMD :
    begin
        if ((( cnt_cmd >= NUM_ERASE_CMD ) && (( flag_erase_all == 1'b1 ) || ( flag_erase_k == 1'b1 ))) ||
            (( cnt_cmd >= NUM_WR_CMD ) && ( flag_wr == 1'b1 )))
            fsm_curr = FSM_WAIT;
        else if ((( cnt_cmd >= NUM_ID_CMD ) && ( flag_id == 1'b1 )) || 
                 (( cnt_cmd >= NUM_CHK_CMD ) && ( flag_chk == 1'b1 )))
            fsm_curr = FSM_RD;
        else
            fsm_curr = FSM_CMD;
    end
    FSM_WAIT :
    begin
        if (( &cnt_erase_all_wait == 1'b1 ) || ( &cnt_erase_64k_wait == 1'b1 ) || ( &cnt_wr_flash_wait == 1'b1 ))
            fsm_curr = FSM_DQ;
        else if (( cnt_erase_all_cycle >= CYCLE_ERASE ) || ( cnt_erase_k_cycle >= CYCLE_ERASE_K ) || ( cnt_wr_cycle >= CYCLE_WR ))  //abnormal, exceed the max time
            fsm_curr = FSM_IDLE;
        else
            fsm_curr = FSM_WAIT;
    end
    FSM_DQ :
    begin
        //if (( cnt_beat_oe == NUM_RD_BEAT_LOW ) && ( flag_dq6_first == 1'b1 ))  //need read DQ6 more than twice
        if (( cnt_beat_oe == NUM_RD_BEAT_LOW ) && ( flag_dq6_sec == 1'b1 ))
        begin
            if (( dq6_sec_value == ioflash_dq[6] ) && ( flag_wr == 1'b1 ))
                fsm_curr = FSM_WR_CHK;
            else if (( dq6_sec_value == ioflash_dq[6] ) && ( flag_wr == 1'b0 ))
                fsm_curr = FSM_IDLE;
            else
                fsm_curr = FSM_WAIT;
        end
        else
            fsm_curr = FSM_DQ;
    end
    FSM_RD :
    begin
        if (( flag_id == 1'b1 ) && ( cnt_beat_oe == NUM_RD_BEAT ))
            fsm_curr = FSM_RST;
        else if ((( flag_rd == 1'b1 ) && ( cnt_rd_flash_data >= ird_flash_num_buf )) || 
                 (( flag_chk == 1'b1 ) && ( cnt_beat_oe == NUM_RD_BEAT ) && ( flag_chk_sec == 1'b1 )))
            fsm_curr = FSM_IDLE;
        else if (( flag_chk == 1'b1 ) && ( cnt_beat_oe == NUM_RD_BEAT ) && ( flag_chk_sec == 1'b0 ))
            fsm_curr = FSM_CHK;
        else
            fsm_curr = FSM_RD;
    end
    FSM_RST :
    begin
        if ( cnt_cmd >= NUM_RST_CMD )
            fsm_curr = FSM_IDLE;
        else
            fsm_curr = FSM_RST;
    end
    FSM_CHK :
    begin
        if ( cnt_cmd >= NUM_CHK_2CMD )
            fsm_curr = FSM_RD;
        else
            fsm_curr = FSM_CHK;
    end
    default :  //FSM_WR_CHK :
    begin
        if ( &cnt_wr_chk == 1'b1 )
            fsm_curr = FSM_IDLE;
        else
            fsm_curr = FSM_WR_CHK;
    end
    
    endcase
end

//oflash_ce_n
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_IDLE ) || (( fsm_next == FSM_WR_CHK ) && ( cnt_wr_chk < NUM_WR_CHK_LOW )))
        oflash_ce_n <= #U_DLY 1'b1;
    else
        oflash_ce_n <= #U_DLY 1'b0;
end
//oflash_we_n
always@(posedge iglobal_clk)
begin
    if (( cnt_beat_we >= NUM_CMD_BEAT_LOW ) && ( cnt_beat_we <= NUM_CMD_BEAT_HIGH ))
        oflash_we_n <= #U_DLY 1'b0;
    else
        oflash_we_n <= #U_DLY 1'b1;
end
//oflash_oe_n
always@(posedge iglobal_clk)
begin
    if ((( fsm_next == FSM_DQ ) && ( cnt_beat_oe <= NUM_RD_BEAT_LOW )) || ( fsm_next == FSM_RD ) ||
             (( fsm_next == FSM_WR_CHK ) && ( cnt_wr_chk >= NUM_WR_CHK_LOW ) && ( cnt_wr_chk <= NUM_WR_CHK_HIGH )))
        oflash_oe_n <= #U_DLY 1'b0;
    else
        oflash_oe_n <= #U_DLY 1'b1;
end
//flash_dq_ctr
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_DQ ) || ( fsm_next == FSM_RD ) || ( fsm_next == FSM_WR_CHK ))
        flash_dq_ctr <= #U_DLY 1'b1;
    else
        flash_dq_ctr <= #U_DLY 1'b0;
end
assign ioflash_dq = ( flash_dq_ctr == 1'b0 )? flash_dq_out : 16'hzzzz;
//flash_dq_out
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_CMD )
    begin
        if (( cnt_cmd == 3'd3 ) && ( flag_wr == 1'b1 ))
            flash_dq_out <= #U_DLY iwr_flash_dout_buf;
        else
        begin
            case( cnt_cmd )
            //3'd0    : flash_dq_out <= #U_DLY {8'd0,icmd_1din};
            3'd1    : flash_dq_out <= #U_DLY {8'd0,icmd_2din};
            3'd2    : flash_dq_out <= #U_DLY {8'd0,icmd_3din};
            3'd3    : flash_dq_out <= #U_DLY {8'd0,icmd_4din};
            3'd4    : flash_dq_out <= #U_DLY {8'd0,icmd_5din};
            3'd5    : flash_dq_out <= #U_DLY {8'd0,icmd_6din};
            default : flash_dq_out <= #U_DLY {8'd0,icmd_1din};
            endcase
        end
    end
    else if ( fsm_next == FSM_RST )
        flash_dq_out <= #U_DLY {8'd0,icmd_rst};
    else if ( fsm_next == FSM_CHK )
    begin
        case( cnt_cmd )
        3'd0    : flash_dq_out <= #U_DLY ichk2_1din;
        3'd1    : flash_dq_out <= #U_DLY ichk2_2din;
        default : flash_dq_out <= #U_DLY ichk2_3din;  //3'd2
        endcase
    end
    else
        ;
end
//oflash_adr
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_CMD )
    begin
        if ((( cnt_cmd == 3'd3 ) && ( flag_wr == 1'b1 )) || (( cnt_cmd == 3'd5 ) && ( flag_erase_k == 1'b1 )))
            oflash_adr <= #U_DLY iuser_adr_buf;
        else
        begin
            case( cnt_cmd )
            3'd0 : oflash_adr <= #U_DLY {15'd0,icmd_1adr};
            3'd1 : oflash_adr <= #U_DLY {15'd0,icmd_2adr};
            3'd2 : oflash_adr <= #U_DLY {15'd0,icmd_3adr};
            3'd3 : oflash_adr <= #U_DLY {15'd0,icmd_4adr};
            3'd4 : oflash_adr <= #U_DLY {15'd0,icmd_5adr};
            3'd5 : oflash_adr <= #U_DLY {15'd0,icmd_6adr};
            endcase
        end
    end
    else if ((( fsm_next == FSM_IDLE ) && ( iconfig_cmd == 3'b100 )) || (( fsm_next == FSM_RD ) && ( flag_id == 1'b1 )))
        oflash_adr <= #U_DLY iuser_adr;
    else if (( fsm_next == FSM_RD ) && ( cnt_beat_oe == NUM_RD_BEAT ))
        oflash_adr <= #U_DLY oflash_adr + 1'b1;
    else if ( fsm_next == FSM_CHK )
    begin
        case( cnt_cmd )
        3'd0    : oflash_adr <= #U_DLY ichk2_1adr;
        3'd1    : oflash_adr <= #U_DLY ichk2_2adr;
        default : oflash_adr <= #U_DLY ichk2_3adr;
        endcase
    end
    else if ( fsm_next == FSM_WAIT )
        oflash_adr <= #U_DLY iuser_adr_buf;
    else
        ;
end

//************* common *************//
//cnt_beat_we
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_CMD ) || ( fsm_next == FSM_RST ) || ( fsm_next == FSM_CHK ))
    begin
        if ( cnt_beat_we == NUM_CMD_BEAT )
            cnt_beat_we <= #U_DLY 3'd0;
        else
            cnt_beat_we <= #U_DLY cnt_beat_we + 1'b1;
    end
    else
        cnt_beat_we <= #U_DLY 3'd0;
end
//cnt_beat_oe
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_DQ ) || ( fsm_next == FSM_RD ) || ( fsm_next == FSM_WR_CHK ))
    begin
        if ( cnt_beat_oe == NUM_RD_BEAT )
            cnt_beat_oe <= #U_DLY 4'd0;
        else
            cnt_beat_oe <= #U_DLY cnt_beat_oe + 1'b1;
    end
    else
        cnt_beat_oe <= #U_DLY 4'd0;
end

//iuser_adr_buf
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
        iuser_adr_buf <= #U_DLY iuser_adr;
    else
        ;
end
//ird_flash_num_buf
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
        ird_flash_num_buf <= #U_DLY ird_flash_num;
    else
        ;
end
//iwr_flash_dout_buf
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
        iwr_flash_dout_buf <= #U_DLY iwr_flash_dout;
    else
        ;
end
//owr_flash_rd
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_IDLE ) && ( iconfig_cmd == 3'b011 ))
        owr_flash_rd <= #U_DLY 1'b1;
    else
        owr_flash_rd <= #U_DLY 1'b0;
end

//************* FSM_IDLE *************//
//flag_erase_all
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
    begin
        if ( iconfig_cmd == 3'b001 )
            flag_erase_all <= #U_DLY 1'b1;
        else
            flag_erase_all <= #U_DLY 1'b0;
    end
    else
        ;
end
//flag_erase_k
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
    begin
        if ( iconfig_cmd == 3'b010 )
            flag_erase_k <= #U_DLY 1'b1;
        else
            flag_erase_k <= #U_DLY 1'b0;
    end
    else
        ;
end
//flag_wr
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
    begin
        if ( iconfig_cmd == 3'b011 )
            flag_wr <= #U_DLY 1'b1;
        else
            flag_wr <= #U_DLY 1'b0;
    end
    else
        ;
end
//flag_rd
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
    begin
        if ( iconfig_cmd == 3'b100 )
            flag_rd <= #U_DLY 1'b1;
        else
            flag_rd <= #U_DLY 1'b0;
    end
    else
        ;
end
//flag_id
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
    begin
        if ( iconfig_cmd == 3'b101 )
            flag_id <= #U_DLY 1'b1;
        else
            flag_id <= #U_DLY 1'b0;
    end
    else
        ;
end
//flag_rst
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
    begin
        if ( iconfig_cmd == 3'b110 )
            flag_rst <= #U_DLY 1'b1;
        else
            flag_rst <= #U_DLY 1'b0;
    end
    else
        ;
end
//flag_chk
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
    begin
        if ( iconfig_cmd == 3'b111 )
            flag_chk <= #U_DLY 1'b1;
        else
            flag_chk <= #U_DLY 1'b0;
    end
    else
        ;
end

//oflash_rdy
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_IDLE ) && ( iconfig_cmd == 3'b000 ) && flash_ry_by_i == 1'b1)
        oflash_rdy <= #U_DLY 1'b1;
    else
        oflash_rdy <= #U_DLY 1'b0;
end

//************* FSM_CMD *************//
//cnt_cmd
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_CMD ) || ( fsm_next == FSM_RST ) || ( fsm_next == FSM_CHK ))
    begin
        if ( cnt_beat_we >= NUM_CMD_BEAT )
            cnt_cmd <= #U_DLY cnt_cmd + 1'b1;
        else
            ;
    end
    else
        cnt_cmd <= #U_DLY 3'd0;
end

//************* FSM_WAIT *************//
//cnt_erase_all_wait
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_WAIT ) && ( flag_erase_all == 1'b1 ))
        cnt_erase_all_wait <= #U_DLY cnt_erase_all_wait + 1'b1;
    else
        cnt_erase_all_wait <= #U_DLY {ERASE_W{1'b0}};
end
//cnt_erase_64k_wait
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_WAIT ) && ( flag_erase_k == 1'b1 ))
        cnt_erase_64k_wait <= #U_DLY cnt_erase_64k_wait + 1'b1;
    else
        cnt_erase_64k_wait <= #U_DLY {ERASE_KW{1'b0}};
end
//cnt_wr_flash_wait
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_WAIT ) && ( flag_wr == 1'b1 ))
        cnt_wr_flash_wait <= #U_DLY cnt_wr_flash_wait + 1'b1;
    else
        cnt_wr_flash_wait <= #U_DLY {WR_WORD{1'b0}};
end

//fsm_next_1d
always@(posedge iglobal_clk)
begin
    fsm_next_1d <= #U_DLY fsm_next;
end
//cnt_erase_all_cycle
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
        cnt_erase_all_cycle <= #U_DLY 7'd0;
    else if (( fsm_next == FSM_WAIT ) && ( fsm_next_1d == FSM_DQ ) && ( flag_erase_all == 1'b1 ))
        cnt_erase_all_cycle <= #U_DLY cnt_erase_all_cycle + 1'b1;
    else
        ;
end
//cnt_erase_k_cycle
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
        cnt_erase_k_cycle <= #U_DLY 8'd0;
    else if (( fsm_next == FSM_WAIT ) && ( fsm_next_1d == FSM_DQ ) && ( flag_erase_k == 1'b1 ))
        cnt_erase_k_cycle <= #U_DLY cnt_erase_k_cycle + 1'b1;
    else
        ;
end
//cnt_wr_cycle
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
        cnt_wr_cycle <= #U_DLY 7'd0;
    else if (( fsm_next == FSM_WAIT ) && ( fsm_next_1d == FSM_DQ ) && ( flag_wr == 1'b1 ))
        cnt_wr_cycle <= #U_DLY cnt_wr_cycle + 1'b1;
    else
        ;
end

//oexceed_max_time
always@(posedge iglobal_clk or posedge iglobal_rst)
begin
    if (iglobal_rst == 1'b1)
        oexceed_max_time <= 1'b0;
    else if (( cnt_erase_all_cycle >= CYCLE_ERASE ) || ( cnt_erase_k_cycle >= CYCLE_ERASE_K ) || ( cnt_wr_cycle >= CYCLE_WR ))
        oexceed_max_time <= #U_DLY 1'b1;
    else if (( fsm_next == FSM_IDLE ) && ( iconfig_cmd == 3'b110 ))
        oexceed_max_time <= #U_DLY 1'b0;
    else
        ;
end

//************* FSM_DQ *************//
//dq6_sec_value
always@(posedge iglobal_clk)
begin
    if (( cnt_beat_oe == NUM_RD_BEAT_LOW ) && ( flag_dq6_first == 1'b1 ))
        dq6_sec_value <= #U_DLY ioflash_dq[6];
    else
        ;
end

//flag_dq6_first
always@(posedge iglobal_clk)
begin
    if ( fsm_next != FSM_DQ )
        flag_dq6_first <= #U_DLY 1'b0;
    else if ( cnt_beat_oe == NUM_RD_BEAT )
        flag_dq6_first <= #U_DLY 1'b1;
    else
        ;
end
//flag_dq6_sec
always@(posedge iglobal_clk)
begin
    if ( fsm_next != FSM_DQ )
        flag_dq6_sec <= #U_DLY 1'b0;
    else if (( cnt_beat_oe == NUM_RD_BEAT ) && ( flag_dq6_first == 1'b1 ))
        flag_dq6_sec <= #U_DLY 1'b1;
    else
        ;
end

//************* FSM_RD *************//
//cnt_rd_flash_data
always@(posedge iglobal_clk)
begin
    if ( cnt_beat_oe == NUM_RD_BEAT )
        cnt_rd_flash_data <= #U_DLY cnt_rd_flash_data + 1'b1;
    else if ( fsm_next != FSM_RD )
        cnt_rd_flash_data <= #U_DLY 24'd0;
    else
        ;
end
//ord_flash_wr
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_RD ) && (( flag_rd == 1'b1 ) || ( flag_chk == 1'b1 ))&& ( cnt_beat_oe == NUM_RD_BEAT ))
        ord_flash_wr <= #U_DLY 1'b1;
    else
        ord_flash_wr <= #U_DLY 1'b0;
end
//ord_flash_din
always@(posedge iglobal_clk)
begin
    if ((( fsm_next == FSM_RD ) &&( cnt_beat_oe == NUM_RD_BEAT )) || ( cnt_wr_chk == NUM_WR_CHK_HIGH ))
        ord_flash_din <= #U_DLY ioflash_dq;
    else
        ;
end
//ord_id_wr
always@(posedge iglobal_clk)
begin
    if (( fsm_next == FSM_RD ) && ( flag_id == 1'b1 ) && ( cnt_beat_oe == NUM_RD_BEAT ))
        ord_id_wr <= #U_DLY 1'b1;
    else
        ord_id_wr <= #U_DLY 1'b0;
end

//************* FSM_CHK *************//
//flag_chk_sec
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_IDLE )
        flag_chk_sec <= #U_DLY 1'b0;
    else if ( fsm_next == FSM_CHK )
        flag_chk_sec <= #U_DLY 1'b1;
    else
        ;
end

////************* FSM_WR_CHK *************//
//cnt_wr_chk
always@(posedge iglobal_clk)
begin
    if ( fsm_next == FSM_WR_CHK )
        cnt_wr_chk <= #U_DLY cnt_wr_chk + 1'b1;
    else
        cnt_wr_chk <= #U_DLY 4'd0;
end
//oflag_wr_chk_err
always@(posedge iglobal_clk or posedge iglobal_rst)
begin
    if (iglobal_rst == 1'b1)
        oflag_wr_chk_err <= 1'b0;
    else if (( cnt_wr_chk == NUM_WR_CHK_HIGH ) && ( ioflash_dq != iwr_flash_dout_buf ))
        oflag_wr_chk_err <= 1'b1;
    else
        ;
end


endmodule
