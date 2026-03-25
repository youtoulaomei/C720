# BHD-C720 FPGA项目 文档

> **项目名称**: BHD-C720 逻辑设计  
> **FPGA器件**: Xilinx Kintex-7 系列  
> **顶层模块**: `bhd_c720_top` (`BHD_C720_top.v`, 1483行)  
> **Logic ID**: `441D_4337_3135`, **版本**: `1000`

---

## 一、项目概述

### 1.1 项目定位

BHD-C720 是一个基于 Xilinx 7系列 FPGA 的**信号采集与回放系统**，集成了高速数据采集（ADC via LVDS）、信号处理（BPF滤波/加噪/DDC数字下变频/DUC数字上变频）、高速数据传输（PCIe Gen3 x8）、数据缓存（DDR3 SDRAM）、数模转换回放（DAC via JESD204B TX）、时间同步（北斗/B码）及在线升级（NOR Flash MEFC）等功能。

### 1.2 硬件板卡组成

| 板卡 | 功能 | 关键接口 |
|------|------|----------|
| **主卡 9981** | 核心FPGA、PCIe、DDR3、NOR Flash、时间同步 | PCIe x8, DDR3 64bit, NOR Flash 16bit |
| **FMC RX（采集子卡 9933）** | ADC采集，PLL时钟 | LVDS 16ch, SPI×3（AD9516 PLL + 2×AD9467 ADC） |
| **FMC TX（回放子卡 9905）** | DAC回放 | JESD204B 4-lane TX, SPI×2（HMC7044 PLL + AD9172 DAC） |
| **变频模块 ZD20E** | 接收下变频 | SPI控制 |
| **发射模块 ZC18** | 发射上变频 | SPI控制 |

### 1.3 系统时钟架构

```
sys_clk (100MHz差分) ──► sys_clk_wiz ──┬── clk_50m   (50MHz)
                                        ├── clk_100m  (100MHz) ← 主系统时钟
                                        ├── clk_150m  (150MHz)
                                        └── clk_200m  (200MHz) ← IDELAYCTRL

JESD TX 参考时钟 ──► jesd_tx_top ──► dac_clk (tx_core_clk, ~93.33MHz)
                                       │
                                       └► DAC_division ──► dac_double_clk (~186.67MHz)

LVDS RX 时钟 ──► lvds_7k_top ──► ad_clk (ADC采样时钟)

PCIe参考时钟 ──► IBUFDS_GTE2 ──► pcie_clk_gt ──► pcie_app ──► user_clk
```

**关键面试点**：系统存在**至少5个时钟域**：`clk_100m`、`clk_50m`、`ad_clk`、`dac_clk`/`dac_double_clk`、`user_clk`(PCIe)。跨时钟域通过异步FIFO（`asyn_fifo`）和多级寄存器同步实现。

---

## 二、系统整体架构

### 2.1 数据流框图

```
                        ┌─────────────┐
    LVDS RX ──► lvds_7k_top ──► BPF ──► add_noise ──► bit_convert(16→64)
                                                              │
                                                    ┌─────────┴─────────┐
                                              ad_data_d(ADC原始)   ddc_dout_d(DDC下变频)
                                                    │                   │
                                                    └─────┬─────────────┘
                                                          ▼
                                                    multif_top (6ch数据复用)
                                                          │
                                                          ▼
                                              sgl_ch_ddr_frame_top (DDR3帧存储)
                                                     ┌────┴────┐
                                                     ▼         ▼
                                            PCIe DMA上传    DAC回放通道
                                                     │         │
                                              pcie_app     width_conv_B2S(512→32)
                                                     │         │
                                                     │    ddc_duc_top(DUC上变频)
                                                     │         │
                                                     │    width_conv_S2B(32→64)
                                                     │         │
                                                     │    jesd_tx_top(JESD204B TX)
                                                     │         │
                                                     ▼         ▼
                                                   上位机     DAC输出
```

### 2.2 CPU总线架构

