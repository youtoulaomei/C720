// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2017/12/11 11:34:26
// File Name    : i2c_phy.v
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
module i2c_phy #(
parameter                           U_DLY = 1,
parameter                           CPU_ADDR_W = 7,
parameter                           DATA_BIT_LEN = 8
)
(
input                               clk,
input                               rst,
//i2c sda scl
inout   wire                        sda,
(* IOB="true" *)output  reg         scl/* synthesis syn_useioff = 1 */,
//cpu interface
input                               cpu_cs,
input                               cpu_we,
input                               cpu_rd,
input           [CPU_ADDR_W - 1:0]  cpu_addr,
input           [31:0]              cpu_wdata,
output  wire    [31:0]              cpu_rdata,
//config
input                               i2c_start,
input           [23:0]              i2c_scl_prd,          //min freq:10K
input           [2:0]               i2c_header_len,
input           [5:0]               i2c_op_len,
input           [15:0]              i2c_sta_hold,         //start hold time.a high-to-low transition of SDA.
input           [15:0]              i2c_sto_setup,
input                               last_read_ack,
output  reg                         slave_no_ack,
output  reg                         i2c_master_free,
//others
input                               authorize_succ
);
// Parameter Define 
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

localparam                          DATA_BIT_LEN_W = clog2b(DATA_BIT_LEN);
localparam                          LVL1_IDLE = 6'b00_0001;  
localparam                          START = 6'b00_0010;  
localparam                          SEND_HEADER = 6'b00_0100;  
localparam                          I2C_WRITE = 6'b00_1000;  
localparam                          I2C_READ = 6'b01_0000; 
localparam                          STOP = 6'b10_0000; 

localparam                          LVL2_W_IDLE = 3'b001;
localparam                          SEND_DATA = 3'b010;
localparam                          WAITING_ACK = 3'b100;

localparam                          LVL2_R_IDLE = 3'b001;
localparam                          RECE_DATA = 3'b010;
localparam                          SEND_ACK = 3'b100;
// Register Define 
reg                                 i2c_start_dly;
reg     [DATA_BIT_LEN - 1:0]        tdata_ram[2**(CPU_ADDR_W-1) - 1:0]/* synthesis syn_ramstyle="block_ram" */;
reg                                 tdata_ram_wen;
reg     [DATA_BIT_LEN - 1:0]        tdata_ram_wdata;
reg     [DATA_BIT_LEN - 1:0]        tdata_ram_p1_rdata_pre;
reg     [DATA_BIT_LEN - 1:0]        tdata_ram_p1_rdata;
reg     [DATA_BIT_LEN - 1:0]        tdata_ram_p0_rdata_pre;
reg     [DATA_BIT_LEN - 1:0]        tdata_ram_p0_rdata;
reg     [CPU_ADDR_W - 2:0]          tdata_ram_p0_addr;
reg                                 tdata_ram_p0_ren;
reg     [1:0]                       tdata_ram_p0_ren_dly;
reg                                 tdata_ram_p1_ren;
reg     [1:0]                       tdata_ram_p1_ren_dly;
reg     [CPU_ADDR_W - 2:0]          tdata_ram_p1_raddr;
reg     [5:0]                       lvl1_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [5:0]                       lvl1_next_st;
reg     [2:0]                       lvl2_w_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [2:0]                       lvl2_w_next_st;
reg     [2:0]                       lvl2_r_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [2:0]                       lvl2_r_next_st;
reg     [15:0]                      sta_hold_cnt;
reg                                 start_done;
reg                                 rw_ind;
reg                                 wbyte_send_en;
reg                                 wbyte_send_done;
reg                                 send_header_done;
reg                                 wdata_done;
reg                                 rbyte_rec_en;
reg                                 rbyte_rec_done;
reg                                 rdata_done;
reg     [2:0]                       send_header_cnt;
reg     [5:0]                       wbyte_cnt;
reg     [DATA_BIT_LEN_W:0]          bit_send_cnt;
reg     [5:0]                       rbyte_cnt;
reg     [DATA_BIT_LEN_W:0]          bit_rec_cnt;
reg     [23:0]                      i2c_prd_cnt;
reg     [15:0]                      sto_setup_cnt;
reg                                 stop_done;
reg     [DATA_BIT_LEN - 1:0]        send_data_shift;
reg                                 sda_oe;
(* IOB="true" *)reg                 sda_in_dly;
(* IOB="true" *)reg                 sda_o;
reg     [31:0]                      cpu_rdata_w;
reg     [DATA_BIT_LEN - 1:0]        rec_data_shift;
reg                                 rdata_ram_wen;
reg     [DATA_BIT_LEN - 1:0]        rdata_ram_wdata;
reg     [CPU_ADDR_W - 2:0]          rdata_ram_waddr;
reg     [DATA_BIT_LEN - 1:0]        rdata_ram_rdata_pre;
reg     [DATA_BIT_LEN - 1:0]        rdata_ram_rdata;
reg                                 rdata_ram_ren;
reg     [1:0]                       rdata_ram_ren_dly;
reg     [31:0]                      cpu_rdata_r;
reg     [CPU_ADDR_W - 2:0]          rdata_ram_raddr;
reg     [DATA_BIT_LEN - 1:0]        rdata_ram[2**(CPU_ADDR_W-1) - 1:0]/* synthesis syn_ramstyle="block_ram" */;
reg                                 cpu_rd_dly;
reg                                 cpu_we_dly;
reg                                 waiting_ack_done;
reg                                 send_ack_done;
reg                                 sda_trans_ind;
reg                                 i2c_prd_cnt_over;
reg                                 i2c_rec_sample_ind;
reg                                 master_ack_value;
// Wire Define 

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            i2c_start_dly <= #U_DLY 1'b0;
            cpu_rd_dly <= 1'b1;
            cpu_we_dly <= 1'b1;
        end
    else
        begin
            i2c_start_dly <= #U_DLY i2c_start;
            cpu_rd_dly <= #U_DLY cpu_rd;
            cpu_we_dly <= #U_DLY cpu_we;
        end
