// *********************************************************************************/
// Project Name :
// Author       : yangyong
// Email        : 
// Creat Time   : 2018/3/5 10:45:23
// File Name    : mefc_phy.v
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
module mefc_phy #(
parameter                           U_DLY = 1,
parameter                           ADDR_W = 26,
parameter                           DATA_W = 16
)
(
input                               clk,                        //100m,if the clock is not 100MHz,must modify the parameter
input                               rst,
//interface with upstram module
input                               op_req,
output  reg                         op_ack,
input                               op_rw,                      //0:write
input           [ADDR_W - 1:0]      op_addr,
input           [DATA_W - 1:0]      op_wdata,
(* IOB="true" *)
output  reg     [DATA_W - 1:0]      op_rdata,
output  reg                         op_rvld,
//IO
(* IOB="true" *)
output  reg     [ADDR_W - 1:0]      io_addr,
(* IOB="true" *)
output  reg                         io_ce,
(* IOB="true" *)
output  reg                         io_oe,
(* IOB="true" *)
output  reg                         io_we,
inout           [DATA_W - 1:0]      io_dq
);
// Parameter Define 
localparam                           IDLE = 3'b001;
localparam                           WRITE = 3'b010;
localparam                           READ = 3'b100;
localparam                           W_IDLE = 5'b00001;                       
localparam                           W_T_AS = 5'b00010;                       
localparam                           W_T_WP = 5'b00100;                       
localparam                           W_T_CH = 5'b01000;                       
localparam                           W_T_WPH = 5'b10000;                       
localparam                           R_IDLE = 3'b001;
localparam                           R_T_ACC = 3'b010;
localparam                           R_T_OH = 3'b100;

