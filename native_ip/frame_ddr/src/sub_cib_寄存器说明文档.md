# Frame DDR (sub_cib) 寄存器功能说明与排查手段

> 源文件: `sub_cib.v`  
> 模块名: `sub_cib`  
> 功能概述: 帧数据 DDR 缓存子模块的配置接口，提供 DDR 初始化状态、FIFO 状态监控、帧计数统计、水线配置等

---

## 一、寄存器总览

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x0 | SUB_0 | R/W | 控制: bit[1]=ctl_rst, bit[0]=soft_rst |
| 0x1 | SUB_1 | R | 当前状态: DDR 类型、授权、DDR 初始化、FIFO 状态 |
| 0x2 | SUB_2 | R | 历史告警(读清): FIFO 满/空、数据传输 FIFO 异常 |
| 0x3 | SUB_3 | R | 历史告警(读清): 信号有效性、帧错误 |
| 0x4 | SUB_4 | R | 输入 slot 计数 (读清, 周期计数) |
| 0x5 | SUB_5 | R | 输入 frame 计数 (读清, 周期计数) |
| 0x6 | SUB_6 | R | 输出 slot 计数 (读清, 周期计数) |
| 0x7 | SUB_7 | R | 输出 frame 计数 (读清, 周期计数) |
| 0x8 | SUB_8 | R | 帧 FIFO 当前水线 |
| 0x9 | SUB_9 | R/W | 帧 FIFO 水线下限，复位值=0x0F |
| 0xA | SUB_A | R/W | 帧 FIFO 水线上限，复位值=0xFFFFFFF0 |
| 0xB | SUB_B | R | CMD 数据校验计数 |

---

## 二、寄存器详细说明

### 2.1 SUB_0 (0x0) - 控制寄存器
- **类型**: 读写
- **位域**:
  - bit[1]: `ctl_rst` — 控制器复位
  - bit[0]: `soft_rst` — 软复位
- **排查用途**: 模块异常时可复位恢复

### 2.2 SUB_1 (0x1) - 当前状态寄存器
- **类型**: 只读（alarm_current 跨时钟域同步）
- **位域**:
  - bit[31:28]: `ddr_type` — DDR 类型标识（4bit）
  - bit[25]: `cur_authorize_succ` — 授权成功状态
  - bit[24]: `cur_ddr_init_done` — DDR 初始化完成
  - bit[17]: `cur_frame_ififo_afull` — 帧输入 FIFO 将满
  - bit[16]: `cur_frame_ififo_aempty` — 帧输入 FIFO 将空
  - bit[13]: `cur_pktinfo_fifo_full` — 包信息 FIFO 满
  - bit[12]: `cur_data_trans_fifo_full` — 数据传输 FIFO 满
  - bit[9]: `cur_frame_ififo_full` — 帧 FIFO 满
  - bit[8]: `cur_frame_ififo_empty` — 帧 FIFO 空
  - bit[5]: `cur_frag_o_full` — 输出分片 FIFO 满
  - bit[4]: `cur_frag_i_full` — 输入分片 FIFO 满
  - bit[1]: `cur_frag_o_empty` — 输出分片 FIFO 空
  - bit[0]: `cur_frag_i_empty` — 输入分片 FIFO 空
- **排查核心**: 最重要的状态寄存器

### 2.3 SUB_2 (0x2) - FIFO 历史告警
- **类型**: 只读（读清, alarm_history 机制）
- **位域**:
  - bit[17]: `his_frame_ififo_afull` — 帧 FIFO 将满历史
  - bit[16]: `his_frame_ififo_aempty` — 帧 FIFO 将空历史
  - bit[13]: `his_pktinfo_fifo_full` — 包信息 FIFO 满历史
  - bit[12]: `his_dtrans_fifo_full` — 数据传输 FIFO 满历史
  - bit[9]: `his_frame_ififo_full` — 帧 FIFO 满历史
  - bit[8]: `his_frame_ififo_empty` — 帧 FIFO 空历史
  - bit[5]: `his_frag_o_full` — 输出分片满历史
  - bit[4]: `his_frag_i_full` — 输入分片满历史
  - bit[1]: `his_frag_o_empty` — 输出分片空历史
  - bit[0]: `his_frag_i_empty` — 输入分片空历史
- **排查用途**: 诊断数据溢出/欠载位置

### 2.4 SUB_3 (0x3) - 信号告警
- **类型**: 只读（读清）
- **位域**:
  - bit[21]: `his_fout_rdy` — 输出 ready 历史
  - bit[20]: `his_fout_vld` — 输出 valid 历史
  - bit[17]: `his_fin_rdy` — 输入 ready 历史
  - bit[16]: `his_fin_vld` — 输入 valid 历史
  - bit[1]: `his_vld_err` — 有效性错误历史
  - bit[0]: `his_sof_eof_err` — SOF/EOF 帧边界错误历史
- **排查用途**: 诊断帧数据格式问题

### 2.5 SUB_4~7 - 帧/Slot 计数器
- **类型**: 只读（读清, 周期计数, cib_counter_32b 实现）
- **特点**: 跨时钟域计数，每次读取后自动清零重新开始计数
- **排查用途**: 
  - 比较输入输出计数判断是否丢帧
  - 输入帧数 ≠ 输出帧数 → 数据丢失或积压

### 2.6 SUB_8 (0x8) - 帧 FIFO 水线
- **类型**: 只读（alarm_current 同步）
- **位域**: [31:0] = `cur_frame_waterline`
- **作用**: 当前帧 FIFO 中的数据量
- **排查用途**: 
  - 水线过高（接近上限）→ 下游消费慢，有溢出风险
  - 水线为0 → 上游无数据或数据已全部消费

### 2.7 SUB_9/A (0x9, 0xA) - 水线阈值
- **SUB_9**: 水线下限，复位值=0x0F，触发将空告警
- **SUB_A**: 水线上限，复位值=0xFFFFFFF0，触发将满告警
- **排查用途**: 根据实际数据流量调整阈值

---

## 三、问题排查手册

### 3.1 DDR 未初始化
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 读状态 | 读 0x1 bit[24] | ddr_init_done=1 |
| 2. 检查 DDR 类型 | 读 0x1 bit[31:28] | 类型标识正确 |
| 3. 检查时钟 | 确认 DDR 参考时钟 | 频率正确 |
| 4. 复位重试 | 写 0x0=0x03, 再清零 | DDR 重新初始化 |

### 3.2 数据丢帧
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 对比帧计数 | 读 0x5 vs 0x7 | 输入=输出 |
| 2. 对比 slot 计数 | 读 0x4 vs 0x6 | 输入=输出 |
| 3. 检查 FIFO 告警 | 读 0x2 | 无满/空告警 |
| 4. 检查帧边界 | 读 0x3 | 无 sof_eof_err |
| 5. 检查水线 | 读 0x8 | 水线在合理范围 |

### 3.3 FIFO 溢出
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 定位溢出位置 | 读 0x2 逐位分析 | 确认哪个 FIFO |
| 2. frag_i_full | 输入分片满 | 检查 DDR 写入带宽 |
| 3. frag_o_full | 输出分片满 | 检查下游读取速度 |
| 4. frame_ififo_full | 帧FIFO满 | 检查 DDR 容量和配置 |
| 5. 调整水线阈值 | 写 0x9/0xA | 优化流控 |

### 3.4 数据有效性错误
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 读 vld_err | 读 0x3 bit[1] | 确认是否有错 |
| 2. 读 sof_eof_err | 读 0x3 bit[0] | 确认帧格式 |
| 3. 检查输入数据 | 确认数据源 SOF/EOF | 帧格式正确 |
| 4. 检查 cmd_data | 读 0xB | 校验计数合理 |
| 5. 检查 fin/fout 状态 | 读 0x3 bit[20:16] | valid/ready 活跃 |