end
//write data ram
always @(posedge clk)
begin
    if(tdata_ram_wen == 1'b1)
        tdata_ram[tdata_ram_p0_addr] <= #U_DLY tdata_ram_wdata;
    else;

    tdata_ram_p1_rdata_pre <= #U_DLY tdata_ram[tdata_ram_p1_raddr];
    tdata_ram_p1_rdata <= #U_DLY tdata_ram_p1_rdata_pre;

    tdata_ram_p0_rdata_pre <= #U_DLY tdata_ram[tdata_ram_p0_addr];
    tdata_ram_p0_rdata <= #U_DLY tdata_ram_p0_rdata_pre;
end    

//p0 port
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            tdata_ram_wen <= 1'b0;
            tdata_ram_p0_addr <= 'd0;
            tdata_ram_wdata <= 'd0;
        end
    else
        begin
            if({cpu_we_dly,cpu_we} == 2'b10 && cpu_cs == 1'b0 && cpu_addr[CPU_ADDR_W - 1] == 1'b0)
                tdata_ram_wen <= #U_DLY 1'b1;
            else
                tdata_ram_wen <= #U_DLY 1'b0;

            if(({cpu_we_dly,cpu_we} == 2'b10 || {cpu_rd_dly,cpu_rd} == 2'b10) && cpu_cs == 1'b0)
                tdata_ram_p0_addr <= #U_DLY cpu_addr[CPU_ADDR_W - 2:0];
            else;

            if({cpu_we_dly,cpu_we} == 2'b10 && cpu_cs == 1'b0)
                tdata_ram_wdata <= #U_DLY cpu_wdata[DATA_BIT_LEN - 1:0];
            else; 
        end
end   

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            tdata_ram_p0_ren <= 1'b0;
            tdata_ram_p0_ren_dly <= 2'd0;
            cpu_rdata_w <= 'd0;
        end
    else
        begin
            if({cpu_rd_dly,cpu_rd} == 2'b10 && cpu_cs == 1'b0 && cpu_addr[CPU_ADDR_W - 1] == 1'b0)
                tdata_ram_p0_ren <= #U_DLY 1'b1;
            else
                tdata_ram_p0_ren <= #U_DLY 1'b0;

            tdata_ram_p0_ren_dly <= #U_DLY {tdata_ram_p0_ren_dly[0],tdata_ram_p0_ren};

            if(tdata_ram_p0_ren_dly[1] == 1'b1)
                cpu_rdata_w <= #U_DLY {{(32-DATA_BIT_LEN){1'b0}},tdata_ram_p0_rdata}; 
            else;
        end
end      
//p1 port read
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            tdata_ram_p1_ren <= 1'b0;
            tdata_ram_p1_ren_dly <= 2'd0;
            tdata_ram_p1_raddr <= 'd0;
        end
    else
        begin
            if(tdata_ram_p1_ren == 1'b1)
                tdata_ram_p1_ren <= #U_DLY 1'b0;
            else if(wbyte_send_en == 1'b1)
                tdata_ram_p1_ren <= #U_DLY 1'b1;
            else;

            tdata_ram_p1_ren_dly <= #U_DLY {tdata_ram_p1_ren_dly[0],tdata_ram_p1_ren};

            if({i2c_start_dly,i2c_start} == 2'b01)
                tdata_ram_p1_raddr <= #U_DLY 'd0;
            else if(tdata_ram_p1_ren == 1'b1)
                tdata_ram_p1_raddr <= #U_DLY tdata_ram_p1_raddr + 'd1;
            else;
        end
end
//level 1 sm
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        lvl1_cur_st <= LVL1_IDLE;
    else
        lvl1_cur_st <= lvl1_next_st;
end

always @(*)
begin
    if(slave_no_ack == 1'b1 || authorize_succ == 1'b0)
        //lvl1_next_st = LVL1_IDLE;
        lvl1_next_st = STOP;
    else
        begin
            case(lvl1_cur_st)
                LVL1_IDLE:begin
                    if({i2c_start_dly,i2c_start} == 2'b01)
                        lvl1_next_st = START;
                    else
                        lvl1_next_st = LVL1_IDLE;end
                START:begin
                    if(start_done == 1'b1)
                        lvl1_next_st = SEND_HEADER;
                    else
                        lvl1_next_st = START;end
                SEND_HEADER:begin
                    if(send_header_done == 1'b1)
                        begin
                            if(rw_ind == 1'b0)
                                lvl1_next_st = I2C_WRITE;
                            else
                                lvl1_next_st = I2C_READ;
                        end
                    else
                        lvl1_next_st = SEND_HEADER;end
                I2C_WRITE:begin
                    if(wdata_done == 1'b1)
                        lvl1_next_st = STOP;
                    else
                        lvl1_next_st = I2C_WRITE;end
                I2C_READ:begin
                    if(rdata_done == 1'b1)
                        lvl1_next_st = STOP;
                    else
                        lvl1_next_st = I2C_READ;end
                STOP:begin
                    if(stop_done == 1'b1)
                        lvl1_next_st = LVL1_IDLE;
                    else
                        lvl1_next_st = STOP;end
                default:lvl1_next_st = LVL1_IDLE;
            endcase
        end
end
//level 2 sm(write)
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        lvl2_w_cur_st <= LVL2_W_IDLE;
    else
        lvl2_w_cur_st <= #U_DLY lvl2_w_next_st;
end

always @(*)
begin
    if(slave_no_ack == 1'b1)
        lvl2_w_next_st = LVL2_W_IDLE;
    else
        begin
            case(lvl2_w_cur_st)
                LVL2_W_IDLE:begin
                    if(wbyte_send_en == 1'b1)
                        lvl2_w_next_st = SEND_DATA;
                    else
                        lvl2_w_next_st = LVL2_W_IDLE;end
                SEND_DATA:begin
                    if(wbyte_send_done == 1'b1)
                        lvl2_w_next_st = WAITING_ACK;
                    else
                        lvl2_w_next_st = SEND_DATA;end
                WAITING_ACK:begin
                    if(waiting_ack_done == 1'b1)
                        lvl2_w_next_st = LVL2_W_IDLE;
                    else
                        lvl2_w_next_st = WAITING_ACK;end
                default:lvl2_w_next_st = LVL2_W_IDLE;
            endcase
        end
    
end
//level 2 sm(read)    
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        lvl2_r_cur_st <= LVL2_R_IDLE;
    else
        lvl2_r_cur_st <= #U_DLY lvl2_r_next_st;
end

always @(*)
begin
    if(slave_no_ack == 1'b1)
        lvl2_r_next_st = LVL2_R_IDLE;
    else
        begin
            case(lvl2_r_cur_st)
                LVL2_R_IDLE:begin
                    if(rbyte_rec_en == 1'b1)
                        lvl2_r_next_st = RECE_DATA;
                    else
                        lvl2_r_next_st = LVL2_R_IDLE;end
                RECE_DATA:begin
                    if(rbyte_rec_done == 1'b1)
                        lvl2_r_next_st = SEND_ACK;
                    else
                        lvl2_r_next_st = RECE_DATA;end
                SEND_ACK:begin
                    if(send_ack_done == 1'b1)
                        lvl2_r_next_st = LVL2_R_IDLE;
                    else
                        lvl2_r_next_st = SEND_ACK;end
                default:lvl2_r_next_st = LVL2_R_IDLE;
            endcase
        end
end
//timing control
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            sta_hold_cnt <= 'd0;
            start_done <= 1'b0;
            rw_ind <= 1'b1;
        end
    else
        begin
            if({i2c_start_dly,i2c_start} == 2'b01)
                sta_hold_cnt <= #U_DLY i2c_sta_hold;
            else if(sta_hold_cnt != 'd0)
                sta_hold_cnt <= #U_DLY sta_hold_cnt - 'd1;
            else;

            if(sta_hold_cnt == 'd1)
                start_done <= #U_DLY 1'b1;
            else
                start_done <= #U_DLY 1'b0;

            if(tdata_ram_p1_ren_dly[1] == 1'b1 && lvl1_cur_st == SEND_HEADER && send_header_cnt == (i2c_header_len - 'd1))
                rw_ind <= #U_DLY tdata_ram_p1_rdata[0];
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            wbyte_send_en <= 1'b0;
            wbyte_send_done <= 1'b0;
            send_header_done <= 1'b0;
            wdata_done <= 1'b0;
            rbyte_rec_en <= 1'b0;
            rbyte_rec_done <= 1'b0;
            rdata_done <= 1'b0;
            waiting_ack_done <= 1'b0;
            send_ack_done <= 1'b0;
        end
    else
        begin
            if(wbyte_send_en == 1'b1)
                wbyte_send_en <= #U_DLY 1'b0;
            else if(lvl1_cur_st == SEND_HEADER && lvl2_w_cur_st == LVL2_W_IDLE && send_header_cnt != 'd0)  //send header
                wbyte_send_en <= #U_DLY 1'b1; 
            else if(lvl1_cur_st == I2C_WRITE && lvl2_w_cur_st == LVL2_W_IDLE && wbyte_cnt != 'd0)
                wbyte_send_en <= #U_DLY 1'b1;
            else;

            if(wbyte_send_done == 1'b1)
                wbyte_send_done <= #U_DLY 1'b0;
            else if(lvl2_w_cur_st == SEND_DATA && bit_send_cnt == 'd0)
                wbyte_send_done <= #U_DLY 1'b1;
            else;  

            if(send_header_done == 1'b1)
                send_header_done <= #U_DLY 1'b0;
            else if(lvl1_cur_st == SEND_HEADER && lvl2_w_cur_st == LVL2_W_IDLE && send_header_cnt == 'd0)
                send_header_done <= #U_DLY 1'b1;
            else;

            if(wdata_done == 1'b1)
                wdata_done <= #U_DLY 1'b0;
            else if(lvl1_cur_st == I2C_WRITE && lvl2_w_cur_st == LVL2_W_IDLE && wbyte_cnt == 'd0)
                wdata_done <= #U_DLY 1'b1;
            else;

            if(rbyte_rec_en == 1'b1)
                rbyte_rec_en <= #U_DLY 1'b0;
            else if(lvl1_cur_st == I2C_READ && lvl2_r_cur_st == LVL2_R_IDLE && rbyte_cnt != 'd0)
                rbyte_rec_en <= #U_DLY 1'b1;
            else;

            if(rbyte_rec_done == 1'b1)
                rbyte_rec_done <= #U_DLY 1'b0;
            else if(lvl2_r_cur_st == RECE_DATA && bit_rec_cnt == 'd0)
                rbyte_rec_done <= #U_DLY 1'b1;
            else;

            if(rdata_done == 1'b1)
                rdata_done <= #U_DLY 1'b0;
            else if(lvl1_cur_st == I2C_READ && lvl2_r_cur_st == LVL2_R_IDLE && rbyte_cnt == 'd0)
                rdata_done <= #U_DLY 1'b1;
            else;

            if(waiting_ack_done == 1'b1)
                waiting_ack_done <= #U_DLY 1'b0;
            else if(lvl2_w_cur_st == WAITING_ACK && i2c_prd_cnt >= i2c_scl_prd)
                waiting_ack_done <= #U_DLY 1'b1;
            else;

            if(send_ack_done == 1'b1)
                send_ack_done <= #U_DLY 1'b0;
            else if(lvl2_r_cur_st == SEND_ACK && i2c_prd_cnt >= i2c_scl_prd)
                send_ack_done <= #U_DLY 1'b1;
            else;
        end
end
             
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            send_header_cnt <= 'd0;
            wbyte_cnt <= 'd0;
            bit_send_cnt <= 'd0;
            rbyte_cnt <= 'd0;
            bit_rec_cnt <= 'd0;
        end
    else
        begin
            if({i2c_start_dly,i2c_start} == 2'b01)
                send_header_cnt <= #U_DLY i2c_header_len;
            else if(wbyte_send_en == 1'b1 && lvl1_cur_st == SEND_HEADER)
                send_header_cnt <= #U_DLY send_header_cnt - 'd1;
            else;

            if({i2c_start_dly,i2c_start} == 2'b01)
                wbyte_cnt <= #U_DLY i2c_op_len;
            else if(wbyte_send_en == 1'b1 && lvl1_cur_st == I2C_WRITE)
                wbyte_cnt <= #U_DLY wbyte_cnt - 'd1;
            else;

            if((lvl1_cur_st == SEND_HEADER || lvl1_cur_st == I2C_WRITE) && wbyte_send_en == 1'b1)
                bit_send_cnt <= #U_DLY DATA_BIT_LEN;
            else if(i2c_prd_cnt_over == 1'b1 && bit_send_cnt > 'd0)
                bit_send_cnt <= #U_DLY bit_send_cnt - 'd1;
            else;

            if({i2c_start_dly,i2c_start} == 2'b01)
                rbyte_cnt <= #U_DLY i2c_op_len;
            else if(rbyte_rec_en == 1'b1 && lvl1_cur_st == I2C_READ)
                rbyte_cnt <= #U_DLY rbyte_cnt - 'd1;
            else;

            if(lvl1_cur_st == I2C_READ && rbyte_rec_en == 1'b1)
                bit_rec_cnt <= #U_DLY DATA_BIT_LEN;
            else if(i2c_prd_cnt_over == 1'b1)
                bit_rec_cnt <= #U_DLY bit_rec_cnt - 'd1;
            else;
        end
end 
                
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            i2c_prd_cnt <= 'd0;
            sto_setup_cnt <= 'd0;
            stop_done <= 'd0;
        end
    else
        begin
            if({i2c_start_dly,i2c_start} == 2'b01 || i2c_prd_cnt >= i2c_scl_prd || lvl1_cur_st == LVL1_IDLE)
                i2c_prd_cnt <= 'd0;
            else if(lvl1_cur_st == SEND_HEADER || lvl1_cur_st == I2C_WRITE || lvl1_cur_st == I2C_READ || lvl1_cur_st == STOP)
                i2c_prd_cnt <= #U_DLY i2c_prd_cnt + 'd1;
            else;

            if(lvl1_cur_st == STOP && i2c_prd_cnt == (i2c_scl_prd >> 1))
                sto_setup_cnt <= #U_DLY i2c_sto_setup;
            else if(sto_setup_cnt != 'd0)
                sto_setup_cnt <= #U_DLY sto_setup_cnt - 'd1;
            else;

            if(sto_setup_cnt == 'd1)
                stop_done <= #U_DLY 1'b1;
            else
                stop_done <= #U_DLY 1'b0;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            send_data_shift <= 'd0;
            sda_trans_ind <= 1'b0;
            i2c_prd_cnt_over <= 1'b0; 
            master_ack_value <= 1'b0;
        end
    else
        begin
            if(tdata_ram_p1_ren_dly[1] == 1'b1)
                send_data_shift <= #U_DLY tdata_ram_p1_rdata;
            else if(sda_trans_ind == 1'b1)
                send_data_shift <= #U_DLY send_data_shift << 1;
            else;

            if(sda_trans_ind == 1'b1)
                sda_trans_ind <= #U_DLY 1'b0;
            else if(i2c_prd_cnt == (i2c_scl_prd >> 2))
                sda_trans_ind <= #U_DLY 1'b1;
            else;

            if(i2c_prd_cnt_over == 1'b1)
                i2c_prd_cnt_over <= #U_DLY 1'b0;
            else if(i2c_prd_cnt >= i2c_scl_prd)
                i2c_prd_cnt_over <= #U_DLY 1'b1;
            else;

            if(lvl2_r_cur_st == SEND_ACK && rbyte_cnt == 'd0)
                master_ack_value <= #U_DLY last_read_ack;
            else
                master_ack_value <= #U_DLY 1'b0; 
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        scl <= 1'b1;
    else
        begin
            if(lvl1_cur_st == SEND_HEADER || lvl1_cur_st == I2C_WRITE || lvl1_cur_st == I2C_READ || lvl1_cur_st == STOP) 
                begin
                    if(i2c_prd_cnt <= (i2c_scl_prd >> 1))
                        scl <= #U_DLY 1'b0;
                    else
                        scl <= #U_DLY 1'b1;
                end
            else
                scl <= #U_DLY 1'b1;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            sda_oe <= 1'b0;
            sda_o <= 1'b1;
        end
    else
        begin
            if(lvl1_cur_st == LVL1_IDLE)
                sda_o <= #U_DLY 1'b1;
            else if(lvl1_cur_st == START)
                    sda_o <= #U_DLY 1'b0;
            else if(lvl1_cur_st == SEND_HEADER || lvl1_cur_st == I2C_WRITE)
                begin
                    if(sda_trans_ind == 1'b1)                   //1/4 period
                        sda_o <= #U_DLY send_data_shift[DATA_BIT_LEN - 1];
                    else;
                end
            else if((lvl1_cur_st == I2C_READ && lvl2_r_cur_st == SEND_ACK) && sda_trans_ind == 1'b1)
                sda_o <= #U_DLY master_ack_value;
            else if(lvl1_cur_st == STOP && sda_trans_ind == 1'b1)
                sda_o <= #U_DLY 1'b0;
            else;

            if(lvl1_cur_st == LVL1_IDLE)
                sda_oe <= #U_DLY 1'b0;
            else if(lvl2_w_cur_st == WAITING_ACK || lvl2_r_cur_st == RECE_DATA)
                begin
                    if(sda_trans_ind == 1'b1)
                        sda_oe <= #U_DLY 1'b1;
                    else;
                end
            else if(sda_trans_ind == 1'b1)
                sda_oe <= #U_DLY 1'b0;
            else;
        end
end

IOBUF #(
    .DRIVE                      (12                         ),
    .IBUF_LOW_PWR               ("FALSE"                    ),
    .IOSTANDARD                 ("DEFAULT"                  ),
    .SLEW                       ("SLOW"                     )
) 
IOBUF_inst (
    .O                          (sda_in                     ), // Buffer output
    .IO                         (sda                        ), // Buffer inout port (connect directly to top-level port)
    .I                          (sda_o                      ), // Buffer input
    .T                          (sda_oe                     )  // 3-state enable input, high=input, low=output
);
//read data
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            i2c_rec_sample_ind <= 1'b0;
            rec_data_shift <= 'd0;
            rdata_ram_wen <= 1'b0;
            rdata_ram_wdata <= 'd0;
            rdata_ram_waddr <= 'd0;
        end
    else
        begin
            if(i2c_rec_sample_ind == 1'b1)
                i2c_rec_sample_ind <= #U_DLY 1'b0;
            else if(i2c_prd_cnt == ((i2c_scl_prd >> 2) + (i2c_scl_prd >> 2) + (i2c_scl_prd >> 2))) //3/4 period
                i2c_rec_sample_ind <= #U_DLY 1'b1;
            else;

            if(rbyte_rec_en == 1'b1)
                rec_data_shift <= #U_DLY 'd0;
            else if(lvl2_r_cur_st == RECE_DATA)
                begin
                    if(i2c_rec_sample_ind == 1'b1)
                        rec_data_shift <= #U_DLY {rec_data_shift[DATA_BIT_LEN-2:0],sda_in_dly};
                    else;
                end
            else;

            if(rbyte_rec_done == 1'b1)
                rdata_ram_wen <= #U_DLY 1'b1;
            else
                rdata_ram_wen <= #U_DLY 1'b0;

            if(rbyte_rec_done == 1'b1)
                rdata_ram_wdata <= #U_DLY rec_data_shift;
            else;

            if({i2c_start_dly,i2c_start} == 2'b01)
                rdata_ram_waddr <= #U_DLY 'd0;
            else if(rdata_ram_wen == 1'b1)
                rdata_ram_waddr <= #U_DLY rdata_ram_waddr + 'd1;
            else;
        end
end

always @(posedge clk)
begin
    if(rdata_ram_wen == 1'b1)
        rdata_ram[rdata_ram_waddr] <= #U_DLY rdata_ram_wdata;
    else;

    rdata_ram_rdata_pre <= #U_DLY rdata_ram[rdata_ram_raddr];
    rdata_ram_rdata <= #U_DLY rdata_ram_rdata_pre;
end    

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            rdata_ram_ren <= 1'b0;
            rdata_ram_ren_dly <= 2'd0;
            rdata_ram_raddr <= 'd0;
            cpu_rdata_r <= 'd0;
        end
    else
        begin
            if({cpu_rd_dly,cpu_rd} == 2'b10 && cpu_cs == 1'b0 && cpu_addr[CPU_ADDR_W - 1] == 1'b1)
                rdata_ram_ren <= #U_DLY 1'b1;
            else
                rdata_ram_ren <= #U_DLY 1'b0;

            rdata_ram_ren_dly <= #U_DLY {rdata_ram_ren_dly[0],rdata_ram_ren};

            if({cpu_rd_dly,cpu_rd} == 2'b10 && cpu_cs == 1'b0 && cpu_addr[CPU_ADDR_W - 1] == 1'b1)
                rdata_ram_raddr <= #U_DLY cpu_addr[DATA_BIT_LEN - 2:0];
            else;

            if(rdata_ram_ren_dly[1] == 1'b1)
                cpu_rdata_r <= #U_DLY {{(32-DATA_BIT_LEN){1'b0}},rdata_ram_rdata}; 
            else;
        end
end      

assign cpu_rdata = (cpu_addr[CPU_ADDR_W - 1] == 1'b0) ? cpu_rdata_w : cpu_rdata_r;
//abnormal,the slave not response
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            slave_no_ack <= 1'b0;
            i2c_master_free <= 1'b1;
            sda_in_dly <= 1'b0;
        end
    else
        begin
            if(lvl2_w_cur_st == WAITING_ACK && i2c_rec_sample_ind == 1'b1 && sda_in_dly == 1'b1)
                slave_no_ack <= #U_DLY 1'b1;
            else
                slave_no_ack <= #U_DLY 1'b0;

            if(lvl1_cur_st == LVL1_IDLE)
                i2c_master_free <= #U_DLY 1'b1;
            else
                i2c_master_free <= #U_DLY 1'b0;

            sda_in_dly <= #U_DLY sda_in; 
        end
end

endmodule

