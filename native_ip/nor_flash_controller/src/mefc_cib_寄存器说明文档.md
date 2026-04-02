# NOR Flash Controller (MEFC) CIB 寄存器功能说明与排查手段

> 源文件: `mefc_cib.v`  
> 模块名: `mefc_cib`  
> 功能概述: NOR Flash 控制器配置接口模块，提供 Flash 擦除、读写控制和状态监控

---

## 一、寄存器总览

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x00 | MEFC_00 | R | 版本号 (VERSION) |
| 0x01 | MEFC_01 | R | 编译日期 {YEAR, MONTH, DAY} |
| 0x02 | MEFC_02 | R/W | 测试寄存器 (写入取反存储) |
| 0x04 | MEFC_04 | R/W | 全片擦除启动: bit[0]=ers_start |
| 0x05 | MEFC_05 | R/W | 写操作启动: bit[0]=wb_start |
| 0x06 | MEFC_06 | R/W | 写起始地址: bit[25:0]=wb_start_addr |
| 0x07 | MEFC_07 | R/W | 写字长度: bit[25:0]=wb_word_len |
| 0x08 | MEFC_08 | R/W | 读操作启动: bit[0]=rd_start |
| 0x09 | MEFC_09 | R/W | 读起始地址: bit[25:0]=rd_start_addr |
| 0x0A | MEFC_0A | R/W | 读字长度: bit[25:0]=rd_word_len |
| 0x0B | MEFC_0B | R/W | 扇区擦除使能: bit[0]=ers_sector_en |
| 0x0C | MEFC_0C | R/W | 扇区擦除地址: bit[9:0]=ers_sector_addr |
| 0x10 | MEFC_10 | R | 控制器空闲状态: bit[0]=cur_st_free |
| 0x11 | MEFC_11 | R | 操作完成告警(读清): bit[2]=alm_ers_reg_done, bit[1]=alm_rd_reg_done, bit[0]=alm_wb_reg_done |
| 0x12 | MEFC_12 | R | 操作失败告警(读清): bit[1]=alm_his_ers_fail, bit[0]=alm_his_wb_fail |
| 0x13 | MEFC_13 | R | 已写数据计数: bit[25:0]=cur_all_data_wcnt |
| 0x18 | MEFC_18 | R | FIFO 异常告警(读清): bit[1]=alm_his_rfifo_full, bit[0]=alm_his_wfifo_empty |
| 0x20 | MEFC_20 | R/W | 扩展功能: bit[4]=bit_order, bit[0]=r_sts_reg_en |
| 0x30 | MEFC_30 | R | 输入数据计数器: cnt_indata |

---

## 二、寄存器详细说明

### 2.1 MEFC_04 (0x04) - 全片擦除启动
- **类型**: 读写
- **位域**: bit[0] = `ers_start`
- **作用**: 写1触发 NOR Flash 全片擦除操作
- **注意**: 全片擦除耗时较长（通常数十秒），需通过 0x10 轮询等待完成

### 2.2 MEFC_05 (0x05) - 写操作启动
- **类型**: 读写
- **位域**: bit[0] = `wb_start`
- **作用**: 写1触发 Flash 写入操作
- **前提**: 需先配置 0x06（起始地址）和 0x07（写长度）

### 2.3 MEFC_06 / MEFC_07 - 写地址/长度配置
- **MEFC_06 bit[25:0]**: `wb_start_addr` — 写操作起始地址（字地址）
- **MEFC_07 bit[25:0]**: `wb_word_len` — 写操作字数
- **注意**: 地址和长度均以 Word (32bit) 为单位

### 2.4 MEFC_08~0x0A - 读操作配置
- **MEFC_08 bit[0]**: `rd_start` — 读操作启动
- **MEFC_09 bit[25:0]**: `rd_start_addr` — 读起始地址
- **MEFC_0A bit[25:0]**: `rd_word_len` — 读字长度

### 2.5 MEFC_0B / MEFC_0C - 扇区擦除
- **MEFC_0B bit[0]**: `ers_sector_en` — 扇区擦除使能（区别于全片擦除）
- **MEFC_0C bit[9:0]**: `ers_sector_addr` — 目标扇区地址（最多1024个扇区）
- **排查用途**: 使用扇区擦除代替全片擦除缩短操作时间