```
PCIe App ──► Local Bus (r_addr[18:0]) ──► cpu_alloc_32users (地址译码)
                                                  │
                 ┌────────────────────────────────┤
                 ▼                                ▼
         [0x000~0x0FF] general_func_7s    [0x100~0x1FF] pcie_app_cib
         [0x200~0x2FF] ddr_frame          [0x300~0x3FF] multif_top
         [0x400~0x4FF] mefc_top           [0x500~0x5FF] spi[0] AD9516
         [0x600~0x6FF] spi[1] ADC1        [0x700~0x7FF] spi[2] ADC2
         [0x800~0x8FF] spi[3] HMC7044     [0x900~0x9FF] spi[4] AD9172
         [0xA00~0xAFF] spi[5] ZD20E       [0xB00~0xBFF] spi[6] ZC18
         [0xC00~0xCFF] fill               [0xD00~0xDFF] jesd_tx
         [0xE00~0xEFF] lvds               [0xF00~0xFFF] fill
         [1000~10FF] i2c[0]~[3]           [1400~17FF] uart[0]~[3]
         [1800~19FF] alg(DDC/DUC)         [1A00~1AFF] add_noise
         [1B00~1BFF] fill                 [1C00~1CFF] btc(B码)
         [1D00~1DFF] bd(北斗)             [1E00~1FFF] fill
```

**核心设计**：`cpu_alloc_32users` 将 PCIe 传下来的 13位地址空间按 256字节（8bit地址）划分为 32 个用户空间，每个子模块通过 `cpu_process` 进行地址匹配和跨时钟域同步（从 `user_clk` 同步到各子模块的工作时钟），实现统一的寄存器读写接口。

---

## 三、核心模块功能详解

### 3.1 PCIe Gen3 x8 模块 (`pcie_app_gen3_belta`)

| 项目 | 说明 |
|------|------|
| **协议** | PCIe Gen3, 8 lanes |
| **功能** | 主机与FPGA的高速数据传输通道 |
| **Local Bus** | 提供 19bit 地址、32bit 数据的寄存器读写总线 |
| **DMA通道** | 提供 9 路 MDMA 回读通道 (rchn) + 1 路下发通道 (wchn)，数据宽度 512bit |
| **状态输出** | `pcie_link` 指示链路状态 |

**面试要点**：
- PCIe参考时钟通过 `IBUFDS_GTE2` 原语接收  
- DMA回读通道0专用于 MEFC Flash在线升级数据  
- DMA下发通道产生512bit宽度数据，需通过DDR帧存储缓存后分发

### 3.2 DDR3 存储与帧管理 (`sgl_ch_ddr_frame_top`)

| 项目 | 说明 |
|------|------|
| **数据总线** | DDR3 64bit（8片DDR3） |
| **地址位宽** | 15bit |
| **功能** | 多通道数据的帧格式存储、调度与分发 |
| **输入** | 9路写入：multif_top(ch0) + 8路PCIe DMA回读(ch1~8) |
| **输出** | 9路读出：PCIe DMA下发(ch0) + 8路DAC回放(ch1~8) |

**数据帧格式**：每帧包含 `sof`(帧头)、`eof`(帧尾)、`data`(512bit)、`len`(15bit长度)、`info`(8bit通道信息) 等信号。

**面试问答**：
- **Q: DDR3控制器的初始化信号在哪里？**
  A: `ddr_init_done` 信号指示DDR3 IP核初始化完成，拉高后方可正常访问。
- **Q: 输入和输出各用什么时钟？**
  A: 输入端9路均使用 `clk_100m`；输出端ch0用 `clk_100m`(送PCIe)，ch1~8用 `clk_50m`(送DAC宽度转换)。

### 3.3 LVDS接收模块 (`lvds_7k_top`)

| 项目 | 说明 |
|------|------|
| **通道数** | 2通道 ADC（每通道 16bit LVDS） |
| **LVDS对数** | 16对数据 + 2对时钟（差分） |
| **输出** | `ad_data`(2×16bit)、`ad_vld`(2bit)、`ad_clk` |
| **IDELAY** | 使用 `IDELAYCTRL` + `clk_200m` 进行位对齐校准（可通过CPU配置） |

**面试要点**：
- Kintex-7的LVDS接收需要使用 `IBUFDS` + `IDELAYE2` + `ISERDESE2` 原语链
- `clk_200m` 专供 `IDELAYCTRL` 使用，这是Xilinx 7系列硬性要求
- IDELAY tap值可通过CPU总线动态配置校准

