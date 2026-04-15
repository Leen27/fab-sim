# 半导体MES系统核心功能清单

> 制造执行系统（Manufacturing Execution System）
> FabSim仿真系统需要对接/验证的目标

---

## 一、MES核心功能（必须有）

### 1. 工单/批次管理（Lot Management）

```
这是MES的"心脏"，所有功能围绕它转

功能：
✅ Lot创建/拆分/合并
✅ Lot状态流转：等待→加工→检验→完成
✅ Lot优先级设置（紧急订单插队）
✅ Lot历史追溯（ genealogy，从晶圆到芯片的完整历史）

FabSim对接点：
→ 接收MES下发的Lot信息（产品型号、工艺路线、优先级）
→ 仿真预测Lot完成时间，反馈给MES
```

### 2. 设备管理（Equipment Management）

```
功能：
✅ 设备状态监控：空闲/运行/故障/维护
✅ 设备OEE统计（稼动率）
✅ 预防性维护（PM）计划
✅ 设备Recipe管理（不同产品用不同参数）
✅ 故障报警与记录

FabSim对接点：
→ 读取设备实时状态
→ 仿真设备故障对产线的影响
→ 优化维护计划
```

### 3. 工艺/Recipe管理

```
功能：
✅ 工艺流程定义（Process Flow）
✅ Recipe版本控制
✅ 工艺参数下载到设备（Download）
✅ 工艺变更管理

FabSim对接点：
→ 导入真实Recipe进行仿真
→ 验证新工艺的可行性
→ 对比不同Recipe的效率
```

### 4. 在制品追踪（WIP Tracking）

```
功能：
✅ 实时WIP位置追踪（在哪台设备/哪个缓冲）
✅ WIP数量统计
✅ WIP年龄监控（防止滞留）
✅ 瓶颈工位预警

FabSim对接点：
→ 影子模式：仿真预测WIP未来分布
→ 对比真实WIP vs 仿真WIP
```

### 5. 排程/调度（Scheduling）

```
功能：
✅ 设备派工（Dispatching）：哪台机器加工哪个Lot
✅ 批次组合（Batching）：相同工艺的Lot一起加工
✅ 规则引擎：FIFO、SPT、CR、OAS等
✅ 交期承诺（ATP/CTP）

FabSim对接点：
→ 这是仿真的核心验证对象！
→ 测试不同调度规则的效果
→ 优化派工策略
```

---

## 二、MES重要功能（建议有）

### 6. 质量管理（Quality Management）

```
功能：
✅ 检验计划（Inspection Plan）
✅ SPC统计过程控制（控制图、Cp/Cpk）
✅ 异常处理（Hold/Release）
✅ 良率分析

FabSim对接点：
→ 仿真质量抽检对产能的影响
→ 优化检验频率
```

### 7. 物料管理

```
功能：
✅ 晶圆库存管理
✅ 化学品/气体追踪
✅ 物料消耗统计
✅ 缺料预警

FabSim对接点：
→ 仿真物料短缺场景
→ 优化物料配送策略
```

### 8. 数据采集（Data Collection）

```
功能：
✅ 设备数据自动采集（EDA/SECS/GEM协议）
✅ 工艺参数记录
✅ 生产事件记录
✅ 报警日志

FabSim对接点：
→ 接收真实数据进行影子仿真
→ 生成仿真数据对比
```

### 9. 人员管理

```
功能：
✅ 操作员资质管理
✅ 操作记录追溯
✅ 培训管理

FabSim对接点：
→ 仿真人员效率对产能的影响
```

### 10. 报表/看板

```
功能：
✅ 生产报表（产量、良率、OEE）
✅ 实时看板
✅ 趋势分析

FabSim对接点：
→ 对比真实报表 vs 仿真预测
→ 验证仿真准确性
```

---

## 三、MES扩展功能（大厂才有）

| 功能 | 说明 | FabSim价值 |
|------|------|-----------|
| **RTD** (Real-Time Dispatcher) | 实时派工系统 | 仿真的核心对象 |
| **APC** (Advanced Process Control) | 先进过程控制 | 验证APC策略 |
| **FDC** (Fault Detection & Classification) | 故障检测分类 | 仿真故障场景 |
| **R2R** (Run-to-Run Control) | 批次间控制 | 优化控制参数 |
| **EAP** (Equipment Automation Program) | 设备自动化 | 对接协议验证 |

---

## 四、FabSim与MES的联动场景

### 场景1：影子模式（Shadow Mode）

```
真实产线 ←→ MES ←→ FabSim
              ↓
         实时同步数据
              ↓
         FabSim预测未来2小时状态
              ↓
         发现瓶颈 → 提前预警
```

### 场景2：策略验证（What-if）

```
MES当前策略 → FabSim仿真 → 结果不满意
                  ↓
            调整参数重跑
                  ↓
            找到最优策略 → 应用到MES
```

### 场景3：新员工培训

```
MES真实数据 → 导入FabSim → 新员工操作仿真
                              ↓
                        不担心搞砸真实产线
```

---

## 五、给你的建议

### FabSim MVP应该验证MES的哪些功能？

| 优先级 | MES功能 | FabSim验证点 |
|--------|---------|-------------|
| **P0** | Lot管理 | Lot流转、状态变更 |
| **P0** | 设备管理 | 设备状态、加工时间 |
| **P0** | 排程调度 | FIFO规则验证 |
| **P1** | WIP追踪 | 实时WIP统计 |
| **P1** | Recipe管理 | 工艺流执行 |
| **P2** | 质量管理 | 抽检策略仿真 |
| **P2** | 数据采集 | 数据对接格式 |

### MES接口建议格式

```json
// MES → FabSim (下发工单)
{
  "lot_id": "L20240411001",
  "product": "8寸晶圆A",
  "recipe": "R001",
  "priority": 5,
  "quantity": 25,
  "due_time": "2024-04-12T18:00:00"
}

// FabSim → MES (仿真预测)
{
  "lot_id": "L20240411001",
  "predicted_completion": "2024-04-11T16:30:00",
  "confidence": 0.92,
  "bottleneck_machine": "M3-LITHO"
}
```

---

## 六、常见MES厂商

| 厂商 | 特点 | 对接难度 |
|------|------|---------|
| **Applied Materials** (PROMIS) | 行业老大，功能全 | 难 |
| **Siemens** (Camstar) | 大厂用得多 | 中等 |
| **IBM** (SiView) | 老牌 | 中等 |
| **WorkStream** | 性价比高 | 易 |
| **国产MES** (芯享、哥瑞利等) | 本地化好 | 易 |

---

**队长，MES功能清楚了吗？** 🫡

FabSim重点验证**排程调度**这个核心功能，其他的先有接口能对接就行！

需要我详细设计**FabSim与MES的数据接口格式**吗？