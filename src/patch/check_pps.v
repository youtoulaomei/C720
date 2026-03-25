//////////////////////////////////////////////////////////////////////////////////
    // Company:
    // Engineer:
    // 
    // Create Date:  
    // Design Name:   ZhaoGaoMin
    // Module Name: 
    // Project Name: 
    // Target Devices:
    // Tool Versions: 
    // Description: 
    // 
    // Dependencies: 
    // 
    // Revision:
    // Revision 0.01 - File Created
    // Additional Comments:
    // 
    //////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns/1 ns
module check_pps #(
parameter                           U_DLY = 1
) 
(
input                               clk_100m,
input                               sys_rst,

input                               pps,
input                               timing_1s,

output    wire                      check_err               

);
// Parameter Define 

// Register Define 
reg       [2:0]                     pps_r;
reg                                 pps_check;
reg       [2:0]                     timing_1s_r;
reg       [2:0]                     timing_1s_cnt;

// Wire Define 

assign  check_err = pps_check;

always @(posedge clk_100m or posedge sys_rst ) 
begin
    if (sys_rst ==1'b1)
        begin
            pps_r <= #U_DLY 'd0;
            timing_1s_r <= #U_DLY 'd0;
        end
    else
        begin
            pps_r <= #U_DLY {pps_r[1:0],pps};
            timing_1s_r <= #U_DLY {timing_1s_r[1:0],timing_1s};
        end
end

always @(posedge clk_100m or posedge sys_rst) 
begin
    if (sys_rst==1'b1)
        begin
            timing_1s_cnt <= #U_DLY 'd0;
        end
    else
        begin
            if (pps_r[2] ^ pps_r[1] == 1'b1)
                timing_1s_cnt <= #U_DLY 'd0;
            else if (timing_1s_cnt == 'd3)
                timing_1s_cnt <= #U_DLY timing_1s_cnt;
            else if (timing_1s_r[2] ^ timing_1s_r[1] ==1'b1)
                timing_1s_cnt <= #U_DLY timing_1s_cnt + 'd1;
            else;
        end
end

always @(posedge clk_100m or posedge sys_rst ) 
begin
    if (sys_rst==1'b1)
        begin
            pps_check <= #U_DLY 1'b0;
        end
    else
        begin
            if (timing_1s_cnt == 'd3)
                pps_check <= #U_DLY 1'b1;
            else
                pps_check <= #U_DLY 1'b0;
        end
end
    
endmodule
