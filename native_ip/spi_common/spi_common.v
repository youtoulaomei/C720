`timescale 1 ns / 1 ns

module spi_common(
input                               clk,
input                               rst,
//cpu bus
input                               cpu_cs,
input                               cpu_wr,
input                               cpu_rd,
input           [7:0]               cpu_addr,
input           [31:0]              cpu_wr_data,
output  wire    [31:0]              cpu_rd_data,
//io
output  wire                        sck,
output  wire                        ss_n,
inout   wire                        mosi,
input   wire                        miso
);
// Parameter Define 

// Register Define 

// Wire Define
wire                                spi_phy_start;
wire                                spi_phy_rw_bit;
wire    [6:0]                       send_data_len;
wire    [6:0]                       read_data_len;
wire                                spi_phy_idle;
wire    [15:0]                      half_period;
wire    [15:0]                      wait_time;
wire    [15:0]                      read_waitTime;
wire                                spi_phy_rd_sel;
wire                                spi_phy_ss_n_sel;
wire    [5:0]                       send_ram_addr;
wire    [7:0]                       send_ram_data;
wire    [5:0]                       recieve_ram_addr;
wire    [7:0]                       recieve_ram_data;
wire                                recieve_ram_en;


spi_cib u_spi_cib(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//cpu bus
    .cpu_cs                     (cpu_cs                     ),
    .cpu_wr                     (cpu_wr                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wr_data                (cpu_wr_data                ),
    .cpu_rd_data                (cpu_rd_data                ),

//others config
    .spi_3line_en               (spi_3line_en               ),
    .spi_phy_start              (spi_phy_start              ),
    .spi_phy_rw_bit             (spi_phy_rw_bit             ),
    .send_data_len              (send_data_len              ),
    .read_data_len              (read_data_len              ),
    .spi_phy_idle               (spi_phy_idle               ),
    .half_period                (half_period                ),
    .wait_time                  (wait_time                  ),
    .read_waitTime              (read_waitTime              ),
    .spi_phy_rd_sel             (spi_phy_rd_sel             ),
    .spi_phy_ss_n_sel           (spi_phy_ss_n_sel           ),


    .send_ram_addr              (send_ram_addr              ),
    .send_ram_data              (send_ram_data              ),
    .recieve_ram_addr           (recieve_ram_addr           ),
    .recieve_ram_en             (recieve_ram_en             ),
    .recieve_ram_data           (recieve_ram_data           )

);


spi_common_phy #(
    .U_DLY                      (1                          ),
    .SLAVE_NUM                  (1                          )
)
u_spi_common_phy(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
    .spi_3line_en               (spi_3line_en               ),

    .spi_phy_start              (spi_phy_start              ),
    .spi_phy_rw_bit             (spi_phy_rw_bit             ),
    .send_data_len              (send_data_len              ),
    .read_data_len              (read_data_len              ),
    .spi_phy_idle               (spi_phy_idle               ),
    .half_period                (half_period                ),
    .wait_time                  (wait_time                  ),  
    .read_waitTime              (read_waitTime              ),
    .spi_phy_rd_sel             (spi_phy_rd_sel             ),
    .spi_phy_ss_n_sel           (spi_phy_ss_n_sel           ),

    .send_ram_addr              (send_ram_addr              ),
    .send_ram_data              (send_ram_data              ),
    .recieve_ram_addr           (recieve_ram_addr           ),
    .recieve_ram_data           (recieve_ram_data           ),
    .recieve_ram_en             (recieve_ram_en             ),

    .phy_sck                    (sck                        ),
    .phy_ss_n                   (ss_n                       ),
    .phy_state3_mosi            (mosi                       ),
    .phy_miso                   (miso                       )

);


endmodule
