// *********************************************************************************/
// Project Name :
// Author       : dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/11/30 14:01:49
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Boyulihua Co., Ltd.. 
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
module pcie_regif_gen3 #(
parameter                           U_DLY = 1
)
(
input                               clk,
input                               rst_n,
input           [255:0]             m_axis_cq_tdata,
input           [84:0]              m_axis_cq_tuser,
input                               m_axis_cq_tlast,
input           [7:0]               m_axis_cq_tkeep,
input                               m_axis_cq_tvalid,
output  reg                         m_axis_cq_tready,

output  reg     [255:0]             s_axis_cc_tdata,
output  wire    [32:0]              s_axis_cc_tuser,
output  wire                        s_axis_cc_tlast,
output  wire    [7:0]               s_axis_cc_tkeep,
output  reg                         s_axis_cc_tvalid,
input                               s_axis_cc_tready,

output  reg                         r_wr_en,
output  reg     [18:0]              r_addr,
output  reg     [31:0]              r_wr_data,
output  reg                         r_rd_en,
input           [31:0]              r_rd_data,

output  wire                        err_type_l,
output  wire                        err_bar_l,
output  wire                        err_len_l 
);
// Parameter Define 

// Register Define 
reg                                 cq_busy;
reg                                 req_vld;
reg     [1:0]                       req_at;
reg                                 req_type;
reg     [7:0]                       req_addr;
reg     [15:0]                      req_id;
reg     [2:0]                       req_tc;
reg     [2:0]                       req_attr;
reg     [7:0]                       req_tag;
reg     [2:0]                       req_tar_func;
reg     [31:0]                      req_data;
reg                                 cq_done;
reg     [1:0]                       rd_dly;
reg                                 bar0_ind;
reg     [1:0]                       low_addr;
reg     [2:0]                       byte_count;
reg     [7:0]                       bar_cnt;
reg                                 r_wr_en_r1;
reg                                 r_rd_en_r1;
reg                                 err_type;
reg                                 err_bar;
reg                                 err_len;
reg     [2:0]                       err_type_r;
reg     [2:0]                       err_bar_r;
reg     [2:0]                       err_len_r;
reg     [256+4-1:0]                 cmd_din;
reg                                 cmd_wen;

// Wire Define 
wire    [31:0]                      header_dw0;
wire    [31:0]                      header_dw1;
wire    [31:0]                      header_dw2;
wire    [3:0]                       first_be;
wire                                cmd_ren;
wire    [256+4-1:0]                 cmd_dout;
wire                                cmd_prog_full;
wire                                cmd_empty;




