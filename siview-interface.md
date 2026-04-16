# SiView 风格 MES 接口设计文档

> **文档定位**: 定义仿真系统与 MES 之间的接口规范，采用 IBM SiView 风格的数据格式和交互模式  
> **版本**: v1.0  
> **日期**: 2024-04-15  
> **协议基础**: SECS/GEM + REST API 映射

---

## 1. 设计原则

### 1.1 SiView 接口风格特征

IBM SiView 作为半导体行业主流 MES 系统，其接口设计具有以下特征：

| 特征 | 说明 | 本系统实现 |
|-----|------|-----------|
| **事件驱动** | 设备状态变化触发事件上报 | WebSocket 实时推送 |
| **标准化消息** | 基于 SECS-II 消息格式 | JSON 格式映射 SECS Stream/Function |
| **分层架构** | 物理层/控制层/数据层分离 | REST API + WebSocket 分层 |
| **状态机严谨** | 设备状态转换有明确定义 | 完整的 Control State + Process State |
| **配方管理** | PPID 全生命周期管理 | Recipe 下载/上传/验证 |
| **数据变量** | SV/EC 分离，支持实时采集 | Status Variable + Equipment Constant |

### 1.2 接口分层设计

```
┌─────────────────────────────────────────────────────────────────┐
│                      MES (SiView 风格)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Layer 3: 业务逻辑层 (Business Logic)                      │  │
│  │  • 工单管理 (Lot Management)                               │  │
│  │  • 设备调度 (Equipment Dispatch)                           │  │
│  │  • WIP 追溯 (WIP Tracking)                                │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            │ HTTP REST API                     │
│  ┌─────────────────────────▼─────────────────────────────────┐  │
│  │  Layer 2: 设备控制层 (Equipment Control - GEM)              │  │
│  │  • S2F41 远程指令 (Host Command)                           │  │
│  │  • S6F11 事件上报 (Event Report)                           │  │
│  │  • S7F3/F5 配方管理 (PPID Download/Upload)                 │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            │ WebSocket + REST                   │
│  ┌─────────────────────────▼─────────────────────────────────┐  │
│  │  Layer 1: 数据采集层 (Data Collection - SECS)               │  │
│  │  • S1F3/S1F4 状态变量 (Status Variable)                    │  │
│  │  • S2F13/S2F14 设备常量 (Equipment Constant)               │  │
│  │  • S1F1/S1F2 通信确认 (Are You Online)                     │  │
│  └─────────────────────────┬─────────────────────────────────┘  │
│                            │                                    │
└────────────────────────────┼────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                     仿真系统 (EAP 层)                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  • 设备状态机模拟                                          │  │
│  │  • SECS 消息转换                                           │  │
│  │  • 事件触发与上报                                          │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. 核心消息定义

### 2.1 Stream 1 - 设备状态 (Equipment Status)

#### S1F1 - Are You Online? (通信建立)

**MES → 仿真系统 (查询)**
```json
{
  "stream_function": "S1F1",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A2B3",
    "timestamp": "2024-01-15T08:00:00Z"
  }
}
```

**仿真系统 → MES (响应)**
```json
{
  "stream_function": "S1F2",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A2B3",
    "timestamp": "2024-01-15T08:00:00.050Z"
  },
  "body": {
    "online": true,
    "communication_state": "COMMUNICATING",
    "model_type": "FAB_SIM_EQUIPMENT",
    "software_version": "v0.1.0"
  }
}
```

#### S1F3/S1F4 - Selected Equipment Status (状态变量查询)

**MES → 仿真系统 (查询)**
```json
{
  "stream_function": "S1F3",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A2C4",
    "timestamp": "2024-01-15T08:05:00Z"
  },
  "body": {
    "svid_list": [1, 2, 3, 4, 5, 6]
  }
}
```

**仿真系统 → MES (响应)**
```json
{
  "stream_function": "S1F4",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A2C4",
    "timestamp": "2024-01-15T08:05:00.080Z"
  },
  "body": {
    "sv_count": 6,
    "status_variables": [
      {
        "svid": 1,
        "sv_name": "ControlState",
        "sv_value": "REMOTE",
        "sv_type": "ASCII",
        "units": ""
      },
      {
        "svid": 2,
        "sv_name": "ProcessState",
        "sv_value": "PROCESSING",
        "sv_type": "ASCII",
        "units": ""
      },
      {
        "svid": 3,
        "sv_name": "CurrentLotID",
        "sv_value": "LOT2024001",
        "sv_type": "ASCII",
        "units": ""
      },
      {
        "svid": 4,
        "sv_name": "CurrentPPID",
        "sv_value": "DEP_100NM_STD",
        "sv_type": "ASCII",
        "units": ""
      },
      {
        "svid": 5,
        "sv_name": "ProcessStartTime",
        "sv_value": "2024-01-15T08:00:00Z",
        "sv_type": "ASCII",
        "units": "ISO8601"
      },
      {
        "svid": 6,
        "sv_name": "ProcessElapsedTime",
        "sv_value": 300,
        "sv_type": "U4",
        "units": "seconds"
      }
    ]
  }
}
```

**预定义 Status Variables (SV)**

| SVID | 名称 | 类型 | 说明 |
|------|------|------|------|
| 1 | ControlState | ASCII | 控制状态: OFFLINE/LOCAL/REMOTE |
| 2 | ProcessState | ASCII | 加工状态: IDLE/SETUP/PROCESSING/COMPLETE |
| 3 | CurrentLotID | ASCII | 当前批次ID |
| 4 | CurrentPPID | ASCII | 当前配方ID |
| 5 | ProcessStartTime | ASCII | 加工开始时间 (ISO8601) |
| 6 | ProcessElapsedTime | U4 | 已加工时间 (秒) |
| 7 | EquipmentStatus | ASCII | 设备状态: UP/DOWN/MAINTENANCE |
| 8 | AlarmCount | U4 | 当前告警数量 |
| 9 | CurrentStep | U4 | 当前工艺步骤 |
| 10 | TotalSteps | U4 | 总工艺步骤 |

---

### 2.2 Stream 2 - 设备控制与配置 (Equipment Control)

#### S2F13/S2F14 - Equipment Constants (设备常量查询/设置)

**MES → 仿真系统 (查询 EC)**
```json
{
  "stream_function": "S2F13",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A3D5",
    "timestamp": "2024-01-15T08:10:00Z"
  },
  "body": {
    "ecid_list": [1, 2]
  }
}
```

**仿真系统 → MES (响应)**
```json
{
  "stream_function": "S2F14",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A3D5",
    "timestamp": "2024-01-15T08:10:00.060Z"
  },
  "body": {
    "ec_count": 2,
    "equipment_constants": [
      {
        "ecid": 1,
        "ec_name": "MaxProcessTime",
        "ec_value": 3600,
        "ec_type": "U4",
        "units": "seconds",
        "min_value": 60,
        "max_value": 7200,
        "default_value": 3600
      },
      {
        "ecid": 2,
        "ec_name": "IdleTimeout",
        "ec_value": 300,
        "ec_type": "U4",
        "units": "seconds",
        "min_value": 60,
        "max_value": 600,
        "default_value": 300
      }
    ]
  }
}
```

**MES → 仿真系统 (设置 EC)**
```json
{
  "stream_function": "S2F15",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A3E6",
    "timestamp": "2024-01-15T08:15:00Z"
  },
  "body": {
    "equipment_constants": [
      {
        "ecid": 1,
        "ec_value": 4000
      }
    ]
  }
}
```

**仿真系统 → MES (确认)**
```json
{
  "stream_function": "S2F16",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A3E6",
    "timestamp": "2024-01-15T08:15:00.040Z"
  },
  "body": {
    "eac": 0,
    "eac_description": "OK"
  }
}
```

**预定义 Equipment Constants (EC)**

| ECID | 名称 | 类型 | 默认值 | 范围 | 说明 |
|------|------|------|--------|------|------|
| 1 | MaxProcessTime | U4 | 3600 | 60-7200 | 最大加工时间(秒) |
| 2 | IdleTimeout | U4 | 300 | 60-600 | 空闲超时时间(秒) |
| 3 | AutoReportEnabled | BOOLEAN | true | - | 自动事件上报开关 |
| 4 | DataSampleRate | U4 | 1000 | 100-10000 | 数据采集间隔(ms) |
| 5 | AlarmHistorySize | U4 | 100 | 10-1000 | 告警历史记录数 |

#### S2F17/S2F18 - Date and Time (时间同步)

**MES → 仿真系统**
```json
{
  "stream_function": "S2F17",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A4F7",
    "timestamp": "2024-01-15T08:20:00Z"
  },
  "body": {
    "time": "2024-01-15T08:20:00.000Z"
  }
}
```

**仿真系统 → MES**
```json
{
  "stream_function": "S2F18",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A4F7",
    "timestamp": "2024-01-15T08:20:00.030Z"
  },
  "body": {
    "time": "2024-01-15T08:20:00.030Z",
    "time_sync_status": "SYNCED"
  }
}
```

#### S2F33/S2F34 - Define Report (报告定义)

**MES → 仿真系统 (定义报告)**
```json
{
  "stream_function": "S2F33",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A508",
    "timestamp": "2024-01-15T08:25:00Z"
  },
  "body": {
    "report_list": [
      {
        "rptid": 2001,
        "variable_list": [
          {"vid": 1, "name": "ControlState"},
          {"vid": 2, "name": "ProcessState"}
        ]
      },
      {
        "rptid": 2012,
        "variable_list": [
          {"vid": 1, "name": "ControlState"},
          {"vid": 2, "name": "ProcessState"},
          {"vid": 3, "name": "CurrentLotID"},
          {"vid": 4, "name": "CurrentPPID"},
          {"vid": 5, "name": "ProcessStartTime"}
        ]
      }
    ]
  }
}
```

**仿真系统 → MES (确认)**
```json
{
  "stream_function": "S2F34",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A508",
    "timestamp": "2024-01-15T08:25:00.050Z"
  },
  "body": {
    "drack": 0,
    "drack_description": "OK"
  }
}
```

#### S2F35/S2F36 - Link Event Report (事件与报告关联)

**MES → 仿真系统 (关联事件与报告)**
```json
{
  "stream_function": "S2F35",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A619",
    "timestamp": "2024-01-15T08:30:00Z"
  },
  "body": {
    "link_list": [
      {
        "ceid": 1012,
        "report_list": [
          {"rptid": 2012}
        ]
      },
      {
        "ceid": 1013,
        "report_list": [
          {"rptid": 2013}
        ]
      }
    ]
  }
}
```

**仿真系统 → MES (确认)**
```json
{
  "stream_function": "S2F36",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A619",
    "timestamp": "2024-01-15T08:30:00.050Z"
  },
  "body": {
    "lrack": 0,
    "lrack_description": "OK"
  }
}
```

#### S2F37/S2F38 - Enable/Disable Event (事件启用/禁用)

**MES → 仿真系统**
```json
{
  "stream_function": "S2F37",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A72A",
    "timestamp": "2024-01-15T08:35:00Z"
  },
  "body": {
    "ceed": true,
    "ceid_list": [1012, 1013]
  }
}
```

**仿真系统 → MES**
```json
{
  "stream_function": "S2F38",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A72A",
    "timestamp": "2024-01-15T08:35:00.040Z"
  },
  "body": {
    "erack": 0,
    "erack_description": "OK"
  }
}
```

#### S2F41/S2F42 - Host Command (远程控制指令)

**MES → 仿真系统 (指令下发)**
```json
{
  "stream_function": "S2F41",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A83B",
    "timestamp": "2024-01-15T08:40:00Z"
  },
  "body": {
    "rcmd": "START",
    "cp_count": 2,
    "command_parameters": [
      {
        "cpname": "LotID",
        "cpval": "LOT2024001"
      },
      {
        "cpname": "PPID",
        "cpval": "DEP_100NM_STD"
      }
    ]
  }
}
```

**仿真系统 → MES (执行确认)**
```json
{
  "stream_function": "S2F42",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A83B",
    "timestamp": "2024-01-15T08:40:00.120Z"
  },
  "body": {
    "hcack": 0,
    "hcack_description": "OK",
    "cp_reply": []
  }
}
```

**Host Command 定义**

| RCMD | 说明 | 必需参数 | 执行条件 |
|------|------|---------|---------|
| START | 开始加工 | LotID, PPID | ControlState=REMOTE, ProcessState=IDLE |
| STOP | 停止加工 | - | ProcessState=PROCESSING |
| PAUSE | 暂停 | - | ProcessState=PROCESSING |
| RESUME | 恢复 | - | ProcessState=PAUSED |
| ABORT | 终止 | - | ProcessState≠IDLE |
| LOCAL | 切换到本地模式 | - | 无 |
| REMOTE | 切换到远程模式 | - | 无 |

**HCACK (Host Command Acknowledge) 代码**

| 代码 | 名称 | 说明 |
|------|------|------|
| 0 | OK | 指令已接受并执行 |
| 1 | InvalidCommand | 无效指令 |
| 2 | CannotPerformNow | 当前状态无法执行 |
| 3 | InvalidParameter | 参数无效 |
| 4 | EquipmentBusy | 设备繁忙 |
| 5 | EquipmentOffline | 设备离线 |

---

### 2.3 Stream 6 - 事件上报 (Event Data Collection)

#### S6F11/S6F12 - Event Report (事件报告)

**仿真系统 → MES (主动上报)**
```json
{
  "stream_function": "S6F11",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A94C",
    "timestamp": "2024-01-15T08:45:00Z"
  },
  "body": {
    "ceid": 1012,
    "ce_name": "ProcessingStarted",
    "report_count": 1,
    "reports": [
      {
        "rptid": 2012,
        "variable_count": 5,
        "variables": [
          {"vid": 1, "vname": "ControlState", "vvalue": "REMOTE"},
          {"vid": 2, "vname": "ProcessState", "vvalue": "PROCESSING"},
          {"vid": 3, "vname": "CurrentLotID", "vvalue": "LOT2024001"},
          {"vid": 4, "vname": "CurrentPPID", "vvalue": "DEP_100NM_STD"},
          {"vid": 5, "vname": "ProcessStartTime", "vvalue": "2024-01-15T08:45:00Z"}
        ]
      }
    ]
  }
}
```

**MES → 仿真系统 (确认)**
```json
{
  "stream_function": "S6F12",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001A94C",
    "timestamp": "2024-01-15T08:45:00.020Z"
  },
  "body": {
    "ackc6": 0,
    "ackc6_description": "OK"
  }
}
```

**预定义 Collection Events (CE)**

| CEID | 名称 | 触发时机 | 关联报告 (RPTID) |
|------|------|---------|-----------------|
| 1001 | ControlStateChanged | 控制状态变化 | 2001 |
| 1002 | ProcessingStateChanged | 加工状态变化 | 2002 |
| 1011 | LotArrived | 批次到达设备 | 2011 |
| 1012 | ProcessingStarted | 开始加工 | 2012 |
| 1013 | ProcessingCompleted | 加工完成 | 2013 |
| 1014 | LotDeparted | 批次离开设备 | 2014 |
| 1021 | AlarmSet | 告警产生 | 2021 |
| 1022 | AlarmCleared | 告警清除 | 2022 |
| 1031 | BankLotArrived | 批次到达Bank | 2031 |
| 1032 | BankLotDeparted | 批次离开Bank | 2032 |
| 1033 | BankDispatchConfirmed | Bank派工确认 | 2033 |

---

### 2.4 Stream 7 - 工艺程序管理 (Process Program)

#### S7F1/S7F2 - PPID Request (配方列表查询)

**MES → 仿真系统**
```json
{
  "stream_function": "S7F1",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001AA5D",
    "timestamp": "2024-01-15T08:50:00Z"
  }
}
```

**仿真系统 → MES**
```json
{
  "stream_function": "S7F2",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001AA5D",
    "timestamp": "2024-01-15T08:50:00.070Z"
  },
  "body": {
    "ppid_count": 3,
    "ppid_list": [
      {"ppid": "DEP_100NM_STD", "description": "100nm沉积标准配方"},
      {"ppid": "DEP_50NM_FAST", "description": "50nm沉积快速配方"},
      {"ppid": "DEP_200NM_SLOW", "description": "200nm沉积慢速配方"}
    ]
  }
}
```

#### S7F3/S7F4 - PPID Download (配方下载到设备)

**MES → 仿真系统**
```json
{
  "stream_function": "S7F3",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001AB6E",
    "timestamp": "2024-01-15T08:55:00Z"
  },
  "body": {
    "ppid": "DEP_100NM_STD",
    "recipe_data": {
      "format": "JSON",
      "content": {
        "thickness_nm": 100,
        "temperature_c": 300,
        "pressure_pa": 50,
        "duration_sec": 1800,
        "gas_flows": {
          "SiH4": 100,
          "N2": 500
        },
        "ramp_rate": 5,
        "stabilization_time": 60
      }
    }
  }
}
```

**仿真系统 → MES (确认)**
```json
{
  "stream_function": "S7F4",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001AB6E",
    "timestamp": "2024-01-15T08:55:00.150Z"
  },
  "body": {
    "ackc7": 0,
    "ackc7_description": "OK"
  }
}
```

**ACKC7 代码**

| 代码 | 名称 | 说明 |
|------|------|------|
| 0 | OK | 配方下载成功 |
| 1 | InvalidPPID | 无效的PPID |
| 2 | InvalidFormat | 配方格式错误 |
| 3 | InvalidParameter | 参数值超出范围 |
| 4 | EquipmentBusy | 设备繁忙，无法接收 |
| 5 | MemoryFull | 设备存储空间不足 |

#### S7F5/S7F6 - PPID Upload (配方上传到MES)

**MES → 仿真系统**
```json
{
  "stream_function": "S7F5",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001AC7F",
    "timestamp": "2024-01-15T09:00:00Z"
  },
  "body": {
    "ppid": "DEP_100NM_STD"
  }
}
```

**仿真系统 → MES**
```json
{
  "stream_function": "S7F6",
  "header": {
    "device_id": "EQ001",
    "system_bytes": "0x0001AC7F",
    "timestamp": "2024-01-15T09:00:00.100Z"
  },
  "body": {
    "ppid": "DEP_100NM_STD",
    "recipe_data": {
      "format": "JSON",
      "content": {
        "thickness_nm": 100,
        "temperature_c": 300,
        "pressure_pa": 50,
        "duration_sec": 1800,
        "gas_flows": {
          "SiH4": 100,
          "N2": 500
        }
      }
    }
  }
}
```

---

## 3. REST API 端点定义

### 3.1 设备管理接口

#### 获取设备列表
```
GET /api/v1/equipment
```

**响应**
```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "count": 6,
    "equipment": [
      {
        "equipment_id": "EQ001",
        "equipment_type": "DEPOSITION",
        "area_id": "AREA_DEP_01",
        "status": "RUNNING",
        "control_state": "REMOTE",
        "process_state": "PROCESSING",
        "current_lot": "LOT2024001"
      }
    ]
  }
}
```

#### 获取设备详情
```
GET /api/v1/equipment/{equipment_id}
```

**响应**
```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "equipment_id": "EQ001",
    "equipment_type": "DEPOSITION",
    "equipment_name": "沉积站-01",
    "area_id": "AREA_DEP_01",
    "work_area_id": "WA_DAY_SHIFT",
    "status": "RUNNING",
    "control_state": "REMOTE",
    "process_state": "PROCESSING",
    "current_lot": "LOT2024001",
    "current_ppid": "DEP_100NM_STD",
    "input_bank": "BK_D1_IN",
    "output_bank": "BK_D1_OUT",
    "upstream": ["C1"],
    "downstream": ["L1"]
  }
}
```

#### 发送远程指令
```
POST /api/v1/equipment/{equipment_id}/command
```

**请求体**
```json
{
  "command": "START",
  "parameters": {
    "LotID": "LOT2024001",
    "PPID": "DEP_100NM_STD"
  }
}
```

**响应**
```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "command_id": "CMD2024001001",
    "status": "ACCEPTED",
    "executed_at": "2024-01-15T09:05:00Z"
  }
}
```

### 3.2 Bank 管理接口

#### 获取 Bank 列表
```
GET /api/v1/banks
```

**响应**
```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "count": 12,
    "banks": [
      {
        "bank_id": "BK_D1_IN",
        "bank_name": "沉积站-入口",
        "bank_type": "INPUT",
        "associated_equipment": "D1",
        "capacity": 2,
        "status": "HOLDING",
        "lot_count": 1,
        "lots": [
          {
            "lot_id": "LOT2024002",
            "priority": "NORMAL",
            "arrive_time": "2024-01-15T09:00:00Z",
            "wait_duration_sec": 300
          }
        ]
      }
    ]
  }
}
```

#### Bank 派工指令
```
POST /api/v1/banks/{bank_id}/dispatch
```

**请求体**
```json
{
  "lot_id": "LOT2024002",
  "target_equipment": "D1",
  "priority": "NORMAL"
}
```

**响应**
```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "dispatch_id": "DIS2024001001",
    "status": "CONFIRMED",
    "confirmed_at": "2024-01-15T09:05:00Z"
  }
}
```

### 3.3 EAP/SECS 接口

#### 发送 SECS 消息
```
POST /api/v1/eap/message
```

**请求体**
```json
{
  "stream_function": "S1F3",
  "device_id": "EQ001",
  "body": {
    "svid_list": [1, 2, 3]
  }
}
```

**响应**
```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "stream_function": "S1F4",
    "device_id": "EQ001",
    "body": {
      "sv_count": 3,
      "status_variables": [...]
    }
  }
}
```

#### 查询事件定义
```
GET /api/v1/eap/events
```

**响应**
```json
{
  "code": 0,
  "message": "OK",
  "data": {
    "collection_events": [
      {
        "ceid": 1012,
        "ce_name": "ProcessingStarted",
        "description": "开始加工",
        "enabled": true,
        "report_id": 2012
      }
    ]
  }
}
```

---

## 4. WebSocket 实时通道

### 4.1 连接建立

```
ws://{host}:8080/ws/mes?device_id={equipment_id}&token={auth_token}
```

### 4.2 消息格式

**通用消息结构**
```json
{
  "message_type": "event|command|status|heartbeat",
  "timestamp": "2024-01-15T09:10:00Z",
  "sequence": 12345,
  "payload": {...}
}
```

### 4.3 仿真系统 → MES 消息

#### 设备状态变化事件
```json
{
  "message_type": "EQUIPMENT_STATUS_CHANGE",
  "timestamp": "2024-01-15T09:10:00Z",
  "sequence": 1001,
  "payload": {
    "device_id": "EQ001",
    "previous_state": {
      "control_state": "REMOTE",
      "process_state": "IDLE"
    },
    "current_state": {
      "control_state": "REMOTE",
      "process_state": "PROCESSING"
    },
    "trigger_event": "S2F41_START",
    "lot_id": "LOT2024001"
  }
}
```

#### Bank 事件
```json
{
  "message_type": "BANK_EVENT",
  "timestamp": "2024-01-15T09:10:05Z",
  "sequence": 1002,
  "payload": {
    "bank_id": "BK_D1_IN",
    "event_type": "LOT_ARRIVE",
    "lot_id": "LOT2024002",
    "from_equipment": "C1",
    "queue_position": 1,
    "wait_time_estimate_sec": 300
  }
}
```

#### EAP SECS 事件
```json
{
  "message_type": "EAP_SECS_EVENT",
  "timestamp": "2024-01-15T09:10:10Z",
  "sequence": 1003,
  "payload": {
    "stream_function": "S6F11",
    "device_id": "EQ001",
    "ceid": 1012,
    "ce_name": "ProcessingStarted",
    "reports": [...]
  }
}
```

### 4.4 MES → 仿真系统 消息

#### 远程指令
```json
{
  "message_type": "REMOTE_COMMAND",
  "timestamp": "2024-01-15T09:10:15Z",
  "message_id": "MES_CMD_001",
  "payload": {
    "command": "S2F41",
    "device_id": "EQ001",
    "rcmd": "START",
    "parameters": {
      "LotID": "LOT2024001",
      "PPID": "DEP_100NM_STD"
    }
  }
}
```

#### 配方下载
```json
{
  "message_type": "PPID_DOWNLOAD",
  "timestamp": "2024-01-15T09:10:20Z",
  "message_id": "MES_PPID_001",
  "payload": {
    "device_id": "EQ001",
    "ppid": "DEP_100NM_STD",
    "recipe_data": {...}
  }
}
```

---

## 5. 错误处理

### 5.1 错误响应格式

```json
{
  "code": 4001,
  "message": "Invalid command for current state",
  "details": {
    "device_id": "EQ001",
    "current_state": "PROCESSING",
    "command": "START",
    "allowed_states": ["IDLE"]
  },
  "timestamp": "2024-01-15T09:15:00Z",
  "request_id": "REQ2024001001"
}
```

### 5.2 错误代码表

| 代码 | 名称 | 说明 |
|------|------|------|
| 0 | OK | 成功 |
| 1001 | InvalidRequest | 请求格式错误 |
| 1002 | DeviceNotFound | 设备不存在 |
| 1003 | BankNotFound | Bank不存在 |
| 1004 | LotNotFound | 批次不存在 |
| 2001 | InvalidState | 当前状态无法执行 |
| 2002 | DeviceBusy | 设备繁忙 |
| 2003 | BankFull | Bank已满 |
| 3001 | InvalidCommand | 无效指令 |
| 3002 | InvalidParameter | 参数无效 |
| 3003 | InvalidPPID | 无效配方ID |
| 4001 | CommunicationError | 通信错误 |
| 4002 | Timeout | 超时 |
| 5001 | InternalError | 内部错误 |

---

## 6. 状态机定义

### 6.1 Control State (控制状态)

```
┌─────────────────────────────────────────────────────────────┐
│                     Control State Machine                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌──────────┐                                              │
│   │ OFFLINE  │←──────────────────────────────────────────┐  │
│   │    0     │                                           │  │
│   └────┬─────┘                                           │  │
│        │ S1F13 Establish Communication                   │  │
│        ↓                                                 │  │
│   ┌──────────┐     S1F17 (Local)      ┌──────────┐     │  │
│   │ ONLINE   │───────────────────────→│  LOCAL   │─────┘  │
│   │    1     │←───────────────────────│    4     │        │
│   └────┬─────┘     S1F17 (Online)     └──────────┘        │
│        │                                                   │
│        │ S1F17 (Remote)                                    │
│        ↓                                                   │
│   ┌──────────┐     S2F41 (LOCAL)      ┌──────────┐        │
│   │ REMOTE   │───────────────────────→│  LOCAL   │────────┘
│   │    5     │←───────────────────────│    4     │
│   └──────────┘     S1F17 (Remote)     └──────────┘
│        │
│        │ 通信断开
│        ↓
│   ┌──────────┐
│   │ OFFLINE  │
│   └──────────┘
│
│  Control State 值:
│  • 0: OFFLINE - 离线，未建立通信
│  • 1: ONLINE - 在线，未确定控制模式
│  • 4: LOCAL - 本地控制模式
│  • 5: REMOTE - 远程控制模式 (MES可操作)
│
└─────────────────────────────────────────────────────────────┘
```

### 6.2 Process State (加工状态)

```
┌─────────────────────────────────────────────────────────────┐
│                    Process State Machine                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌──────────┐                                              │
│   │  IDLE    │←─────────────────────────────────────────┐   │
│   │   空闲   │                                          │   │
│   └────┬─────┘                                          │   │
│        │ Lot到达 / S2F41 START                          │   │
│        ↓                                                │   │
│   ┌──────────┐                                          │   │
│   │  SETUP   │                                          │   │
│   │  准备中  │                                          │   │
│   └────┬─────┘                                          │   │
│        │ 准备完成                                        │   │
│        ↓                                                │   │
│   ┌──────────┐     S2F41 PAUSE      ┌──────────┐       │   │
│   │PROCESSING│────────────────────→│  PAUSED  │       │   │
│   │  加工中  │←─────────────────────│  暂停    │       │   │
│   └────┬─────┘     S2F41 RESUME     └──────────┘       │   │
│        │                                                │   │
│        │ 加工完成 / S2F41 STOP                          │   │
│        ↓                                                │   │
│   ┌──────────┐                                          │   │
│   │ COMPLETE │──────────────────────────────────────────┘   │
│   │  完成    │  Lot移出                                     │
│   └──────────┘                                              │
│        ↑                                                    │
│        │ S2F41 ABORT                                        │
│        │                                                    │
│   ┌────┴─────┐                                              │
│   │  ABORTED │                                              │
│   │  已终止  │                                              │
│   └──────────┘                                              │
│                                                              │
│  状态转换触发:                                               │
│  • 内部: 定时器、状态检查                                    │
│  • 外部: S2F41 Host Command (START/STOP/PAUSE/RESUME/ABORT)  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. 数据字典