### 3.4 JESD204B TX模块 (`jesd_tx_top`)

| 项目 | 说明 |
|------|------|
| **协议** | JESD204B 子类1 |
| **TX通道** | 4 lanes (GTX) |
| **数据通道** | 4路 32bit DAC数据（c0/c1对应通道0, c2/c3对应通道1） |
| **同步信号** | `tx_sync`(来自DAC)、`tx_sysref`(系统参考) |
| **核心时钟** | `tx_core_clk` (~93.33MHz)，由GTX参考时钟分频产生 |

**JESD204B链路建立流程**：
1. DAC芯片(AD9172)拉低 `SYNC~` 信号
2. FPGA发送 `/K28.5/ (K码)` 进行代码组同步(CGS)
3. DAC拉高 `SYNC~`，FPGA发送初始帧对齐序列(ILAS)
4. 进入正常数据传输

**面试问答**：
- **Q: da_dual_sync 是什么？**
  A: `da_dual_sync = sync0 & sync1`，两个DAC core的SYNC信号同时有效才表示链路建立成功。它还驱动 `DAC_division` PLL的复位——sync未建立时PLL被reset。
- **Q: 输入数据是怎么给的？**
  A: DUC输出 2×32bit → `width_conversion_S2B`(32→64) → `jesd_tx_top` 的4路32bit输入。c0/c1共用通道0的vld, c2/c3共用通道1的vld。

### 3.5 DDC/DUC算法模块 (`bhd_c720_ddc_duc_top`)

| 项目 | 说明 |
|------|------|
| **条件编译** | ``ifdef ALG_EN`` 控制是否使能 |
| **DDC输入** | 2通道 ADC数据（经过加噪后），16bit × 2 |
| **DDC输出** | 4通道 32bit下变频结果 |
| **DUC输入** | 8通道 32bit（来自DDR帧输出经宽度转换） |
| **DUC输出** | 2通道 32bit上变频结果 |
| **时钟** | ADC侧用 `ad_clk`，DAC侧用 `dac_double_clk`，CIB用 `clk_50m` |

**bypass模式**：当 `ALG_EN` 未定义时，DDC输出为0，DUC直通（`duc_dout = dac2alg_data`）。

**面试要点**：
- DDC（Digital Down Converter）将宽带信号下变频到基带，降低数据率
- DUC（Digital Up Converter）将基带信号上变频，恢复到射频频率
- 算法模块接收采样率 `samp_rate` 和时间戳 `stamp` 用于时频域对齐

### 3.6 数据复用模块 (`multif_top`)

| 项目 | 说明 |
|------|------|
| **输入** | 6通道 64bit 数据（2ch ADC原始 + 4ch DDC下变频结果） |
| **输出** | 1路 512bit帧数据 |
| **功能** | 将多路采集数据按帧格式打包，添加时间戳、采样率等信息 |
| **时钟** | 写入用 `ad_clk`(ADC侧)，处理用 `clk_100m`(系统侧)，读出用 `clk_100m` |

**面试要点**：
- 6路输入的 `info` 字段是 0~5 的通道编号，由 `generate` 自动赋值
- 输出帧包含 `sof/eof/data/len/info/end` 完整帧结构
- 实现了多通道数据到单通道帧流的汇聚

### 3.7 SPI控制器 (`spi_common`) ×7

共实例化 **7 个** SPI控制器，控制不同外设：

| 实例编号 | 目标芯片 | 功能 |
|----------|----------|------|
| spi[0] | AD9516 PLL | 采集子卡时钟PLL配置 |
| spi[1] | AD9467 Chip1 | ADC通道1寄存器配置 |
| spi[2] | AD9467 Chip2 | ADC通道2寄存器配置 |
| spi[3] | HMC7044 PLL | 回放子卡时钟PLL配置 |
| spi[4] | AD9172 DAC | DAC芯片寄存器配置 |
| spi[5] | ZD20E | 接收变频模块控制 |
| spi[6] | ZC18 | 发射变频模块控制 |

所有SPI控制器均运行在 `clk_100m`，使用 `hard_rst` 复位。

### 3.8 I2C控制器 (`i2c_master_top`) ×3

