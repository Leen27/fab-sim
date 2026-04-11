# FabSim - AI Agent 开发指南

## 项目概述

**FabSim** 是一个基于 Godot 4.x 的半导体工厂仿真系统，用于模拟晶圆生产线的 Lot 流转和调度过程。

- **技术栈**: Godot 4.6 (GDScript)
- **项目类型**: 2D 拓扑仿真工具
- **核心功能**: Lot 流转仿真 + FIFO 调度算法

## 项目结构

```
fab-sim/
├── project.godot              # Godot 项目配置文件
├── README.md                  # 项目说明文档（中文）
├── AGENTS.md                  # 本文件
│
├── scenes/                    # Godot 场景文件 (.tscn)
│   ├── main.tscn             # 主场景（带标签页的界面）
│   ├── simulator.tscn        # 仿真场景（旧版，已弃用）
│   ├── simulator/
│   │   └── simulator.tscn    # 仿真器主场景
│   └── editor/
│       ├── editor.tscn       # 产线编辑器场景
│       └── machine_item.tscn # 设备节点场景
│
├── scripts/                   # GDScript 脚本
│   ├── main.gd               # 主场景脚本，管理标签页切换
│   ├── main.gd.uid           # Godot 唯一标识符文件
│   │
│   ├── core/                 # 仿真引擎核心
│   │   └── sim_engine.gd     # SimEngine 类，核心仿真逻辑
│   │
│   ├── simulator/            # 仿真器模块
│   │   ├── simulator.gd      # 仿真场景脚本（旧版）
│   │   └── simulator_main.gd # 主仿真器 UI 逻辑
│   │
│   └── editor/               # 产线编辑器模块
│       ├── editor.gd         # 编辑器主逻辑
│       └── machine_item.gd   # 设备节点交互逻辑
│
└── data/                      # 数据配置文件（JSON）
    ├── default_layout.json   # 默认产线布局
    ├── machine_types.json    # 设备类型定义
    └── recipes.json          # 工艺配方定义
```

## 技术栈详解

### Godot 引擎配置
- **引擎版本**: Godot 4.6+
- **渲染后端**: Mobile（移动设备优化）
- **窗口尺寸**: 1400x900
- **拉伸模式**: canvas_items

### 核心类架构

```
SimEngine (RefCounted)
├── 仿真状态管理
├── Lot 生命周期管理
├── 设备状态跟踪
└── FIFO 调度算法
```

### 信号系统
SimEngine 使用 Godot 信号机制进行状态通知：
- `time_updated(current_time_minutes)` - 仿真时间更新
- `wip_updated(wip_count)` - 在制品数量变化
- `lot_completed(lot_id, total_time)` - Lot 完成事件
- `machine_status_changed(machine_id, status)` - 设备状态变化

## 数据格式规范

### 产线布局 (data/default_layout.json)
```json
{
  "machines": [
    {
      "id": "M1",
      "type": "clean",        // 设备类型，对应 machine_types.json
      "name": "清洗机",
      "x": 100,               // 屏幕 X 坐标
      "y": 300,               // 屏幕 Y 坐标
      "process_time": 10      // 加工时间（分钟）
    }
  ],
  "buffers": [
    {
      "id": "B1",
      "name": "清洗后缓冲",
      "x": 190,
      "y": 420,
      "capacity": 5           // 缓冲容量
    }
  ],
  "connections": [
    {"from": "M1", "to": "B1"},  // 连接关系：设备 -> 缓冲
    {"from": "B1", "to": "M2"}   // 连接关系：缓冲 -> 设备
  ]
}
```

### 设备类型 (data/machine_types.json)
```json
{
  "machine_types": [
    {
      "id": "clean",
      "name": "清洗机",
      "color": "#FFD700",
      "default_time": 10,
      "icon": "🟨"
    }
  ],
  "buffer": {
    "id": "buffer",
    "name": "缓冲",
    "color": "#9370DB",
    "default_capacity": 5,
    "icon": "🟪"
  }
}
```

