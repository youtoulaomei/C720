`timescale 1 ns / 1 ns
`define CIB_00 {VERSION}
`define CIB_01 {YEAR,MONTH,DAY}
`define CIB_02 {test_reg}

`define CIB_03 {fill[31:17],spi_3line_en,fill[15:1],spi_phy_rw_bit}
`define CIB_04 {fill[31:1],spi_phy_start}
`define CIB_05 {fill[31:15],read_data_len,fill[7],send_data_len}
`define CIB_06 {fill[31:16],half_period}
`define CIB_08 {fill[31:16],wait_time}
`define CIB_09 {fill[31:16],read_waitTime}
`define CIB_0A {fill[31:1],spi_phy_idle}
`define CIB_0B {fill[31:2],spi_phy_ss_n_sel,spi_phy_rd_sel}

module spi_cib #(
parameter                           U_DLY = 1,
parameter                           VERSION =32'h00_00_00_01,
parameter                           YEAR = 16'h20_18,
parameter                           MONTH = 8'h07,
parameter                           DAY = 8'h18
)
(
input                               clk,
input                               rst,
//cpu bus
input                               cpu_cs,
input                               cpu_wr,
input                               cpu_rd,
input        [7:0]                  cpu_addr,
input        [31:0]                 cpu_wr_data,
output reg   [31:0]                 cpu_rd_data,

//others config
output reg                          spi_3line_en,
output reg                          spi_phy_start,
output reg                          spi_phy_rw_bit,
output reg   [6:0]                  send_data_len,
output reg   [6:0]                  read_data_len,
input                               spi_phy_idle,
output reg   [15:0]                 half_period,
output reg   [15:0]                 wait_time,
output reg   [15:0]                 read_waitTime,
output reg                          spi_phy_rd_sel,
output reg                          spi_phy_ss_n_sel,

input        [5:0]                  send_ram_addr,
output reg   [7:0]                  send_ram_data,
input        [5:0]                  recieve_ram_addr,
input        [7:0]                  recieve_ram_data,
input                               recieve_ram_en

);
// Parameter Define 

// Register Define 
reg                                 cpu_wr_dly;
reg                                 cpu_rd_dly;
reg     [7:0]                       cpu_raddr;
reg     [31:0]                      fill;
reg     [31:0]                      test_reg;
reg     [7:0]                       tmem_rd_data;
reg     [7:0]                       rmem_rd_data;

reg                                 spi_burst_wr;
reg     [5:0]                       spi_burst_wr_addr;
reg     [7:0]                       spi_burst_wr_data;

reg     [7:0]                       tx_mem [63:0];
reg     [7:0]                       rx_mem [63:0];

// Wire Define 
wire    [5:0]                       tmem_rd_addr;
wire    [5:0]                       rmem_rd_addr;

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            cpu_wr_dly <= 1'b1;
            cpu_rd_dly <= 1'b1;
        end
    else
        begin
            cpu_wr_dly <= #U_DLY cpu_wr;
            cpu_rd_dly <= #U_DLY cpu_rd;
        end
end

always @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        cpu_raddr <= 'd0;
    else if({cpu_rd,cpu_rd_dly} == 2'b01 && cpu_cs == 1'b0)   //read
        cpu_raddr <= #U_DLY cpu_addr;
end

always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)
        cpu_rd_data <= #U_DLY 'b0;
    else if(cpu_raddr>=8'h40 && cpu_raddr<=8'h7f)
        cpu_rd_data <= #U_DLY tmem_rd_data;
    else if(cpu_raddr>=8'h80 && cpu_raddr<=8'hbf)
        cpu_rd_data <= #U_DLY rmem_rd_data;
    else
        case(cpu_raddr)
            8'h00:cpu_rd_data <= #U_DLY `CIB_00;
            8'h01:cpu_rd_data <= #U_DLY `CIB_01;
            8'h02:cpu_rd_data <= #U_DLY `CIB_02;
            8'h03:cpu_rd_data <= #U_DLY `CIB_03;
            8'h04:cpu_rd_data <= #U_DLY `CIB_04;
            8'h05:cpu_rd_data <= #U_DLY `CIB_05;
            8'h06:cpu_rd_data <= #U_DLY `CIB_06;
            8'h08:cpu_rd_data <= #U_DLY `CIB_08;
            8'h09:cpu_rd_data <= #U_DLY `CIB_09;
            8'h0A:cpu_rd_data <= #U_DLY `CIB_0A;
            8'h0B:cpu_rd_data <= #U_DLY `CIB_0B;
            default:cpu_rd_data <= #U_DLY 'b0;
        endcase 

