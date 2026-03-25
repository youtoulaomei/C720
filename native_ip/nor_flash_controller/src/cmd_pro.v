// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/3/6 14:59:59
// File Name    : cmd_pro.v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2017,BoYuLiHua Technology Co., Ltd.. 
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
module cmd_pro #(
parameter                           U_DLY = 1,
parameter                           ADDR_W = 26,
parameter                           DATA_W = 16
)
(
input                               clk,
input                               rst,
//io
input                               ry_byn,
//interface with phy
output  reg                         op_req,
input                               op_ack,
output  reg                         op_rw,                           //0:write
output  reg     [ADDR_W - 1:0]      op_addr,
output  reg     [DATA_W - 1:0]      op_wdata,
input           [DATA_W - 1:0]      op_rdata,
input                               op_rvld,
//interface with up-stream module
output  reg     [DATA_W - 1:0]      rdata,
output  reg                         rvld,

input           [DATA_W - 1:0]      wdata,
output  reg                         wdata_ren,
input                               wdata_rdy,
//cfg or alarm
input           [ADDR_W-1:0]        wb_start_addr,
input           [ADDR_W-1:0]        wb_word_len,                    //base on word
input                               wb_start,

input           [ADDR_W-1:0]        rd_start_addr,
input           [ADDR_W-1:0]        rd_word_len,                    //base on word
input                               rd_start,

input                               ers_start,
input                               ers_sector_en,
input           [ADDR_W-17:0]       ers_sector_addr,

output  reg                         st_free,
output  reg                         wb_fail,
output  reg                         ers_fail,
output  reg                         wb_reg_done,
output  reg                         rd_reg_done,
output  reg                         ers_reg_done,
input                               r_sts_reg_en,
output  reg     [ADDR_W-1:0]        all_data_wcnt,
input                               bit_order,
//others
output  reg                         inbuf_en,
input                               authorize_succ
);
// Parameter Define 
localparam                           IDLE = 4'b0001;
localparam                           WRITE_BUF = 4'b0010;
localparam                           READ = 4'b0100;
localparam                           ERASE = 4'b1000;

localparam                           WB_IDLE = 8'b0000_0001;
localparam                           WB_HEAD = 8'b000_0010;
localparam                           WB_USER_DATA = 8'b0000_0100;
localparam                           WB_CONFIRM = 8'b0000_1000;
localparam                           WB_WAITING_NOBUSY = 8'b0001_0000;
localparam                           WB_R_STATUS = 8'b0010_0000;
localparam                           WB_C_STATUS = 8'b0100_0000;
localparam                           WB_WAIT_WDATA = 8'b1000_0000;

localparam                           E_IDLE = 5'b00001;
localparam                           E_CHIP_ERS = 5'b00010;
localparam                           E_WAITING_NOBUSY = 5'b00100;
localparam                           E_R_STATUS = 5'b01000;
localparam                           E_C_STATUS = 5'b10000;

localparam                           SR_IDLE = 3'b001;
localparam                           SR_WRITE_CMD = 3'b010;
localparam                           SR_READ_STATUS = 3'b100;
// Register Define 
reg     [3:0]                       m_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [3:0]                       m_next_st;
reg     [3:0]                       m_cur_st_dly;
reg                                 wb_start_dly;
reg                                 rd_start_dly;
reg                                 ers_start_dly;
reg                                 wb_start_pulse;
reg                                 rd_start_pulse;
reg                                 ers_start_pulse;
reg     [7:0]                       wb_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [7:0]                       wb_next_st;
reg     [7:0]                       wb_cur_st_dly;
reg     [ADDR_W-1:0]                cur_wb_addr;
reg     [1:0]                       wb_head_op_cnt;
reg                                 wb_head_wdone;
reg                                 wb_userdata_wdone;
reg                                 all_data_wdone;
reg                                 wb_confirm_wdone;
reg     [2:0]                       ry_byn_dly;
reg                                 nobusy_rising;
reg     [1:0]                       wb_status_cnt;
reg                                 wb_status_rdone;
reg                                 wb_status_cdone;
reg                                 wb_done;
reg     [ADDR_W-1:0]                cur_rd_addr;
reg     [ADDR_W-1:0]                all_data_rcnt;
reg                                 all_data_rdone;
reg                                 rd_done;
reg     [4:0]                       e_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [4:0]                       e_next_st;
reg     [2:0]                       erase_cnt;
reg                                 chip_ers_done;
reg     [1:0]                       e_status_cnt;
reg                                 e_status_rdone;
reg                                 e_status_cdone;
reg                                 ers_done;
reg     [ADDR_W-1:0]                sector_addr;
reg     [7:0]                       wc_num;
reg     [DATA_W-1:0]                wdata_latch;
reg                                 ers_sa_en;
reg     [ADDR_W-17:0]               ers_sa;
reg                                 nobusy_sr;
reg     [2:0]                       r_sr_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [2:0]                       r_sr_next_st;
reg                                 sr_polling_start;
reg                                 sr_wcmd_done;
reg     [2:0]                       r_sr_cur_st_dly;
reg                                 sr_req_en;
// Wire Define 
wire    [DATA_W-1:0]                wdata_change_order;


