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
2022-10-28     chenjianwu  1.0                                  Initial
        
\*******************************************************************************/

`timescale 1ns / 1ps

module nor_bpi_user #
(
    parameter          CYCLE_ERASE      = 7'd102, //the number of the 10s cycle,    max time of the erase the whole flash time
    parameter          CYCLE_ERASE_K    = 8'd60,  //the number of the 167ms cycle,  max time of the erase flash 64k or 32k time 
    parameter          CYCLE_WR         = 7'd117  //the number of the 1.28us cycle, max time of the write the flash page time
)
(
    //reset and clock
    input              iglobal_rst        ,
    input              iglobal_clk        ,
    //command
    input              istart_opt_flash   ,  //when oflash_rdy == 1,istart_opt_flash=0 and then istart_opt_flash=1, posedge will start to operate the flash
    input       [2 :0] iconfig_cmd        ,  //000:not configure, 001:erase the all flash, 010:erase the sector, 011:write the flash(one word), 
                                             //100:read the flash(one word), 101:read the flash id, 110:soft reset the flash, 111:Continuity check
    output reg         oflash_rdy         ,  //1: the flash is ready, 0:not
    input              iwrite_done        ,  //1:write done 
    //the operate address
    input       [26:0] iuser_adr          ,
    //write port
    output             owr_flash_rd       ,
    input       [15:0] iwr_flash_dout     ,
    input              iwr_flash_empty    ,
    //read port
    input       [23:0] ird_flash_num      ,  //The maximum number of data read at a time is 2^16 = 65536-1 = 65535
    output             ord_flash_wr       ,
    output      [15:0] ord_flash_din      ,
    //read id
    output             ord_id_wr          ,
    //common command
    input       [11:0] icom_1adr          ,
    input       [7 :0] icom_1din          ,
    input       [11:0] icom_2adr          ,
    input       [7 :0] icom_2din          ,
    input       [11:0] icom_3adr          ,
    //erase common command
    input       [7 :0] ierase_3din        ,
    input       [11:0] ierase_4adr        ,
    input       [7 :0] ierase_4din        ,
    input       [11:0] ierase_5adr        ,
    input       [7 :0] ierase_5din        ,
    //erase all flash
    input       [11:0] ierase_all_6adr    ,
    input       [7 :0] ierase_all_6din    ,
    //erase sector flash
    //input       [26:0] ierase_sector_6adr ,
    input       [7 :0] ierase_sector_6din ,
    //write command
    input       [7 :0] iwrite_3din        ,
    //read id command
    input       [7 :0] iid_3din           ,
    //reset command
    input       [7 :0] ireset_1din        ,
    //check command
    input       [7 :0] ichk1_1din         ,
    input       [11:0] ichk1_2adr         ,
    input       [7 :0] ichk1_2din         ,
    input       [26:0] ichk2_1adr         ,
    input       [15:0] ichk2_1din         ,
    input       [26:0] ichk2_2adr         ,
    input       [15:0] ichk2_2din         ,
    input       [26:0] ichk2_3adr         ,
    input       [15:0] ichk2_3din         ,
    //abnormal
    output             oexceed_max_time   ,
    output             oflag_wr_chk_err   ,
    //flash port
    output             oflash_ce_n        ,
    output             oflash_oe_n        ,
    input              flash_ry_by_i      ,
    output             oflash_we_n        ,
    output    [15:0]                      flash_dq_out,
    inout       [15:0] ioflash_dq         ,
    output      [26:0] oflash_adr         
);
/******************************************************************************\
                                    parameters
\******************************************************************************/
parameter   U_DLY               = 1'b1;

/******************************************************************************\
                                    variables
\******************************************************************************/
reg                       istart_opt_flash_1d;
reg                       iwrite_done_1d;
reg                       oflash_rdy_1d;
reg                       flash_rdy_1d;
reg    [2 :0]             config_cmd;
reg    [2 :0]             iconfig_cmd_buf;
reg                       flash_write;
reg    [7 :0]             icmd_1din;
reg    [12:0]             icmd_2adr;
reg    [7 :0]             icmd_2din;
reg    [7 :0]             icmd_3din;
reg    [7 :0]             icmd_6din;
wire                      flash_rdy;
reg    [26:0]             user_adr;

/******************************************************************************\
                                    main_proc
\******************************************************************************/
always@(posedge iglobal_clk)
begin
    istart_opt_flash_1d <= #U_DLY istart_opt_flash;
    iwrite_done_1d      <= #U_DLY iwrite_done;
    oflash_rdy_1d       <= #U_DLY oflash_rdy;
    flash_rdy_1d        <= #U_DLY flash_rdy;
end
//config_cmd
always@(posedge iglobal_clk)
begin
    if (( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 ) && ( iconfig_cmd != 3'b011 ))
        config_cmd <= #U_DLY iconfig_cmd;
    else if (( flash_write == 1'b1 ) && ( flash_rdy == 1'b1 ) && ( iwr_flash_empty == 1'b0 ))
        config_cmd <= #U_DLY iconfig_cmd_buf;
    else
        config_cmd <= #U_DLY 3'b000;
end
//iconfig_cmd_buf
always@(posedge iglobal_clk)
begin
    if (( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 ))
        iconfig_cmd_buf <= #U_DLY iconfig_cmd;
    else
        ;
end

//flash_write
always@(posedge iglobal_clk or posedge iglobal_rst)
begin
    if (iglobal_rst == 1'b1)
        flash_write <= #U_DLY 1'b0;
    else if (( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 ) && ( iconfig_cmd == 3'b011 ))  //011:write the flash(one word)
        flash_write <= #U_DLY 1'b1;
    else if (( iwrite_done == 1'b1 ) && ( iwrite_done_1d == 1'b0 ))
        flash_write <= #U_DLY 1'b0;
    else
        ;
end
//icmd_1din
always@(posedge iglobal_clk)
begin
    if (( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 ))
    begin
        if ( iconfig_cmd == 3'b111 )         //111:Continuity check
            icmd_1din <= #U_DLY ichk1_1din;
        else
            icmd_1din <= #U_DLY icom_1din;
    end
    else
        ;
end
//icmd_2adr
always@(posedge iglobal_clk)
begin
    if (( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 ))
    begin
        if ( iconfig_cmd == 3'b111 )         //111:Continuity check
            icmd_2adr <= #U_DLY ichk1_2adr;
        else
            icmd_2adr <= #U_DLY icom_2adr;
    end
    else
        ;
end
//icmd_2din
always@(posedge iglobal_clk)
begin
    if (( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 ))
    begin
        if ( iconfig_cmd == 3'b111 )         //111:Continuity check
            icmd_2din <= #U_DLY ichk1_2din;
        else
            icmd_2din <= #U_DLY icom_2din;
    end
    else
        ;
end
//icmd_3din
always@(posedge iglobal_clk)
begin
    if (( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 ))
    begin
        if ( iconfig_cmd == 3'b011 )         //011:write the flash(one word)
            icmd_3din <= #U_DLY iwrite_3din;
        else if ( iconfig_cmd == 3'b101 )     //101:read the flash id
            icmd_3din <= #U_DLY iid_3din;
        else
            icmd_3din <= #U_DLY ierase_3din;
    end
    else
        ;
end
//icmd_6din
always@(posedge iglobal_clk)
begin
    if (( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 ))
    begin
        if ( iconfig_cmd == 3'b001 )         //001:erase the all flash
            icmd_6din <= #U_DLY ierase_all_6din;
        else                               //if 010:erase the sector
            icmd_6din <= #U_DLY ierase_sector_6din;
    end
    else
        ;
end
//oflash_rdy
always@(posedge iglobal_clk or posedge iglobal_rst)
begin
    if (iglobal_rst == 1'b1)
        oflash_rdy <= #U_DLY 1'b1;
    else if ((( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 )) || ( flash_write == 1'b1 ))
        oflash_rdy <= #U_DLY 1'b0;
    else if (( oflash_rdy == 1'b0 ) && ( oflash_rdy_1d == 1'b1 ))
        oflash_rdy <= #U_DLY 1'b0;
    else
        oflash_rdy <= #U_DLY flash_rdy;
end
//user_adr
always@(posedge iglobal_clk)
begin
    if ( flash_write == 1'b1 )
    begin
        if (( flash_rdy == 1'b1 ) && ( flash_rdy_1d == 1'b0 ))
            user_adr <= #U_DLY user_adr + 1'b1;
        else
            ;
    end
    else if (( istart_opt_flash == 1'b1 ) && ( istart_opt_flash_1d == 1'b0 ) && ( oflash_rdy == 1'b1 ))
        user_adr <= #U_DLY iuser_adr;
    else
        ;
end



nor_bpi_port #
(
    .CYCLE_ERASE            (7'd102             ),  //the number of the 10s cycle,    max time of the erase the whole flash time
    .CYCLE_ERASE_K          (8'd60              ),  //the number of the 167ms cycle,  max time of the erase flash 64k or 32k time 
    .CYCLE_WR               (7'd117             )   //the number of the 1.28us cycle, max time of the write the flash page time
)
u_nor_bpi_port
(
    //reset and clock
    .iglobal_rst            (iglobal_rst        ),
    .iglobal_clk            (iglobal_clk        ),
    //configure the command
    .iconfig_cmd            (config_cmd         ),  //000:not configure, 001:erase the all flash, 010:erase the sector(64K or 32K), 011:write the flash(one word), 
                                                    //100:read the flash(one word), 101:read the flash id, 110:soft reset the flash
    //the operate address
    .iuser_adr              (user_adr           ),
    //write data
    .owr_flash_rd           (owr_flash_rd       ),
    .iwr_flash_dout         (iwr_flash_dout     ),
    //read data
    .ird_flash_num          (ird_flash_num      ),  //The maximum number of data read at a time is 2^16 = 65536-1 = 65535
    .ord_flash_wr           (ord_flash_wr       ),
    .ord_flash_din          (ord_flash_din      ),
    //read id
    .ord_id_wr              (ord_id_wr          ),
    //ready
    .oflash_rdy             (flash_rdy          ),
    //configure the command
    .icmd_1adr              (icom_1adr          ),  //the first  command address
    .icmd_1din              (icmd_1din          ),  //the first  command data
    .icmd_2adr              (icmd_2adr          ),  //the second command address
    .icmd_2din              (icmd_2din          ),  //the second command data
    .icmd_3adr              (icom_3adr          ),
    .icmd_3din              (icmd_3din          ),
    .icmd_4adr              (ierase_4adr        ),
    .icmd_4din              (ierase_4din        ),
    .icmd_5adr              (ierase_5adr        ),
    .icmd_5din              (ierase_5din        ),
    .icmd_6adr              (ierase_all_6adr    ),
    .icmd_6din              (icmd_6din          ),
    .icmd_rst               (ireset_1din        ),
    .ichk2_1adr             (ichk2_1adr         ),
    .ichk2_1din             (ichk2_1din         ),
    .ichk2_2adr             (ichk2_2adr         ),
    .ichk2_2din             (ichk2_2din         ),
    .ichk2_3adr             (ichk2_3adr         ),
    .ichk2_3din             (ichk2_3din         ),
    //abnormal
    .oexceed_max_time       (oexceed_max_time   ),
    .oflag_wr_chk_err       (oflag_wr_chk_err   ),
    //flash port
    .oflash_ce_n            (oflash_ce_n        ),
    .oflash_oe_n            (oflash_oe_n        ),
    .oflash_we_n            (oflash_we_n        ),
    .flash_ry_by_i              (flash_ry_by_i              ),
    .flash_dq_out               (flash_dq_out               ),
    .ioflash_dq             (ioflash_dq         ),
    .oflash_adr             (oflash_adr         )
);

endmodule
