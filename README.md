# 🔥 FabSim - 半导体工厂仿真系统

> 单人MVP版本 | Godot 4.x | 2D拓扑仿真
> **核心功能：Lot流转仿真 + FIFO调度**

---

## 🚀 快速开始

### 1. 运行项目

```bash
# 进入项目目录
cd /root/.openclaw/workspace/fabsim

# 用Godot打开（命令行方式）
godot4 project.godot

# 或者双击 project.godot 文件用Godot编辑器打开
```

### 2. 操作说明

| 按钮 | 功能 |
|------|------|
| ▶ 开始 | 启动仿真，生成5个初始Lot |
| ⏸ 暂停 | 暂停/继续仿真 |
| ⏹ 重置 | 清空所有Lot，重置时间 |
| 1x/10x/100x | 时间加速 |

### 3. 观察什么

- **🟨🟩🟦🟥🟧⬜** 6色设备方块显示状态
- **红色角标** = 设备前排队等待的Lot数
- **🟪 紫色缓冲** = 设备间的暂存区，显示库存数
- **📊 信息面板** = 时间/WIP/已完成/平均周期时间

---

## 📂 项目结构

```
fabsim/
├── project.godot              # Godot项目文件
├── scenes/
│   └── simulator.tscn         # 仿真主场景
├── scripts/
│   ├── simulator/
│   │   └── simulator_main.gd  # 仿真器主逻辑
│   └── core/
│       └── sim_engine.gd      # 仿真引擎核心
└── data/
    ├── default_layout.json    # 产线布局配置
    ├── machine_types.json     # 设备类型定义
    └── recipes.json           # 工艺配方
```

---

## ⚙️ 配置说明

### 修改产线布局

编辑 `data/default_layout.json`：

```json
{
  "machines": [
    {
      "id": "M1",
      "type": "clean",        // 设备类型
      "name": "清洗机",
      "x": 100,               // 屏幕X位置
      "y": 300,               // 屏幕Y位置
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
    {"from": "M1", "to": "B1"},  // M1 → B1
    {"from": "B1", "to": "M2"}   // B1 → M2
  ]
}
```

### 修改工艺配方

编辑 `data/recipes.json`：

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

---

## 🎮 仿真逻辑

```
Lot流转流程：

1. Lot生成 → 放入第一台设备队列
2. 设备空闲 + 队列有Lot → 开始加工
3. 加工完成 → 放入缓冲
4. 缓冲Lot → 移入下一台设备队列
5. 重复直到所有步骤完成
6. Lot完成 → 统计CT

调度规则：FIFO（先进先出）
```

---

## 📊 当前实现

- ✅ Lot生成与流转
- ✅ 6设备+5缓冲产线
- ✅ FIFO调度
- ✅ 实时状态显示
- ✅ 时间加速（1x/10x/100x）
- ✅ 基础统计（WIP/吞吐量/CT）

---

## 🛠️ 开发路线图

- [ ] CSV导入Lot清单
- [ ] 多种调度算法（SPT/CR/OAS）
- [ ] 设备故障模拟
- [ ] 报表导出
- [ ] MES接口对接

---

**队长，运行试试看！** 🔥

有问题直接说，随时调！