| 实例 | 连接 | 功能 |
|------|------|------|
| i2c_master | 主板 I2C | 温度传感器、EEPROM、授权码读取 |
| i2c_fmc0 | FMC RX子卡 | 采集子卡监控 |
| i2c_fmc1 | FMC TX子卡 | 回放子卡监控 |

**关键信号**：`authorize_code` 授权码由 I2C master 从EEPROM读取，用于IP核授权校验。

### 3.9 NOR Flash在线升级 (`mefc_top`)

| 项目 | 说明 |
|------|------|
| **Flash接口** | 并行NOR Flash，26bit地址，16bit数据 |
| **功能** | FPGA固件在线升级（擦除/编程/校验） |
| **数据来源** | PCIe DMA ch0 → DDR帧存储 → `pcie_to_mefc_patch` → `mefc_top` |
| **数据宽度转换** | 512bit → 16bit（通过 `pcie_to_mefc_patch` 移位分拆） |

**`pcie_to_mefc_patch` 工作原理**：
1. 握手接收一个 512bit 的 DDR3 输出数据
2. 通过移位寄存器将 512bit 分 32 次以 16bit 输出给 MEFC
3. 使用 `shift_data_cnt`(5bit) 计数，0~31 共 32 拍
4. 每输出完 32 个 16bit 数据后，拉高 ready 请求下一个 512bit

### 3.10 时间同步模块

#### 3.10.1 北斗定位/授时 (`bd_top`)
- 接收北斗卫星 UART 报文（`bd_rx`/`bd_tx`），解析 UTC 时间
- 接收北斗 PPS 脉冲（`bd_pps`），用于秒对齐
- 输出 RTC 时间：年/月/日/时/分/秒/毫秒/微秒/纳秒
- `bd_utc_chok` 指示UTC锁定状态

#### 3.10.2 GJB B码 (`gjb_btc_top`)
- 解码/编码 GJB B码时间信号（军标IRIG-B码）
- 接收 BTC 1PPS 脉冲（`btc_1pps`）
- 输出 RTC 时间：年/天/时/分/秒/毫秒/微秒/纳秒
- `bcode_chok` 指示B码锁定状态

#### 3.10.3 时间源选择逻辑

通过 `reserevd_2cfg[1:0]` 配置时间源选择：

| cfg[1] | cfg[0] | PPS源选择 | 时间源 |
|--------|--------|-----------|--------|
| 0 | 0 | B码 1PPS（or内部timing_1s回退） | B码时间 |
| 0 | 1 | 北斗 PPS（or内部timing_1s回退） | 北斗时间 |
| 1 | X | 内部 timing_1s | 按cfg[0]选北斗/B码 |

**PPS回退机制**：
- 当 `cfg[1]=0` 时：优先使用外部PPS。如果外部时间源已锁定（`chok=1`），使用其物理PPS脉冲上升沿；如果未锁定，回退使用 `timing_1s` 内部秒脉冲。
- 当 `cfg[1]=1` 时：强制使用内部 `timing_1s`（自由运行模式）。

**采样率测量**：`samp_cnt` 在每个PPS间隔内对 `ad_clk` 计数，PPS到来时锁存为 `samp_rate`，实现ADC采样率自动测量。

### 3.11 PPS检测模块 (`check_pps`) ×2

实例化两个独立的PPS检测器，分别检测北斗PPS和B码PPS的健康状态。

**工作原理**：
1. 检测PPS边沿变化 (`pps_r[2] ^ pps_r[1]`)
2. 用 `timing_1s` 内部秒脉冲计数（`timing_1s_cnt`）
3. 如果连续 3 个内部秒都没有检测到PPS变化，`check_err` 拉高报错
4. 一旦检测到PPS变化，计数器清零

### 3.12 BPF带通滤波器 (`bpf_top`)

- 对2通道ADC数据进行数字带通滤波
- 支持 bypass 模式（`reserevd_0cfg[6]`），bypass信号经3级寄存器同步到 `ad_clk` 域
- 在 `ad_clk` 域工作

### 3.13 加噪模块 (`add_noise_top`)

- 在滤波后的ADC数据上叠加数字噪声（用于仿真/测试）
- 双时钟域：`ad_clk`(数据侧) + `clk_100m`(CIB配置侧)
- 可通过CPU总线配置噪声参数

---