//----------------------------------------------------------------
//u_bar_cmd_fifo
//----------------------------------------------------------------
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (256+4                      ),
    .DATA_DEEPTH                (256                        ),
    .ADDR_WIDTH                 (8                          )
)u_bar_cmd_fifo
(
    .wr_clk                     (clk                        ),
    .wr_rst_n                   (rst_n                      ),
    .rd_clk                     (clk                        ),
    .rd_rst_n                   (rst_n                      ),
    .din                        (cmd_din                    ),
    .wr_en                      (cmd_wen                    ),
    .rd_en                      (cmd_ren                    ),
    .dout                       (cmd_dout                   ),
    .full                       (                           ),
    .prog_full                  (cmd_prog_full              ),
    .empty                      (cmd_empty                  ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (8'd248                     ),
    .prog_empty_thresh          (8'd4                       ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )
);
//----------------------------------------------------------------
//u_bar_cmd_fifo
//----------------------------------------------------------------


assign cmd_ren = (cmd_empty==1'b0 && r_rd_en_r1==1'b1 && r_wr_en_r1==1'b1 && req_vld==1'b0 && cq_busy==1'b0) ? 1'b1 : 1'b0;

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        cmd_wen <= #U_DLY 1'b0;
    else if(m_axis_cq_tvalid==1'b1 && m_axis_cq_tready==1'b1 && m_axis_cq_tlast ==1'b1)  
        cmd_wen <= #U_DLY 1'b1;
    else
    	cmd_wen <= #U_DLY 1'b0;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        cmd_din <= #U_DLY 'b0;
    else if(m_axis_cq_tvalid==1'b1 && m_axis_cq_tready==1'b1 && m_axis_cq_tlast ==1'b1)  
        cmd_din <= #U_DLY {m_axis_cq_tuser[3:0],m_axis_cq_tdata};
    else
    	cmd_din <= #U_DLY 'b0;
end


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        m_axis_cq_tready <= 1'b1;
    else    
        begin
            if(cmd_prog_full == 1'b0)
                m_axis_cq_tready <= 1'b1;
            else if({m_axis_cq_tvalid,m_axis_cq_tready,m_axis_cq_tlast} == 3'b111 &&  cmd_prog_full == 1'b1 )
                m_axis_cq_tready <= #U_DLY 1'b0;
        end
end

//----------------------------------------------------------------
// logic
//----------------------------------------------------------------
assign first_be = cmd_dout[256+:4];

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            cq_busy <= 1'b0;
            req_vld <= 1'b0;
            req_at <= 2'd0;
            req_type <= 1'd0; 
            req_addr <= 8'd0;
            req_id <= 16'd0;
            req_tc <= 3'd0;
            req_attr <= 3'd0;
            req_tag <= 8'd0;
            req_tar_func <= 3'd0;
            req_data <= 32'd0;
            low_addr <= 2'd0;
            byte_count <= 3'd0;
        end
    else    
        begin
        	  if(cq_done == 1'b1)
                cq_busy <= #U_DLY 1'b0;
            else if(cmd_ren == 1'b1)
                cq_busy <= #U_DLY 1'b1;
            else if(r_wr_en_r1 == 1'b0 || r_rd_en_r1==1'b0)
            	cq_busy <= #U_DLY 1'b1;

            if(cmd_ren == 1'b1)
                req_vld <= #U_DLY 1'b1;           
            else
                req_vld <= #U_DLY 1'b0;

            if(cmd_ren == 1'b1)
                req_at <= #U_DLY cmd_dout[1:0]; 

            if(cmd_ren == 1'b1)
                req_addr <= #U_DLY cmd_dout[9:2];           

            if(cmd_ren == 1'b1)
                req_type <= #U_DLY cmd_dout[75];     //0:read 1:write          

            if(cmd_ren == 1'b1)
                req_id <= #U_DLY cmd_dout[95:80];     

            if(cmd_ren == 1'b1)
                req_tag <= #U_DLY cmd_dout[103:96];     

            if(cmd_ren == 1'b1)
                req_tar_func <= #U_DLY cmd_dout[106:104];            

            if(cmd_ren == 1'b1)
                req_tc <= #U_DLY cmd_dout[123:121];            

            if(cmd_ren == 1'b1)
                req_attr <= #U_DLY cmd_dout[126:124];            

            if(cmd_ren == 1'b1)
                req_data <= #U_DLY cmd_dout[159:128];           

            if(cmd_ren == 1'b1)
                begin
                    if(first_be == 4'b0000 || first_be[0] == 1'b1)
                        low_addr <= #U_DLY 2'b00;
                    else if(first_be[1] == 1'b1)
                        low_addr <= #U_DLY 2'b01;
                    else if(first_be[2] == 1'b1)
                        low_addr <= #U_DLY 2'b10;
                    else if(first_be[3] == 1'b1)
                        low_addr <= #U_DLY 2'b11;
                end
            
            if(cmd_ren == 1'b1)
                begin
                    case(first_be)
                        4'b1001,4'b1011,4'b1101,4'b1111 :   byte_count <= #U_DLY 3'd4;
                        4'b0101,4'b0111,4'b1010,4'b1110 :   byte_count <= #U_DLY 3'd3;
                        4'b0011,4'b0110,4'b1100         :   byte_count <= #U_DLY 3'd2;
                        4'b0000,4'b0001,4'b0010,4'b0100,4'b1000:byte_count <= #U_DLY 3'd1;
                        default                         :   byte_count <= #U_DLY 3'd4;
                    endcase
                end           
        end
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            err_type <= 1'b0;
            err_bar  <= 1'b0;
            bar0_ind <= 1'b0;
            err_len  <= 1'b0;
        end
    else    
        begin
            //if({m_axis_cq_tvalid,m_axis_cq_tready,m_axis_cq_tlast} == 3'b111)
            if(cmd_ren == 1'b1)
                begin
                    if(cmd_dout[78:76] != 3'b000)
                        err_type <= #U_DLY 1'b1;
                    else
                        err_type <= #U_DLY 1'b0;
                end
            else
                err_type <= #U_DLY 1'b0;

            //if({m_axis_cq_tvalid,m_axis_cq_tready,m_axis_cq_tlast} == 3'b111)
            if(cmd_ren == 1'b1)
                begin
                    if(cmd_dout[114:112] == 3'b000)
                        bar0_ind <= #U_DLY 1'b1;
                    else
                        bar0_ind <= #U_DLY 1'b0;
                end
            else
                bar0_ind <= #U_DLY 1'b0;


            //if({m_axis_cq_tvalid,m_axis_cq_tready,m_axis_cq_tlast} == 3'b111)
            if(cmd_ren == 1'b1)
                begin
                    //if(m_axis_cq_tdata[114:112] != 3'b000 && m_axis_cq_tdata[114:112] != 3'b001)
                    if(cmd_dout[114:112] != 3'b000)
                        err_bar  <= #U_DLY 1'b1;
                    else
                        err_bar  <= #U_DLY 1'b0;
                end
            else
                err_bar  <= #U_DLY 1'b0;
            

            //if({m_axis_cq_tvalid,m_axis_cq_tready,m_axis_cq_tlast} == 3'b111)
            if(cmd_ren == 1'b1)
                begin
                    if(cmd_dout[74:64] != 11'd1)
                        err_len <= #U_DLY 1'b1;
                    else
                        err_len <= #U_DLY 1'b0;
                end
            else
                err_len <= #U_DLY 1'b0;
        end
end

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            err_type_r <= #U_DLY 'b0; 
            err_bar_r  <= #U_DLY 'b0;
            err_len_r  <= #U_DLY 'b0;
        end
    else
        begin
            err_type_r <= #U_DLY {err_type_r[1:0],err_type}; 
            err_bar_r  <= #U_DLY {err_bar_r[1:0],err_bar};
            err_len_r  <= #U_DLY {err_len_r[1:0],err_len};
        end
end

assign err_type_l = (|err_type_r==1'b1) ? 1'b1 : 1'b0;
assign err_bar_l  = (|err_bar_r==1'b1) ? 1'b1 : 1'b0;
assign err_len_l  = (|err_len_r==1'b1) ? 1'b1 : 1'b0;


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            r_wr_en_r1 <= 1'b1;
            r_rd_en_r1 <= 1'b1;
            r_wr_data <= 32'd0;
            r_addr <= 19'd0;
        end
    else
        begin
            if(r_wr_en_r1==1'b0 && bar_cnt=='d199)         	             
                r_wr_en_r1 <= #U_DLY 1'b1; 
            else if(req_vld == 1'b1 && {err_type,bar0_ind,err_len} == 3'b010 && req_type ==1'b1) 
                r_wr_en_r1 <= #U_DLY 1'b0;                           
            
            if(r_rd_en_r1==1'b0 && bar_cnt=='d199)
            	r_rd_en_r1 <= #U_DLY 1'b1;                                                              
            else if(req_vld == 1'b1 && {err_type,bar0_ind,err_len} == 3'b010 && req_type ==1'b0) 
                r_rd_en_r1 <= #U_DLY 1'b0;                           
            
            if(cmd_ren==1'b1)
                r_wr_data <= #U_DLY cmd_dout[159:128];
            
            if(cmd_ren==1'b1)
                r_addr <= #U_DLY cmd_dout[18:0]; 

        end
end


always @ (posedge clk or negedge rst_n)
begin
	 if(rst_n==1'b0)
	     r_wr_en <= #U_DLY 1'b1; 
	 else if(r_wr_en_r1==1'b0 && bar_cnt=='d199)
	     r_wr_en <= #U_DLY 1'b1;
     else if(r_wr_en_r1==1'b0 && bar_cnt=='d39)
         r_wr_en <= #U_DLY 1'b0;           
end


always @ (posedge clk or negedge rst_n)
begin
	 if(rst_n==1'b0)
	     r_rd_en <= #U_DLY 1'b1; 
	 else if(r_rd_en_r1==1'b0 && bar_cnt=='d199)
	     r_rd_en <= #U_DLY 1'b1;
     else if(r_rd_en_r1==1'b0 && bar_cnt=='d39)
         r_rd_en <= #U_DLY 1'b0;           
end

always @ (posedge clk or negedge rst_n)
begin
	  if(rst_n==1'b0)
	      bar_cnt <= 'b0;
	  else if((r_wr_en_r1==1'b0 || r_rd_en_r1==1'b0) && bar_cnt=='d199)
	  	  bar_cnt <= 'b0;
	  else if(r_wr_en_r1==1'b0 || r_rd_en_r1==1'b0)
	      bar_cnt <= bar_cnt + 'b1;
end


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        cq_done <= 1'b0;
    else    
        begin
            if( (r_wr_en_r1==1'b0 && bar_cnt=='d199)  || {s_axis_cc_tvalid,s_axis_cc_tready,s_axis_cc_tlast} == 3'b111)
                cq_done <= #U_DLY 1'b1;
            else
                cq_done <= #U_DLY 1'b0;
        end
end

assign header_dw0 = {{13'd0,byte_count},{6'd0,req_at},{1'b0,req_addr[4:0],low_addr}};
assign header_dw1 = {req_id,8'd0,8'd1};
assign header_dw2 = {{1'b0,req_attr,req_tc,1'b0},8'd0,{5'd0,req_tar_func},req_tag};

assign s_axis_cc_tlast = s_axis_cc_tvalid;
assign s_axis_cc_tkeep = 8'h0f;
assign s_axis_cc_tuser = 33'd0;

always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            s_axis_cc_tvalid <= 1'b0;
            s_axis_cc_tdata <= 256'd0;
            rd_dly <= 2'd0;
        end
    else    
        begin
            rd_dly <= #U_DLY {rd_dly[0],(r_rd_en_r1==1'b0 && bar_cnt=='d199) };
            
            if({s_axis_cc_tvalid,s_axis_cc_tready,s_axis_cc_tlast} == 3'b111)
                s_axis_cc_tvalid <= #U_DLY 1'b0;
            else if(rd_dly[1] == 1'b1)
                s_axis_cc_tvalid <= #U_DLY 1'b1;
            else;

            if(rd_dly[1] == 1'b1)
                s_axis_cc_tdata <= #U_DLY {128'd0,r_rd_data,header_dw2,header_dw1,header_dw0}; 

        end
end


endmodule


