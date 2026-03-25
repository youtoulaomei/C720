`timescale 1 ns / 1 ns

module spi_tb;

// Clock & reset
reg clk_100m;
wire clk = clk_100m; // used by the DUT
reg rst;
reg hard_rst;

// CPU bus signals
reg                 cpu_cs;
reg                 cpu_wr;
reg                 cpu_rd;
reg     [7:0]       cpu_addr;
reg     [31:0]      cpu_wr_data;
wire    [31:0]      cpu_rd_data;

// SPI IO
wire                sck;
wire                ss_n;
wire                mosi;
reg                 miso;
reg     [31:0]      miso_data;
reg     [2:0]       bitptr;

// Instantiate DUT
spi_common u_spi_common(
    .clk                        (clk                        ),
    .rst                        (rst                        ),
//cpu bus
    .cpu_cs                     (cpu_cs                     ),
    .cpu_wr                     (cpu_wr                     ),
    .cpu_rd                     (cpu_rd                     ),
    .cpu_addr                   (cpu_addr                   ),
    .cpu_wr_data                (cpu_wr_data                ),
    .cpu_rd_data                (cpu_rd_data                ),
//io
    .sck                        (sck                        ),
    .ss_n                       (ss_n                       ),
    .mosi                       (mosi                       ),
    .miso                       (miso                       )
);

// Clock generation: 100 MHz -> period 10 ns
initial begin
    clk_100m = 1'b0;
end
always #5 clk_100m = ~clk_100m;

// simple monitor
initial begin
    $dumpfile("spi_tb.vcd");
    $dumpvars(0, spi_tb);
    $display("Time\tss_n\tsck\tmosi\tmiso");
    $monitor("%0t\t%b\t%b\t%02x\t%b", $time, ss_n, sck, mosi, miso);
end

// CPU bus helper tasks
task reg_wr;
input [7:0]  addr;
input [31:0] wdata;
begin
    cpu_cs = 1'b0;
    cpu_wr = 1'b0; // drive from 0->1 to create rising edge
    cpu_rd = 1'b1;
    cpu_addr = addr;
    cpu_wr_data = wdata;
    repeat(10) @(posedge clk_100m);
    cpu_cs = 1'b1;
    cpu_wr = 1'b1;
    cpu_rd = 1'b1;
    cpu_addr = 8'b0;
    cpu_wr_data = 32'd0;
    repeat(10) @(posedge clk_100m);
end
endtask

task reg_rd;
input [7:0]  addr;
begin
    cpu_cs = 1'b0;
    cpu_wr = 1'b1;
    cpu_rd = 1'b0; // drive from 0->1 to create rising edge on read
    cpu_addr = addr;
    cpu_wr_data = 32'd0;
    repeat(10) @(posedge clk_100m);
    cpu_cs = 1'b1;
    cpu_wr = 1'b1;
    cpu_rd = 1'b1;
    cpu_addr = 8'b0;
    repeat(10) @(posedge clk_100m);
end
endtask

// Test sequence
integer i;
initial begin
    // init signals
    rst = 1'b1;
    hard_rst = 1'b1;
    cpu_cs = 1'b1;
    cpu_wr = 1'b1;
    cpu_rd = 1'b1;
    cpu_addr = 8'd0;
    cpu_wr_data = 32'd0;
    miso = 1'b0;

    // hold reset
    repeat(50) @(posedge clk_100m);
    rst = 1'b0;
    hard_rst = 1'b0;
    $display("Reset released at %0t", $time);

    // configure timing to speed simulation
    reg_wr(8'h06, 32'd8); // half_period
    reg_wr(8'h08, 32'd20); // wait_time
    reg_wr(8'h09, 32'd8); // rd_time

    // // prepare tx_mem (addresses 0x40..)
    // $display("Writing tx_mem bytes...");
    // reg_wr(8'h40, 32'h55);
    // reg_wr(8'h41, 32'hF0);
    // reg_wr(8'h42, 32'hA6);
    // reg_wr(8'h43, 32'h0F);

    // // set burst length (send 4 bytes)
    // reg_wr(8'h05, 32'd4);

    // // start write burst (spi_busrt_rw = 0)
    // reg_wr(8'h03, 32'd100); // set rw=0
    // reg_wr(8'h04, 32'd0); // start
    // reg_wr(8'h04, 32'd1); // start
    // $display("Write burst started at %0t", $time);


    reg_wr(8'h05, 32'h204);
    reg_wr(8'h03, 32'h0);
    reg_wr(8'h40, 32'hf0);
    reg_wr(8'h41, 32'haa);
    reg_wr(8'h42, 32'h55);
    reg_wr(8'h43, 32'h0f);

    reg_wr(8'h04, 32'd0); // start
    reg_wr(8'h04, 32'd1); // start

    reg_rd(8'h80);
    reg_rd(8'h81);
    $display("Write burst started at %0t", $time);

    #20000
    $stop;
end
endmodule