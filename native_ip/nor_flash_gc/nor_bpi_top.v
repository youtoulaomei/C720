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
2022-11-01     chenjianwu  1.0                                  Initial
        
\*******************************************************************************/

`timescale 1ns / 1ps

module nor_bpi_top
(
    input              clk_50m            , 
    input              rst                , 
    input              hard_rst           , 

    //bpi flash port
    output             flash_ce_n_o       ,
    output             flash_oe_n_o       ,
    output             flash_we_n_o       ,
    inout       [15:0] flash_dq_io        ,
    output      [24:0] flash_adr_o        ,
    input              flash_ry_by_i      ,

    input       [15:0] mefc_odata         ,
    input              mefc_ovld          ,
    output   reg       mefc_ordy          ,
    
    output      [15:0] read_data        , 
    output      [0:0]  read_vld        ,

    output      [31:0] flash_rdata        ,
    input       [31:0] flash_wdata        ,
    input       [7:0]  flash_addr         ,
    input              flash_rd           ,
    input              flash_we           ,
    input              flash_cs

);

/******************************************************************************\
                                    parameters
\******************************************************************************/
//parameter define
parameter  CLK_FREQ = 50000000;         //定义系统时钟频率
//parameter  UART_BPS = 115200;           //定义串口波特率
parameter  UART_BPS = 460800;           //定义串口波特率

/******************************************************************************\
                                    variables
\******************************************************************************/
wire              locked;
reg    [23:0]     cnt_rst;
reg    [24:0]     cnt_led;
reg     [15:0]                      din;
reg                                 wr_en;
wire              uart_done;
reg               uart_done_1d;
reg               iwr_en;
wire   [7 :0]     iwr_din;
wire   [15:0]     fifo1_dout;
wire              fifo1_full;
wire              fifo1_empty;
reg               fifo2_wr_en;
reg               fifo2_rd_en;
wire   [7 :0]     fifo2_dout;
wire              fifo2_full;
wire              fifo2_empty;
reg    [6 :0]     cnt_uart_busy;
reg               uart_en;
reg    [7 :0]     uart_din;
wire              uart_tx_busy;
wire    [15:0]                      flash_dq_out;
wire                                prog_full;
wire                                prog_empty;

wire              owr_flash_rd;
wire   [15:0]     iwr_flash_dout;
wire              iwr_flash_empty;
wire              ord_id_wr;
wire              ord_flash_wr;
wire   [15:0]     ord_flash_din;

wire              iuart_rx;
wire              ouart_tx;
wire              oflash_rdy;
wire              oexceed_max_time;
wire              oflag_wr_chk_err;
wire              istart_opt_flash;
wire   [2 :0]     iconfig_cmd;
wire              iwrite_done;
wire   [26:0]     iuser_adr;
wire   [23:0]     ird_flash_num;

reg               istart_opt_flash_1d;
reg               fifo1_wr_en;
reg    [7 :0]     cnt_fifo1_wr_en;


//注意：这一段的命令参数，最好通过配置的方式输入，否则程序跑飞可能会导致flash被误擦误写
//*************************************************************//
//common command
wire   [11:0]     icom_1adr          ;
wire   [7 :0]     icom_1din          ;
wire   [11:0]     icom_2adr          ;
wire   [7 :0]     icom_2din          ;
wire   [11:0]     icom_3adr          ;
//erase common command
wire   [7 :0]     ierase_3din        ;
wire   [11:0]     ierase_4adr        ;
wire   [7 :0]     ierase_4din        ;
wire   [11:0]     ierase_5adr        ;
wire   [7 :0]     ierase_5din        ;
//erase all flash
wire   [11:0]     ierase_all_6adr    ;
wire   [7 :0]     ierase_all_6din    ;
//erase sector flash
wire   [7 :0]     ierase_sector_6din ;
//write command
wire   [7 :0]     iwrite_3din        ;
//read id command
wire   [7 :0]     iid_3din           ;
//reset command
wire   [7 :0]     ireset_1din        ;
//check command
wire   [7 :0]     ichk1_1din         ;
wire   [11:0]     ichk1_2adr         ;
wire   [7 :0]     ichk1_2din         ;
wire   [26:0]     ichk2_1adr         ;
wire   [15:0]     ichk2_1din         ;
wire   [26:0]     ichk2_2adr         ;
wire   [15:0]     ichk2_2din         ;
wire   [26:0]     ichk2_3adr         ;
wire   [15:0]     ichk2_3din         ;

//使用bpi flash时，输入配置的命令值，不使用时，输入配置的命令值统一输入为0，具体配置的值如下：
assign icom_1adr          = 12'h555    ;
assign icom_1din          = 8'haa      ;
assign icom_2adr          = 12'h2aa    ;
assign icom_2din          = 8'h55      ;
assign icom_3adr          = 12'h555    ;
assign ierase_3din        = 8'h80      ;
assign ierase_4adr        = 12'h555    ;
assign ierase_4din        = 8'haa      ;
assign ierase_5adr        = 12'h2aa    ;
assign ierase_5din        = 8'h55      ;
assign ierase_all_6adr    = 12'h555    ;
assign ierase_all_6din    = 8'h10      ;
assign ierase_sector_6din = 8'h30      ;
assign iwrite_3din        = 8'ha0      ;
assign iid_3din           = 8'h90      ;
assign ireset_1din        = 8'hf0      ;
assign ichk1_1din         = 8'h71      ;
assign ichk1_2adr         = 12'h555    ;
assign ichk1_2din         = 8'h70      ;
assign ichk2_1adr         = 27'h2aaaa55;
assign ichk2_1din         = 16'hff00   ;
assign ichk2_2adr         = 27'h15555aa;
assign ichk2_2din         = 16'h00ff   ;
assign ichk2_3adr         = 27'h0000555;
assign ichk2_3din         = 16'h0070   ;
//*************************************************************//

//注意：这是为了bpi*16加载bin文件专门修改低8bit与高8bit颠倒，使用时根据实际情况看是否调整
//assign iwr_flash_dout  = {fifo1_dout[7:0],fifo1_dout[15:8]};

//位序修改为【0:15】
assign iwr_flash_dout  = {fifo1_dout[0],fifo1_dout[1],fifo1_dout[2],fifo1_dout[3],fifo1_dout[4],fifo1_dout[5],fifo1_dout[6],fifo1_dout[7],fifo1_dout[8],fifo1_dout[9],fifo1_dout[10],fifo1_dout[11],fifo1_dout[12],fifo1_dout[13],fifo1_dout[14],fifo1_dout[15]};
assign iwr_flash_empty = fifo1_empty;

//assign flash_rst_n_o = 1'b1;
wire    [26:0]    flash_adr;


flash_cib u_flash_cib(
    .clk                        (clk_50m                    ),
    .rst                        (hard_rst                   ),
//
    .fifo2_empty                (iwr_flash_empty            ),
    .oflash_rdy                 (oflash_rdy                 ),
    .oexceed_max_time           (oexceed_max_time           ),
    .oflag_wr_chk_err           (oflag_wr_chk_err           ),
    .istart_opt_flash           (istart_opt_flash           ),
    .iconfig_cmd                (iconfig_cmd                ),
    .iwrite_done                (iwrite_done                ),
    .iuser_adr                  (iuser_adr                  ),
    .ird_flash_num              (ird_flash_num              ),
//cpu
    .cpu_cs                     (flash_cs                    ),
    .cpu_we                     (flash_we                    ),
    .cpu_rd                     (flash_rd                    ),
    .cpu_addr                   (flash_addr                  ),
    .cpu_wdata                  (flash_wdata                 ),
    .cpu_rdata                  (flash_rdata                 )
);

asyn_fifo # (
    .U_DLY                      (0                          ),
    .DATA_WIDTH                 (16                         ),
    .DATA_DEEPTH                (1024                       ),
    .ADDR_WIDTH                 (10                         )
//    .RAM_STYLE                  ("BRAM"                     )
)u_mefc_fifo
(
    .wr_clk                     (clk_50m                    ),
    .wr_rst_n                   (~rst                       ),
    .rd_clk                     (clk_50m                    ),
    .rd_rst_n                   (~rst                       ),
    .din                        (din                        ),
    .wr_en                      (wr_en                      ),
    .rd_en                      (owr_flash_rd               ),
    .dout                       (fifo1_dout                 ),
    .full                       (fifo1_full                 ),
    .prog_full                  (prog_full                  ),
    .empty                      (fifo1_empty                ),
    .prog_empty                 (prog_empty                 ),
    .prog_full_thresh           (10'd900                    ),
    .prog_empty_thresh          (10'd4                     )

);

always@(posedge clk_50m or posedge rst)
begin
    if(rst == 1'b1)
        begin
            mefc_ordy <=  1'b0;
            wr_en <=  1'b0;
            din <=  16'b0;
        end
    else
        begin 
            if(prog_full == 1'b1)
                mefc_ordy <= 1'b0;
            else
                mefc_ordy <= 1'b1;
            
            if(mefc_ovld==1'b1 && mefc_ordy==1'b1)
                wr_en <=  1'b1;
            else
                wr_en <=  1'b0;
            
            if(mefc_ovld==1'b1 && mefc_ordy==1'b1)
                din <=  mefc_odata;
        end 
end



//ila_bpi u_ila_bpi (
//  .clk    (clk_50m            ), // input wire clk
//  .probe0 (wr_en             ), // input wire [0:0]  probe0  
//  .probe1 (din            ), // input wire [7:0]  probe1 
//  .probe2 (owr_flash_rd       ), // input wire [0:0]  probe2 
//  .probe3 (ord_flash_din      ), // input wire [15:0]  probe3 
//  .probe4 (flash_adr_o        ), // input wire [25:0]  probe4
//  .probe5 (ord_id_wr          ), // input wire [0:0]  probe5  
//  .probe6 (ord_flash_wr       ), // input wire [0:0]  probe6
//  .probe7 (flash_ry_by_i      ),  // input wire [0:0]  probe7
//  .probe8 (oflash_rdy         ),  // input wire [0:0]  probe8
//  .probe9 (oexceed_max_time   ),  // input wire [0:0]  probe9
//  .probe10 (oflag_wr_chk_err   ),  // input wire [0:0]  probe10
//  .probe11 (istart_opt_flash   ),  // input wire [0:0]  probe11
//  .probe12 (iconfig_cmd        ),  // input wire [2:0]  probe12
//  .probe13 (iwrite_done        ),  // input wire [0:0]  probe13
//  .probe14 (flash_ce_n_o        ),  // input wire [0:0]  probe14
//  .probe15 (flash_we_n_o        ),  // input wire [0:0]  probe15
//  .probe16 (flash_oe_n_o        ),  // input wire [0:0]  probe16
//  .probe17 (flash_dq_out        ),  // input wire [15:0]  probe17
//  .probe18 (fifo1_full          ),  // input wire [0:0]  probe18
//  .probe19 (fifo1_empty          ),  // input wire [0:0]  probe19
//  .probe20 (fifo1_dout          ),  // input wire [15:0]  probe20
//  .probe21 (prog_full          )  // input wire [15:0]  probe20
//);



//fifo2_wr_en
always@(posedge clk_50m)
begin
    fifo2_wr_en <= ord_id_wr | ord_flash_wr;
end


assign read_data = ord_flash_din;
assign read_vld = fifo2_wr_en;

nor_bpi_user #
(
    .CYCLE_ERASE            (7'd102           ),  //the number of the 10s cycle,    max time of the erase the whole flash time
    .CYCLE_ERASE_K          (8'd60            ),  //the number of the 167ms cycle,  max time of the erase flash 64k or 32k time 
    .CYCLE_WR               (7'd117           )   //the number of the 1.28us cycle, max time of the write the flash page time
)
u_nor_bpi_user
(
    //reset and clock
    .iglobal_rst            (rst       ),
    .iglobal_clk            (clk_50m          ),
    //command
    .istart_opt_flash       (istart_opt_flash ),  //when oflash_rdy == 1,istart_opt_flash=0 and then istart_opt_flash=1, posedge will start to operate the flash
    .iconfig_cmd            (iconfig_cmd      ),  //000:not configure, 001:erase the all flash, 010:erase the sector, 011:write the flash(one word), 
                                                  //100:read the flash(one word), 101:read the flash id, 110:soft reset the flash, 111:Continuity check
    .oflash_rdy             (oflash_rdy       ),  //1: the flash is ready, 0:not
    .iwrite_done            (iwrite_done      ),  //1:write done 
    //the operate address
    .iuser_adr              (iuser_adr        ),
    //write port
    .owr_flash_rd           (owr_flash_rd     ),
    .iwr_flash_dout         (iwr_flash_dout   ),
    .iwr_flash_empty        (iwr_flash_empty  ),
    //read port
    .ird_flash_num          (ird_flash_num    ),
    .ord_flash_wr           (ord_flash_wr     ),
    .ord_flash_din          (ord_flash_din    ),
    //read id
    .ord_id_wr              (ord_id_wr        ),
    //common command
    .icom_1adr          (12'h555          ),
    .icom_1din          (8'haa            ),
    .icom_2adr          (12'h2aa          ),
    .icom_2din          (8'h55            ),
    .icom_3adr          (12'h555          ),
    //erase common command
    .ierase_3din        (8'h80            ),
    .ierase_4adr        (12'h555          ),
    .ierase_4din        (8'haa            ),
    .ierase_5adr        (12'h2aa          ),
    .ierase_5din        (8'h55            ),
    //erase all flash
    .ierase_all_6adr    (12'h555          ),
    .ierase_all_6din    (8'h10            ),
    //erase sector flash
    .ierase_sector_6din (8'h30            ),
    //write command
    .iwrite_3din        (8'ha0            ),
    //read id command
    .iid_3din           (8'h90            ),
    //reset command
    .ireset_1din        (8'hf0            ),
    //check command
    .ichk1_1din         (8'h71            ),
    .ichk1_2adr         (12'h555          ),
    .ichk1_2din         (8'h70            ),
    .ichk2_1adr         (27'h2aaaa55      ),
    .ichk2_1din         (16'hff00         ),
    .ichk2_2adr         (27'h15555aa      ),
    .ichk2_2din         (16'h00ff         ),
    .ichk2_3adr         (27'h0000555      ),
    .ichk2_3din         (16'h0070         ),
    
    //abnormal
    .oexceed_max_time       (oexceed_max_time ),
    .oflag_wr_chk_err       (oflag_wr_chk_err   ),
    //flash port
    .oflash_ce_n            (flash_ce_n_o      ),
    .oflash_oe_n            (flash_oe_n_o      ),
    .oflash_we_n            (flash_we_n_o      ),
    .ioflash_dq             (flash_dq_io      ),
    .flash_dq_out               (flash_dq_out               ),
    .flash_ry_by_i              (flash_ry_by_i              ),
    .oflash_adr             (flash_adr        )
);

assign flash_adr_o = flash_adr[24:0];



endmodule
