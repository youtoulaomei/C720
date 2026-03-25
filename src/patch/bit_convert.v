
`timescale 1 ns / 1 ns
module bit_convert # (
parameter                           U_DLY = 1,
parameter                           WIDTH_INPUT = 32,
parameter                           WIDTH_OUTPUT = 256
)
(
input                               WC_in_clk,
input                               rst,
// width_conversion_B2S input data
input        [WIDTH_INPUT-1:0]      WC_in_data,
input                               WC_in_vld,
// width_conversion_B2S output data
output       [WIDTH_OUTPUT-1:0]     WC_out_data,
output                              WC_out_vld
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
// Register Define 
reg         [INCNT_WIDTH-1:0]               input_cnt;
reg                                         wr_en;
reg         [WIDTH_OUTPUT-1:0]              fifo_in;
// Wire Define
// wire                                        prog_full;

always @ (posedge WC_in_clk or posedge rst) begin
    if(rst==1'b1)
        begin
            input_cnt <= #U_DLY 'd0;
            wr_en <= #U_DLY 1'b0;
            fifo_in <= #U_DLY {WIDTH_OUTPUT{1'b0}};
        end
    else
        begin
            if(WC_in_vld==1'b1 && input_cnt==(INCNT-1))
                input_cnt <= #U_DLY 'd0;
            else if(WC_in_vld==1'b1)
                input_cnt <= #U_DLY input_cnt + 'd1;

            // if(prog_full==1'b1)
                // WC_in_rdy <= #U_DLY 1'b0;
            // else
                // WC_in_rdy <= #U_DLY 1'b1;

            if(WC_in_vld==1'b1 && input_cnt==(INCNT-1))
                wr_en <= #U_DLY 1'b1;
            else
                wr_en <= #U_DLY 1'b0;

            if(WC_in_vld==1'b1)
                fifo_in <= #U_DLY {WC_in_data,fifo_in[WIDTH_OUTPUT-1:WIDTH_INPUT]};
        end
end








// always@(posedge clk or posedge clk)begin
	// if(rst)begin
	
	// end
	// else if()begin
	
	// end
// end
assign WC_out_vld = wr_en;
assign WC_out_data = fifo_in;


endmodule
