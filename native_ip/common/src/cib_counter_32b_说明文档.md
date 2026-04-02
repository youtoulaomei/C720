# CIB Counter 32b 通用计数器模块说明

> 源文件: `cib_counter_32b.v`  
> 模块名: `cib_counter_32b`  
> 功能概述: 通用32位跨时钟域计数器，被各 CIB 模块广泛实例化用于统计信号变化、数据吞吐量等

---

## 一、功能概述

本模块是一个可复用的 32 位计数器组件，具备以下特性:
- **跨时钟域**: 源信号在 `src_clk` 域产生，计数值在 `cpu_clk` 域读取
- **两种计数模式**: 周期计数（cycle）和非周期计数（non-cycle）
- **读清机制**: 读取后自动清零，开始新一轮统计
- **地址匹配**: 仅在 CPU 读取到本计数器地址时响应

---

## 二、参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| U_DLY | 1 | 仿真延迟 |
| ADDR_WIDTH | 7 | CPU 地址宽度 |
| CNT_ADDR | 7'h00 | 本计数器的寄存器地址 |
| CNT_CYCLE | 0 | 0=非周期计数, 1=周期计数 |
| SRC_WIDTH | 32 | 源计数值位宽 |

---

## 三、工作模式

### 3.1 非周期计数 (CNT_CYCLE=0)
- 源信号 `src_cnt[31:0]` 直接反映当前计数值
- CPU 读取时锁定当前值
- 读取后源计数器**不会**被自动清零
- 适用于: 累计计数、状态值读取

### 3.2 周期计数 (CNT_CYCLE=1)
- 源信号 `src_cnt` 为脉冲计数使能
- 模块内部维护 32bit 累加计数器
- CPU 读取时:
  1. 锁定当前计数值供 CPU 读取
  2. **自动清零**内部计数器开始新一轮统计
- 适用于: 吞吐量统计、频率测量、事件计数

---

## 四、跨时钟域处理

```
src_clk domain          cpu_clk domain
    │                       │
    │  src_cnt ──[同步]──►  lock_value ──► cpu_rdata
    │                       │
    │ <──[同步]── rd_pulse   │ ◄── cpu_read_en
```

- 使用两级同步器处理读触发信号的跨时钟域传递
- 计数值通过锁存实现安全传递
- 延迟约 2~3 个 cpu_clk 周期

---

## 五、接口说明

| 端口 | 方向 | 说明 |
|------|------|------|
| src_clk | input | 源时钟域 |
| rst | input | 复位 |
| src_cnt | input [SRC_WIDTH-1:0] | 源计数值 / 计数使能 |
| cpu_clk | input | CPU 时钟域 |
| cpu_read_en | input | CPU 读使能 |
| cpu_addr | input | CPU 地址 |
| cpu_rdata | output [31:0] | CPU 读数据 |

---

## 六、典型实例化

```verilog
cib_counter_32b #(
    .U_DLY       (U_DLY      ),
    .ADDR_WIDTH  (7           ),
    .CNT_ADDR    (7'h04       ),  // 寄存器地址 0x04
    .CNT_CYCLE   (1           )   // 周期计数模式
) u_slot_in_cnt (
    .rst         (rst         ),
    .src_clk     (data_clk    ),
    .src_cnt     (slot_in_en  ),  // 每个 slot 脉冲计数一次
    .cpu_clk     (cpu_clk     ),
    .cpu_read_en (cpu_read_en ),
    .cpu_addr    (cpu_addr    ),
    .cpu_rdata   (cnt_slot_in )   // 读出一个统计周期内的 slot 数
);
```

---

## 七、排查要点

### 计数值始终为0
1. 检查 `src_cnt` 信号是否有有效脉冲/值
2. 确认 `CNT_CYCLE` 参数是否正确选择
3. 确认 `CNT_ADDR` 地址与实际读取地址匹配

### 计数值不合理
1. 周期模式下: 检查两次读取间隔是否合理
2. 非周期模式下: 检查源计数器逻辑
3. 确认跨时钟域信号是否存在毛刺

### 应用场景参考
- `sub_cib.v` 中用于统计 slot/frame 输入输出数量
- 各模块中用于带宽统计、事件计数