### 7.1 Status Variables (SV)

| SVID | 名称 | 数据类型 | 描述 | 示例值 |
|------|------|---------|------|--------|
| 1 | ControlState | ASCII | 控制状态 | REMOTE |
| 2 | ProcessState | ASCII | 加工状态 | PROCESSING |
| 3 | CurrentLotID | ASCII | 当前批次ID | LOT2024001 |
| 4 | CurrentPPID | ASCII | 当前配方ID | DEP_100NM_STD |
| 5 | ProcessStartTime | ASCII | 加工开始时间 | 2024-01-15T08:00:00Z |
| 6 | ProcessElapsedTime | U4 | 已加工时间(秒) | 300 |
| 7 | EquipmentStatus | ASCII | 设备状态 | UP |
| 8 | AlarmCount | U4 | 当前告警数 | 0 |
| 9 | CurrentStep | U4 | 当前工艺步骤 | 5 |
| 10 | TotalSteps | U4 | 总工艺步骤 | 30 |
| 11 | BankInCount | U4 | 输入Bank批次数 | 1 |
| 12 | BankOutCount | U4 | 输出Bank批次数 | 0 |

### 7.2 Equipment Constants (EC)

| ECID | 名称 | 数据类型 | 默认值 | 范围 | 描述 |
|------|------|---------|--------|------|------|
| 1 | MaxProcessTime | U4 | 3600 | 60-7200 | 最大加工时间(秒) |
| 2 | IdleTimeout | U4 | 300 | 60-600 | 空闲超时(秒) |
| 3 | AutoReportEnabled | BOOLEAN | true | - | 自动事件上报 |
| 4 | DataSampleRate | U4 | 1000 | 100-10000 | 数据采集间隔(ms) |
| 5 | AlarmHistorySize | U4 | 100 | 10-1000 | 告警历史记录数 |

