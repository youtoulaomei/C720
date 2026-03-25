`timescale 1 ns / 1 ns
module spi_common_phy # (
parameter                           U_DLY = 1,
parameter                           SLAVE_NUM = 1
)
(
input                               clk,
input                               rst,
input                               spi_3line_en,

input                               spi_phy_start,      //raise to start spi phy module
input                               spi_phy_rw_bit,     //0:write; 1:read
input           [6:0]               send_data_len,      //number of bytes to send
input           [6:0]               read_data_len,      //number of bytes to read
output reg                          spi_phy_idle,       //1:idle; 0:busy
input           [15:0]              half_period,        //SPI clock half period
input           [15:0]              wait_time,          //SPI wait time after done
input           [15:0]              read_waitTime,      //SPI wait time before read
input                               spi_phy_rd_sel,     //0:read on sck rising edge; 1:read on sck falling edge
input           [SLAVE_NUM - 1:0]   spi_phy_ss_n_sel,

output reg      [5:0]               send_ram_addr,
input           [7:0]               send_ram_data,

output reg      [5:0]               recieve_ram_addr,
output reg      [7:0]               recieve_ram_data,
output reg                          recieve_ram_en,

output  reg                         phy_sck,
output  reg     [SLAVE_NUM - 1:0]   phy_ss_n,
inout   wire                        phy_state3_mosi,
input                               phy_miso

);
// Parameter Define 
localparam                          IDLE      = 3'd0;
localparam                          SEND_DATA = 3'd1;
localparam                          READ_WAIT = 3'd2;
localparam                          READ_DATA = 3'd3;
localparam                          DONE      = 3'd4;

// Register Define 
reg                                                                     sck;
(* syn_keep="true",mark_debug="true" *)  reg                            phy_sck_1delay;
(* IOB="true" *)  reg                                                   phy_sck_2delay;

reg     [SLAVE_NUM - 1:0]                                               ss_n;
(* syn_keep="true",mark_debug="true" *)  reg     [SLAVE_NUM - 1:0]      phy_ss_n_1delay;
(* IOB="true" *)  reg     [SLAVE_NUM - 1:0]                             phy_ss_n_2delay;

reg                                                                     mosi;
reg                                                                     mosi_reg;
(* syn_keep="true",mark_debug="true" *)             reg                 mosi_reg_1delay;
(* IOB="true" *)  reg                                                   mosi_reg_2delay;

reg     [1:0]                                                           miso_reg;
(* syn_keep="true",mark_debug="true" *)  reg                            miso_reg_1delay;
(* IOB="true" *)  reg                                                   miso_reg_2delay;

reg     [2:0]                       state;
reg     [2:0]                       nextstate;
reg                                 spi_phy_module_start;
reg     [1:0]                       spi_phy_start_reg;
reg     [15:0]                      half_period_cnt;
reg                                 half_period_flag;
reg     [2:0]                       bit_cnt;
reg     [6:0]                       rd_burst_cnt;
reg                                 read_done;
reg                                 wait_done;
reg     [15:0]                      wait_readTime_cnt;
reg                                 wait_read_done;

reg     [6:0]                       spi_burst_cnt;
reg                                 send_done;
reg                                 tx_rd_en;
reg     [7:0]                       tx_rd_data_r;

reg     [15:0]                      wait_cnt;

reg                                 state3_en;
// Wire Define 



always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        state <= #U_DLY IDLE;
    else
        state <= #U_DLY nextstate;
end


always @ (*)begin
    case(state)
        IDLE:begin
            if(spi_phy_module_start==1'b1 && send_data_len >='d1 && send_data_len <='d60)
                nextstate=SEND_DATA;
            else
                nextstate=IDLE;
        end

        SEND_DATA:begin
            if(send_done==1'b1)
                begin
                    if(spi_phy_rw_bit==1'b0)
                        nextstate=DONE;
                    else 
                        begin
                            if(read_data_len!='d0)
                                nextstate=READ_WAIT;
                            else
                                nextstate=DONE;
                        end
                end
            else
                nextstate=SEND_DATA;
        end

        READ_WAIT:begin
            if(wait_read_done==1'b1)
                nextstate=READ_DATA;
            else
                nextstate=READ_WAIT;
        end

        READ_DATA:begin
            if(read_done==1'b1)
                nextstate=DONE;
            else
                nextstate=READ_DATA;
        end

        DONE:begin
            if(wait_done==1'b1)
                nextstate=IDLE;
            else
                nextstate=DONE;
        end

        default:nextstate=IDLE;
    endcase
end


always @(posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            half_period_cnt <= 'd0;
            half_period_flag <= 1'b0;
        end
    else
        begin
            if((state == SEND_DATA ||state == READ_DATA) && (half_period_cnt >= half_period))
                half_period_cnt <= #U_DLY 'd0;
            else if(state == SEND_DATA ||state == READ_DATA)
                half_period_cnt <= #U_DLY half_period_cnt + 'd1;
            else
                half_period_cnt <= #U_DLY 'd0;

            if(half_period_flag == 1'b1)
                half_period_flag <= #U_DLY 1'b0;
            else if(half_period_cnt >= half_period)
                half_period_flag <= #U_DLY 1'b1;
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            mosi <= #U_DLY 1'b0;
            bit_cnt <= #U_DLY 'd7;
        end
    else
        begin
            if(state==IDLE && nextstate==SEND_DATA)
                mosi <= #U_DLY tx_rd_data_r[bit_cnt];
            else if(state==SEND_DATA)
                begin
                    if(state==SEND_DATA && half_period_flag == 1'b1 && sck==1'b1 && bit_cnt=='d7 && spi_burst_cnt == send_data_len-1)
                        mosi <= #U_DLY 1'b0;  
                    else if(half_period_flag == 1'b1 && sck==1'b1) //sck fall edge
                        mosi <= #U_DLY tx_rd_data_r[bit_cnt];
                end
            else
                mosi <= #U_DLY 1'b0;

            if(state==SEND_DATA)
                begin
                    if(half_period_flag == 1'b1 && bit_cnt=='d0 && sck==1'b0)  //sck rise edge
                        bit_cnt <= #U_DLY 'd7;
                    else if(half_period_flag == 1'b1 &&  sck==1'b0)  //sck rise edge
                        bit_cnt <= #U_DLY bit_cnt-'d1;
                end
            else if(state==READ_DATA && spi_phy_rd_sel==1'b0)
                begin
                    if(half_period_flag == 1'b1 && bit_cnt=='d0 && sck==1'b0)  //sck rise edge
                        bit_cnt <= #U_DLY 'd7;
                    else if(half_period_flag == 1'b1 &&  sck==1'b0)  //sck rise edge
                        bit_cnt <= #U_DLY bit_cnt-'d1;
                end
            else if(state==READ_DATA && spi_phy_rd_sel==1'b1)
                begin
                    if(half_period_flag == 1'b1 && bit_cnt=='d0 && sck==1'b1)  //sck rise edge
                        bit_cnt <= #U_DLY 'd7;
                    else if(half_period_flag == 1'b1 &&  sck==1'b1)  //sck rise edge
                        bit_cnt <= #U_DLY bit_cnt-'d1;
                end
            else
                bit_cnt <= #U_DLY 'd7;
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            recieve_ram_data <= #U_DLY 'b0;
            recieve_ram_en <= #U_DLY 1'b0;
            recieve_ram_addr <= #U_DLY 'b0;
        end
    else
        begin
            if(state==READ_DATA && half_period_flag == 1'b1)
                begin
                    if(spi_phy_rd_sel==1'b0 && sck==1'b0) //rise
                        recieve_ram_data[bit_cnt] <= #U_DLY miso_reg_2delay;
                    else if(spi_phy_rd_sel==1'b1 && sck==1'b1)//fall
                        recieve_ram_data[bit_cnt] <= #U_DLY miso_reg_2delay;
                end

            if(state==READ_DATA && half_period_flag == 1'b1 && sck==1'b1 && bit_cnt=='d7 && spi_phy_rw_bit==1'b1 && spi_phy_rd_sel==1'b0)//rise
                recieve_ram_en <= #U_DLY 1'b1;
            else if(state==READ_DATA && half_period_flag == 1'b1 && sck==1'b1 && bit_cnt=='d0 && spi_phy_rw_bit==1'b1 && spi_phy_rd_sel==1'b1)//fall
                recieve_ram_en <= #U_DLY 1'b1;
            else
                recieve_ram_en <= #U_DLY 1'b0;

            if(state==DONE && nextstate==IDLE)
                recieve_ram_addr <= #U_DLY 'd0;
            else if(recieve_ram_en==1'b1)
                recieve_ram_addr <= #U_DLY recieve_ram_addr + 'b1;
        end
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            spi_burst_cnt <= #U_DLY 'd0;
            send_done <= #U_DLY 1'b0;
            read_done <= #U_DLY 1'b0; 
            rd_burst_cnt <= #U_DLY 'd0;
        end
    else 
        begin
            if(state==SEND_DATA)
                begin
                    if(half_period_flag == 1'b1 && sck==1'b1 && bit_cnt=='d7) //
                        spi_burst_cnt <= #U_DLY spi_burst_cnt + 'd1;
                end
            else
                spi_burst_cnt <= #U_DLY 'd0;
            
            if(send_done==1'b1)
                send_done <= #U_DLY 1'b0;
            else if(state==SEND_DATA && half_period_flag == 1'b1 && sck==1'b1 && bit_cnt=='d7 &&  spi_burst_cnt == send_data_len-1)
                send_done <= #U_DLY 1'b1;

            if(state==READ_DATA)
                begin
                    if(half_period_flag == 1'b1 && sck==1'b1 && bit_cnt=='d7 && spi_phy_rd_sel==1'b0) //rise
                        rd_burst_cnt <= #U_DLY rd_burst_cnt + 'd1;
                    else if(half_period_flag == 1'b1 && sck==1'b1 && bit_cnt=='d0 && spi_phy_rd_sel==1'b1) //fall
                        rd_burst_cnt <= #U_DLY rd_burst_cnt + 'd1;
                end
            else
                rd_burst_cnt <= #U_DLY 'd0;

            if(read_done==1'b1)
                read_done <= #U_DLY 1'b0;
            else if(state==READ_DATA && half_period_flag == 1'b1 && sck==1'b1 && bit_cnt=='d7 &&  rd_burst_cnt == read_data_len-1 && spi_phy_rd_sel==1'b0)//rise
                read_done <= #U_DLY 1'b1;
            else if(state==READ_DATA && half_period_flag == 1'b1 && sck==1'b1 && bit_cnt=='d0 &&  rd_burst_cnt == read_data_len-1 && spi_phy_rd_sel==1'b1)//fall
                read_done <= #U_DLY 1'b1;
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            tx_rd_en <= #U_DLY 1'b0;
            send_ram_addr <= #U_DLY 'd0;
            tx_rd_data_r <= #U_DLY 'b0;
        end
    else
        begin
            if(tx_rd_en==1'b1)
                tx_rd_en <= #U_DLY 1'b0;
            else if(state==SEND_DATA && half_period_flag == 1'b1 && bit_cnt=='d0 && sck==1'b0) //sck rise edge
                tx_rd_en <= #U_DLY 1'b1;

            if(send_done==1'b1)
                send_ram_addr <= #U_DLY 'b0;
            else if(tx_rd_en==1'b1)
                send_ram_addr <= #U_DLY send_ram_addr + 'b1;

            tx_rd_data_r <= #U_DLY send_ram_data;
        end
end





//---------------------------------------------------------------------------
// rx dual port ram
//---------------------------------------------------------------------------
always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1) 
        begin
            sck <= #U_DLY 1'b0; 
            ss_n <= #U_DLY {SLAVE_NUM{1'b1}};
        end
    else 
        begin
            if(state==SEND_DATA || state==READ_DATA) 
                begin
                    if(half_period_flag==1'b1)
                        sck <= #U_DLY ~sck;
                end
            else
                sck <= #U_DLY 1'b0;

            if(|{spi_phy_ss_n_sel} == 1'b1)
                begin
                    if(state==SEND_DATA)
                        ss_n <= #U_DLY ~spi_phy_ss_n_sel;
                    else
                        ss_n <= #U_DLY {SLAVE_NUM{1'b1}};
                end
            else
                begin
                    if(state==SEND_DATA || state==READ_WAIT || state==READ_DATA)
                        begin
                            if (SLAVE_NUM > 1)
                                ss_n <= #U_DLY {{(SLAVE_NUM-1){1'b1}},1'b0};
                            else
                                ss_n <= #U_DLY 1'b0;
                        end
                    else 
                        ss_n <= #U_DLY {SLAVE_NUM{1'b1}};
                end
        end

end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        miso_reg <= #U_DLY 'b0;
    else if(spi_3line_en == 1'b0)
        miso_reg <= #U_DLY {miso_reg[0],phy_miso};
    else
        miso_reg <= #U_DLY {miso_reg[0],state3_miso};
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            spi_phy_module_start <= #U_DLY 1'b0;
            spi_phy_start_reg <= #U_DLY 'b0;
        end
    else
        begin
            if(spi_phy_start_reg[0]==1'b1 && spi_phy_start_reg[1]==1'b0)
                spi_phy_module_start <= #U_DLY 1'b1;
            else
                spi_phy_module_start <= #U_DLY 1'b0;

            spi_phy_start_reg <= #U_DLY {spi_phy_start_reg[0],spi_phy_start};
        end
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        spi_phy_idle <= #U_DLY 1'b0;
    else if(state==IDLE)
        spi_phy_idle <= #U_DLY 1'b1;
    else
        spi_phy_idle <= #U_DLY 1'b0;
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            wait_cnt <= #U_DLY 'b0;
            wait_done <= #U_DLY 1'b0;
        end
    else
        begin
            if(wait_done==1'b1)
                wait_cnt <= #U_DLY 'd0;
            else if(state==DONE)
                wait_cnt <= #U_DLY wait_cnt + 'b1;

            if(wait_cnt>=wait_time)
                wait_done <= #U_DLY 1'b1;
            else
                wait_done <= #U_DLY 1'b0;
        end
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            wait_read_done <= #U_DLY 1'b0;
            wait_readTime_cnt <= #U_DLY 'd0;
        end
    else
        begin
            if(state==IDLE)
                wait_readTime_cnt <= #U_DLY 'd0;
            else if(state==READ_WAIT)
                wait_readTime_cnt <= #U_DLY wait_readTime_cnt + 'd1;

            if(state==IDLE)
                wait_read_done <= #U_DLY 1'b0;
            else if(wait_readTime_cnt>=read_waitTime)
                wait_read_done <= #U_DLY 1'b1;
        end
end

//4-wire SPI or 3 wire SPI
IOBUF #(
    .DRIVE                      (12                         ),
    .IBUF_LOW_PWR               ("FALSE"                    ),
    .IOSTANDARD                 ("DEFAULT"                  ),
    .SLEW                       ("SLOW"                     )
) 
IOBUF_inst (
    .O                          (state3_miso                ), // Buffer output
    .IO                         (phy_state3_mosi            ), // Buffer inout port (connect directly to top-level port)
    .I                          (mosi_reg                   ), // Buffer input
    .T                          (state3_en                  )  // 3-state enable input, high=input, low=output
);

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            state3_en <= #U_DLY 1'b0;
        end
    else
        begin
            if(spi_3line_en == 1'b0)
                state3_en <= #U_DLY 1'b0;
            else
                begin
                    if(state == SEND_DATA) //when read,set sdio input
                        state3_en <= #U_DLY 1'b0;
                    else
                        state3_en <= #U_DLY 1'b1;
                end
        end
end

/* ----------------------------------- IOB ---------------------------------- */
always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            phy_sck <= #U_DLY 1'b0;
            phy_sck_1delay <= #U_DLY 1'b0;
            phy_sck_2delay <= #U_DLY 1'b0;

            phy_ss_n <= #U_DLY {SLAVE_NUM{1'b1}};
            phy_ss_n_1delay <= #U_DLY {SLAVE_NUM{1'b1}};
            phy_ss_n_2delay <= #U_DLY {SLAVE_NUM{1'b1}};
            
            mosi_reg <= #U_DLY 1'b0;
            mosi_reg_1delay <= #U_DLY 1'b0;
            mosi_reg_2delay <= #U_DLY 1'b0;

            miso_reg_1delay <= #U_DLY 1'b0;
            miso_reg_2delay <= #U_DLY 1'b0;
        end
    else
        begin
            mosi_reg_1delay <= #U_DLY mosi;
            mosi_reg_2delay <= #U_DLY mosi_reg_1delay;
            mosi_reg <= #U_DLY mosi_reg_2delay;

            phy_sck_1delay <= #U_DLY sck;
            phy_sck_2delay <= #U_DLY phy_sck_1delay;
            phy_sck <= #U_DLY phy_sck_2delay;

            phy_ss_n_1delay <= #U_DLY ss_n;
            phy_ss_n_2delay <= #U_DLY phy_ss_n_1delay;
            phy_ss_n <= #U_DLY phy_ss_n_2delay;

            miso_reg_1delay <= #U_DLY miso_reg[1];
            miso_reg_2delay <= #U_DLY miso_reg_1delay;
        end
end

endmodule