## 四、关键数据通路详解

### 4.1 采集通路（ADC → PCIe上传）

```
LVDS差分 → lvds_7k_top → 2×16bit@ad_clk
    → bpf_top(带通滤波) → 2×16bit
    → add_noise_top(加噪) → 2×16bit
    ├─► bit_convert(16→64) → 2×64bit@ad_clk (原始ADC数据)
    └─► ddc_duc_top(DDC下变频) → 4×32bit → bit_convert(32→64) → 4×64bit@ad_clk
         │
         └─► multif_top(6ch复用, 打包成帧) → 1×512bit@clk_100m
              → sgl_ch_ddr_frame_top(DDR3缓存)
              → pcie_app_gen3_belta(DMA上传) → 主机
```

### 4.2 回放通路（PCIe下发 → DAC输出）

```
主机 → pcie_app(DMA下发) → 1×512bit@clk_100m
    → sgl_ch_ddr_frame_top(DDR3缓存) → 8×512bit@clk_50m
    → width_conversion_B2S(512→32) → 8×32bit@dac_double_clk
    → ddc_duc_top(DUC上变频) → 2×32bit@dac_double_clk
    → width_conversion_S2B(32→64) → 2×64bit@dac_clk
    → jesd_tx_top(JESD204B TX) → 4-lane GTX → DAC(AD9172)
```

### 4.3 在线升级通路

```
主机 → pcie_app(DMA ch0) → 1×512bit@clk_100m
    → sgl_ch_ddr_frame_top(DDR3缓存) → 1×512bit@clk_100m
    → pcie_to_mefc_patch(512→16，移位分拆) → 16bit@clk_100m
    → mefc_top → NOR Flash(并行写入)
```

---

## 五、位宽转换模块详解

系统中大量使用位宽转换模块，是数据通路设计的核心技巧之一：

### 5.1 `bit_convert` — 无FIFO的纯同步位宽拼接

- **方向**：窄→宽（同时钟域内）
- **原理**：使用移位寄存器将连续的窄字拼接成宽字，计数器到达后输出
- **无反压**：没有ready反馈，假设下游始终能接收
- **用途**：ADC 16bit→64bit, DDC 32bit→64bit

### 5.2 `width_conversion_S2B` — 窄转宽（跨时钟域，带FIFO）

- **方向**：窄→宽（Small to Big）
- **原理**：输入侧先用移位寄存器拼接成宽字，再写入异步FIFO，输出侧直接读出
- **反压**：通过 `prog_full` 控制 `WC_in_rdy`
- **用途**：DUC输出 32bit→64bit（`dac_double_clk` → `dac_clk` 域）

### 5.3 `width_conversion_B2S` — 宽转窄（跨时钟域，双级FIFO）

- **方向**：宽→窄（Big to Small）
- **原理**：
  1. **第一级FIFO**（异步）：跨时钟域缓冲宽字
  2. **拆分逻辑**：读出宽字后移位分拆成多个窄字
  3. **第二级FIFO**（同步或异步）：缓冲拆分后的窄字数据
- **反压**：通过双级FIFO状态控制流量
- **用途**：DDR帧输出 512bit→32bit（`clk_50m` → `dac_double_clk` 域），8路并行实例

### 5.4 `asyn_fifo` — 自研异步FIFO

**核心设计**：
- 使用**格雷码**进行读写指针的跨时钟域同步（2级寄存器）
- 支持 `register` 和 `block` 两种RAM风格（通过参数选择）
- 提供 `prog_full`/`prog_empty` 可编程阈值
- **满判断**：写域中 `wbin - rbin_syn == 全1` → full
- **空判断**：读域中 `rbinnext == wbin_syn` → empty
- 格雷码↔二进制转换通过 `gray_to_bin` function 实现

**面试常见问题**：
- **Q: 为什么用格雷码？**  
  A: 格雷码相邻值只有1bit变化，多级寄存器同步时不会出现多bit同时变化导致的亚稳态传播问题。
- **Q: 满/空判断有什么区别？**  
  A: full在写时钟域判断（保守，可能"假满"不会"假空"）；empty在读时钟域判断（保守，可能"假空"不会"假满"）。都是安全的。

---

## 六、复位与告警系统

### 6.1 复位层次

