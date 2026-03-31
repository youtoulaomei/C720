# PCIe Gen3 DMA 引擎学习指南

> [!NOTE]
> 本指南按照 **"先整体后局部、先数据流后控制流"** 的顺序组织，适合从零开始理解这个多通道 DMA 引擎。

---

## 第一课：这个模块在做什么？

### 1.1 先从一句话开始

**这个模块是一个 PCIe Gen3 x8 的多通道 DMA 引擎，它让 FPGA 和 PC 之间能快速批量传输数据。**

### 1.2 什么是 DMA？

普通数据传输（PIO）方式下，CPU 每次读写一个寄存器（32bit），效率极低。DMA（Direct Memory Access）让硬件自主完成大块数据传输：

```
PIO方式 (慢):
  CPU: 写地址 → 写数据 → 写地址 → 写数据 → ... （每次32bit，CPU全程参与）

DMA方式 (快):
  CPU: 告诉DMA引擎 "从地址A搬运N字节到地址B"
  DMA引擎: 自动完成整块传输，完成后中断通知CPU
  CPU: 去做别的事情，等中断即可
```

### 1.3 这个模块的角色

在 BHD-C720 FPGA 项目中，这个模块的位置是：

```
┌─────────────────────────────────────────────┐
│                    PC 主机                    │
│  ┌───────┐    ┌──────────┐    ┌───────────┐ │
│  │ 驱动  │    │  PC内存   │    │  应用程序  │ │
│  └───┬───┘    └────┬─────┘    └───────────┘ │
│      │             │                         │
│      └─────────────┘                         │
│             │ PCIe Gen3 x8                   │
└─────────────┼───────────────────────────────┘
              │ 约 8 GB/s 理论带宽
┌─────────────┼───────────────────────────────┐
│  FPGA       │                                │
│  ┌──────────┴──────────┐                     │
│  │ ★ pcie_app_gen3_belta │  ← 你正在学的模块  │
│  │   (PCIe DMA 引擎)    │                     │
│  └──────────┬──────────┘                     │
│             │                                │
│  ┌──────────┴──────────┐                     │
│  │ DDR3 / JESD204B /   │                     │
│  │ 数据采集/处理模块    │                     │
│  └─────────────────────┘                     │
└─────────────────────────────────────────────┘
```

### 1.4 两个传输方向

这个DMA引擎支持双向传输：

| 方向 | 名称 | 术语 | 含义 |
|------|------|------|------|
| **FPGA → PC** | 写DMA (WDMA) | 上行 (Upstream) | FPGA采集的数据上传到PC内存 |
| **PC → FPGA** | 读DMA (RDMA) | 下行 (Downstream) | PC把数据（如配置/波形）发给FPGA |

> [!TIP]
> **"写"和"读"是站在 PC 内存的角度**看的：写DMA = 往 PC 内存里写 = FPGA 上传数据。

---

## 第二课：打开顶层文件，认识接口