localparam                           T_WPH = 3;                                       //base on clock 100M
localparam                           T_WP = 3;
localparam                           T_RACC = 12;
// Register Define 
reg     [2:0]                       m_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [2:0]                       m_next_st;
reg     [4:0]                       w_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [4:0]                       w_next_st;
reg     [2:0]                       r_cur_st/* synthesis syn_encoding="safe,onehot" */;
reg     [2:0]                       r_next_st;
reg                                 write_start;
reg                                 read_start;
reg                                 write_done;
reg                                 read_done;
reg     [2:0]                       r_cur_st_dly;
reg     [4:0]                       w_cur_st_dly;
reg     [3:0]                       slot_cnt;
reg                                 w_twp_done;
reg                                 r_tacc_done;
reg     [DATA_W - 1:0]              io_data_out;
reg                                 buf_ctl/* synthesis syn_preserve = 1 */;
// Wire Define 
wire    [DATA_W - 1:0]              io_data_in;

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        op_ack <= 1'b0;
    else
        begin
            if(op_ack == 1'b1)
                op_ack <= #U_DLY 1'b0;
            else if(m_cur_st == IDLE && op_req == 1'b1)
                op_ack <= #U_DLY 1'b1;
            else;
        end
end
//*****************************************************************************//
//main state machine
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        m_cur_st <= IDLE;
    else
        m_cur_st <= #U_DLY m_next_st;
end

always @(*)
begin
    case(m_cur_st)
        IDLE:begin
            if({op_req,op_ack} == 2'b11)
                begin
                    if(op_rw == 1'b0)
                        m_next_st = WRITE;
                    else 
                        m_next_st = READ;
                end
            else
                m_next_st = IDLE;end
        WRITE:begin
            if(write_done == 1'b1)
                m_next_st = IDLE;
            else
                m_next_st = WRITE;end
        READ:begin
            if(read_done == 1'b1) 
                m_next_st = IDLE;
            else
                m_next_st = READ;end
        default:m_next_st = IDLE;
    endcase
end
//write state machine
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        w_cur_st <= W_IDLE;
    else
        w_cur_st <= #U_DLY w_next_st;
end

always @(*)
begin 
    if(m_cur_st != WRITE)
        w_next_st = W_IDLE;
    else
        begin
            case(w_cur_st)
                W_IDLE:begin
                    if(write_start == 1'b1)
                        w_next_st = W_T_AS;
                    else
                        w_next_st = W_IDLE;end
                W_T_AS:w_next_st = W_T_WP;
                W_T_WP:begin
                    if(w_twp_done == 1'b1)
                        w_next_st = W_T_CH;
                    else
                        w_next_st = W_T_WP;end
                W_T_CH:w_next_st = W_T_WPH;
                W_T_WPH:begin
                    if(write_done == 1'b1)
                        w_next_st = W_IDLE;
                    else
                        w_next_st = W_T_WPH;end
                default:w_next_st = W_IDLE;
            endcase
        end
end
//read state machine
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        r_cur_st <= R_IDLE;
    else
        r_cur_st <= #U_DLY r_next_st;
end

always @(*)
begin
    if(m_cur_st != READ)
        r_next_st = R_IDLE;
    else
        begin
            case(r_cur_st)
                R_IDLE:begin
                    if(read_start == 1'b1)
                        r_next_st = R_T_ACC;
                    else
                        r_next_st = R_IDLE;end
                R_T_ACC:begin
                    if(r_tacc_done == 1'b1)
                        r_next_st = R_T_OH;
                    else
                        r_next_st = R_T_ACC;end
                R_T_OH:r_next_st = R_IDLE;
                default:r_next_st = R_IDLE;
            endcase
        end
end
//*****************************************************************************//
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            write_start <= 1'b0;
            read_start <= 1'b0;
            write_done <= 1'b0;
            read_done <= 1'b0;
        end
    else
        begin
            if(write_start == 1'b1)
                write_start <= #U_DLY 1'b0;
            else if(m_cur_st == IDLE && {op_req,op_ack} == 2'b11 && op_rw == 1'b0)
                write_start <= #U_DLY 1'b1;
            else;

            if(read_start == 1'b1)
                read_start <= #U_DLY 1'b0;
            else if(m_cur_st == IDLE && {op_req,op_ack} == 2'b11 && op_rw == 1'b1)
                read_start <= #U_DLY 1'b1;
            else;

            if(write_done == 1'b1)
                write_done <= #U_DLY 1'b0;
            else if(m_cur_st == WRITE && w_cur_st == W_T_WPH && slot_cnt >= ((T_WPH - 1) - 1))
                write_done <= #U_DLY 1'b1;
            else;

            read_done <= #U_DLY r_tacc_done;               
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            r_cur_st_dly <= W_IDLE;
            w_cur_st_dly <= R_IDLE;
            slot_cnt <= 'd0;
            w_twp_done <= 1'b0;
            r_tacc_done <= 1'b0;
        end
    else
        begin 
            r_cur_st_dly <= #U_DLY r_cur_st;
            w_cur_st_dly <= #U_DLY w_cur_st;

            if(read_start == 1'b1 || write_start == 1'b1 || r_cur_st_dly != r_cur_st || w_cur_st_dly != w_cur_st)
                slot_cnt <= #U_DLY 'd0;
            else if(slot_cnt != 4'hf)
                slot_cnt <= #U_DLY slot_cnt + 'd1;
            else;

            if(w_twp_done == 1'b1)
                w_twp_done <= #U_DLY 1'b0;
            else if(m_cur_st == WRITE && w_cur_st == W_T_WP && slot_cnt >= ((T_WP - 1) - 1))
                w_twp_done <= #U_DLY 1'b1;
            else;

            if(r_tacc_done == 1'b1)
                r_tacc_done <= #U_DLY 1'b0;
            else if(m_cur_st == READ && r_cur_st == R_T_ACC && slot_cnt >= ((T_RACC - 1) - 1))
                r_tacc_done <= #U_DLY 1'b1;
            else;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            op_rvld <= 1'b0;
            op_rdata <= 'd0;
        end
    else
        begin
            if(op_rvld == 1'b1)
                op_rvld <= #U_DLY 1'b0;
            else if(m_cur_st == READ && r_cur_st == R_T_OH)
                op_rvld <= #U_DLY 1'b1;
            else;

            if(m_cur_st == READ && r_cur_st == R_T_OH)
                op_rdata <= #U_DLY io_data_in;
            else;
        end
end 
//*****************************************************************************//           
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
       begin
           io_addr <= 'd0;
           io_ce <= 1'b1;
           io_oe <= 1'b1;
           io_we <= 1'b1;
        end
    else
        begin
            if(m_cur_st == IDLE && {op_req,op_ack} == 2'b11)
                io_addr <= #U_DLY op_addr;
            else;

            if(m_cur_st == WRITE)
                begin
                    if(w_cur_st == W_T_AS || w_cur_st == W_T_WP || w_cur_st == W_T_CH)
                        io_ce <= #U_DLY 1'b0;
                    else
                        io_ce <= #U_DLY 1'b1;
                end
            else if(m_cur_st == READ)
                io_ce <= #U_DLY 1'b0;
            else
                io_ce <= #U_DLY 1'b1;

            if(m_cur_st == READ)
                io_oe <= #U_DLY 1'b0;
            else
                io_oe <= #U_DLY 1'b1;

            if(m_cur_st == WRITE && w_cur_st == W_T_WP)
                io_we <= #U_DLY 1'b0;
            else
                io_we <= #U_DLY 1'b1;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            io_data_out <= 'd0;
            buf_ctl <= 1'b0;
        end
    else
        begin
            if(m_cur_st == IDLE && {op_req,op_ack} == 2'b11 && op_rw == 1'b0)
                io_data_out <= #U_DLY op_wdata;
            else;

            if(m_cur_st == READ)
                buf_ctl <= #U_DLY 1'b1;
            else
                buf_ctl <= #U_DLY 1'b0;
        end
end

genvar i;
generate
for(i=0; i<=(DATA_W-1); i=i+1)
begin
    IOBUF #(
        .DRIVE                      (12                         ),// Specify the output drive strength
        .IBUF_LOW_PWR               ("FALSE"                    ),// Low Power - "TRUE", High Performance = "FALSE" 
        .IOSTANDARD                 ("DEFAULT"                  ),// Specify the I/O standard
        .SLEW                       ("SLOW"                     ) // Specify the output slew rate
    ) 
    IOBUF_inst(
        .O                          (io_data_in[i]              ),// Buffer output
        .IO                         (io_dq[i]                   ),// Buffer inout port (connect directly to top-level port)
        .I                          (io_data_out[i]             ),// Buffer input
        .T                          (buf_ctl                    ) // 3-state enable input, high=input, low=output
    );
end
endgenerate

endmodule