### 7.3 Collection Events (CE)

| CEID | 名称 | 描述 | 报告ID |
|------|------|------|--------|
| 1001 | ControlStateChanged | 控制状态变化 | 2001 |
| 1002 | ProcessingStateChanged | 加工状态变化 | 2002 |
| 1011 | LotArrived | 批次到达设备 | 2011 |
| 1012 | ProcessingStarted | 开始加工 | 2012 |
| 1013 | ProcessingCompleted | 加工完成 | 2013 |
| 1014 | LotDeparted | 批次离开设备 | 2014 |
| 1021 | AlarmSet | 告警产生 | 2021 |
| 1022 | AlarmCleared | 告警清除 | 2022 |
| 1031 | BankLotArrived | 批次到达Bank | 2031 |
| 1032 | BankLotDeparted | 批次离开Bank | 2032 |
| 1033 | BankDispatchConfirmed | Bank派工确认 | 2033 |

### 7.4 Reports (RPT)

| RPTID | 名称 | 包含变量 |
|-------|------|---------|
| 2001 | ControlStateReport | SV 1, 2 |
| 2002 | ProcessStateReport | SV 1, 2 |
| 2011 | LotArrivedReport | SV 1, 2, 3 |
| 2012 | ProcessStartReport | SV 1, 2, 3, 4, 5 |
| 2013 | ProcessCompleteReport | SV 1, 2, 3, 4, 6 |
| 2014 | LotDepartedReport | SV 1, 2, 3 |
| 2021 | AlarmSetReport | SV 1, 2, 8 |
| 2022 | AlarmClearedReport | SV 1, 2, 8 |
| 2031 | BankArrivedReport | SV 1, 11 |
| 2032 | BankDepartedReport | SV 1, 12 |
| 2033 | BankDispatchReport | SV 1, 3, 11 |

