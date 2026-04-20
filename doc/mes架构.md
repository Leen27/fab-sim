┌─────────────────────────────────────────────────────────┐
│  MDM: 配置(静态)  ──►  Process Modeling (工艺建模)        │
│  定义"应该怎么生产"                                       │
└─────────────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│  MES: 执行(动态)  ──►  Lot Process Operation (生产执行)   │
│  跟踪"实际怎么生产"                                       │
└─────────────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│  状态管控  ──►  Lot/FOUP/EQP 状态机管理                   │
│  监控"现在什么状态"                                       │
└─────────────────────────────────────────────────────────┘


1️⃣ 顶层：Process Modeling（工艺建模）- MDM
作用：定义产品生产的"剧本"（静态配置）

Product A ─┐
Product B ─┼──► Process Package ──► Flow A ──► Operation1 ──► [EQP, Recipe, Q-Time, DCol]
Product C ─┤                       │           Operation2
Product D ─┤                       │           Operation3
Product E ─┘                       │           Operation4
                                   │
                                   ▼
                               Flow B ──► Operation4 ──► [EQP, Recipe, Q-Time, DCol]
                                           Operation5
                                           Operation6


| 概念                  | 说明              |
| ------------------- | --------------- |
| **Process Package** | 工艺包，一组相关产品的工艺集合 |
| **Flow**            | 流程，定义加工步骤顺序     |
| **Operation**       | 工序，单个加工步骤       |
| **EQP**             | 设备限制（哪类设备可以做）   |
| **Recipe**          | 配方（具体工艺参数）      |
| **Q-Time**          | 停留时间限制          |
| **DCol**            | 数据采集要求          |


2️⃣ 中层：Lot Process Operation（Lot全流程监控）- MES

Release ──► Lot Create ──► Step10 ──► Step20 ──► ... ──► Step90
                                    │        │
                                    ▼        ▼
                                 [Q-Time] [Reserve]
                                    │        │
                                    ▼        ▼
                                 Sampling  Track In ──► Track Out
                                    │                   │
                                   NO◄──────────────────┘
                                    │
                                    ▼
                                 Rework ──► Scrap
                                    │
                                    ▼
                                 [Bank]
                                    │
                                    ▼
                               Operation Skip
                                    │
                                    ▼
                               Future Hold

| 操作                 | 说明          |
| ------------------ | ----------- |
| **Lot Create**     | 创建Lot       |
| **Release**        | 释放Lot（允许投产） |
| **Q-Time**         | 检查停留时间      |
| **Reserve**        | 预约设备        |
| **Track In**       | ⭐ 投入设备开始加工  |
| **Track Out**      | ⭐ 设备加工完成产出  |
| **Sampling**       | 抽样检查        |
| **Rework**         | 返工（不合格时）    |
| **Scrap**          | 报废          |
| **Bank**           | 进入存储库等待     |
| **Operation Skip** | 跳过某步骤       |
| **Future Hold**    | 预设未来Hold点   |

┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Split     │  │   Merge     │  │   Scrap     │
│  (拆分)     │  │  (合并)     │  │  (报废)     │
├─────────────┤  ├─────────────┤  ├─────────────┤
│ Parent(25)  │  │ Parent(22)  │  │             │
│    ⬇️       │  │      ⬇️     │  │    [Lot]    │
│ Child(3)    │  │   Child(3)  │  │      ⬇️     │
│ Parent(22)  │  │    ⬇️       │  │    [Scrap]  │
│             │  │ Parent(25)  │  │             │
└─────────────┘  └─────────────┘  └─────────────┘

3️⃣ 右侧：状态管控（State Model）
作用：管理Lot、FOUP、Equipment等对象的状态机
状态机示例

| 对象       | 可能状态                                                  |
| -------- | ----------------------------------------------------- |
| **Lot**  | Create → Ready → Processing → Complete / Hold / Scrap |
| **FOUP** | Empty → Loaded → At Equipment → In Transit            |
| **EQP**  | IDLE → SETUP → PROCESSING → DOWN / MAINTENANCE        |

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Lot State     │  │  Carrier State  │  │   EQP State     │
├─────────────────┤  ├─────────────────┤  ├─────────────────┤
│  Hold State     │  │   Hold State    │  │   Hold State    │
│  Clean State    │  │   Clean State   │  │   Port State    │
│  Reserve State  │  │                 │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘

```gdscript
enum LotState {
	# === 初始状态 ===
	CREATED,              # 刚创建，等待释放
	READY,                # 已释放，可以投产
	
	# === 执行状态 ===
	WAITING_FOR_RESERVE,  # 等待预约设备
	RESERVED,             # 已预约设备
	QUEUED,               # 在设备队列中
	TRACK_IN,             # Track In执行中
	PROCESSING,           # 加工中
	TRACK_OUT,            # Track Out执行中
	
	# === 分支状态 ===
	SAMPLING,             # 抽样检查中
	BANK_IN,              # 进入Bank
	BANK_OUT,             # 从Bank出
	REWORK,               # 返工中
	SCRAPPED,             # 已报废
	
	# === 控制状态 ===
	HELD,                 # Hold状态（可与其他状态叠加）
	FUTURE_HELD,          # 预设Hold点触发
	
	# === 终态 ===
	COMPLETED,            # 所有步骤完成
	ABORTED               # 中止
}
```

                         ┌─────────────┐
                         │   CREATED   │
                         │   (创建)     │
                         └──────┬──────┘
                                │ Release
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                         ┌─────────┐                         │
│                         │  READY  │◄──────────────────┐     │
│                         │ (就绪)   │                   │     │
│                         └────┬────┘                   │     │
│                              │ Reserve                │     │
│                              ▼                        │     │
│                    ┌──────────────────┐               │     │
│                    │ WAITING_FOR_RESERVE│              │     │
│                    │   (等待预约)       │              │     │
│                    └────────┬─────────┘               │     │
│                             │                         │     │
│                             ▼                         │     │
│                         ┌─────────┐                   │     │
│                    ┌───►│RESERVED │───Reserve失败─────┘     │
│                    │    │(已预约) │                        │
│                    │    └────┬────┘                        │
│                    │         │ Reserve成功                  │
│                    │         ▼                              │
│                    │    ┌─────────┐                         │
│                    └───┤ QUEUED  │◄──Track In失败          │
│                        │(队列中)  │                         │
│                        └────┬────┘                         │
│                             │ Track In                      │
│                             ▼                               │
│                        ┌─────────┐    ┌─────────┐          │
│                        │TRACK_IN │───►│PROCESSING│          │
│                        │(投入中) │    │(加工中)  │          │
│                        └─────────┘    └────┬────┘          │
│                                            │                │
│                              ┌─────────────┼─────────────┐ │
│                              ▼             ▼             ▼ │
│                         ┌────────┐    ┌────────┐    ┌────────┐
│                         │TrackOut│    │Sampling│    │ Rework │
│                         │(产出)  │    │(抽样)  │    │(返工)  │
│                         └───┬────┘    └───┬────┘    └───┬────┘
│                             │             │             │
│                             ▼             ▼             │
│                        ┌────────┐    ┌────────┐         │
│                   ┌───►│ READY  │    │  HELD  │         │
│                   │    │(下一周期)│    │(Hold)  │         │
│                   │    └────────┘    └────┬───┘         │
│                   │                       │              │
│                   │                       ▼              │
│                   │                  ┌────────┐          │
│                   │                  │Scrapped│          │
│                   │                  │(报废)  │          │
│                   │                  └────────┘          │
│                   │                                      │
│                   └──────────────────────────────────────┘
│                   
│   Bank分支: 任何状态 ──► BANK_IN ──► BANK_OUT ──► READY
│   
│   终态: COMPLETED (全部步骤完成)
└─────────────────────────────────────────────────────────────┘

┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│  MES   │    │  RTD   │    │  EAP   │    │  EQP   │    │  RMS   │
└───┬────┘    └────┬───┘    └───┬────┘    └───┬────┘    └───┬────┘
    │              │            │             │             │
    │  1. 请求下一设备          │             │             │
    │─────────────►│            │             │             │
    │              │            │             │             │
    │  2. 返回目标设备          │             │             │
    │◄─────────────│            │             │             │
    │              │            │             │             │
    │  3. Reserve请求           │             │             │
    │──────────────────────────►│             │             │
    │              │            │             │             │
    │              │            │ 4. 检查Buffer│             │
    │              │            │────────────►│             │
    │              │            │             │             │
    │              │            │ 5. Buffer OK│             │
    │              │            │◄────────────│             │
    │              │            │             │             │
    │  6. Reserve成功           │             │             │
    │◄──────────────────────────│             │             │
    │              │            │             │             │
    │  7. 创建CJ                │             │             │
    │────────────┐│            │             │             │
    │            ││            │             │             │
    │◄───────────┘│            │             │             │
    │              │            │             │             │
    │  8. 下发Track In          │             │             │
    │──────────────────────────►│             │             │
    │              │            │             │             │
    │              │            │ 9. 请求Recipe验证        │
    │              │            │──────────────────────────►│
    │              │            │             │             │
    │              │            │ 10. Recipe验证OK         │
    │              │            │◄──────────────────────────│
    │              │            │             │             │
    │              │            │ 11. 设备准备就绪          │
    │              │            │────────────►│             │
    │              │            │             │             │
    │              │            │ 12. 开始加工 ◄──(PJ Start)│
    │              │            │────────────►│             │
    │              │            │             │             │
    │  13. Track In完成上报      │             │             │
    │◄──────────────────────────│             │             │
    │              │            │             │             │
    │  14. 更新Lot状态为PROCESSING             │             │
    │────────────┐│            │             │             │
    │            ││            │             │             │
    │◄───────────┘│            │             │             │
    │              │            │             │             │


┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
│  MES   │    │  RTD   │    │  EAP   │    │  EQP   │    │  SPC   │
└───┬────┘    └────┬───┘    └───┬────┘    └───┬────┘    └───┬────┘
    │              │            │             │             │
    │              │            │ 1. 加工完成 │             │
    │              │            │◄────────────│             │
    │              │            │             │             │
    │              │            │ 2. 数据采集 │             │
    │              │            │─────────────┼────────────►│
    │              │            │             │             │
    │              │            │ 3. SPC结果  │             │
    │              │            │◄────────────┼─────────────│
    │              │            │             │             │
    │              │            │ 4. Track Out请求         │
    │              │            │────────────►│             │
    │              │            │             │             │
    │              │            │ 5. FOUP卸载准备           │
    │              │            │◄────────────│             │
    │              │            │             │             │
    │  6. Track Out上报         │             │             │
    │◄──────────────────────────│             │             │
    │              │            │             │             │
    │  7. 更新WIP状态           │             │             │
    │────────────┐│            │             │             │
    │            ││            │             │             │
    │◄───────────┘│            │             │             │
    │              │            │             │             │
    │  8. 判断是否抽样          │             │             │
    │────────────┐│            │             │             │
    │  [是]      ││            │             │             │
    │◄───────────┘│            │             │             │
    │              │            │             │             │
    │  9. 触发Sampling         │             │             │
    │──────────────────────────►             │             │
    │              │            │             │             │
    │  [否]        │            │             │             │
    │              │            │             │             │
    │  10. 请求下一站(RTD)      │             │             │
    │─────────────►│            │             │             │
    │              │            │             │             │
    │  11. 返回下一站设备        │             │             │
    │◄─────────────│            │             │             │
    │              │            │             │             │
    │  12. 创建Transfer Job     │             │             │
    │──────────────────────────►(AMHS)       │             │
    │              │            │             │             │
    │              │            │             │             │