end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            fill <= #U_DLY 32'd0;
            `CIB_02 <= #U_DLY 32'hdead_beef;
            `CIB_03 <= #U_DLY 32'd0;
            `CIB_04 <= #U_DLY 32'd0;
            `CIB_05 <= #U_DLY 32'd0;
            `CIB_06 <= #U_DLY 32'd25;
            `CIB_08 <= #U_DLY 32'd50;
            `CIB_09 <= #U_DLY 32'd100;
            `CIB_0B <= #U_DLY 32'd0;

        end
    else
        begin
            if({cpu_wr,cpu_wr_dly} == 2'b01 && cpu_cs == 1'b0)
                begin
                    case(cpu_addr)
                        8'h02:`CIB_02 <= #U_DLY cpu_wr_data;
                        8'h03:`CIB_03 <= #U_DLY cpu_wr_data;
                        8'h04:`CIB_04 <= #U_DLY cpu_wr_data;
                        8'h05:`CIB_05 <= #U_DLY cpu_wr_data;
                        8'h06:`CIB_06 <= #U_DLY cpu_wr_data;
                        8'h08:`CIB_08 <= #U_DLY cpu_wr_data;
                        8'h09:`CIB_09 <= #U_DLY cpu_wr_data;
                        8'h0B:`CIB_0B <= #U_DLY cpu_wr_data;
                        default:;
                    endcase
                end
            else
                fill <= #U_DLY 32'd0;
        end
end


always @ (posedge clk or posedge rst)begin
    if(rst == 1'b1)     
        begin
            spi_burst_wr <= #U_DLY 1'b0;
            spi_burst_wr_addr <= #U_DLY 'b0;
            spi_burst_wr_data <= #U_DLY 'b0;
        end        
    else
        begin
            if({cpu_wr,cpu_wr_dly} == 2'b01 && cpu_cs == 1'b0 && cpu_addr>=8'h40 && cpu_addr<=8'h7f)
                begin
                    spi_burst_wr <= #U_DLY 1'b1;
                    spi_burst_wr_addr <= #U_DLY cpu_addr[5:0];
                    spi_burst_wr_data <= #U_DLY cpu_wr_data[7:0];
                end
            else
                    spi_burst_wr <= #U_DLY 1'b0;
        end
end


//---------------------------------------------------------------------------
// tx dual port ram  TURE
//---------------------------------------------------------------------------
always @ (posedge clk)
begin
    if(spi_burst_wr == 1'b1)
        tx_mem[spi_burst_wr_addr] <= #U_DLY spi_burst_wr_data;
end


always @ (posedge clk)
begin
    send_ram_data <= #U_DLY tx_mem[send_ram_addr];
end

assign tmem_rd_addr = (cpu_raddr>=8'h40 && cpu_raddr<=8'h7f) ? cpu_raddr[5:0] : 'b0;

always @ (posedge clk)
begin
    tmem_rd_data <= #U_DLY tx_mem[tmem_rd_addr];
end


//---------------------------------------------------------------------------
// rx dual port ram
//---------------------------------------------------------------------------
always @ (posedge clk)
begin
    if(recieve_ram_en == 1'b1)
        rx_mem[recieve_ram_addr] <= #U_DLY recieve_ram_data;
end

assign rmem_rd_addr = (cpu_raddr>=8'h80 && cpu_raddr<=8'hbf) ? cpu_raddr[5:0] : 'b0;

always @ (posedge clk)
begin
    rmem_rd_data <= #U_DLY rx_mem[rmem_rd_addr];
end

endmodule