---

## 8. 接口使用示例

### 8.1 完整加工流程示例

```
1. 通信建立
   MES → 仿真: S1F1 (Are You Online?)
   仿真 → MES: S1F2 (Online, ControlState=OFFLINE)

2. 切换到REMOTE模式
   MES → 仿真: S1F17 (Go Online Remote)
   仿真 → MES: S1F18 (ControlState=REMOTE)
   仿真 → MES: S6F11 (CEID=1001 ControlStateChanged)

3. 定义报告和关联事件
   MES → 仿真: S2F33 (Define Report RPTID=2012)
   仿真 → MES: S2F34 (DRACK=0)
   MES → 仿真: S2F35 (Link CEID=1012 to RPTID=2012)
   仿真 → MES: S2F36 (LRACK=0)
   MES → 仿真: S2F37 (Enable CEID=1012)
   仿真 → MES: S2F38 (ERACK=0)

4. 下载配方
   MES → 仿真: S7F3 (PPID=DEP_100NM_STD)
   仿真 → MES: S7F4 (ACKC7=0)

5. 开始加工
   MES → 仿真: S2F41 (RCMD=START, LotID=LOT001, PPID=DEP_100NM_STD)
   仿真 → MES: S2F42 (HCACK=0)
   仿真 → MES: S6F11 (CEID=1012 ProcessingStarted)

6. 状态查询
   MES → 仿真: S1F3 (SVID=[1,2,3,4])
   仿真 → MES: S1F4 (ProcessState=PROCESSING, CurrentLotID=LOT001)

7. 加工完成
   仿真 → MES: S6F11 (CEID=1013 ProcessingCompleted)
   仿真 → MES: S6F11 (CEID=1014 LotDeparted)

8. 获取结果
   MES → 仿真: S1F3 (SVID=[3,4,6])
   仿真 → MES: S1F4 (CurrentLotID="", ProcessElapsedTime=1800)
```

---

## 9. 附录

### 9.1 SECS 数据类型映射

| SECS 类型 | JSON 类型 | 说明 |
|----------|----------|------|
| ASCII | string | ASCII字符串 |
| I1/I2/I4/I8 | number | 有符号整数 |
| U1/U2/U4/U8 | number | 无符号整数 |
| F4/F8 | number | 浮点数 |
| BOOLEAN | boolean | 布尔值 |
| LIST | array | 列表 |
| BINARY | string (base64) | 二进制数据 |

### 9.2 与真实 SiView 的差异

| 方面 | 真实 SiView | 本仿真系统 |
|------|------------|-----------|
| 传输协议 | SECS-I/HSMS (二进制) | REST/WebSocket (JSON) |
| 消息格式 | SML (SECS Message Language) | JSON |
| 通信层 | 专用硬件/驱动 | HTTP/TCP |
| 数据编码 | 二进制 SECS | JSON 文本 |
| 消息头 | Session ID, System Bytes | HTTP Header + JSON 字段 |

**设计理念**: 保持 SECS/GEM 语义，使用现代 Web 技术实现，便于调试和集成。

---

**文档版本**: v1.0  
**最后更新**: 2024-04-15  
**作者**: FabSim Team