```
sys_clk_wiz.locked ──(取反)──► hard_rst (时钟未就绪)
                                    │
                                    ├──► rst = hard_rst | soft_rst
                                    │                       ↑
                                    │         general_func_7s(CPU软复位)
                                    │
                                    └──► sys_rst = rst
```

| 复位信号 | 使用范围 | 说明 |
|----------|----------|------|
| `hard_rst` | 时钟IP、SPI、I2C、DDR | PLL未锁定时的全局硬复位 |
| `soft_rst` | 算法相关模块 | CPU可控的软复位 |
| `rst` (= hard\|soft) | 大多数模块 | 综合复位 |
| `sys_rst` (= rst) | 等同于rst | 别名 |

### 6.2 告警监测

通过 `general_func_7s` 管理两组当前告警和历史告警（各32bit × 2）：

**`reserved_cur_0alm`**（实时状态）：
- bit[0]: `pcie_link` — PCIe链路状态
- bit[1]: `ddr_init_done` — DDR3初始化完成
- bit[2~9]: `duc_din_rdy_x` — 8路DUC ready
- bit[10~11]: `dac2alg_data_vld` — DAC数据有效
- bit[12~13]: `btc_check_err` / `bd_check_err` — PPS错误
- bit[14~15]: `rx_zd20e_full_warm` — 变频器温度告警

**`reserved_cur_1alm`**：
- bit[0~7]: `fout_rdy` — 帧输出就绪
- bit[8~15]: `fout_vld` — 帧输出有效
- bit[16]: `locked_dac` — DAC时钟PLL锁定
- bit[17]: `bcode_chok` — B码锁定
- bit[18]: `bd_utc_chok` — 北斗UTC锁定
- bit[19]: `locked_ad` — ADC时钟PLL锁定

---

## 七、可配置功能与寄存器

通过 `general_func_7s` 的 `reserevd_Xcfg` 寄存器实现功能配置：

### `reserevd_0cfg` 功能位

| Bit | 功能 |
|-----|------|
| [0] | `fmc_ad_pll_pwr_ctrl` — 采集PLL电源控制 |
| [1] | `fmc_ad_pll_sel` — 采集PLL选择 |
| [2] | `pll_hmc7044_reset_pin` — 回放PLL复位 |
| [3] | `dac_ad9172_reset_pin` — DAC复位（取反） |
| [4] | MEFC ready bypass |
| [5] | Flash DMA ready bypass |
| [6] | BPF bypass（经3级同步到ad_clk域） |
| [7] | `rf_power_en` — 射频电源使能（取反） |

### `reserevd_2cfg` 功能位

| Bit | 功能 |
|-----|------|
| [0] | 时间源选择：1=北斗，0=B码 |
| [1] | PPS源模式：1=内部timing_1s，0=外部PPS |

### `reserevd_3cfg` 功能位

| Bit | 功能 |
|-----|------|
| [2] | `da_chn0_en` — DAC通道0使能（取反） |
| [3] | `da_chn1_en` — DAC通道1使能（取反） |
| [4] | `btc_rx_en` — B码接收使能 |
| [5] | `btc_1pps_en` — B码1PPS使能 |
| [13:6] | `cfg_rdy[7:0]` — 回放通道ready覆盖（经3级同步到dac_double_clk域） |

---

## 八、跨时钟域处理技术总结

| 场景 | 技术手段 | 实例 |
|------|----------|------|
| 单bit配置信号 | 多级寄存器同步（3级） | `bypass_en_r[2:0]`、`reserevd_*cfg_*r` |
| 多bit数据流 | 异步FIFO（格雷码指针同步） | `asyn_fifo` 在所有宽度转换模块中 |
| 时间戳同步 | 双寄存器打拍 | `stamp_1r` → `stamp_2r`（clk_100m→ad_clk） |
| PPS脉冲检测 | 3级寄存器+边沿检测 | `pp1s_r[2:0]`、`bd_pps_r[2:0]` |
| CPU总线跨域 | `cpu_process` 内部同步 | `cpu_alloc_32users` 为每个用户端口做跨域 |

---

## 九、高频面试问题与参考回答

### 9.1 项目整体类

