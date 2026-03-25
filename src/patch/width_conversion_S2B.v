
`timescale 1 ns / 1 ns
module width_conversion_S2B # (
parameter                           U_DLY = 1,
parameter                           WIDTH_INPUT = 32,
parameter                           WIDTH_OUTPUT = 256,
parameter                           RAM_STYLE = "block",
parameter                           FIFO_DEEPTH = 128,
parameter                           FIFO_PROG_FULL_THRESH = 64,
parameter                           FIFO_PROG_EMPTY_THRESH = 2
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
localparam                                  INCNT = WIDTH_OUTPUT/WIDTH_INPUT;
localparam                                  INCNT_WIDTH  = clog2b(INCNT);
localparam                                  FIFO_ADDR_WIDTH = clog2b(FIFO_DEEPTH);
// Register Define 
reg         [INCNT_WIDTH-1:0]               input_cnt;
reg                                         wr_en;
reg         [WIDTH_OUTPUT-1:0]              fifo_in;
// Wire Define
wire                                        prog_full;

always @ (posedge WC_in_clk or posedge rst) begin
    if(rst==1'b1)
        begin
            input_cnt <= #U_DLY 'd0;
            WC_in_rdy <= #U_DLY 1'b0;
            wr_en <= #U_DLY 1'b0;
            fifo_in <= #U_DLY {WIDTH_OUTPUT{1'b0}};
        end
    else
        begin
            if(WC_in_vld==1'b1 && input_cnt==(INCNT-1))
                input_cnt <= #U_DLY 'd0;
            else if(WC_in_vld==1'b1)
                input_cnt <= #U_DLY input_cnt + 'd1;

            if(prog_full==1'b1)
                WC_in_rdy <= #U_DLY 1'b0;
            else
                WC_in_rdy <= #U_DLY 1'b1;

            if(WC_in_vld==1'b1 && WC_in_rdy==1'b1 && input_cnt==(INCNT-1))
                wr_en <= #U_DLY 1'b1;
            else
                wr_en <= #U_DLY 1'b0;

            if(WC_in_vld==1'b1)
                fifo_in <= #U_DLY {WC_in_data,fifo_in[WIDTH_OUTPUT-1:WIDTH_INPUT]};
        end
end

//---------------------------------------------------------------
//asyn_fifo
//---------------------------------------------------------------
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (WIDTH_OUTPUT               ),
    .DATA_DEEPTH                (FIFO_DEEPTH                ),
    .ADDR_WIDTH                 (FIFO_ADDR_WIDTH            ),
    .RAM_STYLE                  (RAM_STYLE                  )
)output_fifo
(
    .wr_clk                     (WC_in_clk                  ),
    .wr_rst_n                   (~rst                       ),
    .rd_clk                     (WC_out_clk                 ),
    .rd_rst_n                   (~rst                       ),
    .din                        (fifo_in                    ),
    .wr_en                      (wr_en                      ),
    .rd_en                      (rd_en                      ),
    .dout                       (WC_out_data                ),
    .full                       (full                       ),
    .prog_full                  (prog_full                  ),
    .empty                      (empty                      ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (FIFO_PROG_FULL_THRESH      ),
    .prog_empty_thresh          (FIFO_PROG_EMPTY_THRESH     ),
    .rd_data_count              (                           ),
    .wr_data_count              (                           )
);

assign rd_en = (empty == 1'b0 && WC_out_rdy == 1'b1) ? 1'b1 : 1'b0;
assign WC_out_vld = rd_en;

assign WC_fifo_empty = empty;
assign WC_fifo_prog_full = prog_full;

endmodule
