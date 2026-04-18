## 5. 使用示例

### 示例 1: 创建一条产线 (Mode A - 独立仿真)

```gdscript
# 独立仿真模式 - 纯离散事件仿真

var equipments = []

# 1. 创建清洗机
equipments.append(EquipmentFactory.create_equipment({
    "id": "CLEAN01",
    "name": "清洗机#1",
    "type": "CLEAN",
    "capacity": 1,
    "process_time": 300,
    "chemical": "HF",
    "gem_mode": false  # 独立模式，不需要 GEM
}))

# 2. 创建光刻机
equipments.append(EquipmentFactory.create_equipment({
    "id": "LITHO01",
    "name": "光刻机#1",
    "type": "LITHO",
    "capacity": 1,
    "process_time": 600,
    "reticle": "RET_001",
    "gem_mode": false
}))

# 3. 创建扩散炉 (批量设备)
equipments.append(EquipmentFactory.create_equipment({
    "id": "FURNACE01",
    "name": "扩散炉#1",
    "type": "FURNACE",
    "capacity": 100,  # 批量设备
    "process_time": 1800,
    "batch_size": 100,
    "gem_mode": false
}))

# 仿真循环
func _process(delta):
    for eq in equipments:
        eq.update(delta)  # 推进仿真时间
```

### 示例 2: 创建 GEM 设备集群 (Mode B - MES 联调)

```gdscript
# MES 联调模式 - 真实 GEM 设备仿真

var gem_equipments = []

# 创建 5 台 GEM 光刻机
for i in range(5):
    var eq = EquipmentFactory.create_equipment({
        "id": "LITHO%02d" % (i + 1),
        "name": "光刻机#%d" % (i + 1),
        "type": "LITHO",
        "capacity": 1,
        "process_time": 600,
        "device_id": 100 + i,  # GEM 设备地址
        "gem_mode": true  # 启用 GEM 模式
    })
    gem_equipments.append(eq)

# HSMS 服务器启动
var hsms_server = HSMSServer.new()
hsms_server.port = 5000
hsms_server.equipment_cluster = gem_equipments
hsms_server.start()

# 等待 SiView 连接...
```

### 示例 3: 故障注入测试

```gdscript
# 测试场景: 光刻机真空泵故障

func test_litho_pump_failure():
    var litho = EquipmentFactory.create_equipment({
        "id": "LITHO01",
        "type": "LITHO",
        "gem_mode": true
    })
    
    # 1. 上线设备
    litho.handle_s1f15(null)  # Online
    
    # 2. 开始加工
    litho._gem_start_processing("L001", "R_LITHO_01")
    
    # 3. 模拟 30 秒后注入故障
    await get_tree().create_timer(30).timeout
    litho.inject_fault("VACUUM_PUMP", 1200)  # 20分钟修复
    
    # 4. 验证 MES 收到 S5F1 报警
    assert(litho.active_alarms.size() > 0)
    
    # 5. 模拟故障恢复
    await get_tree().create_timer(1200).timeout
    litho.clear_fault("LITHO_LITHO01_VACUUM_PUMP")
```

### 示例 4: 批量设备 (扩散炉) 调度测试

```gdscript
# 测试扩散炉批量组批逻辑

func test_furnace_batching():
    var furnace = EquipmentFactory.create_equipment({
        "id": "FURNACE01",
        "type": "FURNACE",
        "capacity": 100,
        "batch_size": 100,
        "gem_mode": false
    })
    
    # 尝试添加 50 个相同 Recipe 的 Lot
    for i in range(50):
        var success = furnace.add_to_batch("L%03d" % i, "R_DIFF_01")
        assert(success == true)
    
    # 检查状态: 应该还在组批中，未启动
    assert(furnace.is_processing == false)
    assert(furnace.current_batch.size() == 50)
    
    # 添加第 51-100 个 Lot
    for i in range(50, 100):
        furnace.add_to_batch("L%03d" % i, "R_DIFF_01")
    
    # 达到批量大小，应该自动启动
    assert(furnace.is_processing == true)
    assert(furnace.current_batch.size() == 100)
```

### 示例 5: 可视化更新

```gdscript
# Godot 场景中的设备节点

class_name EquipmentNode
extends Node2D

var equipment: BaseEquipment
var label: Label
var sprite: Sprite2D

func setup(eq: BaseEquipment):
    equipment = eq
    
    # 设置图标
    var icon = equipment.get_icon()
    label.text = icon
    
    # 连接信号
    equipment.state_changed.connect(_on_state_changed)
    equipment.process_started.connect(_on_process_started)
    equipment.process_completed.connect(_on_process_completed)
    equipment.alarm_triggered.connect(_on_alarm)

func _process(delta):
    # 更新仿真
    equipment.update(delta)
    
    # 更新显示颜色
    modulate = equipment.get_status_color()
    
    # 更新工具提示
    tooltip_text = equipment.get_status_text()

func _on_state_changed(eq_id, old_state, new_state):
    # 播放状态变化动画
    pass

func _on_alarm(eq_id, alarm_code, alarm_text):
    # 播放报警闪烁
    pass
```

## 6. 架构总结

```
FabSim Pro 设备模型架构:

                    ┌─────────────────┐
                    │  EquipmentNode  │  ← Godot 可视化节点
                    │  (Node2D)       │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ↓              ↓              ↓
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │   LITHO     │ │    CLEAN    │ │   FURNACE   │  ← 特化设备类型
    │ Equipment   │ │ Equipment   │ │ Equipment   │
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
           │               │               │
           └───────────────┼───────────────┘
                           ↓
              ┌─────────────────────┐
              │   GEMEquipment      │  ← Mode B: 真实 GEM 通信
              │   (可选继承)         │
              └──────────┬──────────┘
                         │
              ┌──────────┴──────────┐
              ↓                     ↓
    ┌─────────────────┐   ┌─────────────────┐
    │ BaseEquipment   │   │  SECSMessage    │  ← 基础层
    │ (数学仿真核心)   │   │  (消息编解码)    │
    └─────────────────┘   └─────────────────┘

设计理念:
1. 抽象层 (BaseEquipment): 纯数学离散事件仿真，不关心设备类型
2. 特化层 (LITHO/CLEAN/FURNACE): 实现设备类型特有的逻辑、故障、图标
3. 通信层 (GEMEquipment): 实现 SECS/GEM 状态机，与 MES 真实通信
4. 可视化层 (EquipmentNode): Godot 2D 节点，负责显示和交互

优势:
- Mode A (独立仿真): 使用 BaseEquipment + 特化类，轻量高效
- Mode B (MES 联调): 使用 GEMEquipment + 特化类，真实通信
- 代码复用: 70% 逻辑在基类，特化类只关注差异点
- 可扩展: 新增设备类型只需继承并重写关键方法
```
