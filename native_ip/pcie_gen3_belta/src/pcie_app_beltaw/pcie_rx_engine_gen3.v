// *********************************************************************************/
// Project Name :
// Author       : dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/11/2 9:59:25
// File Name    : .v
// Module Name  : 
// Called By    :
// Abstract     :
//
// CopyRight(c) 2014, Sichuan shenrong digital equipment Co., Ltd.. 
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
module pcie_rx_engine_gen3 # (
parameter                           U_DLY = 1,
parameter                           RTAG_NUM = 32
)
(
input                               clk,
input                               rst_n,
input           [2:0]               cfg_max_payload,
input                               rchn_st,
//  Requester Completion Package
//(* syn_keep = "true", mark_debug = "true" *)
input           [255:0]             m_axis_rc_tdata,        
input           [74:0]              m_axis_rc_tuser,
input                               m_axis_rc_tlast,
input           [7:0]               m_axis_rc_tkeep,
input                               m_axis_rc_tvalid,
output  wire                        m_axis_rc_tready,
//
output reg                          tag_release,
//  RX Buffer
output reg                          rmem_wr,
output reg      [7:0]               rmem_waddr,
output reg      [511:0]             rmem_wdata,
//  Debug Interface
output reg                          rc_is_err,
output reg                          rc_is_fail
);


// Parameter Define 
localparam                          ADDR_128PAYLOAD = (RTAG_NUM*128)/64; 
localparam                          ADDR_256PAYLOAD = (RTAG_NUM*256)/64; 
localparam                          ADDR_512PAYLOAD = (RTAG_NUM*512)/64;      
// Register Define 
reg                                 rc_req_complete;
reg     [159:0]                     rc_data_reg;
reg     [RTAG_NUM-1:0]              cpld_tag_count;
reg     [3:0]                       tag_release_r;
reg                                 rc_wr;
reg     [255:0]                     rc_wdata;
reg                                 rc_wr_flg;
//(* syn_keep = "true", mark_debug = "true" *)
reg     [2:0]                       cfg_max_payload_r1;
reg     [2:0]                       cfg_max_payload_r2;
reg     [8:0]                       rmem_wr_cnt;
reg     [7:0]                       cpld_cnt;
reg     [7:0]                       rmem_waddr_pre;
reg                                 rmem_waddr_ind;
reg     [11:0]                      st_byte_addr;


// Wire Define 
wire                                rc_sof;
wire    [4:0]                       rc_tag_x;
wire                                rc_last_x;
wire    [11:0]                      byte_count;
wire                                cpld_first;

wire    [11:0]                      st_mem_waddr;