### 工艺配方 (data/recipes.json)
```json
{
  "recipes": [
    {
      "id": "R001",
      "name": "标准晶圆工艺",
      "steps": [
        {"step": 1, "machine_type": "clean", "time": 10},
        {"step": 2, "machine_type": "deposition", "time": 30},
        {"step": 3, "machine_type": "lithography", "time": 45},
        {"step": 4, "machine_type": "etching", "time": 30},
        {"step": 5, "machine_type": "heat", "time": 20},
        {"step": 6, "machine_type": "inspect", "time": 15}
      ]
    }
  ]
}
```

## 仿真逻辑说明

### Lot 流转流程
1. **生成**: 仿真启动时生成 5 个初始 Lot
2. **入队**: Lot 放入第一台设备的等待队列
3. **加工**: 设备空闲 + 队列有 Lot → 开始加工
4. **流转**: 加工完成 → 放入下游缓冲
5. **移动**: 缓冲 Lot 自动移入下一台设备队列
6. **完成**: 所有步骤完成后统计周期时间 (CT)

### 调度规则
- **FIFO** (先进先出): 默认调度算法
- 设备空闲时立即处理队列中的第一个 Lot

### 时间系统
- 基础时间单位：分钟
- 支持时间加速：1x / 10x / 100x
- 显示格式：`HH:MM`

## 运行方式

### 方式一：Godot 编辑器
```bash
# 打开项目
godot4 project.godot
```

### 方式二：导出运行
通过 Godot 编辑器导出为可执行文件后运行。

## 代码规范

### GDScript 风格
- 使用 **snake_case** 命名变量和函数
- 使用 **PascalCase** 命名类名
- 使用 **UPPER_CASE** 命名常量
- 缩进使用 **Tab**
- 信号使用 **snake_case**

### 注释规范
- 关键逻辑添加中文注释
- 使用 `#` 进行行注释
- 信号和公共方法需要注释说明

### 示例代码风格
```gdscript
class_name SimEngine
extends RefCounted

signal time_updated(current_time_minutes)

var current_time: float = 0.0  # 仿真时间（分钟）
var time_scale: float = 1.0    # 时间加速倍数

func start():
    """启动仿真，生成初始 Lot"""
    if is_running:
        return
    is_running = true
    _generate_lots(5)
```

## 开发注意事项

### 文件引用
- 使用 `res://` 前缀引用项目文件
- JSON 文件通过 `FileAccess` 读取
- 场景使用 `preload()` 预加载

### 内存管理
- SimEngine 继承自 `RefCounted`，会被自动释放
- 场景节点通过 `queue_free()` 释放
- 信号连接需要适时断开

### UI 更新
- 通过 `_process(delta)` 调用 `sim_engine.update(delta)`
- 信号驱动 UI 更新，避免轮询
- 使用 `@onready` 延迟获取节点引用

## 扩展开发指南

### 添加新调度算法
1. 在 `sim_engine.gd` 中修改 `_dispatch_lots()` 方法
2. 实现新的调度策略（SPT/CR/OAS 等）
3. 添加算法切换 UI

### 添加新设备类型
1. 在 `machine_types.json` 中定义新类型
2. 在 `_get_machine_color()` 中添加颜色映射
3. 更新配方 `recipes.json` 使用新设备

### 添加新功能模块
1. 在 `scripts/` 下创建新目录
2. 遵循现有模块化结构
3. 在 `main.gd` 中集成新场景

## 调试技巧

1. **打印调试**: 使用 `print()` 输出日志
2. **断点调试**: 在 Godot 编辑器中设置断点
3. **状态检查**: 运行时查看 SimEngine 的变量状态
4. **速度控制**: 使用 1x 速度观察详细流程

## 已知限制

- 当前仅支持线性产线布局
- 调度算法仅实现 FIFO
- 暂不支持设备故障模拟
- 报表导出功能待实现

---

**开发提示**: 本项目使用中文注释和文档，代码中涉及业务概念（如 Lot、WIP、CT）请保持半导体行业术语。
