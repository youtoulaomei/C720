# PCIe Gen3 DMA CIB 寄存器功能说明与排查手段

> 源文件: `pcie_cib.v`  
> 模块名: `pcie_cib`  
> 功能概述: PCIe Gen3 DMA 引擎的配置接口模块，提供 DMA 通道管理、传输控制、链路状态监控、内建自测 (BIST)、FIFO 调度队列管理

---

## 一、寄存器总览

### 1.1 全局控制寄存器

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x00 | DMA_00 | R/W | 中断禁止: bit[16]=rdma_int_dis, bit[0]=wdma_int_dis |
| 0x01 | DMA_01 | R/W | 测试寄存器，复位值 0xBEEF_BEEF |
| 0x02 | DMA_02 | R/W | 软复位: bit[0]=soft_rst |
| 0x05 | DMA_05 | R/W | 停止控制: bit[16]=rdma_stop, bit[0]=wdma_stop |

### 1.2 PCIe 链路配置信息（只读）

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x0F | DMA_0F | R | 链路速率/宽度: bit[10:8]=cfg_current_speed, bit[3:0]=cfg_negotiated_width |
| 0x10 | DMA_10 | R | Max Read Req/Payload: bit[10:8]=cfg_max_read_req, bit[2:0]=cfg_max_payload |

### 1.3 DMA 状态/告警寄存器

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x12 | DMA_12 | R | FIFO 状态+溢出告警: rib/wdb/wib_empty, his_cfifo_overflow, trabt_err, his_wdb_underflow/overflow |
| 0x13 | DMA_13 | R | 通道运行状态: wchn_dvld, rfifo_empty, cfifo_empty, t_rchn/wchn_cur_st |
| 0x14 | DMA_14 | R | 错误历史告警(读清): rfifo_overflow/underflow, wchnindex_err, item_fifo_overflow/underflow, txfifo_abnormal, rc_fail/err, err_type/len/bar |

### 1.4 WDMA (写DMA) 通道管理

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x18 | DMA_18 | R/W | WITEM FIFO 复位: bit[0]=witem_rst |
| 0x20~0x22 | DMA_20~22 | R/W | 通道使能掩码: wchn_ena[95:0] |

### 1.5 RDMA (读DMA) 通道管理

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x19 | DMA_19 | R/W | RITEM FIFO 复位: bit[0]=ritem_rst |

### 1.6 带宽统计

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x28 | DMA_28 | R | TX 带宽计数: band[31:0] (Bytes/sec) |
| 0x29 | DMA_29 | R | RX 带宽计数: rx_band[31:0] (Bytes/sec) |

### 1.7 BIST (内建自测)

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x40 | DMA_40 | R/W | 自测通道使能: built_in[WPHY_NUM-1:0] |
| 0x41~0x42 | DMA_41~42 | R/W | 静态测试图案: ds_static_pattern[63:0]，复位值 0x5A5A5A5A |
| 0x43 | DMA_43 | R/W | 令牌桶宽度: ds_tbucket_width[21:0]，复位值 6442 |
| 0x44 | DMA_44 | R/W | 定长模式计数: ds_len_mode_count[31:0] |
| 0x45 | DMA_45 | R/W | 校验启动: bit[0]=check_st |
| 0x46 | DMA_46 | R/W | 数据模式: ds_data_mode[2:0]，复位值 1 |
| 0x47 | DMA_47 | R/W | 发送控制: bit[4]=ds_tx_len_start, bit[0]=ds_tx_con_start |
| 0x48 | DMA_48 | R/W | 令牌桶深度: ds_tbucket_deepth[21:0]，复位值 8512 |

### 1.8 DMA 调试统计

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x80 | DMA_80 | R | WCHN DMA 使能计数 |
| 0x81 | DMA_81 | R | WCHN DMA 完成计数 |
| 0x82 | DMA_82 | R/W | 通道启停状态: bit[1]=rchn_st, bit[0]=wchn_st |
| 0x83 | DMA_83 | R | RCHN 计数 (当前) |
| 0x84 | DMA_84 | R | RCHN 传输错误标志 |
| 0x85 | DMA_85 | R | RCHN 计数 (high 32bit) |
| 0x86 | DMA_86 | R | RCHN DMA 完成计数 |
| 0x87 | DMA_87 | R | 等待时间: wt_time[19:0] |
| 0x88 | DMA_88 | R | WITEM FIFO 读写指针 |
| 0x89 | DMA_89 | R | ORITEM FIFO 读写指针 |
| 0x8A | DMA_8A | R | 当前写通道索引: wchn_curr_index |
| 0x8B | DMA_8B | R | 写 DMA 使能状态 |
| 0x8C | DMA_8C | R | 读 DMA 使能状态 |
| 0x8D | DMA_8D | R | RITEM FIFO 空状态 |
| 0x8E | DMA_8E | R | RCHN DMA 使能计数 |
| 0x8F | DMA_8F | R | RG FIFO 读出计数 |
| 0x90 | DMA_90 | R | RITEM FIFO 写入计数 |
| 0x91 | DMA_91 | R | RITEM FIFO 读出计数 |