**Q: 请简要介绍一下C720这个项目**  
A: C720是一个基于Kintex-7 FPGA的宽带信号采集与回放系统。采集侧通过LVDS接收双通道ADC数据，经过带通滤波、加噪、DDC下变频处理后，通过数据复用器打包成帧，缓存在DDR3中，再通过PCIe Gen3 x8上传到主机。回放侧则从PCIe接收数据，存入DDR3后分8路送DUC上变频，最终经JESD204B发送到DAC输出。系统支持北斗和GJB B码双时间源同步，以及NOR Flash在线固件升级。

**Q: 你在这个项目中负责什么？**  
A: 我主要负责[根据实际情况填写，参考以下方向]：顶层集成与模块例化、数据通路的位宽转换设计、时间同步选择逻辑、采集/回放通路的调试、SPI/I2C外设驱动。

### 9.2 接口协议类

**Q: JESD204B的建链过程是怎样的？子类1和子类2有什么区别？**  
A: JESD204B链路建立分三步：(1) CGS阶段，TX持续发K28.5码，RX检测到后拉高SYNC~；(2) ILAS阶段，TX发送4个多帧的初始帧对齐序列；(3) 数据传输阶段。子类1采用确定性延迟，SYSREF信号同时对齐TX和RX的本地多帧计数器，保证多设备同步；子类2不需要SYSREF，通过CGS和ILAS自动对齐。

**Q: PCIe的BAR空间和DMA是怎么实现的？**  
A: PCIe App模块将BAR空间映射到local bus，通过19bit地址和32bit数据进行寄存器读写。DMA使用自定义MDMA引擎，支持9路回读和1路下发通道，每路512bit宽度，具有标准的vld/rdy流控和sof/eof帧边界。

**Q: DDR3控制器使用的是什么？初始化需要注意什么？**  
A: 使用Xilinx MIG IP核生成的DDR3控制器，64bit数据宽度。初始化时需要等待 `init_done` 信号拉高后才能发起读写操作。同时需要提供 `clk_200m` 用于内部参考时钟，以及芯片温度（`device_temp`）用于温度补偿的ZQ校准。

### 9.3 FIFO与跨时钟域类

**Q: 你的异步FIFO是怎么设计的？**  
A: 使用格雷码指针跨时钟域同步方案。写指针在写时钟域转成格雷码，再通过两级寄存器同步到读时钟域进行空判断；反之亦然。满判断在写域完成（`wbin - rbin_syn == 全1`），空判断在读域完成（`rbinnext == wbin_syn`）。这种设计保证了安全性——满判断可能假满（保守），但不会假空导致溢出。

**Q: 格雷码同步为什么用2级寄存器？能不能用1级？**  
A: 异步信号跨时钟域至少需要2级寄存器来降低亚稳态概率到可接受水平。1级寄存器的亚稳态概率过高，不满足MTBF要求。更高要求的系统也可以用3级。格雷码的关键在于每次只有1bit变化，即使第一级寄存器采样到亚稳态，影响也仅限于这1bit，不会出现多bit同时不确定的情况。

**Q: 你的宽度转换为什么用双级FIFO？**  
A: `width_conversion_B2S`(宽→窄)用双级FIFO：第一级异步FIFO实现跨时钟域，第二级FIFO缓冲拆分后的窄字数据，平滑突发与连续数据之间的速率差异。如果只用一级FIFO直接拆分，在拆分期间无法接收新数据，会造成流控反压脉冲过于频繁。

### 9.4 信号处理类

**Q: DDC和DUC分别做什么？为什么需要？**  
A: DDC(数字下变频)将射频/中频信号搬移到基带并抽取降低数据率，减少后端处理和传输带宽压力。DUC(数字上变频)将基带信号插值并搬到射频/中频频率，驱动DAC输出。在C720中，ADC采样率较高，DDC将2路16bit原始数据降到4路32bit基带数据（抽取因子由算法配置决定）。

**Q: BPF带通滤波器的作用是什么？bypass怎么实现的？**  
A: BPF对ADC原始数据做带通滤波，滤除带外噪声和干扰，改善信噪比。bypass通过 `reserevd_0cfg[6]` 配置位控制，该信号从 `clk_100m` 域通过3级寄存器同步到 `ad_clk` 域（`bypass_en_r[2:0]`），取最高位作为BPF的bypass使能。

