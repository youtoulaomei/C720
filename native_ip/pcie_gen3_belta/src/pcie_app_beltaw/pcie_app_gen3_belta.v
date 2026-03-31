// *********************************************************************************/
// Project Name : BHD-C720
// Author       : dingliang
// Email        : 63464404@qq.com
// Creat Time   : 2017/11/2 16:08:44
// File Name    : pcie_app_gen3_belta.v
// Module Name  : pcie_app_gen3_belta
// Called By    : 顶层FPGA设计
// Abstract     : PCIe Gen3 x8 多通道DMA引擎顶层模块
//
// ============================================================================
// 【模块功能概述】
//   本模块是 PCIe Gen3 DMA 引擎的顶层集成模块，实现 FPGA 与 PC 之间的
//   高速双向 DMA 数据传输。
//
// 【整体架构 — 子模块清单】
//   ┌───────────────────────────────────────────────────────────┐
//   │ 用户接口层                                                 │
//   │   couple_logic ×WPHY_NUM   : 上行数据耦合 + 跨时钟域FIFO    │
//   │   datas_builtin_top ×WPHY_NUM : 内建自测试数据发生器        │
//   │   pcie_rchn_couple ×RCHN_NUM  : 下行数据FIFO + 帧格式化     │
//   │   bandcount ×2                 : 上行/下行带宽统计          │
//   ├───────────────────────────────────────────────────────────┤
//   │ 仲裁与缓冲层                                               │
//   │   pcie_wchn_arbiter           : 写通道轮询仲裁 + TLP分片    │
//   │   pcie_rchn_arbiter           : 读通道仲裁 + 双缓冲管理     │
//   │   u_wib_fifo (asyn_fifo)      : 写信息FIFO (sys→user)      │
//   │   u_wdb_fifo (asyn_fifo)      : 写数据FIFO (sys→user)      │
//   │   u_rib_fifo (asyn_fifo)      : 读信息FIFO (sys→user)      │
//   ├───────────────────────────────────────────────────────────┤
//   │ TLP引擎层                                                  │
//   │   pcie_tx_engine_gen3         : TLP组装 + MWr/MRd发送      │
//   │   pcie_rx_engine_gen3         : Completion接收 + Tag管理    │
//   │   pcie_regif_gen3             : BAR0 寄存器读写接口         │
//   ├───────────────────────────────────────────────────────────┤
//   │ PCIe协议层                                                 │
//   │   pcie3_7x_0                  : Xilinx 7系列 Gen3 EP IP    │
//   │   pcie_msi_engine_gen3        : MSI 中断引擎               │
//   ├───────────────────────────────────────────────────────────┤
//   │ 控制管理层 (贯穿所有层)                                     │
//   │   pcie_cib                    : 中央控制接口块              │
//   │     └─ pcie_witem_glb + pcie_item ×WCHN_NUM : 写DMA描述符  │
//   │     └─ pcie_ritem_glb + pcie_item ×RCHN_NUM : 读DMA描述符  │
//   └───────────────────────────────────────────────────────────┘
//
// 【数据流方向】
//   上行(写DMA): 用户→couple_logic→wchn_arbiter→WDB/WIB→tx_engine→PCIe→PC内存
//   下行(读DMA): PC内存→PCIe→rx_engine→RAM→rchn_arbiter→rfifo→rchn_couple→用户
//   寄存器访问: PC→PCIe→CQ→regif→local_bus→CIB (读返回: CC)
//
// 【时钟域】
//   ref_clk    : PCIe参考时钟 100MHz (→ pcie3_7x_0)
//   user_clk   : PCIe用户时钟 ~250MHz (← pcie3_7x_0, 用于TLP引擎)
//   sys_clk    : 系统时钟 (用于仲裁器/CIB)
//   wchn_clk   : 上行用户时钟 (用于couple_logic写侧)
//   rchn_clk[] : 下行用户时钟 (用于rchn_couple读侧)
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
module pcie_app_gen3_belta # (
// ---- 通道与数据宽度参数 ----
parameter                           WCHN_NUM   = 32,    // 写(上行)逻辑通道数, 支持32路数据源共享PCIe链路
parameter                           RCHN_NUM   = 9,     // 读(下行)逻辑通道数, 9路独立接收通道
parameter                           WDATA_WIDTH= 512,   // 写数据位宽(bit), 用户接口每拍传512bit=64Byte
parameter                           RDATA_WIDTH= 512,   // 读数据位宽(bit)
parameter                           WCHN_NUM_W = clog2b(WCHN_NUM),  // 写通道编号位宽=5bit(log2(32))
parameter                           RCHN_NUM_W = clog2b(RCHN_NUM),  // 读通道编号位宽=4bit(log2(9))
parameter                           WPHY_NUM   = 1,     // 写物理通道数(=1, 所有逻辑通道复用1个物理口)
parameter                           WPHY_NUM_W = clog2b(WPHY_NUM),  // 物理通道编号位宽=1bit
// ---- PCIe传输参数 ----
parameter                           RTAG_NUM   = 16,    // 读请求Tag数量: 一次批量发出16个MRd请求
                                                        //   Tag越多=并发请求越多=带宽越高, 但需要更大RAM
parameter                           RBURST_LEN = 2048,  // 读突发长度(Bytes): 每帧固定输出2KB给用户
parameter                           BURST_LEN  = 2048,  // 写突发长度(Bytes): 每次从用户端连续读取2KB
parameter                           U_DLY      = 1      // 仿真延迟(ns): 所有 <= 后加 #U_DLY, 避免仿真竞争
)
(
// ========================================================================================
// 【时钟与复位】
// ========================================================================================
input                               ref_clk,        // PCIe参考时钟(100MHz), 输入给Xilinx IP的sys_clk口
input                               ref_reset_n,    // PCIe参考复位(低有效), 输入给Xilinx IP的sys_reset口
input                               sys_clk,        // 系统时钟, 驱动仲裁器/CIB/FIFO写侧等逻辑
input                               sys_rst_n,      // 系统复位(低有效)
output                              user_clk,       // 用户时钟(~250MHz), 由pcie3_7x_0输出, 驱动TLP引擎
output                              user_rst_n,     // 用户复位(低有效), 由pcie3_7x_0输出
input                               rtc_s_flg,      // RTC秒脉冲标志, 用于bandcount统计每秒带宽
input                               rtc_us_flg,     // RTC微秒脉冲标志, 用于datas_builtin_top令牌桶限速

// ========================================================================================
// 【PCIe物理层】 8条差分Lane, 直接连接PCIe金手指, 由Xilinx IP管理
// ========================================================================================
output      [7:0]                   pci_exp_txn,    // PCIe发送差分信号 负端 ×8lanes
output      [7:0]                   pci_exp_txp,    // PCIe发送差分信号 正端 ×8lanes
input       [7:0]                   pci_exp_rxn,    // PCIe接收差分信号 负端 ×8lanes
input       [7:0]                   pci_exp_rxp,    // PCIe接收差分信号 正端 ×8lanes
output                              pcie_link,      // PCIe链路建立指示, =user_lnk_up (高=链路正常)

// ========================================================================================
// 【本地总线接口】 PC通过BAR0空间读写FPGA内部寄存器
//   PC端: iowrite32(bar0_base + offset, data) → 经pcie_regif_gen3解析后驱动这些信号
// ========================================================================================
output                              r_wr_en,        // 寄存器写使能(低有效), 持续约160ns
output      [18:0]                  r_addr,         // 寄存器地址, 来自CQ TLP中的地址字段
output      [31:0]                  r_wr_data,      // 寄存器写数据, 来自CQ TLP中的数据字段
output                              r_rd_en,        // 寄存器读使能(低有效), 读完后由CC TLP返回数据
input       [31:0]                  r_rd_data,      // 寄存器读返回数据, 用CC Completion TLP返回给PC

// ========================================================================================
// 【CIB总线接口】 FPGA内部CPU或其他模块读写pcie_cib的控制寄存器
//   用于配置DMA描述符、启停控制、状态查询等
// ========================================================================================
input                               pcie_cs,        // 片选(低有效)
input                               pcie_wr,        // 写使能(低有效, 下降沿触发写入)
input                               pcie_rd,        // 读使能(低有效, 上升沿锁存地址)
input       [7:0]                   pcie_addr,      // 地址(8bit, 256个寄存器)
input       [31:0]                  pcie_wr_data,   // 写数据
output      [31:0]                  pcie_rd_data,   // 读返回数据


// ========================================================================================
// 【下行(读DMA)用户接口】 PC内存数据经DMA传输后, 通过此接口输出给FPGA其他模块
//   共RCHN_NUM=9个独立通道, 每通道有自己的时钟和rdy/vld握手
//   数据以固定长度帧输出: SOF + DATA×N + EOF (每帧RBURST_LEN=2048字节)
// ========================================================================================
input       [RCHN_NUM-1:0]                  rchn_clk,       // 各通道用户时钟(可不同频率)
input       [RCHN_NUM-1:0]                  rchn_rst_n,     // 各通道复位
input       [RCHN_NUM-1:0]                  rchn_data_rdy,  // 用户端就绪(高=可接收), 反压信号
output      [RCHN_NUM-1:0]                  rchn_data_vld,  // 数据有效(高=当前数据有效)
output      [RCHN_NUM-1:0]                  rchn_sof,       // Start of Frame 帧起始标志
output      [RCHN_NUM-1:0]                  rchn_eof,       // End of Frame 帧结束标志
output      [RCHN_NUM*RDATA_WIDTH-1:0]      rchn_data,      // 读回数据(9×512bit拼接)
output      [(RCHN_NUM*RDATA_WIDTH)/8-1:0]  rchn_keep,      // 字节使能(全1, 每拍64Byte全有效)
output      [RCHN_NUM*15-1:0]               rchn_length,    // 帧长度(固定=RBURST_LEN=2048)


// ========================================================================================
// 【上行(写DMA)用户接口】 FPGA其他模块的数据通过此接口注入, 经DMA传输到PC内存
//   共WPHY_NUM=1个物理通道, 通过wchn_chn字段标识32个逻辑通道
//   采用 ready/valid 握手: 仅当 data_rdy=1 且 data_vld=1 时数据被接收
// ========================================================================================
input       [WPHY_NUM-1:0]                   wchn_clk,       // 用户时钟(数据源时钟)
input       [WPHY_NUM-1:0]                   wchn_rst_n,     // 用户复位
output      [WPHY_NUM-1:0]                   wchn_data_rdy,  // DMA引擎就绪(高=可接收数据), 反压信号
input       [WPHY_NUM-1:0]                   wchn_data_vld,  // 数据有效(高=用户有数据要发)
input       [WPHY_NUM-1:0]                   wchn_sof,       // Start of Frame 帧起始
input       [WPHY_NUM-1:0]                   wchn_eof,       // End of Frame 帧结束
input       [WPHY_NUM*WDATA_WIDTH-1:0]       wchn_data,      // 用户数据(512bit)
input       [WPHY_NUM-1:0]                   wchn_end,       // DMA包结束(配合eof表示整包传完)
input       [(WPHY_NUM*WDATA_WIDTH)/8-1:0]   wchn_keep,      // 字节使能
input       [WPHY_NUM*15-1:0]                wchn_length,    // 本包长度(字节)
input       [WPHY_NUM*WCHN_NUM_W-1:0]        wchn_chn        // 逻辑通道号(0~31), 标识数据源身份
) /* synthesis syn_maxfan = 20 */;

