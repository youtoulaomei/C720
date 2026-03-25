`timescale 1 ns / 1 ns
module width_conversion_B2S # (
parameter                           U_DLY = 1,
parameter                           WIDTH_INPUT = 256,
parameter                           WIDTH_OUTPUT = 32,
parameter                           RAM_STYLE = "block",
parameter                           IN_FIFO_DEEPTH = 128,
parameter                           IN_FIFO_PROG_FULL_THRESH = 64,
parameter                           IN_FIFO_PROG_EMPTY_THRESH = 2,
parameter                           OUT_FIFO_DEEPTH = 128,
parameter                           OUT_FIFO_PROG_FULL_THRESH = 64,
parameter                           OUT_FIFO_PROG_EMPTY_THRESH = 2
)
(
input                               WC_in_clk,
input                               WC_out_clk,
input                               rst,
// width_conversion_B2S input data
input        [WIDTH_INPUT-1:0]      WC_in_data,
input                               WC_in_vld,
output reg                          WC_in_rdy,
// width_conversion_B2S output data
output       [WIDTH_OUTPUT-1:0]     WC_out_data,
output                              WC_out_vld,
input                               WC_out_rdy,

output                              WC_fifo_empty,
output                              WC_fifo_prog_full
);

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

// Parameter Define 
localparam                                  INCNT = WIDTH_INPUT/WIDTH_OUTPUT;
localparam                                  INCNT_WIDTH  = clog2b(INCNT);
localparam                                  IN_FIFO_ADDR_WIDTH = clog2b(IN_FIFO_DEEPTH);
localparam                                  OUT_FIFO_ADDR_WIDTH = clog2b(OUT_FIFO_DEEPTH);
// Register Define 
reg     [WIDTH_INPUT-1:0]                   din;
reg                                         wr_en;
reg                                         o_wr_en;
reg     [INCNT_WIDTH-1:0]                   o_wr_cnt;
reg     [WIDTH_OUTPUT-1:0]                  o_din;
reg     [WIDTH_INPUT-WIDTH_OUTPUT-1:0]      dout_reg;

// Wire Define
wire                                        rd_en;
wire    [WIDTH_INPUT-1:0]                   dout;
wire                                        prog_full;
wire                                        empty;
wire                                        o_rd_en;
wire    [WIDTH_OUTPUT-1:0]                  o_dout;
wire                                        o_prog_full;
wire                                        o_empty;


always @ (posedge WC_in_clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            WC_in_rdy <= #U_DLY 1'b1;
            wr_en <= #U_DLY 1'b0;
            din <= #U_DLY 'd0;
        end
    else
        begin
            if(prog_full==1'b1)
                WC_in_rdy <= #U_DLY 1'b0;
            else
                WC_in_rdy <= #U_DLY 1'b1;

            if(WC_in_vld==1'b1 && WC_in_rdy==1'b1)
                wr_en <= #U_DLY 1'b1;
            else
                wr_en <= #U_DLY 1'b0;

            if(WC_in_vld==1'b1 && WC_in_rdy==1'b1)
                din <= #U_DLY WC_in_data;
        end
end

//---------------------------------------------------------------
//asyn_fifo
//---------------------------------------------------------------
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (WIDTH_INPUT                ),
    .DATA_DEEPTH                (IN_FIFO_DEEPTH             ),
    .RAM_STYLE                  (RAM_STYLE                  ),
    .ADDR_WIDTH                 (IN_FIFO_ADDR_WIDTH         )
)input_fifo
(
    .wr_clk                     (WC_in_clk                  ),
    .wr_rst_n                   (~rst                       ),
    .rd_clk                     (WC_out_clk                 ),
    .rd_rst_n                   (~rst                       ),
    .din                        (din                        ),
    .wr_en                      (wr_en                      ),
    .rd_en                      (rd_en                      ),
    .dout                       (dout                       ),
    .full                       (                           ),
    .prog_full                  (prog_full                  ),
    .empty                      (empty                      ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (IN_FIFO_PROG_FULL_THRESH   ),
    .prog_empty_thresh          (IN_FIFO_PROG_EMPTY_THRESH  ),
    .rd_data_count              (                           ),
    .wr_data_count              (                           )
);



assign rd_en = (o_prog_full==1'b0) && (empty==1'b0) && (o_wr_en==1'b0) ? 1'b1 : (o_prog_full==1'b0) && (empty==1'b0) && (o_wr_cnt==(INCNT-1)) ? 1'b1 : 1'b0;


always @ (posedge WC_out_clk or posedge rst)begin
    if(rst == 1'b1)
        begin
            o_wr_en <= #U_DLY 1'b0;
            o_wr_cnt <= #U_DLY 'd0;
            o_din <= #U_DLY 'd0;
            dout_reg <= #U_DLY 'd0;
        end
    else
        begin
            if(o_wr_en==1'b1 && o_wr_cnt==(INCNT-1) && rd_en==1'b0)
                o_wr_en <= #U_DLY 1'b0;
            else if(rd_en==1'b1)
                o_wr_en <= #U_DLY 1'b1;

            if(o_wr_en==1'b1 && o_wr_cnt==(INCNT-1))
                o_wr_cnt <= #U_DLY 'd0;
            else if(o_wr_en==1'b1)
                o_wr_cnt <= #U_DLY o_wr_cnt + 'd1;

            if(rd_en==1'b1)
                o_din <= #U_DLY dout[WIDTH_OUTPUT-1:0];
            else
                o_din <= #U_DLY dout_reg;

            if(rd_en==1'b1)
                dout_reg <= #U_DLY dout[WIDTH_INPUT-1:WIDTH_OUTPUT];
            else
                dout_reg <= #U_DLY dout_reg>>WIDTH_OUTPUT;
        end

end

//---------------------------------------------------------------
//asyn_fifo
//---------------------------------------------------------------
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (WIDTH_OUTPUT               ),
    .DATA_DEEPTH                (OUT_FIFO_DEEPTH            ),
    .ADDR_WIDTH                 (OUT_FIFO_ADDR_WIDTH        ),
    .RAM_STYLE                  (RAM_STYLE                  )
)output_fifo
(
    .wr_clk                     (WC_out_clk                 ),
    .wr_rst_n                   (~rst                       ),
    .rd_clk                     (WC_out_clk                 ),
    .rd_rst_n                   (~rst                       ),
    .din                        (o_din                      ),
    .wr_en                      (o_wr_en                    ),
    .rd_en                      (o_rd_en                    ),
    .dout                       (o_dout                     ),
    .full                       (o_full                     ),
    .prog_full                  (o_prog_full                ),
    .empty                      (o_empty                    ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (OUT_FIFO_PROG_FULL_THRESH  ),
    .prog_empty_thresh          (OUT_FIFO_PROG_EMPTY_THRESH ),
    .rd_data_count              (                           ),
    .wr_data_count              (                           )
);

assign o_rd_en = (o_empty == 1'b0 && WC_out_rdy == 1'b1) ? 1'b1 : 1'b0;
assign WC_out_data = o_dout;
assign WC_out_vld  = o_rd_en;

assign WC_fifo_empty = empty;
assign WC_fifo_prog_full = o_prog_full;

endmodule