### 9.5 时间同步类

**Q: 北斗和B码时间怎么选择的？**  
A: 通过 `reserevd_2cfg[1:0]` 配置。`bit[0]` 选择时间数据来源（北斗 or B码），`bit[1]` 选择PPS脉冲模式（外部硬件PPS or 内部定时器）。时间数据和PPS脉冲是独立选择的——可以用北斗的时间数据但用内部PPS。

**Q: 采样率是怎么测量的？**  
A: 在 `ad_clk` 域维护一个32bit计数器 `samp_cnt`。每个PPS脉冲到来时，将当前计数值锁存为 `samp_rate`（即一秒内的ADC时钟周期数），然后计数器清零重新计数。这样就得到了ADC的精确采样率。

### 9.6 调试与工程类

**Q: 如何调试这个系统？用了哪些debug手段？**  
A: (1) 代码中大量使用 `(* mark_debug="true" *)` 标记关键信号，用Vivado ILA抓取；(2) 告警寄存器 `reserved_cur_Xalm` 实时反映各模块状态；(3) SPI/I2C可在线读取外设寄存器；(4) check_pps模块自动检测PPS信号健康状态。

**Q: 如果PCIe链路建不成功，你怎么排查？**  
A: (1) 先检查 `pcie_link` 状态位是否为0；(2) 用ILA抓 PCIe GT收发器的原始信号，确认物理层是否有信号；(3) 检查参考时钟 `pcie_clk_gt` 是否正常（IBUFDS_GTE2输出）；(4) 检查 `pcie_rst_n` 复位信号是否正确释放；(5) 检查PCIe IP核的配置（lane数、速率等）是否与板卡硬件匹配。

---

## 十、模块源文件清单

| 路径 | 模块/文件 | 功能 |
|------|-----------|------|
| `src/top/BHD_C720_top.v` | `bhd_c720_top` | 顶层模块 |
| `src/common/asyn_fifo.v` | `asyn_fifo` | 异步FIFO |
| `src/check_pps/check_pps.v` | `check_pps` | PPS健康检测 |
| `src/cpu_alloc/src/cpu_alloc_32users.v` | `cpu_alloc_32users` | CPU总线地址分配 |
| `src/cpu_alloc/src/cpu_process.v` | `cpu_process` | 单用户CPU总线处理 |
| `src/patch/bit_convert.v` | `bit_convert` | 位宽拼接（无FIFO） |
| `src/patch/width_conversion_B2S.v` | `width_conversion_B2S` | 宽→窄位宽转换 |
| `src/patch/width_conversion_S2B.v` | `width_conversion_S2B` | 窄→宽位宽转换 |
| `src/patch/pcie_to_mefc_patch.v` | `pcie_to_mefc_patch` | 512→16数据分拆 |
| `src/patch/ddr_duc_patch.v` | `ddr_duc_patch` | DDR→DUC数据适配 |
| `src/patch/assembly.v` | `assembly` | 数据组装/拆分 |
| `src/patch/bd_btc_select.v` | `bd_btc_select` | 时间源选择 |
| `netlist/mutlif/multif_top.dcp` | `multif_top` | 数据复用（网表） |
| `netlist/spi_common/spi_common.dcp` | `spi_common` | SPI控制器（网表） |
| `netlist/i2c/i2c_master_top.dcp` | `i2c_master_top` | I2C控制器（网表） |
| `netlist/common/general_func_7s.dcp` | `general_func_7s` | 通用功能/告警/定时 |
| `native_ip/` | Xilinx IP | DDR3 MIG, PCIe, JESD204B等 |

---

## 附录：关键参数速查

| 参数 | 值 |
|------|-----|
| FPGA | Kintex-7 |
| Logic ID | 441D_4337_3135 |
| Version | 1000 |
| 系统时钟 | 100MHz (来自差分100MHz输入) |
| PCIe | Gen3 × 8 lanes |
| DDR3 | 64bit × 1 rank |
| JESD204B | 4-lane TX |
| LVDS ADC | 2ch × 16bit |
| SPI控制器数量 | 7 |
| I2C控制器数量 | 3 |
| CPU地址空间 | 32个用户 × 256字节 |
| 时间精度 | 纳秒级 |