//******************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        m_cur_st <= IDLE;
    else
        m_cur_st <= #U_DLY m_next_st;
end

always @(*)
begin
    if(authorize_succ == 1'b0)
        m_next_st = IDLE;
    else
        begin
            case(m_cur_st)
                IDLE:begin
                    if(wb_start_pulse == 1'b1)
                        m_next_st = WRITE_BUF;
                    else if(rd_start_pulse == 1'b1)
                        m_next_st = READ;
                    else if(ers_start_pulse == 1'b1)
                        m_next_st = ERASE;
                    else
                        m_next_st = IDLE;end
                WRITE_BUF:begin
                    if(wb_done == 1'b1)
                        m_next_st = IDLE;
                    else
                        m_next_st = WRITE_BUF;end
                READ:begin
                    if(rd_done == 1'b1)
                        m_next_st = IDLE;
                    else
                        m_next_st = READ;end
                ERASE:begin
                    if(ers_done == 1'b1)
                        m_next_st = IDLE;
                    else
                        m_next_st = ERASE;end
                default:m_next_st = IDLE;
            endcase
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            m_cur_st_dly <= IDLE;
            wb_start_dly <= 1'b0;
            rd_start_dly <= 1'b0;
            ers_start_dly <= 1'b0;
            wb_start_pulse <= 1'b0;
            rd_start_pulse <= 1'b0;
            ers_start_pulse <= 1'b0;
            ers_sa_en <= 1'b0;
            ers_sa <= 'd0;
        end
    else
        begin
            m_cur_st_dly <= #U_DLY m_cur_st;
            wb_start_dly <= #U_DLY wb_start;
            rd_start_dly <= #U_DLY rd_start;
            ers_start_dly <= #U_DLY ers_start;

            if({wb_start_dly,wb_start} == 2'b01)
                wb_start_pulse <= #U_DLY 1'b1;
            else
                wb_start_pulse <= #U_DLY 1'b0;

            if({rd_start_dly,rd_start} == 2'b01)
                rd_start_pulse <= #U_DLY 1'b1;
            else
                rd_start_pulse <= #U_DLY 1'b0;

            if({ers_start_dly,ers_start} == 2'b01)
                ers_start_pulse <= #U_DLY 1'b1;
            else
                ers_start_pulse <= #U_DLY 1'b0;

            if({ers_start_dly,ers_start} == 2'b01)
                ers_sa_en <= #U_DLY ers_sector_en;
            else;

            if({ers_start_dly,ers_start} == 2'b01)
                ers_sa <= #U_DLY ers_sector_addr;
            else;
        end
end        
//******************************************************************//
//write process
//******************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        wb_cur_st <= WB_IDLE;
    else
        wb_cur_st <= #U_DLY wb_next_st;
end

always @(*)
begin
    case(wb_cur_st)
        WB_IDLE:begin
            if(m_cur_st_dly == IDLE && m_cur_st == WRITE_BUF)
                wb_next_st = WB_WAIT_WDATA;
            else 
                wb_next_st = WB_IDLE;end
        WB_WAIT_WDATA:begin
            if(wdata_rdy == 1'b1)
                wb_next_st = WB_HEAD;
            else
                wb_next_st = WB_WAIT_WDATA;end
        WB_HEAD:begin                                                //write head, 4 operate
            if(wb_head_wdone == 1'b1)
                wb_next_st = WB_USER_DATA;
            else
                wb_next_st = WB_HEAD;end
        WB_USER_DATA:begin                                           //write user data ,WC
            if(wb_userdata_wdone == 1'b1)
                wb_next_st = WB_CONFIRM;
            else
                wb_next_st = WB_USER_DATA;end
        WB_CONFIRM:begin                                             //confirm buffer write
            if(wb_confirm_wdone == 1'b1)
                wb_next_st = WB_WAITING_NOBUSY;
            else
                wb_next_st = WB_CONFIRM;end
        WB_WAITING_NOBUSY:begin                                      //waiting no busy
            if(r_sts_reg_en == 1'b0)                                 //judge by busy wire signal
                begin
                    if(nobusy_rising == 1'b1)
                        wb_next_st = WB_R_STATUS;
                    else
                        wb_next_st = WB_WAITING_NOBUSY;
                end
            else                                                     //judge by status register
                begin
                    if(nobusy_sr == 1'b1)
                        wb_next_st = WB_R_STATUS;
                    else
                        wb_next_st = WB_WAITING_NOBUSY;
                end
            end
        WB_R_STATUS:begin                                            //read status
            if(wb_status_rdone == 1'b1)
                wb_next_st = WB_C_STATUS;
            else
                wb_next_st = WB_R_STATUS;end
        WB_C_STATUS:begin                                            //clear status
            if(wb_status_cdone == 1'b1)
                begin
                    if(all_data_wdone == 1'b1)
                        wb_next_st = WB_IDLE;
                    else
                        wb_next_st = WB_WAIT_WDATA;
                end
            else
                wb_next_st = WB_C_STATUS;end
        default:wb_next_st = WB_IDLE;
    endcase
end    

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wb_cur_st_dly <= WB_IDLE;
            cur_wb_addr <= 'd0;
            all_data_wcnt <= 'd0;               //base on word
        end
    else
        begin
            wb_cur_st_dly <= #U_DLY wb_cur_st;

            if(wb_start_pulse == 1'b1)
                cur_wb_addr <= #U_DLY wb_start_addr;
            else if(m_cur_st == WRITE_BUF && wb_cur_st == WB_USER_DATA && {op_req,op_ack} == 2'b11)
                begin
                    if(cur_wb_addr != {ADDR_W{1'b1}})
                        cur_wb_addr <= #U_DLY cur_wb_addr + 'd1;
                    else;
                end
            else;

            if(wb_start_pulse == 1'b1)
                all_data_wcnt <= #U_DLY wb_word_len - 'd1;
            else if(m_cur_st == WRITE_BUF && wb_cur_st == WB_USER_DATA && {op_req,op_ack} == 2'b11)
                begin
                    if(all_data_wcnt > 'd0)
                        all_data_wcnt <= #U_DLY all_data_wcnt - 'd1;
                    else;
                end
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wb_head_op_cnt <= 'd0;
            wb_head_wdone <= 1'b0;
        end
    else
        begin
            if(wb_cur_st == WB_IDLE || wb_cur_st == WB_R_STATUS)
                wb_head_op_cnt <= #U_DLY 'd0;
            else if(m_cur_st == WRITE_BUF && wb_cur_st == WB_HEAD && {op_req,op_ack} == 2'b11)
                wb_head_op_cnt <= #U_DLY wb_head_op_cnt + 'd1;
            else;

            if(m_cur_st == WRITE_BUF && wb_cur_st == WB_HEAD && {op_req,op_ack} == 2'b11)
                begin
                    if(wb_head_op_cnt >= 'd3)
                        wb_head_wdone <= #U_DLY 1'b1;
                    else
                        wb_head_wdone <= #U_DLY 1'b0;
                end
            else
                wb_head_wdone <= #U_DLY 1'b0;
        end
end       

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wb_userdata_wdone <= 1'b0;
            all_data_wdone <= 1'b0;
        end
    else
        begin
            if(m_cur_st == WRITE_BUF && wb_cur_st == WB_USER_DATA && {op_req,op_ack} == 2'b11)
                begin
                    if(all_data_wcnt == 'd0)                                //write to file end
                        wb_userdata_wdone <= #U_DLY 1'b1;
                    else if(cur_wb_addr[7:0] == 8'hff)                      //or write to the line boundary
                        wb_userdata_wdone <= #U_DLY 1'b1;
                    else
                        wb_userdata_wdone <= #U_DLY 1'b0;
                end
            else
                wb_userdata_wdone <= #U_DLY 1'b0;

            if(m_cur_st == WRITE_BUF && wb_cur_st == WB_USER_DATA && {op_req,op_ack} == 2'b11 && all_data_wcnt == 'd0)
                all_data_wdone <= #U_DLY 1'b1;
            else if(m_cur_st == IDLE)
                all_data_wdone <= #U_DLY 1'b0;
            else;
        end
end
                         
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        wb_confirm_wdone <= 1'b0;
    else
        begin
            if(m_cur_st == WRITE_BUF && wb_cur_st == WB_CONFIRM && {op_req,op_ack} == 2'b11)
                wb_confirm_wdone <= #U_DLY 1'b1;
            else
                wb_confirm_wdone <= #U_DLY 1'b0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            ry_byn_dly <= 3'd1;
            nobusy_rising <= 1'b0;
        end
    else
        begin
            ry_byn_dly <= #U_DLY {ry_byn_dly[1:0],ry_byn};

            if(ry_byn_dly[2:1] == 2'b01)
                nobusy_rising <= #U_DLY 1'b1;
            else
                nobusy_rising <= #U_DLY 1'b0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wb_status_cnt <= 2'd0;
            wb_status_rdone <= 1'b0;
            wb_status_cdone <= 1'b0;
            wb_done <= 1'b0;
        end
    else 
        begin
            if(nobusy_rising == 1'b1 || op_rvld == 1'b1)
                wb_status_cnt <= #U_DLY 'd0;
            else if(m_cur_st == WRITE_BUF && wb_cur_st == WB_R_STATUS && {op_req,op_ack} == 2'b11)      //indicate the second operate of the READ_STATUS commond
                wb_status_cnt <= #U_DLY wb_status_cnt + 'd1;
            else; 

            if(m_cur_st == WRITE_BUF && wb_cur_st == WB_R_STATUS && wb_status_cnt >= 'd2 && op_rvld == 1'b1)
                wb_status_rdone <= #U_DLY 1'b1;
            else
                wb_status_rdone <= #U_DLY 1'b0;

            if(m_cur_st == WRITE_BUF && wb_cur_st == WB_C_STATUS && {op_req,op_ack} == 2'b11)
                wb_status_cdone <= #U_DLY 1'b1;
            else
                wb_status_cdone <= #U_DLY 1'b0;

            if(all_data_wdone == 1'b1 && wb_status_cdone == 1'b1)
                wb_done <= #U_DLY 1'b1;
            else
                wb_done <= #U_DLY 1'b0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            inbuf_en <= 1'b0;
        end
    else 
        begin
            if(m_cur_st == WRITE_BUF)
                inbuf_en <= #U_DLY 1'b1;
            else
                inbuf_en <= #U_DLY 1'b0;
        end
end
//******************************************************************//
//read process
//******************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cur_rd_addr <= 'd0;
            all_data_rcnt <= 'd0;
            all_data_rdone <= 1'b0;
            rd_done <= 1'b0;
        end
    else
        begin
            if(rd_start_pulse == 1'b1)
                cur_rd_addr <= #U_DLY rd_start_addr;
            else if(m_cur_st == READ && {op_req,op_ack} == 2'b11)
                begin
                    if(cur_rd_addr != {ADDR_W{1'b1}})
                        cur_rd_addr <= #U_DLY cur_rd_addr + 'd1;
                    else;
                end
            else;

            if(rd_start_pulse == 1'b1)
                all_data_rcnt <= #U_DLY rd_word_len;
            else if(m_cur_st == READ && {op_req,op_ack} == 2'b11)
                begin
                    if(all_data_rcnt != 'd0)
                        all_data_rcnt <= #U_DLY all_data_rcnt - 'd1;
                    else;
                end
            else;

            if(m_cur_st == READ && {op_req,op_ack} == 2'b11 && all_data_rcnt <= 'd1)
                all_data_rdone <= #U_DLY 1'b1;
            else if(m_cur_st == IDLE)
                all_data_rdone <= #U_DLY 1'b0;
            else;

            if(m_cur_st == READ && all_data_rdone == 1'b1 && op_rvld == 1'b1)
                rd_done <= #U_DLY 1'b1;
            else
                rd_done <= #U_DLY 1'b0;
        end
end
//******************************************************************//
//erase process
//******************************************************************//               
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        e_cur_st <= E_IDLE;
    else
        e_cur_st <= #U_DLY e_next_st;
end

always @(*)
begin
    case(e_cur_st)
        E_IDLE:begin
            if(m_cur_st_dly == IDLE && m_cur_st == ERASE)
                e_next_st = E_CHIP_ERS;
            else
                e_next_st = E_IDLE;end
        E_CHIP_ERS:begin
            if(chip_ers_done == 1'b1)
                e_next_st = E_WAITING_NOBUSY;
            else
                e_next_st = E_CHIP_ERS;end
        E_WAITING_NOBUSY:begin
            if(r_sts_reg_en == 1'b0)                                 //judge by busy wire signal
                begin
                    if(nobusy_rising == 1'b1)
                        e_next_st = E_R_STATUS;
                    else
                        e_next_st = E_WAITING_NOBUSY;
                end
            else                                                     //judge by status register
                begin
                    if(nobusy_sr == 1'b1)
                        e_next_st = E_R_STATUS;
                    else
                        e_next_st = E_WAITING_NOBUSY;
                end
            end
        E_R_STATUS:begin
            if(e_status_rdone == 1'b1)
                e_next_st = E_C_STATUS;
            else
                e_next_st = E_R_STATUS;end
        E_C_STATUS:begin
            if(e_status_cdone == 1'b1)
                e_next_st = E_IDLE;
            else
                e_next_st = E_C_STATUS;end
        default:e_next_st = E_IDLE;
    endcase
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            erase_cnt <= 'd0;                                                
            chip_ers_done <= 1'b0;
            e_status_cnt <= 'd0;  
            e_status_rdone <= 1'b0;
            e_status_cdone <= 1'b0;
            ers_done <= 1'b0;
        end
    else
        begin
            if(e_cur_st == E_IDLE)
                erase_cnt <= #U_DLY 'd0;
            else if(m_cur_st == ERASE && e_cur_st == E_CHIP_ERS && {op_req,op_ack} == 2'b11)
                begin
                    if(erase_cnt >= 'd5)
                        erase_cnt <= #U_DLY 'd0;
                    else 
                        erase_cnt <= #U_DLY erase_cnt + 'd1;
                end
            else;

            if(m_cur_st == ERASE && e_cur_st == E_CHIP_ERS && {op_req,op_ack} == 2'b11 && erase_cnt >= 'd5)
                chip_ers_done <= #U_DLY 1'b1;
            else
                chip_ers_done <= #U_DLY 1'b0;

            if(nobusy_rising == 1'b1 || op_rvld == 1'b1)
                e_status_cnt <= #U_DLY 'd0;
            else if(m_cur_st == ERASE && e_cur_st == E_R_STATUS && {op_req,op_ack} == 2'b11)      //indicate the second operate of the READ_STATUS commond
                e_status_cnt <= #U_DLY e_status_cnt + 'd1;
            else;            

            if(m_cur_st == ERASE && e_cur_st == E_R_STATUS && e_status_cnt >= 'd2 && op_rvld == 1'b1)
                e_status_rdone <= #U_DLY 1'b1;
            else
                e_status_rdone <= #U_DLY 1'b0;
            
            if(m_cur_st == ERASE && e_cur_st == E_C_STATUS && {op_req,op_ack} == 2'b11)
                e_status_cdone <= #U_DLY 1'b1;
            else
                e_status_cdone <= #U_DLY 1'b0;

            ers_done <= #U_DLY e_status_cdone;
        end
end 
//******************************************************************//
//status register for busy/ready
//******************************************************************//    
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        r_sr_cur_st <= SR_IDLE;
    else
        r_sr_cur_st <= #U_DLY r_sr_next_st;
end

always @(*)
begin
    case(r_sr_cur_st)
        SR_IDLE:begin
            if(sr_polling_start == 1'b1)
                r_sr_next_st = SR_WRITE_CMD;    //write 0x70 to address 0x555
            else
                r_sr_next_st = SR_IDLE;end
        SR_WRITE_CMD:begin
            if(sr_wcmd_done == 1'b1)
                r_sr_next_st = SR_READ_STATUS;
            else 
                r_sr_next_st = SR_WRITE_CMD;end
        SR_READ_STATUS:begin
            if(op_rvld == 1'b1)
                begin
                   if(op_rdata[7] == 1'b1)       //Device Ready Bit
                       r_sr_next_st = SR_IDLE;
                   else
                       r_sr_next_st = SR_WRITE_CMD;
                end
            else
                r_sr_next_st = SR_READ_STATUS;end
        default:r_sr_next_st = SR_IDLE;
    endcase
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            sr_polling_start <= 1'b0;
            sr_wcmd_done <= 1'b0;
            nobusy_sr <= 1'b0;
        end
    else
        begin
            if((wb_confirm_wdone == 1'b1 || chip_ers_done == 1'b1) && r_sts_reg_en == 1'b1)
                sr_polling_start <= #U_DLY 1'b1;
            else
                sr_polling_start <= #U_DLY 1'b0;

            if(r_sr_cur_st == SR_WRITE_CMD && {op_req,op_ack} == 2'b11)
                sr_wcmd_done <= #U_DLY 1'b1;
            else
                sr_wcmd_done <= #U_DLY 1'b0;

            if(r_sr_cur_st == SR_READ_STATUS && op_rvld == 1'b1 && op_rdata[7] == 1'b1)
                nobusy_sr <= #U_DLY 1'b1;
            else
                nobusy_sr <= #U_DLY 1'b0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            r_sr_cur_st_dly <= SR_IDLE;
            sr_req_en <= 1'b0;
        end
    else
        begin
            r_sr_cur_st_dly <= #U_DLY r_sr_cur_st;
            
            if(r_sr_cur_st_dly != r_sr_cur_st && r_sr_cur_st != SR_IDLE)
                sr_req_en <= #U_DLY 1'b1;
            else
                sr_req_en <= #U_DLY 1'b0;
        end
end
//******************************************************************//
//data request process
//******************************************************************//                     
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            sector_addr <= 'd0;
            wc_num <= 'd0;
        end
    else
        begin
            if(m_cur_st == WRITE_BUF && wb_cur_st_dly != WB_HEAD && wb_cur_st == WB_HEAD)
                sector_addr <= #U_DLY {cur_wb_addr[16+:(ADDR_W - 16)],16'd0};
            else;

            if(m_cur_st == WRITE_BUF && wb_cur_st_dly != WB_HEAD && wb_cur_st == WB_HEAD)
                begin
                    if(all_data_wcnt[ADDR_W-1:8] == 'd0)
                        wc_num <= #U_DLY all_data_wcnt[7:0];
                    else
                        wc_num <= #U_DLY 8'hff - cur_wb_addr[7:0];
                end
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        op_req <= 1'b0;
    else
        begin
            if(op_ack == 1'b1)
                op_req <= #U_DLY 1'b0;  
            else if(m_cur_st == WRITE_BUF)
                begin
                    if(wb_cur_st == WB_HEAD || wb_cur_st == WB_USER_DATA)                   //head,user data and confirm
                        op_req <= #U_DLY 1'b1;
                    else if(wb_cur_st == WB_WAITING_NOBUSY && sr_req_en == 1'b1) //waiting device ready form the status register
                        op_req <= #U_DLY 1'b1;
                    else if(wb_cur_st == WB_R_STATUS && wb_status_cnt <= 'd1)               //read status request
                        op_req <= #U_DLY 1'b1;
                    else if(wb_status_rdone == 1'b1)                                        //clear status
                        op_req <= #U_DLY 1'b1;
                    else;
                end
            else if(m_cur_st == READ && all_data_rdone == 1'b0)
                op_req <= 1'b1;
            else if(m_cur_st == ERASE)
                begin
                    if(e_cur_st == E_CHIP_ERS && chip_ers_done != 1'b1)                     //erase cmd 
                        op_req <= #U_DLY 1'b1;
                    else if(e_cur_st == E_WAITING_NOBUSY && sr_req_en == 1'b1) //waiting device ready form the status register
                        op_req <= #U_DLY 1'b1;
                    else if(e_cur_st == E_R_STATUS && e_status_cnt <= 'd1)                  //read status request
                        op_req <= #U_DLY 1'b1;
                    else if(e_status_rdone == 1'b1)                                         //clear status
                        op_req <= #U_DLY 1'b1;
                    else;
                end
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        op_rw <= 1'b1;
    else
        begin
            if(m_cur_st == WRITE_BUF)
                begin
                    if(wb_cur_st == WB_HEAD || wb_cur_st == WB_USER_DATA || (wb_cur_st == WB_R_STATUS && wb_status_cnt == 'd0) || wb_status_rdone == 1'b1)
                        op_rw <= #U_DLY 1'b0;
                    else if(wb_cur_st == WB_WAITING_NOBUSY && sr_req_en == 1'b1)
                        begin
                            if(r_sr_cur_st == SR_WRITE_CMD)
                                op_rw <= #U_DLY 1'b0;
                            else
                                op_rw <= #U_DLY 1'b1;
                        end
                    else if(wb_cur_st == WB_R_STATUS && wb_status_cnt == 'd1)               //read status second request
                        op_rw <= #U_DLY 1'b1;
                    else;
                end
            else if(m_cur_st == READ)
                op_rw <= 1'b1;
            else if(m_cur_st == ERASE)
                begin
                    if(e_cur_st == E_CHIP_ERS && chip_ers_done != 1'b1 || (e_cur_st == E_R_STATUS && e_status_cnt == 'd0) || e_status_rdone == 1'b1)
                        op_rw <= #U_DLY 1'b0;
                    else if(e_cur_st == E_WAITING_NOBUSY && sr_req_en == 1'b1)
                        begin
                            if(r_sr_cur_st == SR_WRITE_CMD)
                                op_rw <= #U_DLY 1'b0;
                            else
                                op_rw <= #U_DLY 1'b1;
                        end
                    else if(e_cur_st == E_R_STATUS && e_status_cnt == 'd1)                  //read status second request
                        op_rw <= #U_DLY 1'b1;
                    else;
                end
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        op_addr <= 'd0;
    else
        begin
            if(m_cur_st == WRITE_BUF)
                begin
                    if(wb_cur_st == WB_HEAD)
                        begin
                            case(wb_head_op_cnt)
                                'd0:op_addr <= #U_DLY 'h555;                                      //write buffer commond address
                                'd1:op_addr <= #U_DLY 'h2AA;
                                'd2,'d3:op_addr <= #U_DLY sector_addr;                            //SA  
                                default:op_addr <= #U_DLY 'h555;
                            endcase
                        end
                    else if(wb_cur_st == WB_USER_DATA)
                        op_addr <= #U_DLY cur_wb_addr;
                    else if(wb_cur_st == WB_CONFIRM)
                        op_addr <= #U_DLY sector_addr;
                    else if(wb_cur_st == WB_R_STATUS || wb_cur_st == WB_WAITING_NOBUSY)
                        op_addr <= #U_DLY 'h555;
                    else if(wb_cur_st == WB_C_STATUS)    
                        op_addr <= #U_DLY 'h555;
                    else;
                end 
           else if(m_cur_st == READ)  
               op_addr <= #U_DLY cur_rd_addr;  
           else if(m_cur_st == ERASE)  
               begin
                   if(e_cur_st == E_CHIP_ERS) 
                       begin
                           case(erase_cnt)
                               'd0,'d2,'d3:op_addr <= #U_DLY 'h555;
                               'd1,'d4:    op_addr <= #U_DLY 'h2AA;
                               'd5:begin
                                   if(ers_sa_en == 1'b1)
                                       op_addr <= #U_DLY {ers_sa,16'd0};
                                   else
                                       op_addr <= #U_DLY 'h555;end  
                               default:op_addr <= #U_DLY 'h555;
                           endcase
                       end
                   else if(e_cur_st == E_R_STATUS || e_cur_st == E_WAITING_NOBUSY)
                       op_addr <= #U_DLY 'h555;
                   else if(e_cur_st == E_C_STATUS)
                       op_addr <= #U_DLY 'h555;
                   else;
               end
           else;
       end
end   

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        op_wdata <= 'd0;
    else
        begin
            if(m_cur_st == WRITE_BUF)
                begin
                    if(wb_cur_st == WB_HEAD)
                        begin
                            case(wb_head_op_cnt)
                                'd0:op_wdata <= #U_DLY 'hAA;
                                'd1:op_wdata <= #U_DLY 'h55;
                                'd2:op_wdata <= #U_DLY 'h25;
                                'd3:op_wdata <= #U_DLY {{(DATA_W-8){1'b0}},wc_num};
                                default:op_wdata <= #U_DLY 'hAA;
                            endcase
                        end
                    else if(wb_cur_st == WB_USER_DATA)
                        op_wdata <= #U_DLY wdata_latch;
                    else if(wb_cur_st == WB_CONFIRM)
                        op_wdata <= #U_DLY 'h29;
                    else if(wb_cur_st == WB_R_STATUS || wb_cur_st == WB_WAITING_NOBUSY)
                        op_wdata <= #U_DLY 'h70;
                    else if(wb_cur_st == WB_C_STATUS)
                        op_wdata <= #U_DLY 'h71;
                    else;
                end
            else if(m_cur_st == ERASE)
               begin
                   if(e_cur_st == E_CHIP_ERS) 
                       begin
                           case(erase_cnt)
                               'd0,'d3:op_wdata <= #U_DLY 'hAA;
                               'd1,'d4:op_wdata <= #U_DLY 'h55;
                               'd2:op_wdata <= #U_DLY 'h80;
                               'd5:begin
                                   if(ers_sa_en == 1'b1)
                                       op_wdata <= #U_DLY 'h30;
                                   else
                                       op_wdata <= #U_DLY 'h10;end
                               default:op_wdata <= #U_DLY 'hAA;
                           endcase
                       end
                   else if(e_cur_st == E_R_STATUS || e_cur_st == E_WAITING_NOBUSY)
                        op_wdata <= #U_DLY 'h70;
                   else if(e_cur_st == E_C_STATUS)
                        op_wdata <= #U_DLY 'h71;
                   else;
               end
           else;
       end
end
//******************************************************************//
//status process
//******************************************************************//                          
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wb_fail <= 1'b0;
            ers_fail <= 1'b0;
            st_free <= 1'b1;
        end
    else
        begin
            if(m_cur_st == WRITE_BUF && wb_cur_st == WB_R_STATUS && wb_status_cnt >= 'd2 && op_rvld == 1'b1)
                wb_fail <= #U_DLY op_rdata[4];                   //program status bit
            else
                wb_fail <= #U_DLY 1'b0;

            if(m_cur_st == ERASE && e_cur_st == E_R_STATUS && e_status_cnt >= 'd2 && op_rvld == 1'b1)
                ers_fail <= #U_DLY op_rdata[5];                  //Erase status bit
            else
                ers_fail <= #U_DLY 1'b0;

            if(m_cur_st == IDLE)
                st_free <= #U_DLY 1'b1;
            else
                st_free <= #U_DLY 1'b0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wb_reg_done <= 1'b0;
            rd_reg_done <= 1'b0;
            ers_reg_done <= 1'b0;
        end
    else
        begin
            if(wb_reg_done == 1'b1)
                wb_reg_done <= #U_DLY 1'b0;
            else if(wb_done == 1'b1)
                wb_reg_done <= #U_DLY 1'b1;
            else;

            if(rd_reg_done == 1'b1)
                rd_reg_done <= #U_DLY 1'b0;
            else if(rd_done == 1'b1)
                rd_reg_done <= #U_DLY 1'b1;
            else;

            if(ers_reg_done == 1'b1)
                ers_reg_done <= #U_DLY 1'b0;
            else if(ers_done == 1'b1)
                ers_reg_done <= #U_DLY 1'b1;
            else;
        end
end
//******************************************************************//
//data process
//******************************************************************// 
assign wdata_change_order = {wdata[0],wdata[1],wdata[2],wdata[3],wdata[4],wdata[5],wdata[6],wdata[7],wdata[8],wdata[9],wdata[10],wdata[11],wdata[12],wdata[13],wdata[14],wdata[15]};
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wdata_latch <= 'd0;
            wdata_ren <= 1'b0;
        end
    else
        begin
            //if(wb_start_pulse == 1'b1 || wdata_ren == 1'b1)
            if(wdata_ren == 1'b1)
                begin
                    if(bit_order == 1'b0)
                        wdata_latch <= #U_DLY wdata;
                    else
                        wdata_latch <= #U_DLY wdata_change_order;
                end
             else;

            //if(wb_start_pulse == 1'b1)
            //if(wb_cur_st == WB_HEAD && wb_cur_st_dly != WB_HEAD)
            if(wb_cur_st == WB_USER_DATA && wb_cur_st_dly == WB_HEAD)
                wdata_ren <= #U_DLY 1'b1;
            else if(m_cur_st == WRITE_BUF && wb_cur_st == WB_USER_DATA && {op_req,op_ack} == 2'b11 && all_data_wcnt != 'd0 &&  cur_wb_addr[7:0] != 8'hff) //last data ren
                wdata_ren <= #U_DLY 1'b1;
            else
                wdata_ren <= #U_DLY 1'b0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1) 
        begin
            rdata <= 'd0;
            rvld <= 1'b0;
        end
    else
        begin
            if(m_cur_st == READ)
                rdata <= #U_DLY op_rdata;
            else;
          
            if(m_cur_st == READ)    
               rvld <= #U_DLY op_rvld;
            else;
        end
end  
 

endmodule