// ========================================================================================
// 【局部参数 — PCIe设备序列号】 用于PCIe配置空间DSN(Device Serial Number)
// ========================================================================================
localparam                          PCI_EXP_EP_OUI   = 24'h000A35;  // Xilinx OUI
localparam                          PCI_EXP_EP_DSN_1 = {{8'h1},PCI_EXP_EP_OUI};
localparam                          PCI_EXP_EP_DSN_2 = 32'h1;


// Register Define 
reg                                 cfg_power_state_change_ack; // PCIe电源状态变更应答

// ========================================================================================
// 【内部信号声明】
// 按功能分组: PCIe IP接口 → DMA控制 → FIFO互联 → 调试
// ========================================================================================

// ---- PCIe IP 核心接口 (user_clk域, 连接pcie3_7x_0的AXI-Stream) ----
wire                                user_reset;         // PCIe IP输出的用户侧复位(高有效)
wire                                user_lnk_up;        // PCIe链路建立指示(高=Link Up)

// RQ (Requester Request): FPGA发送 MWr/MRd TLP → PC
//   数据流: tx_engine → s_axis_rq → pcie3_7x_0 → PCIe PHY
wire                                s_axis_rq_tlast;    // AXI-Stream 最后一拍
wire    [255:0]                     s_axis_rq_tdata;    // 256bit TLP数据(Header+Payload)
wire    [59:0]                      s_axis_rq_tuser;    // 附加信息({52'd0, last_be, first_be})
wire    [7:0]                       s_axis_rq_tkeep;    // 字节使能(8DW=256bit中有效的DW)
wire    [3:0]                       s_axis_rq_tready;   // IP就绪(背压信号)
wire                                s_axis_rq_tvalid;   // 数据有效

// RC (Requester Completion): PC返回的读完成数据 → FPGA
//   数据流: pcie3_7x_0 → m_axis_rc → rx_engine → RAM Buffer
wire    [255:0]                     m_axis_rc_tdata;    // 256bit Completion数据
wire    [74:0]                      m_axis_rc_tuser;    // {is_eof, byte_en, ...}
wire                                m_axis_rc_tlast;    // 包终止
wire    [7:0]                       m_axis_rc_tkeep;    // 字节使能
wire                                m_axis_rc_tvalid;   // 数据有效
wire                                m_axis_rc_tready;   // FPGA就绪

// CQ (Completer Request): PC通过BAR0发来的寄存器读写请求
//   数据流: pcie3_7x_0 → m_axis_cq → regif → local_bus
wire    [255:0]                     m_axis_cq_tdata;    // 256bit 请求TLP
wire    [84:0]                      m_axis_cq_tuser;    // {sop, byte_en}
wire                                m_axis_cq_tlast;
wire    [7:0]                       m_axis_cq_tkeep;
wire                                m_axis_cq_tvalid;
wire                                m_axis_cq_tready;

// CC (Completer Completion): FPGA回复PC的寄存器读数据
//   数据流: regif → s_axis_cc → pcie3_7x_0 → PC
wire    [255:0]                     s_axis_cc_tdata;
wire    [32:0]                      s_axis_cc_tuser;
wire                                s_axis_cc_tlast;
wire    [7:0]                       s_axis_cc_tkeep;
wire                                s_axis_cc_tvalid;
wire    [3:0]                       s_axis_cc_tready;

// PCIe 配置信息 (由IP输出, CIB用于自适应TLP大小)
wire    [3:0]                       cfg_negotiated_width;  // 协商链路宽度(8=x8)
wire    [2:0]                       cfg_current_speed;     // 当前速率(3=Gen3/8GT)
wire    [2:0]                       cfg_max_payload;       // 最大Payload(0=128B,1=256B,2=512B)
wire    [2:0]                       cfg_max_read_req;      // 最大读请求大小
wire                                cfg_power_state_change_interrupt; // 电源状态变更中断

// BAR 寄存器访问错误检测 (regif→CIB)
wire                                err_type_l;   // 请求类型错(非MWr/MRd)
wire                                err_bar_l;    // BAR号不匹配(非BAR0)
wire                                err_len_l;    // DWord计数≠1(仅支持单DW操作)

// ---- MSI 中断信号 ----
wire    [1:0]                       cfg_interrupt_msi_enable;   // MSI使能(由PCIe配置空间决定)
wire                                cfg_interrupt_msi_sent;     // MSI已发送确认
wire                                cfg_interrupt_msi_fail;     // MSI发送失败
wire    [31:0]                      cfg_interrupt_msi_int;      // MSI中断向量(仅用bit0)

// ---- RX Buffer接口 (rx_engine → rchn_arbiter的RAM) ----
wire                                rmem_wr;        // RAM写使能(user_clk域)
wire    [7:0]                       rmem_waddr;     // RAM写地址(由Tag+offset编码)
wire    [511:0]                     rmem_wdata;     // RAM写数据(两个256bit RC包拼接成512bit)

// ---- 读通道FIFO状态 (rchn_couple → rchn_arbiter/CIB) ----
wire    [RCHN_NUM-1:0]              rfifo_empty;     // 各通道RFIFO为空
wire    [RCHN_NUM-1:0]              rfifo_prog_full; // 各通道RFIFO将满(反压rchn_arbiter)
wire    [RCHN_NUM-1:0]              rfifo_wr;        // 各通道RFIFO写使能
wire    [RDATA_WIDTH-1:0]           rfifo_wr_data;   // RFIFO写数据(所有通道共享此数据线)

// ---- 全局控制信号 ----
wire                                txfifo_abnormal_rst; // TX FIFO异常复位(WIB/WDB不同步超时→自动复位)
wire                                soft_rst;       // 软复位(CIB寄存器可控)
wire                                sys_rst_n_x;    // 组合复位 = sys_rst_n & ~soft_rst & ~user_reset

// ---- 写通道 couple_logic ↔ wchn_arbiter 互联 ----
wire    [WPHY_NUM-1:0]              wchn_eflg;      // 数据包结束标志(couple→arbiter)
wire    [WPHY_NUM-1:0]              wchn_eflg_clr;  // 清除结束标志(arbiter→couple)
wire    [WPHY_NUM-1:0]              cfifo_overflow;  // couple内部FIFO溢出
wire    [WPHY_NUM-1:0]              cfifo_empty;     // couple内部FIFO为空

// ---- 带宽统计 ----
wire    [31:0]                      band;           // 上行带宽(KB/s)
wire    [31:0]                      rx_band;        // 下行带宽(KB/s)

// ---- 中断控制 ----
wire                                wdma_int_dis;   // 写DMA中断禁止(CIB寄存器控制)
wire                                rdma_int_dis;   // 读DMA中断禁止

// ---- 写DMA 描述符参数 (CIB → wchn_arbiter) ----
//   CIB通过pcie_item管理每个通道的DMA描述符, 输出使能/地址/长度/保留字
wire    [WCHN_NUM-1:0]              wchn_dma_en;     // 各通道DMA使能(上升沿启动)
wire    [32*WCHN_NUM-1:0]           wchn_dma_addr;   // 各通道PCIe目标地址(低32bit) ×32
wire    [32*WCHN_NUM-1:0]           wchn_dma_addr_h; // 各通道PCIe目标地址(高32bit) ×32
wire    [24*WCHN_NUM-1:0]           wchn_dma_len;    // 各通道DMA长度(单位:TLP大小) ×32
wire    [64*WCHN_NUM-1:0]           wchn_dma_rev;    // 各通道保留字段 ×32
wire                                wchn_len_done;   // 某通道DMA长度消耗完(arbiter→CIB)
wire    [WCHN_NUM_W-1:0]            wchn_len_chn;    // 完成的通道编号
wire                                wdma_stop;       // 写DMA停止命令(CIB→arbiter)

// ---- 写DMA 完成反馈 (tx_engine → CIB) ----
wire                                wchn_dma_done;   // 某通道DMA传输完成
wire                                wchn_dma_end;    // 推测为数据包结束标志
wire    [WCHN_NUM_W-1:0]            wchn_dma_chn;    // 完成的通道编号
wire    [23:0]                      wchn_dma_count;  // 已传输的TLP计数
wire    [31:0]                      wchn_dma_daddr;  // 当前DMA目标地址(低)
wire    [31:0]                      wchn_dma_daddr_h;// 当前DMA目标地址(高)
wire    [63:0]                      wchn_dma_drev;   // 描述符保留字段

// ---- 读DMA 描述符参数 (CIB → rchn_arbiter) ----
wire    [RCHN_NUM-1:0]              rchn_dma_en;     // 各通道DMA使能 ×9
wire    [32*RCHN_NUM-1:0]           rchn_dma_addr;   // 各通道PCIe源地址(低32bit) ×9
wire    [32*RCHN_NUM-1:0]           rchn_dma_addr_h; // 各通道PCIe源地址(高32bit) ×9
wire    [24*RCHN_NUM-1:0]           rchn_dma_len;    // 各通道DMA长度 ×9
wire    [64*RCHN_NUM-1:0]           rchn_dma_rev;    // 各通道保留字段 ×9
wire                                rdma_stop;       // 读DMA停止命令

// ---- 读DMA 完成反馈 (tx_engine → CIB) ----
wire                                rchn_dma_done;   // 某通道读DMA完成
wire    [RCHN_NUM_W-1:0]            rchn_dma_chn;    // 完成的通道编号
wire    [31:0]                      rchn_dma_daddr;  // 当前DMA地址(低)
wire    [31:0]                      rchn_dma_daddr_h;// 当前DMA地址(高)
wire    [63:0]                      rchn_dma_drev;   // 描述符保留字段

// ---- TLP 大小参数 (CIB → arbiter/tx_engine) ----
wire    [9:0]                       wdma_tlp_size;   // 写TLP大小(128/256字节)
wire    [9:0]                       rdma_tlp_size;   // 读TLP大小(128/256字节)

// ---- 读通道调试信号 ----
wire                                rchn_st;         // 读DMA整体启动信号
wire    [32*RCHN_NUM-1:0]           rchn_cnt;        // 各通道接收字节计数(调试用)
wire    [32*RCHN_NUM-1:0]           rchn_cnt_h;      // 各通道接收字节计数高位
wire    [RCHN_NUM-1:0]              rchn_terr;       // 各通道数据校验错误
wire    [RCHN_NUM-1:0]              rfifo_overflow;  // 各通道RFIFO溢出
wire    [RCHN_NUM-1:0]              rfifo_underflow; // 各通道RFIFO欠流
wire    [1:0]                       t_rchn_cur_st;   // 读仲裁器状态机(0=ABT,1=RECORD,2=DONE)
wire                                trabt_err;       // MWr和MRd同时活跃(不应发生)
wire                                wchnindex_err;   // 写通道索引越界
wire    [WCHN_NUM_W-1:0]            wchn_curr_index; // 当前服务的写通道号

// ---- RX 错误检测 (rx_engine → CIB) ----
wire                                rc_is_err;    // Completion TLP状态字段指示错误
wire                                rc_is_fail;   // Completion TLP指示请求失败

// ---- Tag 管理 (rx_engine → rchn_arbiter) ----
wire                                tag_release;  // 所有Tag的Completion都已收到→可开始下一批

// ---- RIB FIFO互联 (rchn_arbiter → RIB FIFO → tx_engine) ----
//   传递读请求信息: {地址高, 地址低, 保留字, done, tag, 通道号, tlp_size, pcie地址}
wire                                rib_wen;      // RIB FIFO写使能(sys_clk域的rchn_arbiter写入)
wire    [191:0]                     rib_din;      // RIB FIFO写数据(192bit MRd请求描述)
wire                                rib_prog_full;// RIB FIFO将满(反压rchn_arbiter)

// ---- WDB FIFO互联 (wchn_arbiter → WDB FIFO → tx_engine) ----
//   传递上行数据负载: 512bit原始数据
wire                                wdb_full;     // WDB FIFO满
wire                                wdb_prog_full;// WDB FIFO将满(反压wchn_arbiter)
wire                                wdb_wen;      // WDB写使能
wire    [512-1:0]                   wdb_din;      // WDB写数据(512bit)

// ---- WIB FIFO互联 (wchn_arbiter → WIB FIFO → tx_engine) ----
//   传递上行TLP信息: {通道号, 目标地址, 长度, done, end, tlp实际大小, 保留字, pcie地址}
wire                                wib_full;     // WIB FIFO满
wire                                wib_prog_full;// WIB FIFO将满
wire                                wib_wen;      // WIB写使能
wire    [255:0]                     wib_din;      // WIB写数据(256bit)

// ---- FIFO读侧信号 (tx_engine ← 三个FIFO) ----
wire                                wib_empty;    // WIB为空(tx_engine检查)
wire                                wib_ren;      // WIB读使能(tx_engine驱动)
wire    [255:0]                     wib_dout;     // WIB读数据
wire                                rib_empty;    // RIB为空
wire                                rib_ren;      // RIB读使能
wire    [191:0]                     rib_dout;     // RIB读数据
wire                                wdb_empty;    // WDB为空
wire                                wdb_ren;      // WDB读使能
wire    [512-1:0]                   wdb_dout;     // WDB读数据

// ---- couple_logic ↔ wchn_arbiter 数据通路 ----
wire    [WPHY_NUM-1:0]              wchn_ren;     // couple FIFO读使能(arbiter→couple)
wire    [WPHY_NUM-1:0]              wchn_dvld;    // couple FIFO有数据(couple→arbiter)
wire    [WPHY_NUM*(528+WCHN_NUM_W)-1:0] wchn_dout; // couple FIFO读数据
                                                   // 格式={通道号[WCHN_NUM_W], 长度[15], 结束[1], 数据[512]}

// ---- 内建自测试控制信号 (CIB → datas_builtin_top) ----
wire    [WPHY_NUM-1:0]              built_in;     // 内建测试使能(1=使用测试数据)
wire    [WPHY_NUM*512-1:0]          ds_rx_data;   // 测试数据
wire    [WPHY_NUM-1:0]              ds_rx_data_vld; // 测试数据有效

// ---- FIFO异常检测 (各模块 → CIB) ----
wire                                wdb_overflow;  // WDB FIFO溢出
wire                                wib_overflow;  // WIB FIFO溢出
wire                                wdb_underflow; // WDB FIFO欠流(tx_engine读空)
wire    [1:0]                       t_wchn_cur_st; // 写仲裁器状态机(0=ABT,1=READ,2=WAIT)

// ---- 内建自测试参数 (CIB → datas_builtin_top) ----
wire    [22-1:0]                    ds_tbucket_width;    // 令牌桶宽度(控速)
wire    [22-1:0]                    ds_tbucket_deepth;   // 令牌桶深度
wire    [3-1:0]                     ds_data_mode;        // 数据模式: 0=递增8bit, 1=PRBS31, ...
wire    [63:0]                      ds_static_pattern;   // 静态模式的固定数据
wire    [1-1:0]                     ds_tx_len_start;     // 定长模式启动
wire    [1-1:0]                     ds_tx_con_start;     // 连续模式启动
wire    [1*32-1:0]                  ds_len_mode_count;   // 定长模式的传输长度
wire    [1-1:0]                     check_st;            // 数据校验启动

// ========================================================================================
// 【顶层连线 — 复位与链路状态】
//   pcie_link: 外部可读的PCIe链路状态
//   sys_rst_n_x: 三合一复位, 任一触发都会复位全部逻辑
// ========================================================================================
assign pcie_link = user_lnk_up;                        // 链路指示直接输出
assign user_rst_n =  ~user_reset;                       // user_clk域复位取反(IP输出高有效→转低有效)
assign sys_rst_n_x = (sys_rst_n) & (~soft_rst) &( ~user_reset); // 组合复位



// ========================================================================================
// 【子模块1: couple_logic — 上行数据耦合模块】
//   功能: 接收用户上行数据, 通过异步FIFO完成 wchn_clk→sys_clk 的跨时钟域传输
//   数据流: wchn_data → [内部FIFO] → wchn_dout → wchn_arbiter
//   说明: generate循环, 为每个物理通道实例化一个couple_logic + datas_builtin_top
//         WPHY_NUM=1时只有1个实例
// ========================================================================================
genvar i;
generate 
for(i=0;i<WPHY_NUM;i=i+1)
begin   
couple_logic # (
    .WCHN_NUM_W                 (WCHN_NUM_W                 ),  // 通道编号位宽
    .WDATA_WIDTH                (WDATA_WIDTH                ),  // 数据位宽512bit
    .BUILTIN_NUM                (i                          ),  // 内建测试通道号
    .BURST_LEN                  (BURST_LEN                  ),  // 突发长度2048B
    .U_DLY                      (U_DLY                      )
)u_couple_logic
(
    .wr_clk                     (wchn_clk[i]                ),
    .wr_rst_n                   (sys_rst_n_x & wchn_rst_n[i]),
    
    .rd_clk                     (sys_clk                    ),
    .rd_rst_n                   (sys_rst_n_x & wchn_rst_n[i]),
    .built_in                   (built_in[i]                ),
    .ds_rx_data_vld             (ds_rx_data_vld[i]          ),
    .ds_rx_data                 (ds_rx_data[512*i+:512]     ),
    
    .wchn_data_rdy              (wchn_data_rdy[i]           ),
    .wchn_data_vld              (wchn_data_vld[i]           ),
    .wchn_sof                   (wchn_sof[i]                ),
    .wchn_eof                   (wchn_eof[i]                ),
    .wchn_data                  (wchn_data[WDATA_WIDTH*i+:WDATA_WIDTH]),
    .wchn_end                   (wchn_end[i]                ),
    .wchn_keep                  (wchn_keep[(WDATA_WIDTH/8)*i+:(WDATA_WIDTH/8)]),
    .wchn_length                (wchn_length[15*i+:15]      ),
    .wchn_chn                   (wchn_chn[WCHN_NUM_W*i+:WCHN_NUM_W]),
 
    .wchn_eflg                  (wchn_eflg[i]               ),
    .wchn_eflg_clr              (wchn_eflg_clr[i]           ),
    .wchn_ren                   (wchn_ren[i]                ),
    .wchn_dvld                  (wchn_dvld[i]               ),
    .wchn_dout                  (wchn_dout[(528+WCHN_NUM_W)*i+:(528+WCHN_NUM_W)]),
    .cfifo_overflow             (cfifo_overflow[i]             ),
    .cfifo_empty                (cfifo_empty[i]                )
);



datas_builtin_top # (
    .U_DLY                      (U_DLY                      ),
    .TBUCKET_DEEPTH             ('d8000                     )
)u_datas_builtin_top
(
    .clk                        (wchn_clk[i]                ),   
    .rst_n                      (sys_rst_n_x & wchn_rst_n[i]),   
    .chk_clk                    (wchn_clk[i]                ),   
    .chk_rst_n                  (sys_rst_n_x & wchn_rst_n[i]),   
    .rtc_us_flg                 (rtc_us_flg                 ),
//                                                                
    .ds_tbucket_deepth          (ds_tbucket_deepth          ),
    .ds_tbucket_width           (ds_tbucket_width           ),

    .ds_data_mode               (ds_data_mode               ),
    .ds_static_pattern          (ds_static_pattern          ),
    .ds_tx_len_start            (ds_tx_len_start            ),
    .ds_tx_con_start            (ds_tx_con_start            ),
    .ds_len_mode_count          (ds_len_mode_count          ),

    .check_st                   (check_st                   ),
    .file_len                   (                           ),
    .err_num_8bit               (                           ),
    .err_len_8bit               (                           ),
    .err_num_prbs31             (                           ),
    .err_len_prbs31             (                           ),
    .err_num_128bit             (                           ),
    .err_len_128bit             (                           ),
    .errcontext_8bit_wr         (                           ),
    .errcontext_8bit_wr_addr    (                           ),
    .errcontext_8bit_wr_data    (                           ),
    .errcontext_prbs31_wr       (                           ),
    .errcontext_prbs31_wr_addr  (                           ),
    .errcontext_prbs31_wr_data  (                           ),
    .errcontext_128bit_wr       (                           ),
    .errcontext_128bit_wr_addr  (                           ),
    .errcontext_128bit_wr_data  (                           ),

    .full                       (~wchn_data_rdy[i]          ),
    .ds_rx_data                 (ds_rx_data[512*i+:512]     ),
    .ds_rx_keep                 (                           ),
    .ds_rx_data_vld             (ds_rx_data_vld[i]          ),
    .ds_rx_last                 (                           ),

    .ds_tx_tdata                (512'b0                     ),
    .ds_tx_tkeep                (64'b0                      ),
    .ds_tx_tvalid               (1'b0                       ),
    .ds_tx_tlast                (1'b0                       ),
    .ds_tx_tready               (                           ),
    .ds_send_done               (                           )

);
end
endgenerate
 
// ========================================================================================
// 【子模块3: bandcount — 带宽统计】
//   上行: 统计 wdb_wen(WDB FIFO写入)的速率, 即实际送入PCIe的数据量, 单位KB/s
//   下行: 统计 |rfifo_wr(任意通道RFIFO写入)的速率
//   原理: 每秒(rtc_s_flg边沿)锁存计数值
// ========================================================================================
bandcount # (
    .U_DLY                      (U_DLY                      ),
    .DATAW                      (WDATA_WIDTH                )  // 512bit, 每拍64Byte
)u_bandcount(
    .clk                        (sys_clk                    ),
    .rst_n                      (sys_rst_n_x                ),
    .rtc_s_flg                  (rtc_s_flg                  ),  // 1秒标志
    .valid                      (wdb_wen                    ),  // ★上行有效=WDB FIFO写入
    .band                       (band                       )   // 输出: 上行带宽(KB/s)
);

bandcount # (
    .U_DLY                      (U_DLY                      ),
    .DATAW                      (RDATA_WIDTH                )
)u_bandcount_rx(
    .clk                        (sys_clk                    ),
    .rst_n                      (sys_rst_n_x                ),
    .rtc_s_flg                  (rtc_s_flg                  ),
    .valid                      (|rfifo_wr                  ),  // ★下行有效=任一通道RFIFO写入
    .band                       (rx_band                    )   // 输出: 下行带宽(KB/s)
);

// ========================================================================================
// 【子模块4: pcie_rchn_couple — 下行数据输出模块】
//   功能: 每个读通道一个实例, 将sys_clk域的读回数据通过异步FIFO转到用户时钟域
//         状态机攒够RBURST_LEN字节后输出一帧(SOF+DATA+EOF)
//   数据流: rchn_arbiter → rfifo_wr → [异步FIFO] → rchn_data/vld/sof/eof → 用户
//   共 RCHN_NUM=9 个实例
// ========================================================================================
genvar j;
generate 
for(j=0;j<RCHN_NUM;j=j+1)
begin
pcie_rchn_couple #(
    .U_DLY                      (U_DLY                      ),
    .RDATA_WIDTH                (RDATA_WIDTH                ),  // 512bit
    .RBURST_LEN                 (RBURST_LEN                 )   // 2048B/帧
)u_pcie_rchn_couple
(
    .sys_clk                    (sys_clk                    ),  // FIFO写侧时钟
    .sys_rst_n                  (sys_rst_n_x & rchn_rst_n[j]),  // 组合复位

    .rd_clk                     (rchn_clk[j]                ),  // FIFO读侧=用户时钟
    .rd_rst_n                   (sys_rst_n_x & rchn_rst_n[j]),
    
    .rchn_st                    (rchn_st                    ),  // 读DMA整体启动(复位计数器)
    .rchn_cnt                   (rchn_cnt[32*j+:32]         ),  // 本通道接收字节计数
    .rchn_cnt_h                 (rchn_cnt_h[32*j+:32]       ),  // 字节计数高位
    .rchn_terr                  (rchn_terr[j]               ),  // 数据校验错误标志
    
    // ---- 系统侧FIFO接口(rchn_arbiter写入) ----
    .rfifo_empty                (rfifo_empty[j]             ),  // FIFO空(状态输出)
    .rfifo_prog_full            (rfifo_prog_full[j]         ),  // FIFO将满(反压)
    .rfifo_wr                   (rfifo_wr[j]                ),  // 写使能(arbiter驱动)
    .rfifo_wr_data              (rfifo_wr_data              ),  // 写数据(所有通道共享)

    // ---- 用户侧帧接口(ready/valid握手) ----
    .rchn_data_rdy              (rchn_data_rdy[j]           ),  // 用户就绪
    .rchn_data_vld              (rchn_data_vld[j]           ),  // 数据有效
    .rchn_sof                   (rchn_sof[j]                ),  // 帧起始
    .rchn_eof                   (rchn_eof[j]                ),  // 帧结束
    .rchn_data                  (rchn_data[(RDATA_WIDTH)*j+:RDATA_WIDTH]      ),
    .rchn_keep                  (rchn_keep[(RDATA_WIDTH/8)*j +: (RDATA_WIDTH/8)]),
    .rchn_length                (rchn_length[15*j+:15]      ),
    
    .rfifo_overflow             (rfifo_overflow[j]          ),  // 溢出指示
    .rfifo_underflow            (rfifo_underflow[j]         )   // 欠流指示
   
    
);
end
endgenerate
// ========================================================================================
// 【子模块5: pcie_cib — 中央控制接口块】
//   功能: 系统的"大脑", 管理DMA描述符、配置寄存器、状态监控
//   接口: 上游=CIB总线(pcie_cs/wr/rd), 下游=所有仲裁器和引擎
//   内含: pcie_witem_glb(写描述符管理) + pcie_ritem_glb(读描述符管理)
//         + pcie_item ×(WCHN_NUM+RCHN_NUM) 个描述符实例
//   时钟域: sys_clk
// ========================================================================================

pcie_cib #(
    .U_DLY                      (U_DLY                      ),
    .WCHN_NUM                   (WCHN_NUM                   ),
    .WCHN_NUM_W                 (WCHN_NUM_W                 ),
    .RCHN_NUM                   (RCHN_NUM                   ),
    .RCHN_NUM_W                 (RCHN_NUM_W                 ),
    .WPHY_NUM                   (WPHY_NUM                   ),
    .WPHY_NUM_W                 (WPHY_NUM_W                 )
)u_pcie_cib
(
    .clk                        (sys_clk                    ),
    .rst_n                      (~user_reset                ),

    .cpu_cs                     (pcie_cs                    ),
    .cpu_wr                     (pcie_wr                    ),
    .cpu_rd                     (pcie_rd                    ),
    .cpu_addr                   (pcie_addr                  ),
    .cpu_wr_data                (pcie_wr_data               ),
    .cpu_rd_data                (pcie_rd_data               ),

    .band                       (band                       ),
    .rx_band                    (rx_band                    ),
    .wdma_int_dis               (wdma_int_dis               ),
    .rdma_int_dis               (rdma_int_dis               ),
    .rtc_us_flg                 (rtc_us_flg                 ),
    //WDMA
    .wchn_dma_addr              (wchn_dma_addr              ),
    .wchn_dma_addr_h            (wchn_dma_addr_h            ),
    .wchn_dma_en                (wchn_dma_en                ),
    .wchn_dma_len               (wchn_dma_len               ),
    .wchn_dma_rev               (wchn_dma_rev               ),
    .wchn_len_done              (wchn_len_done              ),
    .wchn_len_chn               (wchn_len_chn               ),
    .wdma_stop                  (wdma_stop                  ),

    .wchn_dma_done              (wchn_dma_done              ),
    .wchn_dma_end               (wchn_dma_end               ),
    .wchn_dma_chn               (wchn_dma_chn               ),
    .wchn_dma_count             (wchn_dma_count             ),
    .wchn_dma_daddr             (wchn_dma_daddr             ),
    .wchn_dma_drev              (wchn_dma_drev              ),
    .wchn_dma_daddr_h           (wchn_dma_daddr_h           ),
   
    //RDMA
    .rchn_dma_en                (rchn_dma_en                ),
    .rchn_dma_addr              (rchn_dma_addr              ),
    .rchn_dma_len               (rchn_dma_len               ),
    .rchn_dma_rev               (rchn_dma_rev               ),
    .rdma_stop                  (rdma_stop                  ),
    .rchn_dma_addr_h            (rchn_dma_addr_h            ),

    .rchn_dma_done              (rchn_dma_done              ),
    .rchn_dma_chn               (rchn_dma_chn               ),
    .rchn_dma_daddr             (rchn_dma_daddr             ),
    .rchn_dma_drev              (rchn_dma_drev              ),
    .rchn_dma_daddr_h           (rchn_dma_daddr_h           ),

    .wdma_tlp_size              (wdma_tlp_size              ),
    .rdma_tlp_size              (rdma_tlp_size              ),

    .cfg_negotiated_width       (cfg_negotiated_width       ),
    .cfg_current_speed          (cfg_current_speed          ),
    .cfg_max_payload            (cfg_max_payload            ),
    .cfg_max_read_req           (cfg_max_read_req           ),


    .built_in                   (built_in                   ),
    .ds_tbucket_width           (ds_tbucket_width           ),
    .ds_tbucket_deepth          (ds_tbucket_deepth          ),
    .ds_data_mode               (ds_data_mode               ),
    .ds_static_pattern          (ds_static_pattern          ),
    .ds_tx_len_start            (ds_tx_len_start            ),
    .ds_tx_con_start            (ds_tx_con_start            ),
    .ds_len_mode_count          (ds_len_mode_count          ),
    .check_st                   (check_st                   ), 
    .soft_rst                   (soft_rst                   ),

    .wdb_overflow               (wdb_overflow               ),
    .wib_overflow               (wib_overflow               ),
    .wdb_underflow              (wdb_underflow              ),
    .cfifo_overflow             ({ {(8-WPHY_NUM){1'b0}},cfifo_overflow}             ),
    .cfifo_empty                ({ {(8-WPHY_NUM){1'b1}},cfifo_empty}                ),
    .wchn_dvld                  ({ {(8-WPHY_NUM){1'b0}},wchn_dvld}                  ),
    .t_wchn_cur_st              (t_wchn_cur_st              ), 
    .wchnindex_err              (wchnindex_err              ),
    .wchn_curr_index            (wchn_curr_index            ),
    .wib_empty                  (wib_empty                  ),
    .wdb_empty                  (wdb_empty                  ),
    .rib_empty                  (rib_empty                  ),

    .err_type_l                 (err_type_l                 ),
    .err_bar_l                  (err_bar_l                  ),
    .err_len_l                  (err_len_l                  ),
    .rc_is_err                  (rc_is_err                  ),
    .rc_is_fail                 (rc_is_fail                 ),
    
    .rfifo_empty                (rfifo_empty                ),
    .txfifo_abnormal_rst        (txfifo_abnormal_rst        ),
    
    .rchn_st                    (rchn_st                    ),
    .rchn_cnt                   (rchn_cnt[31:0]             ),
    .rchn_cnt_h                 (rchn_cnt_h[31:0]           ), 
    .rchn_terr                  (rchn_terr                  ),
    
    .rfifo_overflow             (rfifo_overflow             ),
    .rfifo_underflow            (rfifo_underflow            ),
    
    .t_rchn_cur_st              (t_rchn_cur_st              ),
    .trabt_err                  (trabt_err                  )

);

// ========================================================================================  
// 【子模块6: pcie_regif_gen3 — BAR0 寄存器接口】
//   功能: 解析PC通过BAR0发来的CQ TLP(寄存器读写请求)
//         写操作: 解析地址+数据 → local_bus → 各模块
//         读操作: 解析地址 → local_bus → 读数据 → CC TLP → 返回PC
//   时钟域: user_clk (直接接PCIe IP的AXI-Stream)
// ========================================================================================  
pcie_regif_gen3 #(
    .U_DLY                      (U_DLY                      )
)u_pcie_regif_gen3
(
    .clk                        (user_clk                   ),
    .rst_n                      (~user_reset                ),
    .m_axis_cq_tdata            (m_axis_cq_tdata            ),
    .m_axis_cq_tuser            (m_axis_cq_tuser            ),
    .m_axis_cq_tlast            (m_axis_cq_tlast            ),
    .m_axis_cq_tkeep            (m_axis_cq_tkeep            ),
    .m_axis_cq_tvalid           (m_axis_cq_tvalid           ),
    .m_axis_cq_tready           (m_axis_cq_tready           ),

    .s_axis_cc_tdata            (s_axis_cc_tdata            ),
    .s_axis_cc_tuser            (s_axis_cc_tuser            ),
    .s_axis_cc_tlast            (s_axis_cc_tlast            ),
    .s_axis_cc_tkeep            (s_axis_cc_tkeep            ),
    .s_axis_cc_tvalid           (s_axis_cc_tvalid           ),
    .s_axis_cc_tready           (s_axis_cc_tready[0]        ),

    .r_wr_en                    (r_wr_en                    ),
    .r_addr                     (r_addr                     ),
    .r_wr_data                  (r_wr_data                  ),
    .r_rd_en                    (r_rd_en                    ),
    .r_rd_data                  (r_rd_data                  ),

    .err_type_l                 (err_type_l                 ),
    .err_bar_l                  (err_bar_l                  ),
    .err_len_l                  (err_len_l                  )  
    
);                                                               
// ========================================================================================
// 【子模块7: pcie_rx_engine_gen3 — RX Completion 接收引擎】
//   功能: 解析PC返回的Completion TLP(MRd请求的数据返回)
//         将256bit RC数据拼接为512bit, 按Tag计算地址写入RAM Buffer
//         管理Tag位图, 全部Tag完成后发出tag_release
//   时钟域: user_clk
//   数据流: m_axis_rc → 解析Header → 拼接512bit → rmem_wr/waddr/wdata → rchn_arbiter内RAM
// ========================================================================================
pcie_rx_engine_gen3 # (
    .U_DLY                      (U_DLY                      ),
    .RTAG_NUM                   (RTAG_NUM                   )
)u_pcie_rx_engine_gen3
(
    .clk                        (user_clk                   ),
    .rst_n                      (sys_rst_n_x                ),
    .cfg_max_payload            (cfg_max_payload            ),
    .rchn_st                    (rchn_st                    ),
//  Requester Completion Package
    .m_axis_rc_tdata            (m_axis_rc_tdata            ),
    .m_axis_rc_tuser            (m_axis_rc_tuser            ),
    .m_axis_rc_tlast            (m_axis_rc_tlast            ),
    .m_axis_rc_tkeep            (m_axis_rc_tkeep            ),
    .m_axis_rc_tvalid           (m_axis_rc_tvalid           ),
    .m_axis_rc_tready           (m_axis_rc_tready           ),
//
    .tag_release                (tag_release                ),
//  RX Buffer
    .rmem_wr                    (rmem_wr                    ),
    .rmem_waddr                 (rmem_waddr                 ),
    .rmem_wdata                 (rmem_wdata                 ),
//  Debug Interface
    .rc_is_err                  (rc_is_err                  ),
    .rc_is_fail                 (rc_is_fail                 )
    
);

// ========================================================================================
// 【子模块8: pcie_rchn_arbiter — 读通道仲裁器】
//   功能: 管理9个读通道的DMA请求, 生成MRd请求信息写入RIB FIFO
//         使用双缓冲(buf_state[0:1])实现请求发送和数据接收的流水化
//         收到rx_engine写入的数据后, 分发到对应通道的RFIFO
//   状态机: RCHN_ABT(仲裁) → RCHN_RECORD(发请求) → RCHN_DONE(等Tag释放)
//   时钟域: sys_clk (FIFO写侧), user_clk (RAM写侧, 连接rx_engine)
// ========================================================================================
pcie_rchn_arbiter#(
    .RCHN_NUM                   (RCHN_NUM                   ),
    .RCHN_NUM_W                 (RCHN_NUM_W                 ),
    .RTAG_NUM                   (RTAG_NUM                   ), 
    .RDATA_WIDTH                (RDATA_WIDTH                ),
    .U_DLY                      (U_DLY                      )
)u_pcie_rchn_arbiter
(
    .clk                        (sys_clk                    ),
    .rst_n                      (sys_rst_n_x                ),
    .rdma_tlp_size              (rdma_tlp_size              ),
    .rdma_stop                  (rdma_stop                  ),

    .tag_release                (tag_release                ),

    .rchn_dma_addr              (rchn_dma_addr[RCHN_NUM*32-1:0]     ),
    .rchn_dma_en                (rchn_dma_en[RCHN_NUM-1:0]          ),
    .rchn_dma_len               (rchn_dma_len[RCHN_NUM*24-1:0]      ),
    .rchn_dma_rev               (rchn_dma_rev[RCHN_NUM*64-1:0]      ),    
    .rchn_dma_addr_h            (rchn_dma_addr_h[RCHN_NUM*32-1:0]   ),

    .rib_wen                    (rib_wen                    ),
    .rib_din                    (rib_din                    ),
    .rib_prog_full              (rib_prog_full              ),

    .wr_clk                     (user_clk                   ), 
    .rmem_wr                    (rmem_wr                    ), 
    .rmem_waddr                 (rmem_waddr                 ), 
    .rmem_wdata                 (rmem_wdata                 ), 

    .rfifo_prog_full            (rfifo_prog_full            ),
    .rfifo_wr                   (rfifo_wr                   ),
    .rfifo_wr_data              (rfifo_wr_data              ),
    .t_rchn_cur_st              (t_rchn_cur_st              )
    


);



// ========================================================================================
// 【FIFO 1: u_rib_fifo — 读信息FIFO (Read Info Buffer)】
//   功能: 传递MRd请求描述信息, 从sys_clk域的rchn_arbiter到user_clk域的tx_engine
//   数据: 192bit = {目标地址高, 目标地址低, 保留字, done, tag, 通道号, tlp_size, pcie地址}
//   深度: 64条目, prog_full阈值=32
// ========================================================================================
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (192                        ),
    .DATA_DEEPTH                (64                         ),
    .ADDR_WIDTH                 (6                          )
)u_rib_fifo
(
    .wr_clk                     (sys_clk                    ),
    .wr_rst_n                   (sys_rst_n_x                ),
    .rd_clk                     (user_clk                   ),
    .rd_rst_n                   (sys_rst_n_x                ),
    .din                        (rib_din                    ),
    .wr_en                      (rib_wen                    ),
    .rd_en                      (rib_ren                    ),
    .dout                       (rib_dout                   ),
    .full                       (                           ),
    .prog_full                  (rib_prog_full              ),
    .empty                      (rib_empty                  ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (6'd32                      ),
    .prog_empty_thresh          (6'd2                       ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )

);


// ========================================================================================
// 【子模块9: pcie_wchn_arbiter — 写通道仲裁器】
//   功能: 轮询WPHY_NUM个物理通道的couple_logic FIFO
//         从中读取用户上行数据, 按TLP大小分片, 写入WDB(数据)和WIB(信息)
//   状态机: WCHN_ABT(仲裁) → WCHN_READ(读数据+分片) → WCHN_WAIT(等清理)
//   时钟域: sys_clk
// ========================================================================================
pcie_wchn_arbiter#(
    .WCHN_NUM                   (WCHN_NUM                   ),
    .WCHN_NUM_W                 (WCHN_NUM_W                 ),
    .WPHY_NUM                   (WPHY_NUM                   ),
    .WPHY_NUM_W                 (WPHY_NUM_W                 ),
    .BURST_LEN                  (BURST_LEN                  ),
    .U_DLY                      (U_DLY                      )
)u_pcie_wchn_arbiter
(
    .clk                        (sys_clk                    ),
    .rst_n                      (sys_rst_n_x                ),
    .wdma_tlp_size              (wdma_tlp_size              ),
    .wdma_stop                  (wdma_stop                  ),

    .wchn_eflg                  (wchn_eflg                  ),
    .wchn_eflg_clr              (wchn_eflg_clr              ),
    .wchn_dvld                  (wchn_dvld                  ),
    .wchn_ren                   (wchn_ren                   ),
    .wchn_dout                  (wchn_dout                  ),

    .wchn_dma_addr              (wchn_dma_addr[WCHN_NUM*32-1:0]     ),
    .wchn_dma_addr_h            (wchn_dma_addr_h[WCHN_NUM*32-1:0]   ),
    .wchn_dma_en                (wchn_dma_en[WCHN_NUM-1:0]          ),
    .wchn_dma_len               (wchn_dma_len[WCHN_NUM*24-1:0]      ),
    .wchn_dma_rev               (wchn_dma_rev[WCHN_NUM*64-1:0]      ),
    .wchn_len_done              (wchn_len_done              ),
    .wchn_len_chn               (wchn_len_chn               ),

    
    //wchn_data_fifo
    .wdb_full                   (wdb_full                   ),
    .wdb_prog_full              (wdb_prog_full              ),
    .wdb_wen                    (wdb_wen                    ),
    .wdb_din                    (wdb_din                    ),
    //wchn_info_fifo
    .wib_full                   (wib_full                   ),   
    .wib_prog_full              (wib_prog_full              ), 
    .wib_wen                    (wib_wen                    ),
    .wib_din                    (wib_din                    ),
    
    .wdb_overflow               (wdb_overflow               ),
    .wib_overflow               (wib_overflow               ),
    .t_wchn_cur_st              (t_wchn_cur_st              ),
    .wchnindex_err              (wchnindex_err              ),
    .wchn_curr_index            (wchn_curr_index            )

);

// ========================================================================================
// 【FIFO 2: u_wib_fifo — 写信息FIFO (Write Info Buffer)】
//   功能: 传递MWr TLP描述信息, 从sys_clk域的wchn_arbiter到user_clk域的tx_engine
//   数据: 256bit = {通道号, 地址高, rd_end, done, tlp大小, 地址低, 累计长度, 保留字, pcie地址}
//   深度: 128条目, prog_full阈值=64
//   复位: sys_rst_n_x & ~txfifo_abnormal_rst (异常时强制复位)
// ========================================================================================
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (256                        ),
    .DATA_DEEPTH                (128                        ),
    .ADDR_WIDTH                 (7                          )
)u_wib_fifo
(
    .wr_clk                     (sys_clk                    ),
    .wr_rst_n                   (sys_rst_n_x&(~txfifo_abnormal_rst)),
    .rd_clk                     (user_clk                   ),
    .rd_rst_n                   (sys_rst_n_x&(~txfifo_abnormal_rst)),
    .din                        (wib_din                    ),
    .wr_en                      (wib_wen                    ),
    .rd_en                      (wib_ren                    ),
    .dout                       (wib_dout                   ),
    .full                       (wib_full                   ),
    .prog_full                  (wib_prog_full              ),
    .empty                      (wib_empty                  ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (7'd64                      ),
    .prog_empty_thresh          (7'd4                       ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )
);

// ========================================================================================
// 【FIFO 3: u_wdb_fifo — 写数据FIFO (Write Data Buffer)】
//   功能: 缓存上行DMA数据负载, 从sys_clk域到user_clk域
//   数据: 512bit 纯数据负载
//   深度: 512条目 × 512bit = 32KB 缓冲
//   复位: sys_rst_n_x & ~txfifo_abnormal_rst (与WIB同步复位, 保持一致性)
// ========================================================================================
asyn_fifo # (
    .U_DLY                      (U_DLY                      ),
    .DATA_WIDTH                 (512                        ),
    .DATA_DEEPTH                (512                        ),
    .ADDR_WIDTH                 (9                          )
)u_wdb_fifo
(
    .wr_clk                     (sys_clk                    ),
    .wr_rst_n                   ((sys_rst_n_x)&(~txfifo_abnormal_rst)),
    .rd_clk                     (user_clk                   ),
    .rd_rst_n                   ((sys_rst_n_x)&(~txfifo_abnormal_rst)),
    .din                        (wdb_din                    ),
    .wr_en                      (wdb_wen                    ),
    .rd_en                      (wdb_ren                    ),
    .dout                       (wdb_dout                   ),
    .full                       (wdb_full                   ),
    .prog_full                  (wdb_prog_full              ),
    .empty                      (wdb_empty                  ),
    .prog_empty                 (                           ),
    .prog_full_thresh           (9'd128                     ),
    .prog_empty_thresh          (9'd4                       ),
    .rd_data_count              (/* NOT USED */             ),
    .wr_data_count              (/* NOT USED */             )

);

// ========================================================================================
// 【子模块10: pcie_tx_engine_gen3 — TX TLP 发送引擎】
//   功能: 从 WIB/WDB/RIB 三个FIFO读取数据和信息, 组装PCIe TLP包
//         支持两种TLP类型:
//           MWr: 写PC内存(上行DMA数据) — 从WIB取地址, 从WDB取数据
//           MRd: 读PC内存(下行DMA请求) — 从RIB取地址/Tag, 无数据负载
//         通过 last_flg 实现读写交替调度, 避免带宽饥饿
//   时钟域: user_clk (直接驱动s_axis_rq AXI-Stream接口)
//   数据流: WIB+WDB → 组装MWr TLP → s_axis_rq → pcie3_7x_0
//           RIB     → 组装MRd TLP → s_axis_rq → pcie3_7x_0
// ========================================================================================
pcie_tx_engine_gen3 # (
    .U_DLY                      (U_DLY                           ),
    .WCHN_NUM                   (WCHN_NUM                        ),
    .RCHN_NUM                   (RCHN_NUM                        )
)u_pcie_tx_engine_gen3
(
    .clk                        (user_clk                        ),  // user_clk域
    .rst_n                      (sys_rst_n_x                     ),
    
    .wdma_tlp_size              (wdma_tlp_size                   ),  // TLP大小(128/256B)
 
    // ---- 写DMA完成反馈 (输出→CIB) ----
    .wchn_dma_done              (wchn_dma_done                   ),  // 写通道DMA完成
    .wchn_dma_end               (wchn_dma_end                    ),  // 写通道数据包结束
    .wchn_dma_chn               (wchn_dma_chn                    ),  // 完成的通道编号
    .wchn_dma_count             (wchn_dma_count                  ),  // 已传输TLP计数
    .wchn_dma_daddr             (wchn_dma_daddr                  ),  // 当前目标地址(低)
    .wchn_dma_drev              (wchn_dma_drev                   ),  // 描述符保留字
    .wchn_dma_daddr_h           (wchn_dma_daddr_h                ),  // 当前目标地址(高)

    // ---- 读DMA完成反馈 (输出→CIB) ----
    .rchn_dma_done              (rchn_dma_done                   ),  // 读通道DMA完成
    .rchn_dma_chn               (rchn_dma_chn                    ),  // 完成的通道编号
    .rchn_dma_daddr             (rchn_dma_daddr                  ),  // 当前地址(低)
    .rchn_dma_drev              (rchn_dma_drev                   ),  // 描述符保留字
    .rchn_dma_daddr_h           (rchn_dma_daddr_h                ),  // 当前地址(高)

    // ---- RQ AXI-Stream接口 (输出→pcie3_7x_0) ----
    .s_axis_rq_tlast            (s_axis_rq_tlast                 ),  // TLP最后一拍
    .s_axis_rq_tdata            (s_axis_rq_tdata                 ),  // 256bit TLP数据
    .s_axis_rq_tuser            (s_axis_rq_tuser                 ),  // 附加信息(byte enable)
    .s_axis_rq_tkeep            (s_axis_rq_tkeep                 ),  // DW使能
    .s_axis_rq_tready           (s_axis_rq_tready[0]             ),  // IP背压
    .s_axis_rq_tvalid           (s_axis_rq_tvalid                ),  // 有效标志

    // ---- WIB FIFO读接口 (MWr地址/信息) ----
    .wib_empty                  (wib_empty                       ),  // WIB空→无MWr可发
    .wib_ren                    (wib_ren                         ),  // WIB读使能
    .wib_dout                   (wib_dout                        ),  // WIB读数据(256bit信息)

    // ---- RIB FIFO读接口 (MRd地址/Tag) ----
    .rib_empty                  (rib_empty                       ),  // RIB空→无MRd可发
    .rib_ren                    (rib_ren                         ),  // RIB读使能
    .rib_dout                   (rib_dout                        ),  // RIB读数据(192bit信息)

    // ---- WDB FIFO读接口 (MWr数据负载) ----
    .wdb_empty                  (wdb_empty                       ),  // WDB空(与异常检测相关)
    .wdb_ren                    (wdb_ren                         ),  // WDB读使能
    .wdb_dout                   (wdb_dout                        ),  // WDB读数据(512bit)
    .wdb_underflow              (wdb_underflow                   ),  // WDB欠流(读空→错误)
    .txfifo_abnormal_rst        (txfifo_abnormal_rst             ),  // FIFO异常复位输出
    .trabt_err                  (trabt_err                       )   // MWr/MRd同时活跃错误

);

// ========================================================================================
// 【子模块11: pcie_msi_engine_gen3 — MSI 中断引擎】
//   功能: 将写/读DMA完成事件转换为MSI中断请求, 通知PC端驱动程序
//   工作流程:
//     1. tx_engine发出 wchn_dma_done/rchn_dma_done(上升沿)
//     2. MSI引擎检测到上升沿 → 置 wdma_int_ind/rdma_int_ind = 1
//     3. 置 cfg_interrupt_msi_int = 32'h1 → PCIe IP发送MSI中断
//     4. IP确认 msi_sent=1 → 清除标志, 等待下一次DMA完成
//   时钟域: user_clk
// ========================================================================================

pcie_msi_engine_gen3#(
    .U_DLY                      (U_DLY                      ) 
)
u_pcie_msi_engine_gen3(
    .clk                        (user_clk                   ),  // user_clk域
    .rst_n                      (sys_rst_n_x                ),
    .wdma_int_dis               (wdma_int_dis               ),  // 写DMA中断禁止(CIB可控)
    .rdma_int_dis               (rdma_int_dis               ),  // 读DMA中断禁止
    .wchn_dma_done              (wchn_dma_done               ),  // 写DMA完成事件
    .rchn_dma_done              (rchn_dma_done              ),  // 读DMA完成事件
    .cfg_interrupt_msi_enable   (cfg_interrupt_msi_enable[0]),  // MSI使能(PCIe配置空间)
    .cfg_interrupt_msi_sent     (cfg_interrupt_msi_sent     ),  // MSI已发送确认(IP输出)
    .cfg_interrupt_msi_fail     (cfg_interrupt_msi_fail     ),  // MSI发送失败(IP输出)
    .cfg_interrupt_msi_int      (cfg_interrupt_msi_int      )   // MSI中断向量(输出→IP)

);



// ========================================================================================
// 【子模块12: pcie3_7x_0 — Xilinx 7系列 PCIe Gen3 Endpoint IP Core】
//   功能: Xilinx提供的PCIe硬核IP, 处理PCIe协议所有层次:
//         物理层(PHY) + 数据链路层(DLL) + 事务层(TL)
//         对外提供AXI-Stream接口(RQ/RC/CQ/CC)给用户逻辑
//   接口组:
//     RQ (s_axis_rq): FPGA发出的请求(MWr/MRd TLP)
//     RC (m_axis_rc): PC返回的完成包(MRd的数据回复)
//     CQ (m_axis_cq): PC发来的请求(BAR寄存器读写)
//     CC (s_axis_cc): FPGA回复的完成包(BAR读数据或写确认)
//   时钟: sys_clk(100MHz参考钟) → 内部生成 user_clk(~250MHz)
// ========================================================================================
pcie3_7x_0 u_pcie3_7x_0(
    // ---- PCIe 物理层接口 (连接金手指) ----
    .pci_exp_txn                (pci_exp_txn                ),  // 发送差分负端 ×8
    .pci_exp_txp                (pci_exp_txp                ),  // 发送差分正端 ×8
    .pci_exp_rxn                (pci_exp_rxn                ),  // 接收差分负端 ×8
    .pci_exp_rxp                (pci_exp_rxp                ),  // 接收差分正端 ×8
    // ---- 内部时钟输出 (未使用, 供多实例或调试用) ----
    .int_pclk_out_slave         (                           ),
    .int_pipe_rxusrclk_out      (                           ),
    .int_rxoutclk_out           (                           ),
    .int_dclk_out               (                           ),
    .int_userclk1_out           (                           ),
    .int_userclk2_out           (                           ),
    .int_oobclk_out             (                           ),
    .int_qplllock_out           (                           ),
    .int_qplloutclk_out         (                           ),
    .int_qplloutrefclk_out      (                           ),
    .int_pclk_sel_slave         (8'b0                       ),  // PIPE时钟选择(单实例=0)
    .mmcm_lock                  (                           ),  // MMCM锁定状态
    // ---- 核心时钟与复位 ----
    .user_clk                   (user_clk                   ),  // ★输出: 用户时钟(~250MHz)
    .user_reset                 (user_reset                 ),  // ★输出: 用户复位(高有效)
    .user_lnk_up                (user_lnk_up                ),  // ★输出: 链路建立指示
    .user_app_rdy               (                           ),  // 用户应用就绪
    // ---- RQ: FPGA发请求(MWr写PC内存 / MRd读PC内存) ----
    .s_axis_rq_tlast            (s_axis_rq_tlast            ),  // input:  TLP最后一拍
    .s_axis_rq_tdata            (s_axis_rq_tdata            ),  // input:  256bit 数据
    .s_axis_rq_tuser            (s_axis_rq_tuser            ),  // input:  60bit 附加信息
    .s_axis_rq_tkeep            (s_axis_rq_tkeep            ),  // input:  8bit DW使能
    .s_axis_rq_tready           (s_axis_rq_tready           ),  // output: 4bit 背压
    .s_axis_rq_tvalid           (s_axis_rq_tvalid           ),  // input:  有效标志
    // ---- RC: PC返回完成包(MRd的数据回复) ----
    .m_axis_rc_tdata            (m_axis_rc_tdata            ),  // output: 256bit Completion数据
    .m_axis_rc_tuser            (m_axis_rc_tuser            ),  // output: 75bit 附加信息
    .m_axis_rc_tlast            (m_axis_rc_tlast            ),  // output: 包终止
    .m_axis_rc_tkeep            (m_axis_rc_tkeep            ),  // output: DW使能
    .m_axis_rc_tvalid           (m_axis_rc_tvalid           ),  // output: 有效
    .m_axis_rc_tready           (m_axis_rc_tready           ),  // input:  FPGA就绪
    // ---- CQ: PC发来的请求(BAR0寄存器读写) ----
    .m_axis_cq_tdata            (m_axis_cq_tdata            ),  // output: 256bit 请求包
    .m_axis_cq_tuser            (m_axis_cq_tuser            ),  // output: 85bit 附加信息
    .m_axis_cq_tlast            (m_axis_cq_tlast            ),
    .m_axis_cq_tkeep            (m_axis_cq_tkeep            ),
    .m_axis_cq_tvalid           (m_axis_cq_tvalid           ),
    .m_axis_cq_tready           (m_axis_cq_tready           ),  // input: FPGA就绪
    // ---- CC: FPGA回复完成包(BAR读数据返回) ----
    .s_axis_cc_tdata            (s_axis_cc_tdata            ),  // input:  256bit 回复数据
    .s_axis_cc_tuser            (s_axis_cc_tuser            ),
    .s_axis_cc_tlast            (s_axis_cc_tlast            ),
    .s_axis_cc_tkeep            (s_axis_cc_tkeep            ),
    .s_axis_cc_tvalid           (s_axis_cc_tvalid           ),
    .s_axis_cc_tready           (s_axis_cc_tready           ),  // output: IP背压
    // ---- 流控信息 ----
    .pcie_rq_seq_num            (                           ),  // 请求序号
    .pcie_rq_seq_num_vld        (                           ),
    .pcie_rq_tag                (                           ),  // IP分配的Tag(未使用,自己管理)
    .pcie_rq_tag_vld            (                           ),
    .pcie_tfc_nph_av            (                           ),  // Non-Posted Header可用信用
    .pcie_tfc_npd_av            (                           ),  // Non-Posted Data可用信用
    .pcie_cq_np_req             (1'b1                       ),  // 始终允许Non-Posted请求
    .pcie_cq_np_req_count       (                           ),
    // ---- PCIe 配置信息输出 ----
    .cfg_phy_link_down          (                           ),
    .cfg_phy_link_status        (                           ),
    .cfg_negotiated_width       (cfg_negotiated_width       ),  // ★协商宽度(8=x8)
    .cfg_current_speed          (cfg_current_speed          ),  // ★当前速率(3=Gen3)
    .cfg_max_payload            (cfg_max_payload            ),  // ★最大Payload(CIB用来设置TLP大小)
    .cfg_max_read_req           (cfg_max_read_req           ),  // ★最大读请求大小
    .cfg_function_status        (                           ),
    .cfg_function_power_state   (                           ),
    .cfg_vf_status              (                           ),
    .cfg_vf_power_state         (                           ),
    .cfg_link_power_state       (                           ),
    // ---- 配置空间管理接口 (未使用, 全部置0) ----
    .cfg_mgmt_addr              (19'b0                      ),
    .cfg_mgmt_write             (1'b0                       ),
    .cfg_mgmt_write_data        (32'b0                      ),
    .cfg_mgmt_byte_enable       (4'b0                       ),
    .cfg_mgmt_read              (1'b0                       ),
    .cfg_mgmt_read_data         (                           ),
    .cfg_mgmt_read_write_done   (                           ),
    .cfg_mgmt_type1_cfg_reg_access(1'b0                     ),
    // ---- 错误报告 ----
    .cfg_err_cor_out            (                           ),  // 可纠正错误
    .cfg_err_nonfatal_out       (                           ),  // 非致命错误
    .cfg_err_fatal_out          (                           ),  // 致命错误
    // ---- 链路状态(未使用) ----
    .cfg_ltr_enable             (                           ),
    .cfg_ltssm_state            (                           ),  // LTSSM状态机(可用于调试)
    .cfg_rcb_status             (                           ),
    .cfg_dpa_substate_change    (                           ),
    .cfg_obff_enable            (                           ),
    .cfg_pl_status_change       (                           ),
    .cfg_tph_requester_enable   (                           ),
    .cfg_tph_st_mode            (                           ),
    .cfg_vf_tph_requester_enable(                           ),
    .cfg_vf_tph_st_mode         (                           ),
    // ---- 消息接口 (未使用) ----
    .cfg_msg_received           (                           ),
    .cfg_msg_received_data      (                           ),
    .cfg_msg_received_type      (                           ),
    .cfg_msg_transmit           (1'b0                       ),
    .cfg_msg_transmit_type      (3'b0                       ),
    .cfg_msg_transmit_data      (32'b0                      ),
    .cfg_msg_transmit_done      (                           ),
    // ---- 流控信用 (未使用, 供确认资源可用性) ----
    .cfg_fc_ph                  (                           ),  // Posted Header信用
    .cfg_fc_pd                  (                           ),  // Posted Data信用
    .cfg_fc_nph                 (                           ),  // Non-Posted Header信用
    .cfg_fc_npd                 (                           ),  // Non-Posted Data信用
    .cfg_fc_cplh                (                           ),  // Completion Header信用
    .cfg_fc_cpld                (                           ),  // Completion Data信用
    .cfg_fc_sel                 (3'b0                       ),
    // ---- 每功能状态 (未使用) ----
    .cfg_per_func_status_control(3'b0                       ),
    .cfg_per_func_status_data   (                           ),
    .cfg_per_function_number    (3'b0                       ),
    .cfg_per_function_output_request(1'b0                   ),
    .cfg_per_function_update_done(                          ),
    // ---- 设备标识 ----
    .cfg_subsys_vend_id         (16'h10ee                   ),  // 子系统厂商ID=Xilinx
    .cfg_dsn                    ({PCI_EXP_EP_DSN_2,PCI_EXP_EP_DSN_1}), // 设备序列号
    // ---- 电源管理 ----
    .cfg_power_state_change_ack (cfg_power_state_change_ack ),  // 电源变更应答
    .cfg_power_state_change_interrupt (cfg_power_state_change_interrupt), // 电源变更中断
    // ---- 错误注入 (未使用) ----
    .cfg_err_cor_in             (1'b0                       ),  // 无可纠正错误注入
    .cfg_err_uncor_in           (1'b0                       ),  // 无不可纠正错误注入
    // ---- Function Level Reset (未使用) ----
    .cfg_flr_in_process         (                           ),
    .cfg_flr_done               (2'b0                       ),
    .cfg_vf_flr_in_process      (                           ),
    .cfg_vf_flr_done            (6'b0                       ),
    // ---- 链路训练 ----
    .cfg_link_training_enable   (1'b1                       ),  // 始终允许链路训练
    // ---- MSI 中断接口 ----
    .cfg_interrupt_int          (4'b0                       ),  // Legacy中断(未使用)
    .cfg_interrupt_pending      (2'b0                       ),
    .cfg_interrupt_sent         (                           ),
    .cfg_interrupt_msi_enable   (cfg_interrupt_msi_enable   ),  // ★输出: MSI使能状态
    .cfg_interrupt_msi_vf_enable(                           ),
    .cfg_interrupt_msi_mmenable (                           ),
    .cfg_interrupt_msi_mask_update (                        ),
    .cfg_interrupt_msi_data     (                           ),
    .cfg_interrupt_msi_select   (4'b0                       ),
    .cfg_interrupt_msi_int      (cfg_interrupt_msi_int      ),  // ★输入: MSI中断向量(从msi_engine)
    .cfg_interrupt_msi_pending_status(64'b0                 ),
    .cfg_interrupt_msi_sent     (cfg_interrupt_msi_sent     ),  // ★输出: MSI已发送
    .cfg_interrupt_msi_fail     (cfg_interrupt_msi_fail     ),  // ★输出: MSI发送失败
    .cfg_interrupt_msi_attr     (3'b0                       ),
    .cfg_interrupt_msi_tph_present(1'b0                     ),
    .cfg_interrupt_msi_tph_type (2'b0                       ),
    .cfg_interrupt_msi_tph_st_tag(9'b0                      ),
    .cfg_interrupt_msi_function_number(3'b0                 ),
    // ---- 其他配置 ----
    .cfg_hot_reset_out          (                           ),
    .cfg_config_space_enable    (1'b1                       ),  // 启用配置空间
    .cfg_req_pm_transition_l23_ready(1'b0                   ),
    .cfg_hot_reset_in           (1'b0                       ),  // 不触发热复位
    .cfg_ds_port_number         (8'b0                       ),  // 下游端口号
    .cfg_ds_bus_number          (8'b0                       ),
    .cfg_ds_device_number       (5'b0                       ),
    .cfg_ds_function_number     (3'b0                       ),
    // ---- 参考时钟与复位 ----
    .sys_clk                    (ref_clk                    ),  // ★100MHz参考时钟
    .sys_reset                  (~ref_reset_n               )   // ★复位(取反为高有效)
);

// ========================================================================================
// 【PCIe 电源状态管理】
//   当PCIe链路发生电源状态变更(D0→D3等)时, IP会发出中断
//   必须在几个时钟周期内应答, 否则链路可能异常
//   这里简单地: 收到中断→立即应答, 无中断→取消应答
// ========================================================================================
always @ (posedge user_clk or posedge user_reset)
begin
    if(user_reset == 1'b1)     
        cfg_power_state_change_ack <= 1'b0;  
    else    
        begin
            if(cfg_power_state_change_interrupt == 1'b1)
                cfg_power_state_change_ack <= #U_DLY 1'b1;
            else
                cfg_power_state_change_ack <= #U_DLY 1'b0;
        end
end

// ========================================================================================
// 【clog2b 函数 — 计算 ceil(log2(value))】
//   用于自动计算参数位宽, 例如:
//     clog2b(32) = 5  (5bit可编码0~31)
//     clog2b(9)  = 4  (4bit可编码0~15, 覆盖0~8)
//     clog2b(1)  = 1  (最小1bit)
//   注意: 这是综合前的函数, 不生成硬件, 只用于参数计算
// ========================================================================================
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

endmodule