### 1.9 WITEM FIFO 队列 (写DMA 描述符)

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0xA0~0xA4 | DMA_A0~A4 | R/W | 写入数据 witem_wdata0~4 (160bit 描述符) |
| 0xA7 | DMA_A7 | R/W | WITEM 状态+写触发: fifo状态, bit[0]写1触发写入 |
| 0xA8~0xAC | DMA_A8~AC | R | 输出数据 owitem_rdata0~4 |
| 0xAF | DMA_AF | R/W | OWITEM 状态+读触发: bit[0]写1触发读出 |

### 1.10 RITEM FIFO 队列 (读DMA 描述符)

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0xB0~0xB4 | DMA_B0~B4 | R/W | 写入数据 ritem_wdata0~4 (160bit 描述符) |
| 0xB6 | DMA_B6 | R | RITEM FIFO 将满标志 |
| 0xB7 | DMA_B7 | R/W | RG FIFO 状态+写触发: bit[0]写1触发写入 |
| 0xB8~0xBC | DMA_B8~BC | R | 输出数据 oritem_rdata0~4 |
| 0xBF | DMA_BF | R/W | ORITEM 状态+读触发: bit[0]写1触发读出 |

---

## 二、关键寄存器详细说明

### 2.1 DMA_0F (0x0F) - PCIe 链路信息
- **位域**:
  - bit[10:8]: `cfg_current_speed` — 链路速率
    - 1 = Gen1 (2.5GT/s)
    - 2 = Gen2 (5.0GT/s)  
    - 3 = Gen3 (8.0GT/s)
  - bit[3:0]: `cfg_negotiated_width` — 协商链路宽度
    - 1=x1, 2=x2, 4=x4, 8=x8
- **排查核心**: 确认 PCIe 链路训练结果

### 2.2 DMA_10 (0x10) - 最大负载信息
- **位域**:
  - bit[10:8]: `cfg_max_read_req` — 最大读请求大小
  - bit[2:0]: `cfg_max_payload` — 最大负载大小
    - 0=128B, 1=256B, 2=512B, 3=1024B
- **作用**: 自动用于计算 wdma_tlp_size 和 rdma_tlp_size
- **TLP 大小映射**: payload=0→128B, payload=1→256B, payload≥2→256B(限制)

### 2.3 DMA_12 (0x12) - FIFO 状态告警
- **位域** (从高到低):
  - bit[24]: `rib_empty_r` — 读信息缓冲空
  - bit[20]: `wdb_empty_r` — 写数据缓冲空
  - bit[16]: `wib_empty_r` — 写信息缓冲空
  - bit[15:8]: `his_cfifo_overflow` — 命令 FIFO 溢出历史(8路)
  - bit[6:4]: `trabt_err_r` — 传输中止错误
  - bit[2]: `his_wdb_underflow` — 写数据缓冲下溢
  - bit[1]: `his_wib_overflow` — 写信息缓冲溢出
  - bit[0]: `his_wdb_overflow` — 写数据缓冲溢出
- **读清**: 历史告警位在读取 0x12 时更新

### 2.4 DMA_13 (0x13) - 通道运行时状态
- **位域**:
  - bit[31:24]: `wchn_dvld_r2` — 写通道数据有效(8路)
  - bit[23:16]: `rfifo_empty_r2` — 读通道 FIFO 空(8路)
  - bit[15:8]: `cfifo_empty_r2` — 命令 FIFO 空(8路)
  - bit[5:4]: `t_rchn_cur_st` — 读通道当前状态机
  - bit[1:0]: `t_wchn_cur_st` — 写通道当前状态机

### 2.5 DMA_14 (0x14) - 错误历史告警 (全局)
- **位域** (从高到低):
  - bit[17]: `his_rfifo_overflow` — 读 FIFO 溢出
  - bit[16]: `his_rfifo_underflow` — 读 FIFO 下溢
  - bit[13]: `his_wchnindex_err` — 写通道索引错误
  - bit[12]: `his_oritem_fifo_underflow`
  - bit[11]: `his_oritem_fifo_overflow`
  - bit[10]: `his_ritem_fifo_overflow` — 读描述符 FIFO 溢出
  - bit[9]: `his_rg_fifo_overflow` — RG FIFO 溢出
  - bit[8]: `his_owitem_fifo_underflow`
  - bit[7]: `his_owitem_fifo_overflow`
  - bit[6]: `his_witem_fifo_overflow` — 写描述符 FIFO 溢出
  - bit[5]: `his_txfifo_abnormal` — TX FIFO 异常复位
  - bit[4]: `his_rc_fail` — RC 响应失败
  - bit[3]: `his_rc_err` — RC 响应错误
  - bit[2]: `his_err_type` — TLP 类型错误
  - bit[1]: `his_err_len` — TLP 长度错误
  - bit[0]: `his_err_bar` — BAR 地址错误