打开 [pcie_app_gen3_belta.v](file:///c:/Users/18197/Desktop/code/c720/native_ip/pcie_gen3_belta/src/pcie_app_beltaw/pcie_app_gen3_belta.v)，先看端口声明（第36-89行）：

### 2.1 时钟和复位 (第37-40行)

```verilog
input   ref_clk,        // PCIe 参考时钟 (100MHz)，给Xilinx IP用
input   ref_reset_n,    // PCIe 参考复位
input   sys_clk,        // 系统时钟，给DMA控制逻辑用
input   sys_rst_n,      // 系统复位
output  user_clk,       // PCIe IP输出的用户时钟 (~250MHz @ Gen3x8)
output  user_rst_n,     // PCIe IP输出的用户复位
```

**为什么有这么多时钟？**

因为这个模块连接了三个不同速率的世界：
- **PCIe 世界** → user_clk (由IP自动生成，约250MHz)
- **FPGA 内部逻辑世界** → sys_clk
- **用户数据源/接收** → wchn_clk / rchn_clk

这三个时钟相互独立，所以模块内部需要大量的 **异步FIFO** 来安全传递数据。

### 2.2 PCIe 物理层接口 (第46-50行)

```verilog
output  [7:0]  pci_exp_txn,   // PCIe 发送差分信号 (8 lanes)
output  [7:0]  pci_exp_txp,
input   [7:0]  pci_exp_rxn,   // PCIe 接收差分信号 (8 lanes)
input   [7:0]  pci_exp_rxp,
output         pcie_link,     // PCIe 链路建立指示
```

这是实际连到 PCIe 金手指上的信号，8条lane = x8。你不需要关心它们的时序细节，Xilinx IP 会处理。

### 2.3 本地总线接口 (第52-56行)

```verilog
output         r_wr_en,       // 寄存器写使能
output [18:0]  r_addr,        // 寄存器地址
output [31:0]  r_wr_data,     // 寄存器写数据
output         r_rd_en,       // 寄存器读使能
input  [31:0]  r_rd_data,     // 寄存器读返回数据
```

这是 **PC 通过 BAR0 空间读写 FPGA 寄存器** 的接口。PC驱动做 `iowrite32(addr, data)` 最终就会驱动这些信号。

### 2.4 上行用户接口 — 写通道 (第79-89行)

```verilog
input  [WPHY_NUM-1:0]              wchn_clk,        // 用户时钟
input  [WPHY_NUM-1:0]              wchn_rst_n,      // 用户复位
output [WPHY_NUM-1:0]              wchn_data_rdy,   // ★ "我准备好接收了"
input  [WPHY_NUM-1:0]              wchn_data_vld,   // ★ "数据有效"
input  [WPHY_NUM-1:0]              wchn_sof,        // 帧起始
input  [WPHY_NUM-1:0]              wchn_eof,        // 帧结束
input  [WPHY_NUM*WDATA_WIDTH-1:0]  wchn_data,       // 数据 (512bit)
input  [WPHY_NUM-1:0]              wchn_end,        // DMA包结束
input  [(WPHY_NUM*WDATA_WIDTH)/8-1:0] wchn_keep,    // 字节使能
input  [WPHY_NUM*15-1:0]           wchn_length,     // 包长度
input  [WPHY_NUM*WCHN_NUM_W-1:0]   wchn_chn,        // 逻辑通道号
```

这是 **其他FPGA模块往PC发数据时** 调用的接口。采用经典的 **ready/valid 握手协议**：

```
         ┌──┐  ┌──┐  ┌──┐  ┌──┐
clk     ─┘  └──┘  └──┘  └──┘  └──
         ___________________________
rdy     ─────┐          ┌──────────  DMA引擎准备好接收
              └──────────┘
         ___   ___   ___
vld     ─┘ └─┘ └─┘ └──────────────  用户有数据要发
              ↑
         只有 rdy=1 且 vld=1 时，数据才真正被接收
```

### 2.5 下行用户接口 — 读通道 (第68-76行)

```verilog
input  [RCHN_NUM-1:0]              rchn_clk,        // 各通道用户时钟
input  [RCHN_NUM-1:0]              rchn_rst_n,      // 各通道复位
input  [RCHN_NUM-1:0]              rchn_data_rdy,   // 用户端就绪
output [RCHN_NUM-1:0]              rchn_data_vld,   // 数据有效
output [RCHN_NUM-1:0]              rchn_sof,        // 帧起始
output [RCHN_NUM-1:0]              rchn_eof,        // 帧结束
output [RCHN_NUM*RDATA_WIDTH-1:0]  rchn_data,       // 数据 (512bit×9通道)
output [(RCHN_NUM*RDATA_WIDTH)/8-1:0] rchn_keep,    // 字节使能
output [RCHN_NUM*15-1:0]           rchn_length,     // 包长度
```

这是 **PC发下来的数据送给FPGA其他模块** 的接口，共9个独立通道，每个通道有自己的时钟。

---

## 第三课：一笔数据是怎么传输的？

### 3.1 场景：FPGA 上传 2KB 数据到 PC (写DMA)

让我们跟踪一笔完整的上行 DMA 传输：

```
步骤1: PC驱动 配置DMA描述符
   PC驱动通过BAR0写入: 目标地址=0x1000_0000, 长度=2KB, 通道=0
   ↓ (经过 pcie_regif_gen3 → local bus → pcie_cib → pcie_item)
   
步骤2: pcie_item 输出使能
   wchn_dma_en[0] = 1
   wchn_dma_addr[31:0] = 0x1000_0000
   wchn_dma_len[23:0] = 2048/128 = 16 (单位: 128字节)

步骤3: 用户模块 送入数据
   用户模块在 wchn_clk 域: wchn_data_vld=1, wchn_data=512bit, wchn_chn=0
   ↓ (进入 couple_logic 的异步FIFO)

步骤4: pcie_wchn_arbiter 仲裁
   状态机检测到: FIFO有数据(dvld=1) + DMA已使能(pcnt>0) + 输出FIFO未满
   → 开始读取 couple_logic FIFO
   → 每读满一个TLP大小(如128B)的数据，写入 WDB + WIB

步骤5: pcie_tx_engine_gen3 组装TLP
   从 WDB 读取 512bit 数据
   从 WIB 读取 地址/通道号/长度信息
   组装 Memory Write TLP:
     Header: {地址=0x1000_0000, 类型=MWr, 长度=32DW}
     Data:   128字节 payload
   → 送入 s_axis_rq → pcie3_7x_0

步骤6: PCIe IP 发送TLP
   pcie3_7x_0 添加CRC、序列号等，通过 pci_exp_txp/txn 发出

步骤7: PC端接收
   PC的Root Complex收到MWr TLP
   直接写入PC内存 0x1000_0000 位置

步骤8: 传输完成
   所有TLP发送完毕后, wchn_dma_done=1
   → MSI引擎 发送MSI中断
   → PC驱动收到中断，知道数据已到达
```

### 3.2 场景：PC 下发 2KB 数据到 FPGA (读DMA)

```
步骤1: PC驱动 配置DMA描述符
   写入: 源地址=0x2000_0000, 长度=2KB, 通道=0

步骤2: pcie_rchn_arbiter 生成读请求
   状态机: RCHN_ABT → RCHN_RECORD
   循环生成 RTAG_NUM(16)个读请求，填入 RIB FIFO:
     请求0: addr=0x2000_0000, tag=0, size=128B
     请求1: addr=0x2000_0080, tag=1, size=128B
     ...
     请求15: addr=0x2000_0780, tag=15, size=128B

步骤3: pcie_tx_engine_gen3 发送 MRd TLP
   从 RIB 读取请求信息
   组装 Memory Read TLP (无数据负载，只有Header):
     {地址=0x2000_0000, 类型=MRd, 长度=32DW, Tag=0}
   → 送入 pcie3_7x_0

步骤4: PC端处理
   Root Complex 收到 MRd，从PC内存读取数据
   以 Completion TLP 返回数据

步骤5: pcie_rx_engine_gen3 接收
   收到 m_axis_rc: 解析 Tag、字节计数
   将 256bit 数据拼接为 512bit
   按 Tag 计算地址，写入内部 RAM Buffer

步骤6: Tag全部回收
   16个Tag都收到Completion后 → tag_release=1
   → rchn_arbiter 知道数据已就绪

步骤7: 数据分发
   rchn_arbiter 从 RAM Buffer 读出数据
   根据通道号，写入对应通道的 rfifo

步骤8: 用户接收
   pcie_rchn_couple 状态机:
     FIFO攒够一个BURST → 输出帧 (sof + data×N + eof)
   用户模块通过 rchn_data/vld/rdy 接收数据
```

> [!IMPORTANT]
> **关键区别**: 写DMA是"推"模型（数据主动流出），读DMA是"请求-等待"模型（先发请求，等返回数据）。这就是为什么读DMA需要 Tag 管理和 RAM Buffer——因为返回数据可能乱序。

---

## 第四课：子模块分层理解

把12个子模块按功能分为4层，逐层学习：

```
┌─────────────────────────────────────────────────────┐
│ 第4层：PCIe 协议层                                    │
│  pcie3_7x_0 (Xilinx IP) + pcie_msi_engine_gen3      │
├─────────────────────────────────────────────────────┤
│ 第3层：TLP 引擎层                                     │
│  pcie_tx_engine_gen3 + pcie_rx_engine_gen3           │
│  + pcie_regif_gen3                                    │
├─────────────────────────────────────────────────────┤
│ 第2层：仲裁与缓冲层                                   │
│  pcie_wchn_arbiter + pcie_rchn_arbiter               │
│  + u_wib_fifo + u_wdb_fifo + u_rib_fifo             │
├─────────────────────────────────────────────────────┤
│ 第1层：用户接口层                                     │
│  couple_logic + pcie_rchn_couple + bandcount         │
│  + datas_builtin_top                                  │
├─────────────────────────────────────────────────────┤
│ 第0层：控制管理层 (贯穿所有层)                         │
│  pcie_cib + pcie_item + pcie_witem_glb               │
│  + pcie_ritem_glb                                     │
└─────────────────────────────────────────────────────┘
```

### 4.1 第1层：用户接口层 — 你首先应该理解的

#### couple_logic — "数据入口翻译官"

**核心问题**: 用户数据在 `wchn_clk` 时钟域，DMA引擎在 `sys_clk` 时钟域，怎么安全传递？

**答案**: 用异步FIFO。

```verilog
// 第298-299行: FIFO写入格式 —— 打包信息
assign txdma_fifo_wr      =  wvld;
assign txdma_fifo_wr_data =  {wchn, wchn_len, wend, wdata};
//                             通道号  长度   结束  512bit数据
```

注意这个打包格式 `{通道号, 长度, 结束标志, 数据}` — 这样仲裁器从FIFO读出时就知道这包数据属于哪个通道。

**built_in 模式** (第134行):

```verilog
else if(built_in_r[2]==1'b1)     // 内建测试模式
    begin
        if(ds_rx_data_vld==1'b1)
            wvld <= #U_DLY 1'b1; // 用测试数据代替用户数据
    end
```

当 `built_in=1` 时，数据源从外部用户切换为内部测试发生器。这是调试PCIe链路时非常有用的功能。

**eflg (end flag)** — 通知仲裁器的巧妙设计:

```verilog
// 第309-310行
else if(wvld==1'b1 && wend==1'b1)
    wchn_eflg <= #U_DLY 1'b1;    // 一包数据写完 → 置flag
```

`wchn_eflg` 是跨时钟域的"数据包结束"信号。仲裁器看到 `eflg=1` 就知道这个物理通道当前没有新数据需要拆分了。

#### pcie_rchn_couple — "数据出口打包员"

这个模块对每个读通道做了什么：

```
RAW数据(sys_clk域)            帧格式数据(rchn_clk域)
  rfifo_wr ──→ [异步FIFO] ──→ 状态机 ──→ rchn_data/vld/sof/eof
                                ↓
                      攒够RBURST_LEN ──→ 输出一帧
```

状态机逻辑（第115-139行）简洁明了：

```
IDLE: FIFO攒够数据？→ FRM (开始输出帧)
FRM:  输出完最后一拍？→ DONE
DONE: 回到 IDLE
```

**学习要点**: 注意 `rfifo_prog_empty` 信号——它不是"完全空"，而是"数据不够一个burst"。只有攒够 `RBURST_LEN/RDATA_WIDTH_BYTE` 个数据才开始输出，这样保证每帧长度固定。

---

### 4.2 第2层：仲裁与缓冲层 — 系统性能的关键

#### pcie_wchn_arbiter — "写通道交通警察"

**核心问题**: 只有1个物理通道（WPHY_NUM=1），但有32个逻辑通道，怎么公平分配带宽？

**答案**: 轮询仲裁 + 突发传输。

```
状态机工作流程:
WCHN_ABT:  轮询每个物理通道，检查是否有数据(dvld)且DMA已使能(pcnt>0)
WCHN_READ: 读取数据，按TLP大小(128B/256B)分片，写入WDB和WIB
WCHN_WAIT: 一个burst结束，清理状态
```

**关键代码解读** — 怎么决定一个TLP结束？（第312行）

```verilog
if(wdb_wen_pre==1'b1 && wtlp_cnt >= wdma_tlp_size -'d64)
    wtlp_cnt <= #U_DLY 'b0;   // TLP计数满 → 重置
```

`wtlp_cnt` 累计到 `wdma_tlp_size`（如128字节），就认为一个 TLP 的数据已收集完毕。此时 `wib_wen=1`，把对应的地址/通道信息写入 WIB。

**WIB 信息 FIFO 的内容** — 一个 TLP 的"发货单"（第394-403行）

```verilog
assign wib_din = { wchn_cnt,             // 哪个通道的数据
                   wchn_dma_daddr_h,      // PC端目标地址(高32位)
                   wchn_rd_end,           // 数据流结束标志
                   wchn_done,             // DMA总量传完标志
                   wtlp_real_cnt,         // 这个TLP的实际大小
                   wchn_dma_daddr,        // PC端目标地址(低32位)
                   wchn_dma_plen,         // 累计传输长度
                   wchn_dma_prev,         // 描述符保留字段
                   wchn_dma_paddr};       // PCIe侧地址
```

TX Engine 就是靠这个"发货单"来组装 TLP Header 的。

#### pcie_rchn_arbiter — "读通道调度员"

**核心问题**: 读DMA需要先发请求再等数据返回，如何管理？

**答案**: Tag + 双缓冲。

**Tag 机制**:
```
每次读DMA, 一次性发出 RTAG_NUM(16) 个读请求:
  请求0: 读128B, Tag=0
  请求1: 读128B, Tag=1
  ...
  请求15: 读128B, Tag=15

PC端可能乱序返回:
  返回Tag=5的数据
  返回Tag=0的数据
  返回Tag=12的数据
  ...

RX引擎按Tag计算写入地址, 所以乱序也不影响正确性
```

**双缓冲** (第110-111行):

```verilog
reg [1:0] buf_state [0:1];    // 两个buffer的状态
reg [RCHN_NUM_W-1:0] buf_user [0:1]; // 各buffer服务的通道号
```

当 buffer0 在等待 PC 返回数据时，buffer1 可以接收新的需求——这样实现了流水化。

---

### 4.3 第3层：TLP 引擎层 — PCIe 协议的核心

#### pcie_tx_engine_gen3 — "TLP 包装车间"

**核心问题**: 怎么把数据和地址信息组装成PCIe TLP？

先理解 PCIe Gen3 RQ 接口格式 (256bit AXI-Stream):

```
第1拍 (Header): 
  [31:0]   = 地址低32位
  [63:32]  = 地址高32位  
  [95:64]  = {requester_id, poisoned, req_type, dword_count}
  [127:96] = {force_ecrc, attr, tc, req_id_en, tag}
  [255:128]= 数据 (MWr首拍携带128bit数据)

第2-N拍 (Data):
  [255:0]  = 256bit 纯数据
  
最后一拍: tlast=1
```

**MWr Header 组装**（第423-426行）:

```verilog
assign mwr_header_dw0 = {wr_dma_addr};                    // 目标地址低
assign mwr_header_dw1 = {wr_dma_addr_h};                  // 目标地址高
assign mwr_header_dw2 = {16'b0, 1'b0, 4'b0001,            // req_type=MWr(0001)
                         {3'd0, wdma_tlp_size_dw}};        // DWord计数
assign mwr_header_dw3 = {1'b0,3'd0,3'b0,1'b0,5'd0,3'd0,  // 属性/TC
                         8'd0, 8'd0};                       // Tag(MWr不用)
```

**MRd Header 组装**（第438-441行） — 注意区别:

```verilog
assign mrd_header_dw2 = {16'b0, 1'b0, 4'b0000,            // req_type=MRd(0000)
                         {3'd0, rdma_tlp_size_dw}};
assign mrd_header_dw3 = {... 8'd0, {3'd0, rdma_tag}};     // ★ Tag 有值！
```

> MWr 的 Tag 不重要（不需要返回），MRd 的 Tag 是关键（用它来匹配返回数据）。

**读写交替调度** — 避免带宽饥饿（第169-173行）:

```verilog
// last_flg = 0: 读优先; last_flg = 1: 写优先
assign mwr_st_x = (abt_flg_x && last_flg==1 && wib非空 && wdb非空) ? 1  // 写优先且有写数据
                : (abt_flg_x && last_flg==0 && rib空 && wib非空 && wdb非空) ? 1  // 读优先但无读请求
                : 0;

assign mrd_st_x = (abt_flg_x && last_flg==0 && rib非空) ? 1  // 读优先且有读请求
                : (abt_flg_x && last_flg==1 && rib非空 && (wib空||wdb空)) ? 1  // 写优先但无写数据
                : 0;
```

这段逻辑的精髓：**有能力做的事优先做，没能力做时把机会让给另一方**。

#### pcie_rx_engine_gen3 — "TLP 拆包车间"

**核心问题**: PC返回的 Completion TLP 怎么拆解并存到正确位置？

**256bit → 512bit 拼接** (第163-183行):

```
RC TLP格式 (AXI-Stream 256bit):
  第1拍(SOF): [95:0]=Header信息(Tag,ByteCount等), [255:96]=数据开头160bit
  第2拍:      [95:0]=上一拍剩余的续接, [255:96]=新数据160bit
  ...

拼接过程:
  rc_data_reg ← 每拍暂存 tdata[255:96] = 160bit
  rc_wdata    ← {当前拍96bit, 上一拍160bit} = 256bit
  
  rc_wr_flg 交替:
    flg=0: rmem_wdata[255:0]   ← rc_wdata  (低256bit)
    flg=1: rmem_wdata[511:256] ← rc_wdata  (高256bit) → 触发 rmem_wr
```

**地址计算** — 按 Tag 和偏移确定 RAM 位置（第117-119行）:

```verilog
case(cfg_max_payload_r2)
    3'b000: rmem_waddr_pre <= {2'b0, rc_tag_x, st_mem_waddr[0]};   // 128B→2slot/tag
    3'b001: rmem_waddr_pre <= {1'b0, rc_tag_x, st_mem_waddr[1:0]}; // 256B→4slot/tag
    3'b010: rmem_waddr_pre <= {rc_tag_x, st_mem_waddr[2:0]};       // 512B→8slot/tag
endcase
```

地址 = `{Tag编号, 偏移}`，这样16个Tag的数据自然分隔在RAM的不同区域，即使乱序返回也能写入正确位置。

---

### 4.4 第0层：控制管理层 — pcie_cib

#### pcie_cib — "中央控制室"

这是最复杂的模块，但理解了整体后就清晰了。它的职责：

```
1. 寄存器管理 ← PC驱动读写FPGA寄存器
2. DMA描述符 ← 管理32个写通道+9个读通道的DMA参数
3. 状态监控  ← FIFO溢出、错误历史、带宽统计
4. TLP大小   ← 根据PCIe协商结果自动设置
5. 自测控制  ← 内建测试模式的参数
```

**描述符如何传递?**

```
PC驱动:
  1. 往 witem_wdata0~4 写入描述符内容 (目标地址、长度、保留字)
  2. 触发 witem_wr_det=1
  3. pcie_witem_glb 将描述符写入内部FIFO
  4. pcie_item[i] 从FIFO读取描述符
  5. 输出 wchn_dma_en[i]=1, wchn_dma_addr[i], wchn_dma_len[i]
  6. 仲裁器看到使能就开始传输
```

**TLP Size 自适应** (第1020-1026行):

```verilog
case(cfg_max_payload_r2)
    3'b000: wdma_tlp_size <= 10'd128;   // PCIe 协商 Max Payload = 128B
    3'b001: wdma_tlp_size <= 10'd256;   // PCIe 协商 Max Payload = 256B
    3'b010: wdma_tlp_size <= 10'd256;   // 512B 时限制到 256B
    default: wdma_tlp_size <= 10'd128;
endcase
```

注意即使 PCIe 协商支持 512B Max Payload，这里也限制到 256B。这可能是为了平衡延迟和吞吐量。

---

## 第五课：三个关键跨时钟域 FIFO

这三个 FIFO 是整个系统的"枢纽"，理解它们就理解了数据如何在不同时钟域间流动：

```
                sys_clk 域                    user_clk 域
              ┌──────────┐               ┌──────────────────┐
              │ wchn     │  ┌─────────┐  │ tx_engine        │
              │ arbiter ─┼→│ WDB FIFO│→─┼→ (发送MWr TLP)   │
              │          │  │ 512b×512│  │                   │
              │          │  └─────────┘  │                   │
              │          │               │                   │
              │         ─┼→┌─────────┐→─┼→                  │
              │          │  │ WIB FIFO│  │                   │
              │          │  │ 256b×128│  │                   │
              └──────────┘  └─────────┘  │                   │
                                         │                   │
              ┌──────────┐               │                   │
              │ rchn     │  ┌─────────┐  │                   │
              │ arbiter ─┼→│ RIB FIFO│→─┼→ (发送MRd TLP)   │
              │          │  │ 192b×64 │  │                   │
              └──────────┘  └─────────┘  └──────────────────┘
```

**为什么 WDB 深度是 512 而 WIB 只有 128？**

因为每个 TLP 对应:
- WDB: 多个512bit数据（如128B TLP = 2个512bit）
- WIB: 只有1个256bit描述信息

所以数据量差距大约 4:1，FIFO 深度比例也大致对应。

---

## 第六课：常见调试技巧

### 6.1 怎么判断 DMA 是否正常？

通过 CIB 寄存器读取：

```
1. 读 DMA_0F (0x43C): 确认 PCIe 链路状态
   - cfg_negotiated_width = 8 (x8)
   - cfg_current_speed = 3 (Gen3)

2. 读 DMA_28 (0x4A0): 上行带宽 (KB/s)
   - 正常 ~7,000,000 (约7GB/s)

3. 读 DMA_14 (0x450): 错误历史
   - 全0 = 无错误
   - his_wdb_overflow=1 → 数据FIFO溢出，用户数据速率太快
   - his_rc_err=1 → Completion包异常

4. 读 DMA_13 (0x44C): 状态机状态
   - t_wchn_cur_st: 写仲裁器 (0=ABT, 1=READ, 2=WAIT)
   - t_rchn_cur_st: 读仲裁器 (0=ABT, 1=RECORD, 2=DONE)
   - 卡在某个状态 → 对应握手信号有问题
```

### 6.2 数据丢失怎么排查？

```
检查路径 (上行):
  用户接口 → couple_logic FIFO → wchn_arbiter → WDB → tx_engine → PCIe

  1. cfifo_overflow？ → couple_logic FIFO满，用户数据丢失
  2. wdb_overflow？   → WDB FIFO满，仲裁器产数据太快
  3. wdb_underflow？  → WDB FIFO空，tx_engine读到空数据
  4. txfifo_abnormal？→ WIB/WDB 不同步，已自动复位

检查路径 (下行):
  PCIe → rx_engine → RAM Buffer → rchn_arbiter → rfifo → 用户

  1. rc_is_err？      → Completion TLP有错误
  2. rfifo_overflow？  → 用户端来不及消费数据
  3. rfifo_underflow？ → 状态机提前读导致空读
```

### 6.3 内建自测试怎么用？

```
1. 写 DMA_40 = 1    → 切换到内建测试模式
2. 写 DMA_46 = 1    → 设置数据模式(递增8bit)
3. 写 DMA_47 bit0=1 → 连续发送模式启动
4. 写 DMA_43 = 6442 → 设置令牌桶宽度(控制速率)
5. 配置DMA描述符并启动
6. 读 DMA_28         → 确认带宽
7. 写 DMA_45 = 1     → 启动数据校验
```

---

## 第七课：设计模式总结

### 7.1 这个模块教你的 FPGA 设计模式

| 模式 | 在哪里用了 | 为什么用 |
|------|-----------|---------|
| **异步FIFO跨时钟域** | couple_logic, rchn_couple, WDB/WIB/RIB | 不同频率时钟域之间安全传数据 |
| **Ready/Valid 握手** | 用户接口 wchn/rchn | 流控：防止数据丢失 |
| **轮询仲裁** | wchn/rchn arbiter | 多通道公平共享带宽 |
| **双缓冲流水** | rchn_arbiter 的 buf_state[0:1] | 请求和接收流水化，提高吞吐量 |
| **Tag 管理** | rx_engine 的 cpld_tag_count | 匹配乱序返回的 Completion |
| **描述符队列** | pcie_item + witem_glb | CPU配置DMA任务的标准方式 |
| **错误历史寄存器** | pcie_cib 的 his_xxx 信号 | 事件瞬间发生也不会被遗漏 |
| **FIFO 异常自恢复** | tx_engine 的 txfifo_abnormal_rst | 系统自愈，避免永久卡死 |
| **令牌桶限速** | datas_builtin_top | 精确控制数据注入速率 |
| **`#U_DLY` 仿真延迟** | 所有模块的非阻塞赋值 | 仿真时避免竞争条件 |

### 7.2 推荐的阅读顺序

```
第1遍：宏观理解（你正在做的）
  ✅ 顶层端口 → 子模块列表 → 数据流

第2遍：自底向上读每个模块
  1. bandcount (最简单，40行有效代码)
  2. pcie_msi_engine_gen3 (简单的中断逻辑)
  3. couple_logic (理解FIFO打包)
  4. pcie_rchn_couple (理解帧输出)
  5. pcie_regif_gen3 (理解BAR访问)
  6. pcie_rx_engine_gen3 (理解Completion解析)
  7. pcie_wchn_arbiter (理解写仲裁)
  8. pcie_rchn_arbiter (理解读仲裁)
  9. pcie_tx_engine_gen3 (理解TLP组装)
  10. pcie_cib (理解全局控制)

第3遍：结合仿真波形
  用 ILA 或 仿真工具，跟踪一笔完整DMA传输的信号变化
```

---

## 第八课：关键问答

**Q: 为什么写通道有32个逻辑通道但只有1个物理通道？**

A: 因为 FPGA 内部有多个数据源（如多路ADC），每路独立产生数据，但它们共享一个 PCIe 链路。逻辑通道号 `wchn_chn` 用来区分不同数据源，仲裁器轮流服务每个有数据的通道。

**Q: RTAG_NUM=16 意味着什么？**

A: 读DMA每次批量发出16个读请求（每个请求128-256字节），然后等待全部返回。这样利用了 PCIe 的流水线特性——不用等一个请求返回就发下一个。Tag 越多，"在空中飞行"的数据越多，带宽利用率越高。但 Tag 多了需要更大的 RAM Buffer。

**Q: burst_done 和 wchn_dma_done 有什么区别？**

A: 
- `burst_done`: 一次突发传输完成（如2KB），但总的DMA可能有10MB
- `wchn_dma_done`: 整个DMA传输完成（所有数据都发出去了）
- 一个 DMA = 多次 burst，一次 burst = 多个 TLP

**Q: txfifo_abnormal_rst 什么情况会触发？**

A: 当 WIB（写信息FIFO）和 WDB（写数据FIFO）出现一个空一个非空的状态，且持续超过约1秒时触发。这意味着数据和信息"失步"了，不复位就永远无法恢复。这是一种保护机制，实际运行中不应触发，触发说明有 bug。

**Q: `#U_DLY` 为什么到处都有？**

A: 所有非阻塞赋值都加了 `#U_DLY`（1ns延迟），目的是在 **仿真** 中避免 delta cycle 竞争条件。综合工具会自动忽略它，不影响实际电路。这是 Verilog 仿真的最佳实践。