assign rc_tag_x = m_axis_rc_tdata[64+:5];
assign m_axis_rc_tready = 1'b1;
assign rc_sof = m_axis_rc_tuser[32];
assign rc_last_x = (m_axis_rc_tvalid==1'b1 && m_axis_rc_tready == 1'b1 && m_axis_rc_tlast==1'b1 && rc_sof==1'b0) ? 1'b1 :1'b0;
assign cpld_first = (m_axis_rc_tready==1'b1 && m_axis_rc_tvalid==1'b1 && rc_sof==1'b1) ? 1'b1:1'b0;  



assign byte_count=m_axis_rc_tdata[16+:12];

always @ (*)begin
    case(cfg_max_payload_r2)
        3'b000:st_byte_addr=12'h080-byte_count;
        3'b001:st_byte_addr=12'h100-byte_count;
        3'b010:st_byte_addr=12'h200-byte_count;
         default:st_byte_addr=12'h0;
    endcase
end

assign st_mem_waddr=st_byte_addr[11:6];

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0) 
        begin    
            rmem_waddr_pre <= #U_DLY 'b0;
            rmem_waddr_ind <= #U_DLY 1'b0;
            cpld_cnt <= #U_DLY 'd0;
        end       
    else 
        begin
            if(m_axis_rc_tready==1'b1 && m_axis_rc_tvalid==1'b1 && cpld_first==1'b1)
    	        case(cfg_max_payload_r2)
    	            3'b000:rmem_waddr_pre <= #U_DLY {2'b0,rc_tag_x,st_mem_waddr[0]};
    	            3'b001:rmem_waddr_pre <= #U_DLY {1'b0,rc_tag_x,st_mem_waddr[1:0]};
    	            3'b010:rmem_waddr_pre <= #U_DLY {rc_tag_x,st_mem_waddr[2:0]};
    	        endcase
            
            if(rc_last_x==1'b1)
                 cpld_cnt <= #U_DLY 'd0;
            else if(m_axis_rc_tready==1'b1 && m_axis_rc_tvalid==1'b1)
                 cpld_cnt <= #U_DLY cpld_cnt + 'd1;

            if(m_axis_rc_tready==1'b1 && m_axis_rc_tvalid==1'b1 && cpld_cnt=='d2 && rc_sof==1'b0)
                rmem_waddr_ind <= #U_DLY 1'b1;
            else
                rmem_waddr_ind <= #U_DLY 1'b0;
        end
end



always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rc_data_reg <= #U_DLY 'b0;        
    else if(m_axis_rc_tvalid==1'b1 && m_axis_rc_tready==1'b1)
        rc_data_reg <= #U_DLY  m_axis_rc_tdata[255:96];    
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rc_wr <= #U_DLY 1'b0;        
    else if(m_axis_rc_tvalid==1'b1 && m_axis_rc_tready==1'b1 && rc_sof==1'b0)
        rc_wr <= #U_DLY 1'b1;
    else
        rc_wr <= #U_DLY 1'b0;   
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rc_wdata <= #U_DLY 'b0;        
    else if(m_axis_rc_tvalid==1'b1 && m_axis_rc_tready==1'b1 && rc_sof==1'b0) 
        rc_wdata <= #U_DLY {m_axis_rc_tdata[95:0],rc_data_reg};   
end


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rmem_wr <= #U_DLY 1'b0;        
    else if(rc_wr==1'b1 && rc_wr_flg==1'b1)
        rmem_wr <= #U_DLY 1'b1;
    else
        rmem_wr <= #U_DLY 1'b0;   
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rc_wr_flg <= #U_DLY 1'b0;        
    else if(rc_wr==1'b1)
        rc_wr_flg <= #U_DLY rc_wr_flg + 1'b1;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rmem_wdata <= #U_DLY 'b0;        
    else if(rc_wr==1'b1 && rc_wr_flg==1'b0)
        rmem_wdata[255:0]   <= #U_DLY rc_wdata;
    else if(rc_wr==1'b1 && rc_wr_flg==1'b1)
    	rmem_wdata[511:256] <= #U_DLY rc_wdata;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rmem_waddr <= #U_DLY 'b0;
    else if(rmem_waddr_ind==1'b1)
        rmem_waddr <= #U_DLY rmem_waddr_pre;
    else if(rmem_wr==1'b1)      
        rmem_waddr <= #U_DLY rmem_waddr + 'd1;
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        rmem_wr_cnt <= #U_DLY 'b0; 
    else if((rmem_wr_cnt>=ADDR_128PAYLOAD && tag_release_r[0]==1'b1 && cfg_max_payload_r2==3'b000)
    	     ||(rmem_wr_cnt>=ADDR_256PAYLOAD && tag_release_r[0]==1'b1 && cfg_max_payload_r2==3'b001)
    	     ||(rmem_wr_cnt>=ADDR_512PAYLOAD && tag_release_r[0]==1'b1 && cfg_max_payload_r2==3'b010))
    	  rmem_wr_cnt <= #U_DLY 'b0;  	        	
    else if(rmem_wr=='b1)
    	  rmem_wr_cnt <= #U_DLY rmem_wr_cnt + 'b1;   	  
end


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        cpld_tag_count <= #U_DLY 'b0;        
    else if(tag_release == 1'b1)
        cpld_tag_count <= #U_DLY 'b0;
    else 
        begin:TAG_PRO
            integer i;
            for(i=0;i<RTAG_NUM;i=i+1)
               if(m_axis_rc_tvalid==1'b1 && m_axis_rc_tready == 1'b1 && rc_sof == 1'b1 && m_axis_rc_tdata[30]==1'b1 &&  m_axis_rc_tdata[68:64]==i )
                   cpld_tag_count[i] <= #U_DLY 1'b1;                   
        end
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        tag_release_r <= #U_DLY 'b0;
    else 
        begin
            tag_release_r[3:1] <= #U_DLY tag_release_r[2:0];

          //if((&cpld_tag_count ==1'b1) && ((rmem_wr_cnt>='d64 && cfg_max_payload_r2==3'b000) || (rmem_wr_cnt>='d128 && cfg_max_payload_r2==3'b001)  || (rmem_wr_cnt>='d256 && cfg_max_payload_r2==3'b010)) )          
           if((&cpld_tag_count ==1'b1) && 
            ((rmem_wr_cnt>=ADDR_128PAYLOAD && cfg_max_payload_r2==3'b000) || (rmem_wr_cnt>=ADDR_256PAYLOAD && cfg_max_payload_r2==3'b001)  || (rmem_wr_cnt>=ADDR_512PAYLOAD && cfg_max_payload_r2==3'b010)) )
                tag_release_r[0] <= #U_DLY 1'b1; 
            else
                tag_release_r[0] <= #U_DLY 1'b0;
        end
end


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)     
        tag_release <= #U_DLY 1'b0;        
    else if(|tag_release_r==1'b1)   
        tag_release <= #U_DLY 1'b1;
    else
        tag_release <= #U_DLY 1'b0;   
end



always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            rc_is_err <= 1'b0;
            rc_is_fail <= 1'b0;
        end
    else    
        begin
        	  if(rc_is_err==1'b1)
        	  	  rc_is_err <= #U_DLY 1'b0;
            else if({m_axis_rc_tvalid,m_axis_rc_tready} == 2'b11 && rc_sof == 1'b1 && (m_axis_rc_tdata[15:12] != 4'b0000 || m_axis_rc_tdata[34:32] != 3'b000))    //Dword Count is not n*256b
                rc_is_err <= #U_DLY 1'b1;

            if(rc_is_fail==1'b1)
            	  rc_is_fail <= #U_DLY 1'b0; 
            else if({m_axis_rc_tvalid,m_axis_rc_tready} == 2'b11 && rc_sof == 1'b1 && m_axis_rc_tdata[45:43] != 3'b000) 
            	  rc_is_fail <= #U_DLY 1'b1;
//                ({m_axis_rc_tvalid,m_axis_rc_tready,m_axis_rc_tlast} == 3'b111 && rc_req_complete == 1'b1 ))
                          
        end
end


always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)     
        begin
            cfg_max_payload_r1 <= 3'b0;
            cfg_max_payload_r2 <= 3'b0;
        end
    else   
       begin
            cfg_max_payload_r1 <= cfg_max_payload;
            //cfg_max_payload_r2 <= cfg_max_payload_r1;
            case(cfg_max_payload_r1)
                3'b000:cfg_max_payload_r2 <= #U_DLY 3'b000;  //128BYTE
                3'b001:cfg_max_payload_r2 <= #U_DLY 3'b001;  //256BYTE
                3'b010:cfg_max_payload_r2 <= #U_DLY 3'b001;  //256BYTE
                default:cfg_max_payload_r2 <= #U_DLY 3'b000;  //128BYTE
            endcase

       end    	
end 


//(* syn_keep = "true", mark_debug = "true" *)reg [2:0] rchn_st_r;
//(* syn_keep = "true", mark_debug = "true" *)reg [31:0]  rmem_wr_cnt;
//(* syn_keep = "true", mark_debug = "true" *)reg [31:0]  rmem_wr_cnt_h;
//
//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)                  
//        rchn_st_r <= #U_DLY 'b0;               
//    else 
//        rchn_st_r <= #U_DLY {rchn_st_r[1:0],rchn_st};   
//end
//
//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)                   
//        rmem_wr_cnt <= #U_DLY 'b0;        
//    else if(rchn_st_r[1]==1'b1 && rchn_st_r[2]==1'b0)
//        rmem_wr_cnt <= #U_DLY 'b0;
//    else if(rmem_wr==1'b1)
//        rmem_wr_cnt <= #U_DLY rmem_wr_cnt + 'd64;   
//end
//
//always @ (posedge clk or negedge rst_n)
//begin
//    if(rst_n == 1'b0)                    
//        rmem_wr_cnt_h <= #U_DLY 'b0;        
//    else if(rchn_st_r[1]==1'b1 && rchn_st_r[2]==1'b0)
//        rmem_wr_cnt_h <= #U_DLY 'b0;
//    else if(rmem_wr==1'b1 && rmem_wr_cnt==32'hffff_ffc0)
//        rmem_wr_cnt_h <= #U_DLY rmem_wr_cnt_h + 'd1;   
//end



(* syn_keep = "true", mark_debug = "true" *)reg [2:0]      rchn_st_r;
(* syn_keep = "true", mark_debug = "true" *)reg       rchn_first;
(* syn_keep = "true", mark_debug = "true" *)reg [511:0] rmem_wdata_r;
(* syn_keep = "true", mark_debug = "true" *)reg [15:0]  rmem_terr_l;
(* syn_keep = "true", mark_debug = "true" *)reg         rmem_terr;

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)                  
        rchn_st_r <= #U_DLY 'b0;               
    else 
        rchn_st_r <= #U_DLY {rchn_st_r[1:0],rchn_st};   
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)         
        rchn_first <= #U_DLY 1'b0;        
    else if(rchn_st_r[1]==1'b1 && rchn_st_r[2]==1'b0)
        rchn_first <= #U_DLY 1'b1;
    else if(rmem_wr==1'b1) 
        rchn_first <= #U_DLY 1'b0;  
end

always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)         
        rmem_wdata_r <= #U_DLY 'b0;        
    else if(rmem_wr==1'b1)   
        rmem_wdata_r <= #U_DLY rmem_wdata;
end

always @ (posedge clk or negedge rst_n)begin:RMEM_TERR_L_PRO
integer i;
    if(rst_n == 1'b0)      
        rmem_terr_l <= #U_DLY 'b0;       
    else if(rmem_wr==1'b1 && rchn_first==1'b0)
        begin
            for(i=0;i<16;i=i+1)
               if(rmem_wdata[i*32+:32]!=rmem_wdata_r[i*32+:32]+'d16)
                   rmem_terr_l[i] <= #U_DLY 1'b1;
               else
                   rmem_terr_l[i] <= #U_DLY 1'b0;
        end   
    else
        rmem_terr_l <= #U_DLY 'b0;   
end


always @ (posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)    
        rmem_terr <= #U_DLY 1'b0; 
    else if(|rmem_terr_l==1'b1)
        rmem_terr <= #U_DLY 1'b1;     
    else 
        rmem_terr <= #U_DLY 1'b0;     
end



endmodule
