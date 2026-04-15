# 产线编辑器：要还是不要？

## 现状分析

你已经有了：
- ✅ 6种设备类型定义
- ✅ 产线JSON数据结构
- ✅ 基础的拖拽编辑器（已写80%代码）

---

## 方案对比

### 方案A：保留编辑器（现在已完成80%）

```
优点：
✅ 直观拖拽，调试试错快
✅ 演示给客户/老板时效果好
✅ 已写大部分代码，弃之可惜
✅ 后期加设备类型不用改代码

缺点：
❌ 要处理边界情况（重叠、删除、保存等）
❌ 需要半天~1天完善
```

### 方案B：砍掉编辑器，直接用JSON配置

```
数据/fabsim_layout.json
{
  "machines": [
    {"id": "M1", "type": "clean", "name": "清洗", "x": 100, "y": 200},
    {"id": "M2", "type": "lithography", "name": "光刻", "x": 250, "y": 200},
    {"id": "M3", "type": "etching", "name": "刻蚀", "x": 400, "y": 200}
  ],
  "buffers": [
    {"id": "B1", "name": "缓冲", "x": 175, "y": 300}
  ]
}
```

优点：
✅ 立即省掉1天开发时间
✅ 产线配置可版本控制（Git管理）
✅ 多人协作时共享方便
✅ 写JSON比拖拖拽拽快（对你而言）

缺点：
❌ 改布局要手动改JSON
❌ 调试时看不到效果，要先跑仿真
```

---

## 我的建议

**如果你是给自己用** → **砍掉编辑器，用JSON** ⚡
- 你熟悉代码，改JSON比拖拽快
- 省下的时间做仿真核心更有价值
- 单人项目，不需要"演示效果"

**如果你要给别人演示** → **保留简化版编辑器** 🎯
- 已经写了80%，弃之可惜
- 拖拽演示更直观
- 最多再花半天完善

---

## 方案B（砍编辑器）快速改造

### 1. 删除文件
```
删除：
- scenes/editor/
- scripts/editor/
- main.tscn里的TabContainer
```

### 2. 简化主界面
```
直接加载默认JSON：

func _ready():
    var layout = load_json("res://data/default_layout.json")
    simulator.set_layout_data(layout)
```

### 3. 创建默认产线JSON
```json
{
  "machines": [
    {"id": "M1", "type": "clean", "name": "清洗机", "x": 100, "y": 200, "time": 10},
    {"id": "M2", "type": "deposition", "name": "沉积机", "x": 250, "y": 200, "time": 30},
    {"id": "M3", "type": "lithography", "name": "光刻机", "x": 400, "y": 200, "time": 45},
    {"id": "M4", "type": "etching", "name": "刻蚀机", "x": 550, "y": 200, "time": 30},
    {"id": "M5", "type": "heat", "name": "热处理", "x": 700, "y": 200, "time": 20},
    {"id": "M6", "type": "inspect", "name": "检测机", "x": 850, "y": 200, "time": 15}
  ],
  "buffers": [
    {"id": "B1", "name": "清洗缓冲", "x": 175, "y": 300, "capacity": 5},
    {"id": "B2", "name": "沉积缓冲", "x": 325, "y": 300, "capacity": 5},
    {"id": "B3", "name": "光刻缓冲", "x": 475, "y": 300, "capacity": 5},
    {"id": "B4", "name": "刻蚀缓冲", "x": 625, "y": 300, "capacity": 5},
    {"id": "B5", "name": "热处理缓冲", "x": 775, "y": 300, "capacity": 5}
  ]
}
```

### 4. 改造后项目结构
```
fabsim/
├── scenes/
│   └── simulator.tscn      ← 只剩仿真界面
├── scripts/
│   ├── simulator.gd
│   └── core/
│       └── sim_engine.gd
└── data/
    ├── machine_types.json
    └── default_layout.json  ← 产线配置
```

---

## 结论

| 你的情况 | 建议 |
|---------|------|
| 只给自己用，追求效率 | 砍编辑器，用JSON ⚡ |
| 需要给别人演示 | 保留简化编辑器 🎯 |
| 不确定 | 先砍编辑器，后期再加（编辑器可以后补）|

**队长，你怎么选？** 🫡

- 🔥 **砍！** → 我5分钟给你改造成JSON配置版
- 🎯 **留！** → 我半天完善编辑器功能
- 🤔 **再看看** → 先跑起来试试现有编辑器？