```gdscript
# ============================================
# FabSim - Lot状态机实现
# ============================================

class_name LotStateMachine
extends RefCounted

signal state_changed(lot_id: String, from_state: int, to_state: int)
signal track_in_completed(lot_id: String, equipment_id: String)
signal track_out_completed(lot_id: String, equipment_id: String)

enum State {
	CREATED,
	READY,
	WAITING_FOR_RESERVE,
	RESERVED,
	QUEUED,
	TRACK_IN,
	PROCESSING,
	TRACK_OUT,
	SAMPLING,
	BANK_IN,
	BANK_OUT,
	REWORK,
	SCRAPPED,
	HELD,
	COMPLETED
}

var current_state: State
var lot_id: String
var current_equipment: String
var current_step: int

# 状态转换规则: {当前状态: [允许的目标状态]}
var valid_transitions: Dictionary = {
	State.CREATED: [State.READY],
	State.READY: [State.WAITING_FOR_RESERVE, State.HELD, State.SCRAPPED],
	State.WAITING_FOR_RESERVE: [State.RESERVED, State.HELD],
	State.RESERVED: [State.QUEUED, State.READY, State.HELD],
	State.QUEUED: [State.TRACK_IN, State.READY, State.HELD],
	State.TRACK_IN: [State.PROCESSING, State.HELD],
	State.PROCESSING: [State.TRACK_OUT, State.SAMPLING, State.REWORK, State.HELD],
	State.TRACK_OUT: [State.READY, State.COMPLETED, State.BANK_IN],
	State.SAMPLING: [State.READY, State.REWORK, State.SCRAPPED],
	State.BANK_IN: [State.BANK_OUT],
	State.BANK_OUT: [State.READY],
	State.REWORK: [State.READY],
	State.HELD: [State.READY],  # Unhold
	State.SCRAPPED: [],  # 终态
	State.COMPLETED: []  # 终态
}

func _init(id: String):
	lot_id = id
	current_state = State.CREATED

## 尝试状态转换
## new_state: 目标状态
## 返回: 是否转换成功
func transition_to(new_state: State) -> bool:
	if not can_transition_to(new_state):
		push_error("Invalid state transition: %s -> %s" % [State.keys()[current_state], State.keys()[new_state]])
		return false
	
	var old_state = current_state
	current_state = new_state
	
	emit_signal("state_changed", lot_id, old_state, new_state)
	_on_state_enter(new_state)
	
	return true

## 检查是否可以转换到指定状态
func can_transition_to(new_state: State) -> bool:
	if not valid_transitions.has(current_state):
		return false
	return new_state in valid_transitions[current_state]

## 进入新状态的回调
func _on_state_enter(state: State):
	match state:
		State.TRACK_IN:
			_on_track_in()
		State.TRACK_OUT:
			_on_track_out()
		State.PROCESSING:
			_on_processing_start()

func _on_track_in():
	# Track In逻辑
	emit_signal("track_in_completed", lot_id, current_equipment)

func _on_track_out():
	# Track Out逻辑
	emit_signal("track_out_completed", lot_id, current_equipment)

func _on_processing_start():
	# 开始加工
	pass

## 快捷方法
func release() -> bool:
	return transition_to(State.READY)

func reserve() -> bool:
	return transition_to(State.RESERVED)

func track_in(equipment_id: String) -> bool:
	current_equipment = equipment_id
	return transition_to(State.TRACK_IN)

func track_out() -> bool:
	return transition_to(State.TRACK_OUT)

func hold() -> bool:
	return transition_to(State.HELD)

func unhold() -> bool:
	return transition_to(State.READY)

func complete() -> bool:
	return transition_to(State.COMPLETED)

func scrap() -> bool:
	return transition_to(State.SCRAPPED)

## 获取当前状态名称
func get_state_name() -> String:
	return State.keys()[current_state]
```

```
class_name MESCore
extends Node

signal lot_state_changed(lot_id: String, old_state: int, new_state: int)

var lots: Dictionary = {}  # lot_id -> Lot
var state_machines: Dictionary = {}  # lot_id -> LotStateMachine

## 创建Lot
func create_lot(lot_id: String, product: String, recipe: String) -> Lot:
	var lot = Lot.new(lot_id, product, recipe)
	lots[lot_id] = lot
	
	# 创建状态机
	var sm = LotStateMachine.new(lot_id)
	sm.state_changed.connect(_on_lot_state_changed)
	state_machines[lot_id] = sm
	
	return lot

## 释放Lot
func release_lot(lot_id: String) -> bool:
	var sm = state_machines.get(lot_id)
	if not sm:
		return false
	return sm.release()

## Track In
func track_in(lot_id: String, equipment_id: String) -> bool:
	var sm = state_machines.get(lot_id)
	if not sm:
		return false
	
	# 1. 检查设备是否可以接受
	var eq = get_equipment(equipment_id)
	if not eq.can_accept_lot(lots[lot_id]):
		return false
	
	# 2. 执行Track In
	return sm.track_in(equipment_id)

## Track Out
func track_out(lot_id: String) -> bool:
	var sm = state_machines.get(lot_id)
	if not sm:
		return false
	return sm.track_out()

func _on_lot_state_changed(lot_id: String, from_state: int, to_state: int):
	emit_signal("lot_state_changed", lot_id, from_state, to_state)
	
	# 根据状态变化触发后续操作
	match to_state:
		LotStateMachine.State.TRACK_OUT:
			# Track Out后找下一站
			_find_next_destination(lot_id)
		
		LotStateMachine.State.COMPLETED:
			# Lot完成
			_on_lot_completed(lot_id)

func _find_next_destination(lot_id: String):
	var lot = lots[lot_id]
	var next_eq = rtd_scheduler.get_next_equipment(lot)
	if next_eq:
		reserve_equipment(next_eq.equipment_id, lot)

func _on_lot_completed(lot_id: String):
	print("Lot %s completed!" % lot_id)
```