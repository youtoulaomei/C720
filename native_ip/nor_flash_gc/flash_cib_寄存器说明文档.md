# Flash GC (Generic Controller) CIB 寄存器功能说明与排查手段

> 源文件: `flash_cib.v`  
> 模块名: `flash_cib`  
> 功能概述: 通用 Flash 控制器的配置接口模块，提供 Flash 操作命令控制和状态监控

---

## 一、寄存器总览

| 地址 | 宏定义 | 读写 | 功能简述 |
|------|--------|------|----------|
| 0x00 | FLASH_00 | R | 版本号 (VERSION) |
| 0x01 | FLASH_01 | R | 编译日期 {YEAR, MONTH, DAY} |
| 0x02 | FLASH_02 | R/W | 测试寄存器 (写入取反存储) |
| 0x10 | FLASH_10 | R | 告警状态: bit[8]=istart_opt_flash(回读), bit[1]=his_oexceed_max_time, bit[0]=his_oflag_wr_chk_err |
| 0x30 | FLASH_30 | R/W | 操作控制: bit[8]=istart_opt_flash, bit[4]=iwrite_done, bit[2:0]=iconfig_cmd |
| 0x31 | FLASH_31 | R/W | Flash 地址: bit[26:0]=iuser_adr |
| 0x32 | FLASH_32 | R/W | 读取字节数: bit[23:0]=ird_flash_num |
| 0x33 | FLASH_33 | R | 状态: bit[3]=fifo2_empty, bit[0]=oflash_rdy |

---

## 二、寄存器详细说明

### 2.1 FLASH_10 (0x10) - 告警状态寄存器
- **类型**: 只读（读清, alarm_history 机制）
- **位域**:
  - bit[8]: `istart_opt_flash` — 操作启动状态回读
  - bit[1]: `his_oexceed_max_time` — 超时告警历史（Flash 操作超过最大等待时间）
  - bit[0]: `his_oflag_wr_chk_err` — 写校验错误历史（写后校验不通过）
- **排查用途**:
  - **超时告警**: Flash 芯片响应异常、时钟异常或硬件连接问题
  - **写校验错误**: Flash 写入数据与期望不符，可能 Flash 损坏

### 2.2 FLASH_30 (0x30) - 操作控制寄存器
- **类型**: 读写
- **位域**:
  - bit[8]: `istart_opt_flash` — 写1启动 Flash 操作
  - bit[4]: `iwrite_done` — 写完成标志（CPU 通知控制器写数据已准备完毕）
  - bit[2:0]: `iconfig_cmd` — 操作命令类型
    - 典型值：读/写/擦除等命令编码
- **排查用途**: 确认操作命令配置正确

### 2.3 FLASH_31 (0x31) - Flash 地址
- **类型**: 读写
- **位域**: bit[26:0] = `iuser_adr`
- **作用**: 设置 Flash 操作的目标地址
- **排查用途**: 确认地址不越界

### 2.4 FLASH_32 (0x32) - 读取字节数
- **类型**: 读写
- **位域**: bit[23:0] = `ird_flash_num`
- **作用**: 设置 Flash 读操作的字节数
- **排查用途**: 确认读取长度正确

### 2.5 FLASH_33 (0x33) - 状态寄存器
- **类型**: 只读
- **位域**:
  - bit[3]: `fifo2_empty` — 数据 FIFO 空标志
  - bit[0]: `oflash_rdy` — Flash 控制器就绪（1=可接受新操作）
- **排查用途**: 
  - 操作前确认 oflash_rdy=1
  - 读操作完成后检查 fifo2_empty 确认数据已读完

---

## 三、问题排查手册

### 3.1 Flash 操作典型流程
```
1. 读 0x33 确认 bit[0]=1 (控制器就绪)
2. 写 0x31 配置目标地址
3. 写 0x32 配置读取字节数 (读操作)
4. 写 0x30 配置命令并启动操作
5. 轮询 0x33 等待 oflash_rdy=1
6. 读 0x10 检查是否有异常告警
```

### 3.2 Flash 操作超时
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 读告警 | 读 0x10 | bit[1]=1 确认超时 |
| 2. 检查 Flash 芯片 | 硬件测量 Flash CS/CLK | 信号正常 |
| 3. 检查供电 | 测量 Flash VCC | 电压正常 |
| 4. 检查连接 | 确认 Flash 焊接 | 无虚焊 |

### 3.3 Flash 写校验错误
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 读告警 | 读 0x10 | bit[0]=1 确认校验错 |
| 2. 确认先擦除 | 先执行擦除命令 | NOR Flash 写前必须擦除 |
| 3. 检查 Flash 寿命 | 确认擦写次数 | 未超过寿命限制 |
| 4. 更换 Flash | 排除芯片故障 | 新芯片操作正常 |

### 3.4 Flash 控制器不就绪
| 排查步骤 | 操作 | 预期结果 |
|----------|------|----------|
| 1. 读状态 | 读 0x33 | bit[0]=0 表示忙 |
| 2. 等待完成 | 持续轮询 0x33 | 操作完成后变1 |
| 3. 模块复位 | 上层 soft_rst | 状态恢复 |