### 2.6 MEFC_10 (0x10) - 控制器空闲状态
- **类型**: 只读
- **位域**: bit[0] = `cur_st_free`
- **作用**: 1=控制器空闲可接受新命令，0=正在执行操作
- **排查用途**: 
  - 每次操作前需确认此位为1
  - 操作完成后此位应恢复为1

### 2.7 MEFC_11 (0x11) - 操作完成告警
- **类型**: 只读（读清）
- **位域**:
  - bit[2]: `alm_ers_reg_done` — 擦除完成标志
  - bit[1]: `alm_rd_reg_done` — 读完成标志
  - bit[0]: `alm_wb_reg_done` — 写完成标志
- **排查用途**: 轮询此寄存器确认操作是否完成

### 2.8 MEFC_12 (0x12) - 操作失败告警
- **类型**: 只读（读清）
- **位域**:
  - bit[1]: `alm_his_ers_fail` — 擦除失败历史
  - bit[0]: `alm_his_wb_fail` — 写失败历史
- **排查用途**: 
  - 擦除失败：Flash 可能损坏或写保护
  - 写失败：未先擦除或 Flash 寿命到期

### 2.9 MEFC_13 (0x13) - 写数据计数
- **类型**: 只读
- **位域**: bit[25:0] = `cur_all_data_wcnt`
- **作用**: 当前已写入的数据字数
- **排查用途**: 写操作进度监控

### 2.10 MEFC_18 (0x18) - FIFO 异常告警
- **类型**: 只读（读清）
- **位域**:
  - bit[1]: `alm_his_rfifo_full` — 读 FIFO 满历史（数据溢出）
  - bit[0]: `alm_his_wfifo_empty` — 写 FIFO 空历史（数据欠载）
- **排查用途**: 
  - rfifo_full：CPU 读取速度不够，读 FIFO 溢出
  - wfifo_empty：CPU 写入速度不够，Flash 控制器等待数据

### 2.11 MEFC_20 (0x20) - 扩展功能
- **类型**: 读写
- **复位值**: 0x00000011
- **位域**:
  - bit[4]: `bit_order` — 数据位序（1=MSB first, 0=LSB first），复位为1
  - bit[0]: `r_sts_reg_en` — 读状态寄存器使能，复位为1

### 2.12 MEFC_30 (0x30) - 输入数据计数器
- **类型**: 只读（读清，周期计数）
- **位域**: [31:0] = `cnt_indata`
- **作用**: 统计输入数据量，读后自动清零

---

## 三、问题排查手册

### 3.1 Flash 写操作典型流程
```
1. 读 0x10 确认 bit[0]=1 (空闲)
2. 写 0x06 配置写起始地址
3. 写 0x07 配置写字长度
4. 准备好写 FIFO 中的数据
5. 写 0x05 = 0x01 启动写操作
6. 轮询 0x10 等待 bit[0]=1 或轮询 0x11 等待 bit[0]=1
7. 读 0x12 检查是否有写失败
```

### 3.2 Flash 写操作失败
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 检查失败标志 | 读 0x12 | bit[0]=1 确认写失败 |
| 2. 检查 FIFO 状态 | 读 0x18 | 确认无 wfifo_empty |
| 3. 确认先擦除 | 先执行擦除操作 | NOR Flash 写前必须擦除 |
| 4. 确认写保护 | 检查硬件 WP 引脚 | WP 未接低 |
| 5. 检查地址范围 | 确认地址在有效范围 | 不越界 |

### 3.3 Flash 擦除失败
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 检查失败标志 | 读 0x12 | bit[1]=1 确认擦除失败 |
| 2. 使用扇区擦除 | 配置 0x0B, 0x0C | 缩小擦除范围 |
| 3. 等待足够时间 | 轮询 0x10 | 全片擦除可能需要数十秒 |

### 3.4 读操作数据异常
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 检查 FIFO 状态 | 读 0x18 | 无 rfifo_full 告警 |
| 2. 确认读长度 | 读 0x0A | 长度配置正确 |
| 3. 确认地址 | 读 0x09 | 地址指向有效区域 |
| 4. 检查位序 | 读 0x20 bit[4] | 与数据格式匹配 |
| 5. 写后验证 | 写完后读回对比 | 确认 Flash 存储正确 |