- **读清**: 读取 0x14 后所有历史告警位重新开始捕获

### 2.6 WITEM 描述符队列 (0xA0~0xAF)
- **DMA_A0~A4**: 160bit 写 DMA 描述符（地址、长度、附加信息）
- **DMA_A7**: 写触发 + 状态
  - bit[6]: `witem_fifo_prog_empty` — FIFO 将空
  - bit[5]: `witem_fifo_full` — FIFO 满
  - bit[4]: `witem_fifo_empty` — FIFO 空
  - bit[0]: 写1 → `witem_wr_det` 触发描述符写入 FIFO
- **写描述符流程**:
  1. 写 0xA0~0xA4 填充描述符字段
  2. 写 0xA7 bit[0]=1 触发入队
  3. 检查 0xA7 bit[5] 确认 FIFO 未满

### 2.7 RITEM 描述符队列 (0xB0~0xBF)
- 结构与 WITEM 类似，用于读 DMA 描述符管理

---

## 三、问题排查手册

### 3.1 PCIe 链路建立检查
```
1. 读 0x0F → 确认 speed 和 width
   - Gen3 x8: speed=3, width=8
   - Gen3 x4: speed=3, width=4
2. 若 speed/width 低于预期:
   - 检查 PCIe 槽位拧紧
   - 确认 BIOS 中 PCIe Gen3 已使能
   - 检查信号完整性 (SI)
3. 读 0x10 → 确认 max_payload 和 max_read_req
```

### 3.2 DMA 传输不启动
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 检查软复位 | 读 0x02 | bit[0]=0 (未在复位) |
| 2. 检查停止位 | 读 0x05 | wdma_stop/rdma_stop=0 |
| 3. 检查通道使能掩码 | 读 0x20~0x22 | 对应通道 bit=1 |
| 4. 检查启停状态 | 读 0x82 | wchn_st/rchn_st 已启动 |
| 5. 描述符入队 | 检查 0xA7/0xB7 | FIFO 有内容 |

### 3.3 DMA 数据丢失
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 对比计数 | 读 0x80 vs 0x81 | en_cnt 应≥ done_cnt |
| 2. 检查 FIFO 溢出 | 读 0x12 | 无溢出/下溢告警 |
| 3. 检查错误告警 | 读 0x14 | 全部为0 |
| 4. 检查 RFIFO | 读 0x14 bit[17:16] | 无 overflow/underflow |
| 5. 检查 CFIFO | 读 0x12 bit[15:8] | 无 cfifo_overflow |
| 6. 检查传输错误 | 读 0x84 | rchn_terr=0 |
| 7. 检查状态机 | 读 0x13 bit[5:0] | 状态机在正常推进 |

### 3.4 RC 响应错误
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 读告警 | 读 0x14 bit[4:3] | his_rc_fail/err |
| 2. 读 BAR 错误 | 读 0x14 bit[0] | 确认 BAR 配置 |
| 3. 读长度错误 | 读 0x14 bit[1] | 确认 TLP 长度 |
| 4. 读类型错误 | 读 0x14 bit[2] | 确认 TLP 类型 |
| 5. 检查 RC 配置 | 主机侧 lspci | BAR 映射正确 |

### 3.5 TX FIFO 异常
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 读告警 | 读 0x14 bit[5] | his_txfifo_abnormal |
| 2. 检查带宽 | 读 0x28, 0x29 | 带宽合理 |
| 3. 检查链路 | 读 0x0F | 链路正常 |
| 4. 软复位 | 写 0x02=0x01 | 恢复 FIFO |

### 3.6 BIST 自测流程
```
1. 写 0x41~0x42 设置测试图案 (默认 0x5A5A_5A5A)
2. 写 0x46 设置数据模式 (默认 1)
3. 写 0x43 设置令牌桶宽度 (限速参数)
4. 写 0x48 设置令牌桶深度
5. 写 0x40 使能自测通道
6. 写 0x47 bit[0]=1 启动连续发送
   或 写 0x47 bit[4]=1 启动定长发送 (长度由 0x44 配置)
7. 写 0x45 bit[0]=1 启动校验
8. 读 0x28/0x29 观察带宽
```

### 3.7 描述符 FIFO 队列调试
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 写描述符 | 写 0xA0~A4 | 填充完整描述符 |
| 2. 入队 | 写 0xA7=0x01 | 描述符入 FIFO |
| 3. 检查 FIFO 状态 | 读 0xA7 | full=0, empty=0 |
| 4. 出队查看 | 写 0xAF=0x01 后读 0xA8~AC | 确认完成的描述符 |
| 5. FIFO 指针 | 读 0x88 | r/w cnt 正常推进 |
| 6. FIFO 复位 | 写 0x18=0x01 (w) 或 0x19=0x01 (r) | 清空 FIFO